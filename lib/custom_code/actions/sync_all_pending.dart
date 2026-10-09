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

/// Syncs ALL pending offline queues to Supabase in FK-safe order:
/// workout_logs -> set_logs -> set_analyses, plus the independent
/// analysis_usage queue (no FK, quota events).
///
/// Deletes each Hive entry ONLY after its row was accepted by Supabase (safe
/// key-based deletion, no index-shift bugs). A failure in one queue stops
/// that queue (retry next time) but lets the earlier queues' successes stand.
/// Every Supabase call has a hard timeout - this NEVER hangs and NEVER
/// throws.
///
/// Returns JSON: { success, workoutLogs, setLogs, analyses, usage, errors,
/// pending, debug_string } debug_string - one line per queue, ready for a
/// Text/Snackbar: "workout_log: sent 1, left 0 | set_log: sent 0, left 6 FAIL
/// [column "duration" does not exist] keys=[id,workout_id,...]"
Future<dynamic> syncAllPending() async {
  final sw = Stopwatch()..start();
  const Duration rowTimeout = Duration(seconds: 15);

  xliftLogAdd('[syncAll] START');
  int syncedLogs = 0, syncedSets = 0, syncedAnalyses = 0, syncedUsage = 0;
  final errors = <String>[];
  final Map<String, int> pendingAfter = {};
  final List<String> dbgLines = [];

  // Generic per-box sync: insert to Supabase, delete from Hive by KEY.
  Future<int> syncBox(String boxName, String table) async {
    int synced = 0;
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

      // Snapshot of keys - safe to delete while iterating this list.
      final keys = box.keys.toList();
      xliftLogAdd('[syncAll] $boxName: ${keys.length} pending');

      for (final key in keys) {
        final raw = box.get(key);
        if (raw == null) continue;

        // Hive returns Map<dynamic,dynamic> - Supabase needs String keys.
        final row = Map<String, dynamic>.from(raw as Map);

        try {
          await SupaFlow.client.from(table).upsert(row).timeout(rowTimeout,
              onTimeout: () {
            throw TimeoutException(
                'no response within ${rowTimeout.inSeconds}s');
          });
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
    if (failMsg == null) {
      dbgLines.add('$table: sent $synced, left $left');
    } else {
      dbgLines.add('$table: sent $synced, left $left FAIL [$failMsg]'
          '${failKeys != null ? ' keys=[$failKeys]' : ''}');
    }
    return synced;
  }

  // FK-safe order: parents before children.
  syncedLogs = await syncBox('pendingWorkoutLogs', 'workout_log');
  syncedSets = await syncBox('pendingSetLogs', 'set_log');
  syncedAnalyses = await syncBox('pendingSetAnalyses', 'set_analysis');
  // Independent queue (no FK) - quota usage events.
  syncedUsage = await syncBox('pendingAnalysisUsage', 'analysis_usage');

  final String debugString =
      '${dbgLines.join(' | ')} | ${sw.elapsedMilliseconds}ms';
  xliftLogAdd('[syncAll] DONE $debugString');

  return {
    'success': errors.isEmpty,
    'workoutLogs': syncedLogs,
    'setLogs': syncedSets,
    'analyses': syncedAnalyses,
    'usage': syncedUsage,
    'errors': errors.join(' | '),
    'pending': pendingAfter,
    'debug_string': debugString,
  };
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
