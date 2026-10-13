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

import 'package:google_fonts/google_fonts.dart';

/// The single marker for "AI camera form analysis" across the app.
///
/// showLabel = false -> bare icon (set row button, nav button, tight spots).
/// showLabel = true  -> tinted pill: icon + "AI Form" (exercise lists).
class AiFormBadge extends StatefulWidget {
  const AiFormBadge({
    super.key,
    this.width,
    this.height,
    this.showLabel,
    this.isDark,
    this.iconSize,
    this.color,
  });

  final double? width;
  final double? height;
  final bool? showLabel;
  final bool? isDark;
  final double? iconSize;
  final Color? color;

  @override
  State<AiFormBadge> createState() => _AiFormBadgeState();
}

class _AiFormBadgeState extends State<AiFormBadge> {
  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final bool dark = widget.isDark ?? false;
    final bool label = widget.showLabel ?? false;

    final Color fg = widget.color ??
        (dark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E));
    final Color bg = dark ? const Color(0x295EEAD4) : const Color(0xFFDDF3EF);

    Widget icon(double s) => SizedBox(
          width: s,
          height: s,
          child: CustomPaint(
            size: Size(s, s),
            painter: _AiCamPainter(fg),
          ),
        );

    Widget child;
    if (!label) {
      child = icon(widget.iconSize ?? 20);
    } else {
      child = Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            icon(widget.iconSize ?? 15),
            const SizedBox(width: 5),
            Text(
              'AI Form',
              maxLines: 1,
              softWrap: false,
              style: th.bodyMedium.override(
                fontFamily: th.bodyMediumFamily,
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
                lineHeight: 1.2,
                useGoogleFonts:
                    GoogleFonts.asMap().containsKey(th.bodyMediumFamily),
              ),
            ),
          ],
        ),
      );
    }

    // scaleDown: the content keeps its natural size when the box is big
    // enough, and shrinks (instead of clipping/overflowing) when it is not.
    return Semantics(
      label: 'AI form analysis',
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

/// Video camera with a sparkle inside, drawn on a 24x24 grid.
class _AiCamPainter extends CustomPainter {
  _AiCamPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double k = size.shortestSide / 24.0;
    if (k <= 0) return;

    canvas.save();
    canvas.translate(
      (size.width - 24 * k) / 2,
      (size.height - 24 * k) / 2,
    );
    canvas.scale(k);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Camera body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(2.5, 6, 13.5, 12),
        const Radius.circular(3),
      ),
      stroke,
    );

    // Camera wedge on the right.
    final wedge = Path()
      ..moveTo(16, 10.6)
      ..lineTo(21.5, 7.6)
      ..lineTo(21.5, 16.4)
      ..lineTo(16, 13.4);
    canvas.drawPath(wedge, stroke);

    // Four-point sparkle inside the body.
    const double cx = 9.25, cy = 12, r = 3.6, c = 0.72;
    final spark = Path()
      ..moveTo(cx, cy - r)
      ..cubicTo(cx + c, cy - 1.6 * c, cx + 1.6 * c, cy - c, cx + r, cy)
      ..cubicTo(cx + 1.6 * c, cy + c, cx + c, cy + 1.6 * c, cx, cy + r)
      ..cubicTo(cx - c, cy + 1.6 * c, cx - 1.6 * c, cy + c, cx - r, cy)
      ..cubicTo(cx - 1.6 * c, cy - c, cx - c, cy - 1.6 * c, cx, cy - r)
      ..close();
    canvas.drawPath(
      spark,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AiCamPainter old) => old.color != color;
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
