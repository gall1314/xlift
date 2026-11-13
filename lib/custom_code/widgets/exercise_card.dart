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

import 'dart:ui' as ui show TextDirection;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '/auth/supabase_auth/auth_util.dart';

// =============================================================================
// ExerciseCard — one exercise in the live workout (or in workout creation).
//
// Self-contained: loads the exercise row itself (SQLite query `exercise2`),
// reads and writes App State directly (live lists, or the *Creation lists when
// isLiveWorkout is false), and rebuilds on every App State change.
//
// Inside: header (ExerciseHeaderButton), Superset tag, rest-time button with
// its own picker sheet, ExerciseFinishButton, the ⋮ menu, column headers,
// SetTable (working sets + warm-up rows), "Add set", Smart Warm-up generator.
//
// Only navigation stays outside, as callbacks: onHeaderTap, onReplaceExercise,
// onSupersetTap, onViewHistory, onReorder, onRemoveExercise, onResultTap,
// onLockTap, onStartRest, onDontShowAgain.
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
  "previous": {
    "en": "Previous",
    "es": "Anterior",
    "he": "קודם",
    "de": "Zuvor",
    "fr": "Précédent"
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
  "time": {
    "en": "Time",
    "es": "Tiempo",
    "he": "זמן",
    "de": "Zeit",
    "fr": "Temps"
  },
  "addSet": {
    "en": "Add set",
    "es": "Añadir serie",
    "he": "הוסף סט",
    "de": "Satz hinzufügen",
    "fr": "Ajouter une série"
  },
  "superset": {
    "en": "Superset",
    "es": "Superserie",
    "he": "סופרסט",
    "de": "Supersatz",
    "fr": "Superset"
  },
  "replace": {
    "en": "Replace Exercise",
    "es": "Reemplazar ejercicio",
    "he": "החלף תרגיל",
    "de": "Übung ersetzen",
    "fr": "Remplacer l’exercice"
  },
  "history": {
    "en": "View History",
    "es": "Ver historial",
    "he": "היסטוריה",
    "de": "Verlauf",
    "fr": "Historique"
  },
  "warmup": {
    "en": "Smart Warm-up",
    "es": "Calentamiento inteligente",
    "he": "חימום חכם",
    "de": "Smartes Aufwärmen",
    "fr": "Échauffement intelligent"
  },
  "reorder": {
    "en": "Reorder",
    "es": "Reordenar",
    "he": "סדר מחדש",
    "de": "Neu anordnen",
    "fr": "Réorganiser"
  },
  "remove": {
    "en": "Remove Exercise",
    "es": "Quitar ejercicio",
    "he": "הסר תרגיל",
    "de": "Übung entfernen",
    "fr": "Retirer l’exercice"
  },
  "setRest": {
    "en": "Set Rest Time",
    "es": "Tiempo de descanso",
    "he": "זמן מנוחה",
    "de": "Pausenzeit",
    "fr": "Temps de repos"
  },
  "off": {"en": "Off", "es": "No", "he": "כבוי", "de": "Aus", "fr": "Off"},
  "set": {
    "en": "Set",
    "es": "Fijar",
    "he": "קבע",
    "de": "Festlegen",
    "fr": "Valider"
  },
  "warmupTitle": {
    "en": "Warm-up Generator",
    "es": "Generador de calentamiento",
    "he": "מחולל חימום",
    "de": "Aufwärm-Generator",
    "fr": "Générateur d’échauffement"
  },
  "warmupSub": {
    "en": "Auto-create warm-up sets that won't count toward stats.",
    "es": "Crea series de calentamiento que no cuentan en las estadísticas.",
    "he": "יוצר סטי חימום אוטומטית — לא נספרים בסטטיסטיקות.",
    "de": "Erstellt Aufwärmsätze, die nicht in die Statistik zählen.",
    "fr": "Crée des séries d’échauffement qui ne comptent pas dans les stats."
  },
  "targetWeight": {
    "en": "Target Weight",
    "es": "Peso objetivo",
    "he": "משקל יעד",
    "de": "Zielgewicht",
    "fr": "Poids cible"
  },
  "numSets": {
    "en": "Number of Warm-up Sets",
    "es": "Número de series",
    "he": "מספר סטי חימום",
    "de": "Anzahl Aufwärmsätze",
    "fr": "Nombre de séries"
  },
  "generate": {
    "en": "Generate Warm-ups",
    "es": "Generar calentamiento",
    "he": "צור חימום",
    "de": "Aufwärmen erstellen",
    "fr": "Générer l’échauffement"
  },
  "removeWarmup": {
    "en": "Remove warm-up",
    "es": "Quitar calentamiento",
    "he": "הסר חימום",
    "de": "Aufwärmen entfernen",
    "fr": "Retirer l’échauffement"
  },
  "kg": {"en": "kg", "es": "kg", "he": "ק״ג", "de": "kg", "fr": "kg"},
  "lbs": {"en": "lbs", "es": "lb", "he": "ליב׳", "de": "lbs", "fr": "lb"},
  "cancelSuperset": {
    "en": "Cancel Superset",
    "es": "Cancelar superserie",
    "he": "בטל סופרסט",
    "de": "Supersatz aufheben",
    "fr": "Annuler le superset"
  },
  "addedWeight": {
    "en": "Added weight",
    "es": "Peso añadido",
    "he": "משקל נוסף",
    "de": "Zusatzgewicht",
    "fr": "Poids ajouté"
  },
  "addedWeightSub": {
    "en": "Belt or vest on your working sets",
    "es": "Cinturón o chaleco en las series de trabajo",
    "he": "חגורה או וסט בסטי העבודה",
    "de": "Gürtel oder Weste in den Arbeitssätzen",
    "fr": "Ceinture ou gilet sur les séries de travail"
  },
  "targetAdded": {
    "en": "Target added weight",
    "es": "Peso añadido objetivo",
    "he": "משקל נוסף ליעד",
    "de": "Ziel-Zusatzgewicht",
    "fr": "Poids ajouté cible"
  },
  "warmupSets": {
    "en": "Warm-up sets",
    "es": "Series de calentamiento",
    "he": "סטי חימום",
    "de": "Aufwärmsätze",
    "fr": "Séries d’échauffement"
  },
  "bodyweight": {
    "en": "Bodyweight",
    "es": "Peso corporal",
    "he": "משקל גוף",
    "de": "Körpergewicht",
    "fr": "Poids du corps"
  },
  "sets": {
    "en": "sets",
    "es": "series",
    "he": "סטים",
    "de": "Sätze",
    "fr": "séries"
  },
  "setOne": {
    "en": "set",
    "es": "serie",
    "he": "סט",
    "de": "Satz",
    "fr": "série"
  },
  "best": {
    "en": "best",
    "es": "mejor",
    "he": "הטוב ביותר",
    "de": "beste",
    "fr": "meilleur"
  },
  "repsShort": {
    "en": "reps",
    "es": "reps",
    "he": "חזרות",
    "de": "Wdh.",
    "fr": "reps"
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

String _fmtW(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  String s = v.toStringAsFixed(2);
  while (s.endsWith('0')) s = s.substring(0, s.length - 1);
  if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  return s;
}

/// DB equipment → the key applyWarmupSimpleUnits / suggestBumpedTarget know.
String _equipKey(String? equipment) {
  final e = (equipment ?? '').trim().toLowerCase();
  if (e.contains('dumbbell') || e.contains('kettlebell')) return 'dumbbell';
  if (e.contains('smith')) return 'smith';
  if (e.contains('barbell') || e.contains('trap bar')) return 'barbell';
  return 'machine';
}

double _stepFor(String equipKey, bool isKg, double current) {
  if (equipKey == 'dumbbell') {
    return isKg ? (current < 10 ? 1.0 : 2.0) : (current < 25 ? 2.5 : 5.0);
  }
  return isKg ? 2.5 : 5.0;
}

// =============================================================================
// Widget
// =============================================================================

class ExerciseCard extends StatefulWidget {
  const ExerciseCard({
    super.key,
    this.width,
    this.height,
    required this.exerciseId,
    this.isLiveWorkout = true,
    this.exerciseCount = 1,
    this.isLogEdit = false,
    this.isTemplate = false,
    this.showCameraGuidance,
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
    this.onRestTimeChanged,
  });

  final double? width;
  final double? height;
  final int exerciseId;

  /// true → live App State lists; false → the *Creation lists.
  final bool isLiveWorkout;

  /// Number of exercises in the workout ("Reorder" only when > 1).
  final int exerciseCount;

  /// Editing a logged workout: no rest button, no superset, no warm-up,
  /// no analysis, and a short options menu.
  final bool isLogEdit;

  /// Building a workout template (create / edit template): target reps only,
  /// nothing to complete, no weight and no analysis. The rest time is still
  /// set here, because it is saved with the template.
  final bool isTemplate;
  final bool? showCameraGuidance;

  final Future Function()? onHeaderTap;

  /// Header tap on a user-created exercise (exercise.is_public == 0).
  final Future Function()? onCustomHeaderTap;
  final Future Function()? onReplaceExercise;
  final Future Function()? onSupersetTap;
  final Future Function()? onViewHistory;

  /// View History on a user-created exercise (exercise.is_public == 0).
  final Future Function()? onCustomViewHistory;
  final Future Function()? onReorder;
  final Future Function()? onRemoveExercise;

  /// [exerciseName] is the raw DB name (JSON or plain), as the dialog expects.
  final Future Function(String exerciseName, int setNumber,
      FFUploadedFile? video, String setLogId)? onResultTap;
  final Future Function()? onLockTap;
  final Future Function(
          int exerciseId, String exerciseName, int setNumber, int restMs)?
      onStartRest;
  final Future Function()? onDontShowAgain;

  /// Fired after the user picks a rest time for this exercise, with the new
  /// value in milliseconds (0 = Off). The card has already written it to
  /// App State; this is only for saving it somewhere else.
  final Future Function(int exerciseId, int restMs)? onRestTimeChanged;

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  // exercise row (SQLite exercise2)
  bool _loaded = false;
  String _nameRaw = '';
  String? _illustration;
  String _equipment = '';
  bool _isTimed = false;
  bool _isBodyweight = false;
  bool _allowsBodyweight = false;
  bool _aiEnabled = false;
  bool _isCustom = false;

  @override
  void initState() {
    super.initState();
    _loadExercise();
  }

  @override
  void didUpdateWidget(covariant ExerciseCard old) {
    super.didUpdateWidget(old);
    if (old.exerciseId != widget.exerciseId) _loadExercise();
  }

  Future<void> _loadExercise() async {
    try {
      final rows =
          await SQLiteManager.instance.exercise2(exerciseId: widget.exerciseId);
      if (rows.isEmpty) return;
      final dynamic r = rows.first;
      dynamic g(String k) {
        try {
          return (r as dynamic).data[k];
        } catch (_) {
          return null;
        }
      }

      if (!mounted) return;
      setState(() {
        _nameRaw = (g('name') ?? '').toString();
        final ill = (g('illustration') ?? '').toString().trim();
        _illustration = ill.isEmpty ? null : ill;
        _equipment = (g('equipment') ?? '').toString();
        _isTimed = _truthy(g('is_time_based'));
        _isBodyweight =
            _truthy(g('is_bodyweight_dominant') ?? g('is_bodyweight'));
        _allowsBodyweight = _truthy(g('allows_bodyweight'));
        _aiEnabled = _truthy(g('ai_form_analysis'));
        _isCustom = g('is_public') != null && !_truthy(g('is_public'));
        _loaded = true;
      });
    } catch (_) {}
  }

  // ---------- App State (live vs creation) ----------

  bool get _live => widget.isLiveWorkout;

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
  List<dynamic> get _analysisState => List<dynamic>.from(_live
      ? FFAppState().workoutAnalysisState
      : FFAppState().analysisStateCreation);
  List<dynamic> get _completed => List<dynamic>.from(_live
      ? FFAppState().completedExercises
      : FFAppState().completedExercisesCreation);

  void _write(void Function(FFAppState s) f) =>
      FFAppState().update(() => f(FFAppState()));

  Future<void> _setExerciseSets(List<dynamic> v) async => _write((s) {
        if (_live) {
          s.exercisesets = v;
        } else {
          s.exerciseSetsCreation = v;
        }
      });
  Future<void> _setLoggedSets(List<dynamic> v) async => _write((s) {
        if (_live) {
          s.loggedSets = v;
        } else {
          s.loggedSetsCreation = v;
        }
      });
  Future<void> _setDropSets(List<dynamic> v) async => _write((s) {
        if (_live) {
          s.dropSets = v;
        } else {
          s.dropSetsCreation = v;
        }
      });
  Future<void> _setWarmupSets(List<dynamic> v) async => _write((s) {
        if (_live) {
          s.warmupSets = v;
        } else {
          s.warmUpCreation = v;
        }
      });
  Future<void> _setAnalysisState(List<dynamic> v) async => _write((s) {
        if (_live) {
          s.workoutAnalysisState = v;
        } else {
          s.analysisStateCreation = v;
        }
      });
  Future<void> _setCompleted(List<dynamic> v) async => _write((s) {
        if (_live) {
          s.completedExercises = v;
        } else {
          s.completedExercisesCreation = v;
        }
      });
  Future<void> _setRestMs(int ms) async {
    final Map<String, dynamic> m = {};
    final cur = _restTimers;
    if (cur is Map) cur.forEach((k, v) => m['$k'] = v);
    m['${widget.exerciseId}'] = ms;
    _write((s) {
      if (_live) {
        s.restTimers = m;
      } else {
        s.restTimerCreation = m;
      }
    });
  }

  bool get _isComplete {
    if (!_live) return false;
    for (final e in _completed) {
      if (e is Map && _asInt(e['exerciseId']) == widget.exerciseId)
        return _truthy(e['isComplete']);
    }
    return false;
  }

  int get _restMs {
    final rt = _restTimers;
    if (rt is! Map) return 90000;
    final v = rt['${widget.exerciseId}'] ?? rt[widget.exerciseId];
    return v == null ? 90000 : _asInt(v);
  }

  Map<String, dynamic>? _myTemplate() {
    for (final e in _exerciseSets) {
      if (e is Map && _asInt(e['exerciseId']) == widget.exerciseId)
        return Map<String, dynamic>.from(e);
    }
    return null;
  }

  bool get _isSuperset {
    try {
      return isExerciseSuperset(_exerciseSets, widget.exerciseId);
    } catch (_) {
      return false;
    }
  }

  // ---------- add set ----------

  Future<void> _addSet() async {
    HapticFeedback.selectionClick();
    final list = _exerciseSets
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final idx =
        list.indexWhere((e) => _asInt(e['exerciseId']) == widget.exerciseId);
    if (idx < 0) return;
    final sets = (list[idx]['sets'] is List)
        ? (list[idx]['sets'] as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList()
        : <Map<String, dynamic>>[];
    sets.sort(
        (a, b) => _asInt(a['setNumber']).compareTo(_asInt(b['setNumber'])));
    final Map<String, dynamic> last = sets.isNotEmpty
        ? Map<String, dynamic>.from(sets.last)
        : {
            'weighted': _isBodyweight ? 0 : 1,
            'timerMode': _isTimed ? 2 : 1,
            'durationSeconds': _isTimed ? 30 : 0,
            'targetReps': 10,
            'showWeightField': _isBodyweight ? 0 : 1,
          };
    last['setNumber'] = sets.length + 1;
    sets.add(last);
    list[idx]['sets'] = sets;
    await _setExerciseSets(List<dynamic>.from(list));
  }

  // ---------- rest picker ----------

  Future<void> _openRestPicker(String lang) async {
    HapticFeedback.selectionClick();
    final int? ms = await showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RestSheet(initialMs: _restMs, lang: lang),
    );
    if (ms == null) return;
    await _setRestMs(ms);
    await widget.onRestTimeChanged?.call(widget.exerciseId, ms);
  }

  // ---------- menu ----------

  Future<void> _openMenu(String lang) async {
    HapticFeedback.selectionClick();
    final theme = FlutterFlowTheme.of(context);
    final bool rtl = _kRtl.contains(lang);
    final bool hasWarmup = _warmupSets
        .any((e) => e is Map && _asInt(e['exerciseId']) == widget.exerciseId);
    final bool superset = _isSuperset;
    final String name = localizedName(_nameRaw, lang);
    final int nSets = (_myTemplate()?['sets'] is List)
        ? (_myTemplate()!['sets'] as List).length
        : 0;
    final String sub = [
      if (_equipment.trim().isNotEmpty) _equipment.trim(),
      if (nSets > 0) '$nSets ${_tr(lang, nSets == 1 ? 'setOne' : 'sets')}',
    ].join(' · ');

    Widget item(
        IconData icon, Color color, String label, Future<void> Function() onTap,
        {Color? labelColor, bool chevron = true}) {
      return _MenuRow(
        pressedColor: theme.primaryText.withOpacity(0.06),
        onTap: () async {
          Navigator.of(context, rootNavigator: true).pop();
          await onTap();
        },
        child: Row(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(width: 20),
            Expanded(
              child: Text(label,
                  style: _ts(theme, 17, FontWeight.w400,
                      labelColor ?? theme.primaryText)),
            ),
            if (chevron)
              Icon(
                  rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 22,
                  color: theme.secondaryText),
          ],
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
            color: theme.secondaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: EdgeInsets.only(
              top: 12, bottom: MediaQuery.of(ctx).padding.bottom + 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                    color: theme.alternate,
                    borderRadius: BorderRadius.circular(3)),
              ),
              // header: which exercise this menu is about
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: theme.primaryBackground,
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.fitness_center_rounded,
                          size: 22, color: theme.primaryText),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _ts(theme, 16, FontWeight.w700,
                                  theme.primaryText)),
                          if (sub.isNotEmpty)
                            Text(sub,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _ts(theme, 13, FontWeight.w400,
                                    theme.secondaryText)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                  height: 1, indent: 24, endIndent: 24, color: theme.alternate),
              const SizedBox(height: 4),
              item(Icons.refresh_rounded, theme.primary, _tr(lang, 'replace'),
                  () async => widget.onReplaceExercise?.call()),
              if (!widget.isLogEdit)
                superset
                    ? item(Icons.link_off_rounded, const Color(0xFF7C3AED),
                        _tr(lang, 'cancelSuperset'), _cancelSuperset)
                    : item(
                        Icons.link_rounded,
                        const Color(0xFF7C3AED),
                        _tr(lang, 'superset'),
                        () async => widget.onSupersetTap?.call()),
              item(
                  Icons.bar_chart_rounded,
                  const Color(0xFF64748B),
                  _tr(lang, 'history'),
                  () async => _isCustom
                      ? widget.onCustomViewHistory?.call()
                      : widget.onViewHistory?.call()),
              if (!widget.isLogEdit)
                item(
                    Icons.local_fire_department_rounded,
                    const Color(0xFF38BDF8),
                    _tr(lang, 'warmup'),
                    () async => _openWarmupGenerator(lang),
                    chevron: !hasWarmup),
              if (widget.exerciseCount > 1)
                item(Icons.menu_rounded, const Color(0xFF64748B),
                    _tr(lang, 'reorder'), () async => widget.onReorder?.call()),
              Divider(
                  height: 1, indent: 24, endIndent: 24, color: theme.alternate),
              item(
                  Icons.delete_rounded,
                  const Color(0xFFEF4444),
                  _tr(lang, 'remove'),
                  () async => widget.onRemoveExercise?.call(),
                  labelColor: const Color(0xFFEF4444),
                  chevron: false),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- superset ----------

  /// Same job as unpairSupersetByExercise, inlined (FF can't resolve the
  /// action from inside a widget): clears isSuperset / supersetSeq /
  /// supersetId on this exercise and on every partner sharing its supersetId.
  Future<void> _cancelSuperset() async {
    HapticFeedback.mediumImpact();
    final list = _exerciseSets
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final idx =
        list.indexWhere((e) => _asInt(e['exerciseId']) == widget.exerciseId);
    if (idx < 0) return;
    final dynamic groupId = list[idx]['supersetId'];
    final bool hasGroup =
        groupId != null && '$groupId'.isNotEmpty && '$groupId' != '0';
    for (final e in list) {
      final bool mine = _asInt(e['exerciseId']) == widget.exerciseId;
      final bool partner = hasGroup &&
          e['supersetId'] != null &&
          '${e['supersetId']}' == '$groupId';
      if (!mine && !partner) continue;
      e['isSuperset'] = false;
      e['supersetSeq'] = null;
      e['supersetId'] = null;
    }
    await _setExerciseSets(List<dynamic>.from(list));
  }

  // ---------- warm-up generator ----------

  Future<double?> _suggestTarget() async {
    // weight of working set 1 in this workout, else last time's set 1.
    for (final l in _loggedSets) {
      if (l is Map &&
          _asInt(l['exerciseId']) == widget.exerciseId &&
          _asInt(l['setNumber']) == 1 &&
          !_truthy(l['isDropSet'])) {
        final w = _asDoubleN(l['weight']);
        if (w != null && w > 0) return w;
      }
    }
    try {
      final rows = await SQLiteManager.instance.correctedPreviosSet(
        exerciseId: widget.exerciseId,
        setNumber: 1,
        userId: currentUserUid,
      );
      if (rows.isNotEmpty) {
        final w = _asDoubleN((rows.first as dynamic).data['weight']);
        if (w != null && w > 0) return w;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _openWarmupGenerator(String lang) async {
    // loaded exercise → target weight; bodyweight → optional added weight.
    final bool bodyweight = _isBodyweight;
    final bool withWeight = !_isTimed;
    final double? suggested = withWeight ? await _suggestTarget() : null;
    if (!mounted) return;
    final res = await showModalBottomSheet<_WarmupChoice>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WarmupSheet(
        lang: lang,
        withWeight: withWeight,
        isBodyweight: bodyweight,
        isKg: FFAppState().isKg,
        equipKey: _equipKey(_equipment),
        title: localizedName(_nameRaw, lang),
        subtitle: bodyweight ? _tr(lang, 'bodyweight') : _equipment.trim(),
        initialWeight: suggested,
        hasExisting: _warmupSets.any(
            (e) => e is Map && _asInt(e['exerciseId']) == widget.exerciseId),
      ),
    );
    if (res == null) return;
    if (res.remove) {
      final list = _warmupSets
        ..removeWhere(
            (e) => e is Map && _asInt(e['exerciseId']) == widget.exerciseId);
      await _setWarmupSets(list);
      return;
    }
    // One generator for everything; the mode travels in the equipment key:
    // 'timed' / 'bodyweight' / 'barbell' | 'smith' | 'machine' | 'dumbbell'.
    final String mode = _isTimed
        ? 'timed'
        : (bodyweight ? 'bodyweight' : _equipKey(_equipment));
    List<dynamic> out;
    try {
      out = applyWarmupSimpleUnits(
        _warmupSets,
        widget.exerciseId,
        mode,
        FFAppState().isKg,
        withWeight ? res.targetWeight : null,
        res.numSets,
      );
    } catch (_) {
      return;
    }
    await _setWarmupSets(out);
  }

  // ---------- completed summary ----------

  /// "4 sets · 100 kg × 8" / "4 sets · 12 reps" / "3 sets · 2:00".
  String _summary(String lang) {
    int n = 0;
    double bestW = 0;
    int bestWReps = 0;
    int bestReps = 0;
    int totalMs = 0;
    for (final l in _loggedSets) {
      if (l is! Map || _asInt(l['exerciseId']) != widget.exerciseId) continue;
      if (_truthy(l['isDropSet']) || !_truthy(l['isDone'])) continue;
      n++;
      final int reps = _asInt(l['reps']);
      final double w = _asDoubleN(l['weight']) ?? 0;
      totalMs += _asInt(l['durationMs']);
      if (w > bestW || (w == bestW && reps > bestWReps)) {
        bestW = w;
        bestWReps = reps;
      }
      if (reps > bestReps) bestReps = reps;
    }
    if (n == 0) return '';
    final String sets = '$n ${_tr(lang, n == 1 ? 'setOne' : 'sets')}';
    final String unit = _tr(lang, FFAppState().isKg ? 'kg' : 'lbs');
    String tail;
    if (_isTimed) {
      final s = totalMs ~/ 1000;
      tail = '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
    } else if (bestW > 0) {
      tail = '⁦${_fmtW(bestW)} $unit × $bestWReps⁩';
    } else if (bestReps > 0) {
      tail = '$bestReps ${_tr(lang, 'repsShort')}';
    } else {
      return sets;
    }
    return '$sets · $tail';
  }

  // ---------- text style ----------

  static TextStyle _ts(
          FlutterFlowTheme th, double size, FontWeight w, Color c) =>
      th.bodyMedium.override(
        fontFamily: th.bodyMediumFamily,
        color: c,
        fontSize: size,
        fontWeight: w,
        useGoogleFonts: GoogleFonts.asMap().containsKey(th.bodyMediumFamily),
      );

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>(); // rebuild on every App State change
    final theme = FlutterFlowTheme.of(context);
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    // While editing a logged workout the card never collapses: every set is
    // already done, and the ✓ is just a marker the user can toggle.
    final bool complete =
        _isComplete && !widget.isLogEdit && !widget.isTemplate;
    final Color border =
        dark ? const Color(0xFF2A3644) : const Color(0xFFE3E7EB);

    final Widget header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExerciseHeaderButton(
                exerciseName: _nameRaw,
                illustration: _illustration,
                onTap: () async => _isCustom
                    ? widget.onCustomHeaderTap?.call()
                    : widget.onHeaderTap?.call(),
              ),
              if (complete && _summary(lang).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_summary(lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(
                          theme,
                          13,
                          FontWeight.w500,
                          dark
                              ? const Color(0xFF5EEAD4)
                              : const Color(0xFF0F766E))),
                ),
              if (!complete && !widget.isLogEdit) ...[
                if (_isSuperset) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.accent2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_tr(lang, 'superset'),
                        style: _ts(theme, 15, FontWeight.w500, theme.primary)),
                  ),
                ],
                const SizedBox(height: 10),
                RestTimeButton(
                  exerciseRestTimes: _restTimers,
                  exerciseId: widget.exerciseId,
                  onTap: () async => _openRestPicker(lang),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if ((_live || widget.isLogEdit) && !widget.isTemplate)
              ExerciseFinishButton(
                exerciseId: widget.exerciseId,
                exerciseName: localizedName(_nameRaw, lang),
                exerciseSets: _exerciseSets,
                loggedSets: _loggedSets,
                completedExercises: _completed,
                onApply: (list) async => _setCompleted(list),
              ),
            if (!complete) ...[
              const SizedBox(height: 10),
              _RoundIconButton(
                icon: Icons.more_vert_rounded,
                border: border,
                color: theme.primaryText,
                onTap: () => _openMenu(lang),
              ),
            ],
          ],
        ),
      ],
    );

    final Widget body;
    if (complete) {
      body = const SizedBox.shrink();
    } else if (!_loaded) {
      body = const SizedBox(
          height: 120,
          child: Center(
              child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2))));
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 22),
          SetTable(
            exerciseId: widget.exerciseId,
            exerciseName: _nameRaw,
            userId: currentUserUid,
            isKg: FFAppState().isKg,
            isPremium: FFAppState().isPremium,
            analysisCount: FFAppState().analysisCount,
            aiEnabled: _aiEnabled && _live,
            isTimed: _isTimed,
            isBodyweight: _isBodyweight,
            allowsBodyweight: _allowsBodyweight,
            showHeaders: true,
            isLogEdit: widget.isLogEdit,
            isTemplate: widget.isTemplate,
            showCameraGuidance: widget.showCameraGuidance,
            exerciseSets: _exerciseSets,
            loggedSets: _loggedSets,
            dropSets: _dropSets,
            analysisState: _analysisState,
            restTimers: _restTimers,
            warmupSets: _warmupSets,
            onLoggedSetsChanged: _setLoggedSets,
            onExerciseSetsChanged: _setExerciseSets,
            onDropSetsChanged: _setDropSets,
            onAnalysisStateChanged: _setAnalysisState,
            onWarmupSetsChanged: _setWarmupSets,
            onResultTap: (setNumber, video, setLogId) async =>
                widget.onResultTap?.call(_nameRaw, setNumber, video, setLogId),
            onLockTap: widget.onLockTap,
            onStartRest: (exerciseId, setNumber, restMs) async => widget
                .onStartRest
                ?.call(exerciseId, _nameRaw, setNumber, restMs),
            onDontShowAgain: widget.onDontShowAgain,
          ),
          const SizedBox(height: 12),
          _Pressable(
            onTap: _addSet,
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: theme.primary.withOpacity(dark ? 0.55 : 0.45),
                radius: 12,
                strokeWidth: 1.5,
              ),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                          color: theme.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.add_rounded,
                          size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(_tr(lang, 'addSet'),
                        style: _ts(
                            theme,
                            15,
                            FontWeight.w600,
                            dark
                                ? const Color(0xFF5EEAD4)
                                : const Color(0xFF0F766E))),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: SizedBox(
        width: widget.width,
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, complete ? 16 : 20),
          decoration: BoxDecoration(
            color: complete ? theme.accent2 : theme.secondaryBackground,
            borderRadius: BorderRadius.circular(20),
            border: complete ? null : Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [header, body],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Small atoms
// =============================================================================

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

/// Bottom-sheet menu row: highlighted + slightly shrunk while the finger is down.
class _MenuRow extends StatefulWidget {
  const _MenuRow(
      {required this.child, required this.onTap, required this.pressedColor});
  final Widget child;
  final VoidCallback onTap;
  final Color pressedColor;
  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
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
        scale: _down ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _down ? widget.pressedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Dashed rounded border (Flutter has none built in).
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter(
      {required this.color, required this.radius, required this.strokeWidth});
  final Color color;
  final double radius, strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rrect =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius))
            .deflate(strokeWidth / 2);
    final path = Path()..addRRect(rrect);
    const double dash = 6, gap = 4;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(
            metric.extractPath(
                d, (d + dash).clamp(0, metric.length).toDouble()),
            paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton(
      {required this.icon,
      required this.border,
      required this.color,
      required this.onTap});
  final IconData icon;
  final Color border, color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            shape: BoxShape.circle, border: Border.all(color: border)),
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }
}

