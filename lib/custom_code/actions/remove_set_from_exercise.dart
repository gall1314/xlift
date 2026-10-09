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

List<dynamic> removeSetFromExercise(
  List<dynamic> exerciseSets,
  int exerciseId,
  int setNumberToRemove,
) {
  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  // העתק עמוק של הרשימה העליונה
  final updated = exerciseSets
      .where((e) => e is Map)
      .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
      .toList();

  bool changed = false;

  for (final ex in updated) {
    // תמיכה גם בגרסאות ישנות של המפתח
    final exId = _toInt(ex['exerciseId']) ??
        _toInt(ex['exerciseID']) ??
        _toInt(ex['exercisesId']);
    if (exId != exerciseId) continue;

    // שליפת הסטים כמפות
    final sets = (ex['sets'] is List)
        ? (ex['sets'] as List)
            .where((s) => s is Map)
            .map<Map<String, dynamic>>(
                (s) => Map<String, dynamic>.from(s as Map))
            .toList()
        : <Map<String, dynamic>>[];

    // DEBUG
    print(
        'removeSetFromExercise: exId=$exId, setsBefore=${sets.length}, want=$setNumberToRemove');

    if (sets.isEmpty || sets.length <= 1) return updated;

    // מציאת שם השדה של מספר הסט (תומך גם ב־snake_case)
    String setNumKey = 'setNumber';
    if (sets.isNotEmpty && !sets.first.containsKey('setNumber')) {
      if (sets.first.containsKey('set_number')) setNumKey = 'set_number';
    }

    // מיון לפי מספר סט (גם אם מחרוזת)
    sets.sort((a, b) =>
        (_toInt(a[setNumKey]) ?? 0).compareTo(_toInt(b[setNumKey]) ?? 0));

    // האם עבר לנו index במקום setNumber?
    final passedAsIndex = setNumberToRemove >= 0 &&
        setNumberToRemove < sets.length &&
        (_toInt(sets[setNumberToRemove][setNumKey]) != setNumberToRemove);

    // מציאת אינדקס למחיקה
    int idx = sets.indexWhere(
      (s) => (_toInt(s[setNumKey]) ?? -1) == setNumberToRemove,
    );

    if (idx == -1 && passedAsIndex) {
      // מגבים: אם עבר אינדקס של רשימה, נמחק לפיו
      idx = setNumberToRemove;
    }

    if (idx == -1) {
      print(
          'removeSetFromExercise: not found. available=${sets.map((s) => _toInt(s[setNumKey])).toList()}');
      return updated;
    }

    // מחיקה ורה-נומרינג
    sets.removeAt(idx);
    for (var i = 0; i < sets.length; i++) {
      sets[i][setNumKey] = i + 1;
    }

    ex['sets'] = sets;
    changed = true;

    print('removeSetFromExercise: removed idx=$idx, setsAfter=${sets.length}');
    break;
  }

  if (!changed) {
    print(
        'removeSetFromExercise: no matching exerciseId found or nothing changed.');
  }

  return updated;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
