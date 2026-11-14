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

import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Weekly plan builder, in three short steps: 1.
///
/// how many workouts a week and which days are off; 2. which workouts, in
/// rotation order (picked from the library: the ones in the plan on top, the
/// rest below, most recent first, with search), and - only when a workout
/// comes back within the same week - how much rest it needs before it is done
/// again; 3. the week itself: laid out automatically, and every workout can
/// be dragged (long press) or tapped onto another day by hand.
///
/// The plan follows "which workout is next", not the calendar: a missed
/// workout stays next and the rest of the week moves with it. That holds for
/// a week arranged by hand too - the hand-made week sets the days and the
/// order, the re-planning stays automatic.
///
/// Variations: workouts that share at least half of their exercises are one
/// slot and take turns (Push A, then Push B next time). The user can keep
/// them separate.
///
/// This widget only builds and edits the plan. PlanStatus shows the saved
/// plan and its state; the Home screen reads it through [snapshot].
///
/// Fully self-managed. Creates its own local table on first use
/// (training_plan, one row per user) and reads workout, workout_exercise,
/// workout_log and the muscle tables itself. Every save (and delete) also
/// queues the row in the Hive box pendingTrainingPlans, which syncAllPending
/// sends to the Supabase table training_plan.
///
/// Opens on step 3 when a plan exists (edit), on step 1 otherwise. After a
/// save or a delete it calls [onClose]; [onClose] also adds the back and
/// close buttons. [compact], [onStart] and [onOpen] are no longer used and
/// are only kept so existing parameter lists keep working.
///
/// Localization: reads the app language from FFLocalizations (no parameter).
class WeekPlanner extends StatefulWidget {
  const WeekPlanner({
    super.key,
    this.width,
    this.height,
    required this.userId,
    this.compact,
    this.refreshKey,
    this.onStart,
    this.onOpen,
    this.onClose,
  });

  final double? width;
  final double? height;
  final String userId;
  final bool? compact;
  final String? refreshKey;
  final Future Function(String workoutId)? onStart;
  final Future Function()? onOpen;
  final Future Function()? onClose;

  /// For other widgets (Home, PlanStatus): what the saved plan says right
  /// now. [firstDay] = first day of the week (1 = Monday, 7 = Sunday).
  /// Never throws. Keys:
  ///  hasPlan (bool), hasWorkouts (bool),
  ///  workoutId (String, the workout that is up next, '' = none),
  ///  isToday (bool, a workout is planned for today),
  ///  trainedToday (bool), done (int, workouts this week), perWeek (int),
  ///  missing (int, workouts that no longer fit this week),
  ///  today (int, running day number), nextDay (int, day number of the next
  ///  planned workout, -1 = none),
  ///  plannedWeekdays (List<int>, 1 = Monday .. 7 = Sunday, still planned),
  ///  missedWeekday (int, last planned day that passed without a workout,
  ///  0 = none),
  ///  cells (List<Map>, the 7 days of this week: day, weekday, kind = done /
  ///  plan / miss / off / rest, workoutId),
  ///  hold (List<int>, body areas on hold, 0 chest .. 5 core),
  ///  paused (List<String>, workout ids of the slots that are fully on hold),
  ///  names (Map<String, String>, workout id -> stored name).
  static Future<Map<String, dynamic>> snapshot(String userId, int firstDay) =>
      _snapshot(userId, firstDay);

  /// Puts body areas on hold (injury) or clears them, on the saved plan.
  /// 0 chest, 1 back, 2 shoulders, 3 legs, 4 arms, 5 core. Never throws.
  static Future<void> setHold(String userId, List<int> groups) =>
      _setHold(userId, groups);

  @override
  State<WeekPlanner> createState() => _WeekPlannerState();
}

// ---------------------------------------------------------------------------
// Localization (order: en, es, he, de, fr)
// ---------------------------------------------------------------------------

const Set<String> _kRtl = {'he', 'ar'};
const List<String> _kLangs = ['en', 'es', 'he', 'de', 'fr'];
const List<String> _kHeDays = [
  'שני',
  'שלישי',
  'רביעי',
  'חמישי',
  'שישי',
  'שבת',
  'ראשון'
];

