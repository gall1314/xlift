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

Future<void> syncPendingWorkoutLogs() async {
  final box = await Hive.openBox('pendingWorkoutLogs');

  if (box.isEmpty) return;

  // Work with keys, not indices - deleting by key never shifts
  // the position of the remaining entries.
  final keys = box.keys.toList();

  for (final key in keys) {
    final raw = box.get(key);
    if (raw == null) continue;

    final entry = Map<String, dynamic>.from(raw as Map);

    try {
      await SupaFlow.client.from('workout_log').upsert(entry, onConflict: 'id');

      await box.delete(key);
    } catch (e) {
      // Stop on first failure (likely offline) - remaining entries
      // stay queued for the next run.
      break;
    }
  }
}
