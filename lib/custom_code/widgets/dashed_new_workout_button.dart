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

import 'package:dotted_border/dotted_border.dart';

class DashedNewWorkoutButton extends StatefulWidget {
  const DashedNewWorkoutButton({
    super.key,
    this.width,
    this.height,
    required this.buttonText,
    this.onTap,
  });

  final double? width;
  final double? height;
  final String buttonText;
  final Future Function()? onTap;

  @override
  State<DashedNewWorkoutButton> createState() => _DashedNewWorkoutButtonState();
}

class _DashedNewWorkoutButtonState extends State<DashedNewWorkoutButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (widget.onTap != null) {
          await widget.onTap!();
        }
      },
      child: DottedBorder(
        color: const Color(0xFF1D9E75),
        strokeWidth: 1.5,
        dashPattern: const [6, 4],
        borderType: BorderType.RRect,
        radius: const Radius.circular(14),
        child: Container(
          width: widget.width ?? double.infinity,
          height: (widget.height ?? 48) - 3,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 18, color: Color(0xFF0F6E56)),
              const SizedBox(width: 6),
              Text(
                widget.buttonText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F6E56),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
