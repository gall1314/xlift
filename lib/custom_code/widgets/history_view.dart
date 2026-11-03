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

// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` butimport 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl show DateFormat;
import 'dart:ui' as ui;

/// Full History page body: search field, period + muscle filter pills (both
/// bottom sheets built in), workout cards and empty states.
///
/// Fully self-managed, no page state needed: loads from the SQLite query
/// history(userId) and filters in memory, so search / period / muscle always
/// stay in sync.
///
/// Period keys (internal, English): Last 7 days, Last 30 days, Last 90 days,
/// All time. Shown translated. When [isPremium] is false, "Last 90 days" and
/// "All time" are locked (tapping one fires [onLockedTap]) and the default is
/// "Last 30 days"; for premium the default is "All time".
///
/// Localization: reads the app language from FFLocalizations (no parameter).
/// Muscle names come from the DB JSON via localizedName; filtering by muscle
/// is done on the English name so it is language independent. Hebrew renders
/// RTL.
///
/// Callbacks: [onWorkoutTap](workoutLogId) from a card tap and
/// [onMenuTap](workoutLogId) from the card's options button. The list reloads
/// when either action finishes.
///
/// Compare mode ([compareMode] = true): same look and filters, but a card tap
/// selects it (single selection, highlighted), the options button is hidden,
/// and a "Compare" CTA floats at the bottom. It is enabled once a workout is
/// selected and fires [onCompare](workoutLogId). [onWorkoutTap] / [onMenuTap]
/// are not called in this mode. Pass the already-chosen workout as
/// [excludeWorkoutLogId] so it is left out of the list.
///
/// Optional: change [reloadToken] (any different int) to force a reload.
/// Pull-to-refresh also reloads.
class HistoryView extends StatefulWidget {
  const HistoryView({
    super.key,
    this.width,
    this.height,
    required this.userId,
    this.isPremium,
    this.reloadToken,
    this.onWorkoutTap,
    this.onMenuTap,
    this.onLockedTap,
    this.compareMode,
    this.onCompare,
    this.excludeWorkoutLogId,
  });

  final double? width;
  final double? height;
  final String userId;
  final bool? isPremium;
  final int? reloadToken;
  final Future Function(String workoutLogId)? onWorkoutTap;
  final Future Function(String workoutLogId)? onMenuTap;
  final Future Function()? onLockedTap;
  final bool? compareMode;
  final Future Function(String workoutLogId)? onCompare;

