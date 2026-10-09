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

// Return: JSON (isList=true)
// Return: JSON (isList=true)
// Return: JSON (isList=true)
List<dynamic> addExercisesToExerciseSets(
  List<dynamic> exerciseSets,
  List<dynamic> exerciseIds,
) {
  // העתק בטוח
  final list = List<Map<String, dynamic>>.from(
    (exerciseSets ?? []).map((e) => Map<String, dynamic>.from(e ?? {})),
  );

  // נורמליזציה: אם יש פריטים בלי orderIndex - ניתן להם אחד לפי המיקום הנוכחי ברשימה
  for (int i = 0; i < list.length; i++) {
    final oi = list[i]['orderIndex'];
    if (oi == null || (oi is String && int.tryParse(oi) == null)) {
      list[i]['orderIndex'] = i + 1; // לשמר את הסדר הקיים על המסך
    }
  }

  // מציאת ה-orderIndex הגבוה ביותר
  int maxOrder = 0;
  for (final e in list) {
    final oiRaw = e['orderIndex'];
    final oi = (oiRaw is int) ? oiRaw : int.tryParse('$oiRaw') ?? 0;
    if (oi > maxOrder) maxOrder = oi;
  }

  // הוצאת ID מכל צורה אפשרית ({id, name} / int / string)
  int? _extractId(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      for (final k in ['id', 'exerciseId', 'value']) {
        if (m.containsKey(k)) {
          final v = m[k];
          if (v is int) return v;
          if (v is String) return int.tryParse(v);
        }
      }
    }
    return null;
  }

  final ids = <int>[];
  for (final raw in (exerciseIds ?? [])) {
    final id = _extractId(raw);
    if (id != null) ids.add(id);
  }

  // שמירה על סדר הבחירה של המשתמש + בלי כפילויות
  final toAdd = <int>[];
  for (final id in ids) {
    if (!toAdd.contains(id)) toAdd.add(id);
  }

  for (final exId in toAdd) {
    // דלג אם כבר קיים
    final exists = list.any((e) => e['exerciseId'] == exId);
    if (exists) continue;

    maxOrder += 1; // תמיד בסוף

    list.add({
      'exerciseId': exId,
      'orderIndex': maxOrder,
      'sets': <Map<String, dynamic>>[
        {
          'setNumber': 1,
          'reps': null,
          'weight': null,
          'durationSeconds': null,
          'isChecked': false,
          'timerMode': 1,
          'showWeightField': true,
        },
      ],
    });
  }

  // חשוב: לא ממיינים מחדש לפי שום דבר חוץ מה-orderIndex המנורמל
  list.sort((a, b) => ((a['orderIndex'] ?? 999999) as int)
      .compareTo((b['orderIndex'] ?? 999999) as int));

  return list;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
