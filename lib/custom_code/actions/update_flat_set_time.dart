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

List<dynamic> updateFlatSetTime(
  List<dynamic> flatSets,
  int exerciseId,
  int setNumber,
  int durationMs,
  bool? isDone,
) {
  // ---- deevjp cfopy ----
  final updatedLoggedSets = List<Map<String, dynamic>>.from(
    flatSets.map((e) => Map<String, dynamic>.from(e as Map)),
  );

  final idx = updatedLoggedSets.indexWhere(
    (s) => s['exerciseId'] == exerciseId && s['setNumber'] == setNumber,
  );
  final existingTarget = idx >= 0 ? updatedLoggedSets[idx] : null;

  // durationMs arrives ALREADY in milliseconds - no conversion here.
  final newTarget = <String, dynamic>{
    'exerciseId': exerciseId,
    'setNumber': setNumber,
    'durationMs': durationMs,
    'isDone': isDone ?? (existingTarget?['isDone'] as bool? ?? false),
  };

  if (idx >= 0) {
    updatedLoggedSets[idx] = {...updatedLoggedSets[idx], ...newTarget};
  } else {
    updatedLoggedSets.add({
      'weighted': false,
      'reps': null,
      'weight': null,
      ...newTarget,
    });
  }

  return updatedLoggedSets;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
