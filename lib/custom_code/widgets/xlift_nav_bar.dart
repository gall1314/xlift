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

/// Xlift bottom nav bar with a raised center FAB for AI form analysis.
///
/// currentPage: 'history' | 'stats' | 'home' | 'library' (highlights that
/// tab). showFabLock: small lock badge on the FAB (free quota exhausted).
/// isDark: null = auto from theme.
///
/// FAB icon (v3): the app-wide "AI Form" glyph - a video camera with a
/// sparkle inside (same drawing as AiFormBadge / AiFormButton).
/// 3s loop: the sparkle twinkles (grows + quarter turn) and two small
/// sparkles pop briefly next to the camera. On tap the camera body
/// flashes white (shutter).
class XliftNavBar extends StatefulWidget {
  const XliftNavBar({
    super.key,
    this.width,
    this.height,
    required this.currentPage,
    this.showFabLock = false,
    this.isDark,
    this.onHistoryTap,
    this.onStatsTap,
    this.onHomeTap,
    this.onLibraryTap,
    this.onFabTap,
  });

  final double? width;
  final double? height;
  final String currentPage;
  final bool showFabLock;
  final bool? isDark;
  final Future Function()? onHistoryTap;
  final Future Function()? onStatsTap;
  final Future Function()? onHomeTap;
  final Future Function()? onLibraryTap;
  final Future Function()? onFabTap;

  @override
  State<XliftNavBar> createState() => _XliftNavBarState();
}

