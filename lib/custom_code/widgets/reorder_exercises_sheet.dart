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

import 'dart:ui' as ui show TextDirection;
import 'package:flutter/services.dart';

// ---------------- Localization ----------------

const Set<String> _kRtl = {'he', 'ar'};

String _langOf(BuildContext ctx) {
  try {
    final l = FFLocalizations.of(ctx).languageCode.trim().toLowerCase();
    return l.isEmpty ? 'en' : l;
  } catch (_) {
    return 'en';
  }
}

const Map<String, Map<String, String>> _kStrings = {
  "title": {
    "en": "Reorder Exercises",
    "es": "Reordenar ejercicios",
    "he": "סידור תרגילים",
    "de": "Übungen sortieren",
    "fr": "Réorganiser"
  },
  "hint": {
    "en": "Hold and drag to reorder",
    "es": "Mantén y arrastra para mover",
    "he": "לחץ ארוך וגרור כדי לסדר",
    "de": "Halten und ziehen",
    "fr": "Maintenez et glissez"
  },
  "cancel": {
    "en": "Cancel",
    "es": "Cancelar",
    "he": "ביטול",
    "de": "Abbrechen",
    "fr": "Annuler"
  },
  "save": {
    "en": "Save Order",
    "es": "Guardar orden",
    "he": "שמור סידור",
    "de": "Speichern",
    "fr": "Enregistrer"
  },
  "exercise": {
    "en": "Exercise",
    "es": "Ejercicio",
    "he": "תרגיל",
    "de": "Übung",
    "fr": "Exercice"
  },
};

String _tr(String lang, String key) {
  final m = _kStrings[key];
  return m == null ? key : (m[lang] ?? m['en'] ?? key);
}

/// Self-contained drag-to-reorder bottom sheet (draws its own background,
/// rounded top, grab handle and safe area).
///
/// [items] - exerciseSets (List<JSON>). Reads the RAW name from exerciseName
/// / name / exercise_name (JSON translations or plain text), shows it
/// localized via localizedName(), and loads the illustration from the ENGLISH
/// name (same mapping as exerciseImageName). The items passed back in
/// [onSave] are untouched. Reads the app language itself.
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

  /// Raw name as stored in the item (JSON or plain). Empty if none.
  String _rawNameOf(dynamic item) {
    if (item is Map) {
      final v = item['exerciseName'] ?? item['name'] ?? item['exercise_name'];
      final s = v?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return '';
  }

  /// Same mapping as the exerciseImageName custom function (English name).
  String _assetPath(String nameEn) =>
      'assets/images/${nameEn.replaceAll(' ', '_')}.jpg';

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

  Widget _thumb(String nameEn, FlutterFlowTheme theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 48,
        height: 48,
        color: Colors.white,
        child: Image.asset(
          _assetPath(nameEn),
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
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);
    final Color accent = widget.accentColor ?? theme.primary;
    final double screenH = MediaQuery.of(context).size.height;
    final double h = widget.height ?? 0;
    final double sheetH =
        (h.isFinite && h > 0 && h < screenH * 0.9) ? h : screenH * 0.6;
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Align(
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
                _tr(lang, 'title'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _tr(lang, 'hint'),
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
                    final String raw = _rawNameOf(item);
                    final String nameEn = localizedName(raw, 'en');
                    final String shown = raw.isEmpty
                        ? _tr(lang, 'exercise')
                        : localizedName(raw, lang);
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
                            border:
                                Border.all(color: theme.alternate, width: 1),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 22,
                                child: Text(
                                  '${index + 1}',
                                  textAlign: TextAlign.center,
                                  textDirection: ui.TextDirection.ltr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              _thumb(nameEn, theme),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  shown,
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
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.primaryText,
                            side: BorderSide(color: theme.alternate),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(_tr(lang, 'cancel'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
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
                              : Text(_tr(lang, 'save'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
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
