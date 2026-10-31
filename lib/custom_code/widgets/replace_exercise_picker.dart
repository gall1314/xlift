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

/// "Replace Exercise" — designed to live inside a FlutterFlow Bottom Sheet
/// (~80% height): rounded top corners, drag handle, no status-bar inset.
///
/// Runs its own SQLite queries: - smartReplace(exerciseId) → ranked, first
/// row = best match - getAllExercises()        → full catalog (exercise_view
/// + flags) The best match is pre-selected on load. Reads the workout's
/// loggedSets as-is and warns only when done sets exist for the current
/// exercise (they get deleted on replace). Calls [onReplace] with the choice
/// (exerciseName = ENGLISH name, a stable key) and whether the user also
/// wants the saved plan updated.
///
/// Localization: reads the app language from FFLocalizations (no parameter).
/// Exercise / muscle names go through localizedName (JSON or plain), filters
/// and image lookups use the English name. Hebrew renders RTL.
class ReplaceExercisePicker extends StatefulWidget {
  const ReplaceExercisePicker({
    super.key,
    this.width,
    this.height,
    required this.exerciseId,
    this.loggedSets,
    this.onReplace,
    this.onClose,
    this.onCreate,
  });

  final double? width;
  final double? height;
  final int exerciseId;
  final List<dynamic>? loggedSets;
  final Future Function(int exerciseId, String exerciseName, bool updatePlan)?
      onReplace;
  final Future Function()? onClose;
  final Future Function()? onCreate;

  @override
  State<ReplaceExercisePicker> createState() => _ReplaceExercisePickerState();
}

// ---------- localization ----------

const Set<String> _kRtl = {'he', 'ar'};

String _langOf(BuildContext ctx) {
  try {
    final l = FFLocalizations.of(ctx).languageCode.trim().toLowerCase();
    return l.isEmpty ? 'en' : l;
  } catch (_) {
    return 'en';
  }
}

