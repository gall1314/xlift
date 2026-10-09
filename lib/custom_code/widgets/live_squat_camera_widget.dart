// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// ============================================================================
// LIVE SQUAT CAMERA WIDGET
// ============================================================================
//
// Real-time squat coaching using ML Kit Pose Detection in stream mode with
// the LITE model (fast, lower accuracy — fine for live-feedback quality).
//
// Pipeline:
//   Camera → CameraImage stream → InputImage → ML Kit PoseDetector (stream
//   mode, base model) → 33 landmarks → EMA smoother → live rep state machine
//   → UI repaint + audio/haptic on rep completion.
//
// Architectural notes:
//   - Frame dropping: ML Kit on stream mode is fast (~30-60ms per frame on
//     a modern iPhone with the Lite model) but the camera fires at 30fps.
//     We drop incoming frames while a previous frame is in flight, which
//     gives us roughly 15-25 fps of actual analysis with zero queueing.
//     No backlog ever forms; the latency stays bounded.
//
//   - Smoothing: Savitzky-Golay (used in the offline pipeline) is impossible
//     here because it requires the full sequence. Instead we use a per-
//     landmark EMA filter, which is causal (only depends on past frames)
//     and adds <1 frame of lag. This is the standard live-pose approach.
//
//   - Rep detection: same state machine as offline (down/up, knee angle
//     thresholds, soft-start velocity gate), but without unrack retroactive
//     rejection (impossible without the full sequence). To compensate, we
//     add a brief "warmup" period after Start where we run detection but
//     don't count reps, letting the user get into position without the
//     bar-pickup motion triggering a phantom rep.
//
//   - State exposed at session end: the widget builds up a result map in
//     the same shape as the post-analysis action returns, so any existing
//     downstream UI (rep details page, score widgets, save-to-DB action)
//     can consume it without changes. The `_engine` field is set to
//     'live_mlkit' so analytics can distinguish live vs post sessions.
//
// External contract for FlutterFlow:
//   - Widget parameters: width, height, onSessionComplete (Future Function(),
//     no arguments), useFrontCamera (bool), videoVolume (double),
//     showDebugOverlay (bool).
//   - When the user taps STOP, the widget writes the session result map to
//     LiveSquatSessionResult.latest (a static global) and THEN fires
//     onSessionComplete with no arguments. To read the result inside the
//     action chain, either:
//       a. Read the global directly from a Custom Action / Custom Function:
//            return LiveSquatSessionResult.latest;  // returns Map / JSON
//       b. Or just navigate / update app state in the action chain — the
//          result is also already saved to App State by a Custom Action
//          that reads it from the global.
//
// Permissions:
//   - iOS: NSCameraUsageDescription in Info.plist
//   - Android: android.permission.CAMERA in AndroidManifest.xml
//   (FlutterFlow has UI for both — see widget setup notes at bottom.)
//
// Dependencies (pubspec.yaml):
//   - camera: ^0.10.5+9 (or newer) — REQUIRED, must add to project
//   - google_mlkit_pose_detection (already in project)
//   - audioplayers (already in project)
// ============================================================================

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui show TextDirection;

import 'package:flutter/services.dart'; // HapticFeedback
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// ============================================================================
// =========================== TUNABLE PARAMETERS =============================
// ============================================================================
class LiveTuningParams {
  // ---------------------- EMA SMOOTHING ----------------------
  // Higher = more reactive but noisier. 0.5 is a typical sweet spot for
  // 15-25 fps live pose: tracks movement closely without obvious jitter.
  static const double EMA_LANDMARK_ALPHA = 0.5;

  // ---------------------- VISIBILITY ----------------------
  // ML Kit `base` (Lite) outputs landmark "likelihood" scores from 0..1.
  // We hide landmarks below this for skeleton drawing.
  static const double DRAW_VIS_THRESHOLD = 0.45;
  // For analysis (rep detection), require the core landmarks (hips, knees,
  // ankles, shoulders) to average above this. Set lower than draw threshold
  // because we want to keep counting even when some occluded landmarks dip.
  static const double CORE_VIS_THRESHOLD = 0.35;

  // ---------------------- WARMUP ----------------------
  // After tapping Start, we run pose detection but suppress rep counting
  // for this long. Lets the user get into setup position without an unrack
  // motion being counted as rep 1.
  static const double WARMUP_SECONDS = 2.0;

  // ---------------------- REP DETECTION ----------------------
  // Same thresholds as the offline analyzer — proven values.
  static const double STAND_KNEE_ANGLE = 155.0;
  static const double REP_START_KNEE_ANGLE = 125.0;
  static const double REP_FINISH_KNEE_MARGIN = 6.0;
  static const double REP_FINISH_DEPTH_MAX = 0.20;
  static const int MIN_MS_BETWEEN_REPS = 600;
  static const int MIN_REP_DURATION_MS = 500;

  // ---------------------- MOVEMENT VELOCITY GATE ----------------------
  // Squat-start gate: don't start a "down" stage while the body is still
  // visibly moving sideways (e.g. walking toward the rack).
  static const double HIP_VEL_THRESH_PCT = 0.025;
  static const double ANKLE_VEL_THRESH_PCT = 0.030;
  static const double VEL_EMA_ALPHA = 0.6;
  static const double SOFT_START_MARGIN = 1.5;

  // ---------------------- DEPTH SCORING THRESHOLDS ----------------------
  // Same as offline. The depth_pct is what drives the depth ring in the UI
  // and feeds into per-rep grading.
  static const double DEPTH_GOOD_THRESHOLD = 0.96;
  static const double DEPTH_ALMOST_THRESHOLD = 0.85;
  static const double DEPTH_FAIR_THRESHOLD = 0.70;
  static const double MIN_DEPTH_FOR_REP = 0.12;

  // ---------------------- REP SCORE ----------------------
  static const double PENALTY_DEPTH_SEVERE = 3.0;
  static const double PENALTY_DEPTH_MODERATE = 2.0;
  static const double PENALTY_DEPTH_MINOR = 1.0;
  static const double MIN_REP_SCORE = 4.0;
  static const double MAX_IMPERFECT_SCORE = 9.5;
  static const double PERFECT_SCORE = 10.0;

  // ---------------------- LIVE FEEDBACK DISPLAY ----------------------
  // How long a feedback message stays on screen after it's triggered.
  static const int FEEDBACK_HOLD_MS = 1500;
}
// ============================================================================

// ============================================================================
// BlazePose 33-landmark indices, same as the offline analyzer.
// ============================================================================
const int _IDX_NOSE = 0;
const int _IDX_L_SHOULDER = 11;
const int _IDX_R_SHOULDER = 12;
const int _IDX_L_ELBOW = 13;
const int _IDX_R_ELBOW = 14;
const int _IDX_L_WRIST = 15;
const int _IDX_R_WRIST = 16;
const int _IDX_L_HIP = 23;
const int _IDX_R_HIP = 24;
const int _IDX_L_KNEE = 25;
const int _IDX_R_KNEE = 26;
const int _IDX_L_ANKLE = 27;
const int _IDX_R_ANKLE = 28;
const int _IDX_L_HEEL = 29;
const int _IDX_R_HEEL = 30;
const int _IDX_L_FOOT = 31;
const int _IDX_R_FOOT = 32;

