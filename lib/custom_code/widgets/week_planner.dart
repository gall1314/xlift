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

/// Weekly training plan: the user says how many workouts a week, which
/// workouts (in rotation order), how much rest between them, which days are
/// off and which body areas are on hold - and gets a fixed weekly schedule.
///
/// The plan follows "which workout is next", not the calendar: train a day
/// early, late or skip one, and the rest of the week re-plans itself
/// (rotation continues from the last workout actually logged, the weekly
/// target and the rest preference are kept, planned days are preferred).
///
/// Variations: workouts that share at least half of their exercises are
/// treated as one slot and alternate (Push A, then Push B next time). The
/// user can split them back into separate workouts.
///
/// Injuries: body areas put on hold skip every workout where at least half
/// of the exercises target that area.
///
/// Fully self-managed. Creates its own local table on first use
/// (training_plan, one row per user) and reads workout, workout_exercise,
/// workout_log and the muscle tables itself. Every save (and delete) also
/// queues the row in the Hive box pendingTrainingPlans, which
/// syncAllPending sends to the Supabase table training_plan. Reloads when [userId] or
/// [refreshKey] changes and when a page opened on top of it is closed.
///
/// Two looks in one widget:
///  - [compact] = true: a Home card (width infinity, height 96) with today's
///    workout and a Start button, or the next workout on a rest day, or an
///    invitation to build a plan. The card fires [onOpen]; Start fires
///    [onStart] with the workout id.
///  - [compact] = false / unset: the full page (width and height infinity):
///    this week, the rotation, and the plan builder with a live preview.
///    [onClose] adds a back button.
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

  /// For other widgets (the Home screen): what the saved plan says right
  /// now. Keys: hasPlan (bool), workoutId (String, the workout that is up
  /// next in the rotation, '' = none), isToday (bool, a workout is planned
  /// for today), plannedWeekdays (List<int>, 1 = Monday .. 7 = Sunday, the
  /// days still planned this week). [firstDay] = first day of the week
  /// (1 = Monday, 7 = Sunday). Never throws.
  static Future<Map<String, dynamic>> snapshot(String userId, int firstDay) =>
      _snapshot(userId, firstDay);

  @override
  State<WeekPlanner> createState() => _WeekPlannerState();
}

// ---------------------------------------------------------------------------
// Localization (order: en, es, he, de, fr)
// ---------------------------------------------------------------------------

const Color _kHero = Color(0xFF0B1413);
const Set<String> _kRtl = {'he', 'ar'};
const List<String> _kLangs = ['en', 'es', 'he', 'de', 'fr'];

