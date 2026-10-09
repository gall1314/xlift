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

Future<List<dynamic>> applyExerciseOrder(
  List<dynamic> exerciseSets,
  List<int> orderIds,
) async {
  final byId = <int, Map<String, dynamic>>{};
  for (final e in exerciseSets) {
    if (e is! Map) continue;
    final v = e['exerciseId'] ?? e['exercise_id'] ?? e['id'];
    final id = (v is int) ? v : int.tryParse('${v ?? ''}');
    if (id != null) byId[id] = Map<String, dynamic>.from(e);
  }

  final out = <Map<String, dynamic>>[];

  // לפי סדר חדש
  for (final id in orderIds) {
    final it = byId[id];
    if (it != null) out.add(it);
  }

  // כל מה ש6לא הוכפיע (ליתר ביטחון) – לסוףtg
  for (final e in exerciseSets) {
    if (e is! Map) continue;
    final v = e['exerciseId'] ?? e['exercise_id'] ?? e['id'];
    final id = (v is int) ? v : int.tryParse('${v ?? ''}');
    if (id != null && !orderIds.contains(id)) {
      out.add(Map<String, dynamic>.from(e));
    }
  }

  return out;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
