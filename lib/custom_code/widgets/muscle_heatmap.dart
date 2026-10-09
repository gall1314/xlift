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

import 'dart:ui' as ui;
// MuscleHeatmap — FlutterFlow Custom Widget
// ------------------------------------------------------------------
// Interactive front/back body heatmap. Each muscle group is painted
// with an intensity color derived from (sets / target) for the week.
// Tap a muscle to highlight it and show a detail card.
//
// Zero external dependencies — pure Flutter (CustomPainter).
//
// FlutterFlow setup:
//   Widget name : MuscleHeatmap
//   Parameters  :
//     width  (double, nullable)
//     height (double, nullable)
//     setsJson (String, nullable)  -> JSON: {"quads":{"sets":14,"target":16}, ...}
//
// If setsJson is null/invalid, built-in demo data is used so the
// widget renders immediately in the FlutterFlow preview.
// ------------------------------------------------------------------

import 'dart:convert';
import 'dart:math' as math;

class MuscleHeatmap extends StatefulWidget {
  const MuscleHeatmap({
    super.key,
    this.width,
    this.height,
    this.setsJson,
  });

  final double? width;
  final double? height;
  final String? setsJson;

  @override
  State<MuscleHeatmap> createState() => _MuscleHeatmapState();
}

// ------------------------------------------------------------------
// Data
// ------------------------------------------------------------------

class _Muscle {
  const _Muscle(this.id, this.name, this.sources);
  final String id;
  final String name;
  final String sources;
}

const List<_Muscle> _muscles = [
  _Muscle('quads', 'ארבע ראשי', 'סקוואט, ספליט בולגרי'),
  _Muscle('hams', 'ירך אחורית', 'RDL, סטיף־לג, דדליפט'),
  _Muscle('glutes', 'ישבן', 'דדליפט, RDL'),
  _Muscle('chest', 'חזה', 'שכיבות סמיכה, מקבילים'),
  _Muscle('lats', 'גב רחב', 'מתח, חתירה בהטיה'),
  _Muscle('traps', 'טרפז', 'דדליפט (איזומטרי)'),
  _Muscle('delts', 'כתפיים', 'OHP'),
  _Muscle('biceps', 'יד קדמית', 'כפיפת מרפקים, מתח'),
  _Muscle('triceps', 'יד אחורית', 'מקבילים, שכיבות סמיכה'),
  _Muscle('abs', 'בטן', 'עבודה סטטית במורכבים'),
  _Muscle('lowback', 'גב תחתון', 'דדליפט, RDL'),
  _Muscle('calves', 'תאומים', '—'),
];

const Map<String, Map<String, int>> _demoSets = {
  'quads': {'sets': 14, 'target': 16},
  'hams': {'sets': 16, 'target': 16},
  'glutes': {'sets': 12, 'target': 14},
  'chest': {'sets': 10, 'target': 12},
  'lats': {'sets': 12, 'target': 16},
  'traps': {'sets': 5, 'target': 8},
  'delts': {'sets': 9, 'target': 12},
  'biceps': {'sets': 6, 'target': 10},
  'triceps': {'sets': 8, 'target': 10},
  'abs': {'sets': 4, 'target': 8},
  'lowback': {'sets': 7, 'target': 8},
  'calves': {'sets': 2, 'target': 6},
};

// ------------------------------------------------------------------
// Shapes — defined in a 160 x 300 design space per figure.
// kind: 0 = rounded rect, 1 = ellipse, 2 = polygon
// ------------------------------------------------------------------

class _Shape {
  const _Shape(this.muscleId, this.kind, this.a,
      {this.radius = 0, this.points = const []});
  final String muscleId;
  final int kind;
  final Rect a; // bounding rect (rect / ellipse)
  final double radius; // corner radius for rects
  final List<Offset> points; // polygon
}

