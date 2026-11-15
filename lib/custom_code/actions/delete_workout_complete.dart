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

/// Deletes ONE logged workout everywhere, children before parents:
/// set_analysis -> set_log -> workout_log.
///
/// 1. Local SQLite, in one transaction (all three or nothing).
/// 2. Hive upload queues (pendingSetLogs / pendingSetAnalyses /
///    pendingWorkoutLogs): rows of this workout that were still waiting to
///    be uploaded are removed, so syncAllPending never re-uploads a deleted
///    workout.
/// 3. Supabase: the delete is first written to the Hive box
///    `pendingWorkoutLogDeletes`, then sent. It leaves the box only after
///    Supabase accepted it, so an offline delete is retried the next time
///    this action runs. Deletes left over from earlier runs are sent too.
///
/// NEVER throws. Returns JSON:
/// { success, hiveRemoved, cloud: 'deleted' | 'queued', pendingDeletes, errors }
///   success - the local delete went through.
Future<dynamic> deleteWorkoutComplete(String workoutLogId) async {
  const String deletesBox = 'pendingWorkoutLogDeletes';
  const Duration cloudTimeout = Duration(seconds: 10);

  final String id = workoutLogId.trim();
  final errors = <String>[];
  final Set<String> setIds = {};
  int hiveRemoved = 0;

  String str(dynamic v) => (v ?? '').toString();

  if (id.isEmpty) {
    return {
      'success': false,
      'hiveRemoved': 0,
      'cloud': 'queued',
      'pendingDeletes': 0,
      'errors': 'empty workoutLogId',
    };
  }
  xliftLogAdd('[deleteWorkout] START id=$id');

  final db = SQLiteManager.instance.database;

  // ---------- 1. Local SQLite ----------
  // The set ids are read first: after the delete there is no way to find
  // this workout's analyses (locally, in Hive or in Supabase).
  bool localOk = false;
  try {
    final rows = await db.rawQuery(
      'SELECT id FROM set_log WHERE workout_log_id = ?',
      [id],
    );
    for (final r in rows) {
      final String sid = str(r['id']);
      if (sid.isNotEmpty) setIds.add(sid);
    }
    await db.transaction((txn) async {
      await txn.rawDelete(
        'DELETE FROM set_analysis WHERE set_log_id IN '
        '(SELECT id FROM set_log WHERE workout_log_id = ?)',
        [id],
      );
      await txn.rawDelete(
        'DELETE FROM set_log WHERE workout_log_id = ?',
        [id],
      );
      await txn.rawDelete(
        'DELETE FROM workout_log WHERE id = ?',
        [id],
      );
    });
    localOk = true;
  } catch (e) {
    errors.add('local: $e');
    xliftLogAdd('[deleteWorkout] local delete FAILED: $e');
  }

  if (!localOk) {
    // Nothing else is touched: the workout still exists on the device.
    return {
      'success': false,
      'hiveRemoved': 0,
      'cloud': 'queued',
      'pendingDeletes': 0,
      'errors': errors.join(' | '),
    };
  }

  // ---------- 2. Hive upload queues ----------
  Future<void> purge(
    String boxName,
    bool Function(Map row) match, {
    void Function(Map row)? onMatch,
  }) async {
    try {
      final box = await Hive.openBox(boxName);
      // Snapshot of keys - safe to delete while iterating this list.
      for (final key in box.keys.toList()) {
        final raw = box.get(key);
        if (raw is! Map) continue;
        if (!match(raw)) continue;
        if (onMatch != null) onMatch(raw);
        await box.delete(key);
        hiveRemoved++;
      }
    } catch (e) {
      errors.add('$boxName: $e');
    }
  }

  // Sets first: a queued set may not be in SQLite any more, and its id is
  // needed to find its queued analysis.
  await purge(
    'pendingSetLogs',
    (r) => str(r['workout_log_id']) == id,
    onMatch: (r) {
      final String sid = str(r['id']);
      if (sid.isNotEmpty) setIds.add(sid);
    },
  );
  await purge(
    'pendingSetAnalyses',
    (r) => setIds.contains(str(r['set_log_id'])),
  );
  await purge('pendingWorkoutLogs', (r) => str(r['id']) == id);

  // ---------- 3. Supabase ----------
  // Queue first, send second: if the app dies or the network is down, the
  // delete is still on disk.
  int pendingDeletes = 0;
  String cloud = 'queued';
  try {
    final box = await Hive.openBox(deletesBox);
    await box.put(id, {
      'workout_log_id': id,
      'set_log_ids': setIds.toList(),
    });

    if (SupaFlow.client.auth.currentUser != null) {
      for (final key in box.keys.toList()) {
        final raw = box.get(key);
        if (raw is! Map) {
          await box.delete(key);
          continue;
        }
        final String wid = str(raw['workout_log_id'] ?? key);
        final List<String> sids = [
          for (final x in (raw['set_log_ids'] as List? ?? const [])) str(x),
        ];
        try {
          if (sids.isNotEmpty) {
            final String inList = '(${sids.map((x) => '"$x"').join(',')})';
            await SupaFlow.client
                .from('set_analysis')
                .delete()
                .filter('set_log_id', 'in', inList)
                .timeout(cloudTimeout);
          }
          await SupaFlow.client
              .from('set_log')
              .delete()
              .eq('workout_log_id', wid)
              .timeout(cloudTimeout);
          await SupaFlow.client
              .from('workout_log')
              .delete()
              .eq('id', wid)
              .timeout(cloudTimeout);
          await box.delete(key);
        } catch (e) {
          errors.add('cloud: $e');
          xliftLogAdd('[deleteWorkout] cloud delete failed ($wid): $e');
          // Offline or rejected: keep the rest queued, retry next time.
          break;
        }
      }
    }
    pendingDeletes = box.length;
    cloud = box.containsKey(id) ? 'queued' : 'deleted';
  } catch (e) {
    errors.add('$deletesBox: $e');
  }

  xliftLogAdd('[deleteWorkout] DONE hiveRemoved=$hiveRemoved cloud=$cloud '
      'pendingDeletes=$pendingDeletes errors=${errors.length}');
  return {
    'success': true,
    'hiveRemoved': hiveRemoved,
    'cloud': cloud,
    'pendingDeletes': pendingDeletes,
    'errors': errors.join(' | '),
  };
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
