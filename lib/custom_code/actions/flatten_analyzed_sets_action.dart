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

import 'dart:convert';

/// Flattens the nested analysis app state into a FULLY FLAT list
/// ready for the set_analysis insert loop. Every field the insert
/// needs sits at the TOP LEVEL of each item - no nested 'analysis'.
/// EVERY key the insert maps is ALWAYS present (empty string / 0 when
/// missing) so no JSON Path ever fails on an absent key.
/// Only sets with analysisDone == true, a non-null analysis map,
/// and an attached setLogId are included.
Future<List<dynamic>> flattenAnalyzedSetsAction(
  List<dynamic>? analysisList,
) async {
  final out = <Map<String, dynamic>>[];

  if (analysisList == null) return out;

  for (final item in analysisList) {
    if (item is! Map) continue;

    final exerciseId = item['exerciseId'];
    if (exerciseId == null) continue;

    final sets = item['sets'];
    if (sets is! List) continue;

    for (final s in sets) {
      if (s is! Map) continue;

      // Only sets with a completed analysis are relevant for saving.
      if (s['analysisDone'] != true) continue;

      final analysis = s['analysis'];
      if (analysis is! Map) continue;

      // Skip sets that never got a set_log id attached - without it
      // the insert into set_analysis would fail on NOT NULL.
      final setLogId = s['setLogId'];
      if (setLogId == null || setLogId.toString().trim().isEmpty) continue;

      // ---- numeric helpers (analyzer values can be int/double) ----
      double asDouble(dynamic v) {
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '') ?? 0.0;
      }

      int asInt(dynamic v) {
        if (v is int) return v;
        if (v is num) return v.toInt();
        return int.tryParse(v?.toString() ?? '') ?? 0;
      }

      // Feedback is a List in the analyzer output - store as a JSON
      // string so it fits a TEXT column and parseFeedback can read it.
      String feedbackJson = '[]';
      final fb = analysis['feedback'];
      if (fb is List) {
        feedbackJson = jsonEncode(fb);
      } else if (fb is String && fb.trim().isNotEmpty) {
        feedbackJson = fb;
      }

      // form_tip: ALWAYS present as a key, empty string when the
      // analyzer didn't produce one - a missing key breaks the
      // insert's JSON Path binding even on a nullable column.
      final String formTip = (analysis['form_tip'] ?? '').toString();

      out.add({
        'exerciseId': exerciseId,
        'setNumber': s['setNumber'],
        'setLogId': setLogId,
        // ---- flattened analysis fields (top level!) ----
        'technique_score': asDouble(analysis['technique_score']),
        'technique_score_display':
            (analysis['technique_score_display'] ?? '').toString(),
        'technique_label': (analysis['technique_label'] ?? '').toString(),
        'squat_count': asInt(analysis['squat_count']),
        'good_reps': asInt(analysis['good_reps']),
        'bad_reps': asInt(analysis['bad_reps']),
        'feedback': feedbackJson,
        'form_tip': formTip,
      });
    }
  }

  return out;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
