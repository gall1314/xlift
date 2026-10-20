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
  // ---------------------- VIDEO EXTRACTION (FFmpeg) ----------------------
  static const double DEFAULT_FPS = 12.0;
  static const int FRAME_MAX_WIDTH = 1080;
  static const int JPEG_QUALITY = 2;

  // ---------------------- SAVITZKY-GOLAY FILTER ----------------------
  static const int SG_WINDOW_SIZE = 11;
  static const int SG_POLY_ORDER = 2;
  static const double SG_VIS_THRESHOLD = 0.5;

  // ---------------------- TELEMETRY SYNC ----------------------
  static const double TELEMETRY_LEAD_SEC = 0.0;

  // ---------------------- LANDMARK VISIBILITY (HYSTERESIS) ----------------------
  static const double VIS_HIDE_THRESHOLD = 0.40;
  static const double VIS_SHOW_THRESHOLD = 0.60;
  static const double LOW_CORE_VIS_THRESHOLD = 0.5;

  // ---------------------- ANATOMICAL PLAUSIBILITY ----------------------
  static const double MAX_ELBOW_BEND_DEG = 170.0;
  static const double MIN_ELBOW_BEND_DEG = 15.0;

  // ---------------------- BODY CALIBRATION ----------------------
  static const bool BODY_CALIBRATION_ENABLED = true;
  static const int BODY_CAL_MIN_FRAMES = 8;
  static const double BODY_CAL_MAX_RATIO = 1.6;
  static const double BODY_CAL_MIN_RATIO = 0.35;
  static const double BODY_CAL_VIS_FLOOR = 0.5;

  // ---------------------- JUMP / GLITCH REJECTION ----------------------
  static const double JUMP_REJECT_HIP_FRAC = 0.18;
  static const int JUMP_RECOVER_FRAMES = 3;
  // [v16] Maximum consecutive frames that can be rejected by the jump
  // filter before we force-accept the next frame as a new baseline.
  //
  // The jump filter compares each frame's hip position to the last
  // accepted frame's hip position. If they're too far apart, the new
  // frame is rejected (likely ML Kit detection noise).
  //
  // But ML Kit in stream mode occasionally drifts: it can "lose" the
  // person briefly and re-acquire them with the hip placed slightly
  // differently. When that happens, EVERY subsequent frame measures
  // "too far from the last accepted hip" — because the last accepted
  // hip is now from before the drift, and reality has moved on.
  // Result: an infinite cascade of rejections, the skeleton freezes
  // on screen, no reps get counted.
  //
  // The fix is a simple timeout: after N consecutive rejections, we
  // give up on the old baseline and accept whatever comes next as the
  // new truth. 6 frames at 12fps = 0.5s, which is short enough that
  // the user barely notices, but long enough to allow legitimate jump
  // rejection for genuine ML Kit noise.
  static const int JUMP_REJECT_MAX_CONSECUTIVE = 6;

  // ---------------------- PHANTOM REP PREVENTION ----------------------
  static const int MAX_REJECTED_FRAMES_IN_REP = 3;
  static const int MIN_REP_DURATION_FRAMES = 6;

  // ---------------------- REP DETECTION ----------------------
  static const double STAND_KNEE_ANGLE = 155.0;
  static const int MIN_FRAMES_BETWEEN_REPS = 4;
  static const double REP_FINISH_KNEE_MARGIN = 6.0;
  static const double REP_FINISH_DEPTH_MAX = 0.20;
  static const double REP_FINISH_ALLOW_MOVING_DEPTH_MAX = 0.10;
  static const double REP_START_KNEE_ANGLE = 125.0;

  // ---------------------- MOVEMENT DETECTION ----------------------
  static const double HIP_VEL_THRESH_PCT = 0.022;
  static const double ANKLE_VEL_THRESH_PCT = 0.026;
  static const double EMA_ALPHA = 0.65;
  static const int MOVEMENT_CLEAR_FRAMES = 1;
  static const double SOFT_START_MARGIN = 1.5;

  // ---------------------- BACK ANGLE ----------------------
  static const double TOP_BACK_MAX_DEG = 70.0;
  static const double BOTTOM_BACK_MAX_DEG = 85.0;
  static const double TOP_BAD_MIN_SEC = 0.8;
  static const double BOTTOM_BAD_MIN_SEC = 1.0;
  static const double TOP_ZONE_DEPTH_MAX = 0.35;
  static const double BOTTOM_ZONE_DEPTH_MIN = 0.70;

  // ---------------------- REAL-TIME FEEDBACK DISPLAY ----------------------
  static const double RT_FB_HOLD_SEC = 0.8;

  // ---------------------- REP VALIDATION ----------------------
  static const double MAX_HORIZONTAL_ALLOWED = 0.25;
  static const double MAX_ASYMMETRY_ALLOWED = 35.0;
  static const double MIN_DEPTH_FOR_REP = 0.12;

  // ---------------------- DEPTH SCORING ----------------------
  static const double DEPTH_GOOD_THRESHOLD = 0.96;
  static const double DEPTH_ALMOST_THRESHOLD = 0.85;
  static const double DEPTH_FAIR_THRESHOLD = 0.70;

  // ---------------------- REP SCORE ----------------------
  static const double PENALTY_DEPTH_SEVERE = 3.0;
  static const double PENALTY_DEPTH_MODERATE = 2.0;
  static const double PENALTY_DEPTH_MINOR = 1.0;
  static const double PENALTY_BACK = 1.5;
  static const double MIN_REP_SCORE = 4.0;
  static const double MAX_IMPERFECT_SCORE = 9.5;
  static const double PERFECT_SCORE = 10.0;

  // ---------------------- ML KIT POSE DETECTOR ----------------------
  static const bool USE_STREAM_MODE = true;

  // ---------------------- [v22] TRACKER RESET ON LOSS ----------------------
  // In stream mode ML Kit does NOT re-detect the person on every frame: it
  // re-uses the previous frame's body crop (ROI) and only runs the person
  // detector again when its own tracking confidence collapses. That is what
  // makes stream mode fast, and on a clean clip it is also perfectly stable.
  //
  // It breaks when something walks between the camera and the lifter. The
  // crop gets dragged onto the passer-by, the lifter is "lost" for a couple
  // of seconds (every frame rejected -> the real squat in that window is not
  // counted), and when ML Kit re-acquires, it does so from a STALE crop: the
  // landmark model then confidently places a whole skeleton inside the
  // lifter's torso (hips at the chest, "ankles" at mid-thigh) and keeps
  // tracking that hallucination for many seconds while the lifter is just
  // standing. Those frames pass every existing gate — likelihood is high
  // and the fake hip sits close to the real hip so the jump filter never
  // fires — and the side pipeline reads them as a rep with back-angle and
  // depth feedback. Measured on a real clip: 6/6 reps correct before the
  // passer-by, then 1 missed rep + 2 phantom reps in the 15s after.
  //
  // The fix is to throw the tracker state away as soon as we know it is
  // lost: after this many CONSECUTIVE rejected frames (no pose / low core
  // likelihood / hip jump) we close the detector and create a fresh one, so
  // the next frame gets a full-image person detection instead of a stale
  // crop. 6 frames at 12fps = 0.5s. On a clip where the pose is never lost
  // for 0.5s this never triggers and behavior is byte-for-byte unchanged.
  // Recreating the detector costs one model load (~100-300ms) per reset,
  // which only happens while frames are being rejected anyway.
  //
  // Set to 0 to disable. Has no effect when USE_STREAM_MODE is false
  // (single mode already re-detects on every frame).
  static const int TRACKER_RESET_AFTER_REJECTED_FRAMES = 6;

  // ---------------------- [v15] UNRACK REP REJECTION ----------------------
  // The counter sometimes catches the bar-pickup motion as a rep. We
  // retroactively drop the first rep if it's dramatically shallower
  // than the reps right after it.
  //   - UNRACK_MIN_REPS_FOR_CHECK: only run on sets of 3+ reps (need at
  //     least 2 peer reps to compute a stable median).
  //   - UNRACK_PEER_REPS_TO_CONSIDER: compare rep 1 against the median of
  //     the next K reps (not the whole set — late-set fatigue could skew).
  //   - UNRACK_FIRST_REP_DEPTH_PEER_FRACTION: rep 1 is unrack if its
  //     depth_pct is below this fraction of the peer median. 0.50 is
  //     calibrated against measured unrack motions (typically 0.20-0.35
  //     depth_pct) vs typical first reps of a set (0.70-0.95).
  static const int UNRACK_MIN_REPS_FOR_CHECK = 3;
  static const int UNRACK_PEER_REPS_TO_CONSIDER = 3;
  // Rep 1 is flagged as unrack if EITHER condition holds:
  //   (A) ratio: firstRepDepth < peerMedian * UNRACK_FIRST_REP_DEPTH_PEER_FRACTION
  //   (B) absolute: firstRepDepth < UNRACK_FIRST_REP_ABSOLUTE_MAX
  //       AND peerMedian >= UNRACK_ABSOLUTE_CHECK_MIN_PEER_DEPTH
  //
  // Why both: the ratio catches unracks where peers are deep enough that
  // any sub-half rep stands out (e.g. peer=0.95, unrack=0.40). The
  // absolute catches unracks that pass the ratio check because they're
  // similar in magnitude to the (also shallow) peer reps — those are
  // confusing cases where rep 1 reads e.g. 0.78 ("Almost there"-level)
  // and the rest read e.g. 0.85-0.90.
  //
  // The peer-min gate on the absolute check prevents us from incorrectly
  // wiping a legit-but-shallow rep 1 in a set where ALL reps are shallow.
  // If the user's whole working set sits in the "almost there" zone, we
  // don't want to call rep 1 specifically an unrack — they're just doing
  // shallow squats. Only when the rest of the set is genuinely deep
  // (peer median ≥ 0.90 = "Good"-level depth) do we trust that a
  // shallow rep 1 is the unrack.
  static const double UNRACK_FIRST_REP_DEPTH_PEER_FRACTION = 0.70;
  static const double UNRACK_FIRST_REP_ABSOLUTE_MAX = 0.85;
  static const double UNRACK_ABSOLUTE_CHECK_MIN_PEER_DEPTH = 0.90;
}
// ============================================================================

// ============================================================================
// [v21] PER-VARIANT CONFIG
//
// One analyzer, small per-variant tweaks. Everything not listed here is
// identical across variants.
//
//   unrackRejection : run the v15 first-rep unrack check (bar pickup).
//   tempoGates      : require a near-still hip at rep start (softStart) and
//                     MIN_REP_DURATION_FRAMES. Off for bodyweight — people
//                     move fast without load and the gates start the rep late
//                     (depth under-read) or drop it entirely.
//   minRepFrames    : min rep duration when tempoGates is off. 2, not 0, so a
//                     single noisy frame can never count as a rep.
//   depthScale      : multiplier on the side-view DEPTH_* thresholds.
//   backViewScale   : multiplier on the back-view DEPTH_* thresholds.
//                     Sumo: the wide stance shortens the projected thigh from
//                     the side and keeps the torso upright from behind, so
//                     depth under-reads a bit in both views; relax both.
// ============================================================================
class _SquatVariant {
  final bool unrackRejection;
  final bool tempoGates;
  final int minRepFrames;
  final double depthScale;
  final double backViewScale;
  const _SquatVariant({
    required this.unrackRejection,
    required this.tempoGates,
    required this.minRepFrames,
    required this.depthScale,
    required this.backViewScale,
  });

  static const _SquatVariant back = _SquatVariant(
    unrackRejection: true,
    tempoGates: true,
    minRepFrames: TuningParams.MIN_REP_DURATION_FRAMES,
    depthScale: 1.0,
    backViewScale: 1.0,
  );
  static const _SquatVariant bodyweight = _SquatVariant(
    unrackRejection: false,
    tempoGates: false,
    minRepFrames: 2,
    depthScale: 1.0,
    backViewScale: 1.0,
  );
  static const _SquatVariant goblet = _SquatVariant(
    unrackRejection: false,
    tempoGates: true,
    minRepFrames: TuningParams.MIN_REP_DURATION_FRAMES,
    depthScale: 1.0,
    backViewScale: 1.0,
  );
  static const _SquatVariant sumo = _SquatVariant(
    unrackRejection: true,
    tempoGates: true,
    minRepFrames: TuningParams.MIN_REP_DURATION_FRAMES,
    depthScale: 0.90,
    backViewScale: 0.85,
  );

