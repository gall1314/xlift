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

import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';

import 'dart:io';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

/// Bulgarian Split Squat analyzer.
///
/// Pipeline:
///   1. Extract frames at target FPS via ffmpeg.
///   2. Run ML Kit pose detection per frame.
///   3. Reject frames with bad pose (low visibility, partial body, jumps).
///   4. Apply EMA smoothing to active-leg knee angle.
///   5. Detect reps via local-minima in knee angle (descent + rise gates).
///   6. Score form during descent (torso lean, valgus, knee-over-toe, depth).
///   7. Post-process: locate the actual visual peak frame between each
///      pair of bottoms, and place the rep marker + counter tick there.
///
/// The post-process search is what makes the on-screen flash land on the
/// real peak instead of the detection moment (which fires shortly after
/// the bottom, while the user is still rising).
Future<dynamic> analyzeBulgarianVideoAction(
  FFUploadedFile videoFile,
  double? targetFps,
) async {
  // ====== Tuning ======
  const double EMA_ALPHA = 0.5;

  const double DESCENT_DELTA_DEG = 25.0;
  const double RISE_DELTA_DEG = 15.0;
  const double MIN_REP_GAP_SEC = 0.20;
  const int LOOKBACK_WINDOW_SEC = 2;
  const double LOOKAHEAD_MAX_SEC = 0.8;

  const int PEAK_BUFFER_FOR_INIT = 5;
  const double DOWN_DELTA_FROM_PEAK = 25.0;
  const double UP_DELTA_FROM_PEAK = 10.0;

  const double KNEE_HARD_MIN = 40.0;
  const double KNEE_HARD_MAX = 185.0;
  const double RAW_JUMP_REJECT = 90.0;
  const int GAP_RESET_FRAMES = 4;

  const double KNEE_MIN_VIS = 0.5;
  const double HIP_ANK_MIN_VIS = 0.3;

  const double FULL_BODY_MIN_VIS = 0.3;
  const double MIN_BODY_SPAN_RATIO = 0.10;
  const int PEAK_RESET_AFTER_GAP = 15;

  const double SAW_STANDING_DELTA = 25.0;

  // === Form scoring ===
  const double GOOD_REP_MIN_SCORE = 8.0;
  const double TORSO_FROM_VERTICAL_BAD = 65.0;
  const int TORSO_BAD_MIN_FRAMES_FOR_SCORE =
      5; // tightened: 0.5s sustained lean
  const int TORSO_BAD_MIN_FRAMES_FOR_LIVE = 6;

  const double VALGUS_X_TOL = 0.04;
  const int VALGUS_BAD_MIN_FRAMES = 4;
  const double PERFECT_MIN_KNEE = 70.0;
  const double RT_FB_HOLD_SEC = 0.8;

  const double KNEE_OVER_TOE_TOL = 0.06;
  const int KNEE_OVER_TOE_BAD_MIN_FRAMES = 4;

  // Post-process visual-peak search
  const double STOP_DESCENT_DEG = 10.0;
  const double MIN_PEAK_RISE_FROM_BOTTOM = 15.0;

  const List<String> BULGARIAN_TIPS = [
    'Keep your front shin vertical at the bottom',
    'Drive through the front heel for power',
    'Brace your core before the descent',
    'Keep hips square – avoid rotation',
    'Control the eccentric; go down a bit slower',
    'Pause 1–2s at the bottom to build stability',
  ];

  final double fps = (targetFps ?? 10.0).clamp(2.0, 30.0);
  final double dt = 1.0 / fps;
  final int RT_FB_HOLD_FRAMES = math.max(2, (RT_FB_HOLD_SEC / dt).round());

  _bulgCachedW = -1;
  _bulgCachedH = -1;

  double calcAngle(List<double> a, List<double> b, List<double> c) {
    final double rad = math.atan2(c[1] - b[1], c[0] - b[0]) -
        math.atan2(a[1] - b[1], a[0] - b[0]);
    double ang = (rad * 180.0 / math.pi).abs();
    if (ang > 180) ang = 360 - ang;
    return ang;
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
          "Couldn't analyze this video — make sure your full body is visible from the side and that you complete at least one rep."
        ],
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
  final String rawSafeName = uploadName.split('/').last.split('\\').last;
  final String safeName =
      rawSafeName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  final String videoPath = p.join(
    tmp.path,
    'bulg_in_${DateTime.now().millisecondsSinceEpoch}_$safeName',
  );

  try {
    await File(videoPath).writeAsBytes(videoFile.bytes!, flush: true);
  } catch (e) {
    return errorPayload('write_failed', 'Could not save upload: $e');
  }

  final String sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  final Directory framesDir =
      Directory(p.join(tmp.path, 'bulg_frames_$sessionId'));
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

  final poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.single,
      model: PoseDetectionModel.accurate,
    ),
  );

  // ====== State ======
  int counter = 0;
  int goodReps = 0;
  int badReps = 0;
  final List<Map<String, dynamic>> repReports = [];
  final Map<String, int> sessionFeedback = {};

  int frameIdx = 0;
  int repIndex = 1;
  String? stage;

  double? kneeEma;
  double? torsoEma;
  double? prevKneeRaw;
  int gapStreak = 0;

  // Live counters for real-time feedback overlay
  int torsoBadFrames = 0;
  int valgusBadFrames = 0;
  int kneeOverToeBadFrames = 0;
  // Per-rep accumulators (reset on each descent), used for the rep verdict
  int repTorsoBadFramesAccum = 0;
  int repValgusBadFramesAccum = 0;
  int repKneeOverToeBadFramesAccum = 0;

  // Sliding window for local-min detection
  final List<List<double>> kneeSamples = []; // [[t, angle], ...]
  double lastRepTSec = -100.0;

  final List<Map<String, dynamic>> pulseEvents = [];
  bool sawStanding = false;

  double lastDepthForUi = 0.0;
  double? peakKnee;
  int validFrameCount = 0;

  String? rtFbMsg;
  int rtFbHold = 0;

  String? activeLeg;
  final List<String> activeLegVotes = [];
  const int ACTIVE_LEG_VOTES_NEEDED = 3;

  String? repJustFinished;

  final List<Map<String, dynamic>> frameTelemetry = [];

  // Per-frame EMA knee angle, kept in sync with frameTelemetry length.
  // 0.0 = no-pose for that frame. Used by the post-process search.
  final List<double> kneeAngleByFrame = [];

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

  void addEmptyFrame(double tSec) {
    frameTelemetry.add({
      't': tSec,
      'reps': counter,
      'depth': lastDepthForUi,
      'metric_label': 'DEPTH',
      'metric_value': lastDepthForUi,
      'feedback': (rtFbHold > 0) ? rtFbMsg : null,
      'rep_just_finished': repJustFinished,
      'landmarks': <List<double>>[],
    });
    kneeAngleByFrame.add(0.0);
    repJustFinished = null;
    if (rtFbHold > 0) rtFbHold -= 1;
  }

  void noteGap() {
    gapStreak += 1;
    if (gapStreak >= GAP_RESET_FRAMES) {
      kneeEma = null;
      torsoEma = null;
      prevKneeRaw = null;
    }
    if (gapStreak >= PEAK_RESET_AFTER_GAP) {
      if (peakKnee != null) {
        print('🟡 BULG: PEAK RESET after $gapStreak invalid frames');
      }
      peakKnee = null;
      validFrameCount = 0;
      sawStanding = false;
      stage = null;
    }
  }

  // ====== Main loop ======
  try {
    for (final frameFile in frameFiles) {
      frameIdx += 1;
      final double tSec = (frameIdx - 1) / fps;

      final inputImage = InputImage.fromFilePath(frameFile.path);
      List<Pose> poses;
      try {
        poses = await poseDetector.processImage(inputImage);
      } catch (e) {
        noteGap();
        addEmptyFrame(tSec);
        continue;
      }

      if (poses.isEmpty) {
        noteGap();
        addEmptyFrame(tSec);
        continue;
      }

      final Pose pose = poses.first;
      final lm = pose.landmarks;

      double fw = _bulgCachedW;
      double fh = _bulgCachedH;
      if (fw <= 0 || fh <= 0) {
        final dims = await _bulgProbeImageDims(frameFile.path);
        fw = dims.$1.toDouble();
        fh = dims.$2.toDouble();
        _bulgCachedW = fw;
        _bulgCachedH = fh;
      }

      // Active leg vote: ankle that's HIGHER on screen (smaller y) is the back leg
      // (raised on the bench), so the OTHER leg is active/front.
      if (activeLeg == null) {
        final lAnk = lm[PoseLandmarkType.leftAnkle];
        final rAnk = lm[PoseLandmarkType.rightAnkle];
        if (lAnk != null && rAnk != null) {
          final String vote = (lAnk.y < rAnk.y) ? 'right' : 'left';
          activeLegVotes.add(vote);
          if (activeLegVotes.length >= ACTIVE_LEG_VOTES_NEEDED) {
            final int rightCount =
                activeLegVotes.where((v) => v == 'right').length;
            activeLeg =
                (rightCount > activeLegVotes.length / 2) ? 'right' : 'left';
            print('🔵 BULG: activeLeg = $activeLeg');
          }
        }
      }
      if (activeLeg == null) {
        addEmptyFrame(tSec);
        continue;
      }

      final bool isRight = activeLeg == 'right';
      final PoseLandmarkType hipT =
          isRight ? PoseLandmarkType.rightHip : PoseLandmarkType.leftHip;
      final PoseLandmarkType kneeT =
          isRight ? PoseLandmarkType.rightKnee : PoseLandmarkType.leftKnee;
      final PoseLandmarkType ankleT =
          isRight ? PoseLandmarkType.rightAnkle : PoseLandmarkType.leftAnkle;
      final PoseLandmarkType shldrT = isRight
          ? PoseLandmarkType.rightShoulder
          : PoseLandmarkType.leftShoulder;

      final hipLm = lm[hipT];
      final kneeLm = lm[kneeT];
      final ankleLm = lm[ankleT];
      final shldrLm = lm[shldrT];
      final lAnkleLm = lm[PoseLandmarkType.leftAnkle];
      final rAnkleLm = lm[PoseLandmarkType.rightAnkle];

      if (hipLm == null ||
          kneeLm == null ||
          ankleLm == null ||
          shldrLm == null ||
          lAnkleLm == null ||
          rAnkleLm == null) {
        noteGap();
        addEmptyFrame(tSec);
        continue;
      }

      // Visibility: knee critical, hip/ankle looser
      final double visHip = hipLm.likelihood.clamp(0.0, 1.0).toDouble();
      final double visKnee = kneeLm.likelihood.clamp(0.0, 1.0).toDouble();
      final double visAnkle = ankleLm.likelihood.clamp(0.0, 1.0).toDouble();
      if (visKnee < KNEE_MIN_VIS ||
          visHip < HIP_ANK_MIN_VIS ||
          visAnkle < HIP_ANK_MIN_VIS) {
        noteGap();
        addEmptyFrame(tSec);
        continue;
      }

      // Full-body presence check — rejects UI/partial poses (e.g. an icon
      // detected as a person before the real video starts).
      final nose = lm[PoseLandmarkType.nose];
      final lShldr = lm[PoseLandmarkType.leftShoulder];
      final rShldr = lm[PoseLandmarkType.rightShoulder];
      final lHip = lm[PoseLandmarkType.leftHip];
      final rHip = lm[PoseLandmarkType.rightHip];
      final lKnee = lm[PoseLandmarkType.leftKnee];
      final rKnee = lm[PoseLandmarkType.rightKnee];

      bool fullBodyOk = nose != null &&
          lShldr != null &&
          rShldr != null &&
          lHip != null &&
          rHip != null &&
          lKnee != null &&
          rKnee != null &&
          lAnkleLm != null &&
          rAnkleLm != null;

      if (fullBodyOk) {
        final List<double> allVis = [
          nose.likelihood,
          lShldr.likelihood,
          rShldr.likelihood,
          lHip.likelihood,
          rHip.likelihood,
          lKnee.likelihood,
          rKnee.likelihood,
          lAnkleLm.likelihood,
          rAnkleLm.likelihood,
        ];
        for (final v in allVis) {
          if (v < FULL_BODY_MIN_VIS) {
            fullBodyOk = false;
            break;
          }
        }
      }

      if (fullBodyOk) {
        final double headY = nose!.y;
        final double lowestAnkleY = math.max(lAnkleLm!.y, rAnkleLm!.y);
        final double bodySpan = (lowestAnkleY - headY).abs();
        if (bodySpan < fh * MIN_BODY_SPAN_RATIO) {
          fullBodyOk = false;
        }
        final double avgHipY = (lHip!.y + rHip!.y) / 2.0;
        if (!(headY < avgHipY && avgHipY < lowestAnkleY)) {
          fullBodyOk = false;
        }
      }

      if (!fullBodyOk) {
        noteGap();
        addEmptyFrame(tSec);
        continue;
      }

      final List<List<double>> normLandmarks = [];
      for (final t in LM_ORDER) {
        final plm = lm[t];
        if (plm == null) {
          normLandmarks.add([0.0, 0.0, 0.0]);
        } else {
          final double vis = (plm.likelihood).clamp(0.0, 1.0).toDouble();
          normLandmarks.add([
            (plm.x / fw).clamp(0.0, 1.0).toDouble(),
            (plm.y / fh).clamp(0.0, 1.0).toDouble(),
            vis,
          ]);
        }
      }

      final List<double> hipPx = [hipLm.x, hipLm.y];
      final List<double> shldrPx = [shldrLm.x, shldrLm.y];

      // min(L_knee, R_knee) — swap-invariant. The active (front) leg is
      // always the more-bent one, so its angle is the smaller of the two.
      final lHipLm = lm[PoseLandmarkType.leftHip];
      final lKneeLm = lm[PoseLandmarkType.leftKnee];
      final rHipLm = lm[PoseLandmarkType.rightHip];
      final rKneeLm = lm[PoseLandmarkType.rightKnee];

      double activeKneeAngleRaw = 999.0;
      if (lHipLm != null &&
          lKneeLm != null &&
          lAnkleLm != null &&
          lHipLm.likelihood >= HIP_ANK_MIN_VIS &&
          lKneeLm.likelihood >= KNEE_MIN_VIS &&
          lAnkleLm.likelihood >= HIP_ANK_MIN_VIS) {
        final double L = calcAngle([lHipLm.x, lHipLm.y], [lKneeLm.x, lKneeLm.y],
            [lAnkleLm.x, lAnkleLm.y]);
        if (L >= KNEE_HARD_MIN &&
            L <= KNEE_HARD_MAX &&
            L < activeKneeAngleRaw) {
          activeKneeAngleRaw = L;
        }
      }
      if (rHipLm != null &&
          rKneeLm != null &&
          rAnkleLm != null &&
          rHipLm.likelihood >= HIP_ANK_MIN_VIS &&
          rKneeLm.likelihood >= KNEE_MIN_VIS &&
          rAnkleLm.likelihood >= HIP_ANK_MIN_VIS) {
        final double R = calcAngle([rHipLm.x, rHipLm.y], [rKneeLm.x, rKneeLm.y],
            [rAnkleLm.x, rAnkleLm.y]);
        if (R >= KNEE_HARD_MIN &&
            R <= KNEE_HARD_MAX &&
            R < activeKneeAngleRaw) {
          activeKneeAngleRaw = R;
        }
      }
      if (activeKneeAngleRaw >= 900.0) {
        noteGap();
        addEmptyFrame(tSec);
        continue;
      }
      final double kneeAngleRaw = activeKneeAngleRaw;

      // Torso angle from vertical: 0° = upright, 90° = horizontal.
      final double torsoFromVerticalRaw = (math.atan2(
                  (shldrPx[0] - hipPx[0]).abs(),
                  (hipPx[1] - shldrPx[1]).abs()) *
              180.0 /
              math.pi)
          .abs();

      if (kneeAngleRaw < KNEE_HARD_MIN || kneeAngleRaw > KNEE_HARD_MAX) {
        noteGap();
        addEmptyFrame(tSec);
        continue;
      }

      // Reject jumps even across short gaps. Allowed jump scales with
      // gap length so real fast motion isn't rejected, but ML Kit
      // confusion (110°+ flips) still gets caught.
      if (prevKneeRaw != null) {
        final double jump = (kneeAngleRaw - prevKneeRaw!).abs();
        final double allowedJump =
            RAW_JUMP_REJECT + 15.0 * gapStreak.clamp(0, 4).toDouble();
        if (jump > allowedJump) {
          noteGap();
          addEmptyFrame(tSec);
          continue;
        }
      }

      gapStreak = 0;
      prevKneeRaw = kneeAngleRaw;
      validFrameCount += 1;

      // Confidence-weighted EMA: trust low-vis frames less.
      double effectiveAlpha = EMA_ALPHA;
      if (visKnee < 0.7) {
        effectiveAlpha = EMA_ALPHA * (visKnee / 0.7);
      }

      if (kneeEma == null) {
        kneeEma = kneeAngleRaw;
        torsoEma = torsoFromVerticalRaw;
      } else {
        kneeEma =
            effectiveAlpha * kneeAngleRaw + (1 - effectiveAlpha) * kneeEma!;
        torsoEma = effectiveAlpha * torsoFromVerticalRaw +
            (1 - effectiveAlpha) * torsoEma!;
      }
      final double kneeAngle = kneeEma!;
      final double torsoFromVertical = torsoEma!;

      if (validFrameCount >= PEAK_BUFFER_FOR_INIT) {
        if (peakKnee == null || kneeAngle > peakKnee!) {
          peakKnee = kneeAngle;
        }
      }

      final double kneeXNorm = kneeLm.x / fw;
      final double ankleXNorm = ankleLm.x / fw;
      final bool valgusOk = !(kneeXNorm < ankleXNorm - VALGUS_X_TOL);
      final bool kneeOverToeOk =
          (kneeXNorm - ankleXNorm).abs() < KNEE_OVER_TOE_TOL;

      if (validFrameCount < PEAK_BUFFER_FOR_INIT || peakKnee == null) {
        frameTelemetry.add({
          't': tSec,
          'reps': counter,
          'depth': 0.0,
          'metric_label': 'DEPTH',
          'metric_value': 0.0,
          'feedback': null,
          'rep_just_finished': null,
          'landmarks': normLandmarks,
        });
        kneeAngleByFrame.add(kneeAngle);
        continue;
      }

      final double downThresh = peakKnee! - DOWN_DELTA_FROM_PEAK;
      final double upThresh = peakKnee! - UP_DELTA_FROM_PEAK;

      if (!sawStanding &&
          stage != 'down' &&
          kneeAngle >= peakKnee! - SAW_STANDING_DELTA) {
        sawStanding = true;
      }

      // Stage tracking + form-error accumulation during descent
      if (kneeAngle < downThresh) {
        if (stage != 'down') {
          stage = 'down';
          torsoBadFrames = 0;
          valgusBadFrames = 0;
          kneeOverToeBadFrames = 0;
          repTorsoBadFramesAccum = 0;
          repValgusBadFramesAccum = 0;
          repKneeOverToeBadFramesAccum = 0;
        }
        if (torsoFromVertical > TORSO_FROM_VERTICAL_BAD) {
          torsoBadFrames += 1;
          repTorsoBadFramesAccum += 1;
        } else {
          torsoBadFrames = 0;
        }
        if (!valgusOk) {
          valgusBadFrames += 1;
          repValgusBadFramesAccum += 1;
        } else {
          valgusBadFrames = 0;
        }
        if (!kneeOverToeOk) {
          kneeOverToeBadFrames += 1;
          repKneeOverToeBadFramesAccum += 1;
        } else {
          kneeOverToeBadFrames = 0;
        }
      } else if (kneeAngle > upThresh) {
        if (stage == 'down') {
          stage = 'up';
        }
        torsoBadFrames = 0;
        valgusBadFrames = 0;
        kneeOverToeBadFrames = 0;
      }

      // ====== Local-minima rep detection ======
      kneeSamples.add([tSec, kneeAngle]);
      final double cutoffT = tSec - (LOOKBACK_WINDOW_SEC + 1.0);
      while (kneeSamples.isNotEmpty && kneeSamples.first[0] < cutoffT) {
        kneeSamples.removeAt(0);
      }

      if (kneeSamples.length >= 3) {
        for (int i = 1; i < kneeSamples.length - 1; i++) {
          final double tCand = kneeSamples[i][0];
          final double aCand = kneeSamples[i][1];

          if (tCand <= lastRepTSec) continue;
          if (tCand - lastRepTSec < MIN_REP_GAP_SEC) continue;

          final double aPrev = kneeSamples[i - 1][1];
          final double aNext = kneeSamples[i + 1][1];
          if (!(aCand < aPrev && aCand <= aNext)) continue;

          double peakBefore = -1;
          for (int j = i - 1; j >= 0; j--) {
            if (tCand - kneeSamples[j][0] > LOOKBACK_WINDOW_SEC) break;
            if (kneeSamples[j][1] > peakBefore) peakBefore = kneeSamples[j][1];
          }
          if (peakBefore < 0) continue;
          if (peakBefore - aCand < DESCENT_DELTA_DEG) continue;

          double peakAfter = -1;
          for (int j = i + 1; j < kneeSamples.length; j++) {
            if (kneeSamples[j][0] - tCand > LOOKAHEAD_MAX_SEC) break;
            final double v = kneeSamples[j][1];
            if (v > peakAfter) {
              peakAfter = v;
            } else if (peakAfter > 0 && v < peakAfter - 5.0) {
              break;
            }
          }
          if (peakAfter < 0) continue;
          if (peakAfter - aCand < RISE_DELTA_DEG) continue;

          // Form evaluation
          final List<String> repFb = [];
          double repScore = 10.0;

          if (repTorsoBadFramesAccum >= TORSO_BAD_MIN_FRAMES_FOR_SCORE) {
            repFb.add('Keep your back straight');
            repScore -= 2.0;
          }
          if (repValgusBadFramesAccum >= VALGUS_BAD_MIN_FRAMES) {
            repFb.add('Avoid knee collapse');
            repScore -= 2.0;
          }
          if (repKneeOverToeBadFramesAccum >= KNEE_OVER_TOE_BAD_MIN_FRAMES) {
            repFb.add('Keep knee over toe');
            repScore -= 1.0;
          }

          final double denomForDepth =
              math.max(10.0, peakBefore - PERFECT_MIN_KNEE);
          final double depthPct =
              ((peakBefore - aCand) / denomForDepth).clamp(0.0, 1.0);
          if (depthPct < 0.6) {
            repFb.add('Go a bit deeper');
            repScore -= 1.5;
          } else if (depthPct < 0.8) {
            repFb.add('Go a bit deeper');
            repScore -= 0.5;
          }

          repScore = repScore.clamp(0.0, 10.0);
          final double scoreQ = (repScore * 2).round() / 2.0;
          final bool isGoodRep = scoreQ >= GOOD_REP_MIN_SCORE;

          for (final f in repFb) {
            sessionFeedback[f] = (sessionFeedback[f] ?? 0) + 1;
          }

          counter += 1;
          if (isGoodRep) {
            repJustFinished = 'good';
            goodReps += 1;
          } else {
            repJustFinished = 'bad';
            badReps += 1;
          }
          print(
              '🟢 BULG: REP #$counter score=$scoreQ ${isGoodRep ? "GOOD" : "BAD"}');

          final int bottomFrameForPulse = (tCand * fps).round() + 1;
          pulseEvents.add({
            'bottomFrameIdx': bottomFrameForPulse,
            'prevRepCount': counter - 1,
            'newRepCount': counter,
            'verdict': isGoodRep ? 'good' : 'bad',
            'fb': repFb,
          });

          repReports.add({
            'rep_index': repIndex,
            'score': scoreQ,
            'score_display': displayHalfStr(scoreQ),
            'feedback': repFb,
            'good': isGoodRep,
            'bottom_frame': bottomFrameForPulse,
            'bottom_t': tCand,
            'start_knee_angle': double.parse(peakBefore.toStringAsFixed(2)),
            'min_knee_angle': double.parse(aCand.toStringAsFixed(2)),
            'max_knee_angle': double.parse(peakAfter.toStringAsFixed(2)),
            'depth_pct': depthPct,
          });

          repTorsoBadFramesAccum = 0;
          repValgusBadFramesAccum = 0;
          repKneeOverToeBadFramesAccum = 0;
          repIndex += 1;
          lastRepTSec = tCand;
          lastDepthForUi = depthPct;

          while (kneeSamples.isNotEmpty && kneeSamples.first[0] <= tCand) {
            kneeSamples.removeAt(0);
          }

          break;
        }
      }

      // Depth gauge — 70° of knee bend = 100% on the gauge
      double depthLive = lastDepthForUi;
      if (peakKnee != null) {
        const double DEPTH_RANGE = 70.0;
        depthLive = ((peakKnee! - kneeAngleRaw) / DEPTH_RANGE).clamp(0.0, 1.0);
      }

      // Real-time feedback (uses live counters, not the stricter rep-verdict ones)
      String? liveMsg;
      if (stage == 'down') {
        final List<String> msgs = [];
        if (torsoBadFrames >= TORSO_BAD_MIN_FRAMES_FOR_LIVE) {
          msgs.add('Keep your back straight');
        }
        if (valgusBadFrames >= VALGUS_BAD_MIN_FRAMES) {
          msgs.add('Avoid knee collapse');
        }
        if (kneeOverToeBadFrames >= KNEE_OVER_TOE_BAD_MIN_FRAMES) {
          msgs.add('Keep knee over toe');
        }
        if (msgs.isNotEmpty) liveMsg = msgs.first;
      }
      if (liveMsg != null) {
        if (liveMsg != rtFbMsg) {
          rtFbMsg = liveMsg;
          rtFbHold = RT_FB_HOLD_FRAMES;
        } else {
          rtFbHold = math.max(rtFbHold, RT_FB_HOLD_FRAMES);
        }
      } else {
        if (rtFbHold > 0) rtFbHold -= 1;
        if (rtFbHold == 0) rtFbMsg = null;
      }

      frameTelemetry.add({
        't': tSec,
        'reps': counter,
        'depth': depthLive,
        'metric_label': 'DEPTH',
        'metric_value': depthLive,
        'feedback': (rtFbHold > 0 && rtFbMsg != null) ? rtFbMsg : null,
        'rep_just_finished': repJustFinished,
        'landmarks': normLandmarks,
      });
      kneeAngleByFrame.add(kneeAngle);
      repJustFinished = null;
    }

    print('🔵 BULG: loop done. counter=$counter, frames=$frameIdx');

    // ====== Post-process: place rep markers at the actual visual peak ======
    //
    // The detection loop fires reps shortly after the bottom (as soon as
    // RISE_DELTA_DEG of rise is confirmed), which is mid-ascent — not the
    // visual peak. To place the on-screen flash correctly, we scan the
    // actual frame trace between each pair of consecutive bottoms and find
    // where the knee was most extended. That's the visual peak.
    //
    // The search is bounded only by the next bottom: the peak is GUARANTEED
    // to be in this range because the user must be at the top before going
    // back down. We stop the scan early when knee descends ≥STOP_DESCENT_DEG
    // from the running max (passed the peak), and skip no-pose frames.

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

      // Bottom knee for the rise-from-bottom check.
      double bottomKnee = 0.0;
      if (bottomIdx < kneeAngleByFrame.length &&
          kneeAngleByFrame[bottomIdx] > 0) {
        bottomKnee = kneeAngleByFrame[bottomIdx];
      } else {
        for (int d = 1; d <= 3; d++) {
          if (bottomIdx - d >= 0 && kneeAngleByFrame[bottomIdx - d] > 0) {
            bottomKnee = kneeAngleByFrame[bottomIdx - d];
            break;
          }
          if (bottomIdx + d < kneeAngleByFrame.length &&
              kneeAngleByFrame[bottomIdx + d] > 0) {
            bottomKnee = kneeAngleByFrame[bottomIdx + d];
            break;
          }
        }
      }

      // Find max knee in [bottomIdx+1, nextBottomIdx). Stop on clear descent.
      int peakIdx = -1;
      double bestKnee = -1.0;
      for (int i = bottomIdx + 1;
          i < nextBottomIdx && i < kneeAngleByFrame.length;
          i++) {
        final double k = kneeAngleByFrame[i];
        if (k <= 0.0) continue;
        if (bottomKnee > 0 && (k - bottomKnee) < MIN_PEAK_RISE_FROM_BOTTOM)
          continue;
        if (k > bestKnee) {
          bestKnee = k;
          peakIdx = i;
        } else if (bestKnee > 0 && (bestKnee - k) >= STOP_DESCENT_DEG) {
          break;
        }
      }

      // Fallback: midpoint between bottoms when the window had no usable frames.
      if (peakIdx < 0) {
        peakIdx = bottomIdx + ((nextBottomIdx - bottomIdx) ~/ 2);
        if (peakIdx <= bottomIdx) peakIdx = bottomIdx + 1;
        if (peakIdx >= frameTelemetry.length) {
          peakIdx = frameTelemetry.length - 1;
        }
      }

      if (peakIdx <= bottomIdx) continue;

      // Flash duration: 40% of gap to next rep, capped 0.10–0.35s.
      // The cap keeps the flash from bleeding into the next descent.
      double flashDurationSec;
      if (e + 1 < pulseEvents.length) {
        final int gapFrames = nextBottomIdx - peakIdx;
        final double gapSec = gapFrames / fps;
        flashDurationSec = (gapSec * 0.4).clamp(0.10, 0.35);
      } else {
        flashDurationSec = 0.35;
      }
      final int flashFrames = math.max(1, (flashDurationSec * fps).round());

      // Counter rewrite: tick exactly at peakIdx so the counter and the
      // skeleton flash transition on the same telemetry frame.
      final int prevRC = (ev['prevRepCount'] as int?) ?? 0;
      final int newRC = (ev['newRepCount'] as int?) ?? (prevRC + 1);
      for (int i = bottomIdx; i < peakIdx; i++) {
        frameTelemetry[i]['reps'] = prevRC;
      }
      for (int i = peakIdx;
          i < nextBottomIdx && i < frameTelemetry.length;
          i++) {
        frameTelemetry[i]['reps'] = newRC;
      }

      frameTelemetry[peakIdx]['rep_just_finished'] = ev['verdict'] ?? 'good';
      frameTelemetry[peakIdx]['flash_duration_sec'] = flashDurationSec;
      frameTelemetry[peakIdx]['flash_frames'] = flashFrames;

      // Bad-rep feedback overlay during descent + bottom.
      final List<String> repFb =
          (ev['fb'] as List?)?.cast<String>() ?? <String>[];
      if (repFb.isNotEmpty && (ev['verdict'] ?? 'good') == 'bad') {
        final String fbStr = repFb.join('\n');
        final int fbStart = math.max(0, bottomIdx - (0.4 * fps).round());
        final int fbEnd = math.min(
            frameTelemetry.length - 1, bottomIdx + (0.6 * fps).round());
        for (int i = fbStart; i <= fbEnd; i++) {
          frameTelemetry[i]['feedback'] = fbStr;
        }
      }
    }
  } catch (e, stack) {
    print('🔴 BULG: EXCEPTION = $e');
    print('🔴 BULG: STACK = $stack');
  } finally {
    await poseDetector.close();
    try {
      framesDir.deleteSync(recursive: true);
    } catch (_) {}
  }

  double avg = 0.0;
  if (repReports.isNotEmpty) {
    double sum = 0;
    for (final r in repReports) {
      sum += (r['score'] as num).toDouble();
    }
    avg = sum / repReports.length;
  }
  if (avg.isNaN || avg.isInfinite) avg = 0.0;
  final double techniqueScore =
      double.parse((((avg * 2).round() / 2.0)).toStringAsFixed(2));

  final List<String> feedbackList;
  if (counter == 0) {
    feedbackList = <String>[
      "Couldn't analyze this video — make sure your full body is visible from the side and that you complete at least one rep."
    ];
  } else if (sessionFeedback.isNotEmpty) {
    feedbackList = sessionFeedback.keys.toList();
  } else {
    feedbackList = <String>['Great form! Keep it up 💪'];
  }

  // Session tip — only mentions issues we actually measure.
  String? sessionTip;
  if (counter == 0) {
    sessionTip = null;
  } else if ((sessionFeedback['Avoid knee collapse'] ?? 0) >= 2) {
    sessionTip = 'Track your knee over your toes';
  } else if ((sessionFeedback['Keep your back straight'] ?? 0) >= 2) {
    sessionTip = 'Brace your core and keep chest up';
  } else if ((sessionFeedback['Go a bit deeper'] ?? 0) >= 2) {
    sessionTip = 'Aim for thigh parallel with the floor';
  } else if ((sessionFeedback['Keep knee over toe'] ?? 0) >= 2) {
    sessionTip = 'Front shin should stay roughly vertical';
  } else {
    sessionTip = BULGARIAN_TIPS[1];
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
    'form_tip': sessionTip,
    'tips': sessionTip != null ? <String>[sessionTip] : <String>[],
    'reps': repReports,
    'video_path': fileUri,
    'analyzed_fps': fps,
    'frame_count': frameIdx,
    'active_leg': activeLeg ?? 'unknown',
    'peak_knee_observed': peakKnee,
    '_source_video_uri': fileUri,
    '_frame_telemetry': frameTelemetry,
  };
}

double _bulgCachedW = -1;
double _bulgCachedH = -1;

Future<(int, int)> _bulgProbeImageDims(String path) async {
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
