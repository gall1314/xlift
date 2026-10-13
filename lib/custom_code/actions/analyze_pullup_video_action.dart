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

import 'dart:io';
import 'dart:collection';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

/// Analyze a pull-up video locally using ML Kit Pose Detection.
///
/// Translated 1:1 from pullup_analysis.py (Python/MediaPipe) to Dart/ML Kit,
/// keeping the same counting logic and the same three feedback cues:
///   - "Go a bit higher (chin over bar)"  (FB_CUE_HIGHER)
///   - "Reduce body swing (no kipping)"   (FB_CUE_SWING)
///   - "Fully extend arms at bottom"      (FB_CUE_BOTTOM)
///
/// [variant]: 'pullup' (default, null) | 'neutral' | 'chinup'.
/// 'chinup' adds a fourth cue:
///   - "Narrow your grip to shoulder width" (FB_CUE_GRIP)
///   Measured as wrist-to-wrist span / shoulder-to-shoulder span (median
///   over the rep cycle). Only evaluated when the shoulders are seen from
///   the front/back (shoulder span wide enough) — a side view has no
///   usable width information, so the check is silently skipped there.
///
/// [FEEDBACK-SYNC] The returned `feedback` list is derived from EXACTLY
/// the set of cues that were displayed as in-video banners by the
/// post-process pass. Summary and video can no longer diverge.
///
/// Why they could diverge before: the in-video banner requires BOTH the
/// per-rep flag AND the session-level cue, but the session-level cue
/// could be raised WITHOUT any rep being flagged. The main leak was
/// SWING: `sessionFeedback.add(FB_CUE_SWING)` fired the moment
/// swingStreak crossed threshold, even when no rep was "open"
/// (currentRepCountFrameIdx == null) — which is the COMMON case, since
/// kipping mostly happens during the ascent BEFORE the count fires at
/// the top, and between reps after reset. Result: "Reduce body swing"
/// in the summary with zero banners in the video.
///
/// The fix: `displayedCues` records every cue string actually written
/// into frame telemetry; after the post-process pass, sessionFeedback
/// is overwritten with that set (a pure intersection — displayed cues
/// are always already in sessionFeedback, so this can only REMOVE
/// undisplayed cues, never add). techniqueScore and feedbackList are
/// then computed from the synced set.
///
/// Counting rule (same as Python): rep is counted when (a) the user is ON
/// the bar, (b) head ascent from the per-cycle baseline is at least
/// HEAD_MIN_ASCENT, and (c) elbow angle is below ELBOW_TOP_ANGLE (≤100°).
/// After a count we re-arm on either descent (head drops by RESET_DESCENT)
/// or elbow extension (≥RESET_ELBOW).
///
/// On/off-bar gating uses the same checks as the Python version: pose
/// visibility, wrist above the nose, and torso lateral motion below the
/// swing threshold.
///
/// Frontend integration mirrors the pushup analyzer:
///   - per-frame telemetry (skeleton landmarks, reps, height%, feedback,
///     rep_just_finished verdict for haptic/sound pulses)
///   - the rep_just_finished pulse is placed at the visual peak of the rep
///     (head highest = noseY lowest in image coords) via a post-process
///     pass, so the flash/haptic/sound fires exactly when the user reaches
///     the top of the rep on screen.
///   - feedback hold (1.5s) so a cue stays visible even on a fast cadence.
///   - frameTelemetry is filled for every frame (no early break) so the
///     widget never has to extrapolate past the last entry.
Future<dynamic> analyzePullupVideoAction(
  FFUploadedFile videoFile,
  double? targetFps,
  String? variant,
) async {
  // ================ Variant ================
  final String variantName = (variant ?? 'pullup').trim().toLowerCase();
  final bool checkGripWidth = variantName == 'chinup';

  // ================ Parameters (1:1 from pullup_analysis.py) ================
  const double ELBOW_TOP_ANGLE = 100.0; // ≤100° at top
  const double HEAD_MIN_ASCENT = 0.0075; // ~0.75% of frame height
  const double RESET_DESCENT = 0.0045;
  const double RESET_ELBOW = 135.0;
  const int REFRACTORY_FRAMES = 2;
  const double HEAD_VEL_UP_TINY = 0.0002;
  const double ELBOW_EMA_ALPHA = 0.35;
  const double HEAD_EMA_ALPHA = 0.30;

  // On/Off-bar gating
  const double VIS_THR_STRICT = 0.30;
  const double WRIST_VIS_THR = 0.20;
  const double WRIST_ABOVE_HEAD_MARGIN = 0.02;
  const double TORSO_X_THR = 0.010;
  const int ONBAR_MIN_FRAMES = 2;
  const int OFFBAR_MIN_FRAMES = 6;
  const double AUTO_STOP_AFTER_EXIT_SEC = 1.2;
  const double TAIL_NOPOSE_STOP_SEC = 1.0;

  // Feedback cues (verbatim — must match the Python strings so the UI
  // can localize/style them consistently across exercises).
  const String FB_CUE_HIGHER = 'Go a bit higher (chin over bar)';
  const String FB_CUE_SWING = 'Reduce body swing (no kipping)';
  const String FB_CUE_BOTTOM = 'Fully extend arms at bottom';
  const String FB_CUE_GRIP = 'Narrow your grip to shoulder width';

  const Map<String, double> FB_WEIGHTS = {
    FB_CUE_HIGHER: 0.5,
    FB_CUE_SWING: 0.5,
    FB_CUE_BOTTOM: 0.5,
    FB_CUE_GRIP: 0.5,
  };
  const double FB_DEFAULT_WEIGHT = 0.5;
  const double PENALTY_MIN_IF_ANY = 0.5;

  // Display priority for the final feedback list.
  const List<String> CUE_PRIORITY = [
    FB_CUE_HIGHER,
    FB_CUE_BOTTOM,
    FB_CUE_SWING,
    FB_CUE_GRIP,
  ];

  // Swing detection
  const double SWING_THR = 0.012;
  const int SWING_MIN_STREAK = 3;

  // Bottom extension check
  const double BOTTOM_EXT_MIN_ANGLE = 155.0;
  const double BOTTOM_HYST_DEG = 3.0;
  const int BOTTOM_FAIL_MIN_REPS = 2;

  // ---- Chin-up grip width check ----
  // ratio = |wristL.x - wristR.x| / |shoulderL.x - shoulderR.x|.
  // Supinated grip should sit at or inside shoulder width; wider loads
  // the wrists/elbows. 1.3 leaves room for hand-vs-wrist landmark offset
  // and a slightly-wider-than-shoulders grip that is still fine.
  // Only measured when the shoulder span is wide enough to mean the
  // camera sees the lifter from the front/back (side view -> skipped).
  const double GRIP_WIDE_RATIO = 1.30;
  const double GRIP_MIN_SHOULDER_SPAN = 0.06; // normalized frame width
  const int GRIP_FAIL_MIN_REPS = 2;
  const int GRIP_MIN_SAMPLES = 4;

  // ---- "Go a bit higher" tuning (relaxed vs Python) ----
  //
  // The original Python check fired any time the user was mid-ascent
  // and hadn't reached HEAD_MIN_ASCENT * 0.7 yet — which is most of the
  // ascent, so the cue would fire on practically every rep. We now use
  // a stricter "rep arc completed but didn't reach a real top" signal:
  //
  //   - Look at the FULL ascent of each detected attempt (from
  //     ascBaseHead to the apex), not just the running ascentAmt.
  //   - The attempt is "shallow" only if its apex-from-base is less
  //     than HIGHER_REP_MIN_ASCENT (a meaningfully higher bar than
  //     HEAD_MIN_ASCENT used for counting), AND the rep was already
  //     COUNTED (so we know elbow ≤ 100°). A rep that was counted but
  //     didn't get the head high enough is the real "chin not over bar"
  //     case the user wants flagged.
  //   - We also require N such shallow reps before surfacing the
  //     session-level cue (HIGHER_FAIL_MIN_REPS), to avoid one-off
  //     measurement noise tripping it.
  //
  // HIGHER_REP_MIN_ASCENT is the apex-from-base threshold: any rep
  // whose head rose less than this from its descent baseline is
  // flagged as shallow. 0.020 (≈2% of frame height) is empirically
  // about the difference between "barely got chin to bar" and
  // "comfortably over". Tuning this constant up will make the cue
  // fire MORE; down will make it fire LESS.
  const double HIGHER_REP_MIN_ASCENT = 0.020;
  const int HIGHER_FAIL_MIN_REPS = 2;

  // ---- HEIGHT donut normalization ----
  //
  // The Python reference normalized the donut against
  // HEAD_MIN_ASCENT*1.2 (~0.009) — so any small ascent already
  // displayed 100%, which made the donut and the "go higher" cue
  // visually contradictory. We now normalize against a more
  // realistic "good rep ascent" (HEIGHT_DONUT_FULL_ASCENT). With
  // 0.05 (5% of frame), a chin-clearly-over-bar rep reads ~100%, a
  // shallow rep reads ~40%, and an off-bar idle position reads ~0%.
  // This keeps the donut consistent with the cue: when the cue says
  // "go higher", the donut is meaningfully below 100%.
  const double HEIGHT_DONUT_FULL_ASCENT = 0.05;

  final double fps = (targetFps ?? 20.0).clamp(4.0, 30.0);
  final double dt = 1.0 / fps;
  final int OFFBAR_STOP_FRAMES =
      math.max(1, (AUTO_STOP_AFTER_EXIT_SEC / dt).round());
  final int NOPOSE_STOP_FRAMES =
      math.max(1, (TAIL_NOPOSE_STOP_SEC / dt).round());
  // Mirrors the pushup analyzer: 1.5s hold is long enough that even a
  // fast rep cadence won't overwrite the message before the eye reads it.
  final int RT_FB_HOLD_FRAMES = math.max(2, (1.5 / dt).round());

  _cachedW = -1;
  _cachedH = -1;

  // ================ Helpers ================
  double ang(List<double> a, List<double> b, List<double> c) {
    final baX = a[0] - b[0];
    final baY = a[1] - b[1];
    final bcX = c[0] - b[0];
    final bcY = c[1] - b[1];
    final den =
        (math.sqrt(baX * baX + baY * baY) * math.sqrt(bcX * bcX + bcY * bcY)) +
            1e-9;
    final cos = ((baX * bcX + baY * bcY) / den).clamp(-1.0, 1.0);
    return math.acos(cos) * 180.0 / math.pi;
  }

  double ema(double? prev, double newVal, double alpha) {
    if (prev == null) return newVal;
    return alpha * newVal + (1 - alpha) * prev;
  }

  // Round DOWN to nearest 0.5 — matches Python `_half_floor`.
  double halfFloor10(double x) {
    return math.max(0.0, math.min(10.0, (x * 2.0).floorToDouble() / 2.0));
  }

  String displayHalfStr(double x) {
    final q = (x * 2).round() / 2.0;
    if ((q - q.round()).abs() < 1e-9) return q.round().toString();
    return q.toStringAsFixed(1);
  }

  // Score label thresholds match the Python version (which uses 9.5/8.5
  // boundaries — slightly different from the pushup analyzer).
  String scoreLabel(double s) {
    if (s >= 9.5) return 'Excellent';
    if (s >= 8.5) return 'Very good';
    if (s >= 7.0) return 'Good';
    if (s >= 5.5) return 'Fair';
    return 'Needs work';
  }

  double medianOf(List<double> xs) {
    if (xs.isEmpty) return 0.0;
    final s = List<double>.from(xs)..sort();
    final int m = s.length ~/ 2;
    return s.length.isOdd ? s[m] : (s[m - 1] + s[m]) / 2.0;
  }

  Map<String, dynamic> errorPayload(String code, String detail) => {
        'error': code,
        'detail': detail,
        'squat_count': 0,
        'technique_score': 0.0,
        'technique_score_display': '0',
        'technique_label': 'Needs work',
        'good_reps': 0,
        'bad_reps': 0,
        'feedback': <String>['Could not analyze video'],
        'tips': <String>[],
        'reps': <dynamic>[],
        'exercise_type': 'pullup',
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
    'pullup_in_${DateTime.now().millisecondsSinceEpoch}_$safeName',
  );
  try {
    await File(videoPath).writeAsBytes(videoFile.bytes!, flush: true);
  } catch (e) {
    return errorPayload('write_failed', 'Could not save upload: $e');
  }

  // ================ 1) Extract frames ================
  final String sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  final Directory framesDir =
      Directory(p.join(tmp.path, 'pullup_frames_$sessionId'));
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

  // ================ 3) Session state ================
  int repCount = 0;
  int goodReps = 0;
  int badReps = 0;
  final List<Map<String, dynamic>> repReports = [];
  final List<double> allScores = [];

  double? elbowEma;
  double? headEma;
  double? headPrev;
  double? ascBaseHead;
  double? baselineHeadYGlobal;
  // ---- Donut-specific baseline (independent of ascBaseHead) ----
  //
  // ascBaseHead gets set when the head FIRST starts moving up (i.e.
  // partway through the descent already, on the very next frame after
  // velocity flips upward). For the COUNTING logic that's fine — we
  // only need a recent reference. But for the donut it's a problem:
  // the donut should show "how high are you from your dead-hang
  // bottom?", which means we need the LOWEST head position the user
  // hit during the descent, not the position where motion happened to
  // reverse.
  //
  // donutBaselineHeadY tracks the lowest (largest Y in image coords)
  // headY observed since the last completed rep. It refreshes:
  //   - to the current headY whenever the user is descending or
  //     stationary (ascBaseHead == null), keeping it pinned to the
  //     deepest point seen recently.
  //   - resets to a fresh max-track when a rep is committed.
  // This way the donut measures the FULL range of the rep, even the
  // first frames of the ascent that happen before ascBaseHead is set.
  double? donutBaselineHeadY;
  // donutPeakAscent holds onto the highest ascent value seen during
  // the current rep so the donut doesn't snap back to 0 the moment
  // the user starts descending — it stays at the peak briefly, then
  // tracks the actual descent down. Resets when a new rep starts.
  double donutPeakAscent = 0.0;
  // _donutFullAscent is the running estimate of "how much vertical
  // distance the head travels in a full pull-up for this user/camera
  // setup". The donut's 100% mark corresponds to this value. We start
  // with a default that's sane for typical phone-distance framing and
  // then refine it from the measured peak ascent of each completed
  // rep (see the rep-commit block, where it's nudged toward the
  // observed value with a moderate learning rate so a single anomaly
  // doesn't throw the calibration off).
  //
  // Default 0.10 (10% of frame): empirically a reasonable starting
  // point for medium-zoom side-on shots. The first rep will read
  // roughly correctly with this default; rep 2+ will be calibrated
  // to the user's actual range.
  double _donutFullAscent = 0.10;
  bool allowNewPeak = true;
  int lastPeakFrame = -1000000000;

  bool onbar = false;
  int onbarStreak = 0;
  int offbarStreak = 0;
  double? prevTorsoCx;
  int offbarFramesSinceAnyRep = 0;
  int nopopseFramesSinceAnyRep = 0;

  final Set<String> sessionFeedback = {};
  String? rtFbMsg;
  int rtFbHold = 0;

  int swingStreak = 0;
  bool swingAlreadyReported = false;
  bool bottomAlreadyReported = false;

  // ---- Per-rep apex tracking (for the relaxed HIGHER cue) ----
  // After a rep is counted, we keep tracking the head's apex (smallest
  // headY = highest body position) until the next reset. At reset we
  // compare apex-from-base to HIGHER_REP_MIN_ASCENT. If the rep didn't
  // reach a meaningful height, we mark it shallow. After
  // HIGHER_FAIL_MIN_REPS shallow reps in the session, the cue surfaces.
  double? currentRepApexHeadY; // smallest headY since last count
  double? currentRepBaseHeadY; // ascBaseHead at the moment of count
  int? currentRepCountFrameIdx; // 1-based frame index of the count
  int higherFailCount = 0;
  bool higherAlreadyReported = false;

  // Per-rep cue tracking: which reps had which cue so we can attach
  // the right verdict + flash color in post-process.
  // Maps frameIdx -> bool (was-this-rep-shallow / had-swing / etc).
  // Filled at the moment of detection; consumed in post-process to
  // place feedback at the rep's visual peak.
  final List<bool> repShallowFlags = []; // index parallel to pulseEvents
  final List<bool> repSwingFlags = [];
  final List<bool> repBottomFlags = [];
  final List<bool> repGripFlags = [];
  // Per-cycle "did we see swing since this rep was counted" — gets
  // attached to the rep at reset/next-count time.
  bool currentRepHadSwing = false;
  bool currentRepHadBottomMiss = false;

  // Per-cycle grip-width samples (chin-up only). Collected on every
  // on-bar frame with a usable front/back view; evaluated at reset.
  final List<double> cycleGripSamples = [];
  int gripFailCount = 0;
  bool gripAlreadyReported = false;

  // Per-cycle bottom-phase max elbow extension (raw, both arms). When the
  // user is descending after a counted rep, we keep widening this to track
  // the most-extended elbow they hit before re-arming. Resets each rep.
  double? bottomPhaseMaxElbow;
  int bottomFailCount = 0;

  // ============================================================
  // Visible-pulse + counter coherency (same approach as pushup)
  //
  // We count IMMEDIATELY when the rep is detected (Python parity), but
  // the rep_just_finished verdict (which drives the skeleton flash,
  // haptic, and sound on the frontend) is placed in a post-process pass
  // at the actual visual peak of the rep — i.e. the frame where the
  // user's head is highest. For pull-ups that's the frame with the
  // SMALLEST nose Y in image coordinates within an ascent window after
  // the rep's count frame.
  //
  // Why post-process: the count fires at the moment the elbow drops
  // below ELBOW_TOP_ANGLE, but the user typically continues to rise for
  // a few frames after that. Putting the visible event at that true
  // peak makes the flash feel synchronized with the body at the top.
  // ============================================================
  final List<Map<String, dynamic>> pulseEvents = [];
  final List<double?> headYByFrame = [];
  final List<double?> noseYRawByFrame = [];
  // Per-frame RAW ascent (donutBaselineHeadY - headY, in normalized
  // image-Y units, never negative, 0 when the user isn't ascending).
  // Filled inline with the main loop; consumed in a post-process pass
  // that normalizes against the global peak so the donut's 100% mark
  // corresponds to the user's deepest rep across the whole video.
  final List<double> rawAscentByFrame = [];

  int frameIdx = 0;

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

  final List<Map<String, dynamic>> frameTelemetry = [];
  List<List<double>>? lastValidLandmarks;

  String? repJustFinished;

  // ================ 4) Process each frame ================
  try {
    for (final frameFile in frameFiles) {
      frameIdx += 1;
      final double tSec = (frameIdx - 1) / fps;

      String? curRt;

      final inputImage = InputImage.fromFilePath(frameFile.path);
      List<Pose> poses;
      try {
        poses = await poseDetector.processImage(inputImage);
      } catch (_) {
        poses = const [];
      }

      if (poses.isEmpty) {
        // No early break — same reasoning as the pushup analyzer. We
        // emit a telemetry entry for every frame so the widget doesn't
        // freeze the skeleton at the last detected pose. Empty
        // landmarks -> the widget renders nothing for this frame.
        nopopseFramesSinceAnyRep =
            (repCount > 0) ? (nopopseFramesSinceAnyRep + 1) : 0;
        frameTelemetry.add({
          't': tSec,
          'reps': repCount,
          'depth': 0.0, // legacy key; pull-ups use HEIGHT, but the
          // existing widget reads 'depth' as the donut value — we
          // keep the same key so it works without UI changes.
          'metric_label': 'HEIGHT',
          'metric_value': 0.0,
          'feedback': null, // post-process places the real feedback
          'rep_just_finished': repJustFinished,
          // Empty list — widget renders no skeleton when there's no
          // person detected. (Was previously falling back to
          // lastValidLandmarks, which froze a stale skeleton on
          // screen during out-of-frame moments.)
          'landmarks': <List<double>>[],
        });
        repJustFinished = null;
        headYByFrame.add(null);
        noseYRawByFrame.add(null);
        rawAscentByFrame.add(0.0);
        continue;
      }

      nopopseFramesSinceAnyRep = 0;
      final Pose pose = poses.first;
      final lm = pose.landmarks;

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

      // ---- Person-presence gate ----
      //
      // ML Kit returns ALL 33 landmarks every frame regardless of
      // whether anything pose-shaped is actually visible. When the
      // user is out of frame, those landmarks have low confidence and
      // are scattered over background objects (other people, bars,
      // foliage). The widget can't tell those apart from a real
      // skeleton and renders them anyway, producing the "ghost
      // skeleton" effect the user reported.
      //
      // We require two conditions before exposing landmarks to the
      // widget:
      //   1. Mean confidence over the major upper-body joints is
      //      above PRESENCE_MEAN_CONF. ML Kit is generous with
      //      individual likelihoods, but the AVERAGE drops noticeably
      //      when there's no real person — typical real detection
      //      averages 0.6-0.9, ghost detection averages 0.2-0.4.
      //   2. At least PRESENCE_MIN_HIGH_CONF_JOINTS of those joints
      //      have confidence above PRESENCE_HIGH_CONF. A handful of
      //      decently-localized joints prevents a uniform low-
      //      confidence ghost from sneaking through the mean test.
      //
      // When the gate fails we emit an empty landmarks list. The
      // widget should treat that as "no skeleton to draw" and just
      // render the video frame plain. That's much better visually
      // than a misplaced skeleton.
      const double PRESENCE_MEAN_CONF = 0.45;
      const double PRESENCE_HIGH_CONF = 0.55;
      const int PRESENCE_MIN_HIGH_CONF_JOINTS = 5;
      final List<PoseLandmarkType> presenceJoints = const [
        PoseLandmarkType.nose,
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.rightElbow,
        PoseLandmarkType.leftHip,
        PoseLandmarkType.rightHip,
      ];
      double sumConf = 0.0;
      int highConfCount = 0;
      int countedJoints = 0;
      for (final pj in presenceJoints) {
        final p = lm[pj];
        if (p == null) continue;
        sumConf += p.likelihood;
        if (p.likelihood >= PRESENCE_HIGH_CONF) highConfCount += 1;
        countedJoints += 1;
      }
      final double meanConf =
          countedJoints == 0 ? 0.0 : sumConf / countedJoints;
      final bool personPresent = meanConf >= PRESENCE_MEAN_CONF &&
          highConfCount >= PRESENCE_MIN_HIGH_CONF_JOINTS;

      // Only update lastValidLandmarks when the person is actually
      // present, so any "no-pose" frames downstream of this one (e.g.
      // ML Kit returning [] briefly) fall back to a real skeleton
      // rather than a ghost.
      if (personPresent) {
        lastValidLandmarks = normLandmarks;
      }

      // If the person isn't in frame, treat this frame like the no-pose
      // case — empty landmarks, no analysis, but keep the frame counter
      // moving so the widget's video clock stays synchronized.
      if (!personPresent) {
        nopopseFramesSinceAnyRep =
            (repCount > 0) ? (nopopseFramesSinceAnyRep + 1) : 0;
        frameTelemetry.add({
          't': tSec,
          'reps': repCount,
          'depth': 0.0,
          'metric_label': 'HEIGHT',
          'metric_value': 0.0,
          'feedback': null,
          'rep_just_finished': repJustFinished,
          // Empty landmarks list — widget should render no skeleton
          // for this frame. NOT lastValidLandmarks: that would freeze
          // a stale skeleton on screen.
          'landmarks': <List<double>>[],
        });
        repJustFinished = null;
        headYByFrame.add(null);
        noseYRawByFrame.add(null);
        rawAscentByFrame.add(0.0);
        // Also advance off-bar streak so on/off-bar gating doesn't
        // think the user is still on the bar during their absence.
        offbarStreak += 1;
        onbarStreak = 0;
        if (onbar && offbarStreak >= OFFBAR_MIN_FRAMES) {
          onbar = false;
          ascBaseHead = null;
          allowNewPeak = true;
          donutBaselineHeadY = null;
          donutPeakAscent = 0.0;
        }
        continue;
      }

      final PoseLandmark? nose = lm[PoseLandmarkType.nose];
      final PoseLandmark? lsh = lm[PoseLandmarkType.leftShoulder];
      final PoseLandmark? rsh = lm[PoseLandmarkType.rightShoulder];
      final PoseLandmark? le = lm[PoseLandmarkType.leftElbow];
      final PoseLandmark? re = lm[PoseLandmarkType.rightElbow];
      final PoseLandmark? lw = lm[PoseLandmarkType.leftWrist];
      final PoseLandmark? rw = lm[PoseLandmarkType.rightWrist];
      final PoseLandmark? lh = lm[PoseLandmarkType.leftHip];
      final PoseLandmark? rh = lm[PoseLandmarkType.rightHip];

      if (nose == null ||
          lsh == null ||
          rsh == null ||
          le == null ||
          re == null ||
          lw == null ||
          rw == null ||
          lh == null ||
          rh == null) {
        frameTelemetry.add({
          't': tSec,
          'reps': repCount,
          'depth': 0.0,
          'metric_label': 'HEIGHT',
          'metric_value': 0.0,
          'feedback': null, // post-process places the real feedback
          'rep_just_finished': repJustFinished,
          // Missing essential joints — likely a partial / unreliable
          // detection. Emit empty list rather than a partial skeleton
          // that the widget would render incompletely (joints
          // disconnected, bones flying off-screen).
          'landmarks': <List<double>>[],
        });
        repJustFinished = null;
        headYByFrame.add(null);
        noseYRawByFrame.add(null);
        rawAscentByFrame.add(0.0);
        continue;
      }

      // Normalized coordinates (0..1)
      final List<double> nNose = [nose.x / fw, nose.y / fh];
      final List<double> nLsh = [lsh.x / fw, lsh.y / fh];
      final List<double> nRsh = [rsh.x / fw, rsh.y / fh];
      final List<double> nLe = [le.x / fw, le.y / fh];
      final List<double> nRe = [re.x / fw, re.y / fh];
      final List<double> nLw = [lw.x / fw, lw.y / fh];
      final List<double> nRw = [rw.x / fw, rw.y / fh];
      final List<double> nLh = [lh.x / fw, lh.y / fh];
      final List<double> nRh = [rh.x / fw, rh.y / fh];

      // Pick side dynamically (same as Python `_pick_side_dyn`).
      final double vL = (lsh.likelihood) + (le.likelihood) + (lw.likelihood);
      final double vR = (rsh.likelihood) + (re.likelihood) + (rw.likelihood);
      final bool useLeft = vL >= vR;

      // Strict visibility: nose + chosen side's shoulder/elbow/wrist.
      final double minVis = [
        nose.likelihood,
        useLeft ? lsh.likelihood : rsh.likelihood,
        useLeft ? le.likelihood : re.likelihood,
        useLeft ? lw.likelihood : rw.likelihood,
      ].reduce(math.min);
      final bool visStrictOk = minVis >= VIS_THR_STRICT;

      // Raw values
      final double headRaw = nNose[1];
      final double rawElbowL = ang(nLsh, nLe, nLw);
      final double rawElbowR = ang(nRsh, nRe, nRw);
      final double rawElbow = useLeft ? rawElbowL : rawElbowR;

      elbowEma = ema(elbowEma, rawElbow, ELBOW_EMA_ALPHA);
      headEma = ema(headEma, headRaw, HEAD_EMA_ALPHA);
      final double headY = headEma!;
      final double elbowAngle = elbowEma!;

      // Track the LOWEST headY seen during the current ascent — the
      // body's actual peak so far in this rep. This is what the donut
      // should reflect: "how high have you gotten in this attempt?"
      //
      // We use a per-rep tracker instead of a global frame-1 baseline
      // because the global baseline broke in two common ways:
      //   1. Many videos start with the user already gripping the bar
      //      (so headY at frame 1 is already near the top) — every
      //      subsequent reading looked equal-or-higher than baseline
      //      and the donut stayed pinned at 0%.
      //   2. Even when the user starts hanging dead, any preliminary
      //      adjustment ("settling in") before the first real rep
      //      moved them above the locked baseline, again pinning the
      //      donut at 0% afterwards.
      //
      // Per-cycle tracking ties the donut to ascBaseHead (the bottom
      // of THIS attempt) and refreshes every rep, so the donut climbs
      // from ~0% at the bottom of each rep to ~100% at the top of a
      // good rep, exactly like the body does on screen.
      // ---- Donut: track true cycle bottom + adaptive scale ----
      //
      // Update donutBaselineHeadY to the deepest head position seen
      // since the last rep. While the user is hanging or descending
      // (ascBaseHead is null OR the user has gone below ascBaseHead),
      // we keep extending the baseline downward (higher Y) so it
      // captures the true dead-hang bottom — not just the spot where
      // motion happened to reverse.
      if (ascBaseHead == null) {
        if (donutBaselineHeadY == null || headY > donutBaselineHeadY!) {
          donutBaselineHeadY = headY;
        }
      } else {
        // We're in an ascent. The dead-hang for THIS rep is whichever
        // is lower (= deeper, larger Y) between donutBaselineHeadY and
        // the moment ascBaseHead was captured.
        if (donutBaselineHeadY == null || ascBaseHead! > donutBaselineHeadY!) {
          donutBaselineHeadY = ascBaseHead;
        }
      }

      // ---- Donut: emit RAW ascent for post-process normalization ----
      //
      // We're computing offline (the whole video is already captured),
      // so there's no reason to use a running estimate of the user's
      // ascent range. Instead we record the raw ascent value at every
      // frame and let a post-process pass normalize them all against
      // the GLOBAL peak ascent observed across the whole video. That
      // way:
      //   - The user's deepest rep peaks at exactly 100% on the donut.
      //   - A rep matching that peak also reads 100%.
      //   - Shallower reps read proportionally (e.g. 75% if the user
      //     only got 75% as high on that attempt).
      //
      // We still compute a provisional heightLive here for any future
      // frame-level decisions that might want it, but the final donut
      // value displayed comes from the post-process pass below.
      double ascentNow = 0.0;
      if (donutBaselineHeadY != null) {
        ascentNow = donutBaselineHeadY! - headY;
        if (ascentNow < 0) ascentNow = 0.0;
        if (ascentNow > donutPeakAscent) {
          donutPeakAscent = ascentNow;
        }
      }
      // Provisional value (used only as a placeholder; overwritten in
      // post-process). Computed against _donutFullAscent so if the
      // post-process pass somehow can't run, we at least show
      // something reasonable.
      final double heightLive =
          (ascentNow / _donutFullAscent).clamp(0.0, 1.0).toDouble();
      // baselineHeadYGlobal kept around for any future analysis that
      // wants the absolute frame-1 reference; not used by the donut
      // anymore.
      baselineHeadYGlobal ??= headY;

      // Torso center X, normalized lateral motion per frame.
      final double torsoCx = ((nLsh[0] + nRsh[0] + nLh[0] + nRh[0]) / 4.0) * fw;
      final double torsoDxNorm = prevTorsoCx == null
          ? 0.0
          : ((torsoCx - prevTorsoCx!).abs() / math.max(1.0, fw));
      prevTorsoCx = torsoCx;

      // On/off-bar gate: at least one wrist must be ABOVE the nose
      // (with a small margin) and visible enough.
      final bool lwAbove = (lw.likelihood >= WRIST_VIS_THR) &&
          (nLw[1] < nNose[1] - WRIST_ABOVE_HEAD_MARGIN);
      final bool rwAbove = (rw.likelihood >= WRIST_VIS_THR) &&
          (nRw[1] < nNose[1] - WRIST_ABOVE_HEAD_MARGIN);
      final bool grip = lwAbove || rwAbove;

      if (visStrictOk && grip && (torsoDxNorm <= TORSO_X_THR)) {
        onbarStreak += 1;
        offbarStreak = 0;
      } else {
        offbarStreak += 1;
        onbarStreak = 0;
      }

      if (!onbar && onbarStreak >= ONBAR_MIN_FRAMES) {
        onbar = true;
        ascBaseHead = null;
        allowNewPeak = true;
        swingStreak = 0;
        bottomPhaseMaxElbow = null;
        cycleGripSamples.clear();
      }

      if (onbar && offbarStreak >= OFFBAR_MIN_FRAMES) {
        onbar = false;
        offbarFramesSinceAnyRep = 0;
        bottomPhaseMaxElbow = null;
      }

      if (!onbar && repCount > 0) {
        offbarFramesSinceAnyRep += 1;
        // No early break. Same reasoning as the pushup analyzer: we let
        // the loop run to the end of the video so frameTelemetry covers
        // every frame. The widget keeps showing the last counter value
        // and an empty (or last-seen) skeleton until pose returns.
      }

      // ---- Chin-up grip width sample (on-bar, front/back view only) ----
      if (checkGripWidth &&
          onbar &&
          lw.likelihood >= WRIST_VIS_THR &&
          rw.likelihood >= WRIST_VIS_THR) {
        final double shoulderSpan = (nLsh[0] - nRsh[0]).abs();
        if (shoulderSpan >= GRIP_MIN_SHOULDER_SPAN) {
          final double wristSpan = (nLw[0] - nRw[0]).abs();
          cycleGripSamples.add(wristSpan / shoulderSpan);
        }
      }

      // ---- Counting (only ON-BAR) ----
      final double headVel = headPrev == null ? 0.0 : (headY - headPrev!);

      if (onbar && visStrictOk) {
        // Per-ascent baseline. We start the baseline when the head
        // begins moving up (negative velocity in image-y coords), and
        // we re-baseline if the user descends past 2x RESET_DESCENT
        // before reaching the top (so a fresh attempt gets a fresh
        // baseline).
        if (ascBaseHead == null) {
          if (headVel < -HEAD_VEL_UP_TINY) {
            ascBaseHead = headY;
          }
        } else {
          if ((headY - ascBaseHead!) > (RESET_DESCENT * 2)) {
            ascBaseHead = headY;
          }
        }

        final double ascentAmt =
            ascBaseHead == null ? 0.0 : (ascBaseHead! - headY);
        final bool atTop =
            (elbowAngle <= ELBOW_TOP_ANGLE) && (ascentAmt >= HEAD_MIN_ASCENT);
        final bool canCnt = (frameIdx - lastPeakFrame) >= REFRACTORY_FRAMES;

        if (atTop && allowNewPeak && canCnt) {
          repCount += 1;
          goodReps += 1;
          allScores.add(10.0);
          repReports.add({
            'rep_index': repCount,
            'top_elbow': elbowAngle,
            'ascent_from': ascBaseHead != null ? ascBaseHead! : headY,
            'peak_head_y': headY,
          });
          lastPeakFrame = frameIdx;
          allowNewPeak = false;
          bottomAlreadyReported = false;
          // Start tracking bottom-phase max elbow for THIS rep's
          // descent. Both arms — we use whichever extends further.
          bottomPhaseMaxElbow = math.max(rawElbowL, rawElbowR);

          // Per-rep apex tracking starts here. The apex is initially
          // the headY at the count frame; we'll update it on each
          // subsequent frame until reset.
          currentRepApexHeadY = headY;
          currentRepBaseHeadY = ascBaseHead;
          currentRepCountFrameIdx = frameIdx;
          currentRepHadSwing = false;
          currentRepHadBottomMiss = false;

          // Queue a pulse event. The visible flash/haptic/sound is
          // placed at the visual peak in post-process. The shallow /
          // swing / bottom flags are filled in at reset (next block).
          pulseEvents.add({
            'countFrameIdx': frameIdx,
            'topElbow': elbowAngle,
            'prevRepCount': repCount - 1,
            'newRepCount': repCount,
          });
          repShallowFlags.add(false);
          repSwingFlags.add(false);
          repBottomFlags.add(false);
          repGripFlags.add(false);
        }

        // Track maximum elbow extension during the descent until reset.
        if (!allowNewPeak) {
          final double cand = math.max(rawElbowL, rawElbowR);
          bottomPhaseMaxElbow = bottomPhaseMaxElbow == null
              ? cand
              : math.max(bottomPhaseMaxElbow!, cand);
        }

        // Track the current rep's apex (smallest headY = highest body)
        // until we re-arm. This drives both the post-process visual
        // peak placement AND the new HIGHER cue evaluation at reset.
        if (!allowNewPeak &&
            currentRepApexHeadY != null &&
            headY < currentRepApexHeadY!) {
          currentRepApexHeadY = headY;
        }

        // Re-arm conditions: enough descent OR enough elbow extension.
        final bool resetByDesc =
            ascBaseHead != null && (headY - ascBaseHead!) >= RESET_DESCENT;
        final bool resetByElb = elbowAngle >= RESET_ELBOW;

        if (resetByDesc || resetByElb) {
          // ---- BOTTOM extension check (unchanged behavior) ----
          if (!bottomAlreadyReported) {
            final double effectiveMax =
                bottomPhaseMaxElbow ?? math.max(rawElbowL, rawElbowR);
            if (effectiveMax < (BOTTOM_EXT_MIN_ANGLE - BOTTOM_HYST_DEG)) {
              bottomFailCount += 1;
              currentRepHadBottomMiss = true;
              if (bottomFailCount >= BOTTOM_FAIL_MIN_REPS) {
                sessionFeedback.add(FB_CUE_BOTTOM);
              }
            } else {
              // Good extension this rep → decay the counter (with a
              // floor at zero) so a stretch of good reps reverses the
              // session-level cue. Same behavior as Python.
              bottomFailCount = math.max(0, bottomFailCount - 1);
            }
            bottomAlreadyReported = true;
          }

          // ---- HIGHER cue evaluation (relaxed, per-rep apex) ----
          //
          // Now that the rep has finished its arc and the user is
          // re-arming for the next one, we know the FULL ascent the
          // user achieved this rep. If apex-from-base was less than
          // HIGHER_REP_MIN_ASCENT (a stricter bar than the counting
          // threshold HEAD_MIN_ASCENT), this rep was shallow. We
          // accumulate shallow reps and surface the session cue only
          // after HIGHER_FAIL_MIN_REPS of them — same min-reps policy
          // as the bottom check.
          //
          // The shallow flag is also stored on the rep's pulse event,
          // so the post-process pass can mark this specific rep as
          // 'bad' (orange flash) and place the cue at the rep's peak.
          bool repWasShallow = false;
          if (currentRepApexHeadY != null && currentRepBaseHeadY != null) {
            final double repAscent =
                currentRepBaseHeadY! - currentRepApexHeadY!;
            if (repAscent < HIGHER_REP_MIN_ASCENT) {
              repWasShallow = true;
              higherFailCount += 1;
              if (higherFailCount >= HIGHER_FAIL_MIN_REPS &&
                  !higherAlreadyReported) {
                sessionFeedback.add(FB_CUE_HIGHER);
                higherAlreadyReported = true;
              }
            } else {
              // Decay so a streak of clearly-good reps eventually
              // suppresses the cue (matches the bottom check pattern).
              higherFailCount = math.max(0, higherFailCount - 1);
            }
          }

          // ---- GRIP width evaluation (chin-up only) ----
          // Median of the cycle's wrist/shoulder span ratios. Evaluated
          // only when a rep was actually counted in this cycle and we
          // have enough front/back-view samples.
          bool repGripWide = false;
          if (checkGripWidth &&
              currentRepCountFrameIdx != null &&
              cycleGripSamples.length >= GRIP_MIN_SAMPLES) {
            final double ratio = medianOf(cycleGripSamples);
            if (ratio > GRIP_WIDE_RATIO) {
              repGripWide = true;
              gripFailCount += 1;
              if (gripFailCount >= GRIP_FAIL_MIN_REPS && !gripAlreadyReported) {
                sessionFeedback.add(FB_CUE_GRIP);
                gripAlreadyReported = true;
              }
            } else {
              gripFailCount = math.max(0, gripFailCount - 1);
            }
          }
          cycleGripSamples.clear();

          // ---- Attach per-rep flags to the rep that just finished ----
          // pulseEvents and repShallowFlags / repSwingFlags / repBottomFlags
          // are kept in lock-step. The last-pushed rep is always the one
          // we just evaluated.
          if (pulseEvents.isNotEmpty) {
            final int lastIdx = pulseEvents.length - 1;
            repShallowFlags[lastIdx] = repWasShallow;
            repSwingFlags[lastIdx] = currentRepHadSwing;
            repBottomFlags[lastIdx] = currentRepHadBottomMiss;
            repGripFlags[lastIdx] = repGripWide;
          }

          // ---- Donut calibration: handled in post-process ----
          // The previous version learned _donutFullAscent online with
          // an EMA. That was a running ESTIMATE of the user's range,
          // which always lagged on the first rep and never quite
          // reached the true peak even on later reps. Since we have
          // the entire video available offline, the post-process pass
          // below normalizes against the actual GLOBAL peak ascent —
          // an exact answer instead of an estimate. The user's deepest
          // rep reads exactly 100%, shallower reps read proportionally.

          // Reset per-rep apex tracking for the next attempt.
          currentRepApexHeadY = null;
          currentRepBaseHeadY = null;
          currentRepCountFrameIdx = null;
          // Reset donut state for the next rep — baseline will be
          // re-captured on the descent, peak ascent goes back to 0.
          donutBaselineHeadY = null;
          donutPeakAscent = 0.0;

          allowNewPeak = true;
          ascBaseHead = headY;
          bottomPhaseMaxElbow = null;
        }

        // ---- HIGHER cue: REMOVED from in-loop ----
        //
        // The previous in-loop check fired any time the user was
        // mid-ascent and hadn't reached HEAD_MIN_ASCENT*0.7 yet —
        // which is most of every ascent — so the cue effectively
        // fired on every rep. The cue is now evaluated ONLY at reset
        // time using the actual apex of the rep (see block above).
        // That gives us a real "did the user actually get high
        // enough this rep?" answer instead of an over-eager
        // mid-ascent guess.

        // Kipping / body swing detection. We accumulate a streak of
        // high-lateral-motion frames and trip the cue once it crosses
        // SWING_MIN_STREAK. We tag the CURRENTLY-IN-PROGRESS rep
        // (currentRepHadSwing) so that in post-process the rep's
        // verdict + flash + cue placement reflect the swing rather
        // than firing arbitrarily mid-ascent.
        if (torsoDxNorm > SWING_THR) {
          swingStreak += 1;
        } else {
          swingStreak = math.max(0, swingStreak - 1);
        }
        if (swingStreak >= SWING_MIN_STREAK) {
          // Tag the rep currently in progress (if any) — this is
          // either the rep being descended-from (after a count) or
          // the upcoming attempt. Either way the user IS swinging
          // right now, so the rep that's open should be marked.
          if (currentRepCountFrameIdx != null) {
            currentRepHadSwing = true;
          }
          // [FEEDBACK-SYNC] Note: this session-level add can fire with
          // NO rep in progress (before the first count, or between
          // reps after reset) — in that case no rep flag is set and no
          // banner will ever be shown for it. The post-process sync
          // below removes it from the summary in that case, so the
          // returned feedback always matches the video.
          if (!swingAlreadyReported) {
            sessionFeedback.add(FB_CUE_SWING);
            swingAlreadyReported = true;
          }
        }
      } else {
        ascBaseHead = null;
        allowNewPeak = true;
        swingStreak = 0;
        bottomPhaseMaxElbow = null;
      }

      // NOTE: in-loop feedback rendering is intentionally null. All
      // cue text is placed in the post-process pass at the rep's
      // visual peak (see below). curRt / rtFbHold / rtFbMsg are kept
      // as variables so the file's structure stays parallel to the
      // pushup analyzer's flow, but they no longer drive the displayed
      // 'feedback' field — that's overwritten entirely by post-process.

      frameTelemetry.add({
        't': tSec,
        'reps': repCount,
        'depth': heightLive, // legacy key for the donut widget
        'metric_label': 'HEIGHT',
        'metric_value': heightLive,
        'feedback': null, // post-process places the real feedback
        'rep_just_finished': repJustFinished, // cleared/placed in post-process
        'landmarks': normLandmarks,
      });
      repJustFinished = null;
      headYByFrame.add(headY);
      noseYRawByFrame.add(headRaw);
      rawAscentByFrame.add(ascentNow);

      headPrev = headY;
    }

    // ---- End-of-video flush ----
    // If the video ends with the user still at/near the top of a rep
    // (no descent was detected), the per-rep evaluation block inside
    // the loop never ran for that final rep. Run it now so the last
    // rep gets the same treatment as the others — apex compared to
    // HIGHER_REP_MIN_ASCENT for shallow detection, swing/bottom flags
    // attached, and the post-process pass can place its peak verdict.
    if (currentRepApexHeadY != null &&
        currentRepBaseHeadY != null &&
        pulseEvents.isNotEmpty) {
      final double repAscent = currentRepBaseHeadY! - currentRepApexHeadY!;
      bool repWasShallow = false;
      if (repAscent < HIGHER_REP_MIN_ASCENT) {
        repWasShallow = true;
        higherFailCount += 1;
        if (higherFailCount >= HIGHER_FAIL_MIN_REPS && !higherAlreadyReported) {
          sessionFeedback.add(FB_CUE_HIGHER);
          higherAlreadyReported = true;
        }
      }
      // Bottom check: at end-of-video we don't have a guaranteed
      // descent, so we use whatever the running bottomPhaseMaxElbow
      // is as a best-effort. If it's null (no tracking yet), we
      // skip the bottom flag — better than a false positive.
      bool repHadBottomMiss = false;
      if (bottomPhaseMaxElbow != null && !bottomAlreadyReported) {
        if (bottomPhaseMaxElbow! < (BOTTOM_EXT_MIN_ANGLE - BOTTOM_HYST_DEG)) {
          repHadBottomMiss = true;
          bottomFailCount += 1;
          if (bottomFailCount >= BOTTOM_FAIL_MIN_REPS) {
            sessionFeedback.add(FB_CUE_BOTTOM);
          }
        }
      }
      // Grip check for the final (unreset) rep.
      bool repGripWide = false;
      if (checkGripWidth && cycleGripSamples.length >= GRIP_MIN_SAMPLES) {
        final double ratio = medianOf(cycleGripSamples);
        if (ratio > GRIP_WIDE_RATIO) {
          repGripWide = true;
          gripFailCount += 1;
          if (gripFailCount >= GRIP_FAIL_MIN_REPS && !gripAlreadyReported) {
            sessionFeedback.add(FB_CUE_GRIP);
            gripAlreadyReported = true;
          }
        }
      }
      final int lastIdx = pulseEvents.length - 1;
      repShallowFlags[lastIdx] = repWasShallow;
      repSwingFlags[lastIdx] = currentRepHadSwing;
      repBottomFlags[lastIdx] = repHadBottomMiss;
      repGripFlags[lastIdx] = repGripWide;
    }
  } finally {
    await poseDetector.close();
    try {
      framesDir.deleteSync(recursive: true);
    } catch (_) {}
  }

  // ============================================================
  // POST-PROCESS 1/2: Donut normalization
  //
  // The donut is purely a visual indicator. It uses a FIXED absolute
  // threshold for "100%" — not a dynamic per-rep or per-video peak.
  // Behavior:
  //   - Head ascent ≥ DONUT_FULL_ASCENT → donut reads 100%.
  //     Going higher than that doesn't add — it stays clamped at 100%.
  //   - Head ascent < DONUT_FULL_ASCENT → donut reads proportionally
  //     (e.g. half the threshold = 50%). This gives the smooth,
  //     responsive climb across the rep that you'd expect.
  //   - At rest / dead hang → 0%.
  //
  // DONUT_FULL_ASCENT = 0.08 (8% of frame height). Calibrated so that
  // a clean chin-over-bar rep crosses the threshold and reads 100%,
  // while mid-ascent reads honestly below 100%.
  //
  // IMPORTANT: this constant is for VISUALS only. It is completely
  // independent of HIGHER_REP_MIN_ASCENT (which controls the "Go
  // higher" cue at the analysis level). Tweaking DONUT_FULL_ASCENT
  // changes only how the donut looks; it does NOT change which reps
  // are flagged as shallow, the rep count, or any score.
  //
  // Tuning:
  //   - Donut not reaching 100% on visibly clean reps → lower this.
  //   - Donut hitting 100% before the user is fully up → raise this.
  const double DONUT_FULL_ASCENT = 0.06;

  // First, compute the raw normalized value per frame.
  final List<double> donutRaw = List<double>.filled(frameTelemetry.length, 0.0);
  for (int i = 0;
      i < frameTelemetry.length && i < rawAscentByFrame.length;
      i++) {
    donutRaw[i] =
        (rawAscentByFrame[i] / DONUT_FULL_ASCENT).clamp(0.0, 1.0).toDouble();
  }

  // ---- Temporal smoothing (zero-phase) ----
  //
  // Pure raw values can feel "choppy" because the head's vertical
  // position has small frame-to-frame jitter from ML Kit and from
  // sub-pixel motion. The eye reads the donut as snapping between
  // adjacent values rather than gliding.
  //
  // We smooth with a small EMA, but apply it twice — once forward,
  // once backward — then average. This is a standard zero-phase
  // smoother: a single forward EMA introduces a phase lag (the
  // smoothed value trails the real motion by a few frames), which
  // would make the donut feel "behind" the body on screen. Forward+
  // backward+average cancels that lag while keeping the smoothing
  // benefit. Result: visually buttery, but still arriving at 100%
  // exactly when the body reaches its peak.
  //
  // SMOOTH_ALPHA = 0.45 is light: enough to remove jitter, not so
  // much that the donut lazily lingers behind. Lower values smooth
  // more (e.g. 0.3); higher values smooth less (e.g. 0.6).
  const double SMOOTH_ALPHA = 0.45;
  final List<double> fwd = List<double>.filled(donutRaw.length, 0.0);
  final List<double> bwd = List<double>.filled(donutRaw.length, 0.0);
  if (donutRaw.isNotEmpty) {
    fwd[0] = donutRaw[0];
    for (int i = 1; i < donutRaw.length; i++) {
      fwd[i] = SMOOTH_ALPHA * donutRaw[i] + (1 - SMOOTH_ALPHA) * fwd[i - 1];
    }
    bwd[donutRaw.length - 1] = donutRaw[donutRaw.length - 1];
    for (int i = donutRaw.length - 2; i >= 0; i--) {
      bwd[i] = SMOOTH_ALPHA * donutRaw[i] + (1 - SMOOTH_ALPHA) * bwd[i + 1];
    }
  }

  for (int i = 0; i < frameTelemetry.length; i++) {
    final double smoothed =
        ((fwd[i] + bwd[i]) / 2.0).clamp(0.0, 1.0).toDouble();
    // Take the max of smoothed and raw. Why: the zero-phase smoothing
    // averages each frame with its neighbors, which slightly LOWERS
    // the peaks (the highest raw value gets averaged with the slightly-
    // lower frames around it, so the smoothed peak ends up ~80-85% of
    // the raw peak). For the climb that's fine — exactly the buttery
    // feel we want — but at the top of a clean rep we lose the
    // guarantee that good reps reach 100%.
    //
    // max(smoothed, raw) gives us both: the smoothed value dominates
    // during the climb (because it's similar to the raw on the way up
    // anyway), but raw wins at the actual peak since it's the only
    // one that reaches the clamp ceiling. The transition is invisible
    // because the smoothed and raw values are within a few percent
    // of each other except at the peak itself.
    final double raw = donutRaw[i];
    final double finalVal = math.max(smoothed, raw);
    frameTelemetry[i]['depth'] = finalVal;
    frameTelemetry[i]['metric_value'] = finalVal;
  }

  // ============================================================
  // POST-PROCESS 2/2: place rep_just_finished pulses + cue text at the
  // visual peak of each rep, and assign a per-rep verdict.
  //
  // For pull-ups the visual peak is the frame within an ascent window
  // after the count where the nose Y is SMALLEST (head highest in the
  // image). The elbow already hit "below 100°" at the count frame and
  // may not drop much further in the few frames after — but the head
  // usually keeps rising for another 2-5 frames as the user finishes
  // the pull. That's the moment the eye registers as "top of pull-up".
  //
  // Per-rep verdicts:
  //   - 'bad'  → at least one form flag fired for this rep AND the
  //              corresponding session-level cue is active. The widget
  //              renders this as an ORANGE skeleton flash + cue text
  //              held on screen at the peak.
  //   - 'good' → no form flags. GREEN flash, no text.
  //
  // The cue text shown at the peak is whichever flag fired, joined
  // with newlines if multiple. The widget's hold logic keeps the
  // message visible for 1.5s afterwards.
  //
  // Window: from countFrameIdx forward, up to either
  //   (a) the next pulse event's countFrameIdx, OR
  //   (b) MAX_PEAK_LOOKAHEAD frames (safety bound).
  // ============================================================
  const int MAX_PEAK_LOOKAHEAD = 25; // ~1.25s @ 20fps

  // Clear any feedback / rep_just_finished left in the per-frame
  // telemetry from the loop. The loop set 'feedback' from the rolling
  // RT hold buffer, but we want the cue text to live ONLY in the rep's
  // peak-aligned window so the user sees it exactly when their body
  // reaches the (insufficient) top — not earlier in the ascent.
  for (final f in frameTelemetry) {
    f['rep_just_finished'] = null;
    f['feedback'] = null;
  }

  // Frames per second feedback hold around the peak (matches the
  // widget's 1.5s hold elsewhere).
  final int holdFramesPeak = math.max(2, (1.5 / dt).round());

  // Reset goodReps / badReps so we recompute them from the per-rep
  // verdict we're about to place.
  goodReps = 0;
  badReps = 0;

  // [FEEDBACK-SYNC] Every cue actually WRITTEN into frame telemetry
  // (i.e. shown as an in-video banner) is recorded here. After this
  // pass, sessionFeedback is overwritten with this set — the in-video
  // banners are the single source of truth for the summary.
  final Set<String> displayedCues = {};

  for (int e = 0; e < pulseEvents.length; e++) {
    final ev = pulseEvents[e];
    final int countIdx = (ev['countFrameIdx'] as int) - 1; // 0-based
    if (countIdx < 0 || countIdx >= frameTelemetry.length) continue;

    final int nextCountIdx = e + 1 < pulseEvents.length
        ? (pulseEvents[e + 1]['countFrameIdx'] as int) - 1
        : frameTelemetry.length;
    final int windowEnd = math.min(
      frameTelemetry.length,
      math.min(nextCountIdx, countIdx + MAX_PEAK_LOOKAHEAD),
    );

    // Find visual peak: the FIRST frame where noseYRaw enters its
    // plateau-near-minimum, not the absolute argmin.
    //
    // Why not just argmin?
    //   1. Plateau ties: at the top of a pull-up the head often sits
    //      essentially still for 2-3 frames (the user holds the
    //      contraction briefly, or the camera samples while motion is
    //      below the noise floor). argmin returns the LAST of those
    //      tied frames, which feels visibly late.
    //   2. Detection noise: ML Kit's nose landmark can drift up by ~1
    //      frame-pixel even after the body has clearly started
    //      descending — argmin will latch onto that spurious frame.
    //   3. Anatomy lag: the chin clears the bar (the moment the eye
    //      registers as "top") slightly before the nose reaches its
    //      own absolute peak, because the head tilts back slightly as
    //      the user finishes the rep. The chin's crossing happens at
    //      the FRONT of the head's plateau, not the back.
    //
    // Algorithm: do a two-pass scan.
    //   Pass 1 — find absoluteMin in the window.
    //   Pass 2 — walk forward from countIdx and pick the FIRST frame
    //            within PEAK_PLATEAU_EPS of absoluteMin. That is "the
    //            moment the user reached the top", as the eye sees it.
    //
    // PEAK_PLATEAU_EPS is in normalized image-Y units (range 0..1).
    // 0.004 ≈ 0.4% of frame height — about 4-5 pixels at 1080p — small
    // enough that anything inside the band is visually indistinguishable
    // from the absolute peak, but large enough to absorb detection
    // jitter.
    const double PEAK_PLATEAU_EPS = 0.004;

    int peakIdx = countIdx;
    double? minNoseY;
    for (int i = countIdx; i < windowEnd; i++) {
      if (i >= noseYRawByFrame.length) break;
      final nY = noseYRawByFrame[i];
      if (nY == null) continue;
      if (minNoseY == null || nY < minNoseY) {
        minNoseY = nY;
      }
    }
    if (minNoseY != null) {
      // Walk forward from the count and pick the first frame that's
      // within PEAK_PLATEAU_EPS of the absolute minimum. That frame is
      // visually "at the top" but typically lands 1-3 frames earlier
      // than argmin, which is exactly the perceptual offset we want
      // to remove.
      for (int i = countIdx; i < windowEnd; i++) {
        if (i >= noseYRawByFrame.length) break;
        final nY = noseYRawByFrame[i];
        if (nY == null) continue;
        if (nY <= minNoseY + PEAK_PLATEAU_EPS) {
          peakIdx = i;
          break;
        }
      }
    }
    ev['peakIdx'] = peakIdx;

    // Frames between count and peak keep the OLD rep count so the
    // visible counter ticks at the peak frame, synchronized with the
    // skeleton flash + haptic + sound.
    final int prevRC = (ev['prevRepCount'] as int?) ?? 0;
    for (int i = countIdx; i < peakIdx; i++) {
      frameTelemetry[i]['reps'] = prevRC;
    }

    // ---- Per-rep cues: only those whose session-level cue actually
    // fired count towards a 'bad' verdict for this rep. A rep that
    // was shallow but sat below HIGHER_FAIL_MIN_REPS won't be marked
    // bad on its own, because the session never raised that cue. ----
    final List<String> repCues = [];
    final bool wasShallow =
        e < repShallowFlags.length ? repShallowFlags[e] : false;
    final bool hadSwing = e < repSwingFlags.length ? repSwingFlags[e] : false;
    final bool hadBottomMiss =
        e < repBottomFlags.length ? repBottomFlags[e] : false;
    final bool hadWideGrip = e < repGripFlags.length ? repGripFlags[e] : false;

    if (wasShallow && sessionFeedback.contains(FB_CUE_HIGHER)) {
      repCues.add(FB_CUE_HIGHER);
    }
    if (hadBottomMiss && sessionFeedback.contains(FB_CUE_BOTTOM)) {
      repCues.add(FB_CUE_BOTTOM);
    }
    if (hadSwing && sessionFeedback.contains(FB_CUE_SWING)) {
      repCues.add(FB_CUE_SWING);
    }
    if (hadWideGrip && sessionFeedback.contains(FB_CUE_GRIP)) {
      repCues.add(FB_CUE_GRIP);
    }

    final bool isBad = repCues.isNotEmpty;
    if (isBad) {
      badReps += 1;
    } else {
      goodReps += 1;
    }

    // Place verdict at the peak.
    frameTelemetry[peakIdx]['rep_just_finished'] = isBad ? 'bad' : 'good';

    // Place the cue text starting AT the peak and held for 1.5s. We
    // intentionally don't paint cue text before the peak: the user's
    // body is still rising (or transitioning) and a "go higher" cue
    // before they've actually finished is misleading. At the peak
    // they've just reached their max height for this rep, which is
    // exactly when the cue is honest.
    if (isBad) {
      final String fb = repCues.join('\n');
      final int holdEnd =
          math.min(frameTelemetry.length - 1, peakIdx + holdFramesPeak);
      for (int i = peakIdx; i <= holdEnd; i++) {
        // Don't bleed into the next rep's count frame. If a follow-up
        // rep starts before the hold ends, the cue clears at that
        // frame so the next rep begins clean.
        if (e + 1 < pulseEvents.length) {
          final int nextCnt = (pulseEvents[e + 1]['countFrameIdx'] as int) - 1;
          if (i >= nextCnt) break;
        }
        frameTelemetry[i]['feedback'] = fb;
      }
      // [FEEDBACK-SYNC] These cues were actually written to at least
      // one frame (the loop above always writes the peak frame, since
      // peakIdx < nextCountIdx by construction). Record them as
      // displayed.
      displayedCues.addAll(repCues);
    }
  }

  // ============================================================
  // [FEEDBACK-SYNC] The in-video banners placed above are the single
  // source of truth. Overwrite sessionFeedback with exactly the set of
  // cues that were displayed, so the returned `feedback` list (and the
  // technique-score penalty derived from it) always matches what the
  // user sees in the video.
  //
  // This closes the leak paths where a cue could sit in sessionFeedback
  // WITHOUT any banner having been shown:
  //   - SWING raised while no rep was open (before the first count, or
  //     between reps after reset) — no rep flag set → no banner.
  //   - Any cue whose flagged rep(s) fell outside the telemetry window.
  // Cues WITH banners are always in sessionFeedback already (the
  // per-rep gating above requires `sessionFeedback.contains`), so this
  // is a pure intersection — it can only remove undisplayed cues,
  // never add.
  // ============================================================
  sessionFeedback
    ..clear()
    ..addAll(displayedCues);

  // ================ 5) Aggregate session ================
  // Same scoring as Python: 10.0 minus sum of cue weights, floored to
  // nearest 0.5. If no cues fired, score is exactly 10.0.
  double techniqueScore;
  if (repCount == 0) {
    techniqueScore = 0.0;
  } else {
    double penalty = 0.0;
    if (sessionFeedback.isNotEmpty) {
      for (final m in sessionFeedback) {
        penalty += FB_WEIGHTS[m] ?? FB_DEFAULT_WEIGHT;
      }
      penalty = math.max(PENALTY_MIN_IF_ANY, penalty);
    }
    techniqueScore = halfFloor10(math.max(0.0, 10.0 - penalty));
  }

  // Final feedback list. If no cues, return the encouragement string
  // exactly as Python does. If reps are 0, return a generic message
  // (matching the pushup analyzer's pattern for consistency in the UI).
  final List<String> feedbackList;
  if (repCount == 0) {
    feedbackList = <String>[
      "Couldn't analyze this video — make sure your full body is visible and that you complete at least one pull-up."
    ];
  } else if (sessionFeedback.isNotEmpty) {
    feedbackList =
        CUE_PRIORITY.where((cue) => sessionFeedback.contains(cue)).toList();
  } else {
    feedbackList = <String>['Great form! Keep it up 💪'];
  }

  final String fileUri = 'file://$videoPath';

  final Map<String, dynamic> result = {
    'squat_count': repCount,
    'technique_score': techniqueScore,
    'technique_score_display': displayHalfStr(techniqueScore),
    'technique_label': scoreLabel(techniqueScore),
    'good_reps': goodReps,
    'bad_reps': badReps,
    'feedback': feedbackList,
    'tips': <String>[],
    'reps': repReports,
    'exercise_type': 'pullup',
    'pullup_variant': variantName,
    'video_path': fileUri,
    'analyzed_fps': fps,
    'frame_count': frameIdx,
    '_source_video_uri': fileUri,
    '_frame_telemetry': frameTelemetry,
  };
  if (feedbackList.isNotEmpty && repCount > 0 && sessionFeedback.isNotEmpty) {
    result['primary_form_error'] = feedbackList.first;
  }
  return result;
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
