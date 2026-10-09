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

class AiLoadingIndicator extends StatefulWidget {
  const AiLoadingIndicator({
    super.key,
    this.width,
    this.height,
    this.isDark,
    this.circleColor,
  });

  final double? width;
  final double? height;

  /// true = dark theme, false = light theme.
  /// null = auto-detect from the app's current brightness.
  final bool? isDark;

  /// Optional disc behind the icon.
  /// null = transparent in dark mode, soft white disc in light mode.
  final Color? circleColor;

  @override
  State<AiLoadingIndicator> createState() => _AiLoadingIndicatorState();
}

class _AiLoadingIndicatorState extends State<AiLoadingIndicator>
    with TickerProviderStateMixin {
  // Glow arc + orbiting dots rotation (slow, continuous).
  late final AnimationController _orbitCtrl;
  // Center icon rotation (square <-> diamond, continuous spin).
  late final AnimationController _iconCtrl;

  @override
  void initState() {
    super.initState();
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.width ?? widget.height ?? 140.0;
    final bool dark =
        widget.isDark ?? (Theme.of(context).brightness == Brightness.dark);

    return SizedBox(
      width: widget.width ?? size,
      height: widget.height ?? size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_orbitCtrl, _iconCtrl]),
        builder: (context, _) => CustomPaint(
          painter: _AiLoaderPainter(
            orbitT: _orbitCtrl.value,
            iconT: _iconCtrl.value,
            isDark: dark,
            circleColor: widget.circleColor,
          ),
        ),
      ),
    );
  }
}

class _AiLoaderPainter extends CustomPainter {
  _AiLoaderPainter({
    required this.orbitT,
    required this.iconT,
    required this.isDark,
    this.circleColor,
  });

  final double orbitT; // 0..1 - glow + dots rotation
  final double iconT; // 0..1 - center icon rotation
  final bool isDark;
  final Color? circleColor;

  static const Color _teal = Color(0xFF2DD4BF);
  static const Color _tealDeep = Color(0xFF14B8A6);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double base = math.min(size.width, size.height);
    final double circleR = base * 0.32;
    final double orbitAngle = orbitT * 2 * math.pi;

    final Color accent = isDark ? _teal : _tealDeep;
    final double glowMul = isDark ? 1.0 : 0.75;

    // --- 1. Rotating glow arc ---
    // Light mode: tighter + less blurred so it reads as a highlight,
    // not a smudge on the white background.
    final double glowR = circleR * (isDark ? 1.1 : 0.95);
    final double glowBlur = isDark ? 12 : 7;
    final glowCenter = center +
        Offset(math.cos(orbitAngle), math.sin(orbitAngle)) * (circleR * 0.85);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withOpacity(0.55 * glowMul),
          accent.withOpacity(0.18 * glowMul),
          accent.withOpacity(0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(
        Rect.fromCircle(center: glowCenter, radius: glowR),
      )
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlur);
    canvas.drawCircle(glowCenter, glowR, glowPaint);

    // --- 2. Disc ---
    // Dark: transparent unless circleColor given (unchanged behavior).
    // Light: soft white disc with a faint shadow + teal tint, so the
    // loader has a defined shape on a light background.
    if (circleColor != null) {
      canvas.drawCircle(center, circleR, Paint()..color = circleColor!);
    } else if (!isDark) {
      final shadowPaint = Paint()
        ..color = accent.withOpacity(0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, base * 0.05);
      canvas.drawCircle(center + Offset(0, base * 0.015), circleR, shadowPaint);

      final discPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white,
            Color.lerp(Colors.white, accent, 0.10)!,
          ],
          stops: const [0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: circleR));
      canvas.drawCircle(center, circleR, discPaint);
    }

    // --- 2b. Full faint ring (light mode) so the circle reads as complete ---
    if (!isDark) {
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = base * 0.012
        ..color = accent.withOpacity(0.22);
      canvas.drawCircle(center, circleR, ringPaint);
    }

    // Rim highlight on the glow side (works on any background).
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = base * 0.012
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        transform: GradientRotation(orbitAngle - math.pi / 3),
        colors: [
          accent.withOpacity(0.7),
          accent.withOpacity(0.0),
          accent.withOpacity(0.0),
          accent.withOpacity(0.7),
        ],
        stops: const [0.0, 0.35, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: circleR));
    canvas.drawCircle(center, circleR, rimPaint);

    // --- 3. Rotating rounded square in the center ---
    final double iconHalf = circleR * 0.34;
    final double iconAngle = iconT * 2 * math.pi;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(iconAngle);

    final iconRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: iconHalf * 2,
        height: iconHalf * 2,
      ),
      Radius.circular(iconHalf * 0.45),
    );

    final iconGlowPaint = Paint()
      ..color = accent.withOpacity(0.5 * glowMul)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, iconHalf * 0.6);
    canvas.drawRRect(iconRect, iconGlowPaint);

    final iconPaint = Paint()..color = accent;
    canvas.drawRRect(iconRect, iconPaint);
    canvas.restore();

    // --- 4. Three orbiting glowing dots ---
    final dots = <List<double>>[
      // [baseAngle, orbitRadiusFactor, dotRadiusFactor, speed]
      [0.0, 1.35, 0.030, 1.0],
      [2.1, 1.20, 0.022, 1.0],
      [4.2, 1.45, 0.026, 1.0],
    ];

    for (final d in dots) {
      final double a = d[0] + orbitAngle * d[3];
      final double r = circleR * d[1];
      final double dotR = base * d[2];
      final dotCenter = center + Offset(math.cos(a), math.sin(a)) * r;

      final dotGlow = Paint()
        ..color = accent.withOpacity(0.45 * glowMul)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, dotR * 2.2);
      canvas.drawCircle(dotCenter, dotR * 2.2, dotGlow);

      final dotPaint = Paint()..color = accent;
      canvas.drawCircle(dotCenter, dotR, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AiLoaderPainter old) =>
      old.orbitT != orbitT ||
      old.iconT != iconT ||
      old.isDark != isDark ||
      old.circleColor != circleColor;
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
