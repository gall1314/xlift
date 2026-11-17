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

/// Warm-up sets of a workout, in the shape App State `warmupSets` uses.
///
/// The template only says HOW MANY warm-up sets an exercise has. The weights
/// and the rest between them are built here, when the workout starts, by the
/// same generator the live workout uses (applyWarmupSimpleUnits), from the
/// weight of working set 1 the last time this exercise was done.
/// No history yet -> reps-only warm-up with the template's reps.
Future<List<dynamic>> loadWarmupSets(
  String? workoutId,
  String? userId,
  bool? isKg,
) async {
  final List<dynamic> out = [];
  final String wid = (workoutId ?? "").trim();
  if (wid.isEmpty) return out;
  final String uid = (userId ?? "").trim();
  final bool kg = isKg ?? true;

  int asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse((v ?? "").toString()) ?? 0;
  }

  double asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse((v ?? "").toString()) ?? 0;
  }

  bool truthy(dynamic v) {
    final String s = (v ?? "").toString().toLowerCase();
    return s == "1" || s == "true";
  }

  String equipKey(dynamic equipment) {
    final String e = (equipment ?? "").toString().trim().toLowerCase();
    if (e.contains("dumbbell") || e.contains("kettlebell")) return "dumbbell";
    if (e.contains("smith")) return "smith";
    if (e.contains("barbell") || e.contains("trap bar")) return "barbell";
    return "machine";
  }

  try {
    final db = SQLiteManager.instance.database;
    final rows = await db.rawQuery(
      'SELECT we.exercise_id AS exercise_id, es.set_number AS set_number, '
      'es.target_reps AS target_reps, '
      'es.duration_seconds AS duration_seconds, '
      'e.equipment AS equipment, e.is_time_based AS is_time_based, '
      'e.is_bodyweight AS is_bodyweight '
      'FROM exercise_sets es '
      'JOIN workout_exercise we ON we.id = es.workout_exercise_id '
      'LEFT JOIN exercise e ON e.id = we.exercise_id '
      'WHERE we.workout_id = ? AND COALESCE(es.is_warmup, 0) = 1 '
      'AND COALESCE(es.is_dropset, 0) = 0 '
      'ORDER BY we."order", es.set_number',
      [wid],
    );

    // group by exercise, keeping the workout order
    final List<int> order = [];
    final Map<int, List<Map<String, dynamic>>> byEx = {};
    for (final r in rows) {
      final int exId = asInt(r["exercise_id"]);
      if (exId <= 0) continue;
      if (!byEx.containsKey(exId)) {
        byEx[exId] = [];
        order.add(exId);
      }
      byEx[exId]!.add(Map<String, dynamic>.from(r));
    }

    for (final int exId in order) {
      final List<Map<String, dynamic>> tpl = byEx[exId]!;
      final int n = tpl.length;
      final bool timed = truthy(tpl.first["is_time_based"]);
      final bool bodyweight = truthy(tpl.first["is_bodyweight"]);

      // weight of working set 1 the last time, in the app's unit
      double? target;
      if (!timed && !bodyweight) {
        try {
          final List<Object?> args = [exId];
          String sql = 'SELECT weight, is_kg FROM set_log '
              'WHERE exercise_id = ? AND COALESCE(is_dropset, 0) = 0 '
              'AND CAST(set_number AS INTEGER) = 1 AND weight > 0';
          if (uid.isNotEmpty) {
            sql = sql + ' AND user_id = ?';
            args.add(uid);
          }
          sql = sql + ' ORDER BY created_at DESC LIMIT 1';
          final last = await db.rawQuery(sql, args);
          if (last.isNotEmpty) {
            double w = asDouble(last.first["weight"]);
            final dynamic rawKg = last.first["is_kg"];
            final bool logKg = rawKg == null ? kg : truthy(rawKg);
            if (logKg && !kg) w = w * 2.20462;
            if (!logKg && kg) w = w / 2.20462;
            w = (w * 100).round() / 100;
            if (w > 0) target = w;
          }
        } catch (_) {}
      }

      final bool withWeight = target != null;
      final String mode = timed
          ? "timed"
          : (withWeight ? equipKey(tpl.first["equipment"]) : "bodyweight");

      // the smart generator: weights by equipment + rest between the sets
      Map<String, dynamic>? entry;
      try {
        final dynamic gen = applyWarmupSimpleUnits(
          <dynamic>[],
          exId,
          mode,
          kg,
          target,
          n,
        );
        if (gen is List) {
          for (final g in gen) {
            if (g is Map && asInt(g["exerciseId"]) == exId) {
              entry = Map<String, dynamic>.from(g);
              break;
            }
          }
        }
      } catch (_) {}

      List<Map<String, dynamic>> sets = [];
      if (entry != null && entry["sets"] is List) {
        sets = (entry["sets"] as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }

      if (sets.isEmpty) {
        // generator unavailable: plain rows from the template
        for (int i = 0; i < n; i++) {
          sets.add({
            "setNumber": i + 1,
            "weight": "0",
            "restSec": 0,
          });
        }
      }

      // Weighted plan: the generator's reps belong to its weights, keep them.
      // Everything else keeps what was typed in the template.
      for (int i = 0; i < sets.length; i++) {
        final Map<String, dynamic> s = sets[i];
        final Map<String, dynamic>? t = i < n ? tpl[i] : null;
        final int tReps = t == null ? 0 : asInt(t["target_reps"]);
        final int tDur = t == null ? 0 : asInt(t["duration_seconds"]);
        if (!withWeight && !timed && tReps > 0) {
          s["reps"] = tReps;
          s["repsText"] = tReps.toString();
          s["targetReps"] = tReps;
        }
        if (timed && tDur > 0) s["durationSec"] = tDur;
        if (s["weight"] == null) s["weight"] = "0";
        if (s["restSec"] == null) s["restSec"] = 0;
        s["isDone"] = false;
      }

      out.add({
        "exerciseId": exId,
        "hidden": false,
        "completed": false,
        "sets": sets,
      });
    }
  } catch (_) {}
  return out;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
