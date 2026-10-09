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

/// Main exercise analyzer dispatcher.
///
/// Takes an exercise name (in any of the supported aliases — as it arrives
/// from the database), routes to the matching specialized analyzer action,
/// and returns the result. The DB labels currently in use are:
///
///   Barbell Back Squat, Bulgarian Split Squat, Push-up, Chest Dips,
///   Pull-up, Barbell Bent-over Row, Barbell Bicep Curl, Deadlift,
///   Romanian Deadlift, Military Press, Good Morning, Stiff-Leg Deadlift
///
/// All of those map to a real translated action EXCEPT Barbell Bent-over
/// Row, which is intentionally held back and returns a `not_implemented`
/// error.
///
/// Returns a Map (as `dynamic`) with the same shape every analyzer uses:
///   {
///     "squat_count": int,
///     "technique_score": double,
///     "feedback": List<String>,
///     "reps": List<Map>,
///     "exercise_type": String,
///     "_source_video_uri": String,
///     "_frame_telemetry": List,
///     ...
///   }
///
/// On unsupported exercise → returns an error payload but does not throw.
/// On Bent-over Row → returns 'not_implemented' error.
Future<dynamic> analyzeExerciseVideoAction(
  FFUploadedFile videoFile,
  String exerciseType,
  double? targetFps,
) async {
  // ----- Exercise alias map -----
  // Keys must be LOWERCASE — input is lowercased before lookup.
  // Includes both the exact DB labels and common alternative spellings
  // so the dispatcher is forgiving if labels evolve.
  const Map<String, String> EXERCISE_MAP = {
    // Squat
    'barbell squat': 'squat',
    'barbell back squat': 'squat',
    'squat': 'squat',
    // Deadlift
    'deadlift': 'deadlift',
    // Romanian deadlift
    'romanian deadlift': 'romanian_deadlift',
    'rdl': 'romanian_deadlift',
    // Stiff leg deadlift
    'stiff leg deadlift': 'stiff_leg_deadlift',
    'stiff-leg deadlift': 'stiff_leg_deadlift',
    'stiff leg': 'stiff_leg_deadlift',
    'sldl': 'stiff_leg_deadlift',
    'straight leg deadlift': 'stiff_leg_deadlift',
    'straight-leg deadlift': 'stiff_leg_deadlift',
    // Bulgarian split squat
    'bulgarian split squat': 'bulgarian',
    'split squat': 'bulgarian',
    'bulgarian': 'bulgarian',
    // Pull-up
    'pull-up': 'pullup',
    'pull up': 'pullup',
    'pullups': 'pullup',
    'pullup': 'pullup',
    // Bicep curl
    'barbell bicep curl': 'bicep_curl',
    'bicep curl': 'bicep_curl',
    // Bent-over row (intentionally NOT exposed - see switch below)
    'bent-over row': 'bent_row',
    'barbell bent-over row': 'bent_row',
    'barbell bent over row': 'bent_row',
    'bent over row': 'bent_row',
    'barbell row': 'bent_row',
    'row': 'bent_row',
    // Good morning
    'good morning': 'good_morning',
    'good mornings': 'good_morning',
    // Dips
    'dips': 'dips',
    'dip': 'dips',
    'bench dips': 'dips',
    'bench dip': 'dips',
    'chest dips': 'dips',
    'chest dip': 'dips',
    'tricep dips': 'dips',
    'triceps dips': 'dips',
    'parallel bar dips': 'dips',
    'bar dips': 'dips',
    // Overhead / military press
    'overhead press': 'overhead_press',
    'barbell overhead press': 'overhead_press',
    'military press': 'overhead_press',
    'standing press': 'overhead_press',
    'shoulder press': 'overhead_press',
    'strict press': 'overhead_press',
    // Push-up
    'push-up': 'pushup',
    'push up': 'pushup',
    'pushups': 'pushup',
    'push ups': 'pushup',
    'push-ups': 'pushup',
    'pushup': 'pushup',
    'regular push-up': 'pushup',
    'standard push-up': 'pushup',
  };

  Map<String, dynamic> errorPayload(String code, String detail, String exType) {
    return {
      'error': code,
      'detail': detail,
      'squat_count': 0,
      'technique_score': 0.0,
      'technique_score_display': '0',
      'technique_label': 'Needs work',
      'good_reps': 0,
      'bad_reps': 0,
      'feedback': <String>[detail],
      'tip': null,
      'reps': <dynamic>[],
      'exercise_type': exType,
      'video_path': '',
      '_source_video_uri': '',
      '_frame_telemetry': <dynamic>[],
    };
  }

  // ----- Validate input -----
  final String rawType = (exerciseType).trim().toLowerCase();
  if (rawType.isEmpty || rawType == 'null') {
    return errorPayload(
      'missing_exercise_type',
      'exercise_type is required',
      '',
    );
  }

  final String? resolvedType = EXERCISE_MAP[rawType];
  if (resolvedType == null) {
    final supported = EXERCISE_MAP.values.toSet().toList()..sort();
    return errorPayload(
      'unsupported_exercise_type',
      'Unsupported exercise: $rawType. Supported: ${supported.join(", ")}',
      rawType,
    );
  }

  // ----- Resolve effective FPS -----
  // Each exercise has a "native" FPS that matches the calibration of the
  // original Python analyzer. If the caller didn't pass an explicit
  // targetFps, we pick the right one for the exercise. If they did pass
  // a value, we honor it as an override.
  const Map<String, double> NATIVE_FPS = {
    'squat': 10.0,
    'pushup': 15.0,
    'bicep_curl': 10.0,
    'good_morning': 10.0,
    'bent_row': 15.0,
    'bulgarian': 10.0,
    'pullup': 15.0,
    'deadlift': 12.0,
    'romanian_deadlift': 10.0,
    'stiff_leg_deadlift': 10.0,
    'dips': 15.0,
    'overhead_press': 15.0,
  };

  final double effectiveFps = targetFps ?? (NATIVE_FPS[resolvedType] ?? 10.0);

  // ----- Route to the correct analyzer -----
  switch (resolvedType) {
    // ===== TRANSLATED & EXPOSED =====
    case 'squat':
      return await analyzeSquatVideoAction(videoFile, effectiveFps);

    case 'pushup':
      return await analyzePushupVideoAction(videoFile, effectiveFps);

    case 'bicep_curl':
      return await analyzeBicepCurlVideoAction(videoFile, effectiveFps);

    case 'good_morning':
      return await analyzeGoodMorningVideoAction(videoFile, effectiveFps);

    case 'bulgarian':
      return await analyzeBulgarianVideoAction(videoFile, effectiveFps);

    case 'romanian_deadlift':
      return await analyzeRomanianDeadliftVideoAction(videoFile, effectiveFps);

    case 'deadlift':
      return await analyzeDeadliftVideoAction(videoFile, effectiveFps);

    case 'pullup':
      return await analyzePullupVideoAction(videoFile, effectiveFps);

    case 'stiff_leg_deadlift':
      return await analyzeStiffLegDeadliftVideoAction(videoFile, effectiveFps);

    case 'dips':
      return await analyzeDipsVideoAction(videoFile, effectiveFps);

    case 'overhead_press':
      return await analyzeOverheadPressVideoAction(videoFile, effectiveFps);

    // ===== INTENTIONALLY NOT EXPOSED =====
    // Bent-over Row is held back for now. To enable later, replace this
    // branch with a real action call (e.g.
    //   return await analyzeBentRowVideoAction(videoFile, effectiveFps);
    // ).
    case 'bent_row':
      return errorPayload(
        'not_implemented',
        'Bent-over row analyzer not yet available',
        'bent_row',
      );

    default:
      return errorPayload(
        'unhandled_type',
        'Unhandled internal type: $resolvedType',
        resolvedType,
      );
  }
}
