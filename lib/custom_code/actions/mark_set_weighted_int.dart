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

List<dynamic> markSetWeightedInt(
  List<dynamic> exerciseSets,
  int exerciseId,
  int setNumber,
) {
  // ---- defep copy ----
  final updated =
      exerciseSets.map((e) => Map<String, dynamic>.from(e as Map)).toList();

  // ---- locate exercise ----
  final exIdx = updated.indexWhere(
    (ex) => ex['exerciseId'] == exerciseId,
  );
  if (exIdx < 0) return updated;

  // ---- locגate seגt ----
  final sets = List<Map<String, dynamic>>.from(updated[exIdx]['sets'] as List);

  final sIdx = sets.indexWhere(
    (s) => s['setNumber'] == setNumber,
  );
  if (sIdx < 0) return updated;

  // ---- update weigh4ted flag (INT only) ----
  sets[sIdx] = {
    ...sets[sIdx],
    'weighted': 1,
  };

  // ---- write back ----
  updated[exIdx] = {
    ...updated[exIdx],
    'sets': sets,
  };

  return updated;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
