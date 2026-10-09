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

/// Analyze a pushup video locally using ML Kit Pose Detection.
///
/// v19 — FEEDBACK SYNC. The returned `feedback` list is now derived
/// from EXACTLY the set of errors that were displayed as in-video
/// banners by the phase-2 post-process. Summary feedback and video
/// feedback can no longer diverge. Two surgical changes, no behavior
/// change to counting, scoring thresholds, or banner placement:
///
///   (LL) A `displayedFormErrors` set records every error string that
///        `addFb` actually wrote into frame telemetry. After phase 2,
///        `sessionFormErrors` is overwritten with that set. Legacy
///        paths that added session-level errors WITHOUT a matching
///        banner (e.g. HIPS fired at plank-exit via evaluateCycleForm,
///        or leftover in-loop accumulators) can no longer leak into
///        the summary.
///
///   (MM) The legacy score-percentile DEPTH check in the aggregation
///        section is DISABLED. It ran AFTER the post-process pass had
///        already decided (and possibly cleared) the depth verdict,
///        re-adding FB_ERROR_DEPTH to the summary with zero in-video
///        banner — exactly the mismatch the user reported. The v17/v18
///        visual depth check in the post-process is authoritative.
///
/// v18 (kept): depth check tuning. v17 was too aggressive — flagged
/// visually deep reps as shallow (false positives). The fix:
///
///   (II) Search ±5 frames around bottomIdx for the actual deepest
///        frame (smallest raw elbow angle). bottomIdx is just the
///        frame the rep was DETECTED at, which is often a frame or
///        two before the user actually reaches their lowest point.
///
///   (JJ) Use raw elbow min (not EMA-smoothed) for the depth check.
///        EMA still reflects higher angles from earlier in the descent.
///
///   (KK) Threshold raised: elbow > 110° (was 100°) and shY-elY tol
///        raised to 0.025 (was 0.01). On the user's videos these
///        cleared all visually-deep reps that v17 flagged.
///
/// v17 (replaced): introduced shoulder-vs-elbow + elbow-angle combined
/// depth check at the bottom of each rep. Logic kept; thresholds tuned.
///
/// v16 (kept): Frame loop runs to end of video — no early break.
/// v15 (kept): Lockout 165° threshold.
/// v14 (kept): EXTREME_TEMPO_MIN_REPS = 1
/// v13 (kept): Error-specific timing windows.
/// v11 (kept): visual peak by shoulderY.
/// v10 (kept): two-phase post-process.
/// v9  (kept): LOCKOUT-MIN-REPS = 3.
Future<dynamic> analyzePushupVideoAction(
  FFUploadedFile videoFile,
  double? targetFps,
) async {
  // ================ Parameters ================
  const double ELBOW_BENT_ANGLE = 105.0;
  const double SHOULDER_MIN_DESCENT = 0.032;
  const double RESET_ASCENT = 0.018;
  const double RESET_ELBOW = 148.0;
  const int REFRACTORY_FRAMES = 5;

  const double ELBOW_EMA_ALPHA = 0.92;
  const double SHOULDER_EMA_ALPHA = 0.90;

  const double VIS_THR_STRICT = 0.29;
  const double PLANK_BODY_ANGLE_MAX = 26.0;
  const double HANDS_BELOW_SHOULDERS = 0.035;
  const int ONPUSHUP_MIN_FRAMES = 2;
  const int OFFPUSHUP_MIN_FRAMES = 5;
  const double AUTO_STOP_AFTER_EXIT_SEC = 1.5;
  const double TAIL_NOPOSE_STOP_SEC = 1.0;
  const double RAW_ELBOW_REARM_RISE = 18.0;

  const String FB_ERROR_DEPTH = 'Go deeper (chest to floor)';
  const String FB_ERROR_HIPS = "Keep hips level (don't sag or pike)";
  const String FB_ERROR_LOCKOUT = 'Fully lockout arms at top';
  const String FB_ERROR_ELBOWS = 'Keep elbows at 45° (not flared)';
  // [v4 TEMPO-EXTREME-PENALTY] New form-level error for extreme descent
  // velocity. Distinct from the existing perf tips (which are softer).
  const String FB_ERROR_TEMPO_FAST = 'Slow down — control the descent';
  const String PERF_TIP_SLOW_DOWN = 'Lower slowly for better control';
  const String PERF_TIP_TEMPO = 'Try 2-1-2 tempo (down-pause-up)';
  const String PERF_TIP_BREATHING = 'Breathe: inhale down, exhale up';
  const String PERF_TIP_CORE = 'Engage core throughout movement';

  const Map<String, double> FB_WEIGHTS = {
    FB_ERROR_DEPTH: 1.2,
    FB_ERROR_HIPS: 1.0,
    FB_ERROR_LOCKOUT: 0.9,
    FB_ERROR_ELBOWS: 0.7,
    // [v4] Tempo extreme is a real form penalty.
    FB_ERROR_TEMPO_FAST: 1.5,
  };
  const double FB_DEFAULT_WEIGHT = 0.5;
  const double PENALTY_MIN_IF_ANY = 0.5;

  const List<String> FORM_ERROR_PRIORITY = [
    // [v4] Tempo extreme has highest priority — it's the most actionable.
    FB_ERROR_TEMPO_FAST,
    FB_ERROR_DEPTH,
    FB_ERROR_LOCKOUT,
    FB_ERROR_HIPS,
  ];
  const List<String> PERF_TIP_PRIORITY = [
    PERF_TIP_SLOW_DOWN,
    PERF_TIP_TEMPO,
    PERF_TIP_BREATHING,
    PERF_TIP_CORE,
  ];

  const double DEPTH_EXCELLENT_ANGLE = 95.0;
  const double DEPTH_GOOD_ANGLE = 108.0;
  const double DEPTH_FAIR_ANGLE = 118.0;
  const double DEPTH_POOR_ANGLE = 128.0;
  const double HIP_EXCELLENT = 12.0;
  const double HIP_GOOD = 22.0;
  const double HIP_FAIR = 50.0;
  const double HIP_POOR = 65.0;
  const double LOCKOUT_EXCELLENT = 155.0;
  const double LOCKOUT_GOOD = 140.0;
  const double LOCKOUT_FAIR = 125.0;
  const double LOCKOUT_POOR = 110.0;
  const double FLARE_EXCELLENT = 90.0;
  const double FLARE_GOOD = 120.0;
  const double FLARE_FAIR = 150.0;
  const double FLARE_POOR = 180.0;

  const double DESCENT_SPEED_FAST = 0.0015;
  // [v5] Was 0.0035 in v4 — that fired on virtually every rep because the
  // descent of a normal pushup briefly hits velocities in that range. The
  // user reported this triggering on all reps, so we're disabling the
  // extreme tempo penalty for now by setting the threshold so high it
  // can't trigger. Keeping the constant + plumbing so we can re-enable
  // with a properly calibrated value later (would need real measurements
  // from a known "uncontrolled fall" video to set correctly).
  // [v8 TEMPO-DURATION] Switched from instantaneous max velocity to
  // descent DURATION as the trigger for "uncontrolled fast" feedback.
  // Velocity-based was firing on most reps because even controlled
  // descents have a brief peak velocity moment. Duration is what a
  // human coach actually checks ("how long did you take to go down?").
  //
  // [v10 RECALIBRATED] Was 0.13 in v9, but the user reports a 5-rep
  // video with descents 0.10–0.20s ("excellent execution at a good
  // tempo, not too fast") triggers the warning. Empirically that's
  // the user's NORMAL tempo. Lowering to 0.08s — at this point only
  // genuine drops (where the user is essentially falling, not lowering)
  // will hit. Below 0.08s, even the eye registers it as "drop" rather
  // than "fast lower". Keep tuning if the user finds new edge cases.
  const double EXTREME_DESCENT_DURATION_SEC = 0.08;

  const int DEPTH_FAIL_MIN_REPS = 4;
  const int HIPS_FAIL_MIN_REPS = 6;
  // [v9 LOWERED] Was 9 — but typical pushup sets in the wild are 1–10
  // reps, often 3–5. Requiring 9 misses meant the lockout warning
  // basically never fired. Lowered to 3 — if 3+ reps in a row missed
  // lockout, the user genuinely needs the cue.
  const int LOCKOUT_FAIL_MIN_REPS = 3;
  const int TEMPO_CHECK_MIN_REPS = 3;
  // [v14 LOWERED] Was 2 — but if the user does even one "drop" rep
  // it's worth flagging. With the conservative threshold (0.18s)
  // false positives are rare, so 1 is fine.
  const int EXTREME_TEMPO_MIN_REPS = 1;

  const double DEPTH_ERROR_ANGLE = 999.0; // disabled
  const double LOCKOUT_ERROR_ANGLE = -1.0; // disabled

  // [v6] Increased from 35 to 50 — the user reported the previous
  // threshold flagging good lockouts and missing actual short ones.
  // 50° is "a clear, hard-to-miss difference from the user's normal top"
  // rather than "a noticeable difference". If the user's typical top is
  // 165° and a particular rep tops out at 115° → still flagged. But a
  // rep at 130° → no longer flagged (assumed within ML Kit measurement
  // noise).
  const double LOCKOUT_RELATIVE_MARGIN = 50.0;
  const int LOCKOUT_TOP_K = 5;
  const int LOCKOUT_EVAL_MIN_REPS = 4;
  const double LOCKOUT_BAD_PCT_THRESHOLD = 0.85;
  const double DEPTH_BAD_PCT_THRESHOLD = 0.75;

  const double INFLECT_VEL_THR = 0.0027;
  const int MIN_CYCLE_ELBOW_SAMPLES = 2;
  const double ROBUST_BOTTOM_PERCENTILE = 25.0;
  const double ROBUST_CONFIRMED_PERCENTILE = 10.0;

  final double fps = (targetFps ?? 20.0).clamp(4.0, 30.0);
  final double dt = 1.0 / fps;
  final int OFFPUSHUP_STOP_FRAMES =
      math.max(1, (AUTO_STOP_AFTER_EXIT_SEC / dt).round());
  final int NOPOSE_STOP_FRAMES =
      math.max(1, (TAIL_NOPOSE_STOP_SEC / dt).round());
  // [v4 FEEDBACK-HOLD-LONGER] 1.5 sec instead of 0.8 — long enough that
  // even a 0.4-sec-per-rep fast cadence can't overwrite the message before
  // the eye registers it.
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

  double? medianOfTopK(List<double> values, int k) {
    if (values.isEmpty) return null;
    final sorted = List<double>.from(values)..sort((a, b) => b.compareTo(a));
    final take = sorted.take(math.min(k, sorted.length)).toList();
    take.sort();
    final int n = take.length;
    if (n == 0) return null;
    if (n.isOdd) return take[n ~/ 2];
    return (take[(n ~/ 2) - 1] + take[n ~/ 2]) / 2.0;
  }

  double calculateBodyAngle(List<double> mLsh, List<double> mRsh,
      List<double> mLa, List<double> mRa) {
    final midShX = (mLsh[0] + mRsh[0]) / 2.0;
    final midShY = (mLsh[1] + mRsh[1]) / 2.0;
    final midAnkX = (mLa[0] + mRa[0]) / 2.0;
    final midAnkY = (mLa[1] + mRa[1]) / 2.0;
    final dx = midShX - midAnkX;
    final dy = midShY - midAnkY;
    return (math.atan2(dy.abs(), dx.abs() + 1e-9) * 180.0 / math.pi).abs();
  }

  double calculateHipMisalignment(List<double> mLsh, List<double> mRsh,
      List<double> mLh, List<double> mRh, List<double> mLa, List<double> mRa) {
    final midSh = [(mLsh[0] + mRsh[0]) / 2.0, (mLsh[1] + mRsh[1]) / 2.0];
    final midHp = [(mLh[0] + mRh[0]) / 2.0, (mLh[1] + mRh[1]) / 2.0];
    final midAnk = [(mLa[0] + mRa[0]) / 2.0, (mLa[1] + mRa[1]) / 2.0];
    return (180.0 - ang(midSh, midHp, midAnk)).abs();
  }

  double calculateElbowFlare(List<double> mLsh, List<double> mRsh,
      List<double> mLe, List<double> mRe) {
    final midSh = [(mLsh[0] + mRsh[0]) / 2.0, (mLsh[1] + mRsh[1]) / 2.0];

    final leftVecShX = midSh[0] - mLsh[0];
    final leftVecShY = midSh[1] - mLsh[1];
    final leftVecElbX = mLe[0] - mLsh[0];
    final leftVecElbY = mLe[1] - mLsh[1];
    final leftAngle = (math.atan2(
              leftVecShX * leftVecElbY - leftVecShY * leftVecElbX,
              leftVecShX * leftVecElbX + leftVecShY * leftVecElbY,
            ) *
            180.0 /
            math.pi)
        .abs();

    final rightVecShX = midSh[0] - mRsh[0];
    final rightVecShY = midSh[1] - mRsh[1];
    final rightVecElbX = mRe[0] - mRsh[0];
    final rightVecElbY = mRe[1] - mRsh[1];
    final rightAngle = (math.atan2(
              rightVecShX * rightVecElbY - rightVecShY * rightVecElbX,
              rightVecShX * rightVecElbX + rightVecShY * rightVecElbY,
            ) *
            180.0 /
            math.pi)
        .abs();

    return math.max(leftAngle, rightAngle);
  }

  List<double?> robustCycleElbows(
    List<double> bottomSamples,
    List<double> topSamples,
    double? fallbackBottom,
    double? fallbackTop,
    List<double> confirmedBottom,
  ) {
    double? robustBottom = fallbackBottom;
    double? robustTop = medianOfTopK(topSamples, LOCKOUT_TOP_K) ?? fallbackTop;

    if (confirmedBottom.isNotEmpty) {
      robustBottom = percentile(confirmedBottom, ROBUST_CONFIRMED_PERCENTILE);
    } else if (bottomSamples.isNotEmpty) {
      robustBottom = percentile(bottomSamples, ROBUST_BOTTOM_PERCENTILE);
    }

    if (fallbackBottom != null && robustBottom != null) {
      robustBottom = math.min(robustBottom, fallbackBottom);
    }
    return [robustBottom, robustTop];
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
        'exercise_type': 'pushup',
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
    'pushup_in_${DateTime.now().millisecondsSinceEpoch}_$safeName',
  );
  try {
    await File(videoPath).writeAsBytes(videoFile.bytes!, flush: true);
  } catch (e) {
    return errorPayload('write_failed', 'Could not save upload: $e');
  }

  // ================ 1) Extract frames ================
  final String sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  final Directory framesDir =
      Directory(p.join(tmp.path, 'pushup_frames_$sessionId'));
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
      mode: PoseDetectionMode.stream,
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
  double? shoulderEma;
  double? shoulderPrev;
  double? shoulderVelPrev;
  double? baselineShoulderY;
  double? descBaseShoulder;
  bool allowNewBottom = true;
  int lastBottomFrame = -1000000000;
  double cycleMaxDescent = 0.0;
  double cycleMinElbow = 999.0;
  bool countedThisCycle = false;

  bool onpushup = false;
  int onpushupStreak = 0;
  int offpushupStreak = 0;
  int offpushupFramesSinceAnyRep = 0;
  int nopopseFramesSinceAnyRep = 0;

  final Set<String> sessionFormErrors = {};
  final Set<String> sessionPerfTips = {};
  String? rtFbMsg;
  int rtFbHold = 0;

  List<double> cycleBottomSamples = [];
  List<double> cycleTopSamples = [];
  List<double> confirmedBottomSamples = [];
  int depthFailCount = 0;
  int hipsFailCount = 0;
  int lockoutFailCount = 0;
  // [v4 TEMPO-EXTREME-PENALTY] Per-cycle counter for extreme tempo events.
  int extremeTempoFailCount = 0;
  bool extremeTempoAlreadyReported = false;

  final List<double> sessionTopMedians = [];

  String? repJustFinished;

  bool currentCycleHasIssue = false;
  int fastDescentCount = 0;
  bool depthAlreadyReported = false;
  bool hipsAlreadyReported = false;
  bool lockoutAlreadyReported = false;
  bool tempoAlreadyReported = false;

  double? bottomPhaseMinElbow;
  double? topPhaseMaxElbow;
  double? cycleMaxHipMisalign;
  double? cycleMaxFlare;
  double cycleMaxDescentVel = 0.0;
  // [v8 TEMPO-DURATION] Track the frame at which descent began so we can
  // compute descent DURATION at bottom (a much more reliable signal than
  // max instantaneous velocity, which spikes briefly even in controlled
  // pushups). Reset when descent restarts.
  int? descentStartFrame;
  bool inDescentPhase = false;

  // ============================================================
  // [v6 IMMEDIATE-COUNT + DEFERRED-DISPLAY]
  //
  // The counter is incremented IMMEDIATELY at bottom-detection (back to
  // the v3 counting model the user found most accurate). v4 and v5
  // tried to also defer the counting itself, which made detection less
  // reliable.
  //
  // What we keep deferred is only the VISIBLE EVENT (skeleton color
  // flash, haptic, sound). Each commit registers a pulseEvent with the
  // bottom frame index + verdict. After the loop completes, we walk the
  // event list and place each rep_just_finished pulse on the actual
  // visual peak frame (the frame with the highest raw elbow angle within
  // the rep's ascent window). The counting and form evaluation logic is
  // unchanged from v3; only the timing of the visible flash is shifted.
  // ============================================================
  final List<Map<String, dynamic>> pulseEvents = [];
  // We also need to remember the per-frame raw elbow max so the
  // post-process pass can find the visual peak. Stored separately from
  // frameTelemetry to avoid leaking internal data to the widget.
  final List<double> rawElbowMaxByFrame = [];
  // [v11] shoulder Y per frame for visual peak detection (head highest).
  final List<double?> shoulderYByFrame = [];
  // [v11] elbow min per frame for confidence gating.
  final List<double> rawElbowMinByFrame = [];
  // [v17 DEPTH-VIA-SHOULDER-VS-ELBOW] Track elbow Y position (mean of
  // both elbows) and the smoothed elbow angle per frame, so the post-
  // process pass can check depth at the bottom of each rep using a
  // visual criterion (shoulder vs elbow Y position) combined with
  // joint angle. Pure-angle was prone to false positives on
  // shallow-but-bent reps; pure-position was prone to false positives
  // on side-camera angles. Combining both catches genuine shallow
  // reps while sparing genuine deep reps.
  final List<double?> elbowYByFrame = [];
  final List<double?> elbowAngleEmaByFrame = [];

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

  // ---- build rep report (no counter mutation) ----
  Map<String, dynamic> buildRepReport({
    required double? bottomPhaseMinElbowArg,
    required double? topPhaseMaxElbowArg,
    required double? cycleMaxHipMisalignArg,
    required double? cycleMaxFlareArg,
  }) {
    double depthScore = 10.0;
    double lockoutScore = 10.0;
    double hipsScore = 10.0;
    double flareScore = 10.0;

    if (bottomPhaseMinElbowArg != null) {
      if (bottomPhaseMinElbowArg <= DEPTH_EXCELLENT_ANGLE) {
        depthScore = 10.0;
      } else if (bottomPhaseMinElbowArg <= DEPTH_GOOD_ANGLE) {
        depthScore = 9.0;
      } else if (bottomPhaseMinElbowArg <= DEPTH_FAIR_ANGLE) {
        depthScore = 7.5;
      } else if (bottomPhaseMinElbowArg <= DEPTH_POOR_ANGLE) {
        depthScore = 5.0;
      } else {
        depthScore = 3.0;
      }
    }
    if (topPhaseMaxElbowArg != null) {
      if (topPhaseMaxElbowArg >= LOCKOUT_EXCELLENT) {
        lockoutScore = 10.0;
      } else if (topPhaseMaxElbowArg >= LOCKOUT_GOOD) {
        lockoutScore = 9.0;
      } else if (topPhaseMaxElbowArg >= LOCKOUT_FAIR) {
        lockoutScore = 7.5;
      } else if (topPhaseMaxElbowArg >= LOCKOUT_POOR) {
        lockoutScore = 5.0;
      } else {
        lockoutScore = 3.0;
      }
    }
    if (cycleMaxHipMisalignArg != null) {
      if (cycleMaxHipMisalignArg <= HIP_EXCELLENT) {
        hipsScore = 10.0;
      } else if (cycleMaxHipMisalignArg <= HIP_GOOD) {
        hipsScore = 9.0;
      } else if (cycleMaxHipMisalignArg <= HIP_FAIR) {
        hipsScore = 7.5;
      } else if (cycleMaxHipMisalignArg <= HIP_POOR) {
        hipsScore = 5.0;
      } else {
        hipsScore = 3.0;
      }
    }
    if (cycleMaxFlareArg != null) {
      if (cycleMaxFlareArg <= FLARE_EXCELLENT) {
        flareScore = 10.0;
      } else if (cycleMaxFlareArg <= FLARE_GOOD) {
        flareScore = 9.0;
      } else if (cycleMaxFlareArg <= FLARE_FAIR) {
        flareScore = 7.5;
      } else if (cycleMaxFlareArg <= FLARE_POOR) {
        flareScore = 5.0;
      } else {
        flareScore = 3.0;
      }
    }

    double repScore =
        depthScore * 0.40 + lockoutScore * 0.30 + hipsScore * 0.30;
    repScore = (repScore * 2).round() / 2.0;

    return {
      'rep_index': 0,
      'score': repScore,
      'good': repScore >= 9.0,
      'detailed_scores': {
        'depth': depthScore,
        'lockout': lockoutScore,
        'hips': hipsScore,
        'flare': flareScore,
      },
      'measurements': {
        'bottom_elbow_angle': bottomPhaseMinElbowArg,
        'top_elbow_angle': topPhaseMaxElbowArg,
        'hip_misalignment': cycleMaxHipMisalignArg,
        'elbow_flare': cycleMaxFlareArg,
      },
    };
  }

  // [v6] Commit a rep IMMEDIATELY when bottom is detected. Returns the
  // rep's verdict so the caller can also record a pulseEvent for later
  // peak-aligned display. v3-style immediate counting; the visible
  // flash is moved to the peak in a post-process pass.
  String commitRep({
    required Map<String, dynamic> repData,
    required bool repIsBad,
    required double topElbowAngle,
  }) {
    final data = Map<String, dynamic>.from(repData);
    data['rep_index'] = repCount + 1;
    if (topElbowAngle > 0) {
      final meas = data['measurements'] as Map?;
      if (meas != null) meas['top_elbow_angle'] = topElbowAngle;
    }
    repReports.add(data);
    allScores.add((data['score'] as num).toDouble());
    repCount += 1;

    if (topElbowAngle > 0) sessionTopMedians.add(topElbowAngle);

    final bool showingFeedback = rtFbHold > 0 && rtFbMsg != null;
    final String verdict;
    if (repIsBad && showingFeedback) {
      badReps += 1;
      verdict = 'bad';
    } else {
      goodReps += 1;
      verdict = 'good';
    }
    return verdict;
  }

  // ---- evaluate cycle form ----
  // [v4] Also evaluates the new EXTREME tempo error.
  String? evaluateCycleForm({
    required double? bottomPhaseMinElbowArg,
    required double? topPhaseMaxElbowArg,
    required double? cycleMaxHipMisalignArg,
    required double cycleMaxDescentVelArg,
    required double? descentDurationSecArg, // [v8 TEMPO-DURATION]
    required int nBottom,
    required int nTop,
  }) {
    bool hasDepth = false;
    bool hasLockout = false;
    bool hasHips = false;
    bool hasExtremeTempo = false;

    currentCycleHasIssue = false;

    // [v8 TEMPO-DURATION] Hard form error: descent took less than the
    // duration threshold. Triggers from the first occurrence (no min
    // count) — uncontrolled drops should be flagged immediately.
    if (descentDurationSecArg != null &&
        descentDurationSecArg < EXTREME_DESCENT_DURATION_SEC) {
      hasExtremeTempo = true;
      extremeTempoFailCount += 1;
      if (extremeTempoFailCount >= EXTREME_TEMPO_MIN_REPS &&
          !extremeTempoAlreadyReported) {
        sessionFormErrors.add(FB_ERROR_TEMPO_FAST);
        extremeTempoAlreadyReported = true;
      }
    }

    if (bottomPhaseMinElbowArg != null && nBottom >= 1) {
      if (bottomPhaseMinElbowArg > DEPTH_ERROR_ANGLE) {
        hasDepth = true;
        depthFailCount += 1;
        if (depthFailCount >= DEPTH_FAIL_MIN_REPS && !depthAlreadyReported) {
          sessionFormErrors.add(FB_ERROR_DEPTH);
          depthAlreadyReported = true;
        }
      }
    }
    if (topPhaseMaxElbowArg != null && nTop >= 1) {
      // [v8 LOCKOUT-DISABLED-IN-LOOP] In-loop lockout check disabled.
      // The `topPhaseMaxElbowArg` here comes from cycleTopSamples which
      // gets contaminated with samples from the descent phase, making
      // the in-loop value unreliable. The post-process pass uses
      // rawElbowMaxByFrame to get the true peak per rep and decides
      // there. This block is left here as documentation.
    }
    if (cycleMaxHipMisalignArg != null) {
      if (cycleMaxHipMisalignArg > HIP_FAIR) {
        hasHips = true;
        hipsFailCount += 1;
        if (hipsFailCount >= HIPS_FAIL_MIN_REPS && !hipsAlreadyReported) {
          sessionFormErrors.add(FB_ERROR_HIPS);
          hipsAlreadyReported = true;
        }
      }
    }

    if (repCount >= TEMPO_CHECK_MIN_REPS && !tempoAlreadyReported) {
      if (cycleMaxDescentVelArg > DESCENT_SPEED_FAST) {
        fastDescentCount += 1;
        if (fastDescentCount >= 1) {
          sessionPerfTips.add(PERF_TIP_SLOW_DOWN);
          sessionPerfTips.add(PERF_TIP_TEMPO);
          tempoAlreadyReported = true;
        }
      }
    }

    currentCycleHasIssue = hasDepth || hasLockout || hasHips || hasExtremeTempo;

    // [v4] Tempo extreme has highest display priority — it's the most
    // urgent feedback and triggers immediately.
    if (hasExtremeTempo && sessionFormErrors.contains(FB_ERROR_TEMPO_FAST)) {
      return FB_ERROR_TEMPO_FAST;
    }
    if (hasDepth && sessionFormErrors.contains(FB_ERROR_DEPTH)) {
      return FB_ERROR_DEPTH;
    }
    if (hasLockout && sessionFormErrors.contains(FB_ERROR_LOCKOUT)) {
      return FB_ERROR_LOCKOUT;
    }
    if (hasHips && sessionFormErrors.contains(FB_ERROR_HIPS)) {
      return FB_ERROR_HIPS;
    }
    return null;
  }

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
        // [v15 NO-EARLY-BREAK] We used to break out of the frame loop
        // here after TAIL_NOPOSE_STOP_SEC of consecutive empty frames,
        // and similarly when the user exited plank in OFFPUSHUP_STOP.
        // The break left frameTelemetry truncated mid-video, so when
        // the widget tried to look up frames past the truncation point,
        // it kept returning the LAST telemetry entry — making the
        // skeleton appear to freeze and the counter to stop ticking
        // even though the video kept playing.
        //
        // Now we just keep emitting telemetry entries (with empty
        // landmarks if no pose) for every frame, all the way to the
        // end of the video. The widget renders nothing for empty-
        // landmark entries, so the skeleton just disappears cleanly
        // when the user is out of frame, instead of freezing.
        nopopseFramesSinceAnyRep =
            (repCount > 0) ? (nopopseFramesSinceAnyRep + 1) : 0;
        frameTelemetry.add({
          't': tSec,
          'reps': repCount,
          'depth': 0.0,
          'metric_label': 'DEPTH',
          'metric_value': 0.0,
          'feedback': (rtFbHold > 0 && rtFbMsg != null) ? rtFbMsg : null,
          'rep_just_finished': repJustFinished,
          'landmarks': lastValidLandmarks ?? <List<double>>[],
        });
        repJustFinished = null;
        if (rtFbHold > 0) rtFbHold -= 1;
        // [v17] Keep all per-frame arrays the same length as
        // frameTelemetry so post-process indexing is correct even
        // when some frames lacked pose detection.
        rawElbowMaxByFrame.add(0.0);
        rawElbowMinByFrame.add(0.0);
        shoulderYByFrame.add(null);
        elbowYByFrame.add(null);
        elbowAngleEmaByFrame.add(null);
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
      lastValidLandmarks = normLandmarks;

      final PoseLandmark? lsh = lm[PoseLandmarkType.leftShoulder];
      final PoseLandmark? rsh = lm[PoseLandmarkType.rightShoulder];
      final PoseLandmark? le = lm[PoseLandmarkType.leftElbow];
      final PoseLandmark? re = lm[PoseLandmarkType.rightElbow];
      final PoseLandmark? lw = lm[PoseLandmarkType.leftWrist];
      final PoseLandmark? rw = lm[PoseLandmarkType.rightWrist];
      final PoseLandmark? lh = lm[PoseLandmarkType.leftHip];
      final PoseLandmark? rh = lm[PoseLandmarkType.rightHip];
      final PoseLandmark? la = lm[PoseLandmarkType.leftAnkle];
      final PoseLandmark? ra = lm[PoseLandmarkType.rightAnkle];

      if (lsh == null ||
          rsh == null ||
          le == null ||
          re == null ||
          lw == null ||
          rw == null ||
          lh == null ||
          rh == null ||
          la == null ||
          ra == null) {
        frameTelemetry.add({
          't': tSec,
          'reps': repCount,
          'depth': 0.0,
          'metric_label': 'DEPTH',
          'metric_value': 0.0,
          'feedback': (rtFbHold > 0 && rtFbMsg != null) ? rtFbMsg : null,
          'rep_just_finished': repJustFinished,
          'landmarks': normLandmarks,
        });
        repJustFinished = null;
        if (rtFbHold > 0) rtFbHold -= 1;
        // [v19 ARRAY-SYNC] This early-continue path (pose found but a
        // required landmark missing) previously did NOT append to the
        // per-frame arrays, silently desyncing them from frameTelemetry
        // and shifting every post-process index after such a frame.
        // Append no-pose placeholders here too, exactly like the
        // poses.isEmpty path above.
        rawElbowMaxByFrame.add(0.0);
        rawElbowMinByFrame.add(0.0);
        shoulderYByFrame.add(null);
        elbowYByFrame.add(null);
        elbowAngleEmaByFrame.add(null);
        continue;
      }

      List<double> nLsh = [lsh.x / fw, lsh.y / fh];
      List<double> nRsh = [rsh.x / fw, rsh.y / fh];
      List<double> nLe = [le.x / fw, le.y / fh];
      List<double> nRe = [re.x / fw, re.y / fh];
      List<double> nLw = [lw.x / fw, lw.y / fh];
      List<double> nRw = [rw.x / fw, rw.y / fh];
      List<double> nLh = [lh.x / fw, lh.y / fh];
      List<double> nRh = [rh.x / fw, rh.y / fh];
      List<double> nLa = [la.x / fw, la.y / fh];
      List<double> nRa = [ra.x / fw, ra.y / fh];

      final double vL = (lsh.likelihood) + (le.likelihood) + (lw.likelihood);
      final double vR = (rsh.likelihood) + (re.likelihood) + (rw.likelihood);
      final bool useLeft = vL >= vR;

      final double minVis = [
        useLeft ? lsh.likelihood : rsh.likelihood,
        useLeft ? le.likelihood : re.likelihood,
        useLeft ? lw.likelihood : rw.likelihood,
        lh.likelihood,
        rh.likelihood,
      ].reduce(math.min);
      final bool visStrictOk = minVis >= VIS_THR_STRICT;

      final double shoulderRaw = useLeft ? nLsh[1] : nRsh[1];
      final double rawElbowL = ang(nLsh, nLe, nLw);
      final double rawElbowR = ang(nRsh, nRe, nRw);
      final double rawElbow = useLeft ? rawElbowL : rawElbowR;
      final double rawElbowMin = math.min(rawElbowL, rawElbowR);
      final double rawElbowMax = math.max(rawElbowL, rawElbowR);

      elbowEma = ema(elbowEma, rawElbow, ELBOW_EMA_ALPHA);
      shoulderEma = ema(shoulderEma, shoulderRaw, SHOULDER_EMA_ALPHA);
      final double shoulderY = shoulderEma!;
      final double elbowAngle = elbowEma!;

      baselineShoulderY ??= shoulderY;
      final double depthLive = ((shoulderY - baselineShoulderY!) /
              math.max(0.10, SHOULDER_MIN_DESCENT * 1.2))
          .clamp(0.0, 1.0)
          .toDouble();

      final double bodyAngleDeg = calculateBodyAngle(nLsh, nRsh, nLa, nRa);
      final bool handsPosition = (nLw[1] > nLsh[1] - HANDS_BELOW_SHOULDERS) &&
          (nRw[1] > nRsh[1] - HANDS_BELOW_SHOULDERS);
      final bool inPlank =
          (bodyAngleDeg <= PLANK_BODY_ANGLE_MAX) && handsPosition;

      if (visStrictOk && inPlank) {
        onpushupStreak += 1;
        offpushupStreak = 0;
      } else {
        offpushupStreak += 1;
        onpushupStreak = 0;
      }

      if (!onpushup && onpushupStreak >= ONPUSHUP_MIN_FRAMES) {
        onpushup = true;
        descBaseShoulder = null;
        descentStartFrame = null;
        allowNewBottom = true;
        cycleMaxDescent = 0.0;
        cycleMinElbow = 999.0;
        countedThisCycle = false;
        cycleBottomSamples = [];
        cycleTopSamples = [];
        confirmedBottomSamples = [];
        bottomPhaseMinElbow = null;
        topPhaseMaxElbow = null;
        cycleMaxHipMisalign = null;
        cycleMaxFlare = null;
        cycleMaxDescentVel = 0.0;
        inDescentPhase = false;
      }

      // Pushup EXIT.
      if (onpushup && offpushupStreak >= OFFPUSHUP_MIN_FRAMES) {
        final rb = robustCycleElbows(
          cycleBottomSamples,
          cycleTopSamples,
          bottomPhaseMinElbow,
          topPhaseMaxElbow,
          confirmedBottomSamples,
        );
        final cycleRtMsg = evaluateCycleForm(
          bottomPhaseMinElbowArg: rb[0],
          topPhaseMaxElbowArg: rb[1],
          cycleMaxHipMisalignArg: cycleMaxHipMisalign,
          cycleMaxDescentVelArg: cycleMaxDescentVel,
          // [v8] At exit we don't have a clean descent duration —
          // the user already exited plank. Pass null to skip the
          // tempo check at exit.
          descentDurationSecArg: null,
          nBottom: cycleBottomSamples.length,
          nTop: cycleTopSamples.length,
        );
        if (cycleRtMsg != null && curRt == null) curRt = cycleRtMsg;

        // [v6] Removed commitPendingRep — counting is immediate now.

        onpushup = false;
        offpushupFramesSinceAnyRep = 0;
        descBaseShoulder = null;
        descentStartFrame = null;
        cycleMaxDescent = 0.0;
        cycleMinElbow = 999.0;
        countedThisCycle = false;
        cycleBottomSamples = [];
        cycleTopSamples = [];
        confirmedBottomSamples = [];
        bottomPhaseMinElbow = null;
        topPhaseMaxElbow = null;
        cycleMaxHipMisalign = null;
        cycleMaxFlare = null;
        cycleMaxDescentVel = 0.0;
      }

      if (!onpushup && repCount > 0) {
        offpushupFramesSinceAnyRep += 1;
        // [v15 NO-EARLY-BREAK] No early termination — same reasoning
        // as the no-pose case above. We let the frame loop run to the
        // end of the video so frameTelemetry covers every frame and
        // the widget never has to extrapolate past the last entry.
        // The counter (repCount) and landmarks just stay current.
      }

      final double shoulderVel =
          shoulderPrev == null ? 0.0 : (shoulderY - shoulderPrev!);
      shoulderVelPrev = shoulderVel;

      if (onpushup && visStrictOk) {
        if (descBaseShoulder == null) {
          if (shoulderVel > INFLECT_VEL_THR.abs()) {
            descBaseShoulder = shoulderY;
            descentStartFrame = frameIdx; // [v8 TEMPO-DURATION]
            cycleMaxDescent = 0.0;
            cycleMinElbow = elbowAngle;
            countedThisCycle = false;
            cycleBottomSamples = [];
            cycleTopSamples = [];
            confirmedBottomSamples = [];
            bottomPhaseMinElbow = null;
            cycleMaxHipMisalign = null;
            cycleMaxFlare = null;
            cycleMaxDescentVel = 0.0;
            inDescentPhase = true;
          }
        } else {
          cycleMaxDescent =
              math.max(cycleMaxDescent, (shoulderY - descBaseShoulder!));
          cycleMinElbow = math.min(cycleMinElbow, elbowAngle);

          final double velAbs = shoulderVel.abs();
          // [v7 TEMPO-FIX] Only measure descent velocity during actual
          // descent (shoulderVel > 0, since image y grows downward). The
          // old logic also tracked ascent velocity via the velAbs > 0.0005
          // catchall, which made fast-but-controlled pushups register as
          // "fast descent" and triggered false-positive tempo feedback.
          if (shoulderVel > 0 && inDescentPhase) {
            cycleMaxDescentVel = math.max(cycleMaxDescentVel, velAbs);
          }
          // (Removed the catchall: `if (velAbs > 0.0005) cycleMaxDescentVel = max(...)`.
          // It was conflating descent and ascent velocities.)

          final double minElbNow = math.min(rawElbowL, rawElbowR);
          cycleBottomSamples.add(minElbNow);
          if (cycleBottomSamples.length > 40) {
            cycleBottomSamples.removeAt(0);
          }
          bottomPhaseMinElbow = bottomPhaseMinElbow == null
              ? minElbNow
              : math.min(bottomPhaseMinElbow!, minElbNow);

          final double maxElbNow = rawElbowMax;
          cycleTopSamples.add(maxElbNow);
          if (cycleTopSamples.length > 40) {
            cycleTopSamples.removeAt(0);
          }
          topPhaseMaxElbow = topPhaseMaxElbow == null
              ? maxElbNow
              : math.max(topPhaseMaxElbow!, maxElbNow);

          final double hipMisalign =
              calculateHipMisalignment(nLsh, nRsh, nLh, nRh, nLa, nRa);
          cycleMaxHipMisalign = cycleMaxHipMisalign == null
              ? hipMisalign
              : math.max(cycleMaxHipMisalign!, hipMisalign);

          final double elbowFlare = calculateElbowFlare(nLsh, nRsh, nLe, nRe);
          cycleMaxFlare = cycleMaxFlare == null
              ? elbowFlare
              : math.max(cycleMaxFlare!, elbowFlare);

          final bool resetByAsc = descBaseShoulder != null &&
              (descBaseShoulder! - shoulderY) >= RESET_ASCENT;
          final bool resetByElb = elbowAngle >= RESET_ELBOW;
          bool resetByRawElb = false;
          if (countedThisCycle && bottomPhaseMinElbow != null) {
            final double rawRise = rawElbowMin - bottomPhaseMinElbow!;
            if (rawRise >= 35.0) resetByRawElb = true;
          }

          if (shoulderVel < 0 && inDescentPhase) inDescentPhase = false;

          // ---- Cycle reset between reps ----
          // [v4] If a pending rep is still here at cycle reset, the peak
          // tracker never declared a peak (probably the user immediately
          // started the next descent without a clean lockout). We commit
          // it here using whatever top we observed, so the visible event
          // doesn't get lost. Only one rep can be pending at a time, so
          // this is bounded.
          if (resetByAsc || resetByElb || resetByRawElb) {
            final rb = robustCycleElbows(
              cycleBottomSamples,
              cycleTopSamples,
              bottomPhaseMinElbow,
              topPhaseMaxElbow,
              confirmedBottomSamples,
            );
            final cycleRtMsg = evaluateCycleForm(
              bottomPhaseMinElbowArg: rb[0],
              topPhaseMaxElbowArg: rb[1],
              cycleMaxHipMisalignArg: cycleMaxHipMisalign,
              cycleMaxDescentVelArg: cycleMaxDescentVel,
              // [v8] cycle reset is triggered AFTER ascent has begun;
              // the descent duration was the time from descentStartFrame
              // to the bottom of THIS cycle, but we don't easily have
              // that recorded here. Pass null — tempo check happens at
              // bottom-detection (below) where we have the duration.
              descentDurationSecArg: null,
              nBottom: cycleBottomSamples.length,
              nTop: cycleTopSamples.length,
            );
            if (cycleRtMsg != null && curRt == null) curRt = cycleRtMsg;

            // [v6] Counting is immediate now, no pending state to update.
            // Just continue with the cycle reset.

            descBaseShoulder = shoulderY;
            descentStartFrame = frameIdx; // [v8 TEMPO-DURATION] new descent
            cycleMaxDescent = 0.0;
            cycleMinElbow = elbowAngle;
            countedThisCycle = false;
            allowNewBottom = true;
            cycleBottomSamples = [];
            cycleTopSamples = [];
            confirmedBottomSamples = [];
            bottomPhaseMinElbow = null;
            cycleMaxHipMisalign = null;
            cycleMaxFlare = null;
            cycleMaxDescentVel = 0.0;
            inDescentPhase = true;
          }

          final double descentAmt =
              descBaseShoulder == null ? 0.0 : (shoulderY - descBaseShoulder!);
          bool atBottom = (elbowAngle <= ELBOW_BENT_ANGLE) &&
              (descentAmt >= SHOULDER_MIN_DESCENT);
          final bool rawBottom = (rawElbowMin <= (ELBOW_BENT_ANGLE + 7.0)) &&
              (descentAmt >= SHOULDER_MIN_DESCENT * 0.9);
          atBottom = atBottom || rawBottom;
          final bool canCnt = (frameIdx - lastBottomFrame) >= REFRACTORY_FRAMES;

          if (atBottom) {
            confirmedBottomSamples.add(rawElbowMin);
            if (confirmedBottomSamples.length > 15) {
              confirmedBottomSamples.removeAt(0);
            }
          }

          // ---- Queue rep at bottom — commit fires later at peak ----
          if (atBottom && allowNewBottom && canCnt && !countedThisCycle) {
            bool repHasIssues = false;
            // [v7 MULTI-FB] Collect ALL active form errors for this rep
            // into a list, joined with newlines for display. v6 only
            // showed the first one detected (`curRt == null` gates).
            final List<String> repFbs = [];
            final rb = robustCycleElbows(
              cycleBottomSamples,
              cycleTopSamples,
              bottomPhaseMinElbow,
              topPhaseMaxElbow,
              confirmedBottomSamples,
            );

            // [v8 TEMPO-DURATION] EXTREME tempo check at bottom detection,
            // measured by descent DURATION rather than max velocity. We
            // know `descentStartFrame` (where descent began) and `frameIdx`
            // (current = bottom), so duration is straightforward.
            //
            // Threshold: descent < EXTREME_DESCENT_DURATION_SEC (0.4s) is
            // a "drop", not a controlled lower. Beginner pushups take
            // 1.5–2.5s; even fast-controlled reps run 0.5–0.8s.
            double? descentDurationSec;
            if (descentStartFrame != null) {
              descentDurationSec = (frameIdx - descentStartFrame!) / fps;
            }
            if (descentDurationSec != null &&
                descentDurationSec < EXTREME_DESCENT_DURATION_SEC) {
              repHasIssues = true;
              extremeTempoFailCount += 1;
              if (extremeTempoFailCount >= EXTREME_TEMPO_MIN_REPS &&
                  !extremeTempoAlreadyReported) {
                sessionFormErrors.add(FB_ERROR_TEMPO_FAST);
                extremeTempoAlreadyReported = true;
              }
              if (sessionFormErrors.contains(FB_ERROR_TEMPO_FAST)) {
                repFbs.add(FB_ERROR_TEMPO_FAST);
              }
            }

            if (rb[0] != null && rb[0]! > DEPTH_ERROR_ANGLE) {
              repHasIssues = true;
              depthFailCount += 1;
              if (depthFailCount >= DEPTH_FAIL_MIN_REPS &&
                  !depthAlreadyReported) {
                sessionFormErrors.add(FB_ERROR_DEPTH);
                depthAlreadyReported = true;
              }
              if (sessionFormErrors.contains(FB_ERROR_DEPTH)) {
                repFbs.add(FB_ERROR_DEPTH);
              }
            }
            if (rb[1] != null && rb[1]! < LOCKOUT_ERROR_ANGLE) {
              repHasIssues = true;
              lockoutFailCount += 1;
              if (lockoutFailCount >= LOCKOUT_FAIL_MIN_REPS &&
                  !lockoutAlreadyReported) {
                sessionFormErrors.add(FB_ERROR_LOCKOUT);
                lockoutAlreadyReported = true;
              }
              if (sessionFormErrors.contains(FB_ERROR_LOCKOUT)) {
                repFbs.add(FB_ERROR_LOCKOUT);
              }
            }
            if (cycleMaxHipMisalign != null &&
                cycleMaxHipMisalign! > HIP_FAIR) {
              repHasIssues = true;
              hipsFailCount += 1;
              if (hipsFailCount >= HIPS_FAIL_MIN_REPS && !hipsAlreadyReported) {
                sessionFormErrors.add(FB_ERROR_HIPS);
                hipsAlreadyReported = true;
              }
              if (sessionFormErrors.contains(FB_ERROR_HIPS)) {
                repFbs.add(FB_ERROR_HIPS);
              }
            }

            // [v7 MULTI-FB] Build the multi-line string here. We use \n
            // as a separator; the widget splits on \n and renders each
            // line on its own row.
            if (repFbs.isNotEmpty && curRt == null) {
              curRt = repFbs.join('\n');
            }

            // [v6] Commit the rep IMMEDIATELY — counter goes up here.
            // The visible flash is deferred to the peak via post-process.
            final Map<String, dynamic> repData = buildRepReport(
              bottomPhaseMinElbowArg: rb[0] ?? rawElbowMin,
              topPhaseMaxElbowArg: rb[1] ?? rawElbowMax,
              cycleMaxHipMisalignArg: cycleMaxHipMisalign ?? 0.0,
              cycleMaxFlareArg: cycleMaxFlare ?? 0.0,
            );
            final bool repIsBad = repHasIssues || currentCycleHasIssue;
            // Use the best top-elbow we have right now; the post-process
            // pass will refine sessionTopMedians from rawElbowMaxByFrame
            // if needed. This value mostly affects the rep's stored
            // measurements.
            final double topElbow = rb[1] ?? rawElbowMax;
            final String verdict = commitRep(
              repData: repData,
              repIsBad: repIsBad,
              topElbowAngle: topElbow,
            );

            // bottomFrameIdx is 1-based to match frameIdx.
            // [v7] We also record `prevRepCount` — the count BEFORE this
            // rep was committed. The post-process pass uses it to
            // rewrite `reps` for every frame between the bottom (where
            // commitRep already incremented it) and the peak (where the
            // visible event should fire). Net effect: counter visually
            // ticks up at the peak, in sync with the flash/sound/haptic.
            pulseEvents.add({
              'bottomFrameIdx': frameIdx,
              // [v10 VERDICT-IN-POST] verdict is provisional here. We'll
              // recompute it in the post-process pass once we know all
              // session-level form errors that fired across the whole
              // video — including ones that need multiple reps to
              // accumulate before the warning surfaces.
              'verdict': verdict,
              'fb': repIsBad ? curRt : null,
              'prevRepCount': repCount - 1,
              'newRepCount': repCount,
              // [v10] Per-rep reasons collected at bottom-detection.
              // Used by the post-process pass to recompute verdict
              // against the final sessionFormErrors set.
              'reasons': List<String>.from(repFbs),
              'wasExtremeTempo': descentDurationSec != null &&
                  descentDurationSec < EXTREME_DESCENT_DURATION_SEC,
            });

            lastBottomFrame = frameIdx;
            allowNewBottom = false;
            countedThisCycle = true;
            topPhaseMaxElbow = null;
            inDescentPhase = false;
          }

          // Rearm without committing.
          if (!allowNewBottom && lastBottomFrame > 0) {
            bool rearmed = false;
            if (shoulderPrev != null &&
                (shoulderPrev! - shoulderY) > 0 &&
                descBaseShoulder != null) {
              final double ascentFromBottom =
                  (descBaseShoulder! + cycleMaxDescent) - shoulderY;
              final double REARM_ASCENT_EFF =
                  math.max(RESET_ASCENT * 0.50, 0.009);
              if (ascentFromBottom >= REARM_ASCENT_EFF) rearmed = true;
            }
            if (!rearmed && bottomPhaseMinElbow != null) {
              final double elbowRise = rawElbowMin - bottomPhaseMinElbow!;
              if (elbowRise >= RAW_ELBOW_REARM_RISE) rearmed = true;
            }
            if (rearmed) {
              allowNewBottom = true;
            }
          }
        }
      } else {
        descBaseShoulder = null;
        descentStartFrame = null;
        allowNewBottom = true;
      }

      // [v6] We no longer detect the peak in real time. Instead we just
      // record rawElbowMax for each frame so the post-process pass at
      // end-of-loop can find the actual visual peak per rep and place
      // the rep_just_finished pulse there. Counting itself happens
      // immediately at bottom (further up).
      rawElbowMaxByFrame.add(rawElbowMax);
      // [v11 SHOULDER-Y-FOR-PEAK] Also store shoulderY per frame —
      // we'll use it to find the visual peak (head highest = shoulderY
      // lowest in image coordinates) instead of the elbow-angle peak,
      // which is unreliable due to ML Kit detection spikes between reps.
      shoulderYByFrame.add(shoulderY);
      // [v11 RAW-ELBOW-MIN-FOR-CONFIDENCE] Also store rawElbowMin to
      // detect detection-noise frames (where left/right elbow disagree
      // wildly). Such frames have a high max-min gap and shouldn't be
      // trusted for the peak measurement.
      rawElbowMinByFrame.add(rawElbowMin);
      // [v17 DEPTH-VIA-SHOULDER-VS-ELBOW] Record elbow Y position (the
      // average of left+right when both visible, else the more visible
      // side) and the smoothed elbow angle, for the post-process
      // depth check.
      final double elbowYRaw = useLeft ? nLe[1] : nRe[1];
      elbowYByFrame.add(elbowYRaw);
      elbowAngleEmaByFrame.add(elbowAngle);

      if (curRt != null) {
        if (curRt != rtFbMsg) {
          rtFbMsg = curRt;
          rtFbHold = RT_FB_HOLD_FRAMES;
        } else {
          rtFbHold = math.max(rtFbHold, RT_FB_HOLD_FRAMES);
        }
      } else {
        if (rtFbHold > 0) rtFbHold -= 1;
      }

      final String? fbVal = (rtFbHold > 0 && rtFbMsg != null) ? rtFbMsg : null;

      frameTelemetry.add({
        't': tSec,
        'reps': repCount,
        'depth': depthLive,
        'metric_label': 'DEPTH',
        'metric_value': depthLive,
        'feedback': fbVal,
        'rep_just_finished': repJustFinished,
        'landmarks': normLandmarks,
      });
      repJustFinished = null;

      shoulderPrev = shoulderY;
    }

    // [v6] No pending rep to flush — counting was immediate. The visible
    // pulse placement happens in the post-process pass below.
  } finally {
    await poseDetector.close();
    try {
      framesDir.deleteSync(recursive: true);
    } catch (_) {}
  }

  // ============================================================
  // [v6 POST-PROCESS] Place rep_just_finished pulses at visual peaks.
  //
  // For each pulse event recorded during the loop, we find the actual
  // visual peak frame: the frame within an ascent window after the
  // bottom that has the highest raw elbow angle. We then move the
  // verdict + (if bad) feedback to that frame in the telemetry.
  //
  // Why post-process instead of inline:
  //   - Counting stays simple and matches the v3 logic the user trusts.
  //   - We can look ahead in time, which is the natural way to find a
  //     peak. Inline state machines couldn't, so they had heuristics
  //     that sometimes mis-fired.
  //
  // Window per rep: from bottomFrameIdx forward, up to either
  //   (a) the next pulse event's bottomFrameIdx (so we don't claim the
  //       next rep's peak as our own), OR
  //   (b) MAX_PEAK_LOOKAHEAD frames (safety bound).
  //
  // The pulse is placed at the frame with max rawElbowMaxByFrame in
  // that window. If multiple frames tie, we pick the LAST one — that's
  // visually closer to "user has held the top" which feels right.
  // ============================================================
  const int MAX_PEAK_LOOKAHEAD = 25; // [v11] Was 40 — too long; reps are
  // typically 0.5–1.5 sec long, so 25 frames @ 20fps = 1.25s is plenty.
  // 40 frames overlapped into the next rep, picking up noise spikes.

  // [v11] Counter for reps that missed lockout per the post-process
  // re-check.
  int _postLockoutMissCount = 0;
  // [v11] Frame indices of the peaks of reps that missed lockout. Used
  // in a second pass to write per-rep feedback once we know whether the
  // session-level error fires.
  final List<int> _lockoutMissPeakIdx = [];
  // [v17] Same idea for depth — count reps that came up shallow and
  // remember their bottom frame index for the per-rep feedback writes
  // in phase 2.
  int _postDepthMissCount = 0;
  final List<int> _depthMissBottomIdx = [];

  // First, clear any rep_just_finished that the loop accidentally set.
  for (final f in frameTelemetry) {
    f['rep_just_finished'] = null;
  }

  // [v11 TWO-PHASE-POST-PROCESS — VISUAL PEAK]
  //
  // PHASE 1 — Per-rep gather:
  //   For each rep, find the VISUAL peak frame (where the body is
  //   highest = shoulderY lowest in image coords). This is the moment
  //   the eye registers as "top of pushup". Then read the elbow angle
  //   AT that frame for the lockout decision.
  //
  //   Why not "max elbow angle in window"? Because ML Kit produces
  //   noise spikes — frames where the elbow reads 175°+ even when the
  //   user is mid-descent, mid-ascent, or just between reps. Visual
  //   peak (shoulder highest) is much more stable: the body actually
  //   has to be physically up there.
  //
  //   We also gate the elbow reading by detection confidence: if the
  //   left/right elbow angles disagree by > 50° in the same frame,
  //   that frame is unreliable and we skip it.
  //
  // PHASE 2 — Session-aware commit:
  //   As before — recompute verdict against final sessionFormErrors.

  // ---- PHASE 1 ----
  // For each rep, compute these reliable values from the recorded
  // per-frame data:
  //   - peakIdx: visual peak (lowest shoulderY in window)
  //   - peakElbow: actual elbow angle near visual peak
  //   - prevPeakIdx: visual peak of the PREVIOUS rep (or start of clip
  //     if this is the first rep). The descent for this rep started
  //     somewhere between prevPeakIdx and bottomIdx.
  //   - descentStart: frame where shoulderY first started increasing
  //     monotonically toward the bottom. Computed by walking from
  //     bottomIdx backwards to prevPeakIdx, looking for the first
  //     frame where shoulder velocity flipped from upward to downward.
  //   - descentDurationSec: (bottomIdx - descentStart) / fps
  for (int e = 0; e < pulseEvents.length; e++) {
    final ev = pulseEvents[e];
    final int bottomIdx = (ev['bottomFrameIdx'] as int) - 1; // 0-based
    if (bottomIdx < 0 || bottomIdx >= frameTelemetry.length) continue;

    final int nextBottomIdx = e + 1 < pulseEvents.length
        ? (pulseEvents[e + 1]['bottomFrameIdx'] as int) - 1
        : frameTelemetry.length;
    final int windowEnd = math.min(
      frameTelemetry.length,
      math.min(nextBottomIdx, bottomIdx + MAX_PEAK_LOOKAHEAD),
    );

    // [v11] Find VISUAL peak: minimum shoulderY in [bottom, windowEnd).
    int peakIdx = bottomIdx;
    double? minShoulderY;
    for (int i = bottomIdx; i < windowEnd; i++) {
      if (i >= shoulderYByFrame.length) break;
      final shY = shoulderYByFrame[i];
      if (shY == null) continue;
      if (minShoulderY == null || shY < minShoulderY) {
        minShoulderY = shY;
        peakIdx = i;
      }
    }

    // [v13] Read peakElbow from frames TIGHTLY around the visual peak.
    // Look ±2 frames around peakIdx and pick the LARGEST emax — but
    // only from frames where left/right elbow agree (gap < 30°). This
    // catches reps where the user briefly hits a clean lockout that
    // ML Kit registers confidently, without picking up noise spikes
    // from frames far from the peak (which may belong to neighboring
    // reps).
    //
    // We previously used ±5 here, but that allowed spikes from the
    // descent of the NEXT rep to be picked up — false-good readings.
    // ±2 is enough to find a confident frame near the peak without
    // drifting into the next rep.
    //
    // If no frame in the window has an agreed-on reading, we fall
    // back to the median of all rawElbowMax values in the same window.
    double peakElbow = 0.0;
    if (peakIdx < rawElbowMaxByFrame.length) {
      const double GAP_TIGHT = 30.0;
      double bestEmax = 0.0;
      bool anyAgreed = false;
      final int lo = math.max(bottomIdx, peakIdx - 2);
      final int hi = math.min(windowEnd - 1, peakIdx + 2);
      for (int i = lo; i <= hi; i++) {
        if (i >= rawElbowMaxByFrame.length) break;
        final emax = rawElbowMaxByFrame[i];
        final emin = rawElbowMinByFrame[i];
        final gap = (emax - emin).abs();
        if (gap < GAP_TIGHT && emax > bestEmax) {
          bestEmax = emax;
          anyAgreed = true;
        }
      }
      if (anyAgreed) {
        peakElbow = bestEmax;
      } else {
        // Fallback: median of emax values in the same narrow window.
        final List<double> vals = [];
        for (int i = lo; i <= hi; i++) {
          if (i < rawElbowMaxByFrame.length) {
            vals.add(rawElbowMaxByFrame[i]);
          }
        }
        if (vals.isNotEmpty) {
          vals.sort();
          peakElbow = vals[vals.length ~/ 2];
        }
      }
    }

    // [v13] Determine prevPeakIdx for descent-duration computation.
    // For the first rep, prevPeakIdx = 0 (start of clip).
    // For subsequent reps, it's the peak of the previous pulseEvent.
    int prevPeakIdx;
    if (e == 0) {
      prevPeakIdx = 0;
    } else {
      prevPeakIdx = (pulseEvents[e - 1]['peakIdx'] as int?) ?? 0;
    }

    // [v13] Find descent start: walking from bottomIdx backwards toward
    // prevPeakIdx, find the LAST frame where shoulderY is at a local
    // maximum that happens BEFORE the bottom. We look for the smallest
    // shoulderY (highest body position) in [prevPeakIdx, bottomIdx]
    // that's clearly above (i.e. lower in image coords than) the
    // bottom. That frame is where descent began.
    int descentStartIdx = prevPeakIdx;
    if (bottomIdx > prevPeakIdx && bottomIdx < shoulderYByFrame.length) {
      double? minShBeforeBottom;
      int candIdx = prevPeakIdx;
      // Look from prevPeakIdx + 1 to bottomIdx - 1, find frame with min shY.
      for (int i = math.max(0, prevPeakIdx); i < bottomIdx; i++) {
        if (i >= shoulderYByFrame.length) break;
        final shY = shoulderYByFrame[i];
        if (shY == null) continue;
        if (minShBeforeBottom == null || shY < minShBeforeBottom) {
          minShBeforeBottom = shY;
          candIdx = i;
        }
      }
      descentStartIdx = candIdx;
    }
    final double descentDurationSec =
        ((bottomIdx - descentStartIdx) / fps).abs();

    // Stash for phase 2.
    ev['peakIdx'] = peakIdx;
    ev['peakElbow'] = peakElbow;
    ev['descentStartIdx'] = descentStartIdx;
    ev['descentDurationSec'] = descentDurationSec;

    // Rewrite displayed reps count: bottom-to-peak shows the OLD count.
    final int prevRC = (ev['prevRepCount'] as int?) ?? 0;
    for (int i = bottomIdx; i < peakIdx; i++) {
      frameTelemetry[i]['reps'] = prevRC;
    }

    // [v13] Lockout: post-process check uses peakElbow.
    // 155° threshold defines straight arms.
    // [v15 STRICTER] Was 160° in v14, but the user reports it's still
    // "a bit too forgiving". Raised to 165°. Calibrated against the
    // user's videos: clear lockouts read 170-180°, the borderline
    // "almost-but-not-quite" reps read 155-165° — those should now
    // be flagged. True misses where the elbow is visibly bent read
    // below 150°.
    const double LOCKOUT_POST_THRESHOLD = 165.0;
    if (peakElbow > 0.0 && peakElbow < LOCKOUT_POST_THRESHOLD) {
      _postLockoutMissCount++;
      _lockoutMissPeakIdx.add(peakIdx);
      ev['missedLockout'] = true;
    } else {
      ev['missedLockout'] = false;
    }

    // [v13] Tempo: post-process check using REAL descent duration.
    // We override whatever the in-loop check thought because the
    // in-loop value of descentStartFrame is fragile (it's only set
    // when a "fresh" downward velocity is detected, but during a
    // continuous up-pause-down rep cycle that initial detection is
    // sometimes one frame later or earlier than the actual peak).
    // Now we compute it from the full trajectory we've recorded.
    //
    // Threshold: 0.18s. From the user's videos:
    //   "fast but ok" pushups: 0.20-0.35s
    //   "controlled" pushups: 0.30-0.50s
    //   "drop": < 0.15s
    // 0.18 catches genuine drops without flagging fast-controlled reps.
    const double EXTREME_TEMPO_POST_THRESHOLD = 0.18;
    if (descentDurationSec > 0 &&
        descentDurationSec < EXTREME_TEMPO_POST_THRESHOLD) {
      ev['extremeTempoPost'] = true;
    } else {
      ev['extremeTempoPost'] = false;
    }

    // [v18 DEPTH-AT-BOTTOM] Combined criterion using shoulder vs elbow
    // Y position AND elbow angle, both measured at the deepest frame
    // of the rep — not strictly bottomIdx, which is just the frame
    // where the rep was detected (could be a frame or two BEFORE the
    // user actually reaches their lowest point).
    //
    // To find the deepest frame, we scan from bottomIdx backward and
    // forward by ±5 frames and pick the frame with the SMALLEST raw
    // elbow angle (= most bent = deepest rep position). This catches
    // the "real" bottom and avoids reading EMA values that still
    // reflect higher angles from earlier in the descent.
    //
    // Combined logic: a rep is shallow ONLY IF both:
    //   (a) elbow angle at deepest frame > 110°  (arm not really bent)
    //   AND
    //   (b) shoulder Y above elbow Y by ≥ 0.025  (shoulder clearly above
    //       elbow, not merely a noise-level difference)
    //
    // Threshold tuning from user feedback:
    //   v17 had 100° / 0.01 tolerance, which was too aggressive — flagged
    //   visually-deep reps as shallow. Raised to 110° / 0.025 here.
    //   From measured user videos, deep pushups bottom out around
    //   60-80° elbow angle, so 110° still leaves plenty of room for
    //   a clearly-shallow rep to be flagged.
    const double DEPTH_SHALLOW_ELBOW_DEG = 110.0;
    const double DEPTH_SHY_VS_ELY_TOL = 0.025;
    const int DEPTH_BOTTOM_SEARCH_WINDOW = 5;

    // Find the deepest frame by scanning ±DEPTH_BOTTOM_SEARCH_WINDOW
    // around bottomIdx, picking the one with smallest rawElbowMin
    // (which is the most reliable "we're definitely bent" signal —
    // smaller is more bent).
    int deepestIdx = bottomIdx;
    double? minElbowAtBottom;
    final int dLo = math.max(0, bottomIdx - DEPTH_BOTTOM_SEARCH_WINDOW);
    final int dHi = math.min(
        rawElbowMinByFrame.length - 1, bottomIdx + DEPTH_BOTTOM_SEARCH_WINDOW);
    for (int i = dLo; i <= dHi; i++) {
      final double v = rawElbowMinByFrame[i];
      if (v <= 0.0) continue; // 0 = no-pose placeholder, skip
      if (minElbowAtBottom == null || v < minElbowAtBottom) {
        minElbowAtBottom = v;
        deepestIdx = i;
      }
    }

    bool wasShallowDepth = false;
    if (minElbowAtBottom != null &&
        deepestIdx < shoulderYByFrame.length &&
        deepestIdx < elbowYByFrame.length) {
      final double? shYAtDeepest = shoulderYByFrame[deepestIdx];
      final double? elYAtDeepest = elbowYByFrame[deepestIdx];
      if (shYAtDeepest != null && elYAtDeepest != null) {
        final bool elbowTooOpen = minElbowAtBottom > DEPTH_SHALLOW_ELBOW_DEG;
        final bool shoulderAboveElbow =
            shYAtDeepest < (elYAtDeepest - DEPTH_SHY_VS_ELY_TOL);
        if (elbowTooOpen && shoulderAboveElbow) {
          wasShallowDepth = true;
          _postDepthMissCount++;
          _depthMissBottomIdx.add(bottomIdx);
        }
      }
    }
    ev['shallowDepth'] = wasShallowDepth;
  }

  // Now — having seen all reps — decide if session-level lockout fires.
  if (_postLockoutMissCount >= LOCKOUT_FAIL_MIN_REPS &&
      !sessionFormErrors.contains(FB_ERROR_LOCKOUT)) {
    sessionFormErrors.add(FB_ERROR_LOCKOUT);
  }

  // [v13] Re-evaluate session-level TEMPO error from the post-process
  // descent durations, overriding the in-loop accumulator. Same
  // EXTREME_TEMPO_MIN_REPS threshold.
  int postExtremeTempoCount = 0;
  for (final ev in pulseEvents) {
    if ((ev['extremeTempoPost'] as bool?) == true) {
      postExtremeTempoCount++;
    }
  }
  if (postExtremeTempoCount >= EXTREME_TEMPO_MIN_REPS) {
    if (!sessionFormErrors.contains(FB_ERROR_TEMPO_FAST)) {
      sessionFormErrors.add(FB_ERROR_TEMPO_FAST);
    }
  } else {
    // The in-loop check might have erroneously fired tempo. Remove it.
    sessionFormErrors.remove(FB_ERROR_TEMPO_FAST);
  }

  // [v17] DEPTH session-level error: fires if the post-process detected
  // shallow reps in at least DEPTH_FAIL_MIN_REPS reps. Same min-reps
  // policy as lockout — at least 3 misses before surfacing the warning,
  // so a one-off measurement glitch doesn't trip it.
  if (_postDepthMissCount >= DEPTH_FAIL_MIN_REPS &&
      !sessionFormErrors.contains(FB_ERROR_DEPTH)) {
    sessionFormErrors.add(FB_ERROR_DEPTH);
  } else if (_postDepthMissCount < DEPTH_FAIL_MIN_REPS) {
    // The legacy in-loop / aggregation check might have fired DEPTH
    // earlier (the score-percentile code path). Override based on the
    // new visual check, which is what the user actually wants.
    sessionFormErrors.remove(FB_ERROR_DEPTH);
  }

  // ---- PHASE 2 ----
  // Now place pulses + feedback with knowledge of the final session
  // errors. A rep is 'bad' iff it has at least one reason that's
  // contained in sessionFormErrors. Otherwise 'good'.
  //
  // ---- PHASE 2 ----
  // [v13 ERROR-SPECIFIC-TIMING] Each error type is shown at the moment
  // it occurred in the rep, not blanket across [bottom, peak]:
  //
  //   TEMPO_FAST: shown during the descent itself (descentStart →
  //               bottom + 0.5s for readability). The error happens
  //               during descent, so the user sees it then.
  //
  //   LOCKOUT: shown after the peak (peak → peak + 1.5s). The error
  //            is realized AT the peak (when arms should be straight
  //            but aren't), so the message appears then.
  //
  //   DEPTH:  shown around the bottom (bottom → bottom + 1.0s). The
  //           error is realized at the bottom (when chest should
  //           reach lower but didn't).
  //
  //   HIPS:   shown across the rep (descentStart → peak). The error
  //           is form-throughout, no single moment is "the" moment.
  //
  // We build a per-frame map of feedback strings to display. Multiple
  // errors that overlap in time get joined with newlines (the widget
  // already supports multi-line banners). All non-rep frames get
  // null (cleared).
  final int holdFramesMedium = math.max(1, (1.0 * fps).round());
  final int holdFramesLong = math.max(1, (1.5 * fps).round());
  final int holdFramesShort = math.max(1, (0.5 * fps).round());

  final List<List<String>> finalFbsByFrame =
      List<List<String>>.generate(frameTelemetry.length, (_) => <String>[]);

  // [v19 FEEDBACK-SYNC] Record every error string that is ACTUALLY
  // written into frame telemetry (i.e. shown as an in-video banner).
  // After phase 2 this set becomes the single source of truth for the
  // summary `feedback` list, guaranteeing summary == video.
  final Set<String> displayedFormErrors = {};

  // Place per-error feedback into its own time window.
  void addFb(int startIdx, int endIdx, String fb) {
    final int s = math.max(0, startIdx);
    final int e = math.min(frameTelemetry.length - 1, endIdx);
    for (int i = s; i <= e; i++) {
      if (!finalFbsByFrame[i].contains(fb)) {
        finalFbsByFrame[i].add(fb);
      }
    }
    // [v19] Any fb that reached at least one frame counts as displayed.
    if (s <= e) displayedFormErrors.add(fb);
  }

  // Track which reps are bad, for setting rep_just_finished.
  final Set<int> badRepIdxs = {};

  for (int e = 0; e < pulseEvents.length; e++) {
    final ev = pulseEvents[e];
    final int peakIdx = (ev['peakIdx'] as int?) ?? -1;
    final int bottomIdx = (ev['bottomFrameIdx'] as int) - 1;
    final int descentStartIdx = (ev['descentStartIdx'] as int?) ?? bottomIdx;
    if (peakIdx < 0 || peakIdx >= frameTelemetry.length) continue;

    final List<String> reasons =
        (ev['reasons'] as List?)?.cast<String>() ?? <String>[];
    final bool extremeTempoPost = (ev['extremeTempoPost'] as bool?) ?? false;
    final bool missedLockout = (ev['missedLockout'] as bool?) ?? false;
    final bool shallowDepth = (ev['shallowDepth'] as bool?) ?? false;

    bool isBad = false;

    // TEMPO: shown during descent + 0.5s after bottom for readability.
    if (extremeTempoPost && sessionFormErrors.contains(FB_ERROR_TEMPO_FAST)) {
      addFb(descentStartIdx, bottomIdx + holdFramesShort, FB_ERROR_TEMPO_FAST);
      isBad = true;
    }

    // LOCKOUT: shown from peak onward (1.5s).
    if (missedLockout && sessionFormErrors.contains(FB_ERROR_LOCKOUT)) {
      addFb(peakIdx, peakIdx + holdFramesLong, FB_ERROR_LOCKOUT);
      isBad = true;
    }

    // [v17] DEPTH: shown at bottom (when the user IS at the bottom of
    // the rep — that's the moment the error is visible). Holds for
    // 1.0s for readability, but won't extend past the rep's peak.
    if (shallowDepth && sessionFormErrors.contains(FB_ERROR_DEPTH)) {
      final int depthEnd = math.min(peakIdx, bottomIdx + holdFramesMedium);
      addFb(bottomIdx, depthEnd, FB_ERROR_DEPTH);
      isBad = true;
    }

    // Other reasons (HIPS, etc.) — display from bottom for 1s.
    for (final r in reasons) {
      if (r == FB_ERROR_TEMPO_FAST ||
          r == FB_ERROR_LOCKOUT ||
          r == FB_ERROR_DEPTH) continue;
      if (sessionFormErrors.contains(r)) {
        addFb(bottomIdx, bottomIdx + holdFramesMedium, r);
        isBad = true;
      }
    }

    if (isBad) badRepIdxs.add(e);
    frameTelemetry[peakIdx]['rep_just_finished'] = isBad ? 'bad' : 'good';
  }

  // Apply: rewrite frame feedback from the mask, clearing anything
  // outside a bad-rep window.
  for (int i = 0; i < frameTelemetry.length; i++) {
    final List<String> fbs = finalFbsByFrame[i];
    frameTelemetry[i]['feedback'] = fbs.isEmpty ? null : fbs.join('\n');
  }

  // Recompute final goodReps / badReps from the verdicts we just placed.
  int finalGood = 0;
  int finalBad = 0;
  for (final ev in pulseEvents) {
    final int peakIdx = (ev['peakIdx'] as int?) ?? -1;
    if (peakIdx < 0 || peakIdx >= frameTelemetry.length) continue;
    final v = frameTelemetry[peakIdx]['rep_just_finished'];
    if (v == 'bad') {
      finalBad++;
    } else if (v == 'good') {
      finalGood++;
    }
  }
  goodReps = finalGood;
  badReps = finalBad;

  // ============================================================
  // [v19 FEEDBACK-SYNC] The in-video banners placed by phase 2 are the
  // single source of truth for form errors. Overwrite sessionFormErrors
  // with exactly the set of errors that were displayed, so the returned
  // `feedback` list (and the technique-score penalty derived from it)
  // always matches what the user sees in the video.
  //
  // This closes the leak paths where an error could sit in
  // sessionFormErrors WITHOUT any banner having been shown:
  //   - HIPS fired by evaluateCycleForm at plank-exit / cycle-reset
  //     (no corresponding per-rep 'reasons' entry → never displayed).
  //   - Any leftover in-loop accumulator state.
  // Errors WITH banners are always in sessionFormErrors already (phase
  // 2 gates on `sessionFormErrors.contains`), so this is a pure
  // intersection — it can only remove undisplayed errors, never add.
  // ============================================================
  sessionFormErrors
    ..clear()
    ..addAll(displayedFormErrors);

  // ================ 5) Aggregate session ================
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

    if (allScores.isNotEmpty) {
      final double avgRepScore =
          allScores.reduce((a, b) => a + b) / allScores.length;
      if (avgRepScore < 9.0 && techniqueScore >= 10.0) {
        techniqueScore = halfFloor10(avgRepScore + 0.5);
      }
    }
  }

  // [v5b GOOD-REPS-FIX] Removed the override that used to force
  // goodReps = repCount when techniqueScore == 10. That override fired
  // BEFORE the post-aggregation lockout/depth percentile checks, which
  // could legitimately add a session-level form error after the override
  // had already nuked badReps to 0. Result: 18/18 "good" reps with a
  // form-error feedback shown — a contradiction the user noticed.
  //
  // Now goodReps and badReps reflect the actual per-rep verdict from
  // commitPendingRep() (which considers both the rep's own form issues
  // and whether a feedback banner was being shown at commit time). If
  // any session-level error fires, that's still surfaced separately via
  // feedbackList, but it doesn't retroactively flip the rep counts.
  if (sessionFormErrors.isEmpty && repCount > 0) {
    techniqueScore = 10.0;
  }
  // (Old block removed:)
  // if (techniqueScore == 10.0 && repCount > 0) {
  //   goodReps = repCount;
  //   badReps = 0;
  // }

  if (repReports.length >= 2) {
    final List<double> lockoutScores = repReports
        .where((r) => r['detailed_scores'] != null)
        .map<double>(
            (r) => ((r['detailed_scores'] as Map)['lockout'] as num).toDouble())
        .toList();
    final List<double> depthScores = repReports
        .where((r) => r['detailed_scores'] != null)
        .map<double>(
            (r) => ((r['detailed_scores'] as Map)['depth'] as num).toDouble())
        .toList();

    if (lockoutScores.isNotEmpty) {
      // [v8 LOCKOUT-PCT-DISABLED] The session-level lockout error is now
      // decided by the post-process pass that uses the actual peak elbow
      // angle (rawElbowMaxByFrame) per rep. The lockout-score-based
      // percentile check here is unreliable because the per-rep
      // top_elbow_angle stored in repReports comes from the in-loop
      // measurement which is contaminated. Block disabled.
    }
    if (depthScores.isNotEmpty) {
      // [v19 DEPTH-PCT-DISABLED] This score-percentile depth check used
      // to re-add FB_ERROR_DEPTH here — AFTER the post-process pass had
      // already made (and displayed) the authoritative depth decision.
      // Result: the summary `feedback` could contain "Go deeper" while
      // the video showed no banner at all — exactly the mismatch the
      // user reported. The v17/v18 visual depth check in the
      // post-process pass is authoritative; this legacy path is
      // disabled (kept as documentation, mirroring the lockout block
      // above).
    }

    if (sessionFormErrors.isNotEmpty) {
      double penalty = 0.0;
      for (final m in sessionFormErrors) {
        penalty += FB_WEIGHTS[m] ?? FB_DEFAULT_WEIGHT;
      }
      penalty = math.max(PENALTY_MIN_IF_ANY, penalty);
      techniqueScore = halfFloor10(math.max(0.0, 10.0 - penalty));
      if (allScores.isNotEmpty) {
        final avgRepScore =
            allScores.reduce((a, b) => a + b) / allScores.length;
        techniqueScore =
            math.min(techniqueScore, halfFloor10(avgRepScore + 0.5));
      }
    }
  }

  // [v10] Old GOOD-REPS-COHERENCE pass removed. The two-phase post-
  // process pass above now produces consistent goodReps/badReps from
  // the per-rep verdicts (re-decided against the final session error
  // set), so this reconciliation isn't needed.

  final List<String> formErrorsList = FORM_ERROR_PRIORITY
      .where((err) => sessionFormErrors.contains(err))
      .toList();
  final List<String> perfTipsList =
      PERF_TIP_PRIORITY.where((tip) => sessionPerfTips.contains(tip)).toList();

  // [v4] 0 reps → generic "couldn't analyze" feedback (consistency with
  // squat and curl analyzers).
  final List<String> feedbackList;
  if (repCount == 0) {
    feedbackList = <String>[
      "Couldn't analyze this video — make sure your full body is visible from the side and that you complete at least one pushup."
    ];
  } else if (formErrorsList.isNotEmpty) {
    feedbackList = formErrorsList;
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
    'tips': repCount == 0 ? <String>[] : perfTipsList,
    'reps': repReports,
    'exercise_type': 'pushup',
    'video_path': fileUri,
    'analyzed_fps': fps,
    'frame_count': frameIdx,
    '_source_video_uri': fileUri,
    '_frame_telemetry': frameTelemetry,
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
