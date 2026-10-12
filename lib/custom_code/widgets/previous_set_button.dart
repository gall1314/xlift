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

/// Tappable "previous set" label ("120 kg × 10").
///
/// Press feedback: while the finger is down the text fades to ~40% and
/// shrinks slightly. [onTap] fires on release (tap or long-press). Empty
/// [text] renders nothing.
///
/// Done detection: [loggedSets] (the page-state list of logged sets) is
/// scanned for an entry whose exercise id == [exerciseId] and set number ==
/// [setNumber]. If found → plain text, not tappable, no animation. Accepts
/// entries as Map or any object exposing toMap(); keys tried: exercise_id /
/// exerciseId, set_number / setNumber.
///
/// [fontWeight]: 100–900 (400 normal, 500 medium, 600 semibold, 700 bold).
/// Default 500.
class PreviousSetButton extends StatefulWidget {
  const PreviousSetButton({
    super.key,
    this.width,
    this.height,
    required this.text,
    this.loggedSets,
    this.exerciseId,
    this.setNumber,
    this.textColor,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.onTap,
  });

  final double? width;
  final double? height;
  final String text;
  final List<dynamic>? loggedSets;
  final int? exerciseId;
  final int? setNumber;
  final Color? textColor;
  final double? fontSize;
  final int? fontWeight;
  final String? textAlign; // 'left' | 'center' | 'right' (default center)
  final Future Function()? onTap;

  @override
  State<PreviousSetButton> createState() => _PreviousSetButtonState();
}

class _PreviousSetButtonState extends State<PreviousSetButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  // ---------- done check ----------
  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static Map? _asMap(dynamic e) {
    if (e is Map) return e;
    try {
      final m = (e as dynamic).toMap();
      if (m is Map) return m;
    } catch (_) {}
    return null;
  }

  bool get _isDone {
    final list = widget.loggedSets;
    final exId = widget.exerciseId;
    final setNo = widget.setNumber;
    if (list == null || list.isEmpty || exId == null || setNo == null) {
      return false;
    }
    for (final e in list) {
      final m = _asMap(e);
      if (m == null) continue;
      final int? mExId = _toInt(m['exercise_id'] ?? m['exerciseId']);
      final int? mSetNo = _toInt(m['set_number'] ?? m['setNumber']);
      if (mExId == exId && mSetNo == setNo) return true;
    }
    return false;
  }

  TextAlign get _align {
    switch ((widget.textAlign ?? 'center').toLowerCase()) {
      case 'left':
      case 'start':
        return TextAlign.left;
      case 'right':
      case 'end':
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }

  FontWeight get _weight {
    final w = widget.fontWeight ?? 500;
    if (w <= 100) return FontWeight.w100;
    if (w <= 200) return FontWeight.w200;
    if (w <= 300) return FontWeight.w300;
    if (w <= 400) return FontWeight.w400;
    if (w <= 500) return FontWeight.w500;
    if (w <= 600) return FontWeight.w600;
    if (w <= 700) return FontWeight.w700;
    if (w <= 800) return FontWeight.w800;
    return FontWeight.w900;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final String t = widget.text.trim();
    if (t.isEmpty) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    final TextStyle style = theme.bodyMedium.override(
      fontFamily: theme.bodyMediumFamily,
      color: widget.textColor ?? theme.secondaryText,
      fontSize: widget.fontSize ?? 16,
      fontWeight: _weight,
      useGoogleFonts: GoogleFonts.asMap().containsKey(theme.bodyMediumFamily),
    );

    final Widget label = SizedBox(
      width: widget.width,
      height: widget.height,
      child: Center(
        child: Text(
          t,
          style: style,
          textAlign: _align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    // Done set: static text, no gestures, no animation.
    if (_isDone) return label;

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
          child: label,
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
