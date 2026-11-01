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

import 'dart:convert' show jsonDecode;
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:google_fonts/google_fonts.dart';

/// Full-screen exercise picker, shared by every "add exercises" flow (create
/// workout, edit workout, live workout, routine editing).
///
/// Runs its own SQLite queries (catalog + custom + recent), holds its own
/// selection state and hands the result back through [onConfirm]. The page
/// decides what to do with it (exerciseSets vs exerciseSetsCreation).
///
/// Sections: Recent (set_log, last 30 days) · Custom (the user's) · All
/// (catalog, grouped by primary muscle group like the Library). Filters:
/// muscle group → sub-muscle (existing sheet look), equipment (multi-select
/// sheet with counts), AI-form-only toggle, text search.
///
/// Localization: `languageCode` ('en','es','he','de','fr') drives all UI
/// strings (_kStrings), exercise / muscle names (localizedName), equipment
/// labels (_kEquipment) and text direction (RTL for 'he'). Images are keyed
/// by the English name in every language.
///
/// Parameters: userId             - current user id (auth) languageCode -
/// Global Properties → Current Language originalSelection  - the exercises
/// already in the workout: the App State list as-is (structs, maps or JSON —
/// anything with exerciseId / exercise_id). May be null or empty.
/// isLiveWorkout      - live workout: exercises already in it are hidden
/// (removal is done elsewhere), picker is add-only liveExerciseSets   -
/// optional; the live workout's exerciseSets. Falls back to originalSelection
/// when null. workoutName        - optional, shown under the title onConfirm
/// - (List<dynamic> selected) every selected exercise (kept + new) as maps:
/// {exerciseId, exerciseName, isBodyweight, isAssisted, isPublic,
/// isTimeBased, equipment} Feed it to
/// initializeWorkoutExerciseSetsFromSelection. onOpenDetails      -
/// (exerciseId) stats button on a catalog exercise onOpenCustomDetails-
/// (exerciseId) stats button on one of the user's own exercises, wherever it
/// appears (Recent / Custom) onCreate           - the "Creכate" button
/// (custom exercise flow) onBack             - the back arrow (null =
/// Navigator.pop)
class ExercisePickerView extends StatefulWidget {
  const ExercisePickerView({
    super.key,
    this.width,
    this.height,
    required this.userId,
    this.languageCode,
    this.originalSelection,
    this.isLiveWorkout = false,
    this.liveExerciseSets,
    this.workoutName,
    this.onConfirm,
    this.onOpenDetails,
    this.onOpenCustomDetails,
    this.onCreate,
    this.onBack,
  });

  final double? width;
  final double? height;
  final String userId;
  final String? languageCode;
  final List<dynamic>? originalSelection;

  /// Live workout: exercises already in the workout are hidden (removal is
  /// done elsewhere) and the picker is add-only.
  final bool isLiveWorkout;

  /// Optional: the live workout's exerciseSets. Falls back to
  /// originalSelection when null.
  final List<dynamic>? liveExerciseSets;
  final String? workoutName;
  final Future Function(List<dynamic> selected)? onConfirm;
  final Future Function(int exerciseId)? onOpenDetails;
  final Future Function(int exerciseId)? onOpenCustomDetails;
  final Future Function()? onCreate;
  final Future Function()? onBack;

