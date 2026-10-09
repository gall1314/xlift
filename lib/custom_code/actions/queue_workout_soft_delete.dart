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

/// Syncs a workout soft-delete to Supabase (is_deleted = 1).
///
/// Safe to call with or without internet - never throws. Returns true if the
/// cloud update succeeded, false otherwise.
import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';

import 'package:hive/hive.dart';

/// Queues a workout soft-delete for cloud sync.
/// Same offline-queue pattern as saveWorkoutOffline: the entry
/// waits in Hive until the sync action runs with internet.
Future<void> queueWorkoutSoftDelete(
  String workoutId,
  String userId,
) async {
  final box = await Hive.openBox('pendingWorkouts');

  await box.add({
    'action': 'soft_delete',
    'id': workoutId,
    'user_id': userId,
  });
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
