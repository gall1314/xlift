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

/// Analyze a deadlift video locally using ML Kit Pose Detection.
///
/// [variant]: 'conventional' (default, null) | 'trap' | 'sumo'.
/// Detection is self-calibrated per video so all variants count the same.
/// The only per-variant tweak is the per-rep ROM scoring: sumo has a short
/// hip travel and, from the side, a foreshortened knee bend, so its
/// KNEE_DROP_* / HIP_DESC_* thresholds are scaled by 0.7 — otherwise a
/// perfect sumo rep caps at 9 and never shows as GOOD REP. Trap bar needs
/// nothing (more knee bend passes everything easily).
Future<dynamic> analyzeDeadliftVideoAction(
  FFUploadedFile videoFile,
  double? targetFps,
  String? variant,
) async {
  // [DIAG] Diagnostic data attached to result['debug'].
  final List<Map<String, dynamic>> diagCandidates = [];
  Map<String, dynamic>? diagCalib;
  Map<String, dynamic>? diagWalkout;
  Map<String, dynamic>? diagOutlier;
  Map<String, dynamic>? diagFinal;

  // ================ Variant ================
  final String variantName = (variant ?? 'conventional').trim().toLowerCase();
  final double romScale = variantName == 'sumo' ? 0.7 : 1.0;

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
  const double MIN_REP_DURATION_SEC = 0.7;

  const double MAX_HIPX_RANGE_WALK = 0.15;
  const double LATERAL_GATE_PEAK_TH = 0.80;
  const double LATERAL_GATE_RATIO_TH = 0.70;

  // [SCALE-GATE] Body scale = max(shoulder x-width, hip x-width),
  // normalized by frame width. In a deadlift filmed from the front
  // this stays roughly constant; walking TOWARD or AWAY from the
  // camera changes it a lot. Frames whose scale deviates more than
  // +/-30% from the video median are marked invalid BEFORE
  // calibration and rep detection, so a walk-in/walk-out can neither
  // inflate hipRange (which used to tighten every downstream gate)
  // nor become a rep candidate. Skipped when the median scale is tiny
  // (side-view videos, where x-widths are not meaningful).
  const double SCALE_GATE_MIN_RATIO = 0.70;
  const double SCALE_GATE_MAX_RATIO = 1.30;
  const double SCALE_GATE_MIN_MEDIAN = 0.05;
  const int SCALE_GATE_MIN_FRAMES = 10;

  // [KNEE-BOTTOM] A real deadlift bottom has the knees at least this
  // bent. Was hipRange-dependent (120/125/140) but hipRange is a poor
  // proxy for that (and was easily inflated) — a hip-dominant lifter
  // with less knee bend got rejected. Now a single loose constant.
  const double KNEE_BOTTOM_MAX_ANGLE = 140.0;

  // [LAST-REP WALK-OUT v2] Runs on the LAST committed rep only, and only
  // when there are >= 2 committed reps (never wipes a one-rep video).
  //
  // The pattern it targets: the bar is already on the floor, the lifter
  // stands up WITHOUT it and walks away. That "rise" looks like a rep.
  // What separates it from a real last rep: after a real last rep the
  // lifter LOWERS the bar (a descent -> EMA climbs again), and only then
  // walks. After the fake rise there is NO descent - just walking.
  //
  // So: in a window after the last rep's lockout, if there is no descent
  // (no valid frame with EMA >= WALKOUT_DESCENT_EMA) AND there is walking
  // (hipX range over valid frames >= WALKOUT_HIPX_RANGE, or >=
  // WALKOUT_GATED_FRACTION of the window's frames were scale-gated /
  // pose-less, i.e. the person moved toward the camera or out of frame)
  // -> the last rep is removed. A video that ends right after the rep has
  // no window -> nothing happens.
  const double WALKOUT_WINDOW_SEC = 2.5;
  const double WALKOUT_DESCENT_EMA = 0.45;
  const double WALKOUT_HIPX_RANGE = 0.12;
  const double WALKOUT_GATED_FRACTION = 0.35;
  const int WALKOUT_MIN_REPS = 2;
  const int WALKOUT_MIN_WINDOW_FRAMES = 4;

  const int OUTLIER_MIN_REPS = 3;
  const double OUTLIER_ABS_GAP = 0.20;

  const double DEPTH_EXCELLENT_PEAK = 0.85;
  const double DEPTH_GOOD_PEAK = 0.70;
  const double DEPTH_FAIR_PEAK = 0.55;
  // ROM thresholds scaled per variant (sumo: 0.7).
  final double KNEE_DROP_EXCELLENT = 60.0 * romScale;
  final double KNEE_DROP_GOOD = 40.0 * romScale;
  final double KNEE_DROP_FAIR = 25.0 * romScale;
  final double HIP_DESC_EXCELLENT = 0.10 * romScale;
  final double HIP_DESC_GOOD = 0.05 * romScale;
  final double HIP_DESC_FAIR = 0.02 * romScale;

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

      // [SCALE-GATE] body scale for this frame (x-widths, frame-normalized)
      final double shoulderW = ((ls.x - rs.x) / fw).abs();
      final double hipW = ((lh.x - rh.x) / fw).abs();
      final double bodyScale = math.max(shoulderW, hipW);

      double? wristHipDy;
      double? wristY;
      if (lw != null && rw != null) {
        wristY = ((lw.y / fh) + (rw.y / fh)) / 2.0;
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
        scale: bodyScale,
        landmarks: normLandmarks,
      ));
    }
  } finally {
    await poseDetector.close();
    try {
      framesDir.deleteSync(recursive: true);
    } catch (_) {}
  }

  // ================ 3b) Scale gate ================
  // Invalidate frames whose body scale is far from the video median
  // (walking toward/away from the camera). Runs BEFORE calibration so
  // those frames influence neither hipRange/kneeRange nor rep detection.
  int scaleGatedFrames = 0;
  double? scaleMedian;
  {
    final List<double> scales = raw
        .where((r) => r.valid && r.scale != null)
        .map((r) => r.scale!)
        .toList();
    if (scales.length >= SCALE_GATE_MIN_FRAMES) {
      final double med = percentile(scales, 50);
      scaleMedian = med;
      if (med >= SCALE_GATE_MIN_MEDIAN) {
        for (final r in raw) {
          if (!r.valid || r.scale == null) continue;
          final double ratio = r.scale! / med;
          if (ratio < SCALE_GATE_MIN_RATIO || ratio > SCALE_GATE_MAX_RATIO) {
            r.valid = false;
            r.scaleGated = true;
            scaleGatedFrames++;
          }
        }
      }
    }
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
      'deadlift_variant': variantName,
      'video_path': fileUri,
      'analyzed_fps': fps,
      'frame_count': frameIdx,
      '_source_video_uri': fileUri,
      '_frame_telemetry': tel,
      'debug': {
        'aborted_at': 'calibration_insufficient_data',
        'scaleGatedFrames': scaleGatedFrames,
        'scaleMedian': scaleMedian != null ? rd(scaleMedian, 4) : null,
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
    'scaleGatedFrames': scaleGatedFrames,
    'scaleMedian': scaleMedian != null ? rd(scaleMedian, 4) : null,
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
        final bool kneeBottomOk =
            repMinKnee == null || repMinKnee! <= KNEE_BOTTOM_MAX_ANGLE;

        final double lateralVertRatio =
            repHipYRange > 0.001 ? hipxRng / repHipYRange : 0.0;
        final bool lateralOk = peakInRep >= LATERAL_GATE_PEAK_TH ||
            lateralVertRatio <= LATERAL_GATE_RATIO_TH;

        final bool committed = !videoIsStatic &&
            !videoNotADeadlift &&
            holdOk &&
            durOk &&
            (hipOk || kneeOk) &&
            walkOk &&
            peakOk &&
            hipMotionOk &&
            kneeBottomOk &&
            lateralOk;

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
          'minKnee': repMinKnee != null ? rd(repMinKnee!, 1) : null,
          'repHipYRange': rd(repHipYRange, 4),
          'hipxRng': rd(hipxRng, 4),
          'latVRatio': rd(lateralVertRatio, 3),
          'repMaxWristDy': repMaxWristDy != null ? rd(repMaxWristDy!, 4) : null,
          'committed': committed,
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
    final bool kneeBottomOk =
        repMinKnee == null || repMinKnee! <= KNEE_BOTTOM_MAX_ANGLE;
    final double lateralVertRatio =
        endRepHipYRange > 0.001 ? hipxRng / endRepHipYRange : 0.0;
    final bool lateralOk = peakInRep >= LATERAL_GATE_PEAK_TH ||
        lateralVertRatio <= LATERAL_GATE_RATIO_TH;

    final bool committed = !videoIsStatic &&
        !videoNotADeadlift &&
        holdOk &&
        durOk &&
        (hipOk || kneeOk) &&
        walkOk &&
        peakOk &&
        hipMotionOk &&
        kneeBottomOk &&
        lateralOk;

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
      'minKnee': repMinKnee != null ? rd(repMinKnee!, 1) : null,
      'repHipYRange': rd(endRepHipYRange, 4),
      'hipxRng': rd(hipxRng, 4),
      'latVRatio': rd(lateralVertRatio, 3),
      'repMaxWristDy': repMaxWristDy != null ? rd(repMaxWristDy!, 4) : null,
      'committed': committed,
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
  // True min EMA per rep (before visual delay).
  final List<double> repLockoutMinEma = [];
  // Raw (pre-visual-delay) lockout frame per rep - the walk-out check
  // needs the true lockout, not the display-shifted one.
  final List<int> repLockoutRawI = [];

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
    repLockoutRawI.add(lockoutFrameI);

    const double LOCKOUT_VISUAL_DELAY_SEC = 0.20;
    final int lockoutVisualDelayFrames =
        math.max(1, (LOCKOUT_VISUAL_DELAY_SEC * fps).round());
    int adjustedLockoutI = lockoutFrameI + lockoutVisualDelayFrames;
    if (adjustedLockoutI >= searchEnd) adjustedLockoutI = searchEnd - 1;
    if (adjustedLockoutI < lockoutFrameI) adjustedLockoutI = lockoutFrameI;
    lockoutFrameI = adjustedLockoutI;

    repLockoutFrameI.add(lockoutFrameI);
  }

  // ================ 6) LAST-REP WALK-OUT CHECK v2 ================
  // See the WALKOUT_* constants for the rule. Only the last committed rep,
  // only with >= WALKOUT_MIN_REPS reps, and it needs a real window after
  // the lockout to say anything.
  if (committedReps.length >= WALKOUT_MIN_REPS) {
    final int lastI = committedReps.length - 1;
    final int lockRaw = repLockoutRawI[lastI];
    final int winFrames = math.max(1, (WALKOUT_WINDOW_SEC * fps).round());
    final int winStart = lockRaw + 1;
    final int winEnd = math.min(raw.length, lockRaw + 1 + winFrames);
    final int winLen = winEnd - winStart;

    bool sawDescent = false;
    int gated = 0; // scale-gated or pose-less frames
    int validN = 0;
    double? xMin, xMax;

    for (int j = winStart; j < winEnd; j++) {
      final rj = raw[j];
      if (!rj.valid) {
        if (rj.scaleGated || rj.hipY == null) gated++;
        continue;
      }
      validN++;
      if (j < emaByFrame.length && emaByFrame[j] >= WALKOUT_DESCENT_EMA) {
        sawDescent = true;
      }
      if (rj.hipX != null) {
        xMin = (xMin == null) ? rj.hipX : math.min(xMin!, rj.hipX!);
        xMax = (xMax == null) ? rj.hipX : math.max(xMax!, rj.hipX!);
      }
    }

    final double hipxRange =
        (xMin != null && xMax != null) ? (xMax! - xMin!) : 0.0;
    final double gatedFrac = winLen > 0 ? gated / winLen : 0.0;
    final bool walking =
        hipxRange >= WALKOUT_HIPX_RANGE || gatedFrac >= WALKOUT_GATED_FRACTION;
    final bool enoughWindow = winLen >= WALKOUT_MIN_WINDOW_FRAMES;
    final bool removeLast = enoughWindow && !sawDescent && walking;

    diagWalkout = {
      'enabled': true,
      'lastRepLockoutRawI': lockRaw,
      'windowFrames': winLen,
      'validFrames': validN,
      'gatedFrames': gated,
      'gatedFrac': rd(gatedFrac, 3),
      'hipxRange': rd(hipxRange, 4),
      'sawDescent': sawDescent,
      'walking': walking,
      'removed': removeLast,
    };

    if (removeLast) {
      // Mark the matching candidate for the debug string, then drop the rep.
      for (int c = diagCandidates.length - 1; c >= 0; c--) {
        if (diagCandidates[c]['committed'] == true) {
          diagCandidates[c]['committed'] = false;
          diagCandidates[c]['failedGates'] = ['walkOut'];
          break;
        }
      }
      committedReps.removeLast();
      repLockoutFrameI.removeLast();
      repLockoutMinEma.removeLast();
      repLockoutRawI.removeLast();
    }
  } else {
    diagWalkout = {
      'enabled': true,
      'skipped': 'fewer than $WALKOUT_MIN_REPS reps',
    };
  }

  // ================ 6.5) v10 OUTLIER REMOVAL — DISABLED ================
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
      'good': r.score >= 10.0,
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

  // [PERFECT-ONLY] good_reps counts only perfect-10 reps.
  int goodReps = 0;
  int badReps = 0;
  for (final r in committedReps) {
    if (r.score >= 10.0) {
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
  dbgStr.write('variant=$variantName ');
  dbgStr.write('reps=$repCount ');
  dbgStr.write('scaleGated=$scaleGatedFrames ');
  if (diagCalib != null) {
    dbgStr.write('hipRange=${diagCalib['hipRange']} ');
  }
  if (diagWalkout != null) {
    if (diagWalkout['removed'] != null) {
      dbgStr.write(
          'walkout=${diagWalkout['removed'] == true ? "REMOVED" : "kept"}'
          '(desc=${diagWalkout['sawDescent']},walk=${diagWalkout['walking']},'
          'x=${diagWalkout['hipxRange']},gated=${diagWalkout['gatedFrac']},'
          'win=${diagWalkout['windowFrames']}) ');
    } else {
      dbgStr.write('walkout=skipped ');
    }
  }
  if (repLockoutMinEma.isNotEmpty) {
    dbgStr.write('lockoutEmas=[');
    for (int i = 0; i < repLockoutMinEma.length; i++) {
      if (i > 0) dbgStr.write(',');
      dbgStr.write(rd(repLockoutMinEma[i], 3).toString());
    }
    dbgStr.write('] ');
  }
  if (diagCandidates.isNotEmpty) {
    dbgStr.write('cands=${diagCandidates.length} ');
    final committedTimes = diagCandidates
        .where((c) => c['committed'] == true)
        .map((c) =>
            '${c['tStart']}-${c['tEnd']}s(p=${c['peakSig']},k=${c['minKnee']})')
        .toList();
    dbgStr.write('committed=[${committedTimes.join("|")}] ');
    final rejected = diagCandidates.where((c) => c['committed'] == false);
    if (rejected.isNotEmpty) {
      dbgStr.write('rejected=[');
      for (final c in rejected) {
        dbgStr.write(
            '${c['tStart']}s(k=${c['minKnee']};${(c['failedGates'] as List).join(",")})|');
      }
      dbgStr.write('] ');
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
    'deadlift_variant': variantName,
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
  bool valid; // mutable: the scale gate may invalidate a frame post-pass
  bool scaleGated = false; // set by the scale gate
  final double? visMinLm;
  final double? hipY;
  final double? hipX;
  final double? kneeAng;
  final double? wristHipDy;
  final double? shY;
  final double? wristY;
  final double? scale;
  final List<List<double>> landmarks;
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
    this.scale,
    required this.landmarks,
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
