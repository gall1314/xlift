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

class AiLoadingBar extends StatefulWidget {
  const AiLoadingBar({
    super.key,
    this.width,
    this.height,
    this.barColor,
  });

  final double? width;
  final double? height;
  final Color? barColor;

  @override
  State<AiLoadingBar> createState() => _AiLoadingBarState();
}

class _AiLoadingBarState extends State<AiLoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? 220.0,
      height: widget.height ?? 4.0,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => CustomPaint(
          painter: _AiBarPainter(
            t: _ctrl.value,
            color: widget.barColor ?? const Color(0xFF2DD4BF),
          ),
        ),
      ),
    );
  }
}

class _AiBarPainter extends CustomPainter {
  _AiBarPainter({required this.t, required this.color});

  final double t; // 0..1
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double h = size.height;
    final Radius r = Radius.circular(h / 2);

    // --- 1. Track (dark, subtle) ---
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, h),
      r,
    );
    final trackPaint = Paint()..color = Colors.white.withOpacity(0.08);
    canvas.drawRRect(trackRect, trackPaint);

    // --- 2. Moving segment (ping-pong with ease-in-out) ---
    // Triangle wave 0->1->0, then eased for a smooth turnaround.
    final double tri = t < 0.5 ? t * 2 : (1 - t) * 2;
    final double eased = Curves.easeInOut.transform(tri);

    final double segW = size.width * 0.28;
    final double x = eased * (size.width - segW);

    final segRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, 0, segW, h),
      r,
    );

    // Glow under the segment.
    final glowPaint = Paint()
      ..color = color.withOpacity(0.45)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 1.6);
    canvas.drawRRect(segRect, glowPaint);

    // Segment with a soft gradient (brighter center, fading tips).
    final segPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.25),
          color,
          color.withOpacity(0.25),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(segRect.outerRect);
    canvas.drawRRect(segRect, segPaint);
  }

  @override
  bool shouldRepaint(covariant _AiBarPainter old) =>
      old.t != t || old.color != color;
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
