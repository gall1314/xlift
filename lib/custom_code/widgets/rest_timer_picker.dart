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
import 'package:flutter/services.dart';

// ---------------- Localization ----------------

String _langOf(BuildContext ctx) {
  try {
    final l = FFLocalizations.of(ctx).languageCode.trim().toLowerCase();
    return l.isEmpty ? 'en' : l;
  } catch (_) {
    return 'en';
  }
}

const Map<String, String> _kOffLabel = {
  'en': 'off',
  'es': 'apagado',
  'he': 'כבוי',
  'de': 'aus',
  'fr': 'off',
};

/// Rest-time wheel: off, then 0:10 → 8:00 in 10s steps.
///
/// Emits milliseconds.
class RestTimerPicker extends StatefulWidget {
  const RestTimerPicker({
    super.key,
    required this.width,
    required this.height,
    required this.initialSeconds,
    this.onChangedMs,
  });

  final double width;
  final double height;
  final int initialSeconds;

  /// FF Action with an int parameter named "milliseconds".
  final Future<dynamic> Function(int milliseconds)? onChangedMs;

  @override
  State<RestTimerPicker> createState() => _RestTimerPickerState();
}

class _RestTimerPickerState extends State<RestTimerPicker> {
  static const int _kStep = 10;
  static const int _kMin = 10;
  static const int _kMax = 8 * 60;
  static const int _kOff = 0;

  late final List<int> _values;
  late final FixedExtentScrollController _controller;
  late int _selected;

  @override
  void initState() {
    super.initState();

    _values = [
      _kOff,
      for (int s = _kMin; s <= _kMax; s += _kStep) s,
    ];

    int start;
    if (widget.initialSeconds <= 0) {
      start = _kOff;
    } else {
      start = widget.initialSeconds.clamp(_kMin, _kMax);
      start = ((start / _kStep).round() * _kStep).clamp(_kMin, _kMax);
    }

    _selected = start;
    final idx = _values.indexOf(start);
    _controller = FixedExtentScrollController(initialItem: idx >= 0 ? idx : 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String lang = _langOf(context);
    final String offLabel = _kOffLabel[lang] ?? _kOffLabel['en']!;
    final overlayBorder = theme.dividerColor;
    final overlayFill = theme.colorScheme.onSurface.withOpacity(0.06);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: Container(
              height: 42,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: overlayBorder),
                color: overlayFill,
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: _controller,
            physics: const FixedExtentScrollPhysics(),
            itemExtent: 42,
            perspective: 0.002,
            useMagnifier: true,
            magnification: 1.12,
            overAndUnderCenterOpacity: 0.6,
            onSelectedItemChanged: (i) async {
              final seconds = _values[i];

              HapticFeedback.selectionClick();
              if (i % 5 == 0) HapticFeedback.lightImpact();

              setState(() => _selected = seconds);

              final action = widget.onChangedMs;
              if (action != null) {
                final ms = seconds <= 0 ? 0 : seconds * 1000;
                await action(ms);
              }
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (ctx, i) {
                if (i == null || i < 0 || i >= _values.length) return null;
                final s = _values[i];
                final isSel = s == _selected;

                return Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: isSel ? 20 : 18,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel
                              ? theme.colorScheme.onSurface
                              : theme.textTheme.titleMedium?.color,
                        ) ??
                        const TextStyle(fontSize: 18),
                    child: Text(
                      s <= 0 ? offLabel : _mmss(s),
                      // Clock digits always LTR; the "off" word follows its
                      // own script.
                      textDirection: s <= 0 ? null : ui.TextDirection.ltr,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _mmss(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }
}

// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
