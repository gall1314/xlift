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
// v2 [PEAK-SYNCED PULSE]
// Counter increment + rep_just_finished pulse + display change all happen
// at the actual peak of the curl (the frame with the minimum elbow angle
// during the up phase) — NOT at the moment we first crossed BENT_THRESHOLD.
//
// Original behaviour: counter++ fired at the FIRST frame where elbow ≤ 110°.
// The user is still climbing past that threshold and the visual peak is
// 1–3 frames later, so the green "Reps: N" change appeared too early.
//
// New behaviour: while the user is in the up phase, we track which
// telemetry index has the smallest elbow angle so far (the running peak).
// When the rep eventually completes at the bottom, we go back and rewrite
// the counter and rep_just_finished into the recorded peak frame.
//
// The COUNTING LOGIC is unchanged — same threshold crossings, same
// validation gates, same MIN_FRAMES_BETWEEN_REPS check. We only changed
// WHERE in the telemetry timeline the visible event lands.
// ============================================================================

Future<dynamic> analyzeBicepCurlVideoAction(
  FFUploadedFile videoFile,
  double? targetFps,
) async {
  // ================ Constants (mirror barbell_bicep_curl.py) ================
  const int MIN_FRAMES_BETWEEN_REPS = 3;
  const double HIP_VEL_THRESH_PCT = 0.022;
  const double ANKLE_VEL_THRESH_PCT = 0.026;
  const double EMA_ALPHA = 0.65;
  const int MOVEMENT_CLEAR_FRAMES = 1;
  const double RT_FB_HOLD_SEC = 0.8;

  const double ELBOW_BOTTOM_EXT_REF = 170.0;
  const double ELBOW_TOP_FLEX_REF = 60.0;
  const double ELBOW_EXT_END_THR = 150.0;
  const double MIN_BOTTOM_EXTENSION_ANGLE = 145.0;
  const double TOP_FLEXION_RATIO = 0.50;
  const double TOP_FLEXION_MIN_ANGLE = 60.0;
  const double TOP_FLEXION_MAX_ANGLE = 130.0;
  const double TOP_FLEXION_MARGIN_DEG = 12.0;
  const int TOP_FLEXION_TRIGGER_FRAMES = 6;
  const double ECC_SLOW_MIN_SEC = 0.25;
  const double ANGLE_EMA_ALPHA = 0.45;
  const double UP_START_DERIV_THR = -0.2;
  const double DOWN_START_DERIV_THR = 0.15;
  const int DIRECTION_STREAK_FRAMES = 1;
  final double REP_END_ANGLE_THR = ELBOW_EXT_END_THR - 5.0;

  const String FB_NOT_STRAIGHT =
      'Straighten your arms fully at the bottom for a full range of motion';
  const String FB_CURL_HIGHER =
      'Try to curl higher — aim to squeeze at the top';

  final double fps = (targetFps ?? 8.0).clamp(4.0, 30.0);
  final double dt = 1.0 / fps;
  final int RT_FB_HOLD_FRAMES = math.max(2, (RT_FB_HOLD_SEC / dt).round());
  final int ECC_SLOW_MIN_FRAMES = math.max(2, (ECC_SLOW_MIN_SEC / dt).round());

  _cachedW = -1;
  _cachedH = -1;

  // ================ Helpers ================
  double calcAngle(List<double> a, List<double> b, List<double> c) {
    final double rad = math.atan2(c[1] - b[1], c[0] - b[0]) -
        math.atan2(a[1] - b[1], a[0] - b[0]);
    double deg = (rad * 180.0 / math.pi).abs();
    if (deg > 180) deg = 360 - deg;
    return deg;
  }

  double topFlexionThreshold(double bottomRef) {
    final double target =
        bottomRef - TOP_FLEXION_RATIO * (bottomRef - ELBOW_TOP_FLEX_REF);
    return target.clamp(TOP_FLEXION_MIN_ANGLE, TOP_FLEXION_MAX_ANGLE);
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

  int feedbackSeverity(String f) {
    if (f == FB_NOT_STRAIGHT) return 3;
    if (f == FB_CURL_HIGHER) return 2;
    return 1;
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
        'exercise_type': 'bicep_curl',
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
    'curl_in_${DateTime.now().millisecondsSinceEpoch}_$safeName',
  );
  try {
    await File(videoPath).writeAsBytes(videoFile.bytes!, flush: true);
  } catch (e) {
    return errorPayload('write_failed', 'Could not save upload: $e');
  }

  // ================ 1) Extract frames ================
  final String sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  final Directory framesDir =
      Directory(p.join(tmp.path, 'curl_frames_$sessionId'));
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
  final List<Map<String, dynamic>> repReports = [];
  final List<double> allScores = [];
  String sessionBestFeedback = '';
  String? sessionTip;

  // Walking filter state
  List<double>? prevHip;
  List<double>? prevLa;
  List<double>? prevRa;
  double hipVelEma = 0.0;
  double ankleVelEma = 0.0;
  int movementFreeStreak = 0;

  // Rep state
  String? stage; // null / "up" / "down"

  // [v2 PEAK-SYNCED] These three pieces of state track the running peak of
  // the current rep. peakTelemetryIdx is the index INTO frameTelemetry of
  // the frame where the elbow has been most flexed so far in this up
  // phase. When the rep finishes at the bottom, we go back and rewrite
  // that telemetry entry's `reps` and `rep_just_finished` fields so the
  // visible counter increment + pulse line up with the actual visual peak.
  int? peakTelemetryIdx;
  double peakElbowAngle = 999.0;
  // The counter value to apply at the peak (committed only when the rep
  // is validated at the bottom). Equal to counter+1 at the moment the
  // peak is first detected.
  int? peakCounterTarget;

  int frameIdx = 0;
  int lastRepFrame = -999;

  // Angle tracking
  double? extElbowEma;
  double depthLive = 0.0;
  int? repStartFrame;
  double? repStartElbowAngle;
  double repMinElbowAngle = 999.0;
  double repMaxElbowAngle = -999.0;
  int? topIndex;
  double? lastAngle;
  double? elbowAngleEma;
  int topFlexBadFrames = 0;
  int upMotionStreak = 0;
  int downMotionStreak = 0;
  bool sawDescentAfterTop = false;

  // RT feedback
  String? rtFbMsg;
  int rtFbHold = 0;

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
        depthLive = 0.0;
        if (rtFbHold > 0) rtFbHold -= 1;
        frameTelemetry.add({
          't': tSec,
          'reps': counter,
          'depth': depthLive,
          'metric_label': 'CURL',
          'metric_value': depthLive,
          'feedback': (rtFbHold > 0 && rtFbMsg != null) ? rtFbMsg : null,
          'rep_just_finished': null,
          'landmarks': <List<double>>[],
        });
        continue;
      }

      final Pose pose = poses.first;
      final lm = pose.landmarks;

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

      final PoseLandmark? rHip = lm[PoseLandmarkType.rightHip];
      final PoseLandmark? lAnk = lm[PoseLandmarkType.leftAnkle];
      final PoseLandmark? rAnk = lm[PoseLandmarkType.rightAnkle];
      final PoseLandmark? lSh = lm[PoseLandmarkType.leftShoulder];
      final PoseLandmark? lEl = lm[PoseLandmarkType.leftElbow];
      final PoseLandmark? lWr = lm[PoseLandmarkType.leftWrist];
      final PoseLandmark? rSh = lm[PoseLandmarkType.rightShoulder];
      final PoseLandmark? rEl = lm[PoseLandmarkType.rightElbow];
      final PoseLandmark? rWr = lm[PoseLandmarkType.rightWrist];

      if (rHip == null ||
          lAnk == null ||
          rAnk == null ||
          lSh == null ||
          lEl == null ||
          lWr == null ||
          rSh == null ||
          rEl == null ||
          rWr == null) {
        depthLive = 0.0;
        if (rtFbHold > 0) rtFbHold -= 1;
        frameTelemetry.add({
          't': tSec,
          'reps': counter,
          'depth': depthLive,
          'metric_label': 'CURL',
          'metric_value': depthLive,
          'feedback': (rtFbHold > 0 && rtFbMsg != null) ? rtFbMsg : null,
          'rep_just_finished': null,
          'landmarks': normLandmarks,
        });
        continue;
      }

      final List<double> hipPx = [rHip.x, rHip.y];
      final List<double> laPx = [lAnk.x, lAnk.y];
      final List<double> raPx = [rAnk.x, rAnk.y];
      prevHip ??= hipPx;
      prevLa ??= laPx;
      prevRa ??= raPx;

      double dPx(List<double> a, List<double> b) {
        final dx = a[0] - b[0];
        final dy = a[1] - b[1];
        return math.sqrt(dx * dx + dy * dy) / math.max(fw, fh);
      }

      final double hipVel = dPx(hipPx, prevHip!);
      final double anVel = math.max(dPx(laPx, prevLa!), dPx(raPx, prevRa!));
      hipVelEma = EMA_ALPHA * hipVel + (1 - EMA_ALPHA) * hipVelEma;
      ankleVelEma = EMA_ALPHA * anVel + (1 - EMA_ALPHA) * ankleVelEma;
      prevHip = hipPx;
      prevLa = laPx;
      prevRa = raPx;

      final bool movementBlock = (hipVelEma > HIP_VEL_THRESH_PCT) ||
          (ankleVelEma > ANKLE_VEL_THRESH_PCT);
      if (movementBlock) {
        movementFreeStreak = 0;
      } else {
        movementFreeStreak =
            math.min(MOVEMENT_CLEAR_FRAMES, movementFreeStreak + 1);
      }

      final double lAng = calcAngle(
        [lSh.x, lSh.y],
        [lEl.x, lEl.y],
        [lWr.x, lWr.y],
      );
      final double rAng = calcAngle(
        [rSh.x, rSh.y],
        [rEl.x, rEl.y],
        [rWr.x, rWr.y],
      );
      final List<double> angles = [];
      if (!lAng.isNaN) angles.add(lAng);
      if (!rAng.isNaN) angles.add(rAng);

      if (angles.isEmpty) {
        if (rtFbHold > 0) rtFbHold -= 1;
        depthLive = 0.0;
        frameTelemetry.add({
          't': tSec,
          'reps': counter,
          'depth': depthLive,
          'metric_label': 'CURL',
          'metric_value': depthLive,
          'feedback': (rtFbHold > 0 && rtFbMsg != null) ? rtFbMsg : null,
          'rep_just_finished': null,
          'landmarks': normLandmarks,
        });
        continue;
      }

      final double elbowAngleRaw =
          angles.reduce((a, b) => a + b) / angles.length;
      elbowAngleEma = elbowAngleEma == null
          ? elbowAngleRaw
          : ANGLE_EMA_ALPHA * elbowAngleRaw +
              (1.0 - ANGLE_EMA_ALPHA) * elbowAngleEma!;
      final double elbowAngle = elbowAngleEma!;

      if (elbowAngle > ELBOW_EXT_END_THR &&
          movementFreeStreak >= MOVEMENT_CLEAR_FRAMES) {
        extElbowEma = extElbowEma == null
            ? elbowAngle
            : 0.30 * elbowAngle + 0.70 * extElbowEma!;
      }

      final double bottomRef = extElbowEma ?? ELBOW_BOTTOM_EXT_REF;
      final double topFlexThr = topFlexionThreshold(bottomRef);
      final double topFlexFeedbackThr = topFlexThr + TOP_FLEXION_MARGIN_DEG;
      final double denomLive = math.max(10.0, bottomRef - ELBOW_TOP_FLEX_REF);
      depthLive =
          ((bottomRef - elbowAngle) / denomLive).clamp(0.0, 1.0).toDouble();

      double? deriv;
      if (lastAngle != null) {
        deriv = elbowAngle - lastAngle!;
      }
      lastAngle = elbowAngle;

      if (deriv != null) {
        if (deriv < UP_START_DERIV_THR) {
          upMotionStreak += 1;
        } else {
          upMotionStreak = 0;
        }
        if (deriv > DOWN_START_DERIV_THR) {
          downMotionStreak += 1;
        } else {
          downMotionStreak = 0;
        }
      }

      const double BENT_THRESHOLD = 110.0;
      const double STRAIGHT_THRESHOLD = 145.0;

      // ---- Rep start (TOP threshold crossed) ----
      // [v2] We no longer increment counter here. Counting is unchanged
      // semantically, but the visible event (counter, color, pulse) is
      // deferred until we see the actual peak of this curl. We initialize
      // peak tracking to the current frame.
      if ((stage == null || stage == 'down') && elbowAngle <= BENT_THRESHOLD) {
        stage = 'up';
        repStartFrame = frameIdx;
        repStartElbowAngle = elbowAngle;
        repMinElbowAngle = elbowAngle;
        repMaxElbowAngle = elbowAngle;
        topIndex = frameIdx;
        topFlexBadFrames = 0;
        sawDescentAfterTop = true;
        rtFbMsg = null;
        rtFbHold = 0;

        // [v2 PEAK-SYNCED] Initialize peak tracking. peakTelemetryIdx is
        // the index of the frame we're ABOUT to add (frameTelemetry.length
        // before the add). peakCounterTarget is what `reps` should become
        // when this rep is committed at the bottom — only validated reps
        // (the gate below) qualify.
        if (frameIdx - lastRepFrame > MIN_FRAMES_BETWEEN_REPS) {
          peakTelemetryIdx = frameTelemetry.length;
          peakElbowAngle = elbowAngle;
          peakCounterTarget = counter + 1;
          // We commit lastRepFrame here (just like the original code did
          // for counter++) because that gate prevents the SAME up-phase
          // from triggering again. Counting/spacing semantics unchanged.
          lastRepFrame = frameIdx;
        } else {
          peakTelemetryIdx = null;
          peakElbowAngle = 999.0;
          peakCounterTarget = null;
        }
      }

      // [v2 PEAK-SYNCED] Update running peak while in up phase.
      // We're looking for the smallest elbow angle. Note: peakTelemetryIdx
      // is updated to the index of the frame we're ABOUT to push, which
      // equals frameTelemetry.length right now.
      if (stage == 'up' &&
          peakTelemetryIdx != null &&
          elbowAngle < peakElbowAngle) {
        peakElbowAngle = elbowAngle;
        peakTelemetryIdx = frameTelemetry.length;
      }

      // During rep
      if (stage == 'up' || stage == 'down') {
        repMinElbowAngle = math.min(repMinElbowAngle, elbowAngle);
        repMaxElbowAngle = math.max(repMaxElbowAngle, elbowAngle);

        if (stage == 'up') {
          if (repMinElbowAngle > topFlexFeedbackThr) {
            topFlexBadFrames += 1;
          } else {
            topFlexBadFrames = 0;
          }
          if (topFlexBadFrames >= TOP_FLEXION_TRIGGER_FRAMES) {
            if (rtFbMsg != FB_CURL_HIGHER) {
              rtFbMsg = FB_CURL_HIGHER;
              rtFbHold = RT_FB_HOLD_FRAMES;
            } else {
              rtFbHold = math.max(rtFbHold, RT_FB_HOLD_FRAMES);
            }
          } else {
            if (rtFbHold > 0) rtFbHold -= 1;
          }
        } else {
          if (rtFbHold > 0) rtFbHold -= 1;
        }
      }

      // ---- Rep end (BOTTOM): score it, COMMIT pulse to recorded peak ----
      if ((stage == 'up' || stage == 'down') &&
          elbowAngle >= STRAIGHT_THRESHOLD) {
        if (frameIdx - (repStartFrame ?? frameIdx) > 3) {
          final List<String> feedbacks = [];
          double penalty = 0.0;

          String? tipMsg;
          if (topIndex != null) {
            final int eccFrames = frameIdx - topIndex!;
            if (eccFrames < ECC_SLOW_MIN_FRAMES) {
              tipMsg = 'Slow down the lowering phase to maximize hypertrophy';
            }
          }

          double score;
          if (feedbacks.isEmpty) {
            score = 10.0;
          } else {
            score = math.max(4.0, 10.0 - math.min(penalty, 6.0));
            score = (score * 2).round() / 2.0;
          }

          final double bottomRefFinal = extElbowEma ?? ELBOW_BOTTOM_EXT_REF;
          final double denomFinal =
              math.max(10.0, bottomRefFinal - ELBOW_TOP_FLEX_REF);
          final double depthPctFinal =
              ((bottomRefFinal - repMinElbowAngle) / denomFinal)
                  .clamp(0.0, 1.0)
                  .toDouble();

          // [v2 PEAK-SYNCED] Commit the visible event now, BEFORE we
          // increment `counter`. We rewrite the recorded peak frame's
          // telemetry: bump its `reps` to the new value and stamp the
          // verdict so the widget plays haptic+sound at the visual peak.
          // All telemetry frames AFTER the peak (between peak and now)
          // also need their `reps` bumped, because they were emitted
          // with the old counter value.
          //
          // Edge case: if peakTelemetryIdx is null (rep was rejected by
          // MIN_FRAMES_BETWEEN_REPS gate at the start), we don't count
          // this rep at all — same as original behaviour.
          if (peakTelemetryIdx != null && peakCounterTarget != null) {
            final int peakIdx = peakTelemetryIdx!;
            final int newReps = peakCounterTarget!;

            // Stamp the peak frame.
            if (peakIdx < frameTelemetry.length) {
              frameTelemetry[peakIdx]['reps'] = newReps;
              frameTelemetry[peakIdx]['rep_just_finished'] =
                  (score >= 9.5) ? 'good' : 'bad';
            }
            // Bump every frame AFTER the peak (already pushed during the
            // descent of this rep) so the counter visibly ticks up at
            // the peak and stays at the new value.
            for (int j = peakIdx + 1; j < frameTelemetry.length; j++) {
              frameTelemetry[j]['reps'] = newReps;
            }

            // Update the running counter to match.
            counter = newReps;
            if (score >= 9.5) {
              goodReps += 1;
            } else {
              badReps += 1;
            }
            allScores.add(score);

            repReports.add({
              'rep_index': counter,
              'score': double.parse(score.toStringAsFixed(1)),
              'score_display': displayHalfStr(score),
              'feedback': List<String>.from(feedbacks),
              'tip': tipMsg,
              'start_frame': repStartFrame ?? 0,
              'end_frame': frameIdx,
              'start_elbow_angle': double.parse(
                  (repStartElbowAngle ?? elbowAngle).toStringAsFixed(2)),
              'min_elbow_angle':
                  double.parse(repMinElbowAngle.toStringAsFixed(2)),
              'max_elbow_angle':
                  double.parse(repMaxElbowAngle.toStringAsFixed(2)),
              'depth_pct': depthPctFinal,
            });

            if (feedbacks.isNotEmpty) {
              String best = feedbacks.first;
              for (final f in feedbacks) {
                if (feedbackSeverity(f) > feedbackSeverity(best)) best = f;
              }
              if (sessionBestFeedback.isEmpty ||
                  feedbackSeverity(best) >=
                      feedbackSeverity(sessionBestFeedback)) {
                sessionBestFeedback = best;
              }
            }

            if (tipMsg != null && sessionTip == null) {
              sessionTip = tipMsg;
            }
          }

          // Reset for next rep.
          stage = null;
          repStartFrame = null;
          repStartElbowAngle = null;
          repMinElbowAngle = 999.0;
          repMaxElbowAngle = -999.0;
          topIndex = null;
          topFlexBadFrames = 0;
          upMotionStreak = 0;
          downMotionStreak = 0;
          sawDescentAfterTop = false;
          rtFbMsg = null;
          rtFbHold = 0;
          // [v2] Clear peak tracking for the next rep.
          peakTelemetryIdx = null;
          peakElbowAngle = 999.0;
          peakCounterTarget = null;
        }
      }

      // [v2] Always emit telemetry with the CURRENT counter value (which
      // hasn't been bumped yet for the rep in progress — the bump happens
      // retroactively when the rep completes). `rep_just_finished` is
      // never set inline anymore — it's only set retroactively at the
      // peak frame.
      frameTelemetry.add({
        't': tSec,
        'reps': counter,
        'depth': depthLive,
        'metric_label': 'CURL',
        'metric_value': depthLive,
        'feedback': (rtFbHold > 0 && rtFbMsg != null) ? rtFbMsg : null,
        'rep_just_finished': null,
        'landmarks': normLandmarks,
      });
    }

    // [v2 PEAK-SYNCED] End-of-video edge case. If the video ends mid-rep
    // (user reached the peak but never came back down to STRAIGHT_THRESHOLD),
    // peakTelemetryIdx is still set but the rep was never validated /
    // scored. We commit it here as a "good" rep (we have no penalty data
    // either way; same default the original code used). This guarantees
    // the LAST rep of any video gets its visible counter bump + pulse.
    if (peakTelemetryIdx != null && peakCounterTarget != null) {
      final int peakIdx = peakTelemetryIdx!;
      final int newReps = peakCounterTarget!;

      if (peakIdx < frameTelemetry.length) {
        frameTelemetry[peakIdx]['reps'] = newReps;
        // Without bottom validation we can't compute a score; treat as
        // good (this is also what the original code's fallback did).
        frameTelemetry[peakIdx]['rep_just_finished'] = 'good';
      }
      for (int j = peakIdx + 1; j < frameTelemetry.length; j++) {
        frameTelemetry[j]['reps'] = newReps;
      }

      counter = newReps;
      goodReps += 1;
      allScores.add(10.0);

      repReports.add({
        'rep_index': counter,
        'score': 10.0,
        'score_display': '10',
        'feedback': const <String>[],
        'tip': null,
        'start_frame': repStartFrame ?? 0,
        'end_frame': frameIdx,
        'start_elbow_angle':
            double.parse((repStartElbowAngle ?? 0).toStringAsFixed(2)),
        'min_elbow_angle': double.parse(repMinElbowAngle.toStringAsFixed(2)),
        'max_elbow_angle': double.parse(repMaxElbowAngle.toStringAsFixed(2)),
        'depth_pct': 1.0,
        'incomplete_descent': true,
      });
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
  final double techniqueScore =
      double.parse((((avg * 2).round() / 2.0)).toStringAsFixed(2));

  // [v2] Mirror the squat analyzer's behaviour: 0 reps → generic
  // "couldn't analyze" feedback rather than "Great form!". (The squat
  // analyzer was updated for this; doing the same here for consistency.)
  final List<String> feedbackList;
  if (counter == 0) {
    feedbackList = <String>[
      "Couldn't analyze this video — make sure your full body is visible from the side and that you complete at least one curl."
    ];
  } else if (sessionBestFeedback.isNotEmpty) {
    feedbackList = [sessionBestFeedback];
  } else {
    feedbackList = <String>['Great form! Keep it up 💪'];
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
    'tip': counter == 0 ? null : sessionTip,
    'reps': repReports,
    'exercise_type': 'bicep_curl',
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