const Map<String, List<String>> _kS = {
  'title': [
    'Weekly plan',
    'Plan semanal',
    'התוכנית השבועית',
    'Wochenplan',
    'Plan hebdo'
  ],
  'thisWeek': [
    'This week',
    'Esta semana',
    'השבוע',
    'Diese Woche',
    'Cette semaine'
  ],
  'progress': [
    '{a} of {b} done',
    '{a} de {b} hechos',
    '{a} מתוך {b} בוצעו',
    '{a} von {b} erledigt',
    '{a} sur {b} faites'
  ],
  'today': ['Today', 'Hoy', 'היום', 'Heute', "Aujourd'hui"],
  'tomorrow': ['Tomorrow', 'Mañana', 'מחר', 'Morgen', 'Demain'],
  'restDay': [
    'Rest day',
    'Día de descanso',
    'יום מנוחה',
    'Ruhetag',
    'Jour de repos'
  ],
  'doneToday': [
    'Done for today',
    'Hecho por hoy',
    'האימון של היום בוצע',
    'Für heute erledigt',
    "Fait pour aujourd'hui"
  ],
  'next': [
    'Next: {w} · {d}',
    'Siguiente: {w} · {d}',
    'הבא: {w} · {d}',
    'Als Nächstes: {w} · {d}',
    'Ensuite : {w} · {d}'
  ],
  'start': ['Start', 'Empezar', 'התחלה', 'Starten', 'Démarrer'],
  'anyway': [
    'Train anyway',
    'Entrenar igual',
    'אימון בכל זאת',
    'Trotzdem trainieren',
    "S'entraîner quand même"
  ],
  'perWeek': [
    'Workouts per week',
    'Entrenos por semana',
    'אימונים בשבוע',
    'Workouts pro Woche',
    'Séances par semaine'
  ],
  'rotation': [
    'Your rotation',
    'Tu rotación',
    'סבב האימונים',
    'Deine Rotation',
    'Ta rotation'
  ],
  'rotHint': [
    'Tap in the order you train',
    'Toca en el orden en que entrenas',
    'בחירה לפי סדר האימונים',
    'Tippe in deiner Reihenfolge',
    "Touche dans l'ordre voulu"
  ],
  'altWith': [
    'Alternates with {w}',
    'Alterna con {w}',
    'מתחלף עם {w}',
    'Wechselt mit {w}',
    'Alterne avec {w}'
  ],
  'altOff': [
    'Similar to {w} · separate',
    'Parecido a {w} · aparte',
    'דומה ל-{w} · נפרד',
    'Ähnlich wie {w} · getrennt',
    'Proche de {w} · à part'
  ],
  'restBetween': [
    'Rest between workouts',
    'Descanso entre entrenos',
    'מנוחה בין אימונים',
    'Pause zwischen Workouts',
    'Repos entre séances'
  ],
  'rest0': ['Any', 'Da igual', 'לא משנה', 'Egal', 'Peu importe'],
  'rest1': ['1 day +', '1 día +', 'יום +', '1 Tag +', '1 jour +'],
  'rest2': ['2 days +', '2 días +', 'יומיים +', '2 Tage +', '2 jours +'],
  'daysOff': [
    "Days you can't train",
    'Días sin entreno',
    'ימים בלי אימון',
    'Tage ohne Training',
    'Jours sans séance'
  ],
  'hold': [
    'Working around an injury?',
    '¿Alguna lesión?',
    'יש פציעה?',
    'Verletzung?',
    'Une blessure ?'
  ],
  'holdHint': [
    'Workouts built around these areas are skipped',
    'Se saltan los entrenos centrados en estas zonas',
    'אימונים שמבוססים על האזורים האלה ידולגו',
    'Workouts mit diesem Fokus werden übersprungen',
    'Les séances centrées sur ces zones sont sautées'
  ],
  'yourWeek': [
    'Your week',
    'Tu semana',
    'השבוע שלך',
    'Deine Woche',
    'Ta semaine'
  ],
  'other': [
    'Another layout',
    'Otra distribución',
    'סידור אחר',
    'Andere Aufteilung',
    'Autre répartition'
  ],
  'save': [
    'Save plan',
    'Guardar plan',
    'שמירת התוכנית',
    'Plan speichern',
    'Enregistrer le plan'
  ],
  'edit': [
    'Edit plan',
    'Editar plan',
    'עריכת התוכנית',
    'Plan bearbeiten',
    'Modifier le plan'
  ],
  'cancel': ['Cancel', 'Cancelar', 'ביטול', 'Abbrechen', 'Annuler'],
  'delete': [
    'Delete plan',
    'Eliminar plan',
    'מחיקת התוכנית',
    'Plan löschen',
    'Supprimer le plan'
  ],
  'noWorkouts': [
    'Create a workout first, then build your week.',
    'Crea un entreno primero y luego arma tu semana.',
    'קודם יוצרים אימון, ואז בונים את השבוע.',
    'Erstell zuerst ein Workout, dann plan deine Woche.',
    "Crée d'abord une séance, puis planifie ta semaine."
  ],
  'pick': [
    'Pick at least one workout',
    'Elige al menos un entreno',
    'צריך לבחור לפחות אימון אחד',
    'Wähle mindestens ein Workout',
    'Choisis au moins une séance'
  ],
  'noteB2B': [
    'Some workouts fall back to back',
    'Algunos entrenos quedan seguidos',
    'חלק מהאימונים יוצאים ברצף',
    'Einige Workouts liegen direkt hintereinander',
    'Certaines séances se suivent'
  ],
  'noteFew': [
    'Only {n} days are free',
    'Solo hay {n} días libres',
    'רק {n} ימים פנויים',
    'Nur {n} Tage sind frei',
    'Seuls {n} jours sont libres'
  ],
  'noteHeld': [
    '{w} is on hold',
    '{w} está en pausa',
    '{w} בהמתנה',
    '{w} pausiert',
    '{w} est en pause'
  ],
  'noteMiss': [
    "{n} won't fit this week",
    '{n} no caben esta semana',
    '{n} לא ייכנסו השבוע',
    '{n} passen diese Woche nicht mehr',
    '{n} ne rentrent plus cette semaine'
  ],
  'noteMore': [
    'The rotation continues next week',
    'La rotación sigue la próxima semana',
    'הסבב ממשיך בשבוע הבא',
    'Die Rotation läuft nächste Woche weiter',
    'La rotation continue la semaine prochaine'
  ],
  'build': [
    'Build your weekly plan',
    'Arma tu plan semanal',
    'בניית תוכנית שבועית',
    'Wochenplan erstellen',
    'Crée ton plan hebdo'
  ],
  'buildSub': [
    'Pick your days, get your next workout',
    'Elige tus días y sabrás qué toca',
    'בוחרים ימים ומקבלים את האימון הבא',
    'Tage wählen, nächstes Workout sehen',
    'Choisis tes jours, vois ta prochaine séance'
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
  final int rest; // preferred rest days between workouts
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

/// Every way to place [n] workouts on the free weekdays, best first: fewest
/// rest-preference breaks, then the widest smallest gap, then the most even
/// spread, then the earliest days. Weekdays come back in week order.
List<List<int>> _pickDays(int n, List<int> blocked, int rest, int first) {
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
    int viol = 0, minGap = 9, spread = 0;
    for (int i = 0; i < k; i++) {
      final int g = k == 1 ? 7 : (set[(i + 1) % k] - set[i] + 7) % 7;
      if (g - 1 < rest) viol++;
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

/// Rest-preference breaks that the fixed week itself contains.
int _baseViol(List<int> trainDays, int rest, int first) {
  final List<int> set = [];
  for (final int wd in trainDays) {
    set.add(_posOf(wd, first));
  }
  set.sort();
  final int k = set.length;
  int v = 0;
  for (int i = 0; i < k; i++) {
    final int g = k == 1 ? 7 : (set[(i + 1) % k] - set[i] + 7) % 7;
    if (g - 1 < rest) v++;
  }
  return v;
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

/// Position in [act] of the slot that is up next: the one after the last
/// plan workout that was actually logged ([logsDesc] is newest first).
int _pointerOf(List<_Act> act, List<List<String>> slots, List<_Log> logsDesc) {
  if (act.isEmpty) return 0;
  int lastSlot = -1;
  for (final _Log l in logsDesc) {
    int si = -1;
    for (int i = 0; i < slots.length; i++) {
      if (slots[i].contains(l.wid)) {
        si = i;
        break;
      }
    }
    if (si >= 0) {
      lastSlot = si;
      break;
    }
  }
  for (int p = 0; p < act.length; p++) {
    if (act[p].i > lastSlot) return p;
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
  final int base = _baseViol(plan.trainDays, plan.rest, first);
  _Cand best = _Cand(<int>[], 0, need, 0, 99, 0);
  for (int m = 1; m < (1 << cand.length); m++) {
    final List<int> set = [];
    for (int i = 0; i < cand.length; i++) {
      if ((m & (1 << i)) != 0) set.add(cand[i]);
    }
    if (set.length > need) continue;
    int viol = 0, minGap = 99, overlap = 0, sum = 0, prev = last;
    for (final int d in set) {
      if (prev >= 0) {
        if (d - prev - 1 < plan.rest) viol++;
        if (d - prev < minGap) minGap = d - prev;
      }
      if (plan.trainDays.contains(_wdOf(d))) overlap++;
      sum += d - today;
      prev = d;
    }
    final _Cand c = _Cand(set, viol > base ? viol - base : 0, need - set.length,
        overlap, minGap, sum);
    if (_cmpWeek(c, best) < 0) best = c;
  }

  final List<_Act> act = _activeSlots(plan.slots, plan.held);
  final int ptr = _pointerOf(act, plan.slots, logsDesc);
  final Map<int, int> occ = {};
  final Map<int, _Pick> planned = {};
  _Pick? upNext;
  if (act.isNotEmpty) {
    for (int k = 0; k < best.set.length; k++) {
      final _Act s = act[(ptr + k) % act.length];
      final int o = occ[s.i] ?? 0;
      occ[s.i] = o + 1;
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

class _Wk {
  _Wk(this.id, this.name, this.ex);
  final String id;
  final String name;
  final List<int> ex;
}

class _Data {
  _Data(this.workouts, this.exGroups, this.logs, this.row);
  final List<_Wk> workouts;
  final Map<int, List<int>> exGroups; // exercise -> body areas (0..5)
  final List<_Log> logs;
  final Map<String, Object?>? row; // the saved plan, null = none
}

/// What the builder edits.
class _Cfg {
  int n = 3;
  int rest = 1;
  List<int> blocked = [];
  List<String> order = []; // workout ids in rotation order
  List<String> split = []; // similar workouts the user keeps separate
  List<int> hold = []; // body areas on hold
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
  for (final r in lRows) {
    final DateTime? dt = _parseDt(r['created_at']);
    if (dt == null) continue;
    final int day = _dayNo(dt);
    if (day < from) continue;
    logs.add(_Log(day, dt.millisecondsSinceEpoch, (r['wid'] ?? '').toString()));
  }
  return _Data(workouts, exGroups, logs, pRows.isEmpty ? null : pRows.first);
}

Future<Map<String, dynamic>> _snapshot(String userId, int first) async {
  final Map<String, dynamic> none = {
    'hasPlan': false,
    'workoutId': '',
    'isToday': false,
    'plannedWeekdays': <int>[],
  };
  try {
    final _Data d = await _loadData(userId);
    final Map<String, Object?>? row = d.row;
    if (row == null) return none;
    final List<String> known = [for (final _Wk w in d.workouts) w.id];
    final List<List<String>> slots = [];
    for (final List<String> slot in _jsonSlots(row['slots'])) {
      final List<String> v = [
        for (final String w in slot)
          if (known.contains(w)) w
      ];
      if (v.isNotEmpty) slots.add(v);
    }
    if (slots.isEmpty) return none;
    final List<int> hold = _csvInts(row['hold_groups']);
    final List<String> held = [];
    if (hold.isNotEmpty) {
      for (final _Wk w in d.workouts) {
        if (w.ex.isEmpty) continue;
        int hit = 0;
        for (final int e in w.ex) {
          final List<int> g = d.exGroups[e] ?? const <int>[];
          if (g.any((x) => hold.contains(x))) hit++;
        }
        if (hit * 2 >= w.ex.length) held.add(w.id);
      }
    }
    final _Plan plan = _Plan(
      _toI(row['per_week'], 3).clamp(1, 7).toInt(),
      _toI(row['rest_days'], 1).clamp(0, 2).toInt(),
      _csvInts(row['blocked_days']),
      _csvInts(row['train_days']),
      slots,
      held,
    );
    final _Week w = _planWeek(plan, d.logs, _dayNo(DateTime.now()), first);
    return {
      'hasPlan': true,
      'workoutId': w.upNext?.wid ?? '',
      'isToday': w.rec?.isToday ?? false,
      'plannedWeekdays': <int>[
        for (final _Cell c in w.cells)
          if (c.kind == 'plan') _wdOf(c.day)
      ],
    };
  } catch (_) {
    return none;
  }
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
  late final Color mintInk;
  late final Color mintSoft;
}

String _initials(String name) {
  final List<String> parts =
      name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  if (parts.length == 1) {
    return parts.first.characters.take(2).toString().toUpperCase();
  }
  return (parts[0].characters.take(1).toString() +
          parts[1].characters.take(1).toString())
      .toUpperCase();
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class _WeekPlannerState extends State<WeekPlanner> {
  _Data? _data;
  _Cfg _cfg = _Cfg();
  bool _editing = false;
  int _token = 0;
  ModalRoute<dynamic>? _route;

  bool get _hasPlan => _data?.row != null;

  @override
  void initState() {
    super.initState();
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
  void didUpdateWidget(covariant WeekPlanner old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId || old.refreshKey != widget.refreshKey) {
      _editing = false;
      _load();
    }
  }

  @override
  void dispose() {
    _route?.secondaryAnimation?.removeStatusListener(_onRouteStatus);
    super.dispose();
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && mounted) _load();
  }

  // ---------- data ----------
  Future<void> _load() async {
    final int token = ++_token;
    _Data d;
    try {
      d = await _loadData(widget.userId);
    } catch (_) {
      d = _Data(<_Wk>[], <int, List<int>>{}, <_Log>[], null);
    }
    if (!mounted || token != _token) return;
    setState(() {
      _data = d;
      if (!_editing) _cfg = _cfgFromRow(d);
    });
  }

  _Cfg _cfgFromRow(_Data d) {
    final _Cfg c = _Cfg();
    final Map<String, Object?>? row = d.row;
    if (row == null) return c;
    final List<String> known = [for (final _Wk w in d.workouts) w.id];
    c.n = _toI(row['per_week'], 3).clamp(1, 7).toInt();
    c.rest = _toI(row['rest_days'], 1).clamp(0, 2).toInt();
    c.blocked = _csvInts(row['blocked_days']);
    c.hold = _csvInts(row['hold_groups']);
    c.layout = _toI(row['layout_index']);
    for (final List<String> slot in _jsonSlots(row['slots'])) {
      for (final String w in slot) {
        if (known.contains(w) && !c.order.contains(w)) c.order.add(w);
      }
    }
    c.split = [
      for (final String w in _jsonStrings(row['split_ids']))
        if (known.contains(w)) w
    ];
    return c;
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

  /// Workouts where at least half of the exercises hit an area on hold.
  List<String> _heldFor(List<int> hold) {
    final List<String> out = [];
    final _Data? d = _data;
    if (d == null || hold.isEmpty) return out;
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

  List<List<int>> _options(int first) {
    final List<List<int>> all =
        _pickDays(_cfg.n, _cfg.blocked, _cfg.rest, first);
    return all.length > 6 ? all.sublist(0, 6) : all;
  }

  List<int> _draftDays(int first) {
    final List<List<int>> o = _options(first);
    return o.isEmpty ? <int>[] : o[_cfg.layout % o.length];
  }

  /// The saved plan, ready for the engine (deleted workouts dropped).
  _Plan? _savedPlan() {
    final _Data? d = _data;
    final Map<String, Object?>? row = d?.row;
    if (d == null || row == null) return null;
    final List<String> known = [for (final _Wk w in d.workouts) w.id];
    final List<List<String>> slots = [];
    for (final List<String> slot in _jsonSlots(row['slots'])) {
      final List<String> v = [
        for (final String w in slot)
          if (known.contains(w)) w
      ];
      if (v.isNotEmpty) slots.add(v);
    }
    return _Plan(
      _toI(row['per_week'], 3).clamp(1, 7).toInt(),
      _toI(row['rest_days'], 1).clamp(0, 2).toInt(),
      _csvInts(row['blocked_days']),
      _csvInts(row['train_days']),
      slots,
      _heldFor(_csvInts(row['hold_groups'])),
    );
  }

  // ---------- actions ----------
  void _tap() => HapticFeedback.selectionClick();

  void _start(String wid) {
    if (wid.isEmpty) return;
    _tap();
    widget.onStart?.call(wid);
  }

  void _toggleWorkout(String wid) {
    _tap();
    setState(() {
      if (_cfg.order.contains(wid)) {
        _cfg.order.remove(wid);
        _cfg.split.remove(wid);
      } else {
        _cfg.order.add(wid);
      }
      _cfg.layout = 0;
    });
  }

  void _toggleIn(List<dynamic> list, dynamic v) {
    _tap();
    setState(() {
      if (list.contains(v)) {
        list.remove(v);
      } else {
        list.add(v);
      }
      _cfg.layout = 0;
    });
  }

  /// Puts the plan row in the offline queue (one entry per user: a newer
  /// save replaces an unsent older one). Never throws.
  Future<void> _queue(Map<String, dynamic> row) async {
    try {
      await Hive.initFlutter();
      final Box box = await Hive.openBox('pendingTrainingPlans');
      await box.put(widget.userId, row);
    } catch (_) {}
  }

  Future<void> _save(int first) async {
    final List<List<String>> slots =
        _buildSlots(_cfg.order, _exMap(), _cfg.split);
    if (slots.isEmpty) return;
    _tap();
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
          _cfg.n,
          _cfg.rest,
          _cfg.blocked.join(','),
          _draftDays(first).join(','),
          jsonEncode(slots),
          jsonEncode(_cfg.split),
          _cfg.hold.join(','),
          _cfg.layout,
          uid,
          now,
          now,
        ],
      );
      // Queue exactly what was stored (created_at of the first save kept).
      final stored =
          await db.rawQuery('SELECT * FROM training_plan WHERE id = ?', [uid]);
      if (stored.isNotEmpty) {
        await _queue(Map<String, dynamic>.from(stored.first));
      }
    } catch (_) {}
    _editing = false;
    await _load();
  }

  Future<void> _delete() async {
    _tap();
    try {
      await SQLiteManager.instance.database
          .rawDelete('DELETE FROM training_plan WHERE id = ?', [widget.userId]);
    } catch (_) {}
    // The cloud queue only upserts, so a deleted plan goes up as an empty
    // one (no workouts); restoreAllFromCloud skips empty plans.
    await _queue(<String, dynamic>{
      'id': widget.userId,
      'user_id': widget.userId,
      'slots': '[]',
      'split_ids': '[]',
      'train_days': '',
      'updated_at': DateTime.now().toIso8601String(),
    });
    _editing = false;
    await _load();
  }

  // ---------- shared pieces ----------
  Widget _pill(BuildContext context, _Pal p, String label, VoidCallback? onTap,
      {bool filled = true, bool onDark = false, bool small = false}) {
    final Color fg = filled ? Colors.white : (onDark ? Colors.white : p.ink);
    final Color edge = onDark ? Colors.white.withAlpha(70) : p.line;
    return Opacity(
      opacity: onTap == null ? 0.4 : 1.0,
      child: Material(
        color: filled ? p.primary : Colors.transparent,
        shape: StadiumBorder(
          side: filled ? BorderSide.none : BorderSide(color: edge, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: small ? 38 : 48,
            padding: EdgeInsets.symmetric(horizontal: small ? 16 : 20),
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _ts(context, small ? 13.5 : 15, FontWeight.w700, fg,
                  height: 1.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, _Pal p, String label, bool on,
      Color onColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? onColor : p.card,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: on ? onColor : p.line, width: 1),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _ts(context, 13, FontWeight.w600, on ? p.card : p.ink,
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

  String _dayLabel(String lang, int day, int today) {
    if (day == today) return _tr(lang, 'today');
    if (day == today + 1) return _tr(lang, 'tomorrow');
    return _tr(lang, 'd' + _wdOf(day).toString());
  }

  /// Seven day cells on a dark card. [today] < 0 = no day is highlighted.
  Widget _strip(
      BuildContext context, String lang, _Pal p, List<_Cell> cells, int today) {
    final Color faint = Colors.white.withAlpha(36);
    final Color soft = Colors.white.withAlpha(158);
    final List<Widget> cols = [];
    for (final _Cell c in cells) {
      final bool isToday = c.day == today;
      Widget inner = const SizedBox.shrink();
      Color fill = Colors.transparent;
      Color edge = faint;
      double edgeW = 1;
      if (c.kind == 'done') {
        fill = p.primary;
        edge = p.primary;
        inner = const Icon(Icons.check_rounded, color: _kHero, size: 20);
      } else if (c.kind == 'plan') {
        edge = p.primary;
        edgeW = 2;
        if (isToday) fill = p.primary.withAlpha(70);
        inner = Text(
          _initials(_nameOf(lang, c.wid)),
          maxLines: 1,
          style: _ts(context, 12, FontWeight.w700, Colors.white, height: 1.0),
        );
      } else if (c.kind == 'miss') {
        inner = Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: soft, shape: BoxShape.circle),
        );
      } else if (c.kind == 'off') {
        fill = Colors.white.withAlpha(14);
        edge = Colors.transparent;
        inner = Text('–',
            style: _ts(context, 13, FontWeight.w600, soft, height: 1.0));
      }
      cols.add(Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _tr(lang, 'd' + _wdOf(c.day).toString()),
              maxLines: 1,
              style: _ts(
                  context,
                  11.5,
                  isToday ? FontWeight.w700 : FontWeight.w500,
                  isToday ? p.primary : soft,
                  height: 1.2),
            ),
            const SizedBox(height: 7),
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(color: edge, width: edgeW),
              ),
              child: inner,
            ),
          ],
        ),
      ));
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: cols);
  }

  /// "Mon · Push A" rows for the planned days.
  List<Widget> _sessionRows(
      BuildContext context, String lang, _Pal p, List<_Cell> cells, int today) {
    final Color soft = Colors.white.withAlpha(158);
    final List<Widget> out = [];
    for (final _Cell c in cells) {
      if (c.kind != 'plan') continue;
      out.add(Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              child: Text(
                _dayLabel(lang, c.day, today),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _ts(context, 13, FontWeight.w500,
                    c.day == today ? p.primary : soft,
                    height: 1.25),
              ),
            ),
            Expanded(
              child: Text(
                _nameOf(lang, c.wid),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _ts(context, 14, FontWeight.w600, Colors.white,
                    height: 1.25),
              ),
            ),
          ],
        ),
      ));
    }
    return out;
  }

  Widget _dark(List<Widget> kids) {
    return Container(
      decoration: BoxDecoration(
        color: _kHero,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: kids,
      ),
    );
  }

  Widget _note(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: _ts(context, 12.5, FontWeight.w500, Colors.white.withAlpha(158),
            height: 1.35),
      ),
    );
  }

  /// Slots whose every variant is on hold -> one note each.
  List<Widget> _heldNotes(BuildContext context, String lang,
      List<List<String>> slots, List<String> held) {
    final List<Widget> out = [];
    for (final List<String> s in slots) {
      if (s.every((w) => held.contains(w))) {
        out.add(_note(
            context, _tr(lang, 'noteHeld', {'w': _nameOf(lang, s.first)})));
      }
    }
    return out;
  }

  // ---------- this week (saved plan) ----------
  List<Widget> _planView(BuildContext context, String lang, _Pal p, int first,
      _Plan plan, List<_Log> logs) {
    final int today = _dayNo(DateTime.now());
    final _Week w = _planWeek(plan, logs, today, first);
    final _Rec? rec = w.rec;
    final _Pick? up = w.upNext;
    final Color soft = Colors.white.withAlpha(158);
    final bool now = rec != null && rec.isToday;
    final String recWid = rec?.wid ?? '';

    String label = _tr(lang, w.trainedToday ? 'doneToday' : 'restDay');
    String big = '';
    if (rec != null) {
      big = now
          ? _nameOf(lang, rec.wid)
          : _tr(lang, 'next', {
              'w': _nameOf(lang, rec.wid),
              'd': _dayLabel(lang, rec.day, today),
            });
    }
    if (now) label = _tr(lang, 'today');

    final List<Widget> hero = [
      Row(
        children: [
          Expanded(
            child: Text(_tr(lang, 'thisWeek'),
                style: _ts(context, 15, FontWeight.w700, Colors.white,
                    height: 1.2)),
          ),
          Text(
            _tr(lang, 'progress',
                {'a': w.done.toString(), 'b': plan.perWeek.toString()}),
            style: _ts(context, 12.5, FontWeight.w500, soft, height: 1.2),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _strip(context, lang, p, w.cells, today),
      const SizedBox(height: 16),
      Container(height: 1, color: Colors.white.withAlpha(26)),
      const SizedBox(height: 14),
      Text(label,
          style: _ts(context, 12.5, FontWeight.w600, p.primary, height: 1.2)),
      if (big.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            big,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _ts(context, now ? 24 : 17, FontWeight.w700, Colors.white,
                height: 1.2, ls: now ? -0.4 : 0),
          ),
        ),
    ];
    final bool canStart = widget.onStart != null;
    if (now && canStart) {
      hero.add(const SizedBox(height: 14));
      hero.add(_pill(context, p, _tr(lang, 'start'), () => _start(recWid)));
    } else if (!now && canStart && up != null && !w.trainedToday) {
      hero.add(const SizedBox(height: 14));
      hero.add(_pill(context, p, _tr(lang, 'anyway'), () => _start(up.wid),
          filled: false, onDark: true));
    }
    if (w.missing > 0) {
      hero.add(
          _note(context, _tr(lang, 'noteMiss', {'n': w.missing.toString()})));
    }
    hero.addAll(_heldNotes(context, lang, plan.slots, plan.held));

    final List<Widget> rot = [_label(context, p, _tr(lang, 'rotation'))];
    for (int i = 0; i < plan.slots.length; i++) {
      final bool isNext = up != null && up.slot == i;
      final bool held = plan.slots[i].every((x) => plan.held.contains(x));
      rot.add(Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isNext ? p.primary : p.mint,
                shape: BoxShape.circle,
              ),
              child: Text(
                (i + 1).toString(),
                style: _ts(context, 12.5, FontWeight.w700,
                    isNext ? Colors.white : p.mintInk,
                    height: 1.0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                [for (final String x in plan.slots[i]) _nameOf(lang, x)]
                    .join('  ⇄  '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _ts(
                    context, 14.5, FontWeight.w600, held ? p.soft : p.ink,
                    height: 1.3),
              ),
            ),
          ],
        ),
      ));
    }

    return [
      _dark(hero),
      const SizedBox(height: 12),
      _box(p, rot),
      const SizedBox(height: 14),
      _pill(context, p, _tr(lang, 'edit'), () {
        _tap();
        setState(() => _editing = true);
      }, filled: false),
      const SizedBox(height: 8),
      Center(
        child: GestureDetector(
          onTap: _delete,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(_tr(lang, 'delete'),
                style:
                    _ts(context, 13.5, FontWeight.w600, p.soft, height: 1.2)),
          ),
        ),
      ),
    ];
  }

  // ---------- builder ----------
  List<Widget> _builder(
      BuildContext context, String lang, _Pal p, int first, _Data d) {
    final Map<String, List<int>> ex = _exMap();
    final List<List<String>> slots = _buildSlots(_cfg.order, ex, _cfg.split);
    final List<String> held = _heldFor(_cfg.hold);
    final List<_Act> act = _activeSlots(slots, held);
    final List<List<int>> opts = _options(first);
    final List<int> days = _draftDays(first);

    // The fixed week of this draft, rotation starting at the first workout.
    final List<_Cell> cells = [];
    final Map<int, int> occ = {};
    int k = 0;
    for (int pos = 0; pos < 7; pos++) {
      final int wd = ((first - 1 + pos) % 7) + 1;
      String kind = _cfg.blocked.contains(wd) ? 'off' : 'rest';
      String wid = '';
      if (days.contains(wd)) {
        kind = 'plan';
        if (act.isNotEmpty) {
          final _Act s = act[k % act.length];
          final int o = occ[s.i] ?? 0;
          occ[s.i] = o + 1;
          wid = s.vars[o % s.vars.length];
        }
        k++;
      }
      cells.add(_Cell(wd + 3, kind, wid)); // weekday of day (wd + 3) is wd
    }

    final List<Widget> rows = [];
    for (final _Wk w in d.workouts) {
      final int idx = _cfg.order.indexOf(w.id);
      final bool on = idx >= 0;
      String chip = '';
      if (on) {
        if (_cfg.split.contains(w.id)) {
          for (int j = 0; j < idx; j++) {
            final String h = _cfg.order[j];
            if (_jaccard(ex[h] ?? const <int>[], w.ex) >= 0.5) {
              chip = _tr(lang, 'altOff', {'w': _nameOf(lang, h)});
              break;
            }
          }
        } else {
          for (final List<String> s in slots) {
            if (s.length > 1 && s.first != w.id && s.contains(w.id)) {
              chip = _tr(lang, 'altWith', {'w': _nameOf(lang, s.first)});
            }
          }
        }
      }
      rows.add(InkWell(
        onTap: () => _toggleWorkout(w.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? p.primary : p.card,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: on ? p.primary : p.line, width: 1.5),
                ),
                child: on
                    ? Text((idx + 1).toString(),
                        style: _ts(context, 13, FontWeight.w700, Colors.white,
                            height: 1.0))
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 12),
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
                          height: 1.3),
                    ),
                    if (chip.isNotEmpty)
                      GestureDetector(
                        onTap: () => _toggleIn(_cfg.split, w.id),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: p.mint,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '⇄  ' + chip,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _ts(context, 12, FontWeight.w600, p.mintInk,
                                height: 1.2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ));
    }

    Widget step(IconData icon, VoidCallback? onTap) {
      return Opacity(
        opacity: onTap == null ? 0.35 : 1.0,
        child: Material(
          color: p.mint,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, color: p.mintInk, size: 22),
            ),
          ),
        ),
      );
    }

    void setN(int v) {
      _tap();
      setState(() {
        _cfg.n = v;
        _cfg.layout = 0;
      });
    }

    final int free = 7 - _cfg.blocked.toSet().length;
    final List<Widget> preview = [
      Text(_tr(lang, 'yourWeek'),
          style: _ts(context, 15, FontWeight.w700, Colors.white, height: 1.2)),
      const SizedBox(height: 14),
      _strip(context, lang, p, cells, -1),
      const SizedBox(height: 6),
      ..._sessionRows(context, lang, p, cells, -1),
      if (free < _cfg.n)
        _note(context, _tr(lang, 'noteFew', {'n': free.toString()})),
      if (_cfg.rest > 0 && _baseViol(days, _cfg.rest, first) > 0)
        _note(context, _tr(lang, 'noteB2B')),
      if (act.length > days.length && days.isNotEmpty)
        _note(context, _tr(lang, 'noteMore')),
      ..._heldNotes(context, lang, slots, held),
      if (opts.length > 1) ...[
        const SizedBox(height: 14),
        _pill(context, p, _tr(lang, 'other'), () {
          _tap();
          setState(() => _cfg.layout = (_cfg.layout + 1) % opts.length);
        }, filled: false, onDark: true, small: true),
      ],
    ];

    return [
      _box(p, [
        Row(
          children: [
            Expanded(child: _label(context, p, _tr(lang, 'perWeek'))),
            step(Icons.remove_rounded,
                _cfg.n > 1 ? () => setN(_cfg.n - 1) : null),
            SizedBox(
              width: 48,
              child: Text(
                _cfg.n.toString(),
                textAlign: TextAlign.center,
                style: _ts(context, 26, FontWeight.w800, p.ink, height: 1.0),
              ),
            ),
            step(Icons.add_rounded, _cfg.n < 7 ? () => setN(_cfg.n + 1) : null),
          ],
        ),
      ]),
      const SizedBox(height: 12),
      _box(p, [
        _label(context, p, _tr(lang, 'rotation'), _tr(lang, 'rotHint')),
        const SizedBox(height: 6),
        ...rows,
      ]),
      const SizedBox(height: 12),
      _box(p, [
        _label(context, p, _tr(lang, 'restBetween')),
        const SizedBox(height: 10),
        Row(
          children: [
            for (int r = 0; r < 3; r++) ...[
              if (r > 0) const SizedBox(width: 8),
              Expanded(
                child: _chip(context, p, _tr(lang, 'rest' + r.toString()),
                    _cfg.rest == r, p.primary, () {
                  _tap();
                  setState(() {
                    _cfg.rest = r;
                    _cfg.layout = 0;
                  });
                }),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _label(context, p, _tr(lang, 'daysOff')),
        const SizedBox(height: 10),
        Row(
          children: [
            for (int pos = 0; pos < 7; pos++) ...[
              if (pos > 0) const SizedBox(width: 5),
              Expanded(
                child: _chip(
                  context,
                  p,
                  _tr(lang, 'd' + (((first - 1 + pos) % 7) + 1).toString()),
                  _cfg.blocked.contains(((first - 1 + pos) % 7) + 1),
                  p.ink,
                  () => _toggleIn(_cfg.blocked, ((first - 1 + pos) % 7) + 1),
                ),
              ),
            ],
          ],
        ),
      ]),
      const SizedBox(height: 12),
      _box(p, [
        _label(context, p, _tr(lang, 'hold'), _tr(lang, 'holdHint')),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int g = 0; g < 6; g++)
              SizedBox(
                width: 98,
                child: _chip(
                    context,
                    p,
                    _tr(lang, 'g' + g.toString()),
                    _cfg.hold.contains(g),
                    p.ink,
                    () => _toggleIn(_cfg.hold, g)),
              ),
          ],
        ),
      ]),
      const SizedBox(height: 12),
      _dark(preview),
      const SizedBox(height: 14),
      _pill(context, p, _tr(lang, slots.isEmpty ? 'pick' : 'save'),
          slots.isEmpty ? null : () => _save(first)),
      if (_hasPlan) ...[
        const SizedBox(height: 8),
        _pill(context, p, _tr(lang, 'cancel'), () {
          _tap();
          _editing = false;
          _load();
        }, filled: false),
      ],
    ];
  }

  // ---------- full page ----------
  Widget _page(BuildContext context, String lang, int first) {
    final _Pal p = _Pal(FlutterFlowTheme.of(context));
    final _Data? d = _data;
    final _Plan? plan = _savedPlan();
    final List<Widget> kids = [
      Row(
        children: [
          if (widget.onClose != null) ...[
            Material(
              color: p.card,
              shape: CircleBorder(side: BorderSide(color: p.line, width: 1)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  _tap();
                  widget.onClose?.call();
                },
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: p.ink, size: 18),
                ),
              ),
            ),
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
        ],
      ),
      const SizedBox(height: 14),
    ];
    if (d != null) {
      if (plan != null && plan.slots.isNotEmpty && !_editing) {
        kids.addAll(_planView(context, lang, p, first, plan, d.logs));
      } else if (d.workouts.isEmpty) {
        kids.add(_box(p, [
          Text(_tr(lang, 'noWorkouts'),
              style: _ts(context, 14.5, FontWeight.w500, p.soft, height: 1.4)),
        ]));
      } else {
        kids.addAll(_builder(context, lang, p, first, d));
      }
    }
    return ColoredBox(
      color: p.bg,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: kids,
          ),
        ),
      ),
    );
  }

  // ---------- compact card (Home) ----------
  Widget _card(BuildContext context, String lang, int first) {
    final _Pal p = _Pal(FlutterFlowTheme.of(context));
    final _Data? d = _data;
    final _Plan? plan = _savedPlan();
    final List<Widget> row = [];
    if (d != null && (plan == null || plan.slots.isEmpty)) {
      row.addAll([
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: p.mint, shape: BoxShape.circle),
          child: Icon(Icons.event_repeat_rounded, color: p.primary, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_tr(lang, 'build'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      _ts(context, 16, FontWeight.w700, p.ink, height: 1.25)),
              const SizedBox(height: 2),
              Text(_tr(lang, 'buildSub'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      _ts(context, 12.5, FontWeight.w500, p.soft, height: 1.3)),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: p.soft, size: 24),
      ]);
    } else if (d != null && plan != null && plan.slots.isNotEmpty) {
      final int today = _dayNo(DateTime.now());
      final _Week w = _planWeek(plan, d.logs, today, first);
      final _Rec? rec = w.rec;
      final bool now = rec != null && rec.isToday;
      final String recWid = rec?.wid ?? '';
      final String label = now
          ? _tr(lang, 'today')
          : _tr(lang, w.trainedToday ? 'doneToday' : 'restDay');
      String big = '';
      if (rec != null) {
        big = now
            ? _nameOf(lang, rec.wid)
            : _tr(lang, 'next', {
                'w': _nameOf(lang, rec.wid),
                'd': _dayLabel(lang, rec.day, today),
              });
      }
      row.addAll([
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: now ? p.primary : p.mint,
            shape: BoxShape.circle,
          ),
          child: w.trainedToday
              ? Icon(Icons.check_rounded, color: p.primary, size: 24)
              : Text(
                  rec == null ? '' : _initials(_nameOf(lang, rec.wid)),
                  style: _ts(context, 15, FontWeight.w800,
                      now ? Colors.white : p.mintInk,
                      height: 1.0),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label +
                    '  ·  ' +
                    _tr(lang, 'progress',
                        {'a': w.done.toString(), 'b': plan.perWeek.toString()}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _ts(context, 12.5, FontWeight.w600, p.mintSoft,
                    height: 1.25),
              ),
              const SizedBox(height: 3),
              Text(
                big,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _ts(context, now ? 18 : 15, FontWeight.w700, p.ink,
                    height: 1.25),
              ),
            ],
          ),
        ),
        if (now && widget.onStart != null) ...[
          const SizedBox(width: 10),
          _pill(context, p, _tr(lang, 'start'), () => _start(recWid),
              small: true),
        ] else
          Icon(Icons.chevron_right_rounded, color: p.soft, size: 24),
      ]);
    }
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.line, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onOpen == null
            ? null
            : () {
                _tap();
                widget.onOpen?.call();
              },
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 12, 0),
          child: Row(children: row),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);
    final bool compact = widget.compact ?? false;
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
          width: compact ? (widget.width ?? double.infinity) : widget.width,
          height: compact ? (widget.height ?? 96.0) : widget.height,
          child: compact
              ? _card(context, lang, first)
              : _page(context, lang, first),
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