  @override
  State<ExercisePickerView> createState() => _ExercisePickerViewState();
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const double _kGutter = 16;
const double _kRadius = 16; // app-wide container radius
const double _kRadiusInner = 12;
const double _kRowImage = 72;
const double _kImageRadius = 14;
const int _kRecentDays = 30;
const int _kRecentMax = 8;
// Divider starts where the text starts: row padding + image + gap.
const double _kDividerIndent = 12 + _kRowImage + 14;

const Set<String> _kRtl = {'he', 'ar'};
const _kTabular = [FontFeature.tabularFigures()];

// ---------------------------------------------------------------------------
// UI strings. {n} / {g} are placeholders. English is the fallback.
// ---------------------------------------------------------------------------
const Map<String, Map<String, String>> _kStrings = {
  "addExercises": {
    "en": "Add exercises",
    "es": "Añadir ejercicios",
    "he": "הוספת תרגילים",
    "de": "Übungen hinzufügen",
    "fr": "Ajouter des exercices",
  },
  "inWorkout": {
    "en": "{n} in workout",
    "es": "{n} en el entrenamiento",
    "he": "{n} באימון",
    "de": "{n} im Workout",
    "fr": "{n} dans la séance",
  },
  "create": {
    "en": "Create",
    "es": "Crear",
    "he": "יצירה",
    "de": "Erstellen",
    "fr": "Créer",
  },
  "searchExercise": {
    "en": "Search exercise",
    "es": "Buscar ejercicio",
    "he": "חיפוש תרגיל",
    "de": "Übung suchen",
    "fr": "Rechercher un exercice",
  },
  "allMuscles": {
    "en": "All muscles",
    "es": "Todos los músculos",
    "he": "כל השרירים",
    "de": "Alle Muskeln",
    "fr": "Tous les muscles",
  },
  "allOf": {
    "en": "All {g}",
    "es": "Todo {g}",
    "he": "כל {g}",
    "de": "Alle {g}",
    "fr": "Tout {g}",
  },
  "equipment": {
    "en": "Equipment",
    "es": "Equipo",
    "he": "ציוד",
    "de": "Gerät",
    "fr": "Matériel",
  },
  "chooseMuscle": {
    "en": "Choose muscle group",
    "es": "Elegir grupo muscular",
    "he": "בחירת קבוצת שרירים",
    "de": "Muskelgruppe wählen",
    "fr": "Choisir un groupe musculaire",
  },
  "chooseSubMuscle": {
    "en": "Choose muscle",
    "es": "Elegir músculo",
    "he": "בחירת שריר",
    "de": "Muskel wählen",
    "fr": "Choisir un muscle",
  },
  "chooseEquipment": {
    "en": "Choose equipment",
    "es": "Elegir equipo",
    "he": "בחירת ציוד",
    "de": "Gerät wählen",
    "fr": "Choisir le matériel",
  },
  "searchMuscle": {
    "en": "Search muscle",
    "es": "Buscar músculo",
    "he": "חיפוש שריר",
    "de": "Muskel suchen",
    "fr": "Rechercher un muscle",
  },
  "searchEquipment": {
    "en": "Search equipment",
    "es": "Buscar equipo",
    "he": "חיפוש ציוד",
    "de": "Gerät suchen",
    "fr": "Rechercher du matériel",
  },
  "all": {
    "en": "All",
    "es": "Todos",
    "he": "הכל",
    "de": "Alle",
    "fr": "Tous",
  },
  "allEquipment": {
    "en": "All equipment",
    "es": "Todo el equipo",
    "he": "כל הציוד",
    "de": "Alle Geräte",
    "fr": "Tout le matériel",
  },
  "clear": {
    "en": "Clear",
    "es": "Limpiar",
    "he": "ניקוי",
    "de": "Zurücksetzen",
    "fr": "Effacer",
  },
  "showN": {
    "en": "Show {n} exercises",
    "es": "Mostrar {n} ejercicios",
    "he": "הצגת {n} תרגילים",
    "de": "{n} Übungen anzeigen",
    "fr": "Afficher {n} exercices",
  },
  "recent": {
    "en": "Recent",
    "es": "Recientes",
    "he": "אחרונים",
    "de": "Zuletzt",
    "fr": "Récents",
  },
  "custom": {
    "en": "Custom",
    "es": "Personalizados",
    "he": "מותאמים אישית",
    "de": "Eigene",
    "fr": "Personnalisés",
  },
  "allExercises": {
    "en": "All exercises",
    "es": "Todos los ejercicios",
    "he": "כל התרגילים",
    "de": "Alle Übungen",
    "fr": "Tous les exercices",
  },
  "other": {
    "en": "Other",
    "es": "Otros",
    "he": "אחר",
    "de": "Sonstige",
    "fr": "Autres",
  },
  "results": {
    "en": "{n} results",
    "es": "{n} resultados",
    "he": "{n} תוצאות",
    "de": "{n} Treffer",
    "fr": "{n} résultats",
  },
  "clearFilters": {
    "en": "Clear filters",
    "es": "Quitar filtros",
    "he": "ניקוי סינון",
    "de": "Filter löschen",
    "fr": "Effacer les filtres",
  },
  "noResults": {
    "en": "No exercises match",
    "es": "Ningún ejercicio coincide",
    "he": "לא נמצאו תרגילים",
    "de": "Keine passenden Übungen",
    "fr": "Aucun exercice trouvé",
  },
  "noResultsHint": {
    "en": "Try another search or clear the filters.",
    "es": "Prueba otra búsqueda o quita los filtros.",
    "he": "נסה חיפוש אחר או נקה את הסינון.",
    "de": "Andere Suche versuchen oder Filter löschen.",
    "fr": "Essayez une autre recherche ou effacez les filtres.",
  },
  "failedToLoad": {
    "en": "Couldn't load exercises",
    "es": "No se pudieron cargar los ejercicios",
    "he": "לא ניתן לטעון תרגילים",
    "de": "Übungen konnten nicht geladen werden",
    "fr": "Impossible de charger les exercices",
  },
  "addOne": {
    "en": "Add 1 exercise",
    "es": "Añadir 1 ejercicio",
    "he": "הוספת תרגיל אחד",
    "de": "1 Übung hinzufügen",
    "fr": "Ajouter 1 exercice",
  },
  "addN": {
    "en": "Add {n} exercises",
    "es": "Añadir {n} ejercicios",
    "he": "הוספת {n} תרגילים",
    "de": "{n} Übungen hinzufügen",
    "fr": "Ajouter {n} exercices",
  },
  "removeOne": {
    "en": "Remove 1 exercise",
    "es": "Quitar 1 ejercicio",
    "he": "הסרת תרגיל אחד",
    "de": "1 Übung entfernen",
    "fr": "Retirer 1 exercice",
  },
  "removeN": {
    "en": "Remove {n} exercises",
    "es": "Quitar {n} ejercicios",
    "he": "הסרת {n} תרגילים",
    "de": "{n} Übungen entfernen",
    "fr": "Retirer {n} exercices",
  },
  "saveChanges": {
    "en": "Save changes",
    "es": "Guardar cambios",
    "he": "שמירת שינויים",
    "de": "Änderungen speichern",
    "fr": "Enregistrer",
  },
  "summaryNew": {
    "en": "+{n} new",
    "es": "+{n} nuevos",
    "he": "+{n} חדשים",
    "de": "+{n} neu",
    "fr": "+{n} nouveaux",
  },
  "summaryRemoved": {
    "en": "−{n} removed",
    "es": "−{n} quitados",
    "he": "−{n} הוסרו",
    "de": "−{n} entfernt",
    "fr": "−{n} retirés",
  },
  "summaryTotal": {
    "en": "{n} in workout",
    "es": "{n} en total",
    "he": "{n} באימון",
    "de": "{n} im Workout",
    "fr": "{n} au total",
  },
};

// Equipment labels. The table stores English; this is display only.
const Map<String, Map<String, String>> _kEquipment = {
  "Bodyweight": {
    "en": "Bodyweight",
    "es": "Peso corporal",
    "he": "משקל גוף",
    "de": "Körpergewicht",
    "fr": "Poids du corps",
  },
  "Barbell": {
    "en": "Barbell",
    "es": "Barra",
    "he": "מוט",
    "de": "Langhantel",
    "fr": "Barre",
  },
  "Dumbbell": {
    "en": "Dumbbell",
    "es": "Mancuerna",
    "he": "משקולת יד",
    "de": "Kurzhantel",
    "fr": "Haltère",
  },
  "Machine": {
    "en": "Machine",
    "es": "Máquina",
    "he": "מכונה",
    "de": "Maschine",
    "fr": "Machine",
  },
  "Cable": {
    "en": "Cable",
    "es": "Polea",
    "he": "כבל",
    "de": "Kabelzug",
    "fr": "Poulie",
  },
  "Bench": {
    "en": "Bench",
    "es": "Banco",
    "he": "ספסל",
    "de": "Bank",
    "fr": "Banc",
  },
  "Plate": {
    "en": "Plate",
    "es": "Disco",
    "he": "פלטה",
    "de": "Scheibe",
    "fr": "Disque",
  },
  "Kettlebell": {
    "en": "Kettlebell",
    "es": "Kettlebell",
    "he": "קטלבל",
    "de": "Kettlebell",
    "fr": "Kettlebell",
  },
  "Trap Bar": {
    "en": "Trap bar",
    "es": "Barra hexagonal",
    "he": "מוט טראפ",
    "de": "Trap Bar",
    "fr": "Trap bar",
  },
  "Smith Machine": {
    "en": "Smith machine",
    "es": "Máquina Smith",
    "he": "סמית' משין",
    "de": "Multipresse",
    "fr": "Smith machine",
  },
  "Resistance Band": {
    "en": "Resistance band",
    "es": "Banda elástica",
    "he": "גומייה",
    "de": "Widerstandsband",
    "fr": "Bande élastique",
  },
  "Sled": {
    "en": "Sled",
    "es": "Trineo",
    "he": "מזחלת",
    "de": "Schlitten",
    "fr": "Traîneau",
  },
  "Medicine Ball": {
    "en": "Medicine ball",
    "es": "Balón medicinal",
    "he": "כדור כוח",
    "de": "Medizinball",
    "fr": "Médecine-ball",
  },
  "Jump Rope": {
    "en": "Jump rope",
    "es": "Cuerda",
    "he": "חבל קפיצה",
    "de": "Springseil",
    "fr": "Corde à sauter",
  },
  "Battle Ropes": {
    "en": "Battle ropes",
    "es": "Cuerdas de batalla",
    "he": "חבלי קרב",
    "de": "Battle Ropes",
    "fr": "Battle ropes",
  },
};

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------
class _Group {
  const _Group(this.id, this.name, this.nameEn, [this.image = '']);
  final int id;
  final String name; // localized
  final String nameEn; // English (image lookup)
  final String image;
}

class _MuscleRef {
  const _MuscleRef({
    required this.mgId,
    required this.mgName,
    required this.pmgId,
    required this.pmgName,
    required this.isPrimary,
  });
  final int mgId;
  final String mgName;
  final int pmgId;
  final String pmgName;
  final bool isPrimary;
}

class _Ex {
  _Ex({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.equipment,
    required this.hasFormCheck,
    required this.isPublic,
    required this.isCustom,
    required this.isBodyweight,
    required this.isAssisted,
    required this.isTimeBased,
    required this.illustration,
    required this.muscles,
  });
  final int id;
  final String name; // localized
  final String nameEn; // English (assets, search)
  final String equipment; // English, as stored
  final bool hasFormCheck;
  final bool isPublic;
  final bool isCustom;
  final bool isBodyweight;
  final bool isAssisted;
  final bool isTimeBased;
  final String? illustration;
  final List<_MuscleRef> muscles; // primary first

