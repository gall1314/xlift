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
  // Window=7 (was 11 — inherited from squat analyzer). The squat is
  // a slow lift where each phase lasts 0.5-1s and SG_WINDOW=11
  // (= 0.92s at 12fps) preserves the peaks fine. The overhead press
  // can be much faster — a rep cycle in this code's real-world test
  // videos was ~1.2s with a 0.2-0.3s peak at lockout (2-4 frames).
  //
  // SG_WINDOW=11 (covering nearly a whole rep cycle) was averaging
  // those brief peaks with surrounding low values and flattening them
  // below the detection thresholds. Empirical sweep on real videos:
  //   SG=11: 7/9 reps counted on the test set
  //   SG=7:  9/9 reps counted  ← chosen
  //   SG=5:  9/9 reps counted (slightly noisier landmarks)
  //   SG=3:  9/9 reps counted (close to raw)
  //
  // Window=7 = 0.58s at 12fps — wide enough for meaningful noise
  // reduction but narrow enough to preserve press peaks that are
  // 2-4 frames wide.
  static const int SG_WINDOW_SIZE = 7;
  static const int SG_POLY_ORDER = 2;
  static const double SG_VIS_THRESHOLD = 0.5;

  // ---------------------- ML KIT POSE DETECTOR ----------------------
  // [v1.15] CRITICAL FIX: switched from stream mode to single mode.
  //
  // We process discrete video frames extracted to JPG files via
  // InputImage.fromFilePath(). For that workflow, single mode is the
  // CORRECT api — stream mode is designed for live, temporally-
  // continuous CAMERA feeds (InputImage.fromBytes from a camera
  // stream), where it locks a tracker onto the most-prominent person
  // in the first frame and then TRACKS that person across subsequent
  // frames assuming inter-frame continuity.
  //
  // The failure that exposed this: a gym video where the lifter was
  // farther from the camera (full body, smaller in frame) under
  // dim, backlit lighting. Stream mode's initial lock-on FAILED on
  // the first frames, and because stream mode cascades from that
  // initial lock, it then returned ZERO poses for the ENTIRE video —
  // "Reps: 0, no skeleton" start to finish. A different analyzer
  // using single mode detected the skeleton on the same video with
  // no trouble.
  //
  // Single mode runs a full, independent detection on every frame
  // with no dependence on a prior lock-on, so it is far more robust
  // to varied subject size, distance, and lighting. The per-frame
  // cost is marginally higher and the raw landmarks are slightly
  // noisier (no temporal smoothing from the tracker), but we already
  // smooth heavily downstream (Savitzky-Golay across frames + EMA on
  // derived scalars), and single mode has the bonus of being fully
  // DETERMINISTIC — same video in, same result out, every run, which
  // also resolves the run-to-run count variance we chased earlier.
  //
  // Stream mode happened to work on earlier test videos only because
  // the lifter was close and well-lit, so the initial lock always
  // succeeded. That was luck, not correctness.
  static const bool USE_STREAM_MODE = false;

  // ---------------------- VISIBILITY (HYSTERESIS) ----------------------
  // Restricted to ARM landmarks only (see applyVisibilityFilters). Body
  // joints pass through always — they're rendered even at low vis.
  static const double VIS_HIDE_THRESHOLD = 0.40;
  static const double VIS_SHOW_THRESHOLD = 0.60;
  static const double LOW_CORE_VIS_THRESHOLD = 0.45;

  // ---------------------- ANATOMICAL PLAUSIBILITY ----------------------
  static const double MAX_ELBOW_BEND_DEG = 178.0;
  static const double MIN_ELBOW_BEND_DEG = 20.0;

  // ---------------------- JUMP / GLITCH REJECTION ----------------------
  // Press is mostly stationary so a small per-frame shoulder jump is
  // very suspicious. Timeout breaks the freeze-cascade (see squat fix).
  static const double JUMP_REJECT_SHOULDER_FRAC = 0.18;
  static const int JUMP_REJECT_MAX_CONSECUTIVE = 6;

  // ---------------------- REP DETECTION (CORE) ----------------------
  // Phase-transition elbow angles. These define what counts as "at the
  // shoulder" vs "arms extended overhead". After 2 detected reps the
  // analyzer adapts these to the user's actual ROM (see calibration).
  //
  // IMPORTANT: there are TWO thresholds for the top.
  //   - TOP_ELBOW_MIN_INIT (used for COUNTING): a relatively lenient
  //     ~115° — enough to say "the user attempted and finished a
  //     press". A user who doesn't fully extend their elbows is still
  //     pressing; they should get a counted rep with a feedback
  //     note, not no rep at all.
  //   - LOCKOUT_TARGET_ANGLE (used for SCORING, see below): ~172°.
  //     Hitting full lockout is what gets you a 10 on the lockout
  //     dimension. Hitting only 150° gets you a lower score plus the
  //     "Press to full lockout overhead" feedback.
  // The point of separating them is that DETECTING a rep and SCORING
  // a rep are different jobs. Mixing them produced a feedback-deadlock:
  // if a user couldn't reach the lockout threshold, no rep counted,
  // so they got no feedback telling them to lock out harder.
  //
  // IMPORTANT REVISION (2026-05-21): TOP_ELBOW_MIN_INIT was lowered
  // from 125° to 115° after a real user video showed 5+ visible
  // press reps with peak elbow EMA of only 117-124° (partial-ROM
  // presses, possibly touching to safety pins). The previous 125°
  // gate plus the 8° hysteresis band meant the effective detection
  // threshold was 118° — just above what these reps reach. With 115°
  // here the effective gate is 107°, comfortably below the peaks
  // while still requiring a real overhead motion (wrist must also be
  // >=10% torso height above shoulder, see WRIST_TOP_MIN_ABOVE_SHOULDER).
  // The LOCKOUT_TARGET_ANGLE (172°) used for SCORING is UNCHANGED, so
  // a partial-rep user still gets a low lockout score (~2-3) and the
  // "Press to full lockout overhead" feedback — exactly what the
  // counting-vs-scoring separation is designed for.
  static const double BOTTOM_ELBOW_MAX_INIT = 110.0;
  static const double TOP_ELBOW_MIN_INIT = 115.0;
  static const double HYSTERESIS_BAND = 8.0;

  // Wrist-position gates. The bottom requires the wrist to be near
  // shoulder height (not arbitrary); the top requires it to be above
  // shoulder height by a meaningful fraction of torso height. Without
  // these, lifting the bar partway off the rack could read as a rep.
  //
  // BOTTOM threshold: how far above the shoulder line the wrist can be
  // and still count as "at the bottom". With EMA smoothing on the
  // wrist Y, the value lags the actual descent by a few frames, so
  // we need a forgiving threshold. 0.15 (= 15% of torso height above
  // shoulder line) is calibrated so that a real return-to-shoulders
  // position registers reliably while a partial-descent doesn't.
  //
  // TOP threshold: how far above the shoulder line the wrist must be
  // to count as "in the top portion of the press". This is part of
  // the COUNTING gate, not the scoring gate. 0.10 (= 10% of torso
  // height above shoulder line) corresponds to "wrist clearly above
  // shoulder, arms partially extended overhead" — enough to confirm
  // a real press attempt without requiring a perfect lockout.
  static const double WRIST_BOTTOM_MAX_ABOVE_SHOULDER = 0.15;
  static const double WRIST_TOP_MIN_ABOVE_SHOULDER = 0.10;

  // [v1.2] Standalone wrist-based TOP threshold. If the wrist rises
  // this much above the shoulder line (as a fraction of torso height),
  // we count it as TOP regardless of the elbow angle (only requiring
  // minimal elbow extension >=80° for sanity). See comment in the
  // state machine's isTop calculation for rationale.
  //
  // 0.18 means "wrist is 18% of torso height above the shoulder line".
  // For a 6ft person that's roughly 4-5 inches above shoulder — clearly
  // in pressing territory, not just an arm raised forward. The user's
  // observed presses showed wrist rises of 0.10-0.16 normalized, so
  // 0.18 catches the strong ones while still being a real overhead
  // position (a casual hand-wave or "I have a question" raise doesn't
  // reach 18% torso above shoulder).
  static const double WRIST_ALONE_TOP_THRESHOLD = 0.18;

  // [v1.3] Envelope-based descent detection. When the user is at TOP,
  // we track the highest position the wrist reached (smallest Y, since
  // Y is normalized from top of image). Once the wrist has descended by
  // this much (as fraction of torso height) from that peak FOR AT LEAST
  // WRIST_DESCENT_SUSTAINED_FRAMES consecutive frames, we declare the
  // descent has started and transition to DESCENDING.
  //
  // This is what catches consecutive fast reps where the wrist DOESN'T
  // come all the way back down to the shoulder between reps. Without
  // this, the state machine would see the wrist stay "way above
  // shoulder" through multiple consecutive presses and never count
  // them as separate reps. Observed in production: user does press 1,
  // counter goes to 1, then user does presses 2 and 3 in quick
  // succession without the wrist dropping below ~10% above shoulder
  // (since the bar isn't being racked between reps). The counter
  // stays at 1 until the user finally pauses and the wrist drops to
  // shoulder level, at which point the counter jumps back to working
  // and counts subsequent reps.
  //
  // [v1.5 REVISION] Threshold was bumped from 5% → 10% torso AND a
  // sustained-frames requirement was added. The original 5%/1-frame
  // setting was too sensitive: it fired on minor wrist Y jitter during
  // the lockout hold (ML Kit data is noisier than MediaPipe), causing
  // a single rep to be counted twice. The math is:
  //   - Real fast-consecutive reps: wrist descends ~47% torso between
  //     peaks (verified from HEIGHT donut readings 51% → 23%). The
  //     10% threshold is easily reached, AND the descent is sustained
  //     across multiple frames as the bar comes down.
  //   - Lockout hold wobble: typically 2-5% torso jitter. Doesn't
  //     hit 10% threshold. Even if it briefly does (noise spike),
  //     it's not sustained for 2+ frames.
  //   - Phantom mid-rep wobble: a single noisy frame of 10%+ descent
  //     is not sustained → no false trigger.
  static const double WRIST_DESCENT_FROM_PEAK = 0.10;

  // [v1.8] Was 2, bumped to 3. The ML Kit landmark stream on
  // unusual angles (side, bottom-up looking at the bar) can produce
  // two consecutive noisy frames that briefly cross the descent
  // threshold even though the user hasn't actually started lowering
  // the bar. Three sustained frames (250ms at 12fps) makes the
  // detection more robust against this kind of glitch while still
  // catching real descents — even fast 1.1s consecutive reps spend
  // 4-6 frames on the descent portion.
  static const int WRIST_DESCENT_SUSTAINED_FRAMES = 3;

  // ---------------------- DETECTION QUALITY GATES ----------------------
  // ML Kit sometimes returns landmarks for partial detections — when
  // only an arm is visible at the edge of the frame, for example, the
  // body landmarks (hips) are placed somewhere far from where they
  // really are. The detected "torso" (shoulder→hip distance) is then
  // tiny — a fraction of what it should be.
  //
  // We use the torso height as a sanity check on the entire detection:
  // unless we can see a real torso, we ignore the frame for purposes
  // of starting a set.
  //
  // [v1.32] LOWERED 0.10 → 0.06 based on a real user video that
  // produced ZERO counted reps. Frame-by-frame simulation on that
  // video (portrait, subject filmed from a distance) showed the
  // subject's GENUINE torso reading 0.06–0.10 for the entire active
  // portion — a full body, clearly visible, legitimately small in
  // frame. The 0.10 gate reset the IDLE bottom-dwell ONE FRAME
  // before it would have completed, and then blocked every exit
  // path from IDLE (including the v1.31 rescue) for the rest of the
  // video: the machine never left IDLE and both real reps were
  // lost. The old comment's claim that "anything under 0.10 means
  // the person isn't really visible" is disproven by this video.
  // Hallucination protection is preserved: partial-body ghosts
  // (frame-edge arm with fabricated hips) read torso < 0.05, and
  // the LOW_CORE_VIS + jump-rejection gates still stand in front.
  static const double MIN_TORSO_HEIGHT_FOR_START = 0.06;

  // ---------------------- IDLE→TOP SHORTCUT (STRICT) ----------------------
  // The IDLE→TOP shortcut handles videos that start with the user
  // already mid-set (already pressed up). It's the riskiest state
  // transition because we never observed the bottom that started the
  // rep, so we have no validation that the user is actually pressing
  // — we're just trusting the current frame.
  //
  // To leave IDLE via this shortcut we require a STRICT lockout, not
  // the lenient counting threshold. A real "started mid-set" video
  // shows the user fully locked out for half a second; a walking
  // person with one arm raised won't sustain a strict lockout pose
  // long enough to fire.
  //
  // These thresholds are deliberately tighter than the counting
  // thresholds used by ASCENDING→TOP and TOP→DESCENDING.
  //
  // [v1.4] Bumped dwell from 5 to 12 frames (1 second at 12fps) AND
  // added a torso-stability check inside the state machine (see
  // IDLE→TOP transition). Observed in production: ML Kit
  // hallucinates landmarks during the camera-shake/setup phase
  // (fingers near lens, etc.) that happen to satisfy the strict
  // lockout criteria for a few frames. Result: a phantom "rep 1"
  // gets registered before the user even starts the workout, then
  // the post-process places the visual peak at the hallucinated
  // frame, displaying "Reps: 1" at t≈3s. Sustaining a strict
  // lockout for a full second is much harder for hallucinated
  // landmarks (which jitter) but trivial for a real started-mid-set
  // video.
  static const double IDLE_TO_TOP_STRICT_ELBOW_MIN = 160.0;
  static const double IDLE_TO_TOP_STRICT_WRIST_ABOVE = 0.20;
  static const int IDLE_TO_TOP_MIN_DWELL_SEC_EQUIV = 12; // frames at any FPS

  // To leave IDLE via the BOTTOM path, the bottom must be observed
  // for this long. Walking-in / unrack transients often briefly
  // satisfy the bottom criteria but don't dwell.
  static const double START_GATE_SEC = 0.5;

  // [v1.31] Fast-first-rep rescue window. If the user reached a real
  // (strict) BOTTOM but left it before completing the START_GATE
  // dwell — i.e. they pressed almost immediately after unracking —
  // and a genuine TOP is observed within this many seconds of leaving
  // that bottom, the state machine enters TOP with the cycle anchored
  // at the observed bottom. This rescues the classic "first rep never
  // counted" failure where the ENTIRE first rep happens while the
  // machine is still IDLE (no count_attempt in the debug log at all).
  // 1.5s comfortably covers the ascent of any real press (fast reps
  // ascend in 0.3-0.6s) while being short enough that an unrelated
  // later arm-raise can't pair up with a stale bottom observation.
  static const double FIRST_REP_RESCUE_WINDOW_SEC = 1.5;

  // Timing — adapted to FPS at runtime.
  static const double MIN_CYCLE_SEC = 0.5;
  static const double MIN_PHASE_SEC = 0.10;
  static const double REFRACTORY_SEC = 0.25;
  // START_GATE_SEC is declared below alongside the IDLE→TOP shortcut.

  // EMA smoothing of scalars used by the state machine.
  // Note: landmarks are already Savitzky-Golay smoothed at this point,
  // so the EMA below is a SECOND layer of smoothing. We use a high
  // alpha (close to 1.0) so we mostly trust the SG-smoothed input and
  // only filter out tiny residual noise. With lower alphas (e.g. 0.4)
  // we were over-smoothing — the elbow EMA lagged 3-4 frames behind
  // the actual angle, which meant a brief 1-frame lockout peak got
  // averaged down below the TOP threshold and the rep didn't register.
  static const double ELBOW_EMA_ALPHA = 0.80;
  static const double WRIST_EMA_ALPHA = 0.70;
  static const double LEAN_EMA_ALPHA = 0.50;
  static const double SHOULDER_EMA_ALPHA = 0.40;
  static const double TORSO_EMA_ALPHA = 0.40;

  // Bilateral arm validation. We compute elbow angle on both arms,
  // pick the side with higher visibility as primary, and if the
  // secondary side disagrees by more than this we trust only primary.
  static const double BILATERAL_DISAGREE_DEG = 35.0;
  static const double VIS_THRESHOLD = 0.40;

  // ---------------------- CALIBRATION ----------------------
  static const int CALIBRATION_REPS = 2;
  static const double CALIBRATION_ADJUSTMENT = 0.85;

  // ---------------------- SCORING ----------------------
  static const double DEPTH_TARGET_ANGLE = 100.0;
  static const double DEPTH_OK_ANGLE = 115.0;
  static const double LOCKOUT_TARGET_ANGLE = 172.0;
  static const double LOCKOUT_OK_ANGLE = 160.0;
  static const double LEAN_TARGET_MAX = 12.0;
  static const double LEAN_OK_MAX = 22.0;
  static const double LEAN_BAD_MAX = 30.0;
  static const double BAR_PATH_TARGET = 0.04;
  static const double BAR_PATH_OK = 0.08;

  // STACK dimension removed — see comment near the original
  // STACK_TARGET_MAX. Replaced by HEAD_THROUGH (whether the head is
  // forward of the wrists at lockout — checks for active scapular
  // upward rotation) and ELBOW_FLARE (whether the elbows are pointing
  // outward instead of forward — guards against shoulder impingement).

  // HEAD_THROUGH measures the head's X position vs the wrists' X
  // position at the top of the press. A correct lockout has the head
  // PASSED UNDER the bar, so the head sits forward of (in front of)
  // the wrists from a side view. Measured as (wristX - noseX) /
  // torsoH. Positive value = head is forward of wrists = good.
  // Negative value = head behind wrists = "head not pushed through".
  //
  // Targets: at lockout, head should be 0-5% torso-units forward of
  // wrists. If head is more than 5% BEHIND the wrists, that's a
  // missed lockout cue.
  //
  // IMPORTANT [v1.6]: This metric is ONLY meaningful in a SIDE view.
  // In a frontal view (camera facing the user), both nose X and wrist
  // X are near the body centerline, so the metric becomes noise-
  // dominated and gives meaningless negative values (head appearing
  // "behind" wrists by a few % of torso). To prevent unfair feedback,
  // we DETECT the camera angle via shoulder X-separation and skip
  // this metric when shoulders are clearly horizontally separated
  // (> FRONTAL_VIEW_SHOULDER_SEP threshold). See the scoring section.
  //
  // [v1.29 — loosened + noise-hardened]: The "Push your head through
  // at the top" cue was firing on visually fine lockouts. Same story
  // as the v1.13 ELBOW_FLARE loosening — the thresholds sat too close
  // to the metric's noise floor. Two compounding causes:
  //   1. The metric records the single WORST frame during TOP. One
  //      noisy nose/wrist frame (ML Kit jitters each landmark 1-3%
  //      torso, and the difference of two noisy X values compounds
  //      to 2-6% torso) sets the value for the whole rep.
  //   2. The head naturally sits slightly behind the bar for a frame
  //      or two right at TOP entry / exit (mid push-through), so even
  //      a perfect rep briefly shows -0.15 to -0.25 at those edges.
  // Fixes (see the tracking + scoring sections):
  //   a. Thresholds widened below (OK -0.20 → -0.30, BAD -0.35 →
  //      -0.48, TARGET -0.10 → -0.15). Feedback now requires the
  //      head to be clearly and persistently behind the wrists.
  //   b. The tracker now uses the SECOND-worst TOP frame instead of
  //      the worst — a single-frame noise spike can no longer set
  //      the rep's value.
  //   c. Scoring requires >= HEAD_THROUGH_MIN_FRAMES measured TOP
  //      frames; below that the observation is unreliable (a 1-2
  //      frame TOP phase) and the score stays neutral with no
  //      feedback — same adaptive-silence pattern as ELBOW_FLARE's
  //      MIN_FLARE_CONFIDENT_FRAMES.
  static const double HEAD_THROUGH_TARGET =
      -0.15; // head slightly behind wrist = ideal target
  static const double HEAD_THROUGH_OK =
      -0.30; // head moderately behind — still acceptable
  static const double HEAD_THROUGH_BAD =
      -0.48; // head clearly behind, looking up at bar
  static const int HEAD_THROUGH_MIN_FRAMES = 3;

  // ELBOW_FLARE measures how far the elbows extend OUTWARD beyond
  // the wrists, normalized by torso height. Recorded only during
  // BOTTOM phase (rack position is where flare is most relevant).
  //
  // [v1.7 — redesigned metric]: Previously this measured elbow vs.
  // SHOULDER, which conflated flare with normal grip width — a wide-
  // grip user with perfect elbow position would score poorly. The
  // new formulation measures how much the elbow extends LATERALLY
  // BEYOND THE WRIST:
  //
  //   For each side:
  //     elbowOutward = max(0, |elbow.X - bodyCenter.X|
  //                          - |wrist.X - bodyCenter.X|)
  //   flare = max(left elbowOutward, right elbowOutward) / torsoH
  //
  // A correct overhead press has elbows roughly UNDER or slightly
  // INSIDE the wrists at the bottom, so elbowOutward ≈ 0. A flared
  // position has the elbow wider than the wrist (90° abduction
  // territory), giving elbowOutward > 0.
  //
  // This metric works best from FRONTAL or BACK view (where lateral
  // flaring is directly visible). From a side view, both elbow and
  // wrist have similar X coords (both in front of the body), so
  // flare ≈ 0 either way — the metric won't trigger false positives
  // in side view, but also can't detect real flares from that angle
  // (which is fine because depth flare isn't measurable from a 2D
  // side-view image anyway).
  //
  // [v1.13 — loosened thresholds]: Previous OK/BAD values (0.10/0.20)
  // were firing feedback on near-perfect form. Real-world video data
  // shows even clean studio performances accumulate 5-15% torso
  // excess due to:
  //   - Natural slight grip-versus-elbow geometry variation
  //   - ML Kit landmark noise (1-3% torso jitter on each landmark
  //     compounds into 2-6% on the excess metric)
  //   - Slightly imperfect frontal/back alignment of the camera
  // Bumping to 0.15/0.30 puts the OK ceiling well above this baseline
  // noise floor while keeping BAD high enough to catch real flares
  // (which show 20-40% torso excess in field data).
  //
  // Verified on a frontal-view 3D-animation reference:
  //   At BOTTOM with normal grip, perfect form: 0.03-0.08 → score 9+
  //   Old metric on the same frames: 0.36-0.40 (false flare)
  static const double ELBOW_FLARE_TARGET =
      0.00; // elbow at most as wide as wrist
  static const double ELBOW_FLARE_OK =
      0.15; // ~15% torso beyond wrist = still acceptable
  static const double ELBOW_FLARE_BAD = 0.30; // ~30% torso = clearly flared

  // [v1.6] Frontal view detection. If the user's shoulders are far
  // apart in the image (> this much of frame width), the camera is
  // looking at them head-on. The HEAD_THROUGH metric becomes
  // meaningless in this case (both head and wrist sit near the body
  // centerline X, so the X-distance between them is noise).
  //
  // 0.10 = 10% of frame width. A side view typically shows shoulder
  // separation < 0.05 (one shoulder occluding the other). A frontal
  // view shows 0.15-0.25. The threshold of 0.10 is a clean cutoff
  // between the two.
  static const double FRONTAL_VIEW_SHOULDER_SEP = 0.10;

  // [v1.8] Minimum number of "confident" frames during BOTTOM phase
  // required before ELBOW_FLARE feedback is shown.
  //
  // A confident frame is one where:
  //   - Shoulder X-separation is large enough (frontal/back view), AND
  //   - Both arms' landmarks are visible enough
  //
  // If we don't have enough confident frames, the flare measurement
  // is unreliable — typically because the camera is positioned at a
  // bad angle (side view, bottom-up, very close to the user, etc.)
  // where the lateral elbow movement that defines flare simply isn't
  // visible. Showing flare feedback in those cases produces false
  // alarms; the algorithm should stay silent instead.
  static const int MIN_FLARE_CONFIDENT_FRAMES = 3;
  static const double FLARE_ARM_VIS_THRESHOLD = 0.5;

  // [v1.9] Minimum wrist rise (as fraction of torso height) from the
  // start of a rep cycle to the peak, required before the rep is
  // counted. Prevents the "phantom cycle" double-count bug where the
  // state machine completes a full transition sequence during the
  // descent of a real rep — but no actual ascent happened, so the
  // wrist never travelled meaningfully upward.
  //
  // [v1.11 REVISION] Raised from 0.05 → 0.15. Previous values were
  // letting jitter-based phantom cycles through:
  //
  //   1. Real rep peaks at Y=0.20. ML Kit briefly under-reports
  //      elbow → state→DESCENDING→BOTTOM. False count fires with
  //      wristYAtCycleStart=0.30 (mid-descent).
  //   2. Single-frame ML Kit jitter spikes the wrist Y back to 0.28
  //      for one frame.
  //   3. State machine: enoughInPhase satisfied → BOTTOM→TOP shortcut
  //      → topPeakWristY = 0.28.
  //   4. ascent = 0.30 − 0.28 = 0.02 → ~15% torsoUnit.
  //   5. At 0.05 threshold (v1.10), 15% passes → phantom counts.
  //
  // 0.15 is set high enough that landmark jitter (typically 1-2%
  // image space, < 15% torso) cannot satisfy it, while staying well
  // below the ascent of any real rep:
  //   - Standard real rep ascent: 30-80% torsoUnit
  //   - Real rep right after early-counted previous rep: 25-40%
  //   - Worst-case borderline real rep: > 20%
  // The trade-off is intentional: we'd rather very occasionally miss
  // a marginal rep than ever count a phantom one.
  static const double MIN_RISE_FROM_CYCLE_START = 0.15;

  static const double W_DEPTH = 0.20;
  static const double W_LOCKOUT = 0.25;
  static const double W_LEAN = 0.20;
  static const double W_BAR_PATH = 0.15;
  static const double W_HEAD_THROUGH = 0.10;
  static const double W_ELBOW_FLARE = 0.10;

  static const double REP_FEEDBACK_SCORE_THR = 7.0;
  // [v1.30] RETIRED from the session-feedback gate (kept only to
  // avoid breaking any external references). The ratio-scaled
  // threshold max(1, 30% of reps) silently dropped issues that
  // occurred in one rep out of 4+, causing the UI to show "Great
  // form! Keep it up" on sessions that scored 9 with a visible
  // in-video issue. Session feedback now uses the flat
  // SESSION_FEEDBACK_MIN below — see the sessionMinCount comment.
  static const double SESSION_FEEDBACK_RATIO = 0.30;
  // [v1.21] Lowered from 2 → 1. With min=2, two reps that had issues
  // in DIFFERENT categories (e.g., one rep with lean, one with bar
  // path) would each only contribute 1 to their category's count,
  // and BOTH categories get filtered out — surfacing no feedback at
  // all and falling back to the UI's default "Great form! Keep it up"
  // message. With min=1, any rep with an issue surfaces it in the
  // session feedback, matching the "proper reps" count the user sees.
  static const int SESSION_FEEDBACK_MIN = 1;

  // ---------------------- HEAD-CROSS PROOF HARDENING ----------------------
  // [v1.32] The v1.19 wristCrossedHead lockout proof used a single
  // frame of (wristY < noseY) with zero margin. Simulation on the
  // real false-first-rep video showed why that's defeatable: during
  // RACK HANDLING the hands grip the bar at upper-chest/chin height,
  // putting the wrist only 3–28% torso BELOW the nose — well inside
  // ML Kit's per-landmark jitter band, so a single noisy frame can
  // flip the comparison and arm the proof, letting the rack-settle
  // cycle count as "rep 1". A REAL lockout is nothing like that: the
  // measured margins were +13% to +72% torso ABOVE the nose,
  // sustained for 5–7 consecutive TOP frames. Requiring the wrist to
  // clear the nose by a real margin (8% torso) on at least 2 TOP
  // frames separates the two populations with enormous headroom:
  //   rack jitter:  margin flutters around 0 ± few %t, single frames
  //   real lockout: +30..70%t for the whole TOP phase
  // The 50%-torso peak fallback (for nose-less back views) remains
  // unchanged as an OR at count time.
  static const double HEAD_CROSS_MARGIN_TORSO = 0.08;
  static const int HEAD_CROSS_SUSTAINED_FRAMES = 2;

  // ---------------------- POST-PROCESS OUTLIER FILTERS ----------------------
  // [v1.31] Absolute floor for the cycle-length outlier filter, in
  // SECONDS OF MOTION (ascent start → count). A cycle is only
  // eligible for removal as a "walk-up" when its MOTION duration
  // exceeds BOTH 3x the typical cycle length AND this absolute floor.
  // Rationale: no real walk-up fits inside 4 seconds of continuous
  // motion, while a deliberately slow rep (3s eccentric — which our
  // own form tip RECOMMENDS) next to fast 1.2s reps could otherwise
  // cross the relative 3x threshold and get deleted. The absolute
  // floor guarantees that slow-but-real reps are never removed.
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