const List<PoseLandmarkType> _LM_ORDER = [
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

// ============================================================================
// Math helpers — same formulas as the offline analyzer.
// ============================================================================
double _angleAt(List<double> a, List<double> b, List<double> c) {
  final double rad = math.atan2(c[1] - b[1], c[0] - b[0]) -
      math.atan2(a[1] - b[1], a[0] - b[0]);
  double ang = (rad * 180.0 / math.pi).abs();
  if (ang > 180) ang = 360 - ang;
  return ang;
}

double _euclid(List<double> a, List<double> b) {
  final dx = a[0] - b[0];
  final dy = a[1] - b[1];
  return math.sqrt(dx * dx + dy * dy);
}

// Compute depth percentage. Same robust formula as the offline analyzer.
double _calculateDepthRobust(
    List<double> midHip, List<double> midKnee, double kneeAngle) {
  final double hipBelowKnee = midHip[1] - midKnee[1];
  final double thighLength = math.max(1e-6, _euclid(midHip, midKnee));
  final double normalizedDepth = hipBelowKnee / thighLength;

  double depthScore;
  if (normalizedDepth >= 0.0) {
    depthScore = 1.0;
  } else if (normalizedDepth >= -0.20) {
    depthScore = 0.80 + ((normalizedDepth + 0.20) / 0.20) * 0.20;
  } else if (normalizedDepth >= -0.40) {
    depthScore = 0.55 + ((normalizedDepth + 0.40) / 0.20) * 0.25;
  } else if (normalizedDepth >= -0.60) {
    depthScore = 0.30 + ((normalizedDepth + 0.60) / 0.20) * 0.25;
  } else {
    depthScore = math.max(0.0, 0.30 * (1.0 + (normalizedDepth + 0.60) / 0.40));
  }

  if (kneeAngle >= 120) {
    depthScore = math.max(0.0, depthScore - 0.35);
  } else if (kneeAngle >= 110) {
    depthScore = math.max(0.0, depthScore - 0.25);
  } else if (kneeAngle >= 100) {
    depthScore = math.max(0.0, depthScore - 0.15);
  } else if (kneeAngle <= 80) {
    depthScore = math.min(1.0, depthScore + 0.10);
  } else if (kneeAngle <= 90) {
    depthScore = math.min(1.0, depthScore + 0.05);
  }

  if (depthScore < 0) depthScore = 0;
  if (depthScore > 1) depthScore = 1;
  return depthScore;
}

// ============================================================================
// EMA smoother — per-landmark exponential moving average.
//
// Maintains a smoothed (x, y) per landmark across frames. When visibility
// drops, the smoothed position stays at the last good value (no jump to
// zero), which keeps the skeleton stable when ML Kit briefly loses a joint.
//
// Visibility values themselves are NOT smoothed — they pass through raw —
// because the visibility filter downstream needs to react instantly when
// a landmark legitimately leaves the frame.
// ============================================================================
class _EmaLandmarkSmoother {
  static const int _NUM_LANDMARKS = 33;
  final List<List<double>?> _state = List.filled(_NUM_LANDMARKS, null);
  final double alpha;

  _EmaLandmarkSmoother({this.alpha = LiveTuningParams.EMA_LANDMARK_ALPHA});

  /// Feed a raw frame and get back the smoothed version.
  /// Input/output: List of [x, y, visibility] per landmark, normalized 0..1.
  List<List<double>> smooth(List<List<double>> raw) {
    final out = List<List<double>>.generate(_NUM_LANDMARKS, (i) {
      if (i >= raw.length) {
        return _state[i] != null
            ? [_state[i]![0], _state[i]![1], 0.0]
            : [0.0, 0.0, 0.0];
      }
      final r = raw[i];
      if (r.length < 3) {
        return _state[i] != null
            ? [_state[i]![0], _state[i]![1], 0.0]
            : [0.0, 0.0, 0.0];
      }
      final double vis = r[2];

      // First time we see a credible value for this landmark, seed directly.
      if (_state[i] == null) {
        if (vis >= LiveTuningParams.DRAW_VIS_THRESHOLD) {
          _state[i] = [r[0], r[1]];
          return [r[0], r[1], vis];
        }
        return [0.0, 0.0, vis];
      }

      // Already have a smoothed position. If visibility is solid, advance.
      // If visibility is bad, hold the last smoothed position (no jumps).
      if (vis >= LiveTuningParams.DRAW_VIS_THRESHOLD) {
        _state[i]![0] = alpha * r[0] + (1 - alpha) * _state[i]![0];
        _state[i]![1] = alpha * r[1] + (1 - alpha) * _state[i]![1];
      }
      return [_state[i]![0], _state[i]![1], vis];
    });
    return out;
  }

  void reset() {
    for (int i = 0; i < _NUM_LANDMARKS; i++) {
      _state[i] = null;
    }
  }
}

// ============================================================================
// Live rep state machine.
//
// Same state diagram as the offline analyzer, but driven by elapsed wall-
// clock time (since the camera rate isn't exactly the FPS we declared) and
// without retroactive corrections.
//
// State per rep being analyzed:
//   - startKneeAngle: knee angle at the moment we entered 'down'
//   - minKneeAngle, maxDepth: maxima during the rep
//   - startTimestamp: when we entered 'down' (for duration check)
//   - hipVelEma, ankleVelEma: smoothed velocities (drives soft-start gate)
// ============================================================================
class _LiveRepReport {
  final int index;
  final double score;
  final List<String> feedback;
  final double depthPct;
  final double minKneeAngle;
  final int durationMs;
  _LiveRepReport({
    required this.index,
    required this.score,
    required this.feedback,
    required this.depthPct,
    required this.minKneeAngle,
    required this.durationMs,
  });

  Map<String, dynamic> toMap() => {
        'rep_index': index,
        'score': double.parse(score.toStringAsFixed(1)),
        'score_display': _displayHalfStr(score),
        'feedback': feedback,
        'tip': null,
        'depth_pct': depthPct,
        'min_knee_angle': double.parse(minKneeAngle.toStringAsFixed(2)),
        'duration_ms': durationMs,
      };
}

String _displayHalfStr(double x) {
  final double q = (x * 2).round() / 2.0;
  if ((q - q.round()).abs() < 1e-9) return q.round().toString();
  return q.toStringAsFixed(1);
}

class _LiveRepStateMachine {
  // ---- session-level totals ----
  int repCounter = 0;
  int goodReps = 0;
  int badReps = 0;
  final List<_LiveRepReport> repReports = [];
  String? lastRepFinished; // 'good' or 'bad', cleared after consumption
  DateTime _lastRepCompletedAt = DateTime.fromMillisecondsSinceEpoch(0);

  // ---- current rep tracking ----
  String _stage = 'up'; // 'up' | 'down'
  double? _startKneeAngle;
  double _minKneeAngle = 180.0;
  double _maxDepth = 0.0;
  DateTime? _repStartTime;

  // ---- velocity tracking (frame-to-frame, used for soft-start gate) ----
  List<double>? _prevHipPx;
  List<double>? _prevLAnklePx;
  List<double>? _prevRAnklePx;
  double _hipVelEma = 0.0;
  double _ankleVelEma = 0.0;

  // ---- realtime UI feedback ----
  // Current depth display value (0-1) — fed to the depth ring on every frame.
  double currentDepthDisplay = 0.0;
  // Current ephemeral feedback message ('Try to squat deeper', etc).
  String? currentFeedback;
  DateTime? _feedbackSetAt;

  String get stage => _stage;

  void reset() {
    repCounter = 0;
    goodReps = 0;
    badReps = 0;
    repReports.clear();
    lastRepFinished = null;
    _stage = 'up';
    _startKneeAngle = null;
    _minKneeAngle = 180.0;
    _maxDepth = 0.0;
    _repStartTime = null;
    _prevHipPx = null;
    _prevLAnklePx = null;
    _prevRAnklePx = null;
    _hipVelEma = 0.0;
    _ankleVelEma = 0.0;
    currentDepthDisplay = 0.0;
    currentFeedback = null;
    _feedbackSetAt = null;
  }

  void _setFeedback(String msg) {
    currentFeedback = msg;
    _feedbackSetAt = DateTime.now();
  }

  void _maybeExpireFeedback() {
    if (currentFeedback == null || _feedbackSetAt == null) return;
    final ageMs = DateTime.now().difference(_feedbackSetAt!).inMilliseconds;
    if (ageMs > LiveTuningParams.FEEDBACK_HOLD_MS) {
      currentFeedback = null;
      _feedbackSetAt = null;
    }
  }

  /// Process one smoothed frame. Returns true if a rep was just completed.
  ///
  /// `landmarks` are smoothed 33-point [x, y, vis] in 0..1 image coords.
  /// `imageW, imageH` are the source image dimensions for velocity scaling.
  /// `inWarmup` suppresses rep counting (but still updates state) during
  /// the initial warmup period after Start.
  bool processFrame({
    required List<List<double>> landmarks,
    required double imageW,
    required double imageH,
    required bool inWarmup,
  }) {
    _maybeExpireFeedback();

    if (landmarks.length < 33) {
      currentDepthDisplay = 0.0;
      return false;
    }

    // Pull the joints we need.
    final hip = [landmarks[_IDX_R_HIP][0], landmarks[_IDX_R_HIP][1]];
    final knee = [landmarks[_IDX_R_KNEE][0], landmarks[_IDX_R_KNEE][1]];
    final ankle = [landmarks[_IDX_R_ANKLE][0], landmarks[_IDX_R_ANKLE][1]];
    final lHip = [landmarks[_IDX_L_HIP][0], landmarks[_IDX_L_HIP][1]];
    final lKnee = [landmarks[_IDX_L_KNEE][0], landmarks[_IDX_L_KNEE][1]];
    final lAnkle = [landmarks[_IDX_L_ANKLE][0], landmarks[_IDX_L_ANKLE][1]];

    // Quick visibility check on core points.
    final double coreVisMean = (landmarks[_IDX_R_HIP][2] +
            landmarks[_IDX_L_HIP][2] +
            landmarks[_IDX_R_KNEE][2] +
            landmarks[_IDX_L_KNEE][2] +
            landmarks[_IDX_R_ANKLE][2] +
            landmarks[_IDX_L_ANKLE][2]) /
        6.0;
    if (coreVisMean < LiveTuningParams.CORE_VIS_THRESHOLD) {
      // Don't trust this frame for rep logic; still update depth display
      // optimistically so the ring doesn't freeze at 0.
      return false;
    }

    final midHip = [(hip[0] + lHip[0]) / 2, (hip[1] + lHip[1]) / 2];
    final midKnee = [(knee[0] + lKnee[0]) / 2, (knee[1] + lKnee[1]) / 2];

    // Compute velocities in pixels (so the thresholds are screen-relative).
    final hipPx = [hip[0] * imageW, hip[1] * imageH];
    final lAnklePx = [lAnkle[0] * imageW, lAnkle[1] * imageH];
    final rAnklePx = [ankle[0] * imageW, ankle[1] * imageH];

    _prevHipPx ??= hipPx;
    _prevLAnklePx ??= lAnklePx;
    _prevRAnklePx ??= rAnklePx;

    double dNorm(List<double> a, List<double> b) {
      final dx = a[0] - b[0];
      final dy = a[1] - b[1];
      return math.sqrt(dx * dx + dy * dy) / math.max(imageW, imageH);
    }

    final hipVel = dNorm(hipPx, _prevHipPx!);
    final anVel = math.max(
        dNorm(lAnklePx, _prevLAnklePx!), dNorm(rAnklePx, _prevRAnklePx!));
    _hipVelEma = LiveTuningParams.VEL_EMA_ALPHA * hipVel +
        (1 - LiveTuningParams.VEL_EMA_ALPHA) * _hipVelEma;
    _ankleVelEma = LiveTuningParams.VEL_EMA_ALPHA * anVel +
        (1 - LiveTuningParams.VEL_EMA_ALPHA) * _ankleVelEma;
    _prevHipPx = hipPx;
    _prevLAnklePx = lAnklePx;
    _prevRAnklePx = rAnklePx;

    final double kneeAngle = _angleAt(hip, knee, ankle);
    final double depth = _calculateDepthRobust(midHip, midKnee, kneeAngle);
    currentDepthDisplay = depth;

    final bool softStartOk = (_hipVelEma <
            LiveTuningParams.HIP_VEL_THRESH_PCT *
                LiveTuningParams.SOFT_START_MARGIN) &&
        (_ankleVelEma <
            LiveTuningParams.ANKLE_VEL_THRESH_PCT *
                LiveTuningParams.SOFT_START_MARGIN);

    // Transition: up → down
    if (_stage == 'up' &&
        kneeAngle < LiveTuningParams.REP_START_KNEE_ANGLE &&
        softStartOk) {
      _stage = 'down';
      _startKneeAngle = kneeAngle;
      _minKneeAngle = kneeAngle;
      _maxDepth = depth;
      _repStartTime = DateTime.now();
    }

    if (_stage == 'down') {
      if (kneeAngle < _minKneeAngle) _minKneeAngle = kneeAngle;
      if (depth > _maxDepth) _maxDepth = depth;
    }

    // Transition: down → up (rep completed)
    final bool postureFinished =
        kneeAngle > LiveTuningParams.STAND_KNEE_ANGLE ||
            (kneeAngle >
                    LiveTuningParams.STAND_KNEE_ANGLE -
                        LiveTuningParams.REP_FINISH_KNEE_MARGIN &&
                depth <= LiveTuningParams.REP_FINISH_DEPTH_MAX);
    if (_stage == 'down' && postureFinished) {
      final int durationMs = _repStartTime == null
          ? 0
          : DateTime.now().difference(_repStartTime!).inMilliseconds;
      final bool durationOk =
          durationMs >= LiveTuningParams.MIN_REP_DURATION_MS;
      final int sinceLastMs =
          DateTime.now().difference(_lastRepCompletedAt).inMilliseconds;
      final bool gapOk = sinceLastMs >= LiveTuningParams.MIN_MS_BETWEEN_REPS;
      final bool deepEnough = _maxDepth >= LiveTuningParams.MIN_DEPTH_FOR_REP;

      final bool repValid = durationOk && gapOk && deepEnough && !inWarmup;

      if (repValid) {
        _commitRep(durationMs: durationMs);
      }

      _stage = 'up';
      _startKneeAngle = null;
      _repStartTime = null;
      // Keep _maxDepth/_minKneeAngle for one more frame so the depth ring
      // doesn't snap to zero the instant the user stands up.
      Future.delayed(const Duration(milliseconds: 250), () {
        _minKneeAngle = 180.0;
        _maxDepth = 0.0;
      });
    }

    return false;
  }

  void _commitRep({required int durationMs}) {
    final double depthPct = _maxDepth;
    final List<String> feedback = [];
    double penalty = 0.0;

    if (depthPct < LiveTuningParams.DEPTH_FAIR_THRESHOLD) {
      feedback.add('Try to squat deeper');
      penalty += LiveTuningParams.PENALTY_DEPTH_SEVERE;
    } else if (depthPct < LiveTuningParams.DEPTH_ALMOST_THRESHOLD) {
      feedback.add('Almost there — go a bit lower');
      penalty += LiveTuningParams.PENALTY_DEPTH_MODERATE;
    } else if (depthPct < LiveTuningParams.DEPTH_GOOD_THRESHOLD) {
      feedback.add('Just a bit more depth');
      penalty += LiveTuningParams.PENALTY_DEPTH_MINOR;
    }

    double score;
    if (feedback.isEmpty) {
      score = LiveTuningParams.PERFECT_SCORE;
    } else {
      score = math.max(
        LiveTuningParams.MIN_REP_SCORE,
        LiveTuningParams.PERFECT_SCORE - penalty,
      );
      score = (score * 2).round() / 2.0;
      score = math.min(score, LiveTuningParams.MAX_IMPERFECT_SCORE);
    }

    final report = _LiveRepReport(
      index: repCounter + 1,
      score: score,
      feedback: feedback,
      depthPct: depthPct,
      minKneeAngle: _minKneeAngle,
      durationMs: durationMs,
    );
    repReports.add(report);
    repCounter += 1;
    _lastRepCompletedAt = DateTime.now();

    if (score >= LiveTuningParams.MAX_IMPERFECT_SCORE) {
      goodReps += 1;
      lastRepFinished = 'good';
    } else {
      badReps += 1;
      lastRepFinished = 'bad';
      if (feedback.isNotEmpty) {
        _setFeedback(feedback.first);
      }
    }
  }
}

// ============================================================================
// CameraImage → InputImage conversion. Handles Android (NV21) and iOS
// (BGRA8888) using the standard pattern from the ML Kit Flutter samples.
// ============================================================================
final Map<DeviceOrientation, int> _orientations = {
  DeviceOrientation.portraitUp: 0,
  DeviceOrientation.landscapeLeft: 90,
  DeviceOrientation.portraitDown: 180,
  DeviceOrientation.landscapeRight: 270,
};

InputImage? _inputImageFromCameraImage(
    CameraImage image, CameraController controller) {
  final camera = controller.description;
  final sensorOrientation = camera.sensorOrientation;

  InputImageRotation? rotation;
  if (Platform.isIOS) {
    rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
  } else if (Platform.isAndroid) {
    var rotationCompensation =
        _orientations[controller.value.deviceOrientation];
    if (rotationCompensation == null) return null;
    if (camera.lensDirection == CameraLensDirection.front) {
      rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
    } else {
      rotationCompensation =
          (sensorOrientation - rotationCompensation + 360) % 360;
    }
    rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
  }
  if (rotation == null) return null;

  final format = InputImageFormatValue.fromRawValue(image.format.raw);
  if (format == null) return null;
  if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
  if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;

  if (image.planes.length != 1) return null;
  final plane = image.planes.first;

  return InputImage.fromBytes(
    bytes: plane.bytes,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: plane.bytesPerRow,
    ),
  );
}

