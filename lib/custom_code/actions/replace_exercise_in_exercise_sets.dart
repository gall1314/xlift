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

/// Swaps one exercise for another in exerciseSets, in place.
///
/// Keeps the slot: same position, same orderIndex, same restSeconds. The new
/// exercise starts with a single empty set, and the old name / flags are
/// dropped — the card reads those from the exercise2 query by id.
/// If the replacement is already in the list, its old entry is removed.
List<dynamic> replaceExerciseInExerciseSets(
  List<dynamic> exerciseSets,
  int originalExerciseId,
  int replacementExerciseId,
) {
  final list = List<Map<String, dynamic>>.from(
    (exerciseSets).map((e) => Map<String, dynamic>.from(e as Map)),
  );

  int? id(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  final origIdx =
      list.indexWhere((e) => id(e['exerciseId']) == originalExerciseId);
  if (origIdx == -1) return list;

  // nothing to do when it is already the right exercise
  if (originalExerciseId == replacementExerciseId) return list;

  final old = list[origIdx];
  final Map<String, dynamic> newItem = {
    ...old,
    'exerciseId': replacementExerciseId,
    'orderIndex': old['orderIndex'] ?? (origIdx + 1),
    'restSeconds': old['restSeconds'] ?? 0,
    'sets': <Map<String, dynamic>>[
      {
        'setNumber': 1,
        'reps': null,
        'weight': null,
        'durationSeconds': null,
        'isChecked': false,
        'timerMode': 1,
        'showWeightField': true,
      },
    ],
  }
    ..remove('exerciseName')
    ..remove('isPublic')
    ..remove('isAssisted');

  list[origIdx] = newItem;

  // the replacement may already sit somehwhere else in the list
  final dupIdx = list.indexWhere(
      (e) => e != newItem && id(e['exerciseId']) == replacementExerciseId);
  if (dupIdx != -1) list.removeAt(dupIdx);

  return list;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