// Front figure
const List<_Shape> _frontShapes = [
  _Shape('delts', 1, Rect.fromLTWH(41, 41, 18, 18)),
  _Shape('delts', 1, Rect.fromLTWH(101, 41, 18, 18)),
  _Shape('chest', 0, Rect.fromLTWH(58, 50, 21, 20), radius: 6),
  _Shape('chest', 0, Rect.fromLTWH(81, 50, 21, 20), radius: 6),
  _Shape('biceps', 1, Rect.fromLTWH(34, 71, 14, 26)),
  _Shape('biceps', 1, Rect.fromLTWH(112, 71, 14, 26)),
  _Shape('abs', 0, Rect.fromLTWH(64, 74, 32, 46), radius: 9),
  _Shape('quads', 0, Rect.fromLTWH(57, 140, 17, 62), radius: 8.5),
  _Shape('quads', 0, Rect.fromLTWH(86, 140, 17, 62), radius: 8.5),
  _Shape('calves', 1, Rect.fromLTWH(56, 214, 16, 36)),
  _Shape('calves', 1, Rect.fromLTWH(88, 214, 16, 36)),
];

// Back figure
const List<_Shape> _backShapes = [
  _Shape('traps', 2, Rect.zero, points: [
    Offset(64, 42),
    Offset(96, 42),
    Offset(88, 60),
    Offset(72, 60),
  ]),
  _Shape('delts', 1, Rect.fromLTWH(41, 41, 18, 18)),
  _Shape('delts', 1, Rect.fromLTWH(101, 41, 18, 18)),
  _Shape('lats', 0, Rect.fromLTWH(57, 60, 20, 36), radius: 8),
  _Shape('lats', 0, Rect.fromLTWH(83, 60, 20, 36), radius: 8),
  _Shape('triceps', 1, Rect.fromLTWH(34, 71, 14, 26)),
  _Shape('triceps', 1, Rect.fromLTWH(112, 71, 14, 26)),
  _Shape('lowback', 0, Rect.fromLTWH(68, 98, 24, 20), radius: 7),
  _Shape('glutes', 1, Rect.fromLTWH(57, 119, 22, 22)),
  _Shape('glutes', 1, Rect.fromLTWH(81, 119, 22, 22)),
  _Shape('hams', 0, Rect.fromLTWH(57, 146, 17, 56), radius: 8.5),
  _Shape('hams', 0, Rect.fromLTWH(86, 146, 17, 56), radius: 8.5),
  _Shape('calves', 1, Rect.fromLTWH(56, 214, 16, 36)),
  _Shape('calves', 1, Rect.fromLTWH(88, 214, 16, 36)),
];

// ------------------------------------------------------------------
// State
// ------------------------------------------------------------------

