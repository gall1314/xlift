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

List<dynamic> addSetToExercise(
  List<dynamic> exerciseSets,
  int exerciseId,
  bool isBodyweight, // קובע ברירת מחדל ל-weighted
) {
  // ---------- clone בטוח ----------
  final updated =
      exerciseSets.map((e) => Map<String, dynamic>.from(e as Map)).toList();

  // ---------- locate exercise ----------
  final exIdx = updated.indexWhere((ex) {
    final id = ex['exerciseId'] ?? ex['exercise_id'];
    return id == exerciseId;
  });
  if (exIdx < 0) return updated;

  // ---------- clone sets ----------
  final rawSets = (updated[exIdx]['sets'] is List)
      ? (updated[exIdx]['sets'] as List)
      : const <dynamic>[];

  final sets = rawSets.map((s) => Map<String, dynamic>.from(s as Map)).toList();

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  // ---------- calculate next setNumber ----------
  final maxSetNo = sets.isEmpty
      ? 0
      : sets
          .map((s) => _toInt(s['setNumber'] ?? s['set_number']))
          .fold<int>(0, (a, b) => a > b ? a : b);

  final newSetNumber = maxSetNo + 1;

  // ---------- weighted כ-INT בלבד ----------
  final int weightedForNew = isBodyweight ? 0 : 1;

  // ---------- add new set (✅ סימטרי לאינישיאל) ----------
  sets.add({
    'setNumber': newSetNumber,
    'timerMode': 1,
    'durationSeconds': null, // 🔥 קריטי
    'weighted': weightedForNew,
    'showWeightField': weightedForNew == 1,
    'targetReps': null,
    'isChecked': false,
  });

  // ---------- write back ----------
  updated[exIdx] = {
    ...updated[exIdx],
    'sets': sets,
  };

  return updated;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
