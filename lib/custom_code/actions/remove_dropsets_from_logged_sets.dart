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

List<dynamic> removeDropsetsFromLoggedSets(
  List<dynamic> loggedSets,
  int exerciseId,
) {
  // --- help4ers ---
  bool _truthy(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  int _getExId(Map m) => _asInt(m['exerciseId'] ?? m['exercise_id']);
  bool _isDrop(Map m) =>
      _truthy(m['isDropSet'] ?? m['is_drop_set'] ?? m['is_drop']);

  // --- fi44l3ter ---
  final updated = loggedSets.where((it) {
    if (it is! Map) return true;

    final sameExercise = _getExId(it) == exerciseId;
    final isDrop = _isDrop(it);

    // להסיר רק דרופסטים ששייכים לאותו תרגיל
    final shouldRemove = sameExercise && isDrop;

    return !shouldRemove;
  }).toList();

  return updated;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
