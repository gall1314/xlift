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

/// Fetches all exercise_sets rows for a user, directly from Supabase.
///
/// exercise_sets has no user_id, so we go workout(user_id) ->
/// workout_exercise -> exercise_sets in ONE embedded select (no IN list,
/// no URL-length limit), page through workouts in chunks so the 1000-row
/// cap never truncates, and flatten to a plain list of exercise_sets rows
/// (each row also carries workout_exercise_id, as in the table).
/// Empty list on failure - the reason is logged, not swallowed silently.
Future<List<dynamic>> fetchExerciseSetsDirect(String userId) async {
  final List<dynamic> out = [];
  const int pageSize = 200; // workouts per page

  try {
    int from = 0;
    while (true) {
      final rows = await SupaFlow.client
          .from('workout')
          .select('id, workout_exercise(id, exercise_sets(*))')
          .eq('user_id', userId)
          .order('id', ascending: true)
          .range(from, from + pageSize - 1);

      final List<dynamic> page = List<dynamic>.from(rows);
      for (final w in page) {
        if (w is! Map) continue;
        final exs = w['workout_exercise'];
        if (exs is! List) continue;
        for (final ex in exs) {
          if (ex is! Map) continue;
          final sets = ex['exercise_sets'];
          if (sets is! List) continue;
          for (final s in sets) {
            if (s is Map) out.add(Map<String, dynamic>.from(s));
          }
        }
      }

      if (page.length < pageSize) break;
      from += pageSize;
    }

    // Stable order: by workout_exercise_id, then order_index.
    out.sort((a, b) {
      final String wa = (a['workout_exercise_id'] ?? '').toString();
      final String wb = (b['workout_exercise_id'] ?? '').toString();
      final int c = wa.compareTo(wb);
      if (c != 0) return c;
      final int oa = (a['order_index'] as num?)?.toInt() ?? 0;
      final int ob = (b['order_index'] as num?)?.toInt() ?? 0;
      return oa.compareTo(ob);
    });

    debugPrint('fetchExerciseSetsDirect: ${out.length} sets');
    return out;
  } catch (e) {
    debugPrint('fetchExerciseSetsDirect FAILED: $e');
    return [];
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
