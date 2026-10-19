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
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'xlift_log_add.dart';

bool _syncAllRunning = false;

/// Syncs ALL pending offline queues to Supabase in FK-safe order: custom
/// exercises: exercise -> exercise_muscle_group templates:        workout ->
/// workout_exercise -> exercise_sets history:          workout_log -> set_log
/// -> set_analysis quota:            analysis_usage (independent)
///
/// OFFLINE-SAFE: a 3s DNS probe runs first.
///
/// No network -> returns at once with `offline - sync skipped`, queues
/// untouched, no Supabase calls. RE-ENTRANT-SAFE: a second call while one is
/// running returns at once.
///
/// BATCHED: each queue is upserted in chunks of [batchSize] rows (one request
/// per chunk). If a chunk is rejected, its rows are retried one by one so the
/// offending row is identified and the good ones still land.
///
/// Cloud columns match SQLite 1:1 - rows are sent as queued, no translation.
///
/// Hive entries are deleted ONLY after Supabase accepted the row (key-based,
/// no index-shift bugs) - OR when the row can never land ("drop"). Every call
/// has a hard timeout - NEVER hangs, NEVER throws.
///
/// Per-row rules: - RLS mismatch (row user_id / created_by_user_id !=
/// signed-in user) -> stop queue, report. - workout_exercise 23503 on
/// exercise_id (exercise not in the cloud) -> DROP that row, remember its id,
/// continue. - exercise_sets 23503 on workout_exercise_id (orphan) -> DROP,
/// continue. Sets whose parent was dropped in this run are dropped up-front.
/// - workout_log 23503 on workout_id (template missing) -> re-send with
/// workout_id = null. - anything else -> stop that queue, retry next sync.
///
/// Returns JSON: { success, exercises, exerciseMuscleGroups, workouts,
/// workoutExercises, exerciseSets, workoutLogs, setLogs, analyses, usage,
/// errors, pending, debug_string }
Future<dynamic> syncAllPending() async {
  final sw = Stopwatch()..start();
  const Duration callTimeout = Duration(seconds: 20);
  const int batchSize = 50;

  // FK-safe order: parents before children.
  const List<List<String>> queues = [
    ['pendingExercises', 'exercise'],
    ['pendingExerciseMuscleGroups', 'exercise_muscle_group'],
    ['pendingWorkouts', 'workout'],
    ['pendingWorkoutExercises', 'workout_exercise'],
    ['pendingExerciseSets', 'exercise_sets'],
    ['pendingWorkoutLogs', 'workout_log'],
    ['pendingSetLogs', 'set_log'],
    ['pendingSetAnalyses', 'set_analysis'],
    ['pendingAnalysisUsage', 'analysis_usage'],
  ];

  Map<String, dynamic> skippedResult(String msg, Map<String, int> pending) => {
        'success': false,
        'exercises': 0,
        'exerciseMuscleGroups': 0,
        'workouts': 0,
        'workoutExercises': 0,
        'exerciseSets': 0,
        'workoutLogs': 0,
        'setLogs': 0,
        'analyses': 0,
        'usage': 0,
        'errors': msg,
        'pending': pending,
        'debug_string': '$msg | ${sw.elapsedMilliseconds}ms',
      };

  Future<Map<String, int>> countPending() async {
    final Map<String, int> p = {};
    for (final q in queues) {
      try {
        p[q[1]] = (await Hive.openBox(q[0])).length;
      } catch (_) {}
    }
    return p;
  }

  // ---------- Re-entrancy guard ----------
  if (_syncAllRunning) {
    xliftLogAdd('[syncAll] already running - skipped');
    return skippedResult('already running - skipped', {});
  }
  _syncAllRunning = true;

  try {
    xliftLogAdd('[syncAll] START');

    // ---------- Connectivity probe ----------
    bool online = false;
    try {
      final r = await InternetAddress.lookup('supabase.co')
          .timeout(const Duration(seconds: 3));
      online = r.isNotEmpty && r.first.rawAddress.isNotEmpty;
    } catch (_) {
      online = false;
    }
    if (!online) {
      const msg = 'offline - sync skipped, queues kept';
      xliftLogAdd('[syncAll] $msg');
      return skippedResult(msg, await countPending());
    }

    final errors = <String>[];
    final Map<String, int> pendingAfter = {};
    final Map<String, int> syncedByTable = {};
    final List<String> dbgLines = [];
    final Set<String> skippedWorkoutExerciseIds = {};

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
      return skippedResult(msg, await countPending());
    }
    final String userId = uid;

    Future<void> upsertRows(String table, List<Map<String, dynamic>> rows) {
      return SupaFlow.client.from(table).upsert(rows).timeout(callTimeout,
          onTimeout: () {
        throw TimeoutException('no response within ${callTimeout.inSeconds}s');
      });
    }

    /// Returns: 'ok' | 'drop' (remove from Hive, continue) | throws (stop).
    Future<String> sendOne(String table, Map<String, dynamic> row) async {
      try {
        await upsertRows(table, [row]);
        return 'ok';
      } catch (e) {
        final String es = e.toString();
        final bool fk = es.contains('23503');
        if (fk && table == 'workout_exercise' && es.contains('exercise_id')) {
          skippedWorkoutExerciseIds.add('${row['id']}');
          xliftLogAdd('[syncAll] workout_exercise ${row['id']}: exercise '
              '${row['exercise_id']} not in cloud - dropped');
          return 'drop';
        }
        if (fk &&
            table == 'exercise_sets' &&
            es.contains('workout_exercise_id')) {
          xliftLogAdd('[syncAll] exercise_sets ${row['id']}: parent '
              '${row['workout_exercise_id']} not in cloud (orphan) - dropped');
          return 'drop';
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

        final List<MapEntry<dynamic, Map<String, dynamic>>> items = [];
        for (final key in box.keys.toList()) {
          final raw = box.get(key);
          if (raw is Map) {
            items.add(MapEntry(key, Map<String, dynamic>.from(raw)));
          }
        }
        xliftLogAdd('[syncAll] $boxName: ${items.length} pending');

        // Orphan pre-filter: sets whose parent was dropped in this run.
        if (table == 'exercise_sets' && skippedWorkoutExerciseIds.isNotEmpty) {
          final orphans = items
              .where((it) => skippedWorkoutExerciseIds
                  .contains('${it.value['workout_exercise_id']}'))
              .toList();
          for (final it in orphans) {
            await box.delete(it.key);
            items.remove(it);
            skipped++;
          }
          if (orphans.isNotEmpty) {
            xliftLogAdd('[syncAll] exercise_sets: ${orphans.length} orphan '
                'rows dropped');
          }
          if (items.isEmpty) {
            pendingAfter[table] = box.length;
            dbgLines
                .add('$table: sent 0 ($skipped skipped), left ${box.length}');
            return 0;
          }
        }

        // RLS guard: every owned row must belong to this user.
        for (final it in items) {
          final rowUid = (it.value['user_id'] ?? it.value['created_by_user_id'])
              ?.toString();
          if (rowUid != null && rowUid.isNotEmpty && rowUid != userId) {
            failMsg = 'row owner=$rowUid != signed-in $userId';
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

          for (final it in chunk) {
            try {
              final r = await sendOne(table, it.value);
              await box.delete(it.key); // 'ok' landed, 'drop' can never land
              if (r == 'ok') {
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
      'exercises': syncedByTable['exercise'] ?? 0,
      'exerciseMuscleGroups': syncedByTable['exercise_muscle_group'] ?? 0,
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
  } finally {
    _syncAllRunning = false;
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
