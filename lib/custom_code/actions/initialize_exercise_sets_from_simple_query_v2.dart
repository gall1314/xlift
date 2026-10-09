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

List<dynamic> initializeExerciseSetsFromSimpleQueryV2(
  List<GetExercisesSimpRow> exercises,
  List<dynamic> exerciseSets,
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
    if (v is bool) return v;
    if (v is num) return v == 1;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }

  dynamic _pick(Map m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k) && m[k] != null) return m[k];
    }
    return null;
  }

  int? _extractExerciseId(Map data) =>
      _toInt(_pick(data, ['exercise_id', 'exerciseId', 'id']));

  // ---------- build workoutExerciseId → exerciseId ----------
  final workoutExToExercise = <String, int>{};

  for (final ex in exercises) {
    final d = Map<String, dynamic>.from(ex.data);
    final workoutExId = d['id']?.toString();
    final exerciseId = _extractExerciseId(d);

    if (workoutExId != null && exerciseId != null) {
      workoutExToExercise[workoutExId] = exerciseId;
    }
  }

  // ---------- detect bodyweight / assisted ----------
  final isBwMap = <int, bool>{};
  final isAssistedMap = <int, bool>{};

  for (final ex in exercises) {
    final d = Map<String, dynamic>.from(ex.data);
    final id = _extractExerciseId(d);
    if (id == null) continue;

    final bw = _toBool(_pick(d, ['is_bodyweight', 'isBodyweight']));
    isBwMap[id] = bw;

    final assisted = _toBool(_pick(d, ['is_assisted', 'isAssisted']));
    isAssistedMap[id] = assisted;
  }

  // ---------- group saved sets (template only) ----------
  final savedByExercise = <int, List<Map<String, dynamic>>>{};

  for (final row in savedSets) {
    final m = Map<String, dynamic>.from(row.data);

    final workoutExId = m['workout_exercise_id']?.toString();
    if (workoutExId == null) continue;

    final exerciseId = workoutExToExercise[workoutExId];
    if (exerciseId == null) continue;

    final isDrop = _toInt(m['is_dropset']) == 1;
    if (isDrop) continue;

    savedByExercise.putIfAbsent(exerciseId, () => []);

    savedByExercise[exerciseId]!.add({
      'setNumber': _toInt(m['set_number']) ?? 1,
      'targetReps': _toCleanString(m['target_reps']),
      'weighted': _toInt(m['weighted']), // 0 / 1
      'durationSeconds': _toInt(m['duration_seconds']), // ← יכול להיות null
    });
  }

  // ---------- build FINAL output ----------
  final out = <Map<String, dynamic>>[];

  for (final ex in exercises) {
    final d = Map<String, dynamic>.from(ex.data);

    final workoutExId = d['id']?.toString();
    final exerciseId = _extractExerciseId(d);
    if (workoutExId == null || exerciseId == null) continue;

    final bool isBW = isBwMap[exerciseId] == true;
    final int defaultWeighted = isBW ? 0 : 1;

    final restSeconds = _toInt(d['rest_seconds']) ?? 0;
    final exerciseName =
        _toCleanString(_pick(d, ['exercise_name', 'exerciseName', 'name']));
    final saved = savedByExercise[exerciseId];

    if (saved != null && saved.isNotEmpty) {
      final sorted = [...saved]..sort(
          (a, b) => (a['setNumber'] as int).compareTo(b['setNumber'] as int),
        );

      final sets = sorted.map((s) {
        final int effectiveWeighted =
            (s['weighted'] != null) ? s['weighted'] : defaultWeighted;

        final int? duration = s['durationSeconds'];
        final bool isTimeBased = duration != null && duration > 0;

        return {
          'setNumber': s['setNumber'],
          'timerMode': isTimeBased ? 2 : 1,
          'durationSeconds': duration, // ✅ תמיד קיים (null / int)
          'weighted': effectiveWeighted,
          'showWeightField': effectiveWeighted == 1,
          'targetReps': s['targetReps'],
        };
      }).toList();

      out.add({
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'workoutExerciseId': workoutExId,
        'restSeconds': restSeconds,
        'isAssisted': isAssistedMap[exerciseId] == true ? 1 : 0,
        'sets': sets,
      });
    } else {
      // ---------- default template ----------
      out.add({
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'workoutExerciseId': workoutExId,
        'restSeconds': restSeconds,
        'isAssisted': isAssistedMap[exerciseId] == true ? 1 : 0,
        'sets': [
          {
            'setNumber': 1,
            'timerMode': 1,
            'durationSeconds': null, // 🔥 הקריטי
            'weighted': defaultWeighted,
            'showWeightField': defaultWeighted == 1,
            'targetReps': null,
          }
        ],
      });
    }
  }

  return out;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
