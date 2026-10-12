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

import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tappable exercise header: illustration (45x45, radius 8) + name.
///
/// Pass the DISPLAY name ("Box Squat"); the widget calls exerciseImageName()
/// itself to resolve the asset. [illustration] = bare file name for custom
/// exercises (same as ExerciseAssetImage), empty for catalog.
///
/// Press feedback: while the finger is down (tap or long-press) the image and
/// text fade to ~40% and shrink slightly, then spring back. [onTap] fires on
/// release.
class ExerciseHeaderButton extends StatefulWidget {
  const ExerciseHeaderButton({
    super.key,
    this.width,
    this.height,
    required this.exerciseName,
    this.illustration,
    this.imageSize = 45,
    this.imageRadius = 8,
    this.gap = 12,
    this.textColor,
    this.fontSize,
    this.maxLines = 2,
    this.onTap,
  });

  final double? width;
  final double? height;
  final String exerciseName;
  final String? illustration;
  final double imageSize;
  final double imageRadius;
  final double gap;
  final Color? textColor;
  final double? fontSize;
  final int maxLines;
  final Future Function()? onTap;

  @override
  State<ExerciseHeaderButton> createState() => _ExerciseHeaderButtonState();
}

class _ExerciseHeaderButtonState extends State<ExerciseHeaderButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final TextStyle style = theme.titleMedium.override(
      fontFamily: theme.titleMediumFamily,
      color: widget.textColor ?? theme.primaryText,
      fontSize: widget.fontSize ?? 20,
      fontWeight: FontWeight.w600,
      useGoogleFonts: GoogleFonts.asMap().containsKey(theme.titleMediumFamily),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) {
        _setPressed(false);
        HapticFeedback.selectionClick();
        widget.onTap?.call();
      },
      // Long press: keep the dimmed state until release, then fire too.
      onLongPressStart: (_) => _setPressed(true),
      onLongPressEnd: (_) {
        _setPressed(false);
        HapticFeedback.selectionClick();
        widget.onTap?.call();
      },
      onLongPressCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.4 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ExerciseAssetImage(
                  width: widget.imageSize,
                  height: widget.imageSize,
                  exerciseName: exerciseImageName(widget.exerciseName),
                  borderRadius: widget.imageRadius,
                  illustration: widget.illustration,
                ),
                SizedBox(width: widget.gap),
                Flexible(
                  child: Text(
                    widget.exerciseName,
                    style: style,
                    maxLines: widget.maxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
