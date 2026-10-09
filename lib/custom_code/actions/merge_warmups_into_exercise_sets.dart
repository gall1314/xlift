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

/// Injects warmup sets from the warmup app state into the nested
/// exerciseSets structure, marked with isWarmup: 1.
/// Working sets get isWarmup: 0. Warmups are placed before them.
Future<List<dynamic>> mergeWarmupsIntoExerciseSets(
  List<dynamic> exerciseSets,
  List<dynamic>? warmupList,
) async {
  final result = <Map<String, dynamic>>[];

  for (final raw in exerciseSets) {
    final ex = Map<String, dynamic>.from(raw as Map);
    final exerciseId = ex['exerciseId'];

    // Existing working sets - ensure isWarmup: 0.
    final workingSets = (ex['sets'] as List? ?? [])
        .map((s) => {
              ...Map<String, dynamic>.from(s as Map),
              'isWarmup': 0,
            })
        .toList();

    // Find this exercise's warmups (skip hidden blocks).
    final warmupSets = <Map<String, dynamic>>[];
    if (warmupList != null) {
      for (final w in warmupList) {
        if (w is! Map) continue;
        if (w['exerciseId'] != exerciseId) continue;
        if (w['hidden'] == true) continue;

        final sets = w['sets'];
        if (sets is! List) break;

        for (final s in sets) {
          if (s is! Map) continue;
          warmupSets.add({
            ...Map<String, dynamic>.from(s),
            'isWarmup': 1,
            'workoutExerciseId': ex['workoutExerciseId'],
          });
        }
        break;
      }
    }

    ex['sets'] = [...warmupSets, ...workingSets];
    result.add(ex);
  }

  return result;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
