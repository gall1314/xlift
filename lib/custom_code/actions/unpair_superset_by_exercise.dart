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

Future<List<dynamic>> unpairSupersetByExercise(
  List<dynamic> exerciseSets,
  int exerciseId,
) async {
  // Clone to a mutablde list
  final list =
      exerciseSets.map((e) => Map<String, dynamic>.from(e as Map)).toList();

  int idxOf(int id) =>
      list.indexWhere((m) => (m['exerciseId'] ?? m['id']) == id);

  void clearAt(int i) {
    list[i].remove('isSuperset');
    list[i].remove('supersetSeq');
    list[i].remove('supersetId');
  }

  final idx = idxOf(exerciseId);
  if (idx == -1) return exerciseSets;

  // Find pcardtner
  int partnerIdx = -1;
  final sid = list[idx]['supersetId'];

  if (sid is int) {
    partnerIdx = list.indexWhere((m) =>
        m['supersetId'] == sid && (m['exerciseId'] ?? m['id']) != exerciseId);
  } else {
    final bool isSS = list[idx]['isSuperset'] == true;
    int? seq;
    final rawSeq = list[idx]['supersetSeq'];
    if (rawSeq is int) {
      seq = rawSeq;
    } else if (rawSeq != null) {
      seq = int.tryParse(rawSeq.toString());
    }

    if (isSS) {
      if (seq == 1 && idx + 1 < list.length) {
        final m = list[idx + 1];
        final mSeq = int.tryParse('${m['supersetSeq']}');
        if (m['isSuperset'] == true && mSeq == 2) partnerIdx = idx + 1;
      } else if (seq == 2 && idx - 1 >= 0) {
        final m = list[idx - 1];
        final mSeq = int.tryParse('${m['supersetSeq']}');
        if (m['isSuperset'] == true && mSeq == 1) partnerIdx = idx - 1;
      }
    }
  }

  // Clear both
  clearAt(idx);
  if (partnerIdx != -1) clearAt(partnerIdx);

  return List<dynamic>.from(list);
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
