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
import 'package:pose_detection/pose_detection.dart' as pd;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

// ============================================================================
// HEAVY EDITION — README (read this before tweaking anything)
// ============================================================================
//
// This file is a parallel implementation of analyzeSquatVideoAction that swaps
// the pose backend from google_mlkit_pose_detection (BlazePose Full via ML Kit)
// to the pose_detection package (BlazePose Heavy via TFLite + YOLOv8n detector).
//
// Target package version: pose_detection: ^3.1.5  (verified 27 May 2026).
//
// 3.1.5 ships a different API than the 1.x line — most notably:
//   * Detector is created via the static factory  PoseDetector.create(...)
//     which both constructs and initialises in one call. No separate
//     await detector.initialize().
//   * The `interpreterPoolSize` knob from 1.x is gone. Acceleration is
//     selected through `performanceConfig`, e.g. PerformanceConfig.xnnpack().
//   * Each returned `Pose` carries its own `imageWidth` and `imageHeight`,
//     so we no longer need a JPEG-header probe to learn frame dimensions.
//   * Detector accepts `detectorIou`, `maxDetections`, `minLandmarkScore`
//     for finer control of the YOLOv8n + landmark pipeline.
//
// If you ever upgrade past 3.1.x and the API breaks, the four touch points
// above are where breakage will land first.
//
// What changes vs. the ML Kit action:
//
//   1. Backend swap. ML Kit "accurate" SDK is BlazePose Full. The new
//      pose_detection package exposes lite / full / heavy explicitly. We use
//      heavy here for the meaningful jump in landmark accuracy on yoga /
//      fitness / dance domains (per the BlazePose GHUM paper, heavy is
//      ~5-6 mAP higher than full on those verticals).
//
//   2. Multi-person handling. ML Kit gives you "the prominent person".
//      pose_detection runs YOLOv8n first and returns a List<Pose>. We pick
//      the lifter ourselves — see _hvPickMainPose. This protects against
//      spotters, training partners, or random people walking through.
//
//   3. Bounding box utilization. YOLOv8 gives us a real bbox per person.
//      We use it for four things the ML Kit pipeline can't do:
//        a) Tracking between frames via IoU — keeps us locked on the same
//           person even when multi-person detection is unstable.
//        b) Out-of-frame detection — if the bbox touches the frame edge,
//           we know the lifter is partially cut off and downgrade trust.
//        c) Bbox-based jump rejection — works alongside the existing
//           hip-jump rejection, but catches a different failure mode:
//           sudden bbox teleportation typically means the model switched
//           to a different person, even if hip position happens to match.
//        d) Landmark sanity check — landmarks that fall significantly
//           outside the bbox are very likely model errors. We zero out
//           their visibility before downstream processing.
//
//   4. Naming. Everything specific to this file is prefixed `Hv` / `_hv`
//      so this can sit next to the ML Kit version in FlutterFlow without
//      class-name collisions. The TuningParams class is HeavyTuningParams.
//
// What's IDENTICAL to the ML Kit action (intentionally, so the two are
// directly comparable):
//
//   - Same function signature and return shape (so the UI stays plug-in).
//   - Same FFmpeg frame extraction parameters.
//   - Same Savitzky-Golay smoothing (offline, post-pass).
//   - Same hysteresis-on-arms + body-calibration visibility filter.
//   - Same rep detection state machine, scoring, depth math.
//   - Same unrack first-rep rejection logic.
//   - Same frame telemetry shape for UI playback.
//
// If a rep counts differently between this and the ML Kit version, the
// difference comes ONLY from the better landmark inputs (and the bbox
// guards). The decision logic above the landmarks is byte-identical.
//
// Performance note. Heavy model is slower per frame than Full. For offline
// video analysis at 12 fps this is fine — we have all the time we need —
// but expect total analysis to take roughly 2-3x longer than the ML Kit
// version on the same device. If you ever want to use this pipeline for
// real-time camera processing, drop heavy → full or full → lite via
// HeavyTuningParams.LANDMARK_MODEL.
// ============================================================================

// ============================================================================
// =========================== TUNABLE PARAMETERS =============================
// ============================================================================
class HeavyTuningParams {
  // ---------------------- POSE_DETECTION PACKAGE (v3.1.5 API) ----------------------
  // The landmark model to use. Heavy is meaningfully more accurate than
  // Full on fitness poses but takes ~2-3x the per-frame time. For
  // offline video analysis the trade is worth it.
  // Values: pd.PoseLandmarkModel.lite | .full | .heavy
  static final pd.PoseLandmarkModel LANDMARK_MODEL = pd.PoseLandmarkModel.heavy;

  // YOLOv8n person-detector parameters. These have sensible defaults
  // inside the package — we now follow the Quick Start example and
  // DO NOT pass them, so they're documented here for reference only.
  // If you want to surface them, re-add them to the `PoseDetector.create`
  // call in the detection loop. Caveat: in 3.1.5 these names should
  // match exactly (detectorConf / detectorIou / maxDetections /
  // minLandmarkScore); if a future release renames any of them, the
  // explicit pass will crash init while the minimal call still works.
  static const double DEFAULT_DETECTOR_CONF =
      0.6; // v2: 0.5->0.6. Tighter threshold reduces YOLOv8 false positives.
  static const double DEFAULT_DETECTOR_IOU = 0.4;
  static const int DEFAULT_MAX_DETECTIONS =
      1; // v2: 5->1. Single-person video. Massive perf win — Heavy model runs once per frame, not N times.
  static const double DEFAULT_MIN_LANDMARK_SCORE = 0.5;

  // ---------------------- VIDEO EXTRACTION (FFmpeg) ----------------------
  static const double DEFAULT_FPS =
      8.0; // v2: 12->8 for ~33% speedup, still ample for squat
  static const int FRAME_MAX_WIDTH =
      640; // v2: 1080->640. BlazePose resizes internally to 256, so we just save FFmpeg encode time + disk I/O.
  static const int JPEG_QUALITY = 2;

  // ---------------------- SAVITZKY-GOLAY FILTER ----------------------
  static const int SG_WINDOW_SIZE = 11;
  static const int SG_POLY_ORDER = 2;
  static const double SG_VIS_THRESHOLD =
      0.35; // v2: 0.5->0.35. Heavy distribution adjustment.

  // ---------------------- TELEMETRY SYNC ----------------------
  static const double TELEMETRY_LEAD_SEC = 0.0;

  // ---------------------- LANDMARK VISIBILITY (HYSTERESIS) ----------------------
  static const double VIS_HIDE_THRESHOLD =
      0.30; // v2: 0.40->0.30. Heavy outputs lower visibility scores in general — this threshold matched Full's distribution and was over-hiding landmarks for Heavy.
  static const double VIS_SHOW_THRESHOLD =
      0.45; // v2: 0.60->0.45. Companion to VIS_HIDE_THRESHOLD reduction.
  static const double LOW_CORE_VIS_THRESHOLD =
      0.4; // v2: 0.5->0.4. Heavy outputs lower visibility scores; was rejecting valid frames.

  // ---------------------- ANATOMICAL PLAUSIBILITY ----------------------
  static const double MAX_ELBOW_BEND_DEG = 170.0;
  static const double MIN_ELBOW_BEND_DEG = 15.0;

  // ---------------------- BODY CALIBRATION ----------------------
  static const bool BODY_CALIBRATION_ENABLED = true;
  static const int BODY_CAL_MIN_FRAMES = 8;
  static const double BODY_CAL_MAX_RATIO = 1.6;
  static const double BODY_CAL_MIN_RATIO = 0.35;
  static const double BODY_CAL_VIS_FLOOR = 0.5;

  // ---------------------- JUMP / GLITCH REJECTION (hip-based) ----------------------
  static const double JUMP_REJECT_HIP_FRAC = 0.18;
  static const int JUMP_RECOVER_FRAMES = 3;
  static const int JUMP_REJECT_MAX_CONSECUTIVE = 6;

