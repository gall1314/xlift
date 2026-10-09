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

class WeeklyDayTabsWidget extends StatefulWidget {
  const WeeklyDayTabsWidget({
    super.key,
    required this.width,
    required this.height,
    this.mondayFirst = false,
    this.initialDayIndex = 0,
    this.hasWorkoutPerDay,
    this.selectedColor,
    this.indicatorColor,
    this.onDayChanged,
  });

  final double width;
  final double height;

  /// true = Mon → Sun, false = Sun → Sat
  final bool mondayFirst;

  /// Selected day index (0–6)
  final int initialDayIndex;

  /// List of 7 booleans indicating if a workout exists on that day
  final List<bool>? hasWorkoutPerDay;

  /// Selected tab text / icon color (optional)
  final Color? selectedColor;

  /// Color for "has workout" indicator (optional)
  final Color? indicatorColor;

  /// Callback on day change
  final Future<dynamic> Function(int dayIndex)? onDayChanged;

  @override
  State<WeeklyDayTabsWidget> createState() => _WeeklyDayTabsWidgetState();
}

class _WeeklyDayTabsWidgetState extends State<WeeklyDayTabsWidget> {
  static const _daysSundayFirst = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat'
  ];
  static const _daysMondayFirst = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  late final List<String> _days;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _days = widget.mondayFirst ? _daysMondayFirst : _daysSundayFirst;
    _selectedIndex = widget.initialDayIndex.clamp(0, 6);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final selectedColor = widget.selectedColor ?? theme.colorScheme.primary;

    final indicatorColor =
        widget.indicatorColor ?? theme.colorScheme.onSurfaceVariant;

    final hasWorkout = widget.hasWorkoutPerDay ?? List<bool>.filled(7, false);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Row(
        children: List.generate(_days.length, (index) {
          final isSelected = index == _selectedIndex;
          final showWorkout = hasWorkout[index];

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_selectedIndex == index) return;

                setState(() => _selectedIndex = index);
                HapticFeedback.selectionClick();
                widget.onDayChanged?.call(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  // ❌ no pill background
                  color: Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      width: 2,
                      color: isSelected ? selectedColor : Colors.transparent,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _days[index],
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? selectedColor
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (showWorkout)
                      Icon(
                        Icons.fitness_center,
                        size: 12,
                        color: isSelected
                            ? selectedColor
                            : indicatorColor.withOpacity(0.6),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
