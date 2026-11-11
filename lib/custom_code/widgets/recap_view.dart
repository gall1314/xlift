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

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl show DateFormat, NumberFormat;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Story-style training recap: full-screen slides that play like a story -
/// intro, consistency, total volume, most trained exercise, muscle focus,
/// AI form, personal records and a share card.
///
/// Fully self-managed: reads workout_log / set_log / set_analysis / exercise
/// and the muscle tables itself (four plain SELECTs, everything else is
/// computed in Dart). No FlutterFlow query needed. Reloads when [userId],
/// [timeRange], [demoMode] or the app language changes.
///
/// Use it as the only widget of a page (width and height = infinity). The
/// look is always dark, like the paywall and the workout poster.
///
/// [timeRange]: 'Last 7 days' | 'Last 30 days' (default) | 'Last 90 days' |
/// 'This month' | 'This year'; anything else ('All time') means no limit.
/// [demoMode]: true shows built-in sample data (previews, screenshots).
/// [onClose]: fired by the X button and by "Done" on the last slide.
///
/// Gestures: tap the leading 30% = back, anywhere else = next, hold = pause.
/// Share renders the summary card to a PNG (3x) and opens the share sheet.
///
/// Localization: reads the app language from FFLocalizations (no parameter).
/// Exercise and muscle names come from the DB through localizedName; Hebrew
/// renders RTL (numbers and charts stay LTR).
class RecapView extends StatefulWidget {
  const RecapView({
    super.key,
    this.width,
    this.height,
    required this.userId,
    this.timeRange,
    this.demoMode,
    this.onClose,
  });

  final double? width;
  final double? height;
  final String userId;
  final String? timeRange;
  final bool? demoMode;
  final Future Function()? onClose;

  @override
  State<RecapView> createState() => _RecapViewState();
}

/// Shown in the header and on the share card. Change it once the final app
/// name is chosen.
const String _kBrand = 'XLIFT';

// Design stage: everything is laid out on a 390 x H canvas and scaled.
const double _kW = 390;
const double _kMinH = 620;
const Color _kBg0 = Color(0xFF071413);
const Color _kBg1 = Color(0xFF030807);
const Color _kDeep = Color(0xFF0C1F1D);
const Color _kOnAccent = Color(0xFF042F2E);
const Color _kUp = Color(0xFF86EFAC);

// ---------------------------------------------------------------------------
// Localization
// ---------------------------------------------------------------------------

const Set<String> _kRtl = {'he', 'ar'};
const List<String> _kLangs = ['en', 'es', 'he', 'de', 'fr'];

String _langOf(BuildContext ctx) {
  try {
    final l = FFLocalizations.of(ctx).languageCode.trim().toLowerCase();
    return l.isEmpty ? 'en' : l;
  } catch (_) {
    return 'en';
  }
}

/// Order: en, es, he, de, fr. {n} {s} numbers, {m} muscle name.
const Map<String, List<String>> _kS = {
  "introTitle": [
    "Your training recap",
    "Tu resumen de entreno",
    "סיכום האימונים שלך",
    "Dein Trainingsrückblick",
    "Votre bilan sportif"
  ],
  "tapNext": [
    "Tap to continue",
    "Toca para continuar",
    "הקישו להמשך",
    "Tippen zum Fortfahren",
    "Touchez pour continuer"
  ],
  "days": ["DAYS", "DÍAS", "ימים", "TAGE", "JOURS"],
  "year": ["YEAR", "AÑO", "שנה", "JAHR", "ANNÉE"],
  "allTime": ["ALL TIME", "HISTORIAL", "כל הזמן", "GESAMT", "TOUT"],
  "range7": [
    "Last 7 days",
    "Últimos 7 días",
    "7 הימים האחרונים",
    "Letzte 7 Tage",
    "7 derniers jours"
  ],
  "range30": [
    "Last 30 days",
    "Últimos 30 días",
    "30 הימים האחרונים",
    "Letzte 30 Tage",
    "30 derniers jours"
  ],
  "range90": [
    "Last 90 days",
    "Últimos 90 días",
    "90 הימים האחרונים",
    "Letzte 90 Tage",
    "90 derniers jours"
  ],
  "rangeAll": [
    "All time",
    "Todo el historial",
    "כל הזמן",
    "Gesamter Zeitraum",
    "Depuis le début"
  ],
  "consistency": [
    "CONSISTENCY",
    "CONSTANCIA",
    "התמדה",
    "KONSTANZ",
    "RÉGULARITÉ"
  ],
  "workouts": [
    "workouts",
    "entrenamientos",
    "אימונים",
    "Workouts",
    "entraînements"
  ],
  "workout1": ["workout", "entrenamiento", "אימון", "Workout", "entraînement"],
  "hoursTrained": ["Hours trained", "Horas", "שעות אימון", "Stunden", "Heures"],
  "perWeek": ["Per week", "Por semana", "בשבוע", "Pro Woche", "Par semaine"],
  "topDay": ["Top day", "Día top", "היום החזק", "Top-Tag", "Jour fort"],
  "volume": [
    "TOTAL VOLUME",
    "VOLUMEN TOTAL",
    "נפח כולל",
    "GESAMTVOLUMEN",
    "VOLUME TOTAL"
  ],
  "volSub": [
    "lifted across {n} sets",
    "en {n} series",
    "ב-{n} סטים",
    "in {n} Sätzen",
    "en {n} séries"
  ],
  "volLike": [
    "THAT'S LIKE LIFTING",
    "ES COMO LEVANTAR",
    "זה כמו להרים",
    "SO VIEL WIE",
    "L'ÉQUIVALENT DE"
  ],
  "objMoto": ["motorcycles", "motos", "אופנועים", "Motorräder", "motos"],
  "objPiano": [
    "grand pianos",
    "pianos de cola",
    "פסנתרי כנף",
    "Konzertflügel",
    "pianos à queue"
  ],
  "objCar": ["cars", "coches", "מכוניות", "Autos", "voitures"],
  "objBus": ["city buses", "autobuses", "אוטובוסים", "Linienbusse", "bus"],
  "objJet": [
    "passenger jets",
    "aviones",
    "מטוסי נוסעים",
    "Passagierjets",
    "avions de ligne"
  ],
  "objLoco": [
    "locomotives",
    "locomotoras",
    "קטרים",
    "Lokomotiven",
    "locomotives"
  ],
  "objRocket": [
    "Falcon 9 rockets",
    "cohetes Falcon 9",
    "טילי פאלקון 9",
    "Falcon-9-Raketen",
    "fusées Falcon 9"
  ],
  "sets": ["Sets", "Series", "סטים", "Sätze", "Séries"],
  "reps": ["Reps", "Reps", "חזרות", "Wdh.", "Reps"],
  "heaviest": ["Heaviest", "Más pesado", "הכי כבד", "Schwerstes", "Plus lourd"],
  "mostTrained": [
    "MOST TRAINED",
    "MÁS ENTRENADO",
    "התרגיל המוביל",
    "MEIST TRAINIERT",
    "LE PLUS TRAVAILLÉ"
  ],
  "setsSessions": [
    "{n} sets · {s} sessions",
    "{n} series · {s} sesiones",
    "{n} סטים · {s} אימונים",
    "{n} Sätze · {s} Einheiten",
    "{n} séries · {s} séances"
  ],
  "bestSet": [
    "Best set",
    "Mejor serie",
    "סט הכי טוב",
    "Bester Satz",
    "Meilleure série"
  ],
  "nSets": ["{n} sets", "{n} series", "{n} סטים", "{n} Sätze", "{n} séries"],
  "bw": ["BW × {n}", "PC × {n}", "משקל גוף × {n}", "KG × {n}", "PDC × {n}"],
  "repsN": ["{n} reps", "{n} reps", "{n} חזרות", "{n} Wdh.", "{n} reps"],
  "muscleFocus": [
    "MUSCLE FOCUS",
    "ENFOQUE MUSCULAR",
    "מיקוד שרירים",
    "MUSKELFOKUS",
    "FOCUS MUSCULAIRE"
  ],
  "mostly": [
    "Mostly {m}",
    "Sobre todo {m}",
    "בעיקר {m}",
    "Vor allem {m}",
    "Surtout {m}"
  ],
  "aiForm": [
    "AI FORM",
    "TÉCNICA IA",
    "טכניקה AI",
    "KI-TECHNIK",
    "TECHNIQUE IA"
  ],
  "formA": [
    "Textbook form",
    "Técnica de manual",
    "טכניקה מהספר",
    "Technik wie im Lehrbuch",
    "Technique d'école"
  ],
  "formB": [
    "Clean reps",
    "Reps limpias",
    "חזרות נקיות",
    "Saubere Wdh.",
    "Reps propres"
  ],
  "formC": [
    "Getting sharper",
    "Cada vez mejor",
    "משתפרים מסט לסט",
    "Wird immer sauberer",
    "De mieux en mieux"
  ],
  "setsChecked": [
    "Sets checked",
    "Series analizadas",
    "סטים שנבדקו",
    "Geprüfte Sätze",
    "Séries analysées"
  ],
  "perfectReps": [
    "Perfect reps",
    "Reps perfectas",
    "חזרות מושלמות",
    "Perfekte Wdh.",
    "Reps parfaites"
  ],
  "bestScore": [
    "Best score",
    "Mejor nota",
    "הציון הגבוה",
    "Bestwert",
    "Meilleure note"
  ],
  "formEmptyT": [
    "No form checks yet",
    "Aún sin análisis",
    "עדיין אין בדיקות טכניקה",
    "Noch keine Technik-Checks",
    "Pas encore d'analyse"
  ],
  "formEmptyS": [
    "Film a set and get a score for every rep.",
    "Graba una serie y recibe una nota por cada rep.",
    "צלמו סט וקבלו ציון על כל חזרה.",
    "Filme einen Satz und erhalte eine Note pro Wdh.",
    "Filmez une série et obtenez une note par rep."
  ],
  "records": [
    "PERSONAL RECORDS",
    "RÉCORDS PERSONALES",
    "שיאים אישיים",
    "PERSÖNLICHE REKORDE",
    "RECORDS PERSONNELS"
  ],
  "newRecords": [
    "new records",
    "nuevos récords",
    "שיאים חדשים",
    "neue Rekorde",
    "nouveaux records"
  ],
  "newRecord1": [
    "new record",
    "nuevo récord",
    "שיא חדש",
    "neuer Rekord",
    "nouveau record"
  ],
  "est1rm": ["est. 1RM", "1RM est.", "1RM משוער", "gesch. 1RM", "1RM est."],
  "mode": [
    "YOUR TRAINING MODE",
    "TU MODO DE ENTRENO",
    "מצב האימון שלך",
    "DEIN TRAININGSMODUS",
    "VOTRE MODE D'ENTRAÎNEMENT"
  ],
  "mMachine": [
    "Machine mode",
    "Modo máquina",
    "מצב מכונה",
    "Maschinenmodus",
    "Mode machine"
  ],
  "mPr": [
    "PR season",
    "Temporada de récords",
    "עונת השיאים",
    "Rekordsaison",
    "Saison des records"
  ],
  "mPrecision": [
    "Pure precision",
    "Precisión pura",
    "דיוק טהור",
    "Pure Präzision",
    "Précision pure"
  ],
  "mHeavy": [
    "Heavy duty",
    "Carga pesada",
    "עומסים כבדים",
    "Schwere Lasten",
    "Charges lourdes"
  ],
  "mFocus": [
    "{m} first",
    "{m} primero",
    "קודם כל {m}",
    "{m} zuerst",
    "{m} d'abord"
  ],
  "mSteady": [
    "Steady builder",
    "Paso firme",
    "בנייה יציבה",
    "Stetiger Aufbau",
    "Progression régulière"
  ],
  "mStarter": [
    "Just getting started",
    "Esto recién empieza",
    "זו רק ההתחלה",
    "Erst der Anfang",
    "Ce n'est que le début"
  ],
  "cWorkouts": ["Workouts", "Entrenos", "אימונים", "Workouts", "Séances"],
  "cVolume": ["Volume", "Volumen", "נפח", "Volumen", "Volume"],
  "cHours": ["Hours", "Horas", "שעות", "Stunden", "Heures"],
  "cForm": ["AI form", "Técnica IA", "טכניקה AI", "KI-Technik", "Technique IA"],
  "cTopLift": [
    "#1 lift",
    "Ejercicio #1",
    "תרגיל מוביל",
    "Übung Nr. 1",
    "Exercice n°1"
  ],
  "cFocus": ["Focus", "Enfoque", "מיקוד", "Fokus", "Focus"],
  "share": ["Share", "Compartir", "שיתוף", "Teilen", "Partager"],
  "done": ["Done", "Listo", "סיום", "Fertig", "Terminé"],
  "shareText": [
    "My training recap",
    "Mi resumen de entreno",
    "סיכום האימונים שלי",
    "Mein Trainingsrückblick",
    "Mon bilan sportif"
  ],
  "emptyT": [
    "Nothing to recap yet",
    "Aún no hay nada que resumir",
    "עדיין אין מה לסכם",
    "Noch nichts zum Zusammenfassen",
    "Rien à résumer pour l'instant"
  ],
  "emptyS": [
    "Finish a workout and your recap will show up here.",
    "Termina un entrenamiento y tu resumen aparecerá aquí.",
    "סיימו אימון והסיכום יופיע כאן.",
    "Beende ein Workout und dein Rückblick erscheint hier.",
    "Terminez un entraînement et votre bilan apparaîtra ici."
  ],
};

