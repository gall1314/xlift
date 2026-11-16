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

/// The "Personal Records" card of the exercise page (Analytics tab).
///
/// Self-managed: reads the exercise's sets from SQLite itself and shows the
/// three records that fit the kind of exercise:
/// - weighted:   most reps in a set, heaviest weight, most volume in a workout
/// - bodyweight: most reps in a set, most reps in a workout, average per set
/// - timed:      longest set, average set time, most time in a workout
/// - assisted:   most reps in a set, most reps in a workout, least assistance
///
/// Parameters:
/// - exerciseId, userId
/// - timeRange: the same value the page queries get ('Last 7 days',
///   'Last 30 days', 'Last 90 days'; anything else = all time).
///
/// Units: every weight is stored as typed with its own unit (set_log.is_kg)
/// and converted here to the app unit (FFAppState().isKg). A drop set is not
/// a separate set, but its reps and weight count.
///
/// Localization: reads the app language from FFLocalizations (no parameter).
/// Hebrew renders RTL.
class ExercisePersonalRecords extends StatefulWidget {
  const ExercisePersonalRecords({
    super.key,
    this.width,
    this.height,
    required this.exerciseId,
    required this.userId,
    this.timeRange,
  });

  final double? width;
  final double? height;
  final int exerciseId;
  final String userId;
  final String? timeRange;

  @override
  State<ExercisePersonalRecords> createState() =>
      _ExercisePersonalRecordsState();
}

const Set<String> _kRtl = {'he', 'ar'};

const double _kKgPerLb = 0.45359237;

const Map<String, Map<String, String>> _kStrings = {
  "title": {
    "en": "Personal Records",
    "es": "Récords personales",
    "he": "שיאים אישיים",
    "de": "Persönliche Rekorde",
    "fr": "Records personnels",
  },
  "maxReps": {
    "en": "Most reps in a set",
    "es": "Más reps en una serie",
    "he": "הכי הרבה חזרות בסט",
    "de": "Meiste Wdh. pro Satz",
    "fr": "Max reps par série",
  },
  "maxWeight": {
    "en": "Heaviest weight",
    "es": "Peso máximo",
    "he": "משקל מקסימלי",
    "de": "Höchstes Gewicht",
    "fr": "Poids max",
  },
  "maxVolume": {
    "en": "Most volume in a workout",
    "es": "Más volumen en un entreno",
    "he": "נפח מקסימלי באימון",
    "de": "Meistes Volumen pro Workout",
    "fr": "Volume max par séance",
  },
  "maxSessionReps": {
    "en": "Most reps in a workout",
    "es": "Más reps en un entreno",
    "he": "הכי הרבה חזרות באימון",
    "de": "Meiste Wdh. pro Workout",
    "fr": "Max reps par séance",
  },
  "avgReps": {
    "en": "Average reps per set",
    "es": "Media de reps por serie",
    "he": "ממוצע חזרות לסט",
    "de": "Ø Wdh. pro Satz",
    "fr": "Moyenne de reps par série",
  },
  "maxDuration": {
    "en": "Longest set",
    "es": "Serie más larga",
    "he": "הסט הארוך ביותר",
    "de": "Längster Satz",
    "fr": "Série la plus longue",
  },
  "avgDuration": {
    "en": "Average set time",
    "es": "Tiempo medio por serie",
    "he": "זמן ממוצע לסט",
    "de": "Ø Satzdauer",
    "fr": "Durée moyenne par série",
  },
  "maxSessionTime": {
    "en": "Most time in a workout",
    "es": "Más tiempo en un entreno",
    "he": "הכי הרבה זמן באימון",
    "de": "Längste Zeit pro Workout",
    "fr": "Temps max par séance",
  },
  "minAssist": {
    "en": "Least assistance",
    "es": "Asistencia mínima",
    "he": "הכי מעט עזרה",
    "de": "Geringste Hilfe",
    "fr": "Assistance minimale",
  },
  "reps": {
    "en": "reps",
    "es": "reps",
    "he": "חזרות",
    "de": "Wdh.",
    "fr": "reps",
  },
  "kg": {
    "en": "kg",
    "es": "kg",
    "he": "ק״ג",
    "de": "kg",
    "fr": "kg",
  },
  "lbs": {
    "en": "lbs",
    "es": "lb",
    "he": "ליב׳",
    "de": "lbs",
    "fr": "lb",
  },
  "sec": {
    "en": "sec",
    "es": "s",
    "he": "שנ׳",
    "de": "Sek.",
    "fr": "s",
  },
  "min": {
    "en": "min",
    "es": "min",
    "he": "דק׳",
    "de": "Min.",
    "fr": "min",
  },
  "hr": {
    "en": "hr",
    "es": "h",
    "he": "שע׳",
    "de": "Std.",
    "fr": "h",
  },
};

