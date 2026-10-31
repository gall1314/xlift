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
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl show DateFormat;

/// "By Muscle" stats tab.
///
/// Top card: a compact grid of recovery rings, one per primary muscle group
/// (ring fills over the 48h recovery window, hours left inside, check when
/// ready), plus a panel for the selected muscle (last trained, status).
/// Below: volume / sets / change tiles with a volume-over-time chart, top
/// exercises and the sub-muscle breakdown for the selected muscle (only when
/// the group actually splits into more than one sub-muscle).
///
/// Fully self-managed: runs its own SQLite queries, no FlutterFlow query
/// needed. Recovery is always computed from the user's full history; the
/// numbers below it follow [timeRange] and reload when it changes.
///
/// Localization: reads the app language from FFLocalizations (no parameter).
/// UI strings come from _kStrings, muscle / exercise names from
/// localizedName, dates from intl; Hebrew renders RTL.
///
/// [timeRange]: 'Last 7 days' | 'Last 30 days' | 'Last 90 days'; anything
/// else ('All', 'All time', empty) means no limit. These are internal keys,
/// not shown to the user. [isDark]: the app's dark-mode flag.
/// [onExerciseTap](exerciseId, isPublic): a "Top exercises" row was tapped.
/// [onRangeChange](range): the button in the "nothing in this time range"
/// state, with the shortest range that contains the muscle's last workout.
///
/// Recovery thresholds (minutes since last trained): < 1440 recovering, <
/// 2880 almost ready, < 10080 ready, otherwise not trained lately.
class MuscleStatsView extends StatefulWidget {
  const MuscleStatsView({
    super.key,
    this.width,
    this.height,
    required this.userId,
    this.timeRange,
    this.isDark,
    this.onExerciseTap,
    this.onRangeChange,
  });

  final double? width;
  final double? height;
  final String userId;
  final String? timeRange;
  final bool? isDark;
  final Future Function(int exerciseId, bool isPublic)? onExerciseTap;
  final Future Function(String range)? onRangeChange;

