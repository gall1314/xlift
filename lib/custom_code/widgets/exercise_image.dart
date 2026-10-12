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

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Exercise illustration that works for BOTH catalog and custom exercises.
///
/// [exerciseName]  - catalog: assets/images/<name with spaces -> '_'>.jpg
/// [illustration]  - custom:  file name saved by saveCustomExerciseImage
///                   (e.g. "custom_42.png") inside Documents/exercise_images
/// Resolution order: custom file (if [illustration] is a bare file name)
/// -> catalog asset -> fallback icon.
class ExerciseImage extends StatefulWidget {
  const ExerciseImage({
    super.key,
    this.width,
    this.height,
    this.exerciseName,
    this.illustration,
    this.borderRadius = 10,
  });

  final double? width;
  final double? height;
  final String? exerciseName;
  final String? illustration;
  final double borderRadius;

  @override
  State<ExerciseImage> createState() => _ExerciseImageState();
}

class _ExerciseImageState extends State<ExerciseImage> {
  static Directory? _docs; // cached across instances
  File? _file;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant ExerciseImage old) {
    super.didUpdateWidget(old);
    if (old.illustration != widget.illustration) {
      _resolved = false;
      _file = null;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    File? f;
    try {
      final String? name = widget.illustration?.trim();
      // Only treat as a local file when it's a bare file name we wrote.
      if (name != null &&
          name.isNotEmpty &&
          !name.contains('/') &&
          !name.startsWith('http')) {
        _docs ??= await getApplicationDocumentsDirectory();
        final candidate = File(p.join(_docs!.path, 'exercise_images', name));
        if (candidate.existsSync()) f = candidate;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _file = f;
        _resolved = true;
      });
    }
  }

  Widget _fallback(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      color: theme.alternate.withOpacity(0.4),
      child: Icon(Icons.fitness_center_rounded,
          size: (widget.width ?? 48) * 0.45, color: theme.secondaryText),
    );
  }

  Widget _asset(BuildContext context) {
    final String n = (widget.exerciseName ?? '').trim();
    if (n.isEmpty) return _fallback(context);
    return Image.asset(
      'assets/images/${n.replaceAll(' ', '_')}.jpg',
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _fallback(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (!_resolved) {
      child = const SizedBox.shrink();
    } else if (_file != null) {
      child = Image.file(
        _file!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _asset(context),
      );
    } else {
      child = _asset(context);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: child,
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
