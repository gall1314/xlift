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

dynamic removeExerciseRestTime(
  dynamic exerciseRestTimes,
  int exerciseId,
) {
  final updated = <String, dynamic>{};

  if (exerciseRestTimes is Map) {
    exerciseRestTimes.forEach((key, value) {
      final keyString = key.toString();
      if (keyString == '_ts') return;
      if (keyString == exerciseId.toString()) return; // מדלג = מוחק
      updated[keyString] = value;
    });
  }

  updated['_ts'] = DateTime.now().millisecondsSinceEpoch;

  return updated;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
