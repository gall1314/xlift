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

import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl show DateFormat;

/// The saved weekly plan and where it stands: this week day by day (done,
/// planned, missed), today's workout or the next one, what is still coming
/// this week, and a note when a missed workout moved the week.
///
/// The plan itself is built and edited in WeekPlanner (which must exist in
/// the project); this widget only shows it. All numbers come from
/// WeekPlanner.snapshot, so both always agree. The one thing changed here is
/// the injury switch: a body area on hold skips the workouts built around
/// it, and is saved to the plan (and queued for the cloud) right away.
///
/// Full page (width and height infinity). Reloads when [userId] or
/// [refreshKey] changes and when a page opened on top of it is closed.
///
///  - [onStart] (workoutId): the Start button. Without it there is no button.
///  - [onEdit]: open the page that holds WeekPlanner. When it is NOT
///    connected, the builder opens right here, inside this widget, and a
///    user without a plan lands in the builder directly - one page is enough.
///  - [onClose] adds a back button.
///
/// Localization: reads the app language from FFLocalizations (no parameter).
class PlanStatus extends StatefulWidget {
  const PlanStatus({
    super.key,
    this.width,
    this.height,
    required this.userId,
    this.refreshKey,
    this.onStart,
    this.onEdit,
    this.onClose,
  });

  final double? width;
  final double? height;
  final String userId;
  final String? refreshKey;
  final Future Function(String workoutId)? onStart;
  final Future Function()? onEdit;
  final Future Function()? onClose;