  // ---------------------- BBOX-BASED PROTECTIONS (NEW) ----------------------
  // Minimum bbox area as fraction of frame area. Below this we treat
  // the frame as "lifter too far away / mostly cropped" and reject.
  static const double BBOX_MIN_AREA_FRAC =
      0.02; // v2: 0.04->0.02. Less aggressive — Heavy is more accurate even on smaller subjects.

  // If the bbox extends within this fraction of any frame edge, we flag
  // the lifter as partially out of frame. We don't reject the frame for
  // this alone, but we suppress real-time back-angle warnings during
  // out-of-frame stretches (the math is unreliable there).
  static const double BBOX_EDGE_MARGIN_FRAC = 0.015;

  // IoU threshold for tracking the same person between frames. If the
  // largest bbox in the new frame has IoU < this with the previous
  // accepted lifter's bbox, we look for a better match among the other
  // candidates instead of blindly taking the biggest.
  static const double BBOX_TRACKING_IOU_MIN = 0.3;

  // Fraction of frame diagonal a bbox center can teleport between
  // frames before we mark it suspicious. Larger than the hip-jump
  // threshold because bboxes are noisier; this is a coarser guard.
  static const double BBOX_CENTER_JUMP_FRAC = 0.25;

  // Landmark-outside-bbox tolerance. When a landmark sits more than
  // this fraction of bbox-diagonal outside the bbox, we zero its
  // visibility. Catches the "wrist flies to the barbell" failure mode
  // that's especially common at top of squat.
  static const double LM_OUTSIDE_BBOX_MARGIN =
      0.30; // v2: 0.10->0.30. The previous tight margin was zeroing legitimate landmarks (especially arms at top of squat) because YOLO bboxes are crop-tight. Heavy model in particular puts wrists/elbows slightly outside the torso bbox during reps — that's correct, not an error.

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

  // ---------------------- UNRACK REP REJECTION ----------------------
  static const int UNRACK_MIN_REPS_FOR_CHECK = 3;
  static const int UNRACK_PEER_REPS_TO_CONSIDER = 3;
  static const double UNRACK_FIRST_REP_DEPTH_PEER_FRACTION = 0.70;
  static const double UNRACK_FIRST_REP_ABSOLUTE_MAX = 0.85;
  static const double UNRACK_ABSOLUTE_CHECK_MIN_PEER_DEPTH = 0.90;
}
// ============================================================================

// ============================================================================
// Landmark indices in the 33-point BlazePose topology. Same as the ML Kit
// version — these are universal across BlazePose deployments.
// ============================================================================
const int _HV_IDX_NOSE = 0;
const int _HV_IDX_L_SHOULDER = 11;
const int _HV_IDX_R_SHOULDER = 12;
const int _HV_IDX_L_ELBOW = 13;
const int _HV_IDX_R_ELBOW = 14;
const int _HV_IDX_L_WRIST = 15;
const int _HV_IDX_R_WRIST = 16;
const int _HV_IDX_L_HIP = 23;
const int _HV_IDX_R_HIP = 24;
const int _HV_IDX_L_KNEE = 25;
const int _HV_IDX_R_KNEE = 26;
const int _HV_IDX_L_ANKLE = 27;
const int _HV_IDX_R_ANKLE = 28;

// pose_detection exposes PoseLandmarkType as an enum aligned with BlazePose.
// We snapshot the iteration order once so we can pull each landmark by index
// without a per-frame map lookup.
const List<pd.PoseLandmarkType> _HV_LM_ORDER = [
  pd.PoseLandmarkType.nose,
  pd.PoseLandmarkType.leftEyeInner,
  pd.PoseLandmarkType.leftEye,
  pd.PoseLandmarkType.leftEyeOuter,
  pd.PoseLandmarkType.rightEyeInner,
  pd.PoseLandmarkType.rightEye,
  pd.PoseLandmarkType.rightEyeOuter,
  pd.PoseLandmarkType.leftEar,
  pd.PoseLandmarkType.rightEar,
  pd.PoseLandmarkType.mouthLeft,
  pd.PoseLandmarkType.mouthRight,
  pd.PoseLandmarkType.leftShoulder,
  pd.PoseLandmarkType.rightShoulder,
  pd.PoseLandmarkType.leftElbow,
  pd.PoseLandmarkType.rightElbow,
  pd.PoseLandmarkType.leftWrist,
  pd.PoseLandmarkType.rightWrist,
  pd.PoseLandmarkType.leftPinky,
  pd.PoseLandmarkType.rightPinky,
  pd.PoseLandmarkType.leftIndex,
  pd.PoseLandmarkType.rightIndex,
  pd.PoseLandmarkType.leftThumb,
  pd.PoseLandmarkType.rightThumb,
  pd.PoseLandmarkType.leftHip,
  pd.PoseLandmarkType.rightHip,
  pd.PoseLandmarkType.leftKnee,
  pd.PoseLandmarkType.rightKnee,
  pd.PoseLandmarkType.leftAnkle,
  pd.PoseLandmarkType.rightAnkle,
  pd.PoseLandmarkType.leftHeel,
  pd.PoseLandmarkType.rightHeel,
  pd.PoseLandmarkType.leftFootIndex,
  pd.PoseLandmarkType.rightFootIndex,
];

// ============================================================================
// Bounding-box helpers (NEW — not in ML Kit version).
// ============================================================================

/// A normalized bbox snapshot we carry across frames for tracking.
/// All four fields are in 0..1 image space.
class _HvBbox {
  final double left;
  final double top;
  final double right;
  final double bottom;
  final double score;
  const _HvBbox(this.left, this.top, this.right, this.bottom, this.score);

  double get width => (right - left).abs();
  double get height => (bottom - top).abs();
  double get area => width * height;
  double get cx => (left + right) / 2.0;
  double get cy => (top + bottom) / 2.0;
}

/// Intersection-over-union of two bboxes. Used for between-frame tracking.
double _hvIou(_HvBbox a, _HvBbox b) {
  final double ix1 = math.max(a.left, b.left);
  final double iy1 = math.max(a.top, b.top);
  final double ix2 = math.min(a.right, b.right);
  final double iy2 = math.min(a.bottom, b.bottom);
  if (ix2 <= ix1 || iy2 <= iy1) return 0.0;
  final double inter = (ix2 - ix1) * (iy2 - iy1);
  final double union = a.area + b.area - inter;
  if (union <= 0) return 0.0;
  return inter / union;
}

/// Pick the lifter from a list of detected poses. Falls back from
/// tracking → biggest bbox → first pose.
///
/// Tracking rule: if [prev] is non-null, prefer the candidate with the
/// highest IoU above BBOX_TRACKING_IOU_MIN. This keeps us locked on
/// the same person even when YOLOv8 occasionally swaps bbox ordering.
///
/// Fallback: if no candidate clears the IoU threshold, pick the largest
/// bbox by area. This handles the first frame and recovery after the
/// lifter walks out and back in.
pd.Pose? _hvPickMainPose(
    List<pd.Pose> poses, _HvBbox? prev, int frameW, int frameH) {
  if (poses.isEmpty) return null;
  if (poses.length == 1) return poses.first;

  // Try IoU-based tracking first.
  if (prev != null) {
    pd.Pose? best;
    double bestIou = HeavyTuningParams.BBOX_TRACKING_IOU_MIN;
    for (final candidate in poses) {
      final cbb = _hvNormalizeBbox(candidate, frameW, frameH);
      final iou = _hvIou(prev, cbb);
      if (iou > bestIou) {
        bestIou = iou;
        best = candidate;
      }
    }
    if (best != null) return best;
  }

  // Fall back: largest bbox by area, weighted lightly by detection score.
  pd.Pose? best;
  double bestRank = -1.0;
  for (final candidate in poses) {
    final cbb = _hvNormalizeBbox(candidate, frameW, frameH);
    // Area dominates, score breaks ties.
    final rank = cbb.area * (0.5 + 0.5 * cbb.score);
    if (rank > bestRank) {
      bestRank = rank;
      best = candidate;
    }
  }
  return best ?? poses.first;
}

