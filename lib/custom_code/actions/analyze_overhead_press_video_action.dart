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

// ============================================================================
// ============================ TUNABLE PARAMETERS ============================
// ============================================================================
class TuningParams {
  // ---------------------- VIDEO EXTRACTION ----------------------
  static const double DEFAULT_FPS = 12.0;
  static const int FRAME_MAX_WIDTH = 1080;
  static const int JPEG_QUALITY = 2;

  // ---------------------- SAVITZKY-GOLAY FILTER ----------------------
  // Window=7 (was 11 — inherited from squat analyzer).
  static const int SG_WINDOW_SIZE = 7;
  static const int SG_POLY_ORDER = 2;
  static const double SG_VIS_THRESHOLD = 0.5;

  // ---------------------- ML KIT POSE DETECTOR ----------------------
  // [v1.15] CRITICAL FIX:
  static const bool USE_STREAM_MODE = false;

  // ---------------------- VISIBILITY (HYSTERESIS) ----------------------
  // Restricted to ARM landmarks only (see applyVisibilityFilters). Body
  // joints pass through always — they're rendered even at low vis.
  static const double VIS_HIDE_THRESHOLD = 0.40;
  static const double VIS_SHOW_THRESHOLD = 0.60;
  static const double LOW_CORE_VIS_THRESHOLD = 0.45;

  // ---------------------- ANATOMICAL PLAUSIBILITY ----------------------
  // [v1.33] DISABLED for the press (bounds widened to the full 0–180° range, which makes the check in…
  static const double MAX_ELBOW_BEND_DEG = 180.0;
  static const double MIN_ELBOW_BEND_DEG = 0.0;

  // ---------------------- JUMP / GLITCH REJECTION ----------------------
  // Press is mostly stationary so a small per-frame shoulder jump is
  // very suspicious. Timeout breaks the freeze-cascade (see squat fix).
  static const double JUMP_REJECT_SHOULDER_FRAC = 0.18;
  static const int JUMP_REJECT_MAX_CONSECUTIVE = 6;

  // ---------------------- REP DETECTION (CORE) ----------------------
  // Phase-transition elbow angles.
  static const double BOTTOM_ELBOW_MAX_INIT = 110.0;
  static const double TOP_ELBOW_MIN_INIT = 115.0;
  static const double HYSTERESIS_BAND = 8.0;

  // Wrist-position gates.
  // [v1.33] BOTTOM threshold 0.15 → 0.25.
  static const double WRIST_BOTTOM_MAX_ABOVE_SHOULDER = 0.25;
  static const double WRIST_TOP_MIN_ABOVE_SHOULDER = 0.10;

  // [v1.2] Standalone wrist-based TOP threshold.
  static const double WRIST_ALONE_TOP_THRESHOLD = 0.18;

  // [v1.3] Envelope-based descent detection.
  // [v1.5 REVISION] Threshold was bumped from 5% → 10% torso AND a sustained-frames requirement was…
  static const double WRIST_DESCENT_FROM_PEAK = 0.10;

  // [v1.8] Was 2, bumped to 3.
  static const int WRIST_DESCENT_SUSTAINED_FRAMES = 3;

  // ---------------------- DETECTION QUALITY GATES ----------------------
  // ML Kit sometimes returns landmarks for partial detections — when only an arm is visible at the edge…
  // [v1.32] LOWERED 0.10 → 0.06 based on a real user video that produced ZERO counted reps.
  static const double MIN_TORSO_HEIGHT_FOR_START = 0.06;

  // ---------------------- IDLE→TOP SHORTCUT (STRICT) ----------------------
  // The IDLE→TOP shortcut handles videos that start with the user already mid-set (already pressed up).
  // [v1.4] Bumped dwell from 5 to 12 frames (1 second at 12fps) AND added a torso-stability check…
  static const double IDLE_TO_TOP_STRICT_ELBOW_MIN = 160.0;
  static const double IDLE_TO_TOP_STRICT_WRIST_ABOVE = 0.20;
  static const int IDLE_TO_TOP_MIN_DWELL_SEC_EQUIV = 12; // frames at any FPS

  // To leave IDLE via the BOTTOM path, the bottom must be observed for this long.
  static const double START_GATE_SEC = 0.5;

  // [v1.31] Fast-first-rep rescue window.
  static const double FIRST_REP_RESCUE_WINDOW_SEC = 1.5;

  // Timing — adapted to FPS at runtime.
  static const double MIN_CYCLE_SEC = 0.5;
  static const double MIN_PHASE_SEC = 0.10;
  static const double REFRACTORY_SEC = 0.25;
  // START_GATE_SEC is declared below alongside the IDLE→TOP shortcut.

  // EMA smoothing of scalars used by the state machine.
  static const double ELBOW_EMA_ALPHA = 0.80;
  static const double WRIST_EMA_ALPHA = 0.70;
  static const double LEAN_EMA_ALPHA = 0.50;
  static const double SHOULDER_EMA_ALPHA = 0.40;
  static const double TORSO_EMA_ALPHA = 0.40;

  // Bilateral arm validation.
  static const double BILATERAL_DISAGREE_DEG = 35.0;
  static const double VIS_THRESHOLD = 0.40;

  // ---------------------- CALIBRATION ----------------------
  static const int CALIBRATION_REPS = 2;
  static const double CALIBRATION_ADJUSTMENT = 0.85;

  // ---------------------- GEOMETRY: ASPECT CORRECTION ----------------------
  // [v1.33] ROOT-CAUSE FIX.

  // ---------------------- SCORING ----------------------
  static const double DEPTH_TARGET_ANGLE = 100.0;
  static const double DEPTH_OK_ANGLE = 115.0;
  static const double LOCKOUT_TARGET_ANGLE = 172.0;
  static const double LOCKOUT_OK_ANGLE = 160.0;

  // [v1.33] Lockout thresholds for FRONTAL recordings.
  static const double LOCKOUT_TARGET_ANGLE_FRONTAL = 152.0;
  static const double LOCKOUT_OK_ANGLE_FRONTAL = 130.0;

  // [v1.33] Lean thresholds rescaled for the aspect fix (old 12/22/30 in the warped portrait space ≡…
  static const double LEAN_TARGET_MAX = 7.0;
  static const double LEAN_OK_MAX = 13.0;
  static const double LEAN_BAD_MAX = 18.0;
  static const double BAR_PATH_TARGET = 0.04;
  static const double BAR_PATH_OK = 0.08;

  // STACK dimension removed — see comment near the original STACK_TARGET_MAX.

  // HEAD_THROUGH measures the head's X position vs the wrists' X position at the top of the press.
  // [v1.33] Rescaled for the aspect fix (old −0.15/−0.30/−0.48 in the warped portrait space ≡…
  static const double HEAD_THROUGH_TARGET =
      -0.08; // head slightly behind wrist = ideal target
  static const double HEAD_THROUGH_OK =
      -0.17; // head moderately behind — still acceptable
  static const double HEAD_THROUGH_BAD =
      -0.27; // head clearly behind, looking up at bar
  static const int HEAD_THROUGH_MIN_FRAMES = 3;

  // ELBOW_FLARE measures how far the elbows extend OUTWARD beyond the wrists, normalized by torso…
  // [v1.33 — measured where it matters + robust statistic]:
  static const double ELBOW_FLARE_TARGET =
      0.05; // elbow at most slightly wider than wrist
  static const double ELBOW_FLARE_OK =
      0.20; // ~20% torso beyond wrist = still acceptable
  static const double ELBOW_FLARE_BAD = 0.35; // ~35% torso = clearly flared

  // [v1.6] Frontal view detection.
  // [v1.33] REPLACED by a scale-invariant measure.
  static const double FRONTAL_VIEW_SHOULDER_SEP = 0.10;
  static const double FRONTAL_VIEW_SHOULDER_SEP_TORSO = 0.35;

  // [v1.8] Minimum number of "confident" frames during BOTTOM phase required before ELBOW_FLARE…
  static const int MIN_FLARE_CONFIDENT_FRAMES = 3;
  static const double FLARE_ARM_VIS_THRESHOLD = 0.5;

  // [v1.9] Minimum wrist rise (as fraction of torso height) from the start of a rep cycle to the peak,…
  // [v1.11 REVISION] Raised from 0.05 → 0.15.
  static const double MIN_RISE_FROM_CYCLE_START = 0.15;

  static const double W_DEPTH = 0.20;
  static const double W_LOCKOUT = 0.25;
  static const double W_LEAN = 0.20;
  static const double W_BAR_PATH = 0.15;
  static const double W_HEAD_THROUGH = 0.10;
  static const double W_ELBOW_FLARE = 0.10;

  static const double REP_FEEDBACK_SCORE_THR = 7.0;
  // [v1.30] RETIRED from the session-feedback gate (kept only to avoid breaking any external…
  static const double SESSION_FEEDBACK_RATIO = 0.30;
  // [v1.21] Lowered from 2 → 1.
  static const int SESSION_FEEDBACK_MIN = 1;

  // ---------------------- HEAD-CROSS PROOF HARDENING ----------------------
  // [v1.32] The v1.19 wristCrossedHead lockout proof used a single frame of (wristY < noseY) with zero…
  static const double HEAD_CROSS_MARGIN_TORSO = 0.08;
  static const int HEAD_CROSS_SUSTAINED_FRAMES = 2;

  // ---------------------- POST-PROCESS OUTLIER FILTERS ----------------------
  // [v1.31] Absolute floor for the cycle-length outlier filter, in SECONDS OF MOTION (ascent start →…
  static const double CYCLE_LEN_FILTER_MIN_SEC = 4.0;

  // ---------------------- DONUT (HEIGHT %) ----------------------
  // Same approach as pullup: fixed absolute scale + zero-phase smoothing
  // + raw-max guarantees 100% at the peak of good reps.
  static const double DONUT_FULL_ASCENT =
      0.22; // wrist rise (norm Y) that reads 100%
  static const double DONUT_SMOOTH_ALPHA = 0.45;

  // ---------------------- REAL-TIME FEEDBACK ----------------------
  static const double RT_FB_HOLD_SEC = 1.5;
}
// ============================================================================

// ============================================================================
// Savitzky-Golay filter (zero-phase smoothing) — copied verbatim from
// the proven squat analyzer.
// ============================================================================

List<double> _computeSavGolCoefficients(int windowSize, int polyOrder) {
  assert(windowSize % 2 == 1, 'window size must be odd');
  assert(polyOrder < windowSize, 'poly order must be less than window size');

  final int half = windowSize ~/ 2;
  final int m = windowSize;
  final int n = polyOrder + 1;

  final List<List<double>> V = List.generate(
    m,
    (i) {
      final int j = i - half;
      final row = List<double>.filled(n, 0.0);
      double power = 1.0;
      for (int k = 0; k < n; k++) {
        row[k] = power;
        power *= j;
      }
      return row;
    },
  );

  final List<List<double>> A =
      List.generate(n, (_) => List<double>.filled(n, 0.0));
  for (int r = 0; r < n; r++) {
    for (int c = 0; c < n; c++) {
      double s = 0.0;
      for (int i = 0; i < m; i++) {
        s += V[i][r] * V[i][c];
      }
      A[r][c] = s;
    }
  }

  final List<double> x = List<double>.filled(n, 0.0);
  x[0] = 1.0;
  final List<List<double>> aug = List.generate(n, (i) => [...A[i], x[i]]);

  for (int pivot = 0; pivot < n; pivot++) {
    int maxRow = pivot;
    double maxVal = aug[pivot][pivot].abs();
    for (int r = pivot + 1; r < n; r++) {
      if (aug[r][pivot].abs() > maxVal) {
        maxVal = aug[r][pivot].abs();
        maxRow = r;
      }
    }
    if (maxRow != pivot) {
      final tmp = aug[pivot];
      aug[pivot] = aug[maxRow];
      aug[maxRow] = tmp;
    }
    final double pivotVal = aug[pivot][pivot];
    if (pivotVal.abs() < 1e-12) {
      return List<double>.filled(windowSize, 1.0 / windowSize);
    }
    for (int c = pivot; c <= n; c++) {
      aug[pivot][c] /= pivotVal;
    }
    for (int r = 0; r < n; r++) {
      if (r == pivot) continue;
      final double factor = aug[r][pivot];
      if (factor == 0.0) continue;
      for (int c = pivot; c <= n; c++) {
        aug[r][c] -= factor * aug[pivot][c];
      }
    }
  }
  for (int i = 0; i < n; i++) x[i] = aug[i][n];

  final List<double> coeffs = List<double>.filled(m, 0.0);
  for (int i = 0; i < m; i++) {
    double s = 0.0;
    for (int k = 0; k < n; k++) s += V[i][k] * x[k];
    coeffs[i] = s;
  }
  return coeffs;
}

