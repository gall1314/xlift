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
// One Euro Filter for landmark smoothing.
// ============================================================================
class _LowPass {
  double? _last;
  double? get lastFiltered => _last;
  bool get hasLast => _last != null;
  double filter(double x, double alpha) {
    if (_last == null) {
      _last = x;
      return x;
    }
    _last = alpha * x + (1.0 - alpha) * _last!;
    return _last!;
  }

  void reset() {
    _last = null;
  }
}

class OneEuroFilter {
  OneEuroFilter({this.minCutoff = 1.0, this.beta = 0.05, this.dCutoff = 1.0});
  final double minCutoff;
  final double beta;
  final double dCutoff;
  final _LowPass _xFilter = _LowPass();
  final _LowPass _dxFilter = _LowPass();
  double? _lastTime;

  static double _alpha(double cutoff, double dt) {
    final double tau = 1.0 / (2.0 * math.pi * cutoff);
    return 1.0 / (1.0 + tau / dt);
  }

  double filter(double x, double tSec) {
    double dt = 1.0 / 30.0;
    if (_lastTime != null) {
      final double diff = tSec - _lastTime!;
      if (diff > 0) dt = diff;
    }
    _lastTime = tSec;
    final double dxRaw =
        _xFilter.hasLast ? (x - _xFilter.lastFiltered!) / dt : 0.0;
    final double dxFiltered = _dxFilter.filter(dxRaw, _alpha(dCutoff, dt));
    final double cutoff = minCutoff + beta * dxFiltered.abs();
    return _xFilter.filter(x, _alpha(cutoff, dt));
  }
}

class _OneEuroLandmark {
  _OneEuroLandmark({double minCutoff = 1.0, double beta = 0.05})
      : _fx = OneEuroFilter(minCutoff: minCutoff, beta: beta),
        _fy = OneEuroFilter(minCutoff: minCutoff, beta: beta);
  final OneEuroFilter _fx;
  final OneEuroFilter _fy;
  List<double> filter(double x, double y, double vis, double tSec) {
    if (vis < 0.3) return [x, y, vis];
    return [_fx.filter(x, tSec), _fy.filter(y, tSec), vis];
  }
}

class _PoseSmoother {
  _PoseSmoother({double minCutoff = 1.0, double beta = 0.05, int n = 33})
      : _filters = List<_OneEuroLandmark>.generate(
            n, (_) => _OneEuroLandmark(minCutoff: minCutoff, beta: beta));
  final List<_OneEuroLandmark> _filters;
  List<List<double>> smooth(List<List<double>> raw, double tSec) {
    final out = <List<double>>[];
    for (int i = 0; i < raw.length; i++) {
      final lm = raw[i];
      if (i >= _filters.length || lm.length < 3) {
        out.add(lm);
        continue;
      }
      out.add(_filters[i].filter(lm[0], lm[1], lm[2], tSec));
    }
    return out;
  }
}

// ============================================================================
// Romanian Deadlift analyzer — REBUILT for ML Kit's actual behavior.
//
// What was wrong with the previous version:
//  - Composite signal (5 weighted components) was too sensitive to ML Kit
//    losing the user's far side. When visibility ratio dropped, weights
//    shifted dramatically, signal jumped between high/low values, and the
//    state machine counted these jumps as "reps". 14 reps in a 7-rep video.
//  - The Python composite was designed for mediapipe's 3D normalized
//    landmarks where torso_3d is independent. ML Kit doesn't provide that.
//  - The skeleton looked broken in many frames (one side missing, arm
//    welded to leg) because ML Kit was guessing under occlusion.
//
// What this version does:
//  1. SHAPE VALIDATION: every frame must look like a "person doing RDL".
//     If it doesn't (e.g. arm collapses onto leg → triangle becomes a line,
//     or hip-knee-ankle ratio is wrong), reject the frame.
//  2. SINGLE STABLE SIGNAL: torso angle from vertical (shoulder-hip vs up).
//     0° = standing, ~85° = full RDL bottom. This is THE definition of an
//     RDL hinge. No 5-component composite, no adaptive weights.
//  3. STRONG MIN-DURATION: a real rep is at least 1.4 seconds. Period.
//  4. SLOW STATE MACHINE: requires sustained transitions (4 frames in
//     each direction before state can change), not single-frame jitter.
//  5. EVAL still mirrors Python (knee bend, depth, torso overextend).
// ============================================================================

const Map<String, int> _FB_SEVERITY = {
  'Go deeper - hinge more at the hips': 3,
  'Bend your knees a bit more': 3,
  'You\'re going too deep - hinge a bit less': 3,
};
const Map<String, String> _FB_CATEGORY = {
  'Go deeper - hinge more at the hips': 'depth',
  'Bend your knees a bit more': 'knees',
  'You\'re going too deep - hinge a bit less': 'back',
};

// Eval thresholds (mirror Python intent)
const double _GOOD_DEPTH_TORSO_ANGLE =
    55.0; // torso angle at bottom must reach this
const double _KNEE_TOO_STRAIGHT =
    160.0; // [v31] tightened further. The borderline reps in v30 still passed in some takes; nudged both thresholds inward by 2 more units.
// [v30 TIGHTENED-THRESHOLDS] / [v31 TIGHTENED-AGAIN]
// After v29 caught ~50% of stiff-leg reps across the same set (very
// similar form, but ML Kit's per-frame measurements oscillated around
// the threshold), moved both thresholds further from the noise center.
// v30 (165→162, 18→21) caught most but a few borderline reps still
// slipped through. v31 (162→160, 21→23) adds 2 more units of margin.
const double _KNEE_MIN_RANGE = 23.0;
// [v32 TOO-DEEP-CHECK] Replaces _TORSO_OVEREXTEND (was 95.0, penalty -1.0,
// message "Your torso is going too far forward").
//
// Real-video evidence (WhatsApp 15/7 16:27): the lifter's torso passes
// HORIZONTAL at the bottom of every rep — shoulders drop below hip level,
// hands nearly touch the floor. That's >90° from vertical. A proper RDL
// stops around parallel; past that the hamstrings are done and the extra
// range comes from lumbar flexion (load shifts onto the lower back).
//
// Why 95° never fired: the torso-angle EMA (alpha 0.5) lags the raw
// signal during motion, so a true ~95° bottom reads as ~88-92° smoothed.
// The check was effectively unreachable for anything but extreme cases.
//
// [v33 TOO-DEEP-V2] 88 → 82, plus a direct geometric trigger.
// v32's 88° threshold only caught 1 of the too-deep reps in the test
// video. Root cause: hipOrderOk in shape validation rejects every frame
// where the shoulder drops to/below hip level (torso ≥ ~90° true), so
// the deepest frames never update the peak — the smoothed peak
// SATURATES in the mid-80s no matter how far past horizontal the user
// actually goes. Fixes:
//  (1) Threshold lowered to 82 (smoothed). An RDL should end where the
//      hamstrings end, typically 60-80° true; approaching parallel is
//      already past the useful range for almost everyone. A deep-but-
//      legit RDL (~75° true) reads ~70-76 smoothed — safely below 82.
//  (2) rPastHorizFrames: counts frames during 'rising' where the
//      shoulder is AT or BELOW hip height (torso ≥ 90° true). Detected
//      inside the shape-validation reject branch — exactly the frames
//      that used to be silently discarded — with sanity guards so
//      broken skeletons don't count. 2+ such frames flag the rep as
//      too deep regardless of the smoothed angle. Immune to EMA lag
//      and to the saturation ceiling.
// Penalty -2.0 so a too-deep rep scores 8.0 and counts as a bad rep.
//
// The eval check uses max(peak_torso, max_torso): peakTorsoAngle is
// tracked on ALL shape-valid frames (including poseReliable=false ones,
// which are common at the deep bottom), so the check can't be dodged by
// ML Kit losing upper-body confidence at exactly the wrong moment.
const double _TORSO_TOO_DEEP = 85.0;
// [v33] Frames with shoulder at/below hip level needed to flag too-deep
// via the geometric trigger. [CAL-1 LOOSENED 2→3] 3 frames = 150ms at 20fps — a real
// past-horizontal bottom spends far longer there; a single spurious
// inversion frame from ML Kit noise does not.
const int _PAST_HORIZ_MIN_FRAMES = 3;
// [v26 ROLLBACK-V23] The v23 "form check" additions (spine rounding,
// excessive knee bend, bar-to-floor) were all removed in v25 and v26
// after they false-positively flagged perfectly fine RDLs. The
// underlying issue, honestly stated, is that ML Kit gives us about a
// dozen body landmarks at modest precision — not enough to make
// nuanced judgments about lifting form. We can reliably measure
//   * how deep the hinge went (torso angle)
//   * how straight or bent the knee was (knee angle)
//   * whether the torso went past neutral (overextension)
// All three are coarse but objective. Anything subtler — spine
// curvature, "is this RDL or a hybrid", bar-relative-to-shin —
// requires either more landmarks, depth data, or domain judgment
// that doesn't fit a sharp threshold. The cost of false positives
// (user stops trusting the analyzer) is bigger than the benefit of
// catching the rare real issue. So we stay conservative.
const double _MIN_SCORE = 4.0;
const double _MAX_SCORE = 10.0;

