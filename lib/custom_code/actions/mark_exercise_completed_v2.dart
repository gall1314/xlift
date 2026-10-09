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

List<dynamic> markExerciseCompletedV2(
  List<dynamic> exerciseSets, // template
  List<dynamic> loggedSets, // collected logs
  int exerciseId,
  bool allowsBodyweight,
  bool isTimedExercise,
) {
  // ---------- safe copy ----------
  final updated = List<Map<String, dynamic>>.from(
    loggedSets.map((s) => Map<String, dynamic>.from(s as Map)),
  );

  // ---------- helpers ----------
  int asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  double? asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  int setNo(Map m) => asInt(m['setNumber']);

  // ---------- fetch template ----------
  final tpl = exerciseSets.firstWhere(
    (e) => e is Map && e['exerciseId'] == exerciseId && e['sets'] is List,
    orElse: () => null,
  );

  if (tpl == null) return updated;

  final templateSets = (tpl['sets'] as List)
      .whereType<Map>()
      .map((m) => Map<String, dynamic>.from(m))
      .toList()
    ..sort((a, b) => asInt(a['setNumber']).compareTo(asInt(b['setNumber'])));

  final Map<int, Map<String, dynamic>> templateBySet = {
    for (final s in templateSets) asInt(s['setNumber']): s,
  };

  // ---------- logged helpers ----------
  Map<String, dynamic>? loggedOf(int sn) {
    for (final s in updated) {
      if (asInt(s['exerciseId']) == exerciseId && asInt(s['setNumber']) == sn) {
        return Map<String, dynamic>.from(s);
      }
    }
    return null;
  }

  Map<String, dynamic>? loggedBackward(int sn) {
    if (isTimedExercise) return null;

    final prev = updated
        .where((s) =>
            asInt(s['exerciseId']) == exerciseId && asInt(s['setNumber']) < sn)
        .toList()
      ..sort((a, b) => asInt(b['setNumber']).compareTo(asInt(a['setNumber'])));

    for (final s in prev) {
      final reps = asInt(s['reps']);
      final w = asDouble(s['weight']);
      if (reps > 0 || (w != null && w > 0)) {
        return s;
      }
    }
    return null;
  }

  Map<String, dynamic>? targetBackward(int sn) {
    if (isTimedExercise) return null;

    final keys = templateBySet.keys.toList()
      ..retainWhere((k) => k < sn)
      ..sort((a, b) => b.compareTo(a));

    for (final k in keys) {
      final t = templateBySet[k]!;
      final tr = asInt(t['targetReps']);
      final tw = asDouble(t['targetWeight']);
      if (tr > 0 || (tw != null && tw > 0)) {
        return t;
      }
    }
    return null;
  }

  // ---------- resolve one set ----------
  Map<String, dynamic> resolveSet(int sn) {
    final logged = loggedOf(sn);
    final tplSet = templateBySet[sn];
    final backLogged = loggedBackward(sn);
    final backTarget = targetBackward(sn);

    int reps = 0;
    double? weight;
    int duration = 0;

    if (isTimedExercise) {
      // no inhרeritance
      duration = asInt(logged?['durationMs']);
      if (duration == 0) {
        duration = asInt(tplSet?['targetDurationSeconds']);
      }
    } else {
      // reps (hierarchy)
      reps = asInt(logged?['reps']);
      if (reps == 0) reps = asInt(tplSet?['targetReps']);
      if (reps == 0) reps = asInt(backLogged?['reps']);
      if (reps == 0) reps = asInt(backTarget?['targetReps']);

      // weight (hierarchy – if exists anywhere, take it)
      weight = asDouble(logged?['weight']);
      if (weight == null || weight == 0) {
        weight = asDouble(tplSet?['targetWeight']);
      }
      if (weight == null || weight == 0) {
        weight = asDouble(backLogged?['weight']);
      }
      if (weight == null || weight == 0) {
        weight = asDouble(backTarget?['targetWeight']);
      }
    }

    final Map<String, dynamic> out = {
      'exerciseId': exerciseId,
      'setNumber': sn,
      'isDone': true,
    };

    if (isTimedExercise) {
      if (duration > 0) out['durationMs'] = duration;
    } else {
      if (reps > 0) out['reps'] = reps;
      if (weight != null && weight > 0) {
        out['weight'] = weight;
      }
    }

    return out;
  }

  // ---------- apply all sets ----------
  for (final t in templateSets) {
    final sn = asInt(t['setNumber']);
    final solved = resolveSet(sn);

    final idx = updated.indexWhere(
      (u) =>
          asInt(u['exerciseId']) == exerciseId && asInt(u['setNumber']) == sn,
    );

    if (idx >= 0) {
      updated[idx] = {...updated[idx], ...solved};
    } else {
      updated.add(solved);
    }
  }

  return updated;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
