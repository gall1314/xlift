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

List<dynamic> addExercisesToExerciseSetsInWorkout(
  List<dynamic> exerciseSets,
  List<dynamic> selectedExercises,
) {
  final List<Map<String, dynamic>> updated =
      exerciseSets.map((e) => Map<String, dynamic>.from(e as Map)).toList();

  bool exists(int exerciseId) {
    return updated.any((e) => e['exerciseId'] == exerciseId);
  }

  String? cleanString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  bool truthy(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }

  dynamic pick(Map m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k) && m[k] != null) return m[k];
    }
    return null;
  }

  for (final ex in selectedExercises) {
    if (ex is! Map) continue;
    final exerciseId = ex['exerciseId'];
    if (exerciseId == null) continue;

    if (exists(exerciseId)) continue;

    final bool isBodyweight = ex['isBodyweight'] == true;
    final int weighted = isBodyweight ? 0 : 1;

    // Same shape as initializeExerciseSetsFromSimpleQueryV2 so downstream
    // readers (reorder sheet, volume calc) see the same keys.
    final String? exerciseName =
        cleanString(pick(ex, ['exerciseName', 'exercise_name', 'name']));
    final int isAssisted =
        truthy(pick(ex, ['isAssisted', 'is_assisted'])) ? 1 : 0;
    final int isPublic = truthy(pick(ex, ['isPublic', 'is_public'])) ? 1 : 0;

    updated.add({
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'isPublic': isPublic,
      'isAssisted': isAssisted,
      'restSeconds': 0,
      'sets': [
        {
          'setNumber': 1,
          'timerMode': 1,
          'durationSeconds': null, // 🔥 קריטי
          'weighted': weighted, // 🔒 INT
          'showWeightField': weighted == 1,
          'targetReps': null,
          'isChecked': false,
        }
      ],
    });
  }

  return updated;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
