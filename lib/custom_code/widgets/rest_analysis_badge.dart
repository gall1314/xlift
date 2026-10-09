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

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import '/app_state.dart';

/// Small round badge for the rest-timer sheet, next to the countdown.
///
/// Looks at ONE set only - [exerciseId] + [setNumber] - and shows:
///   - LOADING: the AI sparkle animation while that set is being analyzed
///   - READY:   the "report" icon; tap -> [onTap](exerciseId, setNumber)
///   - nothing (zero size) otherwise
///
/// LIVE: the widget polls FFAppState().workoutAnalysisState every 500ms
/// and repaints the moment the state changes - no page rebuild needed.
/// The [analysisList] parameter is only the initial snapshot / fallback.
class RestAnalysisBadge extends StatefulWidget {
  const RestAnalysisBadge({
    super.key,
    this.width,
    this.height,
    this.analysisList,
    this.exerciseId,
    this.setNumber,
    this.accentColor,
    this.onTap,
  });

  final double? width;
  final double? height;
  final List<dynamic>? analysisList;
  final int? exerciseId;
  final int? setNumber;
  final Color? accentColor;
  final Future Function(int exerciseId, int setNumber)? onTap;

  @override
  State<RestAnalysisBadge> createState() => _RestAnalysisBadgeState();
}

class _RestAnalysisBadgeState extends State<RestAnalysisBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..repeat();

  Timer? _poll;
  String? _state; // 'loading' | 'ready' | null

  @override
  void initState() {
    super.initState();
    _state = _stateForSet(_liveList());
    _poll = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      final s = _stateForSet(_liveList());
      if (s != _state) setState(() => _state = s);
    });
  }

  @override
  void didUpdateWidget(covariant RestAnalysisBadge old) {
    super.didUpdateWidget(old);
    final s = _stateForSet(_liveList());
    if (s != _state) setState(() => _state = s);
  }

  @override
  void dispose() {
    _poll?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  /// Prefer the live App State; fall back to the parameter snapshot.
  List<dynamic>? _liveList() {
    try {
      final live = FFAppState().workoutAnalysisState;
      if (live is List) return live;
    } catch (_) {}
    return widget.analysisList;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  static bool _truthy(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    return v?.toString().toLowerCase() == 'true';
  }

  /// 'loading' | 'ready' | null  - for THIS set only.
  String? _stateForSet(List<dynamic>? list) {
    final int? wantEx = widget.exerciseId;
    final int? wantSn = widget.setNumber;
    if (list == null || wantEx == null || wantSn == null) return null;

    for (final ex in list) {
      if (ex is! Map) continue;
      if (_toInt(ex['exerciseId']) != wantEx) continue;
      final sets = ex['sets'];
      if (sets is! List) continue;
      for (final s in sets) {
        if (s is! Map) continue;
        if (_toInt(s['setNumber']) != wantSn) continue;
        if (_truthy(s['isProcessing'])) return 'loading';
        if (_truthy(s['analysisDone'])) return 'ready';
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String? state = _state;
    if (state == null) return const SizedBox.shrink();

    final double size = widget.width ?? widget.height ?? 44.0;
    final Color accent =
        widget.accentColor ?? FlutterFlowTheme.of(context).primary;

    if (state == 'loading') {
      return SizedBox(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => CustomPaint(
            painter: _SparklePainter(t: _ctrl.value, color: accent),
          ),
        ),
      );
    }

    // READY - report icon, same look as the set row's post-analysis button.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!(widget.exerciseId!, widget.setNumber!);
            },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: accent.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: accent, width: 2),
        ),
        child: Icon(
          Icons.assignment_outlined,
          size: size * 0.5,
          color: accent,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading painter - identical to AiSparkleIndicator.
// ---------------------------------------------------------------------------
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

    final double glowPulse = 0.5 + 0.5 * math.sin(angle);
    final glowPaint = Paint()
      ..color = color.withOpacity(0.14 + 0.12 * glowPulse)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, base * 0.10);
    canvas.drawCircle(center, circleR * 0.85, glowPaint);

    final particles = <List<double>>[
      [0.6, 0.62, 0.055, 0.00],
      [2.7, 0.68, 0.042, 0.33],
      [4.6, 0.58, 0.048, 0.66],
    ];

    for (final p in particles) {
      final double a = p[0] + angle * 0.7;
      final double r = circleR * p[1];
      final double dotR = base * p[2];
      final double op =
          0.35 + 0.55 * (0.5 + 0.5 * math.sin(angle * 2 + p[3] * 2 * math.pi));
      final dotCenter = center + Offset(math.cos(a), math.sin(a)) * r;
      final dotPaint = Paint()..color = color.withOpacity(op);
      canvas.drawCircle(dotCenter, dotR, dotPaint);
    }

    final double sparklePulse = 0.5 + 0.5 * math.sin(angle * 2);
    final double sparkleR = circleR * (0.42 + 0.16 * sparklePulse);
    final double rot = math.sin(angle) * 0.18;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rot);

    final path = _fourPointStar(sparkleR);

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
