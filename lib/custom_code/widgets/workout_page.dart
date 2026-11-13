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
import 'dart:ui' as ui show TextDirection;
import 'package:flutter/cupertino.dart'
    show CupertinoPicker, CupertinoPickerDefaultSelectionOverlay;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '/auth/supabase_auth/auth_util.dart';

// =============================================================================
// WorkoutPage — the whole live-workout screen.
//
// Top bar (back · WorkoutClock · Finish) with the progress line under it, a
// live-stats strip hanging off the bar (collapsed to a chevron handle; tap →
// Sets · Volume · Exercises), a scrolling list of ExerciseCard (one per
// exercise, in exercisesets order) and "Add Exercises" at the bottom. Reads
// App State directly and rebuilds on every change. Give it width ∞ and
// height ∞ in FF; nothing else to set.
//
// One widget for four screens; `mode` picks which:
//   'live'     — the running workout
//   'logEdit'  — editing a logged workout
//   'template' — creating a workout / editing a workout template
//
// Callbacks (navigation only):
//   onBack(), onFinish(workoutName, workoutDate, durationMs), onAddExercises()
//   onHeaderTap(exerciseId), onCustomHeaderTap(exerciseId), onReplaceExercise(exerciseId),
//   onSupersetTap(exerciseId), onViewHistory(exerciseId),
//   onReorder(), onRemoveExercise(exerciseId)
//   onResultTap(exerciseId, exerciseName, setNumber, video, setLogId)
//   onStartRest(exerciseId, exerciseName, setNumber, restMs), onDontShowAgain()
// =============================================================================

const Set<String> _kRtl = {'he', 'ar'};

String _langOf(BuildContext ctx) {
  try {
    final l = FFLocalizations.of(ctx).languageCode.trim().toLowerCase();
    return l.isEmpty ? 'en' : l;
  } catch (_) {
    return 'en';
  }
}

const Map<String, Map<String, String>> _kStrings = {
  "finish": {
    "en": "Finish",
    "es": "Terminar",
    "he": "סיום",
    "de": "Fertig",
    "fr": "Terminer"
  },
  "addExercises": {
    "en": "Add Exercises",
    "es": "Añadir ejercicios",
    "he": "הוסף תרגילים",
    "de": "Übungen hinzufügen",
    "fr": "Ajouter des exercices"
  },
  "empty": {
    "en": "No exercises yet",
    "es": "Aún no hay ejercicios",
    "he": "עדיין אין תרגילים",
    "de": "Noch keine Übungen",
    "fr": "Pas encore d’exercices"
  },
  "sets": {
    "en": "Sets",
    "es": "Series",
    "he": "סטים",
    "de": "Sätze",
    "fr": "Séries"
  },
  "volume": {
    "en": "Volume",
    "es": "Volumen",
    "he": "נפח",
    "de": "Volumen",
    "fr": "Volume"
  },
  "exercises": {
    "en": "Exercises",
    "es": "Ejercicios",
    "he": "תרגילים",
    "de": "Übungen",
    "fr": "Exercices"
  },
  "kg": {"en": "kg", "es": "kg", "he": "ק״ג", "de": "kg", "fr": "kg"},
  "lbs": {"en": "lbs", "es": "lb", "he": "ליב׳", "de": "lbs", "fr": "lb"},
  // Play mode
  "set": {"en": "Set", "es": "Serie", "he": "סט", "de": "Satz", "fr": "Série"},
  "warmup": {
    "en": "Warm-up",
    "es": "Calentamiento",
    "he": "חימום",
    "de": "Aufwärmen",
    "fr": "Échauffement"
  },
  "reps": {
    "en": "Reps",
    "es": "Reps",
    "he": "חזרות",
    "de": "Wdh.",
    "fr": "Reps"
  },
  "weight": {
    "en": "Weight",
    "es": "Peso",
    "he": "משקל",
    "de": "Gewicht",
    "fr": "Poids"
  },
  "previous": {
    "en": "Previous",
    "es": "Anterior",
    "he": "קודם",
    "de": "Vorher",
    "fr": "Précédent"
  },
  "completeSet": {
    "en": "Complete set",
    "es": "Completar serie",
    "he": "סיים סט",
    "de": "Satz abschließen",
    "fr": "Valider la série"
  },
  "upNext": {
    "en": "UP NEXT",
    "es": "A CONTINUACIÓN",
    "he": "הבא בתור",
    "de": "ALS NÄCHSTES",
    "fr": "ENSUITE"
  },
  "next": {
    "en": "Next",
    "es": "Siguiente",
    "he": "הבא",
    "de": "Nächster",
    "fr": "Suivant"
  },
  "rest": {
    "en": "Rest",
    "es": "Descanso",
    "he": "מנוחה",
    "de": "Pause",
    "fr": "Repos"
  },
  "skipRest": {
    "en": "Skip rest",
    "es": "Saltar descanso",
    "he": "דלג על המנוחה",
    "de": "Pause überspringen",
    "fr": "Passer le repos"
  },
  "of": {"en": "of", "es": "de", "he": "מתוך", "de": "von", "fr": "sur"},
  "allDone": {
    "en": "Nothing left to do",
    "es": "No queda nada",
    "he": "אין סטים שנותרו",
    "de": "Nichts mehr offen",
    "fr": "Plus rien à faire"
  },
  "needReps": {
    "en": "Enter the reps first",
    "es": "Introduce las repeticiones",
    "he": "קודם הזן חזרות",
    "de": "Zuerst Wiederholungen eingeben",
    "fr": "Saisis d’abord les reps"
  },
  "needTime": {
    "en": "Start the timer first",
    "es": "Inicia el cronómetro",
    "he": "קודם הפעל את הטיימר",
    "de": "Starte zuerst den Timer",
    "fr": "Lance d’abord le chrono"
  },
  "tapToStart": {
    "en": "Tap to start",
    "es": "Toca para iniciar",
    "he": "לחץ להתחלה",
    "de": "Zum Starten tippen",
    "fr": "Toucher pour démarrer"
  },
  "tapToPause": {
    "en": "Tap to pause",
    "es": "Toca para pausar",
    "he": "לחץ לעצירה",
    "de": "Zum Pausieren tippen",
    "fr": "Toucher pour mettre en pause"
  },
  // Log edit
  "editWorkout": {
    "en": "Edit Workout",
    "es": "Editar entreno",
    "he": "עריכת אימון",
    "de": "Workout bearbeiten",
    "fr": "Modifier la séance"
  },
  "save": {
    "en": "Save",
    "es": "Guardar",
    "he": "שמור",
    "de": "Speichern",
    "fr": "Enregistrer"
  },
  "workoutDetails": {
    "en": "Workout Details",
    "es": "Detalles del entreno",
    "he": "פרטי האימון",
    "de": "Workout-Details",
    "fr": "Détails de la séance"
  },
  "workoutDate": {
    "en": "Workout Date",
    "es": "Fecha",
    "he": "תאריך האימון",
    "de": "Datum",
    "fr": "Date"
  },
  "duration": {
    "en": "Duration",
    "es": "Duración",
    "he": "משך",
    "de": "Dauer",
    "fr": "Durée"
  },
  "setDate": {
    "en": "Set Date",
    "es": "Elegir fecha",
    "he": "בחר תאריך",
    "de": "Datum wählen",
    "fr": "Choisir la date"
  },
  "setDuration": {
    "en": "Set Duration",
    "es": "Elegir duración",
    "he": "בחר משך",
    "de": "Dauer wählen",
    "fr": "Choisir la durée"
  },
  "create": {
    "en": "Create",
    "es": "Crear",
    "he": "צור",
    "de": "Erstellen",
    "fr": "Créer"
  },
  "createWorkout": {
    "en": "Create Workout",
    "es": "Crear entreno",
    "he": "יצירת אימון",
    "de": "Workout erstellen",
    "fr": "Créer la séance"
  },
  "workoutNameHint": {
    "en": "Workout name",
    "es": "Nombre del entreno",
    "he": "שם האימון",
    "de": "Workout-Name",
    "fr": "Nom de la séance"
  },
  "setBtn": {
    "en": "Set",
    "es": "Aceptar",
    "he": "אישור",
    "de": "Übernehmen",
    "fr": "Valider"
  },
};

