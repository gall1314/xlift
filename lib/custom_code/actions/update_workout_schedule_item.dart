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

List<dynamic> updateWorkoutScheduleItem(
  List<dynamic> currentState,
  String workoutId,
  int? timesPerWeek,
  int? restHours,
) {
  final List<dynamic> updatedList = [];

  for (final item in currentState) {
    if (item is! Map) {
      updatedList.add(item);
      continue;
    }

    if (item['workoutId'] != workoutId) {
      // לא האימון שאנgחנו מחפשים
      updatedList.add(item);
      continue;
    }

    // זה האימון הרלוונטי — מעדכנים
    final updatedItem = Map<String, dynamic>.from(item);

    if (timesPerWeek != null) {
      updatedItem['timesPerWeek'] = timesPerWeek;

      // אם חזרו ל־1 → אין משמעות למנוחה
      if (timesPerWeek <= 1) {
        updatedItem['restHours'] = null;
      }
    }

    if (restHours != null) {
      updatedItem['restHours'] = restHours;
    }

    updatedList.add(updatedItem);
  }

  return updatedList;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
