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

class TwinProgressBar extends StatefulWidget {
  const TwinProgressBar({
    super.key,
    required this.width,
    required this.height,
    required this.leftValue,
    required this.rightValue,
    this.leftColor,
    this.rightColor,
  });

  final double width;
  final double height;

  final double leftValue;
  final double rightValue;

  final Color? leftColor;
  final Color? rightColor;

  @override
  State<TwinProgressBar> createState() => _TwinProgressBarState();
}

class _TwinProgressBarState extends State<TwinProgressBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final double l = widget.leftValue.isFinite ? widget.leftValue : 0.0;
    final double r = widget.rightValue.isFinite ? widget.rightValue : 0.0;
    final double total = l + r;

    final double leftPct = total > 0 ? (l / total) : 0.5;
    final double rightPct = 1.0 - leftPct;

    final Color lColor = widget.leftColor ?? theme.colorScheme.secondary;
    final Color rColor = widget.rightColor ?? theme.colorScheme.primary;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: leftPct),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, animLeft, _) {
          final double animRight = (1.0 - animLeft);

          return ClipRRect(
            borderRadius: BorderRadius.circular(widget.height / 2),
            child: Stack(
              children: [
                // Track
                Positioned.fill(
                  child: Container(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                  ),
                ),
                // Left fill
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: animLeft.clamp(0.0, 1.0).toDouble(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: lColor,
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(widget.height / 2),
                          right: Radius.circular(
                            animRight == 0 ? widget.height / 2 : 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Right fillבגר
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerRight,
                    widthFactor: animRight.clamp(0.0, 1.0).toDouble(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: rColor,
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(widget.height / 2),
                          left: Radius.circular(
                            animLeft == 0 ? widget.height / 2 : 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