/// {n} number, {x} name, {q} query.
const Map<String, Map<String, String>> _kStrings = {
  "title": {
    "en": "Replace Exercise",
    "es": "Reemplazar ejercicio",
    "he": "החלפת תרגיל",
    "de": "Übung ersetzen",
    "fr": "Remplacer l'exercice"
  },
  "create": {
    "en": "Create",
    "es": "Crear",
    "he": "צור",
    "de": "Neu",
    "fr": "Créer"
  },
  "loadFailed": {
    "en": "Could not load exercises",
    "es": "No se pudieron cargar los ejercicios",
    "he": "טעינת התרגילים נכשלה",
    "de": "Übungen konnten nicht geladen werden",
    "fr": "Impossible de charger les exercices"
  },
  "tryAgain": {
    "en": "Try again",
    "es": "Reintentar",
    "he": "נסה שוב",
    "de": "Erneut versuchen",
    "fr": "Réessayer"
  },
  "replacing": {
    "en": "Replacing",
    "es": "Reemplazando",
    "he": "מחליף את",
    "de": "Ersetzt",
    "fr": "Remplacement de"
  },
  "currentExercise": {
    "en": "Current exercise",
    "es": "Ejercicio actual",
    "he": "התרגיל הנוכחי",
    "de": "Aktuelle Übung",
    "fr": "Exercice actuel"
  },
  "warnSets1": {
    "en": "The 1 set you logged for {x} will be deleted.",
    "es": "La serie que registraste de {x} se eliminará.",
    "he": "הסט שתיעדת ב{x} יימחק.",
    "de": "Der eingetragene Satz für {x} wird gelöscht.",
    "fr": "La série enregistrée pour {x} sera supprimée."
  },
  "warnSetsN": {
    "en": "The {n} sets you logged for {x} will be deleted.",
    "es": "Las {n} series que registraste de {x} se eliminarán.",
    "he": "{n} הסטים שתיעדת ב{x} יימחקו.",
    "de": "Die {n} eingetragenen Sätze für {x} werden gelöscht.",
    "fr": "Les {n} séries enregistrées pour {x} seront supprimées."
  },
  "smart": {
    "en": "Smart",
    "es": "Smart",
    "he": "חכם",
    "de": "Smart",
    "fr": "Smart"
  },
  "allExercises": {
    "en": "All exercises",
    "es": "Todos",
    "he": "כל התרגילים",
    "de": "Alle Übungen",
    "fr": "Tous"
  },
  "all": {"en": "All", "es": "Todos", "he": "הכל", "de": "Alle", "fr": "Tous"},
  "searchExercises": {
    "en": "Search exercises",
    "es": "Buscar ejercicios",
    "he": "חיפוש תרגילים",
    "de": "Übungen suchen",
    "fr": "Rechercher des exercices"
  },
  "noSmart": {
    "en": "No smart matches for this exercise.",
    "es": "No hay sugerencias para este ejercicio.",
    "he": "אין התאמות חכמות לתרגיל הזה.",
    "de": "Keine passenden Vorschläge für diese Übung.",
    "fr": "Aucune suggestion pour cet exercice."
  },
  "noEquip": {
    "en": "No matches with this equipment.",
    "es": "Nada con este equipamiento.",
    "he": "אין התאמות עם הציוד הזה.",
    "de": "Nichts mit diesem Equipment.",
    "fr": "Rien avec cet équipement."
  },
  "noneInGroup": {
    "en": "No exercises in this group.",
    "es": "No hay ejercicios en este grupo.",
    "he": "אין תרגילים בקבוצה הזו.",
    "de": "Keine Übungen in dieser Gruppe.",
    "fr": "Aucun exercice dans ce groupe."
  },
  "noMatch": {
    "en": "No exercises match \"{q}\"",
    "es": "Ningún ejercicio coincide con \"{q}\"",
    "he": "אין תרגילים התואמים ל-\"{q}\"",
    "de": "Keine Übungen passen zu \"{q}\"",
    "fr": "Aucun exercice ne correspond à \"{q}\""
  },
  "bestMatch": {
    "en": "Best match",
    "es": "Mejor opción",
    "he": "הכי מתאים",
    "de": "Top-Treffer",
    "fr": "Meilleur choix"
  },
  "form": {
    "en": "Form",
    "es": "Técnica",
    "he": "טכניקה",
    "de": "Technik",
    "fr": "Technique"
  },
  "updatePlan": {
    "en": "Also update my plan",
    "es": "Actualizar también mi plan",
    "he": "עדכן גם את התוכנית",
    "de": "Auch meinen Plan ändern",
    "fr": "Mettre aussi à jour mon plan"
  },
  "planOn": {
    "en": "Replaced in this workout plan from now on",
    "es": "Se reemplaza en este plan a partir de ahora",
    "he": "יוחלף בתוכנית האימון מעכשיו",
    "de": "Ab jetzt in diesem Plan ersetzt",
    "fr": "Remplacé dans ce plan désormais"
  },
  "planOff": {
    "en": "Off: swap for today only",
    "es": "No: solo por hoy",
    "he": "כבוי: החלפה להיום בלבד",
    "de": "Aus: nur für heute",
    "fr": "Non : seulement aujourd'hui"
  },
  "pickExercise": {
    "en": "Pick an exercise",
    "es": "Elige un ejercicio",
    "he": "בחר תרגיל",
    "de": "Übung wählen",
    "fr": "Choisir un exercice"
  },
  "replaceWith": {
    "en": "Replace with {x}",
    "es": "Reemplazar por {x}",
    "he": "החלף ב{x}",
    "de": "Ersetzen durch {x}",
    "fr": "Remplacer par {x}"
  },
};

String _tr(String lang, String key, {int? n, String? x, String? q}) {
  final m = _kStrings[key];
  var s = m == null ? key : (m[lang] ?? m['en'] ?? key);
  if (n != null) s = s.replaceAll('{n}', '$n');
  if (x != null) s = s.replaceAll('{x}', x);
  if (q != null) s = s.replaceAll('{q}', q);
  return s;
}

