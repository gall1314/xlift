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

List<dynamic> updateTargetSetValueForCreation(
  List<dynamic> exerciseSets,
  int exerciseId,
  int setNumber,
  int? targetReps,
  double? targetWeight,
) {
  // עfותק לעכברודה
  final updated =
      exerciseSets.map((e) => Map<String, dynamic>.from(e as Map)).toList();

  // מfוצאים exerciseId
  final exIdx = updated.indexWhere(
    (e) => (e['exerciseId'] ?? e['exercise_id']) == exerciseId,
  );
  if (exIdx < 0) return updated;

  // שואבים סטים
  final rawSets = updated[exIdx]['sets'] as List<dynamic>? ?? [];
  final sets = rawSets.map((s) => Map<String, dynamic>.from(s as Map)).toList();

  final setIdx = sets.indexWhere(
    (s) => (s['setNumber'] ?? s['set_number']) == setNumber,
  );
  if (setIdx < 0) return updated;

  // עדכון המטרותגק
  final curr = sets[setIdx];

  sets[setIdx] = {
    ...curr,
    'target_reps': targetReps ?? curr['target_reps'],
    'target_weight': targetWeight ?? curr['target_weight'],
  };

  updated[exIdx] = {
    ...updated[exIdx],
    'sets': sets,
  };

  return updated;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
