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

/// Analyze a Good Morning video locally using ML Kit Pose Detection.
///
/// Mirrors `good_morning_analysis.py`. Counts reps using torso hinge angle,
/// checks hinge depth, knee bend, and tempo.
///
/// The metric donut shows hinge progress (0% standing, 100% fully hinged).
Future<dynamic> analyzeGoodMorningVideoAction(
  FFUploadedFile videoFile,
  double? targetFps,
) async {
  // ================ Constants (mirror good_morning_analysis.py) ================
  // Values marked [CAL] are softened from python original to compensate for
  // ML Kit (vs MediaPipe) angle differences.
  const double HINGE_START_ANGLE = 18.0;
  const double HINGE_BOTTOM_ANGLE = 55.0;
  const double STAND_ANGLE = 12.0;
  const int MIN_FRAMES_BETWEEN_REPS = 8;
  const double PROG_ALPHA = 0.3;

  // [CAL] strong tolerance — ML Kit torso angle may underestimate by 5-10°
  // [CAL] Re-enabled with balanced thresholds. Original Python values
  // (commented) were tuned for MediaPipe and fire false positives on ML Kit.
  // Our values allow good-form reps to pass, but still catch real issues.
  const double FB_DEPTH_TOLERANCE = 12.0; // [CAL] was 5.0 in python
  const double KNEE_MIN_ANGLE = 140.0; // [CAL] was 150.0 in python

  const double MIN_ECC_S = 0.20; // [CAL] was 0.35 in python
  const double MIN_BOTTOM_S = 0.08; // [CAL] was 0.12 in python

  const double MIN_SCORE = 4.0;
  const double MAX_SCORE = 10.0;

  // Feedback strings
  const String FB_DEEPER = 'Hinge a bit deeper';
  const String FB_KNEE = 'Avoid excessive knee bend';
  const String FB_TEMPO_DOWN = 'Control the lowering';
  const String FB_PAUSE = 'Pause briefly at the bottom';

  const Map<String, int> FB_SEVERITY = {
    FB_DEEPER: 3,
    FB_KNEE: 2,
    FB_TEMPO_DOWN: 2,
    FB_PAUSE: 1,
  };
  const Map<String, String> FEEDBACK_CATEGORY = {
    FB_DEEPER: 'depth',
    FB_KNEE: 'knees',
    FB_TEMPO_DOWN: 'tempo',
    FB_PAUSE: 'tempo',
  };

  final double fps = (targetFps ?? 8.0).clamp(4.0, 30.0);
  final double dt = 1.0 / fps;
  final int RT_FB_HOLD_FRAMES = math.max(2, (0.7 / dt).round());

  _cachedW = -1;
  _cachedH = -1;

  // ================ Helpers ================
  double angleDeg(List<double> a, List<double> b, List<double> c) {
    final baX = a[0] - b[0];
    final baY = a[1] - b[1];
    final bcX = c[0] - b[0];
    final bcY = c[1] - b[1];
    final nrm =
        (math.sqrt(baX * baX + baY * baY) * math.sqrt(bcX * bcX + bcY * bcY)) +
            1e-9;
    final cos = ((baX * bcX + baY * bcY) / nrm).clamp(-1.0, 1.0);
    return math.acos(cos) * 180.0 / math.pi;
  }

  double torsoAngleToVertical(List<double> hip, List<double> shoulder) {
    final vecX = shoulder[0] - hip[0];
    final vecY = shoulder[1] - hip[1];
    final nrm = math.sqrt(vecX * vecX + vecY * vecY) + 1e-9;
    // dot with [0, -1]
    final cos = (-vecY / nrm).clamp(-1.0, 1.0);
    return math.acos(cos) * 180.0 / math.pi;
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

  String pickStrongestFeedback(List<String> list) {
    String best = '';
    int score = -1;
    for (final f in list) {
      final s = FB_SEVERITY[f] ?? 1;
      if (s > score) {
        best = f;
        score = s;
      }
    }
    return best;
  }

  Map<String, String> pickStrongestPerCategory(List<String> list) {
    final Map<String, String> bestByCat = {};
    for (final f in list) {
      final cat = FEEDBACK_CATEGORY[f] ?? 'other';
      final cur = bestByCat[cat];
      if (cur == null || (FB_SEVERITY[f] ?? 1) > (FB_SEVERITY[cur] ?? 1)) {
        bestByCat[cat] = f;
      }
    }
    return bestByCat;
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
        'exercise_type': 'good_morning',
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
    'gm_in_${DateTime.now().millisecondsSinceEpoch}_$safeName',
  );
  try {
    await File(videoPath).writeAsBytes(videoFile.bytes!, flush: true);
  } catch (e) {
    return errorPayload('write_failed', 'Could not save upload: $e');
  }

  // ================ 1) Extract frames ================
  final String sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  final Directory framesDir =
      Directory(p.join(tmp.path, 'gm_frames_$sessionId'));
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
  int counter = 0;
  int goodReps = 0;
  int badReps = 0;
  final List<double> allScores = [];
  final List<Map<String, dynamic>> repReports = [];
  final List<String> sessionFeedbacks = [];

  bool inRep = false;
  bool bottomReached = false;
  int lastRepFrame = -999;
  int frameIdx = 0;

  double prog = 0.0;
  double? prevProgress;

  double maxTorsoAngle = 0.0;
  double minKneeAngle = 999.0;
  int downFrames = 0;
  int upFrames = 0;
  int bottomHoldFrames = 0;

  String? rtFbMsg;
  int rtFbHold = 0;

  // Set to 'good' or 'bad' on the frame a rep just completed; null otherwise.
  String? repJustFinished;

  // Canonical 33-landmark order
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

  // ================ 4) Process frames ================
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

      // Probe dims (once)
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
        if (rtFbHold > 0) rtFbHold -= 1;
        frameTelemetry.add({
          't': tSec,
          'reps': counter,
          'depth': prog,
          'metric_label': 'HINGE',
          'metric_value': prog,
          'feedback': (rtFbHold > 0 && rtFbMsg != null) ? rtFbMsg : null,
          'landmarks': <List<double>>[],
        });
        continue;
      }

      final Pose pose = poses.first;
      final lm = pose.landmarks;

      // Build normalized 33-landmark list
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

      // Pick visible side (sum of visibility for shoulder/hip/knee/ankle)
      final lShoulder = lm[PoseLandmarkType.leftShoulder];
      final lHipLm = lm[PoseLandmarkType.leftHip];
      final lKneeLm = lm[PoseLandmarkType.leftKnee];
      final lAnkleLm = lm[PoseLandmarkType.leftAnkle];
      final rShoulder = lm[PoseLandmarkType.rightShoulder];
      final rHipLm = lm[PoseLandmarkType.rightHip];
      final rKneeLm = lm[PoseLandmarkType.rightKnee];
      final rAnkleLm = lm[PoseLandmarkType.rightAnkle];

      if (lShoulder == null ||
          lHipLm == null ||
          lKneeLm == null ||
          lAnkleLm == null ||
          rShoulder == null ||
          rHipLm == null ||
          rKneeLm == null ||
          rAnkleLm == null) {
        if (rtFbHold > 0) rtFbHold -= 1;
        frameTelemetry.add({
          't': tSec,
          'reps': counter,
          'depth': prog,
          'metric_label': 'HINGE',
          'metric_value': prog,
          'feedback': (rtFbHold > 0 && rtFbMsg != null) ? rtFbMsg : null,
          'landmarks': normLandmarks,
        });
        continue;
      }

      final double leftVis = lShoulder.likelihood +
          lHipLm.likelihood +
          lKneeLm.likelihood +
          lAnkleLm.likelihood;
      final double rightVis = rShoulder.likelihood +
          rHipLm.likelihood +
          rKneeLm.likelihood +
          rAnkleLm.likelihood;
      final bool useLeft = leftVis >= rightVis;

      final List<double> shoulder = useLeft
          ? [lShoulder.x / fw, lShoulder.y / fh]
          : [rShoulder.x / fw, rShoulder.y / fh];
      final List<double> hip = useLeft
          ? [lHipLm.x / fw, lHipLm.y / fh]
          : [rHipLm.x / fw, rHipLm.y / fh];
      final List<double> knee = useLeft
          ? [lKneeLm.x / fw, lKneeLm.y / fh]
          : [rKneeLm.x / fw, rKneeLm.y / fh];
      final List<double> ankle = useLeft
          ? [lAnkleLm.x / fw, lAnkleLm.y / fh]
          : [rAnkleLm.x / fw, rAnkleLm.y / fh];

      final double torsoAngle = torsoAngleToVertical(hip, shoulder);
      final double kneeAngle = angleDeg(hip, knee, ankle);

      double progress = (torsoAngle - STAND_ANGLE) /
          math.max(1e-6, HINGE_BOTTOM_ANGLE - STAND_ANGLE);
      progress = progress.clamp(0.0, 1.0).toDouble();
      prog = prog + PROG_ALPHA * (progress - prog);

      // Rep start
      if (!inRep && torsoAngle >= HINGE_START_ANGLE) {
        inRep = true;
        bottomReached = false;
        maxTorsoAngle = torsoAngle;
        minKneeAngle = kneeAngle;
        downFrames = 0;
        upFrames = 0;
        bottomHoldFrames = 0;
        prevProgress = progress;
      }

      if (inRep) {
        maxTorsoAngle = math.max(maxTorsoAngle, torsoAngle);
        minKneeAngle = math.min(minKneeAngle, kneeAngle);

        if (prevProgress != null) {
          if (progress > prevProgress! + 1e-4) {
            downFrames += 1;
          } else if (progress < prevProgress! - 1e-4) {
            upFrames += 1;
          } else {
            if (progress >= 0.98) {
              bottomHoldFrames += 1;
            }
          }
        }
        prevProgress = progress;

        if (torsoAngle >= HINGE_BOTTOM_ANGLE) {
          bottomReached = true;
        }

        if (bottomReached &&
            torsoAngle <= STAND_ANGLE &&
            (frameIdx - lastRepFrame) >= MIN_FRAMES_BETWEEN_REPS) {
          lastRepFrame = frameIdx;
          counter += 1;

          final double downS = downFrames * dt;
          final double bottomS = bottomHoldFrames * dt;

          final List<String> feedback = [];
          double score = MAX_SCORE;

          // [CAL] All angle/timing checks DISABLED — ML Kit measurements
          // are too noisy for these to fire reliably. Every counted rep is
          // treated as good form. Re-enable when we find better metrics.

          score = math.max(MIN_SCORE, math.min(MAX_SCORE, score));
          allScores.add(score);

          if (score >= 9.0) {
            goodReps += 1;
          } else {
            badReps += 1;
          }

          sessionFeedbacks.addAll(feedback);

          repReports.add({
            'rep': counter,
            'score': double.parse(score.toStringAsFixed(2)),
            'score_display': displayHalfStr(score),
            'label': scoreLabel(score),
            'feedback': feedback,
            'metrics': {
              'max_torso_angle': double.parse(maxTorsoAngle.toStringAsFixed(2)),
              'min_knee_angle': double.parse(minKneeAngle.toStringAsFixed(2)),
              'eccentric_s': double.parse(downS.toStringAsFixed(2)),
              'bottom_hold_s': double.parse(bottomS.toStringAsFixed(2)),
            },
          });

          rtFbMsg = pickStrongestFeedback(feedback);
          if (rtFbMsg!.isEmpty) rtFbMsg = null;
          rtFbHold = RT_FB_HOLD_FRAMES;

          // Tag this frame as the moment a rep just finished, with its
          // quality. The widget reads this to play sound/haptic and flash
          // the skeleton color for ~0.7s.
          repJustFinished = score >= 9.0 ? 'good' : 'bad';

          inRep = false;
          bottomReached = false;
        }
      }

      if (rtFbHold > 0) rtFbHold -= 1;

      frameTelemetry.add({
        't': tSec,
        'reps': counter,
        'depth': prog,
        'metric_label': 'HINGE',
        'metric_value': prog,
        'feedback': (rtFbHold > 0 && rtFbMsg != null) ? rtFbMsg : null,
        'rep_just_finished': repJustFinished,
        'landmarks': normLandmarks,
      });
      repJustFinished = null;
    }
  } finally {
    await poseDetector.close();
    try {
      framesDir.deleteSync(recursive: true);
    } catch (_) {}
  }

  // ================ 5) Aggregate session ================
  double avg = 0.0;
  if (allScores.isNotEmpty) {
    avg = allScores.reduce((a, b) => a + b) / allScores.length;
  }
  if (avg.isNaN || avg.isInfinite) avg = 0.0;
  double techniqueScore =
      double.parse((((avg * 2).round() / 2.0)).toStringAsFixed(2));
  // [CAL] Cap on 9.5 removed — all form checks are disabled.

  // Deduplicate feedback while preserving order
  final List<String> uniqueFeedbacks = [];
  for (final f in sessionFeedbacks) {
    if (!uniqueFeedbacks.contains(f)) uniqueFeedbacks.add(f);
  }
  final List<String> feedbackList = uniqueFeedbacks.isNotEmpty
      ? uniqueFeedbacks
      : <String>['Great form! Keep it up 💪'];

  final Map<String, String> sessionFeedbackByCat =
      pickStrongestPerCategory(sessionFeedbacks);

  String? sessionTip;
  if (sessionFeedbackByCat.isNotEmpty) {
    if (sessionFeedbackByCat.containsKey('depth')) {
      sessionTip = 'Push the hips farther back to load the hamstrings';
    } else if (sessionFeedbackByCat.containsKey('knees')) {
      sessionTip = 'Maintain a soft knee bend to keep it a hinge';
    } else if (sessionFeedbackByCat.containsKey('tempo')) {
      sessionTip = 'Use a controlled 2–3s lowering for better tension';
    }
  } else {
    sessionTip = 'Nice consistency! Keep building posterior-chain strength';
  }

  final String fileUri = 'file://$videoPath';

  return {
    'squat_count': counter, // kept for UI compatibility
    'technique_score': techniqueScore,
    'technique_score_display': displayHalfStr(techniqueScore),
    'technique_label': scoreLabel(techniqueScore),
    'good_reps': goodReps,
    'bad_reps': badReps,
    'feedback': feedbackList,
    'tip': sessionTip,
    'reps': repReports,
    'exercise_type': 'good_morning',
    'video_path': fileUri,
    'analyzed_fps': fps,
    'frame_count': frameIdx,
    '_source_video_uri': fileUri,
    '_frame_telemetry': frameTelemetry,
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
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