/// Equipment values are a fixed English set in the DB.
const Map<String, Map<String, String>> _kEquip = {
  "bodyweight": {
    "es": "Peso corporal",
    "he": "משקל גוף",
    "de": "Körpergewicht",
    "fr": "Poids du corps"
  },
  "barbell": {"es": "Barra", "he": "מוט", "de": "Langhantel", "fr": "Barre"},
  "dumbbell": {
    "es": "Mancuerna",
    "he": "משקולת",
    "de": "Kurzhantel",
    "fr": "Haltère"
  },
  "machine": {
    "es": "Máquina",
    "he": "מכונה",
    "de": "Maschine",
    "fr": "Machine"
  },
  "cable": {"es": "Polea", "he": "פולי", "de": "Kabelzug", "fr": "Poulie"},
  "bench": {"es": "Banco", "he": "ספסל", "de": "Bank", "fr": "Banc"},
  "plate": {"es": "Disco", "he": "פלטה", "de": "Scheibe", "fr": "Disque"},
  "kettlebell": {
    "es": "Kettlebell",
    "he": "קטלבל",
    "de": "Kettlebell",
    "fr": "Kettlebell"
  },
  "trap bar": {
    "es": "Barra hexagonal",
    "he": "מוט טראפ",
    "de": "Trap Bar",
    "fr": "Trap bar"
  },
  "smith machine": {
    "es": "Máquina Smith",
    "he": "סמית",
    "de": "Multipresse",
    "fr": "Smith"
  },
  "resistance band": {
    "es": "Banda",
    "he": "גומייה",
    "de": "Band",
    "fr": "Élastique"
  },
  "sled": {"es": "Trineo", "he": "מזחלת", "de": "Schlitten", "fr": "Traîneau"},
  "medicine ball": {
    "es": "Balón medicinal",
    "he": "כדור כוח",
    "de": "Medizinball",
    "fr": "Médecine-ball"
  },
  "jump rope": {
    "es": "Cuerda",
    "he": "חבל קפיצה",
    "de": "Springseil",
    "fr": "Corde à sauter"
  },
  "battle ropes": {
    "es": "Cuerdas de batalla",
    "he": "חבלי קרב",
    "de": "Battle Ropes",
    "fr": "Battle ropes"
  },
};

String _equip(String lang, String raw) {
  if (raw.isEmpty || lang == 'en') return raw;
  return _kEquip[raw.trim().toLowerCase()]?[lang] ?? raw;
}

class _Ex {
  _Ex({
    required this.id,
    required this.name,
    required this.nameEn,
    this.category = '',
    this.categoryEn = '',
    this.muscles = const [],
    this.equipment = '',
    this.formCheck = false,
  });

  final int id;
  final String name; // localized
  final String nameEn; // English (image, callback)
  final String category; // localized parent group
  final String categoryEn; // English parent group (filter key)
  final List<String> muscles; // localized specific groups
  final String equipment; // raw English (filter key)
  final bool formCheck;

  String subtitle(String lang) {
    final m = muscles.isNotEmpty ? muscles.first : category;
    return [m, _equip(lang, equipment)].where((x) => x.isNotEmpty).join(' · ');
  }

  /// Same mapping as the exerciseImageName custom function.
  String get imageName => nameEn.replaceAll(' ', '_');
}

class _ReplaceExercisePickerState extends State<ReplaceExercisePicker> {
  static const _categoryOrder = [
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Core',
    'Forearms',
    'Neck',
  ];
  static const String _all = '__all__';

  bool _loading = true;
  String? _error;
  bool _busy = false;
  String _lang = 'en';
  bool _started = false;

  List<_Ex> _all_ = [];
  List<_Ex> _smart = [];
  _Ex? _current;

  bool _smartTab = true;
  String _equipFilter = _all; // raw English equipment
  String _muscleFilter = _all; // English category
  String _query = '';
  int? _selectedId;
  String _selectedName = ''; // localized, for the button
  String _selectedNameEn = ''; // for the callback
  bool _updatePlan = false;

  final _searchCtrl = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l = _langOf(context);
    if (!_started || l != _lang) {
      _started = true;
      _lang = l;
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant ReplaceExercisePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseId != widget.exerciseId) _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---------- parsing ----------
  String _s(dynamic v) => v == null ? '' : v.toString().trim();

  int? _i(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(_s(v));
  }

  bool _b(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = _s(v).toLowerCase();
    return s == '1' || s == 'true';
  }

  /// Done, non-drop sets of the current exercise (what save would persist).
  int get _doneSetsForCurrent {
    final list = widget.loggedSets;
    if (list == null) return 0;
    var n = 0;
    for (final item in list) {
      if (item is! Map) continue;
      if (_i(item['exerciseId']) != widget.exerciseId) continue;
      if (_b(item['isDropSet'])) continue;
      if (!_b(item['isDone'])) continue;
      n++;
    }
    return n;
  }