  Iterable<_MuscleRef> get primary => muscles.where((m) => m.isPrimary);
  _MuscleRef? get firstPrimary => primary.isNotEmpty
      ? primary.first
      : (muscles.isNotEmpty ? muscles.first : null);
}

class _Data {
  _Data({
    required this.exercises,
    required this.recentIds,
    required this.primaryGroups,
    required this.subGroups,
  });
  final List<_Ex> exercises;
  final List<int> recentIds; // most recent first
  final List<_Group> primaryGroups;
  final Map<int, List<_Group>> subGroups;
}

class _PickItem {
  const _PickItem(this.id, this.label, this.count,
      {this.labelEn = '', this.image = ''});
  final int? id;
  final String label;
  final String labelEn;
  final int count;
  final String image;
  bool get isAll => id == null;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class _ExercisePickerViewState extends State<ExercisePickerView> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  int? _pmgId;
  int? _mgId;
  final Set<String> _equip = {}; // English equipment values
  bool _fcOnly = false;

  // Selection (exercise ids). Order kept for the confirm payload.
  final List<int> _selected = [];
  final Set<int> _originalIds = {};
  // Live workout: exercises already in it — hidden from every list.
  final Set<int> _hiddenIds = {};
  List<int> _seedIds = const [];
  bool _busy = false;

  _Data? _data;
  String? _error;

  // Palette from FlutterFlowTheme (resolved in didChangeDependencies).
  Color _bg = const Color(0xFFF2F4F3);
  Color _card = const Color(0xFFFFFFFF);
  Color _cardSub = const Color(0xFFEEF1F0);
  Color _line = const Color(0xFFE2E7E5);
  Color _ink = const Color(0xFF0F1D1B);
  Color _inkMuted = const Color(0xFF5B6966);
  Color _inkFaint = const Color(0xFF9AAAA6);
  Color _accent = const Color(0xFF13B094);
  Color _accentDeep = const Color(0xFF0B7D6B);
  Color _accentTint = const Color(0xFFE1F4EF);

  // ---------------------------- localization --------------------------------

  String get _lang {
    final l = (widget.languageCode ?? 'en').trim().toLowerCase();
    return l.isEmpty ? 'en' : l;
  }

  bool get _isRtl => _kRtl.contains(_lang);

  ui.TextDirection get _dir =>
      _isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr;

  String _t(String key, {int? n, String? g}) {
    final m = _kStrings[key];
    var s = m == null ? key : (m[_lang] ?? m['en'] ?? key);
    if (n != null) s = s.replaceAll('{n}', '$n');
    if (g != null) s = s.replaceAll('{g}', g);
    return s;
  }

  String _eq(String en) {
    if (en.isEmpty) return '';
    final m = _kEquipment[en];
    if (m == null) return en;
    return m[_lang] ?? m['en'] ?? en;
  }

  // ------------------------------ lifecycle ---------------------------------

  @override
  void initState() {
    super.initState();
    // ~300 thumbnails decoded at 2x physical size need more than the 100MB
    // default, otherwise the cache evicts and re-decodes while scrolling.
    final cache = PaintingBinding.instance.imageCache;
    if (cache.maximumSizeBytes < 200 << 20) {
      cache.maximumSizeBytes = 200 << 20;
    }
    _seedSelection();
    _load();
  }

  @override
  void didUpdateWidget(covariant ExercisePickerView old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId ||
        old.languageCode != widget.languageCode) {
      _load();
    }
    // FlutterFlow rebuilds with a fresh list instance on every state change;
    // only reseed when the ids (or the mode) actually changed.
    final newIds = _idsOf(_seedSource);
    if (old.isLiveWorkout != widget.isLiveWorkout ||
        newIds.length != _seedIds.length ||
        !newIds.every(_seedIds.contains)) {
      _seedSelection();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final th = FlutterFlowTheme.of(context);
    _bg = th.primaryBackground;
    _card = th.secondaryBackground;
    _ink = th.primaryText;
    _inkMuted = th.secondaryText;
    _line = th.alternate;
    _cardSub = Color.alphaBlend(_ink.withOpacity(0.05), _card);
    _inkFaint = Color.alphaBlend(_inkMuted.withOpacity(0.55), _card);
    final p = th.primary;
    final h = HSLColor.fromColor(p);
    _accent = p;
    _accentDeep =
        h.withLightness((h.lightness * 0.72).clamp(0.0, 1.0)).toColor();
    _accentTint = Color.alphaBlend(p.withOpacity(0.13), _card);
  }

  /// Exercise id of one App State item, whatever shape it has: a Map, a
  /// FlutterFlow struct (toMap / .exerciseId), a JSON string, or an int.
  static int _idOf(dynamic e) {
    if (e == null) return 0;
    if (e is int || e is num) return _int(e);
    if (e is Map) return _int(e['exerciseId'] ?? e['exercise_id']);
    if (e is String) {
      try {
        final m = jsonDecode(e);
        if (m is Map) return _int(m['exerciseId'] ?? m['exercise_id']);
      } catch (_) {}
      return _int(e);
    }
    try {
      final m = (e as dynamic).toMap();
      if (m is Map) return _int(m['exerciseId'] ?? m['exercise_id']);
    } catch (_) {}
    try {
      return _int((e as dynamic).exerciseId);
    } catch (_) {}
    return 0;
  }

