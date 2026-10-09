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

List<dynamic> syncExerciseSetsWithSelectedIds(
  List<dynamic> exerciseSets,
  List<int> selectedExerciseIds,
) {
  // ---------- index existing exerciseSe5ts by exerciseId ----------
  final Map<int, Map<String, dynamic>> existingById = {};

  for (final item in exerciseSets) {
    if (item is Map) {
      final m = Map<String, dynamic>.from(item);
      final exerciseId = m['exerciseId'];
      if (exerciseId is int) {
        existingById[exerciseId] = m;
      }
    }
  }

  final List<Map<String, dynamic>> result = [];

  // ---------- keep existing + add new ----------
  for (final exerciseId in selectedExerciseIds) {
    if (existingById.containsKey(exerciseId)) {
      // ✅ קיים → deep copy מלא (כולל sets)
      final original = existingById[exerciseId]!;

      result.add({
        ...original,
        'sets': (original['sets'] is List)
            ? (original['sets'] as List)
                .whereType<Map>()
                .map((s) => Map<String, dynamic>.from(s))
                .toList()
            : <Map<String, dynamic>>[],
      });
    } else {
      // ➕ חדש → תריגיל חדש עם סט ראשון תקין
      result.add({
        'exerciseId': exerciseId,
        'workoutExerciseId': null,
        'restSeconds': 0,
        'sets': [
          {
            'setNumber': 1,
            'timerMode': 1,
            'weighted': true,
            'showWeightField': true,
            'isChecked': false,

            // ערכים קיימים במפה (null)
            'durationSeconds': null,
            'targetReps': null,
            'targetWeight': null,
          }
        ],
      });
    }
  }

  return result;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