class _MuscleHeatmapState extends State<MuscleHeatmap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;
  String? _selected;
  late Map<String, Map<String, int>> _data;

  // Heat palette (teal ramp)
  static const Color _heatLow = Color(0xFFE1F5EE);
  static const Color _heatHigh = Color(0xFF1D9E75);
  static const Color _heatStroke = Color(0xFF0F6E56);

  @override
  void initState() {
    super.initState();
    _data = _parseSets(widget.setsJson);
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void didUpdateWidget(MuscleHeatmap old) {
    super.didUpdateWidget(old);
    if (old.setsJson != widget.setsJson) {
      _data = _parseSets(widget.setsJson);
    }
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  Map<String, Map<String, int>> _parseSets(String? json) {
    if (json == null || json.trim().isEmpty) return _demoSets;
    try {
      final raw = jsonDecode(json) as Map<String, dynamic>;
      final out = <String, Map<String, int>>{};
      raw.forEach((k, v) {
        final m = v as Map<String, dynamic>;
        out[k] = {
          'sets': (m['sets'] as num).toInt(),
          'target': math.max(1, (m['target'] as num).toInt()),
        };
      });
      return out.isEmpty ? _demoSets : out;
    } catch (_) {
      return _demoSets;
    }
  }

  double _ratio(String id) {
    final d = _data[id];
    if (d == null) return 0;
    return (d['sets']! / d['target']!).clamp(0.0, 1.0);
  }

  Color _heat(double ratio) => Color.lerp(_heatLow, _heatHigh, ratio)!;

  void _onTap(Offset local, Size figureSize, bool isBack) {
    final scale = figureSize.width / 160.0;
    final p = Offset(local.dx / scale, local.dy / scale);
    final shapes = isBack ? _backShapes : _frontShapes;
    for (final s in shapes) {
      if (_hit(s, p)) {
        setState(() => _selected = _selected == s.muscleId ? null : s.muscleId);
        return;
      }
    }
  }

  bool _hit(_Shape s, Offset p) {
    // Inflate slightly for comfortable touch targets.
    switch (s.kind) {
      case 0:
        return s.a.inflate(4).contains(p);
      case 1:
        final c = s.a.center;
        final rx = s.a.width / 2 + 4, ry = s.a.height / 2 + 4;
        final dx = (p.dx - c.dx) / rx, dy = (p.dy - c.dy) / ry;
        return dx * dx + dy * dy <= 1;
      case 2:
        return _polyBounds(s.points).inflate(4).contains(p);
    }
    return false;
  }

  Rect _polyBounds(List<Offset> pts) {
    double minX = pts.first.dx, maxX = pts.first.dx;
    double minY = pts.first.dy, maxY = pts.first.dy;
    for (final o in pts) {
      minX = math.min(minX, o.dx);
      maxX = math.max(maxX, o.dx);
      minY = math.min(minY, o.dy);
      maxY = math.max(maxY, o.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1C) : Colors.white;
    final insetBg = isDark ? const Color(0xFF2A2A28) : const Color(0xFFF4F3EE);
    final border = isDark ? const Color(0xFF3A3A38) : const Color(0xFFE4E2DA);
    final textPrimary =
        isDark ? const Color(0xFFF0EFEA) : const Color(0xFF20201E);
    final textMuted =
        isDark ? const Color(0xFF8E8D86) : const Color(0xFF8A897F);

    final selectedMuscle =
        _muscles.where((m) => m.id == _selected).cast<_Muscle?>().firstOrNull;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        width: widget.width,
        height: widget.height,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('מפת שרירים · השבוע',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textPrimary)),
                _Legend(low: _heatLow, high: _heatHigh, muted: textMuted),
              ],
            ),
            const SizedBox(height: 2),
            Text('לחץ על שריר לפרטים',
                style: TextStyle(fontSize: 12, color: textMuted)),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, c) {
              final figW = math.min(158.0, (c.maxWidth - 8) / 2);
              final figH = figW * 300 / 160;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _figure(figW, figH,
                      isBack: false,
                      label: 'קדמי',
                      insetBg: insetBg,
                      border: border,
                      muted: textMuted),
                  const SizedBox(width: 8),
                  _figure(figW, figH,
                      isBack: true,
                      label: 'אחורי',
                      insetBg: insetBg,
                      border: border,
                      muted: textMuted),
                ],
              );
            }),
            const SizedBox(height: 10),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _detailCard(
                  key: ValueKey(_selected ?? '_none'),
                  muscle: selectedMuscle,
                  insetBg: insetBg,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _figure(double w, double h,
      {required bool isBack,
      required String label,
      required Color insetBg,
      required Color border,
      required Color muted}) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _onTap(d.localPosition, Size(w, h), isBack),
          child: AnimatedBuilder(
            animation: _entry,
            builder: (context, _) => CustomPaint(
              size: Size(w, h),
              painter: _BodyPainter(
                isBack: isBack,
                t: Curves.easeOutCubic.transform(_entry.value),
                ratioOf: _ratio,
                heatOf: _heat,
                stroke: _heatStroke,
                selected: _selected,
                silhouetteFill: insetBg,
                silhouetteBorder: border,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: muted)),
      ],
    );
  }

  Widget _detailCard(
      {required Key key,
      required _Muscle? muscle,
      required Color insetBg,
      required Color textPrimary,
      required Color textMuted}) {
    if (muscle == null) {
      return Container(
        key: key,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
            color: insetBg, borderRadius: BorderRadius.circular(10)),
        child: Text('בחר שריר במפה',
            style: TextStyle(fontSize: 12, color: textMuted)),
      );
    }
    final d = _data[muscle.id] ?? const {'sets': 0, 'target': 1};
    final ratio = _ratio(muscle.id);
    final pct = (ratio * 100).round();
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: insetBg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: _heat(ratio), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${muscle.name} · ${d['sets']} סטים מתוך ${d['target']} ($pct%)',
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: textMuted.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(_heat(ratio)),
            ),
          ),
          const SizedBox(height: 6),
          Text('מקורות עיקריים: ${muscle.sources}',
              style: TextStyle(fontSize: 12.5, color: textMuted)),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

