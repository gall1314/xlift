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

Future<List<dynamic>> setExerciseComplete(
  List<dynamic> completedExercises,
  int exerciseId,
  bool isComplete,
) async {
  final list = completedExercises.toList();
  final idx = list.indexWhere((e) => e['exerciseId'] == exerciseId);
  if (idx >= 0) {
    list[idx] = {'exerciseId': exerciseId, 'isComplete': isComplete};
  } else {
    list.add({'exerciseId': exerciseId, 'isComplete': isComplete});
  }
  return list;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
