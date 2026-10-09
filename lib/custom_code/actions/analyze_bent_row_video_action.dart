// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';

import 'dart:io';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

/// Analyze a Bent-Over Barbell Row video locally using ML Kit Pose Detection.
///
/// v6.24 — SIMPLIFIED CADENCE (per-validated-count, not per-time-window).
///
/// User feedback on v6.23:
///   • FPs gone (good). PULL-check on frontal fallback + cadence rules
///     handled every false-positive scenario the user reported.
///   • The FIRST real rep is missing in almost every video (bad). User
///     suspects a filter specifically on the first rep.
///
/// The user's intuition was right. The v6.22/v6.23 "tier-1 peak needs a
/// neighbor within ±X seconds" check disproportionately affects the first
/// rep because:
///   • The first rep is often tier-1 (the lifter is more deliberate on
///     rep 1 → lower max-raw amplitude relative to later reps).
///   • A natural pause between rep 1 and rep 2 (lifter settles into rhythm)
///     can exceed 5s. With v6.23's 5s window, rep 1 ends up "isolated"
///     and gets dropped.
///   • Later reps in a set have tighter cadence and stronger amplitude
///     (warmed up, in rhythm), so they aren't subject to the same problem.
///
/// The fundamental error in v6.22/v6.23 was tying cadence to TIME WINDOWS.
/// The real discriminator is COUNT, not timing:
///   • A lone tier-1 peak in a video = likely an FP (single noise peak
///     from pose-tracker correlation; happens during setup, standing, or
///     approach phases).
///   • A tier-1 peak inside a multi-peak set = part of a real exercise.
///     The fact that 2+ peaks exist in the video itself is sufficient
///     evidence that an actual set is happening, regardless of how spaced
///     the peaks are.
///
/// New simpler rule in v6.24:
///   • validated.length == 1 AND that peak is tier 1 → reject (FP).
///   • validated.length == 1 AND tier 2/3 → keep (strong single rep).
///   • validated.length >= 2 → keep all (real set, no per-peak filter).
///
/// All previously-reported FPs are still rejected by this rule, because
/// every observed FP video produced ≤1 multi-signal peak. PULL-check on
/// frontal fallback (v6.23) continues to handle the PULL=0 standing-still
/// cases. Real first reps inside multi-rep sets are now retained.
///
/// HISTORY:
/// v6.23: PULL check on frontal fallback + widened cadence window to 5s +
///   don't fall back if cadence rejected peaks.
/// v6.22: Cadence check for tier-1 peaks (drop isolated FPs).
/// v6.21: Lowered tier-1 max-raw threshold 0.20→0.10 + dur bug fix.
/// v6.20: Lowered prominence floor 0.012→0.008; added acc_t & dur.
/// v6.19: 3-tier graduated PULL using max-raw + supporters.
/// v6.18: Lowered graduated trigger from sup≥4 to sup≥3.
/// v6.17: Graduated PULL based on supporters.
/// v6.16: Added per-filter rejection counters.
/// v6.15: Lowered MIN_PULL_PCT_FRONTAL from 0.30 to 0.20.
/// v6.14: BASELINE_FLOOR cap to requiredValley.
/// v6.13: View-dependent MIN_PULL_PCT / MIN_VALLEY_DESCENT.
/// v6.12: Removed v6.11 knee-bent check.
/// v6.11: Added valley-descent check.
///
/// Earlier history preserved verbatim below for context.
///
/// v5 — TWO-PASS BENT-REGION REP DETECTION:
///
/// The previous v4 approach (single-trace adaptive thresholds on
/// elbow-vs-hip Y) failed on real user videos where the barbell plate
/// occludes the wrist AND the elbow trace is dominated by full-body
/// motion (lifter standing up between sets) rather than per-rep arm
/// motion.
///
/// New approach validated against the user's video (4 actual reps):
///   1) Compute torso angle from horizontal each frame (hip→shoulder
///      vector). When torso < 55° the lifter is in the bent-over
///      position where reps actually happen. When torso > 55° they
///      are standing up between sets / between attempts.
///   2) Identify contiguous "bent regions" (torso < 55° for >= 1.5s).
///      Merge regions separated by short upright gaps (< 1.5s — they
///      are the same set with a brief rebound).
///   3) Filter out bent regions with unstable pose detection
///      (median frame-to-frame torso-angle change > 8°). This
///      rejects the noisy first 1–4 seconds of typical user videos
///      where the camera is being placed and pose detector produces
///      garbage. We use a stability check rather than a likelihood
///      threshold because ML Kit's likelihood scores run lower than
///      MediaPipe's reference scoring; the stability check is
///      independent of the likelihood scale.
///   4) Within each surviving bent region, compute the rep signal
///      = shoulderY − elbowY (positive when elbow is above shoulder
///      = bar pulled high). This is robust to barbell-plate occlusion
///      because both shoulder and elbow are visible above/behind the
///      plate; the wrist is what gets hidden, not these.
///   5) Reject regions whose rep-signal range < 0.04 — those are
///      "hold" positions where the lifter is bracing the bar on
///      thighs without doing full reps.
///   6) On the surviving regions, find peaks with adaptive prominence
///      (max(0.025, 30% of region range)) and minimum spacing 0.4s.
///      Each peak is one rep.
///
/// All form analysis (torso drift, knee drive, etc.) is unchanged
/// from v4 — applied per detected rep window.
Future<dynamic> analyzeBentRowVideoAction(
  FFUploadedFile videoFile,
  double? targetFps,
) async {
  // ================ Constants ================
  const double EMA_ALPHA_TORSO = 0.2; // for torso-angle smoothing
  const int MA_WINDOW_SIGNAL = 5; // moving-average window for rep signal

  // Bent-region detection
  const double BENT_TORSO_DEG = 55.0; // torso < this = bent over
  const double MIN_BENT_DUR_SEC = 1.5; // min region duration
  const double MERGE_GAP_SEC = 1.5; // merge regions separated by < this
  // [v5.1] Stability-based quality gate replaces the previous
  // visibility-based gate. Reasoning: ML Kit's likelihood scores
  // run noticeably lower than MediaPipe's (we observed mean shoulder
  // vis = 0.95 in MediaPipe but ML Kit values run ~0.5-0.7 on the
  // same content), so a fixed 0.7/0.5 threshold rejected legitimate
  // user videos. The stability gate is independent of likelihood
  // scaling: a real bent-over phase has the torso angle moving
  // smoothly (median |delta| per frame ~1-4°), while pose-detector
  // garbage at the start of a video (camera being placed, lens
  // covered) shows torso angle teleporting between 0° and 90° with
  // median delta of 25°+. 8° cleanly separates the two.
  const double MAX_MEDIAN_TORSO_JITTER_DEG = 8.0;

  // Per-region rep detection
  // [v5.2] Lowered MIN_REGION_RANGE from 0.04 to 0.035. The 0.04
  // threshold was tuned on MediaPipe data (where rep traces show
  // range ~0.07). ML Kit produces slightly smaller-amplitude traces
  // and the live PULL% donut peaks lower in the user's app,
  // suggesting trace amplitudes ~30-40% smaller than MediaPipe.
  // 0.035 still rejects "hold position" wobble (range ~0.032 in
  // reference data) but leaves margin for ML Kit's smaller signals.
  // If videos with clear visible reps still return 0, lower to 0.025.
  const double MIN_REGION_RANGE = 0.035;
  // [v6.0] Lowered prominence thresholds significantly. Real-video
  // testing on multiple side videos (v11a, v12, v13) showed that
  // legitimate reps were being dropped:
  //  - v12 4th rep: prominence ~0.026, dropped at 0.30*range=0.020
  //  - v13: 5+ reps with prom 0.024-0.045, several dropped
  // The PULL gauge in the UI (which uses raw elShRaw) clearly showed
  // these as 50-100% pulls. Lower threshold (0.20 fraction, 0.010
  // floor) recovers them without introducing false positives — the
  // bent-region gating already filters out non-rep noise.
  const double PROM_FLOOR = 0.010;
  const double PROM_FRACTION_OF_RANGE = 0.20;
  const double MIN_PEAK_DISTANCE_SEC = 0.4;

  // [v5.1] Lowered from 0.3 to 0.1: ML Kit's likelihood scores run
  // lower than MediaPipe's, so 0.3 dropped legitimate frames. We
  // rely on the post-hoc stability gate (median torso-jitter) to
  // reject genuinely garbage pose data instead of trusting the
  // raw likelihood scale.
  const double VIS_THR_MIN = 0.1; // min visibility for landmark to count

  // Form thresholds (unchanged from v4)
  const double TORSO_HIGH_WARNING_DEG = 65.0;
  const double TORSO_DRIFT_DEG = 25.0;
  const double KNEE_EXTENSION_DEG = 12.0;
  const double PULL_HEIGHT_MIN_GOOD_PCT = 0.7;
  const double PULL_HEIGHT_MIN_OK_PCT = 0.45;
  const int MIN_REPS_FOR_FORM_ERROR = 2;

  // Feedback strings
  const String FB_ERROR_PULL_HIGH = 'Pull higher — reach your torso';
  const String FB_ERROR_TORSO_HIGH = 'Lower your torso — get more horizontal';
  const String FB_ERROR_MOMENTUM = 'Avoid using momentum — keep torso still';
  const String FB_ERROR_LEG_DRIVE = 'Minimize leg drive — keep knees steady';
  const List<String> FORM_ERROR_PRIORITY = [
    FB_ERROR_PULL_HIGH,
    FB_ERROR_TORSO_HIGH,
    FB_ERROR_MOMENTUM,
    FB_ERROR_LEG_DRIVE,
  ];

  final double fps = (targetFps ?? 20.0).clamp(4.0, 30.0);
  final double dt = 1.0 / fps;

  _cachedW = -1;
  _cachedH = -1;

  // ================ Helpers ================
  double? angleDeg(List<double>? a, List<double>? b, List<double>? c) {
    if (a == null || b == null || c == null) return null;
    final baX = a[0] - b[0];
    final baY = a[1] - b[1];
    final bcX = c[0] - b[0];
    final bcY = c[1] - b[1];
    final baLen = math.sqrt(baX * baX + baY * baY);
    final bcLen = math.sqrt(bcX * bcX + bcY * bcY);
    if (baLen == 0 || bcLen == 0) return null;
    var cos = (baX * bcX + baY * bcY) / (baLen * bcLen + 1e-9);
    cos = cos.clamp(-1.0, 1.0);
    return math.acos(cos) * 180.0 / math.pi;
  }

  double torsoFromHorizontal(double dx, double dy) {
    return math.atan2(dy.abs(), dx.abs()) * 180.0 / math.pi;
  }

  double clampD(double x, double lo, double hi) =>
      math.max(lo, math.min(hi, x));
  double roundToHalf(double x) => (x * 2).round() / 2.0;

  String technique(double s) {
    if (s >= 9.5) return 'Excellent';
    if (s >= 8.5) return 'Very good';
    if (s >= 7.5) return 'Good';
    if (s >= 6.5) return 'Fair';
    return 'Needs work';
  }

  double? robustRange(List<double> values) {
    if (values.length < 5) return null;
    final sorted = List<double>.from(values)..sort();
    double pct(double pe) {
      if (sorted.length == 1) return sorted.first;
      final rank = (pe / 100.0) * (sorted.length - 1);
      final lo = rank.floor();
      final hi = rank.ceil();
      if (lo == hi) return sorted[lo];
      final frac = rank - lo;
      return sorted[lo] * (1 - frac) + sorted[hi] * frac;
    }

    return pct(90) - pct(10);
  }

  double? safeMean(List<double> values) {
    if (values.length < 5) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  Map<String, dynamic> errorPayload(String code, String detail) => {
        'error': code,
        'detail': detail,
        'squat_count': 0,
        'row_count': 0,
        'technique_score': 0.0,
        'technique_score_display': '0',
        'technique_label': 'Needs work',
        'good_reps': 0,
        'bad_reps': 0,
        'feedback': <String>['Could not analyze video'],
        'tips': <String>[],
        'form_tip': null,
        'reps': <dynamic>[],
        'exercise_type': 'bent_row',
        '_source_video_uri': '',
        '_frame_telemetry': <dynamic>[],
      };

  // ================ 0) Persist upload ================
  if (videoFile.bytes == null || videoFile.bytes!.isEmpty) {
    return errorPayload('empty_upload', 'Uploaded file has no bytes');
  }
  final Directory tmp = await getTemporaryDirectory();
  final String uploadName =
      (videoFile.name?.isNotEmpty ?? false) ? videoFile.name! : 'upload.mp4';
  final String safeName = uploadName.split('/').last.split('\\').last;
  final String videoPath = p.join(
    tmp.path,
    'row_in_${DateTime.now().millisecondsSinceEpoch}_$safeName',
  );
  try {
    await File(videoPath).writeAsBytes(videoFile.bytes!, flush: true);
  } catch (e) {
    return errorPayload('write_failed', 'Could not save upload: $e');
  }

  // ================ 1) Extract frames ================
  final String sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  final Directory framesDir =
      Directory(p.join(tmp.path, 'row_frames_$sessionId'));
  if (framesDir.existsSync()) framesDir.deleteSync(recursive: true);
  framesDir.createSync(recursive: true);

  final String framePattern = p.join(framesDir.path, 'f_%05d.jpg');
  final String extractCmd =
      "-y -i \"$videoPath\" -vf \"fps=$fps,scale='min(720,iw)':-2\" -q:v 4 \"$framePattern\"";
  final extractSession = await FFmpegKit.execute(extractCmd);
  final extractRc = await extractSession.getReturnCode();
  if (!ReturnCode.isSuccess(extractRc)) {
    return errorPayload('ffmpeg_extract_failed', 'Could not extract frames');
  }
  final List<File> frameFiles = framesDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.jpg'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  if (frameFiles.isEmpty) {
    return errorPayload('no_frames', 'No frames were produced');
  }

  // ================ 2) Pose detector ================
  final poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.single,
      model: PoseDetectionModel.accurate,
    ),
  );

  // ================ 3) Per-frame state ================
  int frameIdx = 0;

  // Per-frame measurements
  final List<double?> torsoAngRawByFrame =
      []; // raw torso angle from horizontal
  final List<double?> elbowMinusShoulderByFrame = []; // sy - ey, our rep signal
  final List<double?> hipMinusElbowByFrame =
      []; // legacy v4 signal kept for telemetry
  final List<double?> torsoAngByFrame = []; // for form analysis
  final List<double?> kneeAngByFrame = []; // for form analysis
  // [v5.3] Bilateral average elbow-shoulder Y, used as fallback signal
  // for frontal-camera videos where torso-angle-based bent detection
  // is unreliable.
  final List<double?> elShAvgByFrame = [];
  // [v5.4] For frontal-camera detection and rep counting.
  // shoulderY = avg(left, right) — rises during pull when filming from front.
  // hipY = avg(left, right) — used to detect "stable stance" period.
  // shoulderXSpread = |lsh.x - rsh.x| — wide in frontal, narrow in side view.
  // elbowVisAsym = |lel.vis - rel.vis| — small in frontal, large in side view.
  final List<double?> shoulderYAvgByFrame = [];
  final List<double?> hipYAvgByFrame = [];
  final List<double?> shoulderXSpreadByFrame = [];
  final List<double?> elbowVisAsymByFrame = [];
  // [v5.5] hip-knee-ankle angle (avg of left and right side).
  // ~180° when standing straight, decreases as knees bend.
  // This is the strongest signal for FRONTAL bent-over-row detection
  // because the lifter naturally extends/flexes knees with each rep
  // (range ~40-50° in real videos vs ~0.03 for shoulder Y).
  //
  // [v6.11] Now ALSO used in the side path: as the anti-FP filter that
  // distinguishes "elbow above shoulder during a real strong pull"
  // (knees bent ~140-170°) from "elbow above shoulder while standing
  // upright with arm raised" (knees straight >175°).
  final List<double?> hipKneeAngByFrame = [];
  // [v6.6] Additional signals for multi-signal voting rep detection.
  // wrYAvg = (lwr.y + rwr.y) / 2 — average wrist Y position (rises during pull)
  // elYAvg = (lel.y + rel.y) / 2 — average elbow Y position
  // elXSpread = |lel.x - rel.x| — horizontal distance between elbows
  //   (elbows go wider in side view as the bar travels up)
  // hipYAvg already exists. Combined with shoulderY (already exists) we
  // can compute multiple peak signals:
  //   wrMinusSh = (sh - wr).y   (wrist higher than shoulder = pull)
  //   wrMinusHip = (hip - wr).y (wrist closer to hip = pull complete)
  //   elXSpread peaks when arms are at top of pull
  final List<double?> wristYAvgByFrame = [];
  final List<double?> elbowYAvgByFrame = [];
  final List<double?> elbowXSpreadByFrame = [];
  final List<double> shVisByFrame = [];
  final List<double> hpVisByFrame = [];
  final List<double> elVisByFrame = [];

  final List<Map<String, dynamic>> frameTelemetry = [];

  String? rtFbMsg;
  int rtFbHold = 0;
  final int RT_FB_HOLD_FRAMES = math.max(2, (1.5 / dt).round());
  String? repJustFinished;

  const List<PoseLandmarkType> LM_ORDER = [
    PoseLandmarkType.nose,
    PoseLandmarkType.leftEyeInner,
    PoseLandmarkType.leftEye,
    PoseLandmarkType.leftEyeOuter,
    PoseLandmarkType.rightEyeInner,
    PoseLandmarkType.rightEye,
    PoseLandmarkType.rightEyeOuter,
    PoseLandmarkType.leftEar,
    PoseLandmarkType.rightEar,
    PoseLandmarkType.leftMouth,
    PoseLandmarkType.rightMouth,
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftPinky,
    PoseLandmarkType.rightPinky,
    PoseLandmarkType.leftIndex,
    PoseLandmarkType.rightIndex,
    PoseLandmarkType.leftThumb,
    PoseLandmarkType.rightThumb,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
    PoseLandmarkType.leftHeel,
    PoseLandmarkType.rightHeel,
    PoseLandmarkType.leftFootIndex,
    PoseLandmarkType.rightFootIndex,
  ];

  List<List<double>>? lastValidLandmarks;

  // ================ 4) Pose loop — only collect measurements ================
  try {
    for (final frameFile in frameFiles) {
      frameIdx += 1;
      final double tSec = (frameIdx - 1) / fps;

      final inputImage = InputImage.fromFilePath(frameFile.path);
      List<Pose> poses;
      try {
        poses = await poseDetector.processImage(inputImage);
      } catch (_) {
        poses = const [];
      }

      double fw = _cachedW;
      double fh = _cachedH;
      if (fw <= 0 || fh <= 0) {
        final dims = await _probeImageDims(frameFile.path);
        fw = dims.$1.toDouble();
        fh = dims.$2.toDouble();
        _cachedW = fw;
        _cachedH = fh;
      }

      final List<List<double>> normLandmarks = [];
      if (poses.isNotEmpty) {
        final lm = poses.first.landmarks;
        for (final type in LM_ORDER) {
          final plm = lm[type];
          if (plm == null) {
            normLandmarks.add([0.0, 0.0, 0.0]);
          } else {
            normLandmarks.add([
              (plm.x / fw).clamp(0.0, 1.0).toDouble(),
              (plm.y / fh).clamp(0.0, 1.0).toDouble(),
              (plm.likelihood).clamp(0.0, 1.0).toDouble(),
            ]);
          }
        }
        lastValidLandmarks = normLandmarks;
      }

      if (poses.isEmpty) {
        frameTelemetry.add({
          't': tSec,
          'reps': 0, // populated in post-process
          'depth': 0.0,
          'metric_label': 'PULL',
          'metric_value': 0.0,
          'feedback': null,
          'rep_just_finished': null,
          'landmarks': lastValidLandmarks ?? <List<double>>[],
        });
        torsoAngRawByFrame.add(null);
        elbowMinusShoulderByFrame.add(null);
        hipMinusElbowByFrame.add(null);
        torsoAngByFrame.add(null);
        kneeAngByFrame.add(null);
        elShAvgByFrame.add(null);
        shoulderYAvgByFrame.add(null);
        hipYAvgByFrame.add(null);
        shoulderXSpreadByFrame.add(null);
        elbowVisAsymByFrame.add(null);
        hipKneeAngByFrame.add(null);
        wristYAvgByFrame.add(null);
        elbowYAvgByFrame.add(null);
        elbowXSpreadByFrame.add(null);
        shVisByFrame.add(0.0);
        hpVisByFrame.add(0.0);
        elVisByFrame.add(0.0);
        continue;
      }

      final lm = poses.first.landmarks;
      final lsh = lm[PoseLandmarkType.leftShoulder];
      final rsh = lm[PoseLandmarkType.rightShoulder];
      final lel = lm[PoseLandmarkType.leftElbow];
      final rel = lm[PoseLandmarkType.rightElbow];
      final lwr = lm[PoseLandmarkType.leftWrist];
      final rwr = lm[PoseLandmarkType.rightWrist];
      final lhp = lm[PoseLandmarkType.leftHip];
      final rhp = lm[PoseLandmarkType.rightHip];
      final lkn = lm[PoseLandmarkType.leftKnee];
      final rkn = lm[PoseLandmarkType.rightKnee];
      final lank = lm[PoseLandmarkType.leftAnkle];
      final rank = lm[PoseLandmarkType.rightAnkle];

      double scoreSide(PoseLandmark? sh, PoseLandmark? el, PoseLandmark? wr,
          PoseLandmark? hp, PoseLandmark? kn) {
        double s = 0.0;
        for (final lmk in [sh, el, wr, hp, kn]) {
          s += (lmk?.likelihood ?? 0.0);
        }
        return s;
      }

      final double sL = scoreSide(lsh, lel, lwr, lhp, lkn);
      final double sR = scoreSide(rsh, rel, rwr, rhp, rkn);
      final bool useLeft = sL > sR;

      final PoseLandmark? sh = useLeft ? lsh : rsh;
      final PoseLandmark? el = useLeft ? lel : rel;
      final PoseLandmark? wr = useLeft ? lwr : rwr;
      final PoseLandmark? hp = useLeft ? lhp : rhp;
      final PoseLandmark? kn = useLeft ? lkn : rkn;
      final PoseLandmark? ank = useLeft ? lank : rank;

      bool haveCore = sh != null && hp != null && el != null;
      bool haveAll = haveCore && wr != null && kn != null && ank != null;

      double? torsoAngRaw;
      double? elbowMinusShoulder;
      double? hipMinusElbow;
      double? torsoForForm;
      double? kneeAng;
      // [v5.3] Bilateral average — works in frontal-camera videos where
      // the side-specific signal is noisy (camera switching between L/R
      // gives unstable side picks). Averaging both sides is robust to
      // this. Only computed when both sides are visible enough.
      double? elShAvg;

      if (haveCore &&
          (sh!.likelihood >= VIS_THR_MIN) &&
          (hp!.likelihood >= VIS_THR_MIN) &&
          (el!.likelihood >= VIS_THR_MIN)) {
        final shY = sh.y / fh;
        final shX = sh.x / fw;
        final hpY = hp.y / fh;
        final hpX = hp.x / fw;
        final elY = el.y / fh;

        torsoAngRaw = torsoFromHorizontal(shX - hpX, shY - hpY);
        torsoForForm = torsoAngRaw;
        elbowMinusShoulder = shY - elY; // positive when elbow above shoulder
        hipMinusElbow = hpY - elY;

        if (haveAll &&
            kn!.likelihood >= VIS_THR_MIN &&
            ank!.likelihood >= VIS_THR_MIN) {
          final List<double> hP = [hpX, hpY];
          final List<double> kP = [kn.x / fw, kn.y / fh];
          final List<double> aP = [ank.x / fw, ank.y / fh];
          kneeAng = angleDeg(hP, kP, aP);
        }
      }

      // [v5.3] Compute bilateral average elbow-shoulder Y for frontal-camera
      // fallback. Requires both shoulders and both elbows visible.
      if (lsh != null &&
          rsh != null &&
          lel != null &&
          rel != null &&
          lsh.likelihood >= VIS_THR_MIN &&
          rsh.likelihood >= VIS_THR_MIN &&
          lel.likelihood >= VIS_THR_MIN &&
          rel.likelihood >= VIS_THR_MIN) {
        final lDiff = (lsh.y / fh) - (lel.y / fh);
        final rDiff = (rsh.y / fh) - (rel.y / fh);
        elShAvg = (lDiff + rDiff) / 2.0;
      }

      // [v5.4] Compute features used for frontal-vs-side view detection
      // and frontal-mode rep counting.
      double? shoulderYAvg;
      double? hipYAvg;
      double? shoulderXSpread;
      double? elbowVisAsym;
      if (lsh != null &&
          rsh != null &&
          lsh.likelihood >= VIS_THR_MIN &&
          rsh.likelihood >= VIS_THR_MIN) {
        shoulderYAvg = ((lsh.y / fh) + (rsh.y / fh)) / 2.0;
        shoulderXSpread = ((lsh.x - rsh.x).abs()) / fw;
      }
      if (lhp != null &&
          rhp != null &&
          lhp.likelihood >= VIS_THR_MIN &&
          rhp.likelihood >= VIS_THR_MIN) {
        hipYAvg = ((lhp.y / fh) + (rhp.y / fh)) / 2.0;
      }
      if (lel != null && rel != null) {
        elbowVisAsym = (lel.likelihood - rel.likelihood).abs();
      }

      // [v5.5] hipKneeAng: average of left & right hip-knee-ankle angle.
      // 180° = leg straight, smaller = bent. The strongest signal for
      // frontal rep detection because the lifter's knee bend is
      // visible regardless of camera angle.
      double? hipKneeAng;
      {
        final List<double> angs = [];
        if (lhp != null &&
            lkn != null &&
            lank != null &&
            lhp.likelihood >= VIS_THR_MIN &&
            lkn.likelihood >= VIS_THR_MIN &&
            lank.likelihood >= VIS_THR_MIN) {
          final List<double> hP = [lhp.x / fw, lhp.y / fh];
          final List<double> kP = [lkn.x / fw, lkn.y / fh];
          final List<double> aP = [lank.x / fw, lank.y / fh];
          final double? a = angleDeg(hP, kP, aP);
          if (a != null) angs.add(a);
        }
        if (rhp != null &&
            rkn != null &&
            rank != null &&
            rhp.likelihood >= VIS_THR_MIN &&
            rkn.likelihood >= VIS_THR_MIN &&
            rank.likelihood >= VIS_THR_MIN) {
          final List<double> hP = [rhp.x / fw, rhp.y / fh];
          final List<double> kP = [rkn.x / fw, rkn.y / fh];
          final List<double> aP = [rank.x / fw, rank.y / fh];
          final double? a = angleDeg(hP, kP, aP);
          if (a != null) angs.add(a);
        }
        if (angs.isNotEmpty) {
          double s = 0;
          for (final a in angs) s += a;
          hipKneeAng = s / angs.length;
        }
      }

      // [v6.6] Compute additional signals for voting
      double? wristYAvg;
      double? elbowYAvg;
      double? elbowXSpread;
      if (lwr != null &&
          rwr != null &&
          lwr.likelihood >= VIS_THR_MIN &&
          rwr.likelihood >= VIS_THR_MIN) {
        wristYAvg = (lwr.y / fh + rwr.y / fh) / 2.0;
      }
      if (lel != null &&
          rel != null &&
          lel.likelihood >= VIS_THR_MIN &&
          rel.likelihood >= VIS_THR_MIN) {
        elbowYAvg = (lel.y / fh + rel.y / fh) / 2.0;
        elbowXSpread = (lel.x / fw - rel.x / fw).abs();
      }

      torsoAngRawByFrame.add(torsoAngRaw);
      elbowMinusShoulderByFrame.add(elbowMinusShoulder);
      hipMinusElbowByFrame.add(hipMinusElbow);
      torsoAngByFrame.add(torsoForForm);
      kneeAngByFrame.add(kneeAng);
      elShAvgByFrame.add(elShAvg);
      shoulderYAvgByFrame.add(shoulderYAvg);
      hipYAvgByFrame.add(hipYAvg);
      shoulderXSpreadByFrame.add(shoulderXSpread);
      elbowVisAsymByFrame.add(elbowVisAsym);
      hipKneeAngByFrame.add(hipKneeAng);
      wristYAvgByFrame.add(wristYAvg);
      elbowYAvgByFrame.add(elbowYAvg);
      elbowXSpreadByFrame.add(elbowXSpread);
      shVisByFrame.add(sh?.likelihood ?? 0.0);
      hpVisByFrame.add(hp?.likelihood ?? 0.0);
      elVisByFrame.add(el?.likelihood ?? 0.0);

      // Live UI metric: 0..1 from elbow-vs-shoulder (clamped). Just for the donut.
      // [v5.3] Recalibrated for ML Kit's actual range. Real-world data:
      //   bottom of pull (arms extended): elbowMinusShoulder ≈ -0.07
      //   top of pull (bar at chest):     elbowMinusShoulder ≈ -0.01
      // Old formula (-0.10 → 0%, +0.05 → 100%) compressed the actual
      // motion into the 20-67% range, making the donut feel
      // unresponsive. New formula uses the realistic range:
      //   -0.08 → 0%, -0.01 → 100%
      // This gives the donut full 0-100% travel during a real rep.
      double pullPctLive = 0.0;
      if (elbowMinusShoulder != null) {
        pullPctLive = clampD((elbowMinusShoulder + 0.08) / 0.07, 0.0, 1.0);
      }

      frameTelemetry.add({
        't': tSec,
        'reps': 0, // populated below
        'depth': pullPctLive,
        'metric_label': 'PULL',
        'metric_value': pullPctLive,
        'feedback': null, // populated below
        'rep_just_finished': null, // populated below
        'landmarks': normLandmarks,
      });
    }
  } finally {
    await poseDetector.close();
    try {
      framesDir.deleteSync(recursive: true);
    } catch (_) {}
  }

  // ================ 5) Smoothing ================
  // EMA on torso angle (heavy smoothing - it's a slow signal)
  final List<double?> torsoSmooth = [];
  {
    double? prev;
    for (final v in torsoAngRawByFrame) {
      if (v == null) {
        torsoSmooth.add(null);
        continue;
      }
      if (prev == null) {
        prev = v;
      } else {
        prev = prev + EMA_ALPHA_TORSO * (v - prev);
      }
      torsoSmooth.add(prev);
    }
  }

  // Centered moving average on rep signal (no lag)
  final List<double?> elShMA = [];
  {
    final int half = MA_WINDOW_SIGNAL ~/ 2;
    for (int i = 0; i < elbowMinusShoulderByFrame.length; i++) {
      final lo = math.max(0, i - half);
      final hi = math.min(elbowMinusShoulderByFrame.length - 1, i + half);
      double sum = 0.0;
      int cnt = 0;
      for (int j = lo; j <= hi; j++) {
        final v = elbowMinusShoulderByFrame[j];
        if (v != null) {
          sum += v;
          cnt += 1;
        }
      }
      elShMA.add(cnt > 0 ? sum / cnt : null);
    }
  }

  // ================ 5.5) View detection (frontal vs side) ================
  // [v5.4] Decide if the camera is frontal or side. Each mode uses
  // a different rep-detection strategy:
  //   - SIDE: torso-angle bent regions + elbow-vs-shoulder Y peaks
  //           (works because the lifter's bent silhouette and arm
  //           motion are clearly visible from the side)
  //   - FRONTAL: stable-stance detection + shoulder-Y peaks
  //           (the torso angle is unreliable in frontal view because
  //           the hip→shoulder vector is mostly along Z; instead we
  //           rely on the small upward bob of the body during a pull)
  //
  // Detection rule (validated on real test videos):
  //   FRONTAL = median(shoulderXSpread) >= 0.10
  //          AND median(elbowVisAsym) < 0.10
  // (shoulderXSpread alone is not enough: 3/4-view side videos can
  // have spread up to 0.15. The elbow visibility asymmetry is the
  // tiebreaker — in side view, one elbow is partially hidden so
  // visibilities differ; in frontal both are equally visible.)
  String detectedView = 'side';
  {
    final List<double> shSpreads = [];
    final List<double> elAsyms = [];
    for (int i = 0; i < shoulderXSpreadByFrame.length; i++) {
      final s = shoulderXSpreadByFrame[i];
      if (s != null) shSpreads.add(s);
      final a = elbowVisAsymByFrame[i];
      if (a != null) elAsyms.add(a);
    }
    if (shSpreads.isNotEmpty && elAsyms.isNotEmpty) {
      shSpreads.sort();
      elAsyms.sort();
      final shMed = shSpreads[shSpreads.length ~/ 2];
      final elMed = elAsyms[elAsyms.length ~/ 2];
      if (shMed >= 0.10 && elMed < 0.10) {
        detectedView = 'frontal';
      }
    }
  }

  // ================ 5.6) Frontal-view rep detection ================
  // [v5.5] Hybrid signal selection — frontal videos have two distinct
  // patterns:
  //   A) Lifter holds a stable bent stance and pulls with arms.
  //      (e.g. classic bent-row from the front) — knee angle stays
  //      mostly constant, but shoulders bob up/down with each pull.
  //      Best signal: shoulderY peaks (in stable-stance regions).
  //   B) Lifter performs deadlift-style motion where knees bend/extend
  //      with each rep — knee angle has large range.
  //      Best signal: knee-angle extension peaks.
  //
  // Strategy:
  //   1. Find "stable stance" regions (hipY std < 0.025 for ≥1.5s).
  //   2. If found: within each region, pick the signal with stronger
  //      range (knee if ≥15°, otherwise shoulderY if ≥0.012).
  //   3. If no stable region: fall back to full-video knee analysis.
  final List<int> frontalRepPeaks = [];
  if (detectedView == 'frontal') {
    final int nFrames = frameTelemetry.length;

    // Smooth both candidate signals
    final List<double?> kneeMA = [];
    final List<double?> shYMA = [];
    final int half = MA_WINDOW_SIGNAL ~/ 2;
    for (int i = 0; i < nFrames; i++) {
      // knee
      double sumK = 0.0;
      int cntK = 0;
      // shoulder Y
      double sumS = 0.0;
      int cntS = 0;
      final lo = math.max(0, i - half);
      final hi = math.min(nFrames - 1, i + half);
      for (int j = lo; j <= hi; j++) {
        final vk = (j < hipKneeAngByFrame.length) ? hipKneeAngByFrame[j] : null;
        if (vk != null) {
          sumK += vk;
          cntK++;
        }
        final vs =
            (j < shoulderYAvgByFrame.length) ? shoulderYAvgByFrame[j] : null;
        if (vs != null) {
          sumS += vs;
          cntS++;
        }
      }
      kneeMA.add(cntK > 0 ? sumK / cntK : null);
      shYMA.add(cntS > 0 ? sumS / cntS : null);
    }

    // Find "stable stance" regions: rolling 1s window with hipY std < 0.025
    final int stableWindow = math.max(3, fps.round());
    final List<bool> stableMask = List<bool>.filled(nFrames, false);
    for (int i = stableWindow; i < nFrames; i++) {
      final List<double> sub = [];
      for (int j = i - stableWindow; j < i; j++) {
        final v = hipYAvgByFrame[j];
        if (v != null) sub.add(v);
      }
      if (sub.length < stableWindow ~/ 2) continue;
      double mn = sub[0], mx = sub[0];
      for (final v in sub) {
        if (v < mn) mn = v;
        if (v > mx) mx = v;
      }
      if (mx - mn < 0.025) stableMask[i] = true;
    }

    final List<List<int>> regions = [];
    int idx = 0;
    while (idx < nFrames) {
      if (stableMask[idx]) {
        int j = idx;
        while (j < nFrames && stableMask[j]) j++;
        if (j - idx >= (MIN_BENT_DUR_SEC * fps).round()) {
          regions.add([idx, j - 1]);
        }
        idx = j;
      } else {
        idx++;
      }
    }

    // Fallback: if no stable stance, use the whole video.
    if (regions.isEmpty) {
      regions.add([0, nFrames - 1]);
    }

    final int minPeakDist = math.max(2, (0.6 * fps).round());

    for (final r in regions) {
      final int s = r[0];
      final int e = r[1];

      // Build sub-traces for both signals
      final List<double> kneeSub = [];
      final List<double> shYSub = [];
      final List<int> subIdx = [];
      for (int k = s; k <= e; k++) {
        final vk = kneeMA[k];
        final vs = shYMA[k];
        if (vk != null && vs != null) {
          kneeSub.add(vk);
          shYSub.add(-vs); // negate so peaks = highest position
          subIdx.add(k);
        }
      }
      if (kneeSub.length < 5) continue;

      double kneeMn = kneeSub[0], kneeMx = kneeSub[0];
      for (final v in kneeSub) {
        if (v < kneeMn) kneeMn = v;
        if (v > kneeMx) kneeMx = v;
      }
      double shYMn = shYSub[0], shYMx = shYSub[0];
      for (final v in shYSub) {
        if (v < shYMn) shYMn = v;
        if (v > shYMx) shYMx = v;
      }
      final double kneeRng = kneeMx - kneeMn;
      final double shYRng = shYMx - shYMn;

      // Pick signal: prefer knee if range >= 15°, otherwise shoulderY
      final List<double> sigSub;
      final double promThr;
      if (kneeRng >= 15.0) {
        sigSub = kneeSub;
        promThr = math.max(5.0, 0.30 * kneeRng);
      } else if (shYRng >= 0.012) {
        sigSub = shYSub;
        promThr = math.max(0.008, 0.30 * shYRng);
      } else {
        continue; // signals too small in this region
      }

      // Find candidate local maxima with boundary handling
      final List<int> candidates = [];
      if (sigSub.length >= 2 && sigSub[0] > sigSub[1]) candidates.add(0);
      for (int k = 1; k < sigSub.length - 1; k++) {
        if (sigSub[k] > sigSub[k - 1] && sigSub[k] >= sigSub[k + 1]) {
          candidates.add(k);
        } else if (sigSub[k] >= sigSub[k - 1] && sigSub[k] > sigSub[k + 1]) {
          candidates.add(k);
        }
      }
      if (sigSub.length >= 2) {
        final int last = sigSub.length - 1;
        if (sigSub[last] > sigSub[last - 1]) candidates.add(last);
      }

      // Prominence filter
      final List<int> kept = [];
      final List<double> keptProms = [];
      for (final c in candidates) {
        final double cv = sigSub[c];
        double leftMin = cv;
        for (int k = c - 1; k >= 0; k--) {
          if (sigSub[k] > cv) break;
          if (sigSub[k] < leftMin) leftMin = sigSub[k];
        }
        double rightMin = cv;
        for (int k = c + 1; k < sigSub.length; k++) {
          if (sigSub[k] > cv) break;
          if (sigSub[k] < rightMin) rightMin = sigSub[k];
        }
        final double base = math.max(leftMin, rightMin);
        final double prom = cv - base;
        if (prom >= promThr) {
          kept.add(c);
          keptProms.add(prom);
        }
      }

      // Min-distance filter
      final List<int> orderByProm = List<int>.generate(kept.length, (k) => k)
        ..sort((a, b) => keptProms[b].compareTo(keptProms[a]));
      final List<bool> alive = List<bool>.filled(kept.length, true);
      for (final ki in orderByProm) {
        if (!alive[ki]) continue;
        final int kIdx = subIdx[kept[ki]];
        for (int kj = 0; kj < kept.length; kj++) {
          if (kj == ki || !alive[kj]) continue;
          final int kjIdx = subIdx[kept[kj]];
          if ((kjIdx - kIdx).abs() < minPeakDist) alive[kj] = false;
        }
      }
      for (int k = 0; k < kept.length; k++) {
        if (alive[k]) frontalRepPeaks.add(subIdx[kept[k]]);
      }
    }
    frontalRepPeaks.sort();
  }

  // ================ 6) Identify bent regions ================
  final int n = frameTelemetry.length;
  final int minBentFrames = math.max(3, (MIN_BENT_DUR_SEC * fps).round());
  final int mergeGapFrames = math.max(1, (MERGE_GAP_SEC * fps).round());

  final List<bool> bent = List<bool>.generate(n, (i) {
    final v = torsoSmooth[i];
    return v != null && v < BENT_TORSO_DEG;
  });

  // Find raw contiguous bent runs
  final List<List<int>> rawRegions = []; // each [start, end] inclusive
  int i = 0;
  while (i < n) {
    if (bent[i]) {
      int j = i;
      while (j < n && bent[j]) j++;
      rawRegions.add([i, j - 1]);
      i = j;
    } else {
      i++;
    }
  }

  // Merge regions separated by short gaps
  final List<List<int>> mergedRegions = [];
  for (final r in rawRegions) {
    if (mergedRegions.isNotEmpty &&
        (r[0] - mergedRegions.last[1]) <= mergeGapFrames) {
      mergedRegions.last[1] = r[1];
    } else {
      mergedRegions.add([r[0], r[1]]);
    }
  }

  // Filter by duration
  final List<List<int>> durFilteredRegions =
      mergedRegions.where((r) => (r[1] - r[0]) >= minBentFrames).toList();

  // Visibility quality gate: rejects start-of-video pose-detector noise
  // [v5.1] Replaced visibility-based gate with stability-based gate.
  // We compute the median |delta torso angle| per frame on the RAW
  // (un-smoothed) angle within the region. Pose detector garbage at
  // the start of a video shows torso angle teleporting between 0°
  // and 90° between consecutive frames; a real bent-over phase has
  // the angle moving smoothly. This gate is independent of ML Kit's
  // likelihood scaling.
  final List<List<int>> qualityRegions = [];
  for (final r in durFilteredRegions) {
    final s = r[0];
    final e = r[1];
    final List<double> deltas = [];
    double? prevAng;
    for (int k = s; k <= e; k++) {
      final v = torsoAngRawByFrame[k];
      if (v == null) {
        prevAng = null;
        continue;
      }
      if (prevAng != null) {
        deltas.add((v - prevAng).abs());
      }
      prevAng = v;
    }
    if (deltas.isEmpty) continue;
    deltas.sort();
    final double median = deltas[deltas.length ~/ 2];
    if (median <= MAX_MEDIAN_TORSO_JITTER_DEG) {
      qualityRegions.add([s, e]);
    }
  }

  // [v5.1] Debug info — computed BEFORE any early-return so it's always
  // available in the result for diagnosing why a video produced N reps.
  final List<Map<String, dynamic>> debugRegions = [];
  for (final r in mergedRegions) {
    final s = r[0];
    final e = r[1];
    final double durSec = (e - s + 1) / fps;
    final List<double> deltas = [];
    double? prevAng;
    for (int k = s; k <= e; k++) {
      final v = torsoAngRawByFrame[k];
      if (v == null) {
        prevAng = null;
        continue;
      }
      if (prevAng != null) deltas.add((v - prevAng).abs());
      prevAng = v;
    }
    double medianDelta = -1.0;
    if (deltas.isNotEmpty) {
      deltas.sort();
      medianDelta = deltas[deltas.length ~/ 2];
    }
    double traceRng = 0.0;
    final List<double> sub = [];
    for (int k = s; k <= e; k++) {
      final v = elShMA[k];
      if (v != null) sub.add(v);
    }
    if (sub.isNotEmpty) {
      double mn = sub[0], mx = sub[0];
      for (final v in sub) {
        if (v < mn) mn = v;
        if (v > mx) mx = v;
      }
      traceRng = mx - mn;
    }
    debugRegions.add({
      'start_t': s / fps,
      'end_t': e / fps,
      'duration_s': durSec,
      'median_torso_jitter_deg': medianDelta,
      'trace_range': traceRng,
      'passed_duration_filter': durSec >= MIN_BENT_DUR_SEC,
      'passed_stability_gate':
          medianDelta >= 0 && medianDelta <= MAX_MEDIAN_TORSO_JITTER_DEG,
      'passed_range_filter': traceRng >= MIN_REGION_RANGE,
    });
  }

  // Diagnostic summary (always populated)
  int validPoseFrames = 0;
  int validTraceFrames = 0;
  double sumShVis = 0, sumHpVis = 0, sumElVis = 0;
  for (int k = 0; k < frameTelemetry.length; k++) {
    if (k < torsoAngRawByFrame.length && torsoAngRawByFrame[k] != null) {
      validTraceFrames++;
    }
    sumShVis += shVisByFrame[k];
    sumHpVis += hpVisByFrame[k];
    sumElVis += elVisByFrame[k];
    if (shVisByFrame[k] > 0 || hpVisByFrame[k] > 0 || elVisByFrame[k] > 0) {
      validPoseFrames++;
    }
  }
  final int totalFrames = frameTelemetry.length;
  final Map<String, dynamic> debugSummary = {
    'total_frames': totalFrames,
    'valid_pose_frames': validPoseFrames,
    'valid_trace_frames': validTraceFrames,
    'mean_shoulder_vis': totalFrames > 0 ? sumShVis / totalFrames : 0.0,
    'mean_hip_vis': totalFrames > 0 ? sumHpVis / totalFrames : 0.0,
    'mean_elbow_vis': totalFrames > 0 ? sumElVis / totalFrames : 0.0,
    'raw_regions_found': rawRegions.length,
    'merged_regions': mergedRegions.length,
    'duration_filtered': durFilteredRegions.length,
    'quality_regions': qualityRegions.length,
  };

  // ================ 6.5) Fallback for frontal-camera videos ================
  // If the torso-angle-based bent-region detection failed (frontal
  // camera, unstable pose, or never reached bent position), try to
  // detect reps from the bilateral elbow-shoulder average signal.
  // This signal is less affected by camera angle: regardless of where
  // the camera is, the elbows clearly rise toward the shoulders during
  // a real pull. Averaging both sides cancels out the L/R side-pick
  // jitter common in frontal videos.
  //
  // We synthesize a single "fallback region" covering the whole video
  // and the standard peak-detection pipeline below operates on it
  // using the bilateral signal instead of the side-specific one.
  bool usedFallback = false;
  // Build the bilateral signal up front - we'll use it as the primary
  // signal in fallback mode, OR keep for telemetry/logging in standard mode.
  final List<double?> elShAvgMA = [];
  {
    final int halfMA = MA_WINDOW_SIGNAL ~/ 2;
    for (int i = 0; i < elShAvgByFrame.length; i++) {
      final lo = math.max(0, i - halfMA);
      final hi = math.min(elShAvgByFrame.length - 1, i + halfMA);
      double sum = 0.0;
      int cnt = 0;
      for (int j = lo; j <= hi; j++) {
        final v = elShAvgByFrame[j];
        if (v != null) {
          sum += v;
          cnt += 1;
        }
      }
      elShAvgMA.add(cnt > 0 ? sum / cnt : null);
    }
  }

  if (qualityRegions.isEmpty) {
    // Check if the bilateral signal has enough range to suggest reps.
    double mn = double.infinity, mx = -double.infinity;
    int validCount = 0;
    for (final v in elShAvgMA) {
      if (v == null) continue;
      if (v < mn) mn = v;
      if (v > mx) mx = v;
      validCount++;
    }
    final double rng = (validCount > 0) ? mx - mn : 0.0;

    // Require enough data and motion to attempt fallback detection.
    // 0.025 is conservative: real reps in the bilateral signal show
    // 0.04-0.06 range. Lower than this is just noise.
    if (validCount >= 10 && rng >= 0.025) {
      usedFallback = true;
      qualityRegions.add([0, frameTelemetry.length - 1]);
    }
  }

  // If no surviving regions even after fallback: bail with a SPECIFIC
  // message describing why so we can debug from the UI without reading
  // debug fields.
  // [v5.4] But: if frontal-view detection found reps, skip this early
  // return (the standard pipeline will use frontalRepPeaks instead).
  if (qualityRegions.isEmpty &&
      !(detectedView == 'frontal' && frontalRepPeaks.isNotEmpty)) {
    final String fileUri = 'file://$videoPath';

    // Compute bilateral signal stats for diagnosis
    double biMin = double.infinity, biMax = -double.infinity;
    int biValidCount = 0;
    for (final v in elShAvgMA) {
      if (v == null) continue;
      if (v < biMin) biMin = v;
      if (v > biMax) biMax = v;
      biValidCount++;
    }
    final double biRange = biValidCount > 0 ? biMax - biMin : 0.0;

    // [v5.3] All-in-one diagnostic message that includes the actual
    // numbers. Format: "v5.3 | poseFrames=X/Y | torso=A..B° | bent=N
    // | bilat_range=R". Read this from the UI to see exactly what
    // happened.
    String diagnostic;
    if (validPoseFrames == 0) {
      diagnostic = 'No pose detected. v6.24 | poseFrames=0/$totalFrames';
    } else {
      // Find min/max torso angle to show what we saw
      double tMin = 999, tMax = -999;
      for (final v in torsoAngRawByFrame) {
        if (v == null) continue;
        if (v < tMin) tMin = v;
        if (v > tMax) tMax = v;
      }
      // Find best stability of any region we saw
      double bestJitter = -1;
      for (final r in debugRegions) {
        final j = (r['median_torso_jitter_deg'] as double?) ?? 999;
        if (j > 0 && (bestJitter < 0 || j < bestJitter)) bestJitter = j;
      }
      diagnostic = 'v6.24 | view=$detectedView | '
          'poseFrames=$validPoseFrames/$totalFrames | '
          'torso=${tMin.toStringAsFixed(0)}..${tMax.toStringAsFixed(0)}° | '
          'rawRegs=${rawRegions.length} | '
          'durOK=${durFilteredRegions.length} | '
          'qualOK=${qualityRegions.length} | '
          'jitter=${bestJitter.toStringAsFixed(1)}° | '
          'frontalPeaks=${frontalRepPeaks.length}';
    }

    return {
      'success': true,
      'squat_count': 0,
      'row_count': 0,
      'good_reps': 0,
      'bad_reps': 0,
      'technique_score': 0.0,
      'technique_score_display': '—',
      'technique_label': 'Could not analyze',
      'feedback': <String>[diagnostic],
      'tips': <String>[
        'Best angle: side-on at chest height, full body in frame',
      ],
      'form_tip': diagnostic,
      'tip': diagnostic,
      'reps': <dynamic>[],
      'rep_details': <dynamic>[],
      'exercise_type': 'bent_row',
      'video_path': fileUri,
      'analyzed_fps': fps,
      'frame_count': frameIdx,
      '_source_video_uri': fileUri,
      '_frame_telemetry': frameTelemetry,
      '_debug_regions': debugRegions,
      '_debug_summary': debugSummary,
    };
  }

  // ================ 6.5) [v6.6] Multi-signal voting rep detection ================
  // This is the new robust rep detection layer. It computes peaks in
  // FIVE independent signals and confirms a rep ONLY if the primary
  // anchor signal (el_minus_sh) AND at least one supporting signal
  // both have a peak in the same time window (±0.4s).
  //
  // Signals used:
  //   ANCHOR: el_minus_sh         = (sh.y - el.y) — elbow rises during pull
  //   SUPPORT: wr_minus_sh        = (sh.y - wr.y) — wrist rises during pull
  //   SUPPORT: wr_minus_hip       = (hip.y - wr.y) — wrist closer to hip
  //   SUPPORT: el_X_spread        = |lel.x - rel.x| — elbows widen at peak
  //   SUPPORT: shoulder_Y_neg     = -sh.y — shoulder rises slightly at peak
  //   SUPPORT (frontal): knee     = hip-knee-ankle angle
  //
  // We use ROBUST RANGE (10-90 percentile) instead of min/max to defend
  // against pose-estimation outliers that would otherwise inflate the
  // adaptive prominence threshold.
  //
  // We restrict peak detection to "ACTIVE" frames where the lifter is
  // in working position (torso < 65° for side, torso < 75° OR hip stable
  // for frontal). This kills false positives from pre-set walking around.
  // [v6.8] Track whether the global activity gate passed.
  // Used below to skip the legacy paths if no real activity is present.
  bool globalActivityGatePassed = true;

  // [v6.16] Diagnostic counters — populated inside the multi-signal voting
  // block and surfaced in form_tip so we can see exactly which filter
  // rejected each anchor peak (without needing telemetry export).
  int diagAnchorsTotal = 0; // peaks found by findSigPeaks on el_minus_sh
  int diagRejPull = 0; // rejected by Filter 1 (PULL %)
  int diagRejWidth = 0; // rejected by Filter 5 (peak width)
  int diagRejCoverage = 0; // rejected by Filter 2 (pose coverage)
  int diagRejJump = 0; // rejected by Filter 3 (frame jump)
  int diagRejSupporters = 0; // didn't get ≥1 supporter within ±0.4s
  int diagRejValley = 0; // rejected by valley descent check
  int diagPassedAll = 0; // passed all filters → in final multi list
  int diagMaxSup = 0; // [v6.17] max supporters seen across all anchor peaks
  int diagRejCadence = 0; // [v6.22] tier-1 peaks dropped because isolated
  // [v6.18] Per-PULL-rejection supporter counts. Lets us see whether the
  // rejected peaks had strong multi-signal agreement (high counts → real
  // weak reps we want to catch) or weak agreement (low counts → spurious).
  final List<int> diagRejPullSupporters = [];
  // [v6.19] Per-PULL-rejection timestamps and max-raw-PULL values. Crucial
  // for verifying which rejected peak is the missed middle rep (by time)
  // and whether the new max-raw discriminator tier picks it up.
  final List<double> diagRejPullTimes = []; // seconds
  final List<int> diagRejPullMaxRaw = []; // max raw PULL % in ±0.15s
  // [v6.20] Timestamps of ACCEPTED peaks. Without these I can only see
  // where rejections happen; with them I can locate reps 1 and 3 and
  // infer where the missed middle rep was supposed to occur.
  final List<double> diagAcceptedTimes = []; // seconds

  final List<int> multiSignalRepPeaks = [];
  {
    final int nFrames = frameTelemetry.length;
    final int halfMA = MA_WINDOW_SIGNAL ~/ 2;

    // [v6.8] GLOBAL ACTIVITY GATE — before doing any per-frame analysis,
    // reject videos that show no real exercise. Standing-still videos
    // and walking-around videos have very small el_minus_sh range
    // (< 0.030 over the whole video). Real exercises have range >= 0.05
    // typically, even short clips with one rep show 0.04+.
    //
    // We use a robust 10-90 percentile range on the raw el_minus_sh
    // signal to ignore single-frame pose-error spikes that would inflate
    // a min/max calculation.
    {
      final List<double> all = [];
      for (final v in elShAvgByFrame) {
        if (v != null) all.add(v);
      }
      if (all.length < 5) {
        // Not enough data — bail out (will fall through to side path
        // which has its own gates, or 0 reps if nothing passes).
      } else {
        final List<double> sorted = List<double>.from(all)..sort();
        final int sn = sorted.length;
        final double p10 = sorted[math.max(0, (sn * 0.10).floor())];
        final double p90 = sorted[math.min(sn - 1, (sn * 0.90).floor())];
        final double globalRange = p90 - p10;
        if (globalRange < 0.030) {
          // Whole video shows no meaningful pull motion → no reps.
          // Skip the entire multi-signal section.
          // (multiSignalRepPeaks stays empty; later code falls through
          // to legacy paths but those also won't find anything since
          // the signal is flat.)
          // We use a do/while construct via labeled scope below.
          // For Dart simplicity: just early-return from this block.
          // -> Achieved by short-circuiting all the work below.
          // We mark a flag to skip:
          // (Implemented as a guard below.)
        }
      }
    }

    // Re-compute global range as a guard for the inner work.
    bool _hasMeaningfulRange = true;
    {
      final List<double> all = [];
      for (final v in elShAvgByFrame) {
        if (v != null) all.add(v);
      }
      if (all.length < 5) {
        _hasMeaningfulRange = false;
      } else {
        final List<double> sorted = List<double>.from(all)..sort();
        final int sn = sorted.length;
        final double p10 = sorted[math.max(0, (sn * 0.10).floor())];
        final double p90 = sorted[math.min(sn - 1, (sn * 0.90).floor())];
        final double globalRange = p90 - p10;
        if (globalRange < 0.030) _hasMeaningfulRange = false;
      }
    }
    if (!_hasMeaningfulRange) {
      // Whole video too flat — exit multi-signal block, no reps.
      // multiSignalRepPeaks remains empty.
      globalActivityGatePassed = false;
    } else if (detectedView == 'side') {
      // [v6.8+] SIDE-VIEW BENT GATE: in side view we can reliably measure
      // torso angle. If the lifter spends most of the video standing
      // upright (torso > 60°), they are NOT doing a bent-over row,
      // regardless of how much arm motion the signal shows.
      //
      // Real bent-row videos: 70-100% of frames have torso < 60°
      // Standing/walking videos: typically <30% of frames are bent
      //
      // Threshold: require >=40% bent. This protects against people
      // standing upright moving arms around (curls, presses, etc).
      // We do NOT apply this to frontal view because the projected
      // torso angle is unreliable when the camera looks straight on.
      final List<double> bentMeasures = [];
      for (final v in torsoAngRawByFrame) {
        if (v != null) bentMeasures.add(v);
      }
      if (bentMeasures.isEmpty) {
        globalActivityGatePassed = false;
      } else {
        int bentCount = 0;
        for (final t in bentMeasures) {
          if (t < 60.0) bentCount++;
        }
        final double bentPct = bentCount / bentMeasures.length;
        if (bentPct < 0.40) {
          globalActivityGatePassed = false;
        }
      }
      // If we still passed, fall through to the inner multi-signal logic
      // below (the original `else` branch).
    }
    if (globalActivityGatePassed) {
      // Build active mask
      final List<bool> activeMask = List<bool>.filled(nFrames, false);
      if (detectedView == 'side') {
        for (int i = 0; i < nFrames; i++) {
          final v = (i < torsoSmooth.length) ? torsoSmooth[i] : null;
          if (v != null && v < 65.0) activeMask[i] = true;
        }
      } else {
        // Frontal: torso < 75° OR hip stable in 0.5s window
        final int win = math.max(3, (fps * 0.5).round());
        for (int i = 0; i < nFrames; i++) {
          final v = (i < torsoSmooth.length) ? torsoSmooth[i] : null;
          if (v != null && v < 75.0) {
            activeMask[i] = true;
            continue;
          }
          if (i >= win) {
            final List<double> sub = [];
            for (int j = i - win; j < i; j++) {
              final h = hipYAvgByFrame[j];
              if (h != null) sub.add(h);
            }
            if (sub.length >= win ~/ 2) {
              double mn = sub[0], mx = sub[0];
              for (final x in sub) {
                if (x < mn) mn = x;
                if (x > mx) mx = x;
              }
              if (mx - mn < 0.04) activeMask[i] = true;
            }
          }
        }
      }

      // Helper: smooth an array with MA(5)
      List<double?> smoothMA(List<double?> src) {
        final out = <double?>[];
        for (int i = 0; i < nFrames; i++) {
          final lo = math.max(0, i - halfMA);
          final hi = math.min(nFrames - 1, i + halfMA);
          double sum = 0;
          int cnt = 0;
          for (int j = lo; j <= hi; j++) {
            final v = (j < src.length) ? src[j] : null;
            if (v != null) {
              sum += v;
              cnt++;
            }
          }
          out.add(cnt > 0 ? sum / cnt : null);
        }
        return out;
      }

      // Compute the secondary signals (using bilateral averages we computed earlier)
      final List<double?> elMinusSh =
          elShAvgByFrame; // already (sh.y - el.y) bilateral
      // wr_minus_sh: shoulderYAvg - wristYAvg
      final List<double?> wrMinusSh = List<double?>.generate(nFrames, (i) {
        final s = shoulderYAvgByFrame[i];
        final w = wristYAvgByFrame[i];
        if (s == null || w == null) return null;
        return s - w;
      });
      // wr_minus_hip: hipYAvg - wristYAvg
      final List<double?> wrMinusHip = List<double?>.generate(nFrames, (i) {
        final h = hipYAvgByFrame[i];
        final w = wristYAvgByFrame[i];
        if (h == null || w == null) return null;
        return h - w;
      });
      // el_X_spread already computed
      final List<double?> elXSpread = elbowXSpreadByFrame;
      // -shoulderY (peaks = highest shoulder)
      final List<double?> shoulderYNeg = List<double?>.generate(nFrames, (i) {
        final s = shoulderYAvgByFrame[i];
        return s == null ? null : -s;
      });
      // For frontal, also use knee
      final List<double?> kneeAng = hipKneeAngByFrame;

      // Smooth all signals
      final List<double?> elMinusShMA = smoothMA(elMinusSh);
      final List<double?> wrMinusShMA = smoothMA(wrMinusSh);
      final List<double?> wrMinusHipMA = smoothMA(wrMinusHip);
      final List<double?> elXSpreadMA = smoothMA(elXSpread);
      final List<double?> shoulderYNegMA = smoothMA(shoulderYNeg);
      final List<double?> kneeMA = smoothMA(kneeAng);

      // Apply active mask
      List<double?> applyMask(List<double?> src) {
        return List<double?>.generate(
            nFrames, (i) => activeMask[i] ? src[i] : null);
      }

      final Map<String, List<double?>> signals = {
        'el_minus_sh': applyMask(elMinusShMA),
        'wr_minus_sh': applyMask(wrMinusShMA),
        'wr_minus_hip': applyMask(wrMinusHipMA),
        'el_X_spread': applyMask(elXSpreadMA),
        'shoulderY_neg': applyMask(shoulderYNegMA),
      };
      if (detectedView == 'frontal') {
        signals['knee'] = applyMask(kneeMA);
      }

      // Per-signal min range thresholds
      final Map<String, double> minRanges = {
        'el_minus_sh': 0.025,
        'wr_minus_sh': 0.025,
        'wr_minus_hip': 0.025,
        'el_X_spread': 0.030,
        'shoulderY_neg': 0.012,
        'knee': 8.0,
      };

      // Robust range using 10-90 percentile
      double robustRange(List<double> arr) {
        if (arr.isEmpty) return 0;
        final sorted = List<double>.from(arr)..sort();
        final n = sorted.length;
        final p10 = sorted[math.max(0, (n * 0.10).floor())];
        final p90 = sorted[math.min(n - 1, (n * 0.90).floor())];
        return p90 - p10;
      }

      // Find peaks in a single signal; returns frame indices
      List<int> findSigPeaks(String name, List<double?> vals) {
        final List<double> arr = [];
        final List<int> idx = [];
        for (int i = 0; i < vals.length; i++) {
          final v = vals[i];
          if (v != null) {
            arr.add(v);
            idx.add(i);
          }
        }
        if (arr.length < 5) return [];

        final double rng = robustRange(arr);
        final double minRng = minRanges[name] ?? 0.025;
        if (rng < minRng) return [];

        // Adaptive prominence: 30% of robust range, with floor
        // [v6.20] Lowered floor from 0.012 to 0.008. Real but subtle reps
        // (middle of a fatiguing set) may produce peaks with prominence in
        // the 0.008-0.012 range that were previously rejected as non-peaks
        // before any filter ran. With 0.008 they now appear in anchorPeaks
        // and face the v6.19 3-tier graduated check.
        final double promFloor = (name == 'knee') ? 4.0 : 0.008;
        final double promFrac = 0.30;
        final double promThr = math.max(promFloor, promFrac * rng);

        // min distance: 0.5s for knee (slow), 0.4s for others
        final int minDist =
            math.max(2, ((name == 'knee' ? 0.5 : 0.4) * fps).round());

        // Local maxima
        final List<int> candidates = [];
        for (int k = 1; k < arr.length - 1; k++) {
          if (arr[k] > arr[k - 1] && arr[k] >= arr[k + 1]) {
            candidates.add(k);
          } else if (arr[k] >= arr[k - 1] && arr[k] > arr[k + 1]) {
            candidates.add(k);
          }
        }

        // Prominence filter
        final List<int> kept = [];
        final List<double> keptProms = [];
        for (final c in candidates) {
          final double cv = arr[c];
          double leftMin = cv;
          for (int k = c - 1; k >= 0; k--) {
            if (arr[k] > cv) break;
            if (arr[k] < leftMin) leftMin = arr[k];
          }
          double rightMin = cv;
          for (int k = c + 1; k < arr.length; k++) {
            if (arr[k] > cv) break;
            if (arr[k] < rightMin) rightMin = arr[k];
          }
          final double base = math.max(leftMin, rightMin);
          final double prom = cv - base;
          if (prom >= promThr) {
            kept.add(c);
            keptProms.add(prom);
          }
        }

        // Min-distance filter (greedy, highest prominence first)
        final List<int> order = List<int>.generate(kept.length, (k) => k)
          ..sort((a, b) => keptProms[b].compareTo(keptProms[a]));
        final List<bool> alive = List<bool>.filled(kept.length, true);
        for (final ki in order) {
          if (!alive[ki]) continue;
          final int kIdx = idx[kept[ki]];
          for (int kj = 0; kj < kept.length; kj++) {
            if (kj == ki || !alive[kj]) continue;
            final int kjIdx = idx[kept[kj]];
            if ((kjIdx - kIdx).abs() < minDist) alive[kj] = false;
          }
        }

        final List<int> result = [];
        for (int k = 0; k < kept.length; k++) {
          if (alive[k]) result.add(idx[kept[k]]);
        }
        result.sort();
        return result;
      }

      // Compute peaks per signal
      final Map<String, List<int>> peaksPer = {};
      for (final entry in signals.entries) {
        peaksPer[entry.key] = findSigPeaks(entry.key, entry.value);
      }

      // Anchor-based confirmation:
      // - Use el_minus_sh peaks as anchors
      // - For each anchor, count how many OTHER signals have a peak within ±0.4s
      // - Confirm if anchor + at least 1 supporter
      //
      // [v6.7+] ANTI-FALSE-POSITIVE FILTERS — reject anchor peaks that look
      // like noise rather than real reps. The filters below are:
      //
      //   1. MIN PULL PERCENTAGE: a real bent-row peak shows the elbow
      //      lifted clearly above the shoulder. The PULL formula maps
      //      el_minus_sh in [-0.08, -0.01] → [0%, 100%]. Real reps hit
      //      55-100% PULL at peak. Walking/setup-noise spikes stay below 40%.
      //
      //   2. LOCAL POSE COVERAGE: real reps have continuous pose detection
      //      around the peak. Pose-error spikes (camera zoom, partial body)
      //      have many missing frames in the same window. Require 70%+
      //      of frames within ±0.5s to have a detected pose.
      //
      //   3. ANTI-SPIKE JUMP: real reps have smooth gradual motion (~0.005-0.015
      //      per-frame change in el_minus_sh). Pose errors produce single-frame
      //      jumps of 0.10+. We reject any anchor whose ±0.3s window contains
      //      a frame-to-frame jump > 0.05.
      //
      //   4. [v6.12] FILTER REMOVED. v6.10 had MAX_PEAK_VAL +
      //      MAX_SATURATED_FRAMES here to reject "saturated peaks", v6.11
      //      replaced those with a knee-bent check. Both turned out to
      //      reject too many legitimate reps on real ML Kit data, so v6.12
      //      drops the filter entirely. The "saturated peak that's actually
      //      pose error" case is now unhandled — see top-of-file note for
      //      the reasoning.
      //
      //   5. PEAK WIDTH: a real rep peak takes ~0.4-1.5 seconds —
      //      pull up, brief hold, lower. Pose-error spikes are very narrow
      //      (<0.30s); sustained gestures are wide (>2.5s). Reject peaks
      //      outside this range.
      final List<int> anchorPeaks = peaksPer['el_minus_sh'] ?? [];
      final int confirmWindow = (0.4 * fps).round();
      // [v6.16] Diagnostic: record the count of anchor candidates before
      // any per-peak filtering.
      diagAnchorsTotal = anchorPeaks.length;

      // Tunable thresholds for the anti-FP filters
      // [v6.13/v6.15] PULL threshold is view-dependent (projection geometry
      // halves the signal amplitude in frontal view vs side). [v6.15] also
      // accounts for MA(5) smoothing diluting narrow peaks in frontal
      // (where ML Kit's quick tracker response makes peaks narrower than
      // MediaPipe's broader peaks). See top-of-file note.
      const double MIN_PULL_PCT_SIDE = 0.50;
      const double MIN_PULL_PCT_FRONTAL = 0.20;
      final double minPullPct = (detectedView == 'frontal')
          ? MIN_PULL_PCT_FRONTAL
          : MIN_PULL_PCT_SIDE;
      // [v6.12] The v6.11 knee-bent check has been REMOVED. See top-of-file
      // comment for the FN-regression that motivated this. There is now no
      // dedicated filter for the "saturated peak that's actually pose error"
      // case (which v6.10 handled with MAX_PEAK_VAL/MAX_SATURATED_FRAMES,
      // and v6.11 tried to handle with the knee check). Both attempts had
      // bigger FN cost than benefit, so we drop the filter for now and lean
      // on coverage / frame-jump / valley-descent for noise rejection.

      const double MIN_POSE_COVERAGE = 0.70; // ±0.5s window needs 70%+ poses
      const double MAX_FRAME_JUMP = 0.05; // largest allowed per-frame jump
      const double MIN_PEAK_WIDTH_SEC = 0.30; // peak too narrow = spike
      const double MAX_PEAK_WIDTH_SEC =
          2.50; // peak too wide = sustained, not a rep

      final int coverageWin = (0.5 * fps).round();
      final int jumpWin = (0.3 * fps).round();

      // Build a non-null subset of elMinusShMA for width computation
      final List<double> elArr = [];
      final List<int> elArrIdx = [];
      for (int i = 0; i < elMinusShMA.length; i++) {
        final v = elMinusShMA[i];
        if (v != null) {
          elArr.add(v);
          elArrIdx.add(i);
        }
      }

      final List<List<dynamic>> confirmed = [];
      for (final ap in anchorPeaks) {
        // [v6.17] Compute supporters FIRST. Required for the graduated PULL
        // threshold below — a peak with strong multi-signal agreement gets
        // a lower PULL bar than a lone anchor peak.
        final Set<String> supporters = {'el_minus_sh'};
        for (final entry in peaksPer.entries) {
          if (entry.key == 'el_minus_sh') continue;
          for (final p in entry.value) {
            if ((p - ap).abs() <= confirmWindow) {
              supporters.add(entry.key);
              break;
            }
          }
        }
        // Track max for diagnostics
        if (supporters.length > diagMaxSup) diagMaxSup = supporters.length;

        // ---- Filter 1: PULL percentage at peak (3-tier graduated) ----
        // [v6.19] Three-tier graduated threshold:
        //   Tier 1: max-raw-PULL ≥ 0.20 in ±0.15s AND sup ≥ 3
        //           → smoothed PULL ≥ 0.05 (sharp narrow peak + multi-signal
        //              agreement = real but narrow rep that MA(5) dilutes)
        //   Tier 2: sup ≥ 3
        //           → smoothed PULL ≥ 0.10 (multi-signal agreement only)
        //   Tier 3: otherwise → smoothed PULL ≥ minPullPct (strict)
        //
        // Physical reasoning: a real bent-row rep produces a SHARP NARROW
        // peak in the raw el_minus_sh signal (the bar reaches top, briefly
        // pauses, then descends). MA(5) smoothing averages this peak with
        // surrounding low frames, diluting it to ~half amplitude. But the
        // raw peak still hits 20%+ PULL momentarily. Spurious body motion
        // doesn't show this sharp signature — its raw values stay low.
        // Combined with the supporter count, this distinguishes real
        // narrow reps from spurious peaks at the same smoothed-PULL level.
        final double? smoothedEl =
            (ap < elMinusShMA.length) ? elMinusShMA[ap] : null;
        if (smoothedEl == null) continue;
        final double pullPct = ((smoothedEl + 0.08) / 0.07).clamp(0.0, 1.0);

        // Compute max RAW PULL in ±0.15s window around the smoothed peak.
        final int rawWin = math.max(1, (0.15 * fps).round());
        double maxRawPull = 0.0;
        final int rwLo = math.max(0, ap - rawWin);
        final int rwHi = math.min(nFrames - 1, ap + rawWin);
        for (int k = rwLo; k <= rwHi; k++) {
          final v = (k < elShAvgByFrame.length) ? elShAvgByFrame[k] : null;
          if (v == null) continue;
          final double rawPull = ((v + 0.08) / 0.07).clamp(0.0, 1.0);
          if (rawPull > maxRawPull) maxRawPull = rawPull;
        }

        // Choose threshold by tier.
        // [v6.21] Lowered tier-1 max-raw threshold from 0.20 to 0.10. Real
        // subtle reps (middle of a fatiguing set) have raw peaks as low as
        // 10-15% — diagnostic data showed exactly such a missed middle rep
        // at max-raw=12%. Spurious noise peaks have max-raw at or below 0
        // (below baseline), so 0.10 cleanly separates real-but-subtle from
        // noise.
        // [v6.22] Track which tier this peak passed in so we can apply
        // the cadence check to tier-1 peaks after validation.
        double effectiveMinPull;
        int peakTierVal;
        if (maxRawPull >= 0.10 && supporters.length >= 3) {
          effectiveMinPull = 0.05; // Tier 1: sharp peak + agreement
          peakTierVal = 1;
        } else if (supporters.length >= 3) {
          effectiveMinPull = 0.10; // Tier 2: agreement only
          peakTierVal = 2;
        } else {
          effectiveMinPull = minPullPct; // Tier 3: strict
          peakTierVal = 3;
        }
        if (pullPct < effectiveMinPull) {
          diagRejPull++; // [v6.16] count PULL rejections
          diagRejPullSupporters.add(supporters.length); // [v6.18]
          // [v6.19] also record timestamp and max-raw for forensics
          diagRejPullTimes.add(ap / fps);
          diagRejPullMaxRaw.add((maxRawPull * 100).round());
          continue;
        }

        // ---- [v6.12] Knee-bent filter removed (was Filter 4 in v6.11) ----
        // The knee threshold of 172° was found to be too tight on real ML
        // Kit data. Several legitimate bent-row peaks had knee_median in
        // the 170-175° range and got rejected. See top-of-file note.

        // ---- Filter 5: peak width at half-prominence ----
        // A real rep peak takes ~0.4-1.5 seconds to rise, hold, and fall.
        // Spikes from pose errors are <0.30s wide; sustained gestures are
        // >2.5s. Reject anything outside [0.30, 2.50] seconds.
        // Locate this peak's index inside elArr (the non-null subset).
        int apInArr = -1;
        for (int k = 0; k < elArrIdx.length; k++) {
          if (elArrIdx[k] == ap) {
            apInArr = k;
            break;
          }
        }
        if (apInArr < 0) continue;
        // Find prominence (left/right minima up to where signal exceeds peak)
        final double pkv = elArr[apInArr];
        double leftMin = pkv;
        for (int k = apInArr - 1; k >= 0; k--) {
          if (elArr[k] > pkv) break;
          if (elArr[k] < leftMin) leftMin = elArr[k];
        }
        double rightMin = pkv;
        for (int k = apInArr + 1; k < elArr.length; k++) {
          if (elArr[k] > pkv) break;
          if (elArr[k] < rightMin) rightMin = elArr[k];
        }
        final double prom = pkv - math.max(leftMin, rightMin);
        if (prom <= 0) continue;
        final double halfHeight = pkv - prom * 0.5;
        // Find left edge: where signal first drops below half_height going left
        int leftEdge = apInArr;
        for (int k = apInArr; k >= 0; k--) {
          if (elArr[k] <= halfHeight) {
            leftEdge = k;
            break;
          }
        }
        int rightEdge = apInArr;
        for (int k = apInArr; k < elArr.length; k++) {
          if (elArr[k] <= halfHeight) {
            rightEdge = k;
            break;
          }
        }
        final int widthFrames = rightEdge - leftEdge;
        final double widthSec = widthFrames / fps;
        if (widthSec < MIN_PEAK_WIDTH_SEC || widthSec > MAX_PEAK_WIDTH_SEC) {
          diagRejWidth++; // [v6.16] count width rejections
          continue;
        }

        // ---- Filter 2: local pose coverage ----
        final int covLo = math.max(0, ap - coverageWin);
        final int covHi = math.min(nFrames - 1, ap + coverageWin);
        final int winSize = covHi - covLo + 1;
        int poseCount = 0;
        for (int k = covLo; k <= covHi; k++) {
          // A frame "has pose" if its el_minus_sh raw value is non-null
          // (this proxies for MediaPipe finding shoulder + elbow with good visibility)
          if (k < elMinusSh.length && elMinusSh[k] != null) poseCount++;
        }
        final double coverage = winSize > 0 ? poseCount / winSize : 0.0;
        if (coverage < MIN_POSE_COVERAGE) {
          diagRejCoverage++; // [v6.16] count coverage rejections
          continue;
        }

        // ---- Filter 3: anti-spike (no huge frame-to-frame jumps) ----
        // Check both consecutive frames AND nearby valid values (skipping
        // None gaps up to 3 frames). This catches pose-error "ringing" where
        // the value oscillates between two extremes but None values between
        // them mask the consecutive jump.
        double maxJump = 0.0;
        final int jLo = math.max(1, ap - jumpWin);
        final int jHi = math.min(nFrames - 1, ap + jumpWin);
        // Consecutive
        for (int k = jLo; k <= jHi; k++) {
          final v0 = elMinusSh[k - 1];
          final v1 = elMinusSh[k];
          if (v0 != null && v1 != null) {
            final double d = (v1 - v0).abs();
            if (d > maxJump) maxJump = d;
          }
        }
        // Nearby (within 3-frame gap)
        final List<List<double>> validInWin = []; // [frameIdx, value]
        for (int k = math.max(0, ap - jumpWin);
            k <= math.min(nFrames - 1, ap + jumpWin);
            k++) {
          final v = elMinusSh[k];
          if (v != null) validInWin.add([k.toDouble(), v]);
        }
        for (int i = 0; i < validInWin.length; i++) {
          for (int j = i + 1; j < validInWin.length; j++) {
            if (validInWin[j][0] - validInWin[i][0] > 3) break;
            final double d = (validInWin[j][1] - validInWin[i][1]).abs();
            if (d > maxJump) maxJump = d;
          }
        }
        if (maxJump > MAX_FRAME_JUMP) {
          diagRejJump++; // [v6.16] count frame-jump rejections
          continue;
        }

        // ---- [v6.17] Supporters already computed at top of loop ----
        // Final check: need at least anchor + 1 supporter (length >= 2).
        if (supporters.length >= 2) {
          // [v6.22] also include the tier so the post-validation cadence
          // check can find tier-1 peaks specifically.
          confirmed.add([ap, supporters.length, peakTierVal]);
        } else {
          diagRejSupporters++; // [v6.16] count supporter-deficit rejections
        }
      }

      // Dedup nearby anchors (< 0.5s apart) — keep one with more supporters
      confirmed.sort((a, b) => (a[0] as int).compareTo(b[0] as int));
      final List<List<dynamic>> dedup = [];
      final int minRepDist = (0.5 * fps).round();
      for (final c in confirmed) {
        if (dedup.isNotEmpty &&
            ((c[0] as int) - (dedup.last[0] as int)) < minRepDist) {
          if ((c[1] as int) > (dedup.last[1] as int)) {
            dedup[dedup.length - 1] = c;
          }
        } else {
          dedup.add(c);
        }
      }

      // [v6.11/v6.12/v6.13/v6.14] VALLEY DESCENT CHECK — between two
      // accepted reps, the signal must "release" between the peaks. We
      // accept the release as valid if EITHER:
      //   (a) the signal drops by minValleyDescent below the lower peak
      //       (relative-descent test, catches sub-peaks within a strong
      //       pull whose troughs stay high), OR
      //   (b) the signal reaches BASELINE_FLOOR — the natural el_minus_sh
      //       baseline where the lifter's arms are fully extended down
      //       (PULL ≈ 28%). This is the absolute "did the wrist come back
      //       to rest" test.
      //
      // [v6.14] Added (b) because (a) alone fails when the LOWER of two
      // peaks is itself a weak pull (low PULL). In that case (a)'s
      // requiredValley becomes more negative than the physical floor of
      // the signal (around -0.080), so even a full release between reps
      // can't satisfy it. The cap to BASELINE_FLOOR fixes this.
      //
      // [v6.13] View-dependent descent: 0.030 for side, 0.020 for frontal
      // (frontal-view amplitudes are ~half of side-view, so the descent
      // we require for (a) should also be ~half).
      const double MIN_VALLEY_DESCENT_SIDE = 0.030;
      const double MIN_VALLEY_DESCENT_FRONTAL = 0.020;
      final double minValleyDescent = (detectedView == 'frontal')
          ? MIN_VALLEY_DESCENT_FRONTAL
          : MIN_VALLEY_DESCENT_SIDE;
      // [v6.14] BASELINE_FLOOR for valley check (b).
      // -0.060 corresponds to PULL ≈ 28%, well above the saturation floor
      // (PULL=0% at el ≤ -0.080) but well below typical peak values. A
      // valley reaching this level means the lifter clearly returned to
      // near-rest position between the two peaks. Sub-peak noise within
      // a strong pull stays at PULL 50%+ (el ≥ -0.045), so doesn't pass.
      const double BASELINE_FLOOR = -0.060;
      final List<List<dynamic>> validated = [];
      for (int vi = 0; vi < dedup.length; vi++) {
        if (validated.isEmpty) {
          validated.add(dedup[vi]);
          continue;
        }
        final int prevIdx = validated.last[0] as int;
        final int curIdx = dedup[vi][0] as int;
        final double? prevVal =
            (prevIdx < elMinusShMA.length) ? elMinusShMA[prevIdx] : null;
        final double? curVal =
            (curIdx < elMinusShMA.length) ? elMinusShMA[curIdx] : null;
        if (prevVal == null || curVal == null) {
          // Be defensive: if we can't measure either peak's value, accept.
          validated.add(dedup[vi]);
          continue;
        }
        final double lowerPeak = math.min(prevVal, curVal);
        // [v6.14] Cap requiredValley at BASELINE_FLOOR. The valley check
        // passes if EITHER (a) drop by minValleyDescent below lowerPeak,
        // OR (b) reach BASELINE_FLOOR. The less negative of the two values
        // is the easier-to-satisfy threshold.
        final double requiredValley =
            math.max(lowerPeak - minValleyDescent, BASELINE_FLOOR);
        // Find the minimum value of the smoothed signal between the two peaks.
        double valleyMin = double.infinity;
        for (int k = prevIdx + 1; k < curIdx; k++) {
          final v = (k < elMinusShMA.length) ? elMinusShMA[k] : null;
          if (v != null && v < valleyMin) valleyMin = v;
        }
        if (valleyMin <= requiredValley) {
          // Real release between the peaks — count this as a separate rep.
          validated.add(dedup[vi]);
        } else {
          // No real descent — same rep, keep the peak with more supporters.
          diagRejValley++; // [v6.16] count valley-merge rejections
          if ((dedup[vi][1] as int) > (validated.last[1] as int)) {
            validated[validated.length - 1] = dedup[vi];
          }
        }
      }

      // [v6.24] SINGLE-PEAK CADENCE CHECK (simplified from v6.22/v6.23).
      //
      // The v6.22/v6.23 rule "tier-1 peak needs a neighbor within ±5s" was
      // too aggressive. It worked by FP/FN trade-off in theory, but in
      // practice it rejected legitimate first reps in multi-rep sets where:
      //   • the first rep happens to be tier-1 (lifter careful on first rep
      //     → low max-raw amplitude, but still a real rep), AND
      //   • the gap to rep 2 exceeds 5s (deliberate setup pause before
      //     starting the rhythm).
      //
      // The real discriminator isn't "is this peak isolated in time" but
      // "is this peak the ONLY peak in the entire video". A 3+ rep set is
      // a real set regardless of how the cadences are spaced; a tier-1
      // peak inside it is part of a real exercise. A LONE tier-1 peak in
      // an otherwise empty video is the FP signature (single noise peak
      // from pose-tracker noise + nothing else).
      //
      // All current FP videos fall under the lone-peak case:
      //   • 4.9s standing video: multi-signal returns 0 or 1 peak.
      //   • Camera-setup chaos + standing: 1 peak via fallback (now also
      //     PULL-checked by v6.23).
      //   • Approach phase: 1 isolated peak.
      // So the simpler "reject ONLY a lone tier-1 peak" rule still catches
      // every observed FP scenario while rescuing legitimate first reps.
      final List<List<dynamic>> filteredValidated = [];
      if (validated.length == 1) {
        final v = validated[0];
        final int tier = (v.length >= 3) ? (v[2] as int) : 3;
        if (tier == 1) {
          // Lone tier-1 peak: likely an isolated FP. Reject.
          diagRejCadence++;
        } else {
          // Lone tier-2/3 peak: strong single rep. Keep.
          filteredValidated.add(v);
        }
      } else {
        // 2+ peaks: real set, all kept regardless of tier or spacing.
        filteredValidated.addAll(validated);
      }

      for (final c in filteredValidated) {
        multiSignalRepPeaks.add(c[0] as int);
      }
      diagPassedAll = filteredValidated.length; // [v6.16]
      // [v6.20] Record timestamps of accepted peaks so we can see in
      // form_tip where exactly the algorithm placed reps 1 and 3, and
      // infer where the missed middle rep was supposed to be.
      for (final p in multiSignalRepPeaks) {
        diagAcceptedTimes.add(p / fps);
      }
    } // end of if (globalActivityGatePassed)
  }

  // Each peak in elShMA = one rep.
  // We use a simple local-maximum + prominence test (we don't have
  // scipy here; the implementation below mimics scipy.signal.find_peaks
  // for the prominence parameter).
  //
  // Prominence of a peak P:
  //   - look LEFT until you go below P or hit the boundary
  //   - look RIGHT until you go below P or hit the boundary
  //   - take the highest minimum on each side; prominence = peak - max(min_left, min_right)
  final int minPeakDistanceFrames =
      math.max(2, (MIN_PEAK_DISTANCE_SEC * fps).round());

  final List<Map<String, dynamic>> repEvents = [];
  // Each repEvent: {peakIdx, regionStartIdx, regionEndIdx, regionPullStart, regionPullEnd, pullHeightPct}

  // [v6.6] PRIMARY PATH: Use multi-signal voting result if available.
  // This works for BOTH side and frontal views. The voting algorithm
  // is more robust than single-signal detection.
  //
  // [v6.8] If the global activity gate FAILED (video too flat to be a
  // real exercise), skip ALL detection paths. This prevents the legacy
  // side/frontal paths from finding false-positive reps in standing-still
  // videos.
  if (!globalActivityGatePassed) {
    // No reps. repEvents stays empty.
  } else if (multiSignalRepPeaks.isNotEmpty) {
    final List<int> peaks = List<int>.from(multiSignalRepPeaks)..sort();
    for (int pi = 0; pi < peaks.length; pi++) {
      final int peakIdx = peaks[pi];
      int startIdx;
      int endIdx;
      if (pi == 0) {
        startIdx = math.max(0, peakIdx - (fps * 1.0).round());
      } else {
        startIdx = ((peaks[pi - 1] + peakIdx) / 2).floor();
      }
      if (pi == peaks.length - 1) {
        endIdx =
            math.min(frameTelemetry.length - 1, peakIdx + (fps * 1.0).round());
      } else {
        endIdx = ((peakIdx + peaks[pi + 1]) / 2).floor();
      }

      // Compute pull height percentage from elShAvg trace around peak
      double pullHeightPct = 0.7;
      final double? peakV =
          (peakIdx < elShAvgByFrame.length) ? elShAvgByFrame[peakIdx] : null;
      if (peakV != null) {
        // Find min/max in window around peak for normalization
        double mn = peakV, mx = peakV;
        for (int k = startIdx; k <= endIdx; k++) {
          final v = elShAvgByFrame[k];
          if (v != null) {
            if (v < mn) mn = v;
            if (v > mx) mx = v;
          }
        }
        if (mx > mn) {
          pullHeightPct = ((peakV - mn) / (mx - mn)).clamp(0.0, 1.0);
        }
      }

      repEvents.add({
        'peakIdx': peakIdx,
        'startIdx': startIdx,
        'endIdx': endIdx,
        'pullHeightPct': pullHeightPct,
      });
    }
  } else if (detectedView == 'frontal' &&
      frontalRepPeaks.isNotEmpty &&
      diagRejCadence == 0) {
    // [v6.23] Three conditions to enter the frontal-only fallback:
    //   1. View is frontal.
    //   2. The fallback's stable-stance peak finder produced peaks.
    //   3. The multi-signal block did NOT reject any peaks via the cadence
    //      check. If it did, those rejections represent an active "this is
    //      not a real rep" decision — we should NOT then look elsewhere
    //      for a different peak. Falling back in that case lets path-2
    //      pick up an unrelated noise oscillation (e.g., a tiny knee twitch
    //      while the lifter just stands), giving a FP rep at a frame
    //      where PULL is 0%.
    for (int pi = 0; pi < frontalRepPeaks.length; pi++) {
      final int peakIdx = frontalRepPeaks[pi];

      // [v6.23] PULL CONSISTENCY CHECK. The PULL gauge drives the user's
      // mental model — if it's at 0%, no rep should be counted. The frontal
      // fallback uses knee/shoulderY signals, which can show motion that
      // isn't a bent-row pull. Require the bilateral elbow-vs-shoulder
      // signal (the source of the PULL gauge) to also show pull at this
      // frame.
      final double? peakElForCheck =
          (peakIdx < elShAvgByFrame.length) ? elShAvgByFrame[peakIdx] : null;
      if (peakElForCheck == null) continue;
      final double peakPull = ((peakElForCheck + 0.08) / 0.07).clamp(0.0, 1.0);
      if (peakPull < 0.10) continue;

      // Synthesize start/end as halfway to neighboring peaks
      int startIdx;
      int endIdx;
      if (pi == 0) {
        startIdx = math.max(0, peakIdx - (fps * 1.0).round());
      } else {
        startIdx = ((frontalRepPeaks[pi - 1] + peakIdx) / 2).floor();
      }
      if (pi == frontalRepPeaks.length - 1) {
        endIdx =
            math.min(frameTelemetry.length - 1, peakIdx + (fps * 1.0).round());
      } else {
        endIdx = ((peakIdx + frontalRepPeaks[pi + 1]) / 2).floor();
      }
      repEvents.add({
        'peakIdx': peakIdx,
        'startIdx': startIdx,
        'endIdx': endIdx,
        'pullHeightPct': peakPull, // [v6.23] use actual PULL, not synthetic
      });
    }
  } else {
    // SIDE-view (original) rep-detection loop:
    for (final r in qualityRegions) {
      final int s = r[0];
      final int e = r[1];

      // [v5.3] In fallback mode, use the bilateral average signal
      // instead of the side-specific one.
      final List<double?> sigSrc = usedFallback ? elShAvgMA : elShMA;

      // Collect non-null sub-trace
      final List<double> subV = [];
      final List<int> subIdx = [];
      for (int k = s; k <= e; k++) {
        final v = sigSrc[k];
        if (v != null) {
          subV.add(v);
          subIdx.add(k);
        }
      }
      if (subV.length < 5) continue;

      // Range
      double mn = subV[0], mx = subV[0];
      for (final v in subV) {
        if (v < mn) mn = v;
        if (v > mx) mx = v;
      }
      final double rng = mx - mn;
      // [v5.3] In fallback mode (frontal video), range threshold is
      // 0.025 (we've already screened for this in the fallback gate);
      // in standard mode use the regular threshold.
      final double effectiveMinRange = usedFallback ? 0.025 : MIN_REGION_RANGE;
      if (rng < effectiveMinRange) {
        // Not real reps - skip (e.g. hold position)
        continue;
      }

      final double promThr = math.max(PROM_FLOOR, PROM_FRACTION_OF_RANGE * rng);

      // Find candidate local maxima.
      // [v5.3] Include boundary indices (k=0 and k=length-1) as candidates.
      // Why: the first rep often happens just as the lifter enters the
      // bent-over phase, so the rep's peak can land at index 0 or 1
      // of the region's sub-trace. The old loop `for k=1; k<length-1`
      // skipped both ends, dropping the first rep entirely.
      // We treat boundary points as peaks if they are >= the next/prev
      // neighbor (one-sided comparison).
      final List<int> candidates = [];
      if (subV.length >= 2) {
        // Left boundary: peak if subV[0] > subV[1]
        if (subV[0] > subV[1]) candidates.add(0);
      }
      for (int k = 1; k < subV.length - 1; k++) {
        if (subV[k] > subV[k - 1] && subV[k] >= subV[k + 1]) {
          candidates.add(k);
        } else if (subV[k] >= subV[k - 1] && subV[k] > subV[k + 1]) {
          candidates.add(k);
        }
      }
      if (subV.length >= 2) {
        // Right boundary: peak if subV[last] > subV[last-1]
        final int last = subV.length - 1;
        if (subV[last] > subV[last - 1]) candidates.add(last);
      }

      // Compute prominence and filter
      final List<int> kept = [];
      final List<double> keptProms = [];
      for (final c in candidates) {
        final double cv = subV[c];
        // Left: find min until we hit a higher peak or boundary
        double leftMin = cv;
        for (int k = c - 1; k >= 0; k--) {
          if (subV[k] > cv) break;
          if (subV[k] < leftMin) leftMin = subV[k];
        }
        double rightMin = cv;
        for (int k = c + 1; k < subV.length; k++) {
          if (subV[k] > cv) break;
          if (subV[k] < rightMin) rightMin = subV[k];
        }
        final double base = math.max(leftMin, rightMin);
        final double prom = cv - base;
        if (prom >= promThr) {
          kept.add(c);
          keptProms.add(prom);
        }
      }

      // Apply min-distance constraint: keep highest-prominence peaks first
      // and discard any neighbor closer than minPeakDistanceFrames.
      final List<int> orderByProm = List<int>.generate(kept.length, (k) => k)
        ..sort((a, b) => keptProms[b].compareTo(keptProms[a]));
      final List<bool> alive = List<bool>.filled(kept.length, true);
      for (final ki in orderByProm) {
        if (!alive[ki]) continue;
        final int kIdx = subIdx[kept[ki]];
        for (int kj = 0; kj < kept.length; kj++) {
          if (kj == ki || !alive[kj]) continue;
          final int kjIdx = subIdx[kept[kj]];
          if ((kjIdx - kIdx).abs() < minPeakDistanceFrames) {
            alive[kj] = false;
          }
        }
      }

      // Final peaks (sorted by frame index)
      final List<int> finalPeaks = [];
      for (int k = 0; k < kept.length; k++) {
        if (alive[k]) finalPeaks.add(kept[k]);
      }
      finalPeaks.sort();

      // Build rep events. Pull start/end = nearest local minima in the
      // region around each peak (used for form analysis).
      for (int pi = 0; pi < finalPeaks.length; pi++) {
        final int peakSubIdx = finalPeaks[pi];
        final int peakIdx = subIdx[peakSubIdx];
        // Walk left to find the trough before this peak (or region start)
        int leftTroughSub = peakSubIdx;
        for (int k = peakSubIdx - 1; k >= 0; k--) {
          if (subV[k] < subV[leftTroughSub]) leftTroughSub = k;
          // Stop if we hit the previous peak
          if (pi > 0 && k <= finalPeaks[pi - 1]) break;
        }
        int rightTroughSub = peakSubIdx;
        for (int k = peakSubIdx + 1; k < subV.length; k++) {
          if (subV[k] < subV[rightTroughSub]) rightTroughSub = k;
          if (pi < finalPeaks.length - 1 && k >= finalPeaks[pi + 1]) break;
        }
        final int startIdx = subIdx[leftTroughSub];
        final int endIdx = subIdx[rightTroughSub];

        final double peakV = subV[peakSubIdx];
        final double pullHeightPct = (peakV - mn) / math.max(0.001, rng);

        repEvents.add({
          'peakIdx': peakIdx,
          'startIdx': startIdx,
          'endIdx': endIdx,
          'pullHeightPct': pullHeightPct,
        });
      }
    }
  } // end if-else for view selection

  // ================ 8) Build per-rep reports + form analysis ================
  final List<Map<String, dynamic>> repReports = [];
  final List<double> allScores = [];
  int repCount = 0;

  for (final ev in repEvents) {
    repCount++;
    final int startIdx = ev['startIdx'] as int;
    final int peakIdx = ev['peakIdx'] as int;
    final int endIdx = ev['endIdx'] as int;
    final double pullHeightPct = ev['pullHeightPct'] as double;

    final List<double> torsoVals = [];
    final List<double> kneeVals = [];
    for (int j = startIdx; j <= endIdx; j++) {
      final t = (j < torsoAngByFrame.length) ? torsoAngByFrame[j] : null;
      if (t != null) torsoVals.add(t);
      final k = (j < kneeAngByFrame.length) ? kneeAngByFrame[j] : null;
      if (k != null) kneeVals.add(k);
    }
    final double? torsoMean = safeMean(torsoVals);
    final double? torsoDrift = robustRange(torsoVals);

    double? kneeExtension;
    if (kneeVals.length >= 6) {
      final int n3 = kneeVals.length ~/ 3;
      if (n3 > 0) {
        final start = kneeVals.sublist(0, n3);
        final mid = kneeVals.sublist(n3);
        if (start.isNotEmpty && mid.isNotEmpty) {
          final mS = start.reduce((a, b) => a + b) / start.length;
          final mM = mid.reduce((a, b) => a + b) / mid.length;
          kneeExtension = mM - mS;
        }
      }
    }

    final List<String> reasons = [];
    if (pullHeightPct < PULL_HEIGHT_MIN_OK_PCT) {
      reasons.add(FB_ERROR_PULL_HIGH);
    }
    if (torsoMean != null && torsoMean > TORSO_HIGH_WARNING_DEG) {
      reasons.add(FB_ERROR_TORSO_HIGH);
    }
    if (torsoDrift != null && torsoDrift > TORSO_DRIFT_DEG * 1.5) {
      reasons.add(FB_ERROR_MOMENTUM);
    }
    if (kneeExtension != null && kneeExtension > KNEE_EXTENSION_DEG) {
      reasons.add(FB_ERROR_LEG_DRIVE);
    }

    double penalty = 0.0;
    if (reasons.contains(FB_ERROR_PULL_HIGH)) penalty += 3.0;
    if (reasons.contains(FB_ERROR_TORSO_HIGH)) penalty += 2.0;
    if (reasons.contains(FB_ERROR_MOMENTUM)) penalty += 1.5;
    if (reasons.contains(FB_ERROR_LEG_DRIVE)) penalty += 0.8;
    if (pullHeightPct < PULL_HEIGHT_MIN_GOOD_PCT &&
        pullHeightPct >= PULL_HEIGHT_MIN_OK_PCT) {
      penalty += 1.0;
    }
    final double repScore = clampD(roundToHalf(10.0 - penalty), 4.0, 10.0);
    allScores.add(repScore);

    repReports.add({
      'index': repCount,
      'start_frame': startIdx + 1,
      'peak_frame': peakIdx + 1,
      'end_frame': endIdx + 1,
      'pull_height_pct': pullHeightPct,
      'torso_mean': torsoMean,
      'torso_drift': torsoDrift,
      'knee_extension': kneeExtension,
      'reasons': reasons,
      'score': repScore,
    });

    // Stash reasons back onto the event for feedback windowing below
    ev['reasons'] = reasons;
  }

  // ================ 9) Per-frame counter rewrite ================
  // Walk forward; counter ticks at each peak.
  if (repEvents.isNotEmpty) {
    final List<int> peakIndices =
        repEvents.map<int>((ev) => ev['peakIdx'] as int).toList()..sort();
    int p = 0;
    for (int k = 0; k < frameTelemetry.length; k++) {
      while (p < peakIndices.length && peakIndices[p] <= k) {
        p++;
      }
      frameTelemetry[k]['reps'] = p;
    }
  }

  // ================ 10) Session-level form errors ================
  final Set<String> sessionFormErrors = {};
  int countReason(String r) => repEvents.where((ev) {
        final reasons = (ev['reasons'] as List?)?.cast<String>() ?? const [];
        return reasons.contains(r);
      }).length;
  for (final r in [
    FB_ERROR_PULL_HIGH,
    FB_ERROR_TORSO_HIGH,
    FB_ERROR_MOMENTUM,
    FB_ERROR_LEG_DRIVE,
  ]) {
    if (countReason(r) >= MIN_REPS_FOR_FORM_ERROR) {
      sessionFormErrors.add(r);
    }
  }

  // ================ 11) Per-frame feedback windows ================
  final int holdMedium = math.max(1, (1.0 * fps).round());
  final int holdLong = math.max(1, (1.5 * fps).round());

  final List<List<String>> finalFbs =
      List<List<String>>.generate(frameTelemetry.length, (_) => <String>[]);

  void addFb(int sIdx, int eIdx, String fb) {
    final s = math.max(0, sIdx);
    final e = math.min(frameTelemetry.length - 1, eIdx);
    for (int k = s; k <= e; k++) {
      if (!finalFbs[k].contains(fb)) finalFbs[k].add(fb);
    }
  }

  int finalGood = 0, finalBad = 0;
  for (final ev in repEvents) {
    final int startIdx = ev['startIdx'] as int;
    final int peakIdx = ev['peakIdx'] as int;
    final int endIdx = ev['endIdx'] as int;
    final List<String> reasons =
        (ev['reasons'] as List?)?.cast<String>() ?? <String>[];

    final List<String> activeFbs = [];
    for (final r in reasons) {
      if (sessionFormErrors.contains(r)) activeFbs.add(r);
    }
    final bool isBad = activeFbs.isNotEmpty;
    if (peakIdx >= 0 && peakIdx < frameTelemetry.length) {
      frameTelemetry[peakIdx]['rep_just_finished'] = isBad ? 'bad' : 'good';
    }
    if (isBad) {
      finalBad++;
    } else {
      finalGood++;
    }
    for (final fb in activeFbs) {
      if (fb == FB_ERROR_PULL_HIGH || fb == FB_ERROR_LEG_DRIVE) {
        addFb(peakIdx, peakIdx + holdLong, fb);
      } else {
        addFb(startIdx, math.min(endIdx + holdMedium, peakIdx + holdLong), fb);
      }
    }
  }

  for (int k = 0; k < frameTelemetry.length; k++) {
    final fbs = finalFbs[k];
    frameTelemetry[k]['feedback'] = fbs.isEmpty ? null : fbs.join('\n');
  }

  // ================ 12) Aggregate session ================
  double techniqueScore;
  if (repCount == 0) {
    techniqueScore = 0.0;
  } else if (allScores.isNotEmpty) {
    final mean = allScores.reduce((a, b) => a + b) / allScores.length;
    techniqueScore = clampD(roundToHalf(mean), 4.0, 10.0);
  } else {
    techniqueScore = 7.0;
  }
  final String label = technique(techniqueScore);

  final List<String> formErrorsList =
      FORM_ERROR_PRIORITY.where((r) => sessionFormErrors.contains(r)).toList();

  String? formTip;
  if (formErrorsList.isNotEmpty) {
    final first = formErrorsList.first;
    if (first == FB_ERROR_TORSO_HIGH) {
      formTip =
          'Focus on hip hinge — push your hips back to get more horizontal';
    } else if (first == FB_ERROR_PULL_HIGH) {
      formTip = "Think 'elbows to ceiling' — drive them high and back";
    } else if (first == FB_ERROR_MOMENTUM) {
      formTip = 'Control the descent — lower the bar over 2-3 seconds';
    } else if (first == FB_ERROR_LEG_DRIVE) {
      formTip = 'Keep your knees fixed — pull with your back, not your legs';
    } else {
      formTip = first;
    }
  } else if (finalGood == repCount && repCount > 0) {
    if (detectedView == 'frontal') {
      formTip =
          'Great work! For more accurate analysis, try filming from the side 📐';
    } else {
      formTip = 'Great form! Keep it up 💪';
    }
  } else if (repCount > 0) {
    if (detectedView == 'frontal') {
      formTip =
          'Detected from front view — for detailed form feedback, film from the side';
    } else {
      formTip = 'Try slowing down the lowering phase for better control';
    }
  } else {
    // 0 reps but we DID get past the quality gate — that means the
    // rep signal was too small. Tell the user what happened.
    double bestRange = 0;
    for (final r in debugRegions) {
      final passed = (r['passed_stability_gate'] as bool?) ?? false;
      if (!passed) continue;
      final rng = (r['trace_range'] as double?) ?? 0;
      if (rng > bestRange) bestRange = rng;
    }
    formTip = 'Pull motion too small to detect '
        '(amplitude ${(bestRange * 100).toStringAsFixed(1)}, '
        'min ${(MIN_REGION_RANGE * 100).toStringAsFixed(1)}). '
        'Pull the bar higher toward your chest.';
  }

  // [v6.24 DEBUG] Append diagnostic info to form_tip.
  // v6.24 changes vs v6.23:
  //  - Cadence simplified: applies only when validated.length == 1.
  //    A lone tier-1 peak is rejected (FP); 2+ peaks all kept (real set).
  //  - PULL check on frontal fallback and the don't-fall-back-if-cadence
  //    rule from v6.23 are unchanged.
  final List<String> rejParts = [];
  if (diagRejPull > 0) {
    final String supDetail = diagRejPullSupporters.isEmpty
        ? ''
        : ' sup=[${diagRejPullSupporters.join(",")}]';
    final String timeDetail = diagRejPullTimes.isEmpty
        ? ''
        : ' t=[${diagRejPullTimes.map((t) => t.toStringAsFixed(1)).join(",")}]';
    final String rawDetail = diagRejPullMaxRaw.isEmpty
        ? ''
        : ' rawMax=[${diagRejPullMaxRaw.join(",")}]';
    rejParts.add('P:$diagRejPull$supDetail$timeDetail$rawDetail');
  }
  if (diagRejWidth > 0) rejParts.add('W:$diagRejWidth');
  if (diagRejCoverage > 0) rejParts.add('C:$diagRejCoverage');
  if (diagRejJump > 0) rejParts.add('J:$diagRejJump');
  if (diagRejSupporters > 0) rejParts.add('Sup:$diagRejSupporters');
  if (diagRejValley > 0) rejParts.add('V:$diagRejValley');
  if (diagRejCadence > 0) rejParts.add('Cad:$diagRejCadence'); // [v6.22]
  final String rejStr = rejParts.isEmpty ? '-' : rejParts.join(',');
  // [v6.20/v6.21] accepted-peak times and total duration.
  final String accStr = diagAcceptedTimes.isEmpty
      ? '-'
      : '[${diagAcceptedTimes.map((t) => t.toStringAsFixed(1)).join(",")}]';
  final double videoDuration = (frameTelemetry.length / fps);
  final String diagnosticTag =
      ' [v6.24 view=$detectedView reps=$repCount multi=${multiSignalRepPeaks.length} anch=$diagAnchorsTotal supMax=$diagMaxSup rej=$rejStr acc_t=$accStr dur=${videoDuration.toStringAsFixed(1)}s gate=${globalActivityGatePassed ? "OK" : "FAIL"}]';
  formTip = (formTip ?? '') + diagnosticTag;

  final String fileUri = 'file://$videoPath';

  return {
    'success': true,
    'squat_count': repCount, // for UI compatibility
    'row_count': repCount,
    'good_reps': finalGood,
    'bad_reps': finalBad,
    'technique_score': techniqueScore,
    'technique_score_display': techniqueScore.toStringAsFixed(1),
    'technique_label': label,
    'feedback': formErrorsList,
    'tips': <String>[],
    'form_tip': formTip,
    'tip': formTip,
    'reps': repReports,
    'rep_details': repReports,
    'exercise_type': 'bent_row',
    'video_path': fileUri,
    'analyzed_fps': fps,
    'frame_count': frameIdx,
    '_source_video_uri': fileUri,
    '_frame_telemetry': frameTelemetry,
    '_debug_regions': debugRegions,
    '_debug_summary': debugSummary,
  };
}

// ---- dimension probe cache ----
double _cachedW = -1;
double _cachedH = -1;

Future<(int, int)> _probeImageDims(String path) async {
  final bytes = await File(path).readAsBytes();
  int i = 2;
  while (i < bytes.length - 8) {
    if (bytes[i] != 0xFF) break;
    final marker = bytes[i + 1];
    i += 2;
    if ((marker >= 0xC0 && marker <= 0xCF) &&
        marker != 0xC4 &&
        marker != 0xC8 &&
        marker != 0xCC) {
      final h = (bytes[i + 3] << 8) | bytes[i + 4];
      final w = (bytes[i + 5] << 8) | bytes[i + 6];
      return (w, h);
    } else {
      final segLen = (bytes[i] << 8) | bytes[i + 1];
      i += segLen;
    }
  }
  return (720, 1280);
}
