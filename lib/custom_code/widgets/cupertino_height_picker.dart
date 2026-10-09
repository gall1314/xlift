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

class CupertinoHeightPicker extends StatefulWidget {
  const CupertinoHeightPicker({
    super.key,
    required this.width,
    required this.height,
    required this.isCm,
    this.initialValue,
    this.onChanged,
  });

  final double width;
  final double height;

  final bool isCm; // true = cm, false = inch (feet+inches UI)
  final double? initialValue; // cm OR total inches

  /// value + unit flag (cm = 1, inch = 0)
  final Future<dynamic> Function(double value, int isCmInt)? onChanged;

  @override
  State<CupertinoHeightPicker> createState() => _CupertinoHeightPickerState();
}

class _CupertinoHeightPickerState extends State<CupertinoHeightPicker> {
  static const double _itemExtent = 48.0;

  // ---------- CM mode ----------
  late List<int> _cmValues;
  late int _cmCurrent;
  FixedExtentScrollController? _cmCtrl;

  // ---------- IN mode (feet + inches) ----------
  static const int _minFeet = 4;
  static const int _maxFeet = 7;

  int _feet = 5;
  int _inches = 8;

  FixedExtentScrollController? _feetCtrl;
  FixedExtentScrollController? _inchCtrl;

  @override
  void initState() {
    super.initState();
    _initFromInitial();
  }

  void _initFromInitial() {
    if (widget.isCm) {
      final min = 120;
      final max = 230;

      _cmValues = [for (int i = min; i <= max; i++) i];
      _cmCurrent =
          widget.initialValue?.round().clamp(min, max) ?? ((min + max) ~/ 2);

      _cmCtrl = FixedExtentScrollController(
        initialItem: _cmValues.indexOf(_cmCurrent),
      );
    } else {
      final totalInches = widget.initialValue?.round().clamp(48, 95) ?? 68;

      _feet = totalInches ~/ 12;
      _inches = totalInches % 12;

      _feetCtrl = FixedExtentScrollController(
        initialItem: (_feet - _minFeet).clamp(0, _maxFeet - _minFeet),
      );

      _inchCtrl = FixedExtentScrollController(
        initialItem: _inches.clamp(0, 11),
      );
    }
  }

  @override
  void didUpdateWidget(covariant CupertinoHeightPicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isCm != widget.isCm) {
      _cmCtrl?.dispose();
      _feetCtrl?.dispose();
      _inchCtrl?.dispose();
      _initFromInitial();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _cmCtrl?.dispose();
    _feetCtrl?.dispose();
    _inchCtrl?.dispose();
    super.dispose();
  }

  void _emitInches() {
    final total = (_feet * 12 + _inches).toDouble();
    widget.onChanged?.call(total, 0); // 0 = inch
  }

  TextStyle _valueStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ) ??
      const TextStyle(fontSize: 28, fontWeight: FontWeight.w700);

  TextStyle _unitStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.systemGrey,
          ) ??
      const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey);

  Widget _overlay(BuildContext context) => IgnorePointer(
        child: Container(
          height: _itemExtent,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Theme.of(context).dividerColor),
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _overlay(context),

          // ================= CM MODE =================
          if (widget.isCm)
            Row(
              children: [
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _cmCtrl,
                    itemExtent: _itemExtent,
                    useMagnifier: true,
                    magnification: 1.12,
                    selectionOverlay: const SizedBox.shrink(),
                    onSelectedItemChanged: (index) {
                      _cmCurrent = _cmValues[index];
                      HapticFeedback.selectionClick();
                      widget.onChanged?.call(
                        _cmCurrent.toDouble(),
                        1, // 1 = cm
                      );
                    },
                    children: _cmValues
                        .map(
                          (v) => Center(
                            child:
                                Text(v.toString(), style: _valueStyle(context)),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Text('cm', style: _unitStyle(context)),
                ),
              ],
            ),

          // ================= IN MODE (FEET + INCHES) =================
          if (!widget.isCm)
            Row(
              children: [
                // FEET
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _feetCtrl,
                    itemExtent: _itemExtent,
                    useMagnifier: true,
                    magnification: 1.12,
                    selectionOverlay: const SizedBox.shrink(),
                    onSelectedItemChanged: (index) {
                      _feet = _minFeet + index;
                      HapticFeedback.selectionClick();
                      _emitInches();
                    },
                    children: [
                      for (int f = _minFeet; f <= _maxFeet; f++)
                        Center(
                          child:
                              Text(f.toString(), style: _valueStyle(context)),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('ft', style: _unitStyle(context)),
                ),

                // INCHES
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _inchCtrl,
                    itemExtent: _itemExtent,
                    useMagnifier: true,
                    magnification: 1.12,
                    selectionOverlay: const SizedBox.shrink(),
                    onSelectedItemChanged: (index) {
                      _inches = index;
                      HapticFeedback.selectionClick();
                      _emitInches();
                    },
                    children: [
                      for (int i = 0; i <= 11; i++)
                        Center(
                          child:
                              Text(i.toString(), style: _valueStyle(context)),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Text('in', style: _unitStyle(context)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
