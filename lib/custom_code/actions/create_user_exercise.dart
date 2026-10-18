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

import 'package:hive_flutter/hive_flutter.dart';
import 'xlift_log_add.dart';

/// Creates a user (custom) exercise end to end:
///   1. unique BIGINT id (same scheme as generateUniqueExerciseId)
///   2. INSERT exercise                       (SQLite, parameterized)
///   3. INSERT exercise_muscle_group primary  (SQLite)
///   4. INSERT exercise_muscle_group per secondary muscle (SQLite)
///   5. queue everything to Hive: pendingExercises / pendingExerciseMuscleGroups
///      (drained by syncAllPending BEFORE workout / workout_exercise)
///
/// Flags are stored as integers 0/1 (SQLite, Hive, cloud). Params:
/// isBodyweight / isTimed arrive as int, allowsBodyweight as bool.
/// secondaryMuscles: List<JSON> of {id, name} (the component's `selected`).
/// Returns the new exercise id, or -1 on failure (never throws).
Future<int> createUserExercise(
  String userId,
  String name,
  String equipment,
  int isBodyweight,
  bool allowsBodyweight,
  int isTimed,
  String? illustration,
  int primaryMuscleGroupId,
  List<dynamic>? secondaryMuscles,
) async {
  int _newId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final randomBits = DateTime.now().millisecondsSinceEpoch % 1024;
    return (now << 10) | randomBits;
  }

  int _flag(int v) => v != 0 ? 1 : 0;

  final String? ill = (illustration == null ||
          illustration.trim().isEmpty ||
          illustration.trim().toLowerCase() == 'null')
      ? null
      : illustration.trim();

  final int exerciseId = _newId();

  // ---- muscle rows: primary first, then secondaries (dedup, skip primary) ----
  final List<Map<String, dynamic>> muscleRows = [];
  final Set<int> seen = {};
  void addMuscle(int mgId, int primary) {
    if (!seen.add(mgId)) return;
    muscleRows.add({
      'id':
          _newId() + muscleRows.length, // ids are generated within the same µs
      'muscle_group_id': mgId,
      'is_primary': primary,
      'exercise_id': exerciseId,
    });
  }

  addMuscle(primaryMuscleGroupId, 1);
  for (final m in (secondaryMuscles ?? const [])) {
    int? mgId;
    if (m is Map) {
      final v = m['id'];
      mgId = v is num ? v.toInt() : int.tryParse('$v');
    } else if (m is num) {
      mgId = m.toInt();
    } else {
      mgId = int.tryParse('$m');
    }
    if (mgId != null && mgId != primaryMuscleGroupId) addMuscle(mgId, 0);
  }

  final Map<String, dynamic> exerciseRow = {
    'id': exerciseId,
    'created_by_user_id': userId,
    'name': name.trim(),
    'equipment': equipment,
    'is_bodyweight': _flag(isBodyweight),
    'allows_bodyweight': allowsBodyweight ? 1 : 0,
    'is_time_based': _flag(isTimed),
    'is_public': 0,
    'is_deleted': 0,
    'illustration': ill,
  };

  // ---- SQLite ----
  try {
    final db = SQLiteManager.instance.database;
    await db.transaction((txn) async {
      await txn.rawInsert(
        'INSERT INTO exercise (id, created_by_user_id, name, equipment, '
        'is_bodyweight, allows_bodyweight, is_time_based, is_public, '
        'is_deleted, illustration) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          exerciseId,
          userId,
          exerciseRow['name'],
          equipment,
          exerciseRow['is_bodyweight'],
          exerciseRow['allows_bodyweight'],
          exerciseRow['is_time_based'],
          0,
          0,
          ill,
        ],
      );
      for (final r in muscleRows) {
        await txn.rawInsert(
          'INSERT INTO exercise_muscle_group (id, muscle_group_id, is_primary, '
          'exercise_id) VALUES (?, ?, ?, ?)',
          [r['id'], r['muscle_group_id'], r['is_primary'], exerciseId],
        );
      }
    });
  } catch (e) {
    xliftLogAdd('[createUserExercise] SQLite failed: $e');
    return -1;
  }

  // ---- Hive queues (keyed by id - re-save overwrites, never duplicates) ----
  try {
    final exBox = await Hive.openBox('pendingExercises');
    await exBox.put('$exerciseId', exerciseRow);
    final mgBox = await Hive.openBox('pendingExerciseMuscleGroups');
    for (final r in muscleRows) {
      await mgBox.put('${r['id']}', r);
    }
  } catch (e) {
    // Local write succeeded; cloud copy is lost but the app keeps working.
    xliftLogAdd('[createUserExercise] Hive queue failed: $e');
  }

  xliftLogAdd(
      '[createUserExercise] created $exerciseId "${exerciseRow['name']}" '
      'with ${muscleRows.length} muscle rows');
  return exerciseId;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
