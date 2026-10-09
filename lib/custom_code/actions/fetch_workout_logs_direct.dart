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

import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';

/// Fetches all workout_log rows for a user directly from Supabase,
/// bypassing FlutterFlow's generated schema. Flat JSON list;
/// empty list on any failure.
Future<List<dynamic>> fetchWorkoutLogsDirect(String userId) async {
  try {
    final rows = await SupaFlow.client
        .from('workout_log')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return List<dynamic>.from(rows);
  } catch (e) {
    debugPrint('fetchWorkoutLogsDirect failed: $e');
    return [];
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
