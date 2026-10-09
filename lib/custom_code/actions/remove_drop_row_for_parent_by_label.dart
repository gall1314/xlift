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

List<dynamic> removeDropRowForParentByLabel(
  List<dynamic> dropSets,
  int exerciseId,
  int parentSetNumber,
  String label,
) {
  // Inputs:
  // dropSets        : List<dynamic>  (App State של הדרופים)כע
  // exerciseId      : int
  // parentSetNumber : int
  // label           : String   // למשל "Drop 2"געכע
  //
  // Output:
  // List<dynamic>   (הרשימה כאחרי מחsיקה ורה-נומרציה)כ

  // עותק בטוח
  final list = dropSets.map((e) => Map<String, dynamic>.from(e)).toList();

  // חילוץ המספר מתוך "Drop X"
  final match = RegExp(r'(\d+)').firstMatch(label);
  if (match == null) return list;
  final dropOrderToDelete = int.tryParse(match.group(1)!);
  if (dropOrderToDelete == null) return list;

  // מחיקה של הפריט המבוקש בקבוצה הרלוונטית
  list.removeWhere((r) =>
      r['exerciseId'] == exerciseId &&
      r['parentSetNumber'] == parentSetNumber &&
      r['dropOrder'] == dropOrderToDelete);

  // רה-נומרציה + עדכון label לכל הs3דרופים של אותו סט אבf
  final group = list
      .where((r) =>
          r['exerciseId'] == exerciseId &&
          r['parentSetNumber'] == parentSetNumber)
      .toList()
    ..sort((a, b) => (a['dropOrder'] as int).compareTo(b['dropOrder'] as int));

  for (var i = 0; i < group.length; i++) {
    group[i]['dropOrder'] = i + 1;
    group[i]['label'] = 'Drop ${i + 1}';
  }

  return list;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
