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

List<dynamic> markExerciseCompleted(
  List<dynamic> exerciseSets,
  List<dynamic> loggedSets,
  int exerciseId,
) {
  // עותק כתיבה
  final updated = List<Map<String, dynamic>>.from(
    loggedSets.map((e) => Map<String, dynamic>.from(e as Map)),
  );

  // ---------- helpers ----------
  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final t = v.toLowerCase();
      return t == 'true' || t == '1';
    }
    return false;
  }

  int _setNo(Map m) => _toInt(m['setNumber'] ?? m['set_number']);

  // כל הסטים של התרגיל (מהמצב המעודכן)
  List<Map<String, dynamic>> _allForExercise() => updated
      .where((s) => _toInt(s['exerciseId'] ?? s['exercise_id']) == exerciseId)
      .map((s) => Map<String, dynamic>.from(s))
      .toList();

  // סט נחשב "מאוכלס" (מקור תקין להורשה)
  bool _isPopulated(Map s) {
    final reps = _toInt(s['reps']);
    final dur = _toInt(s['durationMs'] ?? s['duration_ms'] ?? s['duration']);
    final allowW =
        (s['weighted'] as bool?) ?? (s['showWeightField'] as bool?) ?? true;
    final w = _toDouble(s['weight']) ?? 0.0;
    return reps > 0 || dur > 0 || (allowW && w > 0);
  }

  // מקור אחרון מאוכלס *לפני* סט נתון (אחרי עדכונים קודמים בלופ)
  Map<String, dynamic>? _lastNonEmptyBefore(int upToSet) {
    final list = _allForExercise()
      ..retainWhere((s) => _setNo(s) > 0 && _setNo(s) < upToSet)
      ..sort((a, b) => _setNo(b).compareTo(_setNo(a))); // יורד
    for (final s in list) {
      if (_isPopulated(s)) return s;
    }
    return null;
  }

  // ---------- שהולף תבנית לתרגיל ----------
  final tpl = exerciseSets.firstWhere(
    (e) => e is Map && e['exerciseId'] == exerciseId && e['sets'] is List,
    orElse: () => null,
  ) as Map<String, dynamic>?;

  if (tpl == null) return updated;

  // בניית מפת הרשאות משקל מהתבנית: setNumber -> weighted
  final allowBySet = <int, bool>{};
  final setsTpl = (tpl['sets'] as List)
      .whereType<Map>()
      .map((s) => {
            'setNumber': _toInt(s['setNumber'] ?? s['set_number']),
            'weighted': _toBool(s['weighted'] ?? s['showWeightField']),
          })
      .where((s) => (s['setNumber'] as int) > 0)
      .toList()
    ..sort((a, b) => (a['setNumber'] as int).compareTo(b['setNumber'] as int));

  for (final s in setsTpl) {
    allowBySet[s['setNumber'] as int] = s['weighted'] as bool;
  }

  // ---------- עיבוד סט-סט (סדר עולה), הורשה זהה לפלאט, עם חסימת weight כשאסור ----------
  for (final s in setsTpl) {
    final sn = s['setNumber'] as int;
    final allow = s['weighted'] as bool;

    // מצב קיים (אם יש)
    final idx = updated.indexWhere(
      (m) =>
          _toInt(m['exerciseId'] ?? m['exercise_id']) == exerciseId &&
          _setNo(m) == sn,
    );
    final curr = idx >= 0 ? Map<String, dynamic>.from(updated[idx]) : null;

    // מקור אחרון מלא *לפני* הסט הזה
    final src = _lastNonEmptyBefore(sn);

    // פתרון ערכים:
    // reps: קיים>0 -> מקור>0 -> null
    final int? reps = (() {
      final c = _toInt(curr?['reps']);
      final p = _toInt(src?['reps']);
      if (c > 0) return c;
      if (p > 0) return p;
      return null;
    })();

    // durationMs: קיים>0 -> מקור>0 -> 0
    final int durationMs = (() {
      final c = _toInt(
          curr?['durationMs'] ?? curr?['duration_ms'] ?? curr?['duration']);
      final p =
          _toInt(src?['durationMs'] ?? src?['duration_ms'] ?? src?['duration']);
      if (c > 0) return c;
      if (p > 0) return p;
      return 0;
    })();

    // weight: רק אם allow==true, ואז קיים>0 -> מקור>0 -> null
    final double? weight = (() {
      if (!allow) return null;
      final c = _toDouble(curr?['weight']);
      if (c != null && c > 0) return c;
      final p = _toDouble(src?['weight']);
      if (p != null && p > 0) return p;
      return null;
    })();

    final next = <String, dynamic>{
      'exerciseId': exerciseId,
      'setNumber': sn,
      'isDone': true,
      'weighted': allow,
      // תאימות לאחור אם יש צרכנים ישנים
      'showWeightField': allow,
      if (reps != null) 'reps': reps,
      'durationMs': durationMs,
      if (allow && weight != null) 'weight': weight,
    };

    if (idx >= 0) {
      final merged = {...updated[idx], ...next};
      if (!allow) merged.remove('weight'); // חותך דליפה
      updated[idx] = merged;
    } else {
      final toAdd = Map<String, dynamic>.from(next);
      if (!allow) toAdd.remove('weight');
      updated.add(toAdd);
    }
  }

  // ---------- אכיפה סופית: אין weight כשלא weighted ----------f
  for (var i = 0; i < updated.length; i++) {
    final m = updated[i];
    if (_toInt(m['exerciseId'] ?? m['exercise_id']) != exerciseId) continue;
    final sn = _setNo(m);
    final allow = allowBySet[sn] ?? false; // חסר בתבנית ⇒ falseg
    m['weighted'] = allow;
    m['showWeightField'] = allow; // תאימות לאחור
    if (!allow) m.remove('weight');
  }

  return updated;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