/// Convert a pd.Pose's bbox into our normalized form.
_HvBbox _hvNormalizeBbox(pd.Pose pose, int frameW, int frameH) {
  final bb = pose.boundingBox;
  final double w = frameW.toDouble();
  final double h = frameH.toDouble();
  return _HvBbox(
    (bb.left / w).clamp(0.0, 1.0),
    (bb.top / h).clamp(0.0, 1.0),
    (bb.right / w).clamp(0.0, 1.0),
    (bb.bottom / h).clamp(0.0, 1.0),
    pose.score.clamp(0.0, 1.0).toDouble(),
  );
}

/// Returns true if the bbox is touching any frame edge — meaning the
/// lifter is probably partially cropped. We use this to suppress some
/// real-time feedback during cropped stretches (the geometry is
/// unreliable there) but we DON'T reject the frame outright, because a
/// partial body can still produce useful rep counts.
bool _hvBboxAtFrameEdge(_HvBbox bb) {
  final m = HeavyTuningParams.BBOX_EDGE_MARGIN_FRAC;
  return bb.left <= m ||
      bb.top <= m ||
      bb.right >= 1.0 - m ||
      bb.bottom >= 1.0 - m;
}

/// Zero the visibility of any landmark that falls meaningfully outside
/// the bbox. This catches the BlazePose-classic failure mode where an
/// arm landmark "flies off" toward a bright object — barbell, window,
/// gym mirror, etc. — that the model briefly preferred over the real
/// arm.
///
/// We use bbox diagonal as the scale, not raw fractions of the frame,
/// so the tolerance auto-adapts to how big/small the lifter is in
/// the frame.
void _hvZeroLandmarksOutsideBbox(List<List<double>> normLandmarks, _HvBbox bb) {
  final double diag = math.sqrt(bb.width * bb.width + bb.height * bb.height);
  if (diag <= 0) return;
  final double margin = diag * HeavyTuningParams.LM_OUTSIDE_BBOX_MARGIN;

  final double minX = bb.left - margin;
  final double maxX = bb.right + margin;
  final double minY = bb.top - margin;
  final double maxY = bb.bottom + margin;

  for (final lm in normLandmarks) {
    if (lm.length < 3) continue;
    if (lm[2] <= 0.0) continue;
    final double x = lm[0];
    final double y = lm[1];
    if (x < minX || x > maxX || y < minY || y > maxY) {
      lm[2] = 0.0;
    }
  }
}

// ============================================================================
// Savitzky-Golay filter — identical logic to ML Kit version. Renamed
// internal helpers with `_hv` prefix so they don't collide if both
// actions live in the same FlutterFlow project.
// ============================================================================

