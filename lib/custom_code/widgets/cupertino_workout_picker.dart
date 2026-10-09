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
import 'dart:math' as math;

class CupertinoWorkoutPicker extends StatefulWidget {
  const CupertinoWorkoutPicker({
    super.key,
    required this.isDatePicker, // true = Date, false = Durationff
    this.initialDate, // לתאריך
    this.initialMilliseconds, // למשך (ms)
    this.width,
    this.height,
    this.onDatePickedText, // (String "yyyy-MM-dd HH:mm:ss")כ
    this.onDurationPickedMs, // (int milliseconds)
  });

  final bool isDatePicker;
  final DateTime? initialDate;
  final int? initialMilliseconds;
  final double? width;
  final double? height;

  final Future<dynamic> Function(String dateText)? onDatePickedText;
  final Future<dynamic> Function(int milliseconds)? onDurationPickedMs;

  @override
  State<CupertinoWorkoutPicker> createState() => _CupertinoWorkoutPickerState();
}

class _CupertinoWorkoutPickerState extends State<CupertinoWorkoutPicker> {
  // ---- CONSTS ----
  static const double _kItemExtent = 42.0;
  static const int _kMaxHours = 5;

  // ---- DATE STATE (3 wheels, with strict range) ----
  late DateTime _now, _minDate, _maxDate;
  late int _y, _m, _d; // year / month / day
  late List<int> _years, _months, _days;
  late FixedExtentScrollController _yCtrl, _mCtrl, _dCtrl;

  // ---- DURATION STATE (2 wheels) ----
  late int _hour; // 0..5
  late int _minute; // 0..59 OR 0 when hour==5

  @override
  void initState() {
    super.initState();

    // Bounds: today back to a year (date-only, no times)
    _now = DateTime.now();
    _maxDate = DateTime(_now.year, _now.month, _now.day);
    _minDate = _maxDate.subtract(const Duration(days: 365));

    // Init DATE
    final initD =
        _clampDate(widget.initialDate ?? _maxDate, _minDate, _maxDate);
    _y = initD.year;
    _m = initD.month;
    _d = initD.day;

    _years = [for (int y = _minDate.year; y <= _maxDate.year; y++) y];
    _months = _calcMonthsForYear(_y);
    _days = _calcDaysForYearMonth(_y, _m);

    _yCtrl = FixedExtentScrollController(initialItem: _years.indexOf(_y));
    _mCtrl = FixedExtentScrollController(initialItem: _months.indexOf(_m));
    _dCtrl = FixedExtentScrollController(
        initialItem: math.max(0, _days.indexOf(_d)));

    // Init DURATION
    final initMs =
        (widget.initialMilliseconds ?? 0).clamp(0, _kMaxHours * 3600 * 1000);
    _hour = (initMs ~/ 3600000);
    _minute = ((initMs % 3600000) ~/ 60000);
    if (_hour == _kMaxHours) _minute = 0;
  }

  @override
  void dispose() {
    _yCtrl.dispose();
    _mCtrl.dispose();
    _dCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width ?? double.infinity;
    final h = widget.height ?? 260.0;
    final theme = Theme.of(context);

    // Single highlight overlay (one rectangle across all wheels)
    Widget _overlay() => IgnorePointer(
          child: Container(
            height: _kItemExtent,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
              color: theme.colorScheme.onSurface.withOpacity(0.06),
            ),
          ),
        );

    TextStyle _txt() =>
        theme.textTheme.titleMedium
            ?.copyWith(fontSize: 20, fontWeight: FontWeight.w600) ??
        const TextStyle(fontSize: 20, fontWeight: FontWeight.w600);

