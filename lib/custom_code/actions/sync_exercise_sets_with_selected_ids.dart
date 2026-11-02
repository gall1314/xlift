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

/// Rebuilds exerciseSets from the picker's result.
///
/// [selectedExercises] is the list ExercisePickerView hands to onConfirm:
/// maps like {exerciseId, exerciseName, isBodyweight, isAssisted, isPublic,
/// isTimeBased, equipment}, in the order they should appear in the workout.
/// Plain ints (the old contract) and JSON strings are accepted too.
///
/// Existing exercises keep everything (deep copy incl. sets); new ones get a
/// first default set. Exercises that are no longer selected are dropped.
List<dynamic> syncExerciseSetsWithSelectedIds(
  List<dynamic> exerciseSets,
  List<dynamic> selectedExercises,
) {
  int idOf(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is Map) return idOf(v['exerciseId'] ?? v['exercise_id']);
    if (v is String) {
      final n = int.tryParse(v.trim());
      if (n != null) return n;
      try {
        final m = jsonDecode(v);
        if (m is Map) return idOf(m['exerciseId'] ?? m['exercise_id']);
      } catch (_) {}
      return 0;
    }
    try {
      final m = (v as dynamic).toMap();
      if (m is Map) return idOf(m['exerciseId'] ?? m['exercise_id']);
    } catch (_) {}
    try {
      return idOf((v as dynamic).exerciseId);
    } catch (_) {}
    return 0;
  }

  // ---------- index existing exerciseSets by exerciseId ----------
  final Map<int, Map<String, dynamic>> existingById = {};

  for (final item in exerciseSets) {
    if (item is Map) {
      final m = Map<String, dynamic>.from(item);
      final exerciseId = idOf(m['exerciseId']);
      if (exerciseId > 0) {
        existingById[exerciseId] = m;
      }
    }
  }

  final List<Map<String, dynamic>> result = [];
  final Set<int> seen = {};

  // ---------- keep existing + add new, in selection order ----------
  for (final picked in selectedExercises) {
    final exerciseId = idOf(picked);
    if (exerciseId <= 0 || !seen.add(exerciseId)) continue;

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
      // ➕ חדש → תרגיל חדש עם סט ראשון תקין
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
