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
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Exercise illustration - catalog AND user-created exercises.
///
/// Catalog (unchanged): assets/images/<exerciseName>.jpg Custom:
/// [illustration] = a bare file name written by saveCustomExerciseImage (e.g.
/// "custom_42.png"), stored under Documents/exercise_images. If that file
/// exists it is shown; otherwise the widget behaves exactly as before (asset
/// -> fallbackAsset -> icon). Leave [illustration] empty for catalog
/// exercises.
class ExerciseAssetImage extends StatefulWidget {
  const ExerciseAssetImage({
    super.key,
    required this.width,
    required this.height,
    required this.exerciseName,
    this.borderRadius,
    this.fallbackAsset,
    this.opacity,
    this.illustration,
  });

  final double width;
  final double height;
  final String exerciseName;
  final double? borderRadius;
  final String? fallbackAsset;
  final double? opacity;
  final String? illustration;

  @override
  State<ExerciseAssetImage> createState() => _ExerciseAssetImageState();
}

class _ExerciseAssetImageState extends State<ExerciseAssetImage> {
  static Directory? _docs; // resolved once per app run
  File? _customFile;

  @override
  void initState() {
    super.initState();
    _resolveCustom();
  }

  @override
  void didUpdateWidget(covariant ExerciseAssetImage old) {
    super.didUpdateWidget(old);
    if (old.illustration != widget.illustration) _resolveCustom();
  }

  Future<void> _resolveCustom() async {
    final String? name = widget.illustration?.trim();
    File? f;
    // Only a bare file name we wrote ourselves counts as a local image.
    if (name != null &&
        name.isNotEmpty &&
        !name.contains('/') &&
        !name.startsWith('http')) {
      try {
        _docs ??= await getApplicationDocumentsDirectory();
        final c = File(p.join(_docs!.path, 'exercise_images', name));
        if (c.existsSync()) f = c;
      } catch (_) {}
    }
    if (mounted && f?.path != _customFile?.path) {
      setState(() => _customFile = f);
    }
  }

  Widget _icon() =>
      const Icon(Icons.image_not_supported, size: 48, color: Colors.grey);

  Widget _assetImage() {
    return Image.asset(
      'assets/images/${widget.exerciseName}.jpg',
      width: widget.width,
      height: widget.height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        if (widget.fallbackAsset != null) {
          return Image.asset(
            widget.fallbackAsset!,
            width: widget.width,
            height: widget.height,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _icon(),
          );
        }
        return _icon();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double op = (widget.opacity ?? 1.0).clamp(0.0, 1.0);

    final Widget image = _customFile != null
        ? Image.file(
            _customFile!,
            width: widget.width,
            height: widget.height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _assetImage(),
          )
        : _assetImage();

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 0),
        child: Opacity(opacity: op, child: image),
      ),
    );
  }
}
