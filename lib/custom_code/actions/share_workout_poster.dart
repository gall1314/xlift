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
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Captures the current page as a PNG (3x), crops [cropBottom] logical px
/// off the bottom (buttons) and [cropTop] off the top, then opens the
/// native share sheet with the image.
///
/// Returns true if the sheet was opened, false on any failure. Never throws.
Future<bool> shareWorkoutPoster(
  BuildContext context,
  double? cropBottom,
  double? cropTop,
  String? shareText,
) async {
  try {
    // Every Navigator route is wrapped in a RepaintBoundary - grab it.
    final RenderRepaintBoundary? boundary =
        context.findAncestorRenderObjectOfType<RenderRepaintBoundary>();
    if (boundary == null) return false;

    const double ratio = 3.0;
    final ui.Image full = await boundary.toImage(pixelRatio: ratio);

    // Crop in physical pixels.
    final double fullH = full.height.toDouble();
    final double fullW = full.width.toDouble();
    final double top =
        ((cropTop ?? 0) * ratio).clamp(0.0, fullH - 1).toDouble();
    final double bottom =
        ((cropBottom ?? 0) * ratio).clamp(0.0, fullH - 1).toDouble();
    final double h = (fullH - top - bottom).clamp(1.0, fullH).toDouble();

    final ui.PictureRecorder rec = ui.PictureRecorder();
    final Canvas canvas = Canvas(rec);
    canvas.drawImageRect(
      full,
      Rect.fromLTWH(0, top, fullW, h),
      Rect.fromLTWH(0, 0, fullW, h),
      Paint(),
    );
    final ui.Image cropped =
        await rec.endRecording().toImage(full.width, h.toInt());
    full.dispose();

    final ByteData? bytes =
        await cropped.toByteData(format: ui.ImageByteFormat.png);
    cropped.dispose();
    if (bytes == null) return false;

    final Directory dir = await getTemporaryDirectory();
    final File file = File(
        '${dir.path}/xlift_workout_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes.buffer.asUint8List());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: (shareText ?? '').trim().isEmpty ? null : shareText,
      sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
    );
    return true;
  } catch (e) {
    print('[sharePoster] failed: $e');
    return false;
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
