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

/// Force-releases any held DB handles by cycling the connection.

import 'dart:async';

/// Cycles the DB connection - but NEVER hangs: if close() itself blocks
/// (connection held by a stuck query), gives up after 3s and reports it.
///
/// Returns a short status string for the console/debug.
Future<String> resetDbConnection() async {
  const Duration limit = Duration(seconds: 3);
  try {
    print('[resetDb] closing...');
    await SQLiteManager.instance.database.close().timeout(limit, onTimeout: () {
      throw TimeoutException('close() blocked for ${limit.inSeconds}s');
    });
    print('[resetDb] closed, reopening...');
    await SQLiteManager.initialize().timeout(limit, onTimeout: () {
      throw TimeoutException('initialize() blocked for ${limit.inSeconds}s');
    });
    print('[resetDb] reopened OK');
    return 'ok';
  } catch (e) {
    print('[resetDb] FAILED: $e');
    return 'failed: $e';
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