  static List<int> _idsOf(List<dynamic>? list) {
    final out = <int>[];
    for (final e in list ?? const []) {
      final id = _idOf(e);
      if (id > 0 && !out.contains(id)) out.add(id);
    }
    return out;
  }

  List<dynamic>? get _seedSource =>
      widget.isLiveWorkout && widget.liveExerciseSets != null
          ? widget.liveExerciseSets
          : widget.originalSelection;

  void _seedSelection() {
    _seedIds = _idsOf(_seedSource);
    _originalIds.clear();
    _selected.clear();
    _hiddenIds.clear();
    if (widget.isLiveWorkout) {
      // Add-only: what is in the workout is hidden, nothing starts selected.
      _hiddenIds.addAll(_seedIds);
    } else {
      _originalIds.addAll(_seedIds);
      _selected.addAll(_seedIds);
    }
  }

  Future<void> _load() async {
    try {
      final d = await _fetch();
      if (!mounted) return;
      setState(() {
        _data = d;
        _error = null;
      });
      _warmImages(d.exercises);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  // ------------------------------ helpers -----------------------------------

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString().trim() ?? '') ?? 0;
  }

  static bool _flag(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v == 1;
    final s = (v ?? '').toString().trim().toLowerCase();
    return s == '1' || s == 'true';
  }

  static String _str(dynamic v) => (v ?? '').toString().trim();

  // ------------------------------- fetch ------------------------------------

  Future<_Data> _fetch() async {
    final db = SQLiteManager.instance.database;
    final uid = widget.userId;
    final lang = _lang;

    // SELECT * so the image column can be named anything (or not exist).
    final pmgRows =
        await db.rawQuery('SELECT * FROM primary_muscle_group ORDER BY id');
    final mgRows = await db.rawQuery('SELECT * FROM muscle_group');
    String img(Map r) => _str(r['ilustration'] ??
        r['illustration'] ??
        r['image_url'] ??
        r['image'] ??
        r['icon']);
    final emgRows = await db.rawQuery('''
      SELECT emg.exercise_id, emg.muscle_group_id, emg.is_primary,
             mg.name AS mg_name, mg.primary_muscle_group_id AS pmg_id,
             pmg.name AS pmg_name
      FROM exercise_muscle_group emg
      JOIN muscle_group mg ON mg.id = emg.muscle_group_id
      LEFT JOIN primary_muscle_group pmg ON pmg.id = mg.primary_muscle_group_id
      ORDER BY emg.exercise_id, emg.is_primary DESC, emg.id
    ''');

    final primaryGroups = <_Group>[
      for (final r in pmgRows)
        _Group(
          _int(r['id']),
          localizedName(_str(r['name']), lang),
          localizedName(_str(r['name']), 'en'),
          img(r),
        ),
    ];
    final subGroups = <int, List<_Group>>{};
    for (final r in mgRows) {
      subGroups.putIfAbsent(_int(r['primary_muscle_group_id']), () => []).add(
            _Group(
              _int(r['id']),
              localizedName(_str(r['name']), lang),
              localizedName(_str(r['name']), 'en'),
              img(r),
            ),
          );
    }
    for (final list in subGroups.values) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    final exMuscles = <int, List<_MuscleRef>>{};
    for (final r in emgRows) {
      exMuscles.putIfAbsent(_int(r['exercise_id']), () => []).add(_MuscleRef(
            mgId: _int(r['muscle_group_id']),
            mgName: localizedName(_str(r['mg_name']), lang),
            pmgId: _int(r['pmg_id']),
            pmgName: localizedName(_str(r['pmg_name']), lang),
            isPrimary: _int(r['is_primary']) == 1,
          ));
    }

    // Catalog + the user's custom exercises. Images come from assets by
    // English name; custom ones by their illustration file name.
    final exRows = await db.rawQuery('''
      SELECT id, name, equipment, ai_form_analysis, is_public,
             created_by_user_id, illustration, is_bodyweight, is_assisted,
             is_time_based
      FROM exercise
      WHERE COALESCE(is_deleted, 0) = 0
        AND (COALESCE(is_public, 0) = 1 OR created_by_user_id = ?)
    ''', [uid]);
    final exercises = <_Ex>[];
    for (final r in exRows) {
      final id = _int(r['id']);
      final isPublic = _flag(r['is_public']);
      final createdBy = _str(r['created_by_user_id']);
      final rawName = _str(r['name']);
      final ill = _str(r['illustration']);
      exercises.add(_Ex(
        id: id,
        name: localizedName(rawName, lang),
        nameEn: localizedName(rawName, 'en'),
        equipment: _str(r['equipment']),
        hasFormCheck: _flag(r['ai_form_analysis']),
        isPublic: isPublic,
        isCustom: !isPublic || (uid.isNotEmpty && createdBy == uid),
        isBodyweight: _flag(r['is_bodyweight']),
        isAssisted: _flag(r['is_assisted']),
        isTimeBased: _flag(r['is_time_based']),
        // Only bare file names are local custom images; URLs/blobs ignored.
        illustration:
            (ill.isEmpty || ill.contains('/') || ill.length > 120) ? null : ill,
        muscles: exMuscles[id] ?? const [],
      ));
    }
    exercises
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // Recent: last N distinct exercises the user logged sets for.
    final recentIds = <int>[];
    try {
      final rRows = await db.rawQuery('''
        SELECT s.exercise_id, MAX(s.created_at) AS last_used
        FROM set_log s
        WHERE s.user_id = ?
          AND strftime('%s', s.created_at) >=
              strftime('%s', datetime('now', '-$_kRecentDays days'))
        GROUP BY s.exercise_id
        ORDER BY last_used DESC
        LIMIT $_kRecentMax
      ''', [uid]);
      for (final r in rRows) {
        final id = _int(r['exercise_id']);
        if (id > 0) recentIds.add(id);
      }
    } catch (_) {
      // set_log shape differs → no Recent section, nothing else breaks.
    }

    return _Data(
      exercises: exercises,
      recentIds: recentIds,
      primaryGroups: primaryGroups,
      subGroups: subGroups,
    );
  }

  // ------------------------------ filtering ---------------------------------

  bool _notHidden(_Ex e) => !_hiddenIds.contains(e.id);

  bool _matchesMuscle(_Ex e) {
    if (_pmgId == null) return true;
    if (_mgId != null) return e.muscles.any((m) => m.mgId == _mgId);
    return e.muscles.any((m) => m.pmgId == _pmgId);
  }

