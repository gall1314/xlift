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

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl show DateFormat;
import '/flutter_flow/internationalization.dart' show FFLocalizations;

/// Self-managed Home screen content (nav bar / FAB live on the page).
///
/// Runs its own SQLite queries, holds its own state, exposes navigation as
/// callbacks. Fonts and colors come from FlutterFlowTheme so the page matches
/// the rest of the app.
///
/// Localization: the app language is read from FFLocalizations (the same
/// value the app uses everywhere) and drives all UI strings (see _kStrings),
/// muscle / exercise names (via localizedName), dates (intl) and text
/// direction (RTL for 'he'). Supported: 'en','es','he','de','fr'; anything
/// else falls back to English.
///
/// Parameters:
///   userId             - current user id (auth)
///   isPremium          - true hides the form-check quota meter
///   analysisCount      - FFAppState().analysisCount
///   analysisCountMonth - FFAppState().analysisCountMonth ("YYYY-MM")
///   onStartWorkout     - (workoutId) start a saved workout
///   onOpenSummary      - (workoutLogId) open workout summary
///   onOpenLastAnalysis - (GetSetAnalysisRow) show the last analysis; the
///                        camera itself is the page's FAB
///   onOpenStats, onOpenLibrary, onOpenSettings
///   onOpenTemplates    - Library on the Templates tab (initialTab = 1)
///   onCreateWorkout    - open the existing create bottom sheet
class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    this.width,
    this.height,
    required this.userId,
    this.isPremium,
    this.analysisCount,
    this.analysisCountMonth,
    this.onStartWorkout,
    this.onOpenSummary,
    this.onOpenLastAnalysis,
    this.onOpenStats,
    this.onOpenLibrary,
    this.onOpenSettings,
    this.onOpenTemplates,
    this.onCreateWorkout,
  });

  final double? width;
  final double? height;
  final String userId;
  final bool? isPremium;
  final int? analysisCount;
  final String? analysisCountMonth;
  final Future Function(String workoutId)? onStartWorkout;
  final Future Function(String workoutLogId)? onOpenSummary;
  final Future Function(GetSetAnalysisRow analysis)? onOpenLastAnalysis;
  final Future Function()? onOpenStats;
  final Future Function()? onOpenLibrary;
  final Future Function()? onOpenSettings;
  final Future Function()? onOpenTemplates;
  final Future Function()? onCreateWorkout;

  @override
  State<HomeView> createState() => _HomeViewState();
}

// Free-tier form-check quota (mirrors canStartQuickAnalysis).
const int _kFreeMonthlyLimit = 5;

// Space reserved at the bottom for the page's nav bar + FAB overhang.
const double _kBottomInset = 220;

// Horizontal page gutter.
const double _kGutter = 20;

// Minutes per working set, incl. rest and transitions.
const double _kMinPerSet = 3.5;

// App-wide container radius.
const double _kRadius = 16;
const double _kRadiusInner = 12;

// The one intentional dark surface (hero card), fixed in both themes.
const _kDark = Color(0xFF0F1D1B);
const _kOnDark = Color(0xFFF2F4F3);
const _kOnDarkMuted = Color(0xFF9AAAA6);
const _kOnDarkPill = Color(0xFFD7E0DE);

const _kTabular = [FontFeature.tabularFigures()];

// Languages written right-to-left.
const Set<String> _kRtl = {'he', 'ar'};

