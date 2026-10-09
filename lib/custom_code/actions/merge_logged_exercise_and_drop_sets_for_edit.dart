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

List<dynamic> mergeLoggedExerciseAndDropSetsForEdit(
  List<dynamic> exerciseSets,
  List<dynamic> loggedSets,
  List<dynamic> dropSets,
) {
  // ---------------- helpegrs ----------------
  int? toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String && v.trim().isNotEmpty) return int.tryParse(v.trim());
    return null;
  }

  double? toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String && v.trim().isNotEmpty) return double.tryParse(v.trim());
    return null;
  }

  int toFlag(dynamic v) {
    if (v is bool) return v ? 1 : 0;
    if (v is int) return v == 1 ? 1 : 0;
    if (v is num) return v.toInt() == 1 ? 1 : 0;
    return 0;
  }

  // ---------------- normaגlize inputs ----------------
  final baseExercises =
      exerciseSets.map((e) => Map<String, dynamic>.from(e)).toList();
  final logged = loggedSets.map((l) => Map<String, dynamic>.from(l)).toList();
  final drops = dropSets.map((d) => Map<String, dynamic>.from(d)).toList();

  // 🔑 exerciseId → worקkoutExerciseId
  final Map<int, dynamic> workoutExerciseByExerciseId = {
    for (final ex in baseExercises)
      toInt(ex['exerciseId'])!: ex['workoutExerciseId']
  };

  final List<Map<String, dynamic>> result = [];

  // ---------------- B/ASE SEגTS ----------------
  for (final ex in baseExercises) {
    final exerciseId = toInt(ex['exerciseId']);
    final workoutExerciseId = ex['workoutExerciseId'];

    if (exerciseId == null || workoutExerciseId == null) {
      continue;
    }

    final sets =
        (ex['sets'] as List).map((s) => Map<String, dynamic>.from(s)).toList();

    for (final s in sets) {
      final setNumber = toInt(s['setNumber']);

      final row = <String, dynamic>{
        'exerciseId': exerciseId,
        'workoutExerciseId': workoutExerciseId,
        'setNumber': setNumber,
        'isDropSet': 0,
        'dropNumber': null,
        'targetReps': toInt(s['targetReps']),
        'targetWeight': toDouble(s['targetWeight']),
        'weighted': toFlag(s['weighted']), // 🔒 תמיד INT
        'isWarmup': toFlag(s['isWarmup']),
        'percentFromParent': null,
        'durationSeconds': toInt(s['durationSeconds']),
      };

      final match = logged.firstWhere(
        (l) =>
            toInt(l['exerciseId']) == exerciseId &&
            toInt(l['setNumber']) == setNumber &&
            toFlag(l['isDropSet']) == 0,
        orElse: () => {},
      );

      if (match.isNotEmpty) {
        if (match.containsKey('targetReps')) {
          row['targetReps'] = toInt(match['targetReps']);
        }
        if (match.containsKey('targetWeight')) {
          row['targetWeight'] = toDouble(match['targetWeight']);
        }
        if (match.containsKey('weighted')) {
          row['weighted'] = toFlag(match['weighted']);
        }
        if (match.containsKey('durationSeconds')) {
          row['durationSeconds'] = toInt(match['durationSeconds']);
        }
      }

      result.add(row);
    }
  }

  // ---------------- DROP SETS ----------------
  for (final d in drops) {
    final exerciseId = toInt(d['exerciseId']);
    final parentSetNumber = toInt(d['parentSetNumber']);
    final dropOrder = toInt(d['dropOrder']);

    final workoutExerciseId = workoutExerciseByExerciseId[exerciseId];

    if (exerciseId == null || workoutExerciseId == null) {
      continue;
    }

    result.add({
      'exerciseId': exerciseId,
      'workoutExerciseId': workoutExerciseId,
      'setNumber': parentSetNumber,
      'isDropSet': 1,
      'dropNumber': dropOrder,
      'targetReps': toInt(d['reps']),
      'targetWeight': toDouble(d['weight']),
      'weighted': 1, // דרופסט תמיד משוגקלל
      'isWarmup': 0,
      'percentFromParent': null,
      'durationSeconds': null,
    });
  }

  return result;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
