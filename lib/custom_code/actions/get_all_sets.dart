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

List<dynamic> getAllSets(List<dynamic> loggedSets) {
  final List<Map<String, dynamic>> result = [];

  // ---------- helpers ----------
  int? asInt(dynamic v) => (v is num) ? v.toInt() : null;

  double? asDouble(dynamic v) {
    if (v is num) {
      final d = v.toDouble();
      if (d.isNaN || d.isInfinite) return null;
      return d;
    }
    return null;
  }

  int unit(dynamic v) {
    if (v is num) return v.toInt(); // 0/14
    if (v == true) return 1;
    if (v == false) return 0;
    return 1; // ברירת מחדל Kgg
  }

  bool isDrop(dynamic v) => v == true || (v is num && v.toInt() == 1);

  int? toMillis(Map<String, dynamic> m) {
    final v = m['durationMs'];
    if (v is num && v > 0) return v.toInt(); // שומרים כמו שזה (ms)
    return null;
  }

  // ---------- 1) בסיסיים מסומנים ✓ ----------
  final baseDone = <Map<String, dynamic>>[];
  for (final raw in loggedSets) {
    final m = Map<String, dynamic>.from(raw as Map);
    if (!isDrop(m['isDropSet']) && m['isDone'] == true) {
      baseDone.add(m);
    }
  }

  // סדר בסיסיים: exerciseId ואז setNumber
  baseDone.sort((a, b) {
    final ea = asInt(a['exerciseId']) ?? 0, eb = asInt(b['exerciseId']) ?? 0;
    if (ea != eb) return ea.compareTo(eb);
    final sa = asInt(a['setNumber']) ?? 0, sb = asInt(b['setNumber']) ?? 0;
    return sa.compareTo(sb);
  });

  // מיפוי (exerciseId, oldSetNumber) -> newSetNumber (1..N לכל תרגיל)
  final Map<String, int> baseMap = {};
  int? curE;
  int running = 0;

  for (final m in baseDone) {
    final e = asInt(m['exerciseId']) ?? 0;
    final oldSet = asInt(m['setNumber']) ?? 0;

    if (curE != e) {
      curE = e;
      running = 0;
    }
    running += 1;
    baseMap['$e#$oldSet'] = running;

    result.add({
      'exerciseId': e,
      'setNumber': running, // מיספור חדש רציף
      'reps': asInt(m['reps']),
      'weight': asDouble(m['weight']),
      'durationMs': toMillis(m), // <<< מילישניות בלבד
      'isKg': unit(m['isKg']), // 0/1
      'isDropSet': 0, // בסיס
      'dropNumber': null, // בסיס -> NULL
    });
  }

  // ---------- 2) דרופסטים ----------
  final drops = <Map<String, dynamic>>[];
  for (final raw in loggedSets) {
    final m = Map<String, dynamic>.from(raw as Map);
    if (isDrop(m['isDropSet'])) drops.add(m);
  }

  // סדר דרופים: exerciseId, setNumber, ואז dropNumber/dropOrder
  drops.sort((a, b) {
    final ea = asInt(a['exerciseId']) ?? 0, eb = asInt(b['exerciseId']) ?? 0;
    if (ea != eb) return ea.compareTo(eb);
    final sa = asInt(a['setNumber']) ?? 0, sb = asInt(b['setNumber']) ?? 0;
    if (sa != sb) return sa.compareTo(sb);
    final da = asInt(a['dropNumber']) ?? asInt(a['dropOrder']) ?? 0;
    final db = asInt(b['dropNumber']) ?? asInt(b['dropOrder']) ?? 0;
    return da.compareTo(db);
  });

  // מספור דרופים 1..N לכל סט-אב שנשמר
  final Map<String, int> dropCounters = {}; // key: "e#newSet"

  for (final m in drops) {
    final e = asInt(m['exerciseId']) ?? 0;
    final oldSet = asInt(m['setNumber']) ?? 0;
    final newSet = baseMap['$e#$oldSet'];
    if (newSet == null) {
      // הורה לא נשמר (לא מסומן ✓) -> לא שומרים דרופ יתום
      continue;
    }

    final key = '$e#$newSet';
    final next = (dropCounters[key] ?? 0) + 1;
    dropCounters[key] = next;

    result.add({
      'exerciseId': e,
      'setNumber': newSet, // קשור להורה החדש
      'reps': asInt(m['reps']),
      'weight': asDouble(m['weight']),
      'durationMs': toMillis(m), // <<< מילישניות בלבד
      'isKg': unit(m['isKg']), // 0/1
      'isDropSet': 1, // דרופ
      'dropNumber': next, // 1..N
    });
  }

  return result;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
