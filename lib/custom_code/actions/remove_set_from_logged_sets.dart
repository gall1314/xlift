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

/// Removes the entry for (exerciseId, setNumber) from a flat list of
/// per-set maps (loggedSets, workoutAnalysisState) and shifts every
/// higher setNumber of the same exercise down by one, mirroring the
/// renumbering done by removeSetFromExercise.
///
/// Works on any list whose items carry exerciseId / setNumber
/// (also accepts exercise_id / set_number / exerciseID). Entries of other
/// exercises are untouched.
List<dynamic> removeSetFromLoggedSets(
  List<dynamic> loggedSets,
  int exerciseId,
  int setNumber,
) {
  int? toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  String? firstKey(Map m, List<String> candidates) {
    for (final k in candidates) {
      if (m.containsKey(k)) return k;
    }
    return null;
  }

  const exKeys = ['exerciseId', 'exerciseID', 'exercise_id', 'exercisesId'];
  const setKeys = ['setNumber', 'set_number'];

  final out = <Map<String, dynamic>>[];
  int removed = 0, shifted = 0;

  for (final raw in loggedSets) {
    if (raw is! Map) continue;
    final m = Map<String, dynamic>.from(raw);

    final exKey = firstKey(m, exKeys);
    final setKey = firstKey(m, setKeys);
    if (exKey == null || setKey == null || toInt(m[exKey]) != exerciseId) {
      out.add(m);
      continue;
    }

    final int? sn = toInt(m[setKey]);
    if (sn == setNumber) {
      removed++;
      continue; // drop it
    }
    if (sn != null && sn > setNumber) {
      m[setKey] = sn - 1;
      shifted++;
    }
    out.add(m);
  }

  print('removeSetFromLoggedSets: exId=$exerciseId set=$setNumber '
      'removed=$removed shifted=$shifted');
  return out;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