// ============================================================================
// THE WIDGET
// ============================================================================

/// Global holder for the most recent live session result.
///
/// FlutterFlow's Custom Action / Function API can pass simple types easily
/// but typed callbacks (Future Function(Map)) are awkward to wire up. To
/// avoid that friction, the widget writes the completed session into this
/// global static. Any FlutterFlow Custom Action / Function can then read
/// `LiveSquatSessionResult.latest` immediately after the widget's
/// `onSessionComplete` callback fires (which has NO parameters and is just
/// a "the session ended" signal).
///
/// Reading pattern in FlutterFlow:
///   1. Place this widget on a page.
///   2. Set onSessionComplete to an action chain that:
///      a. Calls a tiny Custom Action that does:
///           return LiveSquatSessionResult.latest;
///         (return type: JSON)
///      b. Saves the returned value to App State or pushes a new page
///         with it as a parameter.
///
/// Why static: the widget instance is destroyed when the page is popped.
/// A static holder survives navigation and is the standard pattern for
/// passing complex types between Flutter and FlutterFlow's action layer.
class LiveSquatSessionResult {
  /// The most recent session result, or null if no session has completed
  /// yet in this app run. Reset() can be called to clear it.
  static Map<String, dynamic>? latest;

  /// Clear the latest result. Call this if you want to make sure stale
  /// data from a previous session can't be read by mistake.
  static void reset() {
    latest = null;
  }
}

