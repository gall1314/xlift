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

/// Removes one set's analysis from an analysis state list and returns the
/// new list. Nothing is written to the database: while editing a logged
/// workout the removal only lives in App State, and updateWorkoutComplete
/// deletes the row for real when the workout is saved.
///
/// Set [analysisStateCreation] to the result. An exercise left with no
/// analysed sets is dropped from the list, so the set table stops reserving
/// the analysis column.
///
/// Returns the list unchanged when there is nothing to remove.
List<dynamic> removeAnalysisFromState(
  List<dynamic> analysisState,
  int exerciseId,
  int setNumber,
) {
  int toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v == null ? '' : v.toString()) ?? -1;
  }

  final List<dynamic> out = [];

  for (final entry in analysisState) {
    if (entry is! Map) {
      out.add(entry);
      continue;
    }
    final Map<String, dynamic> ex = Map<String, dynamic>.from(entry);
    if (toInt(ex['exerciseId']) != exerciseId || ex['sets'] is! List) {
      out.add(ex);
      continue;
    }

    final List<dynamic> keptSets = [];
    for (final s in (ex['sets'] as List)) {
      if (s is Map && toInt(s['setNumber']) == setNumber) continue; // the one
      keptSets.add(s);
    }

    // an exercise with nothing analysed left has no reason to stay
    bool anyDone = false;
    for (final s in keptSets) {
      if (s is Map && s['analysisDone'] == true) {
        anyDone = true;
        break;
      }
    }
    if (!anyDone) continue;

    ex['sets'] = keptSets;
    out.add(ex);
  }

  return out;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