  @override
  State<PlanStatus> createState() => _PlanStatusState();
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
  'start': [
    'Start workout',
    'Empezar entreno',
    'התחלת אימון',
    'Workout starten',
    'Démarrer la séance'
  ],
  'anyway': [
    'Train today anyway',
    'Entrenar hoy igual',
    'להתאמן היום בכל זאת',
    'Heute trotzdem trainieren',
    "S'entraîner aujourd'hui quand même"
  ],
  'coming': [
    'Coming up',
    'Lo que viene',
    'בהמשך השבוע',
    'Diese Woche noch',
    'À venir'
  ],
  'nothing': [
    'Nothing left this week.',
    'No queda nada esta semana.',
    'אין עוד אימונים השבוע.',
    'Diese Woche steht nichts mehr an.',
    'Plus rien cette semaine.'
  ],
  'moved': [
    'You missed {d}. {w} is still next, and the rest of the week moved with it.',
    'Te saltaste el {d}. {w} sigue siendo el siguiente y el resto de la semana se movió con él.',
    'פספסת את {d}. {w} נשאר הבא בתור, ושאר השבוע זז איתו.',
    '{d} verpasst. {w} bleibt als Nächstes dran, der Rest der Woche rückt mit.',
    'Tu as manqué {d}. {w} reste la prochaine séance et le reste de la semaine suit.'
  ],
  'roll': [
    'Not everything fits this week: {n} moves to next week.',
    'No todo cabe esta semana: {n} pasan a la siguiente.',
    'לא הכול נכנס השבוע: {n} עוברים לשבוע הבא.',
    'Diese Woche passt nicht alles: {n} rutschen in die nächste.',
    'Tout ne rentre pas cette semaine : {n} passent à la suivante.'
  ],
  'paused': [
    '{w} is paused.',
    '{w} está en pausa.',
    '{w} בהשהיה.',
    '{w} pausiert.',
    '{w} est en pause.'
  ],
  'edit': [
    'Edit plan',
    'Editar plan',
    'עריכת התוכנית',
    'Plan bearbeiten',
    'Modifier le plan'
  ],
  'hold': [
    'Working around an injury?',
    '¿Alguna lesión?',
    'יש פציעה?',
    'Verletzung?',
    'Une blessure ?'
  ],
  'holdHint': [
    'Pause a body area. Workouts built around it are skipped until you turn it off.',
    'Pausa una zona del cuerpo. Los entrenos centrados en ella se saltan hasta que la reactives.',
    'משהים אזור בגוף. אימונים שמבוססים עליו ידולגו עד שמכבים.',
    'Pausiere einen Körperbereich. Workouts mit diesem Fokus werden übersprungen, bis du ihn wieder aktivierst.',
    "Mets une zone du corps en pause. Les séances centrées dessus sont sautées jusqu'à ce que tu la réactives."
  ],
  'holdOn': [
    '{n} paused',
    '{n} en pausa',
    '{n} בהשהיה',
    '{n} pausiert',
    '{n} en pause'
  ],
  'noPlan': [
    'No weekly plan yet',
    'Aún no tienes plan semanal',
    'עדיין אין תוכנית שבועית',
    'Noch kein Wochenplan',
    'Pas encore de plan hebdo'
  ],
  'noPlanSub': [
    'Set your days and workouts once. You always see what is next, and the week moves with you when you miss a day.',
    'Elige tus días y entrenos una vez. Siempre verás qué toca, y la semana se mueve contigo si te saltas un día.',
    'בוחרים ימים ואימונים פעם אחת. תמיד רואים מה הבא בתור, והשבוע זז יחד איתך כשמפספסים יום.',
    'Lege Tage und Workouts einmal fest. Du siehst immer, was als Nächstes dran ist, und die Woche rückt mit, wenn du einen Tag verpasst.',
    "Choisis tes jours et tes séances une fois. Tu vois toujours la suite, et la semaine s'adapte si tu manques un jour."
  ],
  'build': [
    'Build my plan',
    'Crear mi plan',
    'בניית תוכנית',
    'Plan erstellen',
    'Créer mon plan'
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

/// Full weekday name in the app language (1 = Monday .. 7 = Sunday).
String _dayLong(String lang, int wd) {
  try {
    // 1 January 2024 is a Monday.
    return intl.DateFormat.EEEE(lang).format(DateTime(2024, 1, wd));
  } catch (_) {
    return _tr(lang, 'd' + wd.toString());
  }
}

String _capital(String s) =>
    s.isEmpty ? s : s.substring(0, 1).toUpperCase() + s.substring(1);

/// Same weekday rule as WeekPlanner: day numbers -> 1 = Monday .. 7 = Sunday.
int _wdOf(int d) => ((d + 3) % 7) + 1;

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

class _Pal {
  _Pal(FlutterFlowTheme th)
      : primary = th.primary,
        bg = th.primaryBackground,
        card = th.secondaryBackground,
        line = th.alternate,
        ink = th.primaryText,
        soft = th.secondaryText;

  final Color primary;
  final Color bg;
  final Color card;
  final Color line;
  final Color ink;
  final Color soft;
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

/// One day of the week, read from WeekPlanner.snapshot.
class _Day {
  _Day(this.day, this.kind, this.wid);
  final int day;
  final String kind; // done, plan, miss, off, rest
  final String wid;
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class _PlanStatusState extends State<PlanStatus> {
  Map<String, dynamic>? _snap;
  bool _editing = false;
  bool _holdOpen = false;
  bool _started = false;
  int _builderTick = 0;
  int _token = 0;
  int _first = 1;
  ModalRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Week start follows the locale: 0 = Sunday in Flutter, 7 here.
    int first = 1;
    try {
      final int idx = MaterialLocalizations.of(context).firstDayOfWeekIndex;
      first = idx == 0 ? 7 : idx;
    } catch (_) {}
    final bool reload = !_started || first != _first;
    _first = first;
    _started = true;
    // Reload when a page opened on top of this one is closed again
    // (back from a finished workout, or from the builder page).
    final ModalRoute<dynamic>? r = ModalRoute.of(context);
    if (!identical(r, _route)) {
      _route?.secondaryAnimation?.removeStatusListener(_onRouteStatus);
      _route = r;
      _route?.secondaryAnimation?.addStatusListener(_onRouteStatus);
    }
    if (reload) _load();
  }

  @override
  void didUpdateWidget(covariant PlanStatus old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId || old.refreshKey != widget.refreshKey) {
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
    final Map<String, dynamic> snap =
        await WeekPlanner.snapshot(widget.userId, _first);
    if (!mounted || token != _token) return;
    setState(() => _snap = snap);
  }

  bool _b(String key) => _snap?[key] == true;

  int _i(String key, [int fallback = 0]) {
    final dynamic v = _snap?[key];
    return v is int ? v : fallback;
  }

  String _nameOf(String lang, String wid) {
    final dynamic names = _snap?['names'];
    if (names is Map) {
      final dynamic raw = names[wid];
      if (raw != null) return localizedName(raw.toString(), lang);
    }
    return '';
  }

  List<int> _hold() {
    final List<int> out = [];
    final dynamic raw = _snap?['hold'];
    if (raw is List) {
      for (final dynamic x in raw) {
        if (x is int && !out.contains(x)) out.add(x);
      }
    }
    return out;
  }

  List<_Day> _days() {
    final List<_Day> out = [];
    final dynamic raw = _snap?['cells'];
    if (raw is List) {
      for (final dynamic c in raw) {
        if (c is Map) {
          final dynamic day = c['day'];
          out.add(_Day(day is int ? day : 0, (c['kind'] ?? 'rest').toString(),
              (c['workoutId'] ?? '').toString()));
        }
      }
    }
    return out;
  }

  // ---------- actions ----------
  void _tap() => HapticFeedback.selectionClick();

  void _edit() {
    _tap();
    if (widget.onEdit != null) {
      widget.onEdit?.call();
    } else {
      setState(() {
        _editing = true;
        _builderTick++;
      });
    }
  }

  /// The builder shown inside this widget was closed (saved, deleted or
  /// backed out of).
  Future<void> _builderClosed() async {
    await _load();
    if (!mounted) return;
    final bool hasPlan = _b('hasPlan');
    setState(() {
      _editing = false;
      if (!hasPlan) _builderTick++;
    });
    // Nothing to show without a plan: leave the page.
    if (!hasPlan) widget.onClose?.call();
  }

  Future<void> _toggleHold(int g) async {
    _tap();
    final List<int> hold = _hold();
    if (hold.contains(g)) {
      hold.remove(g);
    } else {
      hold.add(g);
    }
    setState(() {
      _snap = <String, dynamic>{...?_snap, 'hold': hold};
    });
    await WeekPlanner.setHold(widget.userId, hold);
    await _load();
  }

  // ---------- pieces ----------
  Widget _pill(BuildContext context, _Pal p, String label, VoidCallback? onTap,
      {bool filled = true, bool onDark = false}) {
    final Color fg = filled ? Colors.white : (onDark ? Colors.white : p.ink);
    final Color edge = onDark ? Colors.white.withAlpha(70) : p.line;
    return Material(
      color: filled ? p.primary : Colors.transparent,
      shape: StadiumBorder(
        side: filled ? BorderSide.none : BorderSide(color: edge, width: 1),
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
            style: _ts(context, 15, FontWeight.w700, fg, height: 1.2),
          ),
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

  Widget _note(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        text,
        style: _ts(context, 12.5, FontWeight.w500, Colors.white.withAlpha(158),
            height: 1.35),
      ),
    );
  }

  String _dayLabel(String lang, int day, int today) {
    if (day == today) return _tr(lang, 'today');
    if (day == today + 1) return _tr(lang, 'tomorrow');
    return _dayLong(lang, _wdOf(day));
  }

  /// Seven day cells on the dark card.
  Widget _strip(
      BuildContext context, String lang, _Pal p, List<_Day> days, int today) {
    final Color faint = Colors.white.withAlpha(36);
    final Color soft = Colors.white.withAlpha(158);
    final List<Widget> cols = [];
    for (final _Day c in days) {
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

  Widget _header(BuildContext context, String lang, _Pal p) {
    return Row(
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
    );
  }

  // ---------- the plan ----------
  List<Widget> _status(BuildContext context, String lang, _Pal p) {
    final int today = _i('today');
    final bool now = _b('isToday');
    final bool trained = _b('trainedToday');
    final String nextId = (_snap?['workoutId'] ?? '').toString();
    final int nextDay = _i('nextDay', -1);
    final List<_Day> days = _days();
    final String nextName = _nameOf(lang, nextId);
    final bool canStart = widget.onStart != null && nextId.isNotEmpty;

    final String label =
        now ? _tr(lang, 'today') : _tr(lang, trained ? 'doneToday' : 'restDay');
    String big = '';
    if (nextId.isNotEmpty) {
      big = (now || nextDay < 0)
          ? nextName
          : _tr(lang, 'next',
              {'w': nextName, 'd': _dayLabel(lang, nextDay, today)});
    }

    final List<Widget> notes = [];
    final int missed = _i('missedWeekday');
    if (missed > 0 && nextId.isNotEmpty) {
      notes.add(_note(context,
          _tr(lang, 'moved', {'d': _dayLong(lang, missed), 'w': nextName})));
    }
    final int missing = _i('missing');
    if (missing > 0) {
      notes.add(_note(context, _tr(lang, 'roll', {'n': missing.toString()})));
    }
    final dynamic paused = _snap?['paused'];
    if (paused is List) {
      for (final dynamic w in paused) {
        final String name = _nameOf(lang, w.toString());
        if (name.isNotEmpty) {
          notes.add(_note(context, _tr(lang, 'paused', {'w': name})));
        }
      }
    }

    final List<Widget> coming = [];
    for (final _Day c in days) {
      if (c.kind != 'plan' || (now && c.day == today)) continue;
      coming.add(Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Text(
                _capital(_dayLabel(lang, c.day, today)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _ts(context, 13, FontWeight.w400, p.soft, height: 1.25),
              ),
            ),
            Expanded(
              child: Text(
                _nameOf(lang, c.wid),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _ts(context, 14.5, FontWeight.w600, p.ink, height: 1.25),
              ),
            ),
          ],
        ),
      ));
    }

    final List<int> hold = _hold();
    return [
      // This week, on the dark card.
      Container(
        decoration: BoxDecoration(
          color: _kHero,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(_tr(lang, 'thisWeek'),
                      style: _ts(context, 15, FontWeight.w700, Colors.white,
                          height: 1.25)),
                ),
                Text(
                  _tr(lang, 'progress', {
                    'a': _i('done').toString(),
                    'b': _i('perWeek').toString(),
                  }),
                  style: _ts(context, 12.5, FontWeight.w500,
                      Colors.white.withAlpha(158),
                      height: 1.25),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _strip(context, lang, p, days, today),
            Container(
              height: 1,
              margin: const EdgeInsets.only(top: 16, bottom: 14),
              color: Colors.white.withAlpha(26),
            ),
            Text(label,
                style: _ts(context, 12.5, FontWeight.w600, p.primary,
                    height: 1.25)),
            if (big.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  big,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _ts(
                      context, now ? 24 : 17, FontWeight.w700, Colors.white,
                      height: 1.2, ls: now ? -0.4 : 0),
                ),
              ),
            if (canStart && now) ...[
              const SizedBox(height: 14),
              _pill(context, p, _tr(lang, 'start'), () {
                _tap();
                widget.onStart?.call(nextId);
              }),
            ] else if (canStart && !trained) ...[
              const SizedBox(height: 14),
              _pill(context, p, _tr(lang, 'anyway'), () {
                _tap();
                widget.onStart?.call(nextId);
              }, filled: false, onDark: true),
            ],
            ...notes,
          ],
        ),
      ),
      const SizedBox(height: 12),
      _box(p, [
        Text(_tr(lang, 'coming'),
            style: _ts(context, 15, FontWeight.w700, p.ink, height: 1.25)),
        if (coming.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_tr(lang, 'nothing'),
                style:
                    _ts(context, 12.5, FontWeight.w400, p.soft, height: 1.35)),
          ),
        ...coming,
      ]),
      const SizedBox(height: 12),
      // Injuries live here, not in the builder: switch on, switch off.
      _box(p, [
        GestureDetector(
          onTap: () {
            _tap();
            setState(() => _holdOpen = !_holdOpen);
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Expanded(
                child: Text(_tr(lang, 'hold'),
                    style:
                        _ts(context, 15, FontWeight.w700, p.ink, height: 1.25)),
              ),
              if (hold.isNotEmpty && !_holdOpen)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: Text(
                    _tr(lang, 'holdOn', {'n': hold.length.toString()}),
                    style: _ts(context, 12.5, FontWeight.w600, p.primary,
                        height: 1.25),
                  ),
                ),
              Icon(
                _holdOpen
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: p.soft,
                size: 22,
              ),
            ],
          ),
        ),
        if (_holdOpen) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_tr(lang, 'holdHint'),
                style:
                    _ts(context, 12.5, FontWeight.w400, p.soft, height: 1.35)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int g = 0; g < 6; g++)
                GestureDetector(
                  onTap: () => _toggleHold(g),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 98,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hold.contains(g) ? p.ink : p.card,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(
                          color: hold.contains(g) ? p.ink : p.line, width: 1),
                    ),
                    child: Text(
                      _tr(lang, 'g' + g.toString()),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(context, 13, FontWeight.w600,
                          hold.contains(g) ? p.card : p.ink,
                          height: 1.2),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ]),
      const SizedBox(height: 12),
      _pill(context, p, _tr(lang, 'edit'), _edit, filled: false),
    ];
  }

  List<Widget> _empty(
      BuildContext context, String lang, _Pal p, bool hasWorkouts) {
    if (!hasWorkouts) {
      return [
        _box(p, [
          Text(_tr(lang, 'noWorkouts'),
              style: _ts(context, 14.5, FontWeight.w500, p.soft, height: 1.4)),
        ]),
      ];
    }
    return [
      _box(p, [
        Text(_tr(lang, 'noPlan'),
            style: _ts(context, 17, FontWeight.w700, p.ink, height: 1.25)),
        const SizedBox(height: 4),
        Text(_tr(lang, 'noPlanSub'),
            style: _ts(context, 13.5, FontWeight.w400, p.soft, height: 1.4)),
        const SizedBox(height: 14),
        _pill(context, p, _tr(lang, 'build'), _edit),
      ]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);
    final _Pal p = _Pal(FlutterFlowTheme.of(context));
    final bool loaded = _snap != null;
    final bool hasPlan = _b('hasPlan');
    final bool hasWorkouts = _b('hasWorkouts');

    // No page of its own for the builder: show it right here.
    if (loaded &&
        widget.onEdit == null &&
        (_editing || (!hasPlan && hasWorkouts))) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: WeekPlanner(
          key: ValueKey<int>(_builderTick),
          userId: widget.userId,
          onClose: _builderClosed,
        ),
      );
    }

    final List<Widget> kids = [
      _header(context, lang, p),
      const SizedBox(height: 14),
    ];
    if (loaded) {
      kids.addAll(hasPlan
          ? _status(context, lang, p)
          : _empty(context, lang, p, hasWorkouts));
    }
    return MediaQuery.withNoTextScaling(
      child: Directionality(
        textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: ColoredBox(
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
          ),
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
