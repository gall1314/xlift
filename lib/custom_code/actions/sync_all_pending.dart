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
/// BATCHED: each queue is upserted in chunks of [batchSize] rows (one request
/// per chunk).
///
/// If a chunk is rejected, its rows are retried one by one so the offending
/// row is identified and the good ones still land.
///
/// Cloud columns match SQLite 1:1 (exercise_sets.set_number / workout_id
/// exist in the cloud) - rows are sent as queued, no translation.
///
/// Hive entries are deleted ONLY after Supabase accepted the row (key-based,
/// no index-shift bugs). Every call has a hard timeout - NEVER hangs, NEVER
/// throws.
///
/// Per-row rules: - RLS mismatch (row user_id != signed-in user) -> stop
/// queue, report. - workout_exercise 23503 on exercise_id (custom exercise
/// not in the cloud) -> SKIP that row (kept in Hive), continue with the rest.
/// - workout_log 23503 on workout_id (template missing) -> re-send with
/// workout_id = null (safety net; needs nullable column). - anything else ->
/// stop that queue, retry next sync.
///
/// Auth guard: no signed-in user -> one refreshSession attempt, else all
/// queues are left untouched and `not signed in` is reported.
///
/// Returns JSON: { success, workouts, workoutExercises, exerciseSets,
/// workoutLogs, setLogs, analyses, usage, errors, pending, debug_string }
Future<dynamic> syncAllPending() async {
  final sw = Stopwatch()..start();
  const Duration callTimeout = Duration(seconds: 20);
  const int batchSize = 50;

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

  Future<void> upsertRows(String table, List<Map<String, dynamic>> rows) {
    return SupaFlow.client.from(table).upsert(rows).timeout(callTimeout,
        onTimeout: () {
      throw TimeoutException('no response within ${callTimeout.inSeconds}s');
    });
  }

  /// Sends ONE row with the per-table fallbacks.
  /// Returns: 'ok' | 'skip' (row kept, continue) | throws (stop queue).
  Future<String> sendOne(String table, Map<String, dynamic> row) async {
    try {
      await upsertRows(table, [row]);
      return 'ok';
    } catch (e) {
      final String es = e.toString();
      final bool fk = es.contains('23503');
      if (fk && table == 'workout_exercise' && es.contains('exercise_id')) {
        xliftLogAdd('[syncAll] workout_exercise ${row['id']}: exercise '
            '${row['exercise_id']} not in cloud (custom) - skipped');
        return 'skip';
      }
      if (fk &&
          table == 'workout_log' &&
          es.contains('workout_id') &&
          row['workout_id'] != null) {
        xliftLogAdd('[syncAll] workout_log ${row['id']}: template '
            '${row['workout_id']} not in cloud, retrying with null');
        final retry = Map<String, dynamic>.from(row)..['workout_id'] = null;
        await upsertRows(table, [retry]);
        return 'ok';
      }
      rethrow;
    }
  }

  // Per-box sync: batch upsert, per-row fallback, key-based Hive delete.
  Future<int> syncBox(String boxName, String table) async {
    int synced = 0;
    int skipped = 0;
    int pendingBefore = 0;
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

      // Snapshot (key, row) - safe to delete while iterating.
      final List<MapEntry<dynamic, Map<String, dynamic>>> items = [];
      for (final key in box.keys.toList()) {
        final raw = box.get(key);
        if (raw is Map) {
          items.add(MapEntry(key, Map<String, dynamic>.from(raw)));
        }
      }
      xliftLogAdd('[syncAll] $boxName: ${items.length} pending');

      // RLS guard: every row with a user_id must belong to this user.
      for (final it in items) {
        final rowUid = it.value['user_id']?.toString();
        if (rowUid != null && rowUid.isNotEmpty && rowUid != userId) {
          failMsg = 'row user_id=$rowUid != signed-in $userId';
          failKeys = it.value.keys.join(',');
          xliftLogAdd('[syncAll] $table $failMsg');
          errors.add('$table: $failMsg');
          pendingAfter[table] = box.length;
          dbgLines.add('$table: sent 0, left ${box.length} FAIL [$failMsg]');
          return 0;
        }
      }

      bool stop = false;
      for (int start = 0; start < items.length && !stop; start += batchSize) {
        final chunk =
            items.sublist(start, (start + batchSize).clamp(0, items.length));

        // 1) Try the whole chunk in one request.
        bool chunkOk = false;
        try {
          await upsertRows(table, chunk.map((e) => e.value).toList());
          chunkOk = true;
        } catch (e) {
          xliftLogAdd('[syncAll] $table chunk@$start failed, '
              'falling back to per-row: $e');
        }
        if (chunkOk) {
          for (final it in chunk) {
            await box.delete(it.key);
          }
          synced += chunk.length;
          continue;
        }

        // 2) Per-row fallback to isolate the bad row(s).
        for (final it in chunk) {
          try {
            final r = await sendOne(table, it.value);
            if (r == 'ok') {
              await box.delete(it.key);
              synced++;
            } else {
              skipped++;
            }
          } catch (e) {
            failMsg = e.toString();
            failKeys = it.value.keys.join(',');
            xliftLogAdd('[syncAll] $table row failed: $failMsg '
                'keys=[$failKeys]');
            errors.add('$table: $failMsg');
            stop = true;
            break;
          }
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
    final String sk = skipped > 0 ? ' ($skipped skipped)' : '';
    if (failMsg == null) {
      dbgLines.add('$table: sent $synced$sk, left $left');
    } else {
      dbgLines.add('$table: sent $synced$sk, left $left FAIL [$failMsg]'
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
