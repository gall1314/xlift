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

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl show NumberFormat;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Training Score: one number (0-100) for how well the user trains, with a
/// tier name, the change since last week, an 8-week trend, a "next step" tip
/// and the four pillars behind the number.
///
/// Everything looks at the last 4 weeks (rolling, ending today):
///
/// Consistency 35% - workouts done vs. the weekly goal, each week capped at
/// the goal; weeks before the first workout don't count. The goal is
/// [weeklyGoal] if given, else the saved weekly plan (WeekPlanner), else the
/// user's own pace (typical workouts a week over 8 weeks, at least 2), else
/// 3. Progress    25% - progressive overload. Per exercise: the latest
/// session vs. the one before it, on the top set (est. 1RM, or reps / time
/// without weight) and on total volume. Same = 70, +3% or more = 100; more
/// volume counts at half. Form        20% - average AI form-check score x 10
/// (set_analysis). Balance     20% - share of sets per muscle group (chest,
/// back, shoulders, legs, arms, core) vs. a minimum share.
///
/// A pillar that cannot be measured yet counts as 50. No workout in the last
/// 4 weeks = the score is paused (no number); no workout at all = no score.
///
/// Fully self-managed: reads workout_log / set_log / set_analysis / exercise
/// and the muscle tables itself (four plain SELECTs, everything else is
/// computed in Dart). No FlutterFlow query needed. Reloads when [userId],
/// [weeklyGoal], [demoMode] or [refreshKey] changes, on pull-to-refresh, and
/// when a page that was opened on top of it is closed again.
///
/// Two looks in one widget: - [compact] = true: a small card for Home / Stats
/// (width infinity, height 100). Tapping it fires [onTap] - navigate to the
/// score page. - [compact] = false / unset: the full page (width and height
/// infinity) with a dark hero, the tip card and the four pillars. [onClose]
/// adds a back button; the share button sends the hero as a PNG (3x).
///
/// [tile] = true: the same card squeezed into a half-width tile (title,
/// gauge, tier, change since last week) for a two-column row; give it a
/// height of about 132. Tapping fires [onTap], like the compact card.
///
/// Tapping a pillar on the full page opens what is behind it: the weeks, the
/// exercises with their numbers, the form averages, the muscle shares.
///
/// [weeklyGoal]: optional (1-7). Leave it empty to let the widget work the
/// goal out (weekly plan, then the user's own pace). [onFormCheck]: optional.
/// When the tip is about form, the tip card becomes tappable and fires it
/// (open the camera / a workout). [demoMode]: true shows built-in sample data
/// (previews, screenshots). [refreshKey]: optional, any text. Change it to
/// force a reload.
///
/// Localization: reads the app language from FFLocalizations (no parameter).
/// Exercise and muscle names come from the DB through localizedName; Hebrew
/// renders RTL (the gauge and the trend line stay LTR).
class TrainingScore extends StatefulWidget {
  const TrainingScore({
    super.key,
    this.width,
    this.height,
    required this.userId,
    this.compact,
    this.tile,
    this.weeklyGoal,
    this.demoMode,
    this.refreshKey,
    this.onTap,
    this.onClose,
    this.onFormCheck,
  });

  final double? width;
  final double? height;
  final String userId;
  final bool? compact;
  final bool? tile;
  final int? weeklyGoal;
  final bool? demoMode;
  final String? refreshKey;
  final Future Function()? onTap;
  final Future Function()? onClose;
  final Future Function()? onFormCheck;

