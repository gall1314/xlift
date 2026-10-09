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
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_litert/flutter_litert.dart';
import 'package:xlift_models/xlift_models.dart';

/// TEST VERSION v5 of the deadlift analyzer.
///
/// v5 = v4 with BARBELL RESCUE TURNED ON.
///
/// This is the first version where the barbell signal can ACTUALLY change
/// the rep count vs the pure-pose v3/production analyzer. Specifically:
/// a candidate rep that the strict pose gates REJECTED can be COUNTED if
/// the barbell strongly confirmed it. The rescue is intentionally narrow
/// so it never overrules a clear "no" from pose — it only catches the
/// borderline cases where pose was unsure.
///
/// What's new vs v3:
///
/// [SPEED-1] Skip YOLO when the lifter is clearly STANDING (between reps).
///   We don't have an EMA yet during the first pass, so we use a cheap proxy:
///   a rolling-min of hipY over the last ~2s. If the current hipY is within
///   `STANDING_HIPY_MARGIN` of that rolling min and we have enough samples,
///   the lifter is at standing baseline — skip YOLO. Saves a meaningful
///   fraction of inference calls on a typical set (long rest between reps).
///
/// [SPEED-2] Faster preprocessing.
///   Instead of `canvas.getPixel(x, y)` per pixel (which is slow in the
///   `image` package), we get the underlying byte buffer once via
///   `canvas.getBytes()` and read it in a flat loop. Same letterbox math,
///   same model input, ~2x faster preprocessing.
///
/// [FUSION-1] Per-rep barbell motion metrics in `_RepInfo`.
///   For every committed rep we compute:
///     - `barDetRate`: fraction of rep frames with the bar detected
///     - `barYRange`:  vertical motion of the bbox center within the rep
///                     (in original-frame normalized units)
///     - `barMeanConf`: average confidence on detected frames
///     - `wristBarDist`: average wrist↔bbox-center distance (when both
///                       are present), in normalized image coords
///
/// [FUSION-2] *** RESCUE ENABLED *** — barbell-assisted rep confirmation.
///   A candidate that the strict pose gates rejected can be COUNTED when
///   all of the following hold:
///     1. The video is not static / not-a-deadlift (safety floors).
///     2. The candidate's hold-deep and duration gates passed (these are
///        noise filters — we never rescue obvious noise blips).
///     3. The peak signal is in the borderline band
///        [BORDERLINE_PEAK_MIN, BORDERLINE_PEAK_MAX].
///     4. EXACTLY ONE other soft gate failed (not multiple — we never
///        rescue a candidate that pose strongly disagrees with).
///     5. The bar was detected on ≥`BAR_CONFIRM_DET_RATE` of rep frames
///        AND moved vertically by ≥`BAR_CONFIRM_Y_RANGE` AND stayed
///        within `BAR_CONFIRM_WRIST_DIST` of the lifter's wrists.
///   In `diagCandidates` each entry carries `committedStrict`,
///   `rescuedByBar`, and `barbell` so we can audit every decision.
///
/// Same letterbox preprocessing, top-K aspect filter, and reverse mapping
/// as v3/v4. Same return shape.
///
/// each frame also runs through the YOLOv8 barbell detector. The barbell
/// bounding box is stored in per-frame telemetry under `barbell_bbox` so the
/// player widget can render it alongside the pose skeleton.
///
/// This action does NOT use barbell detection as a gate for rep validation
/// yet — it only collects data. Once we verify the model performs well on
/// real videos, we can fold `barbellOk` into the commit condition in the
/// production action.
///
/// v3 improvements over v2 (all aim at making YOLO more accurate):
///   1. JPG quality bumped from -q:v 4 → -q:v 2. Less compression noise
///      around the thin barbell silhouette.
///   2. Pre-resize ceiling raised from min(720,iw) → min(1280,iw). Was
///      forcing iPhone 1080p videos through two consecutive downsamples
///      (1080→720→320 for YOLO); now goes 1080→320 directly, keeping the
///      bar much sharper. ML Kit pose handles 1280-wide fine.
///   3. Aspect-ratio sanity filter on YOLO predictions. Take the top-10
///      candidates and prefer the highest-confidence one with width/height
///      >= 2.5 (bar-shaped). Falls back to argmax if nothing qualifies.
///      Cleans up the case where the model gives moderate confidence to a
///      square region around a plate instead of the bar itself.
///
/// v2 fix: switched YOLO preprocessing from STRETCH (resize directly to
/// 320x320) to LETTERBOX (aspect-preserving resize + black-bar pad),
/// matching the "Resize Fit (black edges)" preprocessing used in Roboflow
/// training. The bbox is mapped back to original-frame normalized coords
/// before being stored in telemetry, so the widget side needs no change.
Future<dynamic> analyzeDeadliftWithBarbellTest(
  FFUploadedFile videoFile,
  double? targetFps,
) async {
  // [DIAG] Diagnostic data attached to result['debug'].
  final List<Map<String, dynamic>> diagCandidates = [];
  Map<String, dynamic>? diagCalib;
  Map<String, dynamic>? diagWalkout;
  Map<String, dynamic>? diagOutlier;
  Map<String, dynamic>? diagFinal;

  // ================ Parameters ================
  final double fps = (targetFps ?? 10.0).clamp(4.0, 30.0);
  final double dt = 1.0 / fps;

  const double VIS_MIN = 0.15;

  const double T_DEEP = 0.55;
  const double T_RESET = 0.30;
  const double MIN_HOLD_DEEP_SEC = 0.3;
  const double MIN_BETWEEN_REPS_SEC = 0.8;
  const double BASELINE_LOOKBACK_SEC = 2.0;
  // [DUR-FILTER] A real deadlift rep — even a fast one — runs at least
  // ~1s end-to-end above T_RESET. Sub-second "reps" are pose-detection
  // noise spikes that briefly cross T_DEEP and drop back. The hold-deep
  // gate (MIN_HOLD_DEEP_SEC=0.3) is too short to filter these out, so
  // we add a TOTAL rep duration gate of 0.7s.
  //
  // Why this matters beyond the obvious: a 0.4s noise spike near the
  // start of the video gets a deceptively GOOD lockout EMA (the body
  // is at rest right after), which then becomes v10's "best rep"
  // baseline and triggers v10 to remove every real rep as an outlier.
  // The fix is upstream — never let the spike become a committed rep.
  const double MIN_REP_DURATION_SEC = 0.7;

  const double MAX_HIPX_RANGE_WALK = 0.15;
  const double LATERAL_GATE_PEAK_TH = 0.80;
  const double LATERAL_GATE_RATIO_TH = 0.70;

  // [v10 LOCKOUT-EMA OUTLIER REMOVAL]
  //
  // After all reps are committed, look at the true minimum EMA each
  // rep reaches in its 2-second lockout-search window. A real rep
  // ends with the lifter standing back up — its lockout EMA drops
  // close to the lifter's "standing baseline" in that video.
  //
  // Baseline: MEDIAN of the per-rep lockout EMAs (not the minimum).
  // A median ignores a single anomaly at either end — a brief
  // motion blip with an unusually low lockoutEma (because the body
  // happens to be still right after) doesn't drag the baseline
  // down and falsely make every real rep look like an outlier.
  // Likewise, one unusually high lockout doesn't drag it up.
  //
  // Gap of 0.20 (slightly looser than the original 0.15) allows
  // real reps to vary naturally — camera angle, lifter style — by
  // up to ~0.2 from the median before being treated as outliers.
  // Still cleanly catches blatant fakes (the original calibration
  // case had a gap of 0.345 from the median to the fake rep).
  //
  // Requires 3+ committed reps so the median is meaningful.
  const int OUTLIER_MIN_REPS = 3;
  const double OUTLIER_ABS_GAP = 0.20;

  const double DEPTH_EXCELLENT_PEAK = 0.85;
  const double DEPTH_GOOD_PEAK = 0.70;
  const double DEPTH_FAIR_PEAK = 0.55;
  const double KNEE_DROP_EXCELLENT = 60.0;
  const double KNEE_DROP_GOOD = 40.0;
  const double KNEE_DROP_FAIR = 25.0;
  const double HIP_DESC_EXCELLENT = 0.10;
  const double HIP_DESC_GOOD = 0.05;
  const double HIP_DESC_FAIR = 0.02;

  const String FB_ERROR_DEPTH = 'Go deeper into the hinge';
  const String FB_ERROR_LOCKOUT = 'Stand all the way up at the top';
  const String FB_ERROR_TEMPO_FAST = 'Slow down — control the lift';
  const String PERF_TIP_TEMPO = 'Try a 2-1-2 tempo (down-pause-up)';
  const String PERF_TIP_BREATHING = 'Breathe: brace before lift, exhale at top';

  const Map<String, double> FB_WEIGHTS = {
    FB_ERROR_DEPTH: 1.2,
    FB_ERROR_LOCKOUT: 1.0,
    FB_ERROR_TEMPO_FAST: 1.5,
  };
  const double FB_DEFAULT_WEIGHT = 0.5;
  const double PENALTY_MIN_IF_ANY = 0.5;

  const List<String> FORM_ERROR_PRIORITY = [
    FB_ERROR_TEMPO_FAST,
    FB_ERROR_DEPTH,
    FB_ERROR_LOCKOUT,
  ];
  const List<String> PERF_TIP_PRIORITY = [
    PERF_TIP_TEMPO,
    PERF_TIP_BREATHING,
  ];

  const int DEPTH_FAIL_MIN_REPS = 3;
  const int LOCKOUT_FAIL_MIN_REPS = 3;
  const int EXTREME_TEMPO_MIN_REPS = 1;

  final int minHoldDeepFrames = math.max(1, (MIN_HOLD_DEEP_SEC * fps).round());
  final int minBetweenRepsFrames =
      math.max(1, (MIN_BETWEEN_REPS_SEC * fps).round());
  final int baselineLookbackFrames =
      math.max(1, (BASELINE_LOOKBACK_SEC * fps).round());

  _cachedW = -1;
  _cachedH = -1;

  // ================ Helpers ================
  double angle3pt(List<double> a, List<double> b, List<double> c) {
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

  double halfFloor10(double x) {
    return math.max(0.0, math.min(10.0, (x * 2.0).floorToDouble() / 2.0));
  }

  String displayHalfStr(double x) {
    final q = (x * 2).round() / 2.0;
    if ((q - q.round()).abs() < 1e-9) return q.round().toString();
    return q.toStringAsFixed(1);
  }

  String scoreLabel(double s) {
    if (s >= 9.0) return 'Excellent';
    if (s >= 7.0) return 'Good';
    if (s >= 5.5) return 'Fair';
    return 'Needs work';
  }

  double percentile(List<double> values, double p) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    if (sorted.length == 1) return sorted.first;
    final rank = (p / 100.0) * (sorted.length - 1);
    final lo = rank.floor();
    final hi = rank.ceil();
    if (lo == hi) return sorted[lo];
    final frac = rank - lo;
    return sorted[lo] * (1 - frac) + sorted[hi] * frac;
  }

  double rd(double x, int decimals) {
    final m = math.pow(10, decimals);
    return (x * m).round() / m;
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
        'exercise_type': 'deadlift',
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
    'deadlift_in_${DateTime.now().millisecondsSinceEpoch}_$safeName',
  );
  try {
    await File(videoPath).writeAsBytes(videoFile.bytes!, flush: true);
  } catch (e) {
    return errorPayload('write_failed', 'Could not save upload: $e');
  }

  // ================ 1) Extract frames ================
  final String sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  final Directory framesDir =
      Directory(p.join(tmp.path, 'deadlift_frames_$sessionId'));
  if (framesDir.existsSync()) framesDir.deleteSync(recursive: true);
  framesDir.createSync(recursive: true);

  // Higher JPG quality (-q:v 2 vs the previous 4) and a more conservative
  // max dimension (1280 vs the previous 720) — both help YOLO's barbell
  // detection on the same frames. The previous 720 cap was forcing iPhone
  // 1080p videos through two consecutive downsamples (1080→720→320), which
  // smears the thin barbell silhouette enough to confuse the model. Going
  // straight 1080→320 keeps the bar sharp. ML Kit pose handles 1280-wide
  // frames without trouble.
  final String framePattern = p.join(framesDir.path, 'f_%05d.jpg');
  final String extractCmd =
      "-y -i \"$videoPath\" -vf \"fps=$fps,scale='min(1280,iw)':-2\" -q:v 2 \"$framePattern\"";
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

  // ================ 2b) YOLOv8 barbell detector ================
  // Load the bundled model from the xlift_models package and prepare the
  // interpreter. On failure we don't abort the analysis — pose-based rep
  // counting still works without the barbell signal.
  Interpreter? yoloInterpreter;
  bool yoloIsFloatInput = true;
  bool yoloIsFloatOutput = true;
  double yoloOutputScale = 1.0;
  int yoloOutputZeroPoint = 0;
  int yoloNumPredictions = 0;
  int yoloInputSize = 320;
  String yoloLoadInfo = 'not_loaded';
  try {
    final Uint8List modelBytes = await XliftModels.loadBarbellModel();
    yoloInterpreter = Interpreter.fromBuffer(modelBytes);
    final inTensor = yoloInterpreter.getInputTensor(0);
    final outTensor = yoloInterpreter.getOutputTensor(0);
    final inShape = inTensor.shape; // [1, 320, 320, 3]
    final outShape = outTensor.shape; // [1, 5, 2100]
    yoloIsFloatInput = inTensor.type.toString().toLowerCase().contains('float');
    yoloIsFloatOutput =
        outTensor.type.toString().toLowerCase().contains('float');
    yoloOutputScale = outTensor.params.scale;
    yoloOutputZeroPoint = outTensor.params.zeroPoint;
    if (inShape.length >= 2) yoloInputSize = inShape[1];
    if (outShape.length >= 3) yoloNumPredictions = outShape[2];
    yoloLoadInfo =
        'ok(in=$inShape/$yoloIsFloatInput out=$outShape/$yoloIsFloatOutput)';
  } catch (e) {
    yoloLoadInfo = 'load_failed: $e';
    yoloInterpreter = null;
  }
  const double YOLO_CONF_THRESHOLD = 0.25;

  // ===== [SPEED-1] Standing-frame skip =====
  // We approximate "the lifter is standing" without an EMA by tracking the
  // rolling min of valid hipY values over the last STANDING_WINDOW_SEC.
  // If current hipY is within STANDING_HIPY_MARGIN of that min AND we
  // have at least STANDING_MIN_SAMPLES valid samples, the lifter is at
  // (or very near) their standing baseline — skip YOLO for this frame.
  // We never skip the first STANDING_WARMUP_SEC seconds so the rolling
  // window has a chance to settle on a real baseline.
  const double STANDING_WINDOW_SEC = 2.0;
  const double STANDING_HIPY_MARGIN = 0.02; // ~2% of normalized image height
  const int STANDING_MIN_SAMPLES = 10;
  const double STANDING_WARMUP_SEC = 1.0;

  // ===== [FUSION-2] Barbell-assisted rep confirmation/rescue =====
  // *** ENABLED in v5 ***
  // A rep that the strict pose gates rejected can be COUNTED if the
  // barbell strongly confirmed it AND the failure was on exactly one
  // soft gate (we never overrule a clear "no"). See the rescue logic
  // inside the main loop and at the end-of-video block for the exact
  // conditions and audit fields.
  const bool ENABLE_BARBELL_RESCUE = true;

  // Thresholds defining "the bar told us this was a real rep"
  const double BAR_CONFIRM_DET_RATE = 0.40; // ≥40% rep frames w/ bar
  const double BAR_CONFIRM_Y_RANGE = 0.08; // bbox center moved ≥8%
  const double BAR_CONFIRM_WRIST_DIST = 0.18; // bar mean dist ≤18% to wrist
  const double BORDERLINE_PEAK_MIN = 0.50;
  const double BORDERLINE_PEAK_MAX = 0.60;

  // Track how many frames the model ran on and how many had a detection,
  // so we can show a summary in the result.
  int yoloFramesRun = 0;
  int yoloFramesWithBarbell = 0;
  int yoloFramesSkipped = 0;
  double yoloMaxConfSeen = 0.0;

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

  // ================ 3) First pass ================
  final List<_FrameRaw> raw = [];
  int frameIdx = 0;
  final List<List<double>?> lastLandmarks =
      List<List<double>?>.filled(LM_ORDER.length, null);

  // [SPEED-1] rolling-min window of valid hipY for "lifter is standing"
  // approximation. We push (tSec, hipY) and pop entries older than
  // STANDING_WINDOW_SEC. The min over what's left is the recent baseline.
  final List<double> standingHipYTimes = [];
  final List<double> standingHipYValues = [];

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

      if (poses.isEmpty) {
        raw.add(_FrameRaw(
          idx: frameIdx,
          t: tSec,
          valid: false,
          landmarks: const [],
        ));
        continue;
      }

      final pose = poses.first;
      final lm = pose.landmarks;

      const double LM_HOLD_VIS_TH = 0.5;
      const double LM_HOLD_LEG_VIS_TH = 0.7;
      const int LEG_LM_FIRST = 25;
      const int LEG_LM_LAST = 32;

      final List<List<double>> normLandmarks = [];
      for (int lmIdx = 0; lmIdx < LM_ORDER.length; lmIdx++) {
        final type = LM_ORDER[lmIdx];
        final plm = lm[type];
        final double holdTh = (lmIdx >= LEG_LM_FIRST && lmIdx <= LEG_LM_LAST)
            ? LM_HOLD_LEG_VIS_TH
            : LM_HOLD_VIS_TH;
        if (plm == null) {
          if (lastLandmarks[lmIdx] != null) {
            normLandmarks.add(List<double>.from(lastLandmarks[lmIdx]!));
          } else {
            normLandmarks.add([0.0, 0.0, 0.0]);
          }
        } else {
          final lik = plm.likelihood.clamp(0.0, 1.0).toDouble();
          if (lik < holdTh && lastLandmarks[lmIdx] != null) {
            final last = lastLandmarks[lmIdx]!;
            normLandmarks.add([last[0], last[1], lik]);
          } else {
            final v = [
              (plm.x / fw).clamp(0.0, 1.0).toDouble(),
              (plm.y / fh).clamp(0.0, 1.0).toDouble(),
              lik,
            ];
            normLandmarks.add(v);
            if (lik >= holdTh) {
              lastLandmarks[lmIdx] = v;
            }
          }
        }
      }

      final lh = lm[PoseLandmarkType.leftHip];
      final rh = lm[PoseLandmarkType.rightHip];
      final ls = lm[PoseLandmarkType.leftShoulder];
      final rs = lm[PoseLandmarkType.rightShoulder];
      final lk = lm[PoseLandmarkType.leftKnee];
      final rk = lm[PoseLandmarkType.rightKnee];
      final la = lm[PoseLandmarkType.leftAnkle];
      final ra = lm[PoseLandmarkType.rightAnkle];
      final lw = lm[PoseLandmarkType.leftWrist];
      final rw = lm[PoseLandmarkType.rightWrist];

      if (lh == null ||
          rh == null ||
          ls == null ||
          rs == null ||
          lk == null ||
          rk == null ||
          la == null ||
          ra == null) {
        raw.add(_FrameRaw(
          idx: frameIdx,
          t: tSec,
          valid: false,
          landmarks: normLandmarks,
        ));
        continue;
      }

      final visMinLm = [
        lh.likelihood,
        rh.likelihood,
        ls.likelihood,
        rs.likelihood,
        lk.likelihood,
        rk.likelihood,
      ].reduce(math.min);

      final hipY = ((lh.y / fh) + (rh.y / fh)) / 2.0;
      final hipX = ((lh.x / fw) + (rh.x / fw)) / 2.0;
      final shY = ((ls.y / fh) + (rs.y / fh)) / 2.0;

      double? wristHipDy;
      double? wristY;
      double? wristX;
      if (lw != null && rw != null) {
        wristY = ((lw.y / fh) + (rw.y / fh)) / 2.0;
        wristX = ((lw.x / fw) + (rw.x / fw)) / 2.0;
        wristHipDy = (wristY - hipY).abs();
      }

      double? kneeAng;
      try {
        final lAng = angle3pt([lh.x / fw, lh.y / fh], [lk.x / fw, lk.y / fh],
            [la.x / fw, la.y / fh]);
        final rAng = angle3pt([rh.x / fw, rh.y / fh], [rk.x / fw, rk.y / fh],
            [ra.x / fw, ra.y / fh]);
        const double KNEE_SIDE_VIS_TH = 0.5;
        final double lSideVis =
            [lh.likelihood, lk.likelihood, la.likelihood].reduce(math.min);
        final double rSideVis =
            [rh.likelihood, rk.likelihood, ra.likelihood].reduce(math.min);
        final bool lOk = lSideVis >= KNEE_SIDE_VIS_TH;
        final bool rOk = rSideVis >= KNEE_SIDE_VIS_TH;
        if (lOk && rOk) {
          kneeAng = (lAng + rAng) / 2.0;
        } else if (lOk) {
          kneeAng = lAng;
        } else if (rOk) {
          kneeAng = rAng;
        } else {
          kneeAng = (lSideVis >= rSideVis) ? lAng : rAng;
        }
      } catch (_) {
        kneeAng = null;
      }

      final double bodyHeight = hipY - shY;
      const double MIN_BODY_HEIGHT = 0.04;
      const double MAX_BODY_HEIGHT = 0.35;
      final bool poseAnatomicallyValid =
          bodyHeight >= MIN_BODY_HEIGHT && bodyHeight <= MAX_BODY_HEIGHT;
      final bool isValid = (visMinLm >= VIS_MIN) && poseAnatomicallyValid;

      // [SPEED-1] Update rolling-min hipY window and decide whether
      // we can skip YOLO for this frame.
      bool skipYoloThisFrame = false;
      if (isValid) {
        standingHipYTimes.add(tSec);
        standingHipYValues.add(hipY);
        // Pop entries older than STANDING_WINDOW_SEC
        while (standingHipYTimes.isNotEmpty &&
            (tSec - standingHipYTimes.first) > STANDING_WINDOW_SEC) {
          standingHipYTimes.removeAt(0);
          standingHipYValues.removeAt(0);
        }
        if (tSec >= STANDING_WARMUP_SEC &&
            standingHipYValues.length >= STANDING_MIN_SAMPLES) {
          double minH = standingHipYValues.first;
          for (final v in standingHipYValues) {
            if (v < minH) minH = v;
          }
          // hipY low = high in image (head/top); when STANDING, hipY is
          // at the rolling MIN (smallest value seen recently). A bit
          // above that min still counts as standing.
          if (hipY <= minH + STANDING_HIPY_MARGIN) {
            skipYoloThisFrame = true;
          }
        }
      }

      // ----- YOLO barbell inference on the same frame -----
      // Output (if found): normalized box {x_center, y_center, width, height, confidence}
      // in the model's input-space (0..1 over the 320x320 letterbox), which is
      // the same coordinate system the player widget should use to draw it.
      Map<String, dynamic>? yoloBbox;
      if (yoloInterpreter != null && !skipYoloThisFrame) {
        try {
          final yBytes = await frameFile.readAsBytes();
          final yImage = img.decodeImage(yBytes);
          if (yImage != null) {
            // ===== LETTERBOX PREPROCESSING =====
            // The model was trained on Roboflow's "Resize Fit (black edges)
            // 640x640" — aspect-preserving resize with black bars. The
            // previous version of this code STRETCHED the frame to 320x320,
            // which on portrait video (e.g. 384x848) squashed everything
            // vertically by ~2.6x. The model never saw stretched inputs in
            // training, so the predicted bboxes were misshapen and the
            // detector latched onto plates instead of bars.
            //
            // Now we letterbox in Dart: compute the largest aspect-preserving
            // size that fits inside INPUT_SIZE x INPUT_SIZE, paste the
            // resized frame into the center of a black canvas, and remember
            // the scale/offsets so we can map the bbox back to original-
            // frame normalized coordinates before storing in telemetry.
            final int origW = yImage.width;
            final int origH = yImage.height;
            final double scale = math.min(
              yoloInputSize / origW,
              yoloInputSize / origH,
            );
            final int scaledW = (origW * scale).round();
            final int scaledH = (origH * scale).round();
            final int padX = ((yoloInputSize - scaledW) / 2).floor();
            final int padY = ((yoloInputSize - scaledH) / 2).floor();

            // Build the letterbox canvas. Black background, then paste
            // the aspect-preserved resize at (padX, padY).
            final img.Image canvas = img.Image(
              width: yoloInputSize,
              height: yoloInputSize,
            );
            img.fill(canvas, color: img.ColorRgb8(0, 0, 0));
            final img.Image yResized = img.copyResize(
              yImage,
              width: scaledW,
              height: scaledH,
            );
            img.compositeImage(
              canvas,
              yResized,
              dstX: padX,
              dstY: padY,
            );

            // [SPEED-2] Fast preprocessing: pull the canvas's raw RGB byte
            // buffer once and iterate it linearly, instead of calling
            // canvas.getPixel(x,y) for every pixel. Same letterbox math
            // upstream, same model input downstream.
            final Uint8List rgbBytes =
                canvas.getBytes(order: img.ChannelOrder.rgb);
            final int pxCount = yoloInputSize * yoloInputSize;

            dynamic yInput;
            if (yoloIsFloatInput) {
              final flat = Float32List(pxCount * 3);
              // rgbBytes layout: [R0,G0,B0, R1,G1,B1, ...]
              // We want the same layout as Float32 in [0..1].
              // Iterate one byte at a time — Dart's JIT optimizes a flat
              // loop with typed-list access much better than nested
              // getPixel calls.
              final int total = pxCount * 3;
              for (int i = 0; i < total; i++) {
                flat[i] = rgbBytes[i] / 255.0;
              }
              yInput = flat.reshape([1, yoloInputSize, yoloInputSize, 3]);
            } else {
              // Quantized input: the bytes ARE already the input — just
              // make sure they live in a fresh Uint8List of the right
              // length, then reshape.
              final flat = Uint8List(pxCount * 3);
              flat.setRange(0, pxCount * 3, rgbBytes);
              yInput = flat.reshape([1, yoloInputSize, yoloInputSize, 3]);
            }

            dynamic yOutput;
            if (yoloIsFloatOutput) {
              yOutput = List.generate(
                1,
                (_) => List.generate(
                  5,
                  (_) => List<double>.filled(yoloNumPredictions, 0.0),
                ),
              );
            } else {
              yOutput = List.generate(
                1,
                (_) => List.generate(
                  5,
                  (_) => List<int>.filled(yoloNumPredictions, 0),
                ),
              );
            }

            yoloInterpreter.run(yInput, yOutput);
            yoloFramesRun++;

            double dq(num v) => yoloIsFloatOutput
                ? v.toDouble()
                : (v.toDouble() - yoloOutputZeroPoint) * yoloOutputScale;

            // ===== TOP-K with ASPECT-RATIO SANITY FILTER =====
            // The previous version just took argmax over all predictions.
            // Test runs showed that when the model is unsure, it sometimes
            // assigns moderate confidence (~0.3-0.5) to a SQUARE region
            // around one of the plates instead of the bar itself. A real
            // barbell viewed roughly side-on or front-on has a very high
            // width/height ratio in 2D (typically 4+); a plate is roughly
            // square (~1.0). Picking the highest-confidence WIDE prediction
            // instead of the absolute max filters out plate misdetections
            // cleanly. We still report the absolute max for diagnostics so
            // we can tell whether the model was suppressed by the filter.
            const double _MIN_BAR_ASPECT = 2.5;
            const int _TOPK_FOR_FILTER = 10;

            // Bubble up the top-K predictions by confidence.
            final List<int> topKIdx = [];
            final List<double> topKConf = [];
            for (int i = 0; i < yoloNumPredictions; i++) {
              final c = dq(yOutput[0][4][i]);
              if (topKIdx.length < _TOPK_FOR_FILTER) {
                topKIdx.add(i);
                topKConf.add(c);
              } else {
                // Find current minimum in the top-K window
                int minPos = 0;
                for (int k = 1; k < topKConf.length; k++) {
                  if (topKConf[k] < topKConf[minPos]) minPos = k;
                }
                if (c > topKConf[minPos]) {
                  topKIdx[minPos] = i;
                  topKConf[minPos] = c;
                }
              }
            }

            // Absolute max for diagnostics
            double maxConf = 0.0;
            int maxJ = -1;
            for (int k = 0; k < topKIdx.length; k++) {
              if (topKConf[k] > maxConf) {
                maxConf = topKConf[k];
                maxJ = topKIdx[k];
              }
            }
            if (maxConf > yoloMaxConfSeen) yoloMaxConfSeen = maxConf;

            // Now find the highest-confidence prediction with bar-like shape.
            // If nothing qualifies, fall back to maxJ so we at least see
            // SOMETHING in the telemetry (the bbox just won't pass any
            // downstream "bar present" gate based on aspect).
            int bestBarJ = -1;
            double bestBarConf = 0.0;
            double bestBarAspect = 0.0;
            for (int k = 0; k < topKIdx.length; k++) {
              final int j = topKIdx[k];
              final double w = dq(yOutput[0][2][j]);
              final double h = dq(yOutput[0][3][j]);
              if (h <= 1e-6) continue;
              final double ar = w / h;
              if (ar >= _MIN_BAR_ASPECT && topKConf[k] > bestBarConf) {
                bestBarConf = topKConf[k];
                bestBarJ = j;
                bestBarAspect = ar;
              }
            }

            // Use the bar-shaped one if found; otherwise the absolute max.
            final int chosenJ = bestBarJ >= 0 ? bestBarJ : maxJ;
            final double chosenConf = bestBarJ >= 0 ? bestBarConf : maxConf;

            if (chosenJ >= 0 && chosenConf >= YOLO_CONF_THRESHOLD) {
              yoloFramesWithBarbell++;

              // ===== REVERSE LETTERBOX MAPPING =====
              // The model returns bbox coords normalized to its INPUT_SIZE x
              // INPUT_SIZE letterboxed input. We need to map back to the
              // original frame's normalized coordinates so the widget can
              // draw it correctly on the unstretched video.
              //
              // Letterbox layout: a (scaledW x scaledH) image embedded at
              // offset (padX, padY) inside the (INPUT_SIZE x INPUT_SIZE)
              // canvas. To go from letterbox normalized -> original
              // normalized:
              //   1) multiply by INPUT_SIZE to get pixels in the canvas
              //   2) subtract padding to get pixels within the embedded image
              //   3) divide by scaledW / scaledH to get normalized 0..1 in
              //      the original frame coordinate space
              // For widths/heights, only steps 1 and 3 apply (no padding
              // offset).
              // Decode the chosen prediction (bar-shaped if found, else max)
              final double xcLetter = dq(yOutput[0][0][chosenJ]);
              final double ycLetter = dq(yOutput[0][1][chosenJ]);
              final double wLetter = dq(yOutput[0][2][chosenJ]);
              final double hLetter = dq(yOutput[0][3][chosenJ]);

              final double xcPx = xcLetter * yoloInputSize;
              final double ycPx = ycLetter * yoloInputSize;
              final double wPx = wLetter * yoloInputSize;
              final double hPx = hLetter * yoloInputSize;

              final double xcOrig = scaledW > 0 ? (xcPx - padX) / scaledW : 0.0;
              final double ycOrig = scaledH > 0 ? (ycPx - padY) / scaledH : 0.0;
              final double wOrig = scaledW > 0 ? wPx / scaledW : 0.0;
              final double hOrig = scaledH > 0 ? hPx / scaledH : 0.0;

              // Clamp to a sensible range in case the predicted box pokes
              // into the black-bar padding region.
              double clamp01(double v) {
                if (v.isNaN || v.isInfinite) return 0.0;
                if (v < 0.0) return 0.0;
                if (v > 1.0) return 1.0;
                return v;
              }

              yoloBbox = {
                'x_center': _rd3(clamp01(xcOrig)),
                'y_center': _rd3(clamp01(ycOrig)),
                'width': _rd3(clamp01(wOrig)),
                'height': _rd3(clamp01(hOrig)),
                'confidence': _rd3(chosenConf),
                // Diagnostic: was the choice filtered by aspect, or absolute max?
                'aspect_filtered': bestBarJ >= 0,
                'aspect': _rd3(bestBarJ >= 0 ? bestBarAspect : 0.0),
              };
            }
          }
        } catch (_) {
          // Swallow per-frame YOLO errors so pose analysis keeps running.
        }
      } else if (yoloInterpreter != null && skipYoloThisFrame) {
        // [SPEED-1] Bookkeeping: we had a model loaded but decided this
        // frame was clearly STANDING and didn't need bar detection.
        yoloFramesSkipped++;
      }

      raw.add(_FrameRaw(
        idx: frameIdx,
        t: tSec,
        valid: isValid,
        visMinLm: visMinLm,
        hipY: hipY,
        hipX: hipX,
        kneeAng: kneeAng,
        wristHipDy: wristHipDy,
        shY: shY,
        wristY: wristY,
        wristX: wristX,
        landmarks: normLandmarks,
        barbellBbox: yoloBbox,
      ));
    }
  } finally {
    await poseDetector.close();
    try {
      yoloInterpreter?.close();
    } catch (_) {}
    try {
      framesDir.deleteSync(recursive: true);
    } catch (_) {}
  }

  // ================ 4) Calibration ================
  final validHipY =
      raw.where((r) => r.valid && r.hipY != null).map((r) => r.hipY!).toList();
  final validKnee = raw
      .where((r) => r.valid && r.kneeAng != null)
      .map((r) => r.kneeAng!)
      .toList();

  if (validHipY.length < 20 || validKnee.isEmpty) {
    final List<Map<String, dynamic>> tel = [];
    for (final r in raw) {
      tel.add({
        't': r.t,
        'reps': 0,
        'depth': 1.0,
        'metric_label': 'HEIGHT',
        'metric_value': 1.0,
        'feedback': null,
        'rep_just_finished': null,
        'landmarks': r.landmarks,
        'barbell_bbox': r.barbellBbox,
      });
    }
    final String fileUri = 'file://$videoPath';
    return {
      'squat_count': 0,
      'technique_score': 0.0,
      'technique_score_display': '0',
      'technique_label': 'Needs work',
      'good_reps': 0,
      'bad_reps': 0,
      'feedback': <String>[
        "Couldn't analyze this video — make sure your full body is visible and that you complete at least one deadlift."
      ],
      'tips': <String>[],
      'reps': <dynamic>[],
      'exercise_type': 'deadlift',
      'video_path': fileUri,
      'analyzed_fps': fps,
      'frame_count': frameIdx,
      '_source_video_uri': fileUri,
      '_frame_telemetry': tel,
      'debug': {
        'aborted_at': 'calibration_insufficient_data',
      },
    };
  }

  final hipTop = percentile(validHipY, 2);
  final hipBot = percentile(validHipY, 98);
  final hipRng = math.max(0.05, hipBot - hipTop);
  final hipRange = hipBot - hipTop;

  final kneeTop = percentile(validKnee, 98);
  final kneeBot = percentile(validKnee, 2);
  final kneeRng = math.max(15.0, kneeTop - kneeBot);
  final kneeRange = kneeTop - kneeBot;

  diagCalib = {
    'totalFrames': raw.length,
    'validFrames': validHipY.length,
    'fps': rd(fps, 1),
    'hipTop': rd(hipTop, 4),
    'hipBot': rd(hipBot, 4),
    'hipRange': rd(hipRange, 4),
    'kneeTop': rd(kneeTop, 2),
    'kneeBot': rd(kneeBot, 2),
    'kneeRange': rd(kneeRange, 2),
  };

  const double STATIC_VIDEO_HIP_RANGE = 0.04;
  final bool videoIsStatic = hipRange < STATIC_VIDEO_HIP_RANGE;
  const double NOT_DEADLIFT_KNEE_RANGE = 50.0;
  final bool videoNotADeadliftByKnee = kneeRange < NOT_DEADLIFT_KNEE_RANGE;
  final bool videoIsOverhead = false;
  final bool videoNotADeadlift = videoNotADeadliftByKnee || videoIsOverhead;

  double wHip, wKnee;
  if (hipRange > 0.10) {
    wHip = 0.85;
    wKnee = 0.15;
  } else if (hipRange > 0.04) {
    wHip = 0.5;
    wKnee = 0.5;
  } else {
    wHip = 0.3;
    wKnee = 0.7;
  }

  final reqHipDescent = math.max(0.012, hipRange * 0.30);
  final reqKneeDrop = math.max(15.0, kneeRange * 0.35);

  final validWristDy = raw
      .where((r) => r.valid && r.wristHipDy != null)
      .map((r) => r.wristHipDy!)
      .toList();
  double dyMaxAllowed = double.infinity;
  if (validWristDy.length >= 20) {
    final dyTypical = percentile(validWristDy, 50);
    dyMaxAllowed = dyTypical + math.max(0.025, hipRange * 0.5);
  }

  // [FUSION-1] Helper to compute barbell stats for a rep candidate's window.
  // Used both inside the main loop (rep commit decision) and at end-of-video.
  // `startFrameId` and `endFrameId` are in 1-based `_FrameRaw.idx` space; we
  // convert to 0-based list indices internally.
  Map<String, dynamic> computeCandidateBarbell(
      int startFrameId, int endFrameId) {
    final int sIdx = math.max(0, math.min(raw.length - 1, startFrameId - 1));
    final int eIdx = math.max(0, math.min(raw.length - 1, endFrameId - 1));
    int total = 0;
    int withBar = 0;
    double sumConf = 0.0;
    double barYMin = double.infinity;
    double barYMax = -double.infinity;
    double sumWristBarDist = 0.0;
    int wristSamples = 0;
    for (int j = sIdx; j <= eIdx; j++) {
      total++;
      final fr = raw[j];
      final bbox = fr.barbellBbox;
      if (bbox != null) {
        withBar++;
        sumConf += (bbox['confidence'] as num?)?.toDouble() ?? 0.0;
        final by = (bbox['y_center'] as num?)?.toDouble() ?? double.nan;
        if (!by.isNaN) {
          if (by < barYMin) barYMin = by;
          if (by > barYMax) barYMax = by;
        }
        if (fr.wristY != null && fr.wristX != null) {
          final bx = (bbox['x_center'] as num?)?.toDouble() ?? double.nan;
          if (!bx.isNaN && !by.isNaN) {
            final dx = bx - fr.wristX!;
            final dy = by - fr.wristY!;
            sumWristBarDist += math.sqrt(dx * dx + dy * dy);
            wristSamples++;
          }
        }
      }
    }
    final double rate = total > 0 ? withBar / total : 0.0;
    final double yRange =
        (barYMax > -double.infinity && barYMin < double.infinity)
            ? (barYMax - barYMin)
            : 0.0;
    final double meanConf = withBar > 0 ? sumConf / withBar : 0.0;
    final double meanWrist =
        wristSamples > 0 ? sumWristBarDist / wristSamples : double.nan;
    final bool confirmed = rate >= BAR_CONFIRM_DET_RATE &&
        yRange >= BAR_CONFIRM_Y_RANGE &&
        (!meanWrist.isNaN && meanWrist <= BAR_CONFIRM_WRIST_DIST);
    return {
      'det_rate': _rd3(rate),
      'mean_conf': _rd3(meanConf),
      'bar_y_range': _rd3(yRange),
      'mean_wrist_dist': meanWrist.isNaN ? null : _rd3(meanWrist),
      'confirmed': confirmed,
    };
  }

  // ================ 5) Main loop ================
  final List<Map<String, dynamic>> frameTelemetry = [];
  int repCount = 0;
  int lastRepFrame = -9999;
  String state = 'STANDING';
  double peakInRep = 0.0;
  int deepCount = 0;
  int repStartFrame = -1;
  double? repBaselineHipY;
  double? repMaxHipY;
  double? repMinHipY;
  double? repMaxShY;
  double? repMinShY;
  double? repBaselineKnee;
  double? repMinKnee;
  double? repHipxMin, repHipxMax;
  double? repMaxWristDy;

  double? ema;
  double? kneeEma;
  const double KNEE_EMA_ALPHA = 0.5;
  int consecutiveStandingFrames = 0;
  final int minStableStandingFrames = math.max(1, (0.5 * fps).round());

  bool firstRepStartedMidRep = false;
  bool seenFirstValidFrame = false;
  const double FIRST_REP_MIN_PEAK = 0.70;
  final hipBuf = <double>[];
  final kneeBuf = <double>[];

  final List<double> emaByFrame = [];
  int? curRepBottomI;

  final List<_RepInfo> committedReps = [];
  final List<String?> repFinishedAtFrame = [];

  for (int i = 0; i < raw.length; i++) {
    final r = raw[i];

    double? hipBaseline;
    double? kneeBaseline;
    double curEma = ema ?? 0.0;

    if (r.valid && r.hipY != null) {
      final h = ((r.hipY! - hipTop) / hipRng).clamp(0.0, 1.0);
      double? kSmoothed;
      if (r.kneeAng != null) {
        kneeEma = (kneeEma == null)
            ? r.kneeAng
            : KNEE_EMA_ALPHA * r.kneeAng! + (1 - KNEE_EMA_ALPHA) * kneeEma!;
        kSmoothed = kneeEma;
      } else if (kneeEma != null) {
        kSmoothed = kneeEma;
      }
      final k = kSmoothed != null
          ? ((kneeTop - kSmoothed) / kneeRng).clamp(0.0, 1.0)
          : 0.0;
      final c = wHip * h + wKnee * k;
      ema = (ema == null) ? c : 0.4 * c + 0.6 * ema!;
      curEma = ema!;

      hipBuf.add(r.hipY!);
      if (hipBuf.length > baselineLookbackFrames) hipBuf.removeAt(0);
      if (r.kneeAng != null) {
        kneeBuf.add(r.kneeAng!);
        if (kneeBuf.length > baselineLookbackFrames) kneeBuf.removeAt(0);
      }
      hipBaseline = hipBuf.reduce(math.min);
      kneeBaseline = kneeBuf.isEmpty ? null : kneeBuf.reduce(math.max);
    } else {
      hipBaseline = hipBuf.isEmpty ? null : hipBuf.reduce(math.min);
      kneeBaseline = kneeBuf.isEmpty ? null : kneeBuf.reduce(math.max);
    }
    emaByFrame.add(curEma);

    final bool isStandingNow = curEma < T_RESET;
    if (isStandingNow) {
      consecutiveStandingFrames++;
    }

    String? repJustFinished;

    if (r.valid && r.hipY != null && !seenFirstValidFrame) {
      seenFirstValidFrame = true;
      if (state == 'STANDING' && curEma >= T_DEEP) {
        state = 'HINGED';
        peakInRep = curEma;
        deepCount = 1;
        repStartFrame = r.idx;
        repBaselineHipY = hipTop;
        repMaxHipY = r.hipY;
        repMinHipY = r.hipY;
        repMaxShY = r.shY;
        repMinShY = r.shY;
        repBaselineKnee = kneeTop;
        repMinKnee = r.kneeAng;
        repHipxMin = r.hipX;
        repHipxMax = r.hipX;
        repMaxWristDy = r.wristHipDy;
        curRepBottomI = i;
        firstRepStartedMidRep = true;
      }
    }

    if (state == 'STANDING') {
      if (curEma >= T_DEEP &&
          (r.idx - lastRepFrame) >= minBetweenRepsFrames &&
          r.valid) {
        state = 'HINGED';
        peakInRep = curEma;
        deepCount = 1;
        repStartFrame = r.idx;
        repBaselineHipY = hipBaseline;
        repMaxHipY = r.hipY;
        repMinHipY = r.hipY;
        repMaxShY = r.shY;
        repMinShY = r.shY;
        repBaselineKnee = kneeBaseline;
        repMinKnee = r.kneeAng;
        repHipxMin = r.hipX;
        repHipxMax = r.hipX;
        repMaxWristDy = r.wristHipDy;
        curRepBottomI = i;

        final int backfillFrames = math.max(1, (0.7 * fps).round());
        final int backfillStart = math.max(0, i - backfillFrames);
        for (int j = backfillStart; j < i; j++) {
          final pj = raw[j];
          if (!pj.valid) continue;
          if (j < emaByFrame.length && emaByFrame[j] < T_RESET) continue;
          if (pj.kneeAng != null &&
              (repMinKnee == null || pj.kneeAng! < repMinKnee!)) {
            repMinKnee = pj.kneeAng;
          }
          if (pj.hipY != null && repMaxHipY != null && pj.hipY! > repMaxHipY!) {
            repMaxHipY = pj.hipY;
          }
          if (pj.hipY != null && repMinHipY != null && pj.hipY! < repMinHipY!) {
            repMinHipY = pj.hipY;
          }
        }
      }
    } else {
      if (curEma >= T_DEEP) deepCount++;
      if (curEma > peakInRep) {
        peakInRep = curEma;
        curRepBottomI = i;
      }
      if (r.hipY != null && repMaxHipY != null && r.hipY! > repMaxHipY!) {
        repMaxHipY = r.hipY;
      }
      if (r.hipY != null && repMinHipY != null && r.hipY! < repMinHipY!) {
        repMinHipY = r.hipY;
      }
      if (r.shY != null) {
        if (repMaxShY == null || r.shY! > repMaxShY!) repMaxShY = r.shY;
        if (repMinShY == null || r.shY! < repMinShY!) repMinShY = r.shY;
      }
      if (r.kneeAng != null && repMinKnee != null && r.kneeAng! < repMinKnee!) {
        repMinKnee = r.kneeAng;
      }
      if (r.hipX != null) {
        if (repHipxMin == null || r.hipX! < repHipxMin!) repHipxMin = r.hipX;
        if (repHipxMax == null || r.hipX! > repHipxMax!) repHipxMax = r.hipX;
      }
      if (r.wristHipDy != null) {
        if (repMaxWristDy == null || r.wristHipDy! > repMaxWristDy!) {
          repMaxWristDy = r.wristHipDy;
        }
      }

      double peakDropDelta = 0.0;
      if (peakInRep >= 0.65) {
        peakDropDelta = (peakInRep - T_RESET) * 0.30;
      }
      final bool emaDroppedFromPeak =
          peakInRep >= 0.65 && curEma <= (peakInRep - peakDropDelta);
      if (curEma < T_RESET || emaDroppedFromPeak) {
        final hipDesc = (repMaxHipY != null && repBaselineHipY != null)
            ? (repMaxHipY! - repBaselineHipY!)
            : 0.0;
        final kneeDrop = (repBaselineKnee != null && repMinKnee != null)
            ? (repBaselineKnee! - repMinKnee!)
            : 0.0;
        final hipxRng = (repHipxMax != null && repHipxMin != null)
            ? (repHipxMax! - repHipxMin!)
            : 0.0;

        final holdOk = deepCount >= minHoldDeepFrames;
        final double repDurSec = (r.idx - repStartFrame) / fps;
        final bool durOk = repDurSec >= MIN_REP_DURATION_SEC;
        final hipOk = hipDesc >= reqHipDescent;
        final kneeOk = kneeDrop >= reqKneeDrop;
        final double walkXThresh = hipRange > 0.10 ? 0.20 : 0.15;
        final bool walkOk = hipxRng <= walkXThresh;
        final bool isFirstMidRep =
            committedReps.isEmpty && firstRepStartedMidRep;
        final bool peakOk = !isFirstMidRep || peakInRep >= FIRST_REP_MIN_PEAK;
        final double repHipYRange = (repMaxHipY != null && repMinHipY != null)
            ? (repMaxHipY! - repMinHipY!)
            : 0.0;
        const double MIN_REP_HIPY_RANGE = 0.015;
        final bool hipMotionOk = repHipYRange >= MIN_REP_HIPY_RANGE;
        final double minKneeBottomTh =
            hipRange > 0.15 ? 120.0 : (hipRange > 0.10 ? 125.0 : 140.0);
        final bool kneeBottomOk =
            repMinKnee == null || repMinKnee! <= minKneeBottomTh;

        final double lateralVertRatio =
            repHipYRange > 0.001 ? hipxRng / repHipYRange : 0.0;
        final bool lateralOk = peakInRep >= LATERAL_GATE_PEAK_TH ||
            lateralVertRatio <= LATERAL_GATE_RATIO_TH;

        // Strict (original) commit — never regresses.
        final bool committedStrict = !videoIsStatic &&
            !videoNotADeadlift &&
            holdOk &&
            durOk &&
            (hipOk || kneeOk) &&
            walkOk &&
            peakOk &&
            hipMotionOk &&
            kneeBottomOk &&
            lateralOk;

        // [FUSION-1/2] Evaluate the barbell on this candidate's window.
        final Map<String, dynamic> barEval =
            computeCandidateBarbell(repStartFrame, r.idx);
        final bool barConfirmedHere = barEval['confirmed'] == true;

        // [FUSION-2] Rescue path: only if enabled AND we're on a true
        // borderline (peak in the borderline band, exactly ONE soft gate
        // failing, no hard-fail conditions). We do NOT rescue holdOk/durOk
        // (those are noise filters) and never rescue when the video is
        // static/not-a-deadlift.
        bool rescuedByBar = false;
        if (ENABLE_BARBELL_RESCUE &&
            !committedStrict &&
            !videoIsStatic &&
            !videoNotADeadlift &&
            barConfirmedHere &&
            peakInRep >= BORDERLINE_PEAK_MIN &&
            peakInRep <= BORDERLINE_PEAK_MAX &&
            holdOk &&
            durOk) {
          // Count which gates are failing
          int softFailures = 0;
          if (!hipOk && !kneeOk) softFailures++;
          if (!walkOk) softFailures++;
          if (!peakOk) softFailures++;
          if (!hipMotionOk) softFailures++;
          if (!kneeBottomOk) softFailures++;
          if (!lateralOk) softFailures++;
          if (softFailures == 1) {
            rescuedByBar = true;
          }
        }

        final bool committed = committedStrict || rescuedByBar;

        final List<String> failedGates = [];
        if (!holdOk) failedGates.add('holdOk');
        if (!durOk) failedGates.add('durOk');
        if (!(hipOk || kneeOk)) failedGates.add('hipOrKneeOk');
        if (!walkOk) failedGates.add('walkOk');
        if (!peakOk) failedGates.add('peakOk');
        if (!hipMotionOk) failedGates.add('hipMotionOk');
        if (!kneeBottomOk) failedGates.add('kneeBottomOk');
        if (!lateralOk) failedGates.add('lateralOk');
        diagCandidates.add({
          'tStart': rd(repStartFrame / fps, 2),
          'tEnd': rd(r.idx / fps, 2),
          'peakSig': rd(peakInRep, 3),
          'deepCt': deepCount,
          'hipDesc': rd(hipDesc, 4),
          'kneeDrop': rd(kneeDrop, 2),
          'repHipYRange': rd(repHipYRange, 4),
          'hipxRng': rd(hipxRng, 4),
          'latVRatio': rd(lateralVertRatio, 3),
          'repMaxWristDy': repMaxWristDy != null ? rd(repMaxWristDy!, 4) : null,
          'committed': committed,
          'committedStrict': committedStrict,
          'rescuedByBar': rescuedByBar,
          'barbell': barEval,
          'failedGates': failedGates,
        });

        if (committed) {
          repCount++;
          final repScore = _scoreDeadliftRep(
            peakInRep,
            hipDesc,
            kneeDrop,
            DEPTH_EXCELLENT_PEAK,
            DEPTH_GOOD_PEAK,
            DEPTH_FAIR_PEAK,
            KNEE_DROP_EXCELLENT,
            KNEE_DROP_GOOD,
            KNEE_DROP_FAIR,
            HIP_DESC_EXCELLENT,
            HIP_DESC_GOOD,
            HIP_DESC_FAIR,
          );
          final repShYRange = (repMaxShY != null && repMinShY != null)
              ? (repMaxShY! - repMinShY!)
              : 0.0;
          committedReps.add(_RepInfo(
            startFrame: repStartFrame,
            endFrame: r.idx,
            bottomFrameI: curRepBottomI ?? i,
            peakSig: peakInRep,
            hipDesc: hipDesc,
            kneeDrop: kneeDrop,
            score: repScore,
            hipYRange: repHipYRange,
            shYRange: repShYRange,
          ));
          lastRepFrame = r.idx;
          repJustFinished = repScore >= 7.0 ? 'good' : 'bad';
        }
        state = 'STANDING';
        peakInRep = 0.0;
        deepCount = 0;
        curRepBottomI = null;
      }
    }

    repFinishedAtFrame.add(repJustFinished);

    final double curEmaClamped = curEma.clamp(0.0, 1.0);
    final double heightVal = 1.0 - curEmaClamped;
    frameTelemetry.add({
      't': r.t,
      'reps': repCount,
      'depth': heightVal,
      'metric_label': 'HEIGHT',
      'metric_value': heightVal,
      'feedback': null,
      'rep_just_finished': repJustFinished,
      'landmarks': r.landmarks,
      'barbell_bbox': r.barbellBbox,
    });
  }

  if (state == 'HINGED') {
    final hipDesc = (repMaxHipY != null && repBaselineHipY != null)
        ? (repMaxHipY! - repBaselineHipY!)
        : 0.0;
    final kneeDrop = (repBaselineKnee != null && repMinKnee != null)
        ? (repBaselineKnee! - repMinKnee!)
        : 0.0;
    final hipxRng = (repHipxMax != null && repHipxMin != null)
        ? (repHipxMax! - repHipxMin!)
        : 0.0;
    final holdOk = deepCount >= minHoldDeepFrames;
    final double endRepDurSec = (raw.last.idx - repStartFrame) / fps;
    final bool durOk = endRepDurSec >= MIN_REP_DURATION_SEC;
    final hipOk = hipDesc >= reqHipDescent;
    final kneeOk = kneeDrop >= reqKneeDrop;
    final double walkXThresh = hipRange > 0.10 ? 0.20 : 0.15;
    final bool walkOk = hipxRng <= walkXThresh;
    final bool isFirstMidRep = committedReps.isEmpty && firstRepStartedMidRep;
    final bool peakOk = !isFirstMidRep || peakInRep >= FIRST_REP_MIN_PEAK;
    final double endRepHipYRange = (repMaxHipY != null && repMinHipY != null)
        ? (repMaxHipY! - repMinHipY!)
        : 0.0;
    const double END_MIN_REP_HIPY_RANGE = 0.025;
    final bool hipMotionOk = endRepHipYRange >= END_MIN_REP_HIPY_RANGE;
    final double minKneeBottomTh =
        hipRange > 0.15 ? 120.0 : (hipRange > 0.10 ? 125.0 : 140.0);
    final bool kneeBottomOk =
        repMinKnee == null || repMinKnee! <= minKneeBottomTh;
    final double lateralVertRatio =
        endRepHipYRange > 0.001 ? hipxRng / endRepHipYRange : 0.0;
    final bool lateralOk = peakInRep >= LATERAL_GATE_PEAK_TH ||
        lateralVertRatio <= LATERAL_GATE_RATIO_TH;

    final bool committedStrict = !videoIsStatic &&
        !videoNotADeadlift &&
        holdOk &&
        durOk &&
        (hipOk || kneeOk) &&
        walkOk &&
        peakOk &&
        hipMotionOk &&
        kneeBottomOk &&
        lateralOk;

    // [FUSION-1/2] Evaluate the barbell on the end-of-video candidate.
    final Map<String, dynamic> barEvalEnd =
        computeCandidateBarbell(repStartFrame, raw.last.idx);
    final bool barConfirmedEnd = barEvalEnd['confirmed'] == true;

    bool rescuedByBarEnd = false;
    if (ENABLE_BARBELL_RESCUE &&
        !committedStrict &&
        !videoIsStatic &&
        !videoNotADeadlift &&
        barConfirmedEnd &&
        peakInRep >= BORDERLINE_PEAK_MIN &&
        peakInRep <= BORDERLINE_PEAK_MAX &&
        holdOk &&
        durOk) {
      int softFailures = 0;
      if (!hipOk && !kneeOk) softFailures++;
      if (!walkOk) softFailures++;
      if (!peakOk) softFailures++;
      if (!hipMotionOk) softFailures++;
      if (!kneeBottomOk) softFailures++;
      if (!lateralOk) softFailures++;
      if (softFailures == 1) rescuedByBarEnd = true;
    }

    final bool committed = committedStrict || rescuedByBarEnd;

    final List<String> failedGates = [];
    if (!holdOk) failedGates.add('holdOk');
    if (!durOk) failedGates.add('durOk');
    if (!(hipOk || kneeOk)) failedGates.add('hipOrKneeOk');
    if (!walkOk) failedGates.add('walkOk');
    if (!peakOk) failedGates.add('peakOk');
    if (!hipMotionOk) failedGates.add('hipMotionOk');
    if (!kneeBottomOk) failedGates.add('kneeBottomOk');
    if (!lateralOk) failedGates.add('lateralOk');
    diagCandidates.add({
      'endOfVideo': true,
      'tStart': rd(repStartFrame / fps, 2),
      'tEnd': rd(raw.last.idx / fps, 2),
      'peakSig': rd(peakInRep, 3),
      'deepCt': deepCount,
      'hipDesc': rd(hipDesc, 4),
      'kneeDrop': rd(kneeDrop, 2),
      'repHipYRange': rd(endRepHipYRange, 4),
      'hipxRng': rd(hipxRng, 4),
      'latVRatio': rd(lateralVertRatio, 3),
      'repMaxWristDy': repMaxWristDy != null ? rd(repMaxWristDy!, 4) : null,
      'committed': committed,
      'committedStrict': committedStrict,
      'rescuedByBar': rescuedByBarEnd,
      'barbell': barEvalEnd,
      'failedGates': failedGates,
    });

    if (committed) {
      repCount++;
      final repScore = _scoreDeadliftRep(
        peakInRep,
        hipDesc,
        kneeDrop,
        DEPTH_EXCELLENT_PEAK,
        DEPTH_GOOD_PEAK,
        DEPTH_FAIR_PEAK,
        KNEE_DROP_EXCELLENT,
        KNEE_DROP_GOOD,
        KNEE_DROP_FAIR,
        HIP_DESC_EXCELLENT,
        HIP_DESC_GOOD,
        HIP_DESC_FAIR,
      );
      final repHipYRange = (repMaxHipY != null && repMinHipY != null)
          ? (repMaxHipY! - repMinHipY!)
          : 0.0;
      final repShYRange = (repMaxShY != null && repMinShY != null)
          ? (repMaxShY! - repMinShY!)
          : 0.0;
      committedReps.add(_RepInfo(
        startFrame: repStartFrame,
        endFrame: raw.last.idx,
        bottomFrameI: curRepBottomI ?? (raw.length - 1),
        peakSig: peakInRep,
        hipDesc: hipDesc,
        kneeDrop: kneeDrop,
        score: repScore,
        hipYRange: repHipYRange,
        shYRange: repShYRange,
      ));
      if (frameTelemetry.isNotEmpty) {
        frameTelemetry.last['reps'] = repCount;
        frameTelemetry.last['rep_just_finished'] =
            repScore >= 7.0 ? 'good' : 'bad';
      }
    }
  }

  // ================ 6) Phase 1 post-process: align counter to lockout ================
  const int MAX_LOCKOUT_LOOKAHEAD_SEC = 2;
  final int maxLookaheadFrames = (MAX_LOCKOUT_LOOKAHEAD_SEC * fps).round();

  final List<int> repLockoutFrameI = [];
  // True min EMA per rep (before visual delay) — used by both the
  // v10 outlier check and the HEIGHT rescaling below.
  final List<double> repLockoutMinEma = [];

  for (final f in frameTelemetry) {
    f['rep_just_finished'] = null;
  }

  for (int repI = 0; repI < committedReps.length; repI++) {
    final r = committedReps[repI];

    final int nextRepStartI = repI + 1 < committedReps.length
        ? committedReps[repI + 1].bottomFrameI
        : raw.length;
    final int searchEnd = math.min(
      raw.length,
      math.min(nextRepStartI, r.bottomFrameI + maxLookaheadFrames),
    );

    int lockoutFrameI = r.bottomFrameI;
    double minEma = emaByFrame.isNotEmpty && r.bottomFrameI < emaByFrame.length
        ? emaByFrame[r.bottomFrameI]
        : 1.0;
    for (int j = r.bottomFrameI + 1; j < searchEnd; j++) {
      if (j >= emaByFrame.length) break;
      if (emaByFrame[j] < minEma) {
        minEma = emaByFrame[j];
        lockoutFrameI = j;
      }
    }
    repLockoutMinEma.add(minEma);

    const double LOCKOUT_VISUAL_DELAY_SEC = 0.20;
    final int lockoutVisualDelayFrames =
        math.max(1, (LOCKOUT_VISUAL_DELAY_SEC * fps).round());
    int adjustedLockoutI = lockoutFrameI + lockoutVisualDelayFrames;
    if (adjustedLockoutI >= searchEnd) adjustedLockoutI = searchEnd - 1;
    if (adjustedLockoutI < lockoutFrameI) adjustedLockoutI = lockoutFrameI;
    lockoutFrameI = adjustedLockoutI;

    repLockoutFrameI.add(lockoutFrameI);
  }

  // ================ 6) WALK-OUT CHECK — DISABLED ================
  //
  // The walk-out check used to detect post-rep walking motion and
  // remove the last committed rep if walking was seen. It targeted
  // the "fake bend without bar followed by walking" pattern.
  //
  // The problem: walking AFTER a real rep looks identical to walking
  // after a fake bend. The lifter naturally walks away after finishing
  // a set. The check kept removing real reps and there's no signal in
  // the pose data alone to tell the two cases apart.
  //
  // Worse: when the walking IS captured as its own rejected candidate
  // (with walkOk/lateralOk failing), the walking has already been
  // correctly identified and excluded. Re-attributing that walking to
  // the previous real rep is double-counting the signal in the wrong
  // direction.
  //
  // Disabled. The duration filter and main-loop rep validation gates
  // (walkOk, lateralOk, hipMotionOk, kneeBottomOk, etc.) already
  // reject walking candidates from being committed in the first place.
  if (committedReps.isNotEmpty) {
    final int lockoutFrameI = repLockoutFrameI[committedReps.length - 1];
    diagWalkout = {
      'enabled': false,
      'lastRepLockoutFrameI': lockoutFrameI,
      'note': 'walk-out check disabled — cannot distinguish '
          'post-real-rep walking from fake-bend walking; relies on '
          'rep-validation gates to filter walking candidates instead',
    };
  }

  // ================ 6.5) v10 OUTLIER REMOVAL — DISABLED ================
  //
  // The lockout-EMA outlier filter was over-aggressive in real-world
  // cases: a single rep with an unusually high lockoutEma (because
  // the lifter walked away mid-stand, or due to camera-angle effects)
  // looked identical to a "fake bend" rep. lockoutEma alone simply
  // doesn't distinguish them.
  //
  // The duration filter (MIN_REP_DURATION_SEC) handles sub-second
  // noise blips upstream. The walk-out check (above) handles the
  // "fake bend followed by walking" pattern. Together those two
  // cover most cases v10 was meant to catch, without v10's tendency
  // to remove real reps with high lockoutEma.
  diagOutlier = {
    'enabled': false,
    'committedRepsCount': committedReps.length,
    'note': 'v10 disabled — lockoutEma alone cannot reliably '
        'distinguish real reps from fake bends',
  };

  for (final f in frameTelemetry) {
    f['reps'] = 0;
  }
  for (int repI = 0; repI < committedReps.length; repI++) {
    final lockoutI = repLockoutFrameI[repI];
    if (lockoutI < 0 || lockoutI >= frameTelemetry.length) continue;
    final r = committedReps[repI];
    frameTelemetry[lockoutI]['rep_just_finished'] =
        r.score >= 7.0 ? 'good' : 'bad';
    for (int j = lockoutI; j < frameTelemetry.length; j++) {
      frameTelemetry[j]['reps'] = repI + 1;
    }
  }

  repCount = committedReps.length;

  diagFinal = {
    'repCount': repCount,
    'committedReps': committedReps
        .map((r) => {
              'tStart': rd(r.startFrame / fps, 2),
              'tEnd': rd(r.endFrame / fps, 2),
              'peakSig': rd(r.peakSig, 3),
              'score': rd(r.score, 1),
            })
        .toList(),
    'repLockoutMinEma': repLockoutMinEma.map((e) => rd(e, 4)).toList(),
  };

  // ================ 6a) HEIGHT display rescaling ================
  // After v10 has removed any outlier rep, the surviving lockout EMAs
  // all reflect real reps. We can safely use the MAX of these (the
  // "shallowest real lockout") as the anchor — exactly the original
  // intent, but no longer poisoned by a phantom rep.
  if (committedReps.isNotEmpty && repLockoutFrameI.isNotEmpty) {
    double? shallowestLockoutEma;
    for (int repI = 0; repI < repLockoutFrameI.length; repI++) {
      final int lockoutI = repLockoutFrameI[repI];
      if (lockoutI >= 0 && lockoutI < emaByFrame.length) {
        final double e = emaByFrame[lockoutI];
        if (shallowestLockoutEma == null || e > shallowestLockoutEma) {
          shallowestLockoutEma = e;
        }
      }
    }
    if (shallowestLockoutEma != null &&
        shallowestLockoutEma > 0.05 &&
        shallowestLockoutEma < 0.9) {
      final double displayEmaRange = 1.0 - shallowestLockoutEma;
      for (int i = 0; i < frameTelemetry.length && i < emaByFrame.length; i++) {
        final double e = emaByFrame[i].clamp(0.0, 1.0);
        double h = (1.0 - e) / displayEmaRange;
        if (h < 0.0) h = 0.0;
        if (h > 1.0) h = 1.0;
        frameTelemetry[i]['depth'] = h;
        frameTelemetry[i]['metric_value'] = h;
      }
    }
  }

  // ================ 6b) Aggregate session-level form errors ================
  final Set<String> sessionFormErrors = {};
  final Set<String> sessionPerfTips = {};

  int shallowCount = 0;
  for (final r in committedReps) {
    if (r.peakSig < DEPTH_FAIR_PEAK) shallowCount++;
  }
  if (shallowCount >= DEPTH_FAIL_MIN_REPS) {
    sessionFormErrors.add(FB_ERROR_DEPTH);
  }

  if (committedReps.isNotEmpty) {
    double totalRepDurSec = 0;
    double totalDescDurSec = 0;
    int validRepDurCount = 0;
    int validDescDurCount = 0;
    for (final r in committedReps) {
      final double repDurSec = (r.endFrame - r.startFrame) / fps;
      if (repDurSec > 0) {
        totalRepDurSec += repDurSec;
        validRepDurCount++;
      }
      final double descDurSec = (r.bottomFrameI - r.startFrame + 1) / fps;
      if (descDurSec > 0) {
        totalDescDurSec += descDurSec;
        validDescDurCount++;
      }
    }
    final double avgRepDurSec =
        validRepDurCount > 0 ? totalRepDurSec / validRepDurCount : 0;
    final double avgDescDurSec =
        validDescDurCount > 0 ? totalDescDurSec / validDescDurCount : 0;

    const double TEMPO_FAST_REP_TH = 2.5;
    const double TEMPO_FAST_DESC_TH = 0.7;
    final bool isFastTempo =
        (avgRepDurSec > 0 && avgRepDurSec < TEMPO_FAST_REP_TH) ||
            (avgDescDurSec > 0 && avgDescDurSec < TEMPO_FAST_DESC_TH);

    if (isFastTempo) {
      sessionPerfTips.add(PERF_TIP_TEMPO);
    } else {
      sessionPerfTips.add(PERF_TIP_BREATHING);
    }
  }

  final List<Map<String, dynamic>> repReports = [];
  for (int i = 0; i < committedReps.length; i++) {
    final r = committedReps[i];
    repReports.add({
      'rep_index': i + 1,
      'score': r.score,
      'good': r.score >= 9.0,
      'detailed_scores': {
        'depth': (r.peakSig * 10.0).clamp(0.0, 10.0),
        'lockout': 10.0,
        'hips': 10.0,
        'flare': 10.0,
      },
      'measurements': {
        'peak_signal': r.peakSig,
        'hip_descent': r.hipDesc,
        'knee_drop': r.kneeDrop,
      },
    });
  }

  final int holdFramesMedium = math.max(1, (1.0 * fps).round());
  for (int i = 0; i < committedReps.length; i++) {
    final r = committedReps[i];
    if (r.score >= 7.0) continue;

    String? fb;
    if (r.peakSig < DEPTH_FAIR_PEAK &&
        sessionFormErrors.contains(FB_ERROR_DEPTH)) {
      fb = FB_ERROR_DEPTH;
    }
    if (fb == null) continue;

    final int lockoutI =
        i < repLockoutFrameI.length ? repLockoutFrameI[i] : (r.endFrame - 1);
    final int s = math.max(0, lockoutI);
    final int e =
        math.min(frameTelemetry.length - 1, lockoutI + holdFramesMedium);
    for (int f = s; f <= e; f++) {
      frameTelemetry[f]['feedback'] = fb;
    }
  }

  int goodReps = 0;
  int badReps = 0;
  for (final r in committedReps) {
    if (r.score >= 7.0) {
      goodReps++;
    } else {
      badReps++;
    }
  }

  double techniqueScore;
  if (repCount == 0) {
    techniqueScore = 0.0;
  } else {
    double penalty;
    if (sessionFormErrors.isNotEmpty) {
      penalty = 0.0;
      for (final m in sessionFormErrors) {
        penalty += FB_WEIGHTS[m] ?? FB_DEFAULT_WEIGHT;
      }
      penalty = math.max(PENALTY_MIN_IF_ANY, penalty);
    } else {
      penalty = 0.0;
    }
    techniqueScore = halfFloor10(math.max(0.0, 10.0 - penalty));

    if (repReports.isNotEmpty) {
      final double avgRepScore = repReports
              .map<double>((r) => (r['score'] as num).toDouble())
              .reduce((a, b) => a + b) /
          repReports.length;
      if (avgRepScore < 9.0 && techniqueScore >= 10.0) {
        techniqueScore = halfFloor10(avgRepScore + 0.5);
      }
    }
  }
  if (sessionFormErrors.isEmpty && repCount > 0) {
    techniqueScore = 10.0;
  }

  final List<String> formErrorsList = FORM_ERROR_PRIORITY
      .where((err) => sessionFormErrors.contains(err))
      .toList();
  final List<String> perfTipsList =
      PERF_TIP_PRIORITY.where((tip) => sessionPerfTips.contains(tip)).toList();

  final List<String> feedbackList;
  if (repCount == 0) {
    feedbackList = <String>[
      "Couldn't analyze this video — make sure your full body is visible and that you complete at least one deadlift."
    ];
  } else if (formErrorsList.isNotEmpty) {
    feedbackList = formErrorsList;
  } else {
    feedbackList = <String>['Great form! Keep it up 💪'];
  }

  final String fileUri = 'file://$videoPath';

  // [DIAG] Single-string summary for binding to a UI Text widget.
  final StringBuffer dbgStr = StringBuffer();
  dbgStr.write('reps=$repCount ');
  if (repLockoutMinEma.isNotEmpty) {
    dbgStr.write('lockoutEmas=[');
    for (int i = 0; i < repLockoutMinEma.length; i++) {
      if (i > 0) dbgStr.write(',');
      dbgStr.write(rd(repLockoutMinEma[i], 3).toString());
    }
    dbgStr.write('] ');
  }
  if (diagOutlier != null && diagOutlier['removedCount'] != null) {
    dbgStr.write('outlierRemoved=${diagOutlier['removedCount']} ');
  }
  if (diagCandidates.isNotEmpty) {
    dbgStr.write('cands=${diagCandidates.length} ');
    final committedTimes = diagCandidates
        .where((c) => c['committed'] == true)
        .map((c) => '${c['tStart']}-${c['tEnd']}s(p=${c['peakSig']})')
        .toList();
    dbgStr.write('committed=[${committedTimes.join("|")}] ');
    final rejected = diagCandidates.where((c) => c['committed'] == false);
    if (rejected.isNotEmpty) {
      dbgStr.write('rejected=[');
      for (final c in rejected) {
        dbgStr
            .write('${c['tStart']}s(${(c['failedGates'] as List).join(",")})|');
      }
      dbgStr.write('] ');
    }
  }

  // ----- Barbell detection summary (TEST ONLY — not gating reps yet) -----
  // Per-rep barbell-detection rate is informative: a real rep should have a
  // high rate (lots of frames with the bar visible during the hinge); a fake
  // rep performed without a bar should have near-zero rate. This is exactly
  // the signal we plan to add as a commit gate once the model is trusted.
  //
  // [FUSION-1] v4 also computes per-rep barbell *motion* (vertical bbox
  // range over the rep window) and *proximity* (mean wrist-to-bbox-center
  // distance). A real deadlift moves the bar vertically through ~bar's-
  // height-from-floor; a fake bend does not. The bar is also always close
  // to the lifter's hands during the lift.
  final List<Map<String, dynamic>> repBarbellStats = [];
  // Also collect a per-rep "confirmed" flag for the (optional) rescue.
  final List<bool> repBarbellConfirmed =
      List.filled(committedReps.length, false);
  for (int i = 0; i < committedReps.length; i++) {
    final r = committedReps[i];
    final int sIdx = math.max(0, math.min(raw.length - 1, r.startFrame - 1));
    final int eIdx = math.max(0, math.min(raw.length - 1, r.endFrame - 1));
    final int bIdx = math.max(0, math.min(raw.length - 1, r.bottomFrameI));

    int total = 0;
    int withBar = 0;
    int deepWithBar = 0;
    int deepTotal = 0;
    double maxConfInRep = 0.0;

    // [FUSION-1] new tracking
    double barYMin = double.infinity;
    double barYMax = -double.infinity;
    double sumConf = 0.0;
    double sumWristBarDist = 0.0;
    int wristBarSamples = 0;

    for (int j = sIdx; j <= eIdx; j++) {
      total++;
      final bbox = raw[j].barbellBbox;
      final double curEmaJ = (j < emaByFrame.length) ? emaByFrame[j] : 0.0;
      final bool isDeep = curEmaJ >= T_DEEP;
      if (isDeep) deepTotal++;
      if (bbox != null) {
        withBar++;
        if (isDeep) deepWithBar++;
        final c = (bbox['confidence'] as num?)?.toDouble() ?? 0.0;
        if (c > maxConfInRep) maxConfInRep = c;
        sumConf += c;

        // bar Y-center range
        final by = (bbox['y_center'] as num?)?.toDouble() ?? double.nan;
        if (!by.isNaN) {
          if (by < barYMin) barYMin = by;
          if (by > barYMax) barYMax = by;
        }

        // wrist-bar distance (in normalized original-frame coords).
        // [v4] Now uses the real wrist midpoint (wristX, wristY) instead
        // of approximating with hipX.
        final fr = raw[j];
        if (fr.wristY != null && fr.wristX != null) {
          final bx = (bbox['x_center'] as num?)?.toDouble() ?? double.nan;
          if (!bx.isNaN && !by.isNaN) {
            final dx = bx - fr.wristX!;
            final dy = by - fr.wristY!;
            final dist = math.sqrt(dx * dx + dy * dy);
            sumWristBarDist += dist;
            wristBarSamples++;
          }
        }
      }
    }
    final double overallRate = total > 0 ? withBar / total : 0.0;
    final double deepRate = deepTotal > 0 ? deepWithBar / deepTotal : 0.0;
    final double barYRange =
        (barYMax > -double.infinity && barYMin < double.infinity)
            ? (barYMax - barYMin)
            : 0.0;
    final double meanConf = withBar > 0 ? sumConf / withBar : 0.0;
    final double meanWristBarDist =
        wristBarSamples > 0 ? sumWristBarDist / wristBarSamples : double.nan;

    // [FUSION-2] "Confirmed by the bar" — all three conditions
    final bool barConfirmed = overallRate >= BAR_CONFIRM_DET_RATE &&
        barYRange >= BAR_CONFIRM_Y_RANGE &&
        (!meanWristBarDist.isNaN && meanWristBarDist <= BAR_CONFIRM_WRIST_DIST);
    repBarbellConfirmed[i] = barConfirmed;

    repBarbellStats.add({
      'rep_index': i + 1,
      'total_frames': total,
      'frames_with_barbell': withBar,
      'detection_rate': _rd3(overallRate),
      'deep_frames': deepTotal,
      'deep_frames_with_barbell': deepWithBar,
      'deep_detection_rate': _rd3(deepRate),
      'max_confidence_in_rep': _rd3(maxConfInRep),
      'mean_confidence_in_rep': _rd3(meanConf),
      'bar_y_range': _rd3(barYRange),
      'mean_wrist_bar_dist':
          meanWristBarDist.isNaN ? null : _rd3(meanWristBarDist),
      'barbell_confirmed': barConfirmed,
      'would_pass_gate_50pct': deepRate >= 0.5,
    });
  }

  int totalFramesWithBbox = 0;
  for (final r in raw) {
    if (r.barbellBbox != null) totalFramesWithBbox++;
  }
  final Map<String, dynamic> barbellDebug = {
    'load_info': yoloLoadInfo,
    'frames_run': yoloFramesRun,
    'frames_skipped': yoloFramesSkipped,
    'frames_with_barbell': yoloFramesWithBarbell,
    'total_frames_with_bbox': totalFramesWithBbox,
    'max_confidence_seen': _rd3(yoloMaxConfSeen),
    'overall_detection_rate':
        yoloFramesRun > 0 ? _rd3(yoloFramesWithBarbell / yoloFramesRun) : 0.0,
    'rescue_enabled': ENABLE_BARBELL_RESCUE,
    'per_rep': repBarbellStats,
  };

  // Append a barbell summary to debug_string so a single Text widget shows it.
  dbgStr.write('| barbell: ');
  if (yoloInterpreter == null) {
    dbgStr.write('disabled ($yoloLoadInfo) ');
  } else {
    dbgStr.write(
        'ran=$yoloFramesRun skipped=$yoloFramesSkipped withBar=$yoloFramesWithBarbell maxConf=${_rd3(yoloMaxConfSeen)} ');
    if (repBarbellStats.isNotEmpty) {
      dbgStr.write('perRep[detRate|yRange|wristDist|conf?]=[');
      for (int i = 0; i < repBarbellStats.length; i++) {
        if (i > 0) dbgStr.write(' ');
        final s = repBarbellStats[i];
        final cf = s['barbell_confirmed'] == true ? '✓' : '✗';
        dbgStr.write(
            '${s['detection_rate']}|${s['bar_y_range']}|${s['mean_wrist_bar_dist']}|$cf');
      }
      dbgStr.write('] ');
    }
    // Count rescues
    int rescuedCount = 0;
    for (final c in diagCandidates) {
      if (c['rescuedByBar'] == true) rescuedCount++;
    }
    if (rescuedCount > 0) {
      dbgStr.write('rescued=$rescuedCount ');
    }
  }

  final Map<String, dynamic> result = {
    'squat_count': repCount,
    'technique_score': techniqueScore,
    'technique_score_display': displayHalfStr(techniqueScore),
    'technique_label': scoreLabel(techniqueScore),
    'good_reps': goodReps,
    'bad_reps': badReps,
    'feedback': feedbackList,
    'tips': repCount == 0 ? <String>[] : perfTipsList,
    'reps': repReports,
    'exercise_type': 'deadlift',
    'video_path': fileUri,
    'analyzed_fps': fps,
    'frame_count': frameIdx,
    '_source_video_uri': fileUri,
    '_frame_telemetry': frameTelemetry,
    'debug_string': dbgStr.toString(),
    'debug': {
      'calib': diagCalib,
      'candidates': diagCandidates,
      'walkout': diagWalkout,
      'outlier': diagOutlier,
      'final': diagFinal,
      'barbell': barbellDebug,
    },
  };
  if (perfTipsList.isNotEmpty && repCount > 0) {
    result['form_tip'] = perfTipsList.first;
    result['primary_perf_tip'] = perfTipsList.first;
  }
  if (formErrorsList.isNotEmpty) {
    result['primary_form_error'] = formErrorsList.first;
  }

  return result;
}