class LiveSquatCameraWidget extends StatefulWidget {
  const LiveSquatCameraWidget({
    Key? key,
    this.width,
    this.height,
    this.useFrontCamera = false,
    this.videoVolume = 0.5,
    this.showDebugOverlay = false,
    this.onSessionComplete,
    this.onClose,
  }) : super(key: key);

  final double? width;
  final double? height;
  // Initial camera lens — the user can flip in-widget with the flip button.
  // This parameter just controls the starting state.
  final bool useFrontCamera;
  // Volume for the rep-completion audio cues, 0..1.
  final double videoVolume;
  // Show small text overlay with FPS, detection latency, and vis scores.
  // Useful while testing; turn off for production.
  final bool showDebugOverlay;
  // Fires when the user taps STOP. NO parameters — to keep FlutterFlow
  // wiring trivial. The session result is available at
  // LiveSquatSessionResult.latest immediately when this fires.
  final Future Function()? onSessionComplete;
  // Fires when the user taps the X (close/cancel) button. The widget
  // cancels any in-progress session WITHOUT saving — that's the contract.
  // Wire this in FlutterFlow to Navigate Back (or wherever the close
  // should send the user). If null, the X button still cancels the
  // session but doesn't navigate.
  final Future Function()? onClose;

  @override
  State<LiveSquatCameraWidget> createState() => _LiveSquatCameraWidgetState();
}

class _LiveSquatCameraWidgetState extends State<LiveSquatCameraWidget> {
  // Camera & detector
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  List<CameraDescription>? _availableCameras;
  String? _errorMessage;
  bool _cameraReady = false;

  // Lens state — initialized from widget.useFrontCamera, but the user can
  // flip it at runtime via the flip button in the UI.
  late bool _useFrontCamera;
  // True while the controller is being swapped out for the other lens.
  // We ignore incoming frames during the swap to avoid feeding the
  // detector a half-initialized image stream.
  bool _isSwitchingCamera = false;

  // Session state
  bool _isActive = false; // user has tapped START
  DateTime? _sessionStartedAt;

  // Per-frame state
  bool _isProcessingFrame = false;
  List<List<double>> _currentLandmarks = const [];
  int _currentImageWidth = 0;
  int _currentImageHeight = 0;

  // Smoother & rep state machine
  final _EmaLandmarkSmoother _smoother = _EmaLandmarkSmoother();
  final _LiveRepStateMachine _repSM = _LiveRepStateMachine();

  // Debug stats (only shown when showDebugOverlay=true)
  int _framesReceived = 0;
  int _framesProcessed = 0;
  int _framesDropped = 0;
  int _lastInferenceMs = 0;
  DateTime _statsWindowStart = DateTime.now();
  double _fpsDisplay = 0.0;

  // UI repaint throttle — at most every 50ms (20 hz).
  DateTime _lastRepaintAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _REPAINT_MIN_GAP_MS = 50;

  // Audio
  final List<AudioPlayer> _goodRepPool = [];
  final List<AudioPlayer> _badRepPool = [];
  int _goodPoolIdx = 0;
  int _badPoolIdx = 0;
  static const int _AUDIO_POOL_SIZE = 3;
  String? _goodRepWorkingPath;
  String? _badRepWorkingPath;
  bool _audioReady = false;
  DateTime _lastAudioAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastHapticAt = DateTime.fromMillisecondsSinceEpoch(0);

  static const List<String> _GOOD_REP_CANDIDATES = [
    'audios/good_rep.mp3',
    'audio/good_rep.mp3',
    'good_rep.mp3',
    'assets/audios/good_rep.mp3',
    'assets/audio/good_rep.mp3',
  ];
  static const List<String> _BAD_REP_CANDIDATES = [
    'audios/bad_rep.mp3',
    'audio/bad_rep.mp3',
    'bad_rep.mp3',
    'assets/audios/bad_rep.mp3',
    'assets/audio/bad_rep.mp3',
  ];

  @override
  void initState() {
    super.initState();
    _useFrontCamera = widget.useFrontCamera;
    _initEverything();
  }

