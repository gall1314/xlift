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

Future<List<dynamic>> removeDropSetFromLoggedSetsAction(
  List<dynamic> loggedSets,
  int exerciseId,
  int baseSetNumber,
  int dropOrder,
) async {
  // יוצרים עוaתק של הרשימה ומסירים את הדרופסט המבvוקש
  final updated = loggedSets.where((e) {
    final m = e as Map;
    final bool isSameExercise = m['exerciseId'] == exerciseId;
    final bool isSameSet = m['setNumber'] == baseSetNumber;
    final bool isDrop = (m['isDropSet'] ?? 0) == 1;
    final bool isSameOrder = (m['dropOrder'] ?? 0) == dropOrder;

    // משאירים כל מה שwלא תcאם את הדרוfפסט שאנחנו מוחקים
    return !(isSameExercise && isSameSet && isDrop && isSameOrder);
  }).toList();

  return updated;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