  static _SquatVariant of(String? name) {
    switch ((name ?? '').trim().toLowerCase()) {
      case 'bodyweight':
        return bodyweight;
      case 'goblet':
        return goblet;
      case 'sumo':
        return sumo;
      // front / zercher / smith / back / unknown → unchanged behavior
      default:
        return back;
    }
  }
}

// ============================================================================
// Savitzky-Golay filter — zero-phase offline smoothing.
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

  for (int i = 0; i < n; i++) {
    x[i] = aug[i][n];
  }

  final List<double> coeffs = List<double>.filled(m, 0.0);
  for (int i = 0; i < m; i++) {
    double s = 0.0;
    for (int k = 0; k < n; k++) {
      s += V[i][k] * x[k];
    }
    coeffs[i] = s;
  }

  return coeffs;
}

List<double?> _savgolSmoothSeries(
  List<double?> values,
  List<double> coeffs,
) {
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
    if (anyMissingInWindow) {
      result[i] = values[i];
    } else {
      result[i] = sum;
    }
  }

  return result;
}

List<List<List<double>>> savitzkyGolaySmoothAll(
  List<List<List<double>>> rawFrames,
) {
  final int n = rawFrames.length;
  if (n == 0) return rawFrames;

  const int numLandmarks = 33;

  final List<double> coeffs = _computeSavGolCoefficients(
    TuningParams.SG_WINDOW_SIZE,
    TuningParams.SG_POLY_ORDER,
  );

  final List<List<double?>> xSeries = List.generate(
    numLandmarks,
    (_) => List<double?>.filled(n, null),
  );
  final List<List<double?>> ySeries = List.generate(
    numLandmarks,
    (_) => List<double?>.filled(n, null),
  );
  final List<List<bool>> wasLowVis = List.generate(
    numLandmarks,
    (_) => List<bool>.filled(n, false),
  );

  for (int i = 0; i < n; i++) {
    final frame = rawFrames[i];
    if (frame.isEmpty) continue;
    for (int lm = 0; lm < numLandmarks && lm < frame.length; lm++) {
      final point = frame[lm];
      if (point.length < 3) continue;
      final double vis = point[2];
      if (vis < TuningParams.SG_VIS_THRESHOLD) {
        wasLowVis[lm][i] = true;
        continue;
      }
      xSeries[lm][i] = point[0];
      ySeries[lm][i] = point[1];
    }
  }

  final List<List<List<double>>> out = List.generate(
    n,
    (i) => rawFrames[i].isEmpty
        ? <List<double>>[]
        : List<List<double>>.generate(
            rawFrames[i].length,
            (lm) => List<double>.from(rawFrames[i][lm]),
          ),
  );

  for (int lm = 0; lm < numLandmarks; lm++) {
    final smoothedX = _savgolSmoothSeries(xSeries[lm], coeffs);
    final smoothedY = _savgolSmoothSeries(ySeries[lm], coeffs);

    for (int i = 0; i < n; i++) {
      if (out[i].isEmpty) continue;
      if (lm >= out[i].length) continue;

      if (wasLowVis[lm][i]) {
        out[i][lm][2] = 0.0;
        continue;
      }

      final sx = smoothedX[i];
      final sy = smoothedY[i];
      if (sx != null) out[i][lm][0] = sx;
      if (sy != null) out[i][lm][1] = sy;
    }
  }

  return out;
}

// ============================================================================
// Hysteresis + body calibration + anatomical filter.
// ============================================================================

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

double _angleAt(List<double> a, List<double> b, List<double> c) {
  final double rad = math.atan2(c[1] - b[1], c[0] - b[0]) -
      math.atan2(a[1] - b[1], a[0] - b[0]);
  double ang = (rad * 180.0 / math.pi).abs();
  if (ang > 180) ang = 360 - ang;
  return ang;
}

double _dist(List<double> a, List<double> b) {
  final dx = a[0] - b[0];
  final dy = a[1] - b[1];
  return math.sqrt(dx * dx + dy * dy);
}

class _BodySegment {
  final String name;
  final int a;
  final int b;
  final List<int> dependents;
  const _BodySegment(this.name, this.a, this.b, this.dependents);
}

// [v16] Body calibration segments — now ARM-ONLY.
//
// Previously this list included torso width, trunk length, hip width,
// thigh, and shin segments. Hiding any of those landmarks made the
// skeleton look broken on screen (shoulder disappears, hip vanishes,
// etc.) — which the user reported as "the filter is too aggressive,
// it's hiding parts of the body".
//
// The reality is that ML Kit's "best guess" on a low-confidence body
// landmark is usually correct enough to draw — it's a smart anatomical
// interpolation, not a wild guess. So we let body landmarks through
// always, even at low confidence. The ARM landmarks (elbows + wrists)
// are different: when they go bad, they often "fly off" toward bright
// objects like the barbell, and that does look broken on screen.
//
// So we only keep the arm-segment checks below. Body landmarks
// (shoulders, hips, knees, ankles) are never hidden by this filter.
const List<_BodySegment> _BODY_SEGMENTS = [
  // --- Upper arm (shoulder → elbow) ---
  _BodySegment('left_upper_arm', _IDX_L_SHOULDER, _IDX_L_ELBOW, [_IDX_L_WRIST]),
  _BodySegment(
      'right_upper_arm', _IDX_R_SHOULDER, _IDX_R_ELBOW, [_IDX_R_WRIST]),
  // --- Forearm (elbow → wrist) ---
  _BodySegment('left_forearm', _IDX_L_ELBOW, _IDX_L_WRIST, []),
  _BodySegment('right_forearm', _IDX_R_ELBOW, _IDX_R_WRIST, []),
];

Map<String, double> _calibrateBody(List<List<List<double>>> frames) {
  final Map<String, List<double>> samplesByName = {};

  for (final frame in frames) {
    if (frame.isEmpty) continue;
    for (final seg in _BODY_SEGMENTS) {
      if (seg.name.endsWith('_rev')) continue;
      if (seg.a >= frame.length || seg.b >= frame.length) continue;

      final pa = frame[seg.a];
      final pb = frame[seg.b];
      if (pa.length < 3 || pb.length < 3) continue;
      if (pa[2] < TuningParams.BODY_CAL_VIS_FLOOR ||
          pb[2] < TuningParams.BODY_CAL_VIS_FLOOR) continue;

      final double d = _dist(pa, pb);
      if (d <= 1e-6) continue;
      samplesByName.putIfAbsent(seg.name, () => []).add(d);
    }
  }

  final Map<String, double> medians = {};
  samplesByName.forEach((name, list) {
    if (list.length < TuningParams.BODY_CAL_MIN_FRAMES) return;
    list.sort();
    final int mid = list.length ~/ 2;
    final double m =
        list.length.isOdd ? list[mid] : (list[mid - 1] + list[mid]) / 2.0;
    medians[name] = m;
    medians['${name}_rev'] = m;
  });

  return medians;
}