  Future<void> _initEverything() async {
    try {
      // 1) Camera setup
      _availableCameras = await availableCameras();
      if (_availableCameras == null || _availableCameras!.isEmpty) {
        setState(() => _errorMessage = 'No cameras available on this device');
        return;
      }

      final CameraDescription camera = _availableCameras!.firstWhere(
        (c) =>
            c.lensDirection ==
            (_useFrontCamera
                ? CameraLensDirection.front
                : CameraLensDirection.back),
        orElse: () => _availableCameras!.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium, // 720p, plenty for pose. Higher = slower.
        enableAudio: false,
        imageFormatGroup:
            Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      // 2) Pose detector — STREAM mode + BASE (Lite) model
      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
          model: PoseDetectionModel.base, // Lite — fast, lower accuracy
        ),
      );

      // 3) Audio
      await _initAudio();

      // 4) Start the camera image stream
      await _cameraController!.startImageStream(_onCameraImage);

      setState(() => _cameraReady = true);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Init failed: $e');
      }
    }
  }

  // ===========================================================================
  // CAMERA FLIP — front ↔ back lens switch at runtime.
  //
  // Sequence (order matters):
  //   1. Set _isSwitchingCamera = true so _onCameraImage drops in-flight frames
  //   2. Stop the image stream on the old controller
  //   3. Dispose the old controller
  //   4. Reset the smoother — the perspective is changing, old EMA state
  //      would warp the first few frames of the new lens
  //   5. Create + initialize the new controller with the other lens
  //   6. Start image stream on the new controller
  //   7. Clear the switching flag, repaint
  //
  // We DO NOT re-initialize the pose detector — it's reusable across cameras.
  // We DO NOT reset the rep state machine — if a session is in progress,
  // counted reps carry over (intended; the user just changed angle).
  // ===========================================================================
  Future<void> _toggleCamera() async {
    if (_isSwitchingCamera) return;
    if (_availableCameras == null || _availableCameras!.length < 2) return;

    setState(() {
      _isSwitchingCamera = true;
    });

    try {
      // Stop & dispose old controller.
      try {
        await _cameraController?.stopImageStream();
      } catch (_) {}
      try {
        await _cameraController?.dispose();
      } catch (_) {}
      _cameraController = null;

      // Flip lens preference.
      _useFrontCamera = !_useFrontCamera;

      // Reset smoother — new camera = new perspective.
      _smoother.reset();
      _currentLandmarks = const [];

      // Find the matching camera. Fall back to whatever's available.
      final CameraDescription camera = _availableCameras!.firstWhere(
        (c) =>
            c.lensDirection ==
            (_useFrontCamera
                ? CameraLensDirection.front
                : CameraLensDirection.back),
        orElse: () => _availableCameras!.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup:
            Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
      );
      await _cameraController!.initialize();
      if (!mounted) return;

      await _cameraController!.startImageStream(_onCameraImage);
    } catch (e) {
      // If swap fails, surface the error in the overlay rather than crash.
      if (mounted) {
        setState(() {
          _errorMessage = 'Camera flip failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSwitchingCamera = false;
        });
      }
    }
  }

  // Called by the X (close/cancel) button. Cancels any active session
  // WITHOUT firing onSessionComplete — the contract of the X button is
  // "discard this workout". Then optionally fires onClose so FlutterFlow
  // can navigate away.
  Future<void> _cancelAndClose() async {
    if (_isActive) {
      setState(() {
        _isActive = false;
      });
    }
    if (widget.onClose != null) {
      try {
        await widget.onClose!();
      } catch (e) {
        debugPrint('onClose callback threw: $e');
      }
    }
  }

  Future<void> _initAudio() async {
    for (final path in _GOOD_REP_CANDIDATES) {
      try {
        final p = AudioPlayer();
        await p.setSource(AssetSource(path));
        await p.setVolume(widget.videoVolume.clamp(0.0, 1.0));
        await p.setReleaseMode(ReleaseMode.stop);
        _goodRepPool.add(p);
        _goodRepWorkingPath = path;
        for (int i = 1; i < _AUDIO_POOL_SIZE; i++) {
          final extra = AudioPlayer();
          await extra.setSource(AssetSource(path));
          await extra.setVolume(widget.videoVolume.clamp(0.0, 1.0));
          await extra.setReleaseMode(ReleaseMode.stop);
          _goodRepPool.add(extra);
        }
        break;
      } catch (_) {}
    }
    for (final path in _BAD_REP_CANDIDATES) {
      try {
        final p = AudioPlayer();
        await p.setSource(AssetSource(path));
        await p.setVolume(widget.videoVolume.clamp(0.0, 1.0));
        await p.setReleaseMode(ReleaseMode.stop);
        _badRepPool.add(p);
        _badRepWorkingPath = path;
        for (int i = 1; i < _AUDIO_POOL_SIZE; i++) {
          final extra = AudioPlayer();
          await extra.setSource(AssetSource(path));
          await extra.setVolume(widget.videoVolume.clamp(0.0, 1.0));
          await extra.setReleaseMode(ReleaseMode.stop);
          _badRepPool.add(extra);
        }
        break;
      } catch (_) {}
    }
    _audioReady = _goodRepPool.isNotEmpty || _badRepPool.isNotEmpty;
  }

  void _onCameraImage(CameraImage image) {
    _framesReceived += 1;

    // Drop frames during a camera lens swap — the controller is being
    // replaced and feeding the detector inconsistent images would corrupt
    // EMA / state machine.
    if (_isSwitchingCamera) {
      return;
    }

    // Drop frames if previous is still in flight. Critical: never queue.
    if (_isProcessingFrame) {
      _framesDropped += 1;
      return;
    }
    _isProcessingFrame = true;

    _processCameraImage(image).whenComplete(() {
      _isProcessingFrame = false;
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_poseDetector == null || _cameraController == null) return;

    final stopwatch = Stopwatch()..start();

    try {
      final inputImage = _inputImageFromCameraImage(image, _cameraController!);
      if (inputImage == null) return;

      _currentImageWidth = image.width;
      _currentImageHeight = image.height;

      final poses = await _poseDetector!.processImage(inputImage);
      if (poses.isEmpty) {
        _currentLandmarks = const [];
        _maybeRepaint();
        return;
      }

      // Build raw landmark array, normalized to 0..1 image coords.
      final Pose pose = poses.first;
      final double fw = image.width.toDouble();
      final double fh = image.height.toDouble();
      final List<List<double>> rawNorm = [];
      for (final type in _LM_ORDER) {
        final plm = pose.landmarks[type];
        if (plm == null) {
          rawNorm.add([0.0, 0.0, 0.0]);
        } else {
          rawNorm.add([
            (plm.x / fw).clamp(0.0, 1.0).toDouble(),
            (plm.y / fh).clamp(0.0, 1.0).toDouble(),
            plm.likelihood.clamp(0.0, 1.0).toDouble(),
          ]);
        }
      }

      // Smooth & feed to state machine.
      final smoothed = _smoother.smooth(rawNorm);
      _currentLandmarks = smoothed;

      if (_isActive) {
        final bool inWarmup = _sessionStartedAt == null
            ? true
            : DateTime.now().difference(_sessionStartedAt!).inMilliseconds <
                (LiveTuningParams.WARMUP_SECONDS * 1000).round();

        _repSM.processFrame(
          landmarks: smoothed,
          imageW: image.width.toDouble(),
          imageH: image.height.toDouble(),
          inWarmup: inWarmup,
        );

        // Audio/haptic on completed rep — consume the flag.
        if (_repSM.lastRepFinished != null) {
          final kind = _repSM.lastRepFinished!;
          _repSM.lastRepFinished = null;
          _fireRepCompleteFeedback(kind);
        }
      }

      _framesProcessed += 1;
      _updateFpsStats();
      _lastInferenceMs = stopwatch.elapsedMilliseconds;

      _maybeRepaint();
    } catch (e) {
      // Don't crash on isolated frame errors; just skip and continue.
      debugPrint('Live pose frame error: $e');
    }
  }

  void _updateFpsStats() {
    final now = DateTime.now();
    final elapsedMs = now.difference(_statsWindowStart).inMilliseconds;
    if (elapsedMs >= 1000) {
      _fpsDisplay = _framesProcessed / (elapsedMs / 1000.0);
      _statsWindowStart = now;
      _framesProcessed = 0;
      _framesDropped = 0;
      _framesReceived = 0;
    }
  }

  void _maybeRepaint() {
    if (!mounted) return;
    final now = DateTime.now();
    if (now.difference(_lastRepaintAt).inMilliseconds < _REPAINT_MIN_GAP_MS) {
      return;
    }
    _lastRepaintAt = now;
    setState(() {});
  }

  void _fireRepCompleteFeedback(String kind) {
    final now = DateTime.now();
    if (now.difference(_lastHapticAt).inMilliseconds >= 80) {
      _lastHapticAt = now;
      if (kind == 'good') {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(milliseconds: 90), () {
          HapticFeedback.lightImpact();
        });
      }
    }

    if (now.difference(_lastAudioAt).inMilliseconds < 80) return;
    _lastAudioAt = now;

    if (!_audioReady) return;
    final pool = kind == 'good' ? _goodRepPool : _badRepPool;
    if (pool.isEmpty) return;
    final int idx = kind == 'good' ? _goodPoolIdx : _badPoolIdx;
    final player = pool[idx % pool.length];
    if (kind == 'good') {
      _goodPoolIdx = (_goodPoolIdx + 1) % pool.length;
    } else {
      _badPoolIdx = (_badPoolIdx + 1) % pool.length;
    }
    try {
      player.seek(Duration.zero);
      player.resume();
    } catch (_) {}
  }

  Future<void> _startSession() async {
    _smoother.reset();
    _repSM.reset();
    _sessionStartedAt = DateTime.now();
    if (mounted) {
      setState(() {
        _isActive = true;
      });
    }
  }

  Future<void> _stopSession() async {
    if (!_isActive) return;
    setState(() {
      _isActive = false;
    });

    final sessionData = _buildSessionResult();
    // Publish the result to the global static so any FlutterFlow Custom
    // Action / Function can read it immediately when onSessionComplete
    // fires. The callback itself takes no parameters — this avoids the
    // typed-callback friction in FlutterFlow's UI for wiring up Future
    // Function(Map) signatures.
    LiveSquatSessionResult.latest = sessionData;
    if (widget.onSessionComplete != null) {
      try {
        await widget.onSessionComplete!();
      } catch (e) {
        debugPrint('onSessionComplete callback threw: $e');
      }
    }
  }

  Map<String, dynamic> _buildSessionResult() {
    final double sessionDuration = _sessionStartedAt == null
        ? 0.0
        : DateTime.now().difference(_sessionStartedAt!).inMilliseconds / 1000.0;

    // Session score = mean of rep scores, capped if there's any feedback.
    double avg = 0.0;
    if (_repSM.repReports.isNotEmpty) {
      double sum = 0.0;
      for (final r in _repSM.repReports) {
        sum += r.score;
      }
      avg = sum / _repSM.repReports.length;
    }
    if (avg.isNaN || avg.isInfinite) avg = 0.0;
    double techniqueScore =
        double.parse((((avg * 2).round() / 2.0)).toStringAsFixed(2));

    // Aggregate the strongest feedback per category across reps.
    final Map<String, int> severity = {
      'Try to squat deeper': 3,
      'Almost there — go a bit lower': 2,
      'Just a bit more depth': 1,
    };
    final Set<String> sessionFeedbackSet = {};
    String? strongest;
    int strongestSev = 0;
    for (final r in _repSM.repReports) {
      for (final fb in r.feedback) {
        sessionFeedbackSet.add(fb);
        final sev = severity[fb] ?? 1;
        if (sev > strongestSev) {
          strongestSev = sev;
          strongest = fb;
        }
      }
    }
    final feedbackList = sessionFeedbackSet.toList();
    if (feedbackList.isEmpty && _repSM.repCounter > 0) {
      feedbackList.add('Great form! Keep it up 💪');
    } else if (_repSM.repCounter == 0) {
      feedbackList.add(
        "No reps detected — make sure your full body is visible from the side.",
      );
    }

    String? tip;
    if (_repSM.repCounter > 0 && strongest != null) {
      if (strongest.contains('deeper') ||
          strongest.contains('lower') ||
          strongest.contains('depth')) {
        tip =
            'Focus on hip mobility and ankle flexibility to achieve better depth';
      }
    } else if (_repSM.repCounter > 0) {
      tip =
          'Outstanding consistency! Keep challenging yourself with progressive overload';
    }

    String label;
    if (techniqueScore >= 9.5) {
      label = 'Excellent';
    } else if (techniqueScore >= 8.5) {
      label = 'Very good';
    } else if (techniqueScore >= 7.0) {
      label = 'Good';
    } else if (techniqueScore >= 5.5) {
      label = 'Fair';
    } else {
      label = 'Needs work';
    }

    return {
      'squat_count': _repSM.repCounter,
      'technique_score': techniqueScore,
      'technique_score_display': _displayHalfStr(techniqueScore),
      'technique_label': label,
      'good_reps': _repSM.goodReps,
      'bad_reps': _repSM.badReps,
      'feedback': feedbackList,
      'tip': tip,
      'reps': _repSM.repReports.map((r) => r.toMap()).toList(),
      // No video_path or _frame_telemetry — live mode doesn't record.
      '_engine': 'live_mlkit',
      '_session_duration_sec': sessionDuration,
      '_landmark_model': 'mlkit_base',
    };
  }

  @override
  void dispose() {
    _stopSessionInternal();
    _cameraController?.stopImageStream().catchError((_) {});
    _cameraController?.dispose();
    _poseDetector?.close();
    for (final p in _goodRepPool) {
      try {
        p.dispose();
      } catch (_) {}
    }
    for (final p in _badRepPool) {
      try {
        p.dispose();
      } catch (_) {}
    }
    super.dispose();
  }

  void _stopSessionInternal() {
    // Called by dispose() — best effort, don't await.
    _isActive = false;
  }

  // --------------------------------------------------------------------------
  // BUILD
  //
  // Layout strategy (top to bottom in z-order):
  //
  //   0. Black background — fills any gap that the cover-fit camera doesn't.
  //
  //   1. Camera + skeleton overlay together, wrapped in FittedBox with
  //      BoxFit.cover so they fill the entire widget area edge-to-edge.
  //      Anything outside the camera's aspect ratio is cropped — same
  //      pattern as Instagram Stories / Snapchat. The skeleton is rendered
  //      INSIDE the same FittedBox so it stays aligned with the camera
  //      after cover-scaling.
  //
  //   2. HUD overlay (reps counter, depth ring, feedback bubble) — drawn
  //      in a SECOND CustomPaint that fills the visible widget area, NOT
  //      the camera's native resolution. This way reps/depth labels stay
  //      readable regardless of crop, and they don't get mirrored.
  //
  //   3. Top-left: X (close) button, in SafeArea.
  //   4. Top-right: flip-camera button, in SafeArea.
  //   5. Bottom-center: Start/Stop button, in SafeArea.
  //   6. Warmup banner — sits just above the Start/Stop button.
  //   7. Debug overlay — shown only when widget.showDebugOverlay = true.
  //
  // All controls live in SafeArea so they avoid the notch/dynamic-island
  // and the home-indicator strip.
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Use a LayoutBuilder so we know how much space the parent actually
    // gives us. If the widget is on a page with an AppBar, the actual
    // available height is less than MediaQuery.size.height — using
    // MediaQuery here caused the bottom of our Stack (where the start/stop
    // button lives) to be drawn OUTSIDE the visible area.
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = widget.width ??
            (constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width);
        final double h = widget.height ??
            (constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : MediaQuery.of(context).size.height);
        return _buildContent(context, w, h);
      },
    );
  }

  Widget _buildContent(BuildContext context, double w, double h) {
    if (_errorMessage != null) {
      return SizedBox(
        width: w,
        height: h,
        child: Container(
          color: Colors.black,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    if (!_cameraReady || _cameraController == null) {
      return SizedBox(
        width: w,
        height: h,
        child: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    final controller = _cameraController!;

    // CameraController.value.previewSize reports width × height of the
    // SENSOR. In portrait the visible aspect (height/width) is the inverse,
    // so we swap them when sizing the inner FittedBox child.
    final double cameraAspectW = controller.value.previewSize?.height ?? 9.0;
    final double cameraAspectH = controller.value.previewSize?.width ?? 16.0;

    // Mirror handling for selfie / front-camera mode.
    //
    // Empirically determined: on iOS with flutter/camera, NEITHER the
    // preview NOR the skeleton needs to be mirrored — even for the
    // front camera. The platform's CameraPreview already presents the
    // image in the orientation the user expects, and ML Kit returns
    // landmarks in the same coordinate space as the displayed preview.
    //
    // So we hard-code these to false. We keep the variables (rather
    // than dropping the parameter) so the painter signature stays
    // stable in case we need to re-introduce a toggle later.
    final bool mirrorPreview = false;
    final bool mirrorSkeleton = false;

    // Current rep state for the HUD.
    final int repCount = _repSM.repCounter;
    final double depthDisplay = _repSM.currentDepthDisplay;
    final String? feedback = _repSM.currentFeedback;
    final bool inWarmup = _isActive &&
        _sessionStartedAt != null &&
        DateTime.now().difference(_sessionStartedAt!).inMilliseconds <
            (LiveTuningParams.WARMUP_SECONDS * 1000).round();

    // ========================================================================
    // LAYOUT STRATEGY — Column inside SafeArea, NOT Positioned.
    //
    // Previous attempts with Positioned(bottom: 0) inside a Stack kept
    // clipping the Start/Stop button below the visible area because:
    //   - on a page with an AppBar, the Stack extended beyond the visible
    //     bounds and Positioned(bottom:0) anchored to the off-screen edge
    //   - even with LayoutBuilder reporting correct bounds, the system
    //     gestures area / home indicator inset varies between devices
    //
    // The fix: use a Column inside SafeArea. In a Column, a child with
    // a fixed height is GUARANTEED to be visible because flex layout
    // cannot place children outside its own bounds. The Expanded child
    // in the middle takes whatever space remains.
    //
    // We layer this above the fullscreen camera using a Stack:
    //   Layer 0: black background
    //   Layer 1: camera + skeleton, fullscreen cover
    //   Layer 2: HUD (reps/depth/feedback), fullscreen ignore-pointer
    //   Layer 3: Controls overlay — SafeArea > Column > [top bar, Expanded,
    //            bottom bar]. The top/bottom bars host the actual buttons.
    //            Transparent Expanded ensures they hit the safe edges.
    //   Layer 4: Camera-switching spinner (modal overlay)
    //   Layer 5: Debug overlay (optional)
    // ========================================================================

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ---- Layer 0: black background ----
          Container(color: Colors.black),

          // ---- Layer 1: camera + skeleton, fullscreen cover ----
          Positioned.fill(
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: cameraAspectW,
                  height: cameraAspectH,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Transform(
                        alignment: Alignment.center,
                        transform: mirrorPreview
                            ? (Matrix4.identity()..scale(-1.0, 1.0, 1.0))
                            : Matrix4.identity(),
                        child: CameraPreview(controller),
                      ),
                      CustomPaint(
                        painter: _LiveSquatSkeletonOnlyPainter(
                          landmarks: _currentLandmarks,
                          mirror: mirrorSkeleton,
                          inWarmup: inWarmup,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ---- Layer 2: HUD ----
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _LiveSquatHudPainter(
                  repCount: repCount,
                  depthDisplay: depthDisplay,
                  feedback: feedback,
                ),
              ),
            ),
          ),

          // ---- Layer 3: Controls overlay — Column with manual insets ----
          //
          // We deliberately DO NOT use SafeArea here. The widget is often
          // dropped inside a FlutterFlow page that ALREADY wraps in
          // SafeArea, which causes nested SafeArea to return zero insets
          // (because the system padding was already consumed). The result
          // is the bottom button being drawn into the home-indicator zone.
          //
          // MediaQuery.viewPadding returns the ACTUAL hardware insets
          // (notch, home indicator) regardless of how many SafeAreas
          // already consumed them. That's what we want.
          Positioned.fill(
            child: Builder(
              builder: (context) {
                final EdgeInsets sys = MediaQuery.of(context).viewPadding;
                // Always leave room for the home indicator + breathing
                // space, even on devices without one.
                final double bottomInset = math.max(sys.bottom + 16, 40);
                final double topInset = math.max(sys.top + 8, 16);
                return Padding(
                  padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top bar: X (left), flip-camera (right).
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildIconButton(
                              icon: Icons.close,
                              onTap: _cancelAndClose,
                              bgOpacity: 0.55,
                            ),
                            if (_availableCameras != null &&
                                _availableCameras!.length >= 2)
                              _buildIconButton(
                                icon: Icons.flip_camera_ios,
                                onTap:
                                    _isSwitchingCamera ? null : _toggleCamera,
                                bgOpacity: _isSwitchingCamera ? 0.3 : 0.55,
                              )
                            else
                              const SizedBox(width: 44, height: 44),
                          ],
                        ),
                      ),

                      // Spacer
                      const Expanded(child: SizedBox.shrink()),

                      // Warmup hint, sits right above the Start/Stop button.
                      if (inWarmup)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Get into position…',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Bottom bar: Start/Stop button.
                      Center(
                        child: _isActive
                            ? _buildStopButton()
                            : _buildStartButton(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ---- Layer 4: Camera-switching spinner ----
          if (_isSwitchingCamera)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),

          // ---- Layer 5: Debug overlay ----
          if (widget.showDebugOverlay)
            Positioned(
              left: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 120),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'FPS: ${_fpsDisplay.toStringAsFixed(1)}\n'
                      'inf: ${_lastInferenceMs}ms\n'
                      'stage: ${_repSM.stage}\n'
                      'depth: ${(depthDisplay * 100).round()}%\n'
                      'img: ${_currentImageWidth}x${_currentImageHeight}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Small circular icon button used for X (close) and flip-camera.
  /// Semi-transparent dark background so it shows up on any camera feed.
  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    double bgOpacity = 0.55,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(bgOpacity),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _startSession,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF28C850),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.play_arrow,
          color: Colors.white,
          size: 38,
        ),
      ),
    );
  }

  Widget _buildStopButton() {
    return GestureDetector(
      onTap: _stopSession,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE53935),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.stop,
          color: Colors.white,
          size: 38,
        ),
      ),
    );
  }
}

