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

List<dynamic> updateLoggedSetForCreationV4(
  List<dynamic> flatSets,
  int exerciseId,
  int setNumber,
  int isDropSet, // 0 = רגיל, 1 = דרופסט
  int? dropNumber, // חובקרג4ה רק אם isD4ropכS4et = 1
  int? targetReps,
  int? durationSeconds,
) {
  // ---- deep copy ----
  final updated =
      flatSets.map((e) => Map<String, dynamic>.from(e as Map)).toList();

  // ---- CAST ----
  int? fixInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  final reps = fixInt(targetReps);
  final duration = fixInt(durationSeconds);

  // ---- locate row ----
  int idx;

  if (isDropSet == 0) {
    // סט רגיל
    idx = updated.indexWhere(
      (s) =>
          s['exerciseId'] == exerciseId &&
          s['setNumber'] == setNumber &&
          (s['isDropSet'] == null || s['isDropSet'] == 0),
    );
  } else {
    // דרופסט
    idx = updated.indexWhere(
      (s) =>
          s['exerciseId'] == exerciseId &&
          s['setNumber'] == setNumber &&
          s['isDropSet'] == 1 &&
          s['dropNumber'] == dropNumber,
    );
  }

  // ---- row update ----
  final Map<String, dynamic> rowUpdate = {
    'exerciseId': exerciseId,
    'setNumber': setNumber,
    'isDropSet': isDropSet,
  };

  if (isDropSet == 1 && dropNumber != null) {
    rowUpdate['dropNumber'] = dropNumber;
  }

  if (reps != null) {
    rowUpdate['targetReps'] = reps;
  }

  if (duration != null) {
    rowUpdate['durationSeconds'] = duration;
  }

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
