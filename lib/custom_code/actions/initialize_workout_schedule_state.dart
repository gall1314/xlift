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

List<dynamic> initializeWorkoutScheduleState(
  List<String> workoutIds,
) {
  final List<dynamic> result = [];

  for (final id in workoutIds) {
    if (id.isEmpty) continue;

    result.add({
      'workoutId': id, // String
      'timesPerWeek': 1, // int — אינישיאל קקבק'בוע
      'restHours': null, // int? — 24 / 48 / 72 או null
    });
  }

  return result;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