// ============================================================================
// PAINTERS
//
// Two painters now, separated by purpose:
//
// 1. _LiveSquatSkeletonOnlyPainter — draws JUST the body skeleton over the
//    camera, painted in the camera's native coordinate system (the SizedBox
//    that lives inside the FittedBox cover). Mirror-aware so the skeleton
//    lines up with the visually-mirrored front-camera preview.
//
// 2. _LiveSquatHudPainter — draws the reps counter, depth ring, and
//    feedback bubble in the WIDGET'S coordinate system, NOT the camera's.
//    This guarantees these labels stay readable regardless of camera
//    cropping, mirroring, or scaling, and don't end up flipped on the
//    front camera. The HUD does NOT depend on landmark data.
//
// Splitting them out also lets us throttle repaints differently: the
// skeleton needs to repaint on every new pose frame, but the HUD only
// needs to repaint when reps/depth/feedback change.
// ============================================================================

class _LiveSquatSkeletonOnlyPainter extends CustomPainter {
  _LiveSquatSkeletonOnlyPainter({
    required this.landmarks,
    required this.mirror,
    required this.inWarmup,
  });

  final List<List<double>> landmarks;
  final bool mirror;
  final bool inWarmup;

  static const List<List<int>> _connections = [
    [_IDX_L_SHOULDER, _IDX_R_SHOULDER],
    [_IDX_L_SHOULDER, _IDX_L_HIP],
    [_IDX_R_SHOULDER, _IDX_R_HIP],
    [_IDX_L_HIP, _IDX_R_HIP],
    [_IDX_L_SHOULDER, _IDX_L_ELBOW],
    [_IDX_L_ELBOW, _IDX_L_WRIST],
    [_IDX_R_SHOULDER, _IDX_R_ELBOW],
    [_IDX_R_ELBOW, _IDX_R_WRIST],
    [_IDX_L_HIP, _IDX_L_KNEE],
    [_IDX_L_KNEE, _IDX_L_ANKLE],
    [_IDX_L_ANKLE, _IDX_L_HEEL],
    [_IDX_L_HEEL, _IDX_L_FOOT],
    [_IDX_L_ANKLE, _IDX_L_FOOT],
    [_IDX_R_HIP, _IDX_R_KNEE],
    [_IDX_R_KNEE, _IDX_R_ANKLE],
    [_IDX_R_ANKLE, _IDX_R_HEEL],
    [_IDX_R_HEEL, _IDX_R_FOOT],
    [_IDX_R_ANKLE, _IDX_R_FOOT],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.length < 33) return;

