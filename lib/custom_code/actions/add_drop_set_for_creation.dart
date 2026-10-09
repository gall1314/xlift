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

List<dynamic> addDropSetForCreation(
  List<dynamic> flatSets,
  int exerciseId,
  int setNumber,
  int dropNumber, // ← נוסכeיף חובה!
  int? targetReps,
  double? targetWeight,
  int? weighted,
) {
  // ---- deep copy ----
  final updated =
      flatSets.map((e) => Map<String, dynamic>.from(e as Map)).toList();

  int? fixReps(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  double? fixWeight(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }

  final reps = fixReps(targetReps);
  final weight = fixWeight(targetWeight);

  // ---- locate the correct DROP row ----
  final idx = updated.indexWhere(
    (s) =>
        s['exerciseId'] == exerciseId &&
        s['setNumber'] == setNumber &&
        s['isDropSet'] == 1 &&
        s['dropNumber'] == dropNumber,
  );

  // ---- build row update ----
  final Map<String, dynamic> rowUpdate = {
    'exerciseId': exerciseId,
    'setNumber': setNumber,
    'dropNumber': dropNumber,
    'isDropSet': 1,
  };

  if (reps != null) rowUpdate['targetReps'] = reps;
  if (weight != null) rowUpdate['targetWeight'] = weight;
  if (weighted != null) rowUpdate['weighted'] = weighted;

  // ---- merge ----
  if (idx >= 0) {
    updated[idx] = {
      ...updated[idx],
      ...rowUpdate,
    };
  } else {
    updated.add(rowUpdate);
  }

  return updated;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
