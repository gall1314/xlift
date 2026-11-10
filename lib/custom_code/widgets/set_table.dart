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
import 'dart:math' as math;
import 'dart:ui' as ui show TextDirection;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

// =============================================================================
// SetTable — the whole set table of ONE exercise in the live workout.
//
// Rows (reps / timed), drop sets under their set, the complete / unmark bar,
// the analysis column (camera / lock / processing / score / error), the
// in-app numpads and the timed-set timer sheet. Always LTR, whatever the app
// language; its own strings follow the app language. Column headers stay
// outside (FF) unless showHeaders is true.
//
// The widget keeps no copy of the data. Every change is emitted as a FULL
// list through onLoggedSetsChanged / onExerciseSetsChanged /
// onDropSetsChanged / onAnalysisStateChanged; FF writes each to App State.
// The set menu (complete / dropset / reset / delete) lives inside; deleting
// a set renumbers every list (and the widget's own timers / videos) so each
// set keeps its data under its new number.
// =============================================================================

// ---------------- Localization ----------------

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
  "addDrop": {
    "en": "Add drop",
    "es": "Añadir drop",
    "he": "הוסף דרופ",
    "de": "Drop hinzufügen",
    "fr": "Ajouter un drop"
  },
  "finishWarmup": {
    "en": "Finish Warmup",
    "es": "Terminar calentamiento",
    "he": "סיים חימום",
    "de": "Aufwärmen beenden",
    "fr": "Terminer l’échauffement"
  },
  "markCompleted": {
    "en": "Mark as Completed",
    "es": "Marcar como completada",
    "he": "סמן כהושלם",
    "de": "Als erledigt markieren",
    "fr": "Marquer comme terminée"
  },
  "unmark": {
    "en": "Unmark Completed",
    "es": "Desmarcar",
    "he": "בטל סימון",
    "de": "Markierung aufheben",
    "fr": "Annuler la validation"
  },
  "enableDropset": {
    "en": "Enable Dropset",
    "es": "Activar dropset",
    "he": "הפעל דרופסט",
    "de": "Dropsatz aktivieren",
    "fr": "Activer le dropset"
  },
  "resetSet": {
    "en": "Reset Set",
    "es": "Reiniciar serie",
    "he": "אפס סט",
    "de": "Satz zurücksetzen",
    "fr": "Réinitialiser la série"
  },
  "deleteSet": {
    "en": "Delete Set",
    "es": "Eliminar serie",
    "he": "מחק סט",
    "de": "Satz löschen",
    "fr": "Supprimer la série"
  },
  "close": {
    "en": "Close",
    "es": "Cerrar",
    "he": "סגור",
    "de": "Schließen",
    "fr": "Fermer"
  },
  "retry": {
    "en": "Retry",
    "es": "Reintentar",
    "he": "נסה שוב",
    "de": "Erneut",
    "fr": "Réessayer"
  },
  "retake": {
    "en": "Retake video",
    "es": "Grabar de nuevo",
    "he": "צלם מחדש",
    "de": "Neu aufnehmen",
    "fr": "Refilmer"
  },
  "analysisFailed": {
    "en": "The analysis failed. Try again or record a new video.",
    "es": "El análisis falló. Inténtalo de nuevo o graba otro video.",
    "he": "הניתוח נכשל. נסה שוב או צלם סרטון חדש.",
    "de": "Analyse fehlgeschlagen. Erneut versuchen oder neu aufnehmen.",
    "fr": "L’analyse a échoué. Réessayez ou filmez une nouvelle vidéo."
  },
  "stopwatch": {
    "en": "Stopwatch",
    "es": "Cronómetro",
    "he": "סטופר",
    "de": "Stoppuhr",
    "fr": "Chrono"
  },
  "countdown": {
    "en": "Countdown",
    "es": "Cuenta atrás",
    "he": "טיימר",
    "de": "Countdown",
    "fr": "Minuteur"
  },
  "manual": {
    "en": "Manual",
    "es": "Manual",
    "he": "ידני",
    "de": "Manuell",
    "fr": "Manuel"
  },
  "start": {
    "en": "Start",
    "es": "Iniciar",
    "he": "התחל",
    "de": "Start",
    "fr": "Démarrer"
  },
  "pause": {
    "en": "Pause",
    "es": "Pausa",
    "he": "השהה",
    "de": "Pause",
    "fr": "Pause"
  },
  "resume": {
    "en": "Resume",
    "es": "Continuar",
    "he": "המשך",
    "de": "Weiter",
    "fr": "Reprendre"
  },
  "reps": {
    "en": "Reps",
    "es": "Reps",
    "he": "חזרות",
    "de": "Wdh.",
    "fr": "Reps"
  },
  "kg": {"en": "Kg", "es": "Kg", "he": "ק״ג", "de": "Kg", "fr": "Kg"},
  "lbs": {"en": "Lbs", "es": "Lb", "he": "ליב׳", "de": "Lbs", "fr": "Lb"},
  "noWeight": {
    "en": "No added weight",
    "es": "Sin peso extra",
    "he": "ללא משקל נוסף",
    "de": "Ohne Zusatzgewicht",
    "fr": "Sans charge"
  },
  "prevReps": {
    "en": "reps",
    "es": "reps",
    "he": "חזרות",
    "de": "Wdh.",
    "fr": "reps"
  },
  "hPrev": {
    "en": "Previous",
    "es": "Anterior",
    "he": "קודם",
    "de": "Zuvor",
    "fr": "Précédent"
  },
  "hReps": {
    "en": "Reps",
    "es": "Reps",
    "he": "חזרות",
    "de": "Wdh.",
    "fr": "Reps"
  },
  "hWeight": {
    "en": "Weight",
    "es": "Peso",
    "he": "משקל",
    "de": "Gewicht",
    "fr": "Poids"
  },
  "hTime": {
    "en": "Time",
    "es": "Tiempo",
    "he": "זמן",
    "de": "Zeit",
    "fr": "Temps"
  },
  // validation
  "errReps": {
    "en": "Cannot complete set – reps must be greater than 0.",
    "es": "No se puede completar: las reps deben ser mayores que 0.",
    "he": "אי אפשר לסמן – חזרות חייבות להיות יותר מ-0.",
    "de": "Satz unvollständig – Wdh. müssen größer als 0 sein.",
    "fr": "Impossible de valider : les reps doivent être supérieures à 0."
  },
  "errWeight": {
    "en": "Cannot complete set – weight must be greater than 0.",
    "es": "No se puede completar: el peso debe ser mayor que 0.",
    "he": "אי אפשר לסמן – משקל חייב להיות יותר מ-0.",
    "de": "Satz unvollständig – Gewicht muss größer als 0 sein.",
    "fr": "Impossible de valider : le poids doit être supérieur à 0."
  },
  "errDuration": {
    "en": "Cannot complete set – time must be greater than 0.",
    "es": "No se puede completar: el tiempo debe ser mayor que 0.",
    "he": "אי אפשר לסמן – זמן חייב להיות יותר מ-0.",
    "de": "Satz unvollständig – Zeit muss größer als 0 sein.",
    "fr": "Impossible de valider : le temps doit être supérieur à 0."
  },
  "errDropReps": {
    "en": "Reps must be greater than 0 in drop set {n}.",
    "es": "Las reps del drop {n} deben ser mayores que 0.",
    "he": "חזרות בדרופ {n} חייבות להיות יותר מ-0.",
    "de": "Wdh. in Drop {n} müssen größer als 0 sein.",
    "fr": "Les reps du drop {n} doivent être supérieures à 0."
  },
  "errDropWeight": {
    "en": "Weight must be greater than 0 in drop set {n}.",
    "es": "El peso del drop {n} debe ser mayor que 0.",
    "he": "משקל בדרופ {n} חייב להיות יותר מ-0.",
    "de": "Gewicht in Drop {n} muss größer als 0 sein.",
    "fr": "Le poids du drop {n} doit être supérieur à 0."
  },
};

String _tr(String lang, String key, {Map<String, String>? p}) {
  final m = _kStrings[key];
  var s = m == null ? key : (m[lang] ?? m['en'] ?? key);
  if (p != null) p.forEach((k, v) => s = s.replaceAll('{$k}', v));
  return s;
}

// ---------------- Small helpers ----------------

int _asInt(dynamic v, [int d = 0]) {
  if (v == null) return d;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim()) ?? d;
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

String _fmtW(double? v) {
  if (v == null) return '';
  if (v == v.roundToDouble()) return v.toInt().toString();
  String s = v.toStringAsFixed(2);
  while (s.endsWith('0')) s = s.substring(0, s.length - 1);
  if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  return s;
}

String _mmss(int ms) {
  final s = (ms / 1000).round();
  final m = (s ~/ 60).toString().padLeft(2, '0');
  final r = (s % 60).toString().padLeft(2, '0');
  return '$m:$r';
}

/// Wrap in an LTR isolate so a number never flips inside RTL text.
String _ltr(String s) => '⁦$s⁩';

String _jobKey(int exerciseId, int setNumber) => '$exerciseId:$setNumber';

// =============================================================================
// Global stores — survive rebuilds, list recycling and navigation.
// =============================================================================

/// Recorded videos per set (result dialog + retry need them). Keeps the last 6.
class _VideoStore {
  static final Map<String, FFUploadedFile> _m = {};
  static void put(String k, FFUploadedFile f) {
    _m.remove(k);
    _m[k] = f;
    while (_m.length > 6) {
      _m.remove(_m.keys.first);
    }
  }

  static FFUploadedFile? get(String k) => _m[k];
  static void remove(String k) => _m.remove(k);

  /// Set [removed] of [exerciseId] is gone; higher sets move down by one.
  static void shiftDown(int exerciseId, int removed) {
    _m.remove(_jobKey(exerciseId, removed));
    final moved = <String, FFUploadedFile>{};
    _m.removeWhere((k, v) {
      final p = k.split(':');
      if (p.length != 2 || int.tryParse(p[0]) != exerciseId) return false;
      final n = int.tryParse(p[1]) ?? 0;
      if (n <= removed) return false;
      moved[_jobKey(exerciseId, n - 1)] = v;
      return true;
    });
    _m.addAll(moved);
  }
}

// =============================================================================
// Timed-set "timer finished" notification (same id 1001 as the rest timer).
// =============================================================================

const int _kTimerNotificationId = 1001;

Future<void> _scheduleTimerNotification(
    int seconds, String exerciseName) async {
  try {
    final secs = seconds <= 0 ? 1 : seconds;
    final exName =
        exerciseName.trim().isNotEmpty ? exerciseName.trim() : 'Exercise';
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'rest_channel',
        'Rest Timers',
        channelDescription: 'Notifications for exercise rest timers',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      ),
      iOS: DarwinNotificationDetails(
          presentAlert: true, presentSound: true, presentBadge: true),
    );
    final when = tz.TZDateTime.now(tz.local).add(Duration(seconds: secs));
    await FlutterLocalNotificationsPlugin().zonedSchedule(
      _kTimerNotificationId,
      '$exName timer finished',
      'Great job! Your timed set is complete',
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'type=timedExercise;name=$exName',
    );
  } catch (_) {}
}

Future<void> _cancelTimerNotification() async {
  try {
    await FlutterLocalNotificationsPlugin().cancel(_kTimerNotificationId);
  } catch (_) {}
}

/// The whole analysis chain, outside any widget State so it finishes even if
/// the table is rebuilt or scrolled away mid-way. Same steps as the FF flow:
/// loading → analyze → valid ? result (+usage, notification) : error.
class _Analysis {
  static const double _kTargetFps = 10.0;
  static List<dynamic> latest = const [];
  static Future Function(List<dynamic> analysisState)? emit;
  static final Set<String> _running = {};

  static Future<void> run({
    required int exerciseId,
    required int setNumber,
    required FFUploadedFile video,
    required String nameEn,
    required String displayName,
  }) async {
    final k = _jobKey(exerciseId, setNumber);
    if (_running.contains(k)) return;
    _running.add(k);
    Future<void> push(List<dynamic> l) async {
      latest = l;
      await emit?.call(l);
    }

    try {
      await push(setExerciseLoadingState(latest, exerciseId, setNumber, true));
      dynamic result;
      try {
        result = await analyzeExerciseVideoAction(video, nameEn, _kTargetFps);
      } catch (_) {
        result = null;
      }
      bool ok = false;
      try {
        ok = isAnalysisValid(result);
      } catch (_) {}
      if (ok) {
        await push(
            updateSetAnalysisResult(latest, exerciseId, setNumber, result));
        try {
          await logAnalysisUsage(result);
        } catch (_) {}
        try {
          await sendAnalysisFinishedNotification(displayName, true);
        } catch (_) {}
      } else {
        await push(updateSetAnalysisError(latest, exerciseId, setNumber));
      }
    } finally {
      _running.remove(k);
    }
  }
}

enum _TimeMode { countUp, countdown, manual }

/// One timer per set, independent of any widget (keeps running while you
/// scroll or the page rebuilds).
class _TimerJob {
  _TimerJob(this.mode, this.targetMs);
  _TimeMode mode;
  int targetMs; // countdown length
  int accumulatedMs = 0; // time before the current run
  DateTime? startedAt;
  Timer? _ticker;
  int _lastCommitSec = 0;
  final ValueNotifier<int> tick = ValueNotifier<int>(0);
  void Function(int elapsedMs)? onCommit;

  /// Countdown started with this much left / stopped before the end — the
  /// table schedules / cancels the "timer finished" notification here.
  void Function(int remainingMs)? onCountdownStarted;
  void Function()? onCountdownStopped;

  bool get running => startedAt != null;

  int get elapsedMs =>
      accumulatedMs +
      (startedAt == null
          ? 0
          : DateTime.now().difference(startedAt!).inMilliseconds);

  /// What the cell shows.
  int get shownMs => mode == _TimeMode.countdown
      ? (targetMs - elapsedMs).clamp(0, targetMs).toInt()
      : elapsedMs;

  /// What completing the set logs.
  int get resultMs {
    if (mode == _TimeMode.countdown) {
      if (elapsedMs <= 0 || elapsedMs >= targetMs) return targetMs;
      return elapsedMs;
    }
    return elapsedMs;
  }

