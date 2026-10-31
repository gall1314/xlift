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

import 'dart:ui' as ui show TextDirection;

const Set<String> _kRtl = {'he', 'ar'};

String _langOf(BuildContext ctx) {
  try {
    final l = FFLocalizations.of(ctx).languageCode.trim().toLowerCase();
    return l.isEmpty ? 'en' : l;
  } catch (_) {
    return 'en';
  }
}

/// Three small pills showing how many AI generations were used in the last 7
/// days.
///
/// Fills from the start edge (left in LTR, right in RTL).
class GenerationMeter extends StatefulWidget {
  const GenerationMeter({
    super.key,
    this.width,
    this.height,
    required this.generationDates,
    this.usedColor,
    this.emptyColor,
  });

  final double? width;
  final double? height;
  final List<String> generationDates;
  final Color? usedColor;
  final Color? emptyColor;

  @override
  State<GenerationMeter> createState() => _GenerationMeterState();
}

class _GenerationMeterState extends State<GenerationMeter> {
  @override
  Widget build(BuildContext context) {
    const int limit = 3;

    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    int used = 0;
    for (final d in widget.generationDates) {
      final parsed = DateTime.tryParse(d);
      if (parsed != null && parsed.isAfter(cutoff)) used++;
    }
    if (used > limit) used = limit;

    final Color filled = widget.usedColor ?? const Color(0xFF14B8A6);
    final Color empty = widget.emptyColor ?? const Color(0xFFD1D5DB);
    final bool rtl = _kRtl.contains(_langOf(context));

    return SizedBox(
      width: widget.width,
      height: widget.height ?? 6,
      child: Row(
        textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(limit, (i) {
          return Container(
            width: 18,
            height: widget.height ?? 6,
            margin: EdgeInsetsDirectional.only(end: i < limit - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: i < used ? filled : empty,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
