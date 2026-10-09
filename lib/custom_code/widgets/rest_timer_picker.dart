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

class RestTimerPicker extends StatefulWidget {
  const RestTimerPicker({
    super.key,
    required this.width,
    required this.height,
    required this.initialSeconds,

    // FlutterFlow Action paramגeter: onChangedMs(milliseconds:int)
    this.onChangedMs,
  });

  final double width;
  final double height;
  final int initialSeconds;

  /// נזמן את האקשן עם הערך במילישניות בכל שינוי בחירה.
  /// החתימה הזו תתמפה ל-Action ב-FF עם פרמטר בשם "milliseconds" מסוג int.
  final Future<dynamic> Function(int milliseconds)? onChangedMs;

  @override
  State<RestTimerPicker> createState() => _RestTimerPickerState();
}

class _RestTimerPickerState extends State<RestTimerPicker> {
  static const int _kStep = 10;
  static const int _kMin = 10;
  static const int _kMax = 8 * 60;
  static const int _kOff = 0; // ערך מיוחד ל-off

  late final List<int> _values;
  late final FixedExtentScrollController _controller;
  late int _selected;

  @override
  void initState() {
    super.initState();

    // רשימת הערכים: קודם off (0), ואז 10..480 בקפיצות של 10
    _values = [
      _kOff,
      for (int s = _kMin; s <= _kMax; s += _kStep) s,
    ];

    int start;
    if (widget.initialSeconds <= 0) {
      // אם קיבלנו 0 או שלילי – נתחיל מ-off
      start = _kOff;
    } else {
      // אחרת – נצמיד לטווח ונעגל לצעד של 10 שניות
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
    final overlayBorder = theme.dividerColor;
    final overlayFill = theme.colorScheme.onSurface.withOpacity(0.06);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // קו היילייט מרכזי
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

          // גלגלת הערכים
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

              // האפטיק: עדין תמיד + קל כל 5 צעדים (מתייחס לאינדקס)
              HapticFeedback.selectionClick();
              if (i % 5 == 0) HapticFeedback.lightImpact();

              setState(() => _selected = seconds);

              // קריאת ה-Action (אם הוגדר), עם הערך במילישניות
              final action = widget.onChangedMs;
              if (action != null) {
                // אם זה off => 0ms, אחרת seconds * 1000
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
                    child: Text(_formatValue(s)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // פורמט להצגה: "off" עבור 0, אחרת mm:ss
  String _formatValue(int s) {
    if (s <= 0) return 'off';
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }
}

// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