class _XliftNavBarState extends State<XliftNavBar>
    with TickerProviderStateMixin {
  late final AnimationController _loopCtrl;
  late final AnimationController _shutterCtrl;

  static const double _fabSize = 60;
  static const double _fabLift = 28; // how much the FAB floats above the bar
  static const double _ringWidth = 4; // background-colored ring around FAB

  String? _pressed;
  bool _fabPressed = false;

  @override
  void initState() {
    super.initState();
    _loopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _shutterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _loopCtrl.dispose();
    _shutterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool dark =
        widget.isDark ?? (Theme.of(context).brightness == Brightness.dark);

    final Color barColor = dark ? const Color(0xFF141A21) : Colors.white;
    // Ring matches the PAGE background so the FAB visually detaches
    // from the bar line (classic notched-FAB look without a notch).
    final Color ringColor =
        dark ? const Color(0xFF0B0F14) : const Color(0xFFF0F2F5);
    final Color active =
        dark ? const Color(0xFF2DD4BF) : const Color(0xFF14B8A6);
    final Color inactive =
        dark ? const Color(0xFF6B7683) : const Color(0xFF9CA3AF);
    final Color fabColor =
        dark ? const Color(0xFF2DD4BF) : const Color(0xFF14B8A6);

    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double barHeight = 62 + bottomInset;
    final double fabOuter = _fabSize + _ringWidth * 2;

    return SizedBox(
      height: barHeight + _fabLift + _ringWidth,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // ---- The bar ----
          Container(
            height: barHeight,
            padding: EdgeInsets.only(bottom: bottomInset),
            decoration: BoxDecoration(
              color: barColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(dark ? 0.35 : 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                _tab('history', Icons.history_rounded, 'History', active,
                    inactive, dark, widget.onHistoryTap),
                _tab('stats', Icons.query_stats_rounded, 'Stats', active,
                    inactive, dark, widget.onStatsTap),
                const Expanded(child: SizedBox()), // FAB slot
                _tab('home', Icons.home_rounded, 'Home', active, inactive, dark,
                    widget.onHomeTap),
                _tab('library', Icons.menu_book_rounded, 'Library', active,
                    inactive, dark, widget.onLibraryTap),
              ],
            ),
          ),

          // ---- The floating FAB ----
          Positioned(
            top: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => setState(() => _fabPressed = true),
              onTapCancel: () => setState(() => _fabPressed = false),
              onTapUp: (_) {
                setState(() => _fabPressed = false);
                HapticFeedback.mediumImpact();
                _shutterCtrl.forward(from: 0);
                widget.onFabTap?.call();
              },
              child: AnimatedScale(
                scale: _fabPressed ? 0.90 : 1.0,
                duration: const Duration(milliseconds: 110),
                curve: Curves.easeOut,
                child: Container(
                  width: fabOuter,
                  height: fabOuter,
                  decoration: BoxDecoration(
                    color: ringColor,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(_ringWidth),
                  child: Container(
                    decoration: BoxDecoration(
                      color: fabColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        // Teal glow
                        BoxShadow(
                          color:
                              fabColor.withOpacity(_fabPressed ? 0.25 : 0.50),
                          blurRadius: _fabPressed ? 10 : 20,
                          spreadRadius: _fabPressed ? 0 : 1,
                          offset: Offset(0, _fabPressed ? 3 : 6),
                        ),
                        // Soft dark shadow for depth
                        BoxShadow(
                          color: Colors.black.withOpacity(dark ? 0.45 : 0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation:
                              Listenable.merge([_loopCtrl, _shutterCtrl]),
                          builder: (context, _) => CustomPaint(
                            size: const Size(_fabSize, _fabSize),
                            painter: _AiCameraGlyphPainter(
                              t: _loopCtrl.value,
                              shutter: _shutterCtrl.value,
                              fg: Colors.white,
                            ),
                          ),
                        ),
                        if (widget.showFabLock)
                          Positioned(
                            right: 1,
                            top: 1,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: dark
                                    ? const Color(0xFF141A21)
                                    : Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.lock_rounded,
                                  size: 11, color: fabColor),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(
    String id,
    IconData icon,
    String label,
    Color active,
    Color inactive,
    bool dark,
    Future Function()? onTap,
  ) {
    final bool selected = widget.currentPage.toLowerCase() == id;
    final bool pressed = _pressed == id;
    final Color c = selected ? active : inactive;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = id),
        onTapCancel: () => setState(() => _pressed = null),
        onTapUp: (_) {
          setState(() => _pressed = null);
          if (!selected) HapticFeedback.selectionClick();
          onTap?.call();
        },
        child: AnimatedScale(
          scale: pressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: pressed ? 0.6 : 1.0,
            duration: const Duration(milliseconds: 110),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: c),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
                      fontSize: 11,
                      color: c,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// App-wide "AI Form" glyph: video camera with a sparkle inside, drawn on
/// a 24x24 grid and centered in the FAB disc at half the disc size.
/// Loop: main sparkle twinkles, two small sparkles pop next to the camera.
/// Tap: camera body flashes white (shutter).
class _AiCameraGlyphPainter extends CustomPainter {
  _AiCameraGlyphPainter({
    required this.t,
    required this.shutter,
    required this.fg,
  });

  final double t; // 0..1 loop
  final double shutter; // 0..1 blink
  final Color fg;

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

  // 0 -> 1 -> 0 while t goes from [start] to [end]; 0 outside.
  double _pulse(double start, double end) {
    if (t <= start || t >= end) return 0;
    return math.sin(math.pi * (t - start) / (end - start));
  }

  void _drawSparkle(
    Canvas canvas,
    Offset center,
    double r,
    double scale,
    double rotation,
    double opacity,
  ) {
    if (opacity <= 0 || scale <= 0) return;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.scale(scale);
    canvas.drawPath(
      _sparkle(r),
      Paint()
        ..color = fg.withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Glyph occupies half of the disc, centered.
    final double glyph = size.shortestSide * 0.5;
    final double k = glyph / 24.0;
    if (k <= 0) return;

    canvas.save();
    canvas.translate(
      (size.width - glyph) / 2,
      (size.height - glyph) / 2,
    );
    canvas.scale(k);

    final Paint line = Paint()
      ..color = fg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final RRect body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(2.5, 6, 13.5, 12),
      const Radius.circular(3),
    );

    // Shutter flash behind the outline (on tap).
    if (shutter > 0) {
      final double f = math.sin(shutter * math.pi); // 0 -> 1 -> 0
      canvas.drawRRect(
        body,
        Paint()..color = Colors.white.withOpacity(0.55 * f),
      );
    }

    // Camera body.
    canvas.drawRRect(body, line);

    // Camera wedge on the right.
    final Path wedge = Path()
      ..moveTo(16, 10.6)
      ..lineTo(21.5, 7.6)
      ..lineTo(21.5, 16.4)
      ..lineTo(16, 13.4);
    canvas.drawPath(wedge, line);

    // Main sparkle: twinkle during the first 40% of the loop.
    const double window = 0.4;
    double mainScale = 1.0;
    double mainRot = 0.0;
    if (t < window) {
      final double p = t / window;
      mainScale = 1.0 + 0.35 * math.sin(math.pi * p);
      mainRot = Curves.easeInOut.transform(p) * (math.pi / 2);
    }
    _drawSparkle(canvas, const Offset(9.25, 12), 3.6, mainScale, mainRot, 1.0);

    // Two small sparkles popping outside the camera, slightly staggered.
    final double a = _pulse(0.08, 0.42);
    _drawSparkle(canvas, const Offset(19.6, 3.4), 2.3, 0.4 + 0.6 * a,
        a * (math.pi / 4), a);

    final double b = _pulse(0.20, 0.54);
    _drawSparkle(canvas, const Offset(3.2, 21.2), 1.7, 0.4 + 0.6 * b,
        b * (math.pi / 4), b);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AiCameraGlyphPainter old) =>
      old.t != t || old.shutter != shutter || old.fg != fg;
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
