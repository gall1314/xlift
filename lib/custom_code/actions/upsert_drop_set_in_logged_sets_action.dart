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

Future<List<dynamic>> upsertDropSetInLoggedSetsAction(
  List<dynamic> loggedSets,
  int exerciseId,
  int baseSetNumber,
  int dropOrder,
  String dropLabel,
  int? reps,
  double? weight,
) async {
  // ---------- helpers ----------
  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  double? _asDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  // ---------- work on mutable copy ----------
  final List<Map<String, dynamic>> updated =
      loggedSets.map((e) => Map<String, dynamic>.from(e as Map)).toList();

  // ---------- normalize isDropSet ----------
  for (final r in updated) {
    final v = r['isDropSet'];
    r['isDropSet'] = (v is num) ? v.toInt() : (v == true ? 1 : 0);
  }

  // ---------- try find existing drop set ----------
  final Map<String, dynamic> existing = updated.firstWhere(
    (r) =>
        (r['exerciseId'] as num?)?.toInt() == exerciseId &&
        (r['setNumber'] as num?)?.toInt() == baseSetNumber &&
        ((r['isDropSet'] as int?) ?? 0) == 1 &&
        _asInt(r['dropOrder']) == dropOrder,
    orElse: () => <String, dynamic>{},
  );

  final double? w = _asDoubleOrNull(weight);

  // ===============================
  // ✏️ UPDATE existing drop set
  // ===============================
  if (existing.isNotEmpty) {
    existing['reps'] = reps;
    existing['weight'] = w;
    return List<dynamic>.from(updated);
  }

  // ===============================
  // ➕ INSERT new drop set
  // ===============================
  updated.add({
    'exerciseId': exerciseId,
    'setNumber': baseSetNumber,
    'reps': reps,
    'weight': w,
    'durationMs': null,
    'isDone': false,
    'isDropSet': 1,
    'dropLabel': dropLabel,
    'dropOrder': dropOrder,
  });

  return List<dynamic>.from(updated);
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
