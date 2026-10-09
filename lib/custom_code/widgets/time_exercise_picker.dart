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

class TimeExercisePicker extends StatefulWidget {
  const TimeExercisePicker({
    super.key,
    required this.width,
    required this.height,
    required this.initialMilliseconds,
    this.onChangedMs,
  });

  final double width;
  final double height;

  /// קלט במילגישניות
  final int initialMilliseconds;

  /// פלכט במילישניות
  final Future<dynamic> Function(int milliseconds)? onChangedMs;

  @override
  State<TimeExercisePicker> createState() => _TimeExercisePickerState();
}

class _TimeExercisePickerState extends State<TimeExercisePicker> {
  static const int _maxMinutes = 10;

  late final FixedExtentScrollController _minController;
  late final FixedExtentScrollController _secController;

  late int _minutes;
  late int _seconds;

  @override
  void initState() {
    super.initState();

    final totalSeconds = (widget.initialMilliseconds <= 0)
        ? 0
        : (widget.initialMilliseconds ~/ 1000).clamp(0, _maxMinutes * 60);

    _minutes = totalSeconds ~/ 60;
    _seconds = totalSeconds % 60;

    _minController = FixedExtentScrollController(initialItem: _minutes);
    _secController = FixedExtentScrollController(initialItem: _seconds);
  }

  @override
  void dispose() {
    _minController.dispose();
    _secController.dispose();
    super.dispose();
  }

  void _emit() async {
    final action = widget.onChangedMs;
    if (action != null) {
      final totalMs = ((_minutes * 60) + _seconds) * 1000;
      await action(totalMs);
    }
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int count,
    required int selected,
    required void Function(int) onChanged,
    required ThemeData theme,
  }) {
    final overlayBorder = theme.dividerColor;
    final overlayFill = theme.colorScheme.onSurface.withOpacity(0.06);

    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: Container(
              height: 42,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: overlayBorder),
                color: overlayFill,
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: controller,
            physics: const FixedExtentScrollPhysics(),
            itemExtent: 42,
            perspective: 0.002,
            useMagnifier: true,
            magnification: 1.12,
            overAndUnderCenterOpacity: 0.6,
            onSelectedItemChanged: (i) {
              HapticFeedback.selectionClick();
              if (i % 5 == 0) HapticFeedback.lightImpact();
              onChanged(i);
              _emit();
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: count,
              builder: (ctx, i) {
                final isSel = i == selected;
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
                    child: Text(i.toString().padLeft(2, '0')),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Row(
        children: [
          _buildWheel(
            controller: _minController,
            count: _maxMinutes + 1,
            selected: _minutes,
            theme: theme,
            onChanged: (v) => setState(() => _minutes = v),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              ':',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          _buildWheel(
            controller: _secController,
            count: 60,
            selected: _seconds,
            theme: theme,
            onChanged: (v) => setState(() => _seconds = v),
          ),
        ],
      ),
    );
  }
}

// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
