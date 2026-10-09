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
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Warm up ML Kit's pose detector so that the first real video analysis
/// doesn't get stuck on initialization.
///
/// The problem this solves: when the app launches, ML Kit's pose detector
/// hasn't loaded its model into memory yet. The first time we create a
/// PoseDetector and call processImage, several things happen asynchronously —
/// model download/load, GPU context creation, native library initialization.
/// If a real video analysis is the first thing that uses pose detection,
/// those initializations race against the frame processing loop, and the loop
/// can get stuck waiting for a resource that's still loading. The user sees a
/// frozen skeleton.
///
/// What this action does: creates a PoseDetector, runs it on a tiny dummy
/// image, then closes it. By the time this returns, the model is cached in
/// memory and the GPU context is created. Every subsequent PoseDetector
/// instance (created in the squat/pushup/pullup analyzers) reuses those
/// cached resources and starts cleanly.
///
/// Usage: add this as an action on your home page's On Page Load trigger. It
/// takes about 200-500ms on first run, near-instant on subsequent runs.
/// Errors are swallowed silently — if warm-up fails, the analyzers will still
/// work (just possibly with the original freeze risk on the first run).
Future warmupMLKit() async {
  try {
    // Create a tiny dummy JPEG: 64x64 black image. ML Kit will return
    // an empty pose list (no person), but it doesn't matter — we just
    // need the model loaded and the native code path warmed up.
    //
    // We write the file to the temp directory because InputImage on
    // iOS/Android wants a real path on disk, not just bytes in memory.
    final Directory tmp = await getTemporaryDirectory();
    final String dummyPath = p.join(
        tmp.path, 'mlkit_warmup_${DateTime.now().millisecondsSinceEpoch}.jpg');

    // Minimal valid 64x64 black JPEG. Hand-crafted bytes — small enough
    // that we don't depend on any image-creation library to be present.
    // (Generated once with `convert -size 64x64 xc:black tiny.jpg` and
    // copied as raw bytes here.)
    final Uint8List dummyJpeg = Uint8List.fromList([
      0xFF,
      0xD8,
      0xFF,
      0xE0,
      0x00,
      0x10,
      0x4A,
      0x46,
      0x49,
      0x46,
      0x00,
      0x01,
      0x01,
      0x00,
      0x00,
      0x01,
      0x00,
      0x01,
      0x00,
      0x00,
      0xFF,
      0xDB,
      0x00,
      0x43,
      0x00,
      0x08,
      0x06,
      0x06,
      0x07,
      0x06,
      0x05,
      0x08,
      0x07,
      0x07,
      0x07,
      0x09,
      0x09,
      0x08,
      0x0A,
      0x0C,
      0x14,
      0x0D,
      0x0C,
      0x0B,
      0x0B,
      0x0C,
      0x19,
      0x12,
      0x13,
      0x0F,
      0x14,
      0x1D,
      0x1A,
      0x1F,
      0x1E,
      0x1D,
      0x1A,
      0x1C,
      0x1C,
      0x20,
      0x24,
      0x2E,
      0x27,
      0x20,
      0x22,
      0x2C,
      0x23,
      0x1C,
      0x1C,
      0x28,
      0x37,
      0x29,
      0x2C,
      0x30,
      0x31,
      0x34,
      0x34,
      0x34,
      0x1F,
      0x27,
      0x39,
      0x3D,
      0x38,
      0x32,
      0x3C,
      0x2E,
      0x33,
      0x34,
      0x32,
      0xFF,
      0xC0,
      0x00,
      0x0B,
      0x08,
      0x00,
      0x40,
      0x00,
      0x40,
      0x01,
      0x01,
      0x11,
      0x00,
      0xFF,
      0xC4,
      0x00,
      0x1F,
      0x00,
      0x00,
      0x01,
      0x05,
      0x01,
      0x01,
      0x01,
      0x01,
      0x01,
      0x01,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x01,
      0x02,
      0x03,
      0x04,
      0x05,
      0x06,
      0x07,
      0x08,
      0x09,
      0x0A,
      0x0B,
      0xFF,
      0xC4,
      0x00,
      0xB5,
      0x10,
      0x00,
      0x02,
      0x01,
      0x03,
      0x03,
      0x02,
      0x04,
      0x03,
      0x05,
      0x05,
      0x04,
      0x04,
      0x00,
      0x00,
      0x01,
      0x7D,
      0x01,
      0x02,
      0x03,
      0x00,
      0x04,
      0x11,
      0x05,
      0x12,
      0x21,
      0x31,
      0x41,
      0x06,
      0x13,
      0x51,
      0x61,
      0x07,
      0x22,
      0x71,
      0x14,
      0x32,
      0x81,
      0x91,
      0xA1,
      0x08,
      0x23,
      0x42,
      0xB1,
      0xC1,
      0x15,
      0x52,
      0xD1,
      0xF0,
      0x24,
      0x33,
      0x62,
      0x72,
      0x82,
      0x09,
      0x0A,
      0x16,
      0x17,
      0x18,
      0x19,
      0x1A,
      0x25,
      0x26,
      0x27,
      0x28,
      0x29,
      0x2A,
      0x34,
      0x35,
      0x36,
      0x37,
      0x38,
      0x39,
      0x3A,
      0x43,
      0x44,
      0x45,
      0x46,
      0x47,
      0x48,
      0x49,
      0x4A,
      0x53,
      0x54,
      0x55,
      0x56,
      0x57,
      0x58,
      0x59,
      0x5A,
      0x63,
      0x64,
      0x65,
      0x66,
      0x67,
      0x68,
      0x69,
      0x6A,
      0x73,
      0x74,
      0x75,
      0x76,
      0x77,
      0x78,
      0x79,
      0x7A,
      0x83,
      0x84,
      0x85,
      0x86,
      0x87,
      0x88,
      0x89,
      0x8A,
      0x92,
      0x93,
      0x94,
      0x95,
      0x96,
      0x97,
      0x98,
      0x99,
      0x9A,
      0xA2,
      0xA3,
      0xA4,
      0xA5,
      0xA6,
      0xA7,
      0xA8,
      0xA9,
      0xAA,
      0xB2,
      0xB3,
      0xB4,
      0xB5,
      0xB6,
      0xB7,
      0xB8,
      0xB9,
      0xBA,
      0xC2,
      0xC3,
      0xC4,
      0xC5,
      0xC6,
      0xC7,
      0xC8,
      0xC9,
      0xCA,
      0xD2,
      0xD3,
      0xD4,
      0xD5,
      0xD6,
      0xD7,
      0xD8,
      0xD9,
      0xDA,
      0xE1,
      0xE2,
      0xE3,
      0xE4,
      0xE5,
      0xE6,
      0xE7,
      0xE8,
      0xE9,
      0xEA,
      0xF1,
      0xF2,
      0xF3,
      0xF4,
      0xF5,
      0xF6,
      0xF7,
      0xF8,
      0xF9,
      0xFA,
      0xFF,
      0xDA,
      0x00,
      0x08,
      0x01,
      0x01,
      0x00,
      0x00,
      0x3F,
      0x00,
      0xFB,
      0xD0,
      0x07,
      0xFF,
      0xD9,
    ]);

    await File(dummyPath).writeAsBytes(dummyJpeg, flush: true);

    // Run the same detector configuration the real analyzers use, so
    // we warm up the right code path. Mode and model must match.
    final detector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.accurate,
      ),
    );

    try {
      final inputImage = InputImage.fromFilePath(dummyPath);
      // We don't care about the result. The fact that this completes is
      // enough — by the time it returns, the model is loaded in memory
      // and GPU/native resources are initialized.
      await detector.processImage(inputImage);
    } finally {
      await detector.close();
      try {
        await File(dummyPath).delete();
      } catch (_) {}
    }
  } catch (_) {
    // Swallow errors silently. Worst case the user gets the original
    // first-run freeze risk. We don't want a warm-up failure to crash
    // the app or block the home page from loading.
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
