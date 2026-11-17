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

/// Deletes ONE logged workout, children before parents: set_analysis ->
/// set_log -> workout_log.
///
/// 1. Local SQLite, in one transaction (all three or nothing). 2. Hive upload
/// queues (pendingSetLogs / pendingSetAnalyses / pendingWorkoutLogs): rows of
/// this workout that were still waiting to be uploaded are removed, so
/// syncAllPending never re-uploads a deleted workout. 3. The cloud delete is
/// only QUEUED here, in the Hive box `pendingWorkoutLogDeletes`. This action
/// never talks to Supabase, so it returns at once; syncAllPending sends the
/// queue (and is started here in the background, not awaited).
///
/// NEVER throws. Returns JSON: { success, hiveRemoved, cloud: 'queued',
/// pendingDeletes, errors } success - the local delete went through.
Future<dynamic> deleteWorkoutComplete(String workoutLogId) async {
  const String deletesBox = 'pendingWorkoutLogDeletes';

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

  // ---------- 3. Queue the cloud delete ----------
  // On disk first; syncAllPending sends it and removes it once Supabase
  // accepted it.
  int pendingDeletes = 0;
  const String cloud = 'queued';
  try {
    final box = await Hive.openBox(deletesBox);
    await box.put(id, {
      'workout_log_id': id,
      'set_log_ids': setIds.toList(),
    });
    pendingDeletes = box.length;
  } catch (e) {
    errors.add('$deletesBox: $e');
  }

  // Start the upload in the background: not awaited, never blocks the screen.
  try {
    unawaited(syncAllPending());
  } catch (_) {}

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