  /// A workout_log_id to hide from the list (the one already picked for a
  /// comparison). Empty / null = hide nothing.
  final String? excludeWorkoutLogId;

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

// ---------------------------------------------------------------------------
// Localization
// ---------------------------------------------------------------------------

const Set<String> _kRtl = {'he', 'ar'};

String _langOf(BuildContext ctx) {
  try {
    final l = FFLocalizations.of(ctx).languageCode.trim().toLowerCase();
    return l.isEmpty ? 'en' : l;
  } catch (_) {
    return 'en';
  }
}

/// {n} number, {r} range label.
const Map<String, Map<String, String>> _kStrings = {
  "Last 7 days": {
    "en": "Last 7 days",
    "es": "Últimos 7 días",
    "he": "7 ימים אחרונים",
    "de": "Letzte 7 Tage",
    "fr": "7 derniers jours",
  },
  "Last 30 days": {
    "en": "Last 30 days",
    "es": "Últimos 30 días",
    "he": "30 ימים אחרונים",
    "de": "Letzte 30 Tage",
    "fr": "30 derniers jours",
  },
  "Last 90 days": {
    "en": "Last 90 days",
    "es": "Últimos 90 días",
    "he": "90 ימים אחרונים",
    "de": "Letzte 90 Tage",
    "fr": "90 derniers jours",
  },
  "All time": {
    "en": "All time",
    "es": "Todo el historial",
    "he": "כל הזמן",
    "de": "Gesamter Zeitraum",
    "fr": "Toute la période",
  },
  "selectRange": {
    "en": "Select Time Range",
    "es": "Elige el periodo",
    "he": "בחר טווח זמן",
    "de": "Zeitraum wählen",
    "fr": "Choisir la période",
  },
  "chooseMuscleGroup": {
    "en": "Choose Muscle group",
    "es": "Elige grupo muscular",
    "he": "בחר קבוצת שרירים",
    "de": "Muskelgruppe wählen",
    "fr": "Choisir un groupe musculaire",
  },
  "all": {
    "en": "All",
    "es": "Todos",
    "he": "הכל",
    "de": "Alle",
    "fr": "Tous",
  },
  "allMuscles": {
    "en": "All muscles",
    "es": "Todos los músculos",
    "he": "כל השרירים",
    "de": "Alle Muskeln",
    "fr": "Tous les muscles",
  },
  "searchWorkouts": {
    "en": "Search workouts",
    "es": "Buscar entrenamientos",
    "he": "חיפוש אימונים",
    "de": "Workouts suchen",
    "fr": "Rechercher des entraînements",
  },
  "searchMuscle": {
    "en": "Search Muscle",
    "es": "Buscar músculo",
    "he": "חיפוש שריר",
    "de": "Muskel suchen",
    "fr": "Rechercher un muscle",
  },
  "noMuscleGroups": {
    "en": "No muscle groups found",
    "es": "No se encontraron grupos musculares",
    "he": "לא נמצאו קבוצות שרירים",
    "de": "Keine Muskelgruppen gefunden",
    "fr": "Aucun groupe musculaire trouvé",
  },
  "noWorkoutsYet": {
    "en": "No workouts yet",
    "es": "Aún no hay entrenamientos",
    "he": "אין אימונים עדיין",
    "de": "Noch keine Workouts",
    "fr": "Aucun entraînement pour l'instant",
  },
  "finishToSee": {
    "en": "Finish a workout and it will show up here.",
    "es": "Termina un entrenamiento y aparecerá aquí.",
    "he": "סיים אימון והוא יופיע כאן.",
    "de": "Beende ein Workout und es erscheint hier.",
    "fr": "Terminez un entraînement et il apparaîtra ici.",
  },
  "noMatch": {
    "en": "No workouts match",
    "es": "Ningún entrenamiento coincide",
    "he": "אין אימונים תואמים",
    "de": "Keine passenden Workouts",
    "fr": "Aucun entraînement ne correspond",
  },
  "tryDifferent": {
    "en": "Try a different time range or muscle group.",
    "es": "Prueba otro periodo o grupo muscular.",
    "he": "נסה טווח זמן או קבוצת שרירים אחרת.",
    "de": "Versuche einen anderen Zeitraum oder eine andere Muskelgruppe.",
    "fr": "Essayez une autre période ou un autre groupe musculaire.",
  },
  "clearFilters": {
    "en": "Clear filters",
    "es": "Borrar filtros",
    "he": "נקה סינון",
    "de": "Filter zurücksetzen",
    "fr": "Effacer les filtres",
  },
  "noRecent": {
    "en": "No recent workouts",
    "es": "Sin entrenamientos recientes",
    "he": "אין אימונים אחרונים",
    "de": "Keine aktuellen Workouts",
    "fr": "Aucun entraînement récent",
  },
  "nothingIn": {
    "en": "Nothing logged in the {r}.",
    "es": "Nada registrado en {r}.",
    "he": "לא תועד כלום ב{r}.",
    "de": "Nichts eingetragen in {r}.",
    "fr": "Rien d'enregistré sur {r}.",
  },
  "range7": {
    "en": "last 7 days",
    "es": "los últimos 7 días",
    "he": "7 הימים האחרונים",
    "de": "den letzten 7 Tagen",
    "fr": "les 7 derniers jours",
  },
  "range30": {
    "en": "last 30 days",
    "es": "los últimos 30 días",
    "he": "30 הימים האחרונים",
    "de": "den letzten 30 Tagen",
    "fr": "les 30 derniers jours",
  },
  "range90": {
    "en": "last 90 days",
    "es": "los últimos 90 días",
    "he": "90 הימים האחרונים",
    "de": "den letzten 90 Tagen",
    "fr": "les 90 derniers jours",
  },
  "rangeAll": {
    "en": "all time",
    "es": "todo el historial",
    "he": "כל הזמן",
    "de": "gesamter Zeitraum",
    "fr": "toute la période",
  },
  "workout": {
    "en": "Workout",
    "es": "Entrenamiento",
    "he": "אימון",
    "de": "Workout",
    "fr": "Entraînement",
  },
  "today": {
    "en": "Today",
    "es": "Hoy",
    "he": "היום",
    "de": "Heute",
    "fr": "Aujourd'hui",
  },
  "yesterday": {
    "en": "Yesterday",
    "es": "Ayer",
    "he": "אתמול",
    "de": "Gestern",
    "fr": "Hier",
  },
  "setAnalyzed1": {
    "en": "1 set analyzed",
    "es": "1 serie analizada",
    "he": "סט 1 נותח",
    "de": "1 Satz analysiert",
    "fr": "1 série analysée",
  },
  "setsAnalyzedN": {
    "en": "{n} sets analyzed",
    "es": "{n} series analizadas",
    "he": "{n} סטים נותחו",
    "de": "{n} Sätze analysiert",
    "fr": "{n} séries analysées",
  },
  "workoutOptions": {
    "en": "Workout options",
    "es": "Opciones",
    "he": "אפשרויות",
    "de": "Optionen",
    "fr": "Options",
  },
  "sets": {
    "en": "Sets",
    "es": "Series",
    "he": "סטים",
    "de": "Sätze",
    "fr": "Séries",
  },
  "volume": {
    "en": "Volume",
    "es": "Volumen",
    "he": "נפח",
    "de": "Volumen",
    "fr": "Volume",
  },
  "time": {
    "en": "Time",
    "es": "Tiempo",
    "he": "זמן",
    "de": "Zeit",
    "fr": "Durée",
  },
  "sec": {
    "en": "sec",
    "es": "s",
    "he": "שנ׳",
    "de": "Sek.",
    "fr": "s",
  },
  "min": {
    "en": "min",
    "es": "min",
    "he": "דק׳",
    "de": "Min.",
    "fr": "min",
  },
  "hour": {
    "en": "h",
    "es": "h",
    "he": "שע׳",
    "de": "Std.",
    "fr": "h",
  },
  "viewSummary": {
    "en": "View full summary",
    "es": "Ver resumen completo",
    "he": "לסיכום המלא",
    "de": "Zusammenfassung ansehen",
    "fr": "Voir le résumé complet",
  },
  "tapToSelect": {
    "en": "Tap to select",
    "es": "Toca para seleccionar",
    "he": "הקש לבחירה",
    "de": "Zum Auswählen tippen",
    "fr": "Touchez pour sélectionner",
  },
  "selected": {
    "en": "Selected",
    "es": "Seleccionado",
    "he": "נבחר",
    "de": "Ausgewählt",
    "fr": "Sélectionné",
  },
  "compare": {
    "en": "Compare",
    "es": "Comparar",
    "he": "השווה",
    "de": "Vergleichen",
    "fr": "Comparer",
  },
};

String _tr(String lang, String key, {int? n, String? r}) {
  final m = _kStrings[key];
  var s = m == null ? key : (m[lang] ?? m['en'] ?? key);
  if (n != null) s = s.replaceAll('{n}', '$n');
  if (r != null) s = s.replaceAll('{r}', r);
  return s;
}

String _rangeLabel(String lang, String key) {
  switch (key.trim()) {
    case 'Last 7 days':
      return _tr(lang, 'range7');
    case 'Last 30 days':
      return _tr(lang, 'range30');
    case 'Last 90 days':
      return _tr(lang, 'range90');
    default:
      return _tr(lang, 'rangeAll');
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

TextStyle _hs(BuildContext ctx, double size, FontWeight w, Color c,
    {double ls = 0, double? height}) {
  final th = FlutterFlowTheme.of(ctx);
  final bool rtl = _kRtl.contains(_langOf(ctx));
  return th.bodyMedium.override(
    fontFamily: th.bodyMediumFamily,
    color: c,
    fontSize: size,
    fontWeight: w,
    letterSpacing: rtl && ls < 0 ? 0 : ls,
    lineHeight: height,
    useGoogleFonts: GoogleFonts.asMap().containsKey(th.bodyMediumFamily),
  );
}

bool _isDark(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark;

/// Darker teal for text on light surfaces; theme primary in dark mode.
Color _accent(BuildContext ctx) =>
    _isDark(ctx) ? FlutterFlowTheme.of(ctx).primary : const Color(0xFF0F766E);

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.round();
  return num.tryParse(v.toString())?.round() ?? 0;
}

DateTime? _parseDate(String raw) {
  if (raw.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(raw.trim());
  if (parsed == null) return null;
  return parsed.isUtc ? parsed.toLocal() : parsed;
}

/// Splits a GROUP_CONCAT'ed muscle list. Handles both plain names
/// ("Legs,Back") and JSON names ('{"en":"Legs",..},{"en":"Back",..}') —
/// commas inside braces are not separators.
List<String> _splitRaw(dynamic v) {
  final String s = (v ?? '').toString().trim();
  if (s.isEmpty) return const [];
  final List<String> out = [];
  final StringBuffer cur = StringBuffer();
  int depth = 0;
  for (int i = 0; i < s.length; i++) {
    final String c = s[i];
    if (c == '{') depth++;
    if (c == '}') depth--;
    if (c == ',' && depth <= 0) {
      final t = cur.toString().trim();
      if (t.isNotEmpty) out.add(t);
      cur.clear();
    } else {
      cur.write(c);
    }
  }
  final t = cur.toString().trim();
  if (t.isNotEmpty) out.add(t);
  return out;
}

/// Muscle names in English (stable filter / image key).
List<String> _musclesEn(dynamic v) =>
    _splitRaw(v).map((m) => localizedName(m, 'en')).toList();

/// Muscle names in the app language (display).
List<String> _musclesLoc(dynamic v, String lang) =>
    _splitRaw(v).map((m) => localizedName(m, lang)).toList();

class _MuscleOpt {
  const _MuscleOpt(this.en, this.label);
  final String en; // filter key
  final String label; // localized
}

// ---------------------------------------------------------------------------
// Page state
// ---------------------------------------------------------------------------

class _HistoryViewState extends State<HistoryView> {
  static const List<String> _periods = [
    'Last 7 days',
    'Last 30 days',
    'Last 90 days',
    'All time',
  ];
  // Same order as _periods. 0 = no limit.
  static const List<int> _periodDays = [7, 30, 90, 0];
  static const List<bool> _periodPremiumOnly = [false, false, true, true];

  static const String _allResult = '__all__';
  static const String _lockedResult = '__locked__';

  final TextEditingController _search = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String _q = '';
  late String _period;
  _MuscleOpt? _muscle; // null = all muscles
  bool _sheetOpen = false;
  static List<String>? _muscleRawCache; // raw DB names, loaded once per run

  // Compare mode: the one selected workout_log_id.
  String? _selectedId;

  bool get _premium => widget.isPremium ?? false;
  bool get _compare => widget.compareMode ?? false;
  String get _excludeId => (widget.excludeWorkoutLogId ?? '').trim();
  String get _defaultPeriod => _premium ? 'All time' : 'Last 30 days';
  String get _lang => _langOf(context);

  @override
  void initState() {
    super.initState();
    _period = _defaultPeriod;
    _load();
  }

  @override
  void didUpdateWidget(covariant HistoryView old) {
    super.didUpdateWidget(old);
    if (old.isPremium != widget.isPremium) {
      final bool oldPremium = old.isPremium ?? false;
      final String oldDefault = oldPremium ? 'All time' : 'Last 30 days';
      final int idx = _periods.indexOf(_period);
      final bool nowLocked = idx >= 0 && _periodPremiumOnly[idx] && !_premium;
      if (_period == oldDefault || nowLocked) _period = _defaultPeriod;
    }
    if (old.userId != widget.userId || old.reloadToken != widget.reloadToken) {
      _load();
    }
    if ((old.compareMode ?? false) != _compare) _selectedId = null;
    // The excluded workout can't stay selected.
    if (_selectedId != null && _selectedId == _excludeId) _selectedId = null;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static Map<String, dynamic> _rowMap(dynamic row) {
    try {
      final d = (row as dynamic).data;
      if (d is Map) return Map<String, dynamic>.from(d);
    } catch (_) {}
    if (row is Map) return Map<String, dynamic>.from(row);
    return const {};
  }

  // ---------- data ----------
  Future<void> _load() async {
    final List<Map<String, dynamic>> out = [];
    try {
      final rows = await SQLiteManager.instance.history(userId: widget.userId);
      for (final r in rows) {
        out.add(_rowMap(r));
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _rows = out;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> _filtered() {
    final int idx = _periods.indexOf(_period);
    final int days = idx >= 0 ? _periodDays[idx] : 0;
    final DateTime? cutoff =
        days > 0 ? DateTime.now().subtract(Duration(days: days)) : null;
    final String q = _q.toLowerCase();
    final String? muscleEn = _muscle?.en.toLowerCase();
    final String lang = _lang;
    final String exclude = _excludeId;

    return _rows.where((r) {
      if (exclude.isNotEmpty &&
          (r['workout_log_id'] ?? '').toString() == exclude) {
        return false;
      }
      if (cutoff != null) {
        final dt = _parseDate((r['created_at'] ?? '').toString());
        if (dt != null && dt.isBefore(cutoff)) return false;
      }
      final en = _musclesEn(r['main_muscle_groups'])
          .map((m) => m.toLowerCase())
          .toList();
      if (muscleEn != null && !en.contains(muscleEn)) return false;
      if (q.isNotEmpty) {
        final name = (r['workout_name'] ?? '').toString().toLowerCase();
        final loc = _musclesLoc(r['main_muscle_groups'], lang)
            .map((m) => m.toLowerCase());
        final bool hit = name.contains(q) ||
            en.any((m) => m.contains(q)) ||
            loc.any((m) => m.contains(q));
        if (!hit) return false;
      }
      return true;
    }).toList();
  }

  void _clearFilters() {
    _search.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _q = '';
      _period = _defaultPeriod;
      _muscle = null;
    });
  }

  // ---------- sheets ----------
  Future<List<String>> _loadMuscleRaw() async {
    if (_muscleRawCache != null) return _muscleRawCache!;
    final List<String> out = [];
    try {
      final rows = await SQLiteManager.instance.database.rawQuery(
        'SELECT name FROM primary_muscle_group '
        'WHERE name IS NOT NULL AND TRIM(name) <> \'\' '
        'ORDER BY id ASC',
      );
      for (final r in rows) {
        final n = r['name']?.toString().trim();
        if (n != null && n.isNotEmpty) out.add(n);
      }
    } catch (_) {}
    _muscleRawCache = out;
    return out;
  }

  Future<void> _openMuscleSheet() async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    FocusScope.of(context).unfocus();
    final String lang = _lang;
    final List<String> raw = await _loadMuscleRaw();
    if (!mounted) {
      _sheetOpen = false;
      return;
    }
    final List<_MuscleOpt> opts = [
      for (final r in raw)
        _MuscleOpt(localizedName(r, 'en'), localizedName(r, lang)),
    ]..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));

    final String? picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection:
            _kRtl.contains(lang) ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: _MuscleSheet(
          lang: lang,
          options: opts,
          selectedEn: _muscle?.en,
          allResult: _allResult,
        ),
      ),
    );
    _sheetOpen = false;
    if (picked == null || !mounted) return; // dismissed
    setState(() {
      if (picked == _allResult) {
        _muscle = null;
      } else {
        _muscle = opts.firstWhere((o) => o.en == picked,
            orElse: () => _MuscleOpt(picked, picked));
      }
    });
  }

  Future<void> _openPeriodSheet() async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    FocusScope.of(context).unfocus();
    final String lang = _lang;
    final String? picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection:
            _kRtl.contains(lang) ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: _PeriodSheet(
          lang: lang,
          periods: _periods,
          premiumOnly: _periodPremiumOnly,
          isPremium: _premium,
          selected: _period,
          lockedResult: _lockedResult,
        ),
      ),
    );
    _sheetOpen = false;
    if (picked == null) return; // dismissed
    if (picked == _lockedResult) {
      await widget.onLockedTap?.call();
      return;
    }
    if (mounted) setState(() => _period = picked);
  }

  // ---------- card actions ----------
  Future<void> _tapWorkout(String id) async {
    FocusScope.of(context).unfocus();
    if (_compare) {
      // Single selection; tapping the selected card deselects it.
      setState(() => _selectedId = _selectedId == id ? null : id);
      return;
    }
    await widget.onWorkoutTap?.call(id);
    if (mounted) _load();
  }

  Future<void> _tapMenu(String id) async {
    FocusScope.of(context).unfocus();
    await widget.onMenuTap?.call(id);
    if (mounted) _load();
  }

  Future<void> _tapCompare() async {
    final String? id = _selectedId;
    if (id == null) return;
    FocusScope.of(context).unfocus();
    await widget.onCompare?.call(id);
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final String lang = _lang;
    final bool rtl = _kRtl.contains(lang);
    final List<Map<String, dynamic>> filtered =
        _loading ? const [] : _filtered();
    final bool hasActiveFilters =
        _q.isNotEmpty || _muscle != null || _period != _defaultPeriod;

    Widget body;
    if (_loading) {
      body = Center(child: CircularProgressIndicator(color: th.primary));
    } else if (_rows.isEmpty) {
      body = _EmptyState(
        icon: Icons.fitness_center_rounded,
        title: _tr(lang, 'noWorkoutsYet'),
        subtitle: _tr(lang, 'finishToSee'),
      );
    } else if (filtered.isEmpty && hasActiveFilters) {
      body = _EmptyState(
        icon: Icons.filter_alt_outlined,
        title: _tr(lang, 'noMatch'),
        subtitle: _tr(lang, 'tryDifferent'),
        buttonLabel: _tr(lang, 'clearFilters'),
        onButtonTap: _clearFilters,
      );
    } else if (filtered.isEmpty) {
      body = _EmptyState(
        icon: Icons.calendar_today_outlined,
        title: _tr(lang, 'noRecent'),
        subtitle: _tr(lang, 'nothingIn', r: _rangeLabel(lang, _period)),
      );
    } else {
      body = RefreshIndicator(
        color: th.primary,
        onRefresh: _load,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final String id = (filtered[i]['workout_log_id'] ?? '').toString();
            return _WorkoutCard(
              key: ValueKey(id),
              data: filtered[i],
              lang: lang,
              selectable: _compare,
              selected: _compare && id == _selectedId,
              onTap: () => _tapWorkout(id),
              onMenuTap: () => _tapMenu(id),
            );
          },
        ),
      );
    }

    // Compare CTA floats over the list; the list's bottom padding (120)
    // already keeps the last card clear of it.
    if (_compare) {
      body = Stack(
        children: [
          Positioned.fill(child: body),
          PositionedDirectional(
            start: 16,
            end: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            child: _CompareButton(
              label: _tr(lang, 'compare'),
              enabled: _selectedId != null,
              onTap: _tapCompare,
            ),
          ),
        ],
      );
    }

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Container(
          color: th.primaryBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _searchField(context),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: SizedBox(
                  height: 44,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Flexible(
                        child: _FilterPill(
                          icon: Icons.calendar_today_outlined,
                          label: _tr(lang, _period),
                          active: _period != _defaultPeriod,
                          onTap: _openPeriodSheet,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _FilterPill(
                          icon: Icons.fitness_center_rounded,
                          label: _muscle?.label ?? _tr(lang, 'allMuscles'),
                          active: _muscle != null,
                          onTap: _openMuscleSheet,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField(BuildContext ctx) {
    final th = FlutterFlowTheme.of(ctx);
    final bool dark = _isDark(ctx);
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: th.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: dark ? Border.all(color: th.alternate) : null,
        boxShadow: dark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A101828),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: th.secondaryText),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _q = v.trim()),
              textInputAction: TextInputAction.search,
              cursorColor: th.primary,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: _tr(_lang, 'searchWorkouts'),
                hintStyle: _hs(ctx, 15, FontWeight.w400, th.secondaryText),
              ),
              style: _hs(ctx, 15, FontWeight.w400, th.primaryText),
            ),
          ),
          if (_q.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _search.clear();
                setState(() => _q = '');
              },
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 8, top: 8, bottom: 8),
                child: Icon(Icons.close_rounded,
                    size: 18, color: th.secondaryText),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Workout card
