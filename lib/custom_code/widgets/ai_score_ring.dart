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

import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// AI Form result marker: a ring that fills with the score (0-10, halves
/// allowed), the number in the middle, and a small star sitting on the
/// ring (the "AI" signature). Tappable if onTap is set.
class AiScoreRing extends StatefulWidget {
  const AiScoreRing({
    super.key,
    this.width,
    this.height,
    this.score,
    this.size,
    this.isDark,
    this.onTap,
  });

  final double? width;
  final double? height;

  /// Form score 0-10.
  final double? score;

  /// Ring diameter. Default 44.
  final double? size;

  /// null = auto from the app theme brightness.
  final bool? isDark;

  final Future Function()? onTap;

  @override
  State<AiScoreRing> createState() => _AiScoreRingState();
}

class _AiScoreRingState extends State<AiScoreRing> {
  bool _pressed = false;
  bool _busy = false;

  bool get _tappable => widget.onTap != null;

  void _setPressed(bool v) {
    if (!_tappable || _pressed == v) return;
    setState(() => _pressed = v);
  }

  Future<void> _handleTap() async {
    if (!_tappable || _busy) return;
    _busy = true;
    HapticFeedback.lightImpact();
    try {
      await widget.onTap?.call();
    } finally {
      _busy = false;
    }
  }

  String _formatScore(double s) {
    if (s == s.roundToDouble()) return s.toInt().toString();
    return s.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final bool dark =
        widget.isDark ?? (Theme.of(context).brightness == Brightness.dark);

    final double size = widget.size ?? 44;
    final double score = (widget.score ?? 0).clamp(0.0, 10.0).toDouble();

    final Color ringColor = score >= 8
        ? const Color(0xFF14B8A6)
        : (score >= 6 ? const Color(0xFFF1A24A) : const Color(0xFFE85A5A));
    final Color fill = dark ? const Color(0xFF1A2129) : Colors.white;
    final Color track =
        dark ? const Color(0xFF2A333D) : const Color(0xFFE6EAEE);
    final Color star = dark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E);
    final Color text = dark ? Colors.white : const Color(0xFF14181B);

    final ring = AnimatedScale(
      scale: _pressed ? 0.93 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _AiScoreRingPainter(
                fraction: score / 10.0,
                ringColor: ringColor,
                trackColor: track,
                fillColor: fill,
                starColor: star,
              ),
            ),
            Text(
              _formatScore(score),
              maxLines: 1,
              textAlign: TextAlign.center,
              style: th.bodyMedium.override(
                fontFamily: th.bodyMediumFamily,
                color: text,
                fontSize: size * 0.32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                lineHeight: 1.0,
                useGoogleFonts:
                    GoogleFonts.asMap().containsKey(th.bodyMediumFamily),
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      button: _tappable,
      label: 'Form score ${_formatScore(score)} out of 10',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _tappable ? _handleTap : null,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Center(child: ring),
        ),
      ),
    );
  }
}

/// Filled disc, track ring, score arc starting at 12 o'clock, and a small
/// four-point star on the ring at the top-right. The ring is really cut
/// out (transparent) around the star, so it works on any background.
class _AiScoreRingPainter extends CustomPainter {
  _AiScoreRingPainter({
    required this.fraction,
    required this.ringColor,
    required this.trackColor,
    required this.fillColor,
    required this.starColor,
  });

  final double fraction; // 0..1
  final Color ringColor;
  final Color trackColor;
  final Color fillColor;
  final Color starColor;

  // Four-point sparkle centered on (0,0) with radius r.
  Path _sparkle(double r) {
    final double c = r * 0.2;
    return Path()
      ..moveTo(0, -r)
      ..cubicTo(c, -1.6 * c, 1.6 * c, -c, r, 0)
      ..cubicTo(1.6 * c, c, c, 1.6 * c, 0, r)
      ..cubicTo(-c, 1.6 * c, -1.6 * c, c, -r, 0)
      ..cubicTo(-1.6 * c, -c, -c, -1.6 * c, 0, -r)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    if (s <= 0) return;

    final Offset c = Offset(size.width / 2, size.height / 2);
    final double strokeW = s * 0.08;
    final double r = s / 2 - strokeW / 2 - s * 0.017;

    // Star anchor: on the ring, 45 degrees up-right.
    const double a = -math.pi / 4;
    final Offset starC = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
    final double starR = s * 0.14;
    final double cutR = s * 0.165;

    // Layer so the cutout only erases what is drawn here.
    canvas.saveLayer(Offset.zero & size, Paint());

    // Disc fill.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    // Track.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..isAntiAlias = true,
    );

    // Score arc.
    final double f = fraction.clamp(0.0, 1.0).toDouble();
    if (f > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * f,
        false,
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true,
      );
    }

    // Real cutout around the star.
    canvas.drawCircle(
      starC,
      cutR,
      Paint()
        ..blendMode = BlendMode.clear
        ..isAntiAlias = true,
    );

    canvas.restore();

    // Star.
    canvas.save();
    canvas.translate(starC.dx, starC.dy);
    canvas.drawPath(
      _sparkle(starR),
      Paint()
        ..color = starColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AiScoreRingPainter old) =>
      old.fraction != fraction ||
      old.ringColor != ringColor ||
      old.trackColor != trackColor ||
      old.fillColor != fillColor ||
      old.starColor != starColor;
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