  @override
  State<TrainingScore> createState() => _TrainingScoreState();
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const String _kBrand = 'XLIFT'; // change when the final app name is chosen
const Color _kHero = Color(0xFF0B1413);

const double _kWCons = 0.35;
const double _kWProg = 0.25;
const double _kWForm = 0.20;
const double _kWBal = 0.20;
const double _kNeutral = 50.0;

/// Minimum share of sets per group: chest, back, shoulders, legs, arms, core.
const List<double> _kMinShare = [0.10, 0.10, 0.07, 0.15, 0.07, 0.04];

// ---------------------------------------------------------------------------
// Localization (order: en, es, he, de, fr)
// ---------------------------------------------------------------------------

const Set<String> _kRtl = {'he', 'ar'};
const List<String> _kLangs = ['en', 'es', 'he', 'de', 'fr'];

const Map<String, List<String>> _kS = {
  'title': [
    'Training Score',
    'Puntuación de entreno',
    'ציון האימון',
    'Trainingsscore',
    "Score d'entraînement"
  ],
  't0': ['Warming up', 'Calentando', 'בחימום', 'Aufwärmen', 'Échauffement'],
  't1': [
    'Building',
    'En construcción',
    'בבנייה',
    'Im Aufbau',
    'En construction'
  ],
  't2': ['Solid', 'Sólido', 'יציב', 'Solide', 'Solide'],
  't3': ['Strong', 'Fuerte', 'חזק', 'Stark', 'Fort'],
  't4': ['Elite', 'Élite', 'עילית', 'Elite', 'Élite'],
  'cons': ['Consistency', 'Constancia', 'התמדה', 'Konstanz', 'Régularité'],
  'prog': ['Progress', 'Progreso', 'התקדמות', 'Fortschritt', 'Progression'],
  'form': ['Form', 'Técnica', 'טכניקה', 'Technik', 'Technique'],
  'bal': ['Balance', 'Equilibrio', 'איזון', 'Balance', 'Équilibre'],
  'ofScore': [
    '{p}% of score',
    '{p}% del total',
    '{p}% מהציון',
    '{p}% vom Score',
    '{p}% du score'
  ],
  'consD': [
    '{a} of {b} workouts',
    '{a} de {b} entrenos',
    '{a} מתוך {b} אימונים',
    '{a} von {b} Workouts',
    '{a} séances sur {b}',
  ],
  'srcPlan': [
    'your plan: {g} a week',
    'tu plan: {g} por semana',
    'לפי התוכנית: {g} בשבוע',
    'dein Plan: {g} pro Woche',
    'ton plan : {g} par semaine'
  ],
  'srcHabit': [
    'your pace: {g} a week',
    'tu ritmo: {g} por semana',
    'הקצב שלך: {g} בשבוע',
    'dein Rhythmus: {g} pro Woche',
    'ton rythme : {g} par semaine'
  ],
  'srcGoal': [
    'goal: {g} a week',
    'meta: {g} por semana',
    'יעד: {g} בשבוע',
    'Ziel: {g} pro Woche',
    'objectif : {g} par semaine'
  ],
  'planHint': [
    'Want a different goal? Build a weekly plan.',
    '¿Quieres otra meta? Crea un plan semanal.',
    'רוצים יעד אחר? בונים תוכנית שבועית.',
    'Anderes Ziel? Erstell einen Wochenplan.',
    'Un autre objectif ? Crée un plan hebdo.'
  ],
  'wkNow': [
    'Last 7 days',
    'Últimos 7 días',
    '7 הימים האחרונים',
    'Letzte 7 Tage',
    '7 derniers jours'
  ],
  'wkAgo': [
    '{a}–{b} days ago',
    'Hace {a}–{b} días',
    'לפני {a}–{b} ימים',
    'Vor {a}–{b} Tagen',
    'Il y a {a}–{b} jours'
  ],
  'repsN': ['{n} reps', '{n} reps', '{n} חזרות', '{n} Wdh.', '{n} rép.'],
  'moreVol': [
    'more volume',
    'más volumen',
    'יותר נפח',
    'mehr Volumen',
    'plus de volume'
  ],
  'low': ['low', 'bajo', 'נמוך', 'niedrig', 'faible'],
  'noDetail': [
    'Not enough data yet',
    'Aún no hay datos suficientes',
    'עדיין אין מספיק נתונים',
    'Noch nicht genug Daten',
    'Pas encore assez de données'
  ],
  'progD': [
    '{u} up · {h} steady · {d} down',
    '{u} suben · {h} igual · {d} bajan',
    '{u} בעלייה · {h} ללא שינוי · {d} בירידה',
    '{u} rauf · {h} gleich · {d} runter',
    '{u} en hausse · {h} stable · {d} en baisse',
  ],
  'formD': [
    'Avg {x} · {n} sets checked',
    'Media {x} · {n} series revisadas',
    'ממוצע {x} · {n} סטים נבדקו',
    'Ø {x} · {n} Sätze geprüft',
    'Moy. {x} · {n} séries vérifiées',
  ],
  'formD1': [
    'Avg {x} · 1 set checked',
    'Media {x} · 1 serie revisada',
    'ממוצע {x} · סט אחד נבדק',
    'Ø {x} · 1 Satz geprüft',
    'Moy. {x} · 1 série vérifiée',
  ],
  'balOk': [
    'All muscle groups covered',
    'Todos los grupos cubiertos',
    'כל קבוצות השריר מכוסות',
    'Alle Muskelgruppen abgedeckt',
    'Tous les groupes couverts',
  ],
  'balWeak': [
    '{g}: only {p}% of your sets',
    '{g}: solo el {p}% de tus series',
    '{g}: רק {p}% מהסטים',
    '{g}: nur {p}% deiner Sätze',
    '{g} : seulement {p}% des séries',
  ],
  'notYet': [
    'Not measured yet · counts as 50',
    'Sin medir aún · cuenta como 50',
    'עדיין לא נמדד · נספר כ-50',
    'Noch nicht gemessen · zählt als 50',
    'Pas encore mesuré · compte pour 50',
  ],
  'formNone': [
    'No form check yet · counts as 50',
    'Sin análisis aún · cuenta como 50',
    'עדיין אין ניתוח טכניקה · נספר כ-50',
    'Noch kein Form-Check · zählt als 50',
    "Pas encore d'analyse · compte pour 50",
  ],
  'consInfo': [
    'Hitting your weekly workout goal',
    'Cumplir tu meta semanal de entrenos',
    'עמידה ביעד האימונים השבועי',
    'Dein Wochenziel an Workouts erreichen',
    'Atteindre ton objectif hebdo de séances',
  ],
  'progInfo': [
    'Beating your recent sessions',
    'Superar tus últimas sesiones',
    'שיפור מול האימונים האחרונים',
    'Deine letzten Einheiten übertreffen',
    'Dépasser tes dernières séances',
  ],
  'formInfo': [
    'Your AI form check scores',
    'Tus notas del análisis de técnica con IA',
    'ציוני ניתוח הטכניקה ב-AI',
    'Deine KI-Form-Check-Werte',
    "Tes notes d'analyse technique IA",
  ],
  'balInfo': [
    'Covering every muscle group',
    'Cubrir todos los grupos musculares',
    'כיסוי של כל קבוצות השריר',
    'Alle Muskelgruppen abdecken',
    'Couvrir tous les groupes musculaires',
  ],
  'vsWeek': [
    'vs last week',
    'vs. semana pasada',
    'לעומת שבוע שעבר',
    'ggü. Vorwoche',
    'vs sem. dernière'
  ],
  'same': [
    'Same as last week',
    'Igual que la semana pasada',
    'כמו בשבוע שעבר',
    'Wie letzte Woche',
    'Comme la semaine dernière',
  ],
  'first': [
    'Your first score',
    'Tu primera puntuación',
    'הציון הראשון שלך',
    'Dein erster Score',
    'Ton premier score'
  ],
  'next': [
    'Next step',
    'Siguiente paso',
    'הצעד הבא',
    'Nächster Schritt',
    'Prochaine étape'
  ],
  'trend': [
    'Last 8 weeks',
    'Últimas 8 semanas',
    '8 השבועות האחרונים',
    'Letzte 8 Wochen',
    '8 dernières semaines'
  ],
  'foot': [
    'Based on your last 4 weeks. Tap a row to see what is behind it.',
    'Basado en tus últimas 4 semanas. Toca una fila para ver el detalle.',
    'מבוסס על 4 השבועות האחרונים. לחיצה על שורה מציגה את הפירוט.',
    'Basiert auf deinen letzten 4 Wochen. Tippe auf eine Zeile für Details.',
    'Basé sur tes 4 dernières semaines. Touche une ligne pour le détail.',
  ],
  'noScore': [
    'No score yet',
    'Aún sin puntuación',
    'עדיין אין ציון',
    'Noch kein Score',
    'Pas encore de score'
  ],
  'pausedS': ['Paused', 'En pausa', 'בהשהיה', 'Pausiert', 'En pause'],
  'startShort': [
    'Finish a workout to start',
    'Completa un entreno para empezar',
    'אימון אחד כדי להתחיל',
    'Ein Workout zum Start',
    'Une séance pour commencer',
  ],
  'shareText': [
    'My training score',
    'Mi puntuación de entreno',
    'ציון האימון שלי',
    'Mein Trainingsscore',
    "Mon score d'entraînement",
  ],
  'tStart': [
    'Finish a workout to get your score.',
    'Completa un entreno para ver tu puntuación.',
    'אחרי האימון הראשון יופיע כאן הציון.',
    'Schließ ein Workout ab, um deinen Score zu sehen.',
    'Termine une séance pour obtenir ton score.',
  ],
  'tPaused': [
    'No workouts in the last 4 weeks. One workout restarts your score.',
    'Sin entrenos en 4 semanas. Un entreno reactiva tu puntuación.',
    'אין אימונים ב-4 השבועות האחרונים. אימון אחד מחזיר את הציון.',
    'Keine Workouts in den letzten 4 Wochen. Ein Workout startet deinen Score neu.',
    'Aucune séance depuis 4 semaines. Une séance relance ton score.',
  ],
  'tConsMore': [
    '{n} more workouts this week to hit your goal of {g}.',
    '{n} entrenos más esta semana para llegar a tu meta de {g}.',
    'עוד {n} אימונים השבוע כדי להגיע ליעד של {g}.',
    'Noch {n} Workouts diese Woche bis zu deinem Ziel von {g}.',
    'Encore {n} séances cette semaine pour atteindre ton objectif de {g}.',
  ],
  'tConsMore1': [
    '1 more workout this week to hit your goal of {g}.',
    '1 entreno más esta semana para llegar a tu meta de {g}.',
    'עוד אימון אחד השבוע כדי להגיע ליעד של {g}.',
    'Noch 1 Workout diese Woche bis zu deinem Ziel von {g}.',
    'Encore 1 séance cette semaine pour atteindre ton objectif de {g}.',
  ],
  'tConsKeep': [
    'Goal hit this week. Keep the rhythm and the missed weeks fade out.',
    'Meta cumplida esta semana. Mantén el ritmo y las semanas flojas se diluyen.',
    'היעד השבועי הושג. שמירה על הקצב תמחק את השבועות החסרים.',
    'Wochenziel erreicht. Bleib dran, dann verblassen die verpassten Wochen.',
    "Objectif atteint cette semaine. Garde le rythme, les semaines manquées s'effacent.",
  ],
  'tFormFirst': [
    'Film one set. An AI form check replaces the default 50 in Form.',
    'Graba una serie. El análisis con IA sustituye el 50 por defecto en Técnica.',
    'צילום סט אחד: ניתוח ה-AI יחליף את ברירת המחדל 50 בטכניקה.',
    'Film einen Satz. Der KI-Form-Check ersetzt die 50 bei Technik.',
    "Filme une série. L'analyse IA remplace le 50 par défaut en Technique.",
  ],
  'tFormLow': [
    'Your form on {ex} averages {x}. Film it again and fix one cue.',
    'Tu técnica en {ex} promedia {x}. Grábala otra vez y corrige un punto.',
    'הטכניקה ב-{ex} בממוצע {x}. שווה לצלם שוב ולתקן דבר אחד.',
    'Deine Technik bei {ex} liegt im Schnitt bei {x}. Film sie nochmal und verbessere einen Punkt.',
    'Ta technique sur {ex} est à {x} en moyenne. Refilme-la et corrige un point.',
  ],
  'tBalWeak': [
    '{g} got only {p}% of your sets. Add one exercise for it.',
    '{g}: solo el {p}% de tus series. Añade un ejercicio.',
    '{g}: רק {p}% מהסטים. שווה להוסיף תרגיל אחד.',
    '{g}: nur {p}% deiner Sätze. Nimm eine Übung dazu.',
    '{g} : seulement {p}% de tes séries. Ajoute un exercice.',
  ],
  'tProgPush': [
    'Add a rep or a little weight on {ex} next time.',
    'Suma una repetición o un poco de peso en {ex} la próxima vez.',
    'בפעם הבאה ב-{ex}: עוד חזרה או קצת יותר משקל.',
    'Nächstes Mal bei {ex}: eine Wiederholung oder etwas Gewicht mehr.',
    'La prochaine fois sur {ex} : une répétition ou un peu de poids en plus.',
  ],
  'tGreat': [
    "You're training at the top of your game. Keep it up.",
    'Estás entrenando a tu mejor nivel. Sigue así.',
    'רמת אימון מעולה. להמשיך בדיוק ככה.',
    'Du trainierst auf Top-Niveau. Weiter so.',
    "Tu t'entraînes à ton meilleur niveau. Continue.",
  ],
  'g0': ['Chest', 'Pecho', 'חזה', 'Brust', 'Pectoraux'],
  'g1': ['Back', 'Espalda', 'גב', 'Rücken', 'Dos'],
  'g2': ['Shoulders', 'Hombros', 'כתפיים', 'Schultern', 'Épaules'],
  'g3': ['Legs', 'Piernas', 'רגליים', 'Beine', 'Jambes'],
  'g4': ['Arms', 'Brazos', 'ידיים', 'Arme', 'Bras'],
  'g5': ['Core', 'Core', 'ליבה', 'Core', 'Abdos'],
};

String _tr(String lang, String key, [Map<String, String>? vars]) {
  final List<String>? row = _kS[key];
  if (row == null) return key;
  final int i = _kLangs.indexOf(lang);
  String s = row[i < 0 ? 0 : i];
  if (vars != null) {
    vars.forEach((k, v) {
      s = s.replaceAll('{' + k + '}', v);
    });
  }
  return s;
}

String _langOf(BuildContext ctx) {
  try {
    final l = FFLocalizations.of(ctx).languageCode.trim().toLowerCase();
    return l.isEmpty ? 'en' : l;
  } catch (_) {
    return 'en';
  }
}

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------

int _toI(dynamic v, [int d = 0]) {
  if (v == null) return d;
  if (v is int) return v;
  if (v is num) return v.round();
  return num.tryParse(v.toString())?.round() ?? d;
}

double _toD(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().trim()) ?? 0.0;
}

DateTime? _parseDt(dynamic raw) {
  final s = (raw ?? '').toString().trim();
  if (s.isEmpty) return null;
  final parsed = DateTime.tryParse(s);
  if (parsed == null) return null;
  return parsed.isUtc ? parsed.toLocal() : parsed;
}