// ---------------------------------------------------------------------------

class _WorkoutCard extends StatefulWidget {
  const _WorkoutCard({
    super.key,
    required this.data,
    required this.lang,
    required this.onTap,
    required this.onMenuTap,
    this.selectable = false,
    this.selected = false,
  });

  final Map<String, dynamic> data;
  final String lang;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  /// Compare mode: no options button, footer shows the selection hint.
  final bool selectable;
  final bool selected;

  @override
  State<_WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<_WorkoutCard> {
  bool _down = false;
  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  String _formatDate(String raw) {
    final lang = widget.lang;
    final dt = _parseDate(raw);
    if (dt == null) return raw.trim();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final int diff = today.difference(day).inDays;
    final String time = '${_two(dt.hour)}:${_two(dt.minute)}';
    if (diff == 0) return '${_tr(lang, 'today')} · $time';
    if (diff == 1) return '${_tr(lang, 'yesterday')} · $time';
    String base;
    try {
      base = dt.year != now.year
          ? intl.DateFormat('EEE, MMM d, y', lang).format(dt)
          : intl.DateFormat('EEE, MMM d', lang).format(dt);
    } catch (_) {
      base = dt.year != now.year
          ? intl.DateFormat('EEE, MMM d, y').format(dt)
          : intl.DateFormat('EEE, MMM d').format(dt);
    }
    return '$base · $time';
  }

  static String _formatThousands(int n) {
    final String s = n.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return n < 0 ? '-$buf' : buf.toString();
  }

  // The history query's duration_seconds column is stored in MILLISECONDS
  // (same as WorkoutSummaryView reads it). Returns [value, unit].
  List<String> _formatDuration(int ms) {
    final lang = widget.lang;
    final int seconds = (ms / 1000).round();
    if (seconds < 60) return ['$seconds', _tr(lang, 'sec')];
    final int minutes = (seconds / 60).round();
    if (minutes < 60) return ['$minutes', _tr(lang, 'min')];
    return ['${minutes ~/ 60}:${_two(minutes % 60)}', _tr(lang, 'hour')];
  }

  Widget _statTile(BuildContext ctx, IconData icon, String label, String value,
      [String? unit]) {
    final th = FlutterFlowTheme.of(ctx);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: th.primaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: th.secondaryText),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _hs(ctx, 12, FontWeight.w500, th.secondaryText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: _hs(ctx, 18, FontWeight.w700, th.primaryText),
                  ),
                  if (unit != null && unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: _hs(ctx, 12, FontWeight.w500, th.secondaryText),
                    ),
                ],
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final bool dark = _isDark(context);
    final Color accent = _accent(context);
    final String lang = widget.lang;
    final bool rtl = _kRtl.contains(lang);
    final Map<String, dynamic> d = widget.data;
    final bool selectable = widget.selectable;
    final bool selected = widget.selected;

