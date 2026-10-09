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

List<dynamic> removeWorkoutFromDay(
  List<dynamic> week,
  int dayIndex,
) {
  // ---------- safety ----------
  if (dayIndex < 0 || dayIndex >= week.length) {
    return week;
  }

  // ---------- deקep coגpy ----------
  final List<Map<String, dynamic>> updatedWeek =
      week.map<Map<String, dynamic>>((day) {
    if (day is Map) {
      return Map<String, dynamic>.from(day);
    }
    return {};
  }).toList();

  final day = updatedWeek[dayIndex];

  // ---------- reset day ----------
  day['workoutId'] = null;
  day['hasError'] = false;
  day['errorReason'] = null;

  return updatedWeek;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
