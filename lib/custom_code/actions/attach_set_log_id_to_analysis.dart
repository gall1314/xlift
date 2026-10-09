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

Future<List<dynamic>> attachSetLogIdToAnalysis(
  List<dynamic>? analysisList,
  int exerciseId,
  int setNumber,
  String setLogId,
) async {
  final list = List<dynamic>.from(analysisList ?? []);

  final exIndex =
      list.indexWhere((e) => e is Map && e['exerciseId'] == exerciseId);
  if (exIndex == -1) return list; // No analysis for this exercise.

  final exercise = Map<String, dynamic>.from(list[exIndex]);
  final sets = List<dynamic>.from(exercise['sets'] ?? []);

  final setIndex =
      sets.indexWhere((s) => s is Map && s['setNumber'] == setNumber);
  if (setIndex == -1) return list; // No analysis for this set.

  final updatedSet = Map<String, dynamic>.from(sets[setIndex]);

  // Only attach to sets that actually completed an analysis.
  if (updatedSet['analysisDone'] != true) return list;

  updatedSet['setLogId'] = setLogId;
  sets[setIndex] = updatedSet;
  exercise['sets'] = sets;
  list[exIndex] = exercise;

  return list;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
