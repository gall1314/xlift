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

/// Inserts workout_exercise rows for a workout, straight from the
/// getworkoutExercise SQLite query result (typed Row list).
/// Copies exercise_id, exercise_name and order; rest/notes/superset
/// are not part of the query output and are written as NULL/defaults.
/// Returns JSON: { success, inserted } or { success: false, error }.
/// NEVER throws.
Future<dynamic> insertWorkoutExercises(
  String workoutId,
  String userId,
  List<GetworkoutExerciseRow> exercises,
) async {
  print('[insertWE] START count=${exercises.length}');

  int uuidCounter = 0;
  String uuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final salt = Object().hashCode ^ (uuidCounter++);
    String hex(int v, int width) =>
        v.toRadixString(16).padLeft(width, '0').substring(0, width);
    final a = hex(now & 0xFFFFFFFF, 8);
    final b = hex((now >> 32) & 0xFFFF, 4);
    final c = hex(salt & 0xFFF, 3);
    final d = hex((salt >> 12) & 0xFFF, 3);
    final e = hex(((now ^ (salt << 20)) & 0xFFFFFFFFFFFF), 12);
    return '$a-$b-4$c-8$d-$e';
  }

  try {
    final db = SQLiteManager.instance.database;
    final nowIso = DateTime.now().toIso8601String();

    int inserted = 0;
    int fallbackOrder = 0;

    for (final row in exercises) {
      fallbackOrder++;

      final int exerciseId = row.exerciseId ?? 0;
      if (exerciseId <= 0) {
        print('[insertWE] SKIP row without exercise_id');
        continue;
      }

      final String exerciseName = row.exerciseName ?? '';
      if (exerciseName.isEmpty) {
        print('[insertWE] SKIP ex=$exerciseId - missing exercise_name '
            '(NOT NULL in schema)');
        continue;
      }

      final int rowOrder = row.order ?? fallbackOrder;

      print('[insertWE] ex=$exerciseId "$exerciseName" order=$rowOrder');
      await db.rawInsert(
        'INSERT OR IGNORE INTO workout_exercise '
        '(id, workout_id, exercise_id, created_at, "order", '
        'exercise_name, user_id, rest_seconds, notes, '
        'is_superset, superset_group_id) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          uuid(),
          workoutId,
          exerciseId,
          nowIso,
          rowOrder,
          exerciseName,
          userId,
          null, // rest_seconds - not in query output
          null, // notes
          0, // is_superset
          null, // superset_group_id
        ],
      );
      inserted++;
    }

    print('[insertWE] DONE inserted=$inserted');
    return {'success': true, 'inserted': inserted};
  } catch (e) {
    print('[insertWE] FATAL: $e');
    return {'success': false, 'error': e.toString()};
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