const Map<String, List<String>> _kS = {
  's1': [
    'How often do you train?',
    '¿Cuántas veces entrenas?',
    'כמה אימונים בשבוע?',
    'Wie oft trainierst du?',
    "Tu t'entraînes combien de fois ?"
  ],
  's1s': [
    'Pick what you can keep up every week.',
    'Elige lo que puedas mantener cada semana.',
    'בוחרים מספר שאפשר לעמוד בו כל שבוע.',
    'Wähle, was du jede Woche schaffst.',
    'Choisis ce que tu peux tenir chaque semaine.'
  ],
  'restBetween': [
    'Rest before the same workout again',
    'Descanso antes de repetir el mismo entreno',
    'מנוחה לפני שאותו אימון חוזר',
    'Pause, bevor dasselbe Workout wiederkommt',
    'Repos avant de refaire la même séance'
  ],
  'restWhy': [
    '{n} a week with {s} in the plan: a workout comes back within the same week.',
    'Con {n} por semana y {s} en el plan, un entreno se repite en la misma semana.',
    '{n} בשבוע עם {s} בתוכנית: אותו אימון חוזר באותו שבוע.',
    'Bei {n} pro Woche und {s} im Plan kommt ein Workout in derselben Woche wieder.',
    'Avec {n} par semaine et {s} dans le plan, une séance revient dans la même semaine.'
  ],
  'rest0': ['No preference', 'Da igual', 'לא משנה', 'Egal', 'Peu importe'],
  'rest1': ['1 day +', '1 día +', 'יום +', '1 Tag +', '1 jour +'],
  'rest2': ['2 days +', '2 días +', 'יומיים +', '2 Tage +', '2 jours +'],
  'tight': [
    "Doesn't fully fit your days. The closest layout is used.",
    'No encaja del todo con tus días. Se usa la distribución más cercana.',
    'לא מסתדר לגמרי עם הימים שלך. נבחר הסידור הקרוב ביותר.',
    'Passt nicht ganz zu deinen Tagen. Die nächstbeste Aufteilung wird genutzt.',
    'Ça ne rentre pas tout à fait dans tes jours. La répartition la plus proche est utilisée.'
  ],
  'daysOff': [
    "Days you can't train",
    'Días que no puedes entrenar',
    'ימים שאי אפשר להתאמן',
    'Tage, an denen du nicht kannst',
    "Jours où tu ne peux pas t'entraîner"
  ],
  'daysOffSub': [
    'Optional. The plan will skip them.',
    'Opcional. El plan los saltará.',
    'לא חובה. התוכנית תדלג עליהם.',
    'Optional. Der Plan lässt sie aus.',
    'Facultatif. Le plan les évitera.'
  ],
  'next': ['Next', 'Siguiente', 'הבא', 'Weiter', 'Suivant'],
  's2': [
    'Which workouts?',
    '¿Qué entrenos?',
    'אילו אימונים?',
    'Welche Workouts?',
    'Quelles séances ?'
  ],
  's2s': [
    'Add them in the order you do them. They rotate.',
    'Añádelos en el orden en que los haces. Van rotando.',
    'מוסיפים לפי הסדר. הם מתחלפים בסבב.',
    'Füge sie in deiner Reihenfolge hinzu. Sie rotieren.',
    "Ajoute-les dans l'ordre où tu les fais. Elles tournent."
  ],
  'inPlan': [
    'In your plan',
    'En tu plan',
    'בתוכנית',
    'In deinem Plan',
    'Dans ton plan'
  ],
  'none': [
    'Nothing yet. Add your first workout below.',
    'Aún nada. Añade tu primer entreno abajo.',
    'עדיין ריק. מוסיפים אימון ראשון מהרשימה למטה.',
    'Noch leer. Füge unten dein erstes Workout hinzu.',
    "Rien pour l'instant. Ajoute ta première séance ci-dessous."
  ],
  'all': [
    'Your workouts',
    'Tus entrenos',
    'האימונים שלך',
    'Deine Workouts',
    'Tes séances'
  ],
  'search': [
    'Search workouts',
    'Buscar entrenos',
    'חיפוש אימון',
    'Workouts suchen',
    'Rechercher une séance'
  ],
  'noMatch': [
    'No workouts found',
    'Sin resultados',
    'לא נמצאו אימונים',
    'Keine Workouts gefunden',
    'Aucune séance trouvée'
  ],
  'allIn': [
    'Every workout is already in the plan.',
    'Todos los entrenos ya están en el plan.',
    'כל האימונים כבר בתוכנית.',
    'Alle Workouts sind schon im Plan.',
    'Toutes les séances sont déjà dans le plan.'
  ],
  'showAll': [
    'Show all {n}',
    'Ver los {n}',
    'הצגת כל ה-{n}',
    'Alle {n} anzeigen',
    'Voir les {n}'
  ],
  'exs': [
    '{n} exercises',
    '{n} ejercicios',
    '{n} תרגילים',
    '{n} Übungen',
    '{n} exercices'
  ],
  'ago': [
    '{n}d ago',
    'hace {n} d',
    'לפני {n} ימים',
    'vor {n} T.',
    'il y a {n} j'
  ],
  'today': ['today', 'hoy', 'היום', 'heute', "aujourd'hui"],
  'alt': [
    'They take turns: one this time, the other next time',
    'Se turnan: uno esta vez, el otro la siguiente',
    'מתחלפים: פעם אחד, פעם השני',
    'Sie wechseln sich ab: mal das eine, mal das andere',
    "Elles alternent : l'une cette fois, l'autre la suivante"
  ],
  'shared': [
    '{a} of {b} exercises are the same',
    '{a} de {b} ejercicios son iguales',
    '{a} מתוך {b} תרגילים זהים',
    '{a} von {b} Übungen sind gleich',
    '{a} exercices sur {b} sont identiques'
  ],
  'sep': [
    'Keep them separate',
    'Mantenerlos separados',
    'להפריד',
    'Getrennt halten',
    'Les séparer'
  ],
  'join': [
    'Similar to {w}. Take turns with it?',
    'Parecido a {w}. ¿Alternar con él?',
    'דומה ל-{w}. להחליף ביניהם?',
    'Ähnlich wie {w}. Abwechseln?',
    'Proche de {w}. Alterner avec ?'
  ],
  'yourWeek': [
    'Your week',
    'Tu semana',
    'השבוע שלך',
    'Deine Woche',
    'Ta semaine'
  ],
  's3s': [
    'Hold and drag a workout to a day. Or tap it, then tap the day.',
    'Mantén pulsado y arrastra un entreno a un día. O tócalo y luego toca el día.',
    'לחיצה ארוכה וגרירה של אימון ליום. או לחיצה עליו ואז על היום.',
    'Halte ein Workout gedrückt und zieh es auf einen Tag. Oder tippe es an, dann den Tag.',
    'Maintiens une séance et glisse-la sur un jour. Ou touche-la, puis le jour.'
  ],
  'auto': ['Automatic', 'Automático', 'אוטומטי', 'Automatisch', 'Automatique'],
  'edited': [
    'Edited by you',
    'Editado por ti',
    'נערך ידנית',
    'Von dir angepasst',
    'Modifié par toi'
  ],
  'other': [
    'Another layout',
    'Otra distribución',
    'סידור אחר',
    'Andere Aufteilung',
    'Autre répartition'
  ],
  'backAuto': [
    'Back to automatic',
    'Volver a automático',
    'חזרה לאוטומטי',
    'Zurück zu automatisch',
    "Revenir à l'automatique"
  ],
  'cnt': [
    '{n} a week',
    '{n} por semana',
    '{n} בשבוע',
    '{n} pro Woche',
    '{n} par semaine'
  ],
  'rest': ['Rest', 'Descanso', 'מנוחה', 'Pause', 'Repos'],
  'here': [
    'Place here',
    'Colocar aquí',
    'להציב כאן',
    'Hier platzieren',
    'Placer ici'
  ],
  'cant': [
    "Can't train",
    'No disponible',
    'אי אפשר',
    'Nicht möglich',
    'Indisponible'
  ],
  'save': [
    'Save plan',
    'Guardar plan',
    'שמירת התוכנית',
    'Plan speichern',
    'Enregistrer le plan'
  ],
  'saved': [
    'Plan saved',
    'Plan guardado',
    'התוכנית נשמרה',
    'Plan gespeichert',
    'Plan enregistré'
  ],
  'pick': [
    'Add at least one workout',
    'Añade al menos un entreno',
    'צריך להוסיף אימון אחד לפחות',
    'Füge mindestens ein Workout hinzu',
    'Ajoute au moins une séance'
  ],
  'place1': [
    'Place at least one workout',
    'Coloca al menos un entreno',
    'צריך להציב אימון אחד לפחות',
    'Platziere mindestens ein Workout',
    'Place au moins une séance'
  ],
  'delete': [
    'Delete plan',
    'Eliminar plan',
    'מחיקת התוכנית',
    'Plan löschen',
    'Supprimer le plan'
  ],
  'deleteSure': [
    'Tap again to delete',
    'Toca otra vez para eliminar',
    'לחיצה נוספת למחיקה',
    'Zum Löschen erneut tippen',
    'Touche encore pour supprimer'
  ],
  'noWorkouts': [
    'Create a workout first, then build your week.',
    'Crea un entreno primero y luego arma tu semana.',
    'קודם יוצרים אימון, ואז בונים את השבוע.',
    'Erstell zuerst ein Workout, dann plan deine Woche.',
    "Crée d'abord une séance, puis planifie ta semaine."
  ],
  'g0': ['Chest', 'Pecho', 'חזה', 'Brust', 'Pectoraux'],
  'g1': ['Back', 'Espalda', 'גב', 'Rücken', 'Dos'],
  'g2': ['Shoulders', 'Hombros', 'כתפיים', 'Schultern', 'Épaules'],
  'g3': ['Legs', 'Piernas', 'רגליים', 'Beine', 'Jambes'],
  'g4': ['Arms', 'Brazos', 'ידיים', 'Arme', 'Bras'],
  'g5': ['Core', 'Core', 'ליבה', 'Core', 'Abdos'],
  'd1': ['Mon', 'Lun', 'ב׳', 'Mo', 'Lun'],
  'd2': ['Tue', 'Mar', 'ג׳', 'Di', 'Mar'],
  'd3': ['Wed', 'Mié', 'ד׳', 'Mi', 'Mer'],
  'd4': ['Thu', 'Jue', 'ה׳', 'Do', 'Jeu'],
  'd5': ['Fri', 'Vie', 'ו׳', 'Fr', 'Ven'],
  'd6': ['Sat', 'Sáb', 'ש׳', 'Sa', 'Sam'],
  'd7': ['Sun', 'Dom', 'א׳', 'So', 'Dim'],
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

List<int> _csvInts(dynamic raw) {
  final List<int> out = [];
  for (final String p in (raw ?? '').toString().split(',')) {
    final int? v = int.tryParse(p.trim());
    if (v != null) out.add(v);
  }
  return out;
}

/// Theme text style at a real font weight (a Google Font is one file per
/// weight; the family is read from the theme style: "Inter_regular").
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
/// 4 arms, 5 core; -1 = other.
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
// Engine (weekday 1 = Monday .. 7 = Sunday; days are running day numbers)
// ---------------------------------------------------------------------------

class _Plan {
  _Plan(this.perWeek, this.rest, this.blocked, this.trainDays, this.slots,
      this.held);
  final int perWeek;
  final int rest; // rest days wanted before the SAME workout comes back
  final List<int> blocked; // weekdays off
  final List<int> trainDays; // the fixed weekdays
  final List<List<String>> slots; // each slot = variants (workout ids)
  final List<String> held; // workout ids on hold
}

class _Log {
  _Log(this.day, this.ts, this.wid);
  final int day;
  final int ts;
  final String wid;
}

class _DaySet {
  _DaySet(this.set, this.viol, this.minGap, this.spread);
  final List<int> set;
  final int viol;
  final int minGap;
  final int spread;
}

class _Act {
  _Act(this.i, this.vars);
  final int i;
  final List<String> vars;
}

class _Pick {
  _Pick(this.slot, this.wid);
  final int slot;
  final String wid;
}

class _Rec {
  _Rec(this.day, this.slot, this.wid, this.isToday);
  final int day;
  final int slot;
  final String wid;
  final bool isToday;
}

/// kind: done, plan, miss, off, rest.
class _Cell {
  _Cell(this.day, this.kind, this.wid);
  final int day;
  final String kind;
  final String wid;
}

class _Cand {
  _Cand(
      this.set, this.extra, this.missing, this.overlap, this.minGap, this.sum);
  final List<int> set;
  final int extra;
  final int missing;
  final int overlap;
  final int minGap;
  final int sum;
}

class _Week {
  _Week(this.ws, this.cells, this.rec, this.upNext, this.trainedToday,
      this.done, this.missing);
  final int ws;
  final List<_Cell> cells;
  final _Rec? rec;
  final _Pick? upNext;
  final bool trainedToday;
  final int done;
  final int missing;
}

int _wdOf(int d) => ((d + 3) % 7) + 1;

int _posOf(int wd, int first) => (wd - first + 7) % 7;

int _lexCmp(List<int> a, List<int> b) {
  final int n = a.length < b.length ? a.length : b.length;
  for (int i = 0; i < n; i++) {
    if (a[i] != b[i]) return a[i] - b[i];
  }
  return a.length - b.length;
}

/// How many training days of a week bring the same workout back with fewer
/// than [rest] rest days in between. [set] = the week positions in order; a
/// workout comes back [cycle] sessions later (possibly in the next week).
int _sameViol(List<int> set, int cycle, int rest) {
  final int k = set.length;
  int v = 0;
  for (int i = 0; i < k; i++) {
    int j = i + (cycle < 1 ? 1 : cycle);
    int add = 0;
    while (j >= k) {
      j -= k;
      add += 7;
    }
    if (set[j] + add - set[i] - 1 < rest) v++;
  }
  return v;
}

/// After how many sessions the rotation brings a workout back: the number of
/// slots, or fewer when a week arranged by hand repeats one.
int _cycleOf(List<_Act> act) {
  final int n = act.length;
  if (n == 0) return 1;
  final List<String> keys = [];
  for (final _Act a in act) {
    keys.add(a.vars.join('|'));
  }
  int best = n;
  for (int i = 0; i < n; i++) {
    for (int d = 1; d < best; d++) {
      if (keys[(i + d) % n] == keys[i]) {
        best = d;
        break;
      }
    }
  }
  return best;
}

/// Every way to place [n] workouts on the free weekdays, best first: fewest
/// too-early repeats of the same workout ([cycle] = workouts in the
/// rotation), then the widest smallest gap between training days, then the
/// most even spread, then the earliest days. Weekdays come back in week order.
List<List<int>> _pickDays(
    int n, List<int> blocked, int rest, int first, int cycle) {
  final List<List<int>> res = [];
  final List<int> allowed = [];
  for (int p = 0; p < 7; p++) {
    final int wd = ((first - 1 + p) % 7) + 1;
    if (!blocked.contains(wd)) allowed.add(p);
  }
  final int k = n < allowed.length ? n : allowed.length;
  if (k <= 0) return res;
  final List<_DaySet> out = [];
  for (int m = 1; m < (1 << allowed.length); m++) {
    final List<int> set = [];
    for (int i = 0; i < allowed.length; i++) {
      if ((m & (1 << i)) != 0) set.add(allowed[i]);
    }
    if (set.length != k) continue;
    final int viol = _sameViol(set, cycle, rest);
    int minGap = 9, spread = 0;
    for (int i = 0; i < k; i++) {
      final int g = k == 1 ? 7 : (set[(i + 1) % k] - set[i] + 7) % 7;
      if (g < minGap) minGap = g;
      spread += (g * k - 7) * (g * k - 7);
    }
    out.add(_DaySet(set, viol, minGap, spread));
  }
  out.sort((a, b) {
    if (a.viol != b.viol) return a.viol - b.viol;
    if (a.minGap != b.minGap) return b.minGap - a.minGap;
    if (a.spread != b.spread) return a.spread - b.spread;
    return _lexCmp(a.set, b.set);
  });
  for (final _DaySet o in out) {
    final List<int> days = [];
    for (final int p in o.set) {
      days.add(((first - 1 + p) % 7) + 1);
    }
    res.add(days);
  }
  return res;
}

/// Too-early repeats that the fixed week itself contains.
int _baseViol(List<int> trainDays, int rest, int first, int cycle) {
  final List<int> set = [];
  for (final int wd in trainDays) {
    set.add(_posOf(wd, first));
  }
  set.sort();
  return _sameViol(set, cycle, rest);
}

/// Slots that still have a variant that is not on hold.
List<_Act> _activeSlots(List<List<String>> slots, List<String> held) {
  final List<_Act> out = [];
  for (int i = 0; i < slots.length; i++) {
    final List<String> v = [];
    for (final String w in slots[i]) {
      if (!held.contains(w)) v.add(w);
    }
    if (v.isNotEmpty) out.add(_Act(i, v));
  }
  return out;
}

/// Position in [act] of the slot that is up next. The log is replayed oldest
/// to newest, every workout moving the pointer past the nearest slot that
/// holds it, so a week that repeats a workout (Push, Pull, Push, Legs) keeps
/// its place. [logsDesc] is newest first.
int _pointerOf(List<_Act> act, List<List<String>> slots, List<_Log> logsDesc) {
  if (act.isEmpty) return 0;
  final int n = slots.length;
  int ptr = 0;
  for (int k = logsDesc.length - 1; k >= 0; k--) {
    final String w = logsDesc[k].wid;
    for (int j = 0; j < n; j++) {
      final int i = (ptr + j) % n;
      if (slots[i].contains(w)) {
        ptr = (i + 1) % n;
        break;
      }
    }
  }
  for (int p = 0; p < act.length; p++) {
    if (act[p].i >= ptr) return p;
  }
  return 0;
}

/// The variant after the one done last; [occ] = times the slot was already
/// placed in the same week.
String _variantOf(_Act slot, List<_Log> logsDesc, int occ) {
  int start = 0;
  for (final _Log l in logsDesc) {
    final int j = slot.vars.indexOf(l.wid);
    if (j >= 0) {
      start = (j + 1) % slot.vars.length;
      break;
    }
  }
  return slot.vars[(start + occ) % slot.vars.length];
}

int _cmpWeek(_Cand a, _Cand b) {
  if (a.extra != b.extra) return a.extra - b.extra;
  if (a.missing != b.missing) return a.missing - b.missing;
  if (a.overlap != b.overlap) return b.overlap - a.overlap;
  if (a.minGap != b.minGap) return b.minGap - a.minGap;
  if (a.sum != b.sum) return a.sum - b.sum;
  return _lexCmp(a.set, b.set);
}

/// The current week as it stands today: what was done, what is still
/// planned (re-planned around what actually happened) and what to do next.
_Week _planWeek(_Plan plan, List<_Log> logs, int today, int first) {
  final int ws = today - _posOf(_wdOf(today), first);
  final int we = ws + 6;
  final List<_Log> logsDesc = logs.where((l) => l.day <= today).toList();
  logsDesc.sort((a, b) => b.ts.compareTo(a.ts));
  final List<_Log> weekLogs = logsDesc.where((l) => l.day >= ws).toList();
  final bool trainedToday = weekLogs.any((l) => l.day == today);
  final int need =
      plan.perWeek > weekLogs.length ? plan.perWeek - weekLogs.length : 0;
  final int last = logsDesc.isEmpty ? -1 : logsDesc.first.day;
  final List<int> cand = [];
  for (int d = today; d <= we; d++) {
    if (plan.blocked.contains(_wdOf(d))) continue;
    if (d == today && trainedToday) continue;
    cand.add(d);
  }
  final List<_Act> act = _activeSlots(plan.slots, plan.held);
  final int ptr = _pointerOf(act, plan.slots, logsDesc);
  // Per active slot: what it is, and the last day it (any variant) was done.
  final List<String> keys = [];
  final List<int> doneDay = [];
  for (final _Act a in act) {
    keys.add(a.vars.join('|'));
    int dd = -1;
    for (final _Log l in logsDesc) {
      if (plan.slots[a.i].contains(l.wid)) {
        dd = l.day;
        break;
      }
    }
    doneDay.add(dd);
  }
  final int base = _baseViol(plan.trainDays, plan.rest, first, _cycleOf(act));
  _Cand best = _Cand(<int>[], 0, need, 0, 99, 0);
  for (int m = 1; m < (1 << cand.length); m++) {
    final List<int> set = [];
    for (int i = 0; i < cand.length; i++) {
      if ((m & (1 << i)) != 0) set.add(cand[i]);
    }
    if (set.length > need) continue;
    int viol = 0, minGap = 99, overlap = 0, sum = 0, prev = last;
    for (int k = 0; k < set.length; k++) {
      final int d = set[k];
      if (act.isNotEmpty) {
        // The same workout again: after an earlier day of this plan, or
        // after the last time it was actually done.
        final int a = (ptr + k) % act.length;
        int before = doneDay[a];
        for (int j = k - 1; j >= 0; j--) {
          if (keys[(ptr + j) % act.length] == keys[a]) {
            before = set[j];
            break;
          }
        }
        if (before >= 0 && d - before - 1 < plan.rest) viol++;
      }
      if (prev >= 0 && d - prev < minGap) minGap = d - prev;
      if (plan.trainDays.contains(_wdOf(d))) overlap++;
      sum += d - today;
      prev = d;
    }
    final _Cand c = _Cand(set, viol > base ? viol - base : 0, need - set.length,
        overlap, minGap, sum);
    if (_cmpWeek(c, best) < 0) best = c;
  }

  // Variants take turns inside the week too; a workout placed twice by hand
  // shares one counter.
  final Map<String, int> occ = {};
  final Map<int, _Pick> planned = {};
  _Pick? upNext;
  if (act.isNotEmpty) {
    for (int k = 0; k < best.set.length; k++) {
      final _Act s = act[(ptr + k) % act.length];
      final String key = s.vars.join('|');
      final int o = occ[key] ?? 0;
      occ[key] = o + 1;
      planned[best.set[k]] = _Pick(s.i, _variantOf(s, logsDesc, o));
    }
    if (best.set.isNotEmpty) {
      upNext = planned[best.set.first];
    } else {
      final _Act s = act[ptr % act.length];
      upNext = _Pick(s.i, _variantOf(s, logsDesc, 0));
    }
  }

  _Rec? rec;
  final _Pick? un = upNext;
  if (un != null) {
    if (best.set.isNotEmpty) {
      rec = _Rec(best.set.first, un.slot, un.wid, best.set.first == today);
    } else {
      int nd = -1;
      for (int d = we + 1; d <= we + 14; d++) {
        if (plan.trainDays.contains(_wdOf(d))) {
          nd = d;
          break;
        }
      }
      if (nd >= 0) rec = _Rec(nd, un.slot, un.wid, false);
    }
  }

  final List<_Cell> cells = [];
  for (int d = ws; d <= we; d++) {
    String kind = 'rest';
    String wid = '';
    bool hasDone = false;
    for (final _Log l in weekLogs) {
      if (l.day == d) {
        hasDone = true;
        wid = l.wid;
        break;
      }
    }
    final _Pick? pk = planned[d];
    if (hasDone) {
      kind = 'done';
    } else if (pk != null) {
      kind = 'plan';
      wid = pk.wid;
    } else if (d < today && plan.trainDays.contains(_wdOf(d))) {
      kind = 'miss';
    } else if (plan.blocked.contains(_wdOf(d))) {
      kind = 'off';
    }
    cells.add(_Cell(d, kind, wid));
  }
  return _Week(ws, cells, rec, upNext, trainedToday, weekLogs.length,
      act.isEmpty ? 0 : best.missing);
}

double _jaccard(List<int> a, List<int> b) {
  if (a.isEmpty || b.isEmpty) return 0.0;
  final Set<int> sa = a.toSet();
  final Set<int> sb = b.toSet();
  int n = 0;
  for (final int x in sb) {
    if (sa.contains(x)) n++;
  }
  return n / (sa.length + sb.length - n);
}

/// Workouts in rotation order -> slots. A workout that shares at least half
/// of its exercises with an earlier one becomes its variant, unless either
/// of them is in [split].
List<List<String>> _buildSlots(
    List<String> order, Map<String, List<int>> ex, List<String> split) {
  final List<List<String>> slots = [];
  for (final String w in order) {
    int home = -1;
    if (!split.contains(w)) {
      for (int i = 0; i < slots.length; i++) {
        final String h = slots[i].first;
        if (!split.contains(h) &&
            _jaccard(ex[h] ?? const <int>[], ex[w] ?? const <int>[]) >= 0.5) {
          home = i;
          break;
        }
      }
    }
    if (home >= 0) {
      slots[home].add(w);
    } else {
      slots.add(<String>[w]);
    }
  }
  return slots;
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

const String _kCreate = 'CREATE TABLE IF NOT EXISTS training_plan ('
    'id TEXT PRIMARY KEY, user_id TEXT, per_week INTEGER, rest_days INTEGER, '
    'blocked_days TEXT, train_days TEXT, slots TEXT, split_ids TEXT, '
    'hold_groups TEXT, layout_index INTEGER, created_at TEXT, updated_at TEXT)';

// A week arranged by hand is stored in the same columns: layout_index = -1,
// train_days = the chosen weekdays in week order and slots = the workout of
// each of those days, in the same order (a workout may repeat).

class _Wk {
  _Wk(this.id, this.name, this.ex);
  final String id;
  final String name;
  final List<int> ex;
}

class _Data {
  _Data(this.workouts, this.exGroups, this.logs, this.row, this.lastDone);
  final List<_Wk> workouts;
  final Map<int, List<int>> exGroups; // exercise -> body areas (0..5)
  final List<_Log> logs; // the last 8 weeks
  final Map<String, Object?>? row; // the saved plan, null = none
  final Map<String, int> lastDone; // workout id -> day number, all time
}

/// What the builder edits.
class _Cfg {
  int n = 3;
  int rest = 1;
  List<int> blocked = [];
  List<String> order = []; // workout ids in rotation order
  List<String> split = []; // similar workouts the user keeps separate
  List<int> hold = []; // body areas on hold (edited in PlanStatus)
  int layout = 0;
}

List<String> _jsonStrings(dynamic raw) {
  final List<String> out = [];
  try {
    final dynamic v = jsonDecode((raw ?? '').toString());
    if (v is List) {
      for (final dynamic x in v) {
        out.add(x.toString());
      }
    }
  } catch (_) {}
  return out;
}

List<List<String>> _jsonSlots(dynamic raw) {
  final List<List<String>> out = [];
  try {
    final dynamic v = jsonDecode((raw ?? '').toString());
    if (v is List) {
      for (final dynamic s in v) {
        if (s is List) {
          final List<String> vars = [];
          for (final dynamic x in s) {
            vars.add(x.toString());
          }
          if (vars.isNotEmpty) out.add(vars);
        }
      }
    }
  } catch (_) {}
  return out;
}

Future<_Data> _loadData(String userId) async {
  final db = SQLiteManager.instance.database;
  try {
    await db.execute(_kCreate);
  } catch (_) {}

  List<Map<String, Object?>> pRows = const [];
  List<Map<String, Object?>> wRows = const [];
  List<Map<String, Object?>> eRows = const [];
  List<Map<String, Object?>> mRows = const [];
  List<Map<String, Object?>> lRows = const [];
  try {
    pRows =
        await db.rawQuery('SELECT * FROM training_plan WHERE id = ?', [userId]);
  } catch (_) {}
  try {
    wRows = await db.rawQuery(
      'SELECT id, name FROM workout '
      'WHERE user_id = ? AND COALESCE(is_deleted, 0) = 0 '
      'ORDER BY created_at DESC',
      [userId],
    );
  } catch (_) {}
  try {
    eRows = await db.rawQuery(
      'SELECT we.workout_id AS wid, we.exercise_id AS ex '
      'FROM workout_exercise we '
      'JOIN workout w ON w.id = we.workout_id '
      'WHERE w.user_id = ? AND COALESCE(w.is_deleted, 0) = 0',
      [userId],
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
    lRows = await db.rawQuery(
      'SELECT workout_id AS wid, created_at FROM workout_log WHERE user_id = ?',
      [userId],
    );
  } catch (_) {}

  final Map<String, List<int>> exByWorkout = {};
  for (final r in eRows) {
    final List<int> l =
        exByWorkout.putIfAbsent((r['wid'] ?? '').toString(), () => <int>[]);
    final int ex = _toI(r['ex'], -1);
    if (ex >= 0 && !l.contains(ex)) l.add(ex);
  }
  final List<_Wk> workouts = [];
  for (final r in wRows) {
    final String id = (r['id'] ?? '').toString();
    if (id.isEmpty) continue;
    workouts
        .add(_Wk(id, (r['name'] ?? '').toString(), exByWorkout[id] ?? <int>[]));
  }

  final Map<int, List<int>> exGroups = {};
  final Map<String, int> cache = {};
  for (final r in mRows) {
    final String gname = (r['gname'] ?? '').toString();
    if (gname.isEmpty) continue;
    final int g = cache.putIfAbsent(gname, () => _groupOf(gname));
    if (g < 0) continue;
    final List<int> l =
        exGroups.putIfAbsent(_toI(r['exercise_id']), () => <int>[]);
    if (!l.contains(g)) l.add(g);
  }

  // The last 8 weeks are plenty for "what was done last".
  final int from = _dayNo(DateTime.now()) - 56;
  final List<_Log> logs = [];
  final Map<String, int> lastDone = {};
  for (final r in lRows) {
    final DateTime? dt = _parseDt(r['created_at']);
    if (dt == null) continue;
    final int day = _dayNo(dt);
    final String wid = (r['wid'] ?? '').toString();
    if (day > (lastDone[wid] ?? -1)) lastDone[wid] = day;
    if (day < from) continue;
    logs.add(_Log(day, dt.millisecondsSinceEpoch, wid));
  }
  return _Data(
      workouts, exGroups, logs, pRows.isEmpty ? null : pRows.first, lastDone);
}

/// Workouts where at least half of the exercises hit an area on hold.
List<String> _heldOf(_Data d, List<int> hold) {
  final List<String> out = [];
  if (hold.isEmpty) return out;
  for (final _Wk w in d.workouts) {
    if (w.ex.isEmpty) continue;
    int hit = 0;
    for (final int e in w.ex) {
      final List<int> g = d.exGroups[e] ?? const <int>[];
      if (g.any((x) => hold.contains(x))) hit++;
    }
    if (hit * 2 >= w.ex.length) out.add(w.id);
  }
  return out;
}

/// The saved plan, ready for the engine (deleted workouts dropped).
_Plan? _planOf(_Data d) {
  final Map<String, Object?>? row = d.row;
  if (row == null) return null;
  final List<String> known = [for (final _Wk w in d.workouts) w.id];
  final List<int> days = _csvInts(row['train_days']);
  final bool manual = _toI(row['layout_index']) < 0;
  final List<List<String>> stored = _jsonSlots(row['slots']);
  final List<List<String>> slots = [];
  final List<int> keptDays = [];
  for (int k = 0; k < stored.length; k++) {
    final List<String> v = [
      for (final String w in stored[k])
        if (known.contains(w)) w
    ];
    if (v.isEmpty) continue;
    slots.add(v);
    if (manual && k < days.length) keptDays.add(days[k]);
  }
  if (slots.isEmpty) return null;
  return _Plan(
    manual ? slots.length : _toI(row['per_week'], 3).clamp(1, 7).toInt(),
    _toI(row['rest_days'], 1).clamp(0, 2).toInt(),
    _csvInts(row['blocked_days']),
    manual ? keptDays : days,
    slots,
    _heldOf(d, _csvInts(row['hold_groups'])),
  );
}

Future<Map<String, dynamic>> _snapshot(String userId, int first) async {
  final Map<String, dynamic> out = {
    'hasPlan': false,
    'hasWorkouts': false,
    'workoutId': '',
    'isToday': false,
    'trainedToday': false,
    'done': 0,
    'perWeek': 0,
    'missing': 0,
    'today': _dayNo(DateTime.now()),
    'nextDay': -1,
    'plannedWeekdays': <int>[],
    'missedWeekday': 0,
    'cells': <Map<String, dynamic>>[],
    'hold': <int>[],
    'paused': <String>[],
    'names': <String, String>{},
  };
  try {
    final _Data d = await _loadData(userId);
    out['hasWorkouts'] = d.workouts.isNotEmpty;
    out['names'] = <String, String>{
      for (final _Wk w in d.workouts) w.id: w.name
    };
    final _Plan? plan = _planOf(d);
    if (plan == null) return out;
    final int today = _dayNo(DateTime.now());
    final _Week w = _planWeek(plan, d.logs, today, first);
    int missed = 0;
    final List<Map<String, dynamic>> cells = [];
    for (final _Cell c in w.cells) {
      if (c.kind == 'miss') missed = _wdOf(c.day);
      cells.add(<String, dynamic>{
        'day': c.day,
        'weekday': _wdOf(c.day),
        'kind': c.kind,
        'workoutId': c.wid,
      });
    }
    final List<String> paused = [];
    for (final List<String> s in plan.slots) {
      if (s.every((x) => plan.held.contains(x)) && !paused.contains(s.first)) {
        paused.add(s.first);
      }
    }
    out['hasPlan'] = true;
    out['workoutId'] = w.upNext?.wid ?? '';
    out['isToday'] = w.rec?.isToday ?? false;
    out['trainedToday'] = w.trainedToday;
    out['done'] = w.done;
    out['perWeek'] = plan.perWeek;
    out['missing'] = w.missing;
    out['today'] = today;
    out['nextDay'] = w.rec?.day ?? -1;
    out['plannedWeekdays'] = <int>[
      for (final _Cell c in w.cells)
        if (c.kind == 'plan') _wdOf(c.day)
    ];
    out['missedWeekday'] = missed;
    out['cells'] = cells;
    out['hold'] = _csvInts(d.row?['hold_groups']);
    out['paused'] = paused;
    return out;
  } catch (_) {
    return out;
  }
}

/// Puts the plan row in the offline queue (one entry per user: a newer save
/// replaces an unsent older one). Never throws.
Future<void> _queuePlan(String userId, Map<String, dynamic> row) async {
  try {
    await Hive.initFlutter();
    final Box box = await Hive.openBox('pendingTrainingPlans');
    await box.put(userId, row);
  } catch (_) {}
}

Future<void> _setHold(String userId, List<int> groups) async {
  try {
    final db = SQLiteManager.instance.database;
    await db.execute(_kCreate);
    await db.execute(
      'UPDATE training_plan SET hold_groups = ?, updated_at = ? WHERE id = ?',
      [groups.join(','), DateTime.now().toIso8601String(), userId],
    );
    final stored =
        await db.rawQuery('SELECT * FROM training_plan WHERE id = ?', [userId]);
    if (stored.isNotEmpty) {
      await _queuePlan(userId, Map<String, dynamic>.from(stored.first));
    }
  } catch (_) {}
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
    mintLine = Color.alphaBlend(primary.withAlpha(light ? 0x70 : 0x80), card);
    mintInk = Color.lerp(primary, pole, light ? 0.68 : 0.78)!;
    mintSoft = Color.lerp(primary, pole, light ? 0.42 : 0.5)!;
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
}

/// Dashed rounded outline of an empty day.
class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.radius);
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
        Radius.circular(radius),
      ));
    for (final ui.PathMetric m in path.computeMetrics()) {
      double at = 0;
      while (at < m.length) {
        final double end = at + 5 < m.length ? at + 5 : m.length;
        canvas.drawPath(m.extractPath(at, end), paint);
        at += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter old) =>
      old.color != color || old.radius != radius;
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class _WeekPlannerState extends State<WeekPlanner> {
  _Data? _data;
  _Cfg _cfg = _Cfg();
  // A week arranged by hand: weekday -> workout id. null = automatic.
  Map<int, String>? _manual;
  int _step = 1;
  // What is picked up by a tap: 's<slot index>' or 'd<weekday>'.
  String? _arm;
  String _query = '';
  bool _showAll = false;
  bool _saved = false;
  bool _sure = false;
  bool _ready = false;
  int _token = 0;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WeekPlanner old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId || old.refreshKey != widget.refreshKey) {
      _ready = false;
      _load();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ---------- data ----------
  Future<void> _load() async {
    final int token = ++_token;
    _Data d;
    try {
      d = await _loadData(widget.userId);
    } catch (_) {
      d = _Data(<_Wk>[], <int, List<int>>{}, <_Log>[], null, <String, int>{});
    }
    if (!mounted || token != _token) return;
    setState(() {
      _data = d;
      if (!_ready) {
        _ready = true;
        _startFrom(d);
      }
    });
  }

  /// Opens the saved plan for editing, or a fresh draft.
  void _startFrom(_Data d) {
    final _Cfg c = _Cfg();
    Map<int, String>? manual;
    final Map<String, Object?>? row = d.row;
    final List<String> known = [for (final _Wk w in d.workouts) w.id];
    if (row != null) {
      c.n = _toI(row['per_week'], 3).clamp(1, 7).toInt();
      c.rest = _toI(row['rest_days'], 1).clamp(0, 2).toInt();
      c.blocked = _csvInts(row['blocked_days']);
      c.hold = _csvInts(row['hold_groups']);
      final int layout = _toI(row['layout_index']);
      c.layout = layout < 0 ? 0 : layout;
      final List<List<String>> stored = _jsonSlots(row['slots']);
      for (final List<String> slot in stored) {
        for (final String w in slot) {
          if (known.contains(w) && !c.order.contains(w)) c.order.add(w);
        }
      }
      c.split = [
        for (final String w in _jsonStrings(row['split_ids']))
          if (known.contains(w)) w
      ];
      if (layout < 0) {
        final Map<int, String> m = {};
        final List<int> days = _csvInts(row['train_days']);
        for (int k = 0; k < days.length && k < stored.length; k++) {
          for (final String w in stored[k]) {
            if (known.contains(w)) {
              m[days[k]] = w;
              break;
            }
          }
        }
        manual = m;
      }
    }
    final bool editing = row != null && c.order.isNotEmpty;
    if (c.order.isEmpty) {
      // A fresh plan starts with what was trained in the last 30 days, the
      // workout done longest ago first (it is the one that is due).
      final int today = _dayNo(DateTime.now());
      final List<_Wk> recent = [
        for (final _Wk w in d.workouts)
          if ((d.lastDone[w.id] ?? -1) >= today - 30) w
      ];
      recent.sort(
          (a, b) => (d.lastDone[a.id] ?? 0).compareTo(d.lastDone[b.id] ?? 0));
      for (final _Wk w in recent) {
        if (c.order.length < 6) c.order.add(w.id);
      }
      manual = null;
    }
    _cfg = c;
    _manual = manual;
    _arm = null;
    _query = '';
    _search.text = '';
    _showAll = false;
    _saved = false;
    _sure = false;
    _step = editing ? 3 : 1;
  }

  Map<String, List<int>> _exMap() {
    final Map<String, List<int>> m = {};
    for (final _Wk w in _data?.workouts ?? <_Wk>[]) {
      m[w.id] = w.ex;
    }
    return m;
  }

  String _nameOf(String lang, String wid) {
    for (final _Wk w in _data?.workouts ?? <_Wk>[]) {
      if (w.id == wid) return localizedName(w.name, lang);
    }
    return '';
  }

  List<List<String>> _slots() => _buildSlots(_cfg.order, _exMap(), _cfg.split);

  List<List<int>> _options(int first) {
    final int cycle = _slots().length;
    final List<List<int>> all = _pickDays(
        _cfg.n, _cfg.blocked, _cfg.rest, first, cycle < 1 ? 1 : cycle);
    return all.length > 6 ? all.sublist(0, 6) : all;
  }

  List<int> _draftDays(int first) {
    final List<List<int>> o = _options(first);
    return o.isEmpty ? <int>[] : o[_cfg.layout % o.length];
  }

  int _wdAt(int pos, int first) => ((first - 1 + pos) % 7) + 1;

  /// The week as the board shows it, per week position: a slot index,
  /// -1 = rest, -2 = a day the user can't train.
  List<int> _assign(int first, List<List<String>> slots) {
    final List<int> a = [];
    final Map<int, String>? m = _manual;
    final List<int> days = m == null ? _draftDays(first) : <int>[];
    int k = 0;
    for (int pos = 0; pos < 7; pos++) {
      final int wd = _wdAt(pos, first);
      if (_cfg.blocked.contains(wd)) {
        a.add(-2);
      } else if (m != null) {
        final String w = m[wd] ?? '';
        int si = -1;
        if (w.isNotEmpty) {
          for (int i = 0; i < slots.length; i++) {
            if (slots[i].contains(w)) {
              si = i;
              break;
            }
          }
        }
        a.add(si);
      } else if (days.contains(wd) && slots.isNotEmpty) {
        a.add(k % slots.length);
        k++;
      } else {
        a.add(-1);
      }
    }
    return a;
  }

  /// Which variant falls on each position (variants take turns in a week).
  List<String> _turns(List<int> a, List<List<String>> slots) {
    final Map<int, int> seen = {};
    final List<String> out = [];
    for (final int v in a) {
      if (v < 0 || v >= slots.length) {
        out.add('');
        continue;
      }
      final int k = seen[v] ?? 0;
      seen[v] = k + 1;
      out.add(slots[v][k % slots[v].length]);
    }
    return out;
  }

  // ---------- actions ----------
  void _tap() => HapticFeedback.selectionClick();

  void _go(int step) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _step = step;
      _arm = null;
      _sure = false;
    });
  }

  /// A change to the draft. The hand-made week survives everything except a
  /// new number of workouts per week.
  void _change(VoidCallback fn, {bool keepManual = true}) {
    _tap();
    setState(() {
      fn();
      _cfg.layout = 0;
      _arm = null;
      _saved = false;
      _sure = false;
      if (!keepManual) _manual = null;
    });
  }

  void _moveUp(int i) {
    final List<List<String>> sl = _slots();
    if (i <= 0 || i >= sl.length) return;
    _change(() {
      final List<String> t = sl[i];
      sl[i] = sl[i - 1];
      sl[i - 1] = t;
      _cfg.order = [for (final List<String> s in sl) ...s];
    });
  }

  /// Moves a workout on the board. [src] is 's<slot index>' (from the tray)
  /// or 'd<weekday>'; [tgt] is 'd<weekday>' or 'tray' (take it off the week).
  void _applyDrop(String src, String tgt, int first) {
    if (src.length < 2) return;
    final List<List<String>> slots = _slots();
    final List<int> a = _assign(first, slots);
    final Map<int, String> m = {};
    for (int pos = 0; pos < 7; pos++) {
      if (a[pos] >= 0) m[_wdAt(pos, first)] = slots[a[pos]].first;
    }
    final int from = int.tryParse(src.substring(1)) ?? -1;
    if (tgt == 'tray') {
      if (!src.startsWith('d')) return;
      m.remove(from);
    } else {
      final int to = int.tryParse(tgt.length < 2 ? '' : tgt.substring(1)) ?? -1;
      if (to < 1 || to > 7 || _cfg.blocked.contains(to)) return;
      if (src.startsWith('s')) {
        if (from < 0 || from >= slots.length) return;
        m[to] = slots[from].first;
      } else {
        if (from == to) return;
        final String? x = m[from];
        final String? y = m[to];
        if (y == null) {
          m.remove(from);
        } else {
          m[from] = y;
        }
        if (x == null) {
          m.remove(to);
        } else {
          m[to] = x;
        }
      }
    }
    _tap();
    setState(() {
      _manual = m;
      _arm = null;
      _saved = false;
      _sure = false;
    });
  }

  /// Tap on a workout (tray chip or a workout on a day).
  void _tapPill(String id, int first) {
    final String? arm = _arm;
    if (arm == null) {
      _tap();
      setState(() => _arm = id);
    } else if (arm == id) {
      setState(() => _arm = null);
    } else if (id.startsWith('s')) {
      if (arm.startsWith('d')) {
        _applyDrop(id, arm, first);
      } else {
        setState(() => _arm = id);
      }
    } else {
      _applyDrop(arm, id, first);
    }
  }

  /// Tap on an empty day.
  void _tapEmpty(int wd, int first) {
    final String id = 'd' + wd.toString();
    final String? arm = _arm;
    if (arm == null) {
      _tap();
      setState(() => _arm = id);
    } else if (arm == id) {
      setState(() => _arm = null);
    } else {
      _applyDrop(arm, id, first);
    }
  }

  Future<void> _save(int first) async {
    final List<List<String>> slots = _slots();
    final List<int> a = _assign(first, slots);
    final List<int> days = [];
    final List<List<String>> seq = [];
    for (int pos = 0; pos < 7; pos++) {
      if (a[pos] >= 0) {
        days.add(_wdAt(pos, first));
        seq.add(slots[a[pos]]);
      }
    }
    if (seq.isEmpty) return;
    _tap();
    final bool manual = _manual != null;
    final String uid = widget.userId;
    final String now = DateTime.now().toIso8601String();
    try {
      final db = SQLiteManager.instance.database;
      await db.execute(_kCreate);
      await db.rawInsert(
        'INSERT OR REPLACE INTO training_plan '
        '(id, user_id, per_week, rest_days, blocked_days, train_days, slots, '
        'split_ids, hold_groups, layout_index, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, '
        'COALESCE((SELECT created_at FROM training_plan WHERE id = ?), ?), ?)',
        [
          uid,
          uid,
          manual ? days.length : _cfg.n,
          _cfg.rest,
          _cfg.blocked.join(','),
          days.join(','),
          jsonEncode(manual ? seq : slots),
          jsonEncode(_cfg.split),
          _cfg.hold.join(','),
          manual ? -1 : _cfg.layout,
          uid,
          now,
          now,
        ],
      );
      // Queue exactly what was stored (created_at of the first save kept).
      final stored =
          await db.rawQuery('SELECT * FROM training_plan WHERE id = ?', [uid]);
      if (stored.isNotEmpty) {
        await _queuePlan(uid, Map<String, dynamic>.from(stored.first));
      }
    } catch (_) {}
    _saved = true;
    await _load();
    if (mounted) widget.onClose?.call();
  }

  Future<void> _delete() async {
    _tap();
    try {
      await SQLiteManager.instance.database
          .rawDelete('DELETE FROM training_plan WHERE id = ?', [widget.userId]);
    } catch (_) {}
    // The cloud queue only upserts, so a deleted plan goes up as an empty
    // one (no workouts); restoreAllFromCloud skips empty plans.
    await _queuePlan(widget.userId, <String, dynamic>{
      'id': widget.userId,
      'user_id': widget.userId,
      'slots': '[]',
      'split_ids': '[]',
      'train_days': '',
      'updated_at': DateTime.now().toIso8601String(),
    });
    if (!mounted) return;
    if (widget.onClose != null) {
      widget.onClose?.call();
    } else {
      _ready = false;
      await _load();
    }
  }

  // ---------- shared pieces ----------
  Widget _pill(BuildContext context, _Pal p, String label, VoidCallback? onTap,
      {bool filled = true}) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1.0,
      child: Material(
        color: filled ? p.primary : Colors.transparent,
        shape: StadiumBorder(
          side: filled ? BorderSide.none : BorderSide(color: p.line, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _ts(
                  context, 15, FontWeight.w700, filled ? Colors.white : p.ink,
                  height: 1.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(
      BuildContext context, _Pal p, String label, bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? p.primary : p.card,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: on ? p.primary : p.line, width: 1),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _ts(context, 13, FontWeight.w600, on ? Colors.white : p.ink,
              height: 1.2),
        ),
      ),
    );
  }

  Widget _box(_Pal p, List<Widget> kids) {
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line, width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: kids,
      ),
    );
  }

  Widget _label(BuildContext context, _Pal p, String text, [String hint = '']) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text,
            style: _ts(context, 15, FontWeight.w700, p.ink, height: 1.25)),
        if (hint.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(hint,
                style:
                    _ts(context, 12.5, FontWeight.w400, p.soft, height: 1.35)),
          ),
      ],
    );
  }

  Widget _circle(_Pal p, IconData icon, VoidCallback onTap) {
    return Material(
      color: p.card,
      shape: CircleBorder(side: BorderSide(color: p.line, width: 1)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: p.ink, size: 18),
        ),
      ),
    );
  }

  /// A small round button inside a row (move up, remove, add).
  Widget _mini(_Pal p, IconData icon, VoidCallback onTap, {bool mint = false}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: mint ? p.mint : p.bg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: mint ? p.mintInk : p.soft),
      ),
    );
  }

  Widget _link(BuildContext context, _Pal p, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: 5, bottom: 1),
        child: Text(
          text,
          style: _ts(context, 12.5, FontWeight.w600, p.mintSoft, height: 1.3),
        ),
      ),
    );
  }

  /// One of seven equal cells in a row; the round child shrinks on narrow
  /// screens instead of overflowing.
  Widget _cell(Widget child) {
    return Expanded(
      child: Align(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 42, maxHeight: 42),
          child: AspectRatio(aspectRatio: 1, child: child),
        ),
      ),
    );
  }

  Widget _round(BuildContext context, _Pal p, String label, bool on,
      bool struck, VoidCallback onTap) {
    final Color fg = on ? Colors.white : (struck ? p.soft : p.ink);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? p.primary : (struck ? p.bg : p.card),
          shape: BoxShape.circle,
          border: Border.all(color: on ? p.primary : p.line, width: 1),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: _ts(context, label.length > 2 ? 12 : 15,
                  on ? FontWeight.w700 : FontWeight.w600, fg,
                  height: 1.0)
              .copyWith(
            decoration:
                struck ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, _Pal p) {
    final bool canClose = widget.onClose != null;
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          if (_step > 1 || canClose)
            _circle(p, Icons.arrow_back_ios_new_rounded, () {
              _tap();
              if (_step > 1) {
                _go(_step - 1);
              } else {
                widget.onClose?.call();
              }
            }),
          const Spacer(),
          for (int i = 1; i <= 3; i++)
            Container(
              width: 22,
              height: 4,
              margin: EdgeInsetsDirectional.only(start: i == 1 ? 0 : 5),
              decoration: BoxDecoration(
                color: i <= _step ? p.primary : p.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          if (canClose && _step > 1) ...[
            const SizedBox(width: 14),
            _circle(p, Icons.close_rounded, () {
              _tap();
              widget.onClose?.call();
            }),
          ],
        ],
      ),
    );
  }

  List<Widget> _titles(BuildContext context, _Pal p, String title, String sub) {
    return [
      const SizedBox(height: 14),
      Text(title,
          style:
              _ts(context, 26, FontWeight.w700, p.ink, height: 1.15, ls: -0.4)),
      const SizedBox(height: 4),
      Text(sub,
          style: _ts(context, 13.5, FontWeight.w400, p.soft, height: 1.4)),
      const SizedBox(height: 14),
    ];
  }

  String _dayRow(String lang, int wd) =>
      lang == 'he' ? _kHeDays[wd - 1] : _tr(lang, 'd' + wd.toString());

  // ---------- step 1: how often ----------
  List<Widget> _stepOne(BuildContext context, String lang, _Pal p, int first) {
    return [
      ..._titles(context, p, _tr(lang, 's1'), _tr(lang, 's1s')),
      _box(p, [
        Row(
          children: [
            for (int n = 1; n <= 7; n++)
              _cell(_round(context, p, n.toString(), _cfg.n == n, false, () {
                _change(() => _cfg.n = n, keepManual: false);
              })),
          ],
        ),
      ]),
      const SizedBox(height: 12),
      _box(p, [
        _label(context, p, _tr(lang, 'daysOff'), _tr(lang, 'daysOffSub')),
        const SizedBox(height: 12),
        Row(
          children: [
            for (int pos = 0; pos < 7; pos++)
              _cell(_round(
                  context,
                  p,
                  _tr(lang, 'd' + _wdAt(pos, first).toString()),
                  false,
                  _cfg.blocked.contains(_wdAt(pos, first)), () {
                final int wd = _wdAt(pos, first);
                if (!_cfg.blocked.contains(wd) && _cfg.blocked.length >= 6)
                  return;
                _change(() {
                  if (_cfg.blocked.contains(wd)) {
                    _cfg.blocked.remove(wd);
                  } else {
                    _cfg.blocked.add(wd);
                  }
                });
              })),
          ],
        ),
      ]),
      const SizedBox(height: 14),
      _pill(context, p, _tr(lang, 'next'), () {
        _tap();
        _go(2);
      }),
    ];
  }

  // ---------- step 2: which workouts ----------
  String _metaOf(String lang, _Data d, _Wk w, int today) {
    final List<String> parts = [
      _tr(lang, 'exs', {'n': w.ex.length.toString()})
    ];
    final List<int> count = List<int>.filled(6, 0);
    for (final int e in w.ex) {
      for (final int g in d.exGroups[e] ?? const <int>[]) {
        if (g >= 0 && g < 6) count[g]++;
      }
    }
    final List<int> top = [
      for (int g = 0; g < 6; g++)
        if (count[g] > 0) g
    ];
    top.sort((a, b) {
      if (count[a] != count[b]) return count[b].compareTo(count[a]);
      return a.compareTo(b);
    });
    if (top.isNotEmpty) {
      parts.add([for (final int g in top.take(2)) _tr(lang, 'g' + g.toString())]
          .join(' · '));
    }
    final int? last = d.lastDone[w.id];
    if (last != null) {
      final int n = today - last;
      parts.add(
          n <= 0 ? _tr(lang, 'today') : _tr(lang, 'ago', {'n': n.toString()}));
    }
    return parts.join(' · ');
  }

  _Wk? _wk(_Data d, String wid) {
    for (final _Wk w in d.workouts) {
      if (w.id == wid) return w;
    }
    return null;
  }

  Widget _slotRow(BuildContext context, String lang, _Pal p, _Data d,
      Map<String, List<int>> ex, List<List<String>> slots, int i, int today) {
    final List<String> s = slots[i];
    final TextStyle small =
        _ts(context, 12, FontWeight.w400, p.soft, height: 1.35);
    final List<Widget> lines = [
      Text(
        [for (final String w in s) _nameOf(lang, w)].join('  ⇄  '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: _ts(context, 14.5, FontWeight.w600, p.ink, height: 1.25),
      ),
    ];
    if (s.length > 1) {
      final List<int> a = ex[s[0]] ?? const <int>[];
      final List<int> b = ex[s[1]] ?? const <int>[];
      int same = 0;
      for (final int x in a) {
        if (b.contains(x)) same++;
      }
      final int total = a.length > b.length ? a.length : b.length;
      lines.add(Text(_tr(lang, 'alt'), style: small));
      lines.add(Text(
        _tr(lang, 'shared', {'a': same.toString(), 'b': total.toString()}),
        style: small,
      ));
      lines.add(_link(context, p, _tr(lang, 'sep'), () {
        _change(() => _cfg.split.add(s.last));
      }));
    } else {
      final _Wk? w = _wk(d, s[0]);
      if (w != null) {
        lines.add(Text(_metaOf(lang, d, w, today),
            maxLines: 1, overflow: TextOverflow.ellipsis, style: small));
      }
      if (_cfg.split.contains(s[0])) {
        String home = '';
        for (final String o in _cfg.order) {
          if (o != s[0] &&
              _jaccard(ex[o] ?? const <int>[], ex[s[0]] ?? const <int>[]) >=
                  0.5) {
            home = o;
            break;
          }
        }
        if (home.isNotEmpty) {
          lines.add(_link(
              context, p, _tr(lang, 'join', {'w': _nameOf(lang, home)}), () {
            _change(() => _cfg.split.remove(s[0]));
          }));
        }
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle),
            child: Text((i + 1).toString(),
                style: _ts(context, 13, FontWeight.w700, Colors.white,
                    height: 1.0)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: lines,
            ),
          ),
          if (i > 0) ...[
            const SizedBox(width: 6),
            _mini(p, Icons.arrow_upward_rounded, () => _moveUp(i)),
          ],
          const SizedBox(width: 6),
          _mini(p, Icons.close_rounded, () {
            _change(() {
              _cfg.order.remove(s.last);
              _cfg.split.remove(s.last);
            });
          }),
        ],
      ),
    );
  }

  List<Widget> _stepTwo(
      BuildContext context, String lang, _Pal p, _Data d, int first) {
    final Map<String, List<int>> ex = _exMap();
    final List<List<String>> slots = _slots();
    final int today = _dayNo(DateTime.now());
    final Widget rule = Container(height: 1, color: p.line);

    final List<Widget> chosen = [];
    for (int i = 0; i < slots.length; i++) {
      if (i > 0) chosen.add(rule);
      chosen.add(_slotRow(context, lang, p, d, ex, slots, i, today));
    }

    // The library: everything not in the plan, most recently done first.
    final List<_Wk> free = [
      for (final _Wk w in d.workouts)
        if (!_cfg.order.contains(w.id)) w
    ];
    final String q = _query.trim().toLowerCase();
    final List<_Wk> pool = [
      for (final _Wk w in free)
        if (q.isEmpty || localizedName(w.name, lang).toLowerCase().contains(q))
          w
    ];
    final List<int> idx = [for (int i = 0; i < pool.length; i++) i];
    idx.sort((a, b) {
      final int da = d.lastDone[pool[a].id] ?? -1;
      final int db = d.lastDone[pool[b].id] ?? -1;
      if (da != db) return db.compareTo(da);
      return a.compareTo(b);
    });
    final bool cut = q.isEmpty && !_showAll && pool.length > 4;
    final int shown = cut ? 3 : pool.length;
    // Rest is asked only when it can matter: more workouts a week than
    // workouts in the plan, so one of them comes back within the same week.
    final Map<int, String>? hand = _manual;
    final int perWeek = hand == null ? _cfg.n : hand.length;
    final bool repeats = slots.isNotEmpty && perWeek > slots.length;
    bool tight = false;
    if (repeats && hand == null && _cfg.rest > 0) {
      final List<int> pos = [
        for (final int wd in _draftDays(first)) _posOf(wd, first)
      ];
      pos.sort();
      tight = _sameViol(pos, slots.length, _cfg.rest) > 0;
    }

    final List<Widget> lib = [];
    for (int k = 0; k < shown; k++) {
      final _Wk w = pool[idx[k]];
      if (k > 0) lib.add(rule);
      lib.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    localizedName(w.name, lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _ts(context, 14.5, FontWeight.w600, p.ink,
                        height: 1.25),
                  ),
                  Text(
                    _metaOf(lang, d, w, today),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        _ts(context, 12, FontWeight.w400, p.soft, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _mini(p, Icons.add_rounded, () {
              _change(() => _cfg.order.add(w.id));
            }, mint: true),
          ],
        ),
      ));
    }

    return [
      ..._titles(context, p, _tr(lang, 's2'), _tr(lang, 's2s')),
      _box(p, [
        _label(context, p, _tr(lang, 'inPlan')),
        if (chosen.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_tr(lang, 'none'),
                style:
                    _ts(context, 12.5, FontWeight.w400, p.soft, height: 1.35)),
          ),
        ...chosen,
      ]),
      const SizedBox(height: 12),
      _box(p, [
        _label(context, p, _tr(lang, 'all')),
        if (free.length > 4) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            cursorColor: p.primary,
            style: _ts(context, 14, FontWeight.w500, p.ink, height: 1.3),
            decoration: InputDecoration(
              hintText: _tr(lang, 'search'),
              hintStyle: _ts(context, 14, FontWeight.w400, p.soft, height: 1.3),
              prefixIcon: Icon(Icons.search_rounded, color: p.soft, size: 20),
              isDense: true,
              filled: true,
              fillColor: p.card,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: p.line, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: p.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 2),
        ],
        if (lib.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_tr(lang, free.isEmpty ? 'allIn' : 'noMatch'),
                style:
                    _ts(context, 12.5, FontWeight.w400, p.soft, height: 1.35)),
          ),
        ...lib,
        if (cut)
          GestureDetector(
            onTap: () {
              _tap();
              setState(() => _showAll = true);
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Text(
                _tr(lang, 'showAll', {'n': pool.length.toString()}),
                style:
                    _ts(context, 13, FontWeight.w600, p.mintSoft, height: 1.2),
              ),
            ),
          ),
      ]),
      if (repeats) ...[
        const SizedBox(height: 12),
        _box(p, [
          _label(
            context,
            p,
            _tr(lang, 'restBetween'),
            _tr(lang, 'restWhy', {
              'n': perWeek.toString(),
              's': slots.length.toString(),
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int r = 0; r <= 2; r++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(start: r == 0 ? 0 : 6),
                    child: _chip(context, p, _tr(lang, 'rest' + r.toString()),
                        _cfg.rest == r, () {
                      _change(() => _cfg.rest = r);
                    }),
                  ),
                ),
            ],
          ),
          if (tight)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _tr(lang, 'tight'),
                style:
                    _ts(context, 12.5, FontWeight.w400, p.soft, height: 1.35),
              ),
            ),
        ]),
      ],
      const SizedBox(height: 14),
      _pill(
        context,
        p,
        _tr(lang, slots.isEmpty ? 'pick' : 'next'),
        slots.isEmpty
            ? null
            : () {
                _tap();
                _go(3);
              },
      ),
    ];
  }

  // ---------- step 3: the week board ----------
  /// What follows the finger while dragging.
  Widget _ghost(BuildContext context, _Pal p, bool rtl, String label) {
    return FractionalTranslation(
      translation: const Offset(-0.5, -1.15),
      child: Material(
        color: Colors.transparent,
        child: Directionality(
          textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: Container(
            height: 42,
            constraints: const BoxConstraints(maxWidth: 240),
            padding: const EdgeInsetsDirectional.only(start: 8, end: 14),
            decoration: BoxDecoration(
              color: p.mint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.primary, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.drag_indicator_rounded,
                    size: 18, color: p.mintInk.withAlpha(120)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _ts(context, 13.5, FontWeight.w600, p.mintInk,
                        height: 1.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _trayChip(BuildContext context, String lang, _Pal p, int first,
      bool rtl, int i, List<String> slot, int used) {
    final String id = 's' + i.toString();
    final bool on = _arm == id;
    final String label =
        [for (final String w in slot) _nameOf(lang, w)].join('  ⇄  ');
    final Color fg = on ? Colors.white : p.mintInk;
    final Widget chip = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 36,
      padding: const EdgeInsetsDirectional.only(start: 8, end: 12),
      decoration: BoxDecoration(
        color: on ? p.primary : p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: on ? p.primary : p.mintLine, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.drag_indicator_rounded,
              size: 16, color: fg.withAlpha(120)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _ts(context, 13.5, FontWeight.w600, fg, height: 1.2),
            ),
          ),
          if (used > 0) ...[
            const SizedBox(width: 6),
            Text('×' + used.toString(),
                style: _ts(context, 11.5, FontWeight.w700, fg.withAlpha(150),
                    height: 1.2)),
          ],
        ],
      ),
    );
    return LongPressDraggable<String>(
      data: id,
      delay: const Duration(milliseconds: 180),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: _ghost(context, p, rtl, label),
      onDragStarted: () {
        if (_arm != null) setState(() => _arm = null);
      },
      child: GestureDetector(
        onTap: () => _tapPill(id, first),
        behavior: HitTestBehavior.opaque,
        child: chip,
      ),
    );
  }

  /// A workout on a day: drag it, tap it, or drop another one on it (swap).
  Widget _dayPill(BuildContext context, String lang, _Pal p, int first,
      bool rtl, int wd, String wid, bool alt) {
    final String id = 'd' + wd.toString();
    final bool on = _arm == id;
    final String name = _nameOf(lang, wid);
    final Color fg = on ? Colors.white : p.mintInk;
    Widget pill(bool over) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 42,
        padding: const EdgeInsetsDirectional.only(start: 8),
        decoration: BoxDecoration(
          color: on ? p.primary : p.mint,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: (on || over) ? p.primary : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.drag_indicator_rounded,
                size: 18, color: fg.withAlpha(120)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _ts(context, 13.5, FontWeight.w600, fg, height: 1.2),
              ),
            ),
            if (alt)
              Icon(Icons.swap_horiz_rounded,
                  size: 16, color: fg.withAlpha(150)),
            GestureDetector(
              onTap: () => _applyDrop(id, 'tray', first),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 38,
                height: 42,
                child: Icon(Icons.close_rounded,
                    size: 17, color: fg.withAlpha(160)),
              ),
            ),
          ],
        ),
      );
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != id,
      onAcceptWithDetails: (details) => _applyDrop(details.data, id, first),
      builder: (ctx, candidates, rejected) {
        return LongPressDraggable<String>(
          data: id,
          delay: const Duration(milliseconds: 180),
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: _ghost(context, p, rtl, name),
          childWhenDragging: Opacity(opacity: 0.3, child: pill(false)),
          onDragStarted: () {
            if (_arm != null) setState(() => _arm = null);
          },
          child: GestureDetector(
            onTap: () => _tapPill(id, first),
            behavior: HitTestBehavior.opaque,
            child: pill(candidates.isNotEmpty),
          ),
        );
      },
    );
  }

  /// A free day: drop a workout here, or tap to place the picked one.
  Widget _emptyZone(
      BuildContext context, String lang, _Pal p, int first, int wd, bool armS) {
    final String id = 'd' + wd.toString();
    final bool on = _arm == id;
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) => _applyDrop(details.data, id, first),
      builder: (ctx, candidates, rejected) {
        final bool over = candidates.isNotEmpty;
        final bool hot = on || over;
        final bool hint = armS && !hot;
        return GestureDetector(
          onTap: () => _tapEmpty(wd, first),
          behavior: HitTestBehavior.opaque,
          child: CustomPaint(
            foregroundPainter:
                hot ? null : _DashPainter(hint ? p.mintLine : p.line, 14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (hot || hint)
                    ? p.primary.withAlpha(22)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: hot ? p.primary : Colors.transparent, width: 1.5),
              ),
              child: Text(
                (armS || over) ? '+ ' + _tr(lang, 'here') : _tr(lang, 'rest'),
                maxLines: 1,
                style: _ts(context, 12.5, FontWeight.w500,
                    (hot || hint) ? p.mintSoft : p.soft,
                    height: 1.2),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _stepThree(
      BuildContext context, String lang, _Pal p, int first, bool rtl) {
    final List<List<String>> slots = _slots();
    final List<int> a = _assign(first, slots);
    final List<String> turn = _turns(a, slots);
    int cnt = 0;
    for (final int v in a) {
      if (v >= 0) cnt++;
    }
    final bool manual = _manual != null;
    final String arm = _arm ?? '';
    final bool armS = arm.startsWith('s');

    final List<Widget> tray = [];
    for (int i = 0; i < slots.length; i++) {
      int used = 0;
      for (final int v in a) {
        if (v == i) used++;
      }
      tray.add(_trayChip(context, lang, p, first, rtl, i, slots[i], used));
    }

    final List<Widget> rows = [];
    for (int pos = 0; pos < 7; pos++) {
      final int wd = _wdAt(pos, first);
      final int v = a[pos];
      Widget zone;
      if (v == -2) {
        zone = Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            _tr(lang, 'cant'),
            maxLines: 1,
            style: _ts(context, 12.5, FontWeight.w500, p.soft, height: 1.2)
                .copyWith(decoration: TextDecoration.lineThrough),
          ),
        );
      } else if (v >= 0) {
        zone = _dayPill(
            context, lang, p, first, rtl, wd, turn[pos], slots[v].length > 1);
      } else {
        zone = _emptyZone(context, lang, p, first, wd, armS);
      }
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Text(
                _dayRow(lang, wd),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _ts(
                    context, 12.5, FontWeight.w600, v >= 0 ? p.ink : p.soft,
                    height: 1.2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: zone),
          ],
        ),
      ));
    }

    final bool many = _options(first).length > 1;
    final bool hasRow = _data?.row != null;
    return [
      ..._titles(context, p, _tr(lang, 'yourWeek'), _tr(lang, 's3s')),
      Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: p.mint,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              _tr(lang, manual ? 'edited' : 'auto'),
              style:
                  _ts(context, 11.5, FontWeight.w700, p.mintInk, height: 1.2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _tr(lang, 'cnt', {'n': cnt.toString()}),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _ts(context, 12.5, FontWeight.w400, p.soft, height: 1.2),
            ),
          ),
          if (manual)
            GestureDetector(
              onTap: () {
                _tap();
                setState(() {
                  _manual = null;
                  _arm = null;
                  _saved = false;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Text(_tr(lang, 'backAuto'),
                  style: _ts(context, 12.5, FontWeight.w600, p.mintSoft,
                      height: 1.2)),
            )
          else if (many)
            GestureDetector(
              onTap: () {
                _tap();
                setState(() {
                  _cfg.layout++;
                  _arm = null;
                  _saved = false;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Text(_tr(lang, 'other'),
                  style: _ts(context, 12.5, FontWeight.w600, p.mintSoft,
                      height: 1.2)),
            ),
        ],
      ),
      const SizedBox(height: 10),
      _box(p, [
        // The tray: every workout of the rotation. Dropping a workout back
        // here takes it off the week.
        DragTarget<String>(
          onWillAcceptWithDetails: (details) => details.data.startsWith('d'),
          onAcceptWithDetails: (details) =>
              _applyDrop(details.data, 'tray', first),
          builder: (ctx, candidates, rejected) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: candidates.isNotEmpty
                    ? p.primary.withAlpha(22)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Wrap(spacing: 8, runSpacing: 8, children: tray),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Container(height: 1, color: p.line),
        ),
        ...rows,
      ]),
      const SizedBox(height: 14),
      _pill(
        context,
        p,
        _tr(lang, _saved ? 'saved' : (cnt > 0 ? 'save' : 'place1')),
        (cnt > 0 && !_saved) ? () => _save(first) : null,
      ),
      if (hasRow)
        Center(
          child: GestureDetector(
            onTap: () {
              if (_sure) {
                _delete();
              } else {
                _tap();
                setState(() => _sure = true);
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                _tr(lang, _sure ? 'deleteSure' : 'delete'),
                style: _ts(context, 13, FontWeight.w600,
                    _sure ? FlutterFlowTheme.of(context).error : p.soft,
                    height: 1.2),
              ),
            ),
          ),
        ),
    ];
  }

  // ---------- page ----------
  Widget _page(BuildContext context, String lang, int first, bool rtl) {
    final _Pal p = _Pal(FlutterFlowTheme.of(context));
    final _Data? d = _data;
    final List<Widget> kids = [_header(context, p)];
    if (d != null) {
      if (d.workouts.isEmpty) {
        kids.add(const SizedBox(height: 14));
        kids.add(_box(p, [
          Text(_tr(lang, 'noWorkouts'),
              style: _ts(context, 14.5, FontWeight.w500, p.soft, height: 1.4)),
        ]));
      } else {
        final List<Widget> body = _step == 1
            ? _stepOne(context, lang, p, first)
            : (_step == 2
                ? _stepTwo(context, lang, p, d, first)
                : _stepThree(context, lang, p, first, rtl));
        kids.add(AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          layoutBuilder: (Widget? current, List<Widget> previous) {
            return Stack(
              alignment: Alignment.topCenter,
              fit: StackFit.passthrough,
              children: [
                ...previous,
                if (current != null) current,
              ],
            );
          },
          child: Column(
            key: ValueKey<int>(_step),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: body,
          ),
        ));
      }
    }
    return Material(
      color: p.bg,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: kids,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);
    // Week start follows the locale: 0 = Sunday in Flutter, 7 here.
    int first = 1;
    try {
      final int idx = MaterialLocalizations.of(context).firstDayOfWeekIndex;
      first = idx == 0 ? 7 : idx;
    } catch (_) {}
    return MediaQuery.withNoTextScaling(
      child: Directionality(
        textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: _page(context, lang, first, rtl),
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