// ---------------------------------------------------------------------------
// UI strings. {n} / {m} / {d} are placeholders. English is the fallback.
// ---------------------------------------------------------------------------
const Map<String, Map<String, String>> _kStrings = {
  "goodNight": {
    "en": "Good night",
    "es": "Buenas noches",
    "he": "לילה טוב",
    "de": "Gute Nacht",
    "fr": "Bonne nuit",
  },
  "goodMorning": {
    "en": "Good morning",
    "es": "Buenos días",
    "he": "בוקר טוב",
    "de": "Guten Morgen",
    "fr": "Bonjour",
  },
  "goodAfternoon": {
    "en": "Good afternoon",
    "es": "Buenas tardes",
    "he": "צהריים טובים",
    "de": "Guten Tag",
    "fr": "Bon après-midi",
  },
  "goodEvening": {
    "en": "Good evening",
    "es": "Buenas noches",
    "he": "ערב טוב",
    "de": "Guten Abend",
    "fr": "Bonsoir",
  },
  "startHere": {
    "en": "START HERE",
    "es": "EMPIEZA AQUÍ",
    "he": "מתחילים כאן",
    "de": "HIER STARTEN",
    "fr": "COMMENCEZ ICI",
  },
  "buildFirst": {
    "en": "Build your first\nworkout",
    "es": "Crea tu primer\nentrenamiento",
    "he": "בנה את האימון\nהראשון שלך",
    "de": "Erstelle dein erstes\nWorkout",
    "fr": "Créez votre premier\nentraînement",
  },
  "buildFirstSub": {
    "en":
        "Pick exercises yourself, let the AI build one, or start from a ready-made template.",
    "es":
        "Elige los ejercicios tú mismo, deja que la IA lo cree o empieza desde una plantilla.",
    "he": "בחר תרגילים בעצמך, תן ל-AI לבנות אימון, או התחל מתבנית מוכנה.",
    "de":
        "Wähle Übungen selbst, lass die KI eines erstellen oder starte mit einer Vorlage.",
    "fr":
        "Choisissez vos exercices, laissez l'IA en créer un ou partez d'un modèle.",
  },
  "createWorkout": {
    "en": "Create workout",
    "es": "Crear entrenamiento",
    "he": "צור אימון",
    "de": "Workout erstellen",
    "fr": "Créer un entraînement",
  },
  "upNext": {
    "en": "UP NEXT",
    "es": "SIGUIENTE",
    "he": "הבא בתור",
    "de": "ALS NÄCHSTES",
    "fr": "À SUIVRE",
  },
  "recovered": {
    "en": "Recovered",
    "es": "Recuperado",
    "he": "התאוששת",
    "de": "Erholt",
    "fr": "Récupéré",
  },
  "exercisesCount": {
    "en": "{n} exercises",
    "es": "{n} ejercicios",
    "he": "{n} תרגילים",
    "de": "{n} Übungen",
    "fr": "{n} exercices",
  },
  "minutes": {
    "en": "~{n} min",
    "es": "~{n} min",
    "he": "~{n} דק׳",
    "de": "~{n} Min.",
    "fr": "~{n} min",
  },
  "withFormCheck": {
    "en": "{n} with form check",
    "es": "{n} con análisis de técnica",
    "he": "{n} עם ניתוח טכניקה",
    "de": "{n} mit Technik-Check",
    "fr": "{n} avec analyse de technique",
  },
  "startWorkout": {
    "en": "Start workout",
    "es": "Empezar entrenamiento",
    "he": "התחל אימון",
    "de": "Workout starten",
    "fr": "Démarrer l'entraînement",
  },
  "formCheck": {
    "en": "Form check",
    "es": "Análisis de técnica",
    "he": "ניתוח טכניקה",
    "de": "Technik-Check",
    "fr": "Analyse de technique",
  },
  "unlimitedFilm": {
    "en": "Unlimited · film a set with the camera below",
    "es": "Ilimitado · graba una serie con la cámara de abajo",
    "he": "ללא הגבלה · צלם סט עם המצלמה למטה",
    "de": "Unbegrenzt · filme einen Satz mit der Kamera unten",
    "fr": "Illimité · filmez une série avec la caméra ci-dessous",
  },
  "leftFilm": {
    "en": "{n} of {m} free this month · film a set below",
    "es": "{n} de {m} gratis este mes · graba una serie abajo",
    "he": "{n} מתוך {m} חינם החודש · צלם סט למטה",
    "de": "{n} von {m} gratis diesen Monat · filme einen Satz unten",
    "fr": "{n} sur {m} gratuits ce mois-ci · filmez une série ci-dessous",
  },
  "unlimitedReview": {
    "en": "Unlimited · tap to review",
    "es": "Ilimitado · toca para revisar",
    "he": "ללא הגבלה · הקש לצפייה",
    "de": "Unbegrenzt · zum Ansehen tippen",
    "fr": "Illimité · touchez pour revoir",
  },
  "leftChecks": {
    "en": "{n} of {m} free checks left this month",
    "es": "Te quedan {n} de {m} análisis gratis este mes",
    "he": "נותרו {n} מתוך {m} ניתוחים חינם החודש",
    "de": "{n} von {m} Gratis-Checks diesen Monat übrig",
    "fr": "{n} analyses gratuites sur {m} restantes ce mois-ci",
  },
  "thisWeek": {
    "en": "This week",
    "es": "Esta semana",
    "he": "השבוע",
    "de": "Diese Woche",
    "fr": "Cette semaine",
  },
  "fullStats": {
    "en": "Full stats",
    "es": "Estadísticas",
    "he": "כל הנתונים",
    "de": "Alle Statistiken",
    "fr": "Statistiques",
  },
  "workouts": {
    "en": "workouts",
    "es": "entrenamientos",
    "he": "אימונים",
    "de": "Workouts",
    "fr": "séances",
  },
  "sets": {
    "en": "sets",
    "es": "series",
    "he": "סטים",
    "de": "Sätze",
    "fr": "séries",
  },
  "kgVolume": {
    "en": "kg volume",
    "es": "kg volumen",
    "he": 'ק"ג נפח',
    "de": "kg Volumen",
    "fr": "kg volume",
  },
  "lastWorkout": {
    "en": "LAST WORKOUT",
    "es": "ÚLTIMO ENTRENAMIENTO",
    "he": "אימון אחרון",
    "de": "LETZTES WORKOUT",
    "fr": "DERNIER ENTRAÎNEMENT",
  },
  "workout": {
    "en": "Workout",
    "es": "Entrenamiento",
    "he": "אימון",
    "de": "Workout",
    "fr": "Entraînement",
  },
  "setsCount": {
    "en": "{n} sets",
    "es": "{n} series",
    "he": "{n} סטים",
    "de": "{n} Sätze",
    "fr": "{n} séries",
  },
  "prs": {
    "en": "{n} PR",
    "es": "{n} RP",
    "he": "{n} שיא",
    "de": "{n} PR",
    "fr": "{n} RP",
  },
  "prsPlural": {
    "en": "{n} PRs",
    "es": "{n} RPs",
    "he": "{n} שיאים",
    "de": "{n} PRs",
    "fr": "{n} RPs",
  },
  "myWorkouts": {
    "en": "My workouts",
    "es": "Mis entrenamientos",
    "he": "האימונים שלי",
    "de": "Meine Workouts",
    "fr": "Mes entraînements",
  },
  "seeAll": {
    "en": "See all {n}",
    "es": "Ver los {n}",
    "he": "הצג את כל ה-{n}",
    "de": "Alle {n} ansehen",
    "fr": "Voir les {n}",
  },
  "startFromTemplate": {
    "en": "Start from a template",
    "es": "Empieza desde una plantilla",
    "he": "התחל מתבנית",
    "de": "Mit einer Vorlage starten",
    "fr": "Partir d'un modèle",
  },
  "templateSub": {
    "en": "Ready-made workouts you can save and start right away.",
    "es": "Entrenamientos listos que puedes guardar y empezar ya.",
    "he": "אימונים מוכנים שאפשר לשמור ולהתחיל מיד.",
    "de": "Fertige Workouts zum Speichern und sofort Loslegen.",
    "fr": "Des entraînements prêts à enregistrer et à démarrer.",
  },
  "start": {
    "en": "Start",
    "es": "Empezar",
    "he": "התחל",
    "de": "Start",
    "fr": "Démarrer",
  },
  "neverDone": {
    "en": "never done",
    "es": "nunca realizado",
    "he": "לא בוצע",
    "de": "nie gemacht",
    "fr": "jamais fait",
  },
  "neverDoneCap": {
    "en": "Never done",
    "es": "Nunca realizado",
    "he": "לא בוצע",
    "de": "Nie gemacht",
    "fr": "Jamais fait",
  },
  "doneAgo": {
    "en": "Done {d}",
    "es": "Hecho {d}",
    "he": "בוצע {d}",
    "de": "Gemacht {d}",
    "fr": "Fait {d}",
  },
  "justNow": {
    "en": "just now",
    "es": "ahora mismo",
    "he": "עכשיו",
    "de": "gerade eben",
    "fr": "à l'instant",
  },
  "hoursAgo": {
    "en": "{n}h ago",
    "es": "hace {n} h",
    "he": "לפני {n} שע׳",
    "de": "vor {n} Std.",
    "fr": "il y a {n} h",
  },
  "yesterday": {
    "en": "yesterday",
    "es": "ayer",
    "he": "אתמול",
    "de": "gestern",
    "fr": "hier",
  },
  "daysAgo": {
    "en": "{n}d ago",
    "es": "hace {n} días",
    "he": "לפני {n} ימים",
    "de": "vor {n} Tagen",
    "fr": "il y a {n} j",
  },
  "lastDay": {
    "en": "last {d}",
    "es": "el {d} pasado",
    "he": "ביום {d} שעבר",
    "de": "letzten {d}",
    "fr": "{d} dernier",
  },
  "weeksAgo": {
    "en": "{n}w ago",
    "es": "hace {n} sem.",
    "he": "לפני {n} שבועות",
    "de": "vor {n} Wo.",
    "fr": "il y a {n} sem.",
  },
  "today": {
    "en": "Today",
    "es": "Hoy",
    "he": "היום",
    "de": "Heute",
    "fr": "Aujourd'hui",
  },
  "yesterdayCap": {
    "en": "Yesterday",
    "es": "Ayer",
    "he": "אתמול",
    "de": "Gestern",
    "fr": "Hier",
  },
  "failedToLoad": {
    "en": "Home failed to load",
    "es": "No se pudo cargar la pantalla de inicio",
    "he": "טעינת מסך הבית נכשלה",
    "de": "Startseite konnte nicht geladen werden",
    "fr": "Échec du chargement de l'accueil",
  },
};

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------
class _WorkoutRow {
  _WorkoutRow({
    required this.id,
    required this.name,
    required this.exerciseCount,
    required this.lastDoneAt,
    required this.muscles,
    required this.formCheckCount,
    required this.estMinutes,
  });
  final String id;
  final String name;
  final int exerciseCount;
  final DateTime? lastDoneAt;
  final List<String> muscles;
  final int formCheckCount;
  final int estMinutes;