    final String rawName = (d['workout_name'] ?? '').toString().trim();
    final String name = rawName.isEmpty ? _tr(lang, 'workout') : rawName;
    final String dateLabel = _formatDate((d['created_at'] ?? '').toString());
    final int totalSets = _toInt(d['total_sets']);
    final int volume = _toInt(d['volume']);
    final List<String> duration =
        _formatDuration(_toInt(d['duration_seconds']));
    final int analyzedSets = _toInt(d['analyzed_sets']);
    final List<String> muscles = _musclesLoc(d['main_muscle_groups'], lang);

    final Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: selected
            ? Color.alphaBlend(th.primary.withOpacity(dark ? 0.22 : 0.16),
                th.secondaryBackground)
            : th.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
        border: selected
            ? Border.all(color: accent, width: 2)
            : (dark ? Border.all(color: th.alternate) : null),
        boxShadow: dark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A101828),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
                BoxShadow(
                  color: Color(0x0F101828),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: name + AI badge + date, options button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _hs(
                                context, 20, FontWeight.w700, th.primaryText,
                                ls: -0.2),
                          ),
                        ),
                        if (analyzedSets > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                6, 3, 8, 3),
                            decoration: BoxDecoration(
                              color: th.primary.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome_rounded,
                                    size: 12, color: accent),
                                const SizedBox(width: 4),
                                Text(
                                  analyzedSets == 1
                                      ? _tr(lang, 'setAnalyzed1')
                                      : _tr(lang, 'setsAnalyzedN',
                                          n: analyzedSets),
                                  style:
                                      _hs(context, 12, FontWeight.w600, accent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (dateLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        dateLabel,
                        style:
                            _hs(context, 13, FontWeight.w400, th.secondaryText),
                      ),
                    ],
                  ],
                ),
              ),
              if (!selectable)
                Transform.translate(
                  offset: Offset(rtl ? -12 : 12, -10),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: _tr(lang, 'workoutOptions'),
                      icon: Icon(Icons.more_vert_rounded,
                          size: 20, color: th.secondaryText),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        widget.onMenuTap();
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Stats
          Row(
            children: [
              Expanded(
                child: _statTile(context, Icons.layers_outlined,
                    _tr(lang, 'sets'), '$totalSets'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statTile(context, Icons.fitness_center_rounded,
                    _tr(lang, 'volume'), _formatThousands(volume), 'kg'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statTile(context, Icons.schedule_rounded,
                    _tr(lang, 'time'), duration[0], duration[1]),
              ),
            ],
          ),

          // Muscle chips
          if (muscles.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final m in muscles)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: th.primaryBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      m,
                      style: _hs(context, 12, FontWeight.w500, th.primaryText),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          // Footer hint
          Container(
            height: 46,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: th.alternate)),
            ),
            child: selectable
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selected
                            ? _tr(lang, 'selected')
                            : _tr(lang, 'tapToSelect'),
                        style: _hs(context, 14, FontWeight.w600,
                            selected ? accent : th.secondaryText),
                      ),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 22,
                        color: selected ? accent : th.secondaryText,
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _tr(lang, 'viewSummary'),
                        style: _hs(context, 14, FontWeight.w600, accent),
                      ),
                      Icon(
                          rtl
                              ? Icons.chevron_left_rounded
                              : Icons.chevron_right_rounded,
                          size: 20,
                          color: accent),
                    ],
                  ),
          ),
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: card,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compare CTA (compare mode only)
// ---------------------------------------------------------------------------

