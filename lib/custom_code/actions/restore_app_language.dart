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

/// Re-applies the language the user chose last time. Run as an Initial
/// Action on the first page; harmless when nothing is stored.
Future restoreAppLanguage(BuildContext context) async {
  try {
    final stored = FFLocalizations.getStoredLocale();
    if (stored == null) return;
    final code = stored.languageCode.trim().toLowerCase();
    if (code.isEmpty) return;
    final current =
        FFLocalizations.of(context).languageCode.trim().toLowerCase();
    if (code == current) return;
    setAppLanguage(context, code);
  } catch (_) {}
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
