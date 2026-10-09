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

/// Updates a single field ('reps' or 'weight') of one warmup set
/// inside the nested warmup app state, and returns the updated list.
Future<List<dynamic>> updateWarmupSetField(
  List<dynamic>? warmupList,
  int exerciseId,
  int setNumber,
  String field,
  String? newValue,
) async {
  final list = (warmupList ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();

  final exIndex = list.indexWhere((e) => e['exerciseId'] == exerciseId);
  if (exIndex == -1) return list;

  final sets = (list[exIndex]['sets'] as List? ?? [])
      .map((s) => Map<String, dynamic>.from(s as Map))
      .toList();

  final setIndex = sets.indexWhere((s) => s['setNumber'] == setNumber);
  if (setIndex == -1) return list;

  final value = (newValue ?? '').trim();

  if (field == 'reps') {
    // Keep both the display text and the int in sync.
    sets[setIndex]['repsText'] = value;
    sets[setIndex]['reps'] = int.tryParse(value);
  } else if (field == 'weight') {
    sets[setIndex]['weight'] = value;
  }

  list[exIndex]['sets'] = sets;
  return list;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
