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

/// Round button with the AI Form icon (video camera + sparkle).
///
/// The sparkle twinkles briefly every few seconds. Every visual property is
/// optional and falls back to the default teal gradient style.
class AiFormButton extends StatefulWidget {
  const AiFormButton({
    super.key,
    this.width,
    this.height,
    this.size,
    this.iconSize,
    this.backgroundColor,
    this.gradientEndColor,
    this.iconColor,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
    this.shadowColor,
    this.shadowBlur,
    this.enabled,
    this.animate,
    this.onTap,
  });

  final double? width;
  final double? height;

  /// Button diameter. Default 52.
  final double? size;

  /// Icon size. Default 46% of the button size.
  final double? iconSize;

  /// Fill color. If null, the default teal gradient is used.
  final Color? backgroundColor;

  /// Optional second color: fill becomes a gradient from
  /// backgroundColor (top-left) to this color (bottom-right).
  final Color? gradientEndColor;

  /// Icon color. Default white.
  final Color? iconColor;

  /// Corner radius. Default = full circle.
  final double? borderRadius;

  final Color? borderColor;

  /// Border width. Default 0 (no border).
  final double? borderWidth;

  /// Shadow color. Default soft teal.
  final Color? shadowColor;

  /// Shadow blur. Default 14. Pass 0 for no shadow.
  final double? shadowBlur;

  /// When false the button is dimmed and does not respond. Default true.
  final bool? enabled;

  /// Sparkle twinkle animation. Default true.
  final bool? animate;

  final Future Function()? onTap;

  @override
  State<AiFormButton> createState() => _AiFormButtonState();
}

class _AiFormButtonState extends State<AiFormButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _twinkle;
  bool _pressed = false;
  bool _busy = false;

  bool get _enabled => widget.enabled ?? true;

  @override
  void initState() {
    super.initState();
    _twinkle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant AiFormButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final bool run = (widget.animate ?? true) && _enabled && !reduceMotion;
    if (run) {
      if (!_twinkle.isAnimating) _twinkle.repeat();
    } else {
      _twinkle.stop();
      _twinkle.value = 0;
    }
  }

  @override
  void dispose() {
    _twinkle.dispose();
    super.dispose();
  }

  void _setPressed(bool v) {
    if (!_enabled || _pressed == v) return;
    setState(() => _pressed = v);
  }

  Future<void> _handleTap() async {
    if (!_enabled || _busy) return;
    _busy = true;
    HapticFeedback.lightImpact();
    try {
      await widget.onTap?.call();
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size ?? 52;
    final double iconSize = widget.iconSize ?? size * 0.46;
    final double radius = widget.borderRadius ?? size / 2;
    final double borderWidth = widget.borderWidth ?? 0;
    final double blur = widget.shadowBlur ?? 14;

    final Color iconColor = widget.iconColor ?? Colors.white;
    final Color shadowColor = widget.shadowColor ?? const Color(0x590F766E);

    // Fill: default gradient, custom gradient, or solid color.
    Color? solid;
    Gradient? gradient;
    if (widget.backgroundColor == null) {
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
      );
    } else if (widget.gradientEndColor != null) {
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [widget.backgroundColor!, widget.gradientEndColor!],
      );
    } else {
      solid = widget.backgroundColor;
    }

    final button = AnimatedScale(
      scale: _pressed ? 0.93 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _enabled ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: solid,
            gradient: gradient,
            borderRadius: BorderRadius.circular(radius),
            border: (borderWidth > 0 && widget.borderColor != null)
                ? Border.all(color: widget.borderColor!, width: borderWidth)
                : null,
            boxShadow: (blur > 0 && _enabled)
                ? [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: _pressed ? blur * 0.5 : blur,
                      offset: Offset(0, _pressed ? 2 : 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: RepaintBoundary(
              child: SizedBox(
                width: iconSize,
                height: iconSize,
                child: CustomPaint(
                  size: Size(iconSize, iconSize),
                  painter: _AiCamButtonPainter(iconColor, _twinkle),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: 'AI form analysis',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _handleTap,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Center(child: button),
        ),
      ),
    );
  }
}

/// Video camera with a sparkle inside, drawn on a 24x24 grid.
/// The sparkle twinkles during the first ~40% of each animation loop.
class _AiCamButtonPainter extends CustomPainter {
  _AiCamButtonPainter(this.color, this.twinkle) : super(repaint: twinkle);

  final Color color;
  final Animation<double> twinkle;

  static const double _window = 0.4;

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

    // Twinkle: grow a little and turn a quarter turn, then rest.
    final double t = twinkle.value;
    double scale = 1.0;
    double rotation = 0.0;
    if (t < _window) {
      final double p = t / _window; // 0..1 inside the active window
      scale = 1.0 + 0.24 * math.sin(math.pi * p);
      rotation = Curves.easeInOut.transform(p) * (math.pi / 2);
    }

    // Four-point sparkle, centered on (9.25, 12).
    const double r = 3.6, c = 0.72;
    final spark = Path()
      ..moveTo(0, -r)
      ..cubicTo(c, -1.6 * c, 1.6 * c, -c, r, 0)
      ..cubicTo(1.6 * c, c, c, 1.6 * c, 0, r)
      ..cubicTo(-c, 1.6 * c, -1.6 * c, c, -r, 0)
      ..cubicTo(-1.6 * c, -c, -c, -1.6 * c, 0, -r)
      ..close();

    canvas.save();
    canvas.translate(9.25, 12);
    canvas.rotate(rotation);
    canvas.scale(scale);
    canvas.drawPath(
      spark,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AiCamButtonPainter old) =>
      old.color != color || old.twinkle != twinkle;
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
