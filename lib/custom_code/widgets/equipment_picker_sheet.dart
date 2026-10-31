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

/// Self-contained "Choose Equipment" bottom sheet (draws its own background,
/// rounded top, grab handle, search field and safe area).
///
/// Show it inside a fully transparent FF bottom sheet with width/height =
/// Infinite.
///
/// The list is the app's equipment catalog (same strings as
/// exercise.equipment). Images come from assets/images/<name with spaces ->
/// '_'>.jpg (Barbell.jpg, Smith_Machine.jpg, ...). Bodyweight has no image
/// and gets an icon.
///
/// Localization: reads the app language from FFLocalizations (no parameter).
/// Labels are translated in code; [onSelect] and [selected] always use the
/// English DB value (e.g. "Smith Machine"). Hebrew renders RTL.
///
/// Tap a row -> [onSelect], then the sheet closes itself - do NOT add a
/// Dismiss action inside onSelect.
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
    "en": "Choose Equipment",
    "es": "Elige equipamiento",
    "he": "בחר ציוד",
    "de": "Equipment wählen",
    "fr": "Choisir l'équipement"
  },
  "search": {
    "en": "Search equipment",
    "es": "Buscar equipamiento",
    "he": "חיפוש ציוד",
    "de": "Equipment suchen",
    "fr": "Rechercher"
  },
  "none": {
    "en": "No equipment found",
    "es": "No se encontró equipamiento",
    "he": "לא נמצא ציוד",
    "de": "Kein Equipment gefunden",
    "fr": "Aucun équipement trouvé"
  },
};

String _tr(String lang, String key) {
  final m = _kStrings[key];
  return m == null ? key : (m[lang] ?? m['en'] ?? key);
}

/// DB value -> label per language. Order = how they appear.
const List<String> _kOrder = [
  'Bodyweight',
  'Barbell',
  'Dumbbell',
  'Cable',
  'Machine',
  'Smith Machine',
  'Bench',
  'Kettlebell',
  'Plate',
  'Trap Bar',
  'Resistance Band',
  'Sled',
  'Medicine Ball',
  'Jump Rope',
  'Battle Ropes',
];

const Map<String, Map<String, String>> _kEquip = {
  "Bodyweight": {
    "en": "No equipment (bodyweight)",
    "es": "Sin equipo (peso corporal)",
    "he": "ללא ציוד (משקל גוף)",
    "de": "Ohne Equipment (Körpergewicht)",
    "fr": "Sans matériel (poids du corps)"
  },
  "Barbell": {
    "en": "Barbell",
    "es": "Barra",
    "he": "מוט",
    "de": "Langhantel",
    "fr": "Barre"
  },
  "Dumbbell": {
    "en": "Dumbbell",
    "es": "Mancuerna",
    "he": "משקולת יד",
    "de": "Kurzhantel",
    "fr": "Haltère"
  },
  "Cable": {
    "en": "Cable",
    "es": "Polea",
    "he": "פולי",
    "de": "Kabelzug",
    "fr": "Poulie"
  },
  "Machine": {
    "en": "Machine",
    "es": "Máquina",
    "he": "מכונה",
    "de": "Maschine",
    "fr": "Machine"
  },
  "Smith Machine": {
    "en": "Smith Machine",
    "es": "Máquina Smith",
    "he": "מכונת סמית",
    "de": "Multipresse",
    "fr": "Machine Smith"
  },
  "Bench": {
    "en": "Bench",
    "es": "Banco",
    "he": "ספסל",
    "de": "Bank",
    "fr": "Banc"
  },
  "Kettlebell": {
    "en": "Kettlebell",
    "es": "Kettlebell",
    "he": "קטלבל",
    "de": "Kettlebell",
    "fr": "Kettlebell"
  },
  "Plate": {
    "en": "Plate",
    "es": "Disco",
    "he": "פלטה",
    "de": "Hantelscheibe",
    "fr": "Disque"
  },
  "Trap Bar": {
    "en": "Trap Bar",
    "es": "Barra hexagonal",
    "he": "מוט טראפ",
    "de": "Trap Bar",
    "fr": "Trap bar"
  },
  "Resistance Band": {
    "en": "Resistance Band",
    "es": "Banda elástica",
    "he": "גומיית התנגדות",
    "de": "Widerstandsband",
    "fr": "Élastique"
  },
  "Sled": {
    "en": "Sled",
    "es": "Trineo",
    "he": "מזחלת",
    "de": "Schlitten",
    "fr": "Traîneau"
  },
  "Medicine Ball": {
    "en": "Medicine Ball",
    "es": "Balón medicinal",
    "he": "כדור כוח",
    "de": "Medizinball",
    "fr": "Médecine-ball"
  },
  "Jump Rope": {
    "en": "Jump Rope",
    "es": "Cuerda para saltar",
    "he": "חבל קפיצה",
    "de": "Springseil",
    "fr": "Corde à sauter"
  },
  "Battle Ropes": {
    "en": "Battle Ropes",
    "es": "Cuerdas de batalla",
    "he": "חבלי קרב",
    "de": "Battle Ropes",
    "fr": "Battle ropes"
  },
};

String _equipLabel(String lang, String key) =>
    _kEquip[key]?[lang] ?? _kEquip[key]?['en'] ?? key;

class _EquipmentPickerSheetState extends State<EquipmentPickerSheet> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  bool _busy = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _assetPath(String key) =>
      'assets/images/${key.replaceAll(' ', '_')}.jpg';

  List<String> _filtered(String lang) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _kOrder;
    return _kOrder
        .where((k) =>
            k.toLowerCase().contains(q) ||
            _equipLabel(lang, k).toLowerCase().contains(q) ||
            _equipLabel('en', k).toLowerCase().contains(q))
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

  Widget _thumb(String key, FlutterFlowTheme theme, Color accent) {
    if (key == 'Bodyweight') {
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
          _assetPath(key),
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
    final String lang = _langOf(context);
    final Color accent = widget.accentColor ?? theme.primary;
    final double screenH = MediaQuery.of(context).size.height;
    final double h = widget.height ?? 0;
    final double sheetH =
        (h.isFinite && h > 0 && h < screenH * 0.9) ? h : screenH * 0.7;
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final String? current = widget.selected?.trim();
    final items = _filtered(lang);

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
              Text(
                _tr(lang, 'title'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
              ),
              const SizedBox(height: 12),
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
                            hintText: _tr(lang, 'search'),
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
                            padding: const EdgeInsetsDirectional.only(end: 12),
                            child: Icon(Icons.close_rounded,
                                size: 18, color: theme.secondaryText),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(_tr(lang, 'none'),
                            style: TextStyle(
                                fontSize: 14, color: theme.secondaryText)),
                      )
                    : ListView.separated(
                        padding:
                            EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: theme.alternate),
                        itemBuilder: (context, index) {
                          final key = items[index];
                          final bool isSelected = current != null &&
                              current.toLowerCase() == key.toLowerCase();
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _pick(key),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  _thumb(key, theme, accent),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      _equipLabel(lang, key),
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
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
