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

class WeightStepperTextField extends StatefulWidget {
  const WeightStepperTextField({
    super.key,
    required this.width,
    required this.height,
    required this.initialWeight,
    required this.equipment,
    required this.isKg,
    this.onChanged,
  });

  final double width;
  final double height;
  final double? initialWeight;
  final String equipment;
  final bool isKg;
  final Future<dynamic> Function(double? value)? onChanged;

  @override
  State<WeightStepperTextField> createState() => _WeightStepperTextFieldState();
}

class _WeightStepperTextFieldState extends State<WeightStepperTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  final _weightInputFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'^\d*\.?\d*$'),
  );

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialWeight != null ? _format(widget.initialWeight!) : '',
    );

    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _normalizeValue();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  double? get _currentValue {
    final t = _controller.text.trim();
    if (t.isEmpty || t == '.') return null;
    return double.tryParse(t);
  }

  String _format(double v) {
    return (v % 1 == 0) ? v.toInt().toString() : v.toStringAsFixed(1);
  }

  void _normalizeValue() {
    final value = _currentValue;
    if (value == null) return;

    final normalized = (value * 2).round() / 2;

    final text = _format(normalized);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

    widget.onChanged?.call(normalized);
  }

  Future<void> _apply(bool isIncrement) async {
    final newValue = adjustWeight(
      _currentValue,
      widget.equipment,
      widget.isKg,
      isIncrement,
    );

    if (newValue == null) return;

    final text = _format(newValue);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

    await widget.onChanged?.call(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _roundButton(
            icon: Icons.remove,
            onTap: () => _apply(false),
          ),
          Container(
            width: 95,
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E3E7)),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textAlign: TextAlign.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_weightInputFormatter],
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
              },
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
          _roundButton(
            icon: Icons.add,
            onTap: () => _apply(true),
          ),
        ],
      ),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 40,
      height: 40,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primaryBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Icon(
            icon,
            size: 20,
            color: FlutterFlowTheme.of(context).primaryText,
          ),
        ),
      ),
    );
  }
}