  void start() {
    if (running) return;
    startedAt = DateTime.now();
    _lastCommitSec = elapsedMs ~/ 1000;
    if (mode == _TimeMode.countdown)
      onCountdownStarted?.call(targetMs - accumulatedMs);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      tick.value++;
      final sec = elapsedMs ~/ 1000;
      if (sec - _lastCommitSec >= 5) {
        _lastCommitSec = sec;
        onCommit?.call(elapsedMs);
      }
      if (mode == _TimeMode.countdown && elapsedMs >= targetMs) {
        accumulatedMs = targetMs;
        startedAt = null;
        _ticker?.cancel();
        _ticker = null;
        tick.value++;
        HapticFeedback.heavyImpact();
        onCommit?.call(targetMs);
      }
    });
  }

  void pause() {
    if (!running) return;
    accumulatedMs = elapsedMs;
    startedAt = null;
    _ticker?.cancel();
    _ticker = null;
    tick.value++;
    if (mode == _TimeMode.countdown) onCountdownStopped?.call();
    onCommit?.call(accumulatedMs);
  }

  /// Back to zero without telling anyone.
  void clear() {
    if (running && mode == _TimeMode.countdown) onCountdownStopped?.call();
    _ticker?.cancel();
    _ticker = null;
    startedAt = null;
    accumulatedMs = 0;
    _lastCommitSec = 0;
    tick.value++;
  }

  /// Back to zero and log 0.
  void reset() {
    clear();
    onCommit?.call(0);
  }

  void dispose() {
    _ticker?.cancel();
  }
}

class _TimerJobs {
  static final Map<String, _TimerJob> _m = {};
  static final Map<String, _TimeMode> _modes = {};
  static _TimerJob? get(String k) => _m[k];
  static _TimerJob ensure(String k, _TimeMode mode, int targetMs) =>
      _m.putIfAbsent(k, () => _TimerJob(mode, targetMs));
  static void remove(String k) {
    _m[k]?.dispose();
    _m.remove(k);
  }

  static _TimeMode? mode(String k) => _modes[k];
  static void setMode(String k, _TimeMode m) => _modes[k] = m;

  /// Set [removed] of [exerciseId] is gone; higher sets move down by one.
  static void shiftDown(int exerciseId, int removed) {
    remove(_jobKey(exerciseId, removed));
    _modes.remove(_jobKey(exerciseId, removed));
    final movedJobs = <String, _TimerJob>{};
    final movedModes = <String, _TimeMode>{};
    bool mine(String k, int min) {
      final p = k.split(':');
      return p.length == 2 &&
          int.tryParse(p[0]) == exerciseId &&
          (int.tryParse(p[1]) ?? 0) > min;
    }

    int num(String k) => int.tryParse(k.split(':')[1]) ?? 0;
    _m.removeWhere((k, v) {
      if (!mine(k, removed)) return false;
      movedJobs[_jobKey(exerciseId, num(k) - 1)] = v;
      return true;
    });
    _modes.removeWhere((k, v) {
      if (!mine(k, removed)) return false;
      movedModes[_jobKey(exerciseId, num(k) - 1)] = v;
      return true;
    });
    _m.addAll(movedJobs);
    _modes.addAll(movedModes);
  }
}

/// Play / pause from the cell or the sheet.
void _toggleJob(_TimerJob j, int loggedMs) {
  HapticFeedback.selectionClick();
  if (j.running) {
    j.pause();
    return;
  }
  if (j.mode == _TimeMode.countdown) {
    if (j.elapsedMs >= j.targetMs) j.clear();
  } else if (j.elapsedMs == 0 && loggedMs > 0) {
    j.accumulatedMs = loggedMs; // resume from what is already logged
  }
  j.start();
}

// =============================================================================
// Widget
// =============================================================================

class SetTable extends StatefulWidget {
  const SetTable({
    super.key,
    this.width,
    this.height,
    required this.exerciseId,
    this.exerciseName,
    this.userId,
    this.isKg = true,
    this.isPremium = false,
    this.analysisCount = 0,
    this.aiEnabled = false,
    this.isTimed = false,
    this.isBodyweight = false,
    this.allowsBodyweight = false,
    this.showHeaders = false,
    this.showCameraGuidance,
    this.exerciseSets,
    this.loggedSets,
    this.dropSets,
    this.analysisState,
    this.restTimers,
    this.warmupSets,
    this.onLoggedSetsChanged,
    this.onExerciseSetsChanged,
    this.onDropSetsChanged,
    this.onAnalysisStateChanged,
    this.onResultTap,
    this.onLockTap,
    this.onStartRest,
    this.onDontShowAgain,
    this.onHeightChanged,
    this.onWarmupSetsChanged,
  });

  final double? width;
  final double? height;

  final int exerciseId;

  /// Name as stored (raw JSON or plain). The analyzer gets the English name.
  final String? exerciseName;
  final String? userId;
  final bool isKg;
  final bool isPremium;
  final int analysisCount;

  /// Exercise supports AI form analysis.
  final bool aiEnabled;
  final bool isTimed;

  /// Bodyweight exercise: the weight cell shows "+" until a weight is added.
  final bool isBodyweight;

  /// Weight may stay 0 when completing.
  final bool allowsBodyweight;

  /// Draw the column header row inside the widget (aligned in RTL too).
  final bool showHeaders;
  final bool? showCameraGuidance;

  final List<dynamic>? exerciseSets;
  final List<dynamic>? loggedSets;
  final List<dynamic>? dropSets;
  final List<dynamic>? analysisState;
  final dynamic restTimers;

  /// Warm-up sets (separate App State): [{exerciseId, sets:[{setNumber, reps,
  /// weight (String), isDone}], hidden, completed}]. Drawn above the working
  /// sets with a flame; never counted, never saved.
  final List<dynamic>? warmupSets;

  final Future Function(List<dynamic> loggedSets)? onLoggedSetsChanged;
  final Future Function(List<dynamic> exerciseSets)? onExerciseSetsChanged;
  final Future Function(List<dynamic> dropSets)? onDropSetsChanged;
  final Future Function(List<dynamic> analysisState)? onAnalysisStateChanged;
  final Future Function(int setNumber, FFUploadedFile? video)? onResultTap;
  final Future Function()? onLockTap;
  final Future Function(int exerciseId, int setNumber, int restMs)? onStartRest;
  final Future Function()? onDontShowAgain;

  /// Fired whenever the table's own height changes (sets, drops, done state,
  /// the unmark strip). Store it in a component state and bind the widget's
  /// height to it.
  final Future Function(double height)? onHeightChanged;
  final Future Function(List<dynamic> warmupSets)? onWarmupSetsChanged;

  @override
  State<SetTable> createState() => _SetTableState();
}

/// One planned set from exerciseSets.
class _TplSet {
  _TplSet({
    required this.setNumber,
    required this.weighted,
    required this.targetReps,
    required this.durationSec,
  });
  final int setNumber;
  final bool weighted;
  final int targetReps;
  final int durationSec;
}

class _Prev {
  _Prev(this.text, this.reps, this.weight, this.durationSec);
  final String text;
  final int? reps;
  final double? weight;
  final int? durationSec;
}

class _SetTableState extends State<SetTable> {
  final Map<int, _Prev> _prev = {};
  final Set<int> _prevLoading = {};
  final Set<int> _unmarkOpen = {}; // done sets whose unmark strip is showing
  double _lastHeight = -1;
  OverlayEntry? _toast;
  Timer? _toastTimer;

  static const double _colNum = 48;
  static const double _gap = 6;
  static const double _rowH = 54;
  static const double _barH = 28;
  static const double _unmarkH = 32;

  // AI exercises keep a 44px action column; the others spread reps / weight.
  double get _colVal => widget.aiEnabled ? 64 : 80;
  double get _colAct => widget.aiEnabled ? 44 : 0;
  double get _colTime => _colVal * 2 + _gap;
  double get _tail => widget.aiEnabled ? 0 : 18;

  // ---------- template ----------

  List<_TplSet> get _template {
    final out = <_TplSet>[];
    for (final e in widget.exerciseSets ?? const []) {
      if (e is! Map || _asInt(e['exerciseId']) != widget.exerciseId) continue;
      final sets = e['sets'];
      if (sets is! List) break;
      for (final s in sets) {
        if (s is! Map) continue;
        out.add(_TplSet(
          setNumber: _asInt(s['setNumber']),
          weighted: _truthy(s['weighted'] ?? 1),
          targetReps: _asInt(s['targetReps']),
          durationSec: _asInt(s['durationSeconds']),
        ));
      }
      break;
    }
    out.sort((a, b) => a.setNumber.compareTo(b.setNumber));
    return out;
  }

  String get _nameEn {
    final raw0 = widget.exerciseName ?? '';
    final raw = raw0.trim().toLowerCase() == 'null' ? '' : raw0;
    try {
      final s = localizedName(raw, 'en');
      return s.isEmpty ? raw : s;
    } catch (_) {
      return raw;
    }
  }

  String _displayName(String lang) {
    final raw = widget.exerciseName ?? '';
    try {
      final s = localizedName(raw, lang);
      return s.isEmpty ? raw : s;
    } catch (_) {
      return raw;
    }
  }

  // ---------- logged ----------

  Map? _base(int setNumber) {
    for (final l in widget.loggedSets ?? const []) {
      if (l is Map &&
          _asInt(l['exerciseId']) == widget.exerciseId &&
          _asInt(l['setNumber']) == setNumber &&
          !_truthy(l['isDropSet'])) return l;
    }
    return null;
  }

  Map? _loggedDrop(int setNumber, int order) {
    for (final l in widget.loggedSets ?? const []) {
      if (l is Map &&
          _asInt(l['exerciseId']) == widget.exerciseId &&
          _asInt(l['setNumber']) == setNumber &&
          _truthy(l['isDropSet']) &&
          _asInt(l['dropOrder']) == order) return l;
    }
    return null;
  }

  List<Map> _plannedDrops(int setNumber) {
    final out = <Map>[];
    for (final d in widget.dropSets ?? const []) {
      if (d is Map &&
          _asInt(d['exerciseId']) == widget.exerciseId &&
          _asInt(d['parentSetNumber']) == setNumber) out.add(d);
    }
    out.sort(
        (a, b) => _asInt(a['dropOrder']).compareTo(_asInt(b['dropOrder'])));
    return out;
  }

  /// The set may carry a weight: weighted template, or a bodyweight exercise
  /// that allows added weight (shown as "+" until one is entered).
  bool _canWeight(_TplSet t) =>
      t.weighted || widget.isBodyweight || widget.allowsBodyweight;
  bool _plusMode(_TplSet t) =>
      !t.weighted && (widget.isBodyweight || widget.allowsBodyweight);

  bool _isDone(int setNumber) => _truthy(_base(setNumber)?['isDone']);
  bool _isSkipped(int setNumber) => _truthy(_base(setNumber)?['isSkipped']);
  int _loggedMs(int setNumber) => _asInt(_base(setNumber)?['durationMs']);

  /// Latest earlier (non-drop) set of this exercise with a value — the hint.
  int? _prevSetReps(int setNumber) {
    int? best;
    int bestSn = -1;
    for (final l in widget.loggedSets ?? const []) {
      if (l is! Map || _asInt(l['exerciseId']) != widget.exerciseId) continue;
      if (_truthy(l['isDropSet'])) continue;
      final sn = _asInt(l['setNumber']);
      final r = _asIntN(l['reps']);
      if (sn < setNumber && r != null && r > 0 && sn > bestSn) {
        best = r;
        bestSn = sn;
      }
    }
    return best;
  }

  double? _prevSetWeight(int setNumber) {
    double? best;
    int bestSn = -1;
    for (final l in widget.loggedSets ?? const []) {
      if (l is! Map || _asInt(l['exerciseId']) != widget.exerciseId) continue;
      if (_truthy(l['isDropSet'])) continue;
      final sn = _asInt(l['setNumber']);
      final w = _asDoubleN(l['weight']);
      if (sn < setNumber && w != null && w > 0 && sn > bestSn) {
        best = w;
        bestSn = sn;
      }
    }
    return best;
  }

  int _repsHint(_TplSet t) {
    final p = _prevSetReps(t.setNumber);
    if (p != null) return p;
    if (t.targetReps > 0) return t.targetReps;
    for (final s in _template) {
      if (s.targetReps > 0) return s.targetReps;
    }
    return 0;
  }

  double _weightHint(_TplSet t) {
    final p = _prevSetWeight(t.setNumber);
    if (p != null) return p;
    final pr = _prev[t.setNumber];
    if (pr != null && (pr.weight ?? 0) > 0) return pr.weight!;
    return 0;
  }

  // ---------- write back ----------

