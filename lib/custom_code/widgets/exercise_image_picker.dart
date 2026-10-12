// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Round image picker for the Create / Edit Exercise screen.
///
/// Empty  -> camera icon + "Add Asset". Tap -> sheet: Take photo / Choose
///           from gallery.
/// Picked -> shows the image; tap again to replace; small "x" to remove.
/// [existingIllustration] - file name of an already-saved custom image
///           (Documents/exercise_images/<name>) for the Edit flow.
///
/// Every change calls [onImagePicked] with the FFUploadedFile (or null when
/// the user removed the image). Store it in Page State and pass it to
/// saveCustomExerciseImage after the exercise row is created.
class ExerciseImagePicker extends StatefulWidget {
  const ExerciseImagePicker({
    super.key,
    this.width,
    this.height,
    this.size = 180,
    this.existingIllustration,
    this.accentColor,
    this.label,
    this.onImagePicked,
  });

  final double? width;
  final double? height;
  final double size;
  final String? existingIllustration;
  final Color? accentColor;
  final String? label;
  final Future Function(FFUploadedFile? image)? onImagePicked;

  @override
  State<ExerciseImagePicker> createState() => _ExerciseImagePickerState();
}

class _ExerciseImagePickerState extends State<ExerciseImagePicker> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _bytes; // currently shown image (picked or existing)
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final String? name = widget.existingIllustration?.trim();
    if (name == null || name.isEmpty || name.contains('/')) return;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final f = File(p.join(docs.path, 'exercise_images', name));
      if (f.existsSync()) {
        final b = await f.readAsBytes();
        if (mounted) setState(() => _bytes = b);
      }
    } catch (_) {}
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final XFile? x = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (x == null) return; // cancelled
      final Uint8List b = await x.readAsBytes();
      if (!mounted) return;
      setState(() => _bytes = b);
      HapticFeedback.selectionClick();
      final String ext = x.path.contains('.')
          ? x.path.substring(x.path.lastIndexOf('.'))
          : '.jpg';
      await widget.onImagePicked?.call(FFUploadedFile(
        name: 'exercise_${DateTime.now().millisecondsSinceEpoch}$ext',
        bytes: b,
      ));
    } catch (e) {
      debugPrint('ExerciseImagePicker pick failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    HapticFeedback.selectionClick();
    setState(() => _bytes = null);
    await widget.onImagePicked?.call(null);
  }

  void _openSheet() {
    final theme = FlutterFlowTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _sheetRow(Icons.photo_camera_rounded, 'Take photo', () {
                Navigator.of(context).pop();
                _pick(ImageSource.camera);
              }),
              Divider(height: 1, color: theme.alternate),
              _sheetRow(Icons.photo_library_rounded, 'Choose from gallery', () {
                Navigator.of(context).pop();
                _pick(ImageSource.gallery);
              }),
              if (_bytes != null) ...[
                Divider(height: 1, color: theme.alternate),
                _sheetRow(Icons.delete_outline_rounded, 'Remove photo', () {
                  Navigator.of(context).pop();
                  _remove();
                }, danger: true),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetRow(IconData icon, String text, VoidCallback onTap,
      {bool danger = false}) {
    final theme = FlutterFlowTheme.of(context);
    final Color c = danger ? const Color(0xFFE5484D) : theme.primaryText;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(width: 14),
            Text(text,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500, color: c)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final Color accent = widget.accentColor ?? theme.primary;
    final double s = widget.size;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _busy ? null : _openSheet,
                child: Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primaryBackground,
                    border: Border.all(
                        color: _bytes == null ? theme.alternate : accent,
                        width: _bytes == null ? 1 : 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _busy
                      ? Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: accent),
                          ),
                        )
                      : (_bytes != null
                          ? Image.memory(_bytes!, fit: BoxFit.cover)
                          : Icon(Icons.photo_camera_rounded,
                              size: s * 0.28, color: theme.secondaryText)),
                ),
              ),
              if (_bytes != null && !_busy)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: _remove,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.secondaryBackground,
                        border: Border.all(color: theme.alternate),
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 16, color: theme.primaryText),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _busy ? null : _openSheet,
            child: Text(
              widget.label ?? (_bytes == null ? 'Add Asset' : 'Change photo'),
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500, color: accent),
            ),
          ),
        ],
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
