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

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> pickAndSaveProfilePhoto() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 512,
    maxHeight: 512,
    imageQuality: 80, // ההמרה לקובץ קטן (~30-60KB JPEG)
  );
  if (picked == null) return null;

  final docs = await getApplicationDocumentsDirectory();

  // ניקוי תמונה ישנה כדי שלא יצטברו קבצים
  for (final e in docs.listSync()) {
    if (e is File &&
        e.path.split(Platform.pathSeparator).last.startsWith('profile_')) {
      try {
        await e.delete();
      } catch (_) {}
    }
  }

  final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
  await File(picked.path).copy('${docs.path}/$fileName');
  return fileName; // זה מה שנשמר ב-App State
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