  List<Map<String, dynamic>> _copyLogged() => (widget.loggedSets ?? const [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  Future<void> _emit(List<Map<String, dynamic>> list) async {
    await widget.onLoggedSetsChanged?.call(List<dynamic>.from(list));
  }

  /// Same semantics as updateFlatSetValue: only the passed fields change.
  List<Map<String, dynamic>> _upsertBase(
    List<Map<String, dynamic>> list,
    _TplSet t, {
    int? reps,
    bool clearReps = false,
    double? weight,
    bool clearWeight = false,
    int? durationMs,
    bool? isDone,
    bool? isSkipped,
  }) {
    final idx = list.indexWhere((s) =>
        _asInt(s['exerciseId']) == widget.exerciseId &&
        _asInt(s['setNumber']) == t.setNumber &&
        !_truthy(s['isDropSet']));
    final old = idx >= 0 ? list[idx] : <String, dynamic>{};
    final Map<String, dynamic> next = {
      ...old,
      'exerciseId': widget.exerciseId,
      'setNumber': t.setNumber,
      'isDone': isDone ?? _truthy(old['isDone']),
      'weighted': t.weighted,
      'reps': clearReps ? null : (reps ?? old['reps']),
      'weight': !_canWeight(t)
          ? null
          : (clearWeight ? null : (weight ?? _asDoubleN(old['weight']))),
      'durationMs': durationMs ?? _asInt(old['durationMs']),
    };
    if (isSkipped != null) next['isSkipped'] = isSkipped;
    if (idx >= 0) {
      list[idx] = next;
    } else {
      list.add(next);
    }
    return list;
  }

  /// Same semantics as upsertDropSetInLoggedSetsAction.
  List<Map<String, dynamic>> _upsertDrop(
    List<Map<String, dynamic>> list,
    int setNumber,
    int order, {
    int? reps,
    bool keepReps = false,
    double? weight,
    bool keepWeight = false,
  }) {
    final idx = list.indexWhere((s) =>
        _asInt(s['exerciseId']) == widget.exerciseId &&
        _asInt(s['setNumber']) == setNumber &&
        _truthy(s['isDropSet']) &&
        _asInt(s['dropOrder']) == order);
    if (idx >= 0) {
      final old = list[idx];
      list[idx] = {
        ...old,
        'isDropSet': 1,
        'reps': keepReps ? old['reps'] : reps,
        'weight': keepWeight ? old['weight'] : weight,
      };
    } else {
      list.add({
        'exerciseId': widget.exerciseId,
        'setNumber': setNumber,
        'reps': reps,
        'weight': weight,
        'durationMs': null,
        'isDone': false,
        'isDropSet': 1,
        'dropLabel': 'Drop $order',
        'dropOrder': order,
      });
    }
    return list;
  }

  // ---------- lifecycle ----------

  @override
  void initState() {
    super.initState();
    // A timer left over from an earlier workout (nothing logged any more).
    for (final t in _template) {
      final job = _TimerJobs.get(_jobKey(widget.exerciseId, t.setNumber));
      if (job != null && !job.running && _loggedMs(t.setNumber) == 0)
        job.clear();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPrevious());
  }

  @override
  void didUpdateWidget(covariant SetTable old) {
    super.didUpdateWidget(old);
    if (old.exerciseId != widget.exerciseId || old.userId != widget.userId) {
      _prev.clear();
      _prevLoading.clear();
    }
    _loadPrevious();
    _attachTimerCommits();
  }

  @override
  void dispose() {
    _hideToast();
    super.dispose();
  }

  // ---------- previous (last workout) ----------

  Future<void> _loadPrevious() async {
    final uid = widget.userId ?? '';
    if (uid.isEmpty) return;
    for (final t in _template) {
      final n = t.setNumber;
      if (_prev.containsKey(n) || _prevLoading.contains(n)) continue;
      _prevLoading.add(n);
      try {
        final rows = await SQLiteManager.instance.correctedPreviosSet(
          exerciseId: widget.exerciseId,
          setNumber: n,
          userId: uid,
        );
        dynamic row = rows.isNotEmpty ? rows.first : null;
        dynamic g(String k) {
          if (row == null) return null;
          try {
            return (row as dynamic).data[k];
          } catch (_) {
            try {
              return (row as Map)[k];
            } catch (_) {
              return null;
            }
          }
        }

        final reps = _asIntN(g('reps'));
        final weight = _asDoubleN(g('weight'));
        final dur = _asIntN(g('duration_seconds'));
        String text;
        try {
          text = correctedFormatPreviousSet(reps, weight, dur, widget.isKg);
        } catch (_) {
          text = '-';
        }
        if (mounted) setState(() => _prev[n] = _Prev(text, reps, weight, dur));
      } catch (_) {
        if (mounted) setState(() => _prev[n] = _Prev('-', null, null, null));
      } finally {
        _prevLoading.remove(n);
      }
    }
  }

  /// The previous-set text in the app language.
  String _prevLabel(String lang, int setNumber) {
    final p = _prev[setNumber];
    if (p == null) return _prevLoading.contains(setNumber) ? '' : '-';
    var s = p.text;
    if (lang == 'en') return s;
    s = s.replaceAll(RegExp(r'\breps\b'), _tr(lang, 'prevReps'));
    return s;
  }

  Future<void> _applyPrevious(_TplSet t) async {
    final p = _prev[t.setNumber];
    if (p == null || _isDone(t.setNumber)) return;
    HapticFeedback.selectionClick();
    var list = _copyLogged();
    if (widget.isTimed) {
      if ((p.durationSec ?? 0) <= 0) return;
      _TimerJobs.get(_jobKey(widget.exerciseId, t.setNumber))?.clear();
      list = _upsertBase(list, t, durationMs: p.durationSec! * 1000);
    } else {
      if ((p.reps ?? 0) <= 0 && (p.weight ?? 0) <= 0) return;
      list = _upsertBase(list, t,
          reps: (p.reps ?? 0) > 0 ? p.reps : null,
          weight: (p.weight ?? 0) > 0 ? p.weight : null);
    }
    await _emit(list);
  }

  // ---------- timers ----------

  _TimeMode _modeFor(_TplSet t) {
    final k = _jobKey(widget.exerciseId, t.setNumber);
    return _TimerJobs.mode(k) ??
        (t.durationSec > 0 ? _TimeMode.countdown : _TimeMode.countUp);
  }

  _TimerJob _jobFor(_TplSet t) {
    final k = _jobKey(widget.exerciseId, t.setNumber);
    final mode = _modeFor(t);
    final job = _TimerJobs.ensure(k, mode, t.durationSec * 1000);
    job.mode = mode;
    if (job.targetMs <= 0)
      job.targetMs = t.durationSec > 0 ? t.durationSec * 1000 : 60000;
    _wireJob(job, t);
    return job;
  }

  void _wireJob(_TimerJob job, _TplSet t) {
    job.onCommit = (ms) => _commitDuration(t, ms);
    job.onCountdownStarted = (remainingMs) {
      final String lang = mounted ? _langOf(context) : 'en';
      _scheduleTimerNotification(
          (remainingMs / 1000).ceil(), _displayName(lang));
    };
    job.onCountdownStopped = () {
      _cancelTimerNotification();
    };
  }

  void _attachTimerCommits() {
    for (final t in _template) {
      final job = _TimerJobs.get(_jobKey(widget.exerciseId, t.setNumber));
      if (job != null) _wireJob(job, t);
    }
  }

  Future<void> _commitDuration(_TplSet t, int ms) async {
    if (!mounted) return;
    await _emit(_upsertBase(_copyLogged(), t, durationMs: ms));
  }

  void _setMode(_TplSet t, _TimeMode m) {
    final k = _jobKey(widget.exerciseId, t.setNumber);
    _TimerJobs.setMode(k, m);
    final j = _TimerJobs.get(k);
    if (j != null) {
      if (j.running) j.pause();
      j.clear();
      j.mode = m;
      if (j.targetMs <= 0)
        j.targetMs = t.durationSec > 0 ? t.durationSec * 1000 : 60000;
    }
    if (mounted) setState(() {});
  }

  /// Time to log for a timed set right now, in ms (0 = nothing yet).
  /// Mirrors what the cell shows.
  int _timeCandidateMs(_TplSet t) {
    final job = _TimerJobs.get(_jobKey(widget.exerciseId, t.setNumber));
    final int logged = _loggedMs(t.setNumber);
    final int target =
        (job?.targetMs ?? 0) > 0 ? job!.targetMs : t.durationSec * 1000;
    final mode = job?.mode ?? _modeFor(t);
    if (mode == _TimeMode.manual) return logged > 0 ? logged : target;
    if (mode == _TimeMode.countdown) {
      if (job != null && job.elapsedMs > 0) return job.resultMs;
      return target;
    }
    if (job != null && job.elapsedMs > 0) return job.elapsedMs;
    return logged;
  }

  // ---------- complete / unmark ----------

  String? _validationError(_TplSet t, String lang) {
    if (widget.isTimed) {
      return _timeCandidateMs(t) > 0 ? null : _tr(lang, 'errDuration');
    }
    final base = _base(t.setNumber);
    final int reps = _asIntN(base?['reps']) ?? 0;
    if ((reps > 0 ? reps : _repsHint(t)) <= 0) return _tr(lang, 'errReps');
    if (t.weighted && !widget.allowsBodyweight && !widget.isBodyweight) {
      final double w = _asDoubleN(base?['weight']) ?? 0;
      if ((w > 0 ? w : _weightHint(t)) <= 0) return _tr(lang, 'errWeight');
    }
    for (final d in _plannedDrops(t.setNumber)) {
      final order = _asInt(d['dropOrder']);
      final logged = _loggedDrop(t.setNumber, order);
      final int r = _asIntN(logged?['reps']) ?? _asIntN(d['reps']) ?? 0;
      if (r <= 0) return _tr(lang, 'errDropReps', p: {'n': '$order'});
      if (t.weighted && !widget.allowsBodyweight && !widget.isBodyweight) {
        final double w =
            _asDoubleN(logged?['weight']) ?? _asDoubleN(d['weight']) ?? 0;
        if (w <= 0) return _tr(lang, 'errDropWeight', p: {'n': '$order'});
      }
    }
    return null;
  }

  Future<void> _complete(_TplSet t, String lang) async {
    final err = _validationError(t, lang);
    if (err != null) {
      HapticFeedback.heavyImpact();
      _showToast(err, lang);
      return;
    }

    HapticFeedback.mediumImpact();
    var list = _copyLogged();
    final base = _base(t.setNumber);
    if (widget.isTimed) {
      final k = _jobKey(widget.exerciseId, t.setNumber);
      final job = _TimerJobs.get(k);
      if (job != null && job.running) job.pause();
      final ms = _timeCandidateMs(t);
      _TimerJobs.remove(k);
      list =
          _upsertBase(list, t, durationMs: ms, isDone: true, isSkipped: false);
    } else {
      // Persist the hint values the user never typed, so the saved set
      // carries real numbers.
      final int reps = _asIntN(base?['reps']) ?? 0;
      final double w = _asDoubleN(base?['weight']) ?? 0;
      final double wh = _weightHint(t);
      list = _upsertBase(list, t,
          reps: reps > 0 ? reps : _repsHint(t),
          weight: w > 0 ? w : (wh > 0 ? wh : null),
          isDone: true,
          isSkipped: false);
      for (final d in _plannedDrops(t.setNumber)) {
        final order = _asInt(d['dropOrder']);
        final logged = _loggedDrop(t.setNumber, order);
        final int? lr = _asIntN(logged?['reps']);
        final double? lw = _asDoubleN(logged?['weight']);
        if (logged == null || (lr ?? 0) <= 0 || (lw ?? 0) <= 0) {
          list = _upsertDrop(list, t.setNumber, order,
              reps: (lr ?? 0) > 0 ? lr : _asIntN(d['reps']),
              weight: (lw ?? 0) > 0 ? lw : _asDoubleN(d['weight']));
        }
      }
    }
    await _emit(list);

    final rest = _restMs();
    if (rest > 0)
      await widget.onStartRest?.call(widget.exerciseId, t.setNumber, rest);
  }

  Future<void> _unmark(_TplSet t) async {
    HapticFeedback.selectionClick();
    await _emit(_upsertBase(_copyLogged(), t, isDone: false));
  }

  int _restMs() {
    final rt = widget.restTimers;
    if (rt is! Map) return 0;
    final v = rt['${widget.exerciseId}'] ?? rt[widget.exerciseId];
    return _asInt(v);
  }

  // ---------- warm-up ----------

  Map? _warmEntry() {
    for (final e in widget.warmupSets ?? const []) {
      if (e is Map && _asInt(e['exerciseId']) == widget.exerciseId) return e;
    }
    return null;
  }

  /// Visible warm-up sets (none when hidden / completed).
  List<Map> _warmSets() {
    final e = _warmEntry();
    if (e == null || _truthy(e['hidden']) || _truthy(e['completed']))
      return const [];
    final sets = e['sets'];
    if (sets is! List) return const [];
    final out = sets.whereType<Map>().toList()
      ..sort(
          (a, b) => _asInt(a['setNumber']).compareTo(_asInt(b['setNumber'])));
    return out;
  }

  Future<void> _emitWarm(
      void Function(Map<String, dynamic> entry, List<Map<String, dynamic>> sets)
          edit) async {
    final list = _copyList(widget.warmupSets);
    final idx = list.indexWhere((e) => _isMine(e));
    if (idx < 0) return;
    final entry = list[idx];
    final sets = (entry['sets'] is List)
        ? (entry['sets'] as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList()
        : <Map<String, dynamic>>[];
    edit(entry, sets);
    entry['sets'] = sets;
    list[idx] = entry;
    await widget.onWarmupSetsChanged?.call(List<dynamic>.from(list));
  }

  Future<void> _warmSetValue(int setNumber,
      {int? reps, double? weight, bool clearWeight = false}) {
    return _emitWarm((entry, sets) {
      for (final w in sets) {
        if (_asInt(w['setNumber']) != setNumber) continue;
        if (reps != null) {
          w['reps'] = reps;
          w['repsText'] = '$reps';
        }
        if (clearWeight) w['weight'] = '0';
        if (weight != null) w['weight'] = _fmtW(weight);
      }
    });
  }

  /// ✓ on a warm-up set; the last one also hides the whole warm-up.
  Future<void> _warmComplete(int setNumber) async {
    HapticFeedback.mediumImpact();
    await _emitWarm((entry, sets) {
      bool allDone = true;
      for (final w in sets) {
        if (_asInt(w['setNumber']) == setNumber) w['isDone'] = true;
        if (!_truthy(w['isDone'])) allDone = false;
      }
      if (allDone) {
        entry['hidden'] = true;
        entry['completed'] = true;
      }
    });
  }

  Future<void> _warmUnmark(int setNumber) async {
    HapticFeedback.selectionClick();
    await _emitWarm((entry, sets) {
      for (final w in sets) {
        if (_asInt(w['setNumber']) == setNumber) w['isDone'] = false;
      }
    });
  }

  /// One warm-up block: flame · "-" · reps · weight · (empty) + ✓ bar.
  Widget _warmBlock(
      Map w,
      bool isLast,
      String lang,
      bool dark,
      Color text,
      Color muted,
      Color accent,
      Color doneBg,
      Color onDone,
      Color zebra,
      Color cellBg) {
    final int n = _asInt(w['setNumber']);
    final bool done = _truthy(w['isDone']);
    final int? reps = _asIntN(w['reps']);
    final double? weight = _asDoubleN(w['weight']);
    final bool canWeight = !widget.isTimed &&
        (widget.isBodyweight ||
            widget.allowsBodyweight ||
            !_template.any((t) => !t.weighted));
    final Color flame = const Color(0xFF38BDF8);

    final Widget row = SizedBox(
      height: _rowH,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            SizedBox(
              width: _colNum,
              child: Center(
                  child: Icon(Icons.local_fire_department_rounded,
                      size: 22, color: flame)),
            ),
            const SizedBox(width: _gap),
            Expanded(
                child: Center(
                    child: Text('-',
                        style: TextStyle(fontSize: 16, color: muted)))),
            const SizedBox(width: _gap),
            SizedBox(
              width: widget.isTimed ? _colTime : _colVal,
              child: widget.isTimed
                  ? Center(
                      child: Text(
                          _mmss((_asInt(w['durationSec']) > 0
                                  ? _asInt(w['durationSec'])
                                  : 30) *
                              1000),
                          textDirection: ui.TextDirection.ltr,
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: text)))
                  : _RepsCell(
                      value: reps,
                      hint: 0,
                      isDone: done,
                      lang: lang,
                      dark: dark,
                      textColor: text,
                      hintColor: muted.withOpacity(0.5),
                      focusColor: accent,
                      onCommit: (v) => _warmSetValue(n, reps: v ?? 0),
                    ),
            ),
            if (!widget.isTimed) ...[
              const SizedBox(width: _gap),
              SizedBox(
                width: _colVal,
                child: !canWeight || (done && (weight ?? 0) <= 0)
                    ? Center(
                        child: Text('-',
                            style: TextStyle(fontSize: 17, color: muted)))
                    : _WeightCell(
                        value: (weight ?? 0) > 0 ? weight : null,
                        hint: 0,
                        isDone: done,
                        isKg: widget.isKg,
                        plusMode:
                            widget.isBodyweight || widget.allowsBodyweight,
                        lang: lang,
                        dark: dark,
                        textColor: text,
                        hintColor: muted.withOpacity(0.5),
                        focusColor: accent,
                        onCommit: (v) =>
                            _warmSetValue(n, weight: v, clearWeight: v == null),
                      ),
              ),
            ],
            if (widget.aiEnabled) ...[
              const SizedBox(width: _gap),
              SizedBox(width: _colAct),
            ] else
              SizedBox(width: _tail),
          ],
        ),
      ),
    );

