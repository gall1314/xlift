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
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

/// Dips analyzer — v47.2 (meter anchor lowered to 110°, on top of v47.1).
///
/// v36 architecture (UNCHANGED):
///   STATE MACHINE (Schmitt trigger) — same pattern as the proven
///   pushup analyzer. No peak detection, no combined-signal EMA, no
///   filter chain. Just thresholds with large hysteresis gaps.
///
///   bottom = (rawElbow ≤ 115° OR elbowEma ≤ 115°)
///        AND (shoulderDescent ≥ 0.025 OR ≥ 0.0225 with raw elbow ≤ 122°)
///   reset  = (shoulderAscent ≥ 0.015) OR
///            (elbowEma ≥ 165° AND countedThisCycle)
///   refractory = 8 frames (~0.53s @ 15fps)
///
/// v39 ADDITION (one focused fix — phantom counts on dismount/walking):
///
///   The v36 commit fires the moment atBottom criteria are met.
///   That's the leak: dismount and walking both produce a "descent +
///   bent elbow" snapshot that crosses the bottom thresholds, with no
///   way for the state machine to know the body will not return up.
///
///   Fix: split counting into two stages.
///   Stage 1 (PENDING): atBottom criteria met → mark a pending count
///   at this frame, store cycle data, update state (allowNewBottom,
///   countedThisCycle, lastBottomFrame) exactly as v36 did. But DO NOT
///   increment repCount, do not push to repReports/pulseEvents, do not
///   touch depthFailCount/leanFailCount.
///   Stage 2 (COMMIT): if shoulder ascends VALIDATION_ASCENT (0.020)
///   from the pending point within PENDING_TIMEOUT_FRAMES (30, ≈ 2s),
///   commit the rep (all the original commit logic runs then). If the
///   timeout passes without enough ascent, or onDips drops, the
///   pending is silently dropped — repCount was never incremented, so
///   nothing visual is undone.
///
///   Why this filters dismount/walking but keeps real reps:
///     - Real rep: body goes down ~0.025–0.10, then back up ~0.025–0.10
///       to lockout. 0.020 ascent confirms the return.
///     - Dismount: body keeps descending past atBottom (off bars to
///       ground), never returns to anywhere near the bottom shY —
///       ascent stays negative or near 0. Times out → dropped.
///     - Walking after dismount: shY oscillates around standing
///       position, far below the pending point — ascent stays
///       negative.
///
///   This is NOT a retroactive undo: the count never gets visible in
///   the first place. It is NOT a magnitude filter: it does not look
///   at how deep the descent went, so low bars are not penalized.
///
/// v41 ADDITION (one focused fix — phantoms that survive v39):
///
///   v39's two-stage counting filters cases where the body never
///   returns up after a "bottom" event. It does not filter cases
///   where:
///   (a) The mount onto the bars contains a brief sub-cycle (small
///       dip during the push-up), AND the user then ascends to
///       lockout — which validates as ascent ≥ 0.020.
///   (b) Walking after dismount on low/medium bars, where the
///       standing shY is similar to the on-bars shY range — a
///       step-bob can pass the 0.020 ascent threshold.
///
///   Both phantoms share a property: they begin from a different
///   spatial position than real reps. Real reps all start descending
///   from the lockout position on the bars — same shY across the set.
///   Mount cycles start mid-mount; walking cycles start from standing.
///
///   Fix: a single post-process clustering pass. After the state
///   machine has produced its pulseEvents list, compute the median
///   descBaseShoulder over all pulses. Drop any pulse whose
///   descBaseShoulder is more than 0.05 from the median. The drop is
///   invisible to the user — pulses dropped here never increment the
///   counter (we wipe the loop's reps values and rebuild from the
///   filtered list).
///
///   Guarded on having ≥ 5 pulses, so the median is a reliable
///   estimator of the "real rep cluster." With fewer pulses we skip
///   clustering — accepted limit for short sets.
///
///   v41.1 refinement: pulses at the FIRST and LAST positions in the
///   list use a tighter tolerance (0.03 vs 0.05 general). Phantoms
///   structurally appear at edges only (mount precedes all real reps;
///   walking/dismount follows them), so the strictness applies only
///   where phantoms can actually be. Middle pulses keep the looser
///   tolerance and are unaffected.
///
///   This is not a layer on the state machine: state machine logic
///   is unchanged. It is one post-process step operating on the
///   state machine's output, with a clear single purpose.
///
/// v42 — Feedback tuning (DOES NOT touch rep detection):
///
///   1. LOCKOUT_FAIL_ANGLE 130→150. 130° meant the session-level
///      "missed lockout" error only fired on near-90° pseudo-lockouts.
///      150° aligns the session firing with what the per-rep score
///      already considers below "Good".
///   2. LEAN_FAIL_DEG 45→40. 45 only caught extreme postures; 40
///      still allows chest-focused forward lean (~15-30°) but catches
///      consistent posture breakdown.
///   3. FB_ELBOWS_IN removed. It was declared and weighted but no
///      code path ever added it to sessionFormErrors. Dead code.
///   4. Form Tip when session is Excellent: replaces the hardcoded
///      DIPS_TIPS[1] with one of two next-step tips:
///        - TIP_PAUSE (default): "Try a 1-second pause at the bottom"
///        - TIP_PARALLEL (3+ reps with bottom elbow < 70°): nudge
///          toward standard depth target.
///      The previous logic always displayed the lockout tip even at
///      a perfect score, which was misleading.
///
/// EMA convention: ema = alpha * new + (1-alpha) * prev
///   With alpha=0.85: light smoothing, responsive to real motion.
Future<dynamic> analyzeDipsVideoAction(
  FFUploadedFile videoFile,
  double? targetFps,
) async {
  // Schmitt Trigger Parameters
  // Large hysteresis gaps make decisions immune to ML Kit per-frame
  // noise (typical noise is ~2° in elbow, ~0.005 in shoulder Y).
  //
  // v36: ELBOW_BENT_ANGLE relaxed from 100° → 115°. ML Kit on real
  // dip videos reports elbow at bottom anywhere from 80° (deep) to
  // 115° (shallow). Threshold at 100° was missing half the user's
  // reps. 115° still requires a substantial bend (50° below RESET_ELBOW
  // which is 165° — large hysteresis preserved).
  const double ELBOW_BENT_ANGLE = 115.0; // bottom: elbow ≤ 115°
  const double RESET_ELBOW = 165.0; // top:    elbow ≥ 165°  (50° gap)
  const double SHOULDER_MIN_DESCENT = 0.025; // bottom: shY descended ≥ 0.025
  const double RESET_ASCENT = 0.015; // rearm:  shY ascended ≥ 0.015
  // REFRACTORY_FRAMES is fps-derived (REFRACTORY_FRAMES_FPS computed
  // later). Keeps the ~0.55s time meaning constant across fps values.

  // v39: Two-stage counting validation.
  // VALIDATION_ASCENT chosen as 0.020: comfortably below the typical
  // return-to-lockout ascent of a real rep (≈ 0.025–0.10) but above
  // typical walking-step body bob amplitude (≈ 0.005–0.015) and above
  // RESET_ASCENT (0.015) so reset-without-validation is the natural
  // outcome for an incomplete cycle.
  const double VALIDATION_ASCENT = 0.020;
  // PENDING_TIMEOUT_FRAMES is fps-derived (≈ 2s @ any fps).

  // EMA on the per-frame signals. Light smoothing (alpha=0.85 means
  // 85% weight on previous, 15% on new — heavy enough to absorb
  // single-frame ML Kit spikes, light enough to track real motion).
  const double ELBOW_EMA_ALPHA = 0.85;
  const double SHOULDER_EMA_ALPHA = 0.85;

  // Visibility / gating
  const double VIS_THR = 0.30;
  // ONDIPS_MIN_FRAMES and OFFDIPS_MIN_FRAMES are fps-derived.

  // Initial descent detection — INFLECT_VEL_THR is fps-derived.

  // After a counted rep, re-arm allows the next rep to count when:
  //  - shoulder ascended at least RESET_ASCENT*0.5 from cycle min, OR
  //  - raw elbow rose at least RAW_ELBOW_REARM_RISE from cycle min.
  const double RAW_ELBOW_REARM_RISE = 18.0;

  // ================ Form scoring thresholds ================
  // Depth: how bent the elbow gets at the bottom of the rep.
  const double DEPTH_EXCELLENT_ANGLE = 85.0;
  const double DEPTH_GOOD_ANGLE = 95.0;
  const double DEPTH_FAIR_ANGLE = 105.0;
  const double DEPTH_POOR_ANGLE = 115.0;

  // Lockout: how straight the elbow gets at the top.
  const double LOCKOUT_EXCELLENT = 170.0;
  const double LOCKOUT_GOOD = 155.0;
  const double LOCKOUT_FAIR = 140.0;
  const double LOCKOUT_POOR = 125.0;

  // v47.1: Anchor for the VISUAL depth meter only. The scoring rubric
  // above uses 170° as "Excellent lockout" because that's the
  // anatomical target. But ML Kit, in a dip pose where the body
  // partially occludes the upper arms, consistently reads the elbow
  // at 110-120° even when the arms are visually fully straight. The
  // meter therefore must NOT use 170° as its "0% reference" — it
  // would never reach 0 at the visible lockout.
  //
  // v47.2: anchor reduced from 135 → 110 after empirical
  // verification on test video. Back-calculation from observed
  // depth values: when user reports "30-50% at lockout" with
  // anchor=135, the ML Kit elbow reading is 110-120°. Setting
  // anchor to 110° makes both these clamp to 0% at the visible
  // lockout. This is the lowest "natural extension" reading we
  // see — going lower would risk users with cleaner lockouts
  // seeing 0% during much of their descent.
  //
  // This is purely a visual calibration — scoring continues to use
  // 170° / 155° / etc. for grading lockout quality.
  const double METER_TOP_ANCHOR = 110.0;

  // Forward torso lean (degrees from vertical).
  const double LEAN_EXCELLENT = 15.0;
  const double LEAN_GOOD = 25.0;
  const double LEAN_FAIR = 35.0;
  const double LEAN_POOR = 50.0;

  // Session-level form-error firing thresholds
  const double DEPTH_FAIL_ANGLE = 115.0;
  const double LOCKOUT_FAIL_ANGLE = 150.0; // v42: was 130 — 130 only caught
  // pathological non-lockouts. 150 catches honest soft lockouts that
  // the per-rep score already penalizes; the session-level firing
  // now matches what the scoring rubric considers below "Good".
  const double LEAN_FAIL_DEG = 40.0; // v42: was 45 — 45 only caught extreme
  // postures. 40 still allows the legitimate chest-focused forward
  // lean (≤25-30°) but fires on consistent posture breakdown.
  const int DEPTH_FAIL_MIN_REPS = 3;
  const int LOCKOUT_FAIL_MIN_REPS = 3;
  const int LEAN_FAIL_MIN_REPS = 4;

  // Form error labels (kept identical to v1-v34 for app compatibility)
  const String FB_DEEPER = 'Go deeper (elbows to 90°)';
  const String FB_LOCKOUT = 'Fully lockout elbows at top';
  const String FB_LEAN = 'Reduce forward lean (keep torso upright)';
  // v42: FB_ELBOWS_IN removed. It was declared and referenced in
  // FB_PRIORITY/FB_WEIGHTS but no code path ever added it to
  // sessionFormErrors, so it never fired. Detecting elbow flaring
  // would require a measurement we don't currently capture; rather
  // than carry dead code, we remove it.

  const List<String> FB_PRIORITY = [
    FB_DEEPER,
    FB_LOCKOUT,
    FB_LEAN,
  ];

  const Map<String, double> FB_WEIGHTS = {
    FB_DEEPER: 1.0,
    FB_LOCKOUT: 0.8,
    FB_LEAN: 0.7,
  };
  const double FB_DEFAULT_WEIGHT = 0.5;
  const double PENALTY_MIN_IF_ANY = 0.5;

  // v42: Form tip strings (replaces DIPS_TIPS array — only one slot of
  // that array was ever displayed). The form tip is shown when no
  // form error was detected (session score is Excellent / Proper Reps
  // is full). It is a "next step" suggestion, not a fault report.
  //
  // TIP_PAUSE: default progression tip — adding a brief pause at the
  // bottom removes the stretch-shortening bounce, increases time
  // under tension, and is a standard progression cue once technique
  // is solid.
  //
  // TIP_PARALLEL: shown when the user is consistently descending well
  // past parallel (3+ reps with bottom elbow angle < 70°). For a
  // general-fitness app population, going deeper than parallel offers
  // no additional hypertrophy benefit but requires extra shoulder
  // mobility prep — most users haven't done that prep deliberately,
  // so the tip nudges toward the standard depth target.
  const String TIP_PAUSE = 'Try a 1-second pause at the bottom of each rep';
  const String TIP_PARALLEL =
      "Stop near parallel — going much deeper isn't necessary for hypertrophy";
  const double EXTREME_DEPTH_ANGLE = 70.0;
  const int EXTREME_DEPTH_MIN_REPS = 3;

  final double fps = (targetFps ?? 20.0).clamp(2.0, 30.0);

  // Frame-based constants are fps-derived so the time meaning stays
  // constant when fps changes. At fps=20: REFRACTORY ≈ 0.55s,
  // TIMEOUT ≈ 2s, ONDIPS_MIN ≈ 150ms, OFFDIPS_MIN ≈ 350ms.
  final int REFRACTORY_FRAMES_FPS = math.max(2, (0.53 * fps).round());
  final int PENDING_TIMEOUT_FRAMES_FPS = math.max(10, (2.0 * fps).round());
  final int ONDIPS_MIN_FRAMES_FPS = math.max(2, (0.13 * fps).round());
  final int OFFDIPS_MIN_FRAMES_FPS = math.max(3, (0.33 * fps).round());
  // INFLECT_VEL_THR is a PER-FRAME shoulder-Y delta. At higher fps
  // the same body speed produces a smaller per-frame delta, so this
  // threshold scales inversely. The 0.0027 value was tuned at fps=15.
  final double INFLECT_VEL_THR_FPS = 0.0027 * (15.0 / fps);

  _dipsCachedW = -1;
  _dipsCachedH = -1;

  // ================ Helpers ================
  double calcAngle(List<double> a, List<double> b, List<double> c) {
    final double rad = math.atan2(c[1] - b[1], c[0] - b[0]) -
        math.atan2(a[1] - b[1], a[0] - b[0]);
    double ang = (rad * 180.0 / math.pi).abs();
    if (ang > 180) ang = 360 - ang;
    return ang;
  }

  // EMA: alpha = weight on NEW value (same convention as pushup
  // analyzer). Higher alpha = lighter smoothing (more responsive).
  // alpha=0.85 means new value gets 85% weight = light smoothing.
  double ema(double? prev, double newVal, double alpha) {
    if (prev == null) return newVal;
    return alpha * newVal + (1 - alpha) * prev;
  }

  double halfFloor10(double x) {
    final double clamped = x.clamp(0.0, 10.0);
    return ((clamped * 2.0).floorToDouble()) / 2.0;
  }

  String displayHalfStr(double x) {
    final double q = (x * 2).round() / 2.0;
    if ((q - q.round()).abs() < 1e-9) return q.round().toString();
    return q.toStringAsFixed(1);
  }

  String scoreLabel(double s) {
    if (s >= 9.0) return 'Excellent';
    if (s >= 7.0) return 'Good';
    if (s >= 5.5) return 'Fair';
    return 'Needs work';
  }

  // Torso lean: angle from vertical of the line midHip→midShoulder.
  // 0 = perfectly upright; 90 = horizontal.
  double calcTorsoLean(List<double> midSh, List<double> midHip) {
    final dx = midSh[0] - midHip[0];
    final dy = midSh[1] - midHip[1];
    return math.atan2(dx.abs(), dy.abs()) * 180.0 / math.pi;
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
        'feedback': <String>[
          "Couldn't analyze this video — make sure your full body is visible from the side on the dips bars."
        ],
        'tip': null,
        'reps': <dynamic>[],
        'video_path': '',
        '_source_video_uri': '',
        '_frame_telemetry': <dynamic>[],
      };

  // ================ 0) Persist upload ================
  if (videoFile.bytes == null || videoFile.bytes!.isEmpty) {
    return errorPayload('empty_upload', 'Uploaded file has no bytes');
  }

  final Directory tmp = await getTemporaryDirectory();
  final String uploadName =
      (videoFile.name != null && videoFile.name!.isNotEmpty)
          ? videoFile.name!
          : 'upload.mp4';
  final String rawSafeName = uploadName.split('/').last.split('\\').last;
  final String safeName =
      rawSafeName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  final String videoPath = p.join(
    tmp.path,
    'dips_in_${DateTime.now().millisecondsSinceEpoch}_$safeName',
  );

  try {
    await File(videoPath).writeAsBytes(videoFile.bytes!, flush: true);
  } catch (e) {
    return errorPayload('write_failed', 'Could not save upload: $e');
  }

  // ================ 1) Extract frames ================
  final String sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  final Directory framesDir =
      Directory(p.join(tmp.path, 'dips_frames_$sessionId'));
  if (framesDir.existsSync()) framesDir.deleteSync(recursive: true);
  framesDir.createSync(recursive: true);

  final String framePattern = p.join(framesDir.path, 'f_%05d.jpg');
  final String extractCmd =
      "-y -i \"$videoPath\" -vf \"fps=$fps,scale='min(720,iw)':-2\" -q:v 4 \"$framePattern\"";

  final extractSession = await FFmpegKit.execute(extractCmd);
  final extractRc = await extractSession.getReturnCode();
  if (!ReturnCode.isSuccess(extractRc)) {
    return errorPayload(
        'ffmpeg_extract_failed', 'Could not extract frames from video');
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
  // SINGLE mode (no cross-frame tracker state — each frame deterministic
  // per-frame given the same model weights). Accurate model = best for
  // angled views.
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

  // State machine
  double? elbowEma;
  double? shoulderEma;
  double? shoulderPrev;
  double? descBaseShoulder; // shoulder Y when current descent began
  bool allowNewBottom = true;
  int lastBottomFrame = -1000000000;
  double cycleMaxDescent = 0.0;
  bool countedThisCycle = false;

  // v39: Pending-count state (two-stage counting).
  // Set when atBottom criteria are met; committed only after shoulder
  // ascends VALIDATION_ASCENT from pendingCountShY within
  // PENDING_TIMEOUT_FRAMES. Independent of cycle state — survives
  // resetByAsc/resetByElb so a real rep's ascent can validate it even
  // after the cycle has reset. Replaced (silently dropped) if a new
  // atBottom fires before validation; cleared on timeout or onDips=false.
  bool pendingCount = false;
  int pendingCountFrame = 0;
  double pendingCountShY = 0.0;
  double pendingCountRawElbow = 0.0;
  double? pendingBottomElbow;
  double? pendingMaxLean;
  double? pendingMaxElbow;
  // v41: descBaseShoulder snapshot for post-process outlier clustering.
  // Real dip cycles all start from the same spatial position (lockout
  // on the bars); mount/walking-bob cycles start from different shY.
  double? pendingDescBase;
  // v43: midShoulder-X snapshot at Phase A→B transition, for 2D
  // outlier clustering at edges. Real reps stay at the same screen X
  // (bars and camera both fixed); walking shifts the X. We use the
  // MIDPOINT of L/R shoulders (not the dominant-side X), so useLeft
  // flipping mid-set has no effect on this value — avoids the v38
  // failure mode where the dominant-arm X jumped across the body.
  double? pendingDescBaseX;

  bool onDips = false;
  int onDipsStreak = 0;
  int offDipsStreak = 0;
  // v47: EMA state for the visual depth meter only. The meter elbow
  // value comes from raw ML Kit landmarks, which on a dip's deep
  // bottom position can jitter ±15-20° between frames in the SAME
  // body posture — ML Kit guesses occluded joint locations and the
  // guess varies frame-to-frame. A light EMA on the final depth
  // value (not on landmarks, not on the angle, not multiple stages
  // — just one EMA at the very end) damps that jitter without
  // introducing meaningful lag.
  double prevMeterDepth = 0.0;

  // Per-cycle measurements for form scoring
  double? cycleMinElbowRaw; // smallest elbow angle reached (deepest)
  double? cycleMaxElbowRaw; // largest elbow angle reached (most extended)
  double? cycleMaxTorsoLean;

  // Session form-error tracking
  final Set<String> sessionFormErrors = {};
  int depthFailCount = 0;
  int lockoutFailCount = 0;
  int leanFailCount = 0;

  // Per-frame data stored for post-process pass
  final List<double> rawElbowMaxByFrame = [];
  final List<double> rawElbowMinByFrame = [];
  final List<double?> shoulderYByFrame = [];

  // Pulse events recorded at commit; visual placement is resolved in
  // the post-process pass.
  final List<Map<String, dynamic>> pulseEvents = [];

  // Telemetry output
  final List<Map<String, dynamic>> frameTelemetry = [];
  List<List<double>>? lastValidLandmarks;

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

  // Build rep report (form scoring only — no counter mutation)
  Map<String, dynamic> buildRepReport({
    required double? bottomElbow,
    required double? topElbow,
    required double? maxTorsoLean,
  }) {
    double depthScore = 10.0;
    double lockoutScore = 10.0;
    double leanScore = 10.0;

    if (bottomElbow != null) {
      if (bottomElbow <= DEPTH_EXCELLENT_ANGLE) {
        depthScore = 10.0;
      } else if (bottomElbow <= DEPTH_GOOD_ANGLE) {
        depthScore = 9.0;
      } else if (bottomElbow <= DEPTH_FAIR_ANGLE) {
        depthScore = 7.5;
      } else if (bottomElbow <= DEPTH_POOR_ANGLE) {
        depthScore = 5.0;
      } else {
        depthScore = 3.0;
      }
    }
    if (topElbow != null) {
      if (topElbow >= LOCKOUT_EXCELLENT) {
        lockoutScore = 10.0;
      } else if (topElbow >= LOCKOUT_GOOD) {
        lockoutScore = 9.0;
      } else if (topElbow >= LOCKOUT_FAIR) {
        lockoutScore = 7.5;
      } else if (topElbow >= LOCKOUT_POOR) {
        lockoutScore = 5.0;
      } else {
        lockoutScore = 3.0;
      }
    }
    if (maxTorsoLean != null) {
      if (maxTorsoLean <= LEAN_EXCELLENT) {
        leanScore = 10.0;
      } else if (maxTorsoLean <= LEAN_GOOD) {
        leanScore = 9.0;
      } else if (maxTorsoLean <= LEAN_FAIR) {
        leanScore = 7.5;
      } else if (maxTorsoLean <= LEAN_POOR) {
        leanScore = 5.0;
      } else {
        leanScore = 3.0;
      }
    }

    double repScore =
        depthScore * 0.45 + lockoutScore * 0.35 + leanScore * 0.20;
    repScore = (repScore * 2).round() / 2.0;

    return {
      'rep_index': 0,
      'score': repScore,
      'good': repScore >= 9.0,
      'detailed_scores': {
        'depth': depthScore,
        'lockout': lockoutScore,
        'lean': leanScore,
      },
      'measurements': {
        'bottom_elbow_angle': bottomElbow,
        'top_elbow_angle': topElbow,
        'torso_lean': maxTorsoLean,
      },
    };
  }

  // ================ 4) Process each frame ================
  try {
    for (final frameFile in frameFiles) {
      frameIdx += 1;
      final double tSec = (frameIdx - 1) / fps;

      // v39: timeout-only pending check at top of frame. Works even on
      // skipped frames (no-pose, missing landmarks) where the main
      // validation block below doesn't run. Pure timeout — no commit
      // path here.
      if (pendingCount &&
          (frameIdx - pendingCountFrame) > PENDING_TIMEOUT_FRAMES_FPS) {
        pendingCount = false;
      }

      final inputImage = InputImage.fromFilePath(frameFile.path);
      List<Pose> poses;
      try {
        poses = await poseDetector.processImage(inputImage);
      } catch (_) {
        poses = const [];
      }

      // No pose detected
      if (poses.isEmpty) {
        offDipsStreak += 1;
        onDipsStreak = 0;
        if (onDips && offDipsStreak >= OFFDIPS_MIN_FRAMES_FPS) {
          onDips = false;
          descBaseShoulder = null;
          allowNewBottom = true;
          pendingCount = false; // v39: drop pending on onDips exit
        }
        frameTelemetry.add({
          't': tSec,
          'reps': repCount,
          'depth': 0.0,
          'metric_label': 'DEPTH',
          'metric_value': 0.0,
          'feedback': null,
          'rep_just_finished': null,
          'landmarks': lastValidLandmarks ?? <List<double>>[],
        });
        rawElbowMaxByFrame.add(0.0);
        rawElbowMinByFrame.add(0.0);
        shoulderYByFrame.add(null);
        continue;
      }

      final Pose pose = poses.first;
      final lm = pose.landmarks;

      double fw = _dipsCachedW;
      double fh = _dipsCachedH;
      if (fw <= 0 || fh <= 0) {
        final dims = await _dipsProbeImageDims(frameFile.path);
        fw = dims.$1.toDouble();
        fh = dims.$2.toDouble();
        _dipsCachedW = fw;
        _dipsCachedH = fh;
      }

      // Build normalized landmarks for telemetry
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

      if (lsh == null ||
          rsh == null ||
          le == null ||
          re == null ||
          lw == null ||
          rw == null ||
          lh == null ||
          rh == null) {
        offDipsStreak += 1;
        onDipsStreak = 0;
        if (onDips && offDipsStreak >= OFFDIPS_MIN_FRAMES_FPS) {
          onDips = false;
          descBaseShoulder = null;
          allowNewBottom = true;
          pendingCount = false; // v39: drop pending on onDips exit
        }
        frameTelemetry.add({
          't': tSec,
          'reps': repCount,
          'depth': 0.0,
          'metric_label': 'DEPTH',
          'metric_value': 0.0,
          'feedback': null,
          'rep_just_finished': null,
          'landmarks': normLandmarks,
        });
        rawElbowMaxByFrame.add(0.0);
        rawElbowMinByFrame.add(0.0);
        shoulderYByFrame.add(null);
        continue;
      }

      final List<double> nLsh = [lsh.x / fw, lsh.y / fh];
      final List<double> nRsh = [rsh.x / fw, rsh.y / fh];
      final List<double> nLe = [le.x / fw, le.y / fh];
      final List<double> nRe = [re.x / fw, re.y / fh];
      final List<double> nLw = [lw.x / fw, lw.y / fh];
      final List<double> nRw = [rw.x / fw, rw.y / fh];
      final List<double> nLh = [lh.x / fw, lh.y / fh];
      final List<double> nRh = [rh.x / fw, rh.y / fh];

      // Lock to dominant arm by visibility
      final double vL = lsh.likelihood + le.likelihood + lw.likelihood;
      final double vR = rsh.likelihood + re.likelihood + rw.likelihood;
      final bool useLeft = vL >= vR;

      final double minVis = [
        useLeft ? lsh.likelihood : rsh.likelihood,
        useLeft ? le.likelihood : re.likelihood,
        useLeft ? lw.likelihood : rw.likelihood,
      ].reduce(math.min);
      final bool visOk = minVis >= VIS_THR;

      // Per-frame measurements (raw - no smoothing)
      final double rawElbowL = calcAngle(nLsh, nLe, nLw);
      final double rawElbowR = calcAngle(nRsh, nRe, nRw);
      final double rawElbow = useLeft ? rawElbowL : rawElbowR;
      final double rawElbowMin = math.min(rawElbowL, rawElbowR);
      final double rawElbowMax = math.max(rawElbowL, rawElbowR);

      final double shoulderRaw = useLeft ? nLsh[1] : nRsh[1];

      // EMA-smoothed signals (light smoothing — absorbs single-frame
      // ML Kit jitters without significantly delaying real motion).
      elbowEma = ema(elbowEma, rawElbow, ELBOW_EMA_ALPHA);
      shoulderEma = ema(shoulderEma, shoulderRaw, SHOULDER_EMA_ALPHA);
      final double shoulderY = shoulderEma!;
      final double elbowAngle = elbowEma!;

      // Torso lean (for form scoring only — not for rep detection)
      final List<double> midSh = [
        (nLsh[0] + nRsh[0]) / 2.0,
        (nLsh[1] + nRsh[1]) / 2.0,
      ];
      final List<double> midHip = [
        (nLh[0] + nRh[0]) / 2.0,
        (nLh[1] + nRh[1]) / 2.0,
      ];
      final double torsoLean = calcTorsoLean(midSh, midHip);

      // === onDips gating ===
      if (visOk) {
        onDipsStreak += 1;
        offDipsStreak = 0;
      } else {
        offDipsStreak += 1;
        onDipsStreak = 0;
      }

      if (!onDips && onDipsStreak >= ONDIPS_MIN_FRAMES_FPS) {
        onDips = true;
        descBaseShoulder = null;
        allowNewBottom = true;
        cycleMaxDescent = 0.0;
        countedThisCycle = false;
        cycleMinElbowRaw = null;
        cycleMaxElbowRaw = null;
        cycleMaxTorsoLean = null;
      }

      if (onDips && offDipsStreak >= OFFDIPS_MIN_FRAMES_FPS) {
        onDips = false;
        descBaseShoulder = null;
        allowNewBottom = true;
        pendingCount = false; // v39: drop pending on onDips exit
      }

      // v39: STAGE 2 — validate or commit a pending count.
      // Independent of cycle state (works after resetByAsc/resetByElb
      // has already cleared descBaseShoulder). Confirms a real rep by
      // observing shoulder ascent ≥ VALIDATION_ASCENT from the pending
      // bottom; otherwise waits, until the timeout at the top of the
      // next frame drops it.
      if (pendingCount && onDips && visOk) {
        final double ascentFromPending = pendingCountShY - shoulderY;
        if (ascentFromPending >= VALIDATION_ASCENT) {
          // === COMMIT THE REP ===
          final double? bottomElbow = pendingBottomElbow;
          final double? maxLean = pendingMaxLean;

          bool repIsBad = false;
          final List<String> repFbs = [];

          // Depth check
          if (bottomElbow != null && bottomElbow > DEPTH_FAIL_ANGLE) {
            depthFailCount += 1;
            if (depthFailCount >= DEPTH_FAIL_MIN_REPS) {
              sessionFormErrors.add(FB_DEEPER);
            }
            if (sessionFormErrors.contains(FB_DEEPER)) {
              repFbs.add(FB_DEEPER);
              repIsBad = true;
            }
          }

          // Lean check
          if (maxLean != null && maxLean > LEAN_FAIL_DEG) {
            leanFailCount += 1;
            if (leanFailCount >= LEAN_FAIL_MIN_REPS) {
              sessionFormErrors.add(FB_LEAN);
            }
            if (sessionFormErrors.contains(FB_LEAN)) {
              repFbs.add(FB_LEAN);
              repIsBad = true;
            }
          }

          // Build rep report (topElbow filled/refined in post-process)
          final Map<String, dynamic> repData = buildRepReport(
            bottomElbow: bottomElbow ?? pendingCountRawElbow,
            topElbow: pendingMaxElbow,
            maxTorsoLean: maxLean,
          );
          repData['rep_index'] = repCount + 1;
          repReports.add(repData);
          allScores.add((repData['score'] as num).toDouble());
          repCount += 1;

          if (repIsBad) {
            badReps += 1;
          } else {
            goodReps += 1;
          }

          // Record pulse using the ORIGINAL bottom frame (not current
          // frame), so post-process visual placement is anchored to
          // the actual descent low-point as v36 expected.
          pulseEvents.add({
            'bottomFrameIdx': pendingCountFrame,
            'prevRepCount': repCount - 1,
            'newRepCount': repCount,
            'reasons': List<String>.from(repFbs),
            'cycleMinElbow': bottomElbow,
            'descBaseShoulder': pendingDescBase, // v41: for clustering
            'descBaseX': pendingDescBaseX, // v43: for 2D edge clustering
          });

          pendingCount = false;
        }
      }

      // Shoulder velocity (smoothed Δ per frame)
      final double shoulderVel =
          shoulderPrev == null ? 0.0 : (shoulderY - shoulderPrev!);

      double depthLive = 0.0;

      // ================ STATE MACHINE ================
      if (onDips && visOk) {
        // v44.2: depthLive (visual meter only — not used by detection)
        // is computed HERE, outside the Phase A/Phase B branching, so
        // the meter is continuously bound to elbow angle for the entire
        // time the user is on the bars. Previously the meter was set
        // only inside Phase B; the moment the cycle reset (resetByAsc
        // or resetByElb fired, partway through the ascent), the meter
        // dropped to 0 even though the elbow was still bent. This
        // created a visible 100→0 jump on the way back up. With the
        // meter cycle-independent, the ascent now drops the meter
        // smoothly as the elbow extends. When onDips is false (user
        // off the bars), depthLive stays at its 0.0 default.
        //
        // Anchored so 100% corresponds to a score-10
        // (DEPTH_EXCELLENT_ANGLE = 85°) bottom — matches the scoring
        // rubric the user sees. Uses rawElbow (per-frame raw, not the
        // EMA) so the meter is in lockstep with body motion without
        // the 2-3 frame lag the EMA introduces. ML Kit jitter (~1-2°)
        // maps to ±1-2% on the meter — visually negligible.
        //
        // Detection, depth scoring, and form-error logic are
        // untouched — they use descentAmt, elbowAngle, and
        // cycleMinElbowRaw directly, never depthLive.
        //
        // v44.3: meter uses AVERAGE of left and right elbow angles
        // instead of the useLeft-dependent rawElbow. The average is
        // invariant to useLeft and tracks the overall body position.
        //
        // v47.1: anchor changed from LOCKOUT_EXCELLENT (170°) to
        // METER_TOP_ANCHOR (135°). ML Kit consistently reads elbow
        // at 120-140° at the visible "arms straight" lockout in dips
        // (body occludes upper arms, ML Kit guesses joint positions
        // with systematic underestimation). The 170° anchor meant
        // the meter never returned to 0% at the user's natural top
        // — it showed 30-50% even when arms were visually straight.
        // 135° matches what ML Kit actually reads at typical dip
        // lockouts. Scoring is untouched — it still uses 170°.
        final double meterElbow = (rawElbowL + rawElbowR) / 2.0;
        final double rawMeterDepth = ((METER_TOP_ANCHOR - meterElbow) /
                (METER_TOP_ANCHOR - DEPTH_EXCELLENT_ANGLE))
            .clamp(0.0, 1.0)
            .toDouble();
        // v47: light EMA on the final depth value. alpha=0.6 means
        // 60% new + 40% previous. Damps the per-frame jitter that ML
        // Kit produces in deep-dip poses where joints are partially
        // occluded by the body. Lag is ~50ms (one frame at 20fps) —
        // below the visual perception threshold (~80ms) — so the
        // meter still feels in sync with motion. Real fast motion
        // wins (new sample dominates), but rapid back-and-forth
        // oscillations in a static pose get averaged out.
        depthLive = 0.6 * rawMeterDepth + 0.4 * prevMeterDepth;
        prevMeterDepth = depthLive;

        if (descBaseShoulder == null) {
          // === Phase A: waiting for descent to start ===
          // shoulderVel > 0 in image coords = body moving DOWN (shY
          // grows downward in image). Threshold filters out noise.
          if (shoulderVel > INFLECT_VEL_THR_FPS) {
            descBaseShoulder = shoulderY;
            cycleMaxDescent = 0.0;
            cycleMinElbowRaw = rawElbow;
            cycleMaxElbowRaw = rawElbow;
            cycleMaxTorsoLean = torsoLean;
            countedThisCycle = false;
          }
        } else {
          // === Phase B: in a cycle, track + check thresholds ===
          cycleMaxDescent =
              math.max(cycleMaxDescent, shoulderY - descBaseShoulder!);
          cycleMinElbowRaw = math.min(cycleMinElbowRaw ?? rawElbow, rawElbow);
          cycleMaxElbowRaw = math.max(cycleMaxElbowRaw ?? rawElbow, rawElbow);
          cycleMaxTorsoLean =
              math.max(cycleMaxTorsoLean ?? torsoLean, torsoLean);

          final double descentAmt = shoulderY - descBaseShoulder!;

          // === BOTTOM DETECTION (Schmitt trigger — both criteria) ===
          // BOTH conditions must hold simultaneously. This makes
          // detection require true rep motion (no single-noise-flip
          // can cause a count). v36: also check using smoothed
          // elbow + raw elbow with looser threshold, so a real bottom
          // is caught even if one signal is momentarily noisy.
          bool atBottom = (elbowAngle <= ELBOW_BENT_ANGLE) &&
              (descentAmt >= SHOULDER_MIN_DESCENT);
          final bool rawBottom = (rawElbow <= (ELBOW_BENT_ANGLE + 7.0)) &&
              (descentAmt >= SHOULDER_MIN_DESCENT * 0.9);
          atBottom = atBottom || rawBottom;
          final bool canCnt =
              (frameIdx - lastBottomFrame) >= REFRACTORY_FRAMES_FPS;

          if (atBottom && allowNewBottom && canCnt && !countedThisCycle) {
            // v39: STAGE 1 — PENDING (not commit).
            // Snapshot cycle data and shY for later validation. State
            // machine bookkeeping (allowNewBottom/countedThisCycle/
            // lastBottomFrame) updates exactly as v36 did — only the
            // commit-side effects (repCount/repReports/pulseEvents/
            // form-error counters) are deferred until the rep is
            // confirmed by ascent.
            //
            // If a prior pending is still alive, replace it. A new
            // bottom firing implies the prior one was either already
            // committed (pendingCount=false) or never reached the
            // ascent threshold — in the latter case it is silently
            // dropped, never counted.
            pendingCount = true;
            pendingCountFrame = frameIdx;
            pendingCountShY = shoulderY;
            pendingCountRawElbow = rawElbow;
            pendingBottomElbow = cycleMinElbowRaw;
            pendingMaxLean = cycleMaxTorsoLean;
            pendingMaxElbow = cycleMaxElbowRaw;
            pendingDescBase =
                descBaseShoulder; // v41: for post-process clustering
            pendingDescBaseX =
                midSh[0]; // v43: midShoulder X for 2D edge clustering

            lastBottomFrame = frameIdx;
            allowNewBottom = false;
            countedThisCycle = true;
          }

          // === CYCLE RESET (top of motion reached) ===
          // v36: resetByElb is GATED on countedThisCycle.
          // Reason: when descent starts, smoothed elbow is still close
          // to its lockout value (~165-170°), so resetByElb would
          // immediately fire before we've had a chance to reach
          // bottom, killing the cycle. Once we've counted a rep, the
          // user is on the way back up — only THEN does it make sense
          // to reset by elbow extension.
          //
          // resetByAsc doesn't have this issue: it requires ≥ 0.015
          // shY reversal from the cycle's lowest point, which only
          // happens after the user has actually turned around. Safe
          // anytime.
          //
          // Also: use SMOOTHED elbow (elbowAngle) for resetByElb. With
          // the corrected EMA (alpha=0.85 weight on new) this is
          // responsive enough to catch lockouts, while filtering single-
          // frame ML Kit spikes.
          final bool resetByAsc = descBaseShoulder != null &&
              ((descBaseShoulder! + cycleMaxDescent) - shoulderY) >=
                  RESET_ASCENT;
          final bool resetByElb =
              countedThisCycle && (elbowAngle >= RESET_ELBOW);

          if (resetByAsc || resetByElb) {
            // v36: go back to Phase A (descBaseShoulder = null).
            // Next descent will set a fresh descent base at the actual
            // new top of motion, not at a mid-ascent position.
            //
            // v39: pendingCount is intentionally NOT cleared here.
            // Reset on its own does not invalidate a pending rep — the
            // user can still ascend further after reset and validate
            // the count. pending is dropped only on timeout, onDips
            // exit, or replacement by a new atBottom.
            descBaseShoulder = null;
            cycleMaxDescent = 0.0;
            cycleMinElbowRaw = null;
            cycleMaxElbowRaw = null;
            cycleMaxTorsoLean = null;
            countedThisCycle = false;
            allowNewBottom = true;
          }

          // Re-arm if user partially recovered but didn't fully reset
          if (!allowNewBottom) {
            bool rearmed = false;
            if (descBaseShoulder != null) {
              final double ascentFromBottom =
                  (descBaseShoulder! + cycleMaxDescent) - shoulderY;
              if (ascentFromBottom >= RESET_ASCENT * 0.5) rearmed = true;
            }
            if (!rearmed && cycleMinElbowRaw != null) {
              final double elbowRise = rawElbow - cycleMinElbowRaw!;
              if (elbowRise >= RAW_ELBOW_REARM_RISE) rearmed = true;
            }
            if (rearmed) allowNewBottom = true;
          }
        }
      } else {
        // Not in dips position — clear cycle state
        descBaseShoulder = null;
        allowNewBottom = true;
        // v47: reset meter EMA so when user returns to bars the
        // meter starts fresh at 0 instead of carrying over a stale
        // mid-rep value.
        prevMeterDepth = 0.0;
      }

      // Store per-frame data for post-process pass
      rawElbowMaxByFrame.add(rawElbowMax);
      rawElbowMinByFrame.add(rawElbowMin);
      shoulderYByFrame.add(shoulderY);

      // Emit telemetry (feedback + rep_just_finished filled in post-process)
      frameTelemetry.add({
        't': tSec,
        'reps': repCount,
        'depth': depthLive,
        'metric_label': 'DEPTH',
        'metric_value': depthLive,
        'feedback': null,
        'rep_just_finished': null,
        'landmarks': normLandmarks,
      });

      shoulderPrev = shoulderY;
    }
  } finally {
    await poseDetector.close();
    try {
      framesDir.deleteSync(recursive: true);
    } catch (_) {}
  }

  // ============================================================
  // 5a) v41: SPATIAL CLUSTERING (outlier drop)
  //
  // Real dip cycles all start descending from the same spatial place
  // (the lockout position on the bars). Mount-related phantom cycles
  // start mid-mount; walking-bob phantom cycles start from a standing
  // position. Their descBaseShoulder values are statistical outliers
  // relative to the cluster of real reps.
  //
  // We compute the median descBaseShoulder over all pulses and drop
  // any pulse whose descBaseShoulder is more than CLUSTER_TOLERANCE
  // away from the median. The drop is invisible to the user — the
  // counter never increments for a dropped pulse, no retroactive undo.
  //
  // Guarded on pulseEvents.length >= MIN_PULSES_FOR_CLUSTER (5): with
  // fewer pulses we cannot reliably distinguish "majority cluster"
  // from "phantom cluster", so we skip clustering and accept whatever
  // the state machine produced. For users doing few reps this means
  // phantoms may still slip through — acceptable as a known limit.
  //
  // This is not a layer on top of the state machine: it does not
  // touch state machine logic at all, only post-process bookkeeping.
  // ============================================================
  const int MIN_PULSES_FOR_CLUSTER = 5;
  const double CLUSTER_TOLERANCE = 0.05;
  // v41.1: edge pulses (first and last in the list) use a tighter
  // tolerance. Phantoms have a structural reason to appear at edges:
  // the mount necessarily precedes all real reps; walking/dismount
  // necessarily follows all real reps. Pulses in the middle of the
  // list are by definition surrounded by real reps and unlikely to
  // be phantoms. So we don't change the general tolerance (no risk
  // to real reps mid-set), but we ask edge pulses to be more
  // unambiguously inside the cluster.
  //
  // v42.1: edge tolerance tightened from 0.03 → 0.025. On occasional
  // runs, ML Kit's per-image inference non-determinism on iOS (Neural
  // Engine/GPU/CPU routing produces ±1-2° joint-angle variance) was
  // pushing borderline walking-phantom distances above the 0.03 cutoff
  // on some runs and below it on others. Real-rep edge distances are
  // typically < 0.01 from median, so 0.025 leaves a 2.5× margin while
  // catching borderline phantoms consistently across runs.
  //
  // v43: edge check upgraded to 2D Euclidean distance over (Y, X)
  // instead of 1D Y. The X dimension is midShoulder X — invariant to
  // the dominant-arm flip that broke v38's drift filter. Walking
  // phantoms have significant X delta (user moves sideways out of the
  // bars) while real reps don't (camera & bars fixed). The 2D
  // threshold is bumped to 0.03 so that a pure-Y outlier at 0.025
  // (which might be ML Kit noise) is given benefit of doubt unless
  // accompanied by X evidence; a pulse with both Y AND X delta —
  // i.e., a real spatial outlier — is caught decisively.
  const double CLUSTER_TOLERANCE_EDGE = 0.03;

  if (pulseEvents.length >= MIN_PULSES_FOR_CLUSTER) {
    // Extract descBase values (skip nulls — shouldn't happen but defensive)
    final List<double> descBases = [];
    final List<double?> descBasesX = [];
    for (final ev in pulseEvents) {
      final v = (ev['descBaseShoulder'] as num?)?.toDouble();
      if (v != null) descBases.add(v);
      descBasesX.add((ev['descBaseX'] as num?)?.toDouble());
    }

    if (descBases.length == pulseEvents.length && descBases.isNotEmpty) {
      // Median of Y
      final sortedDb = List<double>.from(descBases)..sort();
      final double median = sortedDb[sortedDb.length ~/ 2];

      // Median of X (for edge 2D check). Use the X values that exist;
      // if X is missing on any pulse, fall back to Y-only edge check
      // for that specific pulse.
      final List<double> xVals = descBasesX.whereType<double>().toList();
      double? medianX;
      if (xVals.isNotEmpty) {
        xVals.sort();
        medianX = xVals[xVals.length ~/ 2];
      }

      // Identify which to keep — edge pulses (first/last) use a
      // tighter, 2D-Euclidean check; middle pulses use 1D Y.
      final List<int> keepIndices = [];
      final int lastIdx = pulseEvents.length - 1;
      for (int i = 0; i < pulseEvents.length; i++) {
        final bool isEdge = (i == 0 || i == lastIdx);
        if (isEdge) {
          final double dy = descBases[i] - median;
          final double? dxRaw = (descBasesX[i] != null && medianX != null)
              ? (descBasesX[i]! - medianX)
              : null;
          final double dist =
              dxRaw == null ? dy.abs() : math.sqrt(dy * dy + dxRaw * dxRaw);
          if (dist <= CLUSTER_TOLERANCE_EDGE) {
            keepIndices.add(i);
          }
        } else {
          if ((descBases[i] - median).abs() <= CLUSTER_TOLERANCE) {
            keepIndices.add(i);
          }
        }
      }

      // Only rebuild if we actually dropped something
      if (keepIndices.length != pulseEvents.length) {
        final List<Map<String, dynamic>> newPulses = [];
        final List<Map<String, dynamic>> newReports = [];

        for (int newIdx = 0; newIdx < keepIndices.length; newIdx++) {
          final int origIdx = keepIndices[newIdx];
          final origPulse = pulseEvents[origIdx];
          final int origReportIdx = (origPulse['newRepCount'] as int) - 1;

          // Re-sequence rep numbering
          final newPulse = Map<String, dynamic>.from(origPulse);
          newPulse['prevRepCount'] = newIdx;
          newPulse['newRepCount'] = newIdx + 1;
          newPulses.add(newPulse);

          if (origReportIdx >= 0 && origReportIdx < repReports.length) {
            final newReport =
                Map<String, dynamic>.from(repReports[origReportIdx]);
            newReport['rep_index'] = newIdx + 1;
            newReports.add(newReport);
          }
        }

        pulseEvents
          ..clear()
          ..addAll(newPulses);
        repReports
          ..clear()
          ..addAll(newReports);
        allScores.clear();
        for (final r in newReports) {
          allScores.add((r['score'] as num).toDouble());
        }
        repCount = newPulses.length;

        // Recount form errors from surviving reports.
        // (Counters were accumulated during the loop including dropped
        // pulses — recompute from scratch on the survivor set.)
        depthFailCount = 0;
        leanFailCount = 0;
        for (final report in repReports) {
          final meas = report['measurements'] as Map?;
          if (meas == null) continue;
          final be = (meas['bottom_elbow_angle'] as num?)?.toDouble();
          final ml = (meas['torso_lean'] as num?)?.toDouble();
          if (be != null && be > DEPTH_FAIL_ANGLE) depthFailCount += 1;
          if (ml != null && ml > LEAN_FAIL_DEG) leanFailCount += 1;
        }
        // Re-evaluate session form errors for depth/lean (lockout is
        // handled by the existing post-process below based on peak elbow).
        sessionFormErrors.remove(FB_DEEPER);
        sessionFormErrors.remove(FB_LEAN);
        if (depthFailCount >= DEPTH_FAIL_MIN_REPS) {
          sessionFormErrors.add(FB_DEEPER);
        }
        if (leanFailCount >= LEAN_FAIL_MIN_REPS) {
          sessionFormErrors.add(FB_LEAN);
        }
        // Re-evaluate per-pulse reasons (the live-loop reasons may have
        // been added before form errors actually crossed the threshold)
        for (int p = 0; p < pulseEvents.length; p++) {
          if (p >= repReports.length) continue;
          final meas = repReports[p]['measurements'] as Map?;
          final List<String> newReasons = [];
          if (meas != null) {
            final be = (meas['bottom_elbow_angle'] as num?)?.toDouble();
            final ml = (meas['torso_lean'] as num?)?.toDouble();
            if (be != null &&
                be > DEPTH_FAIL_ANGLE &&
                sessionFormErrors.contains(FB_DEEPER)) {
              newReasons.add(FB_DEEPER);
            }
            if (ml != null &&
                ml > LEAN_FAIL_DEG &&
                sessionFormErrors.contains(FB_LEAN)) {
              newReasons.add(FB_LEAN);
            }
          }
          pulseEvents[p]['reasons'] = newReasons;
        }

        // Frame counter values from during the loop now include dropped
        // pulses — wipe to zero. The existing post-process below sets
        // [bottom, peak-1] of each surviving pulse, and a final pass
        // (5c) sets [peak, end] for each pulse.
        for (final f in frameTelemetry) {
          f['reps'] = 0;
        }
      }
    }
  }

  // ============================================================
  // 5b) Post-process: visual peak placement + lockout check
  //
  // Counting is done. For each pulse event, find the actual visual
  // peak (frame with lowest shoulderY = body highest = "top of dip"
  // moment in user-perceptible terms) within a lookahead window from
  // the bottom. Place rep_just_finished there. Read elbow angle at
  // peak for lockout decision.
  //
  // Also rewrite the per-frame "reps" displayed count so that
  // bottom→peak shows the OLD count (counter visually ticks at the
  // peak, even though counting was decided at the bottom).
  // ============================================================
  // MAX_PEAK_LOOKAHEAD is fps-derived to preserve 2s meaning.
  final int MAX_PEAK_LOOKAHEAD = math.max(20, (2.0 * fps).round());

  // First clear any stray rep_just_finished from the loop
  for (final f in frameTelemetry) {
    f['rep_just_finished'] = null;
  }

  for (int e = 0; e < pulseEvents.length; e++) {
    final ev = pulseEvents[e];
    final int bottomIdx = (ev['bottomFrameIdx'] as int) - 1;
    if (bottomIdx < 0 || bottomIdx >= frameTelemetry.length) continue;

    final int nextBottomIdx = e + 1 < pulseEvents.length
        ? (pulseEvents[e + 1]['bottomFrameIdx'] as int) - 1
        : frameTelemetry.length;
    final int windowEnd = math.min(
      frameTelemetry.length,
      math.min(nextBottomIdx, bottomIdx + MAX_PEAK_LOOKAHEAD),
    );

    // Find peak: lowest shoulderY in window
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

    // Read elbow at peak (±2 frames, agreement check)
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
        // Fallback: median in window
        final List<double> vals = [];
        for (int i = lo; i <= hi; i++) {
          if (i < rawElbowMaxByFrame.length) vals.add(rawElbowMaxByFrame[i]);
        }
        if (vals.isNotEmpty) {
          vals.sort();
          peakElbow = vals[vals.length ~/ 2];
        }
      }
    }

    ev['peakIdx'] = peakIdx;
    ev['peakElbow'] = peakElbow;

    // Lockout check at peak
    bool missedLockout = false;
    if (peakElbow > 0.0 && peakElbow < LOCKOUT_FAIL_ANGLE) {
      lockoutFailCount += 1;
      missedLockout = true;
    }
    ev['missedLockout'] = missedLockout;

    // Counter rewrite: bottom..peak-1 shows old count
    final int prevRC = (ev['prevRepCount'] as int?) ?? 0;
    for (int i = bottomIdx; i < peakIdx; i++) {
      frameTelemetry[i]['reps'] = prevRC;
    }

    // Update rep report with the real top elbow
    if (peakElbow > 0.0 && (ev['newRepCount'] as int) - 1 < repReports.length) {
      final repIdx = (ev['newRepCount'] as int) - 1;
      final meas = repReports[repIdx]['measurements'] as Map?;
      if (meas != null) meas['top_elbow_angle'] = peakElbow;

      // Recompute lockout score with the real value
      final dets = repReports[repIdx]['detailed_scores'] as Map?;
      if (dets != null) {
        double lockoutScore = 10.0;
        if (peakElbow >= LOCKOUT_EXCELLENT) {
          lockoutScore = 10.0;
        } else if (peakElbow >= LOCKOUT_GOOD) {
          lockoutScore = 9.0;
        } else if (peakElbow >= LOCKOUT_FAIR) {
          lockoutScore = 7.5;
        } else if (peakElbow >= LOCKOUT_POOR) {
          lockoutScore = 5.0;
        } else {
          lockoutScore = 3.0;
        }
        dets['lockout'] = lockoutScore;

        // Recompute composite rep score
        final dep = (dets['depth'] as num?)?.toDouble() ?? 10.0;
        final lean = (dets['lean'] as num?)?.toDouble() ?? 10.0;
        double repScore = dep * 0.45 + lockoutScore * 0.35 + lean * 0.20;
        repScore = (repScore * 2).round() / 2.0;
        repReports[repIdx]['score'] = repScore;
        repReports[repIdx]['good'] = repScore >= 9.0;
      }
    }
  }

  // v41: 5c — Rewrite frameTelemetry['reps'] [peak, end] for each pulse.
  // The existing post-process above sets [bottom, peak-1] = prevRC for
  // each pulse. After clustering may have wiped reps to 0 (in 5a), we
  // also need [peak, end] = newRC. Each pulse overrides later frames;
  // because pulses are in chronological order, the last pulse's value
  // persists to end-of-video. Costs ~O(pulses × frames) — negligible.
  for (final ev in pulseEvents) {
    final int? peakIdx = ev['peakIdx'] as int?;
    final int? newRC = (ev['newRepCount'] as num?)?.toInt();
    if (peakIdx == null || newRC == null) continue;
    for (int j = peakIdx; j < frameTelemetry.length; j++) {
      frameTelemetry[j]['reps'] = newRC;
    }
  }

  // Decide session-level lockout error
  if (lockoutFailCount >= LOCKOUT_FAIL_MIN_REPS) {
    sessionFormErrors.add(FB_LOCKOUT);
  }

  // Recompute allScores from updated repReports for the session average
  allScores.clear();
  for (final r in repReports) {
    allScores.add((r['score'] as num).toDouble());
  }

  // Place rep_just_finished at peak + feedback in display windows
  final int holdFramesMedium = math.max(1, (1.0 * fps).round());
  final int holdFramesLong = math.max(1, (1.5 * fps).round());

  final List<List<String>> finalFbsByFrame =
      List<List<String>>.generate(frameTelemetry.length, (_) => <String>[]);

  void addFb(int startIdx, int endIdx, String fb) {
    final int s = math.max(0, startIdx);
    final int e = math.min(frameTelemetry.length - 1, endIdx);
    for (int i = s; i <= e; i++) {
      if (!finalFbsByFrame[i].contains(fb)) {
        finalFbsByFrame[i].add(fb);
      }
    }
  }

  // Re-tally goodReps/badReps now that we know final session errors
  // and the lockout decision.
  goodReps = 0;
  badReps = 0;

  for (int e = 0; e < pulseEvents.length; e++) {
    final ev = pulseEvents[e];
    final int peakIdx = (ev['peakIdx'] as int?) ?? -1;
    final int bottomIdx = (ev['bottomFrameIdx'] as int) - 1;
    if (peakIdx < 0 || peakIdx >= frameTelemetry.length) continue;

    final List<String> reasons =
        (ev['reasons'] as List?)?.cast<String>() ?? <String>[];
    final bool missedLockout = (ev['missedLockout'] as bool?) ?? false;

    bool isBad = false;

    // Lockout: show at peak
    if (missedLockout && sessionFormErrors.contains(FB_LOCKOUT)) {
      addFb(peakIdx, peakIdx + holdFramesLong, FB_LOCKOUT);
      isBad = true;
    }

    // Other reasons (depth, lean) shown around the bottom
    for (final r in reasons) {
      if (r == FB_LEAN && sessionFormErrors.contains(FB_LEAN)) {
        addFb(bottomIdx, peakIdx, FB_LEAN);
        isBad = true;
      } else if (sessionFormErrors.contains(r)) {
        addFb(bottomIdx, bottomIdx + holdFramesMedium, r);
        isBad = true;
      }
    }

    frameTelemetry[peakIdx]['rep_just_finished'] = isBad ? 'bad' : 'good';
    if (isBad) {
      badReps += 1;
    } else {
      goodReps += 1;
    }
  }

  // Apply feedback strings to telemetry
  for (int i = 0; i < frameTelemetry.length; i++) {
    final List<String> fbs = finalFbsByFrame[i];
    frameTelemetry[i]['feedback'] = fbs.isEmpty ? null : fbs.join('\n');
  }

  // ================ 6) Aggregate session score ================
  double techniqueScore;
  if (repCount == 0) {
    techniqueScore = 0.0;
  } else {
    double penalty = 0.0;
    if (sessionFormErrors.isNotEmpty) {
      for (final m in sessionFormErrors) {
        penalty += FB_WEIGHTS[m] ?? FB_DEFAULT_WEIGHT;
      }
      penalty = math.max(PENALTY_MIN_IF_ANY, penalty);
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

  if (sessionFormErrors.isEmpty && repCount > 0) {
    techniqueScore = 10.0;
  }

  final List<String> formErrorsList =
      FB_PRIORITY.where((err) => sessionFormErrors.contains(err)).toList();

  final List<String> feedbackList;
  if (repCount == 0) {
    feedbackList = <String>[
      "Couldn't analyze this video — make sure your full body is visible from the side on the dips bars."
    ];
  } else if (formErrorsList.isNotEmpty) {
    feedbackList = formErrorsList;
  } else {
    feedbackList = <String>['Great form! Keep it up 💪'];
  }

  String? sessionTip;
  if (repCount == 0) {
    sessionTip = null;
  } else if (formErrorsList.isEmpty) {
    // v42: No form error fired (session is Excellent). Surface a
    // "next step" tip. If the user is consistently descending well
    // past parallel, nudge toward standard depth; otherwise default
    // to the pause-at-bottom progression tip. Never null when there
    // are reps — the UI expects something here.
    int extremeDepthReps = 0;
    for (final r in repReports) {
      final meas = r['measurements'] as Map?;
      final be = (meas?['bottom_elbow_angle'] as num?)?.toDouble();
      if (be != null && be < EXTREME_DEPTH_ANGLE) extremeDepthReps += 1;
    }
    sessionTip =
        (extremeDepthReps >= EXTREME_DEPTH_MIN_REPS) ? TIP_PARALLEL : TIP_PAUSE;
  } else {
    sessionTip = formErrorsList.first;
  }

  print('🟢 DIPS v47.2: detected $repCount reps '
      '(good=$goodReps, bad=$badReps, '
      'formErrors=${formErrorsList.join(",")})');

  final String fileUri = 'file://$videoPath';

  return {
    'squat_count': repCount,
    'technique_score': techniqueScore,
    'technique_score_display': displayHalfStr(techniqueScore),
    'technique_label': scoreLabel(techniqueScore),
    'good_reps': goodReps,
    'bad_reps': badReps,
    'feedback': feedbackList,
    'tip': sessionTip,
    'form_tip': sessionTip,
    'tips': sessionTip != null ? <String>[sessionTip] : <String>[],
    'reps': repReports,
    'exercise_type': 'dips',
    'video_path': fileUri,
    'analyzed_fps': fps,
    'frame_count': frameIdx,
    'active_leg': 'both',
    '_source_video_uri': fileUri,
    '_frame_telemetry': frameTelemetry,
  };
}

// ---- dimension probe cache ----
double _dipsCachedW = -1;
double _dipsCachedH = -1;

Future<(int, int)> _dipsProbeImageDims(String path) async {
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
