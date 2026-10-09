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

import 'dart:math';

String generateUuidV4() {
  final rnd = Random.secure();

  String fourHex() => rnd.nextInt(1 << 16).toRadixString(16).padLeft(4, '0');

  // בהתאם לתקן UUID v4 (עם ביטי גרסה ו-variant)
  final part1 = '${fourHex()}${fourHex()}';
  final part2 = fourHex();
  final part3 = ((rnd.nextInt(1 << 16) & 0x0fff) | 0x4000)
      .toRadixString(16)
      .padLeft(4, '0');
  final part4 = ((rnd.nextInt(1 << 16) & 0x3fff) | 0x8000)
      .toRadixString(16)
      .padLeft(4, '0');
  final part5 = '${fourHex()}${fourHex()}${fourHex()}';

  return '$part1-$part2-$part3-$part4-$part5';
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