  // ---------- data ----------
  Future<void> _load() async {
    final lang = _lang;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final allRows = await SQLiteManager.instance.getAllExercises();
      final smartRows = await SQLiteManager.instance
          .smartReplace(exerciseId: widget.exerciseId);

      final byId = <int, _Ex>{};
      for (final r in allRows) {
        final d = r.data;
        final id = _i(d['exercise_id']);
        final rawName = _s(d['exercise_name']);
        if (id == null || rawName.isEmpty || byId.containsKey(id)) continue;
        final muscles = [
          d['sub_muscle_1'],
          d['sub_muscle_2'],
          d['sub_muscle_3']
        ]
            .map(_s)
            .where((x) => x.isNotEmpty)
            .map((x) => localizedName(x, lang))
            .toList();
        final rawCat = _s(d['primary_muscle_1']);
        byId[id] = _Ex(
          id: id,
          name: localizedName(rawName, lang),
          nameEn: localizedName(rawName, 'en'),
          category: localizedName(rawCat, lang),
          categoryEn: localizedName(rawCat, 'en'),
          muscles: muscles,
          equipment: _s(d['equipment']),
          formCheck: _b(d['ai_form_analysis']),
        );
      }

      final smart = <_Ex>[];
      final seen = <int>{};
      for (final r in smartRows) {
        final d = r.data;
        final id = _i(d['id']);
        if (id == null || id == widget.exerciseId || !seen.add(id)) continue;
        final base = byId[id];
        if (base != null) {
          smart.add(base);
        } else {
          final rawName = _s(d['name']);
          if (rawName.isEmpty) continue;
          final rawCat = _s(d['primary_muscles']).split(',').first.trim();
          smart.add(_Ex(
            id: id,
            name: localizedName(rawName, lang),
            nameEn: localizedName(rawName, 'en'),
            category: localizedName(rawCat, lang),
            categoryEn: localizedName(rawCat, 'en'),
            equipment: _s(d['equipment_type']),
          ));
        }
      }

      final all = byId.values.where((e) => e.id != widget.exerciseId).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _all_ = all;
        _smart = smart;
        _current = byId[widget.exerciseId];
        _loading = false;
        _equipFilter = _all;
        if (smart.isNotEmpty) {
          _selectedId = smart.first.id;
          _selectedName = smart.first.name;
          _selectedNameEn = smart.first.nameEn;
        } else {
          _selectedId = null;
          _selectedName = '';
          _selectedNameEn = '';
          _smartTab = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _tr(lang, 'loadFailed');
      });
    }
  }

  /// Equipment chips: raw English keys, ordered by frequency.
  List<String> get _equipChips {
    final counts = <String, int>{};
    for (final e in _smart) {
      if (e.equipment.isEmpty) continue;
      counts[e.equipment] = (counts[e.equipment] ?? 0) + 1;
    }
    final keys = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return keys.length > 1 ? [_all, ...keys] : [];
  }

  /// Muscle chips: English category keys in catalog order.
  List<String> get _muscleChips {
    final cats =
        _all_.map((e) => e.categoryEn).where((c) => c.isNotEmpty).toSet();
    final ordered = [
      ..._categoryOrder.where(cats.contains),
      ...(cats.where((c) => !_categoryOrder.contains(c)).toList()..sort()),
    ];
    return [_all, ...ordered];
  }

  /// Localized label for an English category key.
  String _catLabel(String en) {
    for (final e in _all_) {
      if (e.categoryEn == en) return e.category;
    }
    return en;
  }

  List<_Ex> get _smartVisible => _smart
      .where((e) => _equipFilter == _all || e.equipment == _equipFilter)
      .toList();

  List<_Ex> get _allVisible {
    final q = _query.trim().toLowerCase();
    return _all_
        .where((e) =>
            (_muscleFilter == _all || e.categoryEn == _muscleFilter) &&
            (q.isEmpty ||
                e.name.toLowerCase().contains(q) ||
                e.nameEn.toLowerCase().contains(q)))
        .toList();
  }

  void _pick(_Ex e) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedId == e.id) {
        _selectedId = null;
        _selectedName = '';
        _selectedNameEn = '';
      } else {
        _selectedId = e.id;
        _selectedName = e.name;
        _selectedNameEn = e.nameEn;
      }
    });
  }

  Future<void> _confirm() async {
    if (_selectedId == null || _busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      // English name: a stable key downstream.
      await widget.onReplace?.call(_selectedId!, _selectedNameEn, _updatePlan);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close() async {
    if (widget.onClose != null) {
      await widget.onClose!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final mq = MediaQuery.of(context);
    final h = widget.height ?? mq.size.height * 0.8;
    final bool rtl = _kRtl.contains(_lang);

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          width: widget.width,
          height: h,
          color: theme.primaryBackground,
          child: Column(
            children: [
              _header(theme),
              if (_loading)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: theme.primary),
                  ),
                )
              else if (_error != null)
                Expanded(child: _errorView(theme))
              else ...[
                _currentCard(theme),
                _tabs(theme),
                if (_smartTab) _equipRow(theme) else _searchAndMuscles(theme),
                Expanded(child: _list(theme)),
                _bottomBar(theme, mq.padding.bottom),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(FlutterFlowTheme theme) {
    return Container(
      color: theme.secondaryBackground,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.alternate,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.close_rounded,
                    size: 24, color: theme.primaryText),
                onPressed: _close,
              ),
              Expanded(
                child: Text(
                  _tr(_lang, 'title'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
              ),
              SizedBox(
                width: 72,
                child: widget.onCreate == null
                    ? const SizedBox()
                    : TextButton(
                        onPressed: () => widget.onCreate!(),
                        child: Text(
                          _tr(_lang, 'create'),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: theme.primary,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _errorView(FlutterFlowTheme theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!,
              style: TextStyle(fontSize: 15, color: theme.secondaryText)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _load,
            child: Text(_tr(_lang, 'tryAgain'),
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: theme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _currentCard(FlutterFlowTheme theme) {
    final cur = _current;
    final sets = _doneSetsForCurrent;
    final name = cur?.name ?? _tr(_lang, 'currentExercise');
    final chips = <String>[
      if (cur != null)
        ...(cur.muscles.isNotEmpty ? cur.muscles : [cur.category]),
    ].where((x) => x.isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_tr(_lang, 'replacing'),
              style: TextStyle(fontSize: 12, color: theme.secondaryText)),
          const SizedBox(height: 2),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < chips.length; i++)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: i == 0
                          ? theme.primary.withOpacity(0.14)
                          : theme.alternate.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      chips[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: i == 0 ? theme.primary : theme.secondaryText,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (sets > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: Color(0xFFC26A00)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sets == 1
                          ? _tr(_lang, 'warnSets1', x: name)
                          : _tr(_lang, 'warnSetsN', n: sets, x: name),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8A4B00),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tabs(FlutterFlowTheme theme) {
    Widget tab(String label, bool on, VoidCallback tap, {IconData? icon}) {
      return Expanded(
        child: GestureDetector(
          onTap: tap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 40,
            decoration: BoxDecoration(
              color: on ? theme.secondaryBackground : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: on
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      size: 16,
                      color: on ? theme.primary : theme.secondaryText),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: on ? theme.primary : theme.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.alternate.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          tab(_tr(_lang, 'smart'), _smartTab,
              () => setState(() => _smartTab = true),
              icon: Icons.auto_awesome_rounded),
          const SizedBox(width: 3),
          tab(_tr(_lang, 'allExercises'), !_smartTab,
              () => setState(() => _smartTab = false)),
        ],
      ),
    );
  }

  Widget _chipRow(FlutterFlowTheme theme, List<String> keys, String active,
      String Function(String) label, void Function(String) onTap) {
    if (keys.isEmpty) return const SizedBox(height: 8);
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        itemCount: keys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final on = keys[i] == active;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap(keys[i]);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? theme.primary : theme.secondaryBackground,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: on ? theme.primary : theme.alternate),
              ),
              child: Text(
                keys[i] == _all ? _tr(_lang, 'all') : label(keys[i]),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: on ? Colors.white : theme.primaryText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _equipRow(FlutterFlowTheme theme) => _chipRow(
      theme,
      _equipChips,
      _equipFilter,
      (k) => _equip(_lang, k),
      (v) => setState(() => _equipFilter = v));

  Widget _searchAndMuscles(FlutterFlowTheme theme) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.alternate),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 20, color: theme.secondaryText),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  textInputAction: TextInputAction.search,
                  style: TextStyle(fontSize: 16, color: theme.primaryText),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: _tr(_lang, 'searchExercises'),
                    hintStyle:
                        TextStyle(fontSize: 16, color: theme.secondaryText),
                  ),
                ),
              ),
              if (_query.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() {
                    _query = '';
                    _searchCtrl.clear();
                  }),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: theme.secondaryText),
                ),
            ],
          ),
        ),
        _chipRow(theme, _muscleChips, _muscleFilter, _catLabel,
            (v) => setState(() => _muscleFilter = v)),
      ],
    );
  }

  Widget _list(FlutterFlowTheme theme) {
    if (_smartTab) {
      final items = _smartVisible;
      if (items.isEmpty) {
        return _empty(theme,
            _smart.isEmpty ? _tr(_lang, 'noSmart') : _tr(_lang, 'noEquip'));
      }
      final bestId = _smart.isNotEmpty ? _smart.first.id : null;
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        itemCount: items.length,
        itemBuilder: (_, i) =>
            _row(theme, items[i], best: items[i].id == bestId),
      );
    }

    final items = _allVisible;
    if (items.isEmpty) {
      return _empty(
          theme,
          _query.trim().isEmpty
              ? _tr(_lang, 'noneInGroup')
              : _tr(_lang, 'noMatch', q: _query.trim()));
    }
    final entries = <Object>[];
    String letter = '';
    for (final e in items) {
      final l = e.name.isEmpty ? '' : e.name[0].toUpperCase();
      if (l != letter) {
        letter = l;
        entries.add(l);
      }
      entries.add(e);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final it = entries[i];
        if (it is String) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
            child: Text(
              it,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.secondaryText,
              ),
            ),
          );
        }
        return _row(theme, it as _Ex);
      },
    );
  }

  Widget _empty(FlutterFlowTheme theme, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: theme.secondaryText),
        ),
      ),
    );
  }

  Widget _row(FlutterFlowTheme theme, _Ex e, {bool best = false}) {
    final sel = _selectedId == e.id;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _pick(e),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: sel
                  ? Color.alphaBlend(theme.primary.withOpacity(0.07),
                      theme.secondaryBackground)
                  : theme.secondaryBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: sel ? theme.primary : theme.alternate,
                width: sel ? 1.8 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExerciseAssetImage(
                    width: 56,
                    height: 56,
                    exerciseName: e.imageName,
                    borderRadius: 12,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (best) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _tr(_lang, 'bestMatch'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              e.subtitle(_lang),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (e.formCheck) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam_rounded,
                            size: 13, color: theme.primary),
                        const SizedBox(width: 3),
                        Text(
                          _tr(_lang, 'form'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sel ? theme.primary : Colors.transparent,
                    border: sel
                        ? null
                        : Border.all(color: theme.alternate, width: 2),
                  ),
                  child: sel
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _planToggle(FlutterFlowTheme theme) {
    return Semantics(
      button: true,
      toggled: _updatePlan,
      label: _tr(_lang, 'updatePlan'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _updatePlan = !_updatePlan);
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr(_lang, 'updatePlan'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _updatePlan
                          ? _tr(_lang, 'planOn')
                          : _tr(_lang, 'planOff'),
                      style:
                          TextStyle(fontSize: 12, color: theme.secondaryText),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 48,
                height: 28,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: _updatePlan ? theme.primary : theme.alternate,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  alignment: _updatePlan
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(FlutterFlowTheme theme, double bottomInset) {
    final enabled = _selectedId != null && !_busy;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomInset),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border(top: BorderSide(color: theme.alternate)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _planToggle(theme),
          GestureDetector(
            onTap: enabled ? _confirm : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 54,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: enabled ? theme.primary : theme.alternate,
                borderRadius: BorderRadius.circular(14),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      _selectedId == null
                          ? _tr(_lang, 'pickExercise')
                          : _tr(_lang, 'replaceWith', x: _selectedName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: enabled ? Colors.white : theme.secondaryText,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