Future<dynamic> analyzeRomanianDeadliftVideoAction(
  FFUploadedFile videoFile,
  double? targetFps,
) async {
  // [v16 FPS-MATCH-PUSHUP] Default fps raised from 10 → 20 to match the
  // pushup analyzer. At 10fps each pose detection is ~100ms apart, which
  // makes the rendered skeleton look choppier than the pushup widget
  // (which runs at 20fps = ~50ms apart). The detection quality of ML
  // Kit per frame is identical — it's the temporal sampling rate that
  // makes the visible skeleton look "more accurate" in the pushup videos.
  // Raising fps roughly doubles per-video processing time but produces
  // visibly smoother skeleton motion. Min-clamp also raised to 4.0 to
  // match.
  final double fps = (targetFps ?? 20.0).clamp(4.0, 30.0);
  final double dtSec = 1.0 / fps;
  // [v16 FB-HOLD-MATCH-PUSHUP] Feedback hold raised from 0.7s → 1.5s to
  // match the pushup analyzer. Same reasoning as their v4 comment:
  // for fast cadences, 0.7s could get overwritten before the eye
  // registers the message. 1.5s is short enough to still feel responsive
  // and long enough to be readable.
  final int RT_FB_HOLD_FRAMES = math.max(2, (1.5 / dtSec).round());

  // Rep timing requirements - hard limits
  final int MIN_REP_DURATION_FRAMES = math.max(10, (1.4 * fps).round()); // 1.4s
  // [v21 BACK-TO-BACK-REPS] Was 1.0s. The 1-second gate between reps
  // was blocking the state machine from entering 'rising' until 1s
  // after the previous rep was counted — but in continuous RDL sets
  // users start the next descent within ~0.4s of finishing the
  // previous one. The state then transitioned LATE, mid-descent,
  // and measured rep duration from that moment instead of from the
  // actual start. With a 3-second real rep, the measured duration
  // came out to ~0.6s (below the 1.4s minimum) and the rep got
  // rejected. Dropped to 0.3s: now the state can transition almost
  // as soon as the user starts descending, capturing the full rep.
  // MIN_REP_DURATION_FRAMES (1.4s) is still the primary protection
  // against phantom reps from torso jitter.
  final int MIN_FRAMES_BETWEEN_REPS = math.max(3, (0.3 * fps).round()); // 0.3s
  final int MAX_REP_DURATION_FRAMES = math.max(40, (8.0 * fps).round()); // 8s
  final int STATE_TRANSITION_FRAMES = math.max(3, (0.3 * fps).round()); // 0.3s

  _rdlCachedW = -1;
  _rdlCachedH = -1;

  // ---- helpers ----
  double angleDeg(List<double> a, List<double> b, List<double> c) {
    final ba0 = a[0] - b[0], ba1 = a[1] - b[1];
    final bc0 = c[0] - b[0], bc1 = c[1] - b[1];
    final nrm =
        math.sqrt(ba0 * ba0 + ba1 * ba1) * math.sqrt(bc0 * bc0 + bc1 * bc1) +
            1e-9;
    final cosVal = ((ba0 * bc0 + ba1 * bc1) / nrm).clamp(-1.0, 1.0);
    return math.acos(cosVal) * 180.0 / math.pi;
  }

  double torsoAngleVertical(List<double> hip, List<double> shoulder) {
    final v0 = shoulder[0] - hip[0], v1 = shoulder[1] - hip[1];
    final nrm = math.sqrt(v0 * v0 + v1 * v1) + 1e-9;
    final cosVal = ((v1 * -1) / nrm).clamp(-1.0, 1.0);
    return math.acos(cosVal) * 180.0 / math.pi;
  }

  String dispHalf(double x) {
    final double q = (x * 2).round() / 2.0;
    return ((q - q.round()).abs() < 1e-9)
        ? q.round().toString()
        : q.toStringAsFixed(1);
  }

  String sLabel(double s) {
    if (s >= 9.5) return 'Excellent';
    if (s >= 8.5) return 'Very good';
    if (s >= 7.0) return 'Good';
    if (s >= 5.5) return 'Fair';
    return 'Needs work';
  }

  Map<String, dynamic> errPay(String c, String d) => {
        'error': c,
        'detail': d,
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

  // ---- 0) save file ----
  if (videoFile.bytes == null || videoFile.bytes!.isEmpty) {
    return errPay('empty_upload', 'No bytes');
  }
  final Directory tmp = await getTemporaryDirectory();
  final String safe =
      (videoFile.name ?? 'upload.mp4').split('/').last.split('\\').last;
  final String videoPath =
      p.join(tmp.path, 'rdl_${DateTime.now().millisecondsSinceEpoch}_$safe');
  await File(videoPath).writeAsBytes(videoFile.bytes!, flush: true);

  // ---- 1) extract frames ----
  final Directory framesDir = Directory(
      p.join(tmp.path, 'rdl_f_${DateTime.now().millisecondsSinceEpoch}'));
  if (framesDir.existsSync()) framesDir.deleteSync(recursive: true);
  framesDir.createSync(recursive: true);
  final String fp = p.join(framesDir.path, 'f_%05d.jpg');
  final s1 = await FFmpegKit.execute(
      "-y -i \"$videoPath\" -vf \"fps=$fps,scale='min(1080,iw)':-2\" -q:v 2 \"$fp\"");
  if (!ReturnCode.isSuccess(await s1.getReturnCode())) {
    return errPay('ffmpeg_fail', 'Extract failed');
  }
  final List<File> frames = framesDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.jpg'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  if (frames.isEmpty) return errPay('no_frames', 'No frames');

  // ---- 2) ML Kit + smoother ----
  final pd = PoseDetector(
      options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream, model: PoseDetectionModel.accurate));
  final smoother = _PoseSmoother(minCutoff: 1.0, beta: 0.05);

  // ---- 3) state ----
  int repCount = 0, goodReps = 0, badReps = 0, frameIdx = 0;
  final List<Map<String, dynamic>> repReports = [];
  final List<double> allScores = [];
  final List<String> sessFb = [];
  final Map<String, String> sessFbByCat = {};

  // Calibration — adaptive, no warmup required. Starts with reasonable
  // defaults so reps can be detected from frame 1. Continuously tracks
  // the lowest sustained torso angle as the real standing baseline.
  double standingTorsoAngle =
      8.0; // initial guess — lowest seen will replace it
  double bottomTorsoAngle = 75.0; // adaptive
  double enterDescentAngle = 33.0; // = standing + 25°
  double exitRepAngle = 20.0; // = standing + 12°
  double lowestSustainedTorso = 999.0;

  // ============ [v18 UPRIGHT-CONFIRM-BEFORE-FIRST-REP] ============
  // Gate the very first rep on confirming the user has actually been
  // upright. Without this gate, a video that starts with the user
  // already in a deeply hinged position (e.g. they've already picked
  // up the bar and are setting up at the bottom of the lift) counts
  // the standing-up motion itself as a rep: the code sees torso angle
  // drop from high → low and the state machine confirms a
  // 'rising → falling → standing' transition. That's NOT a rep — a
  // real RDL rep starts from upright and goes DOWN first, not the
  // other way around.
  //
  // Symptom seen in the WhatsApp 6:26 PM video: the user starts the
  // recording already bent over the bar at ~70°, stands up, walks a
  // step, and only THEN starts doing real reps. The standing-up motion
  // was counted as "Rep 1" — the user (correctly) called this out as
  // "just walking" since by the time Reps:1 appeared on screen, he was
  // walking around mid-frame.
  //
  // Fix: track whether we've ever seen the user genuinely upright
  // (torso < ABS_UPRIGHT_THRESHOLD) for a sustained duration. Until
  // that's confirmed, the state machine cannot transition out of
  // 'standing' to start counting a rep. After confirmation (which
  // sticks for the rest of the video), reps count normally.
  //
  // This also incidentally protects against unrelated walking BEFORE
  // the exercise begins: walking with a slight forward lean (~15-25°)
  // is upright enough to satisfy the gate quickly, AND the existing
  // depth/duration gates downstream (peak >= 45° AND duration >= 1.4s)
  // already reject anything that's just walking — they only fire when
  // there's a real deep hinge.
  //
  // Why an absolute threshold (22°) and not "standing + 10°"?
  //   The adaptive standingTorsoAngle starts at 8° and only ratchets
  //   downward. If the user starts the video bent at 70°, the running
  //   lowest never goes below the initial 8° until they actually stand
  //   up. So "standing + 10°" would be 18° (already strict). Using an
  //   absolute 22° is simpler, robust to calibration order, and works
  //   for any human's natural upright posture.
  bool uprightConfirmed = false;
  int framesUpright = 0;
  // [v24 UPRIGHT-THRESHOLD-RELAXED] Was 22.0 — too strict. A user
  // starting the video in normal standing posture (looking down at the
  // bar, getting ready to lift) often has torso angle 22-30° from
  // vertical. That's NOT "in a rep", just casual stance. The 22°
  // threshold blocked uprightConfirmed from flipping, which blocked
  // the first rep from being counted.
  //
  // The original v18 bug we were protecting against was a user starting
  // the video ALREADY HINGED OVER THE BAR (~70° torso). That's still
  // firmly rejected by 35°. The new threshold protects the v18 case
  // while accepting normal pre-lift standing posture.
  const double ABS_UPRIGHT_THRESHOLD = 35.0;
  final int UPRIGHT_CONFIRM_FRAMES = math.max(5, (0.4 * fps).round());

  // ============ [v20 DISPLAY-STABILITY] ============
  // Two purely-cosmetic improvements that do NOT touch rep counting,
  // depth metric, or any of the state-machine logic. Both target the
  // visual smoothness of the skeleton overlay during the bottom of an
  // RDL where ML Kit's per-frame output is jittery.
  //
  // (a) SKELETON PERSISTENCE: when a frame is rejected by jump
  //     detection, shape validation, position lock, etc., emitEmpty
  //     used to send an empty landmark array — the skeleton blinked
  //     off for that frame. Now we keep showing the last good skeleton
  //     for up to STALE_HOLD_FRAMES (~100ms at 20fps). If the frame
  //     after is also bad, we still bail out and show nothing. This
  //     smooths single-frame dropouts (very common at the deep-hinge
  //     bottom) without ever showing seriously stale data.
  //
  //     SAFETY: this only affects the `landmarks` array sent to the
  //     widget for rendering. The internal state machine, accumulators,
  //     and rep-counting logic continue to skip the bad frame exactly
  //     as before. The widget gets a slightly-out-of-date skeleton for
  //     a moment; the analyzer's view of the user's motion is identical.
  //
  // (b) DOMINANT SIDE HYSTERESIS: the original code chose the
  //     dominant side (left/right) per-frame based on which side had
  //     higher total visibility. When the two sides are close in
  //     visibility (very common in a side-profile RDL where the camera
  //     sees both sides almost equally), this flipped every few frames.
  //     Each flip changed which landmarks were fed into torso/knee
  //     angle calculation, which jittered the smoothed angle, which
  //     made the on-screen depth percentage hop.
  //
  //     Fix: lock the dominant side on the first frame, and only
  //     switch when the OTHER side is at least SIDE_SWITCH_MARGIN
  //     (1.3x) more visible than the locked side for
  //     SIDE_SWITCH_FRAMES (3) consecutive frames. Single-frame
  //     "the right side won by 1%" no longer flips the choice.
  List<List<double>>? lastGoodDisplayLm;
  int staleHoldCount = 0;
  const int STALE_HOLD_FRAMES = 2;
  bool? lockedSideLeft; // null = not yet decided
  int sideSwitchVotes = 0;
  const int SIDE_SWITCH_FRAMES = 3;
  const double SIDE_SWITCH_MARGIN = 1.3;

  // State machine
  String state = 'standing'; // 'standing' | 'rising' | 'falling'
  int repStartFrame = -1;
  int lastRepEndFrame = -999;
  double peakTorsoAngle = 0.0;
  int peakFrameIdx = -1; // frame index when current peak occurred
  double currentSmoothedTorso = 0.0;
  double ascentMin = 999.0; // minimum torso seen between reps (the valley)
  // Hysteresis counters for state transitions
  int framesAboveEnter = 0;
  int framesBelowReturn = 0; // frames where torso is back near standing
  int framesAscending = 0; // frames where signal is decreasing during rising
  int fallingStartFrame =
      -1; // frame when 'falling' began (for pendingRep timeout)

  // Pending rep: filled when we detect the bottom (peak), but only counted
  // once the user has clearly returned toward upright.
  Map<String, dynamic>? pendingRep;

  // Per-rep accumulators
  double rMaxTorso = 0;
  double rMaxKnee = 0;
  double rMinKnee = 999;
  bool rBackIssue = false;
  double rBackAngle = 0.0;
  int rBadFrames = 0; // frames during this rep where pose was unreliable
  int rTotalFrames = 0; // total frames during this rep (good + bad)
  // [v33] Frames during this rep where the shoulder was at/below hip
  // level (torso at or past horizontal). Counted in the shape-validation
  // reject branch since hipOrderOk rejects exactly these frames.
  int rPastHorizFrames = 0;

  // ============ [v22 SEMANTIC-ENRICHMENT] ============
  // Multi-signal validation and confidence scoring. All ADDITIVE — does
  // NOT change the rep-counting logic that's already working. Adds:
  //   - hip displacement: how much the hip moved horizontally during the
  //     rep. A real RDL is DEFINED by hip going backward; if the user
  //     just bent at the waist without pushing hips back, this stays
  //     low. This is the strongest single discriminator between RDL
  //     and good-morning / front-bend.
  //   - tempo: descent time vs ascent time. Controlled reps have ~1:1
  //     ratio. Bouncing the bottom or dropping it = bad form.
  //   - symmetry: torso angle computed from left side vs right side
  //     should agree. If they don't, either the user is asymmetric or
  //     ML Kit is hallucinating one side.
  //   - confidence: combined score 0..1 from all signals above. Lets
  //     downstream UI distinguish "definitely a rep" from "probably a
  //     rep" — useful for showing the user which reps to trust.
  //   - stable standing baseline: median-based instead of running min.
  //     Less susceptible to a single noisy upright frame anchoring
  //     calibration too low.

  // Standing baseline of hip position relative to ankle, used to
  // compute hip displacement during reps. Initialized once we see
  // sustained upright frames; updated slowly via EMA.
  double standingHipXRel = 0.0;
  bool standingHipXRelInit = false;

  // Buffer for median-based standing torso calibration. Collect samples
  // when user is upright; once we have enough, the MEDIAN becomes a
  // more stable baseline than the running min.
  final List<double> standingTorsoSamples = [];
  final int STANDING_SAMPLE_LIMIT = 30; // ~1.5s at 20fps
  double medianStandingTorso = -1.0; // -1 = not yet established

  // Per-rep enriched metrics
  double rMaxHipDisp = 0.0;
  double rSymmetrySum = 0.0;
  int rSymmetryFrames = 0;
  int rDescentEndFrame = -1; // = peakFrameIdx, captured when rising→falling
  // ====================================================

  // Display
  double depthPct = 0;
  String? rtMsg;
  int rtHold = 0;
  String? repJust;

  // Jump rejection
  List<double>? lastValidMidHip;
  int recoveryCountdown = 0;
  const double JUMP_REJECT_HIP_FRAC = 0.18;
  const double LOW_CORE_VIS_THRESHOLD = 0.35;
  const int RECOVERY_FRAMES_AFTER_JUMP = 2;
  // [v19 DEEP-HINGE-VIS] Per-landmark visibility threshold for the
  // display layer. Anything below this gets zeroed in displayLm and the
  // widget skips drawing it. Dropped from 0.45 to 0.30 for the same
  // reason as the poseReliable threshold above: ML Kit assigns low
  // visibility (0.30-0.45 range) to individual joints during deep
  // hinges even when they're correctly positioned. At 0.45 the
  // skeleton looked dismembered at the bottom — shoulder, neck, or
  // head landmarks would vanish while hips and legs stayed visible.
  // At 0.30 the skeleton stays whole-looking during the lift bottom
  // and only truly hallucinated joints (vis < 0.30) get hidden.
  const double VIS_HIDE_THRESHOLD = 0.30;

  // Position lock — activated after first counted rep. Locks ONLY hip X/Y
  // (not body size). The user's hip stays in roughly the same area of the
  // frame even during a deep hinge, so a 25% radius is generous for the
  // user's natural movement but rejects ML Kit snapping to a bystander
  // who's typically 30%+ away in the frame.
  bool positionLocked = false;
  double lockedMidHipX = 0.5;
  double lockedMidHipY = 0.5;
  const double POSITION_LOCK_RADIUS = 0.25;
  // Rolling history of recent hip positions. Used as a pre-lock
  // protection: even before any rep is counted, a frame whose hip is
  // far from the recent median is treated as a person-snap.
  final List<double> hipHistoryX = [];
  final List<double> hipHistoryY = [];

  final List<Map<String, dynamic>> telemetry = [];

  const List<PoseLandmarkType> LM_O = [
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

  void emitEmpty(double t, int fi) {
    // [v20a] If a recent good skeleton exists and we haven't already
    // re-used it too many times, send it again instead of an empty
    // array. This smooths over single-frame ML Kit dropouts without
    // ever showing seriously stale data. The state machine still
    // skipped this frame — only the visual is repeated.
    List<List<double>> landmarks;
    bool wasStale = false;
    if (lastGoodDisplayLm != null && staleHoldCount < STALE_HOLD_FRAMES) {
      landmarks = lastGoodDisplayLm!;
      staleHoldCount += 1;
      wasStale = true;
    } else {
      landmarks = <List<double>>[];
    }
    telemetry.add({
      't': t,
      '_frame_idx': fi,
      'reps': repCount,
      'depth': depthPct,
      'metric_label': 'HINGE',
      'metric_value': depthPct,
      'feedback': (rtHold > 0) ? rtMsg : null,
      'rep_just_finished': repJust,
      'landmarks': landmarks,
      // Mark stale frames as reliable=true so the widget keeps drawing
      // them. They're known to be slightly out of date, but visually
      // far better than blinking the skeleton on/off.
      'pose_reliable': wasStale,
    });
    repJust = null;
    if (rtHold > 0) rtHold -= 1;
  }

  void resetPerRep() {
    rMaxTorso = 0;
    rMaxKnee = 0;
    rMinKnee = 999;
    rBackIssue = false;
    rBackAngle = 0.0;
    rBadFrames = 0;
    rTotalFrames = 0;
    rPastHorizFrames = 0; // [v33]
    peakTorsoAngle = 0.0;
    peakFrameIdx = -1;
    framesAscending = 0;
    // [v22] Clear enriched metrics too
    rMaxHipDisp = 0.0;
    rSymmetrySum = 0.0;
    rSymmetryFrames = 0;
    rDescentEndFrame = -1;
    // [v26] All v23 form-check tracking variables removed.
  }

  // [v32 EVAL-FROM-SNAPSHOT] evalRep now reads from the pendingRep
  // snapshot instead of the live accumulators. This fixes a latent bug:
  // when a rep was counted via the SECONDARY trigger (user drops into
  // the next rep without returning to full standing), resetPerRep()
  // ran BEFORE evalRep() — so the rep was evaluated against freshly
  // wiped accumulators. Symptoms: false "Go deeper" (rMaxTorso reset to
  // the new rep's entry angle, always < 55°) and false "Bend your knees"
  // (rMinKnee == rMaxKnee after reset → range check trivially fails) on
  // back-to-back reps. The snapshot in pendingRep was captured at peak
  // confirmation and is immune to the reset.
  Map<String, dynamic> evalRep(Map<String, dynamic> rep) {
    final fb = <String>[];
    double sc = _MAX_SCORE;
    final double snapMaxTorso = rep['max_torso'] as double;
    final double snapPeakTorso = rep['peak_torso'] as double;
    final double snapMinKnee = rep['min_knee'] as double;
    final double snapMaxKnee = rep['max_knee'] as double;
    // Deepest torso angle seen in this rep. peak_torso is tracked on all
    // shape-valid frames (even poseReliable=false), max_torso only on
    // reliable ones — take the max so deep bottoms with low ML Kit
    // confidence still register.
    final double deepest = math.max(snapMaxTorso, snapPeakTorso);
    if (deepest < _GOOD_DEPTH_TORSO_ANGLE) {
      fb.add('Go deeper - hinge more at the hips');
      sc -= 2.0;
    }
    // [v27 KNEE-CHECK-FIX] / [v28 KNEE-RANGE-CHECK]
    // Two independent signals — either fires the flag:
    //  1. minKnee > _KNEE_TOO_STRAIGHT: even at the deepest moment of
    //     the rep, knee was essentially straight. Catches obvious cases
    //     when ML Kit can reliably measure it.
    //  2. (maxKnee - minKnee) < _KNEE_MIN_RANGE: knee barely moved
    //     during the rep. Robust to ML Kit measurement bias (only the
    //     within-rep variation matters, not absolute calibration).
    //     This is the more important check — it catches stiff-leg
    //     deadlifts where ML Kit's per-frame measurement might be
    //     slightly below the absolute threshold but the knee clearly
    //     wasn't doing the work an RDL requires.
    bool kneeTooStraight = false;
    if (snapMinKnee < 998.0 && snapMaxKnee > 0.0) {
      if (snapMinKnee > _KNEE_TOO_STRAIGHT) kneeTooStraight = true;
      if ((snapMaxKnee - snapMinKnee) < _KNEE_MIN_RANGE) kneeTooStraight = true;
    }
    if (kneeTooStraight) {
      fb.add('Bend your knees a bit more');
      sc -= 1.5;
    }
    // [v32 TOO-DEEP-CHECK] / [v33 TOO-DEEP-V2] Torso at/past ~parallel =
    // excessive range. The hamstrings can't lengthen further, so the
    // extra motion comes from lumbar flexion — load shifts onto the
    // lower back. Two triggers, either fires:
    //  1. deepest > 85 (smoothed) [CAL-1 LOOSENED 82→85] — approaching parallel.
    //  2. past_horiz_frames ≥ 2 — direct geometric evidence the
    //     shoulder dropped to/below hip level (≥ 90° true), immune to
    //     EMA lag and to the shape-validation saturation ceiling.
    // Mutually exclusive with the "Go deeper" check above (85 > 55).
    final int snapPastHoriz = (rep['past_horiz_frames'] as int?) ?? 0;
    if (deepest > _TORSO_TOO_DEEP || snapPastHoriz >= _PAST_HORIZ_MIN_FRAMES) {
      fb.add('You\'re going too deep - hinge a bit less');
      sc -= 2.0;
    }
    // [v26] All v23 form checks removed — see comment near constants.
    return {'score': sc.clamp(_MIN_SCORE, _MAX_SCORE), 'feedback': fb};
  }

  String pickStrong(List<String> fbs) {
    String b = '';
    int bs = -1;
    for (final f in fbs) {
      final s = _FB_SEVERITY[f] ?? 1;
      if (s > bs) {
        b = f;
        bs = s;
      }
    }
    return b;
  }

  // ---- 4) main loop ----
  try {
    for (final ff in frames) {
      frameIdx += 1;
      final double t = (frameIdx - 1) / fps;
      final inp = InputImage.fromFilePath(ff.path);
      List<Pose> poses;
      try {
        poses = await pd.processImage(inp);
      } catch (_) {
        emitEmpty(t, frameIdx);
        continue;
      }
      if (poses.isEmpty) {
        emitEmpty(t, frameIdx);
        continue;
      }

      final lm = poses.first.landmarks;
      double fw = _rdlCachedW, fh = _rdlCachedH;
      if (fw <= 0 || fh <= 0) {
        final d = await _rdlProbeDims(ff.path);
        fw = d.$1.toDouble();
        fh = d.$2.toDouble();
        _rdlCachedW = fw;
        _rdlCachedH = fh;
      }

      final ls = lm[PoseLandmarkType.leftShoulder];
      final rs = lm[PoseLandmarkType.rightShoulder];
      final lh = lm[PoseLandmarkType.leftHip];
      final rh = lm[PoseLandmarkType.rightHip];
      final lk = lm[PoseLandmarkType.leftKnee];
      final rk = lm[PoseLandmarkType.rightKnee];
      final la = lm[PoseLandmarkType.leftAnkle];
      final ra = lm[PoseLandmarkType.rightAnkle];
      if (ls == null ||
          rs == null ||
          lh == null ||
          rh == null ||
          lk == null ||
          rk == null ||
          la == null ||
          ra == null) {
        emitEmpty(t, frameIdx);
        continue;
      }

      // Build raw landmark array
      final List<List<double>> rawLm = [];
      for (final tt in LM_O) {
        final pp = lm[tt];
        if (pp == null) {
          rawLm.add([0, 0, 0]);
        } else {
          rawLm.add([
            (pp.x / fw).clamp(0.0, 1.0),
            (pp.y / fh).clamp(0.0, 1.0),
            (pp.likelihood).clamp(0.0, 1.0)
          ]);
        }
      }

      // ============ Jump rejection ============
      final double midHipX = (rawLm[23][0] + rawLm[24][0]) / 2;
      final double midHipY = (rawLm[23][1] + rawLm[24][1]) / 2;
      final double diag = math.sqrt(1.0 + (fh / fw) * (fh / fw));
      bool isJump = false;
      if (lastValidMidHip != null) {
        final dx = midHipX - lastValidMidHip![0];
        final dy = midHipY - lastValidMidHip![1];
        final dist = math.sqrt(dx * dx + dy * dy) / diag;
        if (dist > JUMP_REJECT_HIP_FRAC) isJump = true;
      }

      final double coreVis = (rawLm[11][2] +
              rawLm[12][2] +
              rawLm[23][2] +
              rawLm[24][2] +
              rawLm[25][2] +
              rawLm[26][2] +
              rawLm[27][2] +
              rawLm[28][2]) /
          8.0;

      if (isJump || coreVis < LOW_CORE_VIS_THRESHOLD) {
        recoveryCountdown = RECOVERY_FRAMES_AFTER_JUMP;
        emitEmpty(t, frameIdx);
        continue;
      }
      lastValidMidHip = [midHipX, midHipY];
      if (recoveryCountdown > 0) {
        recoveryCountdown -= 1;
        emitEmpty(t, frameIdx);
        continue;
      }

      // Smooth landmarks
      final List<List<double>> smLm = smoother.smooth(rawLm, t);

      // ============ SHAPE VALIDATION ============
      // Pick dominant side first
      final double lV = smLm[11][2] + smLm[23][2] + smLm[25][2] + smLm[27][2];
      final double rV = smLm[12][2] + smLm[24][2] + smLm[26][2] + smLm[28][2];
      // [v20b] Lock the dominant side and only switch when the other
      // side is clearly more visible for several frames in a row. See
      // the big v20 comment block near `lockedSideLeft` declaration for
      // full rationale.
      if (lockedSideLeft == null) {
        // First frame — pick whichever side has more visibility.
        lockedSideLeft = lV >= rV;
      } else {
        final double currentSideV = lockedSideLeft! ? lV : rV;
        final double otherSideV = lockedSideLeft! ? rV : lV;
        if (otherSideV > currentSideV * SIDE_SWITCH_MARGIN) {
          sideSwitchVotes += 1;
          if (sideSwitchVotes >= SIDE_SWITCH_FRAMES) {
            lockedSideLeft = !lockedSideLeft!;
            sideSwitchVotes = 0;
          }
        } else {
          // Other side isn't decisively better — decay the vote
          // counter so brief flickers don't accumulate.
          sideSwitchVotes = math.max(0, sideSwitchVotes - 1);
        }
      }
      final bool useLeft = lockedSideLeft!;

      final List<double> sh =
          useLeft ? [smLm[11][0], smLm[11][1]] : [smLm[12][0], smLm[12][1]];
      final List<double> hi =
          useLeft ? [smLm[23][0], smLm[23][1]] : [smLm[24][0], smLm[24][1]];
      final List<double> kn =
          useLeft ? [smLm[25][0], smLm[25][1]] : [smLm[26][0], smLm[26][1]];
      final List<double> an =
          useLeft ? [smLm[27][0], smLm[27][1]] : [smLm[28][0], smLm[28][1]];

      // Sanity check: hip must be between shoulder and ankle vertically.
      // If skeleton is broken (arm welded to leg, etc.), this fails.
      final double shY = sh[1], hiY = hi[1], anY = an[1];
      final bool hipOrderOk = shY < hiY && hiY < anY;
      // [v19 DEEP-HINGE-SHAPE] hipFrac lower bound dropped from 0.20 to
      // 0.03. The 0.20 bound assumed roughly upright posture where the
      // shoulder is well above the hip in image Y. In a deep RDL hinge
      // the shoulder projects FORWARD and ends up at almost the same Y
      // as the hip — the spine becomes near-horizontal. With the old
      // bound, hipFrac fell to ~0.10-0.15 at the bottom of every rep,
      // failed shape validation, and the skeleton got wiped via
      // emitEmpty. The hipOrderOk check (shY < hiY < anY) already
      // catches catastrophic flips where ML Kit places the hip above
      // the shoulder; 0.03 just keeps a sliver of margin against
      // exact-overlap failures.
      //
      // [v32 NOTE → v33] hipOrderOk (shY < hiY) means frames where the
      // shoulder drops BELOW the hip (torso past horizontal, >90° true)
      // are rejected by shape validation and never update the peak —
      // the smoothed peak SATURATES in the mid-80s. In v32 this made
      // the 88° threshold catch only 1 of the too-deep reps in the
      // test video. v33 counts these rejected frames directly
      // (rPastHorizFrames, see the !shapeOk branch below) as the
      // primary too-deep evidence, with the lowered 82° threshold as
      // the secondary trigger.
      final double totalSpan = anY - shY;
      double hipFrac = 0.5;
      if (totalSpan > 0.05) {
        hipFrac = (hiY - shY) / totalSpan;
      }
      final bool hipFracOk = hipFrac > 0.03 && hipFrac < 0.90;

      // Knee must be between hip and ankle vertically
      final double knY = kn[1];
      final bool kneeOrderOk = hiY < knY && knY < anY;
      // [v19 DEEP-HINGE-SHAPE] kneeFrac bounds widened the same way.
      // When the user hinges, the knee position relative to hip-ankle
      // can shift more than the original 20-95% window allowed.
      double kneeFrac = 0.5;
      if ((anY - hiY).abs() > 0.05) {
        kneeFrac = (knY - hiY) / (anY - hiY);
      }
      final bool kneeFracOk = kneeFrac > 0.10 && kneeFrac < 0.98;

      // Skeleton width: hip-knee-ankle line shouldn't be exactly straight in 2D
      // (would mean limbs collapsed onto each other)
      final bool shapeOk = hipOrderOk && hipFracOk && kneeOrderOk && kneeFracOk;

      if (!shapeOk) {
        // [v33 PAST-HORIZONTAL-DETECTION] hipOrderOk fails for BOTH
        // broken skeletons AND a genuinely past-horizontal torso
        // (shoulder at/below hip level = torso ≥ 90° true). The second
        // case is real, important form information — it's the direct
        // evidence for the too-deep check — so before discarding the
        // frame, count it if it looks like a plausible deep hinge and
        // not a broken skeleton:
        //   - we're mid-rep ('rising': hunting for the bottom)
        //   - the failure is specifically the shoulder-hip inversion,
        //     with hip still above ankle and knee ordering intact
        //   - the inversion is SMALL relative to leg length (a real
        //     past-horizontal torso puts the shoulder slightly below
        //     the hip; an arm-welded-to-leg skeleton is wildly off)
        //   - shoulder + hip visibility are decent
        // The frame is still rejected for everything else (state
        // machine, peak, display) — only the counter is updated.
        if (state == 'rising' &&
            shY >= hiY &&
            hiY < anY &&
            kneeOrderOk &&
            (shY - hiY) < 0.35 * math.max(0.05, anY - hiY) &&
            (useLeft ? smLm[11][2] : smLm[12][2]) >= 0.30 &&
            (useLeft ? smLm[23][2] : smLm[24][2]) >= 0.30) {
          rPastHorizFrames += 1;
        }
        // Skeleton looks broken — don't update state machine, just emit
        emitEmpty(t, frameIdx);
        continue;
      }

      // ============ Soft jump prevention ============
      // Prevent the skeleton from snapping to a different person between
      // frames. Two layers:
      //   (1) Frame-to-frame: reject huge single-frame jumps (>25% of the
      //       frame). These are clearly identity confusion since natural
      //       movement is much smaller per frame.
      //   (2) Rolling-median: reject frames where the hip is far from the
      //       median of the last ~1s of frames. Catches the case where
      //       ML Kit snaps to a bystander for several frames in a row —
      //       once the median has stabilized on the real user, snaps to
      //       a different X/Y are rejected even before any rep is counted.
      final double curMidHipX = (smLm[23][0] + smLm[24][0]) / 2;
      final double curMidHipY = (smLm[23][1] + smLm[24][1]) / 2;
      bool softJumpDetected = false;
      if (lastValidMidHip != null) {
        final dx = curMidHipX - lastValidMidHip![0];
        final dy = curMidHipY - lastValidMidHip![1];
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist > 0.25) softJumpDetected = true;
      }
      if (softJumpDetected) {
        recoveryCountdown = RECOVERY_FRAMES_AFTER_JUMP;
        emitEmpty(t, frameIdx);
        continue;
      }
      // Rolling history: keep the last ~1 second of hip positions.
      // Once we have enough samples, reject frames whose hip is too far
      // from the rolling median (= dominant cluster of recent frames).
      hipHistoryX.add(curMidHipX);
      hipHistoryY.add(curMidHipY);
      final int historyLimit = math.max(8, fps.round());
      while (hipHistoryX.length > historyLimit) {
        hipHistoryX.removeAt(0);
        hipHistoryY.removeAt(0);
      }
      bool farFromMedian = false;
      if (hipHistoryX.length >= historyLimit) {
        final sortedX = List<double>.from(hipHistoryX)..sort();
        final sortedY = List<double>.from(hipHistoryY)..sort();
        final medX = sortedX[sortedX.length ~/ 2];
        final medY = sortedY[sortedY.length ~/ 2];
        final dx = curMidHipX - medX;
        final dy = curMidHipY - medY;
        final dist = math.sqrt(dx * dx + dy * dy);
        // Generous threshold (35%) since median is a stronger anchor
        // than the previous frame — a real user moving naturally should
        // never be this far from their own median.
        if (dist > 0.35) farFromMedian = true;
      }
      if (farFromMedian) {
        // Skeleton has snapped to a position far from the established
        // user position — reject this frame. Don't update history with
        // this bad position so the median stays anchored on the real user.
        hipHistoryX.removeLast();
        hipHistoryY.removeLast();
        emitEmpty(t, frameIdx);
        continue;
      }
      lastValidMidHip = [curMidHipX, curMidHipY];

      // ============ POSITION LOCK (after first rep) ============
      // After we've counted at least one rep we know roughly where THIS
      // user's hip is in the frame. ML Kit will sometimes briefly snap
      // to a bystander when the main user becomes occluded (e.g. deep
      // hinge cropping the head). We catch that by requiring the hip
      // position to stay within a generous radius of where we last
      // saw it during a confirmed-good moment.
      //
      // Why this works where the previous identity lock failed:
      //  - We lock ONLY position (X,Y), not body height. The previous
      //    lock rejected a deep hinge because the user's apparent size
      //    in the frame changed — but their HIP position in the frame
      //    stays roughly the same when they don't walk around.
      //  - We keep a generous 30% radius — a hinging user's hip moves
      //    a bit (typically 5-15%), but a bystander is always >30% away.
      //  - The lock slowly tracks the user via EMA so they CAN drift
      //    over a long set, but a sudden snap to a bystander is still
      //    rejected.
      bool positionLockFailed = false;
      if (positionLocked) {
        final double dx = curMidHipX - lockedMidHipX;
        final double dy = curMidHipY - lockedMidHipY;
        final double dist = math.sqrt(dx * dx + dy * dy);
        if (dist > POSITION_LOCK_RADIUS) {
          positionLockFailed = true;
        }
      }
      if (positionLockFailed) {
        // Skeleton jumped to a different person. Hide it for this frame
        // and don't update state machine — but DON'T update the lock
        // anchor either, so if the jump corrects on the next frame
        // we resume normally.
        emitEmpty(t, frameIdx);
        continue;
      }
      // Slowly drift the lock toward current position (EMA) so the user
      // can move naturally over time. Only updates when position is
      // valid and inside the radius.
      if (positionLocked) {
        lockedMidHipX = 0.95 * lockedMidHipX + 0.05 * curMidHipX;
        lockedMidHipY = 0.95 * lockedMidHipY + 0.05 * curMidHipY;
      }

      // ============ Minimal pose reliability ============
      // Only require what's actually needed for the torso-angle signal:
      // hip and shoulder visibility. Everything else (nose, ear, head
      // cropping, body size, etc.) was over-aggressive — it rejected
      // legitimate poses where the user briefly turned their back, got
      // close to the camera, or had occluded landmarks. We let those
      // frames through and rely on shape validation (above) to catch
      // genuinely broken skeletons.
      //
      // [v19 DEEP-HINGE-VIS] Threshold lowered from 0.40 to 0.25. ML
      // Kit's visibility scores DROP during unusual postures (deep
      // hinge with horizontal spine, head occluded, body crossing over
      // itself) even when the landmark POSITIONS are correct. At 0.40
      // the bottom of every RDL rep got flagged unreliable and the
      // widget hid the skeleton — exactly the symptom the user reported
      // ("skeleton disappears every time on the descent"). 0.25 still
      // rejects frames where ML Kit clearly has no idea, but trusts the
      // detection during the bottom of the lift where it matters most.
      // Shape validation above is the primary correctness check; this
      // threshold is now a secondary sanity gate.
      final double domShoulderVis = useLeft ? smLm[11][2] : smLm[12][2];
      final double domHipVis = useLeft ? smLm[23][2] : smLm[24][2];
      final bool poseReliable = domShoulderVis >= 0.25 && domHipVis >= 0.25;

      // Build display landmarks (hide low-vis)
      final List<List<double>> displayLm = [];
      for (final pt in smLm) {
        if (pt[2] < VIS_HIDE_THRESHOLD) {
          displayLm.add([pt[0], pt[1], 0.0]);
        } else {
          displayLm.add(pt);
        }
      }

      // ============ Compute torso angle (THE signal) ============
      final double torsoAngle = torsoAngleVertical(hi, sh);
      final double kneeAngle = angleDeg(hi, kn, an);

      // Light smoothing of torso angle for state machine
      currentSmoothedTorso = 0.5 * currentSmoothedTorso + 0.5 * torsoAngle;

      // ============ Adaptive baseline calibration (no warmup) ============
      // The lowest sustained torso angle = real standing baseline.
      // Track the minimum angle ever seen (rep-detection-safe: it can only
      // go down, never up, which means thresholds get tighter over time
      // but never falsely loosen).
      if (currentSmoothedTorso < lowestSustainedTorso) {
        lowestSustainedTorso = currentSmoothedTorso;
      }
      // Standing baseline = lowest seen, clamped to [0, 25°].
      // It updates after every frame, but with a floor so a single low-noise
      // frame doesn't anchor too low.
      final double newBaseline = lowestSustainedTorso.clamp(0.0, 25.0);
      if (newBaseline < standingTorsoAngle) {
        standingTorsoAngle = newBaseline;
        enterDescentAngle = standingTorsoAngle + 25.0;
        exitRepAngle = standingTorsoAngle + 12.0;
      }

      // Adaptive bottom: highest sustained torso angle
      if (currentSmoothedTorso > bottomTorsoAngle) {
        bottomTorsoAngle =
            0.85 * bottomTorsoAngle + 0.15 * currentSmoothedTorso;
      }

      // depth display: 0..1 from standing to ~80°
      depthPct = ((currentSmoothedTorso - standingTorsoAngle) /
              math.max(20.0, bottomTorsoAngle - standingTorsoAngle))
          .clamp(0.0, 1.0);

      // ============ [v22] Hip displacement & standing-baseline buffer ============
      // Body scale = vertical span shoulder→ankle. Used as the denominator
      // for normalizing hip horizontal offset, so the same physical hinge
      // gives the same numeric value regardless of how big the user
      // appears in the frame.
      final double bodyScaleY = math.max(0.05, an[1] - sh[1]);
      // Hip X relative to ankle X, normalized by body height. ~0 in
      // standing (hip directly above ankle); grows in absolute value
      // as user pushes hips back in a hinge.
      final double currentHipXRel = (hi[0] - an[0]) / bodyScaleY;
      // Calibrate standing hip position only when the user is genuinely
      // upright AND we're in 'standing' state (not mid-rep).
      if (poseReliable &&
          uprightConfirmed &&
          state == 'standing' &&
          currentSmoothedTorso < ABS_UPRIGHT_THRESHOLD) {
        if (!standingHipXRelInit) {
          standingHipXRel = currentHipXRel;
          standingHipXRelInit = true;
        } else {
          standingHipXRel = 0.9 * standingHipXRel + 0.1 * currentHipXRel;
        }
        // Also collect torso angle samples for median-based calibration.
        standingTorsoSamples.add(currentSmoothedTorso);
        while (standingTorsoSamples.length > STANDING_SAMPLE_LIMIT) {
          standingTorsoSamples.removeAt(0);
        }
        if (standingTorsoSamples.length >= STANDING_SAMPLE_LIMIT ~/ 2) {
          final sorted = List<double>.from(standingTorsoSamples)..sort();
          medianStandingTorso = sorted[sorted.length ~/ 2];
        }
      }

      // ============ [v18] Upright confirmation tracker ============
      // See the big block comment near `uprightConfirmed` declaration
      // for full rationale. Briefly: until we've seen the user clearly
      // upright (torso < 22°) for ~0.4s, no rep can be counted. This
      // sticks for the rest of the session once flipped — we don't ever
      // un-confirm a user.
      //
      // Decay-rather-than-reset on bent frames: a single noisy frame
      // mid-upright (e.g. ML Kit briefly flickering during a pose hold)
      // shouldn't wipe progress. Slow decay tolerates that without
      // letting a half-bent posture accidentally satisfy the gate.
      if (!uprightConfirmed) {
        if (poseReliable && currentSmoothedTorso < ABS_UPRIGHT_THRESHOLD) {
          framesUpright += 1;
          if (framesUpright >= UPRIGHT_CONFIRM_FRAMES) {
            uprightConfirmed = true;
          }
        } else {
          framesUpright = math.max(0, framesUpright - 1);
        }
      }

      // ============ Update per-rep metrics during rep ============
      if (state == 'rising') {
        rTotalFrames += 1;
        if (!poseReliable) rBadFrames += 1;
        if (currentSmoothedTorso > rMaxTorso) rMaxTorso = currentSmoothedTorso;
        // [RDL SAFEGUARD] Only update knee + back metrics on RELIABLE
        // frames. If ML Kit briefly snaps to a bystander, that frame's
        // geometry would corrupt rMaxKnee/rMinKnee and the back issue
        // flag — leading to false-positive feedback ("Bend your knees
        // more", "Torso going forward") on otherwise-good reps.
        if (poseReliable) {
          if (kneeAngle > rMaxKnee) rMaxKnee = kneeAngle;
          if (kneeAngle < rMinKnee) rMinKnee = kneeAngle;
          // [v32] Threshold lowered 95 → 88 and message reworded. Fires
          // in real time DURING the descent, the moment the torso passes
          // ~parallel — which is when the user can still correct it.
          if (currentSmoothedTorso > _TORSO_TOO_DEEP) {
            rBackIssue = true;
            if (currentSmoothedTorso > rBackAngle)
              rBackAngle = currentSmoothedTorso;
            rtMsg = 'You\'re going too deep - hinge a bit less';
            rtHold = RT_FB_HOLD_FRAMES;
          }
          // [v22] Hip displacement during rep — measure absolute deviation
          // from the user's standing hip position. A real RDL pushes hips
          // back, so this should grow significantly during the descent.
          if (standingHipXRelInit) {
            final double hipDisp = (currentHipXRel - standingHipXRel).abs();
            if (hipDisp > rMaxHipDisp) rMaxHipDisp = hipDisp;
          }
          // [v22] Symmetry — compute torso angle from BOTH sides and
          // accumulate the disagreement. If they disagree consistently,
          // either the user is asymmetric or ML Kit is hallucinating
          // one side. Only sample when both sides have decent visibility.
          if (smLm[11][2] > 0.30 &&
              smLm[12][2] > 0.30 &&
              smLm[23][2] > 0.30 &&
              smLm[24][2] > 0.30) {
            final double lTorso = torsoAngleVertical(
                [smLm[23][0], smLm[23][1]], [smLm[11][0], smLm[11][1]]);
            final double rTorso = torsoAngleVertical(
                [smLm[24][0], smLm[24][1]], [smLm[12][0], smLm[12][1]]);
            rSymmetrySum += (lTorso - rTorso).abs();
            rSymmetryFrames += 1;
          }
          // [v25] Spine neutrality check (ear-shoulder-hip angle) was
          // removed here. The proxy was unreliable — see comment near
          // _KNEE_TOO_STRAIGHT for the reasoning.
          // [v26] Wrist-to-ankle tracking removed for the same reason:
          // bar position at the bottom of the lift isn't a reliable
          // judgment of form (many lifters intentionally go to the
          // floor, and it's a stylistic choice rather than a form
          // error).
        }
      }

      // ============ State machine: detect rep BOTTOMS (peaks of torso angle) ============
      // RDL reps don't always return to full standing between reps.
      // What's reliable: each rep has a clear PEAK in torso angle (= bottom
      // of the hinge). Between two peaks the angle dips. So:
      //   1. Track running peak while torso angle is rising / steady.
      //   2. Once angle drops by > REVERSAL_DROP from the peak, the rep ends.
      //   3. After the dip, when torso starts rising again, the next rep starts.
      // This handles both "return to standing" and "stay in soft hinge" cadences.
      //
      // TIMING: We use a small REVERSAL_DROP so confirmation arrives close
      //   to the peak. We then RETROACTIVELY tag the peak frame's telemetry
      //   with rep_just_finished, so haptic / sound / coloring fire at the
      //   actual deepest point, not on the way back up.

      Map<String, dynamic>? finishedRep;

      const double REVERSAL_DROP =
          5.0; // degrees — must drop this much from peak to confirm end
      // [v17 STRICTER-NEW-REP] Was 8.0 — too low, ambient torso jitter
      // in standing easily exceeds it and triggered phantom reps. 18°
      // ensures the user is genuinely starting another descent (a real
      // RDL descent goes from ~8° to ~70°+, so 18° from the valley is
      // a clear signal).
      const double NEW_REP_RISE = 18.0;

      {
        // States:
        //  'standing'  — looking for start of a rep
        //  'rising'    — torso angle increasing, hunting for the peak (= bottom of rep)
        //  'falling'   — past the peak, torso angle decreasing back up to standing
        //
        // Rep counting timing:
        //   - When we leave 'rising' (peak confirmed), we store a pendingRep.
        //   - When the user RETURNS to upright (transition from 'falling' to
        //     'standing', OR clearly back near standing for several frames),
        //     we COUNT the pendingRep — this fires the haptic / sound /
        //     skeleton coloring at the top of the lift, where the user wants it.
        //
        // CRITICAL: when poseReliable is false, we DO NOT update the state
        //   machine. The torso angle is meaningless when ML Kit is hallucinating
        //   the upper body. Bad frames count toward rejection criteria.

        if (state == 'standing') {
          if (!poseReliable) {
            framesAboveEnter = 0;
          } else if (currentSmoothedTorso >= enterDescentAngle) {
            framesAboveEnter += 1;
          } else {
            framesAboveEnter = 0;
          }
          // [v18] Block transition until uprightConfirmed. Without this
          // check, a video starting with the user already bent over the
          // bar (deep hinge as their FIRST frame) would immediately
          // satisfy framesAboveEnter and start a phantom rep. Then the
          // standing-up motion that follows gets counted as that rep.
          if (poseReliable &&
              uprightConfirmed &&
              framesAboveEnter >= STATE_TRANSITION_FRAMES &&
              (frameIdx - lastRepEndFrame) >= MIN_FRAMES_BETWEEN_REPS) {
            state = 'rising';
            repStartFrame = frameIdx;
            resetPerRep();
            peakTorsoAngle = currentSmoothedTorso;
            peakFrameIdx = frameIdx;
            rMaxTorso = currentSmoothedTorso;
            rMaxKnee = kneeAngle;
            rMinKnee = kneeAngle;
            rTotalFrames = 1;
            framesAboveEnter = 0;
          }
        } else if (state == 'rising') {
          // CHANGED: We now update peak even when poseReliable is false,
          // as long as shape validation passed (we got here, so it did).
          // Reasoning: a user turning their back to the camera at the
          // bottom of an RDL has perfectly valid landmarks for the lower
          // body — the torso angle is still measurable. Refusing to
          // update peak in that moment caused legitimate deep reps to
          // be missed entirely.
          //
          // We still TRACK bad frames (rBadFrames tally) and the
          // 25% quality gate still rejects reps where most frames had
          // hallucinated upper bodies. But individual unreliable
          // frames no longer block peak detection.
          if (currentSmoothedTorso > peakTorsoAngle) {
            peakTorsoAngle = currentSmoothedTorso;
            peakFrameIdx = frameIdx;
            framesAscending = 0;
          } else if (currentSmoothedTorso < peakTorsoAngle - REVERSAL_DROP) {
            framesAscending += 1;
          }
          // Confirm transition to falling after sustained drop
          if (framesAscending >= STATE_TRANSITION_FRAMES) {
            // The rep BOTTOM is confirmed. Decide if it was a real rep, and
            // store as pendingRep. Actual count happens when user returns up.
            final int repDuration = frameIdx - repStartFrame;
            // [v17 STRICTER-DEPTH] Was peakTorsoAngle >= enterDescentAngle + 5
            // (= ~38°). That's only the upper third of an RDL — a partial
            // bend, not a real rep. Real RDL bottoms reach 60-80°. The new
            // floor is 45° absolute, which is conservative (won't reject
            // a genuine but light hinge) but firmly excludes the small
            // upper-body wobbles that were getting counted as reps.
            const double MIN_REAL_REP_DEPTH_ANGLE = 45.0;
            final bool depthEnough =
                peakTorsoAngle >= MIN_REAL_REP_DEPTH_ANGLE &&
                    peakTorsoAngle >= enterDescentAngle + 5.0;
            final bool durationEnough = repDuration >= MIN_REP_DURATION_FRAMES;
            // [v21 RELAXED-QUALITY] Was 0.25 — too strict. The threshold is
            // computed as rBadFrames/rTotalFrames where rTotalFrames only
            // counts frames that PASSED all upstream gates (jump, shape,
            // position lock, rolling median). When many frames are
            // rejected upstream, rTotalFrames is small and just 1-2
            // unreliable frames push the ratio over 25%, falsely failing
            // good reps. The upstream gates are now the primary correctness
            // check (rejected frames don't even enter the state machine),
            // so this gate just needs to catch the extreme case where
            // most of the in-rep frames were ML Kit hallucinations.
            // 50% threshold is still strict enough for that.
            final double badFrac =
                rTotalFrames > 0 ? (rBadFrames / rTotalFrames) : 1.0;
            final bool qualityEnough = badFrac <= 0.50;
            if (depthEnough && durationEnough && qualityEnough) {
              // [v22] Capture descent end frame BEFORE we lose peakFrameIdx
              // to the next rep. Ascent time will be computed at rep count.
              rDescentEndFrame = peakFrameIdx;
              pendingRep = {
                'rep': repCount + 1,
                'peak_torso': peakTorsoAngle,
                'peak_frame': peakFrameIdx,
                'good_depth': peakTorsoAngle >= _GOOD_DEPTH_TORSO_ANGLE,
                'min_knee': rMinKnee,
                'max_knee': rMaxKnee,
                'max_torso': rMaxTorso,
                'back_issue': rBackIssue,
                'back_angle': rBackAngle,
                // [v22] Enriched semantic metrics
                'rep_start_frame': repStartFrame,
                'descent_end_frame': peakFrameIdx,
                'hip_disp': rMaxHipDisp,
                'symmetry_avg_diff':
                    rSymmetryFrames > 0 ? rSymmetrySum / rSymmetryFrames : 0.0,
                'symmetry_samples': rSymmetryFrames,
                'bad_frac': badFrac,
                // [v33] Direct geometric evidence of torso ≥ 90°
                'past_horiz_frames': rPastHorizFrames,
                // [v26] All v23 form-check fields removed
              };
              // Show form feedback NOW, at the bottom of the lift, where it's
              // most relevant. Priority (v32): too-deep first — it's the
              // safety-relevant issue — then stiff knees, then not deep
              // enough. (Too-deep is also shown in real-time during
              // 'rising' when crossing the threshold on reliable frames;
              // this peak-based trigger is the fallback for bottoms where
              // ML Kit confidence dropped and the rising-phase check
              // couldn't fire.)
              final bool kneeStiff = rMinKnee < 998.0 &&
                  rMaxKnee > 0.0 &&
                  (rMinKnee > _KNEE_TOO_STRAIGHT ||
                      (rMaxKnee - rMinKnee) < _KNEE_MIN_RANGE);
              if (peakTorsoAngle > _TORSO_TOO_DEEP ||
                  rPastHorizFrames >= _PAST_HORIZ_MIN_FRAMES) {
                rtMsg = 'You\'re going too deep - hinge a bit less';
                rtHold = RT_FB_HOLD_FRAMES;
              } else if (kneeStiff) {
                rtMsg = 'Bend your knees a bit more';
                rtHold = RT_FB_HOLD_FRAMES;
              } else if (peakTorsoAngle < _GOOD_DEPTH_TORSO_ANGLE) {
                rtMsg = 'Go deeper - hinge more at the hips';
                rtHold = RT_FB_HOLD_FRAMES;
              }
            }
            state = 'falling';
            framesAscending = 0;
            framesBelowReturn = 0;
            ascentMin = currentSmoothedTorso;
            fallingStartFrame = frameIdx;
          }
          // Safety timeout — if the user is stuck "rising" too long, reset
          if ((frameIdx - repStartFrame) > MAX_REP_DURATION_FRAMES) {
            state = 'standing';
            framesAboveEnter = 0;
            pendingRep = null;
          }
        } else if (state == 'falling') {
          // CHANGED: removed `if (poseReliable)` guard. Same reasoning as
          // 'rising' above — when shape validation has passed we can trust
          // the torso angle even if upper-body confidence is moderate.
          if (currentSmoothedTorso < ascentMin) {
            ascentMin = currentSmoothedTorso;
          }
          // Count frames where torso is back near standing
          // (returnAngle = midway between exit and enter — generous)
          final double returnAngle = standingTorsoAngle + 18.0;
          if (currentSmoothedTorso <= returnAngle) {
            framesBelowReturn += 1;
          } else {
            framesBelowReturn = 0;
          }
          // ============ PRIMARY rep-count trigger ============
          // User has returned to upright for several frames — count the rep
          // at THIS moment (top of the lift).
          if (framesBelowReturn >= STATE_TRANSITION_FRAMES &&
              pendingRep != null) {
            finishedRep = pendingRep;
            pendingRep = null;
            lastRepEndFrame = frameIdx;
            state = 'standing';
            framesAboveEnter = 0;
            framesBelowReturn = 0;
          }
          // ============ SECONDARY rep-count trigger ============
          // If the user is dropping into the next rep without fully
          // returning to upright, count the pending rep now (just before
          // we transition into a new rising phase).
          else if (currentSmoothedTorso > ascentMin + NEW_REP_RISE &&
              currentSmoothedTorso >= enterDescentAngle &&
              (frameIdx - lastRepEndFrame) >= MIN_FRAMES_BETWEEN_REPS) {
            // First, count the pending rep if any
            if (pendingRep != null) {
              finishedRep = pendingRep;
              pendingRep = null;
              lastRepEndFrame = frameIdx;
            }
            // Then start a new rep
            // [v32] Safe to reset accumulators here even though
            // finishedRep hasn't been processed yet: evalRep now reads
            // exclusively from the finishedRep snapshot (see
            // EVAL-FROM-SNAPSHOT comment above evalRep).
            state = 'rising';
            repStartFrame = frameIdx;
            resetPerRep();
            peakTorsoAngle = currentSmoothedTorso;
            peakFrameIdx = frameIdx;
            rMaxTorso = currentSmoothedTorso;
            rMaxKnee = kneeAngle;
            rMinKnee = kneeAngle;
            rTotalFrames = 1;
          }
          // Hard return-to-standing: torso fully back to upright
          if (currentSmoothedTorso <= exitRepAngle) {
            // Count pending rep if not already counted
            if (pendingRep != null) {
              finishedRep = pendingRep;
              pendingRep = null;
              lastRepEndFrame = frameIdx;
            }
            state = 'standing';
            framesAboveEnter = 0;
            framesBelowReturn = 0;
          }
          // ============ TIMEOUT trigger ============
          // Some users don't return to a fully-upright stance between reps
          // (they keep partial hinge to maintain tension). If we've been in
          // 'falling' for >2 seconds without the user starting a new rep
          // and without returning to upright, count the pending rep anyway
          // — they clearly finished it. Without this trigger, the rep
          // would never count.
          else if (pendingRep != null &&
              fallingStartFrame > 0 &&
              (frameIdx - fallingStartFrame) > (2.0 * fps).round()) {
            finishedRep = pendingRep;
            pendingRep = null;
            lastRepEndFrame = frameIdx;
            // Stay in 'falling' so we can pick up the next rep when they
            // start one. Don't transition to 'standing' since the user
            // isn't actually upright.
            fallingStartFrame = -1; // disable timeout until next falling
          }
        }
      }

      // ============ Process finished rep ============
      if (finishedRep != null) {
        // [v32] Evaluate from the snapshot captured at peak confirmation —
        // NOT the live accumulators, which may already belong to the next
        // rep (secondary-trigger path).
        final ev = evalRep(finishedRep);
        final double sc = ev['score'] as double;
        final List<String> fb = List<String>.from(ev['feedback'] as List);
        repCount += 1;
        allScores.add(sc);
        final String tag = sc >= 9.0 ? 'good' : 'bad';
        if (sc >= 9.0) {
          goodReps += 1;
        } else {
          badReps += 1;
        }
        // Tag the CURRENT frame — this is the moment the user has returned
        // toward upright (top of the lift), where they want haptic / sound /
        // coloring to fire.
        repJust = tag;
        // Activate position lock now that we've confirmed who this user is.
        // Use the current hip position as anchor — they've just returned to
        // upright so this is a reliable "neutral" position for them.
        if (!positionLocked) {
          positionLocked = true;
          lockedMidHipX = curMidHipX;
          lockedMidHipY = curMidHipY;
        }
        sessFb.addAll(fb);
        for (final f in fb) {
          final cat = _FB_CATEGORY[f] ?? 'other';
          final cur = sessFbByCat[cat];
          if (cur == null ||
              (_FB_SEVERITY[f] ?? 1) > (_FB_SEVERITY[cur] ?? 1)) {
            sessFbByCat[cat] = f;
          }
        }
        // ============ [v22] Compute enriched per-rep metrics & confidence ============
        // Tempo: descent = repStartFrame → peakFrameIdx (eccentric phase).
        //        ascent  = peakFrameIdx → now (concentric phase, current frame
        //                  is when rep was counted = top of lift).
        final int rsf = finishedRep['rep_start_frame'] as int;
        final int defr = finishedRep['descent_end_frame'] as int;
        final int descentFr = defr > rsf ? defr - rsf : 0;
        final int ascentFr = defr > 0 ? frameIdx - defr : 0;
        final double descentSec = descentFr / fps;
        final double ascentSec = ascentFr / fps;
        final double tempoRatio =
            descentSec > 0.05 ? ascentSec / descentSec : 1.0;

        // Confidence — combine all available signals. Starts at 1.0 and
        // decays for each red flag. Each penalty is small so a single
        // weak signal doesn't tank the score; multiple weak signals
        // compound. Result is in [0, 1].
        double conf = 1.0;
        // (a) Depth confidence: deeper rep = more confident it was a real rep
        final double pkTorso = finishedRep['peak_torso'] as double;
        if (pkTorso < 50.0)
          conf *= 0.85; // shallow but valid
        else if (pkTorso < 60.0) conf *= 0.95;
        // (b) Hip displacement: low displacement = suspicious (might be a
        //     front-bend, not an RDL hinge). Front-facing camera also
        //     causes low values, so we only PENALIZE — never reject — and
        //     keep the penalty moderate.
        final double hipDisp = finishedRep['hip_disp'] as double;
        if (hipDisp < 0.03)
          conf *= 0.75; // very little hip movement
        else if (hipDisp < 0.06) conf *= 0.90;
        // (c) Quality: how clean was ML Kit during the rep
        final double badFr = finishedRep['bad_frac'] as double;
        if (badFr > 0.35)
          conf *= 0.85;
        else if (badFr > 0.20) conf *= 0.95;
        // (d) Symmetry: persistent left-vs-right disagreement is suspicious
        final double symAvg = finishedRep['symmetry_avg_diff'] as double;
        final int symSamp = finishedRep['symmetry_samples'] as int;
        if (symSamp >= 5) {
          if (symAvg > 20.0)
            conf *= 0.80; // big disagreement
          else if (symAvg > 12.0) conf *= 0.92;
        }
        // (e) Tempo: extreme cases only (very fast bouncing = not a real rep)
        if (descentSec < 0.3 || ascentSec < 0.3) conf *= 0.85;
        conf = conf.clamp(0.0, 1.0);

        repReports.add({
          'rep': finishedRep['rep'],
          'score': double.parse(sc.toStringAsFixed(2)),
          'score_display': dispHalf(sc),
          'label': sLabel(sc),
          'feedback': fb,
          // [v22] Confidence score 0..1, exposed at top level for UI use
          'confidence': double.parse(conf.toStringAsFixed(3)),
          'metrics': {
            'peak_torso_angle': double.parse(
                (finishedRep['peak_torso'] as double).toStringAsFixed(2)),
            'max_torso_angle': double.parse(
                (finishedRep['max_torso'] as double).toStringAsFixed(2)),
            'min_knee_angle': double.parse(
                (finishedRep['min_knee'] as double).toStringAsFixed(2)),
            'max_knee_angle': double.parse(
                (finishedRep['max_knee'] as double).toStringAsFixed(2)),
            'back_angle': double.parse(
                (finishedRep['back_angle'] as double).toStringAsFixed(2)),
            // [v22] New enriched metrics
            'hip_displacement': double.parse(hipDisp.toStringAsFixed(3)),
            'descent_time_s': double.parse(descentSec.toStringAsFixed(2)),
            'ascent_time_s': double.parse(ascentSec.toStringAsFixed(2)),
            'tempo_ratio': double.parse(tempoRatio.toStringAsFixed(2)),
            'symmetry_avg_diff_deg': double.parse(symAvg.toStringAsFixed(2)),
            'frame_quality': double.parse((1.0 - badFr).toStringAsFixed(3)),
            // [v33] For threshold calibration: how many frames the
            // shoulder was at/below hip level during this rep.
            'past_horizontal_frames':
                (finishedRep['past_horiz_frames'] as int?) ?? 0,
            // [v26] v23 form-check metrics removed
          },
        });
        // Feedback was already surfaced in real-time at the moment it
        // was relevant (torso during rising, knees/depth at peak). No
        // need to repeat it here at top-of-lift.
      }

      if (rtHold > 0) rtHold -= 1;

      telemetry.add({
        't': t,
        '_frame_idx': frameIdx,
        'reps': repCount,
        'depth': depthPct,
        'metric_label': 'HINGE',
        'metric_value': depthPct,
        'feedback': (rtHold > 0 && rtMsg != null) ? rtMsg : null,
        'rep_just_finished': repJust,
        'landmarks': displayLm,
        // [POSE-RELIABLE-FLAG] Tells the widget whether ML Kit's detection
        // for this frame is trustworthy. The widget hides the skeleton for
        // unreliable frames so the visible skeleton stays consistent with
        // the rep-counting logic — no more "skeleton on bystander, but
        // rep counted on lifter" disconnect.
        'pose_reliable': poseReliable,
      });
      // [v20a] Save this displayLm as the fallback for the next dropped
      // frame. Reset stale counter since we just emitted a fresh one.
      lastGoodDisplayLm = displayLm;
      staleHoldCount = 0;
      repJust = null;
    }
  } finally {
    await pd.close();
    try {
      framesDir.deleteSync(recursive: true);
    } catch (_) {}
  }

  // ---- 5) aggregate ----
  double avg = allScores.isEmpty
      ? 0
      : allScores.reduce((a, b) => a + b) / allScores.length;
  if (avg.isNaN || avg.isInfinite) avg = 0;
  double ts2 = double.parse((((avg * 2).round() / 2.0)).toStringAsFixed(2));
  if (sessFb.isNotEmpty) ts2 = math.min(ts2, 9.5);

  final fbl = sessFbByCat.isNotEmpty
      ? sessFbByCat.values.toList()
      : (sessFb.isNotEmpty
          ? sessFb.toSet().toList()
          : <String>['Great form! Keep it up 💪']);

  String? tip;
  // [v25] Spine tip removed (spine category no longer exists).
  // [v32] 'back' (too deep) tip takes top priority — it's the
  // safety-relevant issue.
  if (sessFbByCat.containsKey('back'))
    tip =
        'Stop the descent when your torso is about parallel to the floor - going lower shifts the load onto your lower back';
  else if (sessFbByCat.containsKey('depth'))
    tip = 'Focus on pushing your hips back further to reach full depth';
  else if (sessFbByCat.containsKey('knees'))
    tip = 'Romanian deadlifts need a soft knee bend throughout the movement';
  else if (sessFbByCat.isNotEmpty)
    tip = 'Keep your core tight and chest up';
  else
    tip = 'Great technique! Keep building that posterior chain 💪';

  final String uri = 'file://$videoPath';

  // ============ [v22] Session-level enriched aggregates ============
  // Pull per-rep confidence/tempo/consistency into a session summary so
  // the UI can show things like "All 8 reps confident" or "3 reps had
  // shallow hip displacement". All optional — old fields preserved.
  double avgConfidence = 0.0;
  double avgDescent = 0.0;
  double avgAscent = 0.0;
  double avgHipDisp = 0.0;
  int lowConfidenceReps = 0;
  if (repReports.isNotEmpty) {
    for (final r in repReports) {
      avgConfidence += (r['confidence'] as double? ?? 0.0);
      final m = r['metrics'] as Map<String, dynamic>;
      avgDescent += (m['descent_time_s'] as double? ?? 0.0);
      avgAscent += (m['ascent_time_s'] as double? ?? 0.0);
      avgHipDisp += (m['hip_displacement'] as double? ?? 0.0);
      if ((r['confidence'] as double? ?? 1.0) < 0.7) lowConfidenceReps += 1;
    }
    final n = repReports.length;
    avgConfidence /= n;
    avgDescent /= n;
    avgAscent /= n;
    avgHipDisp /= n;
  }
  // Rep-count consistency: standard deviation of peak torso angles
  // across reps. Low = consistent set. High = depth varied a lot.
  double depthStdDev = 0.0;
  if (repReports.length >= 2) {
    double sumDepth = 0.0;
    for (final r in repReports) {
      sumDepth += ((r['metrics'] as Map<String, dynamic>)['peak_torso_angle']
          as double);
    }
    final meanDepth = sumDepth / repReports.length;
    double sumSq = 0.0;
    for (final r in repReports) {
      final d =
          (r['metrics'] as Map<String, dynamic>)['peak_torso_angle'] as double;
      sumSq += (d - meanDepth) * (d - meanDepth);
    }
    depthStdDev = math.sqrt(sumSq / repReports.length);
  }

  return {
    'squat_count': repCount,
    'technique_score': ts2,
    'technique_score_display': dispHalf(ts2),
    'technique_label': sLabel(ts2),
    'good_reps': goodReps,
    'bad_reps': badReps,
    'feedback': fbl,
    'tip': tip,
    'reps': repReports,
    'video_path': uri,
    'analyzed_fps': fps,
    'frame_count': frameIdx,
    // [v22] New session-level fields
    'avg_confidence': double.parse(avgConfidence.toStringAsFixed(3)),
    'low_confidence_reps': lowConfidenceReps,
    'avg_descent_time_s': double.parse(avgDescent.toStringAsFixed(2)),
    'avg_ascent_time_s': double.parse(avgAscent.toStringAsFixed(2)),
    'avg_hip_displacement': double.parse(avgHipDisp.toStringAsFixed(3)),
    'depth_consistency_stddev': double.parse(depthStdDev.toStringAsFixed(2)),
    '_source_video_uri': uri,
    '_frame_telemetry': telemetry,
  };
}

double _rdlCachedW = -1;
double _rdlCachedH = -1;
Future<(int, int)> _rdlProbeDims(String path) async {
  final bytes = await File(path).readAsBytes();
  int i = 2;
  while (i < bytes.length - 8) {
    if (bytes[i] != 0xFF) break;
    final m = bytes[i + 1];
    i += 2;
    if ((m >= 0xC0 && m <= 0xCF) && m != 0xC4 && m != 0xC8 && m != 0xCC) {
      return (
        (bytes[i + 5] << 8) | bytes[i + 6],
        (bytes[i + 3] << 8) | bytes[i + 4]
      );
    } else {
      i += (bytes[i] << 8) | bytes[i + 1];
    }
  }
  return (720, 1280);
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
