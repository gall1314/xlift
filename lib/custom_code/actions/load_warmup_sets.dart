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

/// Reads the warm-up sets saved with a workout (exercise_sets rows with
/// is_warmup = 1) and returns them in the shape App State `warmupSets` uses:
///
/// [
///   {
///     "exerciseId": 12, "hidden": false, "completed": false,
///     "sets": [
///       { "setNumber": 1, "reps": 10, "repsText": "10", "targetReps": 10,
///         "weight": "0", "durationSec": 0, "restSec": 0, "isDone": false }
///     ]
///   }
/// ]
///
/// One entry per exercise, in the workout's exercise order; sets in set
/// order. Exercises without warm-up sets get no entry.
///
/// A template keeps no weight and no rest for a warm-up set, so weight is
/// "0" and restSec is 0.
///
/// Never throws: returns an empty list when there is nothing or on an error.
Future<List<dynamic>> loadWarmupSets(String? workoutId) async {
  final List<dynamic> out = [];
  final String id = (workoutId ?? "").trim();
  if (id.isEmpty) return out;

  int asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return double.tryParse(v.toString().trim())?.toInt() ?? 0;
  }

  try {
    final db = SQLiteManager.instance.database;
    final rows = await db.rawQuery(
      "SELECT CAST(we.exercise_id AS INTEGER) AS exercise_id, "
      "CAST(es.set_number AS INTEGER) AS set_number, "
      "es.target_reps AS target_reps, "
      "es.duration_seconds AS duration_seconds "
      "FROM exercise_sets es "
      "JOIN workout_exercise we ON we.id = es.workout_exercise_id "
      "WHERE we.workout_id = ? "
      "AND COALESCE(CAST(es.is_warmup AS INTEGER), 0) = 1 "
      "AND COALESCE(CAST(es.is_dropset AS INTEGER), 0) = 0 "
      "ORDER BY we.\"order\" ASC, es.set_number ASC",
      [id],
    );

    // exercise id -> its entry, kept in the order the rows arrive
    final Map<int, Map<String, dynamic>> byExercise = {};
    for (final r in rows) {
      final int exerciseId = asInt(r["exercise_id"]);
      final int setNumber = asInt(r["set_number"]);
      if (exerciseId <= 0 || setNumber <= 0) continue;

      Map<String, dynamic>? entry = byExercise[exerciseId];
      if (entry == null) {
        entry = {
          "exerciseId": exerciseId,
          "hidden": false,
          "completed": false,
          "sets": <dynamic>[],
        };
        byExercise[exerciseId] = entry;
        out.add(entry);
      }

      final int reps = asInt(r["target_reps"]);
      final int seconds = asInt(r["duration_seconds"]);
      (entry["sets"] as List<dynamic>).add({
        "setNumber": setNumber,
        "reps": reps,
        "repsText": reps.toString(),
        "targetReps": reps,
        "weight": "0",
        "durationSec": seconds,
        "restSec": 0,
        "isDone": false,
      });
    }
  } catch (_) {
    return <dynamic>[];
  }

  return out;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
