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

Future<List<dynamic>> buildExerciseSetsForEdit(
  BuildContext context,
  List<ExercisesForEditRow> exercisesForEditRows,
  List<GetAllSetsRow> flatSetRows,
) async {
  // ---------- helpers ----------
  Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map) {
      try {
        return Map<String, dynamic>.from(v);
      } catch (_) {}
    }
    return null;
  }

  List<dynamic> _asList(dynamic v) {
    if (v is List) return v;
    if (v is String && v.trim().isNotEmpty) {
      try {
        final d = jsonDecode(v);
        return d is List ? d : const [];
      } catch (_) {}
    }
    return const [];
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is num) return v.toInt();
    return 0;
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  bool _toBool01(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }

  String? _cleanName(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  // ---------- 1) קריאת exercises מהקוורי החדש ----------
  List<dynamic> exercisesJson = const [];
  for (final row in exercisesForEditRows) {
    final m = Map<String, dynamic>.from(row.data);
    if (m.containsKey('exercises')) {
      exercisesJson = _asList(m['exercises']);
      break;
    }
  }

  // ---------- 2) ids + names מהחדש ----------
  final exerciseIdsNew = <int>{};
  final namesById = <int, String>{};
  for (final ex in exercisesJson) {
    final em = _asMap(ex) ?? {};
    final exId = _toInt(em['exerciseId']);
    if (exId != 0) {
      exerciseIdsNew.add(exId);
      final n =
          _cleanName(em['exerciseName'] ?? em['name'] ?? em['exercise_name']);
      if (n != null) namesById[exId] = n;
    }
  }

  // ---------- 3) קיבוץ מהקוורי הישן (ללא דרופסטים) ----------
  final grouped = <int, List<Map<String, dynamic>>>{};

  for (final row in flatSetRows) {
    final m = Map<String, dynamic>.from(row.data);

    // ❗ סינון דרופסטים
    if (_toBool01(m['is_dropset']) || _toBool01(m['isDropSet'])) {
      continue;
    }

    final exId = _toInt(m['exercise_id'] ?? m['exerciseId'] ?? m['id']);
    if (exId == 0) continue;

    // שם מהקוורי הישן, אם קיים ועוד לא נמצא בחדש
    if (!namesById.containsKey(exId)) {
      final n =
          _cleanName(m['exercise_name'] ?? m['exerciseName'] ?? m['name']);
      if (n != null) namesById[exId] = n;
    }

    final setNo = _toInt(m['set_number']);
    final weight = _toDouble(m['weight']);
    final weighted = weight > 0;

    grouped.putIfAbsent(exId, () => []).add({
      'setNumber': setNo,
      'weighted': weighted,
    });
  }

  // ---------- 4) איחוד ids ----------
  final allIds = <int>{...exerciseIdsNew, ...grouped.keys}.toList()..sort();
  final result = <Map<String, dynamic>>[];

  // ---------- 5) בניית exerciseSets ----------
  for (final exId in allIds) {
    List<Map<String, dynamic>> sets = [];
    bool isAssisted = false;

    // ---------- עדיפות לנתונים מהקוורי החדש ----------
    final fromNew = exercisesJson.firstWhere(
      (e) => _toInt(_asMap(e)?['exerciseId']) == exId,
      orElse: () => null,
    );

    if (fromNew != null) {
      final fromNewMap = _asMap(fromNew) ?? {};
      isAssisted = _toBool01(fromNewMap['isAssisted']);

      final setsJson = _asList(fromNewMap['sets']);

      // ❗ סינון דרופסטים גם כאן
      final baseSets = setsJson.where((s) {
        final sm = _asMap(s);
        if (sm == null) return false;
        return !_toBool01(sm['isDropset']) && !_toBool01(sm['is_dropset']);
      }).toList();

      sets = [
        for (var i = 0; i < baseSets.length; i++)
          {
            'setNumber': (_toInt(_asMap(baseSets[i])?['setNumber']) == 0)
                ? (i + 1)
                : _toInt(_asMap(baseSets[i])?['setNumber']),
            'weighted': _toBool01(_asMap(baseSets[i])?['weighted']),
          }
      ];
    }

    // ---------- fallback לקוורי הישן ----------
    if (sets.isEmpty && grouped.containsKey(exId)) {
      sets = List<Map<String, dynamic>>.from(grouped[exId]!);
    }

    // ---------- רה־אינדוקס סופי ----------
    sets.sort(
      (a, b) => _toInt(a['setNumber']).compareTo(_toInt(b['setNumber'])),
    );

    for (var i = 0; i < sets.length; i++) {
      sets[i]['setNumber'] = i + 1;
      sets[i]['weighted'] = _toBool01(sets[i]['weighted']);
    }

    result.add({
      'exerciseId': exId,
      'exerciseName': namesById[exId],
      'isAssisted': isAssisted,
      'sets': sets,
    });
  }

  return result;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
