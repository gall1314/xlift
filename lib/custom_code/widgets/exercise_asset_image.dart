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

class ExerciseAssetImage extends StatefulWidget {
  const ExerciseAssetImage({
    super.key,
    required this.width,
    required this.height,
    required this.exerciseName,
    this.borderRadius,
    this.fallbackAsset,
    this.opacity,
  });

  final double width;
  final double height;
  final String exerciseName;
  final double? borderRadius;
  final String? fallbackAsset;
  final double? opacity;

  @override
  State<ExerciseAssetImage> createState() => _ExerciseAssetImageState();
}

class _ExerciseAssetImageState extends State<ExerciseAssetImage> {
  @override
  Widget build(BuildContext context) {
    final double op = (widget.opacity ?? 1.0).clamp(0.0, 1.0);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 0),
        child: Opacity(
          opacity: op,
          child: Image.asset(
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
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey,
                  ),
                );
              }
              return Icon(
                Icons.image_not_supported,
                size: 48,
                color: Colors.grey,
              );
            },
          ),
        ),
      ),
    );
  }
}
