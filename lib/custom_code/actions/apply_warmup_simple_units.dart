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

/// The one warm-up generator. Builds (or replaces) the warm-up entry of
/// [exerciseId] in [warmupList]. Same signature as before, so nothing in FF
/// changes; the mode comes from [equipment]:
///
///   'barbell' | 'smith' | 'machine' | 'dumbbell'
///       → percentage ramp of [targetWeight] (weight hint "0" when no target),
///         reps by percent, plate-rounded for the equipment.
///   'bodyweight'
///       → easy rep ramp, weight "0". With [targetWeight] > 0 (belt / vest)
///         the LAST set carries ~half of it.
///   'timed'
///       → duration ramp 15s, 20s, 25s… (durationSec), reps/weight null —
///         this is what applyWarmupSimpleSets used to produce.
///
/// Every set also gets `restSec` — the rest to take after it: 30s early,
/// longer as the load climbs, 90s before the first working set; barbell and
/// smith get +15s near the top. Bodyweight: 30s (last 60s).
///
/// Set shape: {setNumber, percent, reps, repsText, weight (String), isDone,
/// isWarmup, durationSec, restSec}.
List<dynamic> applyWarmupSimpleUnits(
  List<dynamic> warmupList,
  int exerciseId,
  String
      equipment, // 'barbell' | 'smith' | 'machine' | 'dumbbell' | 'bodyweight' | 'timed'
  bool isKg,
  double? targetWeight, // may be null / 0
  int numWarmups, // 1..4
) {
  // ===== helpers =====
  final String eq = equipment.trim().toLowerCase();
  final bool isBodyweight = eq == 'bodyweight';
  final bool isTimed = eq == 'timed';
  final bool isBar = eq == 'barbell' || eq == 'smith' || eq.contains('trap');
  final bool isDumbbell = eq == 'dumbbell' || eq.contains('kettlebell');
  final int count = numWarmups.clamp(1, 4).toInt();
  final bool hasTarget = targetWeight != null && targetWeight > 0;
  final double base = hasTarget ? targetWeight : 0.0;

  List<double> scheme(int n) {
    if (n <= 1) return [0.60];
    if (n == 2) return [0.50, 0.70];
    if (n == 3) return [0.50, 0.70, 0.85];
    return [0.40, 0.60, 0.75, 0.85];
  }

  // bodyweight: sub-maximal reps, climbing toward the working sets
  List<int> bodyweightReps(int n) {
    if (n <= 1) return [6];
    if (n == 2) return [5, 6];
    if (n == 3) return [4, 5, 6];
    return [3, 4, 5, 6];
  }

  int repsForPercent(double p) {
    if (p <= 0.50) return 12;
    if (p <= 0.60) return 10;
    if (p <= 0.70) return 8;
    if (p <= 0.80) return 6;
    return 4;
  }

  num roundForEquipment(num w) {
    if (isDumbbell) {
      final step = isKg ? ((w < 10) ? 1.0 : 2.0) : ((w < 25) ? 2.5 : 5.0);
      return (w / step).round() * step;
    }
    return isKg ? ((w / 2.5).round() * 2.5) : ((w / 5.0).round() * 5.0);
  }

  String fmt(num v) {
    final s = v.toDouble().toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  /// Rest after set [i] (0-based) at [pct] of the working weight.
  int restAfter(int i, double pct, bool loaded) {
    final bool last = i == count - 1;
    if (!loaded) return last ? 60 : 30;
    int r;
    if (last) {
      r = 90;
    } else if (pct <= 0.50) {
      r = 30;
    } else if (pct <= 0.70) {
      r = 45;
    } else {
      r = 60;
    }
    if (isBar && pct >= 0.70) r += 15;
    return r;
  }

  List<Map<String, dynamic>> toMapList(List<dynamic> src) =>
      List<Map<String, dynamic>>.from(
          src.map((e) => Map<String, dynamic>.from(e)));

  // ===== build sets =====
  final generatedSets = <Map<String, dynamic>>[];

  if (isTimed) {
    for (var i = 0; i < count; i++) {
      generatedSets.add({
        'setNumber': i + 1,
        'percent': null,
        'reps': null,
        'repsText': null,
        'weight': null,
        'durationSeconds': null,
        'durationSec': 15 + 5 * i,
        'isDone': false,
        'isWarmup': true,
        'restSec': restAfter(i, 0, false),
      });
    }
  } else if (isBodyweight) {
    final reps = bodyweightReps(count);
    for (var i = 0; i < count; i++) {
      final bool last = i == count - 1;
      // added weight (belt / vest): only the last set carries ~half of it
      final num added = hasTarget && last ? roundForEquipment(base * 0.5) : 0;
      generatedSets.add({
        'setNumber': i + 1,
        'percent': added > 0 ? 0.5 : 0.0,
        'reps': reps[i],
        'repsText': '${reps[i]}',
        'weight': fmt(added),
        'isDone': false,
        'isWarmup': true,
        // with added weight the ramp is a bit heavier → treat like a loaded ramp
        'restSec':
            restAfter(i, hasTarget ? (last ? 0.75 : 0.40) : 0, hasTarget),
      });
    }
  } else {
    final pcts = scheme(count);
    for (var i = 0; i < pcts.length; i++) {
      final pct = pcts[i];
      final reps = repsForPercent(pct);
      // weight hint: always a String, "0" when there is no target
      final String weightText =
          hasTarget ? fmt(roundForEquipment(base * pct)) : '0';
      generatedSets.add({
        'setNumber': i + 1,
        'percent': pct,
        'reps': reps,
        'repsText': '$reps',
        'weight': weightText,
        'isDone': false,
        'isWarmup': true,
        'restSec': restAfter(i, pct, true),
      });
    }
  }

  // ===== merge into list =====
  final list = toMapList(warmupList);
  final idx = list.indexWhere((e) => '${e['exerciseId']}' == '$exerciseId');
  final entry = {
    'exerciseId': exerciseId,
    'sets': generatedSets,
    'hidden': false,
    'completed': false,
  };
  if (idx == -1) {
    list.add(entry);
  } else {
    list[idx] = entry;
  }
  return list;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
