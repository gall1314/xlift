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
    with SingleTickerProviderStateMixin {
  late final AnimationController _sparkleCtrl;

  static const double _fabSize = 60;
  static const double _fabLift = 28; // how much the FAB floats above the bar
  static const double _ringWidth = 4; // background-colored ring around FAB

  String? _pressed;
  bool _fabPressed = false;

  @override
  void initState() {
    super.initState();
    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _sparkleCtrl.dispose();
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
                widget.onFabTap?.call();
              },
              child: AnimatedScale(
                scale: _fabPressed ? 0.90 : 1.0,
                duration: const Duration(milliseconds: 110),
                curve: Curves.easeOut,
                child: Container(
                  // Outer ring in page-background color: crisp separation
                  // from the bar edge -> reads as truly floating.
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
                          animation: _sparkleCtrl,
                          builder: (context, _) => CustomPaint(
                            size: const Size(30, 30),
                            painter: _SparklePainter(t: _sparkleCtrl.value),
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

/// White 4-point AI sparkle with a gentle pulse + rock.
class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double angle = t * 2 * math.pi;
    final double pulse = 0.5 + 0.5 * math.sin(angle * 2);
    final double r = size.width * (0.38 + 0.10 * pulse);
    final double rot = math.sin(angle) * 0.15;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rot);

    final double inner = r * 0.28;
    final path = Path()..moveTo(0, -r);
    path.quadraticBezierTo(inner * 0.4, -inner * 0.4, r, 0);
    path.quadraticBezierTo(inner * 0.4, inner * 0.4, 0, r);
    path.quadraticBezierTo(-inner * 0.4, inner * 0.4, -r, 0);
    path.quadraticBezierTo(-inner * 0.4, -inner * 0.4, 0, -r);
    path.close();

    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => old.t != t;
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