    final double w = size.width;
    final double h = size.height;
    final double refDim = math.max(w, h); // for sizing strokes/dots

    final Paint linePaint = Paint()
      ..color =
          inWarmup ? const Color.fromARGB(220, 255, 200, 60) : Colors.white
      ..strokeWidth = math.max(3.0, refDim * 0.005)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final Paint dotPaint = Paint()
      ..color = linePaint.color
      ..style = PaintingStyle.fill;
    final double dotR = math.max(4.0, refDim * 0.007);

    Offset? pt(int idx) {
      if (idx < 0 || idx >= landmarks.length) return null;
      final lm = landmarks[idx];
      if (lm.length < 3) return null;
      if (lm[2] < LiveTuningParams.DRAW_VIS_THRESHOLD) return null;
      final double x = mirror ? (1.0 - lm[0]) * w : lm[0] * w;
      final double y = lm[1] * h;
      return Offset(x, y);
    }

    for (final conn in _connections) {
      final a = pt(conn[0]);
      final b = pt(conn[1]);
      if (a != null && b != null) {
        canvas.drawLine(a, b, linePaint);
      }
    }

    const bodyIndices = [
      _IDX_L_SHOULDER,
      _IDX_R_SHOULDER,
      _IDX_L_ELBOW,
      _IDX_R_ELBOW,
      _IDX_L_WRIST,
      _IDX_R_WRIST,
      _IDX_L_HIP,
      _IDX_R_HIP,
      _IDX_L_KNEE,
      _IDX_R_KNEE,
      _IDX_L_ANKLE,
      _IDX_R_ANKLE,
      _IDX_L_HEEL,
      _IDX_R_HEEL,
      _IDX_L_FOOT,
      _IDX_R_FOOT,
    ];
    for (final i in bodyIndices) {
      final p = pt(i);
      if (p != null) canvas.drawCircle(p, dotR, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiveSquatSkeletonOnlyPainter old) {
    return old.landmarks != landmarks ||
        old.inWarmup != inWarmup ||
        old.mirror != mirror;
  }
}

class _LiveSquatHudPainter extends CustomPainter {
  _LiveSquatHudPainter({
    required this.repCount,
    required this.depthDisplay,
    required this.feedback,
  });

