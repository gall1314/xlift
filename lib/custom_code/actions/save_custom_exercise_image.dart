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
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Saves a user-picked image as the illustration of a custom exercise,
/// LOCALLY ONLY (Documents/exercise_images/custom_<id>.jpg), downscaled to
/// max 600px. Returns the FILE NAME to store in exercise.illustration -
/// never the full path (the iOS container path changes on app update).
/// Returns '' on failure. Never throws.
Future<String> saveCustomExerciseImage(
  FFUploadedFile? image,
  int? exerciseId,
) async {
  try {
    if (image == null || image.bytes == null || image.bytes!.isEmpty) {
      return '';
    }
    if (exerciseId == null) return '';

    // Decode + downscale (max 600px on the long side).
    final codec = await ui.instantiateImageCodec(
      image.bytes!,
      targetWidth: 600,
    );
    final frame = await codec.getNextFrame();
    final ui.Image img = frame.image;
    final ByteData? png = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    if (png == null) return '';

    final Directory docs = await getApplicationDocumentsDirectory();
    final Directory dir = Directory(p.join(docs.path, 'exercise_images'));
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final String fileName = 'custom_$exerciseId.png';
    final File out = File(p.join(dir.path, fileName));
    await out.writeAsBytes(png.buffer.asUint8List(), flush: true);
    return fileName;
  } catch (e) {
    debugPrint('saveCustomExerciseImage failed: $e');
    return '';
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
