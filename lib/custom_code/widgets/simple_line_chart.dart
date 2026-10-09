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

import 'dart:math';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';

class SimpleLineChart extends StatefulWidget {
  const SimpleLineChart({
    super.key,
    required this.width,
    required this.height,
    required this.xLabels,
    required this.yValues,
    required this.lineColor,
    this.fillColor,
    this.maxXTicks = 4,
    this.maxYTicks = 4,
    this.forceZeroMin = false,
  });

  final double width;
  final double height;
  final List<String> xLabels;
  final List<double> yValues;
  final Color lineColor;
  final Color? fillColor;
  final int maxXTicks;
  final int maxYTicks;
  final bool forceZeroMin;

  @override
  State<SimpleLineChart> createState() => _SimpleLineChartState();
}

class _SimpleLineChartState extends State<SimpleLineChart> {
  static const EdgeInsets padding = EdgeInsets.fromLTRB(40, 20, 20, 36);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: CustomPaint(
        painter: _ChartPainter(
          xLabels: widget.xLabels,
          yValues: widget.yValues,
          lineColor: widget.lineColor,
          fillColor: widget.fillColor,
          maxXTicks: widget.maxXTicks,
          maxYTicks: widget.maxYTicks,
          forceZeroMin: widget.forceZeroMin,
          padding: padding,
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.xLabels,
    required this.yValues,
    required this.lineColor,
    required this.maxXTicks,
    required this.maxYTicks,
    required this.forceZeroMin,
    required this.padding,
    this.fillColor,
  });

  final List<String> xLabels;
  final List<double> yValues;
  final Color lineColor;
  final Color? fillColor;
  final int maxXTicks;
  final int maxYTicks;
  final bool forceZeroMin;
  final EdgeInsets padding;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.left - padding.right,
      size.height - padding.top - padding.bottom,
    );

    final minVal = yValues.reduce(min);
    final maxVal = yValues.reduce(max);

    final minY = forceZeroMin ? 0.0 : minVal;
    final maxY = maxVal == minVal ? minVal + 1 : maxVal;

    _drawGrid(canvas, rect);
    _drawAreaAndLine(canvas, rect, minY, maxY);
    _drawYLabels(canvas, rect, minY, maxY);
    _drawXLabels(canvas, rect);
  }

  void _drawGrid(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.08)
      ..strokeWidth = 1;

    final count = min(maxYTicks, 4);

    for (int i = 0; i < count; i++) {
      final t = count == 1 ? 0.0 : i / (count - 1);
      final y = rect.bottom - rect.height * t;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
    }
  }

  void _drawAreaAndLine(Canvas canvas, Rect rect, double minY, double maxY) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final areaPaint = Paint()
      ..color = (fillColor ?? lineColor.withOpacity(0.12))
      ..style = PaintingStyle.fill;

    final path = Path();
    final areaPath = Path();

    for (int i = 0; i < yValues.length; i++) {
      final t = yValues.length == 1 ? 0.5 : i / (yValues.length - 1);
      final x = rect.left + rect.width * t;
      final norm = (yValues[i] - minY) / (maxY - minY);
      final y = rect.bottom - rect.height * norm;

      if (i == 0) {
        path.moveTo(x, y);
        areaPath.moveTo(x, rect.bottom);
        areaPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        areaPath.lineTo(x, y);
      }
    }

    areaPath.lineTo(rect.right, rect.bottom);
    areaPath.close();

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(path, linePaint);
  }

  void _drawYLabels(Canvas canvas, Rect rect, double minY, double maxY) {
    final style = TextStyle(
      color: Colors.grey.withOpacity(0.6),
      fontSize: 11,
    );

    final count = min(maxYTicks, 4);

    for (int i = 0; i < count; i++) {
      final t = count == 1 ? 0.0 : i / (count - 1);
      final value = minY + (maxY - minY) * t;
      final y = rect.bottom - rect.height * t;

      final tp = TextPainter(
        text: TextSpan(text: value.round().toString(), style: style),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      double dx = rect.left - tp.width - 8;
      double dy = y - tp.height / 2;

      if (i == 0) {
        dy -= 6; // ⬆️ Y label קצת למעלה במפגש
      }

      tp.paint(canvas, Offset(dx, dy));
    }
  }

  void _drawXLabels(Canvas canvas, Rect rect) {
    final style = TextStyle(
      color: Colors.grey.withOpacity(0.6),
      fontSize: 11,
    );

    final count = min(maxXTicks, xLabels.length);

    for (int i = 0; i < count; i++) {
      final index =
          count == 1 ? 0 : (i * (xLabels.length - 1) / (count - 1)).round();
      final t = xLabels.length == 1 ? 0.5 : index / (xLabels.length - 1);
      final x = rect.left + rect.width * t;

      final tp = TextPainter(
        text: TextSpan(
          text: _formatDateShort(xLabels[index]),
          style: style,
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      double dx = x - tp.width / 2;
      double dy = rect.bottom + 6;

      if (i == 0) {
        dx += 10; // ➡️ X label קצת ימינה במפגש
      }

      tp.paint(canvas, Offset(dx, dy));
    }
  }

  String _formatDateShort(String timeStamp) {
    try {
      DateTime dt;
      if (RegExp(r'^\d+$').hasMatch(timeStamp)) {
        dt =
            DateTime.fromMillisecondsSinceEpoch(int.parse(timeStamp)).toLocal();
      } else {
        dt = DateTime.parse(timeStamp).toLocal();
      }

      final now = DateTime.now();
      return dt.year == now.year
          ? DateFormat('MMM d').format(dt)
          : DateFormat('MMM d, y').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