/// Calendar day as a running number (local date, safe across DST).
int _dayNo(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

double _c01(double v) => v < 0 ? 0.0 : (v > 1 ? 1.0 : v);

double _eo3(double p) => 1.0 - math.pow(1.0 - p, 3).toDouble();

/// Always one decimal: 8.7, 9.0.
String _fmt1(String lang, double v) {
  try {
    return intl.NumberFormat('0.0', lang).format(v);
  } catch (_) {
    return v.toStringAsFixed(1);
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

int _tierOf(int total) {
  if (total >= 90) return 4;
  if (total >= 75) return 3;
  if (total >= 60) return 2;
  if (total >= 40) return 1;
  return 0;
}

/// Theme text style at a real font weight. A Google Font is one file per
/// weight, so the weight has to go through GoogleFonts (a plain copyWith
/// would only fake the bold). The family is read from the theme style
/// itself: "Inter_regular" -> "Inter".
TextStyle _ts(BuildContext ctx, double size, FontWeight w, Color c,
    {double? height, double ls = 0}) {
  final TextStyle base = FlutterFlowTheme.of(ctx).bodyMedium;
  TextStyle s = base.copyWith(fontWeight: w);
  try {
    final String ff = base.fontFamily ?? '';
    final int cut = ff.lastIndexOf('_');
    final List<String> names = [cut > 0 ? ff.substring(0, cut) : ff];
    final List<String>? fallback = base.fontFamilyFallback;
    if (fallback != null && fallback.isNotEmpty) names.add(fallback.first);
    for (final String fam in names) {
      if (fam.isNotEmpty && GoogleFonts.asMap().containsKey(fam)) {
        s = GoogleFonts.getFont(fam, textStyle: base, fontWeight: w);
        break;
      }
    }
  } catch (_) {
    // Keep the plain theme style.
  }
  return s.copyWith(
    fontSize: size,
    color: c,
    height: height,
    letterSpacing: ls,
    fontFeatures: const [ui.FontFeature.tabularFigures()],
  );
}

/// primary_muscle_group name -> 0 chest, 1 back, 2 shoulders, 3 legs,
/// 4 arms (biceps, triceps, forearms), 5 core; -1 = not scored (neck).
int _groupOf(String rawName) {
  final String n = localizedName(rawName, 'en').trim().toLowerCase();
  if (n.contains('chest')) return 0;
  if (n.contains('shoulder')) return 2;
  if (n.contains('bicep') || n.contains('tricep') || n.contains('arm'))
    return 4;
  if (n.contains('back')) return 1;
  if (n.contains('leg') || n.contains('glute')) return 3;
  if (n.contains('core') || n.contains('abs') || n.contains('abdom')) return 5;
  return -1;
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

class _SetRow {
  const _SetRow(
      this.wid, this.ex, this.reps, this.w, this.dur, this.drop, this.assisted);
  final String wid;
  final int ex;
  final int reps;
  final double w; // kg
  final double dur; // seconds
  final bool drop;
  final bool assisted;
}

class _An {
  const _An(this.wid, this.ex, this.score);
  final String wid;
  final int ex;
  final double score; // 0..10
}

/// One exercise in one workout: its top set and its total volume there.
class _Sess {
  const _Sess(
      this.day, this.ts, this.kind, this.m, this.w, this.reps, this.vol);
  final int day;
  final int ts;
  final int kind; // 1 weighted, 2 reps only, 3 time
  final double m; // top set: est. 1RM (kg), reps, or seconds
  final double w; // weight of the top set (kind 1)
  final int reps; // reps of the top set (kind 1 and 2)
  final double
      vol; // everything done on the exercise: kg x reps, reps, or seconds
}

/// Running totals of one exercise in one workout.
class _Acc {
  double m1 = 0.0;
  double w1 = 0.0;
  int r1 = 0;
  double v1 = 0.0;
  double m2 = 0.0;
  double v2 = 0.0;
  double m3 = 0.0;
  double v3 = 0.0;
}

/// One exercise in the Progress breakdown: the latest session against the
/// one before it. cls: 1 up, 0 steady, -1 down.
class _ProgItem {
  const _ProgItem(this.name, this.kind, this.cls, this.byVolume, this.pw,
      this.pr, this.pm, this.lw, this.lr, this.lm);
  final String name; // raw exercise name
  final int kind;
  final int cls;
  final bool byVolume; // up thanks to more volume, top set about the same
  final double pw;
  final int pr;
  final double pm;
  final double lw;
  final int lr;
  final double lm;
}

class _FormItem {
  const _FormItem(this.name, this.avg, this.n);
  final String name; // raw exercise name
  final double avg;
  final int n;
}

/// The score at one point in time. state: 0 no workouts, 1 paused, 2 ok.
class _Score {
  const _Score({
    required this.state,
    this.total,
    this.consV = 0,
    this.done = 0,
    this.planned = 0,
    this.need = 0,
    this.weeks = 0,
    this.weekCounts = const <int>[],
    this.progV,
    this.up = 0,
    this.held = 0,
    this.down = 0,
    this.worstEx = '',
    this.prog = const <_ProgItem>[],
    this.formV,
    this.formAvg = 0,
    this.formN = 0,
    this.lowEx = '',
    this.lowAvg = 0,
    this.forms = const <_FormItem>[],
    this.balV,
    this.weak = -1,
    this.weakPct = 0,
    this.shares = const <double>[],
  });

  final int state;
  final int? total;
  final double consV;
  final int done;
  final int planned;
  final int need; // workouts still missing in the last 7 days
  final int weeks; // weeks that count (fewer for a new user)
  final List<int> weekCounts; // workouts per week, latest first
  final double? progV;
  final int up;
  final int held;
  final int down;
  final String worstEx; // raw exercise name, '' = none
  final List<_ProgItem> prog;
  final double? formV;
  final double formAvg;
  final int formN;
  final String lowEx; // raw exercise name, '' = none
  final double lowAvg;
  final List<_FormItem> forms;
  final double? balV;
  final int weak; // group index, -1 = none
  final double weakPct;
  final List<double> shares; // share of sets per group, empty = not measured
}

/// goalSrc: 0 default, 1 the weeklyGoal parameter, 2 the weekly plan,
/// 3 the user's own pace.
class _ScoreData {
  const _ScoreData(
      this.now, this.trend, this.goal, this.goalSrc, this.groupRaw);
  final _Score now;
  final List<int?> trend; // 8 weekly totals, oldest first; last = now
  final int goal;
  final int goalSrc;
  final List<String> groupRaw; // DB names of the six groups ('' = unknown)

  static _ScoreData empty(int goal) => _ScoreData(
        const _Score(state: 0),
        List<int?>.filled(8, null),
        goal,
        0,
        List<String>.filled(6, ''),
      );
}

class _Engine {
  _Engine();
  int goal = 3;
  final Map<String, int> logDay = {};
  final Map<String, int> logTs = {};
  int? first;
  final List<_SetRow> sets = [];
  final List<_An> ans = [];
  final Map<int, List<int>> exGroups = {};
  final Map<int, String> exName = {};
  final Map<int, List<_Sess>> sessions = {};

  /// Collapses the sets into one entry per exercise per workout.
  void prepare() {
    final Map<int, Map<String, _Acc>> acc = {};
    for (final s in sets) {
      if (s.assisted || s.drop) continue;
      if (!logDay.containsKey(s.wid)) continue;
      final Map<String, _Acc> byLog =
          acc.putIfAbsent(s.ex, () => <String, _Acc>{});
      final _Acc a = byLog.putIfAbsent(s.wid, () => _Acc());
      if (s.w > 0 && s.reps > 0) {
        // Epley, same as the Stats tab.
        final double orm = s.reps == 1 ? s.w : s.w * (1 + s.reps / 30.0);
        if (orm > a.m1) {
          a.m1 = orm;
          a.w1 = s.w;
          a.r1 = s.reps;
        }
        a.v1 += s.w * s.reps;
      } else if (s.reps > 0) {
        if (s.reps > a.m2) a.m2 = s.reps.toDouble();
        a.v2 += s.reps;
      } else if (s.dur > 0) {
        if (s.dur > a.m3) a.m3 = s.dur;
        a.v3 += s.dur;
      }
    }
    acc.forEach((ex, byLog) {
      final List<_Sess> list = [];
      byLog.forEach((wid, a) {
        final int day = logDay[wid] ?? 0;
        final int ts = logTs[wid] ?? 0;
        if (a.m1 > 0) {
          list.add(_Sess(day, ts, 1, a.m1, a.w1, a.r1, a.v1));
        } else if (a.m2 > 0) {
          list.add(_Sess(day, ts, 2, a.m2, 0.0, a.m2.round(), a.v2));
        } else if (a.m3 > 0) {
          list.add(_Sess(day, ts, 3, a.m3, 0.0, 0, a.v3));
        }
      });
      list.sort((x, y) => x.ts.compareTo(y.ts));
      sessions[ex] = list;
    });
  }

  /// The user's own pace: the typical number of workouts a week over the
  /// last 8 weeks (weeks without a workout don't count, so one break does
  /// not lower it). At least 2. Returns 0 with less than two weeks of
  /// history - too early to call it a habit.
  int habitGoal(int today) {
    final int? f = first;
    if (f == null || today - f < 13) return 0;
    final List<int> counts = [];
    for (int k = 0; k < 8; k++) {
      final int hi = today - 7 * k;
      if (hi < f) break;
      int c = 0;
      for (final int day in logDay.values) {
        if (day <= hi && day > hi - 7) c++;
      }
      if (c > 0) counts.add(c);
    }
    if (counts.isEmpty) return 0;
    counts.sort((x, y) => x.compareTo(y));
    final int med = counts[(counts.length - 1) ~/ 2];
    return med < 2 ? 2 : (med > 7 ? 7 : med);
  }

  /// The score as it stood on day [a].
  _Score at(int a) {
    final int? f = first;
    if (f == null || f > a) return const _Score(state: 0);

    // ---- consistency ----
    int weeks = ((a - f) ~/ 7) + 1;
    if (weeks > 4) weeks = 4;
    final List<int> n = [0, 0, 0, 0];
    int inWindow = 0;
    for (final int day in logDay.values) {
      final int d = a - day;
      if (d < 0 || d > 27) continue;
      inWindow++;
      n[d ~/ 7]++;
    }
    if (inWindow == 0) return const _Score(state: 1);
    int done = 0;
    for (int k = 0; k < weeks; k++) {
      done += n[k] < goal ? n[k] : goal;
    }
    final int planned = weeks * goal;
    final double consV = 100.0 * done / planned;
    final int need = n[0] >= goal ? 0 : goal - n[0];

    // ---- progress (progressive overload) ----
    // Per exercise: the latest session against the one before it. Two
    // signs count: the top set (est. 1RM / reps / time) and the total
    // volume of the exercise. More volume with the top set about the same
    // is progress too (at half strength); a better top set on much less
    // volume is not.
    double cSum = 0.0;
    int cN = 0, up = 0, held = 0, down = 0;
    int worst = -1;
    double worstE = 9.0;
    final List<_ProgItem> items = [];
    sessions.forEach((ex, list) {
      int li = -1;
      for (int i = list.length - 1; i >= 0; i--) {
        if (list[i].day <= a) {
          li = i;
          break;
        }
      }
      if (li < 0) return;
      final _Sess last = list[li];
      if (a - last.day > 27) return;
      int pi = -1;
      for (int i = li - 1; i >= 0; i--) {
        if (last.day - list[i].day > 60) break;
        if (list[i].kind == last.kind) {
          pi = i;
          break;
        }
      }
      if (pi < 0) return;
      final _Sess prev = list[pi];
      if (prev.m <= 0) return;
      final double r = last.m / prev.m;
      final double v = prev.vol > 0 ? last.vol / prev.vol : 1.0;
      double e = r;
      bool byVolume = false;
      if (r >= 0.98 && v > 1) {
        final double x = 1 + (v - 1) * 0.5;
        if (x > e) {
          e = x;
          byVolume = r < 1.02;
        }
      } else if (r > 1 && v < 0.85) {
        e = 1.0;
      }
      final double credit = e >= 1
          ? math.min(1.0, 0.7 + (e - 1) * 10)
          : math.max(0.2, 0.7 + (e - 1) * 6);
      cSum += credit;
      cN++;
      int cls = 0;
      if (e >= 1.02) {
        up++;
        cls = 1;
      } else if (e <= 0.98) {
        down++;
        cls = -1;
      } else {
        held++;
      }
      if (e < worstE) {
        worstE = e;
        worst = ex;
      }
      items.add(_ProgItem(
          exName[ex] ?? '',
          last.kind,
          cls,
          byVolume && cls == 1,
          prev.w,
          prev.reps,
          prev.m,
          last.w,
          last.reps,
          last.m));
    });
    items.sort(
        (x, y) => y.cls != x.cls ? y.cls - x.cls : x.name.compareTo(y.name));
    final double? progV = cN >= 2 ? 100.0 * cSum / cN : null;
    final String worstEx = (progV != null && worst >= 0 && worstE < 1.02)
        ? (exName[worst] ?? '')
        : '';

    // ---- form ----
    double fSum = 0.0;
    int fN = 0;
    final Map<int, List<double>> fx = {};
    for (final an in ans) {
      final int? day = logDay[an.wid];
      if (day == null) continue;
      final int d = a - day;
      if (d < 0 || d > 27 || an.score <= 0) continue;
      final double sc = an.score > 10 ? 10.0 : an.score;
      fSum += sc;
      fN++;
      final List<double> o = fx.putIfAbsent(an.ex, () => <double>[0.0, 0.0]);
      o[0] += sc;
      o[1] += 1;
    }
    double? formV;
    double formAvg = 0.0, lowAvg = 0.0;
    String lowEx = '';
    final List<_FormItem> forms = [];
    if (fN > 0) {
      formAvg = fSum / fN;
      formV = 10.0 * formAvg;
      double lo = 99.0;
      int loEx = -1;
      fx.forEach((ex, o) {
        final double av = o[0] / o[1];
        forms.add(_FormItem(exName[ex] ?? '', av, o[1].round()));
        if (av < lo) {
          lo = av;
          loEx = ex;
        }
      });
      forms.sort((x, y) =>
          x.avg != y.avg ? x.avg.compareTo(y.avg) : x.name.compareTo(y.name));
      lowAvg = lo;
      lowEx = exName[loEx] ?? '';
    }

    // ---- balance ----
    final List<double> gs = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    double total = 0.0;
    for (final s in sets) {
      if (s.drop) continue;
      final int? day = logDay[s.wid];
      if (day == null) continue;
      final int d = a - day;
      if (d < 0 || d > 27) continue;
      if (s.reps <= 0 && s.dur <= 0) continue;
      final List<int>? grp = exGroups[s.ex];
      if (grp == null || grp.isEmpty) continue;
      for (final int g in grp) {
        gs[g] += 1.0 / grp.length;
      }
      total += 1.0;
    }
    double? balV;
    int weak = -1;
    double weakPct = 0.0;
    final List<double> shares = [];
    if (inWindow >= 4 && total >= 30) {
      double sum = 0.0, weakD = 0.0;
      for (int i = 0; i < 6; i++) {
        final double share = gs[i] / total;
        shares.add(share);
        sum += math.min(1.0, share / _kMinShare[i]);
        final double deficit = _kMinShare[i] - share;
        if (deficit > weakD + 1e-9) {
          weakD = deficit;
          weak = i;
          weakPct = share * 100;
        }
      }
      balV = 100.0 * sum / 6;
    }

    final double t = _kWCons * consV +
        _kWProg * (progV ?? _kNeutral) +
        _kWForm * (formV ?? _kNeutral) +
        _kWBal * (balV ?? _kNeutral);
    return _Score(
      state: 2,
      total: t.round(),
      consV: consV,
      done: done,
      planned: planned,
      need: need,
      weeks: weeks,
      weekCounts: n,
      progV: progV,
      up: up,
      held: held,
      down: down,
      worstEx: worstEx,
      prog: items,
      formV: formV,
      formAvg: formAvg,
      formN: fN,
      lowEx: lowEx,
      lowAvg: lowAvg,
      forms: forms,
      balV: balV,
      weak: weak,
      weakPct: weakPct,
      shares: shares,
    );
  }
}

Future<_ScoreData> _loadScore(String userId, int? goalParam) async {
  final db = SQLiteManager.instance.database;
  final DateTime now = DateTime.now();
  final int today = _dayNo(now);
  // Everything the score and its 8-week trend can look at, with a margin.
  final DateTime cut = DateTime(now.year, now.month, now.day - 150);
  final String cutIso = cut.year.toString().padLeft(4, '0') +
      '-' +
      cut.month.toString().padLeft(2, '0') +
      '-' +
      cut.day.toString().padLeft(2, '0');

  List<Map<String, Object?>> wRows = const [];
  List<Map<String, Object?>> sRows = const [];
  List<Map<String, Object?>> mRows = const [];
  List<Map<String, Object?>> aRows = const [];
  try {
    wRows = await db.rawQuery(
      'SELECT id, created_at FROM workout_log WHERE user_id = ?',
      [userId],
    );
  } catch (_) {}
  try {
    sRows = await db.rawQuery(
      'SELECT sl.workout_log_id AS wid, sl.exercise_id AS ex, '
      'sl.reps AS reps, sl.weight AS weight, sl.is_kg AS is_kg, '
      'sl.duration_seconds AS dur, '
      'COALESCE(sl.is_dropset, 0) AS is_dropset, '
      'e.name AS ex_name, COALESCE(e.is_assisted, 0) AS is_assisted '
      'FROM set_log sl '
      'JOIN workout_log wl ON wl.id = sl.workout_log_id '
      'JOIN exercise e ON e.id = sl.exercise_id '
      'WHERE wl.user_id = ? AND (substr(wl.created_at, 1, 10) >= ? '
      "OR wl.created_at NOT GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*')",
      [userId, cutIso],
    );
  } catch (_) {}
  try {
    mRows = await db.rawQuery(
      'SELECT emg.exercise_id AS exercise_id, pmg.name AS gname '
      'FROM exercise_muscle_group emg '
      'JOIN muscle_group mg ON mg.id = emg.muscle_group_id '
      'JOIN primary_muscle_group pmg ON pmg.id = mg.primary_muscle_group_id '
      'WHERE COALESCE(emg.is_primary, 0) = 1',
    );
  } catch (_) {}
  try {
    aRows = await db.rawQuery(
      'SELECT sa.set_log_id AS sid, sa.score AS score, '
      'sl.workout_log_id AS wid, sl.exercise_id AS ex '
      'FROM set_analysis sa '
      'JOIN set_log sl ON sl.id = sa.set_log_id '
      'JOIN workout_log wl ON wl.id = sl.workout_log_id '
      'WHERE wl.user_id = ? AND sa.score IS NOT NULL',
      [userId],
    );
  } catch (_) {}

  final _Engine en = _Engine();

  for (final r in wRows) {
    final String id = (r['id'] ?? '').toString();
    final DateTime? dt = _parseDt(r['created_at']);
    if (id.isEmpty || dt == null) continue;
    final int day = _dayNo(dt);
    en.logDay[id] = day;
    en.logTs[id] = dt.millisecondsSinceEpoch;
    final int? f = en.first;
    if (f == null || day < f) en.first = day;
  }

  for (final r in sRows) {
    final int ex = _toI(r['ex']);
    final double raw = _toD(r['weight']);
    en.sets.add(_SetRow(
      (r['wid'] ?? '').toString(),
      ex,
      _toI(r['reps']),
      _toI(r['is_kg'], 1) == 1 ? raw : raw * 0.453592,
      _toD(r['dur']) / 1000.0, // stored in milliseconds
      _toI(r['is_dropset']) == 1,
      _toI(r['is_assisted']) == 1,
    ));
    en.exName.putIfAbsent(ex, () => (r['ex_name'] ?? '').toString());
  }

  final List<String> groupRaw = List<String>.filled(6, '');
  final Map<String, int> groupCache = {};
  for (final r in mRows) {
    final String gname = (r['gname'] ?? '').toString();
    if (gname.isEmpty) continue;
    final int g = groupCache.putIfAbsent(gname, () => _groupOf(gname));
    if (g < 0) continue;
    if (g != 4 && groupRaw[g].isEmpty) groupRaw[g] = gname;
    final List<int> l =
        en.exGroups.putIfAbsent(_toI(r['exercise_id']), () => <int>[]);
    if (!l.contains(g)) l.add(g);
  }

  final Set<String> seen = <String>{};
  for (final r in aRows) {
    final String sid = (r['sid'] ?? '').toString();
    final double sc = _toD(r['score']);
    if (sc <= 0 || !seen.add(sid)) continue;
    en.ans.add(_An((r['wid'] ?? '').toString(), _toI(r['ex']), sc));
  }

  en.prepare();

  // The weekly goal: the parameter if given, else the saved weekly plan
  // (WeekPlanner), else the user's own pace, else 3.
  int goal = 3;
  int goalSrc = 0;
  if (goalParam != null) {
    goal = goalParam;
    goalSrc = 1;
  } else {
    int planGoal = 0;
    try {
      final pRows = await db.rawQuery(
          'SELECT per_week, slots FROM training_plan WHERE id = ?', [userId]);
      if (pRows.isNotEmpty) {
        final String slots = (pRows.first['slots'] ?? '').toString().trim();
        if (slots.isNotEmpty && slots != '[]') {
          planGoal = _toI(pRows.first['per_week']);
        }
      }
    } catch (_) {
      // No plan table yet - fine.
    }
    if (planGoal >= 1) {
      goal = planGoal > 7 ? 7 : planGoal;
      goalSrc = 2;
    } else {
      final int habit = en.habitGoal(today);
      if (habit > 0) {
        goal = habit;
        goalSrc = 3;
      }
    }
  }
  en.goal = goal;

  final List<int?> trend = [];
  _Score nowScore = const _Score(state: 0);
  for (int k = 7; k >= 0; k--) {
    final _Score s = en.at(today - 7 * k);
    trend.add(s.total);
    if (k == 0) nowScore = s;
  }
  return _ScoreData(nowScore, trend, goal, goalSrc, groupRaw);
}

/// Sample data for [TrainingScore.demoMode].
_ScoreData _demoScore(int goal) {
  const _Score s = _Score(
    state: 2,
    total: 86,
    consV: 91.7,
    done: 11,
    planned: 12,
    need: 0,
    progV: 76,
    up: 3,
    held: 6,
    down: 1,
    worstEx: 'Bench Press',
    formV: 84,
    formAvg: 8.4,
    formN: 6,
    lowEx: 'Romanian Deadlift',
    lowAvg: 7.6,
    balV: 92,
    weak: 5,
    weakPct: 2,
    weeks: 4,
    weekCounts: <int>[3, 3, 2, 3],
    prog: <_ProgItem>[
      _ProgItem('Squat', 1, 1, false, 100, 5, 116.7, 102.5, 5, 119.6),
      _ProgItem('Barbell Row', 1, 1, true, 70, 8, 88.7, 70, 8, 88.7),
      _ProgItem('Pull-up', 2, 1, false, 0, 10, 10, 0, 11, 11),
      _ProgItem('Overhead Press', 1, 0, false, 50, 6, 60, 50, 6, 60),
      _ProgItem('Bench Press', 1, -1, false, 82.5, 5, 96.3, 80, 5, 93.3),
    ],
    forms: <_FormItem>[
      _FormItem('Romanian Deadlift', 7.6, 2),
      _FormItem('Squat', 8.8, 4),
    ],
    shares: <double>[0.22, 0.24, 0.12, 0.28, 0.12, 0.02],
  );
  return _ScoreData(
    s,
    const <int?>[71, 74, 73, 78, 80, 79, 83, 86],
    goal,
    0,
    List<String>.filled(6, ''),
  );
}

// ---------------------------------------------------------------------------
// View helpers
// ---------------------------------------------------------------------------

class _Pal {
  _Pal(FlutterFlowTheme th)
      : primary = th.primary,
        bg = th.primaryBackground,
        card = th.secondaryBackground,
        line = th.alternate,
        ink = th.primaryText,
        soft = th.secondaryText {
    final bool light = card.computeLuminance() > 0.5;
    final Color pole = light ? Colors.black : Colors.white;
    mint = Color.alphaBlend(primary.withAlpha(light ? 0x38 : 0x40), card);
    mintLine = primary.withAlpha(0x59);
    mintInk = Color.lerp(primary, pole, light ? 0.68 : 0.78)!;
    mintSoft = Color.lerp(primary, pole, light ? 0.42 : 0.5)!;
    mute = Color.lerp(line, soft, 0.35)!;
  }

  final Color primary;
  final Color bg;
  final Color card;
  final Color line;
  final Color ink;
  final Color soft;
  late final Color mint;
  late final Color mintLine;
  late final Color mintInk;
  late final Color mintSoft;
  late final Color mute;
}

/// kind: 0 first score, 1 same as last week, 2 up, 3 down.
class _Delta {
  const _Delta(this.kind, this.n);
  final int kind;
  final int n;
}

_Delta? _deltaOf(_ScoreData d) {
  final int? total = d.now.total;
  if (total == null || d.trend.length < 2) return null;
  final int? prev = d.trend[d.trend.length - 2];
  if (prev == null) {
    for (int i = 0; i < d.trend.length - 2; i++) {
      if (d.trend[i] != null) return null;
    }
    return const _Delta(0, 0);
  }
  final int diff = total - prev;
  if (diff == 0) return const _Delta(1, 0);
  return _Delta(diff > 0 ? 2 : 3, diff.abs());
}

class _Tip {
  const _Tip(this.text, this.formAction);
  final String text;
  final bool formAction;
}

String _groupName(String lang, _ScoreData d, int g) {
  if (g != 4 && g >= 0 && g < d.groupRaw.length && d.groupRaw[g].isNotEmpty) {
    return localizedName(d.groupRaw[g], lang);
  }
  return _tr(lang, 'g' + g.toString());
}

/// The single most useful thing to do next: the pillar with the most
/// points left on the table.
_Tip _tipOf(String lang, _ScoreData d) {
  final _Score s = d.now;
  if (s.state == 0) return _Tip(_tr(lang, 'tStart'), false);
  if (s.state == 1) return _Tip(_tr(lang, 'tPaused'), false);
  final String g = d.goal.toString();
  final double? fv = s.formV;
  final double? bv = s.balV;
  final double? pv = s.progV;
  final double pc = _kWCons * (100 - s.consV);
  final double pf = fv != null ? _kWForm * (100 - fv) : _kWForm * 30;
  final double pb = bv != null ? _kWBal * (100 - bv) : 0.0;
  final double pp = pv != null ? _kWProg * (100 - pv) : 0.0;
  int best = 0;
  double top = pc;
  if (pf > top + 1e-9) {
    best = 1;
    top = pf;
  }
  if (pb > top + 1e-9) {
    best = 2;
    top = pb;
  }
  if (pp > top + 1e-9) {
    best = 3;
    top = pp;
  }
  final _Tip great = _Tip(_tr(lang, 'tGreat'), false);
  if ((s.total ?? 0) >= 90 || top < 2) return great;
  if (best == 0) {
    if (s.need > 1) {
      return _Tip(
          _tr(lang, 'tConsMore', {'n': s.need.toString(), 'g': g}), false);
    }
    if (s.need == 1) return _Tip(_tr(lang, 'tConsMore1', {'g': g}), false);
    return _Tip(_tr(lang, 'tConsKeep'), false);
  }
  if (best == 1) {
    if (fv == null) return _Tip(_tr(lang, 'tFormFirst'), true);
    if (s.lowEx.isEmpty) return great;
    return _Tip(
      _tr(lang, 'tFormLow',
          {'ex': localizedName(s.lowEx, lang), 'x': _fmt1(lang, s.lowAvg)}),
      true,
    );
  }
  if (best == 2) {
    if (s.weak < 0) return great;
    return _Tip(
      _tr(lang, 'tBalWeak', {
        'g': _groupName(lang, d, s.weak),
        'p': s.weakPct.round().toString()
      }),
      false,
    );
  }
  if (s.worstEx.isEmpty) return great;
  return _Tip(
      _tr(lang, 'tProgPush', {'ex': localizedName(s.worstEx, lang)}), false);
}

class _Row {
  const _Row(this.icon, this.nameKey, this.weight, this.value, this.muted,
      this.detail);
  final IconData icon;
  final String nameKey;
  final int weight;
  final double? value;
  final bool muted;
  final String detail;
}

List<_Row> _rowsOf(String lang, _ScoreData? d) {
  const IconData iCons = Icons.event_available_rounded;
  const IconData iProg = Icons.trending_up_rounded;
  const IconData iForm = Icons.videocam_rounded;
  const IconData iBal = Icons.balance_rounded;
  if (d == null || d.now.state != 2) {
    // Nothing to score yet: say what each pillar measures.
    return [
      _Row(iCons, 'cons', 35, null, true, _tr(lang, 'consInfo')),
      _Row(iProg, 'prog', 25, null, true, _tr(lang, 'progInfo')),
      _Row(iForm, 'form', 20, null, true, _tr(lang, 'formInfo')),
      _Row(iBal, 'bal', 20, null, true, _tr(lang, 'balInfo')),
    ];
  }
  final _Score s = d.now;
  final double? pv = s.progV;
  final double? fv = s.formV;
  final double? bv = s.balV;
  final String progD = pv == null
      ? _tr(lang, 'notYet')
      : _tr(lang, 'progD', {
          'u': s.up.toString(),
          'h': s.held.toString(),
          'd': s.down.toString(),
        });
  final String formD = fv == null
      ? _tr(lang, 'formNone')
      : _tr(lang, s.formN == 1 ? 'formD1' : 'formD',
          {'x': _fmt1(lang, s.formAvg), 'n': s.formN.toString()});
  final String balD = bv == null
      ? _tr(lang, 'notYet')
      : (s.weak >= 0
          ? _tr(lang, 'balWeak', {
              'g': _groupName(lang, d, s.weak),
              'p': s.weakPct.round().toString()
            })
          : _tr(lang, 'balOk'));
  return [
    _Row(
        iCons,
        'cons',
        35,
        s.consV,
        false,
        _tr(lang, 'consD',
                {'a': s.done.toString(), 'b': s.planned.toString()}) +
            ' · ' +
            _tr(
                lang,
                d.goalSrc == 2
                    ? 'srcPlan'
                    : (d.goalSrc == 3 ? 'srcHabit' : 'srcGoal'),
                {'g': d.goal.toString()})),
    _Row(iProg, 'prog', 25, pv ?? _kNeutral, pv == null, progD),
    _Row(iForm, 'form', 20, fv ?? _kNeutral, fv == null, formD),
    _Row(iBal, 'bal', 20, bv ?? _kNeutral, bv == null, balD),
  ];
}

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------

/// 270-degree gauge, open at the bottom, with notches at the tier limits.
class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.value,
    required this.color,
    required this.track,
    required this.notch,
    required this.radius,
    required this.stroke,
    required this.cy,
    required this.notchWidth,
  });

  final double value; // 0..100
  final Color color;
  final Color track;
  final Color notch;
  final double radius;
  final double stroke;
  final double cy;
  final double notchWidth;

  static const double _start = math.pi * 0.75; // 135 degrees
  static const double _sweep = math.pi * 1.5; // 270 degrees

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, cy);
    final Rect rect = Rect.fromCircle(center: c, radius: radius);
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = track;
    canvas.drawArc(rect, _start, _sweep, false, p);
    final double v = value < 0 ? 0.0 : (value > 100 ? 100.0 : value);
    if (v > 0.3) {
      p.color = color;
      canvas.drawArc(rect, _start, _sweep * v / 100, false, p);
    }
    final Paint n = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = notchWidth
      ..isAntiAlias = true
      ..color = notch;
    final double r0 = radius - stroke / 2 - 1;
    final double r1 = radius + stroke / 2 + 1;
    for (final double limit in const [40.0, 60.0, 75.0, 90.0]) {
      final double a = _start + _sweep * limit / 100;
      canvas.drawLine(
        Offset(c.dx + r0 * math.cos(a), c.dy + r0 * math.sin(a)),
        Offset(c.dx + r1 * math.cos(a), c.dy + r1 * math.sin(a)),
        n,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value ||
      old.color != color ||
      old.track != track ||
      old.notch != notch ||
      old.radius != radius;
}

/// Weekly score line, oldest on the left. Weeks without a score are gaps.
class _SparkPainter extends CustomPainter {
  const _SparkPainter({
    required this.points,
    required this.progress,
    required this.color,
    required this.ring,
    required this.fillAlpha,
  });

  final List<int?> points;
  final double progress; // 0..1, reveals from the left
  final Color color;
  final Color ring;
  final int fillAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final int n = points.length;
    final List<int> vals = [
      for (final int? v in points)
        if (v != null) v
    ];
    if (n < 2 || vals.isEmpty) return;
    double lo = vals.reduce(math.min).toDouble() - 4;
    double hi = vals.reduce(math.max).toDouble() + 4;
    if (hi - lo < 16) {
      final double m = (hi + lo) / 2;
      lo = m - 8;
      hi = m + 8;
    }
    const double px = 5.0;
    final double stepX = (size.width - 2 * px) / (n - 1);
    final Path line = Path();
    final Path area = Path();
    final List<Offset> run = [];
    Offset? last;

    void flush() {
      if (run.isEmpty) return;
      line.moveTo(run.first.dx, run.first.dy);
      for (int i = 1; i < run.length; i++) {
        line.lineTo(run[i].dx, run[i].dy);
      }
      if (run.length > 1) {
        area.moveTo(run.first.dx, size.height);
        for (final Offset o in run) {
          area.lineTo(o.dx, o.dy);
        }
        area.lineTo(run.last.dx, size.height);
        area.close();
      }
      run.clear();
    }

    for (int i = 0; i < n; i++) {
      final int? v = points[i];
      if (v == null) {
        flush();
      } else {
        final Offset o = Offset(
          px + i * stepX,
          5 + (size.height - 10) * (1 - (v - lo) / (hi - lo)),
        );
        run.add(o);
        last = o;
      }
    }
    flush();

    canvas.save();
    canvas.clipRect(
        Rect.fromLTWH(0, 0, size.width * _c01(progress), size.height));
    canvas.drawPath(
      area,
      Paint()
        ..style = PaintingStyle.fill
        ..color = color.withAlpha(fillAlpha),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..color = color,
    );
    final Offset? end = last;
    if (end != null) {
      canvas.drawCircle(end, 5, Paint()..color = ring);
      canvas.drawCircle(end, 3.2, Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.progress != progress || old.points != points || old.color != color;
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class _TrainingScoreState extends State<TrainingScore>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  final GlobalKey _shareKey = GlobalKey();

  _ScoreData? _data;
  int _token = 0;
  bool _sharing = false;
  int _openRow = -1; // the pillar whose breakdown is open, -1 = none
  ModalRoute<dynamic>? _route;

  bool get _isCompact => widget.compact ?? false;

  /// The weeklyGoal parameter, or null = work it out (plan, then pace).
  int? get _goalParam {
    final int? g = widget.weeklyGoal;
    if (g == null) return null;
    return g < 1 ? 1 : (g > 7 ? 7 : g);
  }

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when a page opened on top of this one is closed again
    // (for example: back from a finished workout).
    final ModalRoute<dynamic>? r = ModalRoute.of(context);
    if (!identical(r, _route)) {
      _route?.secondaryAnimation?.removeStatusListener(_onRouteStatus);
      _route = r;
      _route?.secondaryAnimation?.addStatusListener(_onRouteStatus);
    }
  }

  @override
  void didUpdateWidget(covariant TrainingScore old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId ||
        old.weeklyGoal != widget.weeklyGoal ||
        old.demoMode != widget.demoMode ||
        old.refreshKey != widget.refreshKey) {
      _load();
    }
  }

  @override
  void dispose() {
    _route?.secondaryAnimation?.removeStatusListener(_onRouteStatus);
    _ac.dispose();
    super.dispose();
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && mounted) {
      _load(quiet: true);
    }
  }

  // ---------- data ----------
  Future<void> _load({bool quiet = false}) async {
    final int token = ++_token;
    final int? goal = _goalParam;
    _ScoreData d;
    try {
      if (widget.demoMode ?? false) {
        await Future<void>.value(); // keeps setState out of the build phase
        d = _demoScore(goal ?? 3);
      } else {
        d = await _loadScore(widget.userId, goal);
      }
    } catch (_) {
      d = _ScoreData.empty(goal ?? 3);
    }
    if (!mounted || token != _token) return;
    final _ScoreData? old = _data;
    final bool changed = old == null ||
        old.now.total != d.now.total ||
        old.now.state != d.now.state;
    setState(() {
      _data = d;
    });
    if (!quiet || changed) {
      final bool still =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (still) {
        _ac.value = 1.0;
      } else {
        _ac.forward(from: 0.0);
      }
    }
  }

  // ---------- actions ----------
  void _open() {
    HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  void _close() {
    HapticFeedback.selectionClick();
    widget.onClose?.call();
  }

  void _formCheck() {
    HapticFeedback.selectionClick();
    widget.onFormCheck?.call();
  }

  Future<void> _share() async {
    if (_sharing) return;
    _sharing = true;
    HapticFeedback.selectionClick();
    try {
      final String lang = _langOf(context);
      final int? total = _data?.now.total;
      final RenderObject? ro = _shareKey.currentContext?.findRenderObject();
      if (ro is RenderRepaintBoundary && total != null) {
        final Size screen = MediaQuery.of(context).size;
        final ui.Image img = await ro.toImage(pixelRatio: 3.0);
        final ByteData? bytes =
            await img.toByteData(format: ui.ImageByteFormat.png);
        img.dispose();
        if (bytes != null) {
          final Directory dir = await getTemporaryDirectory();
          final int stamp = DateTime.now().millisecondsSinceEpoch;
          final String caption = _tr(lang, 'shareText') +
              ': ' +
              total.toString() +
              ' · ' +
              _kBrand;
          final File file =
              File(dir.path + '/score_' + stamp.toString() + '.png');
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
      // Sharing is best-effort; the page keeps working.
    } finally {
      _sharing = false;
    }
  }

  // ---------- shared pieces ----------
  Widget _deltaView(
      BuildContext context, String lang, _Delta dl, Color fg, double size) {
    final String label = dl.kind == 0
        ? _tr(lang, 'first')
        : (dl.kind == 1 ? _tr(lang, 'same') : _tr(lang, 'vsWeek'));
    final TextStyle st = _ts(context, size, FontWeight.w600, fg, height: 1.2);
    if (dl.kind < 2) {
      return Text(label,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: st);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          dl.kind == 2
              ? Icons.arrow_drop_up_rounded
              : Icons.arrow_drop_down_rounded,
          size: size + 8,
          color: fg,
        ),
        Text(dl.n.toString(), style: st),
        const SizedBox(width: 4),
        Flexible(
          child: Text(label,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: st),
        ),
      ],
    );
  }

  // ---------- compact card ----------
  Widget _card(BuildContext context, String lang, double t) {
    final _Pal p = _Pal(FlutterFlowTheme.of(context));
    final _ScoreData? d = _data;
    final int? total = d?.now.total;
    final double shown = total == null ? 0.0 : total * _eo3(_c01(t / 0.95));
    final List<int?> trend = d?.trend ?? const <int?>[];
    final int points = trend.where((v) => v != null).length;
    final _Delta? delta = d == null ? null : _deltaOf(d);

    String big = '';
    Widget third = const SizedBox(height: 15);
    if (d != null) {
      if (total != null) {
        big = _tr(lang, 't' + _tierOf(total).toString());
        if (delta != null) {
          third = _deltaView(context, lang, delta,
              delta.kind == 2 ? p.mintSoft : p.soft, 12.5);
        }
      } else {
        big = _tr(lang, d.now.state == 1 ? 'pausedS' : 'noScore');
        third = Text(
          _tr(lang, 'startShort'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _ts(context, 12.5, FontWeight.w500, p.soft, height: 1.2),
        );
      }
    }

    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.line, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap == null ? null : _open,
        splashColor: p.primary.withAlpha(0x22),
        highlightColor: p.primary.withAlpha(0x14),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 10, 0),
          child: Row(
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GaugePainter(
                          value: shown,
                          color: p.primary,
                          track: p.line,
                          notch: p.card,
                          radius: 27,
                          stroke: 7,
                          cy: 34,
                          notchWidth: 2,
                        ),
                      ),
                    ),
                    if (d != null)
                      Text(
                        total == null ? '–' : shown.round().toString(),
                        style: _ts(context, 24, FontWeight.w800,
                            total == null ? p.mute : p.ink,
                            height: 1.0, ls: -0.8),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr(lang, 'title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(context, 12.5, FontWeight.w500, p.soft,
                          height: 1.2),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        big,
                        maxLines: 1,
                        style: _ts(context, 19, FontWeight.w700, p.ink,
                            height: 1.15, ls: -0.3),
                      ),
                    ),
                    const SizedBox(height: 3),
                    third,
                  ],
                ),
              ),
              if (points >= 2) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 58,
                  height: 28,
                  child: CustomPaint(
                    painter: _SparkPainter(
                      points: trend,
                      progress: _eo3(_c01((t - 0.2) / 0.9)),
                      color: p.primary,
                      ring: p.card,
                      fillAlpha: 36,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: p.soft, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- half-width tile ----------
  Widget _tile(BuildContext context, String lang, double t) {
    final _Pal p = _Pal(FlutterFlowTheme.of(context));
    final _ScoreData? d = _data;
    final int? total = d?.now.total;
    final double shown = total == null ? 0.0 : total * _eo3(_c01(t / 0.95));
    final _Delta? delta = d == null ? null : _deltaOf(d);
    String big = '';
    Widget last = const SizedBox(height: 14);
    if (d != null) {
      if (total != null) {
        big = _tr(lang, 't' + _tierOf(total).toString());
        if (delta != null) {
          last = _deltaView(context, lang, delta,
              delta.kind == 2 ? p.mintSoft : p.soft, 11.5);
        }
      } else {
        big = _tr(lang, d.now.state == 1 ? 'pausedS' : 'noScore');
        last = Text(
          _tr(lang, 'startShort'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _ts(context, 11.5, FontWeight.w500, p.soft, height: 1.2),
        );
      }
    }
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap == null ? null : _open,
        splashColor: p.primary.withAlpha(0x22),
        highlightColor: p.primary.withAlpha(0x14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tr(lang, 'title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _ts(context, 12, FontWeight.w500, p.soft, height: 1.2),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _GaugePainter(
                              value: shown,
                              color: p.primary,
                              track: p.line,
                              notch: p.card,
                              radius: 24,
                              stroke: 6.5,
                              cy: 30,
                              notchWidth: 2,
                            ),
                          ),
                        ),
                        if (d != null)
                          Text(
                            total == null ? '–' : shown.round().toString(),
                            style: _ts(context, 21, FontWeight.w800,
                                total == null ? p.mute : p.ink,
                                height: 1.0, ls: -0.6),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        big,
                        maxLines: 1,
                        style: _ts(context, 18, FontWeight.w700, p.ink,
                            height: 1.15, ls: -0.3),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              last,
            ],
          ),
        ),
      ),
    );
  }

  // ---------- full page ----------
  Widget _roundBtn(_Pal p, IconData icon, double size, VoidCallback onTap) {
    return Material(
      color: p.card,
      shape: CircleBorder(side: BorderSide(color: p.line, width: 1)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: p.ink, size: size),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String lang, _Pal p) {
    final bool canShare = _data?.now.total != null;
    return Row(
      children: [
        if (widget.onClose != null) ...[
          _roundBtn(p, Icons.arrow_back_ios_new_rounded, 18, _close),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              _tr(lang, 'title'),
              maxLines: 1,
              style: _ts(context, 26, FontWeight.w700, p.ink,
                  height: 1.15, ls: -0.4),
            ),
          ),
        ),
        if (canShare) ...[
          const SizedBox(width: 12),
          _roundBtn(p, Icons.ios_share_rounded, 19, _share),
        ],
      ],
    );
  }

  Widget _hero(BuildContext context, String lang, bool rtl, _Pal p, double t) {
    final _ScoreData? d = _data;
    final int? total = d?.now.total;
    final double shown = total == null ? 0.0 : total * _eo3(_c01(t / 1.15));
    final List<int?> trend = d?.trend ?? const <int?>[];
    final int points = trend.where((v) => v != null).length;
    final _Delta? delta = d == null ? null : _deltaOf(d);
    final String title = _tr(lang, 'title');
    final Color onSoft = Colors.white.withAlpha(158);
    final Color onTrack = Colors.white.withAlpha(28);

    final List<Widget> inGauge = [
      Positioned.fill(
        child: CustomPaint(
          painter: _GaugePainter(
            value: shown,
            color: p.primary,
            track: onTrack,
            notch: _kHero,
            radius: 92,
            stroke: 16,
            cy: 104,
            notchWidth: 2.5,
          ),
        ),
      ),
    ];
    if (d != null && total != null) {
      inGauge.add(Positioned(
        left: 0,
        right: 0,
        top: 50,
        child: Text(
          shown.round().toString(),
          textAlign: TextAlign.center,
          style: _ts(context, 68, FontWeight.w800, Colors.white,
              height: 1.0, ls: -2.5),
        ),
      ));
      inGauge.add(Positioned(
        left: 0,
        right: 0,
        top: 124,
        child: Text(
          _tr(lang, 't' + _tierOf(total).toString()),
          textAlign: TextAlign.center,
          maxLines: 1,
          style: _ts(context, 15, FontWeight.w700, p.primary, height: 1.2),
        ),
      ));
      if (delta != null) {
        final bool up = delta.kind == 2;
        inGauge.add(Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Center(
            child: Container(
              height: 26,
              padding: EdgeInsetsDirectional.fromSTEB(
                  delta.kind >= 2 ? 5 : 11, 0, 11, 0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: up ? p.primary.withAlpha(46) : onTrack,
                borderRadius: BorderRadius.circular(13),
              ),
              child: _deltaView(context, lang, delta,
                  up ? Color.lerp(p.primary, Colors.white, 0.45)! : onSoft, 12),
            ),
          ),
        ));
      }
    } else if (d != null) {
      inGauge.add(Positioned(
        left: 0,
        right: 0,
        top: 44,
        child: Text(
          '–',
          textAlign: TextAlign.center,
          style: _ts(context, 68, FontWeight.w800, Colors.white.withAlpha(90),
              height: 1.0),
        ),
      ));
      inGauge.add(Positioned(
        left: 22,
        right: 22,
        top: 112,
        child: Text(
          _tr(lang, d.now.state == 1 ? 'pausedS' : 'noScore'),
          textAlign: TextAlign.center,
          maxLines: 2,
          style: _ts(context, 14, FontWeight.w600, onSoft, height: 1.35),
        ),
      ));
    }

    final List<Widget> kids = [
      Row(
        children: [
          Expanded(
            child: Text(
              rtl ? title : title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _ts(context, rtl ? 12 : 11, FontWeight.w600, onSoft,
                  height: 1.2, ls: rtl ? 0 : 1.3),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _kBrand,
            textDirection: ui.TextDirection.ltr,
            style: _ts(context, 11, FontWeight.w800, p.primary,
                height: 1.2, ls: 2.4),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Center(
        child:
            SizedBox(width: 220, height: 200, child: Stack(children: inGauge)),
      ),
    ];
    if (points >= 2) {
      kids.add(const SizedBox(height: 14));
      kids.add(Row(
        children: [
          Text(
            _tr(lang, 'trend'),
            style: _ts(context, 11.5, FontWeight.w500, onSoft, height: 1.2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 40,
              child: CustomPaint(
                painter: _SparkPainter(
                  points: trend,
                  progress: _eo3(_c01((t - 0.35) / 0.95)),
                  color: p.primary,
                  ring: _kHero,
                  fillAlpha: 40,
                ),
              ),
            ),
          ),
        ],
      ));
    }

    // The RepaintBoundary is what gets shared: a square-cornered dark card.
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: RepaintBoundary(
        key: _shareKey,
        child: Container(
          color: _kHero,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: kids),
        ),
      ),
    );
  }

  Widget _tipCard(BuildContext context, String lang, _Pal p, _Tip tip) {
    final bool act = tip.formAction && widget.onFormCheck != null;
    return Material(
      color: p.mint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.mintLine, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: act ? _formCheck : null,
        splashColor: p.primary.withAlpha(0x22),
        highlightColor: p.primary.withAlpha(0x14),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 13, 12, 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration:
                    BoxDecoration(color: p.primary, shape: BoxShape.circle),
                child: const Icon(Icons.bolt_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _tr(lang, 'next'),
                      style: _ts(context, 11.5, FontWeight.w600, p.mintSoft,
                          height: 1.2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tip.text,
                      style: _ts(context, 14, FontWeight.w600, p.mintInk,
                          height: 1.35),
                    ),
                  ],
                ),
              ),
              if (act) ...[
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, color: p.mintSoft, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------- pillar breakdowns ----------
  String _topLabel(String lang, int kind, double w, int reps, double m) {
    if (kind == 1) return _fmtNum(lang, w) + ' kg × ' + reps.toString();
    if (kind == 2) return _tr(lang, 'repsN', {'n': reps.toString()});
    final int s = m.round();
    return (s ~/ 60).toString() + ':' + (s % 60).toString().padLeft(2, '0');
  }

  Widget _line(BuildContext context, _Pal p, String label, String value,
      {IconData? icon, Color? iconColor, bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: iconColor ?? p.soft),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _ts(context, 12.5, FontWeight.w500, p.ink, height: 1.3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            textDirection: ui.TextDirection.ltr,
            style: _ts(
                context,
                12.5,
                strong ? FontWeight.w700 : FontWeight.w500,
                strong ? p.ink : p.soft,
                height: 1.3),
          ),
        ],
      ),
    );
  }

  /// What is behind one pillar: the weeks, the exercises, the muscle shares.
  List<Widget> _details(
      BuildContext context, String lang, _Pal p, int index, _ScoreData d) {
    final _Score s = d.now;
    final List<Widget> out = [];
    if (index == 0) {
      for (int k = 0; k < s.weeks && k < s.weekCounts.length; k++) {
        out.add(_line(
          context,
          p,
          k == 0
              ? _tr(lang, 'wkNow')
              : _tr(lang, 'wkAgo',
                  {'a': (7 * k + 1).toString(), 'b': (7 * k + 7).toString()}),
          s.weekCounts[k].toString() + ' / ' + d.goal.toString(),
          strong: s.weekCounts[k] >= d.goal,
        ));
      }
      if (d.goalSrc == 0 || d.goalSrc == 3) {
        out.add(Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_tr(lang, 'planHint'),
              style: _ts(context, 12, FontWeight.w400, p.soft, height: 1.35)),
        ));
      }
    } else if (index == 1) {
      for (int i = 0; i < s.prog.length && i < 16; i++) {
        final _ProgItem it = s.prog[i];
        final String last = _topLabel(lang, it.kind, it.lw, it.lr, it.lm);
        final String value = it.byVolume
            ? last + ' · ' + _tr(lang, 'moreVol')
            : _topLabel(lang, it.kind, it.pw, it.pr, it.pm) + ' → ' + last;
        out.add(_line(
          context,
          p,
          localizedName(it.name, lang),
          value,
          icon: it.cls > 0
              ? Icons.arrow_upward_rounded
              : (it.cls < 0
                  ? Icons.arrow_downward_rounded
                  : Icons.remove_rounded),
          iconColor: it.cls > 0 ? p.primary : p.soft,
          strong: it.cls > 0,
        ));
      }
    } else if (index == 2) {
      for (final _FormItem it in s.forms) {
        out.add(_line(context, p, localizedName(it.name, lang),
            _fmt1(lang, it.avg) + '  ·  ' + it.n.toString()));
      }
    } else if (s.shares.length == 6) {
      for (int g = 0; g < 6; g++) {
        final bool low = s.shares[g] < _kMinShare[g];
        out.add(_line(
          context,
          p,
          _groupName(lang, d, g),
          (s.shares[g] * 100).round().toString() +
              '%' +
              (low ? '  ·  ' + _tr(lang, 'low') : ''),
          strong: !low,
        ));
      }
    }
    if (out.isEmpty) {
      out.add(Padding(
        padding: const EdgeInsets.only(top: 7),
        child: Text(_tr(lang, 'noDetail'),
            style: _ts(context, 12.5, FontWeight.w400, p.soft, height: 1.3)),
      ));
    }
    return out;
  }

  Widget _pillarRow(
      BuildContext context, String lang, _Pal p, _Row r, double e, int index) {
    final double? v = r.value;
    final String shown = v == null ? '–' : (v * e).round().toString();
    final _ScoreData? d = _data;
    final bool can = d != null && d.now.state == 2;
    final bool open = can && _openRow == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: can
          ? () {
              HapticFeedback.selectionClick();
              setState(() {
                _openRow = open ? -1 : index;
              });
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: p.mint, shape: BoxShape.circle),
              child: Icon(r.icon,
                  color: p.primary,
                  size: 20,
                  textDirection: ui.TextDirection.ltr),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _tr(lang, r.nameKey),
                        style: _ts(context, 15, FontWeight.w600, p.ink,
                            height: 1.2),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _tr(lang, 'ofScore', {'p': r.weight.toString()}),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _ts(context, 11.5, FontWeight.w400, p.soft,
                              height: 1.2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        shown,
                        style: _ts(
                            context,
                            22,
                            r.muted ? FontWeight.w600 : FontWeight.w700,
                            r.muted ? p.soft : p.ink,
                            height: 1.0,
                            ls: -0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.detail,
                          style: _ts(context, 12.5, FontWeight.w400, p.soft,
                              height: 1.35),
                        ),
                      ),
                      if (can)
                        Icon(
                          open
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 18,
                          color: p.soft,
                        ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    width: double.infinity,
                    height: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: p.line,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: v == null ? 0.0 : _c01(v * e / 100),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: r.muted ? p.mute : p.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: open
                        ? Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: d == null
                                  ? const <Widget>[]
                                  : _details(context, lang, p, index, d),
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillars(BuildContext context, String lang, _Pal p, double t) {
    final List<_Row> rows = _rowsOf(lang, _data);
    final List<Widget> kids = [];
    for (int i = 0; i < rows.length; i++) {
      if (i > 0) kids.add(Container(height: 1, color: p.line));
      kids.add(_pillarRow(context, lang, p, rows[i],
          _eo3(_c01((t - 0.25 - i * 0.12) / 0.75)), i));
    }
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Column(mainAxisSize: MainAxisSize.min, children: kids),
    );
  }

  Widget _page(BuildContext context, String lang, bool rtl, double t) {
    final _Pal p = _Pal(FlutterFlowTheme.of(context));
    final _ScoreData? d = _data;
    final List<Widget> kids = [
      _header(context, lang, p),
      const SizedBox(height: 14),
      _hero(context, lang, rtl, p, t),
    ];
    if (d != null) {
      kids.add(const SizedBox(height: 12));
      kids.add(_tipCard(context, lang, p, _tipOf(lang, d)));
    }
    kids.add(const SizedBox(height: 12));
    kids.add(_pillars(context, lang, p, t));
    kids.add(const SizedBox(height: 12));
    kids.add(Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        _tr(lang, 'foot'),
        textAlign: TextAlign.center,
        style: _ts(context, 12, FontWeight.w400, p.soft, height: 1.4),
      ),
    ));

    return ColoredBox(
      color: p.bg,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: p.primary,
          backgroundColor: p.card,
          onRefresh: () => _load(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: kids,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);
    final bool tile = widget.tile ?? false;
    final bool compact = _isCompact || tile;
    return MediaQuery.withNoTextScaling(
      child: Directionality(
        textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: SizedBox(
          width: compact ? (widget.width ?? double.infinity) : widget.width,
          height: compact
              ? (widget.height ?? (tile ? 132.0 : 100.0))
              : widget.height,
          child: AnimatedBuilder(
            animation: _ac,
            builder: (BuildContext ctx, Widget? _) {
              final double t = _ac.value * 1.8;
              if (tile) return _tile(ctx, lang, t);
              return compact ? _card(ctx, lang, t) : _page(ctx, lang, rtl, t);
            },
          ),
        ),
      ),
    );
  }
}
// boilerplate code using the `</>` button on the right!
