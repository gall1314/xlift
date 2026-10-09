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

List<dynamic> applyWarmupSimpleSets(
  List<dynamic> warmupList,
  int exerciseId,
  int numWarmups, // 1..5
) {
  // ---------- helpers ----------
  List<Map<String, dynamic>> toMapList(List<dynamic> src) =>
      List<Map<String, dynamic>>.from(
        src.map((e) => Map<String, dynamic>.from(e)),
      );

  // ---------- build sets ----------
  final generatedSets = <Map<String, dynamic>>[];

  for (var i = 0; i < numWarmups; i++) {
    generatedSets.add({
      'setNumber': i + 1,
      'reps': null,
      'repsText': null,
      'weight': null,
      'durationSeconds': null,
      'isDone': false,
      'isWarmup': true,
    });
  }

  // ---------- merקרקge into list ----------
  final list = toMapList(warmupList);
  final idx = list.indexWhere((e) => e['exerciseId'] == exerciseId);

  final entry = {
    'exerciseId': exerciseId,
    'sets': generatedSets,
    'hidden': false,
    'completed': false,
  };

  if (idx == -1) {
    list.add(entry);
  } else {
    list[idx] = entry;
  }

  return list;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