  @override
  State<MuscleStatsView> createState() => _MuscleStatsViewState();
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

/// {n} number, {m} muscle name, {r} range label, {a} ago text.
const Map<String, Map<String, String>> _kStrings = {
  "noGroups": {
    "en": "No muscle groups found",
    "es": "No se encontraron grupos musculares",
    "he": "לא נמצאו קבוצות שרירים",
    "de": "Keine Muskelgruppen gefunden",
    "fr": "Aucun groupe musculaire trouvé",
  },
  "noDataYet": {
    "en": "No data yet",
    "es": "Sin datos aún",
    "he": "אין נתונים עדיין",
    "de": "Noch keine Daten",
    "fr": "Pas encore de données",
  },
  "recovering": {
    "en": "Recovering",
    "es": "Recuperando",
    "he": "בהתאוששות",
    "de": "Erholt sich",
    "fr": "En récupération",
  },
  "almostReady": {
    "en": "Almost ready",
    "es": "Casi listo",
    "he": "כמעט מוכן",
    "de": "Fast bereit",
    "fr": "Presque prêt",
  },
  "readyToTrain": {
    "en": "Ready to train",
    "es": "Listo para entrenar",
    "he": "מוכן לאימון",
    "de": "Bereit zum Training",
    "fr": "Prêt à entraîner",
  },
  "notTrainedLately": {
    "en": "Not trained lately",
    "es": "Sin entrenar últimamente",
    "he": "לא אומן לאחרונה",
    "de": "Zuletzt nicht trainiert",
    "fr": "Pas entraîné récemment",
  },
  "notTrainedYet": {
    "en": "Not trained yet",
    "es": "Aún sin entrenar",
    "he": "עדיין לא אומן",
    "de": "Noch nicht trainiert",
    "fr": "Pas encore entraîné",
  },
  "minAgo": {
    "en": "{n}m ago",
    "es": "hace {n} min",
    "he": "לפני {n} דק׳",
    "de": "vor {n} Min.",
    "fr": "il y a {n} min",
  },
  "hoursAgo": {
    "en": "{n}h ago",
    "es": "hace {n} h",
    "he": "לפני {n} שע׳",
    "de": "vor {n} Std.",
    "fr": "il y a {n} h",
  },
  "daysAgo": {
    "en": "{n}d ago",
    "es": "hace {n} días",
    "he": "לפני {n} ימים",
    "de": "vor {n} Tagen",
    "fr": "il y a {n} j",
  },
  "lastTrainedReadyIn": {
    "en": "Last trained {a} · ready in about {n}h",
    "es": "Último entreno {a} · listo en unas {n} h",
    "he": "אומן לאחרונה {a} · מוכן בעוד כ-{n} שע׳",
    "de": "Zuletzt {a} · bereit in ca. {n} Std.",
    "fr": "Dernier entraînement {a} · prêt dans env. {n} h",
  },
  "lastTrained": {
    "en": "Last trained {a}",
    "es": "Último entreno {a}",
    "he": "אומן לאחרונה {a}",
    "de": "Zuletzt trainiert {a}",
    "fr": "Dernier entraînement {a}",
  },
  "volumeOf": {
    "en": "{m} volume",
    "es": "Volumen de {m}",
    "he": "נפח {m}",
    "de": "{m}-Volumen",
    "fr": "Volume {m}",
  },
  "total": {
    "en": "Total",
    "es": "Total",
    "he": 'סה"כ',
    "de": "Gesamt",
    "fr": "Total",
  },
  "sets": {
    "en": "Sets",
    "es": "Series",
    "he": "סטים",
    "de": "Sätze",
    "fr": "Séries",
  },
  "change": {
    "en": "Change",
    "es": "Cambio",
    "he": "שינוי",
    "de": "Änderung",
    "fr": "Évolution",
  },
  "noWeightedSets": {
    "en":
        "No weighted sets in this time range, so there is no volume to chart.",
    "es":
        "No hay series con peso en este periodo, así que no hay volumen que mostrar.",
    "he": "אין סטים עם משקל בטווח הזה, אז אין נפח להציג.",
    "de":
        "Keine Sätze mit Gewicht in diesem Zeitraum, also kein Volumen zum Anzeigen.",
    "fr":
        "Aucune série avec charge sur cette période, donc pas de volume à afficher.",
  },
  "oneWorkout": {
    "en": "One workout so far. The trend appears after the second.",
    "es": "Un entrenamiento hasta ahora. La tendencia aparece tras el segundo.",
    "he": "אימון אחד בינתיים. המגמה תופיע אחרי השני.",
    "de": "Bisher ein Workout. Der Trend erscheint nach dem zweiten.",
    "fr":
        "Un entraînement pour l'instant. La tendance apparaît après le deuxième.",
  },
  "topExercises": {
    "en": "Top exercises",
    "es": "Ejercicios principales",
    "he": "תרגילים מובילים",
    "de": "Top-Übungen",
    "fr": "Exercices principaux",
  },
  "setsCount1": {
    "en": "{n} set",
    "es": "{n} serie",
    "he": "סט {n}",
    "de": "{n} Satz",
    "fr": "{n} série",
  },
  "setsCountN": {
    "en": "{n} sets",
    "es": "{n} series",
    "he": "{n} סטים",
    "de": "{n} Sätze",
    "fr": "{n} séries",
  },
  "subBreakdown": {
    "en": "Sub-muscle breakdown",
    "es": "Desglose por músculo",
    "he": "פילוח לפי שריר",
    "de": "Aufteilung nach Muskel",
    "fr": "Répartition par muscle",
  },
  "noDataFor": {
    "en": "No {m} data yet",
    "es": "Sin datos de {m} aún",
    "he": "אין עדיין נתונים ל{m}",
    "de": "Noch keine Daten für {m}",
    "fr": "Pas encore de données pour {m}",
  },
  "logToSee": {
    "en": "Log an exercise that targets {m} and it will show up here.",
    "es": "Registra un ejercicio de {m} y aparecerá aquí.",
    "he": "תעד תרגיל שעובד על {m} והוא יופיע כאן.",
    "de": "Trage eine Übung für {m} ein und sie erscheint hier.",
    "fr": "Enregistrez un exercice ciblant {m} et il apparaîtra ici.",
  },
  "noSetsInRange": {
    "en": "No {m} sets in the {r}",
    "es": "Sin series de {m} en {r}",
    "he": "אין סטים של {m} ב{r}",
    "de": "Keine {m}-Sätze in {r}",
    "fr": "Aucune série {m} sur {r}",
  },
  "olderThanThat": {
    "en": "Your last {m} workout is older than that.",
    "es": "Tu último entreno de {m} es anterior.",
    "he": "האימון האחרון של {m} ישן יותר מזה.",
    "de": "Dein letztes {m}-Workout liegt länger zurück.",
    "fr": "Votre dernier entraînement {m} est plus ancien.",
  },
  "show": {
    "en": "Show {r}",
    "es": "Mostrar {r}",
    "he": "הצג {r}",
    "de": "{r} anzeigen",
    "fr": "Afficher {r}",
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
};

String _tr(String lang, String key, {int? n, String? m, String? r, String? a}) {
  final map = _kStrings[key];
  var s = map == null ? key : (map[lang] ?? map['en'] ?? key);
  if (n != null) s = s.replaceAll('{n}', '$n');
  if (m != null) s = s.replaceAll('{m}', m);
  if (r != null) s = s.replaceAll('{r}', r);
  if (a != null) s = s.replaceAll('{a}', a);
  return s;
}

/// Human label for an internal range key.
String _rangeLabel(String lang, String range) {
  switch (range.trim()) {
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
// Helpers
// ---------------------------------------------------------------------------

TextStyle _ms(BuildContext ctx, double size, FontWeight w, Color c,
    {double ls = 0, double? height}) {
  final th = FlutterFlowTheme.of(ctx);
  // Negative tracking looks wrong on Hebrew glyphs.
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

int _mI(dynamic v, [int d = 0]) {
  if (v == null) return d;
  if (v is int) return v;
  if (v is num) return v.round();
  return num.tryParse(v.toString())?.round() ?? d;
}

int? _mIN(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.round();
  final s = v.toString().trim();
  if (s.isEmpty || s == 'null') return null;
  return num.tryParse(s)?.round();
}

double _mD(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().trim()) ?? 0;
}

DateTime? _mDt(dynamic raw) {
  final s = (raw ?? '').toString().trim();
  if (s.isEmpty) return null;
  final parsed = DateTime.tryParse(s);
  if (parsed == null) return null;
  return parsed.isUtc ? parsed.toLocal() : parsed;
}

String _trim1(double v) {
  final double r = (v * 10).round() / 10;
  return r == r.roundToDouble() ? r.toInt().toString() : r.toStringAsFixed(1);
}

/// 950 -> "950", 1000 -> "1K", 23400 -> "23.4K", 1200000 -> "1.2M".
String _compact(double v) {
  final double a = v.abs();
  if (a >= 1000000) return '${_trim1(v / 1000000)}M';
  if (a >= 1000) return '${_trim1(v / 1000)}K';
  return v.round().toString();
}

String _mShortDate(String lang, DateTime? dt) {
  if (dt == null) return '';
  try {
    return intl.DateFormat.MMMd(lang).format(dt);
  } catch (_) {
    return intl.DateFormat.MMMd().format(dt);
  }
}

/// Step of 1, 2, 2.5 or 5 times a power of 10 giving about [targetTicks].
double _mNiceStep(double range, int targetTicks) {
  if (range <= 0) return 1;
  final double rough = range / (targetTicks - 1);
  final double mag =
      math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
  final double norm = rough / mag;
  double nice;
  if (norm <= 1) {
    nice = 1;
  } else if (norm <= 2) {
    nice = 2;
  } else if (norm <= 2.5) {
    nice = 2.5;
  } else if (norm <= 5) {
    nice = 5;
  } else {
    nice = 10;
  }
  return nice * mag;
}

// ---------------------------------------------------------------------------
// Palette + recovery status
// ---------------------------------------------------------------------------

class _MPal {
  _MPal(BuildContext ctx, this.dark)
      : th = FlutterFlowTheme.of(ctx),
        tint = dark ? const Color(0xFF0F2524) : const Color(0xFFDDF3EF),
        tintInk = dark ? Colors.white : const Color(0xFF0B2F2D),
        tintSub = dark ? const Color(0xFFA9BDBB) : const Color(0xFF3F605D),
        cellSelected = dark ? const Color(0x245EEAD4) : const Color(0xFFDDF3EF),
        chipBg = dark ? const Color(0x1AFFFFFF) : Colors.white,
        accent = dark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E),
        chartFill = dark ? const Color(0x245EEAD4) : const Color(0x1F0F766E),
        track = dark ? const Color(0x1AFFFFFF) : const Color(0xFFECEFF3),
        up = dark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
        down = dark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);

  final bool dark;
  final FlutterFlowTheme th;
  final Color tint, tintInk, tintSub, cellSelected, chipBg;
  final Color accent, chartFill, track, up, down;
}

class _Rec {
  const _Rec({
    required this.ring,
    required this.text,
    required this.label,
    required this.frac,
    required this.center,
    required this.ready,
  });

  final Color ring; // ring / dot color
  final Color text; // readable status text color
  final String label;
  final double frac; // 0..1 of the 48h window
  final String center; // text inside the ring ('' when [ready])
  final bool ready;
}

_Rec _recOf(String lang, int? minutes, bool dark) {
  const Color red = Color(0xFFE85A5A);
  const Color orange = Color(0xFFF1A24A);
  const Color teal = Color(0xFF2CCAAE);
  const Color grey = Color(0xFFC8CDD5);
  final Color greyText =
      dark ? const Color(0xFFCBD5E1) : const Color(0xFF5B6472);

  if (minutes == null) {
    return _Rec(
        ring: grey,
        text: greyText,
        label: _tr(lang, 'noDataYet'),
        frac: 0,
        center: '–',
        ready: false);
  }
  final int m = minutes < 0 ? 0 : minutes;
  final int hoursLeft = ((2880 - m) / 60).ceil();
  if (m < 1440) {
    return _Rec(
        ring: red,
        text: dark ? red : const Color(0xFFB42318),
        label: _tr(lang, 'recovering'),
        frac: m / 2880,
        center: '${hoursLeft}h',
        ready: false);
  }
  if (m < 2880) {
    return _Rec(
        ring: orange,
        text: dark ? orange : const Color(0xFF9A5206),
        label: _tr(lang, 'almostReady'),
        frac: m / 2880,
        center: '${hoursLeft}h',
        ready: false);
  }
  if (m < 10080) {
    return _Rec(
        ring: teal,
        text: dark ? teal : const Color(0xFF0F766E),
        label: _tr(lang, 'readyToTrain'),
        frac: 1,
        center: '',
        ready: true);
  }
  return _Rec(
      ring: grey,
      text: greyText,
      label: _tr(lang, 'notTrainedLately'),
      frac: 0,
      center: '–',
      ready: false);
}

String _lastTrainedText(String lang, int? minutes) {
  if (minutes == null) return _tr(lang, 'notTrainedYet');
  final int m = minutes < 0 ? 0 : minutes;
  String ago;
  if (m < 60) {
    ago = _tr(lang, 'minAgo', n: m);
  } else if (m < 1440) {
    ago = _tr(lang, 'hoursAgo', n: m ~/ 60);
  } else {
    ago = _tr(lang, 'daysAgo', n: m ~/ 1440);
  }
  if (m < 2880) {
    final int hoursLeft = ((2880 - m) / 60).ceil();
    return _tr(lang, 'lastTrainedReadyIn', a: ago, n: hoursLeft);
  }
  return _tr(lang, 'lastTrained', a: ago);
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

class _Muscle {
  const _Muscle(this.id, this.name, this.minutes);
  final int id;
  final String name; // localized
  final int? minutes; // since last trained, null = never
}

class _TopEx {
  _TopEx(this.id, this.name, this.nameEn, this.isPublic, this.illustration);
  final int id;
  final String name; // localized
  final String nameEn; // English (image lookup)
  final bool isPublic;
  final String? illustration;
  int sets = 0;
}

class _Detail {
  _Detail({
    required this.muscleId,
    required this.sets,
    required this.volume,
    required this.changePct,
    required this.sessionVolumes,
    required this.firstDate,
    required this.lastDate,
    required this.top,
    required this.subs,
  });

  final int muscleId;
  final int sets;
  final double volume; // kg
  final double? changePct; // first vs last workout in range, null = n/a
  final List<double> sessionVolumes; // per workout, oldest first
  final DateTime? firstDate, lastDate;
  final List<_TopEx> top;
  final List<MapEntry<String, int>> subs; // sub-muscle (localized) -> count
}

_Detail _buildDetail(
    String lang, int muscleId, List<Map<String, Object?>> rows) {
  final Set<String> seen = {};
  final Map<int, int> subCount = {}; // keyed by muscle_group.id
  final Map<int, String> subName = {};
  final List<String> sessionIds = [];
  final Map<String, double> sessionVol = {};
  final Map<String, DateTime?> sessionDate = {};
  final Map<int, _TopEx> exMap = {};
  int sets = 0;
  double volume = 0;

  for (final r in rows) {
    // Every row counts for the sub-muscle split (an exercise can have two
    // primary sub-muscles in the same group).
    final int subId = _mI(r['sub_muscle_id'], -1);
    final String subRaw = (r['sub_muscle'] ?? '').toString().trim();
    if (subId >= 0 && subRaw.isNotEmpty) {
      subCount[subId] = (subCount[subId] ?? 0) + 1;
      subName[subId] ??= localizedName(subRaw, lang);
    }

    // Everything else counts each set once.
    final String setId = (r['set_id'] ?? '').toString();
    if (!seen.add(setId)) continue;
    sets++;

    final int reps = _mI(r['reps']);
    final double w = _mD(r['weight']);
    final bool isKg = _mI(r['is_kg'], 1) == 1;
    final bool assisted = _mI(r['is_assisted']) == 1;
    final double vol = (assisted || w <= 0 || reps <= 0)
        ? 0
        : reps * (isKg ? w : w * 0.453592);
    volume += vol;

    final String wid = (r['workout_log_id'] ?? '').toString();
    if (!sessionVol.containsKey(wid)) {
      sessionIds.add(wid);
      sessionVol[wid] = 0;
      sessionDate[wid] = _mDt(r['created_at']);
    }
    sessionVol[wid] = sessionVol[wid]! + vol;

    final int exId = _mI(r['exercise_id']);
    final String ill = (r['illustration'] ?? '').toString().trim();
    final String rawName = (r['exercise_name'] ?? '').toString();
    final _TopEx ex = exMap.putIfAbsent(
      exId,
      () => _TopEx(
        exId,
        localizedName(rawName, lang),
        localizedName(rawName, 'en'),
        _mI(r['is_public'], 1) == 1,
        (ill.isEmpty || ill == 'null') ? null : ill,
      ),
    );
    ex.sets++;
  }

  final List<double> series = [for (final w in sessionIds) sessionVol[w]!];
  double? change;
  if (series.length >= 2 && series.first > 0) {
    change = (series.last - series.first) * 100.0 / series.first;
  }

  final List<_TopEx> top = exMap.values.toList()
    ..sort((a, b) {
      final c = b.sets.compareTo(a.sets);
      return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  final List<MapEntry<String, int>> subs = [
    for (final e in subCount.entries) MapEntry(subName[e.key] ?? '', e.value)
  ]..sort((a, b) => b.value.compareTo(a.value));

  return _Detail(
    muscleId: muscleId,
    sets: sets,
    volume: volume,
    changePct: change,
    sessionVolumes: series,
    firstDate: sessionIds.isEmpty ? null : sessionDate[sessionIds.first],
    lastDate: sessionIds.isEmpty ? null : sessionDate[sessionIds.last],
    top: top.length > 5 ? top.sublist(0, 5) : top,
    subs: subs,
  );
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _MuscleStatsViewState extends State<MuscleStatsView> {
  List<_Muscle> _muscles = [];
  bool _loadingMuscles = true;
  int? _selectedId;
  _Detail? _detail;
  bool _loadingDetail = true;
  int _musclesToken = 0;
  int _detailToken = 0;
  String _lang = 'en';

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l = _langOf(context);
    if (l != _lang || _loadingMuscles && _muscles.isEmpty) {
      _lang = l;
      _loadMuscles();
    }
  }

  @override
  void didUpdateWidget(covariant MuscleStatsView old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId) {
      _selectedId = null;
      _loadMuscles();
    } else if (old.timeRange != widget.timeRange) {
      _loadDetail();
    }
  }

  // ---------- data ----------
  String? _cutoffModifier() {
    switch ((widget.timeRange ?? '').trim()) {
      case 'Last 7 days':
        return '-7 days';
      case 'Last 30 days':
        return '-30 days';
      case 'Last 90 days':
        return '-90 days';
      default:
        return null; // All / All time
    }
  }

  /// All primary muscle groups with minutes since last trained (full
  /// history, not limited by the time range).
  Future<void> _loadMuscles() async {
    final int token = ++_musclesToken;
    final String lang = _lang;
    final List<_Muscle> out = [];
    try {
      final rows = await SQLiteManager.instance.database.rawQuery(
        'SELECT pmg.id AS id, pmg.name AS name, '
        '(SELECT CAST((JULIANDAY(\'now\',\'localtime\') - '
        '        JULIANDAY(MAX(s.created_at))) * 1440 AS INTEGER) '
        ' FROM set_log s '
        ' JOIN workout_log wl ON wl.id = s.workout_log_id '
        ' JOIN exercise_muscle_group emg '
        '      ON emg.exercise_id = s.exercise_id AND emg.is_primary = 1 '
        ' JOIN muscle_group mg ON mg.id = emg.muscle_group_id '
        ' WHERE wl.user_id = ? '
        '   AND mg.primary_muscle_group_id = pmg.id) AS minutes_since '
        'FROM primary_muscle_group pmg '
        'WHERE pmg.name IS NOT NULL AND TRIM(pmg.name) <> \'\' '
        'ORDER BY pmg.id ASC',
        [widget.userId],
      );
      for (final r in rows) {
        out.add(_Muscle(
          _mI(r['id']),
          localizedName((r['name'] ?? '').toString().trim(), lang),
          _mIN(r['minutes_since']),
        ));
      }
    } catch (_) {}
    if (!mounted || token != _musclesToken) return;

    // Default selection: the most recently trained muscle, else the first.
    int? pick = _selectedId;
    if (pick == null || !out.any((m) => m.id == pick)) {
      _Muscle? best;
      for (final m in out) {
        if (m.minutes == null) continue;
        if (best == null || m.minutes! < best.minutes!) best = m;
      }
      pick = best?.id ?? (out.isNotEmpty ? out.first.id : null);
    }

    setState(() {
      _muscles = out;
      _selectedId = pick;
      _loadingMuscles = false;
    });
    _loadDetail();
  }

  /// Sets of the selected muscle inside the time range.
  Future<void> _loadDetail() async {
    final int? muscleId = _selectedId;
    final int token = ++_detailToken;
    final String lang = _lang;
    if (muscleId == null) {
      if (mounted) {
        setState(() {
          _detail = null;
          _loadingDetail = false;
        });
      }
      return;
    }
    if (mounted) setState(() => _loadingDetail = true);

    final String? modifier = _cutoffModifier();
    final String cutoffClause = modifier == null
        ? ''
        : "AND datetime(replace(wl.created_at,' ','T')) >= "
            "datetime('now','localtime', ?) ";
    final String sql = 'SELECT '
        'sl.id AS set_id, '
        'sl.exercise_id AS exercise_id, '
        'e.name AS exercise_name, '
        'e.is_public AS is_public, '
        'COALESCE(e.is_assisted, 0) AS is_assisted, '
        'COALESCE(e.illustration, e.no_video_ilustration) AS illustration, '
        'sl.workout_log_id AS workout_log_id, '
        'wl.created_at AS created_at, '
        'sl.reps AS reps, '
        'sl.weight AS weight, '
        'sl.is_kg AS is_kg, '
        'mg.id AS sub_muscle_id, '
        'mg.name AS sub_muscle '
        'FROM set_log sl '
        'JOIN workout_log wl ON wl.id = sl.workout_log_id '
        'JOIN exercise e ON e.id = sl.exercise_id '
        'JOIN exercise_muscle_group emg '
        '     ON emg.exercise_id = sl.exercise_id AND emg.is_primary = 1 '
        'JOIN muscle_group mg ON mg.id = emg.muscle_group_id '
        'WHERE wl.user_id = ? '
        'AND mg.primary_muscle_group_id = ? '
        'AND COALESCE(sl.is_dropset, 0) = 0 '
        '$cutoffClause'
        "ORDER BY datetime(replace(wl.created_at,' ','T')) ASC, "
        'sl.created_at ASC';

    _Detail detail = _buildDetail(lang, muscleId, const []);
    try {
      final rows = await SQLiteManager.instance.database.rawQuery(
        sql,
        modifier == null
            ? [widget.userId, muscleId]
            : [widget.userId, muscleId, modifier],
      );
      detail = _buildDetail(lang, muscleId, rows);
    } catch (_) {}
    if (!mounted || token != _detailToken) return;
    setState(() {
      _detail = detail;
      _loadingDetail = false;
    });
  }

  void _select(int id) {
    if (id == _selectedId) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedId = id);
    _loadDetail();
  }

  _Muscle? get _selected {
    for (final m in _muscles) {
      if (m.id == _selectedId) return m;
    }
    return null;
  }

  /// Shortest range that contains the muscle's last workout, or null when
  /// the current range already is that range / there is nothing to suggest.
  String? _suggestedRange(_Muscle m) {
    if (m.minutes == null || _cutoffModifier() == null) return null;
    final double days = (m.minutes! < 0 ? 0 : m.minutes!) / 1440.0;
    String s;
    if (days <= 29.5) {
      s = 'Last 30 days';
    } else if (days <= 89.5) {
      s = 'Last 90 days';
    } else {
      s = 'All time';
    }
    if (s == (widget.timeRange ?? '').trim()) s = 'All time';
    return s;
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final p = _MPal(context, widget.isDark ?? false);
    final bool rtl = _kRtl.contains(_lang);

    Widget body;
    if (_loadingMuscles) {
      body = Center(child: CircularProgressIndicator(color: p.th.primary));
    } else if (_muscles.isEmpty) {
      body = Center(
        child: Text(_tr(_lang, 'noGroups'),
            style: _ms(context, 14, FontWeight.w500, p.th.secondaryText)),
      );
    } else {
      final _Muscle? sel = _selected;
      final _Detail? d = _detail;
      final List<Widget> children = [
        _recoveryCard(context, p, sel),
        const SizedBox(height: 14),
      ];
      if (_loadingDetail || d == null || sel == null) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator(color: p.th.primary)),
        ));
      } else if (d.sets == 0) {
        children.add(_emptyCard(context, p, sel));
      } else {
        children.add(_volumeCard(context, p, sel, d));
        if (d.top.isNotEmpty) {
          children.add(const SizedBox(height: 14));
          children.add(_topCard(context, p, d));
        }
        // Only meaningful when the group actually splits into sub-muscles
        // (Chest -> just "Chest" = 100% says nothing).
        if (d.subs.length > 1) {
          children.add(const SizedBox(height: 14));
          children.add(_subCard(context, p, d));
        }
      }
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: children,
      );
    }

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: SizedBox(width: widget.width, height: widget.height, child: body),
    );
  }

  BoxDecoration _cardDeco(_MPal p, {bool strong = false}) {
    return BoxDecoration(
      color: p.th.secondaryBackground,
      borderRadius: BorderRadius.circular(22),
      border: p.dark ? Border.all(color: p.th.alternate) : null,
      boxShadow: p.dark
          ? null
          : [
              const BoxShadow(
                color: Color(0x0A101828),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
              if (strong)
                const BoxShadow(
                  color: Color(0x0F101828),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
            ],
    );
  }

  // ---------- recovery card ----------
  Widget _recoveryCard(BuildContext ctx, _MPal p, _Muscle? sel) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _cardDeco(p, strong: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(builder: (ctx2, c) {
            final double cellW = c.maxWidth / 5;
            return Wrap(
              children: [
                for (final m in _muscles)
                  SizedBox(
                    width: cellW,
                    child: _ringCell(ctx, p, m, m.id == _selectedId),
                  ),
              ],
            );
          }),
          if (sel != null) ...[
            const SizedBox(height: 8),
            _selectedPanel(ctx, p, sel),
          ],
        ],
      ),
    );
  }

  Widget _ringCell(BuildContext ctx, _MPal p, _Muscle m, bool selected) {
    final _Rec rec = _recOf(_lang, m.minutes, p.dark);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _select(m.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.only(top: 8, bottom: 7),
        decoration: BoxDecoration(
          color: selected ? p.cellSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RingPainter(
                        track: p.track,
                        color: rec.ring,
                        frac: rec.frac,
                      ),
                    ),
                  ),
                  if (rec.ready)
                    Icon(Icons.check_rounded, size: 16, color: p.th.primaryText)
                  else
                    Text(
                      rec.center,
                      style: _ms(ctx, 10, FontWeight.w700, p.th.primaryText),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                m.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: _ms(ctx, 11, FontWeight.w600, p.th.primaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectedPanel(BuildContext ctx, _MPal p, _Muscle m) {
    final _Rec rec = _recOf(_lang, m.minutes, p.dark);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.tint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  m.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _ms(ctx, 20, FontWeight.w700, p.tintInk, ls: -0.3),
                ),
                const SizedBox(height: 3),
                Text(
                  _lastTrainedText(_lang, m.minutes),
                  style: _ms(ctx, 13, FontWeight.w400, p.tintSub, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 5, 10, 5),
            decoration: BoxDecoration(
              color: p.chipBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: rec.ring,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(rec.label, style: _ms(ctx, 13, FontWeight.w700, rec.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- volume card ----------
  Widget _volumeCard(BuildContext ctx, _MPal p, _Muscle m, _Detail d) {
    String changeText = '–';
    Color changeColor = p.th.primaryText;
    if (d.changePct != null) {
      final double c = d.changePct!;
      if (c > 0.05) {
        changeText = '▲ ${_trim1(c)}%';
        changeColor = p.up;
      } else if (c < -0.05) {
        changeText = '▼ ${_trim1(c.abs())}%';
        changeColor = p.down;
      } else {
        changeText = '0%';
      }
    }
    final bool hasChart = d.sessionVolumes.length >= 2 && d.volume > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(p),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_tr(_lang, 'volumeOf', m: m.name),
              style: _ms(ctx, 16, FontWeight.w700, p.th.primaryText)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _tile(ctx, p, _tr(_lang, 'total'), _compact(d.volume),
                    unit: 'kg'),
              ),
              const SizedBox(width: 8),
              Expanded(child: _tile(ctx, p, _tr(_lang, 'sets'), '${d.sets}')),
              const SizedBox(width: 8),
              Expanded(
                child: _tile(ctx, p, _tr(_lang, 'change'), changeText,
                    valueColor: changeColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasChart) ...[
            // The chart is a time axis (oldest → newest); keep it LTR even in
            // Hebrew, like every chart in the app.
            Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Column(
                children: [
                  SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _VolChartPainter(
                        values: d.sessionVolumes,
                        line: p.accent,
                        fill: p.chartFill,
                        grid: p.track,
                        dotFill: p.th.secondaryBackground,
                        labelStyle:
                            _ms(ctx, 11, FontWeight.w400, p.th.secondaryText),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_mShortDate(_lang, d.firstDate),
                            style: _ms(
                                ctx, 11, FontWeight.w400, p.th.secondaryText)),
                        Text(_mShortDate(_lang, d.lastDate),
                            style: _ms(
                                ctx, 11, FontWeight.w400, p.th.secondaryText)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Text(
              d.volume <= 0
                  ? _tr(_lang, 'noWeightedSets')
                  : _tr(_lang, 'oneWorkout'),
              style: _ms(ctx, 13, FontWeight.w400, p.th.secondaryText,
                  height: 1.4),
            ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext ctx, _MPal p, String label, String value,
      {String? unit, Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.th.primaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _ms(ctx, 11, FontWeight.w500, p.th.secondaryText)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: _ms(ctx, 17, FontWeight.w700,
                        valueColor ?? p.th.primaryText),
                  ),
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: _ms(ctx, 12, FontWeight.w500, p.th.secondaryText),
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

  // ---------- top exercises ----------
  Widget _topCard(BuildContext ctx, _MPal p, _Detail d) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      decoration: _cardDeco(p),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_tr(_lang, 'topExercises'),
              style: _ms(ctx, 16, FontWeight.w700, p.th.primaryText)),
          const SizedBox(height: 6),
          for (int i = 0; i < d.top.length; i++) ...[
            if (i > 0) Divider(height: 1, color: p.th.alternate),
            _topRow(ctx, p, d.top[i]),
          ],
        ],
      ),
    );
  }

  Widget _topRow(BuildContext ctx, _MPal p, _TopEx e) {
    final bool rtl = _kRtl.contains(_lang);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onExerciseTap?.call(e.id, e.isPublic);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 40,
                height: 40,
                color: p.dark ? p.th.primaryBackground : Colors.white,
                child: ExerciseAssetImage(
                  width: 40,
                  height: 40,
                  exerciseName: exerciseImageName(e.nameEn),
                  borderRadius: 10,
                  illustration: e.illustration,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                e.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _ms(ctx, 15, FontWeight.w600, p.th.primaryText),
              ),
            ),
            const SizedBox(width: 8),
            Text(
                e.sets == 1
                    ? _tr(_lang, 'setsCount1', n: e.sets)
                    : _tr(_lang, 'setsCountN', n: e.sets),
                style: _ms(ctx, 13, FontWeight.w500, p.th.secondaryText)),
            const SizedBox(width: 4),
            Icon(rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                size: 18, color: p.th.secondaryText),
          ],
        ),
      ),
    );
  }

  // ---------- sub-muscle breakdown ----------
  Widget _subCard(BuildContext ctx, _MPal p, _Detail d) {
    int total = 0;
    for (final s in d.subs) {
      total += s.value;
    }
    final int safeTotal = total == 0 ? 1 : total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(p),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_tr(_lang, 'subBreakdown'),
              style: _ms(ctx, 16, FontWeight.w700, p.th.primaryText)),
          for (final s in d.subs) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _ms(ctx, 14, FontWeight.w500, p.th.primaryText),
                  ),
                ),
                Text('${(s.value * 100 / safeTotal).round()}%',
                    style: _ms(ctx, 14, FontWeight.w700, p.th.primaryText)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    Positioned.fill(child: Container(color: p.track)),
                    FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: (s.value / safeTotal).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: p.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------- empty (selected muscle has nothing in range) ----------
  Widget _emptyCard(BuildContext ctx, _MPal p, _Muscle m) {
    final String range = (widget.timeRange ?? '').trim();
    final String? suggested = _suggestedRange(m);

    String title, subtitle;
    if (m.minutes == null) {
      title = _tr(_lang, 'noDataFor', m: m.name);
      subtitle = _tr(_lang, 'logToSee', m: m.name);
    } else {
      title =
          _tr(_lang, 'noSetsInRange', m: m.name, r: _rangeLabel(_lang, range));
      subtitle = _tr(_lang, 'olderThanThat', m: m.name);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: _cardDeco(p),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: p.th.alternate,
              shape: BoxShape.circle,
            ),
            child: Icon(
              m.minutes == null
                  ? Icons.show_chart_rounded
                  : Icons.calendar_today_outlined,
              size: 26,
              color: p.th.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: _ms(ctx, 17, FontWeight.w700, p.th.primaryText)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: _ms(ctx, 14, FontWeight.w400, p.th.secondaryText,
                  height: 1.4)),
          if (m.minutes != null && suggested != null) ...[
            const SizedBox(height: 18),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onRangeChange?.call(suggested);
              },
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
                    Text(_tr(_lang, 'show', r: _rangeLabel(_lang, suggested)),
                        style: _ms(ctx, 14, FontWeight.w600, Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------

class _RingPainter extends CustomPainter {
  _RingPainter({required this.track, required this.color, required this.frac});

  final Color track, color;
  final double frac; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 4;
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = (math.min(size.width, size.height) - stroke) / 2;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (frac <= 0) return;
    // Keep a visible sliver for a muscle trained minutes ago.
    final double f = math.min(math.max(frac, 0.04), 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * f,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.frac != frac || old.color != color || old.track != track;
}

class _VolChartPainter extends CustomPainter {
  _VolChartPainter({
    required this.values,
    required this.line,
    required this.fill,
    required this.grid,
    required this.dotFill,
    required this.labelStyle,
  });

  final List<double> values;
  final Color line, fill, grid, dotFill;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    const double left = 36, right = 6, top = 8, bottom = 6;
    final Rect rect =
        Rect.fromLTRB(left, top, size.width - right, size.height - bottom);

    double maxV = 0;
    for (final v in values) {
      maxV = math.max(maxV, v);
    }
    if (maxV <= 0) maxV = 1;
    // Axis starts at 0 and ends on a round number (e.g. 0, 500, 1K).
    final double step = _mNiceStep(maxV, 3);
    final double axisMax = (maxV / step).ceilToDouble() * step;
    final int tickCount = (axisMax / step).round() + 1;

    final Paint gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (int i = 0; i < tickCount; i++) {
      final double value = step * i;
      final double y = rect.bottom - rect.height * (value / axisMax);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: _compact(value), style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(rect.left - 8 - tp.width, y - tp.height / 2));
    }

    final List<Offset> pts = [
      for (int i = 0; i < values.length; i++)
        Offset(
          rect.left + rect.width * i / (values.length - 1),
          rect.bottom - rect.height * (values[i] / axisMax),
        ),
    ];
    final Path linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      linePath.lineTo(pts[i].dx, pts[i].dy);
    }
    final Path area = Path.from(linePath)
      ..lineTo(pts.last.dx, rect.bottom)
      ..lineTo(pts.first.dx, rect.bottom)
      ..close();

    canvas.drawPath(area, Paint()..color = fill);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(pts.last, 4, Paint()..color = dotFill);
    canvas.drawCircle(
      pts.last,
      4,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _VolChartPainter old) =>
      old.values != values || old.line != line || old.fill != fill;
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
