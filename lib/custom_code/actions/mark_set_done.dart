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

/// Marks a set done/undone WITHOUT touching its values.
/// reps / weight / durationMs stay exactly as the input widgets
/// committed them into loggedSets. If the set has no entry yet
/// (user tapped the check without ever opening the fields), a
/// minimal entry is created with the template's weighted flag.
List<dynamic> markSetDone(
  List<dynamic> flatSets,
  int exerciseId,
  int setNumber,
  bool isDone,
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

  // ---------- find existing entry ----------
  final idx = updatedLoggedSets.indexWhere(
    (s) => s['exerciseId'] == exerciseId && s['setNumber'] == setNumber,
  );

  if (idx >= 0) {
    // Entry exists - flip isDone ONLY, values untouched.
    updatedLoggedSets[idx] = {
      ...updatedLoggedSets[idx],
      'isDone': isDone,
    };
  } else {
    // No entry yet - create minimal one (values empty, widgets will
    // fill them via their own commits).
    updatedLoggedSets.add({
      'exerciseId': exerciseId,
      'setNumber': setNumber,
      'isDone': isDone,
      'weighted': getWeightedFromTemplate(setNumber),
      'reps': null,
      'weight': null,
      'durationMs': null,
    });
  }

  return updatedLoggedSets;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
