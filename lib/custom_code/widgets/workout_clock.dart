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

import 'dart:async';

/// Live workout clock.
///
/// Self-contained: ticks internally, repaints ONLY itself - no App State
/// writes, no page rebuilds. startedAt: the DateTime when the workout began.
class WorkoutClock extends StatefulWidget {
  const WorkoutClock({
    super.key,
    this.width,
    this.height,
    required this.startedAt,
    this.fontSize,
    this.color,
  });

  final double? width;
  final double? height;
  final DateTime startedAt;
  final double? fontSize;
  final Color? color;

  @override
  State<WorkoutClock> createState() => _WorkoutClockState();
}

class _WorkoutClockState extends State<WorkoutClock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format() {
    final s =
        DateTime.now().difference(widget.startedAt).inSeconds.clamp(0, 359999);
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) return '${h}h ${m}m ${sec}s';
    return '${m}m ${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Center(
        child: Text(
          _format(),
          textAlign: TextAlign.center,
          maxLines: 1,
          style: TextStyle(
            fontSize: widget.fontSize ?? 20,
            fontWeight: FontWeight.w700,
            height: 1.0, // kill font line-height offset - true vertical center
            color: widget.color ?? const Color(0xFF1A202C),
          ),
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
