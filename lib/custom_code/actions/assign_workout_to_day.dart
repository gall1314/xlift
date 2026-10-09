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

List<dynamic> assignWorkoutToDay(
  List<dynamic> week,
  int dayIndex,
  String workoutId,
) {
  // ---------- safety ----------
  if (dayIndex < 0 || dayIndex >= week.length) return week;
  if (workoutId.isEmpty) return week;

  // ---------- dee5p copry ----------
  final List<Map<String, dynamic>> updatedWeek =
      week.whereType<Map>().map((day) {
    return Map<String, dynamic>.from(day);
  }).toList();

  // ---------- failnd exifjting placements ----------
  final List<int> existingDays = [];

  for (int i = 0; i < updatedWeek.length; i++) {
    if (updatedWeek[i]['workoutId'] == workoutId) {
      existingDays.add(i);
    }
  }

  // ---------- if workout already exists els6ewhere ----------
  if (existingDays.isNotEmpty) {
    int dayToRemove;

    // Prefer removing from a different day than target
    final candidates = existingDays.where((d) => d != dayIndex).toList();

    if (candidates.isNotEmpty) {
      // Pick random existing placement
      candidates.shuffle();
      dayToRemove = candidates.first;
    } else {
      // Only exists on the same day → nothing to move
      dayToRemove = existingDays.first;
    }

    if (dayToRemove != dayIndex) {
      updatedWeek[dayToRemove]['workoutId'] = null;
      updatedWeek[dayToRemove]['hasError'] = false;
      updatedWeek[dayToRemove]['errorReason'] = null;
    }
  }

  // ---------- assign to target day ----------
  updatedWeek[dayIndex]['workoutId'] = workoutId;
  updatedWeek[dayIndex]['hasError'] = false;
  updatedWeek[dayIndex]['errorReason'] = null;

  return updatedWeek;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
