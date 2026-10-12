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

/// Tappable rest-time label ("02:00" / "Off").
///
/// Text is produced by the existing custom function
/// formatExerciseRestTime(exerciseRestTimes, exerciseId) — same ms → mm:ss
/// logic, same "Off" for 0, same 1:30 default — so it matches the old Text
/// exactly. Replaces ONLY the time text; the icon, "Rest:" and chevron stay
/// as they are in FF.
///
/// Press feedback: fade to ~40% + slight shrink while pressed. [onTap]
/// fires on release (tap or long-press).
class RestTimeButton extends StatefulWidget {
  const RestTimeButton({
    super.key,
    this.width,
    this.height,
    required this.exerciseRestTimes,
    required this.exerciseId,
    this.textColor,
    this.fontSize,
    this.onTap,
  });

  final double? width;
  final double? height;
  final dynamic exerciseRestTimes;
  final int exerciseId;
  final Color? textColor;
  final double? fontSize;
  final Future Function()? onTap;

  @override
  State<RestTimeButton> createState() => _RestTimeButtonState();
}

class _RestTimeButtonState extends State<RestTimeButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  String get _label {
    try {
      return formatExerciseRestTime(
          widget.exerciseRestTimes, widget.exerciseId);
    } catch (_) {
      return '01:30';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final TextStyle style = theme.bodyLarge.override(
      fontFamily: theme.bodyLargeFamily,
      color: widget.textColor ?? theme.primary,
      fontSize: widget.fontSize ?? 18,
      fontWeight: FontWeight.w500,
      useGoogleFonts: GoogleFonts.asMap().containsKey(theme.bodyLargeFamily),
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
      onLongPressStart: (_) => _setPressed(true),
      onLongPressEnd: (_) {
        _setPressed(false);
        HapticFeedback.selectionClick();
        widget.onTap?.call();
      },
      onLongPressCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.4 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Text(
              _label,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ),
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
