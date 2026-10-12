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
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Shows a Camera / Gallery sheet, picks a photo, downscales it to 512px
/// JPEG, saves it under Documents as profile_<ts>.jpg (deleting older
/// profile_* files) and returns the bare file name for App State.
/// Returns null if the user cancels.
Future<String?> pickAndSaveProfilePhoto(BuildContext context) async {
  final th = FlutterFlowTheme.of(context);

  Widget row(IconData icon, String label, ImageSource src) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop(src);
      },
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: 24),
            Icon(icon, size: 24, color: th.primary),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: th.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  final ImageSource? source = await showModalBottomSheet<ImageSource>(
    context: context,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final double inset = MediaQuery.of(ctx).padding.bottom;
      return Container(
        padding: EdgeInsets.only(bottom: inset > 0 ? inset - 4 : 8),
        decoration: BoxDecoration(
          color: th.secondaryBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: th.alternate,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Profile photo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: th.primaryText,
              ),
            ),
            const SizedBox(height: 10),
            row(Icons.photo_camera_outlined, 'Take a photo',
                ImageSource.camera),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Divider(height: 1, color: th.alternate),
            ),
            row(Icons.photo_library_outlined, 'Choose from gallery',
                ImageSource.gallery),
          ],
        ),
      );
    },
  );
  if (source == null) return null;

  final XFile? picked;
  try {
    picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
      preferredCameraDevice: CameraDevice.front,
    );
  } catch (_) {
    return null; // permission denied / camera unavailable
  }
  if (picked == null) return null;

  final docs = await getApplicationDocumentsDirectory();

  // Remove previous profile photos so files don't pile up.
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
  return fileName; // bare name -> App State
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
