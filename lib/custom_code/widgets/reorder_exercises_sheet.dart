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

/// Self-contained drag-to-reorder bottom sheet (draws its own background,
/// rounded top, grab handle and safe area).
///
/// Show it inside a fully transparent FF bottom sheet with width/height =
/// Infinite.
///
/// [items] - exerciseSets (List<JSON>). Reads the name from exerciseName /
/// name / exercise_name and loads the illustration from assets/images/<name
/// with spaces -> '_'>.jpg, i.e. the same mapping as the exerciseImageName
/// custom function. [accentColor] - buttons/numbers color; defaults to
/// theme.primary. On Save it calls [onSave] with the reordered [items], then
/// closes the sheet itself - do NOT add a Dismiss action inside onSave.
class ReorderExercisesSheet extends StatefulWidget {
  const ReorderExercisesSheet({
    super.key,
    this.width,
    this.height,
    required this.items,
    this.accentColor,
    required this.onSave,
  });

  final double? width;
  final double? height;
  final List<dynamic> items;
  final Color? accentColor;
  final Future Function(List<dynamic> reorderedItems) onSave;

  @override
  State<ReorderExercisesSheet> createState() => _ReorderExercisesSheetState();
}

class _ReorderExercisesSheetState extends State<ReorderExercisesSheet> {
  late List<dynamic> _list;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _list = List<dynamic>.from(widget.items);
  }

  String _nameOf(dynamic item) {
    if (item is Map) {
      final v = item['exerciseName'] ?? item['name'] ?? item['exercise_name'];
      final s = v?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return 'Exercise';
  }

  /// Same mapping as the exerciseImageName custom function.
  String _assetPath(String name) =>
      'assets/images/${name.replaceAll(' ', '_')}.jpg';

  bool get _changed {
    for (int i = 0; i < _list.length; i++) {
      if (!identical(_list[i], widget.items[i])) return true;
    }
    return false;
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _list.removeAt(oldIndex);
      _list.insert(newIndex, item);
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(_list);
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _thumb(String name, FlutterFlowTheme theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 48,
        height: 48,
        color: Colors.white,
        child: Image.asset(
          _assetPath(name),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.fitness_center_rounded,
            size: 22,
            color: theme.secondaryText,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final Color accent = widget.accentColor ?? theme.primary;
    final double screenH = MediaQuery.of(context).size.height;
    final double h = widget.height ?? 0;
    final double sheetH =
        (h.isFinite && h > 0 && h < screenH * 0.9) ? h : screenH * 0.6;
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: widget.width ?? double.infinity,
        height: sheetH,
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Grab handle
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.alternate,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Reorder Exercises',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hold and drag to reorder',
              style: TextStyle(fontSize: 13, color: theme.secondaryText),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                buildDefaultDragHandles: false,
                itemCount: _list.length,
                onReorderStart: (_) => HapticFeedback.selectionClick(),
                onReorder: _onReorder,
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) {
                      final t = Curves.easeOut.transform(animation.value);
                      return Transform.scale(
                        scale: 1.0 + 0.03 * t,
                        child: Material(
                          color: Colors.transparent,
                          elevation: 8 * t,
                          borderRadius: BorderRadius.circular(14),
                          shadowColor: Colors.black.withOpacity(0.25),
                          child: child,
                        ),
                      );
                    },
                  );
                },
                itemBuilder: (context, index) {
                  final item = _list[index];
                  final name = _nameOf(item);
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(item),
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        height: 64,
                        decoration: BoxDecoration(
                          color: theme.primaryBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: theme.alternate, width: 1),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 22,
                              child: Text(
                                '${index + 1}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _thumb(name, theme),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: theme.primaryText,
                                ),
                              ),
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 16),
                                child: Icon(
                                  Icons.drag_handle_rounded,
                                  color: theme.secondaryText,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed:
                            _saving ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.primaryText,
                          side: BorderSide(color: theme.alternate),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_saving || !_changed) ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          disabledBackgroundColor: accent.withOpacity(0.4),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save Order',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
