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

/// Self-contained "Choose superset partner" bottom sheet (draws its own
/// background, rounded top, grab handle and safe area).
///
/// Show it inside a fully transparent FF bottom sheet with width/height =
/// Infinite.
///
/// [items]             - exerciseSets (List<JSON>). Name from exerciseName /
/// name / exercise_name — raw DB name (JSON translations) or plain; shown in
/// the app language via localizedName, image looked up by the English name.
/// [currentExerciseId] - the exercise we're pairing; it is hidden from the
/// list. [excludeIds]  - optional extra ids to hide. Single selection. "Pair"
/// calls [onSelect] with the chosen item (the same JSON object from [items]),
/// then closes the sheet itself - do NOT add a Dismiss action inside
/// onSelect.
///
/// Localization: reads the app language from FFLocalizations (no parameter).
/// [title] still overrides the heading when given. Hebrew renders RTL.
class SupersetPartnerSheet extends StatefulWidget {
  const SupersetPartnerSheet({
    super.key,
    this.width,
    this.height,
    required this.items,
    required this.currentExerciseId,
    this.excludeIds,
    this.accentColor,
    this.title,
    required this.onSelect,
  });

  final double? width;
  final double? height;
  final List<dynamic> items;
  final int currentExerciseId;
  final List<int>? excludeIds;
  final Color? accentColor;
  final String? title;
  final Future Function(dynamic selectedItem) onSelect;

  @override
  State<SupersetPartnerSheet> createState() => _SupersetPartnerSheetState();
}

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
    "en": "Choose Superset Partner",
    "es": "Elige pareja de superserie",
    "he": "בחר שותף לסופרסט",
    "de": "Supersatz-Partner wählen",
    "fr": "Choisir le partenaire de superset"
  },
  "subtitle": {
    "en": "Pick one exercise from this workout",
    "es": "Elige un ejercicio de este entrenamiento",
    "he": "בחר תרגיל אחד מהאימון הזה",
    "de": "Wähle eine Übung aus diesem Workout",
    "fr": "Choisissez un exercice de cette séance"
  },
  "none": {
    "en": "No other exercises in this workout",
    "es": "No hay otros ejercicios en este entrenamiento",
    "he": "אין תרגילים נוספים באימון הזה",
    "de": "Keine weiteren Übungen in diesem Workout",
    "fr": "Aucun autre exercice dans cette séance"
  },
  "exercise": {
    "en": "Exercise",
    "es": "Ejercicio",
    "he": "תרגיל",
    "de": "Übung",
    "fr": "Exercice"
  },
  "cancel": {
    "en": "Cancel",
    "es": "Cancelar",
    "he": "ביטול",
    "de": "Abbrechen",
    "fr": "Annuler"
  },
  "pair": {
    "en": "Pair",
    "es": "Emparejar",
    "he": "צמד",
    "de": "Koppeln",
    "fr": "Associer"
  },
};

String _tr(String lang, String key) {
  final m = _kStrings[key];
  return m == null ? key : (m[lang] ?? m['en'] ?? key);
}

class _SupersetPartnerSheetState extends State<SupersetPartnerSheet> {
  late List<dynamic> _candidates;
  int _selectedIndex = -1;
  bool _saving = false;

  static int? _idOf(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  int? _exerciseIdOf(dynamic item) {
    if (item is! Map) return null;
    return _idOf(item['exerciseId'] ?? item['exercise_id'] ?? item['id']);
  }

  @override
  void initState() {
    super.initState();
    final Set<int> excluded = {widget.currentExerciseId, ...?widget.excludeIds};
    _candidates = widget.items.where((it) {
      final id = _exerciseIdOf(it);
      return id != null && !excluded.contains(id);
    }).toList();
  }

  /// Raw name as stored in the item (JSON or plain), '' if none.
  String _rawNameOf(dynamic item) {
    if (item is Map) {
      final v = item['exerciseName'] ?? item['name'] ?? item['exercise_name'];
      final s = v?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return '';
  }

  /// Same mapping as the exerciseImageName custom function.
  String _assetPath(String nameEn) =>
      'assets/images/${nameEn.replaceAll(' ', '_')}.jpg';

  Future<void> _confirm() async {
    if (_saving || _selectedIndex < 0) return;
    setState(() => _saving = true);
    try {
      await widget.onSelect(_candidates[_selectedIndex]);
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
    final Color accent = widget.accentColor ?? theme.primary;
    final double screenH = MediaQuery.of(context).size.height;
    final double h = widget.height ?? 0;
    final double sheetH =
        (h.isFinite && h > 0 && h < screenH * 0.9) ? h : screenH * 0.6;
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final String? customTitle =
        (widget.title ?? '').trim().isEmpty ? null : widget.title;

    return Directionality(
      textDirection:
          _kRtl.contains(lang) ? ui.TextDirection.rtl : ui.TextDirection.ltr,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  customTitle ?? _tr(lang, 'title'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _tr(lang, 'subtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: theme.secondaryText),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _candidates.isEmpty
                    ? Center(
                        child: Text(
                          _tr(lang, 'none'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14, color: theme.secondaryText),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _candidates.length,
                        itemBuilder: (context, index) {
                          final item = _candidates[index];
                          final raw = _rawNameOf(item);
                          final String name = raw.isEmpty
                              ? _tr(lang, 'exercise')
                              : localizedName(raw, lang);
                          final String nameEn =
                              raw.isEmpty ? '' : localizedName(raw, 'en');
                          final bool selected = index == _selectedIndex;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedIndex = index);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                height: 64,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? accent.withOpacity(0.10)
                                      : theme.primaryBackground,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selected ? accent : theme.alternate,
                                    width: selected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 10),
                                    _thumb(nameEn, theme),
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
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                          end: 14),
                                      child: Icon(
                                        selected
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        size: 22,
                                        color: selected
                                            ? accent
                                            : theme.secondaryText,
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
                          onPressed:
                              (_saving || _selectedIndex < 0) ? null : _confirm,
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
                              : Text(_tr(lang, 'pair'),
                                  maxLines: 1,
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