    final Widget bar = done
        ? _Pressable(
            onTap: () => _warmUnmark(n),
            child: Container(
              height: _barH,
              color: cellBg,
              alignment: Alignment.center,
              child: Icon(Icons.remove_done_rounded, size: 18, color: muted),
            ),
          )
        : _Pressable(
            onTap: () => _warmComplete(n),
            child: Container(
              height: _barH,
              color: doneBg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, size: 18, color: onDone),
                  if (isLast) ...[
                    const SizedBox(width: 8),
                    Text(_tr(lang, 'finishWarmup'),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: onDone)),
                  ],
                ],
              ),
            ),
          );

    return Container(
      decoration: BoxDecoration(
        color: done ? doneBg : zebra,
        borderRadius: BorderRadius.circular(12),
        border: done
            ? Border.all(
                color: dark ? const Color(0xFF2A3644) : const Color(0xFFE3E7EB))
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [row, bar]),
    );
  }

  // ---------- set menu: dropset / reset / delete ----------

  List<Map<String, dynamic>> _copyList(List<dynamic>? l) => (l ?? const [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  bool _isMine(Map m) => _asInt(m['exerciseId']) == widget.exerciseId;

  /// Drop weight suggestion: 20% under [from], snapped to the plate step.
  double? _dropWeightFrom(double? from) {
    if (from == null || from <= 0) return null;
    final double step = widget.isKg ? 2.5 : 5.0;
    final double w = (from * 0.8 / step).round() * step;
    return w > 0 ? w : step;
  }

  Future<void> _openSetMenu(_TplSet t, String lang) async {
    final theme = FlutterFlowTheme.of(context);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final bool rtl = _kRtl.contains(lang);
    final bool done = _isDone(t.setNumber);
    final bool hasDrops = _plannedDrops(t.setNumber).isNotEmpty;
    final bool canDelete = _template.length > 1;
    final Color text = theme.primaryText;
    final Color sheetBg = dark ? const Color(0xFF141A21) : Colors.white;

    Widget item(IconData icon, Color iconColor, String label, Color labelColor,
        VoidCallback onTap,
        {bool checked = false}) {
      return _Pressable(
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(icon, size: 24, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: labelColor)),
              ),
              if (checked)
                Icon(Icons.check_rounded, size: 22, color: theme.primary),
            ],
          ),
        ),
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: EdgeInsets.only(
              top: 10, bottom: MediaQuery.of(ctx).padding.bottom + 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: text.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2)),
              ),
              item(
                done ? Icons.remove_done_rounded : Icons.check_circle_rounded,
                theme.primary,
                _tr(lang, done ? 'unmark' : 'markCompleted'),
                text,
                () {
                  Navigator.of(ctx).pop();
                  if (done) {
                    _unmark(t);
                  } else {
                    _complete(t, lang);
                  }
                },
              ),
              if (!widget.isTimed)
                item(
                  Icons.trending_down_rounded,
                  const Color(0xFF38BDF8),
                  _tr(lang, 'enableDropset'),
                  text,
                  () {
                    Navigator.of(ctx).pop();
                    _toggleDropset(t);
                  },
                  checked: hasDrops,
                ),
              item(
                Icons.refresh_rounded,
                theme.secondaryText,
                _tr(lang, 'resetSet'),
                text,
                () {
                  Navigator.of(ctx).pop();
                  _resetSet(t);
                },
              ),
              if (canDelete) ...[
                Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                    color: text.withOpacity(0.08)),
                item(
                  Icons.delete_rounded,
                  const Color(0xFFEF4444),
                  _tr(lang, 'deleteSet'),
                  const Color(0xFFEF4444),
                  () {
                    Navigator.of(ctx).pop();
                    _deleteSet(t);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Enable → one drop (reps = set reps, weight = 20% less); disable → drops gone.
  Future<void> _toggleDropset(_TplSet t) async {
    HapticFeedback.selectionClick();
    if (_plannedDrops(t.setNumber).isNotEmpty) {
      final drops = _copyList(widget.dropSets)
        ..removeWhere(
            (d) => _isMine(d) && _asInt(d['parentSetNumber']) == t.setNumber);
      final logged = _copyLogged()
        ..removeWhere((l) =>
            _isMine(l) &&
            _asInt(l['setNumber']) == t.setNumber &&
            _truthy(l['isDropSet']));
      await widget.onDropSetsChanged?.call(List<dynamic>.from(drops));
      await _emit(logged);
      return;
    }
    await _addDrop(t);
  }

  Future<void> _addDrop(_TplSet t) async {
    HapticFeedback.selectionClick();
    final base = _base(t.setNumber);
    final planned = _plannedDrops(t.setNumber);
    final int order =
        planned.isEmpty ? 1 : _asInt(planned.last['dropOrder']) + 1;
    final int? reps = (_asIntN(base?['reps']) ?? 0) > 0
        ? _asIntN(base?['reps'])
        : _repsHint(t);
    double? from;
    if (planned.isNotEmpty) {
      final last = planned.last;
      from = _asDoubleN(
              _loggedDrop(t.setNumber, _asInt(last['dropOrder']))?['weight']) ??
          _asDoubleN(last['weight']);
    } else {
      from = (_asDoubleN(base?['weight']) ?? 0) > 0
          ? _asDoubleN(base?['weight'])
          : _weightHint(t);
    }
    final drops = _copyList(widget.dropSets)
      ..add({
        'exerciseId': widget.exerciseId,
        'parentSetNumber': t.setNumber,
        'dropOrder': order,
        'reps': (reps ?? 0) > 0 ? reps : null,
        'weight': _canWeight(t) ? _dropWeightFrom(from) : null,
      });
    await widget.onDropSetsChanged?.call(List<dynamic>.from(drops));
  }

  /// Remove one drop and renumber the drops below it (planned and logged).
  Future<void> _deleteDrop(_TplSet t, int order) async {
    HapticFeedback.selectionClick();
    final drops = _copyList(widget.dropSets);
    drops.removeWhere((d) =>
        _isMine(d) &&
        _asInt(d['parentSetNumber']) == t.setNumber &&
        _asInt(d['dropOrder']) == order);
    for (final d in drops) {
      if (_isMine(d) &&
          _asInt(d['parentSetNumber']) == t.setNumber &&
          _asInt(d['dropOrder']) > order) {
        d['dropOrder'] = _asInt(d['dropOrder']) - 1;
      }
    }
    final logged = _copyLogged();
    logged.removeWhere((l) =>
        _isMine(l) &&
        _asInt(l['setNumber']) == t.setNumber &&
        _truthy(l['isDropSet']) &&
        _asInt(l['dropOrder']) == order);
    for (final l in logged) {
      if (_isMine(l) &&
          _asInt(l['setNumber']) == t.setNumber &&
          _truthy(l['isDropSet']) &&
          _asInt(l['dropOrder']) > order) {
        final n = _asInt(l['dropOrder']) - 1;
        l['dropOrder'] = n;
        l['dropLabel'] = 'Drop $n';
      }
    }
    await widget.onDropSetsChanged?.call(List<dynamic>.from(drops));
    await _emit(logged);
  }

  /// Back to the untouched row: no logged values, no analysis, no timer.
  Future<void> _resetSet(_TplSet t) async {
    HapticFeedback.mediumImpact();
    final k = _jobKey(widget.exerciseId, t.setNumber);
    _TimerJobs.get(k)?.clear(); // cancels the countdown notification if running
    _TimerJobs.remove(k);
    _VideoStore.remove(k);
    final logged = _copyLogged()
      ..removeWhere((l) => _isMine(l) && _asInt(l['setNumber']) == t.setNumber);
    final drops = _copyList(widget.dropSets)
      ..removeWhere(
          (d) => _isMine(d) && _asInt(d['parentSetNumber']) == t.setNumber);
    await _emit(logged);
    await widget.onDropSetsChanged?.call(List<dynamic>.from(drops));
    await widget.onAnalysisStateChanged
        ?.call(_analysisWithout(t.setNumber, shift: false));
  }

  /// analysisState without set [n] of this exercise; with [shift] the higher
  /// sets move down by one.
  List<dynamic> _analysisWithout(int n, {required bool shift}) {
    final out = _copyList(widget.analysisState);
    for (final e in out) {
      if (!_isMine(e) || e['sets'] is! List) continue;
      final sets = (e['sets'] as List)
          .whereType<Map>()
          .map((s) => Map<String, dynamic>.from(s))
          .where((s) => _asInt(s['setNumber']) != n)
          .toList();
      if (shift) {
        for (final s in sets) {
          if (_asInt(s['setNumber']) > n)
            s['setNumber'] = _asInt(s['setNumber']) - 1;
        }
      }
      e['sets'] = sets;
    }
    return List<dynamic>.from(out);
  }

  /// Delete the set everywhere and renumber what follows, so every remaining
  /// set keeps its own values, drops, analysis, video and timer.
  Future<void> _deleteSet(_TplSet t) async {
    if (_template.length <= 1) return;
    HapticFeedback.mediumImpact();
    final int n = t.setNumber;

    // exerciseSets
    final ex = _copyList(widget.exerciseSets);
    for (final e in ex) {
      if (!_isMine(e) || e['sets'] is! List) continue;
      final sets = (e['sets'] as List)
          .whereType<Map>()
          .map((s) => Map<String, dynamic>.from(s))
          .where((s) => _asInt(s['setNumber']) != n)
          .toList()
        ..sort(
            (a, b) => _asInt(a['setNumber']).compareTo(_asInt(b['setNumber'])));
      for (int i = 0; i < sets.length; i++) {
        sets[i]['setNumber'] = i + 1;
      }
      e['sets'] = sets;
    }

    // loggedSets (base rows and drops)
    final logged = _copyLogged()
      ..removeWhere((l) => _isMine(l) && _asInt(l['setNumber']) == n);
    for (final l in logged) {
      if (_isMine(l) && _asInt(l['setNumber']) > n)
        l['setNumber'] = _asInt(l['setNumber']) - 1;
    }

    // dropSets
    final drops = _copyList(widget.dropSets)
      ..removeWhere((d) => _isMine(d) && _asInt(d['parentSetNumber']) == n);
    for (final d in drops) {
      if (_isMine(d) && _asInt(d['parentSetNumber']) > n) {
        d['parentSetNumber'] = _asInt(d['parentSetNumber']) - 1;
      }
    }

    // widget-side registries + previous cache
    _TimerJobs.get(_jobKey(widget.exerciseId, n))
        ?.clear(); // cancels a running countdown
    _TimerJobs.shiftDown(widget.exerciseId, n);
    _VideoStore.shiftDown(widget.exerciseId, n);
    _prev.clear();
    _prevLoading.clear();

    await widget.onExerciseSetsChanged?.call(List<dynamic>.from(ex));
    await _emit(logged);
    await widget.onDropSetsChanged?.call(List<dynamic>.from(drops));
    await widget.onAnalysisStateChanged?.call(_analysisWithout(n, shift: true));
  }

  // ---------- analysis ----------

  Map? _analysisFor(int setNumber) {
    for (final e in widget.analysisState ?? const []) {
      if (e is! Map || _asInt(e['exerciseId']) != widget.exerciseId) continue;
      final sets = e['sets'];
      if (sets is! List) return null;
      for (final s in sets) {
        if (s is Map && _asInt(s['setNumber']) == setNumber) return s;
      }
      return null;
    }
    return null;
  }

  double? _scoreOf(Map? a) {
    final an = a?['analysis'];
    if (an is! Map) return null;
    return _asDoubleN(an['technique_score'] ??
        an['score'] ??
        an['form_score'] ??
        an['overall_score']);
  }

  bool _lockFor(int setNumber) {
    try {
      return shouldShowLockButton(widget.analysisState ?? const [],
          widget.exerciseId, setNumber, widget.isPremium, widget.analysisCount);
    } catch (_) {
      return false;
    }
  }

  Future<void> _analyze(int setNumber, FFUploadedFile video, String lang) {
    return _Analysis.run(
      exerciseId: widget.exerciseId,
      setNumber: setNumber,
      video: video,
      nameEn: _nameEn,
      displayName: _displayName(lang),
    );
  }

  Future<void> _openCamera(int setNumber) async {
    if (!mounted) return;
    final String lang = _langOf(context);
    final nav = Navigator.of(context, rootNavigator: true);
    await nav.push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (ctx, a, b) => _CameraPage(
          exerciseNameEn: _nameEn,
          showGuidance: widget.showCameraGuidance ?? true,
          onDontShowAgain: widget.onDontShowAgain,
          onVideo: (file) async {
            _VideoStore.put(_jobKey(widget.exerciseId, setNumber), file);
            await _analyze(setNumber, file, lang);
          },
        ),
        transitionsBuilder: (ctx, anim, sec, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Future<void> _onErrorTap(int setNumber, String lang) async {
    final theme = FlutterFlowTheme.of(context);
    String msg;
    try {
      msg = getAnalysisErrorMessage(widget.analysisState ?? const [],
              widget.exerciseId, setNumber, _nameEn) ??
          '';
    } catch (_) {
      msg = '';
    }
    if (msg.trim().isEmpty) msg = _tr(lang, 'analysisFailed');
    final video = _VideoStore.get(_jobKey(widget.exerciseId, setNumber));
    final bool rtl = _kRtl.contains(lang);

    Widget btn(
        String label, Color bg, Color fg, FontWeight fw, VoidCallback onTap) {
      return Expanded(
        child: _Pressable(
          onTap: onTap,
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(12)),
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, fontWeight: fw, color: fg)),
          ),
        ),
      );
    }

    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = dark ? const Color(0xFF1E2731) : Colors.white;
    final Color textColor = dark ? Colors.white : const Color(0xFF1A202C);
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) => Directionality(
        textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF59E0B).withOpacity(0.15),
                    border:
                        Border.all(color: const Color(0xFFF59E0B), width: 2),
                  ),
                  child: const Icon(Icons.priority_high_rounded,
                      size: 22, color: Color(0xFFF59E0B)),
                ),
                Text(msg,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: textColor, fontSize: 15, height: 1.4)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    btn(_tr(lang, 'retry'), theme.primary, Colors.white,
                        FontWeight.w700, () async {
                      Navigator.of(ctx).pop();
                      if (video != null) {
                        await _analyze(setNumber, video, lang);
                      } else {
                        await _openCamera(setNumber);
                      }
                    }),
                    const SizedBox(width: 10),
                    btn(_tr(lang, 'retake'), textColor.withOpacity(0.08),
                        textColor, FontWeight.w600, () async {
                      Navigator.of(ctx).pop();
                      await _openCamera(setNumber);
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- toast ----------

  void _showToast(String text, String lang) {
    _hideToast();
    final overlay = Overlay.of(context, rootOverlay: true);
    final bool rtl = _kRtl.contains(lang);
    _toast = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: Align(
          alignment: Alignment.center,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Directionality(
                textDirection:
                    rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2731),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.35)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _hideToast,
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).primary,
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(_tr(lang, 'close'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_toast!);
    _toastTimer = Timer(const Duration(milliseconds: 2200), _hideToast);
  }

  void _hideToast() {
    _toastTimer?.cancel();
    _toastTimer = null;
    _toast?.remove();
    _toast = null;
  }

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final String lang = _langOf(context);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final tpl = _template;
    _Analysis.latest = widget.analysisState ?? const [];
    if (widget.onAnalysisStateChanged != null)
      _Analysis.emit = widget.onAnalysisStateChanged;

    final Color text = theme.primaryText;
    final Color muted = theme.secondaryText;
    final Color accent = theme.primary;
    final Color doneBg = theme.accent2;
    final Color zebraA =
        dark ? const Color(0xFF1F2933) : const Color(0xFFF3F4F6);
    final Color zebraB =
        dark ? const Color(0xFF242F3D) : const Color(0xFFF9FAFB);
    final Color onDone =
        dark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E);
    final Color cellBg = dark ? const Color(0xFF141A21) : Colors.white;

    final List<Widget> rows = [];

    if (widget.showHeaders && tpl.isNotEmpty) {
      rows.add(Container(
        height: 20, // fixed so the table height is predictable
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 2),
        child: Row(
          children: [
            const SizedBox(width: _colNum),
            const SizedBox(width: _gap),
            Expanded(child: _hdr(_tr(lang, 'hPrev'), muted)),
            const SizedBox(width: _gap),
            if (widget.isTimed)
              SizedBox(width: _colTime, child: _hdr(_tr(lang, 'hTime'), muted))
            else ...[
              SizedBox(width: _colVal, child: _hdr(_tr(lang, 'hReps'), muted)),
              const SizedBox(width: _gap),
              SizedBox(
                  width: _colVal,
                  child: _hdr(
                      '${_tr(lang, 'hWeight')} (${_tr(lang, widget.isKg ? 'kg' : 'lbs').toLowerCase()})',
                      muted)),
            ],
            if (widget.aiEnabled) ...[
              const SizedBox(width: _gap),
              SizedBox(width: _colAct),
            ] else
              SizedBox(width: _tail),
          ],
        ),
      ));
    }

    final warm = _warmSets();
    for (int i = 0; i < warm.length; i++) {
      rows.add(_warmBlock(warm[i], i == warm.length - 1, lang, dark, text,
          muted, accent, doneBg, onDone, i.isEven ? zebraB : zebraA, cellBg));
    }

    for (final t in tpl) {
      final bool done = _isDone(t.setNumber);
      final bool skipped = !done && _isSkipped(t.setNumber);
      final Color bg = done ? doneBg : (t.setNumber % 2 == 0 ? zebraA : zebraB);
      final bool unmarkOpen = done && _unmarkOpen.contains(t.setNumber);
      final Widget rowPart = widget.isTimed
          ? _timedRow(t, done, lang, dark, text, muted, accent)
          : _repsRow(t, done, lang, dark, text, muted, accent);
      final Widget block = Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: done
              ? Border.all(
                  color:
                      dark ? const Color(0xFF2A3644) : const Color(0xFFE3E7EB))
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A done row is tinted on its own; tapping it reveals the unmark strip.
            done
                ? GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => setState(() {
                      if (!_unmarkOpen.remove(t.setNumber))
                        _unmarkOpen.add(t.setNumber);
                    }),
                    child: rowPart,
                  )
                : rowPart,
            if (!widget.isTimed)
              ..._dropRows(
                  t, done, lang, dark, text, muted, accent, cellBg, onDone),
            if (!done) _completeBar(t, lang, doneBg, onDone),
            if (unmarkOpen) _unmarkStrip(t, muted, cellBg),
          ],
        ),
      );
      rows.add(Opacity(opacity: skipped ? 0.45 : 1.0, child: block));
    }

    _reportHeight(tpl);

    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: SizedBox(
        width: widget.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < rows.length; i++) ...[
              rows[i],
              if (i < rows.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  /// The height this build will take, from the same rules the layout uses.
  double _tableHeight(List<_TplSet> tpl) {
    final int warm = _warmSets().length;
    if (tpl.isEmpty && warm == 0) return 0;
    double h = widget.showHeaders ? 20 : 0;
    h += (tpl.length + warm - 1) * 8.0;
    for (final w in _warmSets()) {
      h += _rowH + _barH + (_truthy(w['isDone']) ? 2 : 0);
    }
    for (final t in tpl) {
      final bool done = _isDone(t.setNumber);
      final int drops = widget.isTimed ? 0 : _plannedDrops(t.setNumber).length;
      h += _rowH + drops * 48.0;
      if (done) {
        h += 2; // border
        if (_unmarkOpen.contains(t.setNumber)) h += _unmarkH;
      } else {
        h += _barH;
        if (drops > 0) h += 36; // "Add drop" line
      }
    }
    return h;
  }

  void _reportHeight(List<_TplSet> tpl) {
    if (widget.onHeightChanged == null) return;
    final double h = _tableHeight(tpl);
    if ((h - _lastHeight).abs() < 0.5) return;
    _lastHeight = h;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onHeightChanged?.call(h);
    });
  }

  Widget _hdr(String s, Color c) => Text(s,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c));

  // ---------- reps row ----------

  Widget _repsRow(_TplSet t, bool done, String lang, bool dark, Color text,
      Color muted, Color accent) {
    final base = _base(t.setNumber);
    final int? reps = _asIntN(base?['reps']);
    final double? weight = _asDoubleN(base?['weight']);

    return SizedBox(
      height: _rowH,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            SizedBox(
                width: _colNum,
                child: Center(child: _numberPill(t, done, dark, text, lang))),
            const SizedBox(width: _gap),
            Expanded(child: _previousCell(t, done, lang, muted)),
            const SizedBox(width: _gap),
            SizedBox(
              width: _colVal,
              child: _RepsCell(
                value: reps,
                hint: _repsHint(t),
                isDone: done,
                lang: lang,
                dark: dark,
                textColor: text,
                hintColor: muted.withOpacity(0.5),
                focusColor: accent,
                onCommit: (v) => _emit(_upsertBase(_copyLogged(), t,
                    reps: v, clearReps: v == null)),
              ),
            ),
            const SizedBox(width: _gap),
            SizedBox(
              width: _colVal,
              child:
                  !_canWeight(t) || (done && _plusMode(t) && (weight ?? 0) <= 0)
                      ? Center(
                          child: Text('-',
                              style: TextStyle(fontSize: 17, color: muted)))
                      : _WeightCell(
                          value: weight,
                          hint: _plusMode(t) ? 0 : _weightHint(t),
                          isDone: done,
                          isKg: widget.isKg,
                          plusMode: _plusMode(t),
                          lang: lang,
                          dark: dark,
                          textColor: text,
                          hintColor: muted.withOpacity(0.5),
                          focusColor: accent,
                          onCommit: (v) => _emit(_upsertBase(_copyLogged(), t,
                              weight: v, clearWeight: v == null)),
                        ),
            ),
            if (widget.aiEnabled) ...[
              const SizedBox(width: _gap),
              SizedBox(
                  width: _colAct,
                  child: _analysisCell(t, done, lang, accent, dark)),
            ] else
              SizedBox(width: _tail),
          ],
        ),
      ),
    );
  }

  Widget _numberPill(_TplSet t, bool done, bool dark, Color text, String lang) {
    if (done) {
      // Not tappable on a completed set (like the original).
      return Text('${t.setNumber}',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: dark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E)));
    }
    return _SetPill(
      label: '${t.setNumber}',
      textColor: text,
      fillColor: dark ? const Color(0xFF141A21) : Colors.white,
      borderColor: dark ? const Color(0xFF2A3644) : const Color(0xFFE3E7EB),
      onTap: () => _openSetMenu(t, lang),
    );
  }

  Widget _previousCell(_TplSet t, bool done, String lang, Color muted) {
    final String label = _prevLabel(lang, t.setNumber);
    final Widget txt = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          _ltr(label),
          maxLines: 1,
          textDirection: ui.TextDirection.ltr,
          style: TextStyle(
              fontSize: 16, color: muted, fontWeight: FontWeight.w400),
        ),
      ),
    );
    if (done || label == '-' || label.isEmpty) return Center(child: txt);
    return _Pressable(
        onTap: () => _applyPrevious(t), child: Center(child: txt));
  }

  // ---------- timed row ----------

  Widget _timedRow(_TplSet t, bool done, String lang, bool dark, Color text,
      Color muted, Color accent) {
    final int loggedMs = _loggedMs(t.setNumber);
    final job = done ? null : _jobFor(t);

    return SizedBox(
      height: _rowH,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            SizedBox(
                width: _colNum,
                child: Center(child: _numberPill(t, done, dark, text, lang))),
            const SizedBox(width: _gap),
            Expanded(child: _previousCell(t, done, lang, muted)),
            const SizedBox(width: _gap),
            SizedBox(
              width: _colTime,
              child: done || job == null
                  ? Center(
                      child: Text(_mmss(loggedMs),
                          textDirection: ui.TextDirection.ltr,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: text)),
                    )
                  : _TimeCell(
                      job: job,
                      loggedMs: loggedMs,
                      targetMs: t.durationSec * 1000,
                      lang: lang,
                      dark: dark,
                      textColor: text,
                      hintColor: muted.withOpacity(0.5),
                      accent: accent,
                      onModeChanged: (m) => _setMode(t, m),
                      onManualChanged: (ms) => _commitDuration(t, ms),
                    ),
            ),
            if (widget.aiEnabled) ...[
              const SizedBox(width: _gap),
              SizedBox(
                  width: _colAct,
                  child: _analysisCell(t, done, lang, accent, dark)),
            ] else
              SizedBox(width: _tail),
          ],
        ),
      ),
    );
  }

  // ---------- drops ----------

  List<Widget> _dropRows(_TplSet t, bool done, String lang, bool dark,
      Color text, Color muted, Color accent, Color cellBg, Color onDone) {
    final planned = _plannedDrops(t.setNumber);
    if (planned.isEmpty) return const [];
    final double? baseW = _asDoubleN(_base(t.setNumber)?['weight']);
    final Color rowBg = done ? Colors.transparent : cellBg;

    final List<Widget> out = [];
    for (final d in planned) {
      final int order = _asInt(d['dropOrder']);
      final logged = _loggedDrop(t.setNumber, order);
      final int? reps = _asIntN(logged?['reps']);
      final double? w = _asDoubleN(logged?['weight']);
      final int repsHint = _asInt(d['reps']);
      final double wHint = _asDoubleN(d['weight']) ?? 0;
      final double? shownW = (w ?? 0) > 0 ? w : (wHint > 0 ? wHint : null);
      String pct = '';
      if (baseW != null && baseW > 0 && shownW != null && shownW > 0) {
        final p = ((1 - shownW / baseW) * 100).round();
        pct = p > 0 ? '−$p%' : (p < 0 ? '+${-p}%' : '0%');
      }

      out.add(Padding(
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
              color: rowBg, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              SizedBox(
                width: _colNum,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.subdirectory_arrow_right_rounded,
                          size: 13, color: onDone),
                      const SizedBox(width: 2),
                      Text('D$order',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: onDone)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: Center(
                  child: Text(_ltr(pct),
                      maxLines: 1,
                      style: TextStyle(fontSize: 13, color: muted)),
                ),
              ),
              const SizedBox(width: _gap),
              SizedBox(
                width: _colVal,
                child: _RepsCell(
                  value: reps,
                  hint: repsHint,
                  isDone: done,
                  lang: lang,
                  dark: dark,
                  textColor: text,
                  hintColor: muted.withOpacity(0.5),
                  focusColor: accent,
                  onCommit: (v) => _emit(_upsertDrop(
                      _copyLogged(), t.setNumber, order,
                      reps: v, keepWeight: true)),
                ),
              ),
              const SizedBox(width: _gap),
              SizedBox(
                width: _colVal,
                child: !_canWeight(t) || (done && _plusMode(t) && (w ?? 0) <= 0)
                    ? Center(
                        child: Text('-',
                            style: TextStyle(fontSize: 16, color: muted)))
                    : _WeightCell(
                        value: w,
                        hint: wHint,
                        isDone: done,
                        isKg: widget.isKg,
                        plusMode: _plusMode(t),
                        lang: lang,
                        dark: dark,
                        textColor: text,
                        hintColor: muted.withOpacity(0.5),
                        focusColor: accent,
                        onCommit: (v) => _emit(_upsertDrop(
                            _copyLogged(), t.setNumber, order,
                            weight: v, keepReps: true)),
                      ),
              ),
              const SizedBox(width: _gap),
              SizedBox(
                width: widget.aiEnabled ? _colAct : 44 + _tail - _gap,
                child: done
                    ? const SizedBox.shrink()
                    : Center(
                        child: _Pressable(
                          onTap: () => _deleteDrop(t, order),
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(Icons.delete_outline_rounded,
                                size: 18, color: muted),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ));
    }

    if (!done) {
      out.add(Padding(
        padding: const EdgeInsets.fromLTRB(60, 0, 6, 6),
        child: SizedBox(
          height:
              30, // fixed so the table height is predictable (36 with padding)
          child: Align(
            alignment: Alignment.centerLeft,
            child: _Pressable(
              onTap: () => _addDrop(t),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: onDone),
                    const SizedBox(width: 4),
                    Text(_tr(lang, 'addDrop'),
                        maxLines: 1,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: onDone)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ));
    }
    return out;
  }

  // ---------- bars ----------

  Widget _completeBar(_TplSet t, String lang, Color doneBg, Color fg) {
    final int rest = _restMs();
    return _Pressable(
      onTap: () => _complete(t, lang),
      child: Container(
        height: _barH,
        color: doneBg,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_rounded, size: 18, color: fg),
            if (rest > 0) ...[
              const SizedBox(width: 8),
              Text('+ ${_mmss(rest)}',
                  textDirection: ui.TextDirection.ltr,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
            ],
          ],
        ),
      ),
    );
  }

  /// Shown under a completed row after tapping it: the "unmark" icon.
  Widget _unmarkStrip(_TplSet t, Color fg, Color bg) {
    return _Pressable(
      onTap: () {
        _unmarkOpen.remove(t.setNumber);
        _unmark(t);
      },
      child: Container(
        height: _unmarkH,
        color: bg,
        child:
            Center(child: Icon(Icons.remove_done_rounded, size: 20, color: fg)),
      ),
    );
  }

  // ---------- analysis cell ----------

  Widget _analysisCell(
      _TplSet t, bool done, String lang, Color accent, bool dark) {
    if (!widget.aiEnabled) return const SizedBox.shrink();
    final a = _analysisFor(t.setNumber);
    final bool processing = _truthy(a?['isProcessing']);
    final bool hasError = _truthy(a?['hasError']);
    final bool analysisDone = _truthy(a?['analysisDone']);
    final double? score = analysisDone ? _scoreOf(a) : null;

    Widget child;
    if (processing) {
      child = _Sparkle(color: accent);
    } else if (analysisDone) {
      double s10 = score ?? 0;
      if (s10 > 10) s10 = s10 / 10; // 0-100 → 0-10
      child = AiScoreRing(
        score: s10,
        size: 40,
        onTap: () async => widget.onResultTap?.call(t.setNumber,
            _VideoStore.get(_jobKey(widget.exerciseId, t.setNumber))),
      );
    } else if (hasError) {
      child = _Pressable(
        onTap: () => _onErrorTap(t.setNumber, lang),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF59E0B).withOpacity(dark ? 0.18 : 0.12),
            border: Border.all(color: const Color(0xFFF59E0B), width: 2),
          ),
          child: const Icon(Icons.priority_high_rounded,
              size: 20, color: Color(0xFFD97706)),
        ),
      );
    } else if (done) {
      // Completed without an analysis: nothing to show.
      child = const SizedBox.shrink();
    } else if (_lockFor(t.setNumber)) {
      child = _Pressable(
        onTap: () => widget.onLockTap?.call(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent.withOpacity(0.5), width: 2),
          ),
          child: Icon(Icons.lock_rounded, size: 18, color: accent),
        ),
      );
    } else {
      child =
          AiFormButton(size: 40, onTap: () async => _openCamera(t.setNumber));
    }
    return Center(child: child);
  }
}