class _CompareButton extends StatefulWidget {
  const _CompareButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_CompareButton> createState() => _CompareButtonState();
}

class _CompareButtonState extends State<_CompareButton> {
  bool _down = false;
  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    return IgnorePointer(
      ignoring: !widget.enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) {
          _set(false);
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: AnimatedOpacity(
            opacity: widget.enabled ? (_down ? 0.85 : 1.0) : 0.45,
            duration: const Duration(milliseconds: 160),
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: th.primary,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F101828),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                widget.label,
                style: _hs(context, 17, FontWeight.w700, Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButtonTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: th.alternate,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: th.secondaryText),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: _hs(context, 18, FontWeight.w700, th.primaryText),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: _hs(context, 14, FontWeight.w400, th.secondaryText,
                  height: 1.4),
            ),
            if (buttonLabel != null) ...[
              const SizedBox(height: 20),
              _PillButton(label: buttonLabel!, onTap: onButtonTap),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Solid pill button with press feedback
// ---------------------------------------------------------------------------

class _PillButton extends StatefulWidget {
  const _PillButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
  bool _down = false;
  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) {
        _set(false);
        HapticFeedback.selectionClick();
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: AnimatedOpacity(
          opacity: _down ? 0.7 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: _hs(context, 14, FontWeight.w600, Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter pill (icon + label + chevron, press feedback, active tint)
// ---------------------------------------------------------------------------

class _FilterPill extends StatefulWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_FilterPill> createState() => _FilterPillState();
}

class _FilterPillState extends State<_FilterPill> {
  bool _down = false;
  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final bool dark = _isDark(context);
    final Color accent = _accent(context);
    final Color fg = widget.active ? accent : th.primaryText;
    final Color iconColor = widget.active ? accent : th.secondaryText;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) {
        _set(false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: AnimatedOpacity(
          opacity: _down ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: widget.active
                  ? th.primary.withOpacity(0.18)
                  : th.secondaryBackground,
              borderRadius: BorderRadius.circular(999),
              border: (!widget.active && dark)
                  ? Border.all(color: th.alternate)
                  : null,
              boxShadow: (widget.active || dark)
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x0A101828),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _hs(
                      context,
                      14,
                      widget.active ? FontWeight.w600 : FontWeight.w500,
                      fg,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: iconColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Period bottom sheet
// ---------------------------------------------------------------------------

class _PeriodSheet extends StatelessWidget {
  const _PeriodSheet({
    required this.lang,
    required this.periods,
    required this.premiumOnly,
    required this.isPremium,
    required this.selected,
    required this.lockedResult,
  });

  final String lang;
  final List<String> periods;
  final List<bool> premiumOnly;
  final bool isPremium;
  final String selected;
  final String lockedResult;

  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final Color accent = _accent(context);
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: th.secondaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: th.alternate,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            _tr(lang, 'selectRange'),
            style: _hs(context, 20, FontWeight.w600, th.primaryText),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < periods.length; i++) ...[
            _row(context, th, accent, i),
            if (i < periods.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(height: 1, color: th.alternate),
              ),
          ],
          SizedBox(height: 8 + bottomInset),
        ],
      ),
    );
  }

  Widget _row(
      BuildContext context, FlutterFlowTheme th, Color accent, int index) {
    final String key = periods[index];
    final bool locked = premiumOnly[index] && !isPremium;
    final bool isSelected = !locked && key == selected;
    final Color fg =
        locked ? th.secondaryText : (isSelected ? accent : th.primaryText);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop(locked ? lockedResult : key);
      },
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _tr(lang, key),
              style: _hs(context, 17,
                  isSelected ? FontWeight.w600 : FontWeight.w500, fg),
            ),
            if (locked) ...[
              const SizedBox(width: 8),
              Icon(Icons.lock_outline_rounded, size: 18, color: fg),
            ],
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_rounded, size: 20, color: accent),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Muscle bottom sheet
// ---------------------------------------------------------------------------

class _MuscleSheet extends StatefulWidget {
  const _MuscleSheet({
    required this.lang,
    required this.options,
    required this.selectedEn,
    required this.allResult,
  });