    if (widget.isDatePicker) {
      // ----- CUSTOM DATE (years / months / days), only valid range shown -----
      return SafeArea(
        top: false,
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _overlay(),
              Row(
                children: [
                  _wheel<int>(
                    controller: _yCtrl,
                    values: _years,
                    selectedIndex: _years.indexOf(_y),
                    text: (y) => y.toString(),
                    style: _txt(),
                    onChangedIndex: (i) {
                      _y = _years[i];
                      HapticFeedback.selectionClick();

                      // Rebuild allowed months for chosen year
                      _months = _calcMonthsForYear(_y);
                      if (!_months.contains(_m)) {
                        _m = (_y == _minDate.year)
                            ? _months.first
                            : _months.last;
                        _mCtrl.jumpToItem(_months.indexOf(_m));
                      }

                      // Rebuild allowed days
                      _days = _calcDaysForYearMonth(_y, _m);
                      if (!_days.contains(_d)) {
                        _d = _clipDay(_d, _days);
                        _dCtrl.jumpToItem(_days.indexOf(_d));
                      }

                      _emitDate();
                    },
                  ),
                  _wheel<int>(
                    controller: _mCtrl,
                    values: _months,
                    selectedIndex: _months.indexOf(_m),
                    text: (m) => _two(m), // month number
                    style: _txt(),
                    onChangedIndex: (i) {
                      _m = _months[i];
                      HapticFeedback.selectionClick();

                      _days = _calcDaysForYearMonth(_y, _m);
                      if (!_days.contains(_d)) {
                        _d = _clipDay(_d, _days);
                        _dCtrl.jumpToItem(_days.indexOf(_d));
                      }

                      _emitDate();
                    },
                  ),
                  _wheel<int>(
                    controller: _dCtrl,
                    values: _days,
                    selectedIndex: _days.indexOf(_d),
                    text: (d) => _two(d),
                    style: _txt(),
                    onChangedIndex: (i) {
                      _d = _days[i];
                      HapticFeedback.selectionClick();
                      _emitDate();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // ----- DURATION (0..5h; when 5h -> minutes=00 only) -----
    final hours = List<int>.generate(_kMaxHours + 1, (i) => i);
    final minutes =
        (_hour == _kMaxHours) ? [0] : List<int>.generate(60, (i) => i);

    return SafeArea(
      top: false,
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _overlay(),
            Row(
              children: [
                _wheel<int>(
                  values: hours,
                  selectedIndex: hours.indexOf(_hour),
                  text: (v) => _two(v),
                  style: _txt(),
                  suffix: 'h',
                  onChangedIndex: (i) {
                    _hour = hours[i];
                    if (_hour == _kMaxHours) _minute = 0;
                    HapticFeedback.selectionClick();
                    setState(() {}); // re-render minutes range
                    _emitDurationMs();
                  },
                ),
                _wheel<int>(
                  values: minutes,
                  selectedIndex:
                      minutes.indexOf(_minute.clamp(0, minutes.last)),
                  text: (v) => _two(v),
                  style: _txt(),
                  suffix: 'm',
                  onChangedIndex: (i) {
                    _minute = minutes[i];
                    HapticFeedback.selectionClick();
                    _emitDurationMs();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- generic wheel (with optional controller) ----------
  Widget _wheel<T>({
    FixedExtentScrollController? controller,
    required List<T> values,
    required int selectedIndex,
    required String Function(T v) text,
    required void Function(int newIndex) onChangedIndex,
    TextStyle? style,
    String? suffix,
  }) {
    final ctrl =
        controller ?? FixedExtentScrollController(initialItem: selectedIndex);

    return Expanded(
      child: CupertinoPicker(
        scrollController: ctrl,
        itemExtent: _kItemExtent,
        useMagnifier: true,
        magnification: 1.12,
        selectionOverlay:
            const SizedBox.shrink(), // ❗ רק ה-highlight הכללי מבחוץ
        onSelectedItemChanged: onChangedIndex,
        children: values.map((v) {
          return Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(text(v), style: style),
                if (suffix != null) ...[
                  const SizedBox(width: 4),
                  Text(suffix, style: style),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------- date helpers ----------
  List<int> _calcMonthsForYear(int year) {
    final from = (year == _minDate.year) ? _minDate.month : 1;
    final to = (year == _maxDate.year) ? _maxDate.month : 12;
    return [for (int m = from; m <= to; m++) m];
  }

  List<int> _calcDaysForYearMonth(int year, int month) {
    final first = DateTime(year, month, 1);
    final last = DateTime(year, month + 1, 0).day;
    int from = 1, to = last;
    if (year == _minDate.year && month == _minDate.month) from = _minDate.day;
    if (year == _maxDate.year && month == _maxDate.month) to = _maxDate.day;
    return [for (int d = from; d <= to; d++) d];
  }

  int _clipDay(int wanted, List<int> allowed) {
    if (allowed.isEmpty) return 1;
    if (allowed.contains(wanted)) return wanted;
    return allowed.last;
  }

  void _emitDate() {
    // בוחר תאריך עם זמן השעה/דקה/שנייה הנוכחיים של המכשיר
    final selected = DateTime(_y, _m, _d, _now.hour, _now.minute, _now.second);
    final txt = _formatDateTime(selected);
    widget.onDatePickedText?.call(txt);
  }

  void _emitDurationMs() {
    final ms = (_hour * 3600000) + (_minute * 60000);
    widget.onDurationPickedMs?.call(ms);
  }

  DateTime _clampDate(DateTime d, DateTime min, DateTime max) {
    if (d.isAfter(max)) return max;
    if (d.isBefore(min)) return min;
    return d;
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final mo = _two(dt.month);
    final da = _two(dt.day);
    final h = _two(dt.hour);
    final mi = _two(dt.minute);
    final s = _two(dt.second);
    return '$y-$mo-$da $h:$mi:$s';
  }
}

// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