  bool _matches(_Ex e,
      {bool ignoreEquipment = false, bool ignoreFormCheck = false}) {
    if (_hiddenIds.contains(e.id)) return false;
    if (_query.isNotEmpty) {
      final q = _query;
      if (!e.name.toLowerCase().contains(q) &&
          !e.nameEn.toLowerCase().contains(q)) return false;
    }
    if (!_matchesMuscle(e)) return false;
    if (!ignoreEquipment &&
        _equip.isNotEmpty &&
        !_equip.contains(e.equipment)) {
      return false;
    }
    if (!ignoreFormCheck && _fcOnly && !e.hasFormCheck) return false;
    return true;
  }

  List<_Ex> _visible() =>
      (_data?.exercises ?? const []).where(_matches).toList();

  bool get _filtered =>
      _query.isNotEmpty || _pmgId != null || _equip.isNotEmpty || _fcOnly;

  void _clearFilters() {
    _search.clear();
    setState(() {
      _query = '';
      _pmgId = null;
      _mgId = null;
      _equip.clear();
      _fcOnly = false;
    });
  }

  // ------------------------------ selection ---------------------------------

  bool _isSelected(int id) => _selected.contains(id);

  void _toggle(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  int get _addedCount =>
      _selected.where((id) => !_originalIds.contains(id)).length;
  int get _removedCount =>
      _originalIds.where((id) => !_selected.contains(id)).length;

  String? _ctaLabel() {
    final a = _addedCount, r = _removedCount;
    if (a == 0 && r == 0) return null;
    if (a > 0 && r == 0) return a == 1 ? _t('addOne') : _t('addN', n: a);
    if (r > 0 && a == 0) return r == 1 ? _t('removeOne') : _t('removeN', n: r);
    return _t('saveChanges');
  }

  Future<void> _confirm() async {
    if (_busy || widget.onConfirm == null) return;
    final byId = {for (final e in _data?.exercises ?? const <_Ex>[]) e.id: e};
    final out = <dynamic>[];
    for (final id in _selected) {
      final e = byId[id];
      if (e == null) {
        // Still in the workout but not in the catalog any more: keep the id
        // so the page does not drop it.
        out.add({'exerciseId': id});
        continue;
      }
      out.add({
        'exerciseId': e.id,
        'exerciseName': e.nameEn,
        'isBodyweight': e.isBodyweight ? 1 : 0,
        'isAssisted': e.isAssisted ? 1 : 0,
        'isPublic': e.isPublic ? 1 : 0,
        'isTimeBased': e.isTimeBased ? 1 : 0,
        'equipment': e.equipment,
      });
    }
    setState(() => _busy = true);
    try {
      await widget.onConfirm!(out);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ------------------------------ pickers -----------------------------------

  Future<void> _pickPrimary() async {
    final d = _data;
    if (d == null) return;
    final items = <_PickItem>[
      _PickItem(null, _t('all'), d.exercises.where(_notHidden).length),
      for (final g in d.primaryGroups)
        _PickItem(
          g.id,
          g.name,
          d.exercises
              .where(
                  (e) => _notHidden(e) && e.muscles.any((m) => m.pmgId == g.id))
              .length,
          labelEn: g.nameEn,
          image: g.image,
        ),
    ];
    final picked = await _showPicker(
        title: _t('chooseMuscle'),
        hint: _t('searchMuscle'),
        items: items,
        selected: _pmgId);
    if (picked == null || !mounted) return;
    setState(() {
      _pmgId = picked.id;
      _mgId = null;
    });
  }

  Future<void> _pickSub() async {
    final d = _data;
    if (d == null || _pmgId == null) return;
    final subs = d.subGroups[_pmgId] ?? const <_Group>[];
    _Group? pmg;
    for (final g in d.primaryGroups) {
      if (g.id == _pmgId) pmg = g;
    }
    final items = <_PickItem>[
      _PickItem(
          null,
          _t('allOf', g: (pmg?.name ?? '').toLowerCase()),
          d.exercises
              .where((e) =>
                  _notHidden(e) && e.muscles.any((m) => m.pmgId == _pmgId))
              .length),
      for (final g in subs)
        _PickItem(
          g.id,
          g.name,
          d.exercises
              .where(
                  (e) => _notHidden(e) && e.muscles.any((m) => m.mgId == g.id))
              .length,
          labelEn: g.nameEn,
          image: g.image,
        ),
    ];
    final picked = await _showPicker(
        title: _t('chooseSubMuscle'),
        hint: _t('searchMuscle'),
        items: items,
        selected: _mgId);
    if (picked == null || !mounted) return;
    setState(() => _mgId = picked.id);
  }

  /// Same look as the app's muscle sheet: centered title, search, 64px
  /// illustration per row, hairline dividers, check on the selected one.
  Future<_PickItem?> _showPicker({
    required String title,
    required String hint,
    required List<_PickItem> items,
    required int? selected,
  }) {
    return showModalBottomSheet<_PickItem>(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final maxH = MediaQuery.of(ctx).size.height * 0.85;
        String q = '';
        return Directionality(
          textDirection: _dir,
          child: StatefulBuilder(
            builder: (sctx, setSheet) {
              final visible = q.isEmpty
                  ? items
                  : items
                      .where((it) =>
                          it.isAll ||
                          it.label.toLowerCase().contains(q) ||
                          it.labelEn.toLowerCase().contains(q))
                      .toList();
              return Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(sctx).viewInsets.bottom),
                child: SafeArea(
                  top: false,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxH),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        _grabber(),
                        const SizedBox(height: 22),
                        Text(title,
                            style: _display(26, w: FontWeight.w700),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 18),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: _kGutter),
                          child: _searchBox(
                            hint: hint,
                            onChanged: (v) =>
                                setSheet(() => q = v.trim().toLowerCase()),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
                            itemCount: visible.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              thickness: 1,
                              color: _cardSub,
                              indent: _kGutter,
                              endIndent: _kGutter,
                            ),
                            itemBuilder: (_, i) => _pickRow(
                                sctx, visible[i], visible[i].id == selected),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _pickRow(BuildContext ctx, _PickItem it, bool on) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(ctx).pop(it),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _kGutter, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: it.isAll
                  ? Icon(Icons.grid_view_rounded, size: 28, color: _ink)
                  : ExerciseAssetImage(
                      width: 64,
                      height: 64,
                      exerciseName: exerciseImageName(
                              it.labelEn.isEmpty ? it.label : it.labelEn)
                          .toString(),
                      fallbackAsset: it.image.isEmpty
                          ? null
                          : (it.image.contains('/')
                              ? it.image
                              : 'assets/images/${it.image}'),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                it.label,
                style: _body(17,
                    w: on ? FontWeight.w600 : FontWeight.w500,
                    color: on ? _accentDeep : _ink),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('${it.count}', style: _body(13, color: _inkFaint)),
            if (on) ...[
              const SizedBox(width: 12),
              Icon(Icons.check_rounded, size: 22, color: _accent),
            ],
          ],
        ),
      ),
    );
  }

  /// Equipment: multi-select, counts follow the current muscle / search /
  /// AI filters, values come from the data (new equipment shows up alone).
  Future<void> _pickEquipment() async {
    final d = _data;
    if (d == null) return;
    final base = d.exercises.where((e) => _matches(e, ignoreEquipment: true));
    final counts = <String, int>{};
    for (final e in base) {
      if (e.equipment.isEmpty) continue;
      counts[e.equipment] = (counts[e.equipment] ?? 0) + 1;
    }
    // Known order first, then anything new, alphabetically.
    final known = _kEquipment.keys.where(counts.containsKey).toList();
    final extra = counts.keys.where((k) => !_kEquipment.containsKey(k)).toList()
      ..sort();
    final all = [...known, ...extra];
    final local = Set<String>.from(_equip);

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final maxH = MediaQuery.of(ctx).size.height * 0.85;
        String q = '';
        return Directionality(
          textDirection: _dir,
          child: StatefulBuilder(
            builder: (sctx, setSheet) {
              final visible = q.isEmpty
                  ? all
                  : all
                      .where((k) =>
                          k.toLowerCase().contains(q) ||
                          _eq(k).toLowerCase().contains(q))
                      .toList();
              final shown = base
                  .where((e) => local.isEmpty || local.contains(e.equipment))
                  .length;
              return Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(sctx).viewInsets.bottom),
                child: SafeArea(
                  top: false,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxH),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        _grabber(),
                        const SizedBox(height: 22),
                        Text(_t('chooseEquipment'),
                            style: _display(26, w: FontWeight.w700),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 18),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: _kGutter),
                          child: _searchBox(
                            hint: _t('searchEquipment'),
                            onChanged: (v) =>
                                setSheet(() => q = v.trim().toLowerCase()),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                            itemCount: visible.length + (q.isEmpty ? 1 : 0),
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              thickness: 1,
                              color: _cardSub,
                              indent: _kGutter,
                              endIndent: _kGutter,
                            ),
                            itemBuilder: (_, i) {
                              if (q.isEmpty && i == 0) {
                                return _equipRow(
                                  label: _t('allEquipment'),
                                  count: base.length,
                                  on: local.isEmpty,
                                  leading: Icon(Icons.grid_view_rounded,
                                      size: 28, color: _ink),
                                  onTap: () => setSheet(local.clear),
                                );
                              }
                              final k = visible[i - (q.isEmpty ? 1 : 0)];
                              final on = local.contains(k);
                              return _equipRow(
                                label: _eq(k),
                                count: counts[k] ?? 0,
                                on: on,
                                leading: _equipImage(k),
                                onTap: () => setSheet(() {
                                  if (!local.remove(k)) local.add(k);
                                }),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              _kGutter, 10, _kGutter, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: _button(
                                  _t('clear'),
                                  filled: false,
                                  onTap: () => setSheet(local.clear),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: _button(
                                  _t('showN', n: shown),
                                  onTap: () =>
                                      Navigator.of(sctx).pop(Set.of(local)),
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
            },
          ),
        );
      },
    );
    if (result == null || !mounted) return;
    setState(() {
      _equip
        ..clear()
        ..addAll(result);
    });
  }

  Widget _equipRow({
    required String label,
    required int count,
    required bool on,
    required Widget leading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _kGutter, vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 64, height: 64, child: Center(child: leading)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style: _body(17,
                      w: on ? FontWeight.w600 : FontWeight.w500,
                      color: on ? _accentDeep : _ink),
                  overflow: TextOverflow.ellipsis),
            ),
            Text('$count', style: _body(13, color: _inkFaint)),
            const SizedBox(width: 12),
            Icon(on ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 22, color: on ? _accent : _line),
          ],
        ),
      ),
    );
  }

  /// Equipment illustration from assets (assets/images/<Name_With_Underscores>.jpg),
  /// a neutral icon when there is none.
  Widget _equipImage(String en) {
    final asset = 'assets/images/${exerciseImageName(en)}.jpg';
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kRadiusInner),
      child: Image.asset(
        asset,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 64,
          height: 64,
          color: _cardSub,
          child: Icon(Icons.fitness_center_rounded, size: 26, color: _inkMuted),
        ),
      ),
    );
  }

  // ------------------------------ typography --------------------------------

  TextStyle _ts(
    double size, {
    Color? color,
    FontWeight w = FontWeight.w400,
    double height = 1.25,
    double letterSpacing = 0,
    bool display = false,
  }) {
    final th = FlutterFlowTheme.of(context);
    final fam = display ? th.headlineMediumFamily : th.bodyMediumFamily;
    final base = display ? th.headlineMedium : th.bodyMedium;
    return base
        .override(
          fontFamily: fam,
          color: color ?? _ink,
          fontSize: size,
          fontWeight: w,
          lineHeight: height,
          letterSpacing: letterSpacing,
          useGoogleFonts: GoogleFonts.asMap().containsKey(fam),
        )
        .copyWith(fontFeatures: _kTabular);
  }

  TextStyle _display(double size,
          {Color? color, FontWeight w = FontWeight.w800}) =>
      _ts(size,
          color: color,
          w: w,
          height: 1.05,
          letterSpacing: _isRtl ? 0 : -size * 0.02,
          display: true);

  TextStyle _body(double size,
          {Color? color, FontWeight w = FontWeight.w400}) =>
      _ts(size, color: color, w: w);

  TextStyle _eyebrow({Color? color}) => _ts(11,
      color: color ?? _inkMuted,
      w: FontWeight.w600,
      letterSpacing: _isRtl ? 0 : 1.4);

  // --------------------------------- UI -------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _dir,
      child: Container(
        width: widget.width,
        height: widget.height,
        color: _bg,
        child: Column(
          children: [
            _header(),
            Padding(
              padding: const EdgeInsets.fromLTRB(_kGutter, 10, _kGutter, 0),
              child: _searchBox(
                controller: _search,
                hint: _t('searchExercise'),
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                onClear: () {
                  _search.clear();
                  setState(() => _query = '');
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(_kGutter, 10, _kGutter, 0),
              child: _filters(),
            ),
            Expanded(child: _content()),
            _cta(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final top = MediaQuery.of(context).padding.top;
    final total = _hiddenIds.length + _selected.length;
    // Equal-width slots on both sides keep the title exactly centered while
    // the buttons sit at the edges.
    const slot = 92.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, top + 8, 12, 0),
      child: Row(
        children: [
          SizedBox(
            width: slot,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _roundIcon(
                Icons.arrow_back_ios_new_rounded,
                onTap: () async {
                  if (widget.onBack != null) {
                    await widget.onBack!();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
                // Arrow points "back" in both directions.
                flip: _isRtl,
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_t('addExercises'),
                    style: _display(17, w: FontWeight.w700),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  [
                    if ((widget.workoutName ?? '').trim().isNotEmpty)
                      widget.workoutName!.trim(),
                    _t('inWorkout', n: total),
                  ].join(' · '),
                  style: _body(12, color: _inkMuted),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            width: slot,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap:
                    widget.onCreate == null ? null : () => widget.onCreate!(),
                child: Container(
                  height: 40,
                  padding: const EdgeInsetsDirectional.only(start: 10, end: 14),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 18, color: _accentDeep),
                      const SizedBox(width: 4),
                      Text(_t('create'),
                          style: _body(14,
                              w: FontWeight.w700, color: _accentDeep)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIcon(IconData icon,
      {required VoidCallback onTap, bool flip = false}) {
    final child = Icon(icon, size: 18, color: _ink);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: _card, shape: BoxShape.circle),
        child: Center(
          child: flip
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(3.14159),
                  child: child)
              : child,
        ),
      ),
    );
  }

  Widget _searchBox({
    TextEditingController? controller,
    required String hint,
    required ValueChanged<String> onChanged,
    VoidCallback? onClear,
  }) {
    final hasText = controller != null && controller.text.isNotEmpty;
    return Container(
      height: 48,
      padding: const EdgeInsetsDirectional.only(start: 14, end: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: _inkMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: _body(15),
              cursorColor: _accent,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: _body(15, color: _inkMuted),
              ),
            ),
          ),
          if (hasText && onClear != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration:
                      BoxDecoration(color: _cardSub, shape: BoxShape.circle),
                  child: Icon(Icons.close_rounded, size: 13, color: _inkMuted),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filters() {
    final d = _data;
    _Group? pmg;
    _Group? mg;
    var subs = const <_Group>[];
    if (d != null && _pmgId != null) {
      for (final g in d.primaryGroups) {
        if (g.id == _pmgId) pmg = g;
      }
      subs = d.subGroups[_pmgId] ?? const [];
      if (_mgId != null) {
        for (final g in subs) {
          if (g.id == _mgId) mg = g;
        }
      }
    }
    // How many AI-form exercises the other filters leave.
    final fcAvail = (d?.exercises ?? const <_Ex>[])
        .where((e) => e.hasFormCheck && _matches(e, ignoreFormCheck: true))
        .length;
    final equipLabel = _equip.isEmpty
        ? _t('equipment')
        : (_equip.length == 1
            ? _eq(_equip.first)
            : '${_eq(_equip.first)} +${_equip.length - 1}');

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _filterChip(
                  label: pmg?.name ?? _t('allMuscles'),
                  active: pmg != null,
                  onTap: _pickPrimary,
                  onClear: pmg == null
                      ? null
                      : () => setState(() {
                            _pmgId = null;
                            _mgId = null;
                          }),
                ),
                if (pmg != null && subs.length > 1) ...[
                  const SizedBox(width: 6),
                  _filterChip(
                    label: mg?.name ?? _t('allOf', g: pmg.name.toLowerCase()),
                    active: mg != null,
                    onTap: _pickSub,
                    onClear:
                        mg == null ? null : () => setState(() => _mgId = null),
                  ),
                ],
                const SizedBox(width: 6),
                _filterChip(
                  label: equipLabel,
                  active: _equip.isNotEmpty,
                  onTap: _pickEquipment,
                  onClear: _equip.isEmpty
                      ? null
                      : () => setState(() => _equip.clear()),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _fcOnly = !_fcOnly),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _fcOnly ? _accentTint : _card,
              borderRadius: BorderRadius.circular(_kRadiusInner),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AiFormBadge(
                  width: 18,
                  height: 18,
                  showLabel: false,
                  iconSize: 18,
                  color: _fcOnly ? _accentDeep : _ink,
                ),
                const SizedBox(width: 6),
                Text('$fcAvail',
                    style: _body(13,
                        w: FontWeight.w600,
                        color: _fcOnly ? _accentDeep : _ink)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final fg = active ? _accentDeep : _ink;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
        decoration: BoxDecoration(
          color: active ? _accentTint : _card,
          borderRadius: BorderRadius.circular(_kRadiusInner),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: _body(13,
                    color: fg, w: active ? FontWeight.w600 : FontWeight.w500)),
            const SizedBox(width: 4),
            if (onClear == null)
              Icon(Icons.expand_more_rounded, size: 18, color: fg)
            else
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.close_rounded, size: 16, color: fg),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ------------------------------- content ----------------------------------

  Widget _content() {
    final d = _data;
    if (d == null) {
      return Center(
        child: _error == null
            ? CircularProgressIndicator(color: _accent, strokeWidth: 2)
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Text('${_t('failedToLoad')}\n$_error',
                    textAlign: TextAlign.center,
                    style: _body(13, color: _inkMuted)),
              ),
      );
    }

    final visible = _visible();
    final byId = {for (final e in visible) e.id: e};
    final children = <Widget>[];

    if (_filtered) {
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(_kGutter + 4, 14, _kGutter + 4, 0),
        child: Row(
          children: [
            Text(_t('results', n: visible.length),
                style: _body(12, color: _inkMuted)),
            const Spacer(),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _clearFilters,
              child: Text(_t('clearFilters'),
                  style: _body(12, w: FontWeight.w700, color: _accentDeep)),
            ),
          ],
        ),
      ));
    }

    if (visible.isEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(_kGutter, 40, _kGutter, 0),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 36, color: _inkFaint),
            const SizedBox(height: 10),
            Text(_t('noResults'),
                style: _body(16, w: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(_t('noResultsHint'),
                style: _body(13, color: _inkMuted),
                textAlign: TextAlign.center),
          ],
        ),
      ));
    } else {
      // Recent: the recent ones that pass the current filters.
      final recent = <_Ex>[
        for (final id in d.recentIds)
          if (byId[id] != null) byId[id]!,
      ];
      if (recent.isNotEmpty) {
        children.addAll(_section(_t('recent'), recent, count: false));
      }
      final custom = visible.where((e) => e.isCustom).toList();
      if (custom.isNotEmpty) {
        children.addAll(_section(_t('custom'), custom));
      }
      // All: grouped by the first primary muscle's category, in
      // primary_muscle_group order; no muscles → Other.
      final catalog = visible.where((e) => !e.isCustom).toList();
      final byGroup = <int, List<_Ex>>{};
      final other = <_Ex>[];
      for (final e in catalog) {
        final fp = e.firstPrimary;
        if (fp == null || fp.pmgId == 0) {
          other.add(e);
        } else {
          byGroup.putIfAbsent(fp.pmgId, () => []).add(e);
        }
      }
      if (_pmgId == null && (recent.isNotEmpty || custom.isNotEmpty)) {
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(_kGutter + 4, 22, _kGutter + 4, 0),
          child: Text(_t('allExercises').toUpperCase(),
              style: _eyebrow(color: _inkFaint)),
        ));
      }
      for (final g in d.primaryGroups) {
        final items = byGroup[g.id];
        if (items == null || items.isEmpty) continue;
        children.addAll(_section(g.name, items));
      }
      for (final entry in byGroup.entries) {
        if (d.primaryGroups.any((g) => g.id == entry.key)) continue;
        children.addAll(
            _section(entry.value.first.firstPrimary!.pmgName, entry.value));
      }
      if (other.isNotEmpty) children.addAll(_section(_t('other'), other));
    }

    final bottom = MediaQuery.of(context).padding.bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 24 + bottom),
      children: children,
    );
  }

  List<Widget> _section(String title, List<_Ex> items, {bool count = true}) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(_kGutter + 4, 18, _kGutter + 4, 8),
        child: Row(
          children: [
            Expanded(child: Text(title.toUpperCase(), style: _eyebrow())),
            if (count)
              Text('${items.length}', style: _body(11, color: _inkFaint)),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: _kGutter),
        child: Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(_kRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _row(items[i]),
                if (i < items.length - 1)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                        start: _kDividerIndent),
                    child: Divider(height: 1, thickness: 1, color: _cardSub),
                  ),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  Widget _row(_Ex e) {
    final on = _isSelected(e.id);
    // Position in the workout (1-based) — shown on the badge when selected.
    final order = on ? _selected.indexOf(e.id) + 1 : 0;
    final fp = e.firstPrimary;
    final sub = <String>[
      if (e.equipment.isNotEmpty) _eq(e.equipment),
      if (fp != null && fp.mgName.isNotEmpty) fp.mgName,
    ].join(' · ');
    final details =
        e.isCustom ? widget.onOpenCustomDetails : widget.onOpenDetails;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggle(e.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        color: on ? _accentTint : Colors.transparent,
        padding: const EdgeInsetsDirectional.fromSTEB(12, 14, 12, 14),
        child: Row(
          children: [
            // Illustration is the hero; selection = ring + order badge, nothing else.
            SizedBox(
              width: _kRowImage,
              height: _kRowImage,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: _kRowImage,
                    height: _kRowImage,
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(_kImageRadius),
                      border: Border.all(
                          color: on ? _accent : Colors.transparent, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _rowImage(e),
                  ),
                  PositionedDirectional(
                    end: -6,
                    bottom: -6,
                    child: AnimatedScale(
                      scale: on ? 1 : 0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 24),
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        decoration: BoxDecoration(
                          color: _accent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _accentTint, width: 2.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$order',
                          style: _body(12,
                              w: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(e.name,
                            style: _ts(16,
                                w: FontWeight.w600,
                                color: on ? _accentDeep : _ink,
                                height: 1.2,
                                letterSpacing: _isRtl ? 0 : -0.16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (e.hasFormCheck) ...[
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: AiFormBadge(showLabel: true, iconSize: 11),
                        ),
                      ],
                    ],
                  ),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(sub,
                        style: _body(13, color: _inkMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Details: quiet outline button, catalog vs custom go to
            // different callbacks (different pages behind them).
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: details == null ? null : () => details(e.id),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: on ? _accent : _line, width: 1.5),
                ),
                child: Icon(Icons.query_stats_rounded,
                    size: 19, color: on ? _accentDeep : _inkMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Catalog images are rendered here directly from assets, decoded once at
  /// a small size and kept in the image cache, so fast scrolling never shows
  /// a placeholder. Custom exercises keep going through ExerciseAssetImage.
  Widget _rowImage(_Ex e) {
    if (e.illustration != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(_kImageRadius),
        child: ExerciseAssetImage(
          width: _kRowImage,
          height: _kRowImage,
          exerciseName: exerciseImageName(e.nameEn).toString(),
          illustration: e.illustration,
          borderRadius: _kImageRadius,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kImageRadius),
      child: Image(
        image: _assetFor(e.nameEn),
        width: _kRowImage,
        height: _kRowImage,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Container(
          width: _kRowImage,
          height: _kRowImage,
          color: _cardSub,
          child: Icon(Icons.fitness_center_rounded, size: 24, color: _inkFaint),
        ),
      ),
    );
  }

  /// Decoded at twice the physical size of the thumbnail, so there is no
  /// soft resample at 1:1 and the selected-state scale stays crisp.
  ImageProvider _assetFor(String nameEn) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return ResizeImage(
      AssetImage('assets/images/${exerciseImageName(nameEn)}.jpg'),
      width: (_kRowImage * dpr * 2).round(),
      policy: ResizeImagePolicy.fit,
    );
  }

  /// Decode every catalog image once, right after load, so the list is
  /// warm before the user starts scrolling. Errors (missing files) are
  /// swallowed; the row shows its fallback icon.
  void _warmImages(List<_Ex> list) {
    for (final e in list) {
      if (e.illustration != null) continue;
      precacheImage(_assetFor(e.nameEn), context, onError: (_, __) {});
    }
  }

  // --------------------------------- CTA ------------------------------------

  Widget _cta() {
    final label = _ctaLabel();
    final bottom = MediaQuery.of(context).padding.bottom;
    final a = _addedCount, r = _removedCount;
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: label == null
          ? const SizedBox(width: double.infinity, height: 0)
          : Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(_kGutter, 10, _kGutter, 12 + bottom),
              color: _bg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (a > 0 && r > 0) ...[
                    Text(
                      [
                        _t('summaryNew', n: a),
                        _t('summaryRemoved', n: r),
                        _t('summaryTotal', n: _selected.length),
                      ].join('   ·   '),
                      style: _body(12, color: _inkMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                  ],
                  _button(label, busy: _busy, onTap: _confirm),
                ],
              ),
            ),
    );
  }

  // ------------------------------ primitives --------------------------------

  Widget _grabber() => Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: _line,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _button(String label,
      {required VoidCallback? onTap, bool filled = true, bool busy = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: busy ? null : onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: filled ? _accent : _cardSub,
          borderRadius: BorderRadius.circular(_kRadius),
        ),
        child: Center(
          child: busy
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: filled ? Colors.white : _ink))
              : Text(label,
                  style: _body(16,
                      w: FontWeight.w700, color: filled ? Colors.white : _ink)),
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