  bool get isRested =>
      lastDoneAt == null ||
      DateTime.now().difference(lastDoneAt!) >= const Duration(hours: 48);
}

class _LastWorkout {
  _LastWorkout({
    required this.logId,
    required this.workoutId,
    required this.name,
    required this.at,
    required this.durationSec,
    required this.volume,
    required this.sets,
    required this.muscles,
    required this.prCount,
  });
  final String logId;
  final String workoutId;
  final String name;
  final DateTime at;
  final int durationSec;
  final double volume;
  final int sets;
  final List<String> muscles;
  final int prCount;
}

class _WeekStats {
  _WeekStats({
    required this.workouts,
    required this.sets,
    required this.volume,
    required this.perDay,
  });
  final int workouts;
  final int sets;
  final double volume;
  final List<int> perDay; // Sun..Sat
}

class _LastScore {
  _LastScore({
    required this.setLogId,
    required this.score,
    required this.exerciseName,
    required this.at,
  });
  final String setLogId;
  final double score;
  final String exerciseName; // localized
  final DateTime at;
}

class _HomeData {
  _HomeData({
    required this.workouts,
    required this.lastWorkout,
    required this.week,
    required this.lastScore,
  });
  final List<_WorkoutRow> workouts;
  final _LastWorkout? lastWorkout;
  final _WeekStats week;
  final _LastScore? lastScore;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class _HomeViewState extends State<HomeView> {
  _HomeData? _data;
  String? _error;
  int _heroOffset = 0;

  // App language ('en','es','he','de','fr'), resolved from FFLocalizations in
  // didChangeDependencies (inherited widgets aren't available in initState).
  String _lang = 'en';
  bool _langResolved = false;

  // Palette, resolved from FlutterFlowTheme in didChangeDependencies.
  Color _bg = const Color(0xFFF2F4F3);
  Color _card = const Color(0xFFFFFFFF);
  Color _cardSub = const Color(0xFFEEF1F0);
  Color _line = const Color(0xFFE2E7E5);
  Color _ink = const Color(0xFF0F1D1B);
  Color _inkMuted = const Color(0xFF5B6966);
  Color _inkFaint = const Color(0xFF9AAAA6);
  Color _accent = const Color(0xFF13B094);
  Color _accentDeep = const Color(0xFF0B7D6B);
  Color _accentOnDark = const Color(0xFF3FD2B6);
  Color _accentTint = const Color(0xFFE1F4EF);

  bool get _premium => widget.isPremium ?? false;

  // ---------------------------- localization --------------------------------

  /// Current app language from FFLocalizations, normalized to a bare code
  /// ('zh_Hans' -> 'zh'). Falls back to the widget locale, then English.
  String _currentLang() {
    String code;
    try {
      code = FFLocalizations.of(context).languageCode;
    } catch (_) {
      code = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    }
    final l = code.trim().toLowerCase().split('_').first;
    return l.isEmpty ? 'en' : l;
  }

  bool get _isRtl => _kRtl.contains(_lang);

  ui.TextDirection get _dir =>
      _isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr;

  String _t(String key, {int? n, int? m, String? d}) {
    final map = _kStrings[key];
    var s = map == null ? key : (map[_lang] ?? map['en'] ?? key);
    if (n != null) s = s.replaceAll('{n}', '$n');
    if (m != null) s = s.replaceAll('{m}', '$m');
    if (d != null) s = s.replaceAll('{d}', d);
    return s;
  }

  @override
  void didUpdateWidget(covariant HomeView old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId) _load();
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
    _accentOnDark =
        h.withLightness((h.lightness * 1.3).clamp(0.0, 0.85)).toColor();
    _accentTint = Color.alphaBlend(p.withOpacity(0.13), _card);

    // Language: the first resolution triggers the initial load; a later
    // change (user switched language in settings) reloads so muscle and
    // exercise names come back localized.
    final lang = _currentLang();
    if (!_langResolved || lang != _lang) {
      _lang = lang;
      _langResolved = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final d = await _fetch();
      if (mounted) setState(() => _data = d);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  /// Opens the last analysis via the FlutterFlow-generated query so the
  /// page receives a real GetSetAnalysisRow.
  Future<void> _openLastAnalysis(String setLogId) async {
    if (widget.onOpenLastAnalysis == null) return;
    try {
      final rows =
          await SQLiteManager.instance.getSetAnalysis(setLogId: setLogId);
      if (rows.isNotEmpty) await widget.onOpenLastAnalysis!(rows.first);
    } catch (_) {}
  }

  /// Checks used this month, with the same self-healing month check as
  /// canStartQuickAnalysis: a stale month means a fresh quota.
  int get _usedThisMonth {
    final now = DateTime.now();
    final cur = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final used = (widget.analysisCountMonth ?? '') == cur
        ? (widget.analysisCount ?? 0)
        : 0;
    return used.clamp(0, _kFreeMonthlyLimit);
  }

  // ------------------------------ helpers -----------------------------------

  static DateTime? _parse(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final dt = DateTime.tryParse(s);
    if (dt == null) return null;
    return dt.isUtc ? dt.toLocal() : dt;
  }

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double _dbl(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  static DateTime _startOfWeekSunday(DateTime now) {
    final d = DateTime(now.year, now.month, now.day);
    return d.subtract(Duration(days: d.weekday % 7));
  }

  /// Top 3 primary muscle groups, localized. Rows are grouped by pmg id so
  /// the grouping is language independent.
  List<String> _topMuscles(List<Map<String, Object?>> rows) {
    final out = <String>[];
    for (final r in rows) {
      final raw = (r['name'] ?? '').toString();
      if (raw.isEmpty) continue;
      final n = localizedName(raw, _lang);
      if (n.isNotEmpty && !out.contains(n)) out.add(n);
      if (out.length == 3) break;
    }
    return out;
  }

  static int _estimate(int exerciseCount, int setCount) {
    final sets = setCount == 0 ? exerciseCount * 3 : setCount;
    return math.max(15, (sets * _kMinPerSet).round());
  }

  // ------------------------------- fetch ------------------------------------

  Future<_HomeData> _fetch() async {
    final db = SQLiteManager.instance.database;
    final uid = widget.userId;
    final now = DateTime.now();

    // --- saved workouts ---
    // last_done_at is a correlated subquery, not a JOIN on workout_log: a
    // join would repeat every exercise row once per log and inflate counts
    // (5 exercises x 3 logs showed as "15 with form check").
    final wRows = await db.rawQuery('''
      SELECT
        w.id, w.name, w.created_at,
        COUNT(DISTINCT we.id) AS exercise_count,
        COUNT(DISTINCT CASE WHEN e.ai_form_analysis = 1 THEN we.id END)
          AS fc_count,
        (SELECT MAX(wl.created_at) FROM workout_log wl
          WHERE wl.workout_id = w.id) AS last_done_at,
        (SELECT COUNT(*) FROM exercise_sets es WHERE es.workout_id = w.id) AS set_count
      FROM workout w
      LEFT JOIN workout_exercise we ON we.workout_id = w.id
      LEFT JOIN exercise e          ON e.id = we.exercise_id
      WHERE w.user_id = ? AND COALESCE(w.is_deleted, 0) = 0
      GROUP BY w.id, w.name, w.created_at
    ''', [uid]);

    final workouts = <_WorkoutRow>[];
    for (final r in wRows) {
      final id = (r['id'] ?? '').toString();
      final mRows = await db.rawQuery('''
        SELECT pmg.id AS pmg_id, pmg.name AS name, COUNT(*) AS cnt
        FROM workout_exercise we
        JOIN exercise_muscle_group emg
          ON emg.exercise_id = we.exercise_id AND emg.is_primary = 1
        JOIN muscle_group mg           ON mg.id = emg.muscle_group_id
        JOIN primary_muscle_group pmg  ON pmg.id = mg.primary_muscle_group_id
        WHERE we.workout_id = ?
        GROUP BY pmg.id ORDER BY cnt DESC
      ''', [id]);
      final exCount = _int(r['exercise_count']);
      workouts.add(_WorkoutRow(
        id: id,
        name: (r['name'] ?? '').toString().trim(),
        exerciseCount: exCount,
        lastDoneAt: _parse(r['last_done_at']),
        muscles: _topMuscles(mRows),
        formCheckCount: _int(r['fc_count']),
        estMinutes: _estimate(exCount, _int(r['set_count'])),
      ));
    }

    // Rested first (never / >=7d), then oldest-done.
    workouts.sort((a, b) {
      int tier(_WorkoutRow w) {
        if (w.lastDoneAt == null) return 0;
        return now.difference(w.lastDoneAt!).inDays >= 7 ? 0 : 1;
      }

      final t = tier(a).compareTo(tier(b));
      if (t != 0) return t;
      final al = a.lastDoneAt, bl = b.lastDoneAt;
      if (al == null && bl == null) return 0;
      if (al == null) return 1;
      if (bl == null) return -1;
      return al.compareTo(bl);
    });

    // --- last workout ---
    _LastWorkout? last;
    final lRows = await db.rawQuery('''
      SELECT wl.id, wl.workout_id, wl.created_at, wl.duration_seconds, wl.volume,
             w.name,
             (SELECT COUNT(*) FROM set_log s
               WHERE s.workout_log_id = wl.id AND s.is_dropset = 0) AS sets
      FROM workout_log wl
      LEFT JOIN workout w ON w.id = wl.workout_id
      WHERE wl.user_id = ?
      ORDER BY wl.created_at DESC LIMIT 1
    ''', [uid]);
    if (lRows.isNotEmpty) {
      final r = lRows.first;
      final logId = (r['id'] ?? '').toString();
      final at = _parse(r['created_at']) ?? now;
      final mRows = await db.rawQuery('''
        SELECT pmg.id AS pmg_id, pmg.name AS name, COUNT(*) AS cnt
        FROM set_log s
        JOIN exercise_muscle_group emg
          ON emg.exercise_id = s.exercise_id AND emg.is_primary = 1
        JOIN muscle_group mg           ON mg.id = emg.muscle_group_id
        JOIN primary_muscle_group pmg  ON pmg.id = mg.primary_muscle_group_id
        WHERE s.workout_log_id = ?
        GROUP BY pmg.id ORDER BY cnt DESC
      ''', [logId]);
      final prRows = await db.rawQuery('''
        SELECT COUNT(*) AS prs FROM (
          SELECT s.exercise_id, MAX(s.weight) AS mw
          FROM set_log s WHERE s.workout_log_id = ? AND s.is_dropset = 0
          GROUP BY s.exercise_id
        ) cur
        WHERE cur.mw > COALESCE((
          SELECT MAX(p.weight) FROM set_log p
          JOIN workout_log pl ON pl.id = p.workout_log_id
          WHERE p.exercise_id = cur.exercise_id AND p.user_id = ?
            AND pl.created_at < ?
        ), 0)
      ''', [logId, uid, r['created_at']]);
      // duration_seconds currently receives milliseconds from saveWorkoutComplete.
      final rawDur = _int(r['duration_seconds']);
      final durSec = rawDur > 20000 ? rawDur ~/ 1000 : rawDur;
      last = _LastWorkout(
        logId: logId,
        workoutId: (r['workout_id'] ?? '').toString(),
        name: (r['name'] ?? '').toString().trim(),
        at: at,
        durationSec: durSec,
        volume: _dbl(r['volume']),
        sets: _int(r['sets']),
        muscles: _topMuscles(mRows),
        prCount: prRows.isEmpty ? 0 : _int(prRows.first['prs']),
      );
    }

    // --- this week (Sun..Sat, local) ---
    final weekStart = _startOfWeekSunday(now);
    final wkRows = await db.rawQuery('''
      SELECT wl.id, wl.created_at, wl.volume,
             (SELECT COUNT(*) FROM set_log s
               WHERE s.workout_log_id = wl.id AND s.is_dropset = 0) AS sets
      FROM workout_log wl WHERE wl.user_id = ?
      ORDER BY wl.created_at DESC LIMIT 60
    ''', [uid]);
    final perDay = List<int>.filled(7, 0);
    int wkWorkouts = 0, wkSets = 0;
    double wkVol = 0;
    for (final r in wkRows) {
      final at = _parse(r['created_at']);
      if (at == null || at.isBefore(weekStart)) continue;
      wkWorkouts++;
      wkSets += _int(r['sets']);
      wkVol += _dbl(r['volume']);
      perDay[at.weekday % 7]++;
    }

    // --- last form score ---
    _LastScore? lastScore;
    final aRows = await db.rawQuery('''
      SELECT sa.set_log_id, sa.score, sa.analyzed_at, e.name
      FROM set_analysis sa
      JOIN set_log s        ON s.id = sa.set_log_id
      LEFT JOIN exercise e  ON e.id = s.exercise_id
      WHERE s.user_id = ?
      ORDER BY sa.analyzed_at DESC LIMIT 1
    ''', [uid]);
    if (aRows.isNotEmpty) {
      final r = aRows.first;
      lastScore = _LastScore(
        setLogId: (r['set_log_id'] ?? '').toString(),
        score: _dbl(r['score']),
        exerciseName: localizedName((r['name'] ?? '').toString(), _lang),
        at: _parse(r['analyzed_at']) ?? now,
      );
    }

    return _HomeData(
      workouts: workouts,
      lastWorkout: last,
      week: _WeekStats(
        workouts: wkWorkouts,
        sets: wkSets,
        volume: wkVol,
        perDay: perDay,
      ),
      lastScore: lastScore,
    );
  }

  // ------------------------------ formatting --------------------------------

  String _greeting(DateTime now) {
    final h = now.hour;
    if (h < 5) return _t('goodNight');
    if (h < 12) return _t('goodMorning');
    if (h < 17) return _t('goodAfternoon');
    return _t('goodEvening');
  }

  String _dateLine(DateTime now) {
    try {
      // "Saturday, Oct 31" / "שבת, 31 באוק׳" / "sábado, 31 oct"
      return intl.DateFormat('EEEE, MMM d', _lang).format(now);
    } catch (_) {
      return intl.DateFormat('EEEE, MMM d').format(now);
    }
  }

  String _dayAbbrev(DateTime dt) {
    try {
      return intl.DateFormat.E(_lang).format(dt);
    } catch (_) {
      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return days[dt.weekday % 7];
    }
  }

  String _ago(DateTime? dt) {
    if (dt == null) return _t('neverDone');
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return _t('justNow');
    if (diff.inHours < 24) return _t('hoursAgo', n: diff.inHours);
    if (diff.inDays == 1) return _t('yesterday');
    if (diff.inDays < 7) return _t('daysAgo', n: diff.inDays);
    if (diff.inDays < 14) return _t('lastDay', d: _dayAbbrev(dt));
    return _t('weeksAgo', n: (diff.inDays / 7).floor());
  }

  String _dayShort(DateTime dt) {
    final today = DateTime.now();
    if (dt.year == today.year &&
        dt.month == today.month &&
        dt.day == today.day) {
      return _t('today');
    }
    final y = today.subtract(const Duration(days: 1));
    if (dt.year == y.year && dt.month == y.month && dt.day == y.day) {
      return _t('yesterdayCap');
    }
    return _dayAbbrev(dt);
  }

  /// One-letter weekday labels Sun..Sat in the current language.
  List<String> _weekLetters() {
    try {
      final base = DateTime(2023, 1, 1); // a Sunday
      return [
        for (int i = 0; i < 7; i++)
          intl.DateFormat.E(_lang)
              .format(base.add(Duration(days: i)))
              .characters
              .first
              .toUpperCase(),
      ];
    } catch (_) {
      return const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    }
  }

  static String _duration(int sec) {
    final h = sec ~/ 3600, m = (sec % 3600) ~/ 60;
    if (h == 0) return '${m}m';
    return '$h:${m.toString().padLeft(2, '0')}';
  }

  static String _kg(double v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _displayName(_WorkoutRow w) {
    if (w.name.isNotEmpty &&
        !w.name.toLowerCase().startsWith('unnamed workout')) {
      return _cap(w.name);
    }
    if (w.muscles.isNotEmpty) return w.muscles.take(2).join(' & ');
    return _t('workout');
  }

  static String _score(double s) {
    final r = (s * 10).round() / 10;
    return r == r.roundToDouble() ? r.toInt().toString() : r.toStringAsFixed(1);
  }

  // ------------------------------ typography --------------------------------
  // Built from the app theme so Home uses the same family as every other page.

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
          // Negative tracking looks wrong on Hebrew glyphs.
          letterSpacing: _isRtl ? 0 : -size * 0.02,
          display: true);

  TextStyle _body(double size,
          {Color? color, FontWeight w = FontWeight.w400}) =>
      _ts(size, color: color, w: w);

  TextStyle _eyebrow({Color? color}) => _ts(11,
      color: color ?? _inkMuted,
      w: FontWeight.w600,
      letterSpacing: _isRtl ? 0 : 1.4);

  Widget _gutter(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: _kGutter),
        child: child,
      );

  // --------------------------------- UI -------------------------------------

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Directionality(
      textDirection: _dir,
      child: Container(
        width: widget.width,
        height: widget.height,
        color: _bg,
        child: d == null
            ? Center(
                child: _error == null
                    ? CircularProgressIndicator(color: _accent, strokeWidth: 2)
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          '${_t('failedToLoad')}\n$_error',
                          textAlign: TextAlign.center,
                          style: _body(13, color: _inkMuted),
                        ),
                      ),
              )
            : RefreshIndicator(
                color: _accent,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, _kBottomInset),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _gutter(_header()),
                    const SizedBox(height: 20),
                    _gutter(_hero(d)),
                    const SizedBox(height: 12),
                    _gutter(_formCheckCard(d)),
                    const SizedBox(height: 12),
                    _gutter(_weekCard(d)),
                    if (d.lastWorkout != null) ...[
                      const SizedBox(height: 12),
                      _gutter(_lastWorkoutCard(d.lastWorkout!)),
                    ],
                    const SizedBox(height: 26),
                    _myWorkouts(d),
                  ],
                ),
              ),
      ),
    );
  }

  // --- header: greeting only, settings at the end ---
  Widget _header() {
    final now = DateTime.now();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_dateLine(now).toUpperCase(), style: _eyebrow()),
              const SizedBox(height: 6),
              Text(
                _greeting(now),
                style: _display(32),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => widget.onOpenSettings?.call(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: _card, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(Icons.settings_rounded, size: 20, color: _ink),
          ),
        ),
      ],
    );
  }

  // --- hero: Up next ---
  Widget _hero(_HomeData d) {
    if (d.workouts.isEmpty) {
      return _darkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('startHere'), style: _eyebrow(color: _accentOnDark)),
            const SizedBox(height: 14),
            Text(_t('buildFirst'), style: _display(30, color: _kOnDark)),
            const SizedBox(height: 8),
            Text(_t('buildFirstSub'), style: _body(13, color: _kOnDarkMuted)),
            const SizedBox(height: 18),
            _primaryButton(_t('createWorkout'),
                onTap: () => widget.onCreateWorkout?.call()),
          ],
        ),
      );
    }

    final w = d.workouts[_heroOffset % d.workouts.length];
    final rested = w.muscles.isNotEmpty && w.isRested;
    return _darkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_t('upNext'), style: _eyebrow(color: _accentOnDark)),
              const Spacer(),
              if (rested) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                      color: _accentOnDark, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(_t('recovered'), style: _body(12, color: _kOnDarkMuted)),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _displayName(w),
            style: _display(34, color: _kOnDark),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '${_t('exercisesCount', n: w.exerciseCount)} · ${_t('minutes', n: w.estMinutes)} · ${_ago(w.lastDoneAt)}',
            style: _body(13, color: _kOnDarkMuted),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final m in w.muscles) _pillDark(m),
              if (w.formCheckCount > 0)
                _pillDark(
                  _t('withFormCheck', n: w.formCheckCount),
                  icon: _FormCheckIcon(size: 12, color: _accentOnDark),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _primaryButton(
                  _t('startWorkout'),
                  icon: Icons.play_arrow_rounded,
                  onTap: () => widget.onStartWorkout?.call(w.id),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: d.workouts.length > 1
                    ? () => setState(() => _heroOffset++)
                    : null,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_kRadiusInner),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: d.workouts.length > 1 ? _kOnDark : _kOnDarkMuted,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- form check card: quota + last score. Camera lives on the FAB. ---
  Widget _formCheckCard(_HomeData d) {
    final left = _kFreeMonthlyLimit - _usedThisMonth;
    final ls = d.lastScore;

    String subtitle;
    if (ls == null) {
      subtitle = _premium
          ? _t('unlimitedFilm')
          : _t('leftFilm', n: left, m: _kFreeMonthlyLimit);
    } else if (_premium) {
      subtitle = _t('unlimitedReview');
    } else {
      subtitle = _t('leftChecks', n: left, m: _kFreeMonthlyLimit);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: ls == null ? null : () => _openLastAnalysis(ls.setLogId),
      child: _lightCard(
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _accentTint,
                borderRadius: BorderRadius.circular(_kRadiusInner),
              ),
              alignment: Alignment.center,
              child: _FormCheckIcon(size: 24, color: _accentDeep),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_t('formCheck'), style: _body(16, w: FontWeight.w600)),
                  const SizedBox(height: 5),
                  Text(subtitle,
                      style: _body(12, color: _inkMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (!_premium) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (int i = 0; i < _kFreeMonthlyLimit; i++) ...[
                          Expanded(
                            child: Container(
                              height: 5,
                              decoration: BoxDecoration(
                                color: i < left ? _accent : _line,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          if (i < _kFreeMonthlyLimit - 1)
                            const SizedBox(width: 4),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (ls != null) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 84,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ScoreRing(
                      score: ls.score,
                      label: _score(ls.score),
                      color: _accent,
                      track: _line,
                      labelStyle: _display(16, w: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${ls.exerciseName} · ${_dayShort(ls.at)}',
                      style: _body(10, color: _inkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- this week: circles, centered stats ---
  Widget _weekCard(_HomeData d) {
    final letters = _weekLetters();
    final today = DateTime.now().weekday % 7;
    final wk = d.week;
    return _lightCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_t('thisWeek'), style: _body(14, w: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: () => widget.onOpenStats?.call(),
                child: Row(
                  children: [
                    Text(_t('fullStats'),
                        style:
                            _body(12, color: _accentDeep, w: FontWeight.w500)),
                    Icon(
                        _isRtl
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        size: 16,
                        color: _accentDeep),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (int i = 0; i < 7; i++)
                Expanded(
                  child: Column(
                    children: [
                      _dayDot(done: wk.perDay[i] > 0, today: i == today),
                      const SizedBox(height: 7),
                      Text(
                        letters[i],
                        style: _body(
                          11,
                          color:
                              i == today || wk.perDay[i] > 0 ? _ink : _inkMuted,
                          w: i == today ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: _cardSub),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat('${wk.workouts}', _t('workouts')),
              _stat('${wk.sets}', _t('sets')),
              _stat(_kg(wk.volume), _t('kgVolume')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayDot({required bool done, required bool today}) {
    if (done) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: today ? _card : Colors.transparent,
        border: Border.all(
          color: today ? _accent : _line,
          width: today ? 2 : 1.5,
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value, style: _display(26), textAlign: TextAlign.center),
            const SizedBox(height: 3),
            Text(label,
                style: _body(11, color: _inkMuted),
                textAlign: TextAlign.center),
          ],
        ),
      );

  // --- last workout: card opens summary, round button restarts it ---
  Widget _lastWorkoutCard(_LastWorkout l) {
    final hh = l.at.hour.toString().padLeft(2, '0');
    final mm = l.at.minute.toString().padLeft(2, '0');
    final prText =
        l.prCount > 1 ? _t('prsPlural', n: l.prCount) : _t('prs', n: l.prCount);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onOpenSummary?.call(l.logId),
      child: _lightCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_t('lastWorkout')} · ${_dayShort(l.at).toUpperCase()} $hh:$mm',
                    style: _eyebrow(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(l.name.isEmpty ? _t('workout') : _cap(l.name),
                          style: _display(20, w: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l.muscles.join(' · '),
                          style: _body(12, color: _inkMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text.rich(TextSpan(
                    style: _body(13),
                    children: [
                      TextSpan(
                          text:
                              '${_duration(l.durationSec)} · ${_kg(l.volume)} kg · ${_t('setsCount', n: l.sets)}'),
                      if (l.prCount > 0)
                        TextSpan(
                          text: ' · $prText',
                          style:
                              _body(13, color: _accentDeep, w: FontWeight.w600),
                        ),
                    ],
                  )),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: l.workoutId.isEmpty
                  ? null
                  : () => widget.onStartWorkout?.call(l.workoutId),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _ink, width: 1.5),
                ),
                child: Icon(Icons.refresh_rounded, size: 20, color: _ink),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- my workouts: full-bleed horizontal shelf ---
  Widget _myWorkouts(_HomeData d) {
    final list = d.workouts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _gutter(Row(
          children: [
            Text(_t('myWorkouts'), style: _display(20, w: FontWeight.w700)),
            const Spacer(),
            if (list.isNotEmpty)
              GestureDetector(
                onTap: () => widget.onOpenLibrary?.call(),
                child: Text(_t('seeAll', n: list.length),
                    style: _body(12, color: _accentDeep, w: FontWeight.w500)),
              ),
          ],
        )),
        const SizedBox(height: 12),
        if (list.isNotEmpty)
          SizedBox(
            height: 156,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _kGutter),
              physics: const BouncingScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _workoutCard(list[i]),
            ),
          )
        else
          _gutter(_templatesCard()),
        const SizedBox(height: 12),
        _gutter(GestureDetector(
          onTap: () => widget.onCreateWorkout?.call(),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_kRadius),
              border: Border.all(color: _inkFaint, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 20, color: _ink),
                const SizedBox(width: 8),
                Text(_t('createWorkout'), style: _body(14, w: FontWeight.w600)),
              ],
            ),
          ),
        )),
      ],
    );
  }

  // Shown only while the user has no workouts: points at the template
  // catalog, which new users otherwise don't discover.
  Widget _templatesCard() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => (widget.onOpenTemplates ?? widget.onOpenLibrary)?.call(),
      child: _lightCard(
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _accentTint,
                borderRadius: BorderRadius.circular(_kRadiusInner),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.auto_stories_rounded,
                  size: 22, color: _accentDeep),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_t('startFromTemplate'),
                      style: _body(16, w: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    _t('templateSub'),
                    style: _body(12, color: _inkMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
                _isRtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                size: 22,
                color: _inkMuted),
          ],
        ),
      ),
    );
  }

  Widget _workoutCard(_WorkoutRow w) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(_kRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _displayName(w),
            style: _body(16, w: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
              '${_t('exercisesCount', n: w.exerciseCount)} · ${_t('minutes', n: w.estMinutes)}',
              style: _body(12, color: _inkMuted)),
          const SizedBox(height: 8),
          Text(
            w.muscles.join(' · '),
            style: _body(12, color: _inkMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  w.lastDoneAt == null
                      ? _t('neverDoneCap')
                      : _t('doneAgo', d: _ago(w.lastDoneAt)),
                  style: _body(11, color: _inkMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onStartWorkout?.call(w.id),
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: _kDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(_t('start'),
                      style: _body(13, color: _kOnDark, w: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------ primitives --------------------------------

  Widget _darkCard({required Widget child}) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kDark,
          borderRadius: BorderRadius.circular(_kRadius),
        ),
        child: child,
      );

  Widget _lightCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) =>
      Container(
        padding: padding,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(_kRadius),
        ),
        child: child,
      );

  Widget _pillDark(String text, {Widget? icon}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon, const SizedBox(width: 5)],
            Text(text,
                style: _body(12, color: _kOnDarkPill, w: FontWeight.w500)),
          ],
        ),
      );

  Widget _primaryButton(String label, {IconData? icon, VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(_kRadiusInner),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: _body(16, color: Colors.white, w: FontWeight.w600)),
            ],
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Score ring
// ---------------------------------------------------------------------------
class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    required this.score,
    required this.label,
    required this.color,
    required this.track,
    required this.labelStyle,
  });
  final double score;
  final String label;
  final Color color;
  final Color track;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(50, 50),
            painter: _RingPainter(score.clamp(0, 10) / 10, color, track),
          ),
          Text(label, style: labelStyle),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t, this.color, this.track);
  final double t;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const r = 21.0;
    final bg = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, bg);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * t,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.t != t || old.color != color || old.track != track;
}

// ---------------------------------------------------------------------------
// Unified form-check icon: video camera with a sparkle
// ---------------------------------------------------------------------------
class _FormCheckIcon extends StatelessWidget {
  const _FormCheckIcon({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FormCheckPainter(color)),
    );
  }
}

class _FormCheckPainter extends CustomPainter {
  _FormCheckPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3 * s, 7 * s, 13 * s, 10 * s),
        Radius.circular(2 * s),
      ),
      stroke,
    );
    final lens = Path()
      ..moveTo(16 * s, 10 * s)
      ..lineTo(21 * s, 7 * s)
      ..lineTo(21 * s, 17 * s)
      ..lineTo(16 * s, 14 * s);
    canvas.drawPath(lens, stroke);
    final sp = Path()
      ..moveTo(19 * s, 1.5 * s)
      ..lineTo(19.7 * s, 3.3 * s)
      ..lineTo(21.5 * s, 4 * s)
      ..lineTo(19.7 * s, 4.7 * s)
      ..lineTo(19 * s, 6.5 * s)
      ..lineTo(18.3 * s, 4.7 * s)
      ..lineTo(16.5 * s, 4 * s)
      ..lineTo(18.3 * s, 3.3 * s)
      ..close();
    canvas.drawPath(sp, fill);
  }

  @override
  bool shouldRepaint(_FormCheckPainter old) => old.color != color;
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
