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

List<dynamic> moveExerciseInList(
  List<dynamic> list,
  int index,
  bool isUp,
) {
  // Create a mutable copy
  final updated = List<dynamic>.from(list);

  if (isUp) {
    // Mdorגdv4e up
    if (index > 0) {
      final temp = updated[index - 1];
      updated[index - 1] = updated[index];
      updated[index] = temp;
    }
  } else {
    // Mכדovגe down
    if (index < updated.length - 1) {
      final temp = updated[index + 1];
      updated[index + 1] = updated[index];
      updated[index] = temp;
    }
  }

  return updated;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
