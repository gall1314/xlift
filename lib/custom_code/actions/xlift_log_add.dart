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

import 'package:flutter/foundation.dart';

/// Global in-app log store (top-level - FF-action friendly).
/// Widgets/actions import this file and use xliftLogLines / xliftLogAdd.
final ValueNotifier<List<String>> xliftLogLines =
    ValueNotifier<List<String>>([]);

Future<void> xliftLogAdd(String msg) async {
  final String ts = DateTime.now().toIso8601String().substring(11, 23);
  final String line = '$ts  $msg';
  debugPrint(line); // still goes to the real console
  final List<String> next = List<String>.from(xliftLogLines.value);
  next.add(line);
  if (next.length > 300) {
    next.removeRange(0, next.length - 300);
  }
  xliftLogLines.value = next;
}

Future<void> xliftLogClear() async {
  xliftLogLines.value = [];
}

/// FlutterFlow-callable: log a line from action flows.
Future appLog(String message) async {
  await xliftLogAdd(message);
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
