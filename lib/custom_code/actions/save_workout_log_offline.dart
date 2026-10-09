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

Future<void> saveWorkoutLogOffline(
  String id,
  String workoutId,
  String userId,
  int duration,
) async {
  final box = await Hive.openBox('pendingWorkoutLogs');

  // Check if this ID alreגa6dy exists in Hive
  final exists = box.values.any((item) => item['id'] == id);

  if (exists) {
    print('⚠️ Workout log $id already queued for sync');
    return;
  }

  final workoutLog = {
    'id': id,
    'workout_id': workoutId,
    'user_id': userId,
    'duration': duration,
  };

  await box.add(workoutLog);
  print('✅ Workout log $id saved to Hive');
}