String _tr(String lang, String key) {
  final m = _kStrings[key];
  return m == null ? key : (m[lang] ?? m['en'] ?? key);
}

class _SetRow {
  const _SetRow({
    required this.workoutLogId,
    required this.reps,
    required this.weight,
    required this.isKg,
    required this.seconds,
    required this.isDrop,
  });

  final String workoutLogId;
  final int reps;
  final double weight; // as typed, in its own unit
  final bool isKg;
  final double seconds;
  final bool isDrop;
}

class _Record {
  const _Record(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class _ExercisePersonalRecordsState extends State<ExercisePersonalRecords> {
  List<_SetRow> _rows = [];
  bool _isTimed = false;
  bool _isAssisted = false;
  bool _isBodyweightExercise = false;
  bool _loaded = false;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ExercisePersonalRecords old) {
    super.didUpdateWidget(old);
    if (old.exerciseId != widget.exerciseId ||
        old.userId != widget.userId ||
        old.timeRange != widget.timeRange) {
      _load();
    }
  }

  // ---------- parsing ----------
  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.round();
    return num.tryParse(v.toString().trim())?.round() ?? 0;
  }

  static double _dbl(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim()) ?? 0;
  }

  static String _str(dynamic v) => v == null ? '' : v.toString().trim();

  /// 1 / '1' / true / 'true' -> true. [fallback] when the value is empty.
  static bool _flag(dynamic v, {bool fallback = false}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    final String s = v.toString().trim().toLowerCase();
    if (s.isEmpty) return fallback;
    return s == '1' || s == 'true';
  }

  static DateTime? _parseDate(dynamic v) {
    String s = _str(v);
    if (s.isEmpty) return null;
    if (RegExp(r'^\d+$').hasMatch(s)) {
      final int? ms = int.tryParse(s);
      return ms == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    }
    if (s.length > 10 && s[10] == ' ') s = s.replaceFirst(' ', 'T');
    final DateTime? dt = DateTime.tryParse(s);
    if (dt == null) return null;
    return dt.isUtc ? dt.toLocal() : dt;
  }

  /// Days back for the page's time range; null = all time.
  int? _rangeDays() {
    final String r = (widget.timeRange ?? '').trim().toLowerCase();
    if (r.contains('90')) return 90;
    if (r.contains('30')) return 30;
    if (r.contains('7')) return 7;
    return null;
  }

  // ---------- data ----------
  Future<void> _load() async {
    final int token = ++_token;
    final List<_SetRow> out = [];
    bool timed = false;
    bool assisted = false;
    bool bodyweight = false;

    try {
      final db = SQLiteManager.instance.database;

      try {
        final exRows = await db.rawQuery(
          'SELECT * FROM exercise WHERE id = ? LIMIT 1',
          [widget.exerciseId],
        );
        if (exRows.isNotEmpty) {
          final r = exRows.first;
          timed = _flag(r['is_time_based']);
          assisted = _flag(r['is_assisted']);
          bodyweight = _flag(r['is_bodyweight']);
        }
      } catch (_) {}

      final rows = await db.rawQuery(
        'SELECT sl.*, wl.created_at AS wl_created_at '
        'FROM set_log sl '
        'JOIN workout_log wl ON wl.id = sl.workout_log_id '
        'WHERE sl.exercise_id = ? AND wl.user_id = ?',
        [widget.exerciseId, widget.userId],
      );

      final int? days = _rangeDays();
      final DateTime now = DateTime.now();
      final DateTime? from =
          days == null ? null : now.subtract(Duration(days: days));

      for (final r in rows) {
        if (from != null) {
          final DateTime? at = _parseDate(r['wl_created_at']);
          if (at == null || at.isBefore(from) || at.isAfter(now)) continue;
        }
        double seconds = _dbl(r['duration_seconds']);
        // Old rows hold milliseconds in this column.
        if (seconds >= 1000) seconds = seconds / 1000;
        out.add(_SetRow(
          workoutLogId: _str(r['workout_log_id']),
          reps: _int(r['reps']),
          weight: _dbl(r['weight']),
          isKg: _flag(r['is_kg'], fallback: true),
          seconds: seconds,
          isDrop: _flag(r['is_dropset']),
        ));
      }
    } catch (_) {}

    if (!mounted || token != _token) return;
    setState(() {
      _rows = out;
      _isTimed = timed;
      _isAssisted = assisted;
      _isBodyweightExercise = bodyweight;
      _loaded = true;
    });
  }

  // ---------- formatting ----------
  bool get _appIsKg {
    try {
      return FFAppState().isKg;
    } catch (_) {
      return true;
    }
  }

  /// A stored weight in the app unit.
  double _weight(_SetRow r, bool appKg) {
    if (r.isKg == appKg) return r.weight;
    return appKg ? r.weight * _kKgPerLb : r.weight / _kKgPerLb;
  }

  /// 1400 -> "1,400", 122.5 -> "122.5", 120.0 -> "120".
  String _num(double v, {int decimals = 0}) {
    String s = v.toStringAsFixed(decimals);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    final List<String> parts = s.split('.');
    final String whole = parts[0];
    final StringBuffer b = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) b.write(',');
      b.write(whole[i]);
    }
    return parts.length > 1 ? '${b.toString()}.${parts[1]}' : b.toString();
  }

  /// "45 sec", "1:30 min", "1:05:00 hr". The digits stay left-to-right.
  String _duration(String lang, double seconds) {
    final int s = seconds.round();
    if (s < 60) return '$s ${_tr(lang, 'sec')}';
    final int h = s ~/ 3600;
    final int m = (s % 3600) ~/ 60;
    final String ss = (s % 60).toString().padLeft(2, '0');
    if (h > 0) {
      final String mm = m.toString().padLeft(2, '0');
      return '\u2066$h:$mm:$ss\u2069 ${_tr(lang, 'hr')}';
    }
    return '\u2066$m:$ss\u2069 ${_tr(lang, 'min')}';
  }

  // ---------- records ----------
  List<_Record> _records(String lang) {
    const String dash = '—';
    final bool appKg = _appIsKg;
    final String unit = _tr(lang, appKg ? 'kg' : 'lbs');
    final String repsUnit = _tr(lang, 'reps');

    int maxReps = 0;
    int totalReps = 0;
    int repSets = 0; // sets with reps, drops not counted as sets
    final Map<String, int> repsByWorkout = {};
    for (final r in _rows) {
      if (r.reps <= 0) continue;
      maxReps = math.max(maxReps, r.reps);
      totalReps += r.reps;
      if (!r.isDrop) repSets++;
      repsByWorkout[r.workoutLogId] =
          (repsByWorkout[r.workoutLogId] ?? 0) + r.reps;
    }
    int maxSessionReps = 0;
    for (final v in repsByWorkout.values) {
      maxSessionReps = math.max(maxSessionReps, v);
    }

    final _Record recMaxReps = _Record(
      _tr(lang, 'maxReps'),
      maxReps > 0 ? '$maxReps $repsUnit' : dash,
      Icons.trending_up_rounded,
    );
    final _Record recSessionReps = _Record(
      _tr(lang, 'maxSessionReps'),
      maxSessionReps > 0
          ? '${_num(maxSessionReps.toDouble())} $repsUnit'
          : dash,
      Icons.bar_chart_rounded,
    );

    // --- timed ---
    if (_isTimed) {
      double longest = 0;
      double total = 0;
      int sets = 0;
      final Map<String, double> byWorkout = {};
      for (final r in _rows) {
        if (r.seconds <= 0) continue;
        longest = math.max(longest, r.seconds);
        total += r.seconds;
        if (!r.isDrop) sets++;
        byWorkout[r.workoutLogId] =
            (byWorkout[r.workoutLogId] ?? 0) + r.seconds;
      }
      double best = 0;
      for (final v in byWorkout.values) {
        best = math.max(best, v);
      }
      final double avg = sets > 0 ? total / sets : 0;
      return [
        _Record(
            _tr(lang, 'maxDuration'),
            longest > 0 ? _duration(lang, longest) : dash,
            Icons.timer_outlined),
        _Record(_tr(lang, 'avgDuration'), avg > 0 ? _duration(lang, avg) : dash,
            Icons.av_timer_rounded),
        _Record(_tr(lang, 'maxSessionTime'),
            best > 0 ? _duration(lang, best) : dash, Icons.bar_chart_rounded),
      ];
    }

    // --- assisted ---
    if (_isAssisted) {
      double least = 0;
      for (final r in _rows) {
        final double w = _weight(r, appKg);
        if (w <= 0) continue;
        least = least == 0 ? w : math.min(least, w);
      }
      return [
        recMaxReps,
        recSessionReps,
        _Record(
          _tr(lang, 'minAssist'),
          least > 0 ? '${_num(least, decimals: 1)} $unit' : dash,
          Icons.fitness_center_rounded,
        ),
      ];
    }

    // --- bodyweight: most sets in range carry no weight ---
    int weightedSets = 0;
    for (final r in _rows) {
      if (r.weight > 0) weightedSets++;
    }
    final bool bodyweight = _rows.isEmpty
        ? _isBodyweightExercise
        : (weightedSets / _rows.length) < 0.5;

    if (bodyweight) {
      // Rounded to the nearest half, like before.
      final double avg =
          repSets > 0 ? (totalReps / repSets * 2).round() / 2.0 : 0;
      return [
        recMaxReps,
        recSessionReps,
        _Record(
          _tr(lang, 'avgReps'),
          avg > 0 ? '${_num(avg, decimals: 1)} $repsUnit' : dash,
          Icons.functions_rounded,
        ),
      ];
    }

    // --- weighted ---
    double maxWeight = 0;
    final Map<String, double> volumeByWorkout = {};
    for (final r in _rows) {
      final double w = _weight(r, appKg);
      if (w > maxWeight) maxWeight = w;
      if (r.reps > 0 && w > 0) {
        volumeByWorkout[r.workoutLogId] =
            (volumeByWorkout[r.workoutLogId] ?? 0) + r.reps * w;
      }
    }
    double maxVolume = 0;
    for (final v in volumeByWorkout.values) {
      maxVolume = math.max(maxVolume, v);
    }
    return [
      recMaxReps,
      _Record(
        _tr(lang, 'maxWeight'),
        maxWeight > 0 ? '${_num(maxWeight, decimals: 1)} $unit' : dash,
        Icons.fitness_center_rounded,
      ),
      _Record(
        _tr(lang, 'maxVolume'),
        maxVolume > 0 ? '${_num(maxVolume)} $unit' : dash,
        Icons.bar_chart_rounded,
      ),
    ];
  }

  // ---------- build ----------
  TextStyle _st(double size, FontWeight w, Color c) {
    final th = FlutterFlowTheme.of(context);
    return th.bodyMedium.override(
      fontFamily: th.bodyMediumFamily,
      color: c,
      fontSize: size,
      fontWeight: w,
      letterSpacing: 0,
      useGoogleFonts: GoogleFonts.asMap().containsKey(th.bodyMediumFamily),
    );
  }

  Widget _row(_Record r) {
    final th = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _st(14, FontWeight.w400, th.secondaryText),
                ),
                const SizedBox(height: 2),
                Text(
                  r.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _st(22, FontWeight.w700, th.primary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(r.icon, size: 24, color: th.primary),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    String lang = 'en';
    try {
      final c = FFLocalizations.of(context).languageCode.trim().toLowerCase();
      if (c.isNotEmpty) lang = c;
    } catch (_) {}
    final bool rtl = _kRtl.contains(lang);
    final List<_Record> records = _loaded ? _records(lang) : const [];

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Container(
        width: widget.width,
        height: widget.height,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        decoration: BoxDecoration(
          color: th.secondaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: th.alternate),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    _tr(lang, 'title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _st(18, FontWeight.w600, th.primaryText),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.emoji_events_rounded, size: 24, color: th.primary),
              ],
            ),
            const SizedBox(height: 6),
            for (int i = 0; i < records.length; i++) ...[
              if (i > 0) Container(height: 1, color: th.alternate),
              _row(records[i]),
            ],
          ],
        ),
      ),
    );
  }
}

// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