// ------------------------------------------------------------------
// Legend
// ------------------------------------------------------------------

class _Legend extends StatelessWidget {
  const _Legend({required this.low, required this.high, required this.muted});
  final Color low;
  final Color high;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    Widget swatch(double t) => Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: Color.lerp(low, high, t),
            borderRadius: BorderRadius.circular(3),
          ),
        );
    final label = TextStyle(fontSize: 10.5, color: muted);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('נמוך', style: label),
        const SizedBox(width: 3),
        swatch(0),
        swatch(0.33),
        swatch(0.66),
        swatch(1),
        const SizedBox(width: 3),
        Text('גבוה', style: label),
      ],
    );
  }
}

// ------------------------------------------------------------------
// Painter
// ------------------------------------------------------------------

class _BodyPainter extends CustomPainter {
  _BodyPainter({
    required this.isBack,
    required this.t,
    required this.ratioOf,
    required this.heatOf,
    required this.stroke,
    required this.selected,
    required this.silhouetteFill,
    required this.silhouetteBorder,
  });

  final bool isBack;
  final double t; // entry animation 0..1
  final double Function(String) ratioOf;
  final Color Function(double) heatOf;
  final Color stroke;
  final String? selected;
  final Color silhouetteFill;
  final Color silhouetteBorder;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 160.0;
    canvas.scale(scale);

    _paintSilhouette(canvas);

    final shapes = isBack ? _backShapes : _frontShapes;
    for (var i = 0; i < shapes.length; i++) {
      final s = shapes[i];
      // Staggered reveal: each shape fades its heat in with a delay.
      final delay = i / (shapes.length * 2);
      final local = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      final ratio = ratioOf(s.muscleId) * local;
      final isSel = selected == s.muscleId;

      final fill = Paint()..color = heatOf(ratio);
      final edge = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSel ? 2.4 : 0.6
        ..color = isSel ? stroke : stroke.withOpacity(0.45);

      switch (s.kind) {
        case 0:
          final rr = RRect.fromRectAndRadius(s.a, Radius.circular(s.radius));
          canvas.drawRRect(rr, fill);
          canvas.drawRRect(rr, edge);
          break;
        case 1:
          canvas.drawOval(s.a, fill);
          canvas.drawOval(s.a, edge);
          break;
        case 2:
          final path = Path()..addPolygon(s.points, true);
          canvas.drawPath(path, fill);
          canvas.drawPath(path, edge);
          break;
      }
    }
  }

  void _paintSilhouette(Canvas canvas) {
    final fill = Paint()..color = silhouetteFill;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = silhouetteBorder;
    final limb = Paint()
      ..color = silhouetteFill
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Head
    canvas.drawCircle(const Offset(80, 22), 13, fill);
    canvas.drawCircle(const Offset(80, 22), 13, edge);
    // Torso
    final torso = RRect.fromRectAndRadius(
        const Rect.fromLTWH(52, 38, 56, 98), const Radius.circular(18));
    canvas.drawRRect(torso, fill);
    canvas.drawRRect(torso, edge);
    // Arms
    canvas.drawLine(const Offset(50, 52), const Offset(30, 128), limb);
    canvas.drawLine(const Offset(110, 52), const Offset(130, 128), limb);
    // Legs
    final leg = Paint()
      ..color = silhouetteFill
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(66, 132), const Offset(64, 256), leg);
    canvas.drawLine(const Offset(94, 132), const Offset(96, 256), leg);
  }

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.t != t || old.selected != selected || old.isBack != isBack;
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
