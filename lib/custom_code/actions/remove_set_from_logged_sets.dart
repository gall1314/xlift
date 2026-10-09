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

List<dynamic> removeSetFromLoggedSets(
  List<dynamic> loggedSets,
  int exerciseId,
) {
  final updated = List<Map<String, dynamic>>.from(
    loggedSets.map((s) => Map<String, dynamic>.from(s)),
  );

  // מסנניכם רק את הס4טים של התרגיל הזה
  final setsForExercise =
      updated.where((s) => s['exerciseId'] == exerciseId).toList();

  if (setsForExercise.isEmpty) {
    return updated;
  }

  // הכי גבוה - מוצאים את setNumber האחרוןffג
  setsForExercise.sort((a, b) =>
      ((b['setNumber'] ?? 0) as int).compareTo((a['setNumber'] ?? 0) as int));

  final setToRemove = setsForExercise.first;

  // מוחקים אותו מדתוך הרשימה הראשית
  updated.removeWhere(
    (s) =>
        s['exerciseId'] == exerciseId &&
        s['setNumber'] == setToRemove['setNumber'],
  );

  return updated;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
