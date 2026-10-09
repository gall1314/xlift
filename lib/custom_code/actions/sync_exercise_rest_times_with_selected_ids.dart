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

dynamic syncExerciseRestTimesWithSelectedIds(
  dynamic existingRestTimes,
  List<int> selectedExerciseIds,
) {
  final Map<String, int> current = (existingRestTimes is Map<String, int>)
      ? Map<String, int>.from(existingRestTimes)
      : {};

  final Map<String, int> result = {};

  for (final exerciseId in selectedExerciseIds) {
    final key = exerciseId.toString();

    if (current.containsKey(key)) {
      result[key] = current[key] ?? 0;
    } else {
      result[key] = 0;
    }
  }

  return result;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
