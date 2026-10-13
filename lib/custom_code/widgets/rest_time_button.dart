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

/// Rest-time button: a rounded, lightly tinted box holding [timer icon] Rest:
/// 02:00  [chevron].
///
/// The whole box is the tap target (min 44pt tall).
///
/// Time text comes from the existing custom function
/// formatExerciseRestTime(exerciseRestTimes, exerciseId) — same ms → mm:ss
/// logic, same "Off" for 0, same 1:30 default.
///
/// Press feedback: background darkens + slight shrink. [onTap] fires on
/// release (tap or long-press).
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

  void _fire() {
    _setPressed(false);
    HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final Color color = widget.textColor ?? theme.primary;
    final double fs = widget.fontSize ?? 17;

    TextStyle textStyle(FontWeight w) => theme.bodyLarge.override(
          fontFamily: theme.bodyLargeFamily,
          color: color,
          fontSize: fs,
          fontWeight: w,
          useGoogleFonts:
              GoogleFonts.asMap().containsKey(theme.bodyLargeFamily),
        );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.timer_outlined, size: fs + 4, color: color),
        SizedBox(width: fs * 0.45),
        Text('Rest:', style: textStyle(FontWeight.w400)),
        SizedBox(width: fs * 0.5),
        Text(
          _label,
          style: textStyle(FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.clip,
        ),
        SizedBox(width: fs * 0.2),
        Icon(Icons.keyboard_arrow_down_rounded, size: fs + 4, color: color),
      ],
    );

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      constraints: BoxConstraints(minHeight: widget.height ?? 44),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: color.withOpacity(_pressed ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );

    return Semantics(
      button: true,
      label: 'Rest time $_label',
      child: Align(
        alignment: Alignment.centerLeft,
        widthFactor: widget.width == null ? 1 : null,
        heightFactor: 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _fire(),
          onLongPressStart: (_) => _setPressed(true),
          onLongPressEnd: (_) => _fire(),
          onLongPressCancel: () => _setPressed(false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: button,
          ),
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
