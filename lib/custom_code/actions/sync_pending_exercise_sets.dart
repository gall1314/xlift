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

import 'package:hive/hive.dart';

Future<void> syncPendingExerciseSets() async {
  final box = await Hive.openBox('pendingExerciseSets');

  if (box.isEmpty) return;

  final items = box.values.toList();

  try {
    // 🔥 batch insגert
    await SupaFlow.client.from('exercise_sets').insert(items);

    // 🧹 ניקוי מלא רק אם הצליח
    await box.clear();

    print('✅ Synced ${items.length} exercise sets');
  } catch (e) {
    print('❌ Batch sync failed: $e');
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
