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

List<dynamic> generateWeeklySchedule(
  List<dynamic> workoutConfigs,
) {
  const int daysCount = 7;

  // --- helpers ---
  int restToMinDays(int? restHours) {
    if (restHours == null || restHours <= 0) return 0;
    if (restHours <= 24) return 1;
    if (restHours <= 48) return 2;
    return 3;
  }

  // --- init week ---
  final List<Map<String, dynamic>> week = List.generate(daysCount, (i) {
    return {
      'dayIndex': i,
      'workoutId': null,
      'hasError': false,
      'errorReason': null,
    };
  });

  // --- normalize configs ---
  final List<Map<String, dynamic>> workouts = workoutConfigs
      .whereType<Map>()
      .map<Map<String, dynamic>>((c) {
        final id = c['workoutId'];
        if (id is! String || id.isEmpty) return {};

        return {
          'workoutId': id,
          'timesPerWeek': (c['timesPerWeek'] is int && c['timesPerWeek'] > 0)
              ? c['timesPerWeek']
              : 1,
          'minRestDays':
              restToMinDays(c['restHours'] is int ? c['restHours'] : null),
          'placedDays': <int>[],
        };
      })
      .where((c) => c.isNotEmpty)
      .toList();

  // --- main scheduling ---
  for (int day = 0; day < daysCount; day++) {
    for (final workout in workouts) {
      if (week[day]['workoutId'] != null) continue;

      final placedDays = workout['placedDays'] as List<int>;
      if (placedDays.length >= workout['timesPerWeek']) continue;

      bool violatesRest = false;
      for (final prev in placedDays) {
        if ((day - prev).abs() <= workout['minRestDays']) {
          violatesRest = true;
          break;
        }
      }
      if (violatesRest) continue;

      // place
      week[day]['workoutId'] = workout['workoutId'];
      placedDays.add(day);
      break;
    }
  }

  // --- mark errors ---
  for (final workout in workouts) {
    if ((workout['placedDays'] as List).length < workout['timesPerWeek']) {
      for (final d in workout['placedDays']) {
        week[d]['hasError'] = true;
        week[d]['errorReason'] = 'NOT_ENOUGH_REST';
      }
    }
  }

  return week;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