// =============================================================================
// Small visual atoms
// =============================================================================

/// Scale + fade feedback without Material ink.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;
  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedOpacity(
        opacity: _down ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedScale(
          scale: _down ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Set-number pill: number + chevron, opens the FF set menu.
class _SetPill extends StatelessWidget {
  const _SetPill({
    required this.label,
    required this.textColor,
    required this.fillColor,
    required this.borderColor,
    required this.onTap,
  });
  final String label;
  final Color textColor, fillColor, borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 30,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          textDirection: ui.TextDirection.ltr,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                textDirection: ui.TextDirection.ltr,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor)),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 13, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

/// Camera button: video icon with a small sparkle.
class _CameraButton extends StatelessWidget {
  const _CameraButton({required this.color, required this.onTap});
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(Icons.video_call_outlined, size: 24, color: color),
          ),
        ),
      ),
    );
  }
}

/// "Analyzing" indicator: pulsing sparkle.
class _Sparkle extends StatefulWidget {
  const _Sparkle({required this.color});
  final Color color;
  @override
  State<_Sparkle> createState() => _SparkleState();
}

class _SparkleState extends State<_Sparkle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final double t = _c.value;
          final double pulse = 0.85 + 0.15 * math.sin(t * math.pi * 2);
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: t * math.pi * 2,
                child: CustomPaint(
                  size: const Size(36, 36),
                  painter: _ArcPainter(
                    color: widget.color.withOpacity(0.9),
                    track: widget.color.withOpacity(0.15),
                    fraction: 0.28,
                    stroke: 2.5,
                  ),
                ),
              ),
              Transform.scale(
                scale: pulse,
                child: Icon(Icons.auto_awesome, size: 16, color: widget.color),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Score ring with the score inside (accepts 0–10 or 0–100).
class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    required this.score,
    required this.textColor,
    required this.trackColor,
    required this.onTap,
  });
  final double score;
  final Color textColor, trackColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double frac =
        (score > 10 ? score / 100 : score / 10).clamp(0.0, 1.0).toDouble();
    const Color c = Color(0xFF14B8A6);
    final bool noScore = score < 0;
    final String label = noScore
        ? ''
        : (score == score.roundToDouble()
            ? score.toInt().toString()
            : score.toStringAsFixed(1));
    return _Pressable(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: const Size(38, 38),
              painter: _ArcPainter(
                  color: c,
                  track: trackColor,
                  fraction: noScore ? 1 : frac,
                  stroke: 3),
            ),
            if (noScore) const Icon(Icons.check_rounded, size: 18, color: c),
            if (!noScore)
              Text(label,
                  textDirection: ui.TextDirection.ltr,
                  style: TextStyle(
                      fontSize: label.length > 2 ? 12 : 15,
                      fontWeight: FontWeight.w700,
                      color: textColor)),
            const Positioned(
              right: -3,
              top: -3,
              child: Icon(Icons.auto_awesome, size: 13, color: c),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(
      {required this.color,
      required this.track,
      required this.fraction,
      required this.stroke});
  final Color color, track;
  final double fraction, stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final bg = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, bg);
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * fraction, false, fg);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter o) =>
      o.color != color ||
      o.track != track ||
      o.fraction != fraction ||
      o.stroke != stroke;
}

