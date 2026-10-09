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

List<dynamic> addNextDropRow(
  List<dynamic> dropSets,
  int exerciseId,
  int parentSetNumber,
) {
  // עותק כדי לא לשנות את הרשימה המקורית
  final list = dropSets.map((e) => Map<String, dynamic>.from(e)).toList();

  // מוצאים את כל הדרופים הקיימים לאותו סט אב
  final existing = list.where(
    (r) =>
        r['exerciseId'] == exerciseId &&
        r['parentSetNumber'] == parentSetNumber,
  );

  // מחפשים את המספר הגבוה ביותר שקיים כבר
  final int nextOrder = existing.isEmpty
      ? 1
      : (existing
              .map((e) => (e['dropOrder'] ?? 0) as int)
              .reduce((a, b) => a > b ? a : b) +
          1);

  // מוסיפים דרופ חדש עם מספר סדרתי בלבד
  list.add({
    'exerciseId': exerciseId,
    'parentSetNumber': parentSetNumber,
    'dropOrder': nextOrder,
    'reps': null,
    'weight': null,
    'percentFromParent': null,
    'locked': false,
  });

  return list;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