List<double?> _savgolSmoothSeries(List<double?> values, List<double> coeffs) {
  final int n = values.length;
  final int m = coeffs.length;
  final int half = m ~/ 2;
  final result = List<double?>.filled(n, null);

  for (int i = 0; i < n; i++) {
    if (values[i] == null) continue;
    double sum = 0.0;
    bool anyMissingInWindow = false;
    for (int k = 0; k < m; k++) {
      int idx = i + (k - half);
      if (idx < 0) idx = -idx;
      if (idx >= n) idx = 2 * (n - 1) - idx;
      if (idx < 0 || idx >= n) {
        anyMissingInWindow = true;
        break;
      }
      final v = values[idx];
      if (v == null) {
        anyMissingInWindow = true;
        break;
      }
      sum += coeffs[k] * v;
    }
    result[i] = anyMissingInWindow ? values[i] : sum;
  }
  return result;
}

List<List<List<double>>> savitzkyGolaySmoothAll(
    List<List<List<double>>> rawFrames) {
  final int n = rawFrames.length;
  if (n == 0) return rawFrames;
  const int numLandmarks = 33;

  final coeffs = _computeSavGolCoefficients(
      TuningParams.SG_WINDOW_SIZE, TuningParams.SG_POLY_ORDER);

  final xSeries =
      List.generate(numLandmarks, (_) => List<double?>.filled(n, null));
  final ySeries =
      List.generate(numLandmarks, (_) => List<double?>.filled(n, null));
  final wasLowVis =
      List.generate(numLandmarks, (_) => List<bool>.filled(n, false));

  for (int i = 0; i < n; i++) {
    final frame = rawFrames[i];
    if (frame.isEmpty) continue;
    for (int lm = 0; lm < numLandmarks && lm < frame.length; lm++) {
      final point = frame[lm];
      if (point.length < 3) continue;
      if (point[2] < TuningParams.SG_VIS_THRESHOLD) {
        wasLowVis[lm][i] = true;
        continue;
      }
      xSeries[lm][i] = point[0];
      ySeries[lm][i] = point[1];
    }
  }

  final out = List.generate(
    n,
    (i) => rawFrames[i].isEmpty
        ? <List<double>>[]
        : List<List<double>>.generate(
            rawFrames[i].length,
            (lm) => List<double>.from(rawFrames[i][lm]),
          ),
  );

  for (int lm = 0; lm < numLandmarks; lm++) {
    final sx = _savgolSmoothSeries(xSeries[lm], coeffs);
    final sy = _savgolSmoothSeries(ySeries[lm], coeffs);
    for (int i = 0; i < n; i++) {
      if (out[i].isEmpty || lm >= out[i].length) continue;
      if (wasLowVis[lm][i]) {
        out[i][lm][2] = 0.0;
        continue;
      }
      if (sx[i] != null) out[i][lm][0] = sx[i]!;
      if (sy[i] != null) out[i][lm][1] = sy[i]!;
    }
  }
  return out;
}

// ============================================================================
// Visibility filters (arm-only — see squat analyzer for rationale).
// ============================================================================

const int _IDX_L_SHOULDER = 11;
const int _IDX_R_SHOULDER = 12;
const int _IDX_L_ELBOW = 13;
const int _IDX_R_ELBOW = 14;
const int _IDX_L_WRIST = 15;
const int _IDX_R_WRIST = 16;
const int _IDX_L_HIP = 23;
const int _IDX_R_HIP = 24;

double _angleAt(List<double> a, List<double> b, List<double> c) {
  final rad = math.atan2(c[1] - b[1], c[0] - b[0]) -
      math.atan2(a[1] - b[1], a[0] - b[0]);
  double ang = (rad * 180.0 / math.pi).abs();
  if (ang > 180) ang = 360 - ang;
  return ang;
}

bool _isArmLandmark(int lm) =>
    lm == _IDX_L_ELBOW ||
    lm == _IDX_R_ELBOW ||
    lm == _IDX_L_WRIST ||
    lm == _IDX_R_WRIST;

List<List<List<double>>> applyVisibilityFilters(
    List<List<List<double>>> smoothedFrames) {
  final int n = smoothedFrames.length;
  if (n == 0) return smoothedFrames;
  const int numLandmarks = 33;
  final List<bool> isShown = List<bool>.filled(numLandmarks, false);

  final out = List.generate(
    n,
    (i) => smoothedFrames[i].isEmpty
        ? <List<double>>[]
        : List<List<double>>.generate(
            smoothedFrames[i].length,
            (lm) => List<double>.from(smoothedFrames[i][lm]),
          ),
  );

  // Pass 1: hysteresis on ARMS only. Body landmarks unchanged.
  for (int i = 0; i < n; i++) {
    final frame = out[i];
    if (frame.isEmpty) continue;
    for (int lm = 0; lm < numLandmarks && lm < frame.length; lm++) {
      if (!_isArmLandmark(lm)) continue;
      final point = frame[lm];
      if (point.length < 3) continue;
      final double vis = point[2];
      if (isShown[lm]) {
        if (vis < TuningParams.VIS_HIDE_THRESHOLD) {
          isShown[lm] = false;
          point[2] = 0.0;
        }
      } else {
        if (vis >= TuningParams.VIS_SHOW_THRESHOLD) {
          isShown[lm] = true;
        } else {
          point[2] = 0.0;
        }
      }
    }
  }

  // Pass 2: anatomical elbow check, per side.
  for (int i = 0; i < n; i++) {
    final frame = out[i];
    if (frame.isEmpty) continue;
    void checkArm(int shoulderIdx, int elbowIdx, int wristIdx) {
      if (shoulderIdx >= frame.length ||
          elbowIdx >= frame.length ||
          wristIdx >= frame.length) return;
      final s = frame[shoulderIdx];
      final e = frame[elbowIdx];
      final w = frame[wristIdx];
      if (s.length < 3 || e.length < 3 || w.length < 3) return;
      if (s[2] <= 0.0 || e[2] <= 0.0 || w[2] <= 0.0) return;
      final ang = _angleAt(s, e, w);
      if (ang > TuningParams.MAX_ELBOW_BEND_DEG ||
          ang < TuningParams.MIN_ELBOW_BEND_DEG) {
        e[2] = 0.0;
        w[2] = 0.0;
      }
    }

    checkArm(_IDX_L_SHOULDER, _IDX_L_ELBOW, _IDX_L_WRIST);
    checkArm(_IDX_R_SHOULDER, _IDX_R_ELBOW, _IDX_R_WRIST);
  }

  return out;
}

// ============================================================================
// Phase enum.
// ============================================================================
const int _PHASE_IDLE = 0;
const int _PHASE_BOTTOM = 1;
const int _PHASE_ASCENDING = 2;
const int _PHASE_TOP = 3;
const int _PHASE_DESCENDING = 4;