/// Analyze an overhead/military press video. v1.32 — fixes the
/// "rep 1 counted on setup motion + real rep 1 missed" failure,
/// diagnosed by full frame-by-frame simulation on the user's actual
/// video (BlazePose single-mode landmarks + a faithful port of this
/// state machine). Three coordinated changes:
///   1. MIN_TORSO_HEIGHT_FOR_START 0.10 → 0.06. On the test video
///      the subject's genuine torso read 0.06–0.10 (full body,
///      filmed from a distance); the 0.10 gate reset the IDLE
///      bottom-dwell one frame before completion and then blocked
///      every IDLE exit path — the machine never started and ALL
///      real reps were lost. With 0.06, simulation counts both real
///      reps at their true timestamps with zero false positives.
///   2. SHOULDER-RELATIVE ascent gate. The v1.9/v1.11 gate compared
///      absolute image-Y of the wrist across seconds
///      (wristYAtCycleStart − topPeakWristY), silently assuming the
///      body stays put in frame. After unracking, users WALK BACK —
///      the shoulder line sinks in the image, and the first real
///      rep's lockout wrist-Y lands near the OLD bottom's wrist-Y,
///      driving the absolute ascent to ~0 and killing the count
///      with 'ascent<15%torso' (the exact "real first rep missed"
///      symptom). The gate now compares the SAME-FRAME
///      wrist-above-shoulder height at cycle start vs its maximum
///      during TOP — translation-invariant, so body drift in frame
///      cancels out. Phantom cycles are still blocked: their "peak"
///      above-shoulder height ≈ their start's, so the relative rise
///      is ≈ 0 exactly as before. The absolute value is kept in the
///      debug log as ascentAbs for comparison.
///   3. HARDENED head-cross proof. wristCrossedHead now requires
///      the wrist ABOVE the nose by ≥ HEAD_CROSS_MARGIN_TORSO (8%
///      torso) on ≥ HEAD_CROSS_SUSTAINED_FRAMES (2) TOP frames,
///      instead of one zero-margin frame. Rack handling puts the
///      wrist within jitter distance of the nose (measured −3%t at
///      the closest), so one noisy frame could arm the old proof
///      and let the rack-settle cycle count as rep 1; a real
///      lockout clears the nose by +30..70%t for the whole TOP
///      phase and passes untouched. The same hardened flag feeds
///      the v1.31 peak-filter exemption, keeping it trustworthy.
///   Additionally, the pulse event's peakAboveShoulderNorm now uses
///   the same-frame above-shoulder maximum (peakWristAboveShNorm)
///   instead of mixing the count-frame shoulder with the peak-frame
///   wrist — same translation-robustness applied to the post-process
///   peak filter's input.
///
/// Builds on v1.31 — fixes the
/// "first rep not counted / random reps missed" family of bugs.
/// Four coordinated changes (see the [v1.31] comments at each site):
///   1. LENGTH FILTER MEASURES MOTION, NOT CYCLE. The v1.27 length
///      filter compared cycleLengthFrames (bottom-entry → count)
///      against 3x the typical length — but rep 1's cycle includes
///      the entire post-unrack setup dwell at the bottom, and a
///      rest-pause rep's cycle includes the rest BEFORE it. Both
///      were crossing the 3x threshold and getting DELETED as
///      "walk-up cycles" even though the reps were real. The filter
///      now compares motionLengthFrames (ascent start → count),
///      which excludes bottom-rest entirely, plus an absolute floor
///      of CYCLE_LEN_FILTER_MIN_SEC (4s) of motion below which no
///      cycle is ever removed.
///   2. PEAK FILTER RESPECTS THE HEAD-CROSS PROOF. The v1.26 peak
///      filter (peak < 70% of session max, in raw normalized units)
///      could delete real reps whose peak was slightly lower than
///      the session's best (partial-ROM variation, camera-distance
///      drift, topPeakWristY noise). It now never removes a cycle
///      whose wrist provably crossed above the nose during TOP
///      (the v1.19 geometric lockout proof) — an unrack motion can
///      NEVER satisfy that, so the filter still catches the exact
///      case it was built for while real reps are untouchable.
///   3. FAST-FIRST-REP RESCUE FROM IDLE. If the user presses within
///      START_GATE_SEC of reaching the bottom (typical right after
///      unracking), IDLE→BOTTOM never completes its dwell and the
///      ENTIRE first rep happens while the machine is still IDLE —
///      no count_attempt appears in the debug log at all. The IDLE
///      state now remembers the most recent short strict-bottom
///      dwell; if a genuine TOP is observed within
///      FIRST_REP_RESCUE_WINDOW_SEC of leaving it, the machine
///      enters TOP with the cycle anchored at that bottom. Safe
///      because it requires BOTH a real observed strict bottom
///      (>= 2 frames) AND a full isTop observation in close
///      succession — a walk-in or rack hold produces neither pair,
///      and counting still passes every downstream gate (ascent,
///      realBottomObs, head-cross).
///   4. SECOND PATH FOR THE realBottomObs GATE. The v1.17 gate only
///      incremented on isBottomStrict (elbow EMA <= 110°). When ML
///      Kit under-reports the elbow angle (the documented v1.2 /
///      v1.12 failure mode) the elbow never dips below 110° even
///      though the wrist clearly returns to shoulder level, and the
///      first count dies on 'realBottomObs<3'. A full wrist descent
///      back to shoulder level after a confirmed TOP peak now also
///      qualifies. Rack-descent false positives remain blocked by
///      the v1.19 wristCrossedHead lockout proof at count time.
/// All four changes either relax post-process DELETION conditions or
/// add strictly-gated entry/observation paths; none weakens a
/// count-time gate — non-regressive by construction for the
/// false-positive families fixed in v1.9-v1.30.
///
/// Builds on v1.30, which fixes two consistency bugs on the results
/// screen:
///   1. DOUBLE-COUNTED good/bad reps: when the post-process filter
///      removed cycles, its re-tally block AND the session-summary
///      loop each counted every rep once — good_reps could exceed
///      rep_count (observed: Total Reps 7, "Proper Reps" 12). The
///      session summary now resets the tallies and is the single
///      source of truth.
///   2. "Great form! Keep it up 💪" shown on non-clean sessions: the
///      ratio-scaled session-feedback threshold (30% of reps) dropped
///      issues occurring in a single rep, so a set scoring 9 with a
///      visible in-video issue still fell back to the Great-form
///      message. The gate is now a flat minimum of 1 — the fallback
///      can only appear when every rep is issue-free.
/// Both are output/consistency fixes; counting and scoring logic are
/// untouched.
///
/// Builds on v1.29, which calms the over-aggressive "Push your head
/// through at the top" feedback.
/// Three coordinated changes (see HEAD_THROUGH comments in
/// TuningParams for full rationale):
///   1. Thresholds loosened (TARGET -0.10→-0.15, OK -0.20→-0.30,
///      BAD -0.35→-0.48) — the old values sat inside the metric's
///      noise floor, same failure mode as pre-v1.13 ELBOW_FLARE.
///   2. The per-rep value is now the SECOND-worst TOP frame instead
///      of the single worst — one noisy nose/wrist frame can no
///      longer set the rep's head-through value.
///   3. Scoring requires >= HEAD_THROUGH_MIN_FRAMES (3) measured TOP
///      frames; below that, neutral 7.0 and no feedback (adaptive
///      silence, same pattern as MIN_FLARE_CONFIDENT_FRAMES).
/// Counting logic is untouched — this is a scoring/feedback-only
/// change, non-regressive by construction.
///
/// Builds on v1.28, which fixes the visual-peak-placement bug that
/// survived v1.27's count-attempt filtering. After the filter removed
/// cycle 1 (the walk-up) from pulseEvents, the COUNT was correct (1
/// less than before), but the visual rep-number tick still landed on
/// cycle 1's removed peak frame, not on cycle 2's real peak.
///
/// Root cause: the visual peak search for "rep 1" (which after
/// filtering is the FIRST kept event = original cycle 2) computed
/// `searchStart = max(prev, countIdx - 36)` with `prev = 0` because
/// pulseEvents[e-1] doesn't exist when e==0. The search range thus
/// included cycle 1's removed peak frame (frame 89, wristY 0.228),
/// which was the global min in the range. So visual rep 1's tick
/// landed at cycle 1's peak instead of cycle 2's peak — making it
/// look like "the first real rep is missed" even though the COUNT
/// itself was right.
///
/// Fix: BEFORE filtering, annotate every pulseEvent with its previous
/// ORIGINAL countFrameIdx (the prior cycle's count_attempt frame in
/// the unfiltered list). The visual placement then uses this stored
/// value as the searchStart lower bound, ensuring it excludes frames
/// belonging to filtered-out cycles. For rep 1 in our example:
/// `searchStart = max(92, 104-36) = 92`, search range [92, 104]
/// excludes cycle 1's frames, min wristY lands on cycle 2's peak
/// (frame 102, wristY 0.2252). Visual tick lands at t≈10.1s where
/// the user's first real press peak actually is.
///
/// Builds on v1.27 (cycle-length filter), v1.26 (peak filter
/// re-enabled), v1.25 (filters disabled — partially reversed), v1.24
/// (ascent filter — still disabled), v1.23 (peak filter introduced),
/// v1.22 (reverted v1.21's over-correction), v1.20 (`_debug` log),
/// v1.19 (geometric wrist-crossed-head check), v1.17 (real-bottom-
/// observed gate), v1.15 (single-mode pose detection), v1.14
/// (production-readiness: strict good-rep + form_tips + cleanup),
/// v1.13 (loosened ELBOW_FLARE), v1.12 (wrist-based BOTTOM path),
/// v1.11 (15% ascent gate), v1.9 (real-ascent gate), v1.8 (adaptive
/// ELBOW_FLARE), v1.7 (elbow-vs-wrist flare metric), v1.6 (frontal-
/// view HEAD_THROUGH suppression), v1.5 (sustained-frames descent),
/// v1.4 (envelope descent), v1.3 (narrower SG window), v1.2 (wrist-
/// based TOP fallback), v1.1 (fast-press BOTTOM→TOP shortcut + lower
/// TOP_ELBOW_MIN_INIT).
///
/// State machine (matches Python reference but with tighter gates):
///   IDLE → BOTTOM (must dwell in bottom for START_GATE_SEC)
///   IDLE → TOP (v1.31 rescue: short bottom dwell + genuine TOP soon after)
///   BOTTOM → ASCENDING (elbow clearly opening up)
///   BOTTOM → TOP (fast-press shortcut: isTop already satisfied)
///   ASCENDING → TOP (lockout — elbow straight AND wrist above shoulder)
///   TOP → DESCENDING (elbow clearly bending)
///   DESCENDING → BOTTOM → rep counted (cycle complete)
///
/// Each rep scored on 6 dimensions (depth, lockout, lean, head_through,
/// elbow_flare, bar_path). The frontend gets per-frame telemetry to
/// drive the skeleton overlay, counter, donut, feedback banner, and
/// rep_just_finished pulses (flash/sound/haptic).
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

  // [v1.14] Coaching tips ("form_tips") — surfaced as the `form_tips`
  // field in the response. These are general improvement cues based
  // on session-level metrics; they do NOT lower the score. A tip
  // fires when the relevant metric is in a "passable but not perfect"
  // band (e.g., lockout > 158° = no feedback fires, but < 168° = not
  // fully locked out — perfect window for a gentle reminder).
  //
  // Designed to give 0–3 tips per session: each has independent
  // trigger conditions, and most users hit 1–2.
  const String PERF_TIP_SLOW_DESCENT =
      'Lower the bar slowly — aim for 2–3 seconds on the way down';
  const String PERF_TIP_FULL_LOCKOUT =
      'Drive each rep to full lockout — fully extend your elbows overhead';
  const String PERF_TIP_BRACE_CORE =
      'Brace your core and squeeze your glutes — stay tight throughout';
  const String PERF_TIP_BAR_PATH =
      'Focus on pressing straight up — keep the bar path vertical';

  // Form-tip trigger thresholds.
  // ECCENTRIC_RATIO_MIN: minimum descent/ascent ratio for a "controlled"
  // eccentric. A proper press has descent ≥ 1.5× ascent; below that the
  // user is dropping the bar instead of controlling it.
  const double TIP_ECCENTRIC_RATIO_MIN = 1.5;
  // LOCKOUT band: avgTopElbow in this range means user is *almost*
  // locking out (> OK threshold 160° = no feedback) but < perfect
  // 172° target. Sweet spot for a "go further" reminder.
  const double TIP_LOCKOUT_NEAR_MIN = 158.0;
  const double TIP_LOCKOUT_NEAR_MAX = 168.0;
  // LEAN band: avgMaxLean above target (12°) but below OK (22°). User
  // is leaning slightly but not enough to penalize — coach the brace.
  const double TIP_LEAN_BORDERLINE_MIN = 10.0;
  const double TIP_LEAN_BORDERLINE_MAX = 18.0;
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
  double calcAngle(List<double> a, List<double> b, List<double> c) =>
      _angleAt(a, b, c);

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

      // Need at least one shoulder + matching elbow/wrist + hip on the
      // same side. Press is bilateral, but the camera can occlude one
      // side completely (the front-view test video does exactly this).
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
  // [v1.31] Frame where the ASCENT of the current cycle actually
  // began (leaving BOTTOM). Unlike cycleStartFrame, this excludes
  // any resting/setup dwell at the bottom — which was inflating
  // cycleLengthFrames and causing the v1.27 length filter to delete
  // REAL reps: (a) rep 1, whose cycle includes the whole post-unrack
  // setup dwell; (b) rest-pause reps, where the rest before the rep
  // lands inside that rep's cycle; (c) deliberately slow reps done
  // right after fast ones. 0 = not yet set for the current cycle
  // (falls back to cycleStartFrame at pulse-event time).
  int ascentStartFrame = 0;
  int lastRepFrame = -10000;
  int bottomDwellFrames = 0; // for START_GATE before allowing rep start
  // [v1.1] Counts consecutive frames where TOP was detected while in
  // IDLE. We require several in a row before accepting "started mid-
  // set in TOP" — a single-frame flicker is usually ML Kit noise (a
  // background arm, a partial detection at the frame edge, etc.).
  int idleTopDwellFrames = 0;

  // [v1.31] Fast-first-rep rescue bookkeeping. While in IDLE, we
  // remember where the current strict-bottom dwell started; when a
  // dwell is interrupted BEFORE completing START_GATE_FRAMES, we
  // stash its stats. If a genuine TOP is then observed within
  // RESCUE_WINDOW_FRAMES of that interruption, the rescue transition
  // fires (see the IDLE case). This is what catches the user who
  // unracks and presses immediately — previously the whole first rep
  // played out during IDLE and was never counted.
  int bottomDwellStartFrame = 0;
  double? bottomDwellStartWristY;
  double? bottomDwellStartAboveSh; // [v1.32] same-frame midShY - wristY
  int lastShortDwellFrames = 0;
  int lastShortDwellEndFrame = -100000;
  int lastShortDwellStartFrame = 0;
  double? lastShortDwellStartWristY;
  double? lastShortDwellStartAboveSh; // [v1.32]

  // [v1.17] Universal "real bottom observed" gate. Replaces v1.16's
  // path-specific awaitingFirstRealRep flag with a more robust check
  // that works regardless of which state path produced the count.
  //
  // The motivating bug: a video that starts with the user at the
  // RACK (bar already raised above the wristWayAbove threshold —
  // racks are designed to hold the bar above shoulder height) can
  // make the state machine count the "lower the bar to start
  // position" descent as the first rep. This happens through
  // several paths:
  //   - IDLE→TOP shortcut firing on a back-view rack hold (ML Kit's
  //     2D elbow angle can appear straight from behind even when the
  //     elbow is actually bent).
  //   - A small unrack "lift" creating a HEIGHT bump that looks like
  //     a press peak (e.g. HEIGHT 18% → 25% → 16% → 4%).
  //   - Other rare paths where the bar is at unrack height when the
  //     state machine first starts evaluating.
  //
  // Common to all of these: the user has NEVER ACTUALLY BEEN AT
  // REAL BOTTOM yet. A genuine OHP rep starts with the bar at the
  // clavicle (wrist near shoulder, elbow bent ≤ 110°). Until we've
  // observed that position for at least a few frames, no count is
  // a real count.
  //
  // We count CONSECUTIVE-OR-NEAR frames where the bottom condition
  // holds (i.e. each qualifying frame increments the counter; the
  // counter doesn't reset on a non-qualifying frame, since we're
  // tracking "has been observed at some point" not "currently is").
  // Threshold 3 frames is enough to defeat ML Kit single-frame
  // noise without significantly delaying legitimate counts.
  //
  // [v1.31] A second qualifying path was added at the increment site
  // (see the loop): a full wrist descent back to shoulder level
  // after a confirmed TOP peak. This survives the documented ML Kit
  // elbow under-reporting failure (v1.2/v1.12) where elbowEma never
  // dips below 110° even though the wrist clearly returns to the
  // clavicle — previously killing the first count on
  // 'realBottomObs<3'.
  int realBottomFramesObserved = 0;
  const int REAL_BOTTOM_REQUIRED = 3;

  // Smoothed scalars used for phase transitions.
  double? elbowEma;
  double? wristYEma;
  double? leanEma;
  double? shoulderYEma;
  double? torsoHeightEma;

  // [v1.3] Tracks the highest wrist position reached during the
  // current TOP phase (smallest Y value, since image Y is inverted —
  // Y=0 is top of image, Y=1 is bottom). Initialized when transitioning
  // into TOP, used by the envelope-based clearlyNotTop check, reset
  // (cleared) when transitioning out of TOP. See WRIST_DESCENT_FROM_PEAK
  // comments for the rationale.
  double? topPeakWristY;

  // [v1.9] Wrist Y position at the moment a rep cycle started (i.e.,
  // when we transitioned into BOTTOM or set cycleStartFrame). This is
  // the "starting point" of the wrist trajectory for the upcoming rep.
  //
  // We use this to validate that a real ASCENT happened before
  // counting a rep. A genuine rep has the wrist travel UP from
  // wristYAtCycleStart to a peak (topPeakWristY), giving:
  //   ascent = wristYAtCycleStart - topPeakWristY  >>  0
  //
  // The false-positive double-count bug observed in production
  // produces a "phantom cycle" where the state machine goes through
  // BOTTOM→ASCENDING→TOP→DESCENDING→BOTTOM transitions during the
  // descent of a previous rep — but the wrist never actually went
  // UP. In that case wristYAtCycleStart is roughly equal to the
  // "peak" the state machine recorded, so ascent ≈ 0. We refuse to
  // count reps where ascent < MIN_RISE_FROM_CYCLE_START.
  double? wristYAtCycleStart;

  // [v1.5] Counter of consecutive frames where the envelope-based
  // descent condition is satisfied. We require this to reach
  // WRIST_DESCENT_SUSTAINED_FRAMES before triggering descent — single
  // frame noise spikes don't sustain.
  int wristDescentConsecFrames = 0;

  // [v1.32] Shoulder-relative ascent tracking (FIX 2). Both values
  // are SAME-FRAME measurements of (midShY − wristYEma) — the
  // wrist's height above the shoulder line in normalized image
  // units, positive = above. startWristAboveShNorm is captured when
  // the cycle starts; peakWristAboveShNorm is the maximum observed
  // while at TOP. Their difference is the translation-invariant
  // ascent used by the count gate: if the whole body drifts in the
  // frame (walking back after unracking, camera pan), both the
  // shoulder and the wrist move together and the measure is
  // unaffected — unlike the absolute wrist-Y difference it replaces.
  double? startWristAboveShNorm;
  double? peakWristAboveShNorm;

  // Current-rep accumulators.
  double currentRepMinElbow = 999.0;
  double currentRepMaxElbow = 0.0;
  double currentRepMaxLean = 0.0;
  // [v1.19] Per-cycle flag: was the wrist observed ABOVE THE NOSE
  // landmark at any point during TOP? This is the geometrically
  // robust "did the user actually lock out overhead" check.
  // Distance-of-camera-independent because it compares two landmarks
  // in the same frame (no torso normalization needed). A real OHP
  // lockout puts the wrist clearly above the head; a rack hold puts
  // the wrist at clavicle, well BELOW the head. See the count-time
  // check for the rationale on why this needed adding.
  //
  // [v1.32] Hardened: the flag is now armed only after the wrist has
  // been observed above the nose BY A REAL MARGIN
  // (HEAD_CROSS_MARGIN_TORSO) on HEAD_CROSS_SUSTAINED_FRAMES TOP
  // frames — see currentRepWristOverNoseFrames. One zero-margin
  // jitter frame during rack handling can no longer arm the proof.
  bool currentRepWristCrossedHead = false;
  int currentRepWristOverNoseFrames = 0;
  // The most extreme observed values per rep:
  //   currentRepMinHeadThrough — the lowest (most negative) value of
  //     (wristX - noseX) / torsoH observed during the TOP phase. A
  //     correctly-finished lockout shows the head slightly forward of
  //     the wrists (positive). A bad lockout shows the head behind
  //     the wrists (negative). We record the worst, but only while
  //     the user is at TOP — elsewhere the comparison isn't
  //     meaningful.
  //
  //   [v1.29] The reported value is now the SECOND-worst TOP frame,
  //   not the single worst. currentRepMinHeadThrough1 holds the
  //   absolute worst; currentRepMinHeadThrough (the value that gets
  //   scored/reported) holds the runner-up. A single noisy nose or
  //   wrist frame therefore can't set the rep's head-through value —
  //   a real "head not pushed through" persists across many TOP
  //   frames, so its second-worst ≈ worst and nothing is lost.
  //   currentRepHeadThroughFrames counts how many TOP frames actually
  //   produced a measurement; scoring requires HEAD_THROUGH_MIN_FRAMES
  //   of them before trusting the metric.
  //
  //   currentRepMaxElbowFlare — the highest observed elbow X-offset
  //     from the shoulder (normalized by torso). Recorded only during
  //     BOTTOM phase, where the rack position is what we want to
  //     measure. In ASCENDING/TOP the elbow naturally moves under
  //     the wrist and the X-offset isn't a flare signal.
  double currentRepMinHeadThrough1 = 999.0; // absolute worst (spike-prone)
  double currentRepMinHeadThrough = 999.0; // second-worst (used for scoring)
  int currentRepHeadThroughFrames = 0;
  double currentRepMaxElbowFlare = 0.0;
  // [v1.6] Track maximum shoulder X-separation during the rep. If
  // we observe a clearly frontal view (sep > FRONTAL_VIEW_SHOULDER_SEP)
  // at any point during the rep, the HEAD_THROUGH metric is suppressed
  // for that rep — the metric requires side view to be meaningful.
  double currentRepMaxShoulderSep = 0.0;
  // [v1.8] Count of BOTTOM frames where flare can be reliably measured
  // (frontal/back view + both arms visible). If too few, the flare
  // measurement is suppressed (neutral 7.0, no feedback). This makes
  // the elbow-flare feedback "adaptive" — it only surfaces when we
  // have a confident view of the user's arms.
  int currentRepFlareConfidentFrames = 0;
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

    // Bilateral arm angle computation. Each side's confidence is
    // (avg of shoulder, elbow, wrist vis). We take the side with
    // higher confidence as the primary measurement, and if the other
    // side is also confident AND agrees within tolerance, average
    // them — produces a more stable signal than either side alone.
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
      // Choose how to combine them based on whether they agree:
      //
      // A) Both arms show similar angles (within BILATERAL_DISAGREE_DEG)
      //    OR both arms show elevation (both > 120°):
      //    → use MAX. In a real press, both arms extend together; the
      //    occluded side often under-reports by 10-20° because ML Kit
      //    interpolates from its pose prior. Taking the max recovers
      //    the true lockout angle. The "both > 120°" check catches the
      //    high-elevation case where one arm reads 165° and the other
      //    reads 145° — that's a real lockout where MAX is right.
      //
      // B) Arms disagree wildly AND not both elevated (one is high,
      //    one is way down):
      //    → trust the HIGHER-visibility side. This catches ML Kit's
      //    failure mode where it places one wrist randomly near the
      //    body, producing an elbow angle of ~180° on the bad arm
      //    while the real arm is at 90°. MAX would call that a
      //    lockout (false positive in walking videos).
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
    final double dxLean = midShX - midHpX;
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
    // HEAD_THROUGH: how far the head is forward of the wrists in X,
    // normalized by torso height. At a proper lockout the head pushes
    // through under the bar, so the head sits forward of the wrists.
    // We compute this every frame but only RECORD it during TOP, where
    // it has anatomical meaning.
    // Sign convention: positive = head forward of wrists (good);
    // negative = head behind wrists (need to push through).
    final double torsoUnitForMetrics = math.max(0.05, torsoHeightEma ?? 0.05);
    final List<double>? nosePos = (normLandmarks[0][2] > 0.0)
        ? [normLandmarks[0][0], normLandmarks[0][1]]
        : null;
    double? headThroughValue;
    if (nosePos != null) {
      // wristX - noseX > 0 means wrist is to the RIGHT of nose (in
      // image coords). But for "head forward of wrists" we need to
      // know which way the user is facing. Use a side-view-friendly
      // formulation: if the camera sees the press from the side, the
      // head pushing forward will end up between the wrists and the
      // toes. The simplest robust measure: ABSOLUTE distance between
      // head X and wrist X, signed by which is closer to mid-hip X
      // (the head should be FURTHER from mid-hip than wrists are at
      // good lockout).
      //
      // For now use a simpler approximation: track |noseX - midHipX|
      // vs |wristX - midHipX|. If head is further from hip than
      // wrists are, head is "pushed through".
      final double noseDistFromHip = (nosePos[0] - midHpX).abs();
      final double wristDistFromHip = (primaryWristX - midHpX).abs();
      headThroughValue =
          (noseDistFromHip - wristDistFromHip) / torsoUnitForMetrics;
    }

    // ELBOW_FLARE [v1.7]: how much each elbow extends LATERALLY
    // BEYOND its wrist, normalized by torso height. Recorded only
    // during BOTTOM phase. Use the MAX of the two arms so that even
    // unilateral flaring (one arm out) registers.
    //
    // The body centerline X (mid-shoulder X) is the reference. For
    // each side we measure how far the elbow is from centerline,
    // subtract how far the WRIST is from centerline, and clamp to 0
    // (an elbow that's INSIDE the wrist is fine — not a flare).
    //
    // This metric is robust to grip width: a wide-grip user with
    // forward elbows scores the same as a narrow-grip user with
    // forward elbows. Old metric (vs shoulder) confused grip width
    // with flare.
    final double bodyCenterX = (lShPos[0] + rShPos[0]) / 2.0;
    final double leftElbowOutward = math.max(
        0.0, (lElPos[0] - bodyCenterX).abs() - (lWrPos[0] - bodyCenterX).abs());
    final double rightElbowOutward = math.max(
        0.0, (rElPos[0] - bodyCenterX).abs() - (rWrPos[0] - bodyCenterX).abs());
    final double elbowFlareNorm =
        math.max(leftElbowOutward, rightElbowOutward) / torsoUnitForMetrics;

    // ---- Update per-rep metrics ----
    if (phase == _PHASE_BOTTOM ||
        phase == _PHASE_ASCENDING ||
        phase == _PHASE_TOP ||
        phase == _PHASE_DESCENDING) {
      if (elbowEma! < currentRepMinElbow) currentRepMinElbow = elbowEma!;
      if (elbowEma! > currentRepMaxElbow) currentRepMaxElbow = elbowEma!;
      if (leanEma! > currentRepMaxLean) currentRepMaxLean = leanEma!;

      // Track head-through only at TOP (the only phase where the
      // measurement is anatomically meaningful — at the bottom the
      // user's head is naturally behind the bar).
      //
      // [v1.29] Two-slot minimum tracker: currentRepMinHeadThrough1
      // holds the absolute worst frame, currentRepMinHeadThrough
      // (the scored value) holds the SECOND-worst. A single noisy
      // frame lands in slot 1 and never reaches the scored slot;
      // a real, persistent "head behind bar" fills both slots with
      // nearly identical values. We also count measured frames so
      // scoring can require a minimum sample size.
      if (phase == _PHASE_TOP && headThroughValue != null) {
        currentRepHeadThroughFrames += 1;
        if (headThroughValue < currentRepMinHeadThrough1) {
          currentRepMinHeadThrough = currentRepMinHeadThrough1;
          currentRepMinHeadThrough1 = headThroughValue;
        } else if (headThroughValue < currentRepMinHeadThrough) {
          currentRepMinHeadThrough = headThroughValue;
        }
      }

      // [v1.19] Track whether wrist rose above nose during TOP —
      // the geometric "real lockout" gate at count time. Defeats the
      // rack false-rep family regardless of how small / unreliable
      // torsoUnit may be on far-away subjects, because both landmarks
      // are observed in the same frame at the same scale.
      //
      // [v1.32 HARDENED] Requires the wrist ABOVE the nose by a real
      // margin (HEAD_CROSS_MARGIN_TORSO of torso) on
      // HEAD_CROSS_SUSTAINED_FRAMES TOP frames before the flag arms.
      // Rack handling puts the wrist within jitter distance of the
      // nose (measured as close as 3% torso below), so the old
      // zero-margin single-frame check could be armed by one noisy
      // frame — which is how a rack-settle cycle got counted as
      // "rep 1". A real lockout clears the nose by 30–70% torso for
      // the entire TOP phase and is unaffected.
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

      // [v1.32] Track the same-frame wrist-above-shoulder maximum
      // while at TOP — the peak side of the shoulder-relative ascent
      // gate (see startWristAboveShNorm).
      if (phase == _PHASE_TOP && wristYEma != null) {
        final double aboveSh = midShY - wristYEma!;
        if (peakWristAboveShNorm == null || aboveSh > peakWristAboveShNorm!) {
          peakWristAboveShNorm = aboveSh;
        }
      }

      // [v1.6] Track shoulder X-separation throughout the rep. Used
      // to detect frontal view (separation > FRONTAL_VIEW_SHOULDER_SEP)
      // so we can suppress HEAD_THROUGH scoring in that case (the
      // metric is meaningless from a frontal angle — see HEAD_THROUGH
      // comments in TuningParams).
      final double shoulderSep = (lShPos[0] - rShPos[0]).abs();
      if (shoulderSep > currentRepMaxShoulderSep) {
        currentRepMaxShoulderSep = shoulderSep;
      }

      // Track elbow flare only at BOTTOM (the rack position is where
      // flare is meaningful and dangerous; during the press the elbow
      // naturally moves under the wrist).
      //
      // [v1.8 ADAPTIVE GATE]: Only count this frame for flare
      // measurement if BOTH conditions are met:
      //   1. The shoulder X-separation indicates a frontal/back view
      //      where lateral elbow movement is actually visible (side
      //      views and weird angles like bottom-up shots can't
      //      reliably distinguish flared from forward elbows).
      //   2. Both arms' elbow and wrist landmarks are visible enough
      //      to trust their X coordinates.
      //
      // We track how many BOTTOM frames passed both checks. The
      // scoring section requires MIN_FLARE_CONFIDENT_FRAMES before
      // showing flare feedback — otherwise the score is neutral
      // (7.0) and no feedback fires. This prevents false alarms
      // when the camera angle doesn't let us see flare.
      if (phase == _PHASE_BOTTOM) {
        final bool viewIsFrontalOrBack =
            shoulderSep >= TuningParams.FRONTAL_VIEW_SHOULDER_SEP;
        final bool armsVisible = lElV >= TuningParams.FLARE_ARM_VIS_THRESHOLD &&
            rElV >= TuningParams.FLARE_ARM_VIS_THRESHOLD &&
            lWrV >= TuningParams.FLARE_ARM_VIS_THRESHOLD &&
            rWrV >= TuningParams.FLARE_ARM_VIS_THRESHOLD;
        if (viewIsFrontalOrBack && armsVisible) {
          currentRepFlareConfidentFrames += 1;
          if (elbowFlareNorm > currentRepMaxElbowFlare) {
            currentRepMaxElbowFlare = elbowFlareNorm;
          }
        }
      }

      currentRepWristX.add(primaryWristX);
    }

    // [v1.3] Update peak wrist position while at TOP. We track the
    // smallest wristYEma observed (= highest wrist position in image
    // coords), so the descent envelope check has the correct reference
    // point. Reset of topPeakWristY happens on transitions INTO TOP
    // (see the "phase = _PHASE_TOP" assignments below).
    if (phase == _PHASE_TOP) {
      if (topPeakWristY == null || wristYEma! < topPeakWristY!) {
        topPeakWristY = wristYEma;
      }
    }

    // ---- Phase conditions ----
    final double torsoUnit = math.max(0.05, torsoHeightEma ?? 0.05);
    final bool wristNearShoulder = wristYEma! >=
        midShY - TuningParams.WRIST_BOTTOM_MAX_ABOVE_SHOULDER * torsoUnit;
    final bool wristAboveShoulder = wristYEma! <=
        midShY - TuningParams.WRIST_TOP_MIN_ABOVE_SHOULDER * torsoUnit;

    // For the BOTTOM check used during IDLE (start gate), we require
    // BOTH conditions — to distinguish a real "bar racked at shoulder"
    // setup from "person standing around". But during an active set
    // (any phase past IDLE), we only require the elbow angle to be
    // bent. Reasoning: once the user is mid-set, they're not going to
    // randomly become "bar at shoulder height" — and forcing the wrist
    // to settle exactly at the shoulder line can fail in some videos
    // due to EMA smoothing lag, causing reps after the first to be
    // missed.
    final bool isBottomStrict =
        (elbowEma! <= cfgBottomElbowMax) && wristNearShoulder;

    // [v1.12] BOTTOM detection now has a SECOND PATH via wrist descent
    // from peak. Previously we only checked the elbow angle, which
    // failed in production when ML Kit's elbow estimate stayed
    // unexpectedly HIGH (above the BOTTOM threshold of 110°) during
    // the descent of certain reps — even though the wrist clearly
    // came down. The state machine could not transition out of TOP/
    // DESCENDING in those cycles, so two-three real reps would
    // "merge" into one count, and the state machine would only
    // recover once the user finally rested at the bottom hard enough
    // for ML Kit to register a low elbow.
    //
    // Symptoms in the field:
    //   - One real rep peak gets missed entirely (e.g., HEIGHT 82%
    //     followed by HEIGHT 22% descent followed by HEIGHT 75% peak
    //     — all observed cleanly on the wrist signal — but the
    //     counter only ticks up once across both peaks).
    //   - Later, a tiny ascent (e.g., the bar resettling on the rack)
    //     gets counted as a rep, because the state machine is now
    //     out-of-sync with the user's actual rep boundaries.
    //
    // The wrist path requires the wrist Y to have descended at least
    // 30% torsoUnit from this TOP-phase's recorded peak. That's a
    // large, unambiguous descent (a real rep descends 50-100% torso)
    // — far above noise, well below what a partial rep needs.
    //
    // This path only fires when topPeakWristY is set (i.e., during
    // DESCENDING phase, after we've been at TOP). For ASCENDING-phase
    // checks (abort), it stays false, preserving the existing logic.
    final bool isBottomWristDescended = (topPeakWristY != null) &&
        ((wristYEma! - topPeakWristY!) >= 0.30 * torsoUnit);
    final bool isBottomDuringSet =
        (elbowEma! <= cfgBottomElbowMax) || isBottomWristDescended;

    // [v1.17] Universal real-bottom gate counter.
    // [v1.31] Moved below isBottomWristDescended and given a SECOND
    // qualifying path: a full wrist descent back to shoulder level
    // after a confirmed TOP peak counts as a real-bottom observation
    // too. This survives the documented ML Kit elbow under-reporting
    // failure (v1.2/v1.12), where elbowEma never dips below 110° even
    // though the wrist clearly returns to the clavicle — previously
    // killing the first count on 'realBottomObs<3'. The rack-descent
    // false-positive family stays blocked: this path requires
    // topPeakWristY (only set in TOP) AND wristNearShoulder, and
    // counting still requires the v1.19 wristCrossedHead / 50%-torso
    // lockout proof, which a rack hold can never satisfy.
    if (isBottomStrict) {
      realBottomFramesObserved += 1;
    } else if (isBottomWristDescended && wristNearShoulder) {
      realBottomFramesObserved += 1;
    }

    // [v1.2 wrist-based TOP fallback] In practice ML Kit on FlutterFlow
    // reports elbow angles that are significantly LOWER than the actual
    // anatomical angle when the arms are overhead. We observed this
    // empirically: a real lockout (visually ~170°) was being reported
    // around ~100° by ML Kit, causing the elbow-based isTop gate to
    // never fire even though the user clearly pressed the bar overhead.
    //
    // The HEIGHT donut in the UI (which is driven by wrist position
    // alone, not elbow angle) showed peaks of 50-70% during these
    // presses, confirming ML Kit *does* track the wrist correctly even
    // though it under-reports the elbow angle.
    //
    // The fix: detect TOP via EITHER path:
    //   PATH A (classic): elbow extended >= cfgTopElbowMin AND wrist
    //     a bit above shoulder. Used when ML Kit reports reasonable
    //     elbow angles.
    //   PATH B (wrist-based): wrist is WAY above the shoulder line
    //     (18%+ of torso height) AND there's at least minimal elbow
    //     extension (>= 80°, to reject "arms still bent at shoulder").
    //     Used when ML Kit under-reports elbow angles. The strict
    //     wrist threshold (18% > the 10% used in PATH A) is the
    //     anti-false-positive safeguard: only a genuine overhead
    //     position satisfies it.
    //
    // Simulation showed PATH B firing 35+ times in the user's video
    // and recovering all 9 reps where the elbow-only gate found just 2.
    final bool wristWayAboveShoulder = wristYEma! <=
        midShY - TuningParams.WRIST_ALONE_TOP_THRESHOLD * torsoUnit;
    final bool isTopElbowPath =
        (elbowEma! >= cfgTopElbowMin) && wristAboveShoulder;
    final bool isTopWristPath = wristWayAboveShoulder && (elbowEma! >= 80.0);
    final bool isTop = isTopElbowPath || isTopWristPath;

    // [v1.3] Envelope-based descent detection.
    //
    // Production bug observed: when a user does fast consecutive reps
    // without re-racking the bar (touch-and-go style), the wrist never
    // drops below the wristWayAbove threshold between reps. The state
    // machine therefore stays "at TOP" through multiple rep cycles and
    // counts only the first rep. The counter only "unsticks" when the
    // user finally pauses and the wrist drops to shoulder level.
    //
    // The fix is to detect the directional change in the wrist signal,
    // not just the absolute position. We track the highest the wrist
    // has reached during the current TOP phase (= smallest Y value,
    // since Y is image-coords with 0 at top). Once the wrist has
    // descended by >= WRIST_DESCENT_FROM_PEAK torso units from that
    // peak FOR WRIST_DESCENT_SUSTAINED_FRAMES consecutive frames, we
    // know a real descent has started — even if the wrist is still
    // well above the shoulder.
    //
    // [v1.5] The sustained-frames requirement is what distinguishes a
    // real descent from noise. ML Kit's wrist Y signal can have
    // single-frame jitter that exceeds the threshold momentarily.
    // Without sustained-frames, this jitter caused a single lockout
    // hold to be misclassified as TWO descent events — counting
    // double for a single rep.
    //
    // topPeakWristY is declared outside the loop and reset whenever
    // we enter TOP from a non-TOP phase. See the state machine's
    // TOP-entry transitions below.
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
    //  - Elbow has dropped below the hysteresis band (works when ML
    //    Kit reports elbow angle correctly)
    //  - Envelope-based sustained descent: wrist has come down from
    //    its peak in this TOP phase for multiple consecutive frames
    //    (works when ML Kit under-reports the elbow angle and the
    //    user does fast consecutive reps).
    final bool clearlyNotTop =
        (elbowEma! < cfgTopElbowMin - TuningParams.HYSTERESIS_BAND) ||
            wristDescendedFromPeak;
    final bool clearlyNotBottom =
        elbowEma! > cfgBottomElbowMax + TuningParams.HYSTERESIS_BAND;

    framesInPhase += 1;
    final bool enoughInPhase = framesInPhase >= MIN_PHASE_FRAMES;

    // ---- State machine ----
    // Detection-quality gate: don't trust any frame for state changes
    // unless we can see the torso well enough. ML Kit sometimes
    // hallucinates landmarks when only a partial body is in frame —
    // we'd see an arm sticking out somewhere and a tiny "torso"
    // (shoulder-to-hip distance < 10% of frame). Those frames make
    // false positives very easy if we let them through.
    final bool torsoVisibleEnough =
        (torsoHeightEma ?? 0) >= TuningParams.MIN_TORSO_HEIGHT_FOR_START;

    switch (phase) {
      case _PHASE_IDLE:
        // Three ways to leave IDLE:
        //   1. The classic path — the user is detected in BOTTOM
        //      (arms at shoulder, elbow bent) and dwells there long
        //      enough to look like a real setup. Filters walk-in.
        //   2. [v1.31] The fast-first-rep rescue — the user reached a
        //      real strict BOTTOM but left it before completing the
        //      dwell (pressed immediately after unracking), and a
        //      genuine TOP is observed within the rescue window.
        //   3. The "started in motion" path — the user is detected
        //      already at STRICT TOP for many consecutive frames AND
        //      the torso is fully visible.
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
            currentRepWristX.clear();
            currentRepAscendingFrames = 0;
            currentRepDescendingFrames = 0;
          }
        } else {
          // [v1.31] A strict-bottom dwell was just interrupted before
          // completing the START_GATE. Stash it for the rescue path —
          // a fast presser leaves the bottom within a few frames of
          // reaching it, which is exactly the case the rescue exists
          // for. Requires >= 2 observed frames so a single-frame ML
          // Kit flicker can never arm the rescue.
          if (bottomDwellFrames > 0) {
            lastShortDwellFrames = bottomDwellFrames;
            lastShortDwellEndFrame = frameIdx1Based;
            lastShortDwellStartFrame = bottomDwellStartFrame;
            lastShortDwellStartWristY = bottomDwellStartWristY;
            lastShortDwellStartAboveSh = bottomDwellStartAboveSh; // [v1.32]
          }
          bottomDwellFrames = 0;

          // [v1.31] FAST-FIRST-REP RESCUE. Fire only when ALL hold:
          //   - a strict bottom was observed for >= 2 frames recently
          //     (within RESCUE_WINDOW_FRAMES of the current frame),
          //   - a genuine TOP (full isTop gate: elbow path OR strict
          //     18%-torso wrist path) is observed right now,
          //   - the torso is properly visible.
          // A walk-in never produces the strict-bottom half of the
          // pair; a rack hold never produces the TOP half within the
          // window (the bar sits at rack height, and even if it did,
          // the v1.19 head-cross count gate still blocks the count).
          // The cycle is anchored at the observed bottom so the v1.9
          // ascent gate measures the true rise.
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
            currentRepWristX.clear();
            currentRepAscendingFrames = 0;
            currentRepDescendingFrames = 0;
            lastShortDwellFrames = 0;
            idleTopDwellFrames = 0;
            break;
          }

          // For IDLE→TOP, use the STRICT lockout gate (160°+) — see
          // TuningParams.IDLE_TO_TOP_STRICT_ELBOW_MIN comments. The
          // lenient counting threshold of 115° would let walking
          // gestures through here, since no observed BOTTOM validates
          // the transition.
          final bool isStrictTop = elbowEma! >=
                  TuningParams.IDLE_TO_TOP_STRICT_ELBOW_MIN &&
              wristYEma! <=
                  midShY -
                      TuningParams.IDLE_TO_TOP_STRICT_WRIST_ABOVE * torsoUnit;
          if (isStrictTop && torsoVisibleEnough) {
            idleTopDwellFrames += 1;
            if (idleTopDwellFrames >=
                TuningParams.IDLE_TO_TOP_MIN_DWELL_SEC_EQUIV) {
              // Confirmed strict lockout dwell — user is mid-set OR
              // standing at the rack with the bar already raised.
              // Enter TOP directly. We rely on the v1.17
              // realBottomFramesObserved gate to prevent counting
              // a rep before the user has actually been observed at
              // the real clavicle-height bottom position — without
              // that, the first descent from rack height would be
              // miscounted as a rep.
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
              // [v1.32] Hardened head-cross: seed the sustained
              // counter (with margin) instead of arming from a
              // single zero-margin frame.
              currentRepWristCrossedHead = false;
              currentRepWristOverNoseFrames = (nosePos != null &&
                      wristYEma != null &&
                      (nosePos[1] - wristYEma!) >=
                          TuningParams.HEAD_CROSS_MARGIN_TORSO * torsoUnit)
                  ? 1
                  : 0;
              // [v1.29] Two-slot tracker: this frame's observation
              // (if any) goes into the worst slot; the scored
              // second-worst slot starts empty. Frames counter
              // starts at 1 only if a measurement exists.
              currentRepMinHeadThrough1 = headThroughValue ?? 999.0;
              currentRepMinHeadThrough = 999.0;
              currentRepHeadThroughFrames = (headThroughValue != null) ? 1 : 0;
              currentRepMaxElbowFlare = 0.0;

              currentRepMaxShoulderSep = 0.0; // we never observed bottom

              currentRepFlareConfidentFrames = 0;
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
        // [v1.1 fast-press shortcut] If the press is so quick that the
        // ASCENDING phase is briefer than a single frame at our sampling
        // rate, the EMA peak fires on the same frame that BOTTOM→ASCENDING
        // would transition — and by the next frame the angle has already
        // started dropping. Without this shortcut, we'd transition to
        // ASCENDING, fail to see isTop in the next frame, and abort back
        // to BOTTOM, never counting the rep.
        //
        // The shortcut is safe because isTop is a STRONG gate — it
        // requires BOTH elbow >= cfgTopElbowMin AND wrist clearly above
        // shoulder (>=10% torso). Random gestures (waving, stretching,
        // celebrating) won't reach BOTH simultaneously while we're in
        // BOTTOM phase. We also keep enoughInPhase so we don't flip
        // immediately from a transient.
        //
        // currentRepStartFrame is intentionally NOT reset here — it was
        // set when we entered BOTTOM (from IDLE or from a previous
        // DESCENDING→BOTTOM rep completion), and we want to keep that
        // cycle anchor.
        if (isTop && enoughInPhase) {
          phase = _PHASE_TOP;
          topPeakWristY = wristYEma; // [v1.3] envelope tracking
          // [v1.32] Seed the same-frame above-shoulder peak (kept as
          // max across the whole rep — see the tracker in the
          // per-rep metrics block).
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
        // No MIN_PHASE_FRAMES check on going to TOP — the lockout peak
        // can be a single frame in a fast press, and EMA smoothing
        // already cleaned up noise. Requiring multiple frames at the
        // peak misses brief but real lockouts.
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

          // [v1.9] Real-ascent gate. Verify that the wrist actually
          // travelled UPWARD during this rep cycle. Without this check,
          // the state machine can complete a phantom BOTTOM→ASCENDING
          // →TOP→DESCENDING→BOTTOM cycle during the descent of a real
          // rep, producing a false extra count.
          //
          // A genuine rep has:
          //   wristYAtCycleStart (low position, large Y value)
          //     − topPeakWristY (high position, small Y value)
          //   = positive ascent, typically 20-50% torso
          //
          // A phantom cycle during a descent has:
          //   wristYAtCycleStart ≈ topPeakWristY (state was confused —
          //     never actually ascended), so ascent ≈ 0 or even
          //     negative.
          final double ascentMagnitudeAbs =
              (wristYAtCycleStart != null && topPeakWristY != null)
                  ? wristYAtCycleStart! - topPeakWristY!
                  : 0.0;
          // [v1.32] The GATE now uses the SHOULDER-RELATIVE ascent:
          // (max same-frame wrist-above-shoulder during TOP) minus
          // (same-frame wrist-above-shoulder at cycle start). The
          // absolute image-Y version above silently assumed the body
          // stays put in the frame across the whole cycle — but a
          // user who unracks and WALKS BACK sinks the shoulder line
          // in the image, so the real first rep's lockout wrist-Y
          // lands near the OLD bottom's wrist-Y and the absolute
          // ascent collapses to ~0, killing the count with
          // 'ascent<15%torso' (the exact "real first rep missed"
          // production symptom, confirmed by simulation on the
          // user's video: ascAbs eroded to +0.78t where ascRel read
          // +1.01t, and with ML Kit's earlier IDLE exit the absolute
          // value goes negative). The relative measure is
          // translation-invariant — body drift in frame cancels —
          // while phantom cycles are still blocked exactly as
          // before: their "peak" above-shoulder height ≈ their
          // start's, so the relative rise is ≈ 0 too. The absolute
          // value is kept in the debug log as ascentAbs.
          final double ascentMagnitude =
              (startWristAboveShNorm != null && peakWristAboveShNorm != null)
                  ? peakWristAboveShNorm! - startWristAboveShNorm!
                  : ascentMagnitudeAbs; // fallback: pre-v1.32 behavior
          final bool ascentOk = ascentMagnitude >=
              TuningParams.MIN_RISE_FROM_CYCLE_START * torsoUnit;

          // [v1.18] Peak-height gate. A real OHP rep ends with the
          // bar fully overhead — the wrist needs to be FAR above the
          // shoulder for the cycle's peak to qualify as a press
          // lockout. The rack/unrack false-rep family of bugs all
          // share one property: the cycle's peak is at RACK HEIGHT,
          // which is only marginally above shoulder (typical rack
          // J-hook puts the wrist 30-45% torso above shoulder, well
          // below a real lockout's 80-150% torso). Without this
          // gate, the descent from rack-height to clavicle counts
          // as a rep — because the v1.9 ascent gate, the v1.17
          // real-bottom gate, the cycle length and refractory gates
          // all pass; only the peak-height check distinguishes the
          // rack descent from a real press.
          //
          // [v1.19] PRIMARY check is now wristCrossedHead — the
          // wrist must have risen above the nose landmark at some
          // point during TOP. This is geometrically robust because
          // it compares two landmarks observed in the same frame at
          // the same scale, eliminating any dependence on the
          // potentially-noisy torsoUnit estimate (which the v1.18
          // 50%-torso threshold relied on, and which fails on
          // far-away subjects whose torsoUnit can be under-estimated
          // making the threshold too permissive).
          //
          // The v1.18 torso-relative check remains as a FALLBACK
          // for the rare case where the nose was never detected
          // during TOP (e.g., back-view recordings where the face
          // never appears clearly enough for ML Kit). The 50% torso
          // threshold is well above realistic rack heights but
          // below any real lockout. EITHER check passing is enough.
          final bool peakReachedRealLockout = currentRepWristCrossedHead ||
              (topPeakWristY != null &&
                  topPeakWristY! <= midShY - 0.50 * torsoUnit);

          // [v1.21] Cycle-start hand position gate. A real OHP rep
          // starts with the wrist at clavicle/shoulder height (the
          // bar resting on the front of the shoulders, hands gripping
          // it). If the cycle's recorded start position has the wrist
          // significantly BELOW the shoulder (= hands hanging at the
          // sides / hip level), the cycle isn't a real OHP rep — it's
          // the user transitioning from standing-with-arms-down into
          // OHP setup (e.g., before unracking).
          //
          // Diagnosed from actual telemetry: the false-rack-rep cycle
          // showed wristYAtCycleStart = 0.4471 with midShY = 0.3546
          // and torsoUnit = 0.129 → wrist 72% torso BELOW shoulder.
          // Real reps in the same video showed wristYAtCycleStart in
          // the range "30% torso ABOVE shoulder" to "0% torso below"
          // (clavicle-level start).
          //
          // Threshold 30% torso below shoulder is comfortably below
          // any realistic OHP setup position (clavicle is at or
          // slightly above shoulder), and comfortably above hands-
          // hanging-at-sides (which is 60-80% torso below shoulder).
          final bool cycleStartedAtRealOHPSetup =
              (wristYAtCycleStart != null) &&
                  (wristYAtCycleStart! <= midShY + 0.30 * torsoUnit);

          // [v1.31] Motion-only cycle length (ascent start → count).
          // Excludes any bottom-rest / setup dwell that preceded the
          // ascent. Used by the post-process length filter instead of
          // the full cycleLengthFrames — see the pulse event fields.
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
          // [v1.22] cycleStartedAtRealOHPSetup no longer affects the
          // count outcome — it's still computed and logged in the
          // debug record for diagnostic purposes, but does not
          // contribute to _failReasons or willCount.
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
            final double lockoutScore = scoreInterp(
              currentRepMaxElbow,
              TuningParams.LOCKOUT_TARGET_ANGLE,
              TuningParams.LOCKOUT_OK_ANGLE,
              TuningParams.LOCKOUT_OK_ANGLE - 15.0,
              higherIsBetter: true,
            );
            final double leanScore = scoreInterp(
              currentRepMaxLean,
              TuningParams.LEAN_TARGET_MAX,
              TuningParams.LEAN_OK_MAX,
              TuningParams.LEAN_BAD_MAX,
              higherIsBetter: false,
            );
            // HEAD_THROUGH score: HIGHER value (head further forward
            // of wrists) is better. If we never observed the user at
            // TOP (e.g. IDLE→TOP shortcut couldn't measure it), the
            // sentinel 999.0 is in place — give a neutral 7.0 (don't
            // penalize for missing data).
            //
            // [v1.6] We also suppress HEAD_THROUGH when the camera is
            // looking at the user head-on (frontal view, shoulder X
            // separation > FRONTAL_VIEW_SHOULDER_SEP). In a frontal
            // view both head and wrist sit near the body centerline X,
            // making the metric (|noseX-hipX| - |wristX-hipX|)/torsoH
            // noise-dominated and meaningless. Skipping it here means
            // a perfectly-executed press filmed from the front no
            // longer gets the "Push your head through at the top"
            // feedback it doesn't deserve.
            //
            // [v1.29] Third suppression condition: not enough measured
            // TOP frames (< HEAD_THROUGH_MIN_FRAMES). A 1-2 frame TOP
            // phase can't produce a trustworthy head-through reading —
            // and with the two-slot tracker, 1 measured frame leaves
            // the scored slot at the 999.0 sentinel anyway. Same
            // adaptive-silence pattern as ELBOW_FLARE's
            // MIN_FLARE_CONFIDENT_FRAMES: better silent than wrong.
            final bool isFrontalView = currentRepMaxShoulderSep >
                TuningParams.FRONTAL_VIEW_SHOULDER_SEP;
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
            // ELBOW_FLARE score [v1.8]: Adaptive — only score if we
            // had enough BOTTOM frames where the view was frontal/back
            // AND both arms were visible. The per-frame tracker
            // (currentRepFlareConfidentFrames) counts how many BOTTOM
            // frames met both conditions. Below the minimum, we treat
            // it as "no observation" and give a neutral 7.0 score
            // (skipping feedback too — see the issues block).
            //
            // This silences the false "Don't flare your elbows" alarm
            // on side views, bottom-up angles, or any shot where the
            // user's arms aren't both clearly visible from a viewpoint
            // that can actually see lateral elbow movement.
            //
            // For lower values: LOWER is better (elbow at most as
            // wide as wrist — see ELBOW_FLARE_TARGET).
            final double elbowFlareScore;
            final bool flareReliable = currentRepFlareConfidentFrames >=
                TuningParams.MIN_FLARE_CONFIDENT_FRAMES;
            if (!flareReliable) {
              elbowFlareScore = 7.0; // no reliable observation, neutral
            } else {
              elbowFlareScore = scoreInterp(
                currentRepMaxElbowFlare,
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
            // Only surface HEAD_THROUGH if we actually observed it
            // (otherwise the score is the "no observation" neutral 7).
            // [v1.6] Also suppress in frontal view (see scoring block).
            // [v1.29] Also suppress when the observation is unreliable
            // (too few measured TOP frames).
            if (currentRepMinHeadThrough < 100.0 &&
                !isFrontalView &&
                headThroughReliable &&
                headThroughScore < TuningParams.REP_FEEDBACK_SCORE_THR) {
              issues.add(FB_HEAD_THROUGH);
            }
            // [v1.8] Only surface ELBOW_FLARE if the measurement is
            // reliable (enough BOTTOM frames with frontal-view + arm
            // visibility). Otherwise stay silent — better than a false
            // alarm.
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
              // [v1.14] A rep is "good" only when it has ZERO form issues
              // (= passed every category's feedback threshold). Previously
              // a rep with one minor issue could still be "good" if the
              // overall score was above 7 — but for production reporting
              // we want "good" to mean "the user nailed this one, no
              // notes". Reps with any issue (however minor) are flagged
              // for improvement.
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
              // [v1.23] Peak height (above-shoulder, normalized) used
              // by the post-process outlier filter to identify cycles
              // that don't represent real OHP reps. A rack/unrack
              // motion has wrist briefly above shoulder but well below
              // a real lockout; comparing each cycle's peak against
              // the SESSION'S MAX peak catches these naturally —
              // robust to camera distance and torsoUnit noise because
              // it's a relative comparison within the same recording.
              // [v1.32] Now uses the SAME-FRAME above-shoulder peak
              // (peakWristAboveShNorm) instead of mixing the
              // count-frame shoulder with the peak-frame wrist — the
              // old mix was biased on subjects who drift in the frame
              // (walk-back after unrack), the same translation issue
              // fixed in the ascent gate.
              'peakAboveShoulderNorm': peakWristAboveShNorm ??
                  ((topPeakWristY != null) ? (midShY - topPeakWristY!) : 0.0),
              // [v1.24] Ascent magnitude in torso units. A walk-up
              // cycle (where IDLE→BOTTOM fired when the user was
              // standing with hands at hips, before approaching the
              // bar) has a HUGE ascent (the cycle "starts" at hip
              // and ends with the wrist overhead = 150-200% torso),
              // whereas a real rep's ascent is from clavicle to
              // overhead (≈50-70% torso). The post-process filter
              // uses this to catch walk-up cycles that wouldn't be
              // caught by the peak filter (because they DO include
              // a real press at the end, with full peak height).
              'ascentInTorso':
                  (torsoUnit > 0) ? (ascentMagnitude / torsoUnit) : 0.0,
              // [v1.27] Cycle length in frames. Kept for debug
              // comparability with older logs.
              'cycleLengthFrames': frameIdx1Based - cycleStartFrame,
              // [v1.31] MOTION-ONLY length (ascent start → count).
              // This is what the post-process length filter now uses
              // instead of cycleLengthFrames: it excludes bottom-rest
              // and setup dwell, so rep 1 (whose cycle includes the
              // whole post-unrack setup) and rest-pause reps are no
              // longer inflated past the 3x-median threshold and
              // deleted as "walk-ups".
              'motionLengthFrames': motionLenFrames,
              // [v1.31] Geometric lockout proof for the peak filter:
              // a cycle whose wrist provably crossed above the nose
              // during TOP is NEVER removed by the 70%-of-max peak
              // filter (an unrack motion can never satisfy this, so
              // the filter still catches its target case).
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
                // Clamp: don't let calibration push the counting
                // threshold above what we want to detect. The user
                // who managed 145° on their first 2 reps shouldn't
                // then need 145°+ to count future reps.
                //
                // The lower bound MUST match TOP_ELBOW_MIN_INIT (115)
                // — otherwise the clamp would yank a low-ROM user's
                // calibrated value back up to 125 and undo the v1.1
                // fix that lets them count partial reps in the first
                // place.
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
          currentRepWristX.clear();
          currentRepAscendingFrames = 0;
          currentRepDescendingFrames = 0;
        } else if (isTop && enoughInPhase) {
          // Bounce back up — go back to TOP and wait for real descent.
          phase = _PHASE_TOP;
          topPeakWristY = wristYEma; // [v1.3] envelope tracking
          // [v1.32] Extend (never reset) the above-shoulder peak —
          // the bounce belongs to the same rep, so the rep's true
          // peak must be preserved for the relative ascent gate.
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
  // POST-PROCESS 2: Place rep_just_finished pulse + feedback at the
  // visual peak (= lowest wristY in a window) instead of at the count
  // frame. Same pattern as the other analyzers — ensures the flash,
  // sound, and haptic line up with the moment the user perceives the
  // rep as complete (arms locked out overhead).
  // ============================================================
  for (final f in frameTelemetry) {
    f['rep_just_finished'] = null;
    f['feedback'] = null;
  }
  final int holdFramesAtPeak = math.max(2, (1.5 / dt).round());

  // [v1.26] Re-enables the peak-based post-process filter from v1.23.
  // Diagnosed from the user's frame-by-frame video: a rack/unrack
  // motion (lifting the bar briefly off the J-hooks to free it)
  // has a much LOWER peak than a real OHP lockout — in the test
  // video, HEIGHT 24% vs 52%. The unrack barely lifts the bar above
  // the rack height, while a real lockout fully extends overhead.
  //
  // The peak-based filter (peak < 70% of session max) cleanly
  // catches this case while leaving real reps untouched (real reps
  // cluster within 90-100% of each other). v1.25 disabled this
  // filter based on a test where all cycle peaks happened to be
  // similar — but that was a DIFFERENT user scenario (J-hooks set
  // high enough that the unrack required full extension). For the
  // typical case where unracking is a brief lift, the peak filter
  // works.
  //
  // [v1.31] The peak filter now NEVER removes a cycle whose wrist
  // provably crossed above the nose during TOP (wristCrossedHead,
  // the v1.19 geometric lockout proof). The 70% relative threshold
  // operates in raw normalized units and was deleting REAL reps
  // whose peak was slightly lower than the session's best
  // (partial-ROM variation between reps, camera-distance drift,
  // topPeakWristY noise). An unrack motion — the case the filter
  // exists for — can never cross the head, so the filter's target
  // behavior is fully preserved.
  //
  // The ascent filter (v1.24) remains DISABLED. It was rejecting
  // real first reps because the cycleStart was captured before
  // the user finished setting up.
  //
  // [v1.31] The length filter (v1.27) now compares MOTION length
  // (ascentStartFrame → count) instead of full cycle length. The
  // full cycle length includes bottom-rest and setup dwell, which
  // was inflating rep 1 (whose cycle spans the entire post-unrack
  // setup) and rest-pause reps past the 3x-median threshold —
  // deleting REAL reps as "walk-ups". Motion length excludes all
  // bottom dwell, so a walk-up cycle (long continuous approach
  // motion) still stands out while a rested-then-pressed rep looks
  // exactly like any other rep. An absolute floor
  // (CYCLE_LEN_FILTER_MIN_SEC = 4s of motion) additionally
  // guarantees that deliberately slow reps — which our own form
  // tip recommends — are never removed by the relative threshold.
  //
  // [v1.28] BEFORE the filter runs, annotate every pulseEvent with
  // its PREVIOUS ORIGINAL countFrameIdx. This is needed because the
  // filter may remove some events from pulseEvents, but the visual
  // peak placement still needs to know the boundary between cycles
  // (including removed ones) to avoid placing visual peaks on frames
  // belonging to removed cycles.
  //
  // Without this fix: after the filter removes cycle 1 (walk-up),
  // "rep 1" in the filtered list = original cycle 2. Visual placement
  // searches [searchStart, cycle2.countIdx] for min wristY. The
  // searchStart uses pulseEvents[e-1] which is now empty (since e==0
  // in filtered list), so it falls back to (countIdx - 36). That
  // range INCLUDES cycle 1's removed peak frame (frame 89, wristY
  // 0.228), which is the global min in the range — so visual rep 1
  // is misplaced onto cycle 1's removed peak instead of cycle 2's
  // real peak (frame ~102, wristY 0.2252).
  //
  // With this fix: rep 1's searchStart = max(92, 68) = 92, which
  // excludes cycle 1's peak. Min in [92, 104] is at cycle 2's peak.
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

    // [v1.27] Compute median cycle length, excluding the longest
    // cycle (which would be a walk-up cycle if it exists). This
    // gives us the "typical" rep duration to compare against.
    // [v1.31] Lengths are now MOTION lengths (ascent start → count),
    // with a fallback to cycleLengthFrames for safety. See the long
    // comment above for the rationale.
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
    // [v1.31] Absolute floor: no cycle with under
    // CYCLE_LEN_FILTER_MIN_SEC seconds of MOTION is ever removed by
    // the length filter, regardless of the relative comparison. A
    // real walk-up involves 4-6+ seconds of continuous motion; a
    // slow-but-real rep does not.
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
      // [v1.31] BUT: never remove a cycle where the wrist provably
      // crossed above the head during TOP. An unrack motion (bar at
      // clavicle/rack height) can NEVER satisfy the head-cross proof,
      // so the filter still catches exactly the case it was built
      // for — while a real rep with a slightly-lower-than-max peak
      // (partial-ROM variation, camera drift, landmark noise) is
      // untouchable.
      if (p < _peakThreshold && !_crossedHead) {
        reasons.add('peakBelow70pcMax');
      }
      // [v1.27] Length filter — catches walk-up cycles even when
      // the peak height matches real reps (because the user does
      // a full overhead motion during the unrack).
      // [v1.31] Now compares MOTION length against max(3x median,
      // absolute 4s floor) — bottom-rest no longer counts against
      // the rep, and slow reps are protected by the floor.
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
    // [v1.28] Use the previous ORIGINAL countFrameIdx (set before
    // the filter ran) rather than computing from the filtered
    // pulseEvents[e-1]. This ensures the search range excludes
    // frames that belong to filtered-out cycles.
    final int prevOrig1Based = (ev['_prevOrigCountFrameIdx'] as int?) ?? 0;
    final int prevCountIdx = (prevOrig1Based > 0) ? (prevOrig1Based - 1) : 0;

    // [v1.4] Bound the visual peak search to a recent window around
    // the count frame. Otherwise, for the FIRST rep, we search all
    // frames from 0 to the count frame — and any ML Kit hallucination
    // during the camera-shake/setup phase (fingers near lens, etc.)
    // that placed a "wrist" landmark high in the image would win as
    // the visual peak, causing the rep counter to visually increment
    // at that hallucinated frame instead of the actual rep peak.
    //
    // A real press rep takes ~6-15 frames at 12fps. We bound the
    // search to ~3x the maximum cycle length (= 3 seconds at 12fps =
    // 36 frames) before the count frame. This still covers any real
    // rep cycle while excluding far-away hallucinations.
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

    // Rewrite the 'reps' field on frames from peak forward to the
    // next peak (or end) — so the counter ticks up at the moment of
    // the lockout, not at the descent completion.
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
      // Build the full feedback list for this rep, sorted by severity
      // (strongest first). The widget can render these stacked
      // vertically — newline separated so a multi-line text widget
      // shows all of them, while a single-line widget still shows
      // the most severe issue at the top.
      //
      // We also expose the list as an array under a separate key so
      // a richer widget can format each line independently (color,
      // icons, etc.) without parsing the joined string.
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
        // Parallel array form for richer widgets — list of strings,
        // sorted by severity (strongest first). Single-line widgets
        // can ignore this field and read 'feedback' as before.
        frameTelemetry[j]['feedback_list'] = sortedIssues;
      }
    }
  }

  // ============================================================
  // Session summary
  // ============================================================
  // [v1.14] A rep counts as "good" only when it produced zero
  // feedback issues. See the per-rep 'good' assignment for the
  // rationale.
  //
  // [v1.30 CRITICAL FIX] Reset the tallies before counting. When the
  // post-process filter removed cycles, its "Re-tally good/bad" block
  // had ALREADY populated goodReps/badReps from repReports — and this
  // summary loop then added the same reps AGAIN on top, producing
  // impossible outputs like good_reps=12 with rep_count=7 (each rep
  // tallied twice). This summary loop is now the SINGLE source of
  // truth: it always starts from zero and counts the final, filtered
  // repReports exactly once. (The filter's re-tally is left in place
  // — it's harmless now and keeps the debug flow readable.)
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
  // [v1.30 FIX] The threshold is now a FLAT minimum (1 rep), not the
  // ratio-scaled max(1, 30% of reps) it used to be. The ratio version
  // created a logical contradiction the user sees directly on the
  // results screen: with 7 reps the threshold was round(7*0.30)=2, so
  // an issue that occurred in exactly ONE rep was filtered out of the
  // session feedback — and the UI fell back to "Great form! Keep it
  // up 💪" even though the score was 9 (not 10), bad_reps was 1, and
  // that same issue was visibly displayed on the rep inside the
  // analyzed video. "Great form" must mean a CLEAN session: every rep
  // issue-free. With the flat minimum, any issue that occurred at
  // least once surfaces in the session feedback, so the fallback
  // message can only appear when badReps == 0 — fully consistent
  // with the score, the good/bad counts, and the in-video feedback.
  // (This completes what v1.21 started when it lowered
  // SESSION_FEEDBACK_MIN from 2 → 1; the ratio term was still
  // overriding it via max() on sets of 4+ reps.)
  final int sessionMinCount = TuningParams.SESSION_FEEDBACK_MIN;
  // Use sessionFeedbackByCat (already populated during the loop) for
  // the per-category strongest-issue surface, but only include those
  // that occurred in enough reps.
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
  //
  // Each tip fires on its own threshold band. The bands are
  // specifically positioned so the tip ONLY shows up when the
  // metric is "passable but not perfect" — i.e., the user wouldn't
  // see a feedback message about it (because they're above the
  // OK threshold), but they're not crushing it either. This makes
  // the tips feel like coaching from a friendly trainer, not nags
  // repeating the negative feedback.
  //
  // Returned as both:
  //   `form_tips`: List<String> — all tips that fired.
  //   `tip`:       String? — the first tip (or null), kept for
  //               backward compatibility with consumers that only
  //               handle a single tip.
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
    // Tip 2 — full lockout. User is *almost* locking out but
    // leaving range on the table.
    if (avgTopElbow >= TIP_LOCKOUT_NEAR_MIN &&
        avgTopElbow < TIP_LOCKOUT_NEAR_MAX) {
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
