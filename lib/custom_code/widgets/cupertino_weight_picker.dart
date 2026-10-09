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

class CupertinoWeightPicker extends StatefulWidget {
  const CupertinoWeightPicker({
    super.key,
    required this.width,
    required this.height,
    required this.isKg, // true = KG, false = LBS
    this.initialValue, // value in selected unit
    this.onChanged,
  });

  // FlutterFlow required
  final double width;
  final double height;

  // Logic
  final bool isKg;
  final double? initialValue;
  final Future<dynamic> Function(double value)? onChanged;

  @override
  State<CupertinoWeightPicker> createState() => _CupertinoWeightPickerState();
}

class _CupertinoWeightPickerState extends State<CupertinoWeightPicker> {
  static const double _itemExtent = 42.0;

  late List<int> _integers;
  late List<int> _decimals; // 0–9

  late int _intPart;
  late int _decimalPart;

  late FixedExtentScrollController _intCtrl;
  late FixedExtentScrollController _decCtrl;

  @override
  void initState() {
    super.initState();

    final min = widget.isKg ? 30 : 70;
    final max = widget.isKg ? 200 : 440;

    _integers = [for (int i = min; i <= max; i++) i];
    _decimals = List.generate(10, (i) => i);

    final init = widget.initialValue ?? (min + max) / 2;
    _intPart = init.floor().clamp(min, max);
    _decimalPart = ((init - _intPart) * 10).round().clamp(0, 9);

    _intCtrl = FixedExtentScrollController(
      initialItem: _integers.indexOf(_intPart),
    );
    _decCtrl = FixedExtentScrollController(
      initialItem: _decimalPart,
    );
  }

  @override
  void dispose() {
    _intCtrl.dispose();
    _decCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final TextStyle intStyle = theme.textTheme.titleLarge?.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(fontSize: 30, fontWeight: FontWeight.w700);

    final TextStyle decStyle = theme.textTheme.bodyLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ) ??
        const TextStyle(fontSize: 20, fontWeight: FontWeight.w500);

    final TextStyle unitStyle = theme.textTheme.bodySmall?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ) ??
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

    Widget selectionOverlay = IgnorePointer(
      child: Container(
        height: _itemExtent,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.onSurface.withOpacity(0.06),
        ),
      ),
    );

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          selectionOverlay,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // INTEGER PART
              Expanded(
                flex: 3,
                child: CupertinoPicker(
                  scrollController: _intCtrl,
                  itemExtent: _itemExtent,
                  useMagnifier: true,
                  magnification: 1.12,
                  selectionOverlay: const SizedBox.shrink(),
                  onSelectedItemChanged: (i) {
                    _intPart = _integers[i];
                    HapticFeedback.selectionClick();
                    _emit();
                  },
                  children: _integers
                      .map(
                        (v) => Center(
                          child: Text(v.toString(), style: intStyle),
                        ),
                      )
                      .toList(),
                ),
              ),

              // DECIMAL PART
              Expanded(
                flex: 1,
                child: CupertinoPicker(
                  scrollController: _decCtrl,
                  itemExtent: _itemExtent,
                  useMagnifier: true,
                  magnification: 1.05,
                  selectionOverlay: const SizedBox.shrink(),
                  onSelectedItemChanged: (i) {
                    _decimalPart = _decimals[i];
                    HapticFeedback.selectionClick();
                    _emit();
                  },
                  children: _decimals
                      .map(
                        (v) => Center(
                          child: Text('.$v', style: decStyle),
                        ),
                      )
                      .toList(),
                ),
              ),

              // UNIT (STATIC)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  widget.isKg ? 'kg' : 'lbs',
                  style: unitStyle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _emit() {
    final value = _intPart + (_decimalPart / 10);
    widget.onChanged?.call(value);
  }
}

// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