// =============================================================================
// Camera route — the recorder gets the ENGLISH name.
// =============================================================================

class _CameraPage extends StatelessWidget {
  const _CameraPage({
    required this.exerciseNameEn,
    required this.showGuidance,
    required this.onDontShowAgain,
    required this.onVideo,
  });
  final String exerciseNameEn;
  final bool showGuidance;
  final Future Function()? onDontShowAgain;
  final Future<void> Function(FFUploadedFile file) onVideo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: XliftCameraRecorder(
        width: double.infinity,
        height: double.infinity,
        exerciseName: exerciseNameEn,
        showGuidance: showGuidance,
        onClose: () async => Navigator.of(context).pop(),
        onDontShowAgain: onDontShowAgain,
        onVideoRecorded: (FFUploadedFile videoFile) async {
          Navigator.of(context).pop();
          await onVideo(videoFile);
        },
      ),
    );
  }
}

// =============================================================================
// Pad plumbing shared by the reps / weight / time cells: an overlay sheet that
// slides up like the keyboard, with no barrier — a tap outside closes it AND
// reaches whatever was tapped.
// =============================================================================

mixin _PadHost<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  OverlayEntry? _padEntry;
  bool _closing = false;
  bool editing = false;
  double _padHeight = 0;

  late final AnimationController slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 200),
  );
  late final Animation<Offset> slideOffset = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: slide,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  ));

  bool _hitsSelf(Offset globalPos) {
    try {
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) return false;
      return box.size.contains(box.globalToLocal(globalPos));
    } catch (_) {
      return false;
    }
  }

  void _scrollClearOfPad() {
    try {
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) return;
      final media = MediaQuery.of(context);
      final double padH =
          _padHeight > 0 ? _padHeight : 300 + media.padding.bottom;
      final double padTop = media.size.height - padH;
      final double fieldBottom =
          box.localToGlobal(Offset(0, box.size.height)).dy;
      final double delta = fieldBottom - (padTop - 10);
      if (delta <= 0.5) return;
      ScrollableState? scroll = Scrollable.maybeOf(context);
      int hops = 0;
      while (scroll != null && hops < 6) {
        final pos = scroll.position;
        if (pos.axis == Axis.vertical && pos.maxScrollExtent > 0) break;
        scroll = Scrollable.maybeOf(scroll.context);
        hops++;
      }
      if (scroll == null) return;
      final pos = scroll.position;
      final double target = (pos.pixels + delta)
          .clamp(pos.minScrollExtent, pos.maxScrollExtent)
          .toDouble();
      if ((target - pos.pixels).abs() < 1) return;
      pos.animateTo(target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic);
    } catch (_) {}
  }

  void onPadMeasured(double h) {
    if ((h - _padHeight).abs() < 1) return;
    _padHeight = h;
    _scrollClearOfPad();
  }

  void openPad(Widget Function() sheetBuilder) {
    if (editing) return;
    HapticFeedback.selectionClick();
    if (_padEntry != null) {
      _padEntry!.remove();
      _padEntry = null;
      _closing = false;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    } catch (_) {}
    setState(() => editing = true);
    _scrollClearOfPad();
    _padEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (e) {
                if (_hitsSelf(e.position)) return;
                closePad();
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: slideOffset,
              child: Listener(
                  behavior: HitTestBehavior.opaque, child: sheetBuilder()),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_padEntry!);
    slide.forward(from: 0);
  }

  Future<void> closePad() async {
    if (_padEntry == null || _closing) return;
    _closing = true;
    if (mounted && editing) setState(() => editing = false);
    try {
      await slide.reverse().orCancel;
    } catch (_) {}
    final entry = _padEntry;
    _padEntry = null;
    entry?.remove();
    _closing = false;
  }

  void disposePad() {
    _padEntry?.remove();
    _padEntry = null;
    slide.dispose();
  }
}

/// Blinking caret while a cell is being edited.
class _Caret extends StatefulWidget {
  const _Caret({required this.color, required this.height});
  final Color color;
  final double height;
  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> {
  bool _on = true;
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _on = !_on);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: _on ? 1 : 0,
        child: Container(
          width: 2,
          height: widget.height,
          decoration: BoxDecoration(
              color: widget.color, borderRadius: BorderRadius.circular(1)),
        ),
      );
}

/// Sheet chrome colors.
class _PadColors {
  _PadColors(bool dark)
      : accent = dark ? const Color(0xFF2DD4BF) : const Color(0xFF14B8A6),
        sheetBg = dark ? const Color(0xFF141A21) : Colors.white,
        keyBg = dark ? const Color(0xFF1E2731) : const Color(0xFFF0F2F5),
        keyPressedBg = dark ? const Color(0xFF2A3644) : const Color(0xFFD5DAE1),
        text = dark ? Colors.white : const Color(0xFF1A202C),
        shadow = Colors.black.withOpacity(dark ? 0.5 : 0.15);
  final Color accent, sheetBg, keyBg, keyPressedBg, text, shadow;
}

Widget _sheetShell(
    _PadColors c, GlobalKey key, double bottomInset, List<Widget> children) {
  return Material(
    color: Colors.transparent,
    child: Container(
      key: key,
      decoration: BoxDecoration(
        color: c.sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
              color: c.shadow, blurRadius: 18, offset: const Offset(0, -4))
        ],
      ),
      padding: EdgeInsets.fromLTRB(10, 8, 10, 6 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
                color: c.text.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2)),
          ),
          ...children,
        ],
      ),
    ),
  );
}

/// Small side button (−1 / +2.5 / reset …). Fires on pointer down.
Widget _stepBtn(_PadColors c, VoidCallback onTap,
    {String? label, IconData? icon}) {
  return Listener(
    behavior: HitTestBehavior.opaque,
    onPointerDown: (_) => onTap(),
    child: Container(
      width: 58,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: c.keyBg, borderRadius: BorderRadius.circular(10)),
      child: icon != null
          ? Icon(icon, size: 20, color: c.accent)
          : Text(label ?? '',
              textDirection: ui.TextDirection.ltr,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: c.accent)),
    ),
  );
}

/// One numpad key (inside an Expanded).
Widget _numKey(
  _PadColors c, {
  required String shown,
  required bool enabled,
  required bool pressed,
  required VoidCallback onDown,
  required VoidCallback onUp,
  Widget? child,
  bool accentText = false,
}) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.all(3),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.30,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: enabled ? (_) => onDown() : null,
          onPointerUp: (_) => onUp(),
          onPointerCancel: (_) => onUp(),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
                color: pressed ? c.keyPressedBg : c.keyBg,
                borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: child ??
                  Text(shown,
                      textDirection: ui.TextDirection.ltr,
                      style: TextStyle(
                          fontSize: shown.length > 1 ? 19 : 21,
                          fontWeight: FontWeight.w600,
                          color: accentText ? c.accent : c.text)),
            ),
          ),
        ),
      ),
    ),
  );
}

