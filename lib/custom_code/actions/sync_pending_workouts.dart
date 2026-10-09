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

/// Syncs the pendingWorkouts queue to Supabase.
/// Handles two entry kinds, distinguished by the 'action' field:
///   - 'soft_delete'  -> UPDATE workout SET is_deleted = 1
///   - anything else  -> upsert the workout row (create/update)
Future<void> syncPendingWorkouts() async {
  final box = await Hive.openBox('pendingWorkouts');

  if (box.isEmpty) return;

  final keys = box.keys.toList();

  for (final key in keys) {
    final raw = box.get(key);
    if (raw == null) continue;

    final entry = Map<String, dynamic>.from(raw as Map);
    final String action = (entry['action'] ?? 'upsert').toString();

    try {
      if (action == 'soft_delete') {
        await SupaFlow.client
            .from('workout')
            .update({'is_deleted': 1}).eq('id', entry['id']);
      } else {
        // Regular create/update - strip the control field before writing.
        final data = Map<String, dynamic>.from(entry)..remove('action');
        await SupaFlow.client.from('workout').upsert(data, onConflict: 'id');
      }

      await box.delete(key);
    } catch (e) {
      break; // Offline / failure - keep the rest queued for next run.
    }
  }
}
