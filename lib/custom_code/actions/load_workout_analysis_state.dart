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

/// Rebuilds workoutAnalysisState for a logged workout, so the set table can
/// show the score rings of analyses that were saved during the workout.
///
/// Reads set_analysis joined to its set_log and returns the shape the widget
/// expects:
///   [ { exerciseId, sets: [ { setNumber, analysisDone: true, analysis: {...} } ] } ]
///
/// The analysis map carries the same keys the live analyser emits, so the
/// ring, the result sheet and the feedback list all read it unchanged:
///   technique_score, technique_label, technique_score_display, form_tip,
///   tip, feedback (decoded list), reps (decoded list), avg_depth,
///   squat_count / rep_count, good_reps, analysisId.
///
/// setNumber is the STORED set number, which is what loggedSetsCreation
/// holds after the workout was loaded for editing - so the two line up.
///
/// Returns an empty list when there is nothing to show; never throws.
Future<List<dynamic>> loadWorkoutAnalysisState(String? workoutLogId) async {
  final String logId = (workoutLogId ?? '').trim();
  if (logId.isEmpty) return <dynamic>[];

  try {
    final db = SQLiteManager.instance.database;

    final List rows = await db.rawQuery(
      'SELECT a.id AS analysis_id, a.score, a.total_reps, a.proper_reps, '
      'a.feedback, a.technique_label, a.technique_score_display, '
      'a.form_tip, a.avg_depth, a.reps_json, '
      's.exercise_id AS exercise_id, s.set_number AS set_number '
      'FROM set_analysis a '
      'INNER JOIN set_log s ON s.id = a.set_log_id '
      'WHERE s.workout_log_id = ? '
      'ORDER BY s.exercise_id, s.set_number',
      [logId],
    );
    if (rows.isEmpty) return <dynamic>[];

    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v == null ? '' : v.toString()) ?? 0;
    }

    double asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v == null ? '' : v.toString()) ?? 0.0;
    }

    double? asDoubleOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    /// Stored as TEXT; '[]' or junk both come back as an empty list.
    List<dynamic> decodeList(dynamic raw) {
      if (raw == null) return <dynamic>[];
      if (raw is List) return raw;
      final String s = raw.toString().trim();
      if (s.isEmpty) return <dynamic>[];
      try {
        final dynamic parsed = jsonDecode(s);
        return parsed is List ? parsed : <dynamic>[];
      } catch (_) {
        return <dynamic>[];
      }
    }

    // exerciseId -> its sets, in order
    final Map<int, List<Map<String, dynamic>>> byExercise = {};
    final List<int> order = [];

    for (final r in rows) {
      if (r is! Map) continue;
      final int exerciseId = asInt(r['exercise_id']);
      final int setNumber = asInt(r['set_number']);

      final List<dynamic> feedback = decodeList(r['feedback']);
      final List<dynamic> reps = decodeList(r['reps_json']);
      final String tip = (r['form_tip'] ?? '').toString();
      final int totalReps = asInt(r['total_reps']);

      final Map<String, dynamic> analysis = {
        'analysisId': (r['analysis_id'] ?? '').toString(),
        'technique_score': asDouble(r['score']),
        'technique_label': (r['technique_label'] ?? '').toString(),
        'technique_score_display':
            (r['technique_score_display'] ?? '').toString(),
        'form_tip': tip,
        'tip': tip,
        'feedback': feedback,
        'reps': reps,
        'avg_depth': asDoubleOrNull(r['avg_depth']),
        'total_reps': totalReps,
        // the live analyser reports the rep count under these two keys
        'squat_count': totalReps,
        'rep_count': totalReps,
        'good_reps': asInt(r['proper_reps']),
        'proper_reps': asInt(r['proper_reps']),
      };

      byExercise.putIfAbsent(exerciseId, () {
        order.add(exerciseId);
        return <Map<String, dynamic>>[];
      }).add({
        'setNumber': setNumber,
        'analysisDone': true,
        'isProcessing': false,
        'hasError': false,
        'analysis': analysis,
      });
    }

    final List<dynamic> out = [];
    for (final exerciseId in order) {
      out.add({
        'exerciseId': exerciseId,
        'sets': byExercise[exerciseId],
      });
    }
    return out;
  } catch (_) {
    // Nothing to show beats a broken page.
    return <dynamic>[];
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
