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
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';

/// Saves an analyzed squat video to the device gallery / Photos.
///
/// Input: videoPath: Either a raw filesystem path
/// ("/data/.../squat_in_*.mp4") or a file:// URI
/// ("file:///data/.../squat_in_*.mp4"). This matches what
/// analyzeSquatVideoAction returns in its 'video_path' / '_source_video_uri'
/// fields.
///
/// Returns: true  → video saved successfully and is visible in the gallery.
/// false → something failed. Reason is logged via debugPrint with a tag of
/// [saveVideoToGallery] so you can find it in the device logs.
///
/// Why this exists instead of the built-in FlutterFlow "Save File" action:
/// The built-in action expects an http(s) URL or an FFUploadedFile in memory.
/// The analyzer hands back a path to a local temp file (because the analysis
/// pipeline already wrote the upload to disk). The built-in action sees the
/// file:// URI and silently does nothing useful. This action handles the
/// local-file case directly.
///
/// Setup needed in your project (once): 1. Add to pubspec.yaml under
/// dependencies: gal: ^2.3.0 (In FlutterFlow: Settings → App Settings → Pub
/// Dependencies.)
///
/// 2. iOS — add to ios/Runner/Info.plist (inside the top <dict>):
/// <key>NSPhotoLibraryAddUsageDescription</key> <string>We need access to
/// save your analyzed squat video.</string> In FlutterFlow: Settings → iOS →
/// Info.plist Permissions → "Photo Library Additions" with a description
/// string.
///
/// 3. Android — for Android 9 (API 28) and below, add to
/// android/app/src/main/AndroidManifest.xml inside <manifest>:
/// <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
/// android:maxSdkVersion="28" /> Android 10+ doesn't need any permission for
/// gal.putVideo since it uses MediaStore under the hood. FlutterFlow's
/// default Android manifest already includes WRITE_EXTERNAL_STORAGE for older
/// devices, so this is usually a no-op.
Future<bool> saveVideoToGallery(String videoPath) async {
  if (videoPath.isEmpty) {
    debugPrint('[saveVideoToGallery] empty videoPath');
    return false;
  }

  // Strip a file:// prefix if the caller passed a URI rather than a
  // raw path. The analyzer returns file:// URIs (search the analyzer
  // for `'video_path': fileUri`), so this is the common case.
  String cleanPath = videoPath.trim();
  if (cleanPath.startsWith('file://')) {
    cleanPath = cleanPath.substring('file://'.length);
  }

  // Sanity check: the file must actually exist on disk. If the temp
  // directory was cleaned up between the analysis and this call, we'd
  // get a confusing gal error otherwise.
  final File file = File(cleanPath);
  if (!await file.exists()) {
    debugPrint('[saveVideoToGallery] file does not exist at: $cleanPath');
    return false;
  }

  try {
    // Permission flow:
    //   - On iOS we need "Add to Photo Library" permission. gal asks
    //     the user the first time and remembers the answer.
    //   - On Android 10+ no runtime permission is needed for inserting
    //     into MediaStore via gal. On older Android, gal handles the
    //     WRITE_EXTERNAL_STORAGE prompt.
    //
    // toAlbum: true tells gal we want to check/request the album-write
    // capability specifically, which is what putVideo needs.
    final bool hasAccess = await Gal.hasAccess(toAlbum: true);
    if (!hasAccess) {
      final bool granted = await Gal.requestAccess(toAlbum: true);
      if (!granted) {
        debugPrint('[saveVideoToGallery] user denied gallery access');
        return false;
      }
    }

    // Save the video. Passing an album name makes it land in a
    // dedicated folder ("Squat Analyzer" by default) on platforms that
    // support albums — iOS creates a Photos album, Android creates a
    // folder under DCIM. Change the album name to whatever fits your
    // app's branding.
    await Gal.putVideo(cleanPath, album: 'Squat Analyzer');

    debugPrint('[saveVideoToGallery] saved OK: $cleanPath');
    return true;
  } on GalException catch (e) {
    // gal's typed errors. The common ones are:
    //   - GalExceptionType.accessDenied → user said no to permission
    //   - GalExceptionType.notEnoughSpace → disk full
    //   - GalExceptionType.notSupportedFormat → file isn't a valid video
    //   - GalExceptionType.unexpected → anything else
    // Note: gal's GalException doesn't expose a stable `error` getter
    // across versions, so we just print the type and let toString
    // give us the full message.
    debugPrint('[saveVideoToGallery] GalException: ${e.type} – $e');
    return false;
  } catch (e, st) {
    debugPrint('[saveVideoToGallery] unexpected error: $e\n$st');
    return false;
  }
}
