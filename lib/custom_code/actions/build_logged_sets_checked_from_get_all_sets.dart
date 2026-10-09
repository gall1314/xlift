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

List<dynamic> buildLoggedSetsCheckedFromGetAllSets(
  List<GetAllSetsRow> allSets,
) {
  // ---------- helpers ----------
  int? _toInt(dynamic v) =>
      v == null ? null : (v is num ? v.toInt() : int.tryParse('$v'));

  double? _toDouble(dynamic v) =>
      v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));

  int? _getId(Map m) => _toInt(m['exercise_id'] ?? m['exerciseId'] ?? m['id']);

  // ---------- normalize one set row ----------
  Map<String, dynamic> _normalizeSetFlat(Map raw, int exerciseId) {
    final reps = _toInt(raw['reps']);
    final weight = _toDouble(raw['weight']);
    final durSec = _toInt(raw['duration_seconds']); // נשאר כמו שאהוא
    final isKg = _toInt(raw['is_kg']) ?? 1;

    return {
      'exerciseId': exerciseId,
      'setNumber': _toInt(raw['set_number']) ?? 0,
      'reps': reps,
      'weight': weight,
      'durationMs': durSec, // ❌ אין המרה, ❌ אין *1000
      'isKg': isKg,
      'isDone': true,
    };
  }

  final byExercise = <int, List<Map<String, dynamic>>>{};

  for (final row in allSets) {
    final m = Map<String, dynamic>.from(row.data);
    final exId = _getId(m);
    if (exId == null) continue;
    byExercise.putIfAbsent(exId, () => []).add(_normalizeSetFlat(m, exId));
  }

  final flat = <Map<String, dynamic>>[];

  byExercise.forEach((exId, sets) {
    sets.sort(
      (a, b) => (a['setNumber'] as int).compareTo(b['setNumber'] as int),
    );

    for (var i = 0; i < sets.length; i++) {
      sets[i]['setNumber'] = i + 1;
      flat.add(sets[i]);
    }
  });

  return flat;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
