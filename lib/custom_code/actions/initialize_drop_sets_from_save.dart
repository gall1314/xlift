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

List<dynamic> initializeDropSetsFromSave(
  List<GetExerciseSetsForWorkoutRow>? savedSets,
  List<GetExercisesSimpRow>? exercises,
) {
  try {
    if (savedSets == null || savedSets.isEmpty) return <dynamic>[];
    if (exercises == null || exercises.isEmpty) return <dynamic>[];

    final Map<String, int> workoutExToExercise = {};

    // -------------------------
    // Map workoutExerciseId -> exerciseId
    // -------------------------
    for (final ex in exercises) {
      try {
        final d = Map<String, dynamic>.from(ex.data);
        final workoutExId = d['id']?.toString();
        final exerciseId = d['exercise_id'];

        if (workoutExId != null && exerciseId is int) {
          workoutExToExercise[workoutExId] = exerciseId;
        }
      } catch (_) {}
    }

    final List<Map<String, dynamic>> drops = [];

    // -------------------------
    // Build DropSets from DB rows
    // -------------------------
    for (final row in savedSets) {
      try {
        if ((row.isDropset ?? 0) != 1) continue;

        final workoutExId = row.workoutExerciseId?.toString();
        if (workoutExId == null) continue;

        final exerciseId = workoutExToExercise[workoutExId];
        if (exerciseId == null) continue;

        final parentSetNumber = row.setNumber;
        if (parentSetNumber == null) continue;

        drops.add({
          'exerciseId': exerciseId,
          'parentSetNumber': parentSetNumber,
          'dropOrder': row.dropNumber ?? 1, // נשאר כמו שהיה
          'reps': row.targetReps,
          'percentFromParent': null,
          'locked': false,
        });
      } catch (_) {}
    }

    // -------------------------
    // SORT (by dropOrder)
    // -------------------------
    try {
      drops.sort((a, b) {
        final exCmp = (a['exerciseId'] ?? 0).compareTo(b['exerciseId'] ?? 0);
        if (exCmp != 0) return exCmp;

        final setCmp =
            (a['parentSetNumber'] ?? 0).compareTo(b['parentSetNumber'] ?? 0);
        if (setCmp != 0) return setCmp;

        return (a['dropOrder'] ?? 0).compareTo(b['dropOrder'] ?? 0);
      });
    } catch (_) {}

    return drops;
  } catch (_) {
    return <dynamic>[];
  }
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
