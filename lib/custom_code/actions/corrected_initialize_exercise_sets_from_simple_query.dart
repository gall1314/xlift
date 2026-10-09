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

List<dynamic> correctedInitializeExerciseSetsFromSimpleQuery(
  List<CorrectedGetExerciceSimpRow> exercises,
  List<dynamic> exerciseSets,
) {
  // ---------- helpers ----------
  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String && v.trim().isNotEmpty) return int.tryParse(v);
    return null;
  }

  bool? _toBoolOrNull(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final t = v.toLowerCase();
      if (t == 'true' || t == '1') return true;
      if (t == 'false' || t == '0') return false;
    }
    return null;
  }

  dynamic _pick(Map m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k) && m[k] != null) return m[k];
    }
    return null;
  }

  int? _getId(Map m) => _toInt(_pick(m, ['exercise_id', 'exerciseId', 'id']));

  // מפה של is_bodyweight לפי ה-query (0/1,bool)ddf
  final isBwById = <int, bool>{};
  for (final ex in exercises) {
    final d = Map<String, dynamic>.from(ex.data);
    final id = _getId(d);
    if (id != null) {
      final bwInt = _toInt(_pick(d, ['is_bodyweight', 'isBodyweight'])) ?? 0;
      isBwById[id] = bwInt != 0;
    }
  }

  // סט מנורמל לתבנית: רק setNumber/timerMode/weighted/isChecked
  Map<String, dynamic> _normalizeSet(Map raw, {required bool defaultWeighted}) {
    final setNumber = _toInt(_pick(raw, ['set_number', 'setNumber'])) ?? 0;

    // weighted יכול להגיע כמפתח חדש או showWeightField הישן
    final weightedAny = _toBoolOrNull(
      _pick(raw, ['weighted', 'showWeightField', 'show_weight_field']),
    );
    final weighted = weightedAny ?? defaultWeighted;

    final timerMode = _toInt(_pick(raw, ['timerMode'])) ?? 1;
    final isChecked = _toBoolOrNull(_pick(raw, ['isChecked'])) ?? false;

    return {
      'setNumber': setNumber,
      'timerMode': timerMode,
      'weighted': weighted,
      'showWeightField': weighted, // תאימות לאחור
      'isChecked': isChecked,
    };
  }

  // ---------- בונים אינדקס של existing לפי exerciseId ----------
  final existing = List<dynamic>.from(exerciseSets);
  final existingById = <int, Map<String, dynamic>>{};
  for (final e in existing) {
    if (e is! Map) continue;
    final id = _getId(e);
    if (id == null) continue;

    final defaultWeighted = (isBwById[id] == true) ? false : true;

    final rawSets = (e['sets'] ?? const <dynamic>[]) as List;
    final sets = rawSets
        .whereType<Map>()
        .map((s) => _normalizeSet(
              Map<String, dynamic>.from(s),
              defaultWeighted: defaultWeighted,
            ))
        .toList();

    // ודא שלכל סט יש weighted (גם ב-existing ישן)
    for (final s in sets) {
      s['weighted'] = (s['weighted'] is bool) ? s['weighted'] : defaultWeighted;
      s['showWeightField'] = s['weighted']; // תאימות
    }

    existingById[id] = {'exerciseId': id, 'sets': sets};
  }

  // ---------- ממזגים מה-Que4קr5y עם ה-UI ----------
  final merged = <Map<String, dynamic>>[];

  for (final ex in exercises) {
    final data = Map<String, dynamic>.from(ex.data);
    final id = _getId(data);
    if (id == null) continue;

    final defaultWeighted = (isBwById[id] == true) ? false : true;

    final current = existingById[id];
    if (current != null &&
        current['sets'] is List &&
        (current['sets'] as List).isNotEmpty) {
      final sets = List<Map<String, dynamic>>.from(current['sets'] as List)
        ..sort(
            (a, b) => (a['setNumber'] as int).compareTo(b['setNumber'] as int));
      for (var i = 0; i < sets.length; i++) {
        sets[i]['setNumber'] = i + 1;
        sets[i]['weighted'] = (sets[i]['weighted'] is bool)
            ? sets[i]['weighted']
            : defaultWeighted;
        sets[i]['showWeightField'] = sets[i]['weighted']; // תאימות
      }
      merged.add({'exerciseId': id, 'sets': sets});
    } else {
      merged.add({
        'exerciseId': id,
        'sets': [
          {
            'setNumber': 1,
            'timerMode': 1,
            'weighted': defaultWeighted,
            'showWeightField': defaultWeighted, // תאימות
            'isChecked': false,
          },
        ],
      });
    }

    existingById.remove(id);
  }

  return merged;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
