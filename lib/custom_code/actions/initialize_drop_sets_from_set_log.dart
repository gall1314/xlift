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

List<dynamic> initializeDropSetsFromSetLog(
  List<GetAllSetsRow>? setLogRows,
) {
  try {
    if (setLogRows == null || setLogRows.isEmpty) {
      return <dynamic>[];
    }

    final List<Map<String, dynamic>> drops = [];

    for (final row in setLogRows) {
      try {
        // ❗ רק דרורפסטים
        final isDrop = (row.isDropset ?? 0) == 1;
        if (!isDrop) continue;

        final exerciseId = row.exerciseId;
        final parentSetNumber = row.setNumber;

        if (exerciseId == null || parentSetNumber == null) continue;

        final weight =
            (row.weight is num) ? (row.weight as num).toDouble() : null;

        drops.add({
          'exerciseId': exerciseId,
          'parentSetNumber': parentSetNumber,
          'dropOrder': row.dropNumber ?? 1,
          'reps': row.reps,
          'weight': weight,
          'percentFromParent': null,
          'locked': false,
        });
      } catch (_) {}
    }

    // ---------- SO3RT ----------
    drops.sort((a, b) {
      final exCmp = (a['exerciseId'] ?? 0).compareTo(b['exerciseId'] ?? 0);
      if (exCmp != 0) return exCmp;

      final setCmp =
          (a['parentSetNumber'] ?? 0).compareTo(b['parentSetNumber'] ?? 0);
      if (setCmp != 0) return setCmp;

      return (a['dropOrder'] ?? 0).compareTo(b['dropOrder'] ?? 0);
    });

    return drops;
  } catch (_) {
    return <dynamic>[];
  }
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
