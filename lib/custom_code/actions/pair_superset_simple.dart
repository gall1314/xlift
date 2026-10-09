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

Future<List<dynamic>> pairSupersetSimple(
  List<dynamic> exerciseSets,
  int firstId,
  int secondId,
) async {
  final list = exerciseSets
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  int? toIntId(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  // Robust: match by exerciseId / exercise_id only - never the UUID 'id'.
  int idxOf(int id) => list
      .indexWhere((m) => toIntId(m['exerciseId'] ?? m['exercise_id']) == id);

  final aIdx = idxOf(firstId);
  final bIdx = idxOf(secondId);
  if (aIdx == -1 || bIdx == -1) return exerciseSets;

  // One shared group id for the pair.
  final groupId = 'ss_${DateTime.now().millisecondsSinceEpoch}';

  list[aIdx]['isSuperset'] = true;
  list[aIdx]['supersetSeq'] = 1;
  list[aIdx]['supersetGroupId'] = groupId;

  list[bIdx]['isSuperset'] = true;
  list[bIdx]['supersetSeq'] = 2;
  list[bIdx]['supersetGroupId'] = groupId;

  // Move the second right after the first.
  final second = list.removeAt(bIdx);
  final newAIdx = idxOf(firstId);
  list.insert(newAIdx + 1, second);

  return list;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
