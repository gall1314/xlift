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

Future<void> syncPendingWorkoutExercises() async {
  final box = await Hive.openBox('pendingWorkoutExercises');

  if (box.isEmpty) return;

  final exercises = box.values.toList();

  for (var i = 0; i < exercises.length; i++) {
    try {
      await SupaFlow.client.from('workout_exercise').insert(exercises[i]);

      await box.deleteAt(i);
    } catch (e) {
      print('Sync failed: $e');
      break;
    }
  }
}
