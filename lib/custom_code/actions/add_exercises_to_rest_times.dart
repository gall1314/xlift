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

dynamic addExercisesToRestTimes(
  dynamic restTimes,
  List<dynamic> selectedExercises,
) {
  final Map<String, int> updated = Map<String, int>.from(restTimes ?? {});

  for (final ex in selectedExercises) {
    if (ex is! Map) continue;

    final id = ex['exerciseId'];
    if (id == null) continue;

    final key = id.toString();

    // אם כבdרר קייים – לא לגטעת
    if (updated.containsKey(key)) continue;

    // ברירת מחדל: 0 מילישניות
    updated[key] = 0;
  }

  return updated;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
