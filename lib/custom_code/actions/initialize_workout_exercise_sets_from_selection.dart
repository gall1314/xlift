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

List<dynamic> initializeWorkoutExerciseSetsFromSelection(
  List<dynamic>? selectedExercises,
  List<dynamic>? existingExerciseSets,
) {
  // ---------- helpers ----------
  int? toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  int toFlag(dynamic v) {
    if (v is int) return v == 1 ? 1 : 0;
    if (v is bool) return v ? 1 : 0;
    if (v is String) {
      final s = v.toLowerCase();
      return (s == '1' || s == 'true') ? 1 : 0;
    }
    return 0;
  }

  String? cleanName(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  // Robust exercise id extraction: exerciseId / exercise_id, int or string.
  int? extractId(Map m) => toInt(m['exerciseId'] ?? m['exercise_id']);

  // Name from any of the conventions used across the app.
  String? extractName(Map m) =>
      cleanName(m['exerciseName'] ?? m['exercise_name'] ?? m['name']);

  final selectedList = (selectedExercises ?? []).whereType<Map>().toList();

  final selectedIds =
      selectedList.map((e) => extractId(e)).whereType<int>().toSet();

  // id -> name from the selection (used to backfill existing items).
  final Map<int, String> selectedNames = {};
  for (final e in selectedList) {
    final id = extractId(e);
    final n = extractName(e);
    if (id != null && n != null) selectedNames[id] = n;
  }

  // Step 1: keep only exercises that are still selected.
  final List<Map<String, dynamic>> result = (existingExerciseSets ?? [])
      .whereType<Map>()
      .where((e) => selectedIds.contains(extractId(e)))
      .map((e) {
    final m = Map<String, dynamic>.from(e);
    if (m['sets'] is List) {
      m['sets'] = (m['sets'] as List)
          .whereType<Map>()
          .map((s) => Map<String, dynamic>.from(s))
          .toList();
    }
    // Backfill exerciseName on items created before the field existed.
    if (extractName(m) == null) {
      final id = extractId(m);
      if (id != null && selectedNames[id] != null) {
        m['exerciseName'] = selectedNames[id];
      }
    }
    return m;
  }).toList();

  // Step 1.5: clean orphaned supersets (partner was removed).
  final groupCount = <String, int>{};
  for (final e in result) {
    if (e['isSuperset'] == true || toFlag(e['isSuperset']) == 1) {
      final g = (e['supersetGroupId'] ?? 'default').toString();
      groupCount[g] = (groupCount[g] ?? 0) + 1;
    }
  }
  for (final e in result) {
    if (e['isSuperset'] == true || toFlag(e['isSuperset']) == 1) {
      final g = (e['supersetGroupId'] ?? 'default').toString();
      if ((groupCount[g] ?? 0) < 2) {
        e['isSuperset'] = false;
        e.remove('supersetSeq');
        e.remove('supersetGroupId');
      }
    }
  }

  final existingIds = result.map((e) => extractId(e)).whereType<int>().toSet();

  // Step 2: add only new exercises (at the end).
  for (final ex in selectedList) {
    final int? exerciseId = extractId(ex);
    if (exerciseId == null) continue;
    if (existingIds.contains(exerciseId)) continue;

    final int isBodyweight = toFlag(ex['isBodyweight'] ?? ex['is_bodyweight']);
    final int weighted = isBodyweight == 1 ? 0 : 1;

    result.add({
      'exerciseId': exerciseId,
      'exerciseName': extractName(ex),
      'isAssisted': toFlag(ex['isAssisted'] ?? ex['is_assisted']),
      'isPublic': toFlag(ex['isPublic'] ?? ex['is_public']),
      'restSeconds': 0,
      'sets': [
        {
          'setNumber': 1,
          'timerMode': 1,
          'weighted': weighted,
          'showWeightField': weighted,
          'isChecked': false,
        }
      ],
    });
  }

  return result;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