List<List<List<double>>> applyVisibilityFilters(
  List<List<List<double>>> smoothedFrames,
) {
  final int n = smoothedFrames.length;
  if (n == 0) return smoothedFrames;

  const int numLandmarks = 33;
  final List<bool> isShown = List<bool>.filled(numLandmarks, false);

  final List<List<List<double>>> out = List.generate(
    n,
    (i) => smoothedFrames[i].isEmpty
        ? <List<double>>[]
        : List<List<double>>.generate(
            smoothedFrames[i].length,
            (lm) => List<double>.from(smoothedFrames[i][lm]),
          ),
  );

  // [v16] Hysteresis Pass 1 is now restricted to ARM landmarks only.
  //
  // Previously this filter ran on every one of the 33 landmarks. That
  // meant any landmark — including major body joints (shoulders, hips,
  // knees, ankles) — could be hidden if its visibility dropped below
  // 0.40. The result: large parts of the skeleton disappeared on screen
  // whenever ML Kit got slightly uncertain about a body landmark, even
  // though its best guess for those landmarks is usually anatomically
  // correct (the model interpolates from the rest of the body).
  //
  // Arms are different: when ML Kit gets uncertain about an elbow or
  // wrist, the result tends to "fly off" to bright objects nearby (the
  // barbell, a window, etc.), which IS visually distracting. So we
  // keep the filter for arms and drop it for everything else.
  //
  // applyToArmsOnly() reads as "is this landmark index one of the four
  // arm landmarks". Anything else is passed through untouched.
  bool applyToArmsOnly(int lm) {
    return lm == _IDX_L_ELBOW ||
        lm == _IDX_R_ELBOW ||
        lm == _IDX_L_WRIST ||
        lm == _IDX_R_WRIST;
  }

  for (int i = 0; i < n; i++) {
    final frame = out[i];
    if (frame.isEmpty) continue;

    for (int lm = 0; lm < numLandmarks && lm < frame.length; lm++) {
      final point = frame[lm];
      if (point.length < 3) continue;
      // Body landmarks: keep whatever ML Kit gave us, including low-
      // confidence values. The widget will render them; ML Kit's
      // interpolation is reliable enough on body joints.
      if (!applyToArmsOnly(lm)) continue;

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

  Map<String, double> calibrated = const {};
  if (TuningParams.BODY_CALIBRATION_ENABLED) {
    calibrated = _calibrateBody(out);
  }

  for (int i = 0; i < n; i++) {
    final frame = out[i];
    if (frame.isEmpty) continue;

    if (calibrated.isNotEmpty) {
      for (final seg in _BODY_SEGMENTS) {
        final double? cal = calibrated[seg.name];
        if (cal == null || cal <= 0) continue;
        if (seg.a >= frame.length || seg.b >= frame.length) continue;

        final pa = frame[seg.a];
        final pb = frame[seg.b];
        if (pa.length < 3 || pb.length < 3) continue;
        if (pa[2] <= 0.0 || pb[2] <= 0.0) continue;

        final double cur = _dist(pa, pb);
        final double ratio = cur / cal;

        final bool tooLong = ratio > TuningParams.BODY_CAL_MAX_RATIO;
        final bool tooShort = ratio < TuningParams.BODY_CAL_MIN_RATIO;
        if (!tooLong && !tooShort) continue;

        pb[2] = 0.0;
        for (final dep in seg.dependents) {
          if (dep < frame.length && frame[dep].length >= 3) {
            frame[dep][2] = 0.0;
          }
        }
      }
    }

    void checkArm(int shoulderIdx, int elbowIdx, int wristIdx) {
      if (shoulderIdx >= frame.length ||
          elbowIdx >= frame.length ||
          wristIdx >= frame.length) return;

      final s = frame[shoulderIdx];
      final e = frame[elbowIdx];
      final w = frame[wristIdx];
      if (s.length < 3 || e.length < 3 || w.length < 3) return;
      if (s[2] <= 0.0 || e[2] <= 0.0 || w[2] <= 0.0) return;

      final double elbowAngle = _angleAt(s, e, w);
      final bool implausible = elbowAngle > TuningParams.MAX_ELBOW_BEND_DEG ||
          elbowAngle < TuningParams.MIN_ELBOW_BEND_DEG;

      if (implausible) {
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
// ============== [v18] BACK-VIEW SQUAT DETECTION (ADDITIVE) ==================
// ============================================================================
//
// WHY THIS EXISTS
// ---------------
// The entire side-view pipeline above is the ground truth and is NOT
// touched by anything in this section. But it fundamentally cannot see a
// squat filmed from BEHIND (or from straight in front), because both of
// its core signals collapse at that angle:
//
//   1. calculateDepthRobust() measures hip-below-knee in image-Y over
//      thigh length. From behind, the hip, knee and ankle sit on almost
//      the same vertical line, so this Y-difference barely moves even on
//      a deep squat — depth reads ~0% the whole rep.
//   2. The 3-point knee angle (hip→knee→ankle) stays near-straight in the
//      image plane from behind, because the knee bend happens in the
//      depth axis (toward/away from camera), which a 2D projection can't
//      see. So the "knee < REP_START_KNEE_ANGLE" trigger never fires.
//
// What IS reliable from behind: the MID-HIP HEIGHT. When the lifter
// descends, the whole pelvis drops in the image; when they stand up it
// rises back. Normalizing that drop by torso/leg length (shoulder→ankle
// span) makes it robust to how close the person is to the camera. That's
// the single signal this detector uses — the same philosophy as the RDL
// analyzer (one stable signal beats a fragile composite).
//
// HOW IT'S WIRED IN (no double counting)
// ---------------------------------------
// This detector runs over the SAME smoothed landmark frames, in its own
// pass, producing its own rep count. The main function only FALLS BACK to
// it when the side-view pipeline found (almost) nothing — see the
// integration block near the end of analyzeSquatVideoAction. On a normal
// side-view video the side pipeline counts reps and this result is
// discarded, so existing behavior is byte-for-byte unchanged.
//
// VIEW DETECTION
// --------------
// We only trust the back-view count when the frames actually look like a
// front/back view. The discriminator is shoulder width vs. hip-to-ankle
// vertical span: from the side the shoulders project to a narrow width
// (one shoulder occludes the other), while from front/back they're wide.
// computeFrontBackViewScore() returns a 0..1 fraction of analyzed frames
// that looked front/back-facing.
// ============================================================================

class _BackViewParams {
  // Fraction of frames that must look front/back-facing before we trust
  // the back-view detector at all. Side videos score near 0 here.
  static const double MIN_FRONTBACK_VIEW_FRACTION = 0.55;

  // Shoulder width / (shoulder→ankle vertical span). Front/back views
  // have wide shoulders relative to height (~0.20+); pure side views
  // collapse toward ~0.08-0.12 because one shoulder hides the other.
  static const double FRONTBACK_SHOULDER_WIDTH_RATIO = 0.16;

  // Visibility floor for a frame to contribute to view scoring / detection.
  static const double VIS_FLOOR = 0.35;

  // ============ SIGNAL CHOICE (revised after measuring the real video) ============
  // The first version of this detector used mid-hip vertical drop as the
  // signal. Measuring an actual back-view squat showed that's WRONG: from
  // behind, the pelvis barely moves down in the image. What moves is the
  // UPPER BODY — at the bottom the shoulders sink dramatically toward the
  // hips and the whole torso foreshortens (the lifter hinges forward, the
  // head nearly disappears, shoulders drop toward the waist).
  //
  // So the primary signal is TORSO COMPRESSION:
  //   compression = 1 - (shoulderToHipSpan_now / shoulderToHipSpan_standing)
  // 0 when standing tall, grows toward ~0.3-0.5 at the bottom of a deep
  // squat as the shoulder→hip vertical distance shrinks.
  //
  // We ALSO track normalized hip drop as a weak secondary and take the
  // MAX of the two normalized signals, so a lifter who happens to keep an
  // upright torso (and therefore drops the hips more) is still caught.
  //
  // Both are normalized by a stable body reference (shoulder→ankle span at
  // standing) so distance-to-camera doesn't matter.

  // Combined signal thresholds (max of compression and hip-drop signals).
  static const double SIGNAL_START = 0.10; // begin descent
  static const double SIGNAL_FINISH = 0.06; // returned to standing
  static const double SIGNAL_MIN_DEPTH = 0.16; // must reach this to be a rep

  // Depth scoring thresholds for the back view (combined signal at bottom).
  // A solid parallel back-view squat lands around 0.30-0.45.
  static const double DEPTH_GOOD = 0.32;
  static const double DEPTH_ALMOST = 0.24;
  static const double DEPTH_FAIR = 0.18;

  // Timing — same spirit as the side pipeline.
  static const int MIN_REP_DURATION_FRAMES = 6;
  static const int MIN_FRAMES_BETWEEN_REPS = 4;
  static const int STATE_CONFIRM_FRAMES = 2; // sustained drop/rise to switch

  // Standing-reference tracking. We track the LARGEST shoulder→hip span
  // (most upright torso) and the SMALLEST mid-hip Y (highest hip) seen so
  // far as the standing references. They ratchet toward "more upright"
  // instantly and drift back only slowly via EMA, so a held bottom never
  // redefines standing.
  static const double BASELINE_EMA = 0.08;

  // ---------------------- [v20] TOP-OF-LIFT TIMING ----------------------
  // The torso-compression signal returns to ~0 while the legs are still
  // extending (the torso straightens BEFORE the knees do), so the signal
  // alone declares "top" mid-ascent. That's where the pulse / color /
  // counter / feedback all fired too early on front/back clips.
  //
  // We therefore refuse to call a frame "top" while the mid-shoulder is
  // still moving UP on screen. TOP_RISE_EPS_PER_FRAME is the per-frame
  // upward motion (as a fraction of shoulder→ankle span) above which we
  // consider the body still rising. Ascent runs ~0.02-0.03 span/frame at
  // 12fps and decays toward 0 at the top; 0.004 sits comfortably below.
  //
  // TOP_MAX_WAIT_SEC caps the wait: if the shoulders never "settle" (jitter,
  // continuous cadence), we fall back to the old signal-only top after this
  // long, so a pulse always fires. Counting / depth / scoring are untouched
  // by any of this — only WHEN the already-captured rep is emitted.
  static const double TOP_RISE_EPS_PER_FRAME = 0.004;
  static const double TOP_MAX_WAIT_SEC = 1.0;
}

/// Returns the fraction (0..1) of usable frames that look front/back-facing.
/// Used to decide whether the back-view detector's result is trustworthy.
double computeFrontBackViewScore(List<List<List<double>>> frames) {
  int usable = 0;
  int frontBack = 0;
  for (final f in frames) {
    if (f.isEmpty || f.length < 29) continue;
    final ls = f[_IDX_L_SHOULDER];
    final rs = f[_IDX_R_SHOULDER];
    final la = f[_IDX_L_ANKLE];
    final ra = f[_IDX_R_ANKLE];
    if (ls.length < 3 || rs.length < 3 || la.length < 3 || ra.length < 3)
      continue;
    if (ls[2] < _BackViewParams.VIS_FLOOR || rs[2] < _BackViewParams.VIS_FLOOR)
      continue;

    final double shoulderWidth = (ls[0] - rs[0]).abs();
    final double topY = (ls[1] + rs[1]) / 2.0;
    final double botY = (la[1] + ra[1]) / 2.0;
    final double span = (botY - topY).abs();
    if (span < 1e-4) continue;

    usable += 1;
    final double ratio = shoulderWidth / span;
    if (ratio >= _BackViewParams.FRONTBACK_SHOULDER_WIDTH_RATIO) {
      frontBack += 1;
    }
  }
  if (usable == 0) return 0.0;
  return frontBack / usable;
}

/// Detects squat reps from a front/back view using normalized hip-drop.
/// Returns a map shaped like the side pipeline's outputs so the caller can
/// drop it in: { 'count', 'good', 'bad', 'scores', 'reps', 'feedbackByCat',
/// 'rep_events' } where rep_events is a list of
/// { 'end_frame', 'tag', 'feedback' } for telemetry patching.
///
/// [depthScale] multiplies the DEPTH_* scoring thresholds (1.0 = default;
/// sumo uses < 1 because its upright torso compresses less).
Map<String, dynamic> detectBackViewReps(
  List<List<List<double>>> frames,
  List<bool> frameRejected,
  double fps, {
  double depthScale = 1.0,
}) {
  const Map<String, int> FB_SEVERITY = {
    'Try to squat deeper': 3,
    'Almost there — go a bit lower': 2,
    'Looking good — just a bit more depth': 1,
  };

  final double depthGood = _BackViewParams.DEPTH_GOOD * depthScale;
  final double depthAlmost = _BackViewParams.DEPTH_ALMOST * depthScale;
  final double depthFair = _BackViewParams.DEPTH_FAIR * depthScale;

  String scoreLabel(double s) {
    if (s >= 9.5) return 'Excellent';
    if (s >= 8.5) return 'Very good';
    if (s >= 7.0) return 'Good';
    if (s >= 5.5) return 'Fair';
    return 'Needs work';
  }

  String displayHalfStr(double x) {
    final double q = (x * 2).round() / 2.0;
    if ((q - q.round()).abs() < 1e-9) return q.round().toString();
    return q.toStringAsFixed(1);
  }

  final int n = frames.length;

  // ---- Pass 1: build the combined back-view signal per frame ----
  // signal[i] = max( torsoCompression, normalizedHipDrop ), clamped >= 0.
  //   torsoCompression = 1 - shoulderToHipSpanNow / shoulderToHipSpanStanding
  //   normalizedHipDrop = (midHipY - hipBaselineY) / bodySpan
  // null where the frame is unusable.
  //
  // See _BackViewParams comments for why torso compression is the primary
  // signal from behind (the pelvis barely moves; the upper body collapses).
  final List<double?> signal = List<double?>.filled(n, null);

  // [v20] Per-frame mid-shoulder Y and body span. Used ONLY to decide WHEN
  // the top of the lift is reached (pulse timing) — never for counting.
  final List<double?> shoulderY = List<double?>.filled(n, null);
  final List<double?> bodySpanAt = List<double?>.filled(n, null);

  // Standing references, ratcheting toward "more upright":
  //   stdShoulderHipSpan = LARGEST shoulder→hip vertical span seen
  //   hipBaselineY       = SMALLEST mid-hip Y (highest hip) seen
  double? stdShoulderHipSpan;
  double? hipBaselineY;

  for (int i = 0; i < n; i++) {
    if (frameRejected[i] || frames[i].isEmpty || frames[i].length < 29) {
      continue;
    }
    final f = frames[i];
    final lh = f[_IDX_L_HIP];
    final rh = f[_IDX_R_HIP];
    final ls = f[_IDX_L_SHOULDER];
    final rs = f[_IDX_R_SHOULDER];
    final la = f[_IDX_L_ANKLE];
    final ra = f[_IDX_R_ANKLE];
    if (lh.length < 3 ||
        rh.length < 3 ||
        ls.length < 3 ||
        rs.length < 3 ||
        la.length < 3 ||
        ra.length < 3) continue;
    if ((lh[2] < _BackViewParams.VIS_FLOOR &&
            rh[2] < _BackViewParams.VIS_FLOOR) ||
        (ls[2] < _BackViewParams.VIS_FLOOR &&
            rs[2] < _BackViewParams.VIS_FLOOR)) continue;

    final double midHipY = (lh[1] + rh[1]) / 2.0;
    final double midShoulderY = (ls[1] + rs[1]) / 2.0;
    final double topY = midShoulderY;
    final double botY = (la[1] + ra[1]) / 2.0;
    final double bodySpan = (botY - topY).abs();
    if (bodySpan < 1e-4) continue;

    final double shoulderHipSpan = (midHipY - midShoulderY).abs();

    // --- Update standing references ---
    // Torso span: ratchet UP instantly (taller torso = better standing
    // reference), drift down only slowly.
    if (stdShoulderHipSpan == null) {
      stdShoulderHipSpan = shoulderHipSpan;
    } else if (shoulderHipSpan > stdShoulderHipSpan!) {
      stdShoulderHipSpan = shoulderHipSpan;
    } else {
      stdShoulderHipSpan =
          (1 - _BackViewParams.BASELINE_EMA) * stdShoulderHipSpan! +
              _BackViewParams.BASELINE_EMA * shoulderHipSpan;
    }
    // Hip baseline: ratchet UP (smaller Y = higher hip) instantly, drift
    // down slowly.
    if (hipBaselineY == null) {
      hipBaselineY = midHipY;
    } else if (midHipY < hipBaselineY!) {
      hipBaselineY = midHipY;
    } else {
      hipBaselineY = (1 - _BackViewParams.BASELINE_EMA) * hipBaselineY! +
          _BackViewParams.BASELINE_EMA * midHipY;
    }

    // --- Compute the two normalized signals ---
    double compression = 0.0;
    if (stdShoulderHipSpan != null && stdShoulderHipSpan! > 1e-4) {
      compression = 1.0 - (shoulderHipSpan / stdShoulderHipSpan!);
    }
    final double hipDrop = (midHipY - hipBaselineY!) / bodySpan;

    double sig = compression > hipDrop ? compression : hipDrop;
    if (sig < 0) sig = 0.0;
    signal[i] = sig;
    shoulderY[i] = midShoulderY;
    bodySpanAt[i] = bodySpan;
  }

  // ---- Pass 2: state machine over the hip-drop signal ----
  int count = 0;
  int good = 0;
  int bad = 0;
  final List<double> scores = [];
  final List<Map<String, dynamic>> reps = [];
  final List<Map<String, dynamic>> repEvents = [];
  final Map<String, String> feedbackByCat = {};

  // [v19] State machine with an explicit ASCENDING phase so the rep pulse
  // fires at the TOP of the lift (when the lifter is back upright), exactly
  // like the side pipeline fires at STAND_KNEE_ANGLE. The previous version
  // fired the pulse the instant the signal dipped below SIGNAL_FINISH,
  // which is mid-ascent, not the top — that's the "coloring timing is off"
  // symptom. Now:
  //   standing  -> descending  (signal climbs past SIGNAL_START)
  //   descending-> ascending   (signal peaked and started dropping back)
  //   ascending -> standing    (signal returns near 0 = TOP) <- pulse here
  //
  // We capture all the rep's metrics (depth, score, feedback) at the moment
  // the bottom is confirmed, but we hold them in a pendingRep and only emit
  // the rep event when the lifter reaches the top. This mirrors the side
  // pipeline's pendingRep/finishedRep timing precisely.
  //
  // [v20] "Signal near 0" alone is NOT the top from the front/back: the
  // torso straightens before the knees finish extending, so the signal hits
  // ~0 while the lifter is still in a half squat. We now additionally wait
  // until the shoulders have stopped rising on screen (see
  // shouldersStillRising below) before counting frames toward the top.
  String state = 'standing'; // 'standing' | 'descending' | 'ascending'
  int repStartFrame = -1;
  int lastRepEndFrame = -9999;
  double repMaxSig = 0.0;
  int framesDescending = 0;
  int framesReturning = 0;
  int framesAtTop = 0;
  int framesSinceFinish = 0; // [v20] frames since signal first hit FINISH
  Map<String, dynamic>? pendingRep; // filled at bottom, emitted at top

  final int minDur = _BackViewParams.MIN_REP_DURATION_FRAMES;
  final int minGap = _BackViewParams.MIN_FRAMES_BETWEEN_REPS;
  final int confirm = _BackViewParams.STATE_CONFIRM_FRAMES;
  final int maxTopWait =
      math.max(confirm, (_BackViewParams.TOP_MAX_WAIT_SEC * fps).round());

  // [v20] Is the body still moving UP on screen at frame i? Compares the
  // mid-shoulder Y against the previous usable frame, normalized by body
  // span and by the frame gap. Smaller Y = higher on screen.
  bool shouldersStillRising(int i) {
    final double? yNow = shoulderY[i];
    final double? span = bodySpanAt[i];
    if (yNow == null || span == null || span <= 1e-6) return false;
    int pi = i - 1;
    while (pi >= 0 && shoulderY[pi] == null) {
      pi -= 1;
    }
    if (pi < 0) return false;
    final double vy = (yNow - shoulderY[pi]!) / span / (i - pi);
    return vy < -_BackViewParams.TOP_RISE_EPS_PER_FRAME;
  }

  // Helper: build a pending rep (metrics + score) from the just-finished
  // descent. Returns null if the rep is invalid (too short / too shallow).
  Map<String, dynamic>? buildPendingRep(int bottomFrameIdx, double maxSig) {
    final int dur = bottomFrameIdx - repStartFrame;
    final bool durOk = dur >= minDur;
    final bool depthOk = maxSig >= _BackViewParams.SIGNAL_MIN_DEPTH;
    if (!durOk || !depthOk) return null;

    final List<String> fb = [];
    double penalty = 0.0;
    if (maxSig < depthFair) {
      fb.add('Try to squat deeper');
      penalty += 3.0;
    } else if (maxSig < depthAlmost) {
      fb.add('Almost there — go a bit lower');
      penalty += 2.0;
    } else if (maxSig < depthGood) {
      fb.add('Looking good — just a bit more depth');
      penalty += 1.0;
    }

    double score;
    if (fb.isEmpty) {
      score = 10.0;
    } else {
      score = math.max(4.0, 10.0 - penalty);
      score = (score * 2).round() / 2.0;
      score = math.min(score, 9.5);
    }

    String? strongest;
    int bestSev = -1;
    for (final m in fb) {
      final sev = FB_SEVERITY[m] ?? 1;
      if (sev > bestSev) {
        bestSev = sev;
        strongest = m;
      }
    }

    return {
      'score': score,
      'feedback': fb,
      'strongest': strongest,
      'depth': maxSig,
      'start_frame': repStartFrame + 1,
    };
  }

  // Helper: commit a pending rep at the top-of-lift frame `topFrameNo`.
  void commitRep(Map<String, dynamic> pr, int topFrameNo) {
    final double score = pr['score'] as double;
    final List<String> fb = List<String>.from(pr['feedback'] as List);
    final String? strongest = pr['strongest'] as String?;
    final double depth = pr['depth'] as double;

    count += 1;
    scores.add(score);
    final String tag = score >= 9.5 ? 'good' : 'bad';
    if (score >= 9.5) {
      good += 1;
    } else {
      bad += 1;
    }
    for (final m in fb) {
      final sev = FB_SEVERITY[m] ?? 1;
      feedbackByCat['depth'] = (feedbackByCat['depth'] == null ||
              (FB_SEVERITY[feedbackByCat['depth']!] ?? 1) < sev)
          ? m
          : feedbackByCat['depth']!;
    }
    reps.add({
      'rep_index': count,
      'score': double.parse(score.toStringAsFixed(1)),
      'score_display': displayHalfStr(score),
      'label': scoreLabel(score),
      'feedback': fb,
      'start_frame': pr['start_frame'],
      'end_frame': topFrameNo,
      'depth_pct': double.parse(depth.toStringAsFixed(3)),
      'view': 'back',
    });
    repEvents.add({
      'end_frame': topFrameNo, // top-of-lift = where the pulse fires
      'tag': tag,
      'feedback': strongest,
    });
    lastRepEndFrame = topFrameNo;
  }

  for (int i = 0; i < n; i++) {
    final double? d = signal[i];
    if (d == null) continue;
    final int frameNo = i + 1;

    if (state == 'standing') {
      if (d >= _BackViewParams.SIGNAL_START) {
        framesDescending += 1;
        if (framesDescending >= confirm &&
            (frameNo - lastRepEndFrame) >= minGap) {
          state = 'descending';
          repStartFrame = i;
          repMaxSig = d;
          framesDescending = 0;
          framesReturning = 0;
        }
      } else {
        framesDescending = 0;
      }
    } else if (state == 'descending') {
      if (d > repMaxSig) repMaxSig = d;

      // Detect that we've passed the bottom and started coming back up.
      if (d <= _BackViewParams.SIGNAL_FINISH) {
        framesReturning += 1;
      } else {
        framesReturning = 0;
      }

      if (framesReturning >= confirm) {
        // Bottom confirmed. Build the pending rep now (metrics captured at
        // the deepest point), but DON'T emit yet — wait for the top.
        pendingRep = buildPendingRep(i, repMaxSig);
        state = 'ascending';
        framesAtTop = 0;
        framesSinceFinish = 0;
        framesReturning = 0;
      }
    } else {
      // ascending — waiting for the true top of the lift.
      // The top is when the signal has settled near baseline (~0) AND
      // [v20] the shoulders have stopped rising on screen. That's the
      // highest point of the body = where the side pipeline fires its pulse.
      if (d <= _BackViewParams.SIGNAL_FINISH) {
        framesSinceFinish += 1;
        // [v20] The torso signal is already ~0 here, but the legs may still
        // be extending. Don't count this frame toward "top" while the body
        // is still moving up — unless we've waited too long, in which case
        // fall back to the old signal-only behavior so a pulse always fires.
        if (!shouldersStillRising(i) || framesSinceFinish > maxTopWait) {
          framesAtTop += 1;
        } else {
          framesAtTop = 0;
        }
      } else {
        framesAtTop = 0;
        framesSinceFinish = 0;
        // If they dipped back down without reaching the top, fold it into
        // the current rep's depth rather than spawning a phantom.
        if (d > repMaxSig) repMaxSig = d;
        if (d >= _BackViewParams.SIGNAL_START) {
          // They've started a new descent without ever reaching the top
          // (continuous cadence). Commit the pending rep first if there is
          // one (so its pulse still fires), then begin the new rep. If the
          // previous attempt was invalid (pendingRep == null), we simply
          // start fresh — no phantom is emitted.
          if (pendingRep != null) {
            commitRep(pendingRep!, frameNo);
            pendingRep = null;
          }
          state = 'descending';
          repStartFrame = i;
          repMaxSig = d;
          continue;
        }
      }

      if (framesAtTop >= confirm) {
        // True top reached. Emit the pending rep here (if valid).
        if (pendingRep != null) {
          commitRep(pendingRep!, frameNo);
          pendingRep = null;
        }
        state = 'standing';
        repMaxSig = 0.0;
        framesAtTop = 0;
        framesSinceFinish = 0;
        framesDescending = 0;
      }
    }
  }

  return {
    'count': count,
    'good': good,
    'bad': bad,
    'scores': scores,
    'reps': reps,
    'feedbackByCat': feedbackByCat,
    'rep_events': repEvents,
    // [v18 DEBUG] Per-frame signal trace for calibration. Bind a
    // FlutterFlow Text widget to _backview_debug to see, for every frame,
    // the combined signal value. Use this to tune SIGNAL_START /
    // SIGNAL_MIN_DEPTH / DEPTH_* against your real footage: watch the
    // value at the standing top (should sit near 0) vs the squat bottom
    // (the peak you want SIGNAL_MIN_DEPTH to sit below).
    'signal_trace': signal
        .asMap()
        .entries
        .where((e) => e.value != null)
        .map((e) => {
              'frame': e.key + 1,
              'sig': double.parse(e.value!.toStringAsFixed(3)),
            })
        .toList(),
    'signal_max':
        signal.fold<double>(0.0, (m, v) => (v != null && v > m) ? v : m),
  };
}

/// Analyze a squat video locally using ML Kit Pose Detection.
///
/// v15 changes:
///  - UNRACK REP REJECTION: retroactively drops rep 1 if it's dramatically
///    shallower than the next reps (the bar-pickup motion sometimes
///    triggered the counter). Detection logic itself is unchanged.
///
/// v17 changes (this file):
///  - UNRACK FEEDBACK LEAK FIX: when the unrack rep is retroactively
///    removed, also clear the feedback message it wrote into the frame
///    telemetry. Previously the rep count was correctly rewound to 0
///    but the "Try to squat deeper" overlay still flashed on screen
///    because finalRepFbOverride / rtFbHold had already written the
///    message into the telemetry for the unrack's end frame and the
///    few frames after it. No detection logic changed.
///
/// v18 changes (this file):
///  - BACK/FRONT-VIEW FALLBACK: the side-view pipeline above is unchanged
///    and remains the primary, ground-truth detector. After it finishes,
///    if it counted (almost) no reps AND the footage looks front/back-
///    facing, we run the independent _BackView detector (normalized hip-
///    drop signal) and use ITS reps instead. On any normal side-view clip
///    the side count wins and the back-view result is discarded, so all
///    prior behavior is preserved exactly. See the
///    "[v18] BACK-VIEW SQUAT DETECTION" section above for the full design.
///
/// v19 changes (this file) — back-view DISPLAY fixes (detection unchanged):
///  All four symptoms reported on back-view clips traced to how the v18
///  fallback wrote telemetry vs. the contract the video-player widget
///  actually consumes. None of these touch the side pipeline.
///   1. SKELETON BLINKING/DISAPPEARING: the widget hides the skeleton on
///      any frame whose pose_reliable is false (or whose neighbor is). We
///      now force pose_reliable = true on adopted back-view frames (the
///      back-view detector already validated them via its own signal).
///   2. COLOR/FEEDBACK TIMING WRONG: the pulse now fires at the true TOP of
///      the lift (new 'ascending' state waits for the signal to return to
///      baseline) instead of mid-ascent, matching the side pipeline which
///      pulses at standing.
///   3. COLORED SKELETON WITH NO FEEDBACK + FEEDBACK VANISHING TOO FAST:
///      we stamp flash_duration_sec on the pulse frame (so the widget holds
///      the color a controlled time) and fill the feedback string across
///      the same hold window, so color and text appear and clear together.
///   4. TWO DIFFERENT DEPTH FEEDBACKS ON ONE REP: we now fully wipe the
///      stale side-pipeline feedback/pulses across the whole telemetry
///      before re-emitting the back-view ones, so no leftover side-view
///      bubble can co-exist with the back-view bubble.
///  Also: the depth ring now reflects the back-view signal (it sat at 0%
///  before because calculateDepthRobust reads ~0 from behind).
///
/// v20 changes (this file) — back-view pulse timing only:
///  - The v19 "top" was still too early on front/back clips: the torso
///    signal returns to ~0 while the knees are still extending, so the
///    pulse / color / counter / feedback fired at a half squat. The
///    ascending state now also waits for the shoulders to stop rising on
///    screen (with a 1s safety cap). Counting, depth and scoring unchanged;
///    side pipeline untouched.
///
/// v21 changes (this file) — squat variants:
///  - New optional [variant] argument ('back' | 'front' | 'zercher' |
///    'smith' | 'goblet' | 'bodyweight' | 'sumo'; null = back). See
///    _SquatVariant for the per-variant tweaks. back/front/zercher/smith are
///    byte-for-byte the previous behavior.
///
/// v22 changes (this file) — ML Kit tracker reset after a loss:
///  - When the pose is rejected for TRACKER_RESET_AFTER_REJECTED_FRAMES
///    consecutive frames (someone walked through the frame, etc.) the
///    PoseDetector is closed and recreated, so stream-mode tracking cannot
///    re-acquire from a stale crop and hallucinate a skeleton inside the
///    torso (which produced phantom reps + bogus back/depth feedback while
///    the lifter was standing still). No counting, depth, scoring or
///    telemetry logic changed; clips where the pose is never lost are
///    unaffected. New debug key: _tracker_resets.
Future<dynamic> analyzeSquatVideoAction(
  FFUploadedFile videoFile,
  double? targetFps,
  String? variant,
) async {
  const Map<String, int> FB_SEVERITY = {
    'Try to squat deeper': 3,
    'Avoid knee collapse': 3,
    'Try to keep your back a bit straighter': 2,
    'Almost there — go a bit lower': 2,
    'Looking good — just a bit more depth': 1,
  };
  const Map<String, String> FEEDBACK_CATEGORY = {
    'Try to squat deeper': 'depth',
    'Almost there — go a bit lower': 'depth',
    'Looking good — just a bit more depth': 'depth',
    'Try to keep your back a bit straighter': 'back',
    'Avoid knee collapse': 'knees',
  };

  // [v21] Per-variant config.
  final _SquatVariant cfg = _SquatVariant.of(variant);
  final double DEPTH_GOOD = TuningParams.DEPTH_GOOD_THRESHOLD * cfg.depthScale;
  final double DEPTH_ALMOST =
      TuningParams.DEPTH_ALMOST_THRESHOLD * cfg.depthScale;
  final double DEPTH_FAIR = TuningParams.DEPTH_FAIR_THRESHOLD * cfg.depthScale;

  final double fps = (targetFps ?? TuningParams.DEFAULT_FPS).clamp(2.0, 30.0);
  final double dt = 1.0 / fps;
  final int TOP_BAD_MIN_FRAMES =
      math.max(3, (TuningParams.TOP_BAD_MIN_SEC / dt).round());
  final int BOTTOM_BAD_MIN_FRAMES =
      math.max(3, (TuningParams.BOTTOM_BAD_MIN_SEC / dt).round());
  final int RT_FB_HOLD_FRAMES =
      math.max(2, (TuningParams.RT_FB_HOLD_SEC / dt).round());

  _cachedW = -1;
  _cachedH = -1;

  double calcAngle(List<double> a, List<double> b, List<double> c) {
    final double rad = math.atan2(c[1] - b[1], c[0] - b[0]) -
        math.atan2(a[1] - b[1], a[0] - b[0]);
    double ang = (rad * 180.0 / math.pi).abs();
    if (ang > 180) ang = 360 - ang;
    return ang;
  }

  double angleBetweenVectors(List<double> v1, List<double> v2) {
    final double denom = math.sqrt(v1[0] * v1[0] + v1[1] * v1[1]) *
        math.sqrt(v2[0] * v2[0] + v2[1] * v2[1]);
    if (denom == 0) return 0.0;
    double cosAng = (v1[0] * v2[0] + v1[1] * v2[1]) / denom;
    if (cosAng > 1.0) cosAng = 1.0;
    if (cosAng < -1.0) cosAng = -1.0;
    return math.acos(cosAng) * 180.0 / math.pi;
  }

  double euclid(List<double> a, List<double> b) {
    final dx = a[0] - b[0];
    final dy = a[1] - b[1];
    return math.sqrt(dx * dx + dy * dy);
  }

  double calculateDepthRobust(
      List<double> midHip, List<double> midKnee, double kneeAngle) {
    final double hipBelowKnee = midHip[1] - midKnee[1];
    final double thighLength = math.max(1e-6, euclid(midHip, midKnee));
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
      depthScore =
          math.max(0.0, 0.30 * (1.0 + (normalizedDepth + 0.60) / 0.40));
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

  String displayHalfStr(double x) {
    final double q = (x * 2).round() / 2.0;
    if ((q - q.round()).abs() < 1e-9) return q.round().toString();
    return q.toStringAsFixed(1);
  }

  String scoreLabel(double s) {
    if (s >= 9.5) return 'Excellent';
    if (s >= 8.5) return 'Very good';
    if (s >= 7.0) return 'Good';
    if (s >= 5.5) return 'Fair';
    return 'Needs work';
  }

  Map<String, dynamic> pickStrongestPerCategory(List<String> feedbacks) {
    final Map<String, String> bestByCat = {};
    for (final f in feedbacks) {
      final cat = FEEDBACK_CATEGORY[f] ?? 'other';
      final cur = bestByCat[cat];
      if (cur == null || (FB_SEVERITY[f] ?? 1) > (FB_SEVERITY[cur] ?? 1)) {
        bestByCat[cat] = f;
      }
    }
    return {
      'list': bestByCat.values.toList(),
      'byCat': bestByCat,
    };
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
        'tip': null,
        'reps': <dynamic>[],
        'video_path': '',
        '_source_video_uri': '',
        '_frame_telemetry': <dynamic>[],
      };

  if (videoFile.bytes == null || videoFile.bytes!.isEmpty) {
    return errorPayload('empty_upload', 'Uploaded file has no bytes');
  }

  final Directory tmp = await getTemporaryDirectory();
  final String uploadName =
      (videoFile.name != null && videoFile.name!.isNotEmpty)
          ? videoFile.name!
          : 'upload.mp4';
  final String safeName = uploadName.split('/').last.split('\\').last;
  final String videoPath = p.join(
    tmp.path,
    'squat_in_${DateTime.now().millisecondsSinceEpoch}_$safeName',
  );
  try {
    await File(videoPath).writeAsBytes(videoFile.bytes!, flush: true);
  } catch (e) {
    return errorPayload('write_failed', 'Could not save upload: $e');
  }

  final String sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  final Directory framesDir =
      Directory(p.join(tmp.path, 'squat_frames_$sessionId'));
  if (framesDir.existsSync()) {
    framesDir.deleteSync(recursive: true);
  }
  framesDir.createSync(recursive: true);

  final String framePattern = p.join(framesDir.path, 'f_%05d.jpg');
  final String extractCmd =
      "-y -i \"$videoPath\" -vf \"fps=$fps,scale='min(${TuningParams.FRAME_MAX_WIDTH},iw)':-2\" -q:v ${TuningParams.JPEG_QUALITY} \"$framePattern\"";

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

  // [v22] Detector is no longer final: it is recreated when the tracker is
  // lost for TRACKER_RESET_AFTER_REJECTED_FRAMES consecutive frames.
  PoseDetector newPoseDetector() => PoseDetector(
        options: PoseDetectorOptions(
          mode: TuningParams.USE_STREAM_MODE
              ? PoseDetectionMode.stream
              : PoseDetectionMode.single,
          model: PoseDetectionModel.accurate,
        ),
      );
  PoseDetector poseDetector = newPoseDetector();
  // [v22] Consecutive rejected frames of ANY kind (exception / no pose /
  // missing landmarks / low core likelihood / hip jump). Reset to 0 on the
  // first accepted frame. Drives the tracker reset only.
  int consecutiveRejectedFrames = 0;
  int trackerResets = 0;

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

  const int IDX_R_SHOULDER = 12;
  const int IDX_L_SHOULDER = 11;
  const int IDX_R_HIP = 24;
  const int IDX_L_HIP = 23;
  const int IDX_R_KNEE = 26;
  const int IDX_L_KNEE = 25;
  const int IDX_R_ANKLE = 28;
  const int IDX_L_ANKLE = 27;

  final List<List<List<double>>> allRawLandmarks = [];
  final List<double> allFrameTimes = [];
  final List<bool> frameRejected = [];

  List<double>? lastGoodMidHipNorm;
  int frameIdx = 0;
  // [v16] Count consecutive rejections caused by the jump filter. When
  // this reaches JUMP_REJECT_MAX_CONSECUTIVE, we accept the next frame
  // as a new baseline regardless of how far it jumped — see the comment
  // on the constant for the full reasoning.
  int consecutiveJumpRejections = 0;

  try {
    for (final frameFile in frameFiles) {
      frameIdx += 1;
      final double tSec = (frameIdx - 1) / fps;
      allFrameTimes.add(tSec);

      // [v22] Tracker lost for too long -> drop the stale ROI and start a
      // fresh detector so this frame gets a full-image person detection.
      if (TuningParams.USE_STREAM_MODE &&
          TuningParams.TRACKER_RESET_AFTER_REJECTED_FRAMES > 0 &&
          consecutiveRejectedFrames >=
              TuningParams.TRACKER_RESET_AFTER_REJECTED_FRAMES) {
        try {
          await poseDetector.close();
        } catch (_) {}
        poseDetector = newPoseDetector();
        consecutiveRejectedFrames = 0;
        trackerResets += 1;
      }

      final inputImage = InputImage.fromFilePath(frameFile.path);
      List<Pose> poses = [];
      try {
        poses = await poseDetector.processImage(inputImage);
      } catch (_) {
        consecutiveRejectedFrames += 1;
        allRawLandmarks.add(const []);
        frameRejected.add(true);
        continue;
      }

      if (poses.isEmpty) {
        consecutiveRejectedFrames += 1;
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

      final rHipLm = lm[PoseLandmarkType.rightHip];
      final rKneeLm = lm[PoseLandmarkType.rightKnee];
      final rAnkleLm = lm[PoseLandmarkType.rightAnkle];
      final rShoulderLm = lm[PoseLandmarkType.rightShoulder];
      final lHipLm = lm[PoseLandmarkType.leftHip];
      final lKneeLm = lm[PoseLandmarkType.leftKnee];
      final lAnkleLm = lm[PoseLandmarkType.leftAnkle];
      final lShoulderLm = lm[PoseLandmarkType.leftShoulder];

      if (rHipLm == null ||
          rKneeLm == null ||
          rAnkleLm == null ||
          rShoulderLm == null ||
          lHipLm == null ||
          lKneeLm == null ||
          lAnkleLm == null ||
          lShoulderLm == null) {
        consecutiveRejectedFrames += 1;
        allRawLandmarks.add(const []);
        frameRejected.add(true);
        continue;
      }

      final double coreVisMean = ((rHipLm.likelihood) +
              (lHipLm.likelihood) +
              (rKneeLm.likelihood) +
              (lKneeLm.likelihood) +
              (rAnkleLm.likelihood) +
              (lAnkleLm.likelihood) +
              (rShoulderLm.likelihood) +
              (lShoulderLm.likelihood)) /
          8.0;

      final List<List<double>> rawNormLandmarks = [];
      for (final t in LM_ORDER) {
        final plm = lm[t];
        if (plm == null) {
          rawNormLandmarks.add([0.0, 0.0, 0.0]);
        } else {
          final double vis = (plm.likelihood).clamp(0.0, 1.0).toDouble();
          rawNormLandmarks.add([
            (plm.x / fw).clamp(0.0, 1.0).toDouble(),
            (plm.y / fh).clamp(0.0, 1.0).toDouble(),
            vis,
          ]);
        }
      }

      final List<double> rawMidHip = [
        (rawNormLandmarks[IDX_R_HIP][0] + rawNormLandmarks[IDX_L_HIP][0]) / 2.0,
        (rawNormLandmarks[IDX_R_HIP][1] + rawNormLandmarks[IDX_L_HIP][1]) / 2.0,
      ];

      bool rejectFrame = false;
      bool wasJumpRejection = false;
      if (coreVisMean < TuningParams.LOW_CORE_VIS_THRESHOLD) {
        rejectFrame = true;
      }
      if (!rejectFrame && lastGoodMidHipNorm != null) {
        final double jumpDist = euclid(rawMidHip, lastGoodMidHipNorm!);
        final double jumpFrac = jumpDist / 1.4142135;
        if (jumpFrac > TuningParams.JUMP_REJECT_HIP_FRAC) {
          // [v16] Check if we've been in jump-rejection territory long
          // enough that ML Kit has probably drifted permanently. If so,
          // accept this frame and reset the baseline — the alternative
          // is the skeleton-freeze cascade (see constant comment).
          if (consecutiveJumpRejections >=
              TuningParams.JUMP_REJECT_MAX_CONSECUTIVE) {
            // Force-accept: don't reject, treat this as the new baseline.
            // We deliberately don't increment the counter here — by
            // accepting we're declaring the cascade over.
          } else {
            rejectFrame = true;
            wasJumpRejection = true;
          }
        }
      }

      if (rejectFrame) {
        if (wasJumpRejection) {
          consecutiveJumpRejections += 1;
        }
        consecutiveRejectedFrames += 1;
        allRawLandmarks.add(const []);
        frameRejected.add(true);
        continue;
      }

      // Frame accepted — reset the jump-rejection cascade counter.
      consecutiveJumpRejections = 0;
      consecutiveRejectedFrames = 0;
      lastGoodMidHipNorm = rawMidHip;
      allRawLandmarks.add(rawNormLandmarks);
      frameRejected.add(false);
    }
  } finally {
    await poseDetector.close();
    try {
      framesDir.deleteSync(recursive: true);
    } catch (_) {}
  }

  final List<List<List<double>>> smoothed =
      savitzkyGolaySmoothAll(allRawLandmarks);
  final List<List<List<double>>> allSmoothedLandmarks =
      applyVisibilityFilters(smoothed);

  int counter = 0;
  int goodReps = 0;
  int badReps = 0;
  final List<Map<String, dynamic>> repReports = [];
  final List<double> allScores = [];

  String? stage;
  int lastRepFrame = -999;
  final Map<String, String> sessionFeedbackByCat = {};

  List<double>? prevHip;
  List<double>? prevLa;
  List<double>? prevRa;
  double hipVelEma = 0.0;
  double ankleVelEma = 0.0;
  int movementFreeStreak = 0;

  double? startKneeAngle;
  double repMinKneeAngle = 180.0;
  double repMaxKneeAngle = -999.0;
  double repMaxBackAngleTop = -999.0;
  double repMaxBackAngleBottom = -999.0;
  int? repStartFrame;
  double repMaxDepth = 0.0;
  bool repHadBackFeedback = false;

  double? repStartHipX;
  double? repStartAnkleX;
  double repMaxHorizontalMovement = 0.0;
  double repMaxAsymmetry = 0.0;

  int repTopBadFrames = 0;
  int repBottomBadFrames = 0;

  String? rtFbMsg;
  int rtFbHold = 0;

  String? finalRepFbOverride;
  String? repJustFinished;

  int jumpRecoverCountdown = 0;
  int repRejectedFrameCount = 0;

  final List<Map<String, dynamic>> frameTelemetry = [];

  void abortRep() {
    stage = 'up';
    startKneeAngle = null;
    repStartFrame = null;
    repStartHipX = null;
    repStartAnkleX = null;
    repMaxHorizontalMovement = 0.0;
    repMaxAsymmetry = 0.0;
    repMaxDepth = 0.0;
    repMinKneeAngle = 180.0;
    repMaxKneeAngle = -999.0;
    repMaxBackAngleTop = -999.0;
    repMaxBackAngleBottom = -999.0;
    repTopBadFrames = 0;
    repBottomBadFrames = 0;
    repHadBackFeedback = false;
    repRejectedFrameCount = 0;
  }

  void addEmptyFrame(double tSec) {
    String? fbVal;
    if (finalRepFbOverride != null) {
      fbVal = finalRepFbOverride;
      finalRepFbOverride = null;
    } else if (rtFbHold > 0 && rtFbMsg != null) {
      fbVal = rtFbMsg;
    }
    frameTelemetry.add({
      't': tSec,
      'reps': counter,
      'depth': 0.0,
      'metric_label': 'DEPTH',
      'metric_value': 0.0,
      'feedback': fbVal,
      'rep_just_finished': repJustFinished,
      'landmarks': <List<double>>[],
    });
    repJustFinished = null;
    if (rtFbHold > 0) rtFbHold -= 1;
  }

  final int totalFrames = allSmoothedLandmarks.length;

  double fw = _cachedW > 0 ? _cachedW : 1080.0;
  double fh = _cachedH > 0 ? _cachedH : 1920.0;

  for (int i = 0; i < totalFrames; i++) {
    final int frameIdx1Based = i + 1;
    final double tSec = allFrameTimes[i];
    final normLandmarks = allSmoothedLandmarks[i];

    if (frameRejected[i] || normLandmarks.isEmpty) {
      jumpRecoverCountdown = TuningParams.JUMP_RECOVER_FRAMES;

      if (stage == 'down') {
        repRejectedFrameCount += 1;
        if (repRejectedFrameCount > TuningParams.MAX_REJECTED_FRAMES_IN_REP) {
          abortRep();
        }
      }

      addEmptyFrame(tSec);
      continue;
    }

    if (jumpRecoverCountdown > 0) {
      jumpRecoverCountdown -= 1;
    }

    List<double> at(int idx) => [normLandmarks[idx][0], normLandmarks[idx][1]];

    final List<double> hip = at(IDX_R_HIP);
    final List<double> knee = at(IDX_R_KNEE);
    final List<double> ankle = at(IDX_R_ANKLE);
    final List<double> shoulder = at(IDX_R_SHOULDER);
    final List<double> lHip = at(IDX_L_HIP);
    final List<double> lKnee = at(IDX_L_KNEE);
    final List<double> lAnkle = at(IDX_L_ANKLE);
    final List<double> lShldr = at(IDX_L_SHOULDER);

    final List<double> midHip = [
      (hip[0] + lHip[0]) / 2.0,
      (hip[1] + lHip[1]) / 2.0,
    ];
    final List<double> midKnee = [
      (knee[0] + lKnee[0]) / 2.0,
      (knee[1] + lKnee[1]) / 2.0,
    ];
    final List<double> midAnkle = [
      (ankle[0] + lAnkle[0]) / 2.0,
      (ankle[1] + lAnkle[1]) / 2.0,
    ];
    final List<double> midShoulder = [
      (shoulder[0] + lShldr[0]) / 2.0,
      (shoulder[1] + lShldr[1]) / 2.0,
    ];

    final w = fw;
    final h = fh;
    final List<double> hipPx = [hip[0] * w, hip[1] * h];
    final List<double> laPx = [lAnkle[0] * w, lAnkle[1] * h];
    final List<double> raPx = [ankle[0] * w, ankle[1] * h];

    prevHip ??= hipPx;
    prevLa ??= laPx;
    prevRa ??= raPx;

    double dNorm(List<double> a, List<double> b) {
      final dx = a[0] - b[0];
      final dy = a[1] - b[1];
      return math.sqrt(dx * dx + dy * dy) / math.max(w, h);
    }

    final double hipVel = dNorm(hipPx, prevHip!);
    final double anVel = math.max(dNorm(laPx, prevLa!), dNorm(raPx, prevRa!));
    hipVelEma = TuningParams.EMA_ALPHA * hipVel +
        (1 - TuningParams.EMA_ALPHA) * hipVelEma;
    ankleVelEma = TuningParams.EMA_ALPHA * anVel +
        (1 - TuningParams.EMA_ALPHA) * ankleVelEma;
    prevHip = hipPx;
    prevLa = laPx;
    prevRa = raPx;

    final bool movementBlock = (hipVelEma > TuningParams.HIP_VEL_THRESH_PCT) ||
        (ankleVelEma > TuningParams.ANKLE_VEL_THRESH_PCT);
    if (movementBlock) {
      movementFreeStreak = 0;
    } else {
      movementFreeStreak =
          math.min(TuningParams.MOVEMENT_CLEAR_FRAMES, movementFreeStreak + 1);
    }

    final double kneeAngle = calcAngle(hip, knee, ankle);
    final double backAngle = angleBetweenVectors(
      [midShoulder[0] - midHip[0], midShoulder[1] - midHip[1]],
      [0.0, -1.0],
    );

    // [v21] Bodyweight: no tempo gate at rep start.
    final bool softStartOk = !cfg.tempoGates ||
        ((hipVelEma <
                TuningParams.HIP_VEL_THRESH_PCT *
                    TuningParams.SOFT_START_MARGIN) &&
            (ankleVelEma <
                TuningParams.ANKLE_VEL_THRESH_PCT *
                    TuningParams.SOFT_START_MARGIN));
    final bool kneeGoingDown = (stage != 'down');

    final bool inRecovery = jumpRecoverCountdown > 0;

    if (kneeAngle < TuningParams.REP_START_KNEE_ANGLE &&
        kneeGoingDown &&
        softStartOk &&
        !inRecovery) {
      startKneeAngle = kneeAngle;
      repMinKneeAngle = 180.0;
      repMaxKneeAngle = -999.0;
      repMaxBackAngleTop = -999.0;
      repMaxBackAngleBottom = -999.0;
      repMaxDepth = 0.0;
      repTopBadFrames = 0;
      repBottomBadFrames = 0;
      repHadBackFeedback = false;
      repStartFrame = frameIdx1Based;
      repStartHipX = midHip[0];
      repStartAnkleX = midAnkle[0];
      repMaxHorizontalMovement = 0.0;
      repMaxAsymmetry = 0.0;
      repRejectedFrameCount = 0;
      stage = 'down';
    }

    final double currentDepth =
        calculateDepthRobust(midHip, midKnee, kneeAngle);

    if (stage == 'down') {
      repMinKneeAngle = math.min(repMinKneeAngle, kneeAngle);
      repMaxKneeAngle = math.max(repMaxKneeAngle, kneeAngle);
      repMaxDepth = math.max(repMaxDepth, currentDepth);

      if (repStartHipX != null && repStartAnkleX != null) {
        final double horizontalMovement = math.max(
          (midHip[0] - repStartHipX!).abs(),
          (midAnkle[0] - repStartAnkleX!).abs(),
        );
        repMaxHorizontalMovement =
            math.max(repMaxHorizontalMovement, horizontalMovement);
      }

      final double leftKneeAngle = calcAngle(lHip, lKnee, lAnkle);
      final double currentAsymmetry = (leftKneeAngle - kneeAngle).abs();
      repMaxAsymmetry = math.max(repMaxAsymmetry, currentAsymmetry);

      if (currentDepth < TuningParams.TOP_ZONE_DEPTH_MAX) {
        repMaxBackAngleTop = math.max(repMaxBackAngleTop, backAngle);
      } else if (currentDepth >= TuningParams.BOTTOM_ZONE_DEPTH_MIN) {
        repMaxBackAngleBottom = math.max(repMaxBackAngleBottom, backAngle);
      }

      if (currentDepth < TuningParams.TOP_ZONE_DEPTH_MAX &&
          backAngle > TuningParams.TOP_BACK_MAX_DEG) {
        repTopBadFrames += 1;
        if (repTopBadFrames >= TOP_BAD_MIN_FRAMES) {
          repHadBackFeedback = true;
          if (rtFbMsg != 'Try to keep your back a bit straighter') {
            rtFbMsg = 'Try to keep your back a bit straighter';
            rtFbHold = RT_FB_HOLD_FRAMES;
          } else {
            rtFbHold = math.max(rtFbHold, RT_FB_HOLD_FRAMES);
          }
        }
      } else if (currentDepth >= TuningParams.BOTTOM_ZONE_DEPTH_MIN &&
          backAngle > TuningParams.BOTTOM_BACK_MAX_DEG) {
        repBottomBadFrames += 1;
        if (repBottomBadFrames >= BOTTOM_BAD_MIN_FRAMES) {
          repHadBackFeedback = true;
        }
      } else {
        if (rtFbHold > 0) rtFbHold -= 1;
      }
    } else {
      if (rtFbHold > 0) rtFbHold -= 1;
    }

    final bool hasExcessiveHorizontal =
        repMaxHorizontalMovement > TuningParams.MAX_HORIZONTAL_ALLOWED;
    final bool hasExcessiveAsymmetry =
        repMaxAsymmetry > TuningParams.MAX_ASYMMETRY_ALLOWED;
    final bool hasMinimalDepth = repMaxDepth >= TuningParams.MIN_DEPTH_FOR_REP;
    final bool isPickupMotion = hasExcessiveHorizontal && hasExcessiveAsymmetry;
    final bool isValidRep = !isPickupMotion && hasMinimalDepth;

    final bool repFinishedPosture =
        (kneeAngle > TuningParams.STAND_KNEE_ANGLE) ||
            (kneeAngle >
                    (TuningParams.STAND_KNEE_ANGLE -
                        TuningParams.REP_FINISH_KNEE_MARGIN) &&
                currentDepth <= TuningParams.REP_FINISH_DEPTH_MAX);
    final bool repFinishGateOk =
        (movementFreeStreak >= TuningParams.MOVEMENT_CLEAR_FRAMES) ||
            (currentDepth <= TuningParams.REP_FINISH_ALLOW_MOVING_DEPTH_MAX);

    if (repFinishedPosture && stage == 'down' && repFinishGateOk) {
      final int repDuration =
          (repStartFrame != null) ? (frameIdx1Based - repStartFrame!) : 0;
      // [v21] Per-variant min duration (bodyweight: 2 frames).
      final bool durationOk = repDuration >= cfg.minRepFrames;

      if (!isValidRep || !durationOk) {
        abortRep();
        frameTelemetry.add({
          't': tSec,
          'reps': counter,
          'depth': currentDepth,
          'metric_label': 'DEPTH',
          'metric_value': currentDepth,
          'feedback': (rtFbHold > 0 && rtFbMsg != null) ? rtFbMsg : null,
          'rep_just_finished': repJustFinished,
          'landmarks': normLandmarks,
        });
        continue;
      }

      final List<String> feedbacks = [];
      double penalty = 0.0;
      final double depthPct = repMaxDepth;

      if (depthPct < DEPTH_FAIR) {
        feedbacks.add('Try to squat deeper');
        penalty += TuningParams.PENALTY_DEPTH_SEVERE;
      } else if (depthPct < DEPTH_ALMOST) {
        feedbacks.add('Almost there — go a bit lower');
        penalty += TuningParams.PENALTY_DEPTH_MODERATE;
      } else if (depthPct < DEPTH_GOOD) {
        feedbacks.add('Looking good — just a bit more depth');
        penalty += TuningParams.PENALTY_DEPTH_MINOR;
      }

      if (repHadBackFeedback) {
        feedbacks.add('Try to keep your back a bit straighter');
        penalty += TuningParams.PENALTY_BACK;
      }

      double score;
      if (feedbacks.isEmpty) {
        score = TuningParams.PERFECT_SCORE;
      } else {
        score = math.max(
            TuningParams.MIN_REP_SCORE, TuningParams.PERFECT_SCORE - penalty);
        score = (score * 2).round() / 2.0;
        score = math.min(score, TuningParams.MAX_IMPERFECT_SCORE);
      }

      final catResult = pickStrongestPerCategory(feedbacks);
      final List<String> repFeedbacks =
          List<String>.from(catResult['list'] as List);
      final Map<String, String> repFeedbackByCat =
          Map<String, String>.from(catResult['byCat'] as Map);

      double safeStartKnee = startKneeAngle ?? kneeAngle;
      if (safeStartKnee.isNaN || safeStartKnee.isInfinite)
        safeStartKnee = 160.0;
      double safeMinKnee = repMinKneeAngle;
      if (safeMinKnee.isNaN || safeMinKnee.isInfinite) safeMinKnee = 160.0;
      double safeMaxKnee = repMaxKneeAngle;
      if (safeMaxKnee.isNaN || safeMaxKnee.isInfinite) safeMaxKnee = 160.0;
      double safeBackTop = repMaxBackAngleTop;
      if (safeBackTop.isNaN || safeBackTop.isInfinite) safeBackTop = 0.0;
      double safeBackBottom = repMaxBackAngleBottom;
      if (safeBackBottom.isNaN || safeBackBottom.isInfinite)
        safeBackBottom = 0.0;

      repReports.add({
        'rep_index': counter + 1,
        'score': double.parse(score.toStringAsFixed(1)),
        'score_display': displayHalfStr(score),
        'feedback': repFeedbacks,
        'tip': null,
        'start_frame': repStartFrame ?? 0,
        'end_frame': frameIdx1Based,
        'start_knee_angle': double.parse(safeStartKnee.toStringAsFixed(2)),
        'min_knee_angle': double.parse(safeMinKnee.toStringAsFixed(2)),
        'max_knee_angle': double.parse(safeMaxKnee.toStringAsFixed(2)),
        'torso_angle_top': double.parse(safeBackTop.toStringAsFixed(2)),
        'torso_angle_bottom': double.parse(safeBackBottom.toStringAsFixed(2)),
        'depth_pct': depthPct,
        'top_bad_frames': repTopBadFrames,
        'bottom_bad_frames': repBottomBadFrames,
      });

      repFeedbackByCat.forEach((cat, fb) {
        final cur = sessionFeedbackByCat[cat];
        if (cur == null || (FB_SEVERITY[fb] ?? 1) > (FB_SEVERITY[cur] ?? 1)) {
          sessionFeedbackByCat[cat] = fb;
        }
      });

      startKneeAngle = null;
      repStartFrame = null;
      repStartHipX = null;
      repStartAnkleX = null;
      repMaxHorizontalMovement = 0.0;
      repMaxAsymmetry = 0.0;
      repRejectedFrameCount = 0;
      stage = 'up';

      if (frameIdx1Based - lastRepFrame >
          TuningParams.MIN_FRAMES_BETWEEN_REPS) {
        counter += 1;
        lastRepFrame = frameIdx1Based;
        if (score >= TuningParams.MAX_IMPERFECT_SCORE) {
          goodReps += 1;
          repJustFinished = 'good';
        } else {
          badReps += 1;
          repJustFinished = 'bad';
          if (repFeedbacks.isNotEmpty) {
            String strongest = repFeedbacks.first;
            int bestSev = FB_SEVERITY[strongest] ?? 1;
            for (final f in repFeedbacks) {
              final sev = FB_SEVERITY[f] ?? 1;
              if (sev > bestSev) {
                bestSev = sev;
                strongest = f;
              }
            }
            finalRepFbOverride = strongest;
            rtFbMsg = strongest;
            rtFbHold = RT_FB_HOLD_FRAMES;
          }
        }
        allScores.add(score);
      }
    }

    String? fbVal;
    if (finalRepFbOverride != null) {
      fbVal = finalRepFbOverride;
      finalRepFbOverride = null;
    } else if (rtFbHold > 0 && rtFbMsg != null) {
      fbVal = rtFbMsg;
    }

    frameTelemetry.add({
      't': tSec,
      'reps': counter,
      'depth': currentDepth,
      'metric_label': 'DEPTH',
      'metric_value': currentDepth,
      'feedback': fbVal,
      'rep_just_finished': repJustFinished,
      'landmarks': normLandmarks,
    });
    repJustFinished = null;
  }

  // ============================================================
  // [v15] UNRACK / WARM-UP FIRST-REP REJECTION
  //
  // The squat counter sometimes catches the bar-pickup motion as a rep:
  // when the lifter unracks the barbell, they go through a partial squat
  // (knees bend a bit, hips drop slightly). That motion satisfies the
  // counter's "down → up" sequence and gets counted as rep 1, even
  // though it's not actually a squat attempt.
  //
  // We don't change the detection logic — every guard we tried there
  // either missed real shallow first reps or broke valid reps that
  // happened to start similarly. Instead, we do a retroactive check
  // AFTER all reps are detected:
  //
  //   IF (rep count ≥ UNRACK_MIN_REPS_FOR_CHECK)
  //   AND (rep 1 depth < FRACTION × median of reps 2..K)
  //   THEN drop rep 1.
  //
  // Threshold reasoning: a real first rep might be a touch less deep
  // than later reps (people sometimes ease into a set), but it's never
  // DRAMATICALLY shallower. An unrack rep, on the other hand, almost
  // always produces a depth value 30-50% of a real squat — a different
  // order of magnitude. Requiring rep 1 to be less than 50% of the
  // median catches unrack motion confidently while leaving normal
  // warm-up reps alone.
  //
  // [v21] Skipped for variants without a bar pickup (bodyweight, goblet).
  // ============================================================
  if (cfg.unrackRejection &&
      repReports.length >= TuningParams.UNRACK_MIN_REPS_FOR_CHECK) {
    final double firstRepDepth =
        (repReports[0]['depth_pct'] as num?)?.toDouble() ?? 0.0;

    // Collect the next K reps' depth values as the peer group.
    final int peerEnd = math.min(
        repReports.length, 1 + TuningParams.UNRACK_PEER_REPS_TO_CONSIDER);
    final List<double> peerDepths = [];
    for (int r = 1; r < peerEnd; r++) {
      final double d = (repReports[r]['depth_pct'] as num?)?.toDouble() ?? 0.0;
      if (d > 0) peerDepths.add(d);
    }

    if (peerDepths.length >= 2) {
      peerDepths.sort();
      final int mid = peerDepths.length ~/ 2;
      final double peerMedian = peerDepths.length.isOdd
          ? peerDepths[mid]
          : (peerDepths[mid - 1] + peerDepths[mid]) / 2.0;

      final double threshold =
          peerMedian * TuningParams.UNRACK_FIRST_REP_DEPTH_PEER_FRACTION;
      final bool failedRatio = firstRepDepth < threshold;
      final bool failedAbsolute =
          firstRepDepth < TuningParams.UNRACK_FIRST_REP_ABSOLUTE_MAX &&
              peerMedian >= TuningParams.UNRACK_ABSOLUTE_CHECK_MIN_PEER_DEPTH;
      if (failedRatio || failedAbsolute) {
        // Rep 1 is the unrack — remove it cleanly.
        //
        // Things to fix:
        //   1. The rep record itself (repReports[0]).
        //   2. The session counters (counter, goodReps/badReps, allScores).
        //   3. The frame telemetry — the 'reps' field on each frame past
        //      rep 1's end_frame is offset by 1, the rep_just_finished
        //      pulse that fired for rep 1 needs to be cleared so the UI
        //      doesn't show a phantom flash/sound/haptic for the unrack,
        //      and [v17] the feedback message (e.g. "Try to squat deeper")
        //      that was written to the unrack's end frame + the RT_FB_HOLD
        //      tail must be wiped — otherwise the user sees a feedback
        //      bubble appear over a counter that still reads 0 reps.
        //
        // We also renumber the surviving reps' rep_index so they read
        // 1, 2, 3, ... instead of 2, 3, 4, ...
        final Map<String, dynamic> removed = repReports.removeAt(0);
        counter -= 1;

        if (allScores.isNotEmpty) allScores.removeAt(0);

        final double removedScore =
            (removed['score'] as num?)?.toDouble() ?? 0.0;
        if (removedScore >= TuningParams.MAX_IMPERFECT_SCORE) {
          if (goodReps > 0) goodReps -= 1;
        } else {
          if (badReps > 0) badReps -= 1;
        }

        for (int r = 0; r < repReports.length; r++) {
          repReports[r]['rep_index'] = r + 1;
        }

        // Patch the frame telemetry.
        final int unrackEndFrame = (removed['end_frame'] as int?) ?? 0;

        // [v17] Compute the window of frames over which the unrack's
        // feedback bubble could have been displayed:
        //
        //   - It starts at the unrack's start_frame: while the unrack
        //     was being detected as a "rep in progress", real-time
        //     feedback could have fired (e.g. back-angle warnings) and
        //     been held via rtFbHold.
        //   - It ends at unrackEndFrame + RT_FB_HOLD_FRAMES: when the
        //     rep finished, finalRepFbOverride wrote the message to the
        //     end frame, and rtFbHold kept it alive for the next few
        //     frames.
        //
        // We must NOT wipe feedback that belongs to the real first rep
        // (now repReports[0] after the removeAt above). So we clamp the
        // window to stop at the surviving first rep's start_frame minus
        // one. If no rep survives, just use the end-of-hold window.
        final int unrackStartFrame = (removed['start_frame'] as int?) ?? 0;
        final int survivingFirstRepStart = repReports.isNotEmpty
            ? ((repReports[0]['start_frame'] as int?) ??
                (unrackEndFrame + RT_FB_HOLD_FRAMES + 1))
            : (unrackEndFrame + RT_FB_HOLD_FRAMES + 1);
        final int feedbackClearEnd = math.min(
          unrackEndFrame + RT_FB_HOLD_FRAMES,
          survivingFirstRepStart - 1,
        );

        for (int j = 0; j < frameTelemetry.length; j++) {
          final int frameNumber = j + 1;
          final int curReps = (frameTelemetry[j]['reps'] as num?)?.toInt() ?? 0;

          if (frameNumber >= unrackEndFrame && curReps > 0) {
            frameTelemetry[j]['reps'] = curReps - 1;
          }

          if (frameNumber == unrackEndFrame) {
            frameTelemetry[j]['rep_just_finished'] = null;
          }

          // [v17] Wipe the unrack's leaked feedback bubble.
          if (frameNumber >= unrackStartFrame &&
              frameNumber <= feedbackClearEnd) {
            frameTelemetry[j]['feedback'] = null;
          }
        }

        // Rebuild session-level feedback from the surviving reps so the
        // unrack's "go a bit lower" doesn't leak into the session message.
        sessionFeedbackByCat.clear();
        for (final r in repReports) {
          final List<dynamic>? repFb = r['feedback'] as List<dynamic>?;
          if (repFb == null) continue;
          for (final fbDyn in repFb) {
            final String fb = fbDyn.toString();
            final String cat = FEEDBACK_CATEGORY[fb] ?? 'other';
            final cur = sessionFeedbackByCat[cat];
            if (cur == null ||
                (FB_SEVERITY[fb] ?? 1) > (FB_SEVERITY[cur] ?? 1)) {
              sessionFeedbackByCat[cat] = fb;
            }
          }
        }
      }
    }
  }
  // ============================================================
  // [end v15 UNRACK FIRST-REP REJECTION]
  // ============================================================

  // ============================================================
  // [v18] BACK/FRONT-VIEW FALLBACK
  //
  // The side-view pipeline is done. If it produced (almost) no reps but
  // the footage looks front/back-facing, the side pipeline simply can't
  // see this angle (see the _BackView section comments). Run the
  // independent hip-drop detector and, if it found real reps, REPLACE the
  // empty side-view result with it.
  //
  // Guard conditions (all must hold to switch to back-view results):
  //   1. Side pipeline counted very few reps (<= 1). A working side video
  //      always counts more, so this never triggers on normal clips.
  //   2. The footage scores as front/back-facing on enough frames.
  //   3. The back-view detector itself found at least 2 reps (avoids
  //      promoting a single noisy blip into the whole result).
  //
  // When we switch, we also rewrite the per-frame telemetry's running
  // 'reps' counter and re-emit the rep pulses/feedback so the on-screen
  // overlay matches the new count. The side pipeline's telemetry (depth %,
  // landmarks) is left intact — only the rep-related fields are patched.
  // ============================================================
  Map<String, dynamic>? backViewDebug;
  if (counter <= 1) {
    final double viewScore = computeFrontBackViewScore(allSmoothedLandmarks);
    if (viewScore >= _BackViewParams.MIN_FRONTBACK_VIEW_FRACTION) {
      final Map<String, dynamic> bv = detectBackViewReps(
        allSmoothedLandmarks,
        frameRejected,
        fps,
        depthScale: cfg.backViewScale,
      );
      final int bvCount = bv['count'] as int;

      // Always surface debug so you can calibrate even when not adopted.
      backViewDebug = {
        'view_score': double.parse(viewScore.toStringAsFixed(3)),
        'back_count': bvCount,
        'signal_max': bv['signal_max'],
        'adopted': false,
        'signal_trace': bv['signal_trace'],
      };

      if (bvCount >= 2 && bvCount > counter) {
        // Adopt the back-view results.
        backViewDebug['adopted'] = true;
        counter = bvCount;
        goodReps = bv['good'] as int;
        badReps = bv['bad'] as int;

        allScores
          ..clear()
          ..addAll((bv['scores'] as List).map((e) => (e as num).toDouble()));

        repReports
          ..clear()
          ..addAll(
              (bv['reps'] as List).map((e) => Map<String, dynamic>.from(e)));

        sessionFeedbackByCat
          ..clear()
          ..addAll(Map<String, String>.from(bv['feedbackByCat'] as Map));

        // Rebuild the running rep counter + pulses in the telemetry.
        final List<Map<String, dynamic>> events =
            (bv['rep_events'] as List).map((e) {
          return Map<String, dynamic>.from(e as Map);
        }).toList();

        // Map end_frame -> event for quick lookup.
        final Map<int, Map<String, dynamic>> eventByEndFrame = {};
        for (final ev in events) {
          eventByEndFrame[ev['end_frame'] as int] = ev;
        }

        // [v19] STEP 1 — fully wipe the side pipeline's rep-related fields
        // across the WHOLE telemetry. We adopted the back-view result, so
        // the side pipeline's pulses and feedback are all stale (they
        // belonged to the 1 phantom rep it miscounted). Leaving them in is
        // exactly what produced "two different depth feedbacks on one rep"
        // and orphan colored skeletons with no matching feedback.
        //
        // We also FORCE pose_reliable = true on every telemetry frame. The
        // widget hides the skeleton whenever a frame (or its interpolation
        // neighbor) is pose_reliable == false. The side squat pipeline
        // never sets that flag (defaults true), but to be safe against any
        // false flag leaking in from a future change — and because the
        // back-view detector has already validated these frames via its own
        // signal — we assert reliability here so the skeleton stays solid
        // and stops blinking on the descent. This is the root cause of the
        // "skeleton jumps and disappears too fast" symptom from behind.
        //
        // And we overwrite the per-frame depth metric with the BACK-VIEW
        // signal. The side pipeline's calculateDepthRobust reads ~0 from
        // behind (hip-below-knee in image-Y barely moves), which is why the
        // on-screen depth ring sat at 0% the whole rep. The back-view signal
        // (torso compression / hip drop, 0..~0.45) is the right quantity;
        // we rescale it into a 0..1 ring fill using the same depth bands the
        // detector scores against, so the ring fills meaningfully.
        final Map<int, double> sigByFrame = {};
        for (final s in (bv['signal_trace'] as List)) {
          final m = s as Map;
          sigByFrame[m['frame'] as int] = (m['sig'] as num).toDouble();
        }
        // Map a raw signal value (0..~0.45) to a 0..1 ring fill. DEPTH_GOOD
        // (scaled per variant) reads as a full ring; below that scales
        // linearly.
        double sigToRing(double sig) {
          final double full = _BackViewParams.DEPTH_GOOD * cfg.backViewScale;
          if (full <= 1e-6) return 0.0;
          final double r = sig / full;
          return r < 0.0 ? 0.0 : (r > 1.0 ? 1.0 : r);
        }

        for (int j = 0; j < frameTelemetry.length; j++) {
          frameTelemetry[j]['rep_just_finished'] = null;
          frameTelemetry[j]['feedback'] = null;
          frameTelemetry[j]['pose_reliable'] = true;
          final double? sig = sigByFrame[j + 1];
          if (sig != null) {
            final double ring = sigToRing(sig);
            frameTelemetry[j]['depth'] = ring;
            frameTelemetry[j]['metric_value'] = ring;
          }
        }

        // [v19] STEP 2 — re-emit pulses in the exact contract the widget
        // already understands (see SquatAnalyzedVideoPlayer):
        //   - rep_just_finished fires on EXACTLY ONE frame (the top of the
        //     lift). The widget keys haptics/sound off this single pulse,
        //     and drives the colored-skeleton flash by searching backward
        //     for the most recent pulse and fading over flash_duration_sec.
        //   - We therefore also stamp flash_duration_sec on the pulse frame
        //     so the widget holds the color for a controlled, readable time
        //     instead of falling back to its gap-based estimate. We match
        //     the side pipeline's RT_FB_HOLD window for visual consistency.
        //   - The feedback bubble is drawn from each frame's own feedback,
        //     so we fill feedback across the hold window after the pulse so
        //     it stays on screen exactly as long as the color flash, which
        //     fixes both "colored skeleton with no feedback" and "feedback
        //     vanishes too fast".
        final double flashDurSec = RT_FB_HOLD_FRAMES / fps;
        int runningReps = 0;
        for (int j = 0; j < frameTelemetry.length; j++) {
          final int frameNumber = j + 1;
          final ev = eventByEndFrame[frameNumber];
          if (ev != null) {
            runningReps += 1;
            frameTelemetry[j]['rep_just_finished'] = ev['tag'];
            frameTelemetry[j]['flash_duration_sec'] = flashDurSec;
            // Fill the feedback bubble across the hold window (this frame
            // plus the next RT_FB_HOLD_FRAMES-1), stopping early if another
            // rep's pulse begins.
            final String? fbMsg = ev['feedback'] as String?;
            if (fbMsg != null) {
              for (int k = 0;
                  k < RT_FB_HOLD_FRAMES && (j + k) < frameTelemetry.length;
                  k++) {
                final int holdFrameNo = j + k + 1;
                if (k > 0 && eventByEndFrame.containsKey(holdFrameNo)) break;
                frameTelemetry[j + k]['feedback'] = fbMsg;
              }
            }
          }
          frameTelemetry[j]['reps'] = runningReps;
        }
      }
    }
  }
  // ============================================================
  // [end v18 BACK/FRONT-VIEW FALLBACK]
  // ============================================================

  if (TuningParams.TELEMETRY_LEAD_SEC > 0.0) {
    for (final frame in frameTelemetry) {
      final double tOrig = (frame['t'] as num).toDouble();
      frame['t'] = math.max(0.0, tOrig - TuningParams.TELEMETRY_LEAD_SEC);
    }
  }

  double avg = 0.0;
  if (allScores.isNotEmpty) {
    avg = allScores.reduce((a, b) => a + b) / allScores.length;
  }
  if (avg.isNaN || avg.isInfinite) avg = 0.0;
  double techniqueScore =
      double.parse((((avg * 2).round() / 2.0)).toStringAsFixed(2));

  final List<String> sessionFeedbacks = sessionFeedbackByCat.values.toList();
  if (sessionFeedbacks.isNotEmpty) {
    techniqueScore = math.min(techniqueScore, TuningParams.MAX_IMPERFECT_SCORE);
  }

  final bool noRepsDetected = counter == 0;

  final List<String> feedbackList;
  if (noRepsDetected) {
    feedbackList = <String>[
      "Couldn't analyze this video — make sure your full body is visible from the side and that you complete at least one squat."
    ];
  } else if (sessionFeedbacks.isNotEmpty) {
    feedbackList = sessionFeedbacks;
  } else {
    feedbackList = <String>['Great form! Keep it up 💪'];
  }

  String? sessionTip;
  if (noRepsDetected) {
    sessionTip = null;
  } else if (sessionFeedbackByCat.isNotEmpty) {
    if (sessionFeedbackByCat.containsKey('depth')) {
      sessionTip =
          'Focus on hip mobility and ankle flexibility to achieve better depth';
    } else if (sessionFeedbackByCat.containsKey('back')) {
      sessionTip =
          'Work on core strength and practice maintaining a neutral spine';
    } else if (sessionFeedbackByCat.containsKey('knees')) {
      sessionTip =
          'Practice the \'knees out\' cue and consider strengthening your hip abductors';
    }
  } else {
    sessionTip =
        'Outstanding consistency! Keep challenging yourself with progressive overload';
  }

  final String fileUri = 'file://$videoPath';

  return {
    'squat_count': counter,
    'technique_score': techniqueScore,
    'technique_score_display': displayHalfStr(techniqueScore),
    'technique_label': scoreLabel(techniqueScore),
    'good_reps': goodReps,
    'bad_reps': badReps,
    'feedback': feedbackList,
    'tip': sessionTip,
    'reps': repReports,
    'video_path': fileUri,
    'analyzed_fps': fps,
    'frame_count': frameIdx,
    '_source_video_uri': fileUri,
    '_frame_telemetry': frameTelemetry,
    'squat_variant': variant ?? 'back',
    // [v18] Back-view calibration debug (null on normal side videos).
    '_backview_debug': backViewDebug,
    // [v22] How many times the ML Kit tracker was reset after a loss.
    // 0 on a clean clip. >0 means something occluded the lifter.
    '_tracker_resets': trackerResets,
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
