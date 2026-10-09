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

import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';

List<dynamic> updateFlatSetValue(
  List<dynamic> flatSets,
  int exerciseId,
  int setNumber,
  int? reps,
  double? weight,
  int? durationSeconds,
  bool? isDone,
  List<dynamic> exerciseSets,
) {
  // ---- deep copy ----
  final updatedLoggedSets = List<Map<String, dynamic>>.from(
    flatSets.map((e) => Map<String, dynamic>.from(e as Map)),
  );

  // ---------- helpers ----------
  bool toBoolFromInt(dynamic v) {
    if (v is int) return v == 1;
    if (v is bool) return v;
    return true;
  }

  // ---------- get weighted from template ----------
  bool getWeightedFromTemplate(int sn) {
    final exerciseDyn = exerciseSets.firstWhere(
      (e) =>
          e is Map &&
          e['exerciseId'] == exerciseId &&
          e['sets'] is List &&
          (e['sets'] as List).any(
            (s) => s is Map && s['setNumber'] == sn,
          ),
      orElse: () => null,
    );
    if (exerciseDyn == null) return true;

    final setsList = (exerciseDyn['sets'] as List)
        .where((s) => s is Map && s['setNumber'] == sn)
        .cast<Map>()
        .toList();

    if (setsList.isEmpty) return true;

    return toBoolFromInt(setsList.first['weighted']);
  }

  // ---------- find existing entry for the target set ----------
  final idx = updatedLoggedSets.indexWhere(
    (s) => s['exerciseId'] == exerciseId && s['setNumber'] == setNumber,
  );
  final existingTarget = idx >= 0 ? updatedLoggedSets[idx] : null;

  final targetWeighted = getWeightedFromTemplate(setNumber);

  // ---------- build the new/updated entry ----------
  // Only update fields that were explicitly passed in.
  // Fields that are null in the params keep their existing value.
  final newTarget = <String, dynamic>{
    'exerciseId': exerciseId,
    'setNumber': setNumber,
    'isDone': isDone ?? (existingTarget?['isDone'] as bool? ?? false),
    'weighted': targetWeighted,
    'reps': reps ?? existingTarget?['reps'],
    'weight': targetWeighted
        ? (weight ?? (existingTarget?['weight'] as num?)?.toDouble())
        : null,
    'durationMs':
        durationSeconds ?? (existingTarget?['durationMs'] as int?) ?? 0,
  };

  // ---------- write back ----------
  if (idx >= 0) {
    updatedLoggedSets[idx] = {...updatedLoggedSets[idx], ...newTarget};
  } else {
    updatedLoggedSets.add(newTarget);
  }

  return updatedLoggedSets;
}
