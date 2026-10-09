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
//
// replacement = the JSON you build on tap (e.g. page state idToReplace):
//   { id, name, is_assisted, is_public }  - snake_case or camelCase both OK
List<dynamic> replaceExerciseInExerciseSets(
  List<dynamic> exerciseSets,
  int originalExerciseId,
  dynamic replacement,
) {
  // הגנה בסיסית
  final list = List<Map<String, dynamic>>.from(
    (exerciseSets ?? []).map((e) => Map<String, dynamic>.from(e ?? {})),
  );

  // ---- read the replacement JSON (tolerant to key naming / types) ----
  if (replacement == null || replacement is! Map) return list;
  final Map rep = replacement;

  dynamic pick(List<String> keys) {
    for (final k in keys) {
      if (rep.containsKey(k) && rep[k] != null) return rep[k];
    }
    return null;
  }

  int? toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  int toFlag(dynamic v) {
    if (v == null) return 0;
    if (v is bool) return v ? 1 : 0;
    if (v is num) return v != 0 ? 1 : 0;
    final s = v.toString().trim().toLowerCase();
    return (s == '1' || s == 'true') ? 1 : 0;
  }

  String? toStr(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  final int? replacementExerciseId =
      toInt(pick(['id', 'exerciseId', 'exercise_id']));
  if (replacementExerciseId == null) return list;

  final String? replacementExerciseName =
      toStr(pick(['name', 'exerciseName', 'exercise_name']));
  final int replacementIsAssisted = toFlag(pick(['is_assisted', 'isAssisted']));
  final int replacementIsPublic = toFlag(pick(['is_public', 'isPublic']));

  // מצא את האינדקס של התרגיל המקורי
  final origIdx = list.indexWhere((e) => e['exerciseId'] == originalExerciseId);
  if (origIdx == -1) {
    // אין תרגיל כזה – מחזירים כמו שהוא
    return list;
  }

  // שמור סדר מקורי אם קיים
  final int orderIndex = (list[origIdx]['orderIndex'] is int)
      ? list[origIdx]['orderIndex'] as int
      : (origIdx + 1);

  // שמור את זמן המנוחה של התרגיל המקורי (המשתמש כבר בחר אותו)
  final dynamic restSeconds = list[origIdx]['restSeconds'] ?? 0;

  // הסר את התרגיל המקורי
  list.removeAt(origIdx);

  // למניעת כפילות – אם כבר קיים התרגיל המחליף, נסיר אותו לפני הוספה
  final existedRepIdx =
      list.indexWhere((e) => e['exerciseId'] == replacementExerciseId);
  if (existedRepIdx != -1) {
    list.removeAt(existedRepIdx);
  }

  // בנה פריט חדש עם סט ראשון ברירת-מחדל
  // Same keys as initializeExerciseSetsFromSimpleQueryV2 / addExercises...
  final Map<String, dynamic> newItem = {
    'exerciseId': replacementExerciseId,
    'exerciseName': replacementExerciseName,
    'isPublic': replacementIsPublic,
    'isAssisted': replacementIsAssisted,
    'orderIndex': orderIndex,
    'restSeconds': restSeconds,
    'sets': <Map<String, dynamic>>[
      {
        'setNumber': 1,
        'reps': null,
        'weight': null,
        'durationSeconds': null,
        'isChecked': false,
        'timerMode': 1, // כמו אצלך
        'showWeightField': true, // כמו אצלך
      },
    ],
  };

  // הכנס למיקום המקורי (כדי לשמר סדר), ואם חורג – הוסף לסוף
  final insertIdx =
      (origIdx >= 0 && origIdx <= list.length) ? origIdx : list.length;
  list.insert(insertIdx, newItem);

  // מיון בטיחות לפי orderIndex (במידת הצורך)
  list.sort((a, b) => ((a['orderIndex'] ?? 9999) as int)
      .compareTo((b['orderIndex'] ?? 9999) as int));

  return list;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
