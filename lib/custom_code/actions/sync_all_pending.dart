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

import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'xlift_log_add.dart';

/// Syncs ALL pending offline queues to Supabase in FK-safe order: templates:
/// workout -> workout_exercise -> exercise_sets history:   workout_log ->
/// set_log -> set_analysis quota:     analysis_usage (independent)
///
/// Deletes each Hive entry ONLY after its row was accepted by Supabase (safe
/// key-based deletion, no index-shift bugs).
///
/// A failure in one queue stops that queue (retry next time) but lets the
/// earlier queues' successes stand. Every Supabase call has a hard timeout -
/// this NEVER hangs and NEVER throws.
///
/// Auth guard: no signed-in user -> one refreshSession attempt, else all
/// queues are left untouched and `not signed in` is reported.
///
/// FK fallback (workout_log only, safety net): if a row is rejected because
/// its workout_id points to a template that is not in the cloud, it is
/// re-sent with workout_id = null (requires workout_log.workout_id to be
/// nullable). Covers logs whose template failed/was never queued.
///
/// Returns JSON: { success, workouts, workoutExercises, exerciseSets,
/// workoutLogs, setLogs, analyses, usage, errors, pending, debug_string }
Future<dynamic> syncAllPending() async {
  final sw = Stopwatch()..start();
  const Duration rowTimeout = Duration(seconds: 15);

  xliftLogAdd('[syncAll] START');
  final errors = <String>[];
  final Map<String, int> pendingAfter = {};
  final Map<String, int> syncedByTable = {};
  final List<String> dbgLines = [];

  // FK-safe order: parents before children.
  const List<List<String>> queues = [
    ['pendingWorkouts', 'workout'],
    ['pendingWorkoutExercises', 'workout_exercise'],
    ['pendingExerciseSets', 'exercise_sets'],
    ['pendingWorkoutLogs', 'workout_log'],
    ['pendingSetLogs', 'set_log'],
    ['pendingSetAnalyses', 'set_analysis'],
    ['pendingAnalysisUsage', 'analysis_usage'],
  ];

  // ---------- Auth guard ----------
  String? uid = SupaFlow.client.auth.currentUser?.id;
  final session = SupaFlow.client.auth.currentSession;
  final bool expired = session?.isExpired ?? true;
  if (uid == null || expired) {
    try {
      final res = await SupaFlow.client.auth
          .refreshSession()
          .timeout(const Duration(seconds: 10));
      uid = res.user?.id ?? SupaFlow.client.auth.currentUser?.id;
      xliftLogAdd('[syncAll] session refreshed, uid=$uid');
    } catch (e) {
      xliftLogAdd('[syncAll] refreshSession failed: $e');
    }
  }
  if (uid == null) {
    const msg = 'not signed in - sync skipped, queues kept';
    xliftLogAdd('[syncAll] $msg');
    for (final q in queues) {
      try {
        pendingAfter[q[1]] = (await Hive.openBox(q[0])).length;
      } catch (_) {}
    }
    return {
      'success': false,
      'workouts': 0,
      'workoutExercises': 0,
      'exerciseSets': 0,
      'workoutLogs': 0,
      'setLogs': 0,
      'analyses': 0,
      'usage': 0,
      'errors': msg,
      'pending': pendingAfter,
      'debug_string': '$msg | ${sw.elapsedMilliseconds}ms',
    };
  }
  final String userId = uid;

  Future<void> upsertRow(String table, Map<String, dynamic> row) async {
    await SupaFlow.client.from(table).upsert(row).timeout(rowTimeout,
        onTimeout: () {
      throw TimeoutException('no response within ${rowTimeout.inSeconds}s');
    });
  }

  // Generic per-box sync: insert to Supabase, delete from Hive by KEY.
  Future<int> syncBox(String boxName, String table) async {
    int synced = 0;
    int pendingBefore = 0;
    int fkFallbacks = 0;
    String? failMsg;
    String? failKeys;
    try {
      final box = await Hive.openBox(boxName);
      pendingBefore = box.length;
      if (box.isEmpty) {
        pendingAfter[table] = 0;
        dbgLines.add('$table: nothing pending');
        return 0;
      }

      // Snapshot of keys - safe to delete while iterating this list.
      final keys = box.keys.toList();
      xliftLogAdd('[syncAll] $boxName: ${keys.length} pending');

      for (final key in keys) {
        final raw = box.get(key);
        if (raw == null) continue;

        // Hive returns Map<dynamic,dynamic> - Supabase needs String keys.
        final row = Map<String, dynamic>.from(raw as Map);

        // Rows carrying a user_id must belong to the signed-in user, or
        // RLS rejects them. Surface that clearly instead of a bare 42501.
        final rowUid = row['user_id']?.toString();
        if (rowUid != null && rowUid.isNotEmpty && rowUid != userId) {
          failMsg = 'row user_id=$rowUid != signed-in $userId';
          failKeys = row.keys.join(',');
          xliftLogAdd('[syncAll] $table $failMsg');
          errors.add('$table: $failMsg');
          break;
        }

        try {
          try {
            await upsertRow(table, row);
          } catch (e) {
            // FK fallback: template missing in the cloud -> detach it.
            final String es = e.toString();
            final bool templateFk = table == 'workout_log' &&
                es.contains('23503') &&
                es.contains('workout_id') &&
                row['workout_id'] != null;
            if (!templateFk) rethrow;
            xliftLogAdd('[syncAll] workout_log ${row['id']}: template '
                '${row['workout_id']} not in cloud, retrying with null');
            final retry = Map<String, dynamic>.from(row)..['workout_id'] = null;
            await upsertRow(table, retry);
            fkFallbacks++;
          }
          await box.delete(key); // key-based - no index shifting
          synced++;
        } catch (e) {
          failMsg = e.toString();
          failKeys = row.keys.join(',');
          xliftLogAdd('[syncAll] $table row failed: $failMsg '
              'keys=[$failKeys]');
          errors.add('$table: $failMsg');
          // Stop this queue - likely offline, FK or schema issue; retry later.
          break;
        }
      }
      pendingAfter[table] = box.length;
    } catch (e) {
      failMsg = 'box error: $e';
      xliftLogAdd('[syncAll] $boxName $failMsg');
      errors.add('$boxName: $e');
      pendingAfter[table] = pendingBefore;
    }

    final int left = pendingAfter[table] ?? pendingBefore;
    final String fb = fkFallbacks > 0 ? ' ($fkFallbacks detached)' : '';
    if (failMsg == null) {
      dbgLines.add('$table: sent $synced$fb, left $left');
    } else {
      dbgLines.add('$table: sent $synced$fb, left $left FAIL [$failMsg]'
          '${failKeys != null ? ' keys=[$failKeys]' : ''}');
    }
    return synced;
  }

  for (final q in queues) {
    syncedByTable[q[1]] = await syncBox(q[0], q[1]);
  }

  final String debugString =
      'uid=${userId.substring(0, 8)} | ${dbgLines.join(' | ')} | '
      '${sw.elapsedMilliseconds}ms';
  xliftLogAdd('[syncAll] DONE $debugString');

  return {
    'success': errors.isEmpty,
    'workouts': syncedByTable['workout'] ?? 0,
    'workoutExercises': syncedByTable['workout_exercise'] ?? 0,
    'exerciseSets': syncedByTable['exercise_sets'] ?? 0,
    'workoutLogs': syncedByTable['workout_log'] ?? 0,
    'setLogs': syncedByTable['set_log'] ?? 0,
    'analyses': syncedByTable['set_analysis'] ?? 0,
    'usage': syncedByTable['analysis_usage'] ?? 0,
    'errors': errors.join(' | '),
    'pending': pendingAfter,
    'debug_string': debugString,
  };
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
