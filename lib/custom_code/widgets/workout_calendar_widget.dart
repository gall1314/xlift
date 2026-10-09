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

class WorkoutCalendarWidget extends StatefulWidget {
  const WorkoutCalendarWidget({
    super.key,
    required this.width,
    required this.height,
    this.scheduledDays, // ✅ nullable
    this.initialDate,
    this.viewMode = 'week',
    this.onDateSelected,
  });

  final double width;
  final double height;

  /// Nullable:
  /// [{ date: 'YYYY-MM-DD', hasWorkout: bool }]
  final List<dynamic>? scheduledDays;

  final DateTime? initialDate;

  /// 'week' | 'month' (month reserved for future use)
  final String viewMode;

  final Future<dynamic> Function(DateTime selectedDate)? onDateSelected;

  @override
  State<WorkoutCalendarWidget> createState() => _WorkoutCalendarWidgetState();
}

class _WorkoutCalendarWidgetState extends State<WorkoutCalendarWidget> {
  late DateTime _selectedDate;
  late PageController _pageController;

  static const List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _pageController = PageController(initialPage: 0);
  }

  // ---------- helpers ----------

  DateTime _startOfWeek(DateTime date) {
    final diff = date.weekday - DateTime.monday;
    return date.subtract(Duration(days: diff));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasWorkout(DateTime date) {
    // ✅ אם לא הועבר JSON → אין אימונים
    if (widget.scheduledDays == null || widget.scheduledDays!.isEmpty) {
      return false;
    }

    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    for (final item in widget.scheduledDays!) {
      if (item is! Map) continue;

      if (item['date'] == key && item['hasWorkout'] == true) {
        return true;
      }
    }

    return false;
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        itemBuilder: (context, pageIndex) {
          final baseWeek =
              _startOfWeek(_selectedDate).add(Duration(days: pageIndex * 7));

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final date = baseWeek.add(Duration(days: i));
              final isSelected = _isSameDay(date, _selectedDate);
              final hasWorkout = _hasWorkout(date);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = date);
                    HapticFeedback.selectionClick();
                    widget.onDateSelected?.call(date);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weekDays[i],
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${date.day}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (hasWorkout)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
