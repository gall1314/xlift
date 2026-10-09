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

/// Set-number widget with TWO modes, switched by showChevron (wire it to
/// !isDone): - showChevron TRUE  (set not done): a real button - pill fill,
/// press feedback, number CENTERED in the pill, chevron pinned to the right
/// edge at FIXED size (it never pushes the number off-center).
///
/// The number keeps its full size; only IT shrinks if space runs out, never
/// the chevron. - showChevron FALSE (set done): plain number - no fill, no
/// border, no chevron, NOT tappable.
class SetNumberButton extends StatefulWidget {
  const SetNumberButton({
    super.key,
    this.width,
    this.height,
    this.label,
    this.fontSize,
    this.fontWeight,
    this.textColor,
    this.fillColor,
    this.chevronColor,
    this.chevronSize,
    this.showChevron = true,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.horizontalPadding,
    this.enableHaptic = true,
    this.onTap,
  });

  final double? width;
  final double? height;
  final String? label;
  final double? fontSize; // number MAX size - shrinks only if needed
  final int? fontWeight;
  final Color? textColor;
  final Color? fillColor;
  final Color? chevronColor;
  final double? chevronSize; // FIXED, default fontSize * 0.8
  final bool showChevron; // wire to !isDone
  final Color? borderColor;
  final double? borderWidth;
  final double? borderRadius; // null -> stadium
  final double? horizontalPadding; // default 4
  final bool enableHaptic;
  final Future Function()? onTap;

  @override
  State<SetNumberButton> createState() => _SetNumberButtonState();
}

class _SetNumberButtonState extends State<SetNumberButton> {
  bool _pressed = false;

  static FontWeight _weightFromInt(int? w) {
    switch (w) {
      case 100:
        return FontWeight.w100;
      case 200:
        return FontWeight.w200;
      case 300:
        return FontWeight.w300;
      case 400:
        return FontWeight.w400;
      case 500:
        return FontWeight.w500;
      case 600:
        return FontWeight.w600;
      case 800:
        return FontWeight.w800;
      case 900:
        return FontWeight.w900;
      case 700:
      default:
        return FontWeight.w700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double h = widget.height ?? 36;
    final double w = widget.width ?? 44;
    final double radius = widget.borderRadius ?? h;
    final Color txt = widget.textColor ?? Colors.white;
    final double fs = widget.fontSize ?? 16;

    final Widget numberText = Text(
      widget.label ?? '',
      maxLines: 1,
      style: TextStyle(
        fontSize: fs,
        fontWeight: _weightFromInt(widget.fontWeight),
        height: 1.0,
        color: txt,
      ),
    );

    // ---------- DONE mode: plain, non-tappable number ----------
    if (!widget.showChevron) {
      return SizedBox(
        width: w,
        height: h,
        child: Center(
          child: Padding(
            padding:
                EdgeInsets.symmetric(horizontal: widget.horizontalPadding ?? 4),
            child: FittedBox(fit: BoxFit.scaleDown, child: numberText),
          ),
        ),
      );
    }

    // ---------- ACTIVE mode: real button ----------
    final Color bg = widget.fillColor ?? const Color(0xFF10151B);
    final Color chev = widget.chevronColor ?? txt.withOpacity(0.5);
    final double chevSize = widget.chevronSize ?? fs * 0.8;
    final double hPad = widget.horizontalPadding ?? 4;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () {
        if (widget.enableHaptic) HapticFeedback.selectionClick();
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: _pressed ? Color.lerp(bg, Colors.white, 0.08) : bg,
            borderRadius: BorderRadius.circular(radius),
            border: (widget.borderWidth ?? 0) > 0
                ? Border.all(
                    color: widget.borderColor ?? Colors.transparent,
                    width: widget.borderWidth ?? 0,
                  )
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Number: true center of the pill. Symmetric inset keeps it
              // clear of the chevron on the right without shifting it.
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: hPad + chevSize * 0.55),
                child: FittedBox(fit: BoxFit.scaleDown, child: numberText),
              ),
              // Chevron: pinned to the right edge, FIXED size, never shrinks.
              Positioned(
                right: hPad,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: chevSize,
                  color: chev,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
