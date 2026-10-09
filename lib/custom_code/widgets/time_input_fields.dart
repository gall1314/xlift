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

import '/custom_code/widgets/index.dart';
import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';

import 'package:flutter/services.dart';

class TimeInputFields extends StatefulWidget {
  const TimeInputFields({
    super.key,
    required this.width,
    required this.height,
    this.textSize = 16,
    this.onChanged,
  });

  final double width;
  final double height;
  final double textSize;

  // FlutterFlow Action: onChanged(durationMs)
  final Future<dynamic> Function(int? durationMs)? onChanged;

  @override
  State<TimeInputFields> createState() => _TimeInputFieldsState();
}

class _TimeInputFieldsState extends State<TimeInputFields> {
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _focusNodes = List.generate(4, (_) => FocusNode());

  static const FontWeight _fontWeight = FontWeight.w700;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // Returns null if duration == 0
  int? _computeDurationMs() {
    int v(int i) => int.tryParse(_controllers[i].text) ?? 0;

    final minutes = v(0) * 10 + v(1);
    final seconds = v(2) * 10 + v(3);

    final totalMs = (minutes * 60 + seconds) * 1000;
    return totalMs > 0 ? totalMs : null;
  }

  void _notifyChange() {
    final cb = widget.onChanged;
    if (cb == null) return;
    cb(_computeDurationMs());
  }

  void _onChanged(int index, String value) {
    // Move forward after typing
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }

    // Move back on delete
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    _notifyChange();
  }

  Widget _buildField(int index) {
    return SizedBox(
      width: 24,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(
          fontSize: widget.textSize,
          fontWeight: _fontWeight,
          height: 1.1,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          counterText: '',
          hintText: '0',
          hintStyle: TextStyle(
            fontSize: widget.textSize,
            fontWeight: FontWeight.w400,
            color: Colors.grey.withValues(alpha: 0.4),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 2),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onTap: () {
          _controllers[index].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controllers[index].text.length,
          );
        },
        onChanged: (v) => _onChanged(index, v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildField(0),
          const SizedBox(width: 2),
          _buildField(1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              ':',
              style: TextStyle(
                fontSize: widget.textSize,
                fontWeight: _fontWeight,
                height: 1.1,
                color: Colors.grey.withValues(alpha: 0.6),
              ),
            ),
          ),
          _buildField(2),
          const SizedBox(width: 2),
          _buildField(3),
        ],
      ),
    );
  }
}

// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
