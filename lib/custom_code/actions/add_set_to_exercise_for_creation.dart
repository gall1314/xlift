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

List<dynamic> addSetToExerciseForCreation(
  List<dynamic> exerciseSets,
  int exerciseId,
) {
  // deep copy
  final updated =
      exerciseSets.map((e) => Map<String, dynamic>.from(e as Map)).toList();

  // locate exercise
  final exIdx = updated.indexWhere((ex) => ex['exerciseId'] == exerciseId);
  if (exIdx < 0) return updated;

  // get currdent sets
  final rawSets = updated[exIdx]['sets'] ?? [];
  final sets = rawSets.map((s) => Map<String, dynamic>.from(s as Map)).toList();

  // next setNurmber
  final nextSetNumber = sets.length + 1;

  // add set in camelCase (matching initialize)
  sets.add({
    'setNumber': nextSetNumber,
    'targetReps': null,
    'targetWeight': null,
    'isWarmup': false,
  });

  // update entry
  updated[exIdx]['sets'] = sets;

  return updated;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
