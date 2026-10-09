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

dynamic initializeExerciseRestTimes(
  List<dynamic> exerciseSets,
) {
  final Map<String, int> restTimes = {};

  for (final exercise in exerciseSets) {
    if (exercise is Map) {
      final id = exercise['exerciseId'];
      if (id == null) continue;

      // restSeconds כבר במילישbbניות!!!
      final restMs =
          (exercise['restSeconds'] is int && exercise['restSeconds'] >= 0)
              ? exercise['restSeconds']
              : 0;

      // מפתח תמיד כמחרוזת
      restTimes[id.toString()] = restMs;
    }
  }

  return restTimes;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
