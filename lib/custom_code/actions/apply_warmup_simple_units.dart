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

List<dynamic> applyWarmupSimpleUnits(
  List<dynamic> warmupList,
  int exerciseId,
  String equipment, // 'barbell' | 'smith' | 'machine' | 'dumbbell'
  bool isKg,
  double? targetWeight, // יכו4ל להיות null/0
  int numWarmups, // 1..4
) {
  // ===== helpers =====
  List<double> scheme(int count) {
    if (count <= 1) return [0.60];
    if (count == 2) return [0.50, 0.70];
    if (count == 3) return [0.50, 0.70, 0.85];
    return [0.40, 0.60, 0.75, 0.85];
  }

  int repsForPercent(double p) {
    if (p <= 0.50) return 12;
    if (p <= 0.60) return 10;
    if (p <= 0.70) return 8;
    if (p <= 0.80) return 6;
    return 4;
  }

  num roundForEquipment(num w, String eq, bool isKgUnits) {
    final t = eq.toLowerCase();
    if (t == 'dumbbell') {
      if (isKgUnits) {
        final step = (w < 10) ? 1.0 : 2.0;
        return ((w / step).round() * step);
      } else {
        final step = (w < 25) ? 2.5 : 5.0;
        return ((w / step).round() * step);
      }
    }
    return isKgUnits ? ((w / 2.5).round() * 2.5) : ((w / 5.0).round() * 5.0);
  }

  String _fmt(num v) {
    final d = v.toDouble();
    final s = d.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  List<Map<String, dynamic>> toMapList(List<dynamic> src) =>
      List<Map<String, dynamic>>.from(
        src.map((e) => Map<String, dynamic>.from(e)),
      );

  // ===== main =====
  final pcts = scheme(numWarmups.clamp(1, 4));
  final hasTarget = (targetWeight != null && targetWeight! > 0);
  final base = hasTarget ? targetWeight! : 0.0;

  final generatedSets = <Map<String, dynamic>>[];
  for (var i = 0; i < pcts.length; i++) {
    final pct = pcts[i];
    final reps = repsForPercent(pct);

    // hint משקל: תמיד String, אם אין יעד -> "0"
    String weightText = '0';
    if (hasTarget) {
      final raw = base * pct;
      final rounded = roundForEquipment(raw, equipment, isKg);
      weightText = _fmt(rounded);
    }

    generatedSets.add({
      'setNumber': i + 1, // int
      'percent': pct, // double
      'reps': reps, // int (ללוגיקה)
      'repsText': '$reps', // String (לתצוגה)
      'weight': weightText, // String ("0" כשאין יעד)
      'isDone': false, // bool
    });
  }

  final list = toMapList(warmupList);
  final idx = list.indexWhere((e) => e['exerciseId'] == exerciseId);
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
