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

List<dynamic> initializeExerciseSetsForEdit(
  List<GetExercisesSimpRow> exercises,
  List<GetExerciseSetsForWorkoutRow> savedSets,
) {
  // ---------- helpers ----------
  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String && v.trim().isNotEmpty) return int.tryParse(v.trim());
    return null;
  }

  String? _toCleanString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }

  int? _extractExerciseId(Map data) =>
      _toInt(data['exercise_id'] ?? data['exerciseId'] ?? data['id']);

  // ---------- workoutExerciseId → exerciseId ----------
  final workoutExToExercise = <String, int>{};

  for (final ex in exercises) {
    final d = Map<String, dynamic>.from(ex.data);
    final workoutExId = d['id']?.toString();
    final exerciseId = _extractExerciseId(d);
    if (workoutExId != null && exerciseId != null) {
      workoutExToExercise[workoutExId] = exerciseId;
    }
  }

  // ---------- bodyweight map ----------
  final isBodyweightByExercise = <int, bool>{};

  for (final ex in exercises) {
    final d = Map<String, dynamic>.from(ex.data);
    final exerciseId = _extractExerciseId(d);
    if (exerciseId == null) continue;

    isBodyweightByExercise[exerciseId] =
        _toBool(d['is_bodyweight'] ?? d['isBodyweight']);
  }

  // ---------- group saved sets (no dropsets) ----------
  final savedByExercise = <int, List<Map<String, dynamic>>>{};

  for (final row in savedSets) {
    final m = Map<String, dynamic>.from(row.data);

    if (_toInt(m['is_dropset']) == 1) continue;

    final workoutExId = m['workout_exercise_id']?.toString();
    if (workoutExId == null) continue;

    final exerciseId = workoutExToExercise[workoutExId];
    if (exerciseId == null) continue;

    savedByExercise.putIfAbsent(exerciseId, () => []);

    savedByExercise[exerciseId]!.add({
      'setNumber': _toInt(m['set_number']) ?? 1,
      'targetReps': _toCleanString(m['target_reps']),
      'targetWeight': _toCleanString(m['target_weight']),
      'weighted': _toInt(m['weighted']), // 🔒 INT
      'durationSeconds': _toInt(m['duration_seconds']),
    });
  }

  // ---------- build FINAL ----------
  final result = <Map<String, dynamic>>[];

  for (final ex in exercises) {
    final d = Map<String, dynamic>.from(ex.data);

    final workoutExerciseId = d['id']?.toString();
    final exerciseId = _extractExerciseId(d);
    if (workoutExerciseId == null || exerciseId == null) continue;

    final isBodyweight = isBodyweightByExercise[exerciseId] == true;
    final int defaultWeighted = isBodyweight ? 0 : 1;

    final restSeconds = _toInt(d['rest_seconds']) ?? 0;
    final savedSetsForExercise = savedByExercise[exerciseId];

    List<Map<String, dynamic>> sets;

    if (savedSetsForExercise != null && savedSetsForExercise.isNotEmpty) {
      savedSetsForExercise.sort(
        (a, b) => (a['setNumber'] as int).compareTo(b['setNumber'] as int),
      );

      sets = savedSetsForExercise.map((s) {
        final int weighted = s['weighted'] ?? defaultWeighted; // 🔒 נשאר INT

        final duration = s['durationSeconds'];
        final bool isTimeBased = duration != null && duration > 0;

        return {
          'setNumber': s['setNumber'],
          'timerMode': isTimeBased ? 2 : 1,
          'durationSeconds': duration,

          // 🔒 DATA
          'weighted': weighted,

          // 👁 UI בלבד
          'showWeightField': weighted == 1,

          'isChecked': false,
          'targetReps': s['targetReps'],
          'targetWeight': s['targetWeight'],
        };
      }).toList();
    } else {
      sets = [
        {
          'setNumber': 1,
          'timerMode': 1,

          // 🔒 DATA
          'weighted': defaultWeighted,

          // 👁 UI
          'showWeightField': defaultWeighted == 1,

          'isChecked': false,
        }
      ];
    }

    result.add({
      'exerciseId': exerciseId,
      'workoutExerciseId': workoutExerciseId,
      'restSeconds': restSeconds,
      'sets': sets,
    });
  }

  return result;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