class _FrameRaw {
  final int idx;
  final double t;
  final bool valid;
  final double? visMinLm;
  final double? hipY;
  final double? hipX;
  final double? kneeAng;
  final double? wristHipDy;
  final double? shY;
  final double? wristY;
  final double? wristX;
  final List<List<double>> landmarks;
  final Map<String, dynamic>? barbellBbox;
  _FrameRaw({
    required this.idx,
    required this.t,
    required this.valid,
    this.visMinLm,
    this.hipY,
    this.hipX,
    this.kneeAng,
    this.wristHipDy,
    this.shY,
    this.wristY,
    this.wristX,
    required this.landmarks,
    this.barbellBbox,
  });
}

class _RepInfo {
  final int startFrame, endFrame;
  final int bottomFrameI;
  final double peakSig;
  final double hipDesc;
  final double kneeDrop;
  final double score;
  final double hipYRange;
  final double shYRange;
  _RepInfo({
    required this.startFrame,
    required this.endFrame,
    required this.bottomFrameI,
    required this.peakSig,
    required this.hipDesc,
    required this.kneeDrop,
    required this.score,
    required this.hipYRange,
    required this.shYRange,
  });
}

double _scoreDeadliftRep(
  double peakSig,
  double hipDesc,
  double kneeDrop,
  double deepExc,
  double deepGood,
  double deepFair,
  double kneeExc,
  double kneeGood,
  double kneeFair,
  double hipExc,
  double hipGood,
  double hipFair,
) {
  double depthScore;
  if (peakSig >= deepExc) {
    depthScore = 10.0;
  } else if (peakSig >= deepGood) {
    depthScore = 9.0;
  } else if (peakSig >= deepFair) {
    depthScore = 7.5;
  } else {
    depthScore = 5.0;
  }
  double romScore;
  if (kneeDrop >= kneeExc || hipDesc >= hipExc) {
    romScore = 10.0;
  } else if (kneeDrop >= kneeGood || hipDesc >= hipGood) {
    romScore = 9.0;
  } else if (kneeDrop >= kneeFair || hipDesc >= hipFair) {
    romScore = 7.5;
  } else {
    romScore = 5.0;
  }
  double s = depthScore * 0.6 + romScore * 0.4;
  s = (s * 2).round() / 2.0;
  return math.max(0.0, math.min(10.0, s));
}

double _cachedW = -1;
double _cachedH = -1;

double _rd3(double x) {
  return (x * 1000).round() / 1000.0;
}

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
