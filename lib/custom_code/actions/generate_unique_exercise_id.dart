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

Future<int> generateUniqueExerciseId() async {
  /// MODIFY CODE ONLY BELOW THIS LINE

  final now = DateTime.now().microsecondsSinceEpoch; // זמן מדויק מאוד
  final randomBits = DateTime.now().millisecondsSinceEpoch % 1024; // קצת רנדום
  final uniqueId =
      (now << 10) | randomBits; // משלב זמן ורנגגדום ל-BIGINT ייחודי
  return uniqueId;

  /// MODIFY CODE ONLY ABOVE THIS LINE
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
