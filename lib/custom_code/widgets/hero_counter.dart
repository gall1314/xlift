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

/// Hero number for the Workout Complete screen.
///
/// Takes the value as a STRING ("150", "60.5", "10081") plus a unit, and
/// counts up from 0 to the value with an ease-out curve. The unit is visible
/// from the first frame so the row is centered throughout. Keeps the same
/// number of decimals as the input while counting, adds thousands
/// separators ("10,081"), and from [compactFrom] upwards shows a compact
/// form ("10.1K"). Never overflows: scales down to fit its width.
/// Tap the number to replay the animation.
class HeroCounter extends StatefulWidget {
  const HeroCounter({
    super.key,
    this.width,
    this.height,
    required this.value,
    this.unit,
    this.color,
    this.unitColor,
    this.fontSize,
    this.unitFontSize,
    this.fontFamily,
    this.letterSpacing,
    this.durationMs,
    this.delayMs,
    this.useThousandsSeparator = true,
    this.compactFrom,
  });

  final double? width;
  final double? height;
  final String value; // "150" | "60.5" | "10081"
  final String? unit; // "kg" | "reps"
  final Color? color;
  final Color? unitColor;
  final double? fontSize; // default 120
  final double? unitFontSize; // default 28
  final String? fontFamily; // null = theme default
  final double? letterSpacing; // default -4
  final int? durationMs; // default 900
  final int? delayMs; // default 150
  final bool useThousandsSeparator;
  final double? compactFrom; // default 10000 -> "10.1K"; 1000 -> "2K"

  @override
  State<HeroCounter> createState() => _HeroCounterState();
}

class _HeroCounterState extends State<HeroCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _count;

  double _target = 0;
  int _decimals = 0;

  @override
  void initState() {
    super.initState();
    _parse();

    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs ?? 900),
    );
    _count = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

    Future.delayed(Duration(milliseconds: widget.delayMs ?? 150), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void didUpdateWidget(covariant HeroCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _parse();
      _ctrl.forward(from: 0);
    }
  }

  void _parse() {
    final String raw = widget.value.trim().replaceAll(',', '');
    _target = double.tryParse(raw) ?? 0;
    final int dot = raw.indexOf('.');
    _decimals = dot < 0 ? 0 : (raw.length - dot - 1).clamp(0, 2);
  }

  void _replay() {
    if (_ctrl.isAnimating) return;
    HapticFeedback.lightImpact();
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _compact => _target >= (widget.compactFrom ?? 10000);

  String _fmt(double v) {
    if (_compact) {
      // 2000 -> "2K", 10081 -> "10.1K", 1250000 -> "1.25M"
      final bool m = v >= 1000000;
      final double scaled = m ? v / 1000000 : v / 1000;
      String s = scaled.toStringAsFixed(m ? 2 : 1);
      while (s.endsWith('0')) s = s.substring(0, s.length - 1);
      if (s.endsWith('.')) s = s.substring(0, s.length - 1);
      return s + (m ? 'M' : 'K');
    }

    String s = v.toStringAsFixed(_decimals);
    if (!widget.useThousandsSeparator) return s;
    final int dot = s.indexOf('.');
    final String intPart = dot < 0 ? s : s.substring(0, dot);
    final String fracPart = dot < 0 ? '' : s.substring(dot);
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final int fromEnd = intPart.length - i;
      out.write(intPart[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) out.write(',');
    }
    return out.toString() + fracPart;
  }

  @override
  Widget build(BuildContext context) {
    final Color c = widget.color ?? const Color(0xFF2CD4C3);
    final Color uc = widget.unitColor ?? c;
    final double fs = widget.fontSize ?? 120;
    final double ufs = widget.unitFontSize ?? 28;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _replay,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final double shown = _target * _count.value;
            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _fmt(shown),
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: widget.fontFamily,
                      fontSize: fs,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      letterSpacing: widget.letterSpacing ?? -4,
                      color: c,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (widget.unit != null && widget.unit!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      widget.unit!,
                      style: TextStyle(
                        fontFamily: widget.fontFamily,
                        fontSize: ufs,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                        color: uc,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