String _tr(String lang, String key) {
  final m = _kStrings[key];
  return m == null ? key : (m[lang] ?? m['en'] ?? key);
}

int _asInt(dynamic v, [int d = 0]) {
  if (v == null) return d;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim()) ?? d;
}

double _asDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().trim()) ?? 0;
}

int? _asIntN(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim());
}

double? _asDoubleN(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().trim());
}

bool _truthy(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().trim().toLowerCase();
  return s == 'true' || s == '1';
}

/// 62.5 → "62.5"; 60.0 → "60".
String _fmtNum(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  String s = v.toStringAsFixed(2);
  while (s.endsWith('0')) s = s.substring(0, s.length - 1);
  if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  return s;
}

String _mmss(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

String _mmssMs(int ms) => _mmss(ms ~/ 1000);

/// 4320.5 → "4,320"; 12 → "12".
String _fmtVolume(double v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// Live numbers for the stats strip.
class _Stats {
  const _Stats(this.doneSets, this.totalSets, this.volume, this.doneExercises,
      this.totalExercises);
  final int doneSets, totalSets, doneExercises, totalExercises;
  final double volume;
}

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({
    super.key,
    this.width,
    this.height,
    this.mode = 'live',
    this.title,
    this.saveLabel,
    this.workoutName,
    this.workoutDate,
    this.durationMs,
    this.showCameraGuidance,
    this.onBack,
    this.onFinish,
    this.onAddExercises,
    this.onHeaderTap,
    this.onCustomHeaderTap,
    this.onReplaceExercise,
    this.onSupersetTap,
    this.onViewHistory,
    this.onCustomViewHistory,
    this.onReorder,
    this.onRemoveExercise,
    this.onResultTap,
    this.onLockTap,
    this.onStartRest,
    this.onDontShowAgain,
  });

  final double? width;
  final double? height;

  /// Which screen this is. One of:
  ///
  ///   'live'     — the running workout: clock, rest timers, Play mode,
  ///                analysis, warm-ups. Reads the live App State lists.
  ///   'logEdit'  — editing a logged workout: no clock, no rest timer, no
  ///                superset, no warm-up, no analysis, a short options menu,
  ///                and a Workout Details card (date + duration).
  ///   'template' — creating a workout or editing a workout template: the
  ///                table holds target reps / a target duration, nothing is
  ///                completed, no weight column, no analysis, and the header
  ///                is a workout-name field. The rest time is still set per
  ///                exercise, because it is saved with the template.
  ///
  /// Anything other than 'live' runs on the *Creation App State lists.
  final String mode;

  /// Overrides the title in the top bar ("Create Workout", "Edit Template"…).
  final String? title;

  /// Overrides the label of the top-right button ("Create", "Save"…).
  /// Default: "Save" when editing a logged workout, "Create" in template mode.
  final String? saveLabel;

  /// Template mode: the workout's name, pre-filled when editing.
  final String? workoutName;

  /// Log-edit only: the workout's date and its length in minutes. Bind them
  /// to whatever holds them (App State / page state); the widget reports a
  /// change back through onFinish.
  ///
  /// The date is a String because that is how it is stored: anything
  /// DateTime.parse understands (an ISO-8601 timestamp such as
  /// "2026-11-11T00:00:00.000" or just "2026-11-11"). Unparsable or empty
  /// falls back to today, and the value reported back is ISO-8601.
  final String? workoutDate;

  /// Log-edit only: the workout's length, in the same unit the save action
  /// stores it in (milliseconds).
  final int? durationMs;

  final bool? showCameraGuidance;

  final Future Function()? onBack;

  /// The top-right button: Finish / Save / Create, depending on the mode.
  /// Carries everything the header holds, so nothing has to be stored on the
  /// way: the name typed in template mode (empty elsewhere), and the date
  /// (ISO-8601) and length (ms) from the Workout Details card in logEdit -
  /// the values on screen at that moment, changed or not. Outside logEdit the
  /// date is an empty string and the duration is 0.
  final Future Function(String workoutName, String workoutDate, int durationMs)?
      onFinish;
  final Future Function()? onAddExercises;

  final Future Function(int exerciseId)? onHeaderTap;
  final Future Function(int exerciseId)? onCustomHeaderTap;
  final Future Function(int exerciseId)? onReplaceExercise;
  final Future Function(int exerciseId)? onSupersetTap;
  final Future Function(int exerciseId)? onViewHistory;
  final Future Function(int exerciseId)? onCustomViewHistory;
  final Future Function()? onReorder;
  final Future Function(int exerciseId)? onRemoveExercise;

  /// [setLogId] is the set_log row the saved analysis hangs off ('' when
  /// there is none).
  final Future Function(int exerciseId, String exerciseName, int setNumber,
      FFUploadedFile? video, String setLogId)? onResultTap;
  final Future Function()? onLockTap;
  final Future Function(
          int exerciseId, String exerciseName, int setNumber, int restMs)?
      onStartRest;
  final Future Function()? onDontShowAgain;

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final ScrollController _scroll = ScrollController();
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.workoutName ?? '');

  @override
  void didUpdateWidget(covariant WorkoutPage old) {
    super.didUpdateWidget(old);
    // the page may fill the name in after the first build
    final String incoming = widget.workoutName ?? '';
    if (old.workoutName != widget.workoutName && incoming != _nameCtrl.text) {
      _nameCtrl.text = incoming;
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  String get _mode => widget.mode.trim().toLowerCase();

  /// Editing a logged workout — runs on the *Creation lists.
  bool get _edit => _mode == 'logedit';

  /// Creating a workout / editing a template — also on the *Creation lists.
  bool get _tpl => _mode == 'template';
  bool get _live => !_edit && !_tpl;

  List<dynamic> get _exerciseSets => List<dynamic>.from(
      _live ? FFAppState().exercisesets : FFAppState().exerciseSetsCreation);
  List<dynamic> get _loggedSets => List<dynamic>.from(
      _live ? FFAppState().loggedSets : FFAppState().loggedSetsCreation);

  /// Exercise ids in template order.
  List<int> get _ids {
    final out = <int>[];
    for (final e in _exerciseSets) {
      if (e is Map) {
        final id = _asInt(e['exerciseId'], -1);
        if (id >= 0 && !out.contains(id)) out.add(id);
      }
    }
    return out;
  }

  double get _progress {
    try {
      return workoutProgress(_exerciseSets, _loggedSets)
          .clamp(0.0, 1.0)
          .toDouble();
    } catch (_) {
      return 0.0;
    }
  }

  /// Open/closed state of the stats strip; static so it survives rebuilds
  /// and re-entering the page during one app run.
  static bool _statsOpen = false;

  _Stats _stats(List<int> ids) {
    final ex = _exerciseSets;
    final logged = _loggedSets;
    int total = 0;
    for (final e in ex) {
      if (e is Map && e['sets'] is List) total += (e['sets'] as List).length;
    }
    // done base sets, keyed "exerciseId:setNumber"
    final Set<String> doneKeys = {};
    int done = 0;
    double volume = 0;
    for (final l in logged) {
      if (l is! Map || _truthy(l['isDropSet'])) continue;
      if (!_truthy(l['isDone'])) continue;
      final id = _asInt(l['exerciseId'], -1);
      if (!ids.contains(id)) continue;
      done++;
      doneKeys.add('$id:${_asInt(l['setNumber'])}');
      volume += _asInt(l['reps']) * _asDouble(l['weight']);
    }
    for (final l in logged) {
      if (l is! Map || !_truthy(l['isDropSet'])) continue;
      final id = _asInt(l['exerciseId'], -1);
      if (!doneKeys.contains('$id:${_asInt(l['setNumber'])}')) continue;
      volume += _asInt(l['reps']) * _asDouble(l['weight']);
    }
    int doneEx = 0;
    for (final c in (_live
        ? FFAppState().completedExercises
        : FFAppState().completedExercisesCreation)) {
      if (c is Map &&
          _truthy(c['isComplete']) &&
          ids.contains(_asInt(c['exerciseId'], -1))) doneEx++;
    }
    return _Stats(done, total, volume, doneEx, ids.length);
  }

  /// Full-screen set-by-set mode; writes to the same App State as the list.
  Future<void> _openPlayMode() async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PlayMode(live: _live),
      ),
    );
    if (mounted) setState(() {});
  }

  // ---------- log-edit: date + duration ----------

  DateTime? _date;
  int? _minutes;

  DateTime get _dateValue {
    final d = _date;
    if (d != null) return d;
    final raw = (widget.workoutDate ?? '').trim();
    if (raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  int get _minutesValue => _minutes ?? ((widget.durationMs ?? 0) ~/ 60000);

  /// "Wed, Nov 11" in the app's language.
  String _dateLabel(String lang) {
    final d = _dateValue;
    try {
      final s = dateTimeFormat('EEE, MMM d', d, locale: lang);
      if (s.trim().isNotEmpty) return s;
    } catch (_) {}
    try {
      final s = dateTimeFormat('EEE, MMM d', d);
      if (s.trim().isNotEmpty) return s;
    } catch (_) {}
    return '${d.day}/${d.month}/${d.year}';
  }

  String get _durationLabel {
    final m = _minutesValue;
    return '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate(String lang) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DateSheet(initial: _dateValue, lang: lang),
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  Future<void> _pickDuration(String lang) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DurationSheet(initialMinutes: _minutesValue, lang: lang),
    );
    if (picked == null) return;
    setState(() => _minutes = picked);
  }

  static TextStyle _ts(
          FlutterFlowTheme th, double size, FontWeight w, Color c) =>
      th.bodyMedium.override(
        fontFamily: th.bodyMediumFamily,
        color: c,
        fontSize: size,
        fontWeight: w,
        useGoogleFonts: GoogleFonts.asMap().containsKey(th.bodyMediumFamily),
      );

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final theme = FlutterFlowTheme.of(context);
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final ids = _ids;
    final double progress = _progress;
    final bool canFinish = progress > 0;
    final Color border =
        dark ? const Color(0xFF2A3644) : const Color(0xFFE3E7EB);
    final DateTime startedAt =
        FFAppState().activeWorkoutStartTime ?? DateTime.now();
    final double topInset = MediaQuery.of(context).padding.top;
    // Room under the last card. The page above may already have eaten the
    // safe area, so a floor keeps "Add Exercises" off the screen edge, and
    // the keyboard inset gives the focused field somewhere to scroll to.
    final MediaQueryData mq = MediaQuery.of(context);
    final double safeBottom = mq.padding.bottom > 0 ? mq.padding.bottom : 12;
    final double keyboard = mq.viewInsets.bottom;
    final double bottomInset = safeBottom + keyboard;

    final Widget topBar = Container(
      color: theme.secondaryBackground,
      padding: EdgeInsets.fromLTRB(8, topInset + 6, 12, 10),
      // The clock sits dead centre of the screen; back and Finish float over
      // it, so an unequal left/right width never shifts it.
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 112),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: (_edit || _tpl)
                  ? Text(
                      (widget.title ?? '').trim().isNotEmpty
                          ? widget.title!.trim()
                          : _tr(lang, _edit ? 'editWorkout' : 'createWorkout'),
                      style: _ts(theme, 22, FontWeight.w700, theme.primaryText))
                  : (_live
                      ? WorkoutClock(
                          startedAt: startedAt,
                          fontSize: 24,
                          color: theme.primaryText)
                      : const SizedBox.shrink()),
            ),
          ),
          Row(
            children: [
              _Tap(
                onTap: () => widget.onBack?.call(),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                      rtl
                          ? Icons.chevron_right_rounded
                          : Icons.chevron_left_rounded,
                      size: 32,
                      color: theme.primaryText),
                ),
              ),
              const Spacer(),
              if (_live && ids.isNotEmpty) ...[
                _Tap(
                  onTap: _openPlayMode,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: border, width: 1.5),
                    ),
                    child: Icon(Icons.play_arrow_rounded,
                        size: 24, color: theme.primary),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              _Tap(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  widget.onFinish?.call(
                    _tpl ? _nameCtrl.text.trim() : '',
                    _edit ? _dateValue.toIso8601String() : '',
                    _edit ? _minutesValue * 60000 : 0,
                  );
                },
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (_edit || _tpl || canFinish)
                        ? theme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: (_edit || _tpl || canFinish)
                        ? null
                        : Border.all(color: border, width: 1.5),
                  ),
                  child: Text(
                      (widget.saveLabel ?? '').trim().isNotEmpty
                          ? widget.saveLabel!.trim()
                          : _tr(lang,
                              _edit ? 'save' : (_tpl ? 'create' : 'finish')),
                      style: _ts(
                          theme,
                          17,
                          FontWeight.w700,
                          (_edit || _tpl || canFinish)
                              ? Colors.white
                              : theme.secondaryText)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final Widget progressLine = SizedBox(
      height: 4,
      child: Stack(
        children: [
          Container(color: border),
          FractionallySizedBox(
            widthFactor: progress,
            alignment: rtl ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(color: theme.primary),
          ),
        ],
      ),
    );

    // Log-edit: the Workout Details card, in place of the running clock.
    Widget detailField(
            IconData icon, String label, String value, VoidCallback onTap) =>
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: theme.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _ts(
                            theme, 15, FontWeight.w400, theme.secondaryText)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _Tap(
                onTap: onTap,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.primaryBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _ts(
                                theme, 16, FontWeight.w400, theme.primaryText)),
                      ),
                      Icon(Icons.expand_more_rounded,
                          size: 20, color: theme.secondaryText),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

    final Widget detailsCard = Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(_tr(lang, 'workoutDetails'),
              style: _ts(theme, 22, FontWeight.w700, theme.primaryText)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              detailField(
                  Icons.calendar_today_rounded,
                  _tr(lang, 'workoutDate'),
                  _dateLabel(lang),
                  () => _pickDate(lang)),
              const SizedBox(width: 14),
              detailField(Icons.schedule_rounded, _tr(lang, 'duration'),
                  _durationLabel, () => _pickDuration(lang)),
            ],
          ),
        ],
      ),
    );

    // Template mode: the workout name, in place of the clock / details.
    final Widget nameCard = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: _nameCtrl,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() {}),
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        style: _ts(theme, 19, FontWeight.w400, theme.primaryText),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 22),
          hintText: _tr(lang, 'workoutNameHint'),
          hintStyle: _ts(theme, 19, FontWeight.w400, theme.secondaryText),
        ),
      ),
    );

    // Live stats strip, hanging off the app bar. Collapsed: only a chevron
    // handle. Expanded: Sets · Volume · Exercises, chevron flips.
    final _Stats st = _stats(ids);
    final String unit = _tr(lang, FFAppState().isKg ? 'kg' : 'lbs');
    final bool open = _statsOpen;

    Widget stat(String value, String label, {Color? valueColor}) => Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  textDirection: ui.TextDirection.ltr,
                  maxLines: 1,
                  style: _ts(theme, 18, FontWeight.w800,
                      valueColor ?? theme.primaryText)),
              const SizedBox(height: 2),
              Text(label,
                  maxLines: 1,
                  style: _ts(theme, 11, FontWeight.w500, theme.secondaryText)),
            ],
          ),
        );
    Widget vline() => Container(width: 1, height: 28, color: border);

    final Widget statsStrip = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _statsOpen = !_statsOpen);
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(dark ? 0.25 : 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (open)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      stat('${st.doneSets}/${st.totalSets}', _tr(lang, 'sets'),
                          valueColor: theme.primary),
                      vline(),
                      stat('${_fmtVolume(st.volume)} $unit',
                          _tr(lang, 'volume')),
                      vline(),
                      stat('${st.doneExercises}/${st.totalExercises}',
                          _tr(lang, 'exercises')),
                    ],
                  ),
                ),
              SizedBox(
                height: 22,
                child: Center(
                  child: Icon(
                      open
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 22,
                      color: theme.secondaryText),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final Widget addButton = _Tap(
      onTap: () => widget.onAddExercises?.call(),
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: theme.primary, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 24, color: Colors.white),
            const SizedBox(width: 8),
            Text(_tr(lang, 'addExercises'),
                style: _ts(theme, 18, FontWeight.w700, Colors.white)),
          ],
        ),
      ),
    );

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Container(
        width: widget.width,
        height: widget.height,
        color: theme.primaryBackground,
        child: Column(
          children: [
            topBar,
            if (!_edit && !_tpl) progressLine,
            if (!_edit && !_tpl && ids.isNotEmpty) statsStrip,
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: EdgeInsets.fromLTRB(
                    16, (_edit || _tpl) ? 16 : 12, 16, 28 + bottomInset),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                // cards are tall and their height depends on their content:
                // keeping a screenful alive on either side stops the list
                // from re-measuring (and shifting) when you scroll back
                cacheExtent: 1400,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: ids.length + ((_edit || _tpl) ? 2 : 1),
                itemBuilder: (ctx, raw) {
                  if ((_edit || _tpl) && raw == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _edit ? detailsCard : nameCard,
                    );
                  }
                  final int i = (_edit || _tpl) ? raw - 1 : raw;
                  if (i == ids.length) {
                    return Padding(
                      padding: EdgeInsets.only(top: ids.isEmpty ? 40 : 8),
                      child: Column(
                        children: [
                          if (ids.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(_tr(lang, 'empty'),
                                  style: _ts(theme, 16, FontWeight.w500,
                                      theme.secondaryText)),
                            ),
                          addButton,
                        ],
                      ),
                    );
                  }
                  final int id = ids[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ExerciseCard(
                      key: ValueKey('exercise_$id'),
                      exerciseId: id,
                      isLiveWorkout: _live,
                      isLogEdit: _edit,
                      isTemplate: _tpl,
                      exerciseCount: ids.length,
                      showCameraGuidance: widget.showCameraGuidance,
                      onHeaderTap: () async => widget.onHeaderTap?.call(id),
                      onCustomHeaderTap: () async =>
                          widget.onCustomHeaderTap?.call(id),
                      onReplaceExercise: () async =>
                          widget.onReplaceExercise?.call(id),
                      onSupersetTap: () async => widget.onSupersetTap?.call(id),
                      onViewHistory: () async => widget.onViewHistory?.call(id),
                      onCustomViewHistory: () async =>
                          widget.onCustomViewHistory?.call(id),
                      onReorder: () async => widget.onReorder?.call(),
                      onRemoveExercise: () async =>
                          widget.onRemoveExercise?.call(id),
                      onResultTap: (name, setNumber, video, setLogId) async =>
                          widget.onResultTap
                              ?.call(id, name, setNumber, video, setLogId),
                      onLockTap: () async => widget.onLockTap?.call(),
                      onStartRest: widget.onStartRest,
                      onDontShowAgain: widget.onDontShowAgain,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tap extends StatefulWidget {
  const _Tap({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;
  @override
  State<_Tap> createState() => _TapState();
}

class _TapState extends State<_Tap> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: _down ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: widget.child,
        ),
      ),
    );
  }
}
// =============================================================================
// Play mode — the workout one set at a time, full screen.
//
// Walks every undone set of every unfinished exercise (warm-ups first, then
// the working sets, exercise by exercise), writes to the same App State the
// list view uses, and runs the rest between sets on a full green screen.
// Opened from the ▶ button in the top bar; the chevron closes it.
// =============================================================================

/// One stop in the queue: a warm-up set or a working set.
class _Stop {
  const _Stop(this.exerciseId, this.setNumber, this.warm);
  final int exerciseId;
  final int setNumber;
  final bool warm;
  String get key => '$exerciseId:$setNumber:${warm ? 'w' : 's'}';
}

/// The exercise2 row fields Play mode needs.
class _ExInfo {
  const _ExInfo(this.nameRaw, this.illustration, this.isTimed,
      this.isBodyweight, this.allowsBodyweight);
  final String nameRaw;
  final String? illustration;
  final bool isTimed, isBodyweight, allowsBodyweight;
}

class _PlayMode extends StatefulWidget {
  const _PlayMode({required this.live});
  final bool live;
  @override
  State<_PlayMode> createState() => _PlayModeState();
}

class _PlayModeState extends State<_PlayMode> {
  static const Color _restBg = Color(0xFF0F766E);

  final TextEditingController _repsCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final Map<int, _ExInfo> _info = {};
  final Set<int> _infoLoading = {};
  final Map<String, String> _prev = {};
  final Set<String> _prevLoading = {};

  int _i = 0;
  String _syncedKey = '';

  // rest
  DateTime? _restEnd;
  int _restTotalSec = 0;
  Timer? _ticker;

  // timed sets
  int _elapsedMs = 0;
  DateTime? _runStart;
  Timer? _timedTicker;

  @override
  void initState() {
    super.initState();
    final q = _queue;
    _i = q.indexWhere((s) => !_stopDone(s));
    if (_i < 0) _i = q.isEmpty ? 0 : q.length - 1;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _timedTicker?.cancel();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  // ---------- App State ----------

  bool get _live => widget.live;

  List<dynamic> get _exerciseSets => List<dynamic>.from(
      _live ? FFAppState().exercisesets : FFAppState().exerciseSetsCreation);
  List<dynamic> get _loggedSets => List<dynamic>.from(
      _live ? FFAppState().loggedSets : FFAppState().loggedSetsCreation);
  List<dynamic> get _dropSets => List<dynamic>.from(
      _live ? FFAppState().dropSets : FFAppState().dropSetsCreation);
  List<dynamic> get _warmupSets => List<dynamic>.from(
      _live ? FFAppState().warmupSets : FFAppState().warmUpCreation);
  dynamic get _restTimers =>
      _live ? FFAppState().restTimers : FFAppState().restTimerCreation;

  Future<void> _write(void Function(FFAppState s) f) async {
    FFAppState().update(() => f(FFAppState()));
    if (mounted) setState(() {});
  }

  Future<void> _setLogged(List<dynamic> v) async => _write((s) {
        if (_live) {
          s.loggedSets = v;
        } else {
          s.loggedSetsCreation = v;
        }
      });

  Future<void> _setWarmup(List<dynamic> v) async => _write((s) {
        if (_live) {
          s.warmupSets = v;
        } else {
          s.warmUpCreation = v;
        }
      });

  bool _exerciseComplete(int id) {
    for (final c in (_live
        ? FFAppState().completedExercises
        : FFAppState().completedExercisesCreation)) {
      if (c is Map &&
          _asInt(c['exerciseId'], -1) == id &&
          _truthy(c['isComplete'])) return true;
    }
    return false;
  }

  // ---------- queue ----------

  List<_Stop> get _queue {
    final out = <_Stop>[];
    for (final e in _exerciseSets) {
      if (e is! Map) continue;
      final int id = _asInt(e['exerciseId'], -1);
      if (id < 0 || _exerciseComplete(id)) continue;

      for (final w in _warmSetsOf(id)) {
        out.add(_Stop(id, _asInt(w['setNumber']), true));
      }
      final sets = e['sets'];
      if (sets is List) {
        final planned = sets.whereType<Map>().toList()
          ..sort((a, b) =>
              _asInt(a['setNumber']).compareTo(_asInt(b['setNumber'])));
        for (final s in planned) {
          out.add(_Stop(id, _asInt(s['setNumber']), false));
        }
      }
    }
    return out;
  }

  Map? _warmEntryOf(int id) {
    for (final e in _warmupSets) {
      if (e is Map && _asInt(e['exerciseId']) == id) return e;
    }
    return null;
  }

  List<Map> _warmSetsOf(int id) {
    final e = _warmEntryOf(id);
    if (e == null || _truthy(e['hidden']) || _truthy(e['completed']))
      return const [];
    final sets = e['sets'];
    if (sets is! List) return const [];
    return sets.whereType<Map>().toList()
      ..sort(
          (a, b) => _asInt(a['setNumber']).compareTo(_asInt(b['setNumber'])));
  }

  Map? _warmSet(_Stop s) {
    for (final w in _warmSetsOf(s.exerciseId)) {
      if (_asInt(w['setNumber']) == s.setNumber) return w;
    }
    return null;
  }

  /// The planned (template) set behind a working stop.
  Map? _tplSet(_Stop s) {
    for (final e in _exerciseSets) {
      if (e is! Map || _asInt(e['exerciseId']) != s.exerciseId) continue;
      final sets = e['sets'];
      if (sets is! List) return null;
      for (final x in sets) {
        if (x is Map && _asInt(x['setNumber']) == s.setNumber) return x;
      }
      return null;
    }
    return null;
  }

  /// The logged (non-drop) row behind a working stop.
  Map? _logged(_Stop s) {
    for (final l in _loggedSets) {
      if (l is Map &&
          _asInt(l['exerciseId']) == s.exerciseId &&
          _asInt(l['setNumber']) == s.setNumber &&
          !_truthy(l['isDropSet'])) return l;
    }
    return null;
  }

  bool _stopDone(_Stop s) =>
      s.warm ? _truthy(_warmSet(s)?['isDone']) : _truthy(_logged(s)?['isDone']);

  int _setsOfExercise(int id) {
    for (final e in _exerciseSets) {
      if (e is Map && _asInt(e['exerciseId']) == id && e['sets'] is List) {
        return (e['sets'] as List).length;
      }
    }
    return 0;
  }

  /// Progress over every stop in the queue plus the ones already behind us.
  double get _progress {
    final q = _queue;
    if (q.isEmpty) return 0;
    int done = 0;
    for (final s in q) {
      if (_stopDone(s)) done++;
    }
    return (done / q.length).clamp(0.0, 1.0).toDouble();
  }

  // ---------- exercise row + previous ----------

  _ExInfo? _infoOf(int id) {
    final cached = _info[id];
    if (cached != null) return cached;
    if (!_infoLoading.contains(id)) {
      _infoLoading.add(id);
      () async {
        try {
          final rows = await SQLiteManager.instance.exercise2(exerciseId: id);
          if (rows.isEmpty) return;
          final dynamic r = rows.first;
          dynamic g(String k) {
            try {
              return (r as dynamic).data[k];
            } catch (_) {
              return null;
            }
          }

          final ill = (g('illustration') ?? '').toString().trim();
          final info = _ExInfo(
            (g('name') ?? '').toString(),
            ill.isEmpty ? null : ill,
            _truthy(g('is_time_based')),
            _truthy(g('is_bodyweight_dominant') ?? g('is_bodyweight')),
            _truthy(g('allows_bodyweight')),
          );
          if (mounted) setState(() => _info[id] = info);
        } catch (_) {
        } finally {
          _infoLoading.remove(id);
        }
      }();
    }
    return null;
  }

  String _prevOf(_Stop s, bool isKg) {
    final k = '${s.exerciseId}:${s.setNumber}';
    final cached = _prev[k];
    if (cached != null) return cached;
    if (!_prevLoading.contains(k)) {
      _prevLoading.add(k);
      () async {
        String text = '-';
        try {
          final rows = await SQLiteManager.instance.correctedPreviosSet(
            exerciseId: s.exerciseId,
            setNumber: s.setNumber,
            userId: currentUserUid,
          );
          dynamic row = rows.isNotEmpty ? rows.first : null;
          dynamic g(String key) {
            if (row == null) return null;
            try {
              return (row as dynamic).data[key];
            } catch (_) {
              try {
                return (row as Map)[key];
              } catch (_) {
                return null;
              }
            }
          }

          text = correctedFormatPreviousSet(_asIntN(g('reps')),
              _asDoubleN(g('weight')), _asIntN(g('duration_seconds')), isKg);
        } catch (_) {
          text = '-';
        }
        if (mounted) setState(() => _prev[k] = text);
        _prevLoading.remove(k);
      }();
    }
    return '';
  }

  // ---------- field sync ----------

  bool _canWeight(_Stop s, _ExInfo? info) {
    if (s.warm) return true;
    final t = _tplSet(s);
    final bool weighted = _truthy(t?['weighted'] ?? 1);
    return weighted ||
        (info?.isBodyweight ?? false) ||
        (info?.allowsBodyweight ?? false);
  }

  /// Last value typed in an earlier set of the same exercise, as the hint.
  int _repsHint(_Stop s) {
    int? best;
    int bestSn = -1;
    for (final l in _loggedSets) {
      if (l is! Map ||
          _asInt(l['exerciseId']) != s.exerciseId ||
          _truthy(l['isDropSet'])) continue;
      final sn = _asInt(l['setNumber']);
      final r = _asIntN(l['reps']);
      if (sn < s.setNumber && r != null && r > 0 && sn > bestSn) {
        best = r;
        bestSn = sn;
      }
    }
    if (best != null) return best;
    final t = _tplSet(s);
    final target = _asInt(t?['targetReps']);
    return target > 0 ? target : 0;
  }

  double _weightHint(_Stop s) {
    double? best;
    int bestSn = -1;
    for (final l in _loggedSets) {
      if (l is! Map ||
          _asInt(l['exerciseId']) != s.exerciseId ||
          _truthy(l['isDropSet'])) continue;
      final sn = _asInt(l['setNumber']);
      final w = _asDoubleN(l['weight']);
      if (sn < s.setNumber && w != null && w > 0 && sn > bestSn) {
        best = w;
        bestSn = sn;
      }
    }
    return best ?? 0;
  }

  /// Fills the two fields when the current stop changes.
  void _syncFields(_Stop s) {
    if (_syncedKey == s.key) return;
    _syncedKey = s.key;
    _elapsedMs = s.warm ? 0 : _asInt(_logged(s)?['durationMs']);
    _runStart = null;
    _timedTicker?.cancel();
    _timedTicker = null;

    int reps;
    double weight;
    if (s.warm) {
      final w = _warmSet(s);
      reps = _asInt(w?['reps']);
      weight = _asDoubleN(w?['weight']) ?? 0;
    } else {
      final l = _logged(s);
      reps = _asIntN(l?['reps']) ?? 0;
      weight = _asDoubleN(l?['weight']) ?? 0;
      if (reps <= 0) reps = _repsHint(s);
      if (weight <= 0) weight = _weightHint(s);
    }
    // after the frame: writing to a controller during build would rebuild the
    // TextField that is already on screen
    final String r = reps > 0 ? '$reps' : '';
    final String w = weight > 0 ? _fmtNum(weight) : '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_repsCtrl.text != r) _repsCtrl.text = r;
      if (_weightCtrl.text != w) _weightCtrl.text = w;
    });
  }

  // ---------- complete ----------

  int _restMsOf(int id) {
    final rt = _restTimers;
    if (rt is! Map) return 90000;
    final v = rt['$id'] ?? rt[id];
    return v == null ? 90000 : _asInt(v);
  }

  List<Map> _plannedDrops(_Stop s) {
    final out = <Map>[];
    for (final d in _dropSets) {
      if (d is Map &&
          _asInt(d['exerciseId']) == s.exerciseId &&
          _asInt(d['parentSetNumber']) == s.setNumber) out.add(d);
    }
    out.sort(
        (a, b) => _asInt(a['dropOrder']).compareTo(_asInt(b['dropOrder'])));
    return out;
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, textAlign: TextAlign.center),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  Future<void> _complete(_Stop s, String lang, bool timed) async {
    final int reps = int.tryParse(_repsCtrl.text.trim()) ?? 0;
    final double weight = double.tryParse(_weightCtrl.text.trim()) ?? 0;

    if (timed) {
      if (_totalElapsedMs <= 0) {
        HapticFeedback.heavyImpact();
        _toast(_tr(lang, 'needTime'));
        return;
      }
    } else if (reps <= 0) {
      HapticFeedback.heavyImpact();
      _toast(_tr(lang, 'needReps'));
      return;
    }

    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    _pauseTimed();

    int restSec = 0;

    if (s.warm) {
      final list = _warmupSets
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      for (final entry in list) {
        if (_asInt(entry['exerciseId']) != s.exerciseId ||
            entry['sets'] is! List) continue;
        final sets = (entry['sets'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        bool allDone = true;
        for (final w in sets) {
          if (_asInt(w['setNumber']) == s.setNumber) {
            w['isDone'] = true;
            w['reps'] = reps > 0 ? reps : w['reps'];
            if (weight > 0) w['weight'] = _fmtNum(weight);
            restSec = _asInt(w['restSec']);
          }
          if (!_truthy(w['isDone'])) allDone = false;
        }
        entry['sets'] = sets;
        if (allDone) {
          entry['hidden'] = true;
          entry['completed'] = true;
        }
      }
      await _setWarmup(List<dynamic>.from(list));
    } else {
      final list = _loggedSets
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final bool canW = _canWeight(s, _info[s.exerciseId]);
      final idx = list.indexWhere((l) =>
          _asInt(l['exerciseId']) == s.exerciseId &&
          _asInt(l['setNumber']) == s.setNumber &&
          !_truthy(l['isDropSet']));
      final old = idx >= 0 ? list[idx] : <String, dynamic>{};
      final Map<String, dynamic> next = {
        ...old,
        'exerciseId': s.exerciseId,
        'setNumber': s.setNumber,
        'isDone': true,
        'isSkipped': false,
        'weighted': _truthy(_tplSet(s)?['weighted'] ?? 1),
        'reps': timed ? old['reps'] : reps,
        'weight': canW && weight > 0
            ? weight
            : (canW ? _asDoubleN(old['weight']) : null),
        'durationMs': timed ? _totalElapsedMs : _asInt(old['durationMs']),
      };
      if (idx >= 0) {
        list[idx] = next;
      } else {
        list.add(next);
      }

      // planned drop sets ride along, exactly as the list view does
      for (final d in _plannedDrops(s)) {
        final order = _asInt(d['dropOrder']);
        final di = list.indexWhere((l) =>
            _asInt(l['exerciseId']) == s.exerciseId &&
            _asInt(l['setNumber']) == s.setNumber &&
            _truthy(l['isDropSet']) &&
            _asInt(l['dropOrder']) == order);
        final dOld = di >= 0 ? list[di] : <String, dynamic>{};
        final int? lr = _asIntN(dOld['reps']);
        final double? lw = _asDoubleN(dOld['weight']);
        if (di >= 0 && (lr ?? 0) > 0 && (lw ?? 0) > 0) continue;
        final Map<String, dynamic> dNext = {
          ...dOld,
          'exerciseId': s.exerciseId,
          'setNumber': s.setNumber,
          'isDropSet': 1,
          'dropLabel': 'Drop $order',
          'dropOrder': order,
          'reps': (lr ?? 0) > 0 ? lr : _asIntN(d['reps']),
          'weight': (lw ?? 0) > 0 ? lw : _asDoubleN(d['weight']),
          'durationMs': null,
          'isDone': false,
        };
        if (di >= 0) {
          list[di] = dNext;
        } else {
          list.add(dNext);
        }
      }
      await _setLogged(List<dynamic>.from(list));
      restSec = (_restMsOf(s.exerciseId) / 1000).round();
    }

    // Next stop: the first undone one after this one. The queue is rebuilt
    // from App State (a finished warm-up block disappears from it), so we
    // locate the current stop again instead of trusting the old index.
    final q = _queue;
    final int cur = q.indexWhere((x) => x.key == s.key);
    int next = -1;
    for (int k = (cur >= 0 ? cur + 1 : 0); k < q.length; k++) {
      if (!_stopDone(q[k])) {
        next = k;
        break;
      }
    }
    if (next < 0) {
      for (int k = 0; k < q.length; k++) {
        if (!_stopDone(q[k])) {
          next = k;
          break;
        }
      }
    }
    if (next < 0) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _i = next);
    if (restSec > 0) _startRest(restSec);
  }

  // ---------- rest ----------

  void _startRest(int sec) {
    _restTotalSec = sec;
    _restEnd = DateTime.now().add(Duration(seconds: sec));
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_restLeft <= 0) {
        HapticFeedback.mediumImpact();
        _stopRest();
      } else {
        setState(() {});
      }
    });
    setState(() {});
  }

  void _stopRest() {
    _ticker?.cancel();
    _ticker = null;
    if (mounted) {
      setState(() {
        _restEnd = null;
        _restTotalSec = 0;
      });
    }
  }

  void _bumpRest(int sec) {
    final end = _restEnd;
    if (end == null) return;
    HapticFeedback.selectionClick();
    final next = end.add(Duration(seconds: sec));
    if (next.isBefore(DateTime.now())) {
      _stopRest();
      return;
    }
    setState(() {
      _restEnd = next;
      _restTotalSec = (_restTotalSec + sec).clamp(1, 3600).toInt();
    });
  }

  int get _restLeft {
    final end = _restEnd;
    if (end == null) return 0;
    final l = end.difference(DateTime.now()).inSeconds;
    return l < 0 ? 0 : l;
  }

  // ---------- timed sets ----------

  int get _totalElapsedMs {
    final start = _runStart;
    if (start == null) return _elapsedMs;
    return _elapsedMs + DateTime.now().difference(start).inMilliseconds;
  }

  void _toggleTimed() {
    HapticFeedback.selectionClick();
    if (_runStart == null) {
      _runStart = DateTime.now();
      _timedTicker?.cancel();
      _timedTicker = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _pauseTimed();
    }
    setState(() {});
  }

  void _pauseTimed() {
    final start = _runStart;
    if (start != null)
      _elapsedMs += DateTime.now().difference(start).inMilliseconds;
    _runStart = null;
    _timedTicker?.cancel();
    _timedTicker = null;
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final theme = FlutterFlowTheme.of(context);
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final bool isKg = FFAppState().isKg;
    final Color border =
        dark ? const Color(0xFF2A3644) : const Color(0xFFE3E7EB);
    final Color field = theme.primaryBackground;

    final q = _queue;
    if (q.isEmpty) {
      return Scaffold(
        backgroundColor: theme.secondaryBackground,
        body: SafeArea(
          child: Column(
            children: [
              _closeRow(theme),
              Expanded(
                child: Center(
                  child: Text(_tr(lang, 'allDone'),
                      style: _WorkoutPageState._ts(
                          theme, 17, FontWeight.w600, theme.secondaryText)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_i >= q.length) _i = q.length - 1;
    final _Stop s = q[_i];
    _syncFields(s);

    final _ExInfo? info = _infoOf(s.exerciseId);
    final bool timed = (info?.isTimed ?? false) && !s.warm;
    final bool canW = _canWeight(s, info);
    final String name = (() {
      try {
        return localizedName(info?.nameRaw ?? '', lang);
      } catch (_) {
        return info?.nameRaw ?? '';
      }
    })();
    final int totalSets = s.warm
        ? _warmSetsOf(s.exerciseId).length
        : _setsOfExercise(s.exerciseId);
    final String prevText = _prevOf(s, isKg);
    final String unit = _tr(lang, isKg ? 'kg' : 'lbs');

    // the stop after this one, for "UP NEXT" and the rest screen
    _Stop? nextStop;
    for (int k = _i + 1; k < q.length; k++) {
      if (!_stopDone(q[k])) {
        nextStop = q[k];
        break;
      }
    }

    final Widget setView = Column(
      children: [
        _closeRow(theme),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            height: 4,
            child: Stack(
              children: [
                Container(
                    decoration: BoxDecoration(
                        color: border, borderRadius: BorderRadius.circular(2))),
                FractionallySizedBox(
                  widthFactor: _progress,
                  alignment: rtl ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                      decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(2))),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Column(
              children: [
                _illustrationTile(info?.illustration, theme, field),
                const SizedBox(height: 12),
                Text(name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _WorkoutPageState._ts(
                        theme, 24, FontWeight.w700, theme.primaryText)),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: s.warm ? const Color(0x33F59E0B) : field,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        s.warm
                            ? '${_tr(lang, 'warmup')} ${s.setNumber}/$totalSets'
                            : '${_tr(lang, 'set')} ${s.setNumber}/$totalSets',
                        style: _WorkoutPageState._ts(
                            theme,
                            13,
                            FontWeight.w600,
                            s.warm
                                ? const Color(0xFFB45309)
                                : theme.primaryText),
                      ),
                    ),
                    if (prevText.isNotEmpty && prevText != '-')
                      Text('${_tr(lang, 'previous')}: $prevText',
                          style: _WorkoutPageState._ts(
                              theme, 14, FontWeight.w400, theme.secondaryText)),
                  ],
                ),
                const SizedBox(height: 28),

                // the set itself
                if (timed)
                  _timedTile(theme, field, border, lang)
                else
                  Row(
                    textDirection: ui.TextDirection.ltr,
                    children: [
                      Expanded(
                          child: _numTile(theme, field, border, _repsCtrl,
                              _tr(lang, 'reps'), false)),
                      if (canW) const SizedBox(width: 14),
                      if (canW)
                        Expanded(
                            child: _numTile(theme, field, border, _weightCtrl,
                                '${_tr(lang, 'weight')} ($unit)', true)),
                    ],
                  ),
                const SizedBox(height: 22),

                _Tap(
                  onTap: () => _complete(s, lang, timed),
                  child: Container(
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: theme.primary,
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_rounded,
                            size: 24, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(_tr(lang, 'completeSet'),
                            style: _WorkoutPageState._ts(
                                theme, 19, FontWeight.w700, Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 26),

                if (nextStop != null) _upNext(nextStop, theme, field, lang),
                const SizedBox(height: 18),
                _dots(q, theme, border),
              ],
            ),
          ),
        ),
      ],
    );

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.secondaryBackground,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            SafeArea(child: setView),
            if (_restEnd != null) _restScreen(theme, lang, nextStop),
          ],
        ),
      ),
    );
  }

  // ---------- pieces ----------

  Widget _closeRow(FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
      child: Stack(
        alignment: Alignment.center,
        children: [
          WorkoutClock(
            startedAt: FFAppState().activeWorkoutStartTime ?? DateTime.now(),
            fontSize: 18,
            color: theme.secondaryText,
          ),
          Row(
            children: [
              _Tap(
                onTap: () => Navigator.of(context).pop(),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 30, color: theme.primaryText),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 44, height: 44),
            ],
          ),
        ],
      ),
    );
  }

  Widget _illustrationTile(String? ill, FlutterFlowTheme theme, Color field) {
    Widget fallback() => Icon(Icons.fitness_center_rounded,
        size: 38, color: theme.secondaryText);
    Widget image;
    final String src = (ill ?? '').trim();
    if (src.isEmpty) {
      image = fallback();
    } else if (src.startsWith('http')) {
      image = Image.network(src,
          fit: BoxFit.contain, errorBuilder: (_, __, ___) => fallback());
    } else {
      image = Image.asset(
        src,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/$src',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => fallback(),
        ),
      );
    }
    return Container(
      width: 84,
      height: 84,
      padding: const EdgeInsets.all(6),
      decoration:
          BoxDecoration(color: field, borderRadius: BorderRadius.circular(18)),
      child: Center(child: image),
    );
  }

  Widget _numTile(FlutterFlowTheme theme, Color field, Color border,
      TextEditingController ctrl, String label, bool decimal) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: field,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 56,
            child: TextField(
              controller: ctrl,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              keyboardType: TextInputType.numberWithOptions(decimal: decimal),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    decimal ? RegExp(r'^\d*\.?\d*$') : RegExp(r'^\d*$')),
              ],
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              style: _WorkoutPageState._ts(
                  theme, 44, FontWeight.w800, theme.primaryText),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '0',
                hintStyle: _WorkoutPageState._ts(theme, 44, FontWeight.w800,
                    theme.secondaryText.withOpacity(0.35)),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: _WorkoutPageState._ts(
                  theme, 13, FontWeight.w500, theme.secondaryText)),
        ],
      ),
    );
  }

  Widget _timedTile(
      FlutterFlowTheme theme, Color field, Color border, String lang) {
    final bool running = _runStart != null;
    final int ms = _totalElapsedMs;
    return _Tap(
      onTap: _toggleTimed,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: field,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: running ? theme.primary : border, width: running ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_mmssMs(ms),
                textDirection: ui.TextDirection.ltr,
                style: _WorkoutPageState._ts(
                    theme, 44, FontWeight.w800, theme.primaryText)),
            const SizedBox(height: 2),
            Text(_tr(lang, running ? 'tapToPause' : 'tapToStart'),
                style: _WorkoutPageState._ts(
                    theme, 13, FontWeight.w500, theme.secondaryText)),
          ],
        ),
      ),
    );
  }

  Widget _upNext(_Stop next, FlutterFlowTheme theme, Color field, String lang) {
    final info = _infoOf(next.exerciseId);
    String name;
    try {
      name = localizedName(info?.nameRaw ?? '', lang);
    } catch (_) {
      name = info?.nameRaw ?? '';
    }
    final String line = next.warm
        ? '$name · ${_tr(lang, 'warmup')} ${next.setNumber}'
        : '$name · ${_tr(lang, 'set')} ${next.setNumber}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_tr(lang, 'upNext'),
            style: _WorkoutPageState._ts(
                theme, 12, FontWeight.w600, theme.secondaryText)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: field, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: theme.secondaryBackground,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.fitness_center_rounded,
                    size: 18, color: theme.secondaryText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(line,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _WorkoutPageState._ts(
                        theme, 15, FontWeight.w600, theme.primaryText)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dots(List<_Stop> q, FlutterFlowTheme theme, Color border) {
    // only the stops of the current exercise
    final int id = q[_i].exerciseId;
    final mine = <int>[];
    for (int k = 0; k < q.length; k++) {
      if (q[k].exerciseId == id) mine.add(k);
    }
    if (mine.length < 2) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final k in mine)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: k == _i ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: k == _i
                    ? theme.primaryText
                    : (_stopDone(q[k]) ? theme.primary : border),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
      ],
    );
  }

  Widget _restScreen(FlutterFlowTheme theme, String lang, _Stop? next) {
    final int left = _restLeft;
    final double frac = _restTotalSec <= 0
        ? 0
        : (left / _restTotalSec).clamp(0.0, 1.0).toDouble();
    String nextLine = '';
    if (next != null) {
      final info = _infoOf(next.exerciseId);
      String name;
      try {
        name = localizedName(info?.nameRaw ?? '', lang);
      } catch (_) {
        name = info?.nameRaw ?? '';
      }
      final int total = next.warm
          ? _warmSetsOf(next.exerciseId).length
          : _setsOfExercise(next.exerciseId);
      nextLine = next.warm
          ? '$name · ${_tr(lang, 'warmup')} ${next.setNumber}/$total'
          : '$name · ${_tr(lang, 'set')} ${next.setNumber}/$total';
    }

    Widget pill(String text, VoidCallback onTap) => _Tap(
          onTap: onTap,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border:
                  Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
            child: Text(text,
                textDirection: ui.TextDirection.ltr,
                style: _WorkoutPageState._ts(
                    theme, 16, FontWeight.w600, Colors.white)),
          ),
        );

    return Positioned.fill(
      child: Container(
        color: _restBg,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(_tr(lang, 'rest').toUpperCase(),
                  style: _WorkoutPageState._ts(
                      theme, 14, FontWeight.w600, Colors.white70)),
              const SizedBox(height: 18),
              SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                        size: const Size(240, 240),
                        painter: _RingPainter(frac)),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_mmss(left),
                            textDirection: ui.TextDirection.ltr,
                            style: _WorkoutPageState._ts(
                                theme, 60, FontWeight.w800, Colors.white)),
                        Text('${_tr(lang, 'of')} ${_mmss(_restTotalSec)}',
                            textDirection: ui.TextDirection.ltr,
                            style: _WorkoutPageState._ts(
                                theme, 14, FontWeight.w400, Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: ui.TextDirection.ltr,
                children: [
                  pill('−15s', () => _bumpRest(-15)),
                  const SizedBox(width: 12),
                  pill('+15s', () => _bumpRest(15)),
                ],
              ),
              const Spacer(),
              if (nextLine.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_tr(lang, 'next').toUpperCase(),
                            style: _WorkoutPageState._ts(
                                theme, 12, FontWeight.w600, Colors.white70)),
                        const SizedBox(height: 4),
                        Text(nextLine,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _WorkoutPageState._ts(
                                theme, 17, FontWeight.w700, Colors.white)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: _Tap(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _stopRest();
                  },
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18)),
                    child: Text(_tr(lang, 'skipRest'),
                        style: _WorkoutPageState._ts(
                            theme, 17, FontWeight.w700, _restBg)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The rest countdown ring.
class _RingPainter extends CustomPainter {
  const _RingPainter(this.fraction);
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final track = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    final arc = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.5707963,
        6.2831853 * fraction.clamp(0.0, 1.0), false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}

// =============================================================================
// Log-edit sheets: Set Date (year · month · day) and Set Duration (h · m).
// Cupertino wheels, one Set button.
// =============================================================================

/// Shell shared by both sheets: grabber, title, wheels, Set button.
class _WheelSheet extends StatelessWidget {
  const _WheelSheet(
      {required this.title,
      required this.wheels,
      required this.onSet,
      required this.lang});
  final String title;
  final List<Widget> wheels;
  final VoidCallback onSet;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bool rtl = _kRtl.contains(lang);
    final double bottom = MediaQuery.of(context).padding.bottom;
    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                  color: theme.alternate,
                  borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 18),
            Text(title,
                style: _WorkoutPageState._ts(
                    theme, 22, FontWeight.w700, theme.primaryText)),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              // the wheels read left → right in every language
              child: Row(textDirection: ui.TextDirection.ltr, children: wheels),
            ),
            const SizedBox(height: 16),
            _Tap(
              onTap: onSet,
              child: Container(
                height: 54,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: theme.primary,
                    borderRadius: BorderRadius.circular(16)),
                child: Text(_tr(lang, 'setBtn'),
                    style: _WorkoutPageState._ts(
                        theme, 17, FontWeight.w700, Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One Cupertino wheel column.
class _Wheel extends StatelessWidget {
  const _Wheel({
    super.key,
    required this.count,
    required this.initialIndex,
    required this.label,
    required this.onChanged,
  });
  final int count;
  final int initialIndex;
  final String Function(int index) label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Expanded(
      child: CupertinoPicker.builder(
        scrollController:
            FixedExtentScrollController(initialItem: initialIndex),
        itemExtent: 42,
        squeeze: 1.1,
        magnification: 1.1,
        useMagnifier: true,
        selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
          background: theme.primaryBackground,
        ),
        childCount: count,
        onSelectedItemChanged: (i) {
          HapticFeedback.selectionClick();
          onChanged(i);
        },
        itemBuilder: (_, i) => Center(
          child: Text(label(i),
              textDirection: ui.TextDirection.ltr,
              style: _WorkoutPageState._ts(
                  theme, 24, FontWeight.w600, theme.primaryText)),
        ),
      ),
    );
  }
}

class _DateSheet extends StatefulWidget {
  const _DateSheet({required this.initial, required this.lang});
  final DateTime initial;
  final String lang;
  @override
  State<_DateSheet> createState() => _DateSheetState();
}

class _DateSheetState extends State<_DateSheet> {
  // ten years back, one year forward
  late final int _firstYear = DateTime.now().year - 10;
  late final int _yearCount = (DateTime.now().year + 1) - _firstYear + 1;
  late int _year = widget.initial.year
      .clamp(_firstYear, _firstYear + _yearCount - 1)
      .toInt();
  late int _month = widget.initial.month;
  late int _day = widget.initial.day;

  int get _daysInMonth => DateTime(_year, _month + 1, 0).day;

  @override
  Widget build(BuildContext context) {
    return _WheelSheet(
      lang: widget.lang,
      title: _tr(widget.lang, 'setDate'),
      onSet: () {
        final d = _day > _daysInMonth ? _daysInMonth : _day;
        Navigator.of(context).pop(DateTime(_year, _month, d));
      },
      wheels: [
        _Wheel(
          count: _yearCount,
          initialIndex: _year - _firstYear,
          label: (i) => '${_firstYear + i}',
          onChanged: (i) => setState(() => _year = _firstYear + i),
        ),
        _Wheel(
          count: 12,
          initialIndex: _month - 1,
          label: (i) => (i + 1).toString().padLeft(2, '0'),
          onChanged: (i) => setState(() => _month = i + 1),
        ),
        _Wheel(
          key: ValueKey('days_${_year}_$_month'),
          count: _daysInMonth,
          initialIndex: (_day.clamp(1, _daysInMonth) - 1),
          label: (i) => (i + 1).toString().padLeft(2, '0'),
          onChanged: (i) => setState(() => _day = i + 1),
        ),
      ],
    );
  }
}

class _DurationSheet extends StatefulWidget {
  const _DurationSheet({required this.initialMinutes, required this.lang});
  final int initialMinutes;
  final String lang;
  @override
  State<_DurationSheet> createState() => _DurationSheetState();
}

class _DurationSheetState extends State<_DurationSheet> {
  late int _h = (widget.initialMinutes ~/ 60).clamp(0, 23).toInt();
  late int _m = (widget.initialMinutes % 60).clamp(0, 59).toInt();

  @override
  Widget build(BuildContext context) {
    return _WheelSheet(
      lang: widget.lang,
      title: _tr(widget.lang, 'setDuration'),
      onSet: () => Navigator.of(context).pop(_h * 60 + _m),
      wheels: [
        _Wheel(
          count: 24,
          initialIndex: _h,
          label: (i) => '${i.toString().padLeft(2, '0')} h',
          onChanged: (i) => setState(() => _h = i),
        ),
        _Wheel(
          count: 60,
          initialIndex: _m,
          label: (i) => '${i.toString().padLeft(2, '0')} m',
          onChanged: (i) => setState(() => _m = i),
        ),
      ],
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