  final int repCount;
  final double depthDisplay;
  final String? feedback;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Reserve space at the top for the X / flip buttons. Those buttons
    // are 44dp tall and sit inside SafeArea with 8+8dp of vertical
    // padding, plus the SafeArea top inset (~44dp on notched iPhones).
    // We offset the HUD below all of that so reps/depth labels never
    // overlap the buttons.
    final double topOffset = math.max(96, h * 0.10);

    // ---------- reps counter ----------
    // Smaller and positioned to the LEFT of center, below the X button.
    final double repsFontSize = math.max(16.0, h * 0.040);
    final TextPainter repsTp = TextPainter(
      text: TextSpan(
        text: 'Reps: $repCount',
        style: TextStyle(
          color: Colors.white,
          fontSize: repsFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final double repsPadX = 12;
    final double repsPadY = 8;
    final double repsBoxX = 12;
    final double repsBoxY = topOffset;
    final RRect repsBg = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        repsBoxX,
        repsBoxY,
        repsTp.width + 2 * repsPadX,
        repsTp.height + 2 * repsPadY,
      ),
      const Radius.circular(8),
    );
    final Paint repsBoxBg = Paint()..color = Colors.black.withOpacity(0.55);
    canvas.drawRRect(repsBg, repsBoxBg);
    repsTp.paint(canvas, Offset(repsBoxX + repsPadX, repsBoxY + repsPadY));

    // ---------- depth ring ----------
    // Positioned below the flip-camera button on the right side.
    final double radius = math.max(36.0, h * 0.060);
    final double thick = math.max(4.0, radius * 0.22);
    final double cx = w - 16 - radius;
    final double cy = topOffset + radius;

    final Paint ringBgPaint = Paint()
      ..color = const Color.fromARGB(255, 70, 70, 70)
      ..strokeWidth = thick
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawCircle(Offset(cx, cy), radius, ringBgPaint);

    final double pct = depthDisplay.clamp(0.0, 1.0);
    if (pct > 0) {
      final Paint ringFgPaint = Paint()
        ..color = const Color.fromARGB(255, 40, 200, 80)
        ..strokeWidth = thick
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        -math.pi / 2,
        2 * math.pi * pct,
        false,
        ringFgPaint,
      );
    }

    final TextPainter labelTp = TextPainter(
      text: TextSpan(
        text: 'DEPTH',
        style: TextStyle(
          color: Colors.white,
          fontSize: math.max(9.0, h * 0.018),
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final TextPainter pctTp = TextPainter(
      text: TextSpan(
        text: '${(pct * 100).round()}%',
        style: TextStyle(
          color: Colors.white,
          fontSize: math.max(13.0, h * 0.028),
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final double gap = math.max(2.0, radius * 0.10);
    final double totalTextH = labelTp.height + gap + pctTp.height;
    final double labelY = cy - totalTextH / 2;
    labelTp.paint(canvas, Offset(cx - labelTp.width / 2, labelY));
    pctTp.paint(
        canvas, Offset(cx - pctTp.width / 2, labelY + labelTp.height + gap));

    // ---------- feedback bubble ----------
    // Centered horizontally, sits just above where the Start/Stop button
    // will be (which is at bottom + 32 + safe-area).
    if (feedback != null && feedback!.isNotEmpty) {
      final double fbFontSize = math.max(13.0, h * 0.028);
      final TextPainter fbTp = TextPainter(
        text: TextSpan(
          text: feedback,
          style: TextStyle(
            color: Colors.white,
            fontSize: fbFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 2,
      )..layout(maxWidth: w - 80);

      final double pad = 10;
      // Position 180dp from the bottom so it never sits on the Start/Stop
      // button or the warmup banner.
      final double boxY = h - 180 - fbTp.height - 2 * pad;
      final double boxW = fbTp.width + 2 * pad;
      final double boxX = (w - boxW) / 2;
      final Paint fbBoxBg = Paint()..color = Colors.black.withOpacity(0.7);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(boxX, boxY, boxW, fbTp.height + 2 * pad),
          const Radius.circular(8),
        ),
        fbBoxBg,
      );
      fbTp.paint(canvas, Offset(boxX + pad, boxY + pad));
    }
  }

  @override
  bool shouldRepaint(covariant _LiveSquatHudPainter old) {
    return old.repCount != repCount ||
        old.depthDisplay != depthDisplay ||
        old.feedback != feedback;
  }
}