// =============================================================================
// Rest-time sheet: Cupertino-style wheel, Off then 0:05 → 8:00 in 5s steps.
// =============================================================================

class _RestSheet extends StatefulWidget {
  const _RestSheet({required this.initialMs, required this.lang});
  final int initialMs;
  final String lang;
  @override
  State<_RestSheet> createState() => _RestSheetState();
}

class _RestSheetState extends State<_RestSheet> {
  static const int _step = 5, _min = 5, _max = 8 * 60;
  late final List<int> _values = [
    0,
    for (int s = _min; s <= _max; s += _step) s
  ];
  late final FixedExtentScrollController _ctrl;
  late int _selected;

  @override
  void initState() {
    super.initState();
    int start = (widget.initialMs / 1000).round();
    if (start <= 0) {
      start = 0;
    } else {
      start = ((start / _step).round() * _step).clamp(_min, _max).toInt();
    }
    _selected = start;
    final idx = _values.indexOf(start);
    _ctrl = FixedExtentScrollController(initialItem: idx < 0 ? 0 : idx);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _mmss(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bool rtl = _kRtl.contains(widget.lang);
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
            Text(_tr(widget.lang, 'setRest'),
                style: _ExerciseCardState._ts(
                    theme, 20, FontWeight.w700, theme.primaryText)),
            const SizedBox(height: 10),
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IgnorePointer(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.primaryText.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  ListWheelScrollView.useDelegate(
                    controller: _ctrl,
                    physics: const FixedExtentScrollPhysics(),
                    itemExtent: 44,
                    perspective: 0.003,
                    diameterRatio: 1.6,
                    useMagnifier: true,
                    magnification: 1.08,
                    overAndUnderCenterOpacity: 0.45,
                    onSelectedItemChanged: (i) {
                      HapticFeedback.selectionClick();
                      setState(() => _selected = _values[i]);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: _values.length,
                      builder: (ctx, i) {
                        final s = _values[i];
                        final bool sel = s == _selected;
                        return Center(
                          child: Text(
                            s <= 0 ? _tr(widget.lang, 'off') : _mmss(s),
                            textDirection: s <= 0 ? null : ui.TextDirection.ltr,
                            style: _ExerciseCardState._ts(
                                theme,
                                sel ? 22 : 19,
                                sel ? FontWeight.w700 : FontWeight.w500,
                                sel ? theme.primaryText : theme.secondaryText),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _Pressable(
              onTap: () => Navigator.of(context).pop(_selected * 1000),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: theme.primary,
                    borderRadius: BorderRadius.circular(16)),
                child: Text(_tr(widget.lang, 'set'),
                    style: _ExerciseCardState._ts(
                        theme, 17, FontWeight.w700, Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Warm-up generator sheet (lean): header · [Added weight switch] · target
// weight −/+ · sets 1·2·3·4 · Generate · [Remove warm-up]
// =============================================================================

class _WarmupChoice {
  const _WarmupChoice(
      {required this.targetWeight, required this.numSets, this.remove = false});

  /// Loaded exercise: the working weight. Bodyweight: the added weight, or
  /// null when the switch is off.
  final double? targetWeight;
  final int numSets;
  final bool remove;
}

class _WarmupSheet extends StatefulWidget {
  const _WarmupSheet({
    required this.lang,
    required this.withWeight,
    required this.isBodyweight,
    required this.isKg,
    required this.equipKey,
    required this.title,
    required this.subtitle,
    required this.initialWeight,
    required this.hasExisting,
  });
  final String lang;
  final bool withWeight;
  final bool isBodyweight;
  final bool isKg;
  final String equipKey;
  final String title;
  final String subtitle;
  final double? initialWeight;
  final bool hasExisting;
  @override
  State<_WarmupSheet> createState() => _WarmupSheetState();
}

class _WarmupSheetState extends State<_WarmupSheet> {
  late double _weight = widget.initialWeight ?? 0;
  // bodyweight: the switch starts on only when a weight was already logged
  late bool _added = widget.isBodyweight && (widget.initialWeight ?? 0) > 0;
  int _sets = 3;
  late final TextEditingController _ctrl =
      TextEditingController(text: _weight > 0 ? _fmtW(_weight) : '');

  bool get _showWeight => widget.withWeight && (!widget.isBodyweight || _added);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _bump(bool up) {
    HapticFeedback.selectionClick();
    final step = _stepFor(widget.equipKey, widget.isKg, _weight);
    double w = (_weight + (up ? step : -step));
    if (w < 0) w = 0;
    w = (w / step).roundToDouble() * step;
    setState(() {
      _weight = w;
      _ctrl.text = w > 0 ? _fmtW(w) : '';
    });
  }

  void _reset() {
    HapticFeedback.selectionClick();
    setState(() {
      _weight = widget.initialWeight ?? 0;
      _ctrl.text = _weight > 0 ? _fmtW(_weight) : '';
      _sets = 3;
      _added = widget.isBodyweight && (widget.initialWeight ?? 0) > 0;
    });
  }

  Widget _round(
      IconData icon, VoidCallback onTap, Color border, Color fg, Color bg) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg,
            border: Border.all(color: border)),
        child: Icon(icon, size: 20, color: fg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bool rtl = _kRtl.contains(widget.lang);
    final double bottom = MediaQuery.of(context).padding.bottom;
    final double kb = MediaQuery.of(context).viewInsets.bottom;
    final Color border = theme.alternate;
    final Color field = theme.primaryBackground;
    final String unit = _tr(widget.lang, widget.isKg ? 'kg' : 'lbs');
    final TextStyle label =
        _ExerciseCardState._ts(theme, 15, FontWeight.w600, theme.primaryText);

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.only(bottom: kb),
        child: Container(
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                      color: theme.alternate,
                      borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 10),
              // header: X · title + "exercise · equipment" · reset
              Row(
                children: [
                  _Pressable(
                    onTap: () => Navigator.of(context).pop(),
                    child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.close_rounded,
                            size: 26, color: theme.primaryText)),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(_tr(widget.lang, 'warmupTitle'),
                            textAlign: TextAlign.center,
                            style: _ExerciseCardState._ts(
                                theme, 20, FontWeight.w700, theme.primaryText)),
                        Text(
                          [
                            widget.title,
                            if (widget.subtitle.isNotEmpty) widget.subtitle
                          ].join(' · '),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _ExerciseCardState._ts(
                              theme, 13, FontWeight.w400, theme.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  _Pressable(
                    onTap: _reset,
                    child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.restart_alt_rounded,
                            size: 24, color: theme.primaryText)),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // bodyweight only: Added weight switch
              if (widget.withWeight && widget.isBodyweight) ...[
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: field,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_tr(widget.lang, 'addedWeight'),
                                style: _ExerciseCardState._ts(theme, 16,
                                    FontWeight.w600, theme.primaryText)),
                            const SizedBox(height: 2),
                            Text(_tr(widget.lang, 'addedWeightSub'),
                                style: _ExerciseCardState._ts(theme, 13,
                                    FontWeight.w400, theme.secondaryText)),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _added,
                        activeColor: theme.primary,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _added = v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // target weight
              if (_showWeight) ...[
                Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: _tr(
                              widget.lang,
                              widget.isBodyweight
                                  ? 'targetAdded'
                                  : 'targetWeight')),
                      TextSpan(
                          text: ' ($unit)',
                          style: _ExerciseCardState._ts(
                              theme, 15, FontWeight.w500, theme.secondaryText)),
                    ]),
                    style: label),
                const SizedBox(height: 12),
                Row(
                  textDirection: ui.TextDirection.ltr,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _round(Icons.remove_rounded, () => _bump(false), border,
                        theme.primaryText, field),
                    Container(
                      width: 110,
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: field,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*$'))
                        ],
                        onChanged: (t) => _weight = double.tryParse(t) ?? 0,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        style: _ExerciseCardState._ts(
                            theme, 26, FontWeight.w700, theme.primaryText),
                        decoration: const InputDecoration(
                            isDense: true, border: InputBorder.none),
                      ),
                    ),
                    _round(Icons.add_rounded, () => _bump(true), border,
                        theme.primaryText, field),
                  ],
                ),
                const SizedBox(height: 18),
              ],

              // number of sets: segmented 1 · 2 · 3 · 4
              Text(_tr(widget.lang, 'warmupSets'), style: label),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: field, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  textDirection: ui.TextDirection.ltr,
                  children: [
                    for (int n = 1; n <= 4; n++) ...[
                      if (n > 1) const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (_sets == n) return;
                            HapticFeedback.selectionClick();
                            setState(() => _sets = n);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _sets == n
                                  ? theme.secondaryBackground
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _sets == n
                                  ? [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(0.10),
                                          blurRadius: 3,
                                          offset: const Offset(0, 1))
                                    ]
                                  : null,
                            ),
                            child: Text('$n',
                                style: _ExerciseCardState._ts(
                                    theme,
                                    16,
                                    _sets == n
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    _sets == n
                                        ? theme.primaryText
                                        : theme.secondaryText)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),

              _Pressable(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  Navigator.of(context).pop(_WarmupChoice(
                    targetWeight: _showWeight && _weight > 0 ? _weight : null,
                    numSets: _sets,
                  ));
                },
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(16)),
                  child: Text(_tr(widget.lang, 'generate'),
                      style: _ExerciseCardState._ts(
                          theme, 17, FontWeight.w700, Colors.white)),
                ),
              ),
              if (widget.hasExisting) ...[
                const SizedBox(height: 8),
                _Pressable(
                  onTap: () => Navigator.of(context).pop(const _WarmupChoice(
                      targetWeight: null, numSets: 0, remove: true)),
                  child: Container(
                    height: 46,
                    alignment: Alignment.center,
                    child: Text(_tr(widget.lang, 'removeWarmup'),
                        style: _ExerciseCardState._ts(theme, 15,
                            FontWeight.w600, const Color(0xFFEF4444))),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