void _measureAfterFrame(GlobalKey key, void Function(double h) onMeasured) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) onMeasured(box.size.height);
  });
}

// =============================================================================
// Reps cell + pad
// =============================================================================

class _RepsCell extends StatefulWidget {
  const _RepsCell({
    required this.value,
    required this.hint,
    required this.isDone,
    required this.lang,
    required this.dark,
    required this.textColor,
    required this.hintColor,
    required this.focusColor,
    required this.onCommit,
  });
  final int? value;
  final int hint;
  final bool isDone;
  final String lang;
  final bool dark;
  final Color textColor, hintColor, focusColor;
  final Future<void> Function(int? v) onCommit;

  @override
  State<_RepsCell> createState() => _RepsCellState();
}

class _RepsCellState extends State<_RepsCell>
    with SingleTickerProviderStateMixin, _PadHost<_RepsCell> {
  int? _typed;
  bool _hasTyped = false;

  int? get _shown => _hasTyped ? _typed : widget.value;

  @override
  void didUpdateWidget(covariant _RepsCell old) {
    super.didUpdateWidget(old);
    if (!editing && _hasTyped && widget.value == _typed) _hasTyped = false;
    if (!editing && _hasTyped && widget.value == null && _typed != null) {
      _typed = null;
      _hasTyped = false;
    }
  }

  @override
  void dispose() {
    disposePad();
    super.dispose();
  }

  void _commit(int? v) {
    setState(() {
      _typed = v;
      _hasTyped = true;
    });
    widget.onCommit(v);
  }

  void _open() {
    openPad(() => _RepsPadSheet(
          initial: _shown,
          stepBase: widget.hint,
          colors: _PadColors(widget.dark),
          rtl: _kRtl.contains(widget.lang),
          label: _tr(widget.lang, 'reps'),
          onChanged: _commit,
          onMeasured: onPadMeasured,
        ));
  }

  void _tap() {
    if (editing) {
      closePad();
    } else {
      _open();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool done = widget.isDone;
    final String text = _shown == null ? '' : '$_shown';
    final bool empty = text.isEmpty;
    final bool caretAlone = editing && empty;
    final String display = caretAlone
        ? ''
        : ((done && empty) ? '-' : (empty ? '${widget.hint}' : text));
    final Color color = empty ? widget.hintColor : widget.textColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: done ? null : _tap,
      child: Container(
        height: 40,
        decoration: editing
            ? BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: widget.focusColor, width: 2)))
            : null,
        child: Center(
          child: Row(
            textDirection: ui.TextDirection.ltr,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (display.isNotEmpty)
                Text(display,
                    textDirection: ui.TextDirection.ltr,
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                        color: color)),
              if (editing)
                Padding(
                  padding: EdgeInsets.only(left: display.isNotEmpty ? 1.5 : 0),
                  child: _Caret(color: widget.focusColor, height: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RepsPadSheet extends StatefulWidget {
  const _RepsPadSheet({
    required this.initial,
    required this.stepBase,
    required this.colors,
    required this.rtl,
    required this.label,
    required this.onChanged,
    required this.onMeasured,
  });
  final int? initial;
  final int stepBase;
  final _PadColors colors;
  final bool rtl;
  final String label;
  final void Function(int? value) onChanged;
  final void Function(double height) onMeasured;
  @override
  State<_RepsPadSheet> createState() => _RepsPadSheetState();
}

class _RepsPadSheetState extends State<_RepsPadSheet> {
  late String _text;
  String? _pressedKey;
  final GlobalKey _rootKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _text = widget.initial == null ? '' : widget.initial.toString();
    _measureAfterFrame(_rootKey, widget.onMeasured);
  }

  bool _canPress(String k) =>
      (_text + k).length <= 3 && !(_text.isEmpty && k == '0');
  int? _val() => _text.isEmpty ? null : int.tryParse(_text);
  void _emit() => widget.onChanged(_val());

  void _down(String keyId) {
    if (keyId == 'back') {
      if (_text.isEmpty) return;
      HapticFeedback.selectionClick();
      setState(() {
        _pressedKey = 'back';
        _text = _text.substring(0, _text.length - 1);
      });
      _emit();
      return;
    }
    if (!_canPress(keyId)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pressedKey = keyId;
      _text = _text + keyId;
    });
    _emit();
  }

  void _up() => setState(() => _pressedKey = null);

  void _stepBy(int delta) {
    HapticFeedback.selectionClick();
    final int next =
        ((_val() ?? widget.stepBase) + delta).clamp(0, 999).toInt();
    setState(() => _text = next == 0 ? '' : next.toString());
    _emit();
  }

  Widget _k(String d) => _numKey(widget.colors,
      shown: d,
      enabled: d.isNotEmpty && _canPress(d),
      pressed: _pressedKey == d,
      onDown: () => _down(d),
      onUp: _up);

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final ui.TextDirection dir =
        widget.rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr;
    final display = _text.isEmpty ? '0' : _text;
    return _sheetShell(c, _rootKey, MediaQuery.of(context).padding.bottom, [
      Row(
        textDirection: dir,
        children: [
          _stepBtn(c, () => _stepBy(-1), label: '-1'),
          Expanded(
            child: Row(
              textDirection: dir,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(display,
                    textDirection: ui.TextDirection.ltr,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        color: c.text)),
                const SizedBox(width: 4),
                Text(widget.label,
                    textDirection: dir,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.accent)),
              ],
            ),
          ),
          _stepBtn(c, () => _stepBy(1), label: '+1'),
        ],
      ),
      const SizedBox(height: 6),
      Row(
          textDirection: ui.TextDirection.ltr,
          children: [_k('1'), _k('2'), _k('3')]),
      Row(
          textDirection: ui.TextDirection.ltr,
          children: [_k('4'), _k('5'), _k('6')]),
      Row(
          textDirection: ui.TextDirection.ltr,
          children: [_k('7'), _k('8'), _k('9')]),
      Row(textDirection: ui.TextDirection.ltr, children: [
        _numKey(c,
            shown: '',
            enabled: false,
            pressed: false,
            onDown: () {},
            onUp: () {}),
        _k('0'),
        _numKey(c,
            shown: '',
            enabled: _text.isNotEmpty,
            pressed: _pressedKey == 'back',
            onDown: () => _down('back'),
            onUp: _up,
            child: Icon(Icons.backspace_outlined, size: 21, color: c.text)),
      ]),
    ]);
  }
}

// =============================================================================
// Weight cell + pad
// =============================================================================

class _WeightCell extends StatefulWidget {
  const _WeightCell({
    required this.value,
    required this.hint,
    required this.isDone,
    required this.isKg,
    required this.plusMode,
    required this.lang,
    required this.dark,
    required this.textColor,
    required this.hintColor,
    required this.focusColor,
    required this.onCommit,
  });
  final double? value;
  final double hint;
  final bool isDone;
  final bool isKg;
  final bool plusMode;
  final String lang;
  final bool dark;
  final Color textColor, hintColor, focusColor;
  final Future<void> Function(double? v) onCommit;
  @override
  State<_WeightCell> createState() => _WeightCellState();
}

class _WeightCellState extends State<_WeightCell>
    with SingleTickerProviderStateMixin, _PadHost<_WeightCell> {
  double? _typed;
  bool _hasTyped = false;

  double? get _shown => _hasTyped ? _typed : widget.value;

  @override
  void didUpdateWidget(covariant _WeightCell old) {
    super.didUpdateWidget(old);
    if (!editing && _hasTyped && widget.value == _typed) _hasTyped = false;
    if (!editing && _hasTyped && old.value != null && widget.value == null) {
      _typed = null;
      _hasTyped = false;
    }
  }

  @override
  void dispose() {
    disposePad();
    super.dispose();
  }

  void _commit(double? v) {
    setState(() {
      _typed = v;
      _hasTyped = true;
    });
    widget.onCommit(v);
  }

  void _clear() {
    HapticFeedback.selectionClick();
    setState(() {
      _typed = null;
      _hasTyped = false;
    });
    widget.onCommit(null);
    closePad();
  }

  void _open() {
    // "+" tapped on a bodyweight exercise: adopt the hint weight right away.
    if (widget.plusMode && _shown == null && widget.hint > 0)
      _commit(widget.hint);
    openPad(() => _WeightPadSheet(
          initial: _shown,
          isKg: widget.isKg,
          colors: _PadColors(widget.dark),
          rtl: _kRtl.contains(widget.lang),
          unitLabel: _tr(widget.lang, widget.isKg ? 'kg' : 'lbs'),
          noWeightLabel: _tr(widget.lang, 'noWeight'),
          step: widget.isKg ? 2.5 : 5.0,
          bodyweightMode: widget.plusMode,
          onChanged: _commit,
          onClearWeight: _clear,
          onMeasured: onPadMeasured,
        ));
  }

  void _tap() {
    if (editing) {
      closePad();
    } else {
      _open();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool done = widget.isDone;
    final String text = _fmtW(_shown);
    final bool empty = text.isEmpty;

    if (widget.plusMode && empty && !done && !editing) {
      return Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _open,
          child: Container(
            width: 34,
            height: 34,
            decoration:
                BoxDecoration(color: widget.focusColor, shape: BoxShape.circle),
            child: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
          ),
        ),
      );
    }

    final bool caretAlone = editing && empty;
    final String hint = widget.hint > 0 ? _fmtW(widget.hint) : '0';
    final String display =
        caretAlone ? '' : ((done && empty) ? '-' : (empty ? hint : text));
    final Color color = empty ? widget.hintColor : widget.textColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: done ? null : _tap,
      child: Container(
        height: 40,
        decoration: editing
            ? BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: widget.focusColor, width: 2)))
            : null,
        child: Center(
          child: Row(
            textDirection: ui.TextDirection.ltr,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (display.isNotEmpty)
                Text(display,
                    textDirection: ui.TextDirection.ltr,
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                        color: color)),
              if (editing)
                Padding(
                  padding: EdgeInsets.only(left: display.isNotEmpty ? 1.5 : 0),
                  child: _Caret(color: widget.focusColor, height: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeightPadSheet extends StatefulWidget {
  const _WeightPadSheet({
    required this.initial,
    required this.isKg,
    required this.colors,
    required this.rtl,
    required this.unitLabel,
    required this.noWeightLabel,
    required this.step,
    required this.bodyweightMode,
    required this.onChanged,
    required this.onClearWeight,
    required this.onMeasured,
  });
  final double? initial;
  final bool isKg;
  final _PadColors colors;
  final bool rtl;
  final String unitLabel, noWeightLabel;
  final double step;
  final bool bodyweightMode;
  final void Function(double? value) onChanged;
  final VoidCallback onClearWeight;
  final void Function(double height) onMeasured;
  @override
  State<_WeightPadSheet> createState() => _WeightPadSheetState();
}

class _WeightPadSheetState extends State<_WeightPadSheet> {
  late String _text;
  String? _pressedKey;
  final GlobalKey _rootKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _text = _fmtW(widget.initial);
    _measureAfterFrame(_rootKey, widget.onMeasured);
  }

  RegExp get _valid => widget.isKg
      ? RegExp(r'^\d{0,4}(\.(25|5|75)?)?$')
      : RegExp(r'^\d{0,4}(\.5?)?$');
  bool get _afterDot => _text.endsWith('.');
  double get _snapUnit => widget.isKg ? 0.25 : 0.5;
  double _snap(double v) => (v / _snapUnit).roundToDouble() * _snapUnit;
  bool _canPress(String k) => _valid.hasMatch(_text + k);

  /// After the dot, 2 → .25 and 7 → .75 (kg).
  String _mapKey(String label) {
    if (_afterDot && widget.isKg) {
      if (label == '2') return '25';
      if (label == '7') return '75';
    }
    return label;
  }

  double? _val() {
    String t = _text;
    if (t.endsWith('.')) t = t.substring(0, t.length - 1);
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    return v == null ? null : _snap(v);
  }

  void _emit() => widget.onChanged(_val());

  void _down(String keyId) {
    if (keyId == 'back') {
      if (_text.isEmpty) return;
      HapticFeedback.selectionClick();
      setState(() {
        _pressedKey = 'back';
        if (_text.endsWith('25') || _text.endsWith('75')) {
          final int dot = _text.lastIndexOf('.');
          _text = (dot >= 0 && _text.length - dot == 3)
              ? _text.substring(0, dot + 1)
              : _text.substring(0, _text.length - 1);
        } else {
          _text = _text.substring(0, _text.length - 1);
        }
      });
      _emit();
      return;
    }
    final String k = _mapKey(keyId);
    if (!_canPress(k)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pressedKey = keyId;
      _text = _text + k;
    });
    _emit();
  }

  void _up() => setState(() => _pressedKey = null);

  void _stepBy(double delta) {
    HapticFeedback.selectionClick();
    double next = (_val() ?? 0) + delta;
    if (next < 0) next = 0;
    setState(() => _text = _fmtW(_snap(next)));
    _emit();
  }

  Widget _k(String d) {
    final String shown = _mapKey(d);
    return _numKey(widget.colors,
        shown: shown,
        enabled: _canPress(shown),
        pressed: _pressedKey == d,
        onDown: () => _down(d),
        onUp: _up,
        accentText: shown.length > 1);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final ui.TextDirection dir =
        widget.rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr;
    final display = _text.isEmpty ? '0' : _text;
    return _sheetShell(c, _rootKey, MediaQuery.of(context).padding.bottom, [
      Row(
        textDirection: dir,
        children: [
          _stepBtn(c, () => _stepBy(-widget.step),
              label: '-${_fmtW(widget.step)}'),
          Expanded(
            child: Row(
              textDirection: dir,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(display,
                    textDirection: ui.TextDirection.ltr,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        color: c.text)),
                const SizedBox(width: 4),
                Text(widget.unitLabel,
                    textDirection: dir,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.accent)),
              ],
            ),
          ),
          _stepBtn(c, () => _stepBy(widget.step),
              label: '+${_fmtW(widget.step)}'),
        ],
      ),
      if (widget.bodyweightMode)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => widget.onClearWeight(),
            child: Container(
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  border: Border.all(color: c.accent.withOpacity(0.6)),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(widget.noWeightLabel,
                  textDirection: dir,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.accent)),
            ),
          ),
        ),
      const SizedBox(height: 6),
      Row(
          textDirection: ui.TextDirection.ltr,
          children: [_k('1'), _k('2'), _k('3')]),
      Row(
          textDirection: ui.TextDirection.ltr,
          children: [_k('4'), _k('5'), _k('6')]),
      Row(
          textDirection: ui.TextDirection.ltr,
          children: [_k('7'), _k('8'), _k('9')]),
      Row(textDirection: ui.TextDirection.ltr, children: [
        _k('.'),
        _k('0'),
        _numKey(c,
            shown: '',
            enabled: _text.isNotEmpty,
            pressed: _pressedKey == 'back',
            onDown: () => _down('back'),
            onUp: _up,
            child: Icon(Icons.backspace_outlined, size: 21, color: c.text)),
      ]),
    ]);
  }
}