List<double> _hvComputeSavGolCoefficients(int windowSize, int polyOrder) {
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

List<double?> _hvSavgolSmoothSeries(
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

List<List<List<double>>> _hvSavitzkyGolaySmoothAll(
  List<List<List<double>>> rawFrames,
) {
  final int n = rawFrames.length;
  if (n == 0) return rawFrames;

  const int numLandmarks = 33;

  final List<double> coeffs = _hvComputeSavGolCoefficients(
    HeavyTuningParams.SG_WINDOW_SIZE,
    HeavyTuningParams.SG_POLY_ORDER,
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
      if (vis < HeavyTuningParams.SG_VIS_THRESHOLD) {
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
    final smoothedX = _hvSavgolSmoothSeries(xSeries[lm], coeffs);
    final smoothedY = _hvSavgolSmoothSeries(ySeries[lm], coeffs);

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
// Hysteresis + body calibration + anatomical filter — identical math to
// ML Kit version. Body calibration limited to arms only (see ML Kit
// version's v16 comment for the rationale).
// ============================================================================

double _hvAngleAt(List<double> a, List<double> b, List<double> c) {
  final double rad = math.atan2(c[1] - b[1], c[0] - b[0]) -
      math.atan2(a[1] - b[1], a[0] - b[0]);
  double ang = (rad * 180.0 / math.pi).abs();
  if (ang > 180) ang = 360 - ang;
  return ang;
}

double _hvDist(List<double> a, List<double> b) {
  final dx = a[0] - b[0];
  final dy = a[1] - b[1];
  return math.sqrt(dx * dx + dy * dy);
}

class _HvBodySegment {
  final String name;
  final int a;
  final int b;
  final List<int> dependents;
  const _HvBodySegment(this.name, this.a, this.b, this.dependents);
}

const List<_HvBodySegment> _HV_BODY_SEGMENTS = [
  _HvBodySegment(
      'left_upper_arm', _HV_IDX_L_SHOULDER, _HV_IDX_L_ELBOW, [_HV_IDX_L_WRIST]),
  _HvBodySegment('right_upper_arm', _HV_IDX_R_SHOULDER, _HV_IDX_R_ELBOW,
      [_HV_IDX_R_WRIST]),
  _HvBodySegment('left_forearm', _HV_IDX_L_ELBOW, _HV_IDX_L_WRIST, []),
  _HvBodySegment('right_forearm', _HV_IDX_R_ELBOW, _HV_IDX_R_WRIST, []),
];

Map<String, double> _hvCalibrateBody(List<List<List<double>>> frames) {
  final Map<String, List<double>> samplesByName = {};

  for (final frame in frames) {
    if (frame.isEmpty) continue;
    for (final seg in _HV_BODY_SEGMENTS) {
      if (seg.name.endsWith('_rev')) continue;
      if (seg.a >= frame.length || seg.b >= frame.length) continue;

      final pa = frame[seg.a];
      final pb = frame[seg.b];
      if (pa.length < 3 || pb.length < 3) continue;
      if (pa[2] < HeavyTuningParams.BODY_CAL_VIS_FLOOR ||
          pb[2] < HeavyTuningParams.BODY_CAL_VIS_FLOOR) continue;

      final double d = _hvDist(pa, pb);
      if (d <= 1e-6) continue;
      samplesByName.putIfAbsent(seg.name, () => []).add(d);
    }
  }

  final Map<String, double> medians = {};
  samplesByName.forEach((name, list) {
    if (list.length < HeavyTuningParams.BODY_CAL_MIN_FRAMES) return;
    list.sort();
    final int mid = list.length ~/ 2;
    final double m =
        list.length.isOdd ? list[mid] : (list[mid - 1] + list[mid]) / 2.0;
    medians[name] = m;
    medians['${name}_rev'] = m;
  });

  return medians;
}

List<List<List<double>>> _hvApplyVisibilityFilters(
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

  bool applyToArmsOnly(int lm) {
    return lm == _HV_IDX_L_ELBOW ||
        lm == _HV_IDX_R_ELBOW ||
        lm == _HV_IDX_L_WRIST ||
        lm == _HV_IDX_R_WRIST;
  }

  for (int i = 0; i < n; i++) {
    final frame = out[i];
    if (frame.isEmpty) continue;

    for (int lm = 0; lm < numLandmarks && lm < frame.length; lm++) {
      final point = frame[lm];
      if (point.length < 3) continue;
      if (!applyToArmsOnly(lm)) continue;

      final double vis = point[2];

      if (isShown[lm]) {
        if (vis < HeavyTuningParams.VIS_HIDE_THRESHOLD) {
          isShown[lm] = false;
          point[2] = 0.0;
        }
      } else {
        if (vis >= HeavyTuningParams.VIS_SHOW_THRESHOLD) {
          isShown[lm] = true;
        } else {
          point[2] = 0.0;
        }
      }
    }
  }

  Map<String, double> calibrated = const {};
  if (HeavyTuningParams.BODY_CALIBRATION_ENABLED) {
    calibrated = _hvCalibrateBody(out);
  }

  for (int i = 0; i < n; i++) {
    final frame = out[i];
    if (frame.isEmpty) continue;

    if (calibrated.isNotEmpty) {
      for (final seg in _HV_BODY_SEGMENTS) {
        final double? cal = calibrated[seg.name];
        if (cal == null || cal <= 0) continue;
        if (seg.a >= frame.length || seg.b >= frame.length) continue;

        final pa = frame[seg.a];
        final pb = frame[seg.b];
        if (pa.length < 3 || pb.length < 3) continue;
        if (pa[2] <= 0.0 || pb[2] <= 0.0) continue;

        final double cur = _hvDist(pa, pb);
        final double ratio = cur / cal;

        final bool tooLong = ratio > HeavyTuningParams.BODY_CAL_MAX_RATIO;
        final bool tooShort = ratio < HeavyTuningParams.BODY_CAL_MIN_RATIO;
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

      final double elbowAngle = _hvAngleAt(s, e, w);
      final bool implausible =
          elbowAngle > HeavyTuningParams.MAX_ELBOW_BEND_DEG ||
              elbowAngle < HeavyTuningParams.MIN_ELBOW_BEND_DEG;

      if (implausible) {
        e[2] = 0.0;
        w[2] = 0.0;
      }
    }

    checkArm(_HV_IDX_L_SHOULDER, _HV_IDX_L_ELBOW, _HV_IDX_L_WRIST);
    checkArm(_HV_IDX_R_SHOULDER, _HV_IDX_R_ELBOW, _HV_IDX_R_WRIST);
  }

  return out;
}

// ============================================================================
// (Image-dimension probe removed in the 3.1.5 port — pose.imageWidth and
// pose.imageHeight now come back from the detector, making the JPEG-header
// walk redundant.)
// ============================================================================

/// Analyze a squat video locally using pose_detection package
/// (YOLOv8n + BlazePose Heavy via TFLite).
///
/// HEAVY EDITION — parallel implementation of analyzeSquatVideoAction.
/// Same signature, same return shape. Differences vs ML Kit version
/// are documented at the top of this file.
Future<dynamic> analyzeSquatVideoHeavyAction(
  FFUploadedFile videoFile,
  double? targetFps,
) async {
  // The function body lives inside a try/catch at the very bottom so the
  // function NEVER throws — any uncaught exception becomes a structured
  // JSON payload with code+detail+debug log. This is the contract for
  // TestFlight builds where you have no logcat / Xcode console.
  try {
    return await _analyzeSquatVideoHeavyImpl(videoFile, targetFps);
  } catch (e, st) {
    return {
      'error': 'uncaught_top_level',
      'detail': '$e',
      'squat_count': 0,
      'technique_score': 0.0,
      'technique_score_display': '0',
      'technique_label': 'Needs work',
      'good_reps': 0,
      'bad_reps': 0,
      'feedback': <String>['Internal error — see _debug.stack for the trace.'],
      'tip': null,
      'reps': <dynamic>[],
      'video_path': '',
      '_source_video_uri': '',
      '_frame_telemetry': <dynamic>[],
      '_engine': 'heavy',
      '_error_code': 'uncaught_top_level',
      '_error_detail': '$e',
      '_debug': [
        'analyze_squat_heavy crashed at top level',
        'exception: $e',
        'platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      ],
      '_debug_stack': st.toString().split('\n').take(20).toList(),
    };
  }
}

/// Internal implementation. The public wrapper above catches anything
/// this throws and turns it into a structured payload.
Future<dynamic> _analyzeSquatVideoHeavyImpl(
  FFUploadedFile videoFile,
  double? targetFps,
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

  final double fps =
      (targetFps ?? HeavyTuningParams.DEFAULT_FPS).clamp(2.0, 30.0);
  final double dt = 1.0 / fps;
  final int TOP_BAD_MIN_FRAMES =
      math.max(3, (HeavyTuningParams.TOP_BAD_MIN_SEC / dt).round());
  final int BOTTOM_BAD_MIN_FRAMES =
      math.max(3, (HeavyTuningParams.BOTTOM_BAD_MIN_SEC / dt).round());
  final int RT_FB_HOLD_FRAMES =
      math.max(2, (HeavyTuningParams.RT_FB_HOLD_SEC / dt).round());

  // We cache image dimensions per-run inside this closure rather than as
  // file-level globals, so two analyses running back-to-back can't trip
  // over each other's stale dims.
  int cachedW = -1;
  int cachedH = -1;

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

  // ============================================================
  // DEBUG LOG — captures every step. Surfaces as `_debug` in the
  // returned JSON so you can see exactly what happened even when
  // running through TestFlight with no attached debugger.
  // ============================================================
  final List<String> debugLog = [
    'analyze_squat_heavy v1 start',
    'platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
    'dart: ${Platform.version}',
    'target_fps_arg: $targetFps',
    'video_bytes: ${videoFile.bytes?.length ?? 0}',
    'video_name: ${videoFile.name ?? "(null)"}',
  ];

  Map<String, dynamic> errorPayloadWithDebug(
      String code, String detail, List<String> log) {
    return {
      'error': code,
      'detail': detail,
      'squat_count': 0,
      'technique_score': 0.0,
      'technique_score_display': '0',
      'technique_label': 'Needs work',
      'good_reps': 0,
      'bad_reps': 0,
      'feedback': <String>['Could not analyze video — see _debug for details'],
      'tip': null,
      'reps': <dynamic>[],
      'video_path': '',
      '_source_video_uri': '',
      '_frame_telemetry': <dynamic>[],
      '_engine': 'heavy',
      '_debug': log,
      '_error_code': code,
      '_error_detail': detail,
    };
  }

  Map<String, dynamic> errorPayload(String code, String detail) =>
      errorPayloadWithDebug(code, detail, debugLog);

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
    'squat_hv_in_${DateTime.now().millisecondsSinceEpoch}_$safeName',
  );
  try {
    await File(videoPath).writeAsBytes(videoFile.bytes!, flush: true);
  } catch (e) {
    return errorPayload('write_failed', 'Could not save upload: $e');
  }

  final String sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  final Directory framesDir =
      Directory(p.join(tmp.path, 'squat_hv_frames_$sessionId'));
  if (framesDir.existsSync()) {
    framesDir.deleteSync(recursive: true);
  }
  framesDir.createSync(recursive: true);

  final String framePattern = p.join(framesDir.path, 'f_%05d.jpg');
  final String extractCmd =
      "-y -i \"$videoPath\" -vf \"fps=$fps,scale='min(${HeavyTuningParams.FRAME_MAX_WIDTH},iw)':-2\" -q:v ${HeavyTuningParams.JPEG_QUALITY} \"$framePattern\"";

  final extractSession = await FFmpegKit.execute(extractCmd);
  final extractRc = await extractSession.getReturnCode();
  if (!ReturnCode.isSuccess(extractRc)) {
    debugLog.add('ffmpeg_extract_failed rc=$extractRc');
    return errorPayload(
        'ffmpeg_extract_failed', 'Could not extract frames from video');
  }
  debugLog.add('ffmpeg_extract_ok');

  final List<File> frameFiles = framesDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.jpg'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  debugLog.add('frames_extracted: ${frameFiles.length}');

  if (frameFiles.isEmpty) {
    return errorPayload('no_frames', 'No frames were produced');
  }

  // --------------------- Initialize the heavy pose detector ---------------------
  //
  // pose_detection 3.1.5 uses a static factory `PoseDetector.create(...)`
  // that both constructs and initializes in one async call. There is no
  // separate `detector.initialize()` step (that existed in the 1.x line).
  //
  // CRITICAL — iOS performance reality from the package docs:
  //   "iOS: XNNPACK for YOLO, Metal GPU for landmarks"
  // That mixed delegate IS the auto default. If we force `PerformanceConfig.
  // xnnpack()` we DOWNGRADE iOS — landmarks run on CPU instead of Metal GPU,
  // which on the heavy model means more memory and more time per frame, and
  // a real risk of an OOM kill on older iPhones in TestFlight.
  //
  // So the fallback order is:
  //   1. AUTO (no performanceConfig)  — optimal on iOS (Metal+XNNPACK mix),
  //                                     XNNPACK on Android, etc.
  //   2. XNNPACK explicit             — only if auto somehow fails to init.
  //   3. DISABLED (pure CPU)          — maximum compatibility, slowest.
  //   4. LITE model + DISABLED        — last ditch; if even this fails the
  //                                     package itself is broken on device.

  pd.PoseDetector? detector;
  String? perfModeUsed;
  String? detectorInitError;

  // Minimal config per Quick Start in the official docs. Note the omitted
  // parameters — detectorConf, detectorIou, maxDetections, minLandmarkScore
  // all have defaults inside the package, and the Quick Start example does
  // NOT pass them. Passing them is fine, but if any of them has a different
  // name in 3.1.5 than I assumed, that would have crashed init. Keeping it
  // minimal removes that whole class of risk.
  final List<(String, Future<pd.PoseDetector> Function())> perfAttempts = [
    (
      'auto_default',
      () => pd.PoseDetector.create(
            mode: pd.PoseMode.boxesAndLandmarks,
            landmarkModel: HeavyTuningParams.LANDMARK_MODEL,
            // v2: explicitly limit detection count to avoid running Heavy
            // BlazePose multiple times per frame on YOLO false positives.
            // The user has verified this is a single-person workflow.
            maxDetections: HeavyTuningParams.DEFAULT_MAX_DETECTIONS,
            detectorConf: HeavyTuningParams.DEFAULT_DETECTOR_CONF,
          ),
    ),
    (
      'xnnpack_explicit',
      () => pd.PoseDetector.create(
            mode: pd.PoseMode.boxesAndLandmarks,
            landmarkModel: HeavyTuningParams.LANDMARK_MODEL,
            performanceConfig: const pd.PerformanceConfig.xnnpack(),
            maxDetections: HeavyTuningParams.DEFAULT_MAX_DETECTIONS,
            detectorConf: HeavyTuningParams.DEFAULT_DETECTOR_CONF,
          ),
    ),
    (
      'disabled_cpu_only',
      () => pd.PoseDetector.create(
            mode: pd.PoseMode.boxesAndLandmarks,
            landmarkModel: HeavyTuningParams.LANDMARK_MODEL,
            // PerformanceConfig.disabled is a static const, not a call.
            performanceConfig: pd.PerformanceConfig.disabled,
          ),
    ),
    (
      'lite_disabled_lastditch',
      () => pd.PoseDetector.create(
            mode: pd.PoseMode.boxesAndLandmarks,
            landmarkModel: pd.PoseLandmarkModel.lite,
            performanceConfig: pd.PerformanceConfig.disabled,
          ),
    ),
  ];

  for (final (label, builder) in perfAttempts) {
    try {
      detector = await builder();
      perfModeUsed = label;
      debugLog.add('detector_init_ok with $label');
      break;
    } catch (e, st) {
      debugLog.add('detector_init_fail with $label: $e');
      debugLog.add(
          '  stack head: ${st.toString().split('\n').take(3).join(' | ')}');
      detectorInitError = '$e';
      // try next config
    }
  }

  if (detector == null) {
    return errorPayloadWithDebug(
        'detector_init_all_failed',
        'Every PoseDetector.create attempt threw. Last error: $detectorInitError',
        debugLog);
  }

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
  // Per-frame bbox snapshot, for telemetry and downstream sanity checks.
  // Null on rejected frames.
  final List<_HvBbox?> allBboxes = [];
  // Per-frame "lifter touched a frame edge" flag — derived from bbox.
  final List<bool> allEdgeFlags = [];

  // The bbox of the last accepted frame's lifter — used to track the
  // same person across frames via IoU.
  _HvBbox? lastAcceptedBbox;
  // The mid-hip of the last accepted frame — used for the hip-jump
  // filter inherited from the ML Kit pipeline.
  List<double>? lastGoodMidHipNorm;
  int frameIdx = 0;
  int consecutiveJumpRejections = 0;

  int framesDetectedOk = 0;
  int framesNoPose = 0;
  int framesDetectThrew = 0;
  int framesRejected = 0;

  // ============================================================
  // v3 PERFORMANCE INSTRUMENTATION
  // ============================================================
  // Accumulators that measure where time is actually spent during the
  // detection loop. Reporting cumulative milliseconds across the run
  // gives us a stable signal — single-frame measurements are too noisy
  // to be useful on iOS where the OS may swap thread priorities.
  //
  // We measure four distinct phases per frame:
  //
  //   1. LOAD — File.readAsBytes(). I/O bound, should be tiny (<5ms/frame
  //      for a few hundred KB JPEG). If this is large, the disk or the
  //      FFmpeg output path is the bottleneck, NOT the model.
  //
  //   2. DETECT — detector.detect(imgBytes). This is the inference call.
  //      Includes JPEG decode (native), YOLOv8n forward pass (XNNPACK CPU),
  //      and BlazePose Heavy forward pass (Metal GPU). This is what
  //      "model speed" actually means.
  //
  //   3. PARSE — converting poses[0] into our 33-element normalized
  //      landmark array. Should be ~1ms/frame. If it's large, we have
  //      an O(n²) bug somewhere.
  //
  //   4. POST — everything else in the frame loop after parse: visibility
  //      check, bbox geometry, jump rejection, frame state updates. Should
  //      also be tiny.
  //
  // We report cumulative ms + frames-counted at the end, plus per-frame
  // averages. Calling DateTime.now() ~150 times per second across these
  // measurements adds ~0.1ms overhead per frame, which is negligible.
  int loadMsTotal = 0;
  int detectMsTotal = 0;
  int parseMsTotal = 0;
  int postMsTotal = 0;
  int timedFrames = 0;
  // Also keep min/max for detect, since that's the most variable phase
  // and a high max suggests warmup-cost or memory-pressure stalls.
  int detectMsMin = 1 << 30;
  int detectMsMax = 0;
  final Stopwatch perfWatch = Stopwatch();
  // ============================================================

  try {
    for (final frameFile in frameFiles) {
      frameIdx += 1;
      final double tSec = (frameIdx - 1) / fps;
      allFrameTimes.add(tSec);

      // ---- PHASE 1: LOAD ----
      perfWatch.reset();
      perfWatch.start();
      final Uint8List imgBytes;
      try {
        imgBytes = await frameFile.readAsBytes();
      } catch (e) {
        if (frameIdx == 1) debugLog.add('frame_read_throw: $e');
        allRawLandmarks.add(const []);
        allBboxes.add(null);
        allEdgeFlags.add(false);
        frameRejected.add(true);
        continue;
      }
      perfWatch.stop();
      final int loadMs = perfWatch.elapsedMilliseconds;

      // ---- PHASE 2: DETECT ----
      perfWatch.reset();
      perfWatch.start();
      List<pd.Pose> poses = const [];
      try {
        poses = await detector.detect(imgBytes);
      } on FormatException catch (e) {
        // 3.0+ throws FormatException on undecodable bytes. FFmpeg can
        // produce a partial/truncated last frame; this catches it.
        perfWatch.stop();
        detectMsTotal += perfWatch.elapsedMilliseconds;
        framesDetectThrew += 1;
        if (framesDetectThrew == 1) {
          debugLog.add('detect_format_exception on frame $frameIdx: $e');
        }
        allRawLandmarks.add(const []);
        allBboxes.add(null);
        allEdgeFlags.add(false);
        frameRejected.add(true);
        continue;
      } catch (e) {
        perfWatch.stop();
        detectMsTotal += perfWatch.elapsedMilliseconds;
        framesDetectThrew += 1;
        // Log the first non-format error in detail — that's the one most
        // likely to be a native crash bubbled up to Dart, and we want to
        // see its type and message.
        if (framesDetectThrew == 1) {
          debugLog
              .add('detect_threw on frame $frameIdx: ${e.runtimeType} :: $e');
        }
        allRawLandmarks.add(const []);
        allBboxes.add(null);
        allEdgeFlags.add(false);
        frameRejected.add(true);
        continue;
      }

      if (poses.isEmpty) {
        // Stop the detect-phase timer even on no-pose so we account for
        // the full inference cost regardless of outcome.
        perfWatch.stop();
        detectMsTotal += perfWatch.elapsedMilliseconds;
        framesNoPose += 1;
        allRawLandmarks.add(const []);
        allBboxes.add(null);
        allEdgeFlags.add(false);
        frameRejected.add(true);
        continue;
      }

      perfWatch.stop();
      final int detectMs = perfWatch.elapsedMilliseconds;
      detectMsTotal += detectMs;
      if (detectMs < detectMsMin) detectMsMin = detectMs;
      if (detectMs > detectMsMax) detectMsMax = detectMs;

      framesDetectedOk += 1;

      // ---- PHASE 3: PARSE start (will be stopped after we build rawNormLandmarks) ----
      perfWatch.reset();
      perfWatch.start();

      // v3: detailed per-frame timing. Logged for the first 3 frames and
      // every 30th frame after. Format:
      //   frame=N poses=P load=Lms detect=Dms (so far)
      // We don't log parse/post yet because they haven't run — that's
      // fine, they're consistently tiny and reported in the final
      // summary.
      if (frameIdx <= 3 || frameIdx % 30 == 0) {
        debugLog.add('frame=$frameIdx poses=${poses.length} '
            'load=${loadMs}ms detect=${detectMs}ms');
      }

      // 3.1.5: every returned Pose carries the source image dimensions the
      // detector worked with. We cache those off the first successful frame
      // since FFmpeg guarantees all extracted frames share the same dims.
      // No more JPEG-header probe.
      final int imgW = poses.first.imageWidth;
      final int imgH = poses.first.imageHeight;
      if (cachedW <= 0 || cachedH <= 0) {
        cachedW = imgW;
        cachedH = imgH;
        debugLog.add('first_pose_dims: ${imgW}x$imgH (poses=${poses.length})');
        // Sanity check: imageWidth/imageHeight should be positive. If
        // they aren't, the package contract changed and downstream
        // normalization will divide by zero.
        if (imgW <= 0 || imgH <= 0) {
          debugLog.add('FATAL: pose.imageWidth/Height is non-positive');
          return errorPayload('bad_pose_dims',
              'Pose returned imageWidth=$imgW imageHeight=$imgH — package contract broken');
        }
      }
      final double fw = imgW.toDouble();
      final double fh = imgH.toDouble();

      // Pick the lifter (tracking via IoU, fallback to biggest bbox).
      final pd.Pose? mainPose =
          _hvPickMainPose(poses, lastAcceptedBbox, imgW, imgH);
      if (mainPose == null || !mainPose.hasLandmarks) {
        allRawLandmarks.add(const []);
        allBboxes.add(null);
        allEdgeFlags.add(false);
        frameRejected.add(true);
        // Close out parse timer (we were mid-parse) and account this frame.
        perfWatch.stop();
        parseMsTotal += perfWatch.elapsedMilliseconds;
        loadMsTotal += loadMs;
        timedFrames += 1;
        continue;
      }

      final _HvBbox normBbox = _hvNormalizeBbox(mainPose, imgW, imgH);
      final bool atEdge = _hvBboxAtFrameEdge(normBbox);

      // Bbox area sanity: if the lifter occupies almost nothing of the
      // frame, the landmark accuracy will be terrible — drop the frame.
      if (normBbox.area < HeavyTuningParams.BBOX_MIN_AREA_FRAC) {
        allRawLandmarks.add(const []);
        allBboxes.add(normBbox);
        allEdgeFlags.add(atEdge);
        frameRejected.add(true);
        // Close out parse timer (we were mid-parse) and account this frame.
        perfWatch.stop();
        parseMsTotal += perfWatch.elapsedMilliseconds;
        loadMsTotal += loadMs;
        timedFrames += 1;
        continue;
      }

      // Bbox center-jump sanity. Catches "tracking just swapped to a
      // different person" failures that the hip-jump filter might miss
      // (e.g., two people with similar hip y-positions standing close
      // to each other).
      if (lastAcceptedBbox != null) {
        final double cdx = normBbox.cx - lastAcceptedBbox!.cx;
        final double cdy = normBbox.cy - lastAcceptedBbox!.cy;
        final double centerJump = math.sqrt(cdx * cdx + cdy * cdy);
        if (centerJump > HeavyTuningParams.BBOX_CENTER_JUMP_FRAC &&
            consecutiveJumpRejections <
                HeavyTuningParams.JUMP_REJECT_MAX_CONSECUTIVE) {
          consecutiveJumpRejections += 1;
          allRawLandmarks.add(const []);
          allBboxes.add(normBbox);
          allEdgeFlags.add(atEdge);
          frameRejected.add(true);
          // Close out parse timer (we were mid-parse) and account this frame.
          perfWatch.stop();
          parseMsTotal += perfWatch.elapsedMilliseconds;
          loadMsTotal += loadMs;
          timedFrames += 1;
          continue;
        }
      }

      // Build the 33-landmark frame in normalized (0..1) space.
      final List<List<double>> rawNormLandmarks = [];
      double coreVisSum = 0.0;
      int coreCount = 0;
      for (int li = 0; li < _HV_LM_ORDER.length; li++) {
        final lmType = _HV_LM_ORDER[li];
        final plm = mainPose.getLandmark(lmType);
        if (plm == null) {
          rawNormLandmarks.add([0.0, 0.0, 0.0]);
        } else {
          final double vis = plm.visibility.clamp(0.0, 1.0).toDouble();
          rawNormLandmarks.add([
            (plm.x / fw).clamp(0.0, 1.0).toDouble(),
            (plm.y / fh).clamp(0.0, 1.0).toDouble(),
            vis,
          ]);
          // Core landmarks for confidence averaging — shoulders, hips,
          // knees, ankles. Same set as the ML Kit version.
          if (li == IDX_L_SHOULDER ||
              li == IDX_R_SHOULDER ||
              li == IDX_L_HIP ||
              li == IDX_R_HIP ||
              li == IDX_L_KNEE ||
              li == IDX_R_KNEE ||
              li == IDX_L_ANKLE ||
              li == IDX_R_ANKLE) {
            coreVisSum += vis;
            coreCount += 1;
          }
        }
      }

      // Bbox-anchored sanity: zero visibility on any landmark that
      // strayed meaningfully outside the bbox. This is BEFORE the
      // visibility filter pass, so the downstream hysteresis sees a
      // clean signal.
      _hvZeroLandmarksOutsideBbox(rawNormLandmarks, normBbox);

      // ---- PHASE 3 end: PARSE ----
      perfWatch.stop();
      parseMsTotal += perfWatch.elapsedMilliseconds;

      // ---- PHASE 4: POST ----
      perfWatch.reset();
      perfWatch.start();

      final double coreVisMean =
          (coreCount > 0) ? (coreVisSum / coreCount) : 0.0;

      final List<double> rawMidHip = [
        (rawNormLandmarks[IDX_R_HIP][0] + rawNormLandmarks[IDX_L_HIP][0]) / 2.0,
        (rawNormLandmarks[IDX_R_HIP][1] + rawNormLandmarks[IDX_L_HIP][1]) / 2.0,
      ];

      bool rejectFrame = false;
      bool wasJumpRejection = false;
      if (coreVisMean < HeavyTuningParams.LOW_CORE_VIS_THRESHOLD) {
        rejectFrame = true;
      }
      if (!rejectFrame && lastGoodMidHipNorm != null) {
        final double jumpDist = euclid(rawMidHip, lastGoodMidHipNorm!);
        final double jumpFrac = jumpDist / 1.4142135;
        if (jumpFrac > HeavyTuningParams.JUMP_REJECT_HIP_FRAC) {
          if (consecutiveJumpRejections >=
              HeavyTuningParams.JUMP_REJECT_MAX_CONSECUTIVE) {
            // Force-accept: declare the cascade over. Same logic as ML Kit version.
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
        allRawLandmarks.add(const []);
        allBboxes.add(normBbox);
        allEdgeFlags.add(atEdge);
        frameRejected.add(true);
        // Stop post timer and accumulate this frame's timings.
        perfWatch.stop();
        postMsTotal += perfWatch.elapsedMilliseconds;
        loadMsTotal += loadMs;
        timedFrames += 1;
        continue;
      }

      // Frame accepted.
      consecutiveJumpRejections = 0;
      lastGoodMidHipNorm = rawMidHip;
      lastAcceptedBbox = normBbox;
      allRawLandmarks.add(rawNormLandmarks);
      allBboxes.add(normBbox);
      allEdgeFlags.add(atEdge);
      frameRejected.add(false);

      // ---- PHASE 4 end: POST ----
      perfWatch.stop();
      postMsTotal += perfWatch.elapsedMilliseconds;
      loadMsTotal += loadMs;
      timedFrames += 1;
    }
    debugLog.add(
        'detection_loop_done: ok=$framesDetectedOk no_pose=$framesNoPose throw=$framesDetectThrew rejected=$framesRejected total=$frameIdx');

    // ============================================================
    // v3: cumulative timing report — this is the data we actually want.
    //
    // Per-frame averages tell us the dominant cost. Typical signature
    // for "everything healthy":
    //   load=2ms detect=80-150ms parse=1ms post=1ms
    //
    // Anything else is a clue:
    //   load=>10ms        → disk/I/O issue, FFmpeg JPEG quality maybe wrong
    //   detect=>250ms     → model or framework bottleneck, NOT us
    //   parse=>5ms        → landmark structure walking is O(n²) somewhere
    //   post=>10ms        → bbox/visibility logic is slow
    //
    // detect_min/max tell us if there's a warmup or stall:
    //   small variance → steady state, fine
    //   detect_max >> detect_avg → memory pressure or thermal throttling
    // ============================================================
    if (timedFrames > 0) {
      final int avgLoad = (loadMsTotal / timedFrames).round();
      final int avgDetect = (detectMsTotal / timedFrames).round();
      final int avgParse = (parseMsTotal / timedFrames).round();
      final int avgPost = (postMsTotal / timedFrames).round();
      final int avgTotal = avgLoad + avgDetect + avgParse + avgPost;
      debugLog.add('perf_avg_ms (per frame): '
          'load=$avgLoad detect=$avgDetect parse=$avgParse post=$avgPost '
          'total=$avgTotal');
      debugLog.add('perf_total_ms (whole run): '
          'load=$loadMsTotal detect=$detectMsTotal parse=$parseMsTotal '
          'post=$postMsTotal frames=$timedFrames');
      debugLog.add('perf_detect_range_ms: '
          'min=$detectMsMin max=$detectMsMax avg=$avgDetect');
    }
    // ============================================================
  } catch (e, st) {
    debugLog.add('detection_loop_crashed: $e');
    debugLog
        .add('  stack head: ${st.toString().split('\n').take(5).join(' | ')}');
    // Don't return here — we have whatever data we collected so far;
    // let the smoother and rep state machine run on whatever we got.
  } finally {
    try {
      await detector.dispose();
      debugLog.add('detector_disposed_ok');
    } catch (e) {
      debugLog.add('detector_dispose_threw: $e');
    }
    try {
      framesDir.deleteSync(recursive: true);
    } catch (_) {}
  }

  // If we got literally nothing from the detector, bail out early with a
  // useful error code instead of running the rest of the pipeline on
  // empty data.
  if (framesDetectedOk == 0) {
    return errorPayload(
        'no_detections',
        'Detector ran but produced 0 successful frames. '
            'detect_threw=$framesDetectThrew, no_pose=$framesNoPose, total_frames=$frameIdx. '
            'See _debug for more.');
  }

  final List<List<List<double>>> smoothed =
      _hvSavitzkyGolaySmoothAll(allRawLandmarks);
  final List<List<List<double>>> allSmoothedLandmarks =
      _hvApplyVisibilityFilters(smoothed);

  // ============================================================
  // Rep detection state machine — IDENTICAL to ML Kit version.
  // ============================================================

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

  void addEmptyFrame(double tSec, _HvBbox? bb, bool edge) {
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
      'bbox': bb == null
          ? null
          : {
              'l': bb.left,
              't': bb.top,
              'r': bb.right,
              'b': bb.bottom,
              'score': bb.score,
            },
      'bbox_at_edge': edge,
    });
    repJustFinished = null;
    if (rtFbHold > 0) rtFbHold -= 1;
  }

  final int totalFrames = allSmoothedLandmarks.length;

  final double fw = cachedW > 0 ? cachedW.toDouble() : 1080.0;
  final double fh = cachedH > 0 ? cachedH.toDouble() : 1920.0;

  for (int i = 0; i < totalFrames; i++) {
    final int frameIdx1Based = i + 1;
    final double tSec = allFrameTimes[i];
    final normLandmarks = allSmoothedLandmarks[i];
    final _HvBbox? curBbox = allBboxes[i];
    final bool curEdge = allEdgeFlags[i];

    if (frameRejected[i] || normLandmarks.isEmpty) {
      jumpRecoverCountdown = HeavyTuningParams.JUMP_RECOVER_FRAMES;

      if (stage == 'down') {
        repRejectedFrameCount += 1;
        if (repRejectedFrameCount >
            HeavyTuningParams.MAX_REJECTED_FRAMES_IN_REP) {
          abortRep();
        }
      }

      addEmptyFrame(tSec, curBbox, curEdge);
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
    hipVelEma = HeavyTuningParams.EMA_ALPHA * hipVel +
        (1 - HeavyTuningParams.EMA_ALPHA) * hipVelEma;
    ankleVelEma = HeavyTuningParams.EMA_ALPHA * anVel +
        (1 - HeavyTuningParams.EMA_ALPHA) * ankleVelEma;
    prevHip = hipPx;
    prevLa = laPx;
    prevRa = raPx;

    final bool movementBlock =
        (hipVelEma > HeavyTuningParams.HIP_VEL_THRESH_PCT) ||
            (ankleVelEma > HeavyTuningParams.ANKLE_VEL_THRESH_PCT);
    if (movementBlock) {
      movementFreeStreak = 0;
    } else {
      movementFreeStreak = math.min(
          HeavyTuningParams.MOVEMENT_CLEAR_FRAMES, movementFreeStreak + 1);
    }

    final double kneeAngle = calcAngle(hip, knee, ankle);
    final double backAngle = angleBetweenVectors(
      [midShoulder[0] - midHip[0], midShoulder[1] - midHip[1]],
      [0.0, -1.0],
    );

    final bool softStartOk = (hipVelEma <
            HeavyTuningParams.HIP_VEL_THRESH_PCT *
                HeavyTuningParams.SOFT_START_MARGIN) &&
        (ankleVelEma <
            HeavyTuningParams.ANKLE_VEL_THRESH_PCT *
                HeavyTuningParams.SOFT_START_MARGIN);
    final bool kneeGoingDown = (stage != 'down');

    final bool inRecovery = jumpRecoverCountdown > 0;

    if (kneeAngle < HeavyTuningParams.REP_START_KNEE_ANGLE &&
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

      if (currentDepth < HeavyTuningParams.TOP_ZONE_DEPTH_MAX) {
        repMaxBackAngleTop = math.max(repMaxBackAngleTop, backAngle);
      } else if (currentDepth >= HeavyTuningParams.BOTTOM_ZONE_DEPTH_MIN) {
        repMaxBackAngleBottom = math.max(repMaxBackAngleBottom, backAngle);
      }

      // Back-angle real-time feedback — only fires when bbox is NOT at
      // a frame edge, because torso geometry isn't trustworthy when
      // shoulders or hips might be cropped.
      final bool backFbAllowed = !curEdge;

      if (backFbAllowed &&
          currentDepth < HeavyTuningParams.TOP_ZONE_DEPTH_MAX &&
          backAngle > HeavyTuningParams.TOP_BACK_MAX_DEG) {
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
      } else if (backFbAllowed &&
          currentDepth >= HeavyTuningParams.BOTTOM_ZONE_DEPTH_MIN &&
          backAngle > HeavyTuningParams.BOTTOM_BACK_MAX_DEG) {
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
        repMaxHorizontalMovement > HeavyTuningParams.MAX_HORIZONTAL_ALLOWED;
    final bool hasExcessiveAsymmetry =
        repMaxAsymmetry > HeavyTuningParams.MAX_ASYMMETRY_ALLOWED;
    final bool hasMinimalDepth =
        repMaxDepth >= HeavyTuningParams.MIN_DEPTH_FOR_REP;
    final bool isPickupMotion = hasExcessiveHorizontal && hasExcessiveAsymmetry;
    final bool isValidRep = !isPickupMotion && hasMinimalDepth;

    final bool repFinishedPosture =
        (kneeAngle > HeavyTuningParams.STAND_KNEE_ANGLE) ||
            (kneeAngle >
                    (HeavyTuningParams.STAND_KNEE_ANGLE -
                        HeavyTuningParams.REP_FINISH_KNEE_MARGIN) &&
                currentDepth <= HeavyTuningParams.REP_FINISH_DEPTH_MAX);
    final bool repFinishGateOk = (movementFreeStreak >=
            HeavyTuningParams.MOVEMENT_CLEAR_FRAMES) ||
        (currentDepth <= HeavyTuningParams.REP_FINISH_ALLOW_MOVING_DEPTH_MAX);

    if (repFinishedPosture && stage == 'down' && repFinishGateOk) {
      final int repDuration =
          (repStartFrame != null) ? (frameIdx1Based - repStartFrame!) : 0;
      final bool durationOk =
          repDuration >= HeavyTuningParams.MIN_REP_DURATION_FRAMES;

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
          'bbox': curBbox == null
              ? null
              : {
                  'l': curBbox.left,
                  't': curBbox.top,
                  'r': curBbox.right,
                  'b': curBbox.bottom,
                  'score': curBbox.score,
                },
          'bbox_at_edge': curEdge,
        });
        continue;
      }

      final List<String> feedbacks = [];
      double penalty = 0.0;
      final double depthPct = repMaxDepth;

      if (depthPct < HeavyTuningParams.DEPTH_FAIR_THRESHOLD) {
        feedbacks.add('Try to squat deeper');
        penalty += HeavyTuningParams.PENALTY_DEPTH_SEVERE;
      } else if (depthPct < HeavyTuningParams.DEPTH_ALMOST_THRESHOLD) {
        feedbacks.add('Almost there — go a bit lower');
        penalty += HeavyTuningParams.PENALTY_DEPTH_MODERATE;
      } else if (depthPct < HeavyTuningParams.DEPTH_GOOD_THRESHOLD) {
        feedbacks.add('Looking good — just a bit more depth');
        penalty += HeavyTuningParams.PENALTY_DEPTH_MINOR;
      }

      if (repHadBackFeedback) {
        feedbacks.add('Try to keep your back a bit straighter');
        penalty += HeavyTuningParams.PENALTY_BACK;
      }

      double score;
      if (feedbacks.isEmpty) {
        score = HeavyTuningParams.PERFECT_SCORE;
      } else {
        score = math.max(HeavyTuningParams.MIN_REP_SCORE,
            HeavyTuningParams.PERFECT_SCORE - penalty);
        score = (score * 2).round() / 2.0;
        score = math.min(score, HeavyTuningParams.MAX_IMPERFECT_SCORE);
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
          HeavyTuningParams.MIN_FRAMES_BETWEEN_REPS) {
        counter += 1;
        lastRepFrame = frameIdx1Based;
        if (score >= HeavyTuningParams.MAX_IMPERFECT_SCORE) {
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
      'bbox': curBbox == null
          ? null
          : {
              'l': curBbox.left,
              't': curBbox.top,
              'r': curBbox.right,
              'b': curBbox.bottom,
              'score': curBbox.score,
            },
      'bbox_at_edge': curEdge,
    });
    repJustFinished = null;
  }

  // ============================================================
  // UNRACK / WARM-UP FIRST-REP REJECTION — identical to ML Kit version.
  // ============================================================
  if (repReports.length >= HeavyTuningParams.UNRACK_MIN_REPS_FOR_CHECK) {
    final double firstRepDepth =
        (repReports[0]['depth_pct'] as num?)?.toDouble() ?? 0.0;

    final int peerEnd = math.min(
        repReports.length, 1 + HeavyTuningParams.UNRACK_PEER_REPS_TO_CONSIDER);
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
          peerMedian * HeavyTuningParams.UNRACK_FIRST_REP_DEPTH_PEER_FRACTION;
      final bool failedRatio = firstRepDepth < threshold;
      final bool failedAbsolute = firstRepDepth <
              HeavyTuningParams.UNRACK_FIRST_REP_ABSOLUTE_MAX &&
          peerMedian >= HeavyTuningParams.UNRACK_ABSOLUTE_CHECK_MIN_PEER_DEPTH;
      if (failedRatio || failedAbsolute) {
        final Map<String, dynamic> removed = repReports.removeAt(0);
        counter -= 1;

        if (allScores.isNotEmpty) allScores.removeAt(0);

        final double removedScore =
            (removed['score'] as num?)?.toDouble() ?? 0.0;
        if (removedScore >= HeavyTuningParams.MAX_IMPERFECT_SCORE) {
          if (goodReps > 0) goodReps -= 1;
        } else {
          if (badReps > 0) badReps -= 1;
        }

        for (int r = 0; r < repReports.length; r++) {
          repReports[r]['rep_index'] = r + 1;
        }

        final int unrackEndFrame = (removed['end_frame'] as int?) ?? 0;
        for (int j = 0; j < frameTelemetry.length; j++) {
          final int frameNumber = j + 1;
          final int curReps = (frameTelemetry[j]['reps'] as num?)?.toInt() ?? 0;

          if (frameNumber >= unrackEndFrame && curReps > 0) {
            frameTelemetry[j]['reps'] = curReps - 1;
          }

          if (frameNumber == unrackEndFrame) {
            frameTelemetry[j]['rep_just_finished'] = null;
          }
        }

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

  if (HeavyTuningParams.TELEMETRY_LEAD_SEC > 0.0) {
    for (final frame in frameTelemetry) {
      final double tOrig = (frame['t'] as num).toDouble();
      frame['t'] = math.max(0.0, tOrig - HeavyTuningParams.TELEMETRY_LEAD_SEC);
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
    techniqueScore =
        math.min(techniqueScore, HeavyTuningParams.MAX_IMPERFECT_SCORE);
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

  debugLog
      .add('finalize: counter=$counter goodReps=$goodReps badReps=$badReps');

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
    // Tag the result so the UI / analytics can tell which engine produced it
    // when you A/B test the two actions side-by-side.
    '_engine': 'heavy',
    '_landmark_model': HeavyTuningParams.LANDMARK_MODEL.toString(),
    '_perf_mode': perfModeUsed,
    '_debug': debugLog,
    '_detection_stats': {
      'frames_ok': framesDetectedOk,
      'frames_no_pose': framesNoPose,
      'frames_detect_threw': framesDetectThrew,
      'frames_total': frameIdx,
    },
  };
}