  final String lang;
  final List<_MuscleOpt> options;
  final String? selectedEn; // null = All
  final String allResult;

  @override
  State<_MuscleSheet> createState() => _MuscleSheetState();
}

class _MuscleSheetState extends State<_MuscleSheet> {
  final TextEditingController _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final String lang = widget.lang;
    final double maxH = MediaQuery.of(context).size.height * 0.85;
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final String q = _q.toLowerCase();
    final List<_MuscleOpt> filtered = q.isEmpty
        ? widget.options
        : widget.options
            .where((m) =>
                m.label.toLowerCase().contains(q) ||
                m.en.toLowerCase().contains(q))
            .toList();
    final String allLabel = _tr(lang, 'all');
    final bool showAll = q.isEmpty || allLabel.toLowerCase().contains(q);

    final TextStyle rowStyle =
        _hs(context, 18, FontWeight.w500, th.primaryText);

    Widget row({
      required Widget leading,
      required String text,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              SizedBox(width: 70, height: 70, child: Center(child: leading)),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: rowStyle)),
              if (selected)
                Icon(Icons.check_rounded, size: 26, color: th.primary),
            ],
          ),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: th.secondaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: th.alternate,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _tr(lang, 'chooseMuscleGroup'),
            style: _hs(context, 26, FontWeight.w600, th.primaryText),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: th.secondaryBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: th.alternate),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 22, color: th.secondaryText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged: (v) => setState(() => _q = v.trim()),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: _tr(lang, 'searchMuscle'),
                        hintStyle:
                            _hs(context, 16, FontWeight.w400, th.secondaryText),
                      ),
                      style: _hs(context, 16, FontWeight.w400, th.primaryText),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.only(bottom: 12 + bottomInset),
              children: [
                if (showAll) ...[
                  row(
                    leading: Icon(Icons.grid_view_rounded,
                        size: 30, color: th.primaryText),
                    text: allLabel,
                    selected: widget.selectedEn == null,
                    onTap: () => Navigator.of(context).pop(widget.allResult),
                  ),
                  Divider(height: 1, color: th.alternate),
                ],
                for (int i = 0; i < filtered.length; i++) ...[
                  row(
                    leading: ExerciseAssetImage(
                      width: 70,
                      height: 70,
                      // Images are keyed by the English name.
                      exerciseName: exerciseImageName(filtered[i].en),
                      borderRadius: 8,
                    ),
                    text: filtered[i].label,
                    selected: widget.selectedEn == filtered[i].en,
                    onTap: () => Navigator.of(context).pop(filtered[i].en),
                  ),
                  if (i < filtered.length - 1)
                    Divider(height: 1, color: th.alternate),
                ],
                if (!showAll && filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        _tr(lang, 'noMuscleGroups'),
                        style:
                            _hs(context, 14, FontWeight.w400, th.secondaryText),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