// =============================================================================
// Time cell (timed exercises). The cell shows the time and a mini play/pause;
// tapping the digits opens one sheet with a Stopwatch / Countdown / Manual
// switch at the top.
// =============================================================================

class _TimeCell extends StatefulWidget {
  const _TimeCell({
    required this.job,
    required this.loggedMs,
    required this.targetMs,
    required this.lang,
    required this.dark,
    required this.textColor,
    required this.hintColor,
    required this.accent,
    required this.onModeChanged,
    required this.onManualChanged,
  });
  final _TimerJob job;
  final int loggedMs;
  final int targetMs;
  final String lang;
  final bool dark;
  final Color textColor, hintColor, accent;
  final void Function(_TimeMode m) onModeChanged;
  final Future<void> Function(int ms) onManualChanged;
  @override
  State<_TimeCell> createState() => _TimeCellState();
}

class _TimeCellState extends State<_TimeCell>
    with SingleTickerProviderStateMixin, _PadHost<_TimeCell> {
  @override
  void dispose() {
    disposePad();
    super.dispose();
  }

  void _openSheet() {
    if (editing) {
      closePad();
      return;
    }
    openPad(() => _TimeSheet(
          job: widget.job,
          colors: _PadColors(widget.dark),
          lang: widget.lang,
          loggedMs: widget.loggedMs,
          targetMs: widget.targetMs,
          onModeChanged: widget.onModeChanged,
          onManualChanged: widget.onManualChanged,
          onMeasured: onPadMeasured,
          onClose: closePad,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.job;
    final Color runningColor =
        widget.dark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E);

    return ValueListenableBuilder<int>(
      valueListenable: j.tick,
      builder: (_, __, ___) {
        final bool manual = j.mode == _TimeMode.manual;
        final bool running = j.running;
        int shown;
        bool isHint = false;
        if (manual) {
          shown = widget.loggedMs > 0 ? widget.loggedMs : widget.targetMs;
          isHint = widget.loggedMs <= 0;
        } else if (running || j.elapsedMs > 0) {
          shown = j.shownMs;
        } else if (j.mode == _TimeMode.countdown) {
          shown = j.targetMs;
          isHint = true;
        } else {
          shown = widget.loggedMs;
          isHint = widget.loggedMs <= 0;
        }
        final Color c = running
            ? runningColor
            : (isHint ? widget.hintColor : widget.textColor);

        return Container(
          height: 40,
          decoration: BoxDecoration(
            color:
                running ? widget.accent.withOpacity(0.12) : Colors.transparent,
            borderRadius: editing ? null : BorderRadius.circular(10),
            border: editing
                ? Border(bottom: BorderSide(color: widget.accent, width: 2))
                : null,
          ),
          child: Row(
            textDirection: ui.TextDirection.ltr,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openSheet,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (running)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                              color: widget.accent, shape: BoxShape.circle),
                        ),
                      Text(_mmss(shown),
                          textDirection: ui.TextDirection.ltr,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  running ? FontWeight.w800 : FontWeight.w700,
                              letterSpacing: 0.5,
                              color: c)),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: manual
                    ? _openSheet
                    : () {
                        final bool wasRunning = j.running;
                        _toggleJob(j, widget.loggedMs);
                        setState(() {});
                        // Play opens the sheet (mode switch, reset, pause);
                        // tapping outside closes it and the timer keeps running.
                        if (!wasRunning && !editing) _openSheet();
                      },
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: manual
                        ? widget.accent.withOpacity(0.15)
                        : (running ? runningColor : widget.accent),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    manual
                        ? Icons.dialpad_rounded
                        : (running
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded),
                    size: manual ? 15 : 18,
                    color: manual ? widget.accent : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The one timed-set sheet: mode switch on top, body per mode.
class _TimeSheet extends StatefulWidget {
  const _TimeSheet({
    required this.job,
    required this.colors,
    required this.lang,
    required this.loggedMs,
    required this.targetMs,
    required this.onModeChanged,
    required this.onManualChanged,
    required this.onMeasured,
    required this.onClose,
  });
  final _TimerJob job;
  final _PadColors colors;
  final String lang;
  final int loggedMs;
  final int targetMs;
  final void Function(_TimeMode m) onModeChanged;
  final Future<void> Function(int ms) onManualChanged;
  final void Function(double height) onMeasured;
  final Future<void> Function() onClose;
  @override
  State<_TimeSheet> createState() => _TimeSheetState();
}

class _TimeSheetState extends State<_TimeSheet> {
  final GlobalKey _rootKey = GlobalKey();
  late _TimeMode _mode = widget.job.mode;
  late String _digits = _digitsFromMs(widget.loggedMs); // manual entry, mmss
  late int _logged = widget.loggedMs; // what is logged, as this sheet knows it
  String? _pressedKey;

  @override
  void initState() {
    super.initState();
    _measureAfterFrame(_rootKey, widget.onMeasured);
  }

  /// Digits are typed left → right: first key is the tens of minutes.
  static String _digitsFromMs(int ms) {
    if (ms <= 0) return '';
    final s = (ms / 1000).round();
    return '${(s ~/ 60).clamp(0, 99).toString().padLeft(2, '0')}${(s % 60).toString().padLeft(2, '0')}';
  }

  int get _msFromDigits {
    final p = _digits.padRight(4, '0');
    final m = int.parse(p.substring(0, 2));
    final s = int.parse(p.substring(2, 4));
    return (m * 60 + s) * 1000;
  }

  void _switch(_TimeMode m) {
    if (m == _mode) return;
    HapticFeedback.selectionClick();
    final j = widget.job;
    if (j.running) j.pause();
    j.clear();
    j.mode = m;
    if (j.targetMs <= 0)
      j.targetMs = widget.targetMs > 0 ? widget.targetMs : 60000;
    if (m == _TimeMode.manual) _digits = _digitsFromMs(_logged);
    widget.onModeChanged(m);
    setState(() => _mode = m);
    _measureAfterFrame(_rootKey, widget.onMeasured);
  }

  // ---- manual keys ----

  void _down(String keyId) {
    if (keyId == 'back') {
      if (_digits.isEmpty) return;
      HapticFeedback.selectionClick();
      setState(() {
        _pressedKey = 'back';
        _digits = _digits.substring(0, _digits.length - 1);
      });
      _logged = _msFromDigits;
      widget.onManualChanged(_logged);
      return;
    }
    if (_digits.length >= 4) return;
    // seconds' tens digit can't be 6-9
    if (_digits.length == 2 && int.parse(keyId) > 5) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pressedKey = keyId;
      _digits += keyId;
    });
    _logged = _msFromDigits;
    widget.onManualChanged(_logged);
  }

  void _up() => setState(() => _pressedKey = null);

  Widget _k(String d) => _numKey(widget.colors,
      shown: d,
      enabled: d.isNotEmpty &&
          _digits.length < 4 &&
          !(_digits.length == 2 && int.parse(d) > 5),
      pressed: _pressedKey == d,
      onDown: () => _down(d),
      onUp: _up);

  Widget _digitBox(String d, bool active, {bool typed = true}) {
    final c = widget.colors;
    return Container(
      width: 40,
      height: 48,
      decoration: BoxDecoration(
          color: c.keyBg, borderRadius: BorderRadius.circular(10)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(d,
              textDirection: ui.TextDirection.ltr,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: typed ? c.text : c.text.withOpacity(0.3))),
          if (active)
            Positioned(
              left: 8,
              right: 8,
              bottom: 5,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                    color: c.accent, borderRadius: BorderRadius.circular(1)),
              ),
            ),
        ],
      ),
    );
  }

  // ---- segmented switch ----

  Widget _segmented(ui.TextDirection dir) {
    final c = widget.colors;
    Widget seg(_TimeMode m, IconData icon, String key) {
      final bool on = _mode == m;
      return Expanded(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _switch(m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 36,
            decoration: BoxDecoration(
              color: on ? c.sheetBg : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: on
                  ? [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ]
                  : null,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    textDirection: dir,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          size: 15,
                          color: on ? c.accent : c.text.withOpacity(0.55)),
                      const SizedBox(width: 5),
                      Text(_tr(widget.lang, key),
                          textDirection: dir,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: on ? c.text : c.text.withOpacity(0.55))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: c.keyBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        textDirection: dir,
        children: [
          seg(_TimeMode.countUp, Icons.timer_outlined, 'stopwatch'),
          seg(_TimeMode.countdown, Icons.hourglass_bottom_rounded, 'countdown'),
          seg(_TimeMode.manual, Icons.dialpad_rounded, 'manual'),
        ],
      ),
    );
  }

  // ---- bodies ----

  Widget _bigTime(int ms) => Text(_mmss(ms),
      textDirection: ui.TextDirection.ltr,
      style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          height: 1.0,
          letterSpacing: 1,
          color: widget.colors.text));

  Widget _timerBody(ui.TextDirection dir) {
    final c = widget.colors;
    final j = widget.job;
    final bool countdown = _mode == _TimeMode.countdown;

    return ValueListenableBuilder<int>(
      valueListenable: j.tick,
      builder: (_, __, ___) {
        final bool running = j.running;
        final double progress = countdown && j.targetMs > 0
            ? (j.elapsedMs / j.targetMs).clamp(0.0, 1.0).toDouble()
            : 0.0;
        final bool idleStopwatch = !running && j.elapsedMs == 0 && !countdown;
        final int shown = idleStopwatch ? _logged : j.shownMs;
        final String startKey = running
            ? 'pause'
            : ((j.elapsedMs > 0 || (idleStopwatch && _logged > 0))
                ? 'resume'
                : 'start');

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Row(
              textDirection: ui.TextDirection.ltr,
              children: [
                countdown
                    ? _stepBtn(c, () {
                        if (running) return;
                        HapticFeedback.selectionClick();
                        j.clear();
                        j.targetMs =
                            (j.targetMs - 5000).clamp(5000, 3600000).toInt();
                        j.tick.value++;
                      }, label: '-5')
                    : const SizedBox(width: 58),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _bigTime(shown),
                      if (countdown) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: SizedBox(
                            width: 160,
                            height: 4,
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: c.keyBg,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(c.accent),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                countdown
                    ? _stepBtn(c, () {
                        if (running) return;
                        HapticFeedback.selectionClick();
                        j.clear();
                        j.targetMs =
                            (j.targetMs + 5000).clamp(5000, 3600000).toInt();
                        j.tick.value++;
                      }, label: '+5')
                    : const SizedBox(width: 58),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              textDirection: dir,
              children: [
                _stepBtn(c, () {
                  HapticFeedback.selectionClick();
                  _logged = 0;
                  j.reset();
                }, icon: Icons.replay_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) {
                      _toggleJob(j, _logged);
                      if (!j.running) _logged = j.accumulatedMs;
                    },
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: running ? c.keyBg : c.accent,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        textDirection: dir,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                              running
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 20,
                              color: running ? c.text : Colors.white),
                          const SizedBox(width: 6),
                          Text(_tr(widget.lang, startKey),
                              textDirection: dir,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: running ? c.text : Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (_) {
                    HapticFeedback.selectionClick();
                    widget.onClose();
                  },
                  child: Container(
                    width: 96,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: c.keyBg,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(_tr(widget.lang, 'close'),
                        textDirection: dir,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: c.text)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  Widget _manualBody() {
    final c = widget.colors;
    final p = _digits.padRight(4, '0');
    final int cursor = _digits.length + 1; // next box to fill, from the left
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Row(
          textDirection: ui.TextDirection.ltr,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _digitBox(p[0], cursor == 1, typed: _digits.length > 0),
            const SizedBox(width: 6),
            _digitBox(p[1], cursor == 2, typed: _digits.length > 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(':',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: c.text.withOpacity(0.4))),
            ),
            _digitBox(p[2], cursor == 3, typed: _digits.length > 2),
            const SizedBox(width: 6),
            _digitBox(p[3], cursor == 4, typed: _digits.length > 3),
          ],
        ),
        const SizedBox(height: 10),
        Row(
            textDirection: ui.TextDirection.ltr,
            children: [_k('1'), _k('2'), _k('3')]),
        Row(
            textDirection: ui.TextDirection.ltr,
            children: [_k('4'), _k('5'), _k('6')]),
        Row(
            textDirection: ui.TextDirection.ltr,
            children: [_k('7'), _k('8'), _k('9')]),
        Row(textDirection: ui.TextDirection.ltr, children: [
          _numKey(c,
              shown: '',
              enabled: false,
              pressed: false,
              onDown: () {},
              onUp: () {}),
          _k('0'),
          _numKey(c,
              shown: '',
              enabled: _digits.isNotEmpty,
              pressed: _pressedKey == 'back',
              onDown: () => _down('back'),
              onUp: _up,
              child: Icon(Icons.backspace_outlined, size: 21, color: c.text)),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui.TextDirection dir = _kRtl.contains(widget.lang)
        ? ui.TextDirection.rtl
        : ui.TextDirection.ltr;
    return _sheetShell(
        widget.colors, _rootKey, MediaQuery.of(context).padding.bottom, [
      _segmented(dir),
      _mode == _TimeMode.manual ? _manualBody() : _timerBody(dir),
    ]);
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
