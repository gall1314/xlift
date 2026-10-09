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

class AiSparkleIndicator extends StatefulWidget {
  const AiSparkleIndicator({
    super.key,
    this.width,
    this.height,
    this.sparkleColor,
  });

  final double? width;
  final double? height;
  final Color? sparkleColor;

  @override
  State<AiSparkleIndicator> createState() => _AiSparkleIndicatorState();
}

class _AiSparkleIndicatorState extends State<AiSparkleIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.width ?? widget.height ?? 44.0;
    return SizedBox(
      width: widget.width ?? size,
      height: widget.height ?? size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => CustomPaint(
          painter: _SparklePainter(
            t: _ctrl.value,
            color: widget.sparkleColor ?? const Color(0xFF14B8A6),
          ),
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.t, required this.color});

  final double t; // 0..1 loop
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double base = math.min(size.width, size.height);
    final double circleR = base * 0.42;
    final double angle = t * 2 * math.pi;

    // --- 1. Soft pulsing glow behind the sparkle (transparent bg) ---
    final double glowPulse = 0.5 + 0.5 * math.sin(angle); // 0..1
    final glowPaint = Paint()
      ..color = color.withOpacity(0.14 + 0.12 * glowPulse)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, base * 0.10);
    canvas.drawCircle(center, circleR * 0.85, glowPaint);

    // --- 2. Three floating particles around the sparkle ---
    // Each: [baseAngle, orbitFactor, radiusFactor, phaseOffset]
    final particles = <List<double>>[
      [0.6, 0.62, 0.055, 0.00],
      [2.7, 0.68, 0.042, 0.33],
      [4.6, 0.58, 0.048, 0.66],
    ];

    for (final p in particles) {
      final double a = p[0] + angle * 0.7; // slow drift around the star
      final double r = circleR * p[1];
      final double dotR = base * p[2];
      // Opacity pulse, phase-shifted per particle so they twinkle in turn.
      final double op =
          0.35 + 0.55 * (0.5 + 0.5 * math.sin(angle * 2 + p[3] * 2 * math.pi));
      final dotCenter = center + Offset(math.cos(a), math.sin(a)) * r;
      final dotPaint = Paint()..color = color.withOpacity(op);
      canvas.drawCircle(dotCenter, dotR, dotPaint);
    }

    // --- 3. Center 4-point sparkle (pulsing scale + gentle rotation) ---
    final double sparklePulse = 0.5 + 0.5 * math.sin(angle * 2); // two beats
    final double sparkleR = circleR * (0.42 + 0.16 * sparklePulse);
    final double rot = math.sin(angle) * 0.18; // gentle rock, not full spin

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rot);

    final path = _fourPointStar(sparkleR);

    // Outline (slightly darker) + fill for the two-tone look.
    final fillPaint = Paint()
      ..color = Color.lerp(color, Colors.white, 0.25 * (1 - sparklePulse))!;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = base * 0.03
      ..color = color;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
    canvas.restore();
  }

  // Classic AI sparkle: 4 points with concave curves between them.
  Path _fourPointStar(double r) {
    final double inner = r * 0.28;
    final path = Path()..moveTo(0, -r);
    path.quadraticBezierTo(inner * 0.4, -inner * 0.4, r, 0);
    path.quadraticBezierTo(inner * 0.4, inner * 0.4, 0, r);
    path.quadraticBezierTo(-inner * 0.4, inner * 0.4, -r, 0);
    path.quadraticBezierTo(-inner * 0.4, -inner * 0.4, 0, -r);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) =>
      old.t != t || old.color != color;
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
