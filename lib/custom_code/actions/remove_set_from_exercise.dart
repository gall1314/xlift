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

/// Removes set [setNumberToRemove] of exercise [exerciseId] from the
/// exerciseSets structure and renumbers the remaining sets 1..N.
/// Call removeSetFromLoggedSets with the SAME (exerciseId, setNumber) on
/// loggedSets and on workoutAnalysisState so all three stay aligned.
List<dynamic> removeSetFromExercise(
  List<dynamic> exerciseSets,
  int exerciseId,
  int setNumberToRemove,
) {
  int? toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  final updated = exerciseSets
      .whereType<Map>()
      .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
      .toList();

  for (final ex in updated) {
    final exId = toInt(ex['exerciseId']) ??
        toInt(ex['exerciseID']) ??
        toInt(ex['exercise_id']) ??
        toInt(ex['exercisesId']);
    if (exId != exerciseId) continue;

    final sets = (ex['sets'] is List)
        ? (ex['sets'] as List)
            .whereType<Map>()
            .map<Map<String, dynamic>>((s) => Map<String, dynamic>.from(s))
            .toList()
        : <Map<String, dynamic>>[];

    if (sets.length <= 1) {
      print('removeSetFromExercise: exId=$exId has ${sets.length} set(s), '
          'not removing');
      return updated;
    }

    final String setKey =
        sets.first.containsKey('set_number') ? 'set_number' : 'setNumber';

    sets.sort(
        (a, b) => (toInt(a[setKey]) ?? 0).compareTo(toInt(b[setKey]) ?? 0));

    final int idx =
        sets.indexWhere((s) => toInt(s[setKey]) == setNumberToRemove);
    if (idx == -1) {
      print('removeSetFromExercise: set $setNumberToRemove not found in '
          '${sets.map((s) => toInt(s[setKey])).toList()}');
      return updated;
    }

    sets.removeAt(idx);
    for (var i = 0; i < sets.length; i++) {
      sets[i][setKey] = i + 1;
    }
    ex['sets'] = sets;

    print('removeSetFromExercise: exId=$exId removed set $setNumberToRemove, '
        'now ${sets.length} sets');
    return updated;
  }

  print('removeSetFromExercise: exerciseId=$exerciseId not found');
  return updated;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
