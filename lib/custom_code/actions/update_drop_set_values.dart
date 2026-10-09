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

List<dynamic> updateDropSetValues(
  List<dynamic> dropSets,
  int exerciseId,
  int parentSetNumber,
  int dropOrder,
  int? reps,
) {
  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String && v.trim().isNotEmpty) return int.tryParse(v.trim());
    return null;
  }

  final list =
      dropSets.map((e) => Map<String, dynamic>.from(e as Map)).toList();

  final idx = list.indexWhere(
    (r) =>
        r['exerciseId'] == exerciseId &&
        r['parentSetNumber'] == parentSetNumber &&
        r['dropOrder'] == dropOrder,
  );

  if (idx < 0) return list;

  if (reps != null) {
    list[idx]['reps'] = _toInt(reps);
  }

  return list;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