/// Overhead press analyzer — v1.33.
/// Pipeline: ffmpeg frames @12fps → ML Kit pose (single mode) → Savitzky-Golay
/// smoothing → arm visibility hysteresis → state machine
/// (IDLE → BOTTOM → ASCENDING → TOP → DESCENDING → count) → scoring on 6 dims
/// (depth, lockout, lean, head_through, elbow_flare, bar_path) → post-process
/// outlier filters → per-frame telemetry for the overlay widget.
///
/// v1.33 (validated on the device's own landmarks, frontal set, 13 presses:
/// v1.32 = 12 reps + lockout/flare feedback on every rep; v1.33 = 13/13, clean):
///   1. Aspect-correct geometry: angles/lean/flare/head-through computed with x
///      scaled by frameW/frameH (portrait video stretched x by 1.78x, so straight
///      arms read 20-30 deg more bent). Lean/head-through thresholds rescaled.
///   2. Anatomical elbow filter (20/178 deg) disabled — it deleted the press
///      bottom (frontal) and the press lockout (any view).
///   3. TOP is not left on the elbow angle while the wrist is way above the
///      shoulder (no TOP<->DESCENDING flicker during the ascent).
///   4. Cycle start = lowest wrist position seen in BOTTOM (the ascent gate was
///      measuring from a mid-descent count frame -> 'ascent<15%torso').
///   5. Frontal view = shoulder separation / torso height (scale invariant).
///   6. Frontal lockout thresholds 130/152 (landmark bias from the front).
///   7. Elbow flare: rack-position frames only, median instead of max.
Future<dynamic> analyzeOverheadPressVideoAction(
  FFUploadedFile videoFile,
  double? targetFps,
) async {
  const Map<String, int> FB_SEVERITY = {
    'Press to full lockout overhead': 3,
    'Lower to shoulder level each rep': 3,
    'Keep torso upright — avoid leaning back': 2,
    'Push your head through at the top': 2,
    "Don't flare your elbows — keep them forward": 2,
    'Keep bar path straight and vertical': 1,
  };
  const Map<String, String> FEEDBACK_CATEGORY = {
    'Press to full lockout overhead': 'lockout',
    'Lower to shoulder level each rep': 'depth',
    'Keep torso upright — avoid leaning back': 'lean',
    'Push your head through at the top': 'head_through',
    "Don't flare your elbows — keep them forward": 'elbow_flare',
    'Keep bar path straight and vertical': 'bar_path',
  };
  // Verbatim feedback strings (constants for clarity below).
  const String FB_DEPTH = 'Lower to shoulder level each rep';
  const String FB_LOCKOUT = 'Press to full lockout overhead';
  const String FB_LEAN = 'Keep torso upright — avoid leaning back';
  const String FB_HEAD_THROUGH = 'Push your head through at the top';
  const String FB_ELBOW_FLARE = "Don't flare your elbows — keep them forward";
  const String FB_BAR_PATH = 'Keep bar path straight and vertical';

  // [v1.14] Coaching tips ("form_tips") — surfaced as the `form_tips` field in the response.
  const String PERF_TIP_SLOW_DESCENT =
      'Lower the bar slowly — aim for 2–3 seconds on the way down';
  const String PERF_TIP_FULL_LOCKOUT =
      'Drive each rep to full lockout — fully extend your elbows overhead';
  const String PERF_TIP_BRACE_CORE =
      'Brace your core and squeeze your glutes — stay tight throughout';
  const String PERF_TIP_BAR_PATH =
      'Focus on pressing straight up — keep the bar path vertical';

  // Form-tip trigger thresholds.
  const double TIP_ECCENTRIC_RATIO_MIN = 1.5;
  // LOCKOUT band:
  const double TIP_LOCKOUT_NEAR_MIN_OFFSET = -2.0; // from LOCKOUT_OK
  const double TIP_LOCKOUT_NEAR_MAX_OFFSET = -4.0; // from LOCKOUT_TARGET
  // LEAN band:
  const double TIP_LEAN_BORDERLINE_MIN = 6.0;
  const double TIP_LEAN_BORDERLINE_MAX = 10.0;
  // BAR_PATH band: avgBarDev above target (0.04) but below OK (0.08).
  // Path is wandering slightly — remind user to keep it vertical.
  const double TIP_BAR_PATH_BORDERLINE_MIN = 0.04;
  const double TIP_BAR_PATH_BORDERLINE_MAX = 0.075;

  final double fps = (targetFps ?? TuningParams.DEFAULT_FPS).clamp(2.0, 30.0);
  final double dt = 1.0 / fps;
  final int MIN_CYCLE_FRAMES =
      math.max(4, (TuningParams.MIN_CYCLE_SEC / dt).round());
  final int MIN_PHASE_FRAMES =
      math.max(2, (TuningParams.MIN_PHASE_SEC / dt).round());
  final int REFRACTORY_FRAMES =
      math.max(3, (TuningParams.REFRACTORY_SEC / dt).round());
  final int START_GATE_FRAMES =
      math.max(2, (TuningParams.START_GATE_SEC / dt).round());
  final int RT_FB_HOLD_FRAMES =
      math.max(2, (TuningParams.RT_FB_HOLD_SEC / dt).round());
  // [v1.31] Rescue window in frames (see FIRST_REP_RESCUE_WINDOW_SEC).
  final int RESCUE_WINDOW_FRAMES =
      math.max(6, (TuningParams.FIRST_REP_RESCUE_WINDOW_SEC / dt).round());

  _cachedW = -1;
  _cachedH = -1;

  // ---- Helpers ----
  // [v1.33] Aspect factor (frameWidth / frameHeight) applied to the x axis of every angle / lateral…
  double geomAspect = 1.0;
  double calcAngle(List<double> a, List<double> b, List<double> c) => _angleAt(
      [a[0] * geomAspect, a[1]],
      [b[0] * geomAspect, b[1]],
      [c[0] * geomAspect, c[1]]);

  double euclid(List<double> a, List<double> b) {
    final dx = a[0] - b[0];
    final dy = a[1] - b[1];
    return math.sqrt(dx * dx + dy * dy);
  }

  double emaUpdate(double? prev, double newVal, double alpha) {
    if (prev == null) return newVal;
    return alpha * newVal + (1 - alpha) * prev;
  }

  double scoreInterp(double value, double target, double ok, double bad,
      {required bool higherIsBetter}) {
    if (higherIsBetter) {
      if (value >= target) return 10.0;
      if (value >= ok)
        return 7.0 + 3.0 * (value - ok) / math.max(target - ok, 1e-6);
      if (value >= bad)
        return 3.0 + 4.0 * (value - bad) / math.max(ok - bad, 1e-6);
      return math.max(0.0, 3.0 * value / math.max(bad, 1e-6));
    } else {
      if (value <= target) return 10.0;
      if (value <= ok)
        return 7.0 + 3.0 * (ok - value) / math.max(ok - target, 1e-6);
      if (value <= bad)
        return 3.0 + 4.0 * (bad - value) / math.max(bad - ok, 1e-6);
      return math.max(0.0, 3.0 * (1.0 - (value - bad) / math.max(bad, 1e-6)));
    }
  }

  double halfFloor10(double x) =>
      math.max(0.0, math.min(10.0, (x * 2.0).floorToDouble() / 2.0));

  String displayHalfStr(double x) {
    final q = (x * 2).round() / 2.0;
    if ((q - q.round()).abs() < 1e-9) return q.round().toString();
    return q.toStringAsFixed(1);
  }

  String scoreLabel(double s) {
    if (s >= 9.0) return 'Excellent';
    if (s >= 7.5) return 'Great';
    if (s >= 6.0) return 'Good';
    if (s >= 4.5) return 'Fair';
    if (s >= 3.0) return 'Needs Work';
    return 'Poor';
  }

  double stddev(List<double> values) {
    if (values.length < 2) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    double sumSq = 0.0;
    for (final v in values) {
      final d = v - mean;
      sumSq += d * d;
    }
    return math.sqrt(sumSq / values.length);
  }

  Map<String, dynamic> errorPayload(String code, String detail) => {
        'error': code,
        'detail': detail,
        'squat_count': 0,
        'rep_count': 0,
        'technique_score': 0.0,
        'technique_score_display': '0',
        'technique_label': 'No reps detected',
        'good_reps': 0,
        'bad_reps': 0,
        'feedback': <String>['Could not analyze video'],
        'tip': null,
        'reps': <dynamic>[],
        'exercise_type': 'overhead_press',
        'video_path': '',
        '_source_video_uri': '',
        '_frame_telemetry': <dynamic>[],
      };

  // ---- Save upload ----
  if (videoFile.bytes == null || videoFile.bytes!.isEmpty) {
    return errorPayload('empty_upload', 'Uploaded file has no bytes');
  }
  final Directory tmp = await getTemporaryDirectory();
  final String uploadName =
      (videoFile.name?.isNotEmpty ?? false) ? videoFile.name! : 'upload.mp4';
  final String safeName = uploadName.split('/').last.split('\\').last;
  final String videoPath = p.join(
      tmp.path, 'press_in_${DateTime.now().millisecondsSinceEpoch}_$safeName');
  try {
    await File(videoPath).writeAsBytes(videoFile.bytes!, flush: true);
  } catch (e) {
    return errorPayload('write_failed', 'Could not save upload: $e');
  }

  // ---- Extract frames ----
  final String sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  final Directory framesDir =
      Directory(p.join(tmp.path, 'press_frames_$sessionId'));
  if (framesDir.existsSync()) framesDir.deleteSync(recursive: true);
  framesDir.createSync(recursive: true);

  final String framePattern = p.join(framesDir.path, 'f_%05d.jpg');
  final String extractCmd =
      "-y -i \"$videoPath\" -vf \"fps=$fps,scale='min(${TuningParams.FRAME_MAX_WIDTH},iw)':-2\" -q:v ${TuningParams.JPEG_QUALITY} \"$framePattern\"";
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

  // ---- Pose detector ----
  final poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: TuningParams.USE_STREAM_MODE
          ? PoseDetectionMode.stream
          : PoseDetectionMode.single,
      model: PoseDetectionModel.accurate,
    ),
  );

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

  // ---- First pass: collect raw landmarks per frame ----
  final List<List<List<double>>> allRawLandmarks = [];
  final List<double> allFrameTimes = [];
  final List<bool> frameRejected = [];

  List<double>? lastGoodShoulderNorm;
  int consecutiveJumpRejections = 0;
  int frameIdx = 0;

  try {
    for (final frameFile in frameFiles) {
      frameIdx += 1;
      final double tSec = (frameIdx - 1) / fps;
      allFrameTimes.add(tSec);

      final inputImage = InputImage.fromFilePath(frameFile.path);
      List<Pose> poses = [];
      try {
        poses = await poseDetector.processImage(inputImage);
      } catch (_) {
        allRawLandmarks.add(const []);
        frameRejected.add(true);
        continue;
      }
      if (poses.isEmpty) {
        allRawLandmarks.add(const []);
        frameRejected.add(true);
        continue;
      }

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

      // Need at least one shoulder + matching elbow/wrist + hip on the same side.
      final lsh = lm[PoseLandmarkType.leftShoulder];
      final rsh = lm[PoseLandmarkType.rightShoulder];
      final le = lm[PoseLandmarkType.leftElbow];
      final re = lm[PoseLandmarkType.rightElbow];
      final lw = lm[PoseLandmarkType.leftWrist];
      final rw = lm[PoseLandmarkType.rightWrist];
      final lh = lm[PoseLandmarkType.leftHip];
      final rh = lm[PoseLandmarkType.rightHip];

      if (lsh == null || rsh == null || lh == null || rh == null) {
        allRawLandmarks.add(const []);
        frameRejected.add(true);
        continue;
      }

      final double coreVisMean =
          (lsh.likelihood + rsh.likelihood + lh.likelihood + rh.likelihood) /
              4.0;

      // Build the normalized array always — Savitzky-Golay needs it
      // even when this frame has marginal quality.
      final List<List<double>> rawNormLandmarks = [];
      for (final t in LM_ORDER) {
        final plm = lm[t];
        if (plm == null) {
          rawNormLandmarks.add([0.0, 0.0, 0.0]);
        } else {
          rawNormLandmarks.add([
            (plm.x / fw).clamp(0.0, 1.0).toDouble(),
            (plm.y / fh).clamp(0.0, 1.0).toDouble(),
            (plm.likelihood).clamp(0.0, 1.0).toDouble(),
          ]);
        }
      }

      final List<double> shoulderMidNorm = [
        (rawNormLandmarks[_IDX_L_SHOULDER][0] +
                rawNormLandmarks[_IDX_R_SHOULDER][0]) /
            2.0,
        (rawNormLandmarks[_IDX_L_SHOULDER][1] +
                rawNormLandmarks[_IDX_R_SHOULDER][1]) /
            2.0,
      ];

      bool rejectFrame = false;
      if (coreVisMean < TuningParams.LOW_CORE_VIS_THRESHOLD) {
        rejectFrame = true;
      }
      bool isJumpRejection = false;
      if (!rejectFrame && lastGoodShoulderNorm != null) {
        final double jumpDist = euclid(shoulderMidNorm, lastGoodShoulderNorm!);
        final double jumpFrac = jumpDist / 1.4142135;
        if (jumpFrac > TuningParams.JUMP_REJECT_SHOULDER_FRAC) {
          // Force-accept after N consecutive rejections (squat-analyzer
          // freeze-cascade fix).
          if (consecutiveJumpRejections >=
              TuningParams.JUMP_REJECT_MAX_CONSECUTIVE) {
            // accept; reset counter
          } else {
            rejectFrame = true;
            isJumpRejection = true;
          }
        }
      }

      if (rejectFrame) {
        if (isJumpRejection) consecutiveJumpRejections += 1;
        allRawLandmarks.add(const []);
        frameRejected.add(true);
        continue;
      }

      consecutiveJumpRejections = 0;
      lastGoodShoulderNorm = shoulderMidNorm;
      allRawLandmarks.add(rawNormLandmarks);
      frameRejected.add(false);
    }
  } finally {
    await poseDetector.close();
    try {
      framesDir.deleteSync(recursive: true);
    } catch (_) {}
  }

  // ---- Smooth, then apply visibility filters for telemetry ----
  final smoothed = savitzkyGolaySmoothAll(allRawLandmarks);
  final allSmoothedLandmarks = applyVisibilityFilters(smoothed);

  // [v1.33] Frame dimensions are known now (probed on the first
  // detected frame) — fix the x-axis scale for all geometry below.
  if (_cachedW > 0 && _cachedH > 0) {
    geomAspect = _cachedW / _cachedH;
  }

  // ============================================================
  // Second pass: state machine + scoring
  // ============================================================
  int counter = 0;
  int goodReps = 0;
  int badReps = 0;
  final List<Map<String, dynamic>> repReports = [];
  final List<double> allScores = [];

  int phase = _PHASE_IDLE;
  // [v1.20 debug] Track previous phase to detect transitions for the
  // debug log. Also accumulate raw transition + count-attempt events.
  int prevPhaseForLog = _PHASE_IDLE;
  final List<Map<String, dynamic>> debugLog = [];
  int framesInPhase = 0;
  int cycleStartFrame = 0;
  // [v1.31] Frame where the ASCENT of the current cycle actually began (leaving BOTTOM).
  int ascentStartFrame = 0;
  int lastRepFrame = -10000;
  int bottomDwellFrames = 0; // for START_GATE before allowing rep start
  // [v1.1] Counts consecutive frames where TOP was detected while in IDLE.
  int idleTopDwellFrames = 0;

  // [v1.31] Fast-first-rep rescue bookkeeping.
  int bottomDwellStartFrame = 0;
  double? bottomDwellStartWristY;
  double? bottomDwellStartAboveSh; // [v1.32] same-frame midShY - wristY
  int lastShortDwellFrames = 0;
  int lastShortDwellEndFrame = -100000;
  int lastShortDwellStartFrame = 0;
  double? lastShortDwellStartWristY;
  double? lastShortDwellStartAboveSh; // [v1.32]

  // [v1.17] Universal "real bottom observed" gate.
  // [v1.31] A second qualifying path was added at the increment site (see the loop):
  int realBottomFramesObserved = 0;
  const int REAL_BOTTOM_REQUIRED = 3;

  // Smoothed scalars used for phase transitions.
  double? elbowEma;
  double? wristYEma;
  double? leanEma;
  double? shoulderYEma;
  double? torsoHeightEma;

  // [v1.3] Tracks the highest wrist position reached during the current TOP phase (smallest Y value,…
  double? topPeakWristY;

  // [v1.9] Wrist Y position at the moment a rep cycle started (i.e., when we transitioned into BOTTOM…
  double? wristYAtCycleStart;

  // [v1.5] Counter of consecutive frames where the envelope-based descent condition is satisfied.
  int wristDescentConsecFrames = 0;

  // [v1.32] Shoulder-relative ascent tracking (FIX 2).
  double? startWristAboveShNorm;
  double? peakWristAboveShNorm;

  // Current-rep accumulators.
  double currentRepMinElbow = 999.0;
  double currentRepMaxElbow = 0.0;
  double currentRepMaxLean = 0.0;
  // [v1.19] Per-cycle flag:
  // [v1.32] Hardened:
  bool currentRepWristCrossedHead = false;
  int currentRepWristOverNoseFrames = 0;
  // The most extreme observed values per rep:
  // [v1.29] The reported value is now the SECOND-worst TOP frame, not the single worst.
  double currentRepMinHeadThrough1 = 999.0; // absolute worst (spike-prone)
  double currentRepMinHeadThrough = 999.0; // second-worst (used for scoring)
  int currentRepHeadThroughFrames = 0;
  double currentRepMaxElbowFlare = 0.0;
  // [v1.6] Track maximum shoulder X-separation during the rep.
  double currentRepMaxShoulderSep = 0.0;
  // [v1.8] Count of BOTTOM frames where flare can be reliably measured (frontal/back view + both arms…
  int currentRepFlareConfidentFrames = 0;
  // [v1.33] Every confident rack-position flare sample of the rep;
  final List<double> currentRepFlareValues = [];
  final List<double> currentRepWristX = [];
  int currentRepAscendingFrames = 0;
  int currentRepDescendingFrames = 0;
  int? currentRepStartFrame;

  // Calibrated thresholds (start at init, adjust after 2 reps).
  double cfgBottomElbowMax = TuningParams.BOTTOM_ELBOW_MAX_INIT;
  double cfgTopElbowMin = TuningParams.TOP_ELBOW_MIN_INIT;
  bool calibrated = false;

  // Real-time feedback state.
  String? rtFbMsg;
  int rtFbHold = 0;
  final Map<String, String> sessionFeedbackByCat = {};
  // [v1.33] How many counted reps were scored with the frontal lockout
  // thresholds — the session lockout tip follows the majority view.
  int sessionFrontalReps = 0;

  // For telemetry post-process.
  final List<Map<String, dynamic>> frameTelemetry = [];
  final List<double?> wristYByFrame =
      List<double?>.filled(allSmoothedLandmarks.length, null);
  final List<double> rawAscentByFrame =
      List<double>.filled(allSmoothedLandmarks.length, 0.0);
  final List<Map<String, dynamic>> pulseEvents = [];
  String? repJustFinished;

  final List<int> repAscendingList = [];
  final List<int> repDescendingList = [];
  final List<double> repBarPathList = [];

  void abortRep() {
    phase = _PHASE_BOTTOM;
    framesInPhase = 0;
    bottomDwellFrames = 0;
    currentRepStartFrame = null;
    currentRepMinElbow = 999.0;
    currentRepMaxElbow = 0.0;
    currentRepMaxLean = 0.0;
    currentRepWristCrossedHead = false;
    currentRepWristOverNoseFrames = 0; // [v1.32]
    currentRepMinHeadThrough1 = 999.0;
    currentRepMinHeadThrough = 999.0;
    currentRepHeadThroughFrames = 0;
    currentRepMaxElbowFlare = 0.0;
    currentRepMaxShoulderSep = 0.0;
    currentRepFlareConfidentFrames = 0;
    currentRepFlareValues.clear(); // [v1.33]
    wristYAtCycleStart = null;
    startWristAboveShNorm = null; // [v1.32]
    peakWristAboveShNorm = null; // [v1.32]
    ascentStartFrame = 0; // [v1.31]
    currentRepWristX.clear();
    currentRepAscendingFrames = 0;
    currentRepDescendingFrames = 0;
  }

  void emitEmptyFrame(double tSec) {
    String? fb = (rtFbHold > 0 && rtFbMsg != null) ? rtFbMsg : null;
    frameTelemetry.add({
      't': tSec,
      'reps': counter,
      'depth': 0.0,
      'metric_label': 'HEIGHT',
      'metric_value': 0.0,
      'feedback': fb,
      'rep_just_finished': repJustFinished,
      'landmarks': <List<double>>[],
    });
    repJustFinished = null;
    if (rtFbHold > 0) rtFbHold -= 1;
  }

  final int totalFrames = allSmoothedLandmarks.length;

  for (int i = 0; i < totalFrames; i++) {
    final int frameIdx1Based = i + 1;
    final double tSec = allFrameTimes[i];
    final normLandmarks = allSmoothedLandmarks[i];

    if (frameRejected[i] || normLandmarks.isEmpty) {
      framesInPhase += 1;
      emitEmptyFrame(tSec);
      continue;
    }

    // ---- Extract working coordinates ----
    List<double> at(int idx) => [normLandmarks[idx][0], normLandmarks[idx][1]];

    final lShPos = at(_IDX_L_SHOULDER);
    final rShPos = at(_IDX_R_SHOULDER);
    final lElPos = at(_IDX_L_ELBOW);
    final rElPos = at(_IDX_R_ELBOW);
    final lWrPos = at(_IDX_L_WRIST);
    final rWrPos = at(_IDX_R_WRIST);
    final lHpPos = at(_IDX_L_HIP);
    final rHpPos = at(_IDX_R_HIP);

    final double lShV = normLandmarks[_IDX_L_SHOULDER][2];
    final double rShV = normLandmarks[_IDX_R_SHOULDER][2];
    final double lElV = normLandmarks[_IDX_L_ELBOW][2];
    final double rElV = normLandmarks[_IDX_R_ELBOW][2];
    final double lWrV = normLandmarks[_IDX_L_WRIST][2];
    final double rWrV = normLandmarks[_IDX_R_WRIST][2];

    // Bilateral arm angle computation.
    final double visL = (lShV + lElV + lWrV) / 3.0;
    final double visR = (rShV + rElV + rWrV) / 3.0;
    if (math.max(visL, visR) < TuningParams.VIS_THRESHOLD) {
      framesInPhase += 1;
      emitEmptyFrame(tSec);
      continue;
    }

    double? leftElbowAng;
    double? rightElbowAng;
    double? primaryWristY;
    double? primaryWristX;
    double? primaryShoulderX;
    if (visL >= TuningParams.VIS_THRESHOLD) {
      leftElbowAng = calcAngle(lShPos, lElPos, lWrPos);
    }
    if (visR >= TuningParams.VIS_THRESHOLD) {
      rightElbowAng = calcAngle(rShPos, rElPos, rWrPos);
    }

    double rawElbow;
    if (leftElbowAng != null && rightElbowAng != null) {
      // Both arms have visible landmarks per the visibility threshold.
      final bool bothElevated = leftElbowAng > 120.0 && rightElbowAng > 120.0;
      final bool armsAgree = (leftElbowAng - rightElbowAng).abs() <=
          TuningParams.BILATERAL_DISAGREE_DEG;
      if (armsAgree || bothElevated) {
        rawElbow = math.max(leftElbowAng, rightElbowAng);
        primaryWristY = math.min(lWrPos[1], rWrPos[1]); // higher = smaller Y
        primaryWristX = (lWrPos[0] + rWrPos[0]) / 2.0; // average for bar path
        primaryShoulderX = (lShPos[0] + rShPos[0]) / 2.0;
      } else {
        // Disagree wildly without both elevated → trust higher-vis side.
        if (visL >= visR) {
          rawElbow = leftElbowAng;
          primaryWristY = lWrPos[1];
          primaryWristX = lWrPos[0];
          primaryShoulderX = lShPos[0];
        } else {
          rawElbow = rightElbowAng;
          primaryWristY = rWrPos[1];
          primaryWristX = rWrPos[0];
          primaryShoulderX = rShPos[0];
        }
      }
    } else if (leftElbowAng != null) {
      rawElbow = leftElbowAng;
      primaryWristY = lWrPos[1];
      primaryWristX = lWrPos[0];
      primaryShoulderX = lShPos[0];
    } else if (rightElbowAng != null) {
      rawElbow = rightElbowAng;
      primaryWristY = rWrPos[1];
      primaryWristX = rWrPos[0];
      primaryShoulderX = rShPos[0];
    } else {
      framesInPhase += 1;
      emitEmptyFrame(tSec);
      continue;
    }

    // ---- Smooth ----
    elbowEma = emaUpdate(elbowEma, rawElbow, TuningParams.ELBOW_EMA_ALPHA);
    wristYEma =
        emaUpdate(wristYEma, primaryWristY, TuningParams.WRIST_EMA_ALPHA);

    final double midShY = (lShPos[1] + rShPos[1]) / 2.0;
    final double midHpY = (lHpPos[1] + rHpPos[1]) / 2.0;
    final double torsoH = (midShY - midHpY).abs();
    shoulderYEma =
        emaUpdate(shoulderYEma, midShY, TuningParams.SHOULDER_EMA_ALPHA);
    torsoHeightEma =
        emaUpdate(torsoHeightEma, torsoH, TuningParams.TORSO_EMA_ALPHA);

    // Torso lean from vertical (using shoulder-hip mid line).
    final double midShX = (lShPos[0] + rShPos[0]) / 2.0;
    final double midHpX = (lHpPos[0] + rHpPos[0]) / 2.0;
    // [v1.33] x scaled by geomAspect → true geometric lean angle.
    final double dxLean = (midShX - midHpX) * geomAspect;
    final double dyLean = midShY - midHpY;
    final double leanDeg =
        math.atan2(dxLean.abs(), dyLean.abs() + 1e-9) * 180.0 / math.pi;
    leanEma = emaUpdate(leanEma, leanDeg, TuningParams.LEAN_EMA_ALPHA);

    // Donut raw ascent — how far the wrist has risen from shoulder line.
    // Positive only (wrist above shoulder).
    final double rawAscent = math.max(0.0, midShY - wristYEma!);
    wristYByFrame[i] = wristYEma;
    rawAscentByFrame[i] = rawAscent;

    // ---- Compute new dimension metrics ----
    // HEAD_THROUGH:
    final double torsoUnitForMetrics = math.max(0.05, torsoHeightEma ?? 0.05);
    final List<double>? nosePos = (normLandmarks[0][2] > 0.0)
        ? [normLandmarks[0][0], normLandmarks[0][1]]
        : null;
    double? headThroughValue;
    if (nosePos != null) {
      // wristX - noseX > 0 means wrist is to the RIGHT of nose (in image coords).
      final double noseDistFromHip = (nosePos[0] - midHpX).abs() * geomAspect;
      final double wristDistFromHip =
          (primaryWristX - midHpX).abs() * geomAspect;
      headThroughValue =
          (noseDistFromHip - wristDistFromHip) / torsoUnitForMetrics;
    }

    // ELBOW_FLARE [v1.7]:
    final double bodyCenterX = (lShPos[0] + rShPos[0]) / 2.0;
    final double leftElbowOutward = math.max(
        0.0, (lElPos[0] - bodyCenterX).abs() - (lWrPos[0] - bodyCenterX).abs());
    final double rightElbowOutward = math.max(
        0.0, (rElPos[0] - bodyCenterX).abs() - (rWrPos[0] - bodyCenterX).abs());
    // [v1.33] lateral (x) excess scaled by geomAspect before dividing
    // by the torso height (y) — true geometry, see TuningParams.
    final double elbowFlareNorm =
        math.max(leftElbowOutward, rightElbowOutward) *
            geomAspect /
            torsoUnitForMetrics;

    // [v1.33] Scale-invariant view classification:
    final double shoulderSepTorso =
        (lShPos[0] - rShPos[0]).abs() * geomAspect / torsoUnitForMetrics;

    // [v1.33] "Bar at the rack position" test used to decide which BOTTOM frames may contribute flare…
    final bool wristAtRackHeight = wristYEma! >=
        midShY -
            TuningParams.WRIST_BOTTOM_MAX_ABOVE_SHOULDER * torsoUnitForMetrics;

    // ---- Update per-rep metrics ----
    if (phase == _PHASE_BOTTOM ||
        phase == _PHASE_ASCENDING ||
        phase == _PHASE_TOP ||
        phase == _PHASE_DESCENDING) {
      if (elbowEma! < currentRepMinElbow) currentRepMinElbow = elbowEma!;
      if (elbowEma! > currentRepMaxElbow) currentRepMaxElbow = elbowEma!;
      if (leanEma! > currentRepMaxLean) currentRepMaxLean = leanEma!;

      // Track head-through only at TOP (the only phase where the measurement is anatomically meaningful —…
      // [v1.29] Two-slot minimum tracker:
      if (phase == _PHASE_TOP && headThroughValue != null) {
        currentRepHeadThroughFrames += 1;
        if (headThroughValue < currentRepMinHeadThrough1) {
          currentRepMinHeadThrough = currentRepMinHeadThrough1;
          currentRepMinHeadThrough1 = headThroughValue;
        } else if (headThroughValue < currentRepMinHeadThrough) {
          currentRepMinHeadThrough = headThroughValue;
        }
      }

      // [v1.19] Track whether wrist rose above nose during TOP — the geometric "real lockout" gate at count…
      // [v1.32 HARDENED] Requires the wrist ABOVE the nose by a real margin (HEAD_CROSS_MARGIN_TORSO of…
      if (phase == _PHASE_TOP && nosePos != null && wristYEma != null) {
        final double overNoseMargin = nosePos[1] - wristYEma!;
        if (overNoseMargin >=
            TuningParams.HEAD_CROSS_MARGIN_TORSO * torsoUnitForMetrics) {
          currentRepWristOverNoseFrames += 1;
          if (currentRepWristOverNoseFrames >=
              TuningParams.HEAD_CROSS_SUSTAINED_FRAMES) {
            currentRepWristCrossedHead = true;
          }
        }
      }

      // [v1.32] Track the same-frame wrist-above-shoulder maximum while at TOP — the peak side of the…
      if (phase == _PHASE_TOP && wristYEma != null) {
        final double aboveSh = midShY - wristYEma!;
        if (peakWristAboveShNorm == null || aboveSh > peakWristAboveShNorm!) {
          peakWristAboveShNorm = aboveSh;
        }
      }

      // [v1.6] Track shoulder X-separation throughout the rep.
      if (shoulderSepTorso > currentRepMaxShoulderSep) {
        currentRepMaxShoulderSep = shoulderSepTorso;
      }

      // Track elbow flare only at BOTTOM (the rack position is where flare is meaningful and dangerous;
      // [v1.33] Two more conditions:
      if (phase == _PHASE_BOTTOM) {
        final bool viewIsFrontalOrBack =
            shoulderSepTorso >= TuningParams.FRONTAL_VIEW_SHOULDER_SEP_TORSO;
        final bool armsVisible = lElV >= TuningParams.FLARE_ARM_VIS_THRESHOLD &&
            rElV >= TuningParams.FLARE_ARM_VIS_THRESHOLD &&
            lWrV >= TuningParams.FLARE_ARM_VIS_THRESHOLD &&
            rWrV >= TuningParams.FLARE_ARM_VIS_THRESHOLD;
        if (viewIsFrontalOrBack && armsVisible && wristAtRackHeight) {
          currentRepFlareConfidentFrames += 1;
          currentRepFlareValues.add(elbowFlareNorm);
          if (elbowFlareNorm > currentRepMaxElbowFlare) {
            currentRepMaxElbowFlare = elbowFlareNorm;
          }
        }
      }

      currentRepWristX.add(primaryWristX);
    }

    // [v1.3] Update peak wrist position while at TOP.
    if (phase == _PHASE_TOP) {
      if (topPeakWristY == null || wristYEma! < topPeakWristY!) {
        topPeakWristY = wristYEma;
      }
    }

    // [v1.33] CYCLE START = LOWEST WRIST POSITION OBSERVED IN BOTTOM.
    if (phase == _PHASE_BOTTOM && wristYEma != null) {
      final double aboveShNow = midShY - wristYEma!;
      if (startWristAboveShNorm == null ||
          aboveShNow < startWristAboveShNorm!) {
        startWristAboveShNorm = aboveShNow;
      }
      if (wristYAtCycleStart == null || wristYEma! > wristYAtCycleStart!) {
        wristYAtCycleStart = wristYEma;
      }
    }

    // ---- Phase conditions ----
    final double torsoUnit = math.max(0.05, torsoHeightEma ?? 0.05);
    final bool wristNearShoulder = wristYEma! >=
        midShY - TuningParams.WRIST_BOTTOM_MAX_ABOVE_SHOULDER * torsoUnit;
    final bool wristAboveShoulder = wristYEma! <=
        midShY - TuningParams.WRIST_TOP_MIN_ABOVE_SHOULDER * torsoUnit;

    // For the BOTTOM check used during IDLE (start gate), we require BOTH conditions — to distinguish a…
    final bool isBottomStrict =
        (elbowEma! <= cfgBottomElbowMax) && wristNearShoulder;

    // [v1.12] BOTTOM detection now has a SECOND PATH via wrist descent from peak.
    final bool isBottomWristDescended = (topPeakWristY != null) &&
        ((wristYEma! - topPeakWristY!) >= 0.30 * torsoUnit);
    final bool isBottomDuringSet =
        (elbowEma! <= cfgBottomElbowMax) || isBottomWristDescended;

    // [v1.17] Universal real-bottom gate counter.
    if (isBottomStrict) {
      realBottomFramesObserved += 1;
    } else if (isBottomWristDescended && wristNearShoulder) {
      realBottomFramesObserved += 1;
    }

    // [v1.2 wrist-based TOP fallback] In practice ML Kit on FlutterFlow reports elbow angles that are…
    final bool wristWayAboveShoulder = wristYEma! <=
        midShY - TuningParams.WRIST_ALONE_TOP_THRESHOLD * torsoUnit;
    final bool isTopElbowPath =
        (elbowEma! >= cfgTopElbowMin) && wristAboveShoulder;
    final bool isTopWristPath = wristWayAboveShoulder && (elbowEma! >= 80.0);
    final bool isTop = isTopElbowPath || isTopWristPath;

    // [v1.3] Envelope-based descent detection.
    // [v1.5] The sustained-frames requirement is what distinguishes a real descent from noise.
    final double? topPeakWristYValue = topPeakWristY;
    final bool wristDescentFrameActive = (phase == _PHASE_TOP &&
        topPeakWristYValue != null &&
        (wristYEma! - topPeakWristYValue) >=
            TuningParams.WRIST_DESCENT_FROM_PEAK * torsoUnit);
    if (phase == _PHASE_TOP) {
      if (wristDescentFrameActive) {
        wristDescentConsecFrames += 1;
      } else {
        wristDescentConsecFrames = 0;
      }
    } else {
      wristDescentConsecFrames = 0;
    }
    final bool wristDescendedFromPeak =
        wristDescentConsecFrames >= TuningParams.WRIST_DESCENT_SUSTAINED_FRAMES;

    // Either signal triggers transition out of TOP:
    // [v1.33] The elbow-based exit is only allowed while the wrist is NOT in the strong-top zone…
    final bool clearlyNotTop = wristDescendedFromPeak ||
        ((elbowEma! < cfgTopElbowMin - TuningParams.HYSTERESIS_BAND) &&
            !wristWayAboveShoulder);
    final bool clearlyNotBottom =
        elbowEma! > cfgBottomElbowMax + TuningParams.HYSTERESIS_BAND;

    framesInPhase += 1;
    final bool enoughInPhase = framesInPhase >= MIN_PHASE_FRAMES;

    // ---- State machine ----
    // Detection-quality gate:
    final bool torsoVisibleEnough =
        (torsoHeightEma ?? 0) >= TuningParams.MIN_TORSO_HEIGHT_FOR_START;

    switch (phase) {
      case _PHASE_IDLE:
        // Three ways to leave IDLE:
        if (isBottomStrict && torsoVisibleEnough) {
          if (bottomDwellFrames == 0) {
            // [v1.31] Remember where this dwell started, for the
            // rescue anchor and wristYAtCycleStart.
            bottomDwellStartFrame = frameIdx1Based;
            bottomDwellStartWristY = wristYEma;
            bottomDwellStartAboveSh = midShY - wristYEma!; // [v1.32]
          }
          bottomDwellFrames += 1;
          idleTopDwellFrames = 0;
          if (bottomDwellFrames >= START_GATE_FRAMES) {
            phase = _PHASE_BOTTOM;
            framesInPhase = 0;
            cycleStartFrame = frameIdx1Based;
            ascentStartFrame = 0; // [v1.31] not yet ascending
            wristYAtCycleStart = wristYEma;
            startWristAboveShNorm = midShY - wristYEma!; // [v1.32]
            peakWristAboveShNorm = null; // [v1.32]
            currentRepStartFrame = frameIdx1Based;
            // Fresh accumulators.
            currentRepMinElbow = 999.0;
            currentRepMaxElbow = 0.0;
            currentRepMaxLean = 0.0;
            currentRepWristCrossedHead = false;
            currentRepWristOverNoseFrames = 0; // [v1.32]
            currentRepMinHeadThrough1 = 999.0;
            currentRepMinHeadThrough = 999.0;
            currentRepHeadThroughFrames = 0;
            currentRepMaxElbowFlare = 0.0;

            currentRepMaxShoulderSep = 0.0;

            currentRepFlareConfidentFrames = 0;
            currentRepFlareValues.clear(); // [v1.33]
            currentRepWristX.clear();
            currentRepAscendingFrames = 0;
            currentRepDescendingFrames = 0;
          }
        } else {
          // [v1.31] A strict-bottom dwell was just interrupted before completing the START_GATE.
          if (bottomDwellFrames > 0) {
            lastShortDwellFrames = bottomDwellFrames;
            lastShortDwellEndFrame = frameIdx1Based;
            lastShortDwellStartFrame = bottomDwellStartFrame;
            lastShortDwellStartWristY = bottomDwellStartWristY;
            lastShortDwellStartAboveSh = bottomDwellStartAboveSh; // [v1.32]
          }
          bottomDwellFrames = 0;

          // [v1.31] FAST-FIRST-REP RESCUE.
          final bool recentShortDwell = lastShortDwellFrames >= 2 &&
              (frameIdx1Based - lastShortDwellEndFrame) <= RESCUE_WINDOW_FRAMES;
          if (isTop && torsoVisibleEnough && recentShortDwell) {
            debugLog.add({
              'event': 'idle_fast_first_rep_rescue',
              'frame': frameIdx1Based,
              't': double.parse(tSec.toStringAsFixed(3)),
              'dwellFrames': lastShortDwellFrames,
              'dwellStartFrame': lastShortDwellStartFrame,
              'dwellEndFrame': lastShortDwellEndFrame,
            });
            phase = _PHASE_TOP;
            topPeakWristY = wristYEma; // [v1.3] envelope tracking
            wristDescentConsecFrames = 0; // [v1.5] reset sustained counter
            framesInPhase = 0;
            cycleStartFrame = lastShortDwellStartFrame;
            ascentStartFrame = lastShortDwellStartFrame; // [v1.31]
            wristYAtCycleStart = lastShortDwellStartWristY ?? wristYEma;
            startWristAboveShNorm = // [v1.32] from the observed bottom
                lastShortDwellStartAboveSh ?? (midShY - wristYEma!);
            peakWristAboveShNorm = midShY - wristYEma!; // [v1.32]
            currentRepStartFrame = lastShortDwellStartFrame;
            currentRepMinElbow = 999.0;
            currentRepMaxElbow = elbowEma!;
            currentRepMaxLean = leanEma ?? 0.0;
            // [v1.32] Hardened head-cross: seed the sustained counter
            // instead of arming the flag from a single frame.
            currentRepWristCrossedHead = false;
            currentRepWristOverNoseFrames = (nosePos != null &&
                    wristYEma != null &&
                    (nosePos[1] - wristYEma!) >=
                        TuningParams.HEAD_CROSS_MARGIN_TORSO * torsoUnit)
                ? 1
                : 0;
            currentRepMinHeadThrough1 = headThroughValue ?? 999.0;
            currentRepMinHeadThrough = 999.0;
            currentRepHeadThroughFrames = (headThroughValue != null) ? 1 : 0;
            currentRepMaxElbowFlare = 0.0;
            currentRepMaxShoulderSep = 0.0;
            currentRepFlareConfidentFrames = 0;
            currentRepFlareValues.clear(); // [v1.33]
            currentRepWristX.clear();
            currentRepAscendingFrames = 0;
            currentRepDescendingFrames = 0;
            lastShortDwellFrames = 0;
            idleTopDwellFrames = 0;
            break;
          }

          // For IDLE→TOP, use the STRICT lockout gate (160°+) — see TuningParams.IDLE_TO_TOP_STRICT_ELBOW_MIN…
          final bool isStrictTop = elbowEma! >=
                  TuningParams.IDLE_TO_TOP_STRICT_ELBOW_MIN &&
              wristYEma! <=
                  midShY -
                      TuningParams.IDLE_TO_TOP_STRICT_WRIST_ABOVE * torsoUnit;
          if (isStrictTop && torsoVisibleEnough) {
            idleTopDwellFrames += 1;
            if (idleTopDwellFrames >=
                TuningParams.IDLE_TO_TOP_MIN_DWELL_SEC_EQUIV) {
              // Confirmed strict lockout dwell — user is mid-set OR standing at the rack with the bar already…
              phase = _PHASE_TOP;
              topPeakWristY = wristYEma; // [v1.3] envelope tracking
              wristDescentConsecFrames = 0; // [v1.5] reset sustained counter
              framesInPhase = 0;
              cycleStartFrame = frameIdx1Based;
              ascentStartFrame = frameIdx1Based; // [v1.31]
              wristYAtCycleStart = wristYEma;
              startWristAboveShNorm = midShY - wristYEma!; // [v1.32]
              peakWristAboveShNorm = midShY - wristYEma!; // [v1.32]
              currentRepStartFrame = frameIdx1Based;
              currentRepMinElbow = 999.0;
              currentRepMaxElbow = elbowEma!;
              currentRepMaxLean = leanEma ?? 0.0;
              // [v1.32] Hardened head-cross:
              currentRepWristCrossedHead = false;
              currentRepWristOverNoseFrames = (nosePos != null &&
                      wristYEma != null &&
                      (nosePos[1] - wristYEma!) >=
                          TuningParams.HEAD_CROSS_MARGIN_TORSO * torsoUnit)
                  ? 1
                  : 0;
              // [v1.29] Two-slot tracker:
              currentRepMinHeadThrough1 = headThroughValue ?? 999.0;
              currentRepMinHeadThrough = 999.0;
              currentRepHeadThroughFrames = (headThroughValue != null) ? 1 : 0;
              currentRepMaxElbowFlare = 0.0;

              currentRepMaxShoulderSep = 0.0; // we never observed bottom

              currentRepFlareConfidentFrames = 0;
              currentRepFlareValues.clear(); // [v1.33]
              currentRepWristX.clear();
              currentRepAscendingFrames = 0;
              currentRepDescendingFrames = 0;
              idleTopDwellFrames = 0;
            }
          } else {
            idleTopDwellFrames = 0;
          }
        }
        break;

      case _PHASE_BOTTOM:
        // [v1.1 fast-press shortcut] If the press is so quick that the ASCENDING phase is briefer than a…
        if (isTop && enoughInPhase) {
          phase = _PHASE_TOP;
          topPeakWristY = wristYEma; // [v1.3] envelope tracking
          // [v1.32] Seed the same-frame above-shoulder peak (kept as max across the whole rep — see the tracker…
          final double _aboveShEntry = midShY - wristYEma!;
          if (peakWristAboveShNorm == null ||
              _aboveShEntry > peakWristAboveShNorm!) {
            peakWristAboveShNorm = _aboveShEntry;
          }
          wristDescentConsecFrames = 0; // [v1.5] reset sustained counter
          framesInPhase = 0;
          ascentStartFrame = frameIdx1Based; // [v1.31] motion begins here
          currentRepAscendingFrames = 0;
        } else if (clearlyNotBottom && enoughInPhase) {
          phase = _PHASE_ASCENDING;
          framesInPhase = 0;
          ascentStartFrame = frameIdx1Based; // [v1.31] motion begins here
          currentRepAscendingFrames = 0;
        }
        break;

      case _PHASE_ASCENDING:
        currentRepAscendingFrames += 1;
        // No MIN_PHASE_FRAMES check on going to TOP — the lockout peak can be a single frame in a fast press,…
        if (isTop) {
          phase = _PHASE_TOP;
          topPeakWristY = wristYEma; // [v1.3] envelope tracking
          // [v1.32] Seed/extend the same-frame above-shoulder peak.
          final double _aboveShEntry = midShY - wristYEma!;
          if (peakWristAboveShNorm == null ||
              _aboveShEntry > peakWristAboveShNorm!) {
            peakWristAboveShNorm = _aboveShEntry;
          }
          wristDescentConsecFrames = 0; // [v1.5] reset sustained counter
          framesInPhase = 0;
        } else if (isBottomDuringSet && enoughInPhase) {
          // Came back down without ever reaching top — false start.
          abortRep();
          cycleStartFrame = frameIdx1Based;
          wristYAtCycleStart = wristYEma;
          startWristAboveShNorm = midShY - wristYEma!; // [v1.32]
          currentRepStartFrame = frameIdx1Based;
        }
        break;

      case _PHASE_TOP:
        // Same as ASCENDING→TOP: the descent starts immediately after
        // the lockout peak, sometimes a single frame later. Don't wait.
        if (clearlyNotTop) {
          phase = _PHASE_DESCENDING;
          framesInPhase = 0;
          currentRepDescendingFrames = 0;
        }
        break;

      case _PHASE_DESCENDING:
        currentRepDescendingFrames += 1;
        if (isBottomDuringSet && enoughInPhase) {
          // Rep complete.
          final int cycleLen = frameIdx1Based - cycleStartFrame;
          final bool durationOk = cycleLen >= MIN_CYCLE_FRAMES;
          final bool refractoryOk =
              (frameIdx1Based - lastRepFrame) >= REFRACTORY_FRAMES;

          // [v1.9] Real-ascent gate.
          final double ascentMagnitudeAbs =
              (wristYAtCycleStart != null && topPeakWristY != null)
                  ? wristYAtCycleStart! - topPeakWristY!
                  : 0.0;
          // [v1.32] The GATE now uses the SHOULDER-RELATIVE ascent:
          final double ascentMagnitude =
              (startWristAboveShNorm != null && peakWristAboveShNorm != null)
                  ? peakWristAboveShNorm! - startWristAboveShNorm!
                  : ascentMagnitudeAbs; // fallback: pre-v1.32 behavior
          final bool ascentOk = ascentMagnitude >=
              TuningParams.MIN_RISE_FROM_CYCLE_START * torsoUnit;

          // [v1.18] Peak-height gate.
          // [v1.19] PRIMARY check is now wristCrossedHead — the wrist must have risen above the nose landmark…
          final bool peakReachedRealLockout = currentRepWristCrossedHead ||
              (topPeakWristY != null &&
                  topPeakWristY! <= midShY - 0.50 * torsoUnit);

          // [v1.21] Cycle-start hand position gate.
          final bool cycleStartedAtRealOHPSetup =
              (wristYAtCycleStart != null) &&
                  (wristYAtCycleStart! <= midShY + 0.30 * torsoUnit);

          // [v1.31] Motion-only cycle length (ascent start → count).
          final int motionLenFrames = frameIdx1Based -
              ((ascentStartFrame > 0) ? ascentStartFrame : cycleStartFrame);

          // [v1.20 debug] Log every count attempt with full gate values.
          final double _ascentInTorso =
              torsoUnit > 0 ? (ascentMagnitude / torsoUnit) : 0.0;
          final double _peakAboveShoulderNorm =
              (topPeakWristY != null) ? (midShY - topPeakWristY!) : 0.0;
          final bool _fallbackPeakCheck = topPeakWristY != null &&
              torsoUnit > 0 &&
              topPeakWristY! <= midShY - 0.50 * torsoUnit;
          final List<String> _failReasons = [];
          if (!durationOk) _failReasons.add('duration');
          if (!refractoryOk) _failReasons.add('refractory');
          if (!ascentOk) _failReasons.add('ascent<15%torso');
          if (realBottomFramesObserved < REAL_BOTTOM_REQUIRED) {
            _failReasons.add('realBottomObs<$REAL_BOTTOM_REQUIRED');
          }
          if (!peakReachedRealLockout) _failReasons.add('peakNotOverhead');
          // [v1.22] cycleStartedAtRealOHPSetup no longer affects the count outcome — it's still computed and…
          final bool _willCount = _failReasons.isEmpty;
          debugLog.add({
            'event': 'count_attempt',
            'frame': frameIdx1Based,
            't': double.parse(tSec.toStringAsFixed(3)),
            'cycleStartFrame': cycleStartFrame,
            'cycleLengthFrames': frameIdx1Based - cycleStartFrame,
            'ascentStartFrame': ascentStartFrame, // [v1.31]
            'motionLengthFrames': motionLenFrames, // [v1.31]
            'wristYAtCycleStart': wristYAtCycleStart != null
                ? double.parse(wristYAtCycleStart!.toStringAsFixed(4))
                : null,
            'topPeakWristY': topPeakWristY != null
                ? double.parse(topPeakWristY!.toStringAsFixed(4))
                : null,
            'midShY': double.parse(midShY.toStringAsFixed(4)),
            'torsoUnit': double.parse(torsoUnit.toStringAsFixed(4)),
            'ascentMagnitude': double.parse(ascentMagnitude.toStringAsFixed(4)),
            'ascentInTorso': double.parse(_ascentInTorso.toStringAsFixed(3)),
            // [v1.32] absolute (pre-v1.32) ascent for comparison, and
            // the raw endpoints of the relative measure.
            'ascentAbs': double.parse(ascentMagnitudeAbs.toStringAsFixed(4)),
            'startAboveShNorm': startWristAboveShNorm != null
                ? double.parse(startWristAboveShNorm!.toStringAsFixed(4))
                : null,
            'peakAboveShNormSameFrame': peakWristAboveShNorm != null
                ? double.parse(peakWristAboveShNorm!.toStringAsFixed(4))
                : null,
            'wristOverNoseFrames': currentRepWristOverNoseFrames,
            'peakAboveShoulderNorm':
                double.parse(_peakAboveShoulderNorm.toStringAsFixed(4)),
            'peakAboveShoulderTorso': torsoUnit > 0
                ? double.parse(
                    (_peakAboveShoulderNorm / torsoUnit).toStringAsFixed(3))
                : null,
            'wristCrossedHead': currentRepWristCrossedHead,
            'fallbackPeakCheck50pcTorso': _fallbackPeakCheck,
            'realBottomFramesObserved': realBottomFramesObserved,
            'currentRepMaxElbow':
                double.parse(currentRepMaxElbow.toStringAsFixed(1)),
            'durationOk': durationOk,
            'refractoryOk': refractoryOk,
            'ascentOk': ascentOk,
            'peakReachedRealLockout': peakReachedRealLockout,
            'cycleStartedAtRealOHPSetup': cycleStartedAtRealOHPSetup,
            'willCount': _willCount,
            'failReasons': _failReasons,
            'counterBefore': counter,
          });

          if (durationOk &&
              refractoryOk &&
              ascentOk &&
              realBottomFramesObserved >= REAL_BOTTOM_REQUIRED &&
              peakReachedRealLockout) {
            // ---- Score it ----
            final double depthScore = scoreInterp(
              currentRepMinElbow,
              TuningParams.DEPTH_TARGET_ANGLE,
              TuningParams.DEPTH_OK_ANGLE,
              TuningParams.DEPTH_OK_ANGLE + 20.0,
              higherIsBetter: false,
            );
            // [v1.33] View-dependent lockout thresholds.
            final bool isFrontalView = currentRepMaxShoulderSep >
                TuningParams.FRONTAL_VIEW_SHOULDER_SEP_TORSO;
            final double lockoutTargetUsed = isFrontalView
                ? TuningParams.LOCKOUT_TARGET_ANGLE_FRONTAL
                : TuningParams.LOCKOUT_TARGET_ANGLE;
            final double lockoutOkUsed = isFrontalView
                ? TuningParams.LOCKOUT_OK_ANGLE_FRONTAL
                : TuningParams.LOCKOUT_OK_ANGLE;
            if (isFrontalView) sessionFrontalReps += 1;
            final double lockoutScore = scoreInterp(
              currentRepMaxElbow,
              lockoutTargetUsed,
              lockoutOkUsed,
              lockoutOkUsed - 15.0,
              higherIsBetter: true,
            );
            final double leanScore = scoreInterp(
              currentRepMaxLean,
              TuningParams.LEAN_TARGET_MAX,
              TuningParams.LEAN_OK_MAX,
              TuningParams.LEAN_BAD_MAX,
              higherIsBetter: false,
            );
            // HEAD_THROUGH score:
            // [v1.29] Third suppression condition:
            final bool headThroughReliable = currentRepHeadThroughFrames >=
                TuningParams.HEAD_THROUGH_MIN_FRAMES;
            final double headThroughScore;
            if (currentRepMinHeadThrough > 100.0 ||
                isFrontalView ||
                !headThroughReliable) {
              headThroughScore =
                  7.0; // no reliable observation OR frontal view → neutral
            } else {
              headThroughScore = scoreInterp(
                currentRepMinHeadThrough,
                TuningParams.HEAD_THROUGH_TARGET,
                TuningParams.HEAD_THROUGH_OK,
                TuningParams.HEAD_THROUGH_BAD,
                higherIsBetter: true,
              );
            }
            // ELBOW_FLARE score [v1.8]:
            // [v1.33] Scored on the MEDIAN of the rack-position samples (currentRepFlareValues), not the single…
            final double elbowFlareScore;
            final bool flareReliable = currentRepFlareConfidentFrames >=
                TuningParams.MIN_FLARE_CONFIDENT_FRAMES;
            double elbowFlareScored = currentRepMaxElbowFlare;
            if (currentRepFlareValues.isNotEmpty) {
              final List<double> sortedFlare =
                  List<double>.from(currentRepFlareValues)..sort();
              elbowFlareScored = sortedFlare[sortedFlare.length ~/ 2];
            }
            if (!flareReliable) {
              elbowFlareScore = 7.0; // no reliable observation, neutral
            } else {
              elbowFlareScore = scoreInterp(
                elbowFlareScored,
                TuningParams.ELBOW_FLARE_TARGET,
                TuningParams.ELBOW_FLARE_OK,
                TuningParams.ELBOW_FLARE_BAD,
                higherIsBetter: false,
              );
            }
            final double barPathDev = stddev(currentRepWristX);
            final double barPathScore = scoreInterp(
              barPathDev,
              TuningParams.BAR_PATH_TARGET,
              TuningParams.BAR_PATH_OK,
              TuningParams.BAR_PATH_OK + 0.03,
              higherIsBetter: false,
            );
            final double overall = TuningParams.W_DEPTH * depthScore +
                TuningParams.W_LOCKOUT * lockoutScore +
                TuningParams.W_LEAN * leanScore +
                TuningParams.W_HEAD_THROUGH * headThroughScore +
                TuningParams.W_ELBOW_FLARE * elbowFlareScore +
                TuningParams.W_BAR_PATH * barPathScore;

            final List<String> issues = [];
            if (depthScore < TuningParams.REP_FEEDBACK_SCORE_THR)
              issues.add(FB_DEPTH);
            if (lockoutScore < TuningParams.REP_FEEDBACK_SCORE_THR)
              issues.add(FB_LOCKOUT);
            if (leanScore < TuningParams.REP_FEEDBACK_SCORE_THR)
              issues.add(FB_LEAN);
            // Only surface HEAD_THROUGH if we actually observed it (otherwise the score is the "no observation"…
            if (currentRepMinHeadThrough < 100.0 &&
                !isFrontalView &&
                headThroughReliable &&
                headThroughScore < TuningParams.REP_FEEDBACK_SCORE_THR) {
              issues.add(FB_HEAD_THROUGH);
            }
            // [v1.8] Only surface ELBOW_FLARE if the measurement is reliable (enough BOTTOM frames with…
            if (flareReliable &&
                elbowFlareScore < TuningParams.REP_FEEDBACK_SCORE_THR) {
              issues.add(FB_ELBOW_FLARE);
            }
            if (barPathScore < TuningParams.REP_FEEDBACK_SCORE_THR)
              issues.add(FB_BAR_PATH);

            counter += 1;
            lastRepFrame = frameIdx1Based;

            repReports.add({
              'rep_index': counter,
              'score': double.parse(overall.toStringAsFixed(1)),
              // [v1.14] A rep is "good" only when it has ZERO form issues (= passed every category's feedback…
              'good': issues.isEmpty,
              'depth_score': double.parse(depthScore.toStringAsFixed(1)),
              'lockout_score': double.parse(lockoutScore.toStringAsFixed(1)),
              'lean_score': double.parse(leanScore.toStringAsFixed(1)),
              'head_through_score':
                  double.parse(headThroughScore.toStringAsFixed(1)),
              'elbow_flare_score':
                  double.parse(elbowFlareScore.toStringAsFixed(1)),
              'bar_path_score': double.parse(barPathScore.toStringAsFixed(1)),
              'bottom_elbow':
                  double.parse(currentRepMinElbow.toStringAsFixed(1)),
              'top_elbow': double.parse(currentRepMaxElbow.toStringAsFixed(1)),
              'max_lean': double.parse(currentRepMaxLean.toStringAsFixed(1)),
              'min_head_through': (currentRepMinHeadThrough > 100.0)
                  ? null
                  : double.parse(currentRepMinHeadThrough.toStringAsFixed(3)),
              'head_through_frames': currentRepHeadThroughFrames,
              'max_elbow_flare': flareReliable
                  ? double.parse(currentRepMaxElbowFlare.toStringAsFixed(3))
                  : null,
              // [v1.33] the value that was actually scored (median of
              // the rack-position samples) + how many samples it had.
              'elbow_flare_scored': flareReliable
                  ? double.parse(elbowFlareScored.toStringAsFixed(3))
                  : null,
              'elbow_flare_frames': currentRepFlareConfidentFrames,
              'frontal_view': isFrontalView,
              'bar_path_deviation': double.parse(barPathDev.toStringAsFixed(3)),
              'start_frame': currentRepStartFrame ?? cycleStartFrame,
              'end_frame': frameIdx1Based,
              'ascending_frames': currentRepAscendingFrames,
              'descending_frames': currentRepDescendingFrames,
              'issues': issues,
            });
            allScores.add(overall);
            repAscendingList.add(currentRepAscendingFrames);
            repDescendingList.add(currentRepDescendingFrames);
            repBarPathList.add(barPathDev);

            // Aggregate session feedback (strongest issue per category).
            for (final fb in issues) {
              final cat = FEEDBACK_CATEGORY[fb] ?? 'other';
              final cur = sessionFeedbackByCat[cat];
              if (cur == null ||
                  (FB_SEVERITY[fb] ?? 1) > (FB_SEVERITY[cur] ?? 1)) {
                sessionFeedbackByCat[cat] = fb;
              }
            }

            // Queue a pulse — post-process places it at the visual peak.
            pulseEvents.add({
              'countFrameIdx': frameIdx1Based,
              'prevRepCount': counter - 1,
              'newRepCount': counter,
              'overallScore': overall,
              'issues': List<String>.from(issues),
              // [v1.23] Peak height (above-shoulder, normalized) used by the post-process outlier filter to…
              'peakAboveShoulderNorm': peakWristAboveShNorm ??
                  ((topPeakWristY != null) ? (midShY - topPeakWristY!) : 0.0),
              // [v1.24] Ascent magnitude in torso units.
              'ascentInTorso':
                  (torsoUnit > 0) ? (ascentMagnitude / torsoUnit) : 0.0,
              // [v1.27] Cycle length in frames. Kept for debug
              // comparability with older logs.
              'cycleLengthFrames': frameIdx1Based - cycleStartFrame,
              // [v1.31] MOTION-ONLY length (ascent start → count).
              'motionLengthFrames': motionLenFrames,
              // [v1.31] Geometric lockout proof for the peak filter:
              'wristCrossedHead': currentRepWristCrossedHead,
            });

            // Calibration.
            if (!calibrated && counter >= TuningParams.CALIBRATION_REPS) {
              double sumBottom = 0.0, sumTop = 0.0;
              for (final r in repReports) {
                sumBottom += (r['bottom_elbow'] as num).toDouble();
                sumTop += (r['top_elbow'] as num).toDouble();
              }
              final avgBottom = sumBottom / repReports.length;
              final avgTop = sumTop / repReports.length;
              if (avgBottom < cfgBottomElbowMax + 20.0) {
                cfgBottomElbowMax =
                    TuningParams.CALIBRATION_ADJUSTMENT * avgBottom +
                        (1 - TuningParams.CALIBRATION_ADJUSTMENT) *
                            cfgBottomElbowMax;
                cfgBottomElbowMax = cfgBottomElbowMax.clamp(80.0, 130.0);
              }
              if (avgTop > cfgTopElbowMin - 15.0) {
                cfgTopElbowMin = TuningParams.CALIBRATION_ADJUSTMENT * avgTop +
                    (1 - TuningParams.CALIBRATION_ADJUSTMENT) * cfgTopElbowMin;
                // Clamp:
                cfgTopElbowMin = cfgTopElbowMin.clamp(115.0, 165.0);
              }
              calibrated = true;
            }

            // Real-time feedback for this rep (strongest issue).
            if (issues.isNotEmpty) {
              String strongest = issues.first;
              int bestSev = FB_SEVERITY[strongest] ?? 1;
              for (final f in issues) {
                final s = FB_SEVERITY[f] ?? 1;
                if (s > bestSev) {
                  bestSev = s;
                  strongest = f;
                }
              }
              rtFbMsg = strongest;
              rtFbHold = RT_FB_HOLD_FRAMES;
            }
          }

          // Begin next cycle.
          phase = _PHASE_BOTTOM;
          framesInPhase = 0;
          cycleStartFrame = frameIdx1Based;
          ascentStartFrame = 0; // [v1.31] next cycle hasn't ascended yet
          wristYAtCycleStart = wristYEma;
          startWristAboveShNorm = midShY - wristYEma!; // [v1.32]
          peakWristAboveShNorm = null; // [v1.32]
          currentRepStartFrame = frameIdx1Based;
          currentRepMinElbow = 999.0;
          currentRepMaxElbow = 0.0;
          currentRepMaxLean = 0.0;
          currentRepWristCrossedHead = false;
          currentRepWristOverNoseFrames = 0; // [v1.32]
          currentRepMinHeadThrough1 = 999.0;
          currentRepMinHeadThrough = 999.0;
          currentRepHeadThroughFrames = 0;
          currentRepMaxElbowFlare = 0.0;

          currentRepMaxShoulderSep = 0.0;

          currentRepFlareConfidentFrames = 0;
          currentRepFlareValues.clear(); // [v1.33]
          currentRepWristX.clear();
          currentRepAscendingFrames = 0;
          currentRepDescendingFrames = 0;
        } else if (isTop && enoughInPhase) {
          // Bounce back up — go back to TOP and wait for real descent.
          phase = _PHASE_TOP;
          topPeakWristY = wristYEma; // [v1.3] envelope tracking
          // [v1.32] Extend (never reset) the above-shoulder peak — the bounce belongs to the same rep, so the…
          final double _aboveShEntry = midShY - wristYEma!;
          if (peakWristAboveShNorm == null ||
              _aboveShEntry > peakWristAboveShNorm!) {
            peakWristAboveShNorm = _aboveShEntry;
          }
          wristDescentConsecFrames = 0; // [v1.5] reset sustained counter
          framesInPhase = 0;
        }
        break;
    }

    // ---- Emit telemetry ----
    String? fb = (rtFbHold > 0 && rtFbMsg != null) ? rtFbMsg : null;
    frameTelemetry.add({
      't': tSec,
      'reps': counter,
      'depth': 0.0, // donut value — filled in post-process
      'metric_label': 'HEIGHT',
      'metric_value': 0.0,
      'feedback': fb,
      'rep_just_finished': repJustFinished,
      'landmarks': normLandmarks,
    });
    repJustFinished = null;
    if (rtFbHold > 0) rtFbHold -= 1;

    // [v1.20 debug] Log phase transitions as they happen.
    if (phase != prevPhaseForLog) {
      const Map<int, String> _phaseNames = {
        _PHASE_IDLE: 'IDLE',
        _PHASE_BOTTOM: 'BOTTOM',
        _PHASE_ASCENDING: 'ASCENDING',
        _PHASE_TOP: 'TOP',
        _PHASE_DESCENDING: 'DESCENDING',
      };
      final double _wristAboveShoulderNorm =
          (wristYEma != null) ? (midShY - wristYEma!) : 0.0;
      debugLog.add({
        'event': 'transition',
        'frame': frameIdx1Based,
        't': double.parse(tSec.toStringAsFixed(3)),
        'from': _phaseNames[prevPhaseForLog] ?? 'UNK',
        'to': _phaseNames[phase] ?? 'UNK',
        'wristY': wristYEma != null
            ? double.parse(wristYEma!.toStringAsFixed(4))
            : null,
        'midShY': double.parse(midShY.toStringAsFixed(4)),
        'noseY': nosePos != null
            ? double.parse(nosePos[1].toStringAsFixed(4))
            : null,
        'wristAboveShoulderNorm':
            double.parse(_wristAboveShoulderNorm.toStringAsFixed(4)),
        'wristAboveShoulderTorso': torsoUnit > 0
            ? double.parse(
                (_wristAboveShoulderNorm / torsoUnit).toStringAsFixed(3))
            : null,
        'wristAboveNose': (wristYEma != null && nosePos != null)
            ? (wristYEma! < nosePos[1])
            : null,
        'torsoUnit': double.parse(torsoUnit.toStringAsFixed(4)),
        'elbow': elbowEma != null
            ? double.parse(elbowEma!.toStringAsFixed(1))
            : null,
        'wristCrossedHeadFlag': currentRepWristCrossedHead,
        'realBottomObs': realBottomFramesObserved,
        'counter': counter,
      });
      prevPhaseForLog = phase;
    }
  }

  // ============================================================
  // POST-PROCESS 1: Donut normalization (same approach as pullup)
  // ============================================================
  final List<double> donutRaw = List<double>.filled(frameTelemetry.length, 0.0);
  for (int i = 0; i < frameTelemetry.length; i++) {
    donutRaw[i] = (rawAscentByFrame[i] / TuningParams.DONUT_FULL_ASCENT)
        .clamp(0.0, 1.0)
        .toDouble();
  }
  final List<double> fwd = List<double>.filled(donutRaw.length, 0.0);
  final List<double> bwd = List<double>.filled(donutRaw.length, 0.0);
  if (donutRaw.isNotEmpty) {
    fwd[0] = donutRaw[0];
    for (int i = 1; i < donutRaw.length; i++) {
      fwd[i] = TuningParams.DONUT_SMOOTH_ALPHA * donutRaw[i] +
          (1 - TuningParams.DONUT_SMOOTH_ALPHA) * fwd[i - 1];
    }
    bwd[donutRaw.length - 1] = donutRaw[donutRaw.length - 1];
    for (int i = donutRaw.length - 2; i >= 0; i--) {
      bwd[i] = TuningParams.DONUT_SMOOTH_ALPHA * donutRaw[i] +
          (1 - TuningParams.DONUT_SMOOTH_ALPHA) * bwd[i + 1];
    }
  }
  for (int i = 0; i < frameTelemetry.length; i++) {
    final smoothed = ((fwd[i] + bwd[i]) / 2.0).clamp(0.0, 1.0).toDouble();
    final finalVal = math.max(smoothed, donutRaw[i]);
    frameTelemetry[i]['depth'] = finalVal;
    frameTelemetry[i]['metric_value'] = finalVal;
  }

  // ============================================================
  // POST-PROCESS 2:
  // ============================================================
  for (final f in frameTelemetry) {
    f['rep_just_finished'] = null;
    f['feedback'] = null;
  }
  final int holdFramesAtPeak = math.max(2, (1.5 / dt).round());

  // [v1.26] Re-enables the peak-based post-process filter from v1.23.
  // [v1.28] BEFORE the filter runs, annotate every pulseEvent with its PREVIOUS ORIGINAL countFrameIdx.
  for (int e = 0; e < pulseEvents.length; e++) {
    pulseEvents[e]['_prevOrigCountFrameIdx'] =
        (e > 0) ? (pulseEvents[e - 1]['countFrameIdx'] as int) : 0;
  }

  if (pulseEvents.length >= 2) {
    double _maxPeak = 0.0;
    for (final ev in pulseEvents) {
      final double p = (ev['peakAboveShoulderNorm'] as num?)?.toDouble() ?? 0.0;
      if (p > _maxPeak) _maxPeak = p;
    }
    final double _peakThreshold = 0.70 * _maxPeak;

    // [v1.27] Compute median cycle length, excluding the longest cycle (which would be a walk-up cycle if…
    final List<int> _cycleLengths = [];
    for (final ev in pulseEvents) {
      _cycleLengths.add((ev['motionLengthFrames'] as num?)?.toInt() ??
          (ev['cycleLengthFrames'] as num?)?.toInt() ??
          0);
    }
    final List<int> _sortedLengths = List<int>.from(_cycleLengths)..sort();
    // Use the median of the SHORTER half (= the more typical lengths).
    // This protects against scenarios where MOST cycles are long.
    final int _medianIdx = _sortedLengths.length ~/ 4; // 25th percentile
    final int _medianLength = _sortedLengths[_medianIdx];
    // [v1.31] Absolute floor:
    final int _absFloorFrames =
        math.max(1, (TuningParams.CYCLE_LEN_FILTER_MIN_SEC / dt).round());
    final int _lengthThreshold =
        math.max(_medianLength * 3, _absFloorFrames).clamp(1, 1 << 30);

    final List<Map<String, dynamic>> _keptPulseEvents = [];
    final List<int> _removedIndices = [];
    for (int e = 0; e < pulseEvents.length; e++) {
      final ev = pulseEvents[e];
      final double p = (ev['peakAboveShoulderNorm'] as num?)?.toDouble() ?? 0.0;
      final double a = (ev['ascentInTorso'] as num?)?.toDouble() ?? 0.0;
      final int len = (ev['motionLengthFrames'] as num?)?.toInt() ??
          (ev['cycleLengthFrames'] as num?)?.toInt() ??
          0;
      final bool _crossedHead = (ev['wristCrossedHead'] == true);
      final List<String> reasons = [];
      // [v1.26] Peak filter — catches partial-press unracks.
      if (p < _peakThreshold && !_crossedHead) {
        reasons.add('peakBelow70pcMax');
      }
      // [v1.27] Length filter — catches walk-up cycles even when the peak height matches real reps (because…
      if (len > _lengthThreshold) {
        reasons.add('motionLen>${_lengthThreshold}f(3xMedianOr4s)');
      }
      if (reasons.isEmpty) {
        _keptPulseEvents.add(ev);
      } else {
        _removedIndices.add(e);
        debugLog.add({
          'event': 'post_process_filter_removed',
          'cycleIdx': e,
          'countFrameIdx': ev['countFrameIdx'],
          'peakAboveShoulderNorm': double.parse(p.toStringAsFixed(4)),
          'ascentInTorso': double.parse(a.toStringAsFixed(3)),
          'motionLengthFrames': len,
          'cycleLengthFrames': (ev['cycleLengthFrames'] as num?)?.toInt() ?? 0,
          'wristCrossedHead': _crossedHead,
          'maxPeak': double.parse(_maxPeak.toStringAsFixed(4)),
          'peakThreshold': double.parse(_peakThreshold.toStringAsFixed(4)),
          'medianLength': _medianLength,
          'absFloorFrames': _absFloorFrames,
          'lengthThreshold': _lengthThreshold,
          'reasons': reasons,
        });
      }
    }

    // Renumber rep counts and remove corresponding repReports.
    if (_removedIndices.isNotEmpty) {
      // Build a new repReports list with the filtered entries removed
      // and the rep numbers renumbered.
      final List<Map<String, dynamic>> _keptRepReports = [];
      for (int i = 0; i < repReports.length; i++) {
        if (!_removedIndices.contains(i)) {
          final r = Map<String, dynamic>.from(repReports[i]);
          r['rep_index'] = _keptRepReports.length + 1;
          _keptRepReports.add(r);
        }
      }
      repReports
        ..clear()
        ..addAll(_keptRepReports);

      // Renumber pulseEvents' newRepCount / prevRepCount.
      for (int i = 0; i < _keptPulseEvents.length; i++) {
        _keptPulseEvents[i]['newRepCount'] = i + 1;
        _keptPulseEvents[i]['prevRepCount'] = i;
      }

      // Re-tally good/bad and final counter.
      counter = _keptPulseEvents.length;
      goodReps = 0;
      badReps = 0;
      for (final r in repReports) {
        final bool isGood = (r['good'] as bool?) ?? false;
        if (isGood) {
          goodReps += 1;
        } else {
          badReps += 1;
        }
      }

      pulseEvents
        ..clear()
        ..addAll(_keptPulseEvents);
    }
  }

  for (int e = 0; e < pulseEvents.length; e++) {
    final ev = pulseEvents[e];
    final int countIdx = (ev['countFrameIdx'] as int) - 1;
    if (countIdx < 0 || countIdx >= frameTelemetry.length) continue;
    // [v1.28] Use the previous ORIGINAL countFrameIdx (set before the filter ran) rather than computing…
    final int prevOrig1Based = (ev['_prevOrigCountFrameIdx'] as int?) ?? 0;
    final int prevCountIdx = (prevOrig1Based > 0) ? (prevOrig1Based - 1) : 0;

    // [v1.4] Bound the visual peak search to a recent window around the count frame.
    final int searchWindowFrames = math.max(36, MIN_CYCLE_FRAMES * 6);
    final int searchStart =
        math.max(prevCountIdx, countIdx - searchWindowFrames);

    int peakIdx = countIdx;
    double? minWristY;
    for (int j = math.max(0, searchStart); j <= countIdx; j++) {
      final wY = (j < wristYByFrame.length) ? wristYByFrame[j] : null;
      if (wY == null) continue;
      if (minWristY == null || wY < minWristY) {
        minWristY = wY;
        peakIdx = j;
      }
    }
    ev['peakIdx'] = peakIdx;

    // Rewrite the 'reps' field on frames from peak forward to the next peak (or end) — so the counter…
    final int nextPeakIdx = (e + 1 < pulseEvents.length)
        ? (pulseEvents[e + 1]['countFrameIdx'] as int) - 1
        : frameTelemetry.length;
    final int newRC = ev['newRepCount'] as int;
    for (int j = peakIdx;
        j < math.min(nextPeakIdx, frameTelemetry.length);
        j++) {
      frameTelemetry[j]['reps'] = newRC;
    }
    final int prevRC = ev['prevRepCount'] as int;
    for (int j = 0; j < peakIdx && j < frameTelemetry.length; j++) {
      // Only set it back if it's currently higher than prevRC (i.e. it
      // was incremented in the main loop because we counted at descent).
      final int cur = (frameTelemetry[j]['reps'] as num).toInt();
      if (cur > prevRC) frameTelemetry[j]['reps'] = prevRC;
    }

    // Verdict pulse + feedback hold.
    final List<dynamic> issues = (ev['issues'] as List?) ?? const [];
    final bool isBad = issues.isNotEmpty;
    frameTelemetry[peakIdx]['rep_just_finished'] = isBad ? 'bad' : 'good';

    if (isBad) {
      // Build the full feedback list for this rep, sorted by severity (strongest first).
      final List<String> sortedIssues = issues.map((e) => e.toString()).toList()
        ..sort((a, b) => (FB_SEVERITY[b] ?? 1).compareTo(FB_SEVERITY[a] ?? 1));
      final String joinedFeedback = sortedIssues.join('\n');

      final int holdEnd =
          math.min(frameTelemetry.length - 1, peakIdx + holdFramesAtPeak);
      for (int j = peakIdx; j <= holdEnd; j++) {
        if (e + 1 < pulseEvents.length) {
          final int nextPeak = pulseEvents[e + 1]['peakIdx'] as int? ?? -1;
          if (nextPeak >= 0 && j >= nextPeak) break;
        }
        frameTelemetry[j]['feedback'] = joinedFeedback;
        // Parallel array form for richer widgets — list of strings, sorted by severity (strongest first).
        frameTelemetry[j]['feedback_list'] = sortedIssues;
      }
    }
  }

  // ============================================================
  // Session summary
  // ============================================================
  // [v1.14] A rep counts as "good" only when it produced zero feedback issues.
  // [v1.30 CRITICAL FIX] Reset the tallies before counting.
  // ============================================================
  goodReps = 0;
  badReps = 0;
  for (final r in repReports) {
    final issues = (r['issues'] as List?) ?? const [];
    if (issues.isEmpty) {
      goodReps += 1;
    } else {
      badReps += 1;
    }
  }

  double avgScore = 0.0;
  if (allScores.isNotEmpty) {
    avgScore = allScores.reduce((a, b) => a + b) / allScores.length;
  }
  final double techniqueScore = halfFloor10(avgScore);

  // Aggregate session feedback by frequency.
  final Map<String, int> issueCounts = {};
  for (final r in repReports) {
    final issues = (r['issues'] as List?) ?? const [];
    for (final i in issues) {
      final s = i.toString();
      issueCounts[s] = (issueCounts[s] ?? 0) + 1;
    }
  }
  // [v1.30 FIX] The threshold is now a FLAT minimum (1 rep), not the ratio-scaled max(1, 30% of reps)…
  final int sessionMinCount = TuningParams.SESSION_FEEDBACK_MIN;
  // Use sessionFeedbackByCat (already populated during the loop) for the per-category strongest-issue…
  final List<String> sessionFeedback = sessionFeedbackByCat.values
      .where((fb) =>
          (issueCounts[fb] ?? 0) >=
          math.min(sessionMinCount, repReports.length))
      .toList();

  final bool noReps = counter == 0;
  final List<String> feedbackList;
  if (noReps) {
    feedbackList = [
      "Couldn't analyze this video — make sure your full body is visible and that you complete at least one full press."
    ];
  } else if (sessionFeedback.isNotEmpty) {
    feedbackList = sessionFeedback;
  } else {
    feedbackList = ['Great form! Keep it up 💪'];
  }

  // ============================================================
  // [v1.14] Form tips — coaching cues that don't affect the score.
  // ============================================================
  final List<String> formTips = [];
  if (!noReps && repReports.isNotEmpty) {
    final double avgDesc = repDescendingList.isEmpty
        ? 0.0
        : repDescendingList.reduce((a, b) => a + b) / repDescendingList.length;
    final double avgAsc = repAscendingList.isEmpty
        ? 0.0
        : repAscendingList.reduce((a, b) => a + b) / repAscendingList.length;
    final double avgBarDev = repBarPathList.isEmpty
        ? 0.0
        : repBarPathList.reduce((a, b) => a + b) / repBarPathList.length;
    // Session aggregates for the new tip conditions.
    double sumTopElbow = 0.0;
    double sumMaxLean = 0.0;
    for (final r in repReports) {
      sumTopElbow += (r['top_elbow'] as num).toDouble();
      sumMaxLean += (r['max_lean'] as num).toDouble();
    }
    final double avgTopElbow = sumTopElbow / repReports.length;
    final double avgMaxLean = sumMaxLean / repReports.length;

    // Tip 1 — slow eccentric. Descent should be visibly slower
    // than the press (proper eccentric loads the muscle more).
    if (avgAsc > 0 && (avgDesc / avgAsc) < TIP_ECCENTRIC_RATIO_MIN) {
      formTips.add(PERF_TIP_SLOW_DESCENT);
    }
    // Tip 2 — full lockout.
    final bool sessionIsFrontal = sessionFrontalReps * 2 > repReports.length;
    final double tipLockoutNearMin = (sessionIsFrontal
            ? TuningParams.LOCKOUT_OK_ANGLE_FRONTAL
            : TuningParams.LOCKOUT_OK_ANGLE) +
        TIP_LOCKOUT_NEAR_MIN_OFFSET;
    final double tipLockoutNearMax = (sessionIsFrontal
            ? TuningParams.LOCKOUT_TARGET_ANGLE_FRONTAL
            : TuningParams.LOCKOUT_TARGET_ANGLE) +
        TIP_LOCKOUT_NEAR_MAX_OFFSET;
    if (avgTopElbow >= tipLockoutNearMin && avgTopElbow < tipLockoutNearMax) {
      formTips.add(PERF_TIP_FULL_LOCKOUT);
    }
    // Tip 3 — brace core. Slight lean visible, not enough to flag.
    if (avgMaxLean >= TIP_LEAN_BORDERLINE_MIN &&
        avgMaxLean < TIP_LEAN_BORDERLINE_MAX) {
      formTips.add(PERF_TIP_BRACE_CORE);
    }
    // Tip 4 — bar path borderline. Wandering slightly, not flagged.
    if (avgBarDev >= TIP_BAR_PATH_BORDERLINE_MIN &&
        avgBarDev < TIP_BAR_PATH_BORDERLINE_MAX) {
      formTips.add(PERF_TIP_BAR_PATH);
    }
  }
  final String? sessionTip = formTips.isNotEmpty ? formTips.first : null;

  final String fileUri = 'file://$videoPath';

  return {
    'squat_count': counter, // legacy widget compat
    'rep_count': counter,
    'technique_score': techniqueScore,
    'technique_score_display': displayHalfStr(techniqueScore),
    'technique_label': scoreLabel(techniqueScore),
    'good_reps': goodReps,
    'bad_reps': badReps,
    'feedback': feedbackList,
    'tip': sessionTip,
    'form_tips': formTips,
    '_debug': {
      'log': debugLog,
      'final_counter': counter,
      'total_frames': totalFrames,
      'good_reps': goodReps,
      'bad_reps': badReps,
    },
    'reps': repReports,
    'exercise_type': 'overhead_press',
    'video_path': fileUri,
    'analyzed_fps': fps,
    'frame_count': frameIdx,
    '_source_video_uri': fileUri,
    '_frame_telemetry': frameTelemetry,
  };
}

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
