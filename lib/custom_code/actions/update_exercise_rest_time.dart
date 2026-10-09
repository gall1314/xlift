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

dynamic updateExerciseRestTime(
  dynamic exerciseRestTimes,
  int exerciseId,
  int? newTimeMs, // nullable — אם null, שומר ערך קיים
  bool applyToAll,
) {
  final updated = <String, dynamic>{};

  if (exerciseRestTimes is Map) {
    exerciseRestTimes.forEach((key, value) {
      final keyString = key.toString();
      if (keyString == '_ts') return;

      if (newTimeMs == null) {
        // אין שינוי — שומר הכל כמו שהוא
        updated[keyString] = value;
      } else {
        updated[keyString] = applyToAll
            ? newTimeMs
            : (keyString == exerciseId.toString() ? newTimeMs : value);
      }
    });
  }

  // אם ID לא קיים במפה עדיין
  if (newTimeMs != null && !updated.containsKey(exerciseId.toString())) {
    updated[exerciseId.toString()] = newTimeMs;
  }

  updated['_ts'] = DateTime.now().millisecondsSinceEpoch;

  return updated;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
