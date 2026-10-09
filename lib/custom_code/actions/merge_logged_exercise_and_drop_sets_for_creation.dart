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

List<dynamic> mergeLoggedExerciseAndDropSetsForCreation(
  List<dynamic> exerciseSets,
  List<dynamic> loggedSets,
  List<dynamic> dropSets,
  List<dynamic>? warmupList,
) {
  // ---------- helpers ----------
  int? toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String && v.trim().isNotEmpty) return int.tryParse(v.trim());
    return null;
  }

  int toFlag(dynamic v) {
    if (v is int) return v == 1 ? 1 : 0;
    if (v is bool) return v ? 1 : 0;
    return 0;
  }

  // ---------- clone inputs ----------
  final baseExercises =
      exerciseSets.map((e) => Map<String, dynamic>.from(e)).toList();
  final logged = loggedSets.map((l) => Map<String, dynamic>.from(l)).toList();
  final drops = dropSets.map((d) => Map<String, dynamic>.from(d)).toList();

  // ---------- STEP 0: inject warmup sets (isWarmup 1) ----------
  for (final ex in baseExercises) {
    final exerciseId = ex['exerciseId'];

    // Ensure working sets are flagged 0.
    final workingSets = (ex['sets'] as List? ?? [])
        .map((s) => {
              ...Map<String, dynamic>.from(s as Map),
              'isWarmup': 0,
            })
        .toList();

    final warmupSets = <Map<String, dynamic>>[];
    if (warmupList != null) {
      for (final w in warmupList) {
        if (w is! Map) continue;
        if (w['exerciseId'] != exerciseId) continue;
        if (w['hidden'] == true) continue;

        final wSets = w['sets'];
        if (wSets is! List) break;

        for (final s in wSets) {
          if (s is! Map) continue;
          warmupSets.add({
            ...Map<String, dynamic>.from(s),
            'isWarmup': 1,
            'workoutExerciseId': ex['workoutExerciseId'],
          });
        }
        break;
      }
    }

    ex['sets'] = [...warmupSets, ...workingSets];
  }

  // ---------- exerciseId → workoutExerciseId ----------
  final Map<int, dynamic> workoutExerciseByExerciseId = {
    for (final ex in baseExercises)
      toInt(ex['exerciseId'])!: ex['workoutExerciseId']
  };

  final List<Map<String, dynamic>> result = [];

  // -------------------------------------------------------
  // BASE SETS
  // -------------------------------------------------------
  for (final ex in baseExercises) {
    final exerciseId = toInt(ex['exerciseId']);
    final workoutExerciseId = ex['workoutExerciseId'];

    final sets =
        (ex['sets'] as List).map((s) => Map<String, dynamic>.from(s)).toList();

    final Map<int, Map<String, dynamic>> resolvedSets = {};

    for (final s in sets) {
      final setNumber = toInt(s['setNumber'])!;
      final int rowIsWarmup = toFlag(s['isWarmup']);
      final int baseWeighted = toFlag(s['weighted']);

      final row = <String, dynamic>{
        'exerciseId': exerciseId,
        'workoutExerciseId': workoutExerciseId,
        'setNumber': setNumber,
        'isDropSet': 0,
        'dropNumber': null,
        'targetReps': toInt(s['targetReps']),
        'weighted': baseWeighted,
        'isWarmup': rowIsWarmup,
        'percentFromParent': null,
      };

      // Warmup sets carry their own reps/weight from the warmup builder.
      if (rowIsWarmup == 1) {
        if (row['targetReps'] == null) {
          row['targetReps'] = toInt(s['reps']);
        }
        if (s['weight'] != null) {
          row['warmupWeight'] = s['weight'].toString();
        }
      }

      // --- loggedSets affect only non-warmup sets ---
      if (rowIsWarmup == 0) {
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
          if (match.containsKey('durationSeconds')) {
            row['durationSeconds'] = toInt(match['durationSeconds']);
          }
        }
      }

      // ------------------------------
      // Inheritance - reps only, same set kind only
      // ------------------------------
      if (setNumber > 1 && row['targetReps'] == null) {
        for (int prev = setNumber - 1; prev >= 1; prev--) {
          final prevRow = resolvedSets[prev];
          if (prevRow == null) continue;

          if (prevRow['isWarmup'] == row['isWarmup'] &&
              prevRow['targetReps'] != null) {
            row['targetReps'] = prevRow['targetReps'];
            break;
          }
        }
      }

      resolvedSets[setNumber] = row;
      result.add(row);
    }
  }

  // -------------------------------------------------------
  // DROP SETS
  // -------------------------------------------------------
  for (final d in drops) {
    final exerciseId = toInt(d['exerciseId']);
    final parentSetNumber = toInt(d['parentSetNumber']);
    final dropOrder = toInt(d['dropOrder']);

    final workoutExerciseId = workoutExerciseByExerciseId[exerciseId];
    if (workoutExerciseId == null) continue;

    result.add({
      'exerciseId': exerciseId,
      'workoutExerciseId': workoutExerciseId,
      'setNumber': parentSetNumber,
      'isDropSet': 1,
      'dropNumber': dropOrder,
      'targetReps': toInt(d['reps']),
      'weighted': 1,
      'isWarmup': 0,
      'percentFromParent': null,
    });
  }

  return result;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
