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

import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';

// ✅ זה מה שחסר לך
import 'package:hive/hive.dart';

Future<void> saveExerciseSetOffline(
  String id,
  String workoutExerciseId,
  int setNumber,
  int? targetReps,
  int isWarmup,
  int? isDropset,
  int? dropNumber,
  String? workoutId,
  int? weighted,
  int? durationSeconds,
) async {
  final box = await Hive.openBox('pendingExerciseSets');

  final exists = box.values.any((item) => item['id'] == id);

  if (exists) {
    print('⚠️ Exercise set $id already queued for sync');
    return;
  }

  final exerciseSet = {
    'id': id,
    'workout_exercise_id': workoutExerciseId,
    'set_number': setNumber,
    'target_reps': targetReps,
    'is_warmup': isWarmup,
    'is_dropset': isDropset,
    'drop_number': dropNumber,
    'workout_id': workoutId,
    'weighted': weighted ?? 1,
    'duration_seconds': durationSeconds,
  };

  await box.add(exerciseSet);
  print('✅ Exercise set $id saved to Hive');
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
