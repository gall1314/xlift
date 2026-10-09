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

List<dynamic> updateLoggedSetForCreation(
  List<dynamic> flatSets,
  int exerciseId,
  int setNumber,
  int? targetReps,
  double? targetWeight,
  bool? isWarmup,
) {
  // deep copy
  final updated =
      flatSets.map((e) => Map<String, dynamic>.from(e as Map)).toList();

  // find exis3ting row
  final idx = updated.indexWhere(
    (s) => s['exerciseId'] == exerciseId && s['setNumber'] == setNumber,
  );

  final newRow = <String, dynamic>{
    'exerciseId': exerciseId,
    'setNumber': setNumber,
    if (targetReps != null) 'targetReps': targetReps,
    if (targetWeight != null) 'targetWeight': targetWeight,
    if (isWarmup != null) 'isWarmup': isWarmup,
  };

  if (idx >= 0) {
    updated[idx] = {
      ...updated[idx],
      ...newRow,
    };
  } else {
    updated.add(newRow);
  }

  return updated;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
