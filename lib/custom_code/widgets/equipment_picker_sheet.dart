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

/// Self-contained "Choose Equipment" bottom sheet (draws its own background,
/// rounded top, grab handle, search field and safe area). Show it inside a
/// fully transparent FF bottom sheet with width/height = Infinite.
///
/// The list is the app's equipment catalog (same strings as
/// exercise.equipment). Images come from assets/images/<name with spaces
/// -> '_'>.jpg (Barbell.jpg, Smith_Machine.jpg, ...). Bodyweight has no
/// image and gets an icon.
///
/// Tap a row -> [onSelect] is called with the equipment name exactly as
/// stored in the DB (e.g. "Smith Machine", "Bodyweight"), then the sheet
/// closes itself - do NOT add a Dismiss action inside onSelect.
/// [selected] marks the current value with a check.
class EquipmentPickerSheet extends StatefulWidget {
  const EquipmentPickerSheet({
    super.key,
    this.width,
    this.height,
    this.selected,
    this.accentColor,
    required this.onSelect,
  });

  final double? width;
  final double? height;
  final String? selected;
  final Color? accentColor;
  final Future Function(String equipment) onSelect;

  @override
  State<EquipmentPickerSheet> createState() => _EquipmentPickerSheetState();
}

class _EquipmentPickerSheetState extends State<EquipmentPickerSheet> {
  // DB value -> display label. Order = how they appear.
  static const List<List<String>> _catalog = [
    ['Bodyweight', 'No equipment (bodyweight)'],
    ['Barbell', 'Barbell'],
    ['Dumbbell', 'Dumbbell'],
    ['Cable', 'Cable'],
    ['Machine', 'Machine'],
    ['Smith Machine', 'Smith Machine'],
    ['Bench', 'Bench'],
    ['Kettlebell', 'Kettlebell'],
    ['Plate', 'Plate'],
    ['Trap Bar', 'Trap Bar'],
  ];

  final TextEditingController _search = TextEditingController();
  String _query = '';
  bool _busy = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _assetPath(String name) =>
      'assets/images/${name.replaceAll(' ', '_')}.jpg';

  List<List<String>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _catalog;
    return _catalog
        .where((e) =>
            e[0].toLowerCase().contains(q) || e[1].toLowerCase().contains(q))
        .toList();
  }

  Future<void> _pick(String value) async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.selectionClick();
    try {
      await widget.onSelect(value);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _thumb(String value, FlutterFlowTheme theme, Color accent) {
    if (value == 'Bodyweight') {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.accessibility_new_rounded, size: 26, color: accent),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 52,
        height: 52,
        color: Colors.white,
        padding: const EdgeInsets.all(4),
        child: Image.asset(
          _assetPath(value),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.fitness_center_rounded,
            size: 24,
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
        (h.isFinite && h > 0 && h < screenH * 0.9) ? h : screenH * 0.7;
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final String? current = widget.selected?.trim();
    final items = _filtered;

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
              'Choose Equipment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: theme.primaryBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.alternate),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(Icons.search_rounded,
                        size: 20, color: theme.secondaryText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: (v) => setState(() => _query = v),
                        style:
                            TextStyle(fontSize: 15, color: theme.primaryText),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Search equipment',
                          hintStyle: TextStyle(
                              fontSize: 15, color: theme.secondaryText),
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(Icons.close_rounded,
                              size: 18, color: theme.secondaryText),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // List
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text('No equipment found',
                          style: TextStyle(
                              fontSize: 14, color: theme.secondaryText)),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: theme.alternate),
                      itemBuilder: (context, index) {
                        final value = items[index][0];
                        final label = items[index][1];
                        final bool isSelected = current != null &&
                            current.toLowerCase() == value.toLowerCase();
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _pick(value),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                _thumb(value, theme, accent),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    label,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: theme.primaryText,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_rounded,
                                      size: 22, color: accent),
                              ],
                            ),
                          ),
                        );
                      },
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
