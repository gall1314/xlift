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

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class CupertinoBirthdayPicker extends StatefulWidget {
  const CupertinoBirthdayPicker({
    super.key,
    required this.width,
    required this.height,
    this.initialDate,
    this.onDateChanged, // yyyy-MM-dd
  });

  // FlutterFlow reגquired
  final double width;
  final double height;

  final DateTime? initialDate;
  final Future<dynamic> Function(String dateText)? onDateChanged;

  @override
  State<CupertinoBirthdayPicker> createState() =>
      _CupertinoBirthdayPickerState();
}

class _CupertinoBirthdayPickerState extends State<CupertinoBirthdayPicker> {
  static const double _itemExtent = 42.0;

  static const List<String> _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  late final DateTime _today;
  late final int _minYear;
  late final int _maxYear;

  late int _y, _m, _d;
  late List<int> _years, _days;

  late FixedExtentScrollController _yCtrl;
  late FixedExtentScrollController _mCtrl;
  late FixedExtentScrollController _dCtrl;

  @override
  void initState() {
    super.initState();

    _today = DateTime.now();
    _maxYear = _today.year;
    _minYear = _today.year - 120;

    final init = widget.initialDate ??
        DateTime(_today.year - 25, _today.month, _today.day);

    _y = init.year.clamp(_minYear, _maxYear);
    _m = init.month;
    _d = init.day;

    _years = [for (int y = _minYear; y <= _maxYear; y++) y];
    _days = _calcDays(_y, _m);
    _d = _d.clamp(1, _days.last);

    _yCtrl = FixedExtentScrollController(initialItem: _years.indexOf(_y));
    _mCtrl = FixedExtentScrollController(initialItem: _m - 1);
    _dCtrl = FixedExtentScrollController(initialItem: _days.indexOf(_d));
  }

  @override
  void dispose() {
    _yCtrl.dispose();
    _mCtrl.dispose();
    _dCtrl.dispose();
    super.dispose();
  }

  TextStyle _txt(BuildContext context) =>
      Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontSize: 20, fontWeight: FontWeight.w600) ??
      const TextStyle(fontSize: 20, fontWeight: FontWeight.w600);

  Widget _overlay(BuildContext context) => IgnorePointer(
        child: Container(
          height: _itemExtent,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final style = _txt(context);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _overlay(context),
          Row(
            children: [
              _wheel(
                controller: _yCtrl,
                values: _years,
                text: (v) => v.toString(),
                style: style,
                onChanged: (v) {
                  _y = v;
                  _days = _calcDays(_y, _m);
                  _d = _d.clamp(1, _days.last);
                  _dCtrl.jumpToItem(_days.indexOf(_d));
                  HapticFeedback.selectionClick();
                  _emit();
                },
              ),
              _wheel(
                controller: _mCtrl,
                values: List.generate(12, (i) => i + 1),
                text: (v) => _months[v - 1],
                style: style,
                onChanged: (v) {
                  _m = v;
                  _days = _calcDays(_y, _m);
                  _d = _d.clamp(1, _days.last);
                  _dCtrl.jumpToItem(_days.indexOf(_d));
                  HapticFeedback.selectionClick();
                  _emit();
                },
              ),
              _wheel(
                controller: _dCtrl,
                values: _days,
                text: (v) => v.toString().padLeft(2, '0'),
                style: style,
                onChanged: (v) {
                  _d = v;
                  HapticFeedback.selectionClick();
                  _emit();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required List<int> values,
    required String Function(int) text,
    required TextStyle style,
    required void Function(int) onChanged,
  }) {
    return Expanded(
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: _itemExtent,
        useMagnifier: true,
        magnification: 1.12,
        selectionOverlay: const SizedBox.shrink(),
        onSelectedItemChanged: (i) => onChanged(values[i]),
        children: values
            .map((v) => Center(child: Text(text(v), style: style)))
            .toList(),
      ),
    );
  }

  List<int> _calcDays(int year, int month) {
    final last = DateTime(year, month + 1, 0).day;

    if (year == _today.year && month == _today.month) {
      return [for (int d = 1; d <= _today.day; d++) d];
    }

    return [for (int d = 1; d <= last; d++) d];
  }

  void _emit() {
    final y = _y.toString().padLeft(4, '0');
    final m = _m.toString().padLeft(2, '0');
    final d = _d.toString().padLeft(2, '0');
    widget.onDateChanged?.call('$y-$m-$d');
  }
}

// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
