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

/// Rebuilds the rest-times map from the picker's result.
///
/// [selectedExercises] is the list ExercisePickerView hands to onConfirm
/// (maps with exerciseId); plain ints and JSON strings are accepted too.
/// Existing rest times are kept, new exercises start at 0, dropped
/// exercises are removed.
dynamic syncExerciseRestTimesWithSelectedIds(
  dynamic existingRestTimes,
  List<dynamic> selectedExercises,
) {
  int idOf(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is Map) return idOf(v['exerciseId'] ?? v['exercise_id']);
    if (v is String) {
      final n = int.tryParse(v.trim());
      if (n != null) return n;
      try {
        final m = jsonDecode(v);
        if (m is Map) return idOf(m['exerciseId'] ?? m['exercise_id']);
      } catch (_) {}
      return 0;
    }
    try {
      final m = (v as dynamic).toMap();
      if (m is Map) return idOf(m['exerciseId'] ?? m['exercise_id']);
    } catch (_) {}
    try {
      return idOf((v as dynamic).exerciseId);
    } catch (_) {}
    return 0;
  }

  // Existing map may arrive as Map<String,int>, Map<String,dynamic> or a
  // JSON string — normalize to Map<String,int>.
  final Map<String, int> current = {};
  dynamic src = existingRestTimes;
  if (src is String) {
    try {
      src = jsonDecode(src);
    } catch (_) {
      src = null;
    }
  }
  if (src is Map) {
    src.forEach((k, v) {
      final secs = v is int ? v : (v is num ? v.toInt() : int.tryParse('$v'));
      if (secs != null) current['$k'] = secs;
    });
  }

  final Map<String, int> result = {};

  for (final picked in selectedExercises) {
    final exerciseId = idOf(picked);
    if (exerciseId <= 0) continue;
    final key = exerciseId.toString();
    result[key] = current[key] ?? 0;
  }

  return result;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
