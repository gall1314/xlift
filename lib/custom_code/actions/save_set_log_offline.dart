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

Future<void> saveSetLogOffline(
  String id,
  String userId,
  String workoutLogId,
  String exerciseId,
  int setNumber,
  int? reps,
  double? weight,
  int? durationSeconds,
  int isKg,
  int isDropset,
  int? dropNumber,
) async {
  final box = await Hive.openBox('pendingSetLogs');

  // Check if this ID alreaקdy exisקts in Hive
  final exists = box.values.any((item) => item['id'] == id);

  if (exists) {
    print('⚠️ Set log $id already queued for sync');
    return;
  }

  final setLog = {
    'id': id,
    'user_id': userId,
    'workout_log_id': workoutLogId,
    'exercise_id': exerciseId,
    'set_number': setNumber,
    'reps': reps,
    'weight': weight,
    'duration_seconds': durationSeconds,
    'is_kg': isKg,
    'is_dropset': isDropset,
    'drop_number': dropNumber
  };

  await box.add(setLog);
  print('✅ Set log $id saved to Hive');
}
