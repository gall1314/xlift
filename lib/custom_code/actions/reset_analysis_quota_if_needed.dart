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

import '/app_state.dart';

Future<int> resetAnalysisQuotaIfNeeded() async {
  // Current calendar month in device-local time, e.g. "2026-07".
  final now = DateTime.now();
  final currentMonth =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

  // New month (or first run) → reset the quota.
  if (FFAppState().analysisCountMonth != currentMonth) {
    FFAppState().analysisCountMonth = currentMonth;
    FFAppState().analysisCount = 0;
  }

  // Return the up-to-date count: 0 after a reset, current value otherwise.
  return FFAppState().analysisCount;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
