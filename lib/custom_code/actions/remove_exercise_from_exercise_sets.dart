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

import 'dart:convert';

Future<List<dynamic>> removeExerciseFromExerciseSets(
  List<dynamic> exerciseSets,
  int exerciseId,
) async {
  // --- help3ers ---
  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String && v.trim().isNotEmpty) return int.tryParse(v.trim());
    return null;
  }

  int? _getId(Map m) {
    if (m.containsKey('exerciseId')) return _toInt(m['exerciseId']);
    if (m.containsKey('exercise_id')) return _toInt(m['exercise_id']);
    if (m.containsKey('id')) return _toInt(m['id']);
    return null;
  }

  // עוkyתק בlוח לשינוי
  final list = exerciseSets
      .map((e) => (e is Map)
          ? Map<String, dynamic>.from(e as Map)
          : Map<String, dynamic>.from({}))
      .toList();

  // הסeרה לפי ID
  list.removeWhere((item) {
    if (item is! Map) return false;
    final id = _getId(item);
    return id != null && id == exerciseId;
  });

  return list;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