String _tr(String lang, String key, {String? n, String? s, String? m}) {
  final List<String>? row = _kS[key];
  final int i = _kLangs.indexOf(lang);
  String out = row == null ? key : row[i < 0 ? 0 : i];
  if (n != null) out = out.replaceAll('{n}', n);
  if (s != null) out = out.replaceAll('{s}', s);
  if (m != null) out = out.replaceAll('{m}', m);
  return out;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

int _toI(dynamic v, [int d = 0]) {
  if (v == null) return d;
  if (v is int) return v;
  if (v is num) return v.round();
  return num.tryParse(v.toString())?.round() ?? d;
}

double? _toD(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  final s = v.toString().trim();
  return s.isEmpty ? null : double.tryParse(s);
}

DateTime? _parseDt(dynamic raw) {
  final s = (raw ?? '').toString().trim();
  if (s.isEmpty) return null;
  final parsed = DateTime.tryParse(s);
  if (parsed == null) return null;
  return parsed.isUtc ? parsed.toLocal() : parsed;
}

Color _op(Color c, double o) => c.withAlpha((_c01(o) * 255).round());

double _c01(double v) => v < 0 ? 0.0 : (v > 1 ? 1.0 : v);

double _eo3(double p) => 1.0 - math.pow(1.0 - p, 3).toDouble();

double _back(double p) {
  const double c1 = 1.70158;
  const double c3 = c1 + 1;
  return 1.0 +
      c3 * math.pow(p - 1, 3).toDouble() +
      c1 * math.pow(p - 1, 2).toDouble();
}

/// Ease-out entrance progress (0..1) for an element that starts at [d] s.
double _ent(double t, double d, [double dur = 0.6]) =>
    _eo3(_c01((t - d) / dur));

/// Same with a small overshoot (0 before it starts).
double _pop(double t, double d, [double dur = 0.5]) {
  final double p = _c01((t - d) / dur);
  return p <= 0 ? 0.0 : _back(p);
}

String _fmtInt(String lang, num v) {
  try {
    return intl.NumberFormat.decimalPattern(lang).format(v.round());
  } catch (_) {
    return v.round().toString();
  }
}

/// Up to one decimal: 140, 102.5.
String _fmtNum(String lang, double v) {
  final double r = (v * 10).round() / 10;
  try {
    return intl.NumberFormat('#,##0.#', lang).format(r);
  } catch (_) {
    return r == r.roundToDouble() ? r.toInt().toString() : r.toStringAsFixed(1);
  }
}

/// Always one decimal: 8.7, 9.0.
String _fmt1(String lang, double v) {
  try {
    return intl.NumberFormat('0.0', lang).format(v);
  } catch (_) {
    return v.toStringAsFixed(1);
  }
}

String _fmtHM(int minutes) =>
    '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';

/// [skeleton] is an intl skeleton: MMMd, yMMM, yMMMM, MMM, EEEE.
String _date(String lang, String skeleton, DateTime d) {
  try {
    return intl.DateFormat(skeleton, lang).format(d);
  } catch (_) {
    return intl.DateFormat(skeleton).format(d);
  }
}

int _dayIndex(DateTime from, DateTime d) =>
    (DateTime(d.year, d.month, d.day).difference(from).inHours / 24).round();

TextStyle _xs(BuildContext ctx, double size, FontWeight w, Color c,
    {double ls = 0, double? height}) {
  final th = FlutterFlowTheme.of(ctx);
  return th.bodyMedium
      .override(
    fontFamily: th.bodyMediumFamily,
    color: c,
    fontSize: size,
    fontWeight: w,
    letterSpacing: ls,
    lineHeight: height,
    useGoogleFonts: GoogleFonts.asMap().containsKey(th.bodyMediumFamily),
  )
      .copyWith(
    fontFeatures: const [ui.FontFeature.tabularFigures()],
    leadingDistribution: TextLeadingDistribution.even,
  );
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

class _Obj {
  const _Obj(this.icon, this.kg, this.key);
  final IconData icon;
  final double kg;
  final String key;
}

/// Things the lifted volume is compared to, lightest first.
const List<_Obj> _kObj = [
  _Obj(Icons.two_wheeler_rounded, 200, 'objMoto'),
  _Obj(Icons.piano_rounded, 450, 'objPiano'),
  _Obj(Icons.directions_car_rounded, 1500, 'objCar'),
  _Obj(Icons.directions_bus_rounded, 12000, 'objBus'),
  _Obj(Icons.flight_rounded, 41000, 'objJet'),
  _Obj(Icons.train_rounded, 120000, 'objLoco'),
  _Obj(Icons.rocket_launch_rounded, 549000, 'objRocket'),
];

class _TopEx {
  _TopEx(this.name, this.nameEn, this.illustration, this.sets, this.sessions,
      this.best);
  final String name; // localized
  final String nameEn; // English (image lookup)
  final String? illustration;
  final int sets, sessions;
  final String best; // "120 kg × 5", "BW × 12", "1:30" or ''
}

class _Mus {
  _Mus(this.name, this.share);
  final String name;
  final double share; // 0..1 of the period's sets
}

class _FormEx {
  _FormEx(this.name, this.score);
  final String name;
  final double score;
}

class _Pr {
  _Pr(this.name, this.value, this.delta, this.gain);
  final String name;
  final double value, delta, gain; // kg est. 1RM, kg gained, relative gain
}

class _Recap {
  _Recap({
    required this.rangeKey,
    required this.from,
    required this.today,
    required this.spanDays,
    required this.workouts,
    required this.totalMin,
    required this.cells,
    required this.rows,
    required this.bars,
    required this.perWeek,
    required this.topWeekday,
    required this.volume,
    required this.sets,
    required this.reps,
    required this.heaviest,
    required this.top,
    required this.muscles,
    required this.formAvg,
    required this.formSets,
    required this.formPerfect,
    required this.formBest,
    required this.formByEx,
    required this.prs,
  });

  final String rangeKey;
  final DateTime from, today;
  final int spanDays;
  final int workouts, totalMin;

  /// Calendar (short ranges): one entry per day cell, Monday first.
  /// 0 = outside the range, 1 = rest day, 2 = trained. Empty in bars mode.
  final List<int> cells;
  final int rows;

  /// Long ranges: workouts per week (or per bucket). Empty in calendar mode.
  final List<int> bars;
  final double perWeek;
  final int topWeekday; // 1 = Monday .. 7 = Sunday, 0 = none
  final double volume; // kg
  final int sets, reps;
  final double heaviest; // kg
  final List<_TopEx> top;
  final List<_Mus> muscles;
  final double? formAvg; // null = no analysis in the period
  final int formSets, formPerfect;
  final double formBest;
  final List<_FormEx> formByEx;
  final List<_Pr> prs;

  int get objIdx {
    int best = 0;
    for (int i = 0; i < _kObj.length; i++) {
      if (volume / _kObj[i].kg >= 2) best = i;
    }
    return best;
  }

  int get objN => (volume / _kObj[objIdx].kg).round();

  String get mode {
    if (workouts < 3) return 'mStarter';
    if (prs.length >= 3) return 'mPr';
    if ((formAvg ?? 0.0) >= 9 && formSets >= 5) return 'mPrecision';
    if (perWeek >= 4) return 'mMachine';
    if (muscles.isNotEmpty && muscles.first.share >= 0.4) return 'mFocus';
    if (workouts > 0 && volume / workouts >= 9000) return 'mHeavy';
    return 'mSteady';
  }
}

/// Builds the calendar cells (up to 6 weeks) or the weekly bars.
class _Cal {
  _Cal(DateTime from, int spanDays, Map<int, int> dayCount) {
    final int dow = from.weekday - 1; // Monday = 0
    rows = ((dow + spanDays) / 7).ceil();
    if (rows <= 6) {
      for (int i = 0; i < rows * 7; i++) {
        final int k = i - dow;
        cells
            .add(k < 0 || k >= spanDays ? 0 : ((dayCount[k] ?? 0) > 0 ? 2 : 1));
      }
    } else {
      final int bucket = rows <= 53 ? 7 : (spanDays / 52).ceil();
      final int n = (spanDays / bucket).ceil();
      for (int i = 0; i < n; i++) {
        bars.add(0);
      }
      for (final e in dayCount.entries) {
        final int b = e.key ~/ bucket;
        if (e.key >= 0 && b < n) bars[b] += e.value;
      }
    }
  }

  final List<int> cells = [];
  final List<int> bars = [];
  int rows = 0;
}

int _topWeekday(List<int> wd) {
  int top = 0;
  for (int i = 1; i <= 7; i++) {
    if (wd[i] > 0 && (top == 0 || wd[i] > wd[top])) top = i;
  }
  return top;
}

DateTime? _rangeStart(String key, DateTime today) {
  switch (key) {
    case 'Last 7 days':
      return DateTime(today.year, today.month, today.day - 6);
    case 'Last 30 days':
      return DateTime(today.year, today.month, today.day - 29);
    case 'Last 90 days':
      return DateTime(today.year, today.month, today.day - 89);
    case 'This month':
      return DateTime(today.year, today.month, 1);
    case 'This year':
      return DateTime(today.year, 1, 1);
    default:
      return null; // All time
  }
}

class _ExAgg {
  _ExAgg(this.rawName, this.illustration, this.assisted);
  final String rawName;
  final String? illustration;
  final bool assisted;
  int sets = 0;
  final Set<String> sessions = <String>{};
  double best1rm = 0; // kg, inside the period
  String bestWeighted = '';
  int bestReps = 0;
  double bestDur = 0; // seconds
  double before1rm = 0; // kg, before the period
  double formSum = 0;
  int formN = 0;
}

String _bestLabel(String lang, _ExAgg a) {
  if (a.bestWeighted.isNotEmpty) return a.bestWeighted;
  if (a.bestReps > 0) {
    final String n = a.bestReps.toString();
    return a.assisted ? _tr(lang, 'repsN', n: n) : _tr(lang, 'bw', n: n);
  }
  if (a.bestDur > 0) {
    final int s = a.bestDur.round();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }
  return '';
}

Future<_Recap> _loadRecap(String userId, String rangeKey, String lang) async {
  final db = SQLiteManager.instance.database;
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime? start = _rangeStart(rangeKey, today);

  List<Map<String, Object?>> wRows = const [];
  List<Map<String, Object?>> sRows = const [];
  List<Map<String, Object?>> mRows = const [];
  List<Map<String, Object?>> aRows = const [];
  try {
    wRows = await db.rawQuery(
      'SELECT id, created_at, duration_seconds, volume '
      'FROM workout_log WHERE user_id = ?',
      [userId],
    );
  } catch (_) {}
  try {
    sRows = await db.rawQuery(
      'SELECT sl.id AS id, sl.exercise_id AS exercise_id, '
      'sl.workout_log_id AS workout_log_id, sl.reps AS reps, '
      'sl.weight AS weight, sl.is_kg AS is_kg, '
      'sl.duration_seconds AS duration_seconds, '
      'COALESCE(sl.is_dropset, 0) AS is_dropset, '
      'e.name AS exercise_name, '
      'COALESCE(e.illustration, e.no_video_ilustration) AS illustration, '
      'COALESCE(e.is_assisted, 0) AS is_assisted '
      'FROM set_log sl '
      'JOIN workout_log wl ON wl.id = sl.workout_log_id '
      'JOIN exercise e ON e.id = sl.exercise_id '
      'WHERE wl.user_id = ?',
      [userId],
    );
  } catch (_) {}
  try {
    mRows = await db.rawQuery(
      'SELECT emg.exercise_id AS exercise_id, pmg.id AS gid, '
      'pmg.name AS gname '
      'FROM exercise_muscle_group emg '
      'JOIN muscle_group mg ON mg.id = emg.muscle_group_id '
      'JOIN primary_muscle_group pmg ON pmg.id = mg.primary_muscle_group_id '
      'WHERE COALESCE(emg.is_primary, 0) = 1',
    );
  } catch (_) {}
  try {
    aRows = await db.rawQuery(
      'SELECT sa.set_log_id AS set_log_id, sa.score AS score, '
      'sa.proper_reps AS proper_reps '
      'FROM set_analysis sa '
      'JOIN set_log sl ON sl.id = sa.set_log_id '
      'JOIN workout_log wl ON wl.id = sl.workout_log_id '
      'WHERE wl.user_id = ? AND sa.score IS NOT NULL',
      [userId],
    );
  } catch (_) {}

  // ---- workouts ----
  final Map<String, DateTime> logDate = {};
  final Map<String, double> logVol = {};
  final Map<String, double> logMs = {};
  DateTime? first;
  for (final r in wRows) {
    final String id = (r['id'] ?? '').toString();
    final DateTime? dt = _parseDt(r['created_at']);
    if (id.isEmpty || dt == null) continue;
    logDate[id] = dt;
    logVol[id] = _toD(r['volume']) ?? 0.0;
    logMs[id] = _toD(r['duration_seconds']) ?? 0.0; // stored in milliseconds
    if (first == null || dt.isBefore(first)) first = dt;
  }
  final DateTime from = start ??
      (first == null ? today : DateTime(first.year, first.month, first.day));
  final int spanDays = math.max(1, _dayIndex(from, today) + 1);

  int workouts = 0;
  double totalMs = 0;
  final Map<int, int> dayCount = {};
  final List<int> wd = List<int>.filled(8, 0);
  final Set<String> inLogs = <String>{};
  for (final e in logDate.entries) {
    if (e.value.isBefore(from)) continue;
    inLogs.add(e.key);
    workouts++;
    totalMs += logMs[e.key] ?? 0.0;
    final int k = _dayIndex(from, e.value);
    dayCount[k] = (dayCount[k] ?? 0) + 1;
    wd[e.value.weekday]++;
  }

  // ---- sets ----
  final Map<int, _ExAgg> ex = {};
  final Map<String, int> setEx = {}; // set_log id -> exercise id (period)
  final Map<String, double> calcVol = {}; // workout_log id -> computed kg
  int sets = 0, reps = 0;
  double heaviest = 0;
  for (final r in sRows) {
    final String wid = (r['workout_log_id'] ?? '').toString();
    final DateTime? dt = logDate[wid];
    if (dt == null) continue;
    final int exId = _toI(r['exercise_id']);
    final bool assisted = _toI(r['is_assisted']) == 1;
    final bool drop = _toI(r['is_dropset']) == 1;
    final int rp = _toI(r['reps']);
    final double wRaw = _toD(r['weight']) ?? 0.0;
    final double w = _toI(r['is_kg'], 1) == 1 ? wRaw : wRaw * 0.453592;
    final double durSec = (_toD(r['duration_seconds']) ?? 0.0) / 1000.0;
    final bool weighted = !assisted && w > 0 && rp > 0;
    // Epley, same as the Stats tab.
    final double orm = weighted ? (rp == 1 ? w : w * (1 + rp / 30.0)) : 0.0;

    _ExAgg? a = ex[exId];
    if (a == null) {
      final String ill = (r['illustration'] ?? '').toString().trim();
      a = _ExAgg(
        (r['exercise_name'] ?? '').toString(),
        (ill.isEmpty || ill == 'null') ? null : ill,
        assisted,
      );
      ex[exId] = a;
    }

    if (dt.isBefore(from)) {
      if (!drop && orm > a.before1rm) a.before1rm = orm;
      continue;
    }
    if (rp > 0) reps += rp;
    if (weighted) {
      calcVol[wid] = (calcVol[wid] ?? 0.0) + w * rp;
      if (w > heaviest) heaviest = w;
    }
    if (drop) continue;
    sets++;
    a.sets++;
    a.sessions.add(wid);
    setEx[(r['id'] ?? '').toString()] = exId;
    if (weighted && orm > a.best1rm) {
      a.best1rm = orm;
      a.bestWeighted = '${_fmtNum(lang, w)} kg × $rp';
    }
    if (rp > a.bestReps) a.bestReps = rp;
    if (durSec > a.bestDur) a.bestDur = durSec;
  }

  // Volume: the saved workout volume, or the sets when a log has none.
  double volume = 0;
  for (final id in inLogs) {
    final double v = logVol[id] ?? 0.0;
    volume += v > 0 ? v : (calcVol[id] ?? 0.0);
  }

  // ---- most trained ----
  final List<MapEntry<int, _ExAgg>> ranked =
      ex.entries.where((e) => e.value.sets > 0).toList();
  ranked.sort((x, y) {
    final int c = y.value.sets.compareTo(x.value.sets);
    return c != 0
        ? c
        : y.value.sessions.length.compareTo(x.value.sessions.length);
  });
  final List<_TopEx> top = [];
  for (final e in ranked.take(3)) {
    final _ExAgg a = e.value;
    top.add(_TopEx(
      localizedName(a.rawName, lang),
      localizedName(a.rawName, 'en'),
      a.illustration,
      a.sets,
      a.sessions.length,
      _bestLabel(lang, a),
    ));
  }

  // ---- muscles (primary muscle categories, by sets) ----
  final Map<int, List<int>> exGroups = {};
  final Map<int, String> gName = {};
  for (final r in mRows) {
    final int e = _toI(r['exercise_id']);
    final int g = _toI(r['gid']);
    gName[g] = (r['gname'] ?? '').toString();
    final List<int> l = exGroups.putIfAbsent(e, () => <int>[]);
    if (!l.contains(g)) l.add(g);
  }
  final Map<int, int> gCount = {};
  int gTotal = 0;
  for (final e in ex.entries) {
    if (e.value.sets == 0) continue;
    for (final g in exGroups[e.key] ?? const <int>[]) {
      gCount[g] = (gCount[g] ?? 0) + e.value.sets;
      gTotal += e.value.sets;
    }
  }
  final List<MapEntry<int, int>> gs = gCount.entries.toList();
  gs.sort((x, y) => y.value.compareTo(x.value));
  final List<_Mus> muscles = [];
  for (final g in gs.take(7)) {
    muscles
        .add(_Mus(localizedName(gName[g.key] ?? '', lang), g.value / gTotal));
  }

  // ---- AI form ----
  double fSum = 0, fBest = 0;
  int fN = 0, perfect = 0;
  final Set<String> seen = <String>{};
  for (final r in aRows) {
    final String sid = (r['set_log_id'] ?? '').toString();
    final int? exId = setEx[sid];
    final double sc = _toD(r['score']) ?? 0.0;
    if (exId == null || sc <= 0 || !seen.add(sid)) continue;
    fSum += sc;
    fN++;
    perfect += _toI(r['proper_reps']);
    if (sc > fBest) fBest = sc;
    final _ExAgg? a = ex[exId];
    if (a != null) {
      a.formSum += sc;
      a.formN++;
    }
  }
  final List<_ExAgg> fe = ex.values.where((a) => a.formN > 0).toList();
  fe.sort((x, y) => (y.formSum / y.formN).compareTo(x.formSum / x.formN));
  final List<_FormEx> formByEx = [];
  for (final a in fe.take(3)) {
    formByEx.add(_FormEx(localizedName(a.rawName, lang), a.formSum / a.formN));
  }

  // ---- personal records: best est. 1RM in the period vs. before it ----
  final List<_Pr> prs = [];
  if (start != null) {
    for (final a in ex.values) {
      if (a.before1rm > 0 && a.best1rm > a.before1rm * 1.001) {
        prs.add(_Pr(
          localizedName(a.rawName, lang),
          a.best1rm,
          a.best1rm - a.before1rm,
          (a.best1rm - a.before1rm) / a.before1rm,
        ));
      }
    }
    prs.sort((x, y) => y.gain.compareTo(x.gain));
  }

  final _Cal cal = _Cal(from, spanDays, dayCount);
  return _Recap(
    rangeKey: rangeKey,
    from: from,
    today: today,
    spanDays: spanDays,
    workouts: workouts,
    totalMin: (totalMs / 60000).round(),
    cells: cal.cells,
    rows: cal.rows,
    bars: cal.bars,
    perWeek: workouts / math.max(1.0, spanDays / 7.0),
    topWeekday: _topWeekday(wd),
    volume: volume,
    sets: sets,
    reps: reps,
    heaviest: heaviest,
    top: top,
    muscles: muscles,
    formAvg: fN > 0 ? fSum / fN : null,
    formSets: fN,
    formPerfect: perfect,
    formBest: fBest,
    formByEx: formByEx,
    prs: prs,
  );
}

/// Sample data for [RecapView.demoMode].
_Recap _demoRecap(String lang) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  const int span = 30;
  final DateTime from = DateTime(today.year, today.month, today.day - 29);
  const List<int> ago = [0, 2, 3, 5, 7, 9, 10, 12, 14, 16, 19, 21, 24, 27];
  final Map<int, int> dayCount = {};
  final List<int> wd = List<int>.filled(8, 0);
  for (final a in ago) {
    dayCount[span - 1 - a] = 1;
    wd[DateTime(today.year, today.month, today.day - a).weekday]++;
  }
  final int li = math.max(0, _kLangs.indexOf(lang));
  String m(List<String> names) => names[li];
  final _Cal cal = _Cal(from, span, dayCount);
  return _Recap(
    rangeKey: 'Last 30 days',
    from: from,
    today: today,
    spanDays: span,
    workouts: ago.length,
    totalMin: 940,
    cells: cal.cells,
    rows: cal.rows,
    bars: cal.bars,
    perWeek: ago.length / (span / 7.0),
    topWeekday: _topWeekday(wd),
    volume: 128450,
    sets: 312,
    reps: 2940,
    heaviest: 140,
    top: [
      _TopEx('Barbell Squat', 'Barbell Squat', null, 24, 6, '120 kg × 5'),
      _TopEx('Bench Press', 'Bench Press', null, 21, 5, '85 kg × 6'),
      _TopEx('Pull-up', 'Pull-up', null, 18, 5, _tr(lang, 'bw', n: '12')),
    ],
    muscles: [
      _Mus(m(const ['Legs', 'Piernas', 'רגליים', 'Beine', 'Jambes']), 0.34),
      _Mus(m(const ['Back', 'Espalda', 'גב', 'Rücken', 'Dos']), 0.22),
      _Mus(m(const ['Chest', 'Pecho', 'חזה', 'Brust', 'Pectoraux']), 0.18),
      _Mus(m(const ['Shoulders', 'Hombros', 'כתפיים', 'Schultern', 'Épaules']),
          0.11),
      _Mus(m(const ['Biceps', 'Bíceps', 'יד קדמית', 'Bizeps', 'Biceps']), 0.06),
      _Mus(m(const ['Triceps', 'Tríceps', 'יד אחורית', 'Trizeps', 'Triceps']),
          0.05),
      _Mus(m(const ['Core', 'Core', 'בטן', 'Core', 'Abdos']), 0.04),
    ],
    formAvg: 8.7,
    formSets: 18,
    formPerfect: 86,
    formBest: 9.6,
    formByEx: [
      _FormEx('Barbell Squat', 9.2),
      _FormEx('Deadlift', 8.8),
      _FormEx('Pull-up', 8.1),
    ],
    prs: [
      _Pr('Barbell Squat', 140, 7.5, 0.057),
      _Pr('Bench Press', 102.5, 2.5, 0.025),
      _Pr('Overhead Press', 62.5, 2.5, 0.042),
    ],
  );
}

String _rangeLabel(String lang, _Recap d) {
  switch (d.rangeKey) {
    case 'Last 7 days':
      return _tr(lang, 'range7');
    case 'Last 30 days':
      return _tr(lang, 'range30');
    case 'Last 90 days':
      return _tr(lang, 'range90');
    case 'This month':
      return _date(lang, 'yMMMM', d.today);
    case 'This year':
      return d.today.year.toString();
    default:
      return _tr(lang, 'rangeAll');
  }
}

/// Big and small text inside the intro plate.
List<String> _hubText(String lang, _Recap d) {
  switch (d.rangeKey) {
    case 'Last 7 days':
      return ['7', _tr(lang, 'days')];
    case 'Last 30 days':
      return ['30', _tr(lang, 'days')];
    case 'Last 90 days':
      return ['90', _tr(lang, 'days')];
    case 'This month':
      return [
        _date(lang, 'MMM', d.today).toUpperCase(),
        d.today.year.toString()
      ];
    case 'This year':
      return [d.today.year.toString(), _tr(lang, 'year')];
    default:
      return ['∞', _tr(lang, 'allTime')];
  }
}

String _spanLabel(String lang, _Recap d) {
  final String sk = d.spanDays > 180 ? 'yMMM' : 'MMMd';
  return '${_date(lang, sk, d.from)} – ${_date(lang, sk, d.today)}';
}

// ---------------------------------------------------------------------------
// Bubble packing (muscle slide)
// ---------------------------------------------------------------------------

class _Bub {
  _Bub(this.x, this.y, this.r, [this.s = 1, this.k = 1]);
  final double x, y, r;
  final double s; // entrance scale
  final double k; // share relative to the biggest bubble
}

List<_Bub>? _tryPack(
    List<double> shares, double maxR, double minR, double boxW, double boxH) {
  final double top = shares.first;
  final List<double> rs = [
    for (final s in shares) math.max(minR, maxR * math.sqrt(s / top))
  ];
  final List<_Bub> pts = [_Bub(0, 0, rs[0])];
  for (int i = 1; i < rs.length; i++) {
    _Bub? placed;
    for (int step = 0; step < 1200 && placed == null; step++) {
      final double ang = step * 0.35 + i * 1.3;
      final double rad = rs[0] * 0.4 + step * 0.9;
      final double x = math.cos(ang) * rad, y = math.sin(ang) * rad;
      if (x.abs() + rs[i] > boxW / 2 || y.abs() + rs[i] > boxH / 2) continue;
      bool ok = true;
      for (final p in pts) {
        final double dx = x - p.x, dy = y - p.y, m = rs[i] + p.r + 6;
        if (dx * dx + dy * dy < m * m) {
          ok = false;
          break;
        }
      }
      if (ok) placed = _Bub(x, y, rs[i]);
    }
    if (placed == null) return null;
    pts.add(placed);
  }
  return pts;
}

/// Circles sized by share, biggest in the middle, centred on (0, 0).
/// Shrinks everything until all of them fit the box.
List<_Bub> _packBubbles(
    List<double> shares, double maxR, double minR, double boxW, double boxH) {
  if (shares.isEmpty) return const [];
  List<_Bub>? pts;
  for (int a = 0; a < 18 && pts == null; a++) {
    final double r = maxR * math.pow(0.93, a).toDouble();
    pts = _tryPack(shares, r, math.min(minR, r * 0.42), boxW, boxH);
  }
  pts ??= [_Bub(0, 0, math.min(maxR, boxH * 0.3))];
  double x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9;
  for (final p in pts) {
    x0 = math.min(x0, p.x - p.r);
    x1 = math.max(x1, p.x + p.r);
    y0 = math.min(y0, p.y - p.r);
    y1 = math.max(y1, p.y + p.r);
  }
  final double ox = (x0 + x1) / 2, oy = (y0 + y1) / 2;
  return [for (final p in pts) _Bub(p.x - ox, p.y - oy, p.r)];
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _Lay {
  const _Lay(this.h, this.sT, this.sB);
  final double h; // stage height (design px)
  final double sT, sB; // safe-area insets (design px)
  double get top => sT + 72;
  double get bot => h - sB - 20;
  double get span => bot - top;
}

class _Pal {
  _Pal(Color primary)
      : a = primary,
        al = Color.lerp(primary, Colors.white, 0.45) ?? primary,
        a2 = HSLColor.fromColor(primary)
            .withHue((HSLColor.fromColor(primary).hue + 18) % 360)
            .toColor();
  final Color a, al, a2;
}

class _RecapViewState extends State<RecapView> with TickerProviderStateMixin {
  late final AnimationController _slide; // progress of the current slide
  late final AnimationController _amb; // slow ambient loop
  final GlobalKey _shareKey = GlobalKey();

  _Recap? _data;
  bool _loading = true;
  List<int> _slides = const [];
  int _idx = 0;
  double _bgFrom = 0;
  String _lang = 'en';
  bool _started = false;
  int _loadToken = 0;

  Timer? _holdTimer;
  bool _held = false;
  bool _suppressTap = false;
  bool _sharing = false;

  List<_Bub>? _pack;
  double _packH = -1;

  // Per-frame values read by the node helpers.
  _Pal _p = _Pal(const Color(0xFF14B8A6));
  _Lay _lay = const _Lay(780, 0, 0);
  double _ts = 0; // seconds into the current slide
  bool _rtl = false;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 5500));
    _slide.addStatusListener((s) {
      if (s == AnimationStatus.completed &&
          mounted &&
          _idx < _slides.length - 1) {
        _go(_idx + 1);
      }
    });
    _amb =
        AnimationController(vsync: this, duration: const Duration(seconds: 22))
          ..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String l = _langOf(context);
    if (!_started || l != _lang) {
      _started = true;
      _lang = l;
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant RecapView old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId ||
        old.timeRange != widget.timeRange ||
        old.demoMode != widget.demoMode) {
      _load();
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _slide.dispose();
    _amb.dispose();
    super.dispose();
  }

  // ---------- data ----------
  Future<void> _load() async {
    final int token = ++_loadToken;
    final String lang = _lang;
    final String key = (widget.timeRange ?? '').trim();
    _Recap? d;
    try {
      if (widget.demoMode ?? false) {
        await Future<void>.value(); // keeps setState out of the build phase
        d = _demoRecap(lang);
      } else {
        d = await _loadRecap(
            widget.userId, key.isEmpty ? 'Last 30 days' : key, lang);
      }
    } catch (_) {
      d = null;
    }
    if (!mounted || token != _loadToken) return;
    final List<int> s = [];
    if (d != null && d.workouts > 0) {
      s.add(0);
      s.add(1);
      if (d.volume > 0) s.add(2);
      if (d.top.isNotEmpty) s.add(3);
      if (d.muscles.isNotEmpty) s.add(4);
      s.add(5);
      if (d.prs.isNotEmpty) s.add(6);
      s.add(7);
    }
    setState(() {
      _data = d;
      _slides = s;
      _loading = false;
      _idx = 0;
      _bgFrom = 0;
      _pack = null;
    });
    if (s.isNotEmpty) {
      _slide.duration =
          Duration(milliseconds: (_durOf(s.first) * 1000).round());
      _slide.forward(from: 0);
    } else {
      _slide.stop();
    }
  }

  double _durOf(int id) => id == 0 ? 5.5 : (id == 2 ? 7.5 : 7.0);

  double get _dur => _slides.isEmpty ? 7.0 : _durOf(_slides[_idx]);

  /// Where the background glow sits; glides from the previous slide.
  double _bgPos() =>
      _bgFrom + (_idx - _bgFrom) * _eo3(_c01(_slide.value * _dur / 0.9));

  // ---------- navigation ----------
  void _go(int i) {
    if (_slides.isEmpty) return;
    final int next = math.max(0, math.min(_slides.length - 1, i));
    _bgFrom = _bgPos();
    setState(() => _idx = next);
    _slide.duration =
        Duration(milliseconds: (_durOf(_slides[next]) * 1000).round());
    _slide.forward(from: 0);
  }

  void _onTapUp(TapUpDetails d, double width) {
    if (_suppressTap) {
      _suppressTap = false;
      return;
    }
    if (_slides.isEmpty) return;
    double f = width <= 0 ? 1.0 : d.localPosition.dx / width;
    if (_rtl) f = 1 - f;
    HapticFeedback.selectionClick();
    if (f < 0.3) {
      _go((_ts > 1.2 || _idx == 0) ? _idx : _idx - 1);
    } else if (_idx < _slides.length - 1) {
      _go(_idx + 1);
    }
  }

  void _holdStart() {
    if (!mounted) return;
    _held = true;
    _suppressTap = true;
    _slide.stop();
  }

  void _holdEnd() {
    _holdTimer?.cancel();
    if (_held) {
      _held = false;
      if (_slides.isNotEmpty && _slide.value < 1) _slide.forward();
    }
  }

  void _close() {
    HapticFeedback.selectionClick();
    widget.onClose?.call();
  }

  Future<void> _share() async {
    if (_sharing) return;
    _sharing = true;
    HapticFeedback.selectionClick();
    try {
      final RenderObject? ro = _shareKey.currentContext?.findRenderObject();
      if (ro is RenderRepaintBoundary) {
        final Size screen = MediaQuery.of(context).size;
        final ui.Image img = await ro.toImage(pixelRatio: 3.0);
        final ByteData? bytes =
            await img.toByteData(format: ui.ImageByteFormat.png);
        img.dispose();
        if (bytes != null) {
          final Directory dir = await getTemporaryDirectory();
          final int stamp = DateTime.now().millisecondsSinceEpoch;
          final String caption = _tr(_lang, 'shareText') + ' · ' + _kBrand;
          final File file = File('${dir.path}/recap_$stamp.png');
          await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
          await Share.shareXFiles(
            [XFile(file.path, mimeType: 'image/png')],
            text: caption,
            sharePositionOrigin: Rect.fromLTWH(
                screen.width / 2 - 1, screen.height / 2 - 1, 2, 2),
          );
        }
      }
    } catch (_) {
      // Sharing is best-effort; the recap keeps working.
    } finally {
      _sharing = false;
    }
  }

  // ---------- node helpers (design px inside the 390 x H stage) ----------
  Widget _pos(double x, double y, double w, double? h, bool abs, Widget child) {
    return abs
        ? Positioned(left: x, top: y, width: w, height: h, child: child)
        : PositionedDirectional(
            start: x, top: y, width: w, height: h, child: child);
  }

  /// Fade + slide + scale + rotate (degrees). Always the same widget shape,
  /// so elements keep their state while they animate.
  Widget _fx(Widget child, double op, double dy, double sc, double rot) {
    return Opacity(
      opacity: _c01(op),
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Transform.rotate(
          angle: rot * math.pi / 180,
          child: Transform.scale(scale: sc, child: child),
        ),
      ),
    );
  }

  TextStyle _st(double size, FontWeight weight, Color color,
          {double ls = 0, double lh = 1.25}) =>
      _xs(context, size, weight, color, ls: ls, height: lh);

  /// Text node. [align] 0 start / 1 center / 2 end, [valign] 0 top /
  /// 1 center / 2 bottom, [fit] scales one line down to the width,
  /// [ltr] keeps numbers left-to-right, [abs] ignores RTL mirroring.
  Widget _t(
    String text,
    double x,
    double y,
    double w, {
    double? h,
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = Colors.white,
    double ls = 0,
    double lh = 1.25,
    int lines = 1,
    int align = 0,
    int valign = 0,
    bool fit = false,
    bool ellipsis = false,
    bool ltr = false,
    bool abs = false,
    double op = 1,
    double dy = 0,
    double sc = 1,
    Color? pill,
    List<InlineSpan>? spans,
  }) {
    final TextStyle st =
        _st(size, weight, color, ls: (_rtl && !ltr) ? 0.0 : ls, lh: lh);
    final TextAlign ta = align == 1
        ? TextAlign.center
        : (align == 2 ? TextAlign.end : TextAlign.start);
    final ui.TextDirection? dir = ltr ? ui.TextDirection.ltr : null;
    Widget child = spans != null
        ? Text.rich(
            TextSpan(children: spans),
            maxLines: 1,
            softWrap: false,
            textAlign: ta,
            textDirection: dir,
            style: st,
          )
        : Text(
            text,
            maxLines: lines,
            softWrap: lines > 1,
            overflow: (ellipsis || lines > 1)
                ? TextOverflow.ellipsis
                : TextOverflow.visible,
            textAlign: ta,
            textDirection: dir,
            style: st,
          );
    if (pill != null) {
      child = Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: pill,
          borderRadius: BorderRadius.circular(999),
        ),
        child: child,
      );
    }
    if (fit) child = FittedBox(fit: BoxFit.scaleDown, child: child);
    final double ax = align == 1 ? 0.0 : (align == 2 ? 1.0 : -1.0);
    final double ay = valign == 1 ? 0.0 : (valign == 2 ? 1.0 : -1.0);
    final AlignmentGeometry al =
        abs ? Alignment(ax, ay) : AlignmentDirectional(ax, ay);
    return _pos(x, y, w, h, abs,
        _fx(Align(alignment: al, child: child), op, dy, sc, 0));
  }

  /// Box node (rounded rectangle), optionally tappable.
  Widget _b(
    double x,
    double y,
    double w,
    double h, {
    Color? color,
    double radius = 0,
    bool abs = false,
    double op = 1,
    double dy = 0,
    double sc = 1,
    double rot = 0,
    Widget? child,
    VoidCallback? onTap,
  }) {
    Widget c = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
    if (onTap != null) {
      c = GestureDetector(
          behavior: HitTestBehavior.opaque, onTap: onTap, child: c);
    }
    return _pos(x, y, w, h, abs, _fx(c, op, dy, sc, rot));
  }

  Widget _ic(
    IconData icon,
    double x,
    double y,
    double size,
    Color color, {
    bool abs = false,
    double op = 1,
    double dy = 0,
    double sc = 1,
    double rot = 0,
  }) {
    return _pos(x, y, size, size, abs,
        _fx(Icon(icon, size: size, color: color), op, dy, sc, rot));
  }

  /// Full-stage painter layer behind the nodes.
  Widget _paint(CustomPainter painter) {
    return Positioned.fill(
      child: IgnorePointer(child: CustomPaint(painter: painter)),
    );
  }

  void _eyebrow(List<Widget> n, String text,
      {bool center = false, IconData? icon}) {
    final double e = _ent(_ts, 0.05);
    if (icon != null) n.add(_ic(icon, 24, _lay.top + 5, 15, _p.al, op: e));
    n.add(_t(
      text,
      center ? 30.0 : (icon != null ? 45.0 : 24.0),
      _lay.top + 6,
      center ? 330.0 : 300.0,
      size: 12,
      weight: FontWeight.w700,
      color: _p.al,
      ls: 2,
      align: center ? 1 : 0,
      op: e,
      dy: (1 - e) * 10,
      fit: true,
    ));
  }

  /// Three stat tiles along the bottom: [label, value] each.
  void _tiles(List<Widget> n, List<List<String>> items, double d0,
      {bool lastLtr = true}) {
    final double y = _lay.bot - 84;
    for (int i = 0; i < items.length; i++) {
      final double e = _ent(_ts, d0 + i * 0.1);
      final double x = 24 + i * 117.0;
      final double dy = (1 - e) * 16;
      n.add(_b(x, y, 108, 76,
          color: _op(Colors.white, 0.06), radius: 18, op: e, dy: dy));
      n.add(_t(items[i][0], x + 12, y + 13, 84,
          size: 11,
          weight: FontWeight.w600,
          color: _op(Colors.white, 0.55),
          op: e,
          dy: dy,
          fit: true));
      n.add(_t(items[i][1], x + 12, y + 34, 84,
          size: 22,
          weight: FontWeight.w800,
          op: e,
          dy: dy,
          fit: true,
          ltr: lastLtr || i < items.length - 1));
    }
  }

  // ---------- header: progress bars, brand, close ----------
  void _chrome(List<Widget> n) {
    final int count = _slides.length;
    if (count > 0) {
      const double gap = 4;
      final double sw = (358 - gap * (count - 1)) / count;
      for (int i = 0; i < count; i++) {
        final double x = 16 + i * (sw + gap);
        final double f = i < _idx ? 1.0 : (i == _idx ? _slide.value : 0.0);
        n.add(_b(x, _lay.sT + 10, sw, 3,
            color: _op(Colors.white, 0.22), radius: 2));
        n.add(_b(x, _lay.sT + 10, sw * f, 3, color: Colors.white, radius: 2));
      }
    }
    n.add(_t(_kBrand, 20, _lay.sT + 28, 160,
        size: 13,
        weight: FontWeight.w800,
        color: _op(Colors.white, 0.92),
        ls: 3,
        ltr: true));
    n.add(_b(338, _lay.sT + 20, 36, 36,
        color: _op(Colors.white, 0.1),
        radius: 18,
        onTap: _close,
        child: const Icon(Icons.close_rounded, size: 18, color: Colors.white)));
  }

  // ---------- slide 0: intro ----------
  List<double> _introGeo() {
    final double r = math.max(120.0, math.min(150.0, _lay.span * 0.24));
    final double g = 2 * r + 130;
    final double gy = _lay.top + math.max(0.0, (_lay.span - 60 - g) / 2);
    return [r, gy + 10 + r];
  }

  void _sIntro(List<Widget> n, _Recap d) {
    final double t = _ts;
    final List<double> g = _introGeo();
    final double r = g[0], cy = g[1];
    n.add(_paint(_PlatePainter(Offset(_kW / 2, cy), r, _eo3(_c01(t / 1.3)),
        _amb.value * math.pi * 2, _p.a, _p.al)));
    final List<String> hub = _hubText(_lang, d);
    final double e1 = _ent(t, 0.5), e2 = _ent(t, 0.75);
    final double e3 = _ent(t, 0.95), e4 = _ent(t, 1.1);
    final double hp = _pop(t, 0.35, 0.6);
    final double hw = math.max(60.0, math.min(140.0, 2 * (r - 76) - 16));
    n.add(_t(hub[0], _kW / 2 - hw / 2, cy - 42, hw,
        size: 60,
        weight: FontWeight.w800,
        ls: -2,
        lh: 1,
        align: 1,
        op: math.min(1.0, hp),
        sc: 0.6 + 0.4 * hp,
        fit: true,
        ltr: true,
        abs: true));
    n.add(_t(hub[1], _kW / 2 - hw / 2, cy + 22, hw,
        size: 11,
        weight: FontWeight.w700,
        color: _p.al,
        ls: 3,
        align: 1,
        op: e1,
        fit: true,
        abs: true));
    n.add(_t(_tr(_lang, 'introTitle'), 24, cy + r + 40, 342,
        size: 34,
        weight: FontWeight.w800,
        ls: -0.8,
        lh: 1.15,
        align: 1,
        op: e2,
        dy: (1 - e2) * 16,
        fit: true));
    n.add(_t(_spanLabel(_lang, d), 30, cy + r + 90, 330,
        size: 15,
        color: _op(Colors.white, 0.62),
        align: 1,
        op: e3,
        dy: (1 - e3) * 12,
        fit: true));
    final double pulse = 0.45 + 0.3 * math.sin(t * 3.2);
    n.add(_t(_tr(_lang, 'tapNext'), 30, _lay.bot - 28, 330,
        size: 13,
        weight: FontWeight.w600,
        align: 1,
        op: e4 * pulse,
        fit: true));
  }

  // ---------- slide 1: consistency ----------
  void _sConsistency(List<Widget> n, _Recap d) {
    final double t = _ts;
    n.add(_paint(_CalPainter(d.cells, d.rows, d.bars, _lay.top + 178,
        _lay.bot - 100, t, _p.a, _p.al)));
    _eyebrow(n, _tr(_lang, 'consistency'));
    final double e = _ent(t, 0.15);
    final int cnt = (d.workouts * _eo3(_c01((t - 0.15) / 0.9))).round();
    n.add(_t(_fmtInt(_lang, cnt), 24, _lay.top + 26, 220,
        size: 104,
        weight: FontWeight.w800,
        ls: -4,
        lh: 1,
        op: e,
        dy: (1 - e) * 18,
        fit: true,
        ltr: true));
    final double e2 = _ent(t, 0.3);
    n.add(_t(_tr(_lang, d.workouts == 1 ? 'workout1' : 'workouts'), 24,
        _lay.top + 134, 300,
        size: 22,
        weight: FontWeight.w700,
        color: _op(Colors.white, 0.92),
        op: e2,
        dy: (1 - e2) * 14,
        fit: true));
    final String day = d.topWeekday == 0
        ? '–'
        : _date(_lang, 'EEEE', DateTime(2024, 1, d.topWeekday));
    _tiles(
      n,
      [
        [_tr(_lang, 'hoursTrained'), _fmtHM(d.totalMin)],
        [_tr(_lang, 'perWeek'), _fmtNum(_lang, d.perWeek)],
        [_tr(_lang, 'topDay'), day],
      ],
      1.0,
      lastLtr: false,
    );
  }

  // ---------- slide 2: total volume ----------
  void _sVolume(List<Widget> n, _Recap d) {
    final double t = _ts;
    n.add(_paint(_DecorRingsPainter(
        Offset(_kW + 30, _lay.bot - 30), _ent(t, 0.1, 1.0), _p.a)));
    _eyebrow(n, _tr(_lang, 'volume'));
    final double e = _ent(t, 0.15);
    final double val = d.volume * _eo3(_c01((t - 0.15) / 1.4));
    n.add(_t('', 24, _lay.top + 28, 342,
        lh: 1,
        op: e,
        dy: (1 - e) * 18,
        fit: true,
        ltr: true,
        spans: [
          TextSpan(
              text: _fmtInt(_lang, val),
              style: _st(84, FontWeight.w800, Colors.white, ls: -3, lh: 1)),
          TextSpan(text: ' kg', style: _st(30, FontWeight.w700, _p.al, lh: 1)),
        ]));
    final double e2 = _ent(t, 0.35);
    n.add(_t(_tr(_lang, 'volSub', n: _fmtInt(_lang, d.sets)), 24,
        _lay.top + 122, 342,
        size: 16,
        color: _op(Colors.white, 0.62),
        op: e2,
        dy: (1 - e2) * 14,
        fit: true));

    final int objN = d.objN;
    if (objN >= 2) {
      final _Obj o = _kObj[d.objIdx];
      final int shown = math.min(objN, 12);
      final int perRow = shown > 6 ? (shown / 2).ceil() : shown;
      final int rows = (shown / perRow).ceil();
      final double isz = shown <= 3 ? 64.0 : (shown <= 6 ? 52.0 : 44.0);
      final double gap = shown <= 3 ? 16.0 : 10.0;
      final double blockH = 14 + 16 + rows * (isz + gap) + 6 + 40;
      final double rTop = _lay.top + 168, rBot = _lay.bot - 100;
      final double y0 = rTop + math.max(0.0, (rBot - rTop - blockH) / 2);
      final double e3 = _ent(t, 1.3);
      n.add(_t(_tr(_lang, 'volLike'), 24, y0, 342,
          size: 12,
          weight: FontWeight.w700,
          color: _op(Colors.white, 0.5),
          ls: 1.6,
          align: 1,
          op: e3,
          dy: (1 - e3) * 10,
          fit: true));
      for (int i = 0; i < shown; i++) {
        final int row = i ~/ perRow;
        final int inRow = math.min(perRow, shown - row * perRow);
        final int col = i - row * perRow;
        final double rw = inRow * isz + (inRow - 1) * gap;
        final double s = _pop(t, 1.5 + i * 0.07, 0.45);
        n.add(_ic(o.icon, (_kW - rw) / 2 + col * (isz + gap),
            y0 + 30 + row * (isz + gap), isz, i.isEven ? _p.al : _p.a,
            abs: true, op: math.min(1.0, s), sc: s));
      }
      final double e4 = _ent(t, 1.5 + shown * 0.07 + 0.1);
      n.add(_t('${_fmtInt(_lang, objN)} ${_tr(_lang, o.key)}', 24,
          y0 + 30 + rows * (isz + gap) + 6, 342,
          size: 30,
          weight: FontWeight.w800,
          ls: -0.6,
          align: 1,
          op: e4,
          dy: (1 - e4) * 12,
          fit: true));
    }
    _tiles(
      n,
      [
        [_tr(_lang, 'sets'), _fmtInt(_lang, d.sets)],
        [_tr(_lang, 'reps'), _fmtInt(_lang, d.reps)],
        [_tr(_lang, 'heaviest'), '${_fmtNum(_lang, d.heaviest)} kg'],
      ],
      2.3,
    );
  }

  // ---------- slide 3: most trained exercise ----------
  void _sTop(List<Widget> n, _Recap d) {
    final double t = _ts;
    final _TopEx ex = d.top.first;
    _eyebrow(n, _tr(_lang, 'mostTrained'), center: true);
    final double cs = math.max(150.0, math.min(200.0, _lay.span * 0.29));
    final double cx = (_kW - cs) / 2, cy = _lay.top + 40;
    final double s = _pop(t, 0.2, 0.7);
    n.add(_b(cx, cy, cs, cs,
        color: Colors.white,
        radius: 30,
        abs: true,
        op: math.min(1.0, s * 1.5),
        sc: 0.7 + 0.3 * s,
        rot: -5 - (1 - math.min(1.0, s)) * 9,
        child: ExerciseAssetImage(
          width: cs * 0.82,
          height: cs * 0.82,
          exerciseName: exerciseImageName(ex.nameEn),
          borderRadius: 16,
          illustration: ex.illustration,
        )));
    final double sb = _pop(t, 0.7, 0.5);
    n.add(_b(cx + cs - 30, cy - 14, 46, 46,
        color: _p.a,
        radius: 23,
        abs: true,
        op: math.min(1.0, sb),
        sc: sb,
        child: Text('#1',
            textDirection: ui.TextDirection.ltr,
            style: _st(16, FontWeight.w800, _kOnAccent, lh: 1))));
    final double e1 = _ent(t, 0.55), e2 = _ent(t, 0.7), e3 = _ent(t, 0.85);
    n.add(_t(ex.name, 30, cy + cs + 16, 330,
        h: 66,
        size: 27,
        weight: FontWeight.w800,
        ls: -0.5,
        lh: 1.15,
        lines: 2,
        align: 1,
        valign: 1,
        op: e1,
        dy: (1 - e1) * 14));
    n.add(_t(
        _tr(_lang, 'setsSessions',
            n: _fmtInt(_lang, ex.sets), s: _fmtInt(_lang, ex.sessions)),
        30,
        cy + cs + 86,
        330,
        size: 15,
        color: _op(Colors.white, 0.62),
        align: 1,
        op: e2,
        dy: (1 - e2) * 12,
        fit: true));
    if (ex.best.isNotEmpty) {
      n.add(_t(_tr(_lang, 'bestSet') + '  ' + ex.best, 30, cy + cs + 116, 330,
          size: 14,
          weight: FontWeight.w700,
          color: _p.al,
          align: 1,
          op: e3,
          dy: (1 - e3) * 12,
          fit: true,
          pill: _op(_p.a, 0.16)));
    }
    for (int i = 1; i < math.min(3, d.top.length); i++) {
      final _TopEx r = d.top[i];
      final double y = _lay.bot - 122 + (i - 1) * 60;
      final double e = _ent(t, 1.0 + i * 0.12), dy = (1 - e) * 14;
      n.add(_b(24, y, 342, 52,
          color: _op(Colors.white, 0.05), radius: 16, op: e, dy: dy));
      n.add(_t('#${i + 1}', 38, y + 17, 26,
          size: 14,
          weight: FontWeight.w800,
          color: _op(Colors.white, 0.45),
          op: e,
          dy: dy,
          ltr: true));
      n.add(_b(70, y + 8, 36, 36,
          color: Colors.white,
          radius: 10,
          op: e,
          dy: dy,
          child: ExerciseAssetImage(
            width: 30,
            height: 30,
            exerciseName: exerciseImageName(r.nameEn),
            borderRadius: 8,
            illustration: r.illustration,
          )));
      n.add(_t(r.name, 118, y + 16, 150,
          size: 15, weight: FontWeight.w600, op: e, dy: dy, ellipsis: true));
      n.add(_t(_tr(_lang, 'nSets', n: _fmtInt(_lang, r.sets)), 268, y + 18, 84,
          size: 13,
          color: _op(Colors.white, 0.6),
          align: 2,
          op: e,
          dy: dy,
          fit: true));
    }
  }

  // ---------- slide 4: muscle focus ----------
  List<_Bub> _bubbles(_Recap d) {
    final double top = _lay.top + 112, bot = _lay.bot - 30, boxH = bot - top;
    List<_Bub>? pk = _pack;
    if (pk == null || _packH != boxH) {
      pk = _packBubbles([for (final m in d.muscles) m.share],
          math.min(92.0, boxH * 0.3), 30, 342, boxH);
      _pack = pk;
      _packH = boxH;
    }
    final double cy = top + boxH / 2, k0 = d.muscles.first.share;
    final double a = _amb.value * math.pi * 2;
    final List<_Bub> out = [];
    for (int i = 0; i < pk.length && i < d.muscles.length; i++) {
      out.add(_Bub(
        _kW / 2 + pk[i].x + math.sin(a * 3 + i * 1.7) * 3,
        cy + pk[i].y + math.cos(a * 2 + i) * 3,
        pk[i].r,
        _pop(_ts, 0.35 + i * 0.09, 0.6),
        k0 <= 0 ? 1.0 : d.muscles[i].share / k0,
      ));
    }
    return out;
  }

  void _sMuscles(List<Widget> n, _Recap d) {
    final double t = _ts;
    final List<_Bub> bs = _bubbles(d);
    n.add(_paint(_BubblePainter(bs, _p.a, _p.al)));
    _eyebrow(n, _tr(_lang, 'muscleFocus'));
    final double e = _ent(t, 0.15);
    n.add(_t(
        _tr(_lang, 'mostly', m: d.muscles.first.name), 24, _lay.top + 30, 342,
        size: 36,
        weight: FontWeight.w800,
        ls: -1,
        lh: 1.1,
        op: e,
        dy: (1 - e) * 16,
        fit: true));
    for (int i = 0; i < bs.length; i++) {
      final _Bub b = bs[i];
      final bool big = i == 0;
      final double o = _c01(b.s * 1.4 - 0.4);
      final double fs = big ? 19.0 : math.max(10.0, math.min(15.0, b.r * 0.3));
      final int pct = (d.muscles[i].share * 100).round();
      n.add(_t(d.muscles[i].name, b.x - b.r * 0.8, b.y - fs * 1.05, b.r * 1.6,
          size: fs,
          weight: FontWeight.w800,
          color: big ? _kOnAccent : Colors.white,
          align: 1,
          op: o,
          fit: true,
          abs: true));
      n.add(_t('$pct%', b.x - b.r * 0.8, b.y + fs * 0.2, b.r * 1.6,
          size: fs * 0.82,
          weight: FontWeight.w600,
          color: big ? _op(_kOnAccent, 0.75) : _op(Colors.white, 0.7),
          align: 1,
          op: o,
          fit: true,
          ltr: true,
          abs: true));
    }
  }

  // ---------- slide 5: AI form ----------
  void _sForm(List<Widget> n, _Recap d) {
    final double t = _ts;
    final double r = math.max(78.0, math.min(118.0, _lay.span * 0.19));
    final double cy = _lay.top + 52 + r;
    final double? avg = d.formAvg;
    final double grow = _eo3(_c01((t - 0.2) / 1.3));
    n.add(_paint(_RingPainter(Offset(_kW / 2, cy), r, (avg ?? 0.0) / 10, grow,
        avg == null, _p.a, _p.al)));
    _eyebrow(n, _tr(_lang, 'aiForm'), icon: Icons.auto_awesome_rounded);
    final double e = _ent(t, 0.3);
    n.add(_t(avg == null ? '–' : _fmt1(_lang, avg * grow), _kW / 2 - r * 0.75,
        cy - r * 0.42, r * 1.5,
        size: r * 0.62,
        weight: FontWeight.w800,
        ls: -2,
        lh: 1,
        align: 1,
        op: e,
        fit: true,
        ltr: true,
        abs: true));
    n.add(_t('/10', _kW / 2 - 40, cy + r * 0.3, 80,
        size: 15,
        weight: FontWeight.w600,
        color: _op(Colors.white, 0.5),
        align: 1,
        op: e,
        ltr: true,
        abs: true));
    final double e2 = _ent(t, 1.2);
    if (avg == null) {
      n.add(_t(_tr(_lang, 'formEmptyT'), 30, cy + r + 26, 330,
          size: 26,
          weight: FontWeight.w800,
          ls: -0.5,
          align: 1,
          op: e2,
          dy: (1 - e2) * 14,
          fit: true));
      final double e3 = _ent(t, 1.35);
      n.add(_t(_tr(_lang, 'formEmptyS'), 45, cy + r + 68, 300,
          h: 66,
          size: 16,
          color: _op(Colors.white, 0.62),
          lh: 1.35,
          lines: 3,
          align: 1,
          op: e3,
          dy: (1 - e3) * 12));
      return;
    }
    final String key = avg >= 9 ? 'formA' : (avg >= 7.5 ? 'formB' : 'formC');
    n.add(_t(_tr(_lang, key), 30, cy + r + 26, 330,
        size: 27,
        weight: FontWeight.w800,
        ls: -0.5,
        align: 1,
        op: e2,
        dy: (1 - e2) * 14,
        fit: true));
    final double rowsTop = cy + r + 76;
    final int fits = ((_lay.bot - 100 - rowsTop) / 50).floor();
    final int rows =
        math.max(0, math.min(math.min(3, fits), d.formByEx.length));
    for (int i = 0; i < rows; i++) {
      final _FormEx f = d.formByEx[i];
      final double y = rowsTop + i * 50;
      final double er = _ent(t, 1.45 + i * 0.1), dy = (1 - er) * 12;
      n.add(_b(24, y, 342, 42,
          color: _op(Colors.white, 0.05), radius: 14, op: er, dy: dy));
      n.add(_t(f.name, 40, y + 12, 220,
          size: 14, weight: FontWeight.w600, op: er, dy: dy, ellipsis: true));
      n.add(_t(_fmt1(_lang, f.score), 280, y + 11, 70,
          size: 15,
          weight: FontWeight.w800,
          color: _p.al,
          align: 2,
          op: er,
          dy: dy,
          ltr: true));
    }
    _tiles(
      n,
      [
        [_tr(_lang, 'setsChecked'), _fmtInt(_lang, d.formSets)],
        [_tr(_lang, 'perfectReps'), _fmtInt(_lang, d.formPerfect)],
        [_tr(_lang, 'bestScore'), _fmt1(_lang, d.formBest)],
      ],
      1.8,
    );
  }

  // ---------- slide 6: personal records ----------
  void _sRecords(List<Widget> n, _Recap d) {
    final double t = _ts;
    _eyebrow(n, _tr(_lang, 'records'));
    final double e = _ent(t, 0.15), s = _pop(t, 0.3, 0.7);
    n.add(_ic(
        Icons.emoji_events_rounded, 236, _lay.top + 20, 140, _op(_p.a, 0.22),
        op: math.min(1.0, s), sc: 0.6 + 0.4 * s, rot: 12));
    n.add(_t(_fmtInt(_lang, d.prs.length), 24, _lay.top + 26, 200,
        size: 104,
        weight: FontWeight.w800,
        ls: -4,
        lh: 1,
        op: e,
        dy: (1 - e) * 18,
        fit: true,
        ltr: true));
    final double e2 = _ent(t, 0.3);
    n.add(_t(_tr(_lang, d.prs.length == 1 ? 'newRecord1' : 'newRecords'), 24,
        _lay.top + 134, 300,
        size: 22,
        weight: FontWeight.w700,
        color: _op(Colors.white, 0.92),
        op: e2,
        dy: (1 - e2) * 14,
        fit: true));
    final int rows = math.min(3, d.prs.length);
    final double free = _lay.bot - 30 - (_lay.top + 186) - (rows * 74 - 10);
    final double y0 = _lay.top + 186 + math.max(0.0, free * 0.38);
    for (int i = 0; i < rows; i++) {
      final _Pr r = d.prs[i];
      final double y = y0 + i * 74;
      final double er = _ent(t, 0.7 + i * 0.14), dy = (1 - er) * 18;
      n.add(_b(24, y, 342, 64,
          color: _op(Colors.white, 0.06), radius: 18, op: er, dy: dy));
      n.add(_t(r.name, 42, y + 13, 190,
          size: 16, weight: FontWeight.w700, op: er, dy: dy, ellipsis: true));
      n.add(_t(_tr(_lang, 'est1rm'), 42, y + 37, 190,
          size: 12, color: _op(Colors.white, 0.5), op: er, dy: dy, fit: true));
      n.add(_t('${_fmtNum(_lang, r.value)} kg', 236, y + 12, 112,
          size: 18,
          weight: FontWeight.w800,
          align: 2,
          op: er,
          dy: dy,
          fit: true,
          ltr: true));
      n.add(_t('+${_fmtNum(_lang, r.delta)} kg', 236, y + 37, 112,
          size: 13,
          weight: FontWeight.w700,
          color: _kUp,
          align: 2,
          op: er,
          dy: dy,
          fit: true,
          ltr: true));
    }
  }

  // ---------- slide 7: summary + share ----------
  String _modeReason(_Recap d) {
    final String workoutWord =
        _tr(_lang, d.workouts == 1 ? 'workout1' : 'workouts');
    switch (d.mode) {
      case 'mPr':
        return _fmtInt(_lang, d.prs.length) + ' ' + _tr(_lang, 'newRecords');
      case 'mMachine':
        return _tr(_lang, 'perWeek') + ': ' + _fmtNum(_lang, d.perWeek);
      case 'mPrecision':
        return _tr(_lang, 'cForm') +
            ': ' +
            _fmtNum(_lang, d.formAvg ?? 0.0) +
            ' / 10';
      case 'mHeavy':
        return _tr(_lang, 'cVolume') + ': ' + _fmtInt(_lang, d.volume) + ' kg';
      case 'mFocus':
        final int pct = (d.muscles.first.share * 100).round();
        return '$pct% ' + d.muscles.first.name;
      default:
        return _fmtInt(_lang, d.workouts) + ' ' + workoutWord;
    }
  }

  void _sSummary(List<Widget> n, _Recap d) {
    final double t = _ts;
    final double ch = math.max(410.0, math.min(560.0, _lay.span - 138));
    final double e = _ent(t, 0.1, 0.8);
    final Color soft = _op(Colors.white, 0.55);
    final String mode = d.mode;
    final String title =
        _tr(_lang, mode, m: mode == 'mFocus' ? d.muscles.first.name : null)
            .toUpperCase();
    final double bottomTop = ch - 74;
    final double rowGap =
        math.max(62.0, math.min(84.0, (bottomTop - 214) / 2.5));
    final double statsTop =
        214 + math.max(0.0, (bottomTop - 214 - (rowGap + 62)) / 2);
    final double? fa = d.formAvg;
    final String form = fa == null ? '–' : _fmtNum(_lang, fa) + ' / 10';
    final List<List<String>> stats = [
      [_fmtInt(_lang, d.workouts), _tr(_lang, 'cWorkouts')],
      ['${_fmtInt(_lang, d.volume)} kg', _tr(_lang, 'cVolume')],
      [_fmtHM(d.totalMin), _tr(_lang, 'cHours')],
      [form, _tr(_lang, 'cForm')],
    ];
    final List<Widget> k = [
      Positioned.fill(
          child: CustomPaint(painter: _CardDecorPainter(_p.a, _p.al, _rtl))),
      _t(_kBrand, 24, 24, 150,
          size: 13, weight: FontWeight.w800, ls: 3, ltr: true),
      _t(_rangeLabel(_lang, d), 150, 25, 168,
          size: 11,
          weight: FontWeight.w700,
          color: _op(Colors.white, 0.6),
          ls: 0.6,
          align: 2,
          fit: true),
      _t(_tr(_lang, 'mode'), 24, 72, 294,
          size: 11, weight: FontWeight.w700, color: _p.al, ls: 2, fit: true),
      _t(title, 24, 90, 294,
          h: 82, size: 37, weight: FontWeight.w800, ls: -1, lh: 1.06, lines: 2),
      _t(_modeReason(d), 24, 178, 294,
          size: 15,
          weight: FontWeight.w600,
          color: _op(Colors.white, 0.7),
          fit: true),
      _b(24, statsTop - 4, 294, 1, color: _op(Colors.white, 0.1)),
      for (int i = 0; i < 4; i++) ...[
        _t(stats[i][0], 24 + (i % 2) * 156.0, statsTop + 12 + (i ~/ 2) * rowGap,
            138,
            size: 30,
            weight: FontWeight.w800,
            ls: -0.8,
            lh: 1,
            fit: true,
            ltr: true),
        _t(stats[i][1], 24 + (i % 2) * 156.0, statsTop + 49 + (i ~/ 2) * rowGap,
            138,
            size: 12, weight: FontWeight.w600, color: soft, fit: true),
      ],
      _b(24, bottomTop, 294, 1, color: _op(Colors.white, 0.1)),
      _t(_tr(_lang, 'cTopLift'), 24, bottomTop + 16, 138,
          size: 11,
          weight: FontWeight.w600,
          color: _op(Colors.white, 0.5),
          fit: true),
      _t(d.top.isEmpty ? '–' : d.top.first.name, 24, bottomTop + 34, 138,
          size: 15, weight: FontWeight.w700, ellipsis: true),
      _t(_tr(_lang, 'cFocus'), 180, bottomTop + 16, 138,
          size: 11,
          weight: FontWeight.w600,
          color: _op(Colors.white, 0.5),
          fit: true),
      _t(d.muscles.isEmpty ? '–' : d.muscles.first.name, 180, bottomTop + 34,
          138,
          size: 15, weight: FontWeight.w700, ellipsis: true),
    ];
    // The RepaintBoundary is what gets shared: a square-cornered poster.
    // The rounded corners and the hairline border exist on screen only.
    final Widget card = Container(
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _op(Colors.white, 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: RepaintBoundary(
          key: _shareKey,
          child: SizedBox(width: 342, height: ch, child: Stack(children: k)),
        ),
      ),
    );
    n.add(Positioned(
      left: 24,
      top: _lay.top + 2,
      width: 342,
      height: ch,
      child: _fx(card, e, (1 - e) * 24, 0.96 + 0.04 * e, 0),
    ));
    final double e2 = _ent(t, 0.7), e3 = _ent(t, 0.85);
    n.add(_b(24, _lay.bot - 106, 342, 50,
        color: _p.a,
        radius: 25,
        abs: true,
        op: e2,
        dy: (1 - e2) * 14,
        onTap: _share,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.ios_share_rounded, size: 20, color: _kOnAccent),
            const SizedBox(width: 8),
            Text(_tr(_lang, 'share'),
                style: _st(16, FontWeight.w700, _kOnAccent, lh: 1.2)),
          ],
        )));
    n.add(_b(115, _lay.bot - 46, 160, 40,
        abs: true,
        op: e3,
        onTap: _close,
        child: Text(_tr(_lang, 'done'),
            style:
                _st(15, FontWeight.w600, _op(Colors.white, 0.75), lh: 1.2))));
  }

  // ---------- loading / empty ----------
  void _sEmpty(List<Widget> n) {
    final double cy = _lay.top + _lay.span * 0.4;
    n.add(_ic(Icons.fitness_center_rounded, _kW / 2 - 28, cy - 90, 56,
        _op(_p.al, 0.6),
        abs: true));
    n.add(_t(_tr(_lang, 'emptyT'), 30, cy - 10, 330,
        size: 24, weight: FontWeight.w800, ls: -0.4, align: 1, fit: true));
    n.add(_t(_tr(_lang, 'emptyS'), 50, cy + 30, 290,
        h: 70,
        size: 15,
        color: _op(Colors.white, 0.62),
        lh: 1.4,
        lines: 3,
        align: 1));
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final Color primary = FlutterFlowTheme.of(context).primary;
    // Light status-bar icons: the recap is dark in both app themes.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Material(
          type: MaterialType.transparency,
          child: ClipRect(
            child: LayoutBuilder(builder: (ctx, box) {
              final double w = box.maxWidth, h = box.maxHeight;
              if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) {
                return const SizedBox.shrink();
              }
              double scale = w / _kW;
              double stageH = h / scale;
              if (stageH < _kMinH) {
                scale = h / _kMinH;
                stageH = _kMinH;
              }
              final EdgeInsets pad = MediaQuery.of(ctx).padding;
              return AnimatedBuilder(
                animation: Listenable.merge([_slide, _amb]),
                builder: (ctx2, _) =>
                    _frame(primary, w, scale, stageH, pad.top, pad.bottom),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _frame(Color primary, double w, double scale, double stageH,
      double padTop, double padBottom) {
    _p = _Pal(primary);
    _lay = _Lay(stageH, padTop / scale, padBottom / scale);
    _ts = _slide.value * _dur;
    _rtl = _kRtl.contains(_lang);
    final _Recap? d = _data;

    final List<Widget> n = [];
    if (_loading) {
      n.add(Positioned.fill(
          child: Center(child: CircularProgressIndicator(color: _p.a))));
      _chrome(n);
    } else if (d == null || _slides.isEmpty) {
      _sEmpty(n);
      _chrome(n);
    } else {
      final List<Widget> body = [];
      switch (_slides[_idx]) {
        case 0:
          _sIntro(body, d);
          break;
        case 1:
          _sConsistency(body, d);
          break;
        case 2:
          _sVolume(body, d);
          break;
        case 3:
          _sTop(body, d);
          break;
        case 4:
          _sMuscles(body, d);
          break;
        case 5:
          _sForm(body, d);
          break;
        case 6:
          _sRecords(body, d);
          break;
        default:
          _sSummary(body, d);
      }
      // One keyed layer per slide: a new slide starts from a clean tree.
      n.add(Positioned.fill(
        child: Opacity(
          key: ValueKey<int>(_slides[_idx]),
          opacity: _c01(_ts / 0.25),
          child: Stack(children: body),
        ),
      ));
      _chrome(n);
    }

    return Listener(
      onPointerDown: (_) {
        _suppressTap = false;
        _holdTimer?.cancel();
        _holdTimer = Timer(const Duration(milliseconds: 220), _holdStart);
      },
      onPointerUp: (_) => _holdEnd(),
      onPointerCancel: (_) => _holdEnd(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) => _onTapUp(details, w),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _BgPainter(_p.a, _p.a2, _amb.value, _bgPos())),
            Center(
              child: SizedBox(
                width: _kW * scale,
                height: stageH * scale,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox(
                    width: _kW,
                    height: stageH,
                    child: MediaQuery.withNoTextScaling(
                      child: Directionality(
                        textDirection:
                            _rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                        child: Stack(children: n),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painters (design px, except the background)
// ---------------------------------------------------------------------------

Paint _stroke(Color c, double width, [StrokeCap cap = StrokeCap.butt]) =>
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = cap
      ..color = c;

/// Dark gradient with three slow teal glows that travel with the slides.
class _BgPainter extends CustomPainter {
  _BgPainter(this.a, this.a2, this.amb, this.pos);
  final Color a, a2;
  final double amb, pos;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width, h = size.height;
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(
              Offset.zero, Offset(0, h), const [_kBg0, _kBg1]));
    final double th = pos * 1.1;
    final double dx = math.sin(amb * math.pi * 2) * 10;
    final double dy = math.cos(amb * math.pi * 2) * 8;
    void blob(double x, double y, double rad, Color c, double o) {
      canvas.drawRect(
          rect,
          Paint()
            ..shader =
                ui.Gradient.radial(Offset(x, y), rad, [_op(c, o), _op(c, 0)]));
    }

    blob(w * 0.5 + w * 0.42 * math.cos(th) + dx,
        h * 0.26 + h * 0.12 * math.sin(th * 1.3) + dy, w * 0.78, a, 0.24);
    blob(w * 0.5 + w * 0.45 * math.cos(th + 2.4) - dx,
        h * 0.62 + h * 0.14 * math.sin(th * 0.9 + 1) - dy, w * 0.85, a2, 0.15);
    blob(w * 0.5 + w * 0.3 * math.cos(th + 4.2), h * 0.97, w * 0.7, a, 0.12);
  }

  @override
  bool shouldRepaint(covariant _BgPainter old) =>
      old.amb != amb || old.pos != pos || old.a != a;
}

/// The intro "weight plate": rim that draws in, tick marks, bolt arcs, hub.
class _PlatePainter extends CustomPainter {
  _PlatePainter(this.c, this.r, this.p, this.rot, this.a, this.al);
  final Offset c;
  final double r, p, rot;
  final Color a, al;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
        c,
        r * 1.7,
        Paint()
          ..shader = ui.Gradient.radial(c, r * 1.7, [_op(a, 0.22), _op(a, 0)]));
    canvas.drawCircle(c, r, _stroke(_op(Colors.white, 0.06), 12));
    if (p > 0) {
      final Paint rim = _stroke(a, 12, StrokeCap.round)
        ..shader = ui.Gradient.sweep(c, [al, a, al], const [0.0, 0.5, 1.0],
            TileMode.clamp, -math.pi / 2, math.pi * 1.5);
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2,
          math.pi * 2 * p, false, rim);
    }
    canvas.drawCircle(c, r - 20, _stroke(_op(Colors.white, 0.16 * p), 1.5));
    for (int i = 0; i < 72; i++) {
      if (i / 72 > p) break;
      final bool major = i % 6 == 0;
      final double ang = rot + i / 72 * math.pi * 2 - math.pi / 2;
      final double r1 = r - (major ? 39 : 33), r2 = r - 26;
      canvas.drawLine(
          c + Offset(math.cos(ang) * r1, math.sin(ang) * r1),
          c + Offset(math.cos(ang) * r2, math.sin(ang) * r2),
          _stroke(_op(Colors.white, major ? 0.5 : 0.22), major ? 2.0 : 1.2));
    }
    final Paint seg = _stroke(_op(a, 0.3 * p), 9, StrokeCap.round);
    final Rect segRect = Rect.fromCircle(center: c, radius: r - 56);
    for (int i = 0; i < 5; i++) {
      canvas.drawArc(segRect, -rot * 1.5 + i * (math.pi * 2 / 5),
          (math.pi * 2 / 5) * 0.62 * p, false, seg);
    }
    canvas.drawCircle(c, r - 76, Paint()..color = _kDeep);
    canvas.drawCircle(c, r - 76, _stroke(_op(Colors.white, 0.14), 1));
  }

  @override
  bool shouldRepaint(covariant _PlatePainter old) => true;
}

/// Training calendar (dots, Monday first) or weekly bars for long ranges.
class _CalPainter extends CustomPainter {
  _CalPainter(this.cells, this.rows, this.bars, this.top, this.bottom, this.t,
      this.a, this.al);
  final List<int> cells, bars;
  final int rows;
  final double top, bottom, t;
  final Color a, al;

  @override
  void paint(Canvas canvas, Size size) {
    if (cells.isNotEmpty && rows > 0) {
      final double pitch = math.min(46.0, (bottom - top) / rows);
      final double gw = 7 * pitch, gh = rows * pitch;
      final double x0 = (_kW - gw) / 2 + pitch / 2;
      final double y0 = top + (bottom - top - gh) / 2 + pitch / 2;
      final double rad = pitch * 0.36;
      int seen = 0;
      for (int i = 0; i < cells.length; i++) {
        final int state = cells[i];
        if (state == 0) continue;
        final Offset o = Offset(x0 + (i % 7) * pitch, y0 + (i ~/ 7) * pitch);
        final double s = _pop(t, 0.35 + seen * 0.022, 0.45);
        seen++;
        if (s <= 0) continue;
        if (state == 2) {
          canvas.drawCircle(
              o,
              rad * 2.2,
              Paint()
                ..shader = ui.Gradient.radial(o, rad * 2.2,
                    [_op(a, 0.35 * math.min(1.0, s)), _op(a, 0)]));
          canvas.drawCircle(
              o,
              rad * s,
              Paint()
                ..shader = ui.Gradient.linear(
                    o.translate(0, -rad), o.translate(0, rad), [al, a]));
        } else {
          canvas.drawCircle(
              o, rad * 0.72 * s, Paint()..color = _op(Colors.white, 0.08));
        }
      }
      return;
    }
    final int nb = bars.length;
    if (nb == 0) return;
    int mx = 1;
    for (final v in bars) {
      if (v > mx) mx = v;
    }
    final double gap = nb > 30 ? 2.0 : 4.0;
    final double bw = (342 - gap * (nb - 1)) / nb;
    final double maxH = math.min(160.0, (bottom - top) * 0.7);
    final double base = top + (bottom - top + maxH) / 2;
    for (int i = 0; i < nb; i++) {
      final double g = _ent(t, 0.35 + i * (0.9 / nb), 0.5);
      final double hh =
          bars[i] == 0 ? 3.0 : math.max(6.0, maxH * bars[i] / mx) * g;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(24 + i * (bw + gap), base - hh, bw, hh),
              Radius.circular(math.min(4.0, bw / 2))),
          Paint()
            ..color = bars[i] == 0
                ? _op(Colors.white, 0.12)
                : _op(al, 0.45 + 0.55 * bars[i] / mx));
    }
  }

  @override
  bool shouldRepaint(covariant _CalPainter old) => true;
}

/// Faint plate rings in the corner of the volume slide.
class _DecorRingsPainter extends CustomPainter {
  _DecorRingsPainter(this.c, this.p, this.a);
  final Offset c;
  final double p;
  final Color a;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(c, 230, _stroke(_op(Colors.white, 0.028 * p), 46));
    canvas.drawCircle(c, 168, _stroke(_op(Colors.white, 0.06 * p), 2));
    canvas.drawCircle(c, 128, _stroke(_op(a, 0.07 * p), 18));
  }

  @override
  bool shouldRepaint(covariant _DecorRingsPainter old) => old.p != p;
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.list, this.a, this.al);
  final List<_Bub> list;
  final Color a, al;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < list.length; i++) {
      final _Bub b = list[i];
      if (b.s <= 0) continue;
      final Offset o = Offset(b.x, b.y);
      final double r = b.r * b.s;
      if (i == 0) {
        canvas.drawCircle(
            o,
            r * 1.6,
            Paint()
              ..shader =
                  ui.Gradient.radial(o, r * 1.6, [_op(a, 0.3), _op(a, 0)]));
        canvas.drawCircle(
            o,
            r,
            Paint()
              ..shader = ui.Gradient.linear(
                  o.translate(0, -r), o.translate(0, r), [al, a]));
      } else {
        canvas.drawCircle(o, r, Paint()..color = _op(a, 0.1 + 0.22 * b.k));
        canvas.drawCircle(o, r, _stroke(_op(al, 0.3 + 0.4 * b.k), 1.5));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) => true;
}

/// AI form score ring with the sparkle riding the end of the arc.
class _RingPainter extends CustomPainter {
  _RingPainter(this.c, this.r, this.frac, this.p, this.empty, this.a, this.al);
  final Offset c;
  final double r, frac, p;
  final bool empty;
  final Color a, al;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromCircle(center: c, radius: r);
    final Paint track = _stroke(_op(Colors.white, 0.08), 14);
    if (empty) {
      for (int i = 0; i < 40; i++) {
        canvas.drawArc(
            rect, i * math.pi * 2 / 40, math.pi * 2 / 40 * 0.3, false, track);
      }
      return;
    }
    canvas.drawCircle(c, r, track);
    final double f = _c01(frac);
    final double sweep = math.pi * 2 * f * p;
    if (sweep <= 0.001) return;
    canvas.drawCircle(
        c,
        r * 1.5,
        Paint()
          ..shader = ui.Gradient.radial(c, r * 1.5,
              [_op(a, 0), _op(a, 0.1 * p), _op(a, 0)], const [0.4, 0.7, 1.0]));
    final Paint arc = _stroke(a, 14, StrokeCap.round)
      ..shader = ui.Gradient.sweep(
          c,
          [a, al, a],
          [0.0, math.max(0.05, math.min(0.95, f)), 1.0],
          TileMode.clamp,
          -math.pi / 2,
          math.pi * 1.5);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);

    final double ang = -math.pi / 2 + sweep;
    final Offset sp = c + Offset(math.cos(ang) * r, math.sin(ang) * r);
    const double sr = 11;
    canvas.drawCircle(sp, sr * 1.5, Paint()..color = _op(Colors.white, 0.25));
    final Path star = Path();
    for (int i = 0; i < 8; i++) {
      final double rr = i.isEven ? sr : sr * 0.36;
      final double aa = i * math.pi / 4 - math.pi / 2;
      final Offset pt = sp + Offset(math.cos(aa) * rr, math.sin(aa) * rr);
      if (i == 0) {
        star.moveTo(pt.dx, pt.dy);
      } else {
        star.lineTo(pt.dx, pt.dy);
      }
    }
    star.close();
    canvas.drawPath(star, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => true;
}

/// Background of the share card (mirrored for RTL).
class _CardDecorPainter extends CustomPainter {
  _CardDecorPainter(this.a, this.al, this.flip);
  final Color a, al;
  final bool flip;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width, h = size.height;
    if (flip) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(Offset.zero, Offset(w, h),
              const [Color(0xFF0F2927), Color(0xFF081413)]));
    canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(
              Offset(w, 0), w * 0.9, [_op(a, 0.3), _op(a, 0)]));
    final Offset c = Offset(w - 34, 30);
    canvas.drawCircle(c, 118, _stroke(_op(al, 0.16), 12));
    canvas.drawCircle(c, 98, _stroke(_op(Colors.white, 0.12), 1.5));
    final Paint seg = _stroke(_op(a, 0.2), 8, StrokeCap.round);
    final Rect segRect = Rect.fromCircle(center: c, radius: 70);
    for (int i = 0; i < 5; i++) {
      canvas.drawArc(segRect, 0.4 + i * (math.pi * 2 / 5),
          (math.pi * 2 / 5) * 0.6, false, seg);
    }
  }

  @override
  bool shouldRepaint(covariant _CardDecorPainter old) =>
      old.a != a || old.flip != flip;
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
