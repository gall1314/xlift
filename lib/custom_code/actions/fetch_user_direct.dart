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

/// Fetches the user's row directly from Supabase, bypassing
/// FlutterFlow's generated schema. Returns the row as JSON,
/// or null if not found / any failure.
Future<dynamic> fetchUserDirect(String userId) async {
  try {
    final row = await SupaFlow.client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return row; // Map with all columns, or null if no row.
  } catch (e) {
    debugPrint('fetchUserDirect failed: $e');
    return null;
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
