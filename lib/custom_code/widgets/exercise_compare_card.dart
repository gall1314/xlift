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

/// The "compared to previous" strip of ONE exercise inside ONE logged workout
/// (the row of stat columns at the top of each card in the exercise History
/// tab).
///
/// Replaces the rowOffline component.
///
/// Self-managed: reads set_log itself, finds the previous workout that
/// contains the same exercise, and compares the two. No FlutterFlow query and
/// no visibility rules needed.
///
/// Columns by kind of session, separated by thin divider lines: - Weighted:
/// Sets · Volume · Reps · Weight/rep - Bodyweight only: Sets · Total reps ·
/// Avg set · Best set - Timed:           Sets · Total time · Avg set
///
/// Bodyweight: total reps IS the volume of the workout (did I do more work
/// overall), reps per set shows what happened inside each set when the set
/// count changed, and best set is the most reps in one set.
///
/// Each column: label, value, change vs. the previous session (arrow +
/// amount), a bar in the column's own color, and the change in %. The bar is
/// this session against the previous one: it is full when this session is the
/// same or higher, and partly filled when it is lower. A value that cannot be
/// compared (no previous session, or a different kind of session) shows a
/// dash.
///
/// Rules: - A drop set is not counted as a set, but its reps and volume
/// count. - Weights are stored as typed, each with its own unit (is_kg); a
/// value is converted only when its unit is not the one the app shows.
///
/// HEIGHT: fixed layout, give the widget a height of 120.
///
/// Localization: reads the app language from FFLocalizations (no parameter);
/// Hebrew renders RTL, numbers stay left-to-right.
class ExerciseCompareCard extends StatefulWidget {
  const ExerciseCompareCard({
    super.key,
    this.width,
    this.height,
    required this.workoutLogId,
    required this.exerciseId,
  });

  final double? width;
  final double? height;
  final String workoutLogId;
  final int exerciseId;

  @override
  State<ExerciseCompareCard> createState() => _ExerciseCompareCardState();
}

// Bar color of each column (the colors of the old rowOffline component).
const Color _kSetsColor = Color(0xFF5BC0EB);
const Color _kVolumeColor = Color(0xFF00C896);
const Color _kRepsColor = Color(0xFF4A90E2);
const Color _kWeightColor = Color(0xFF00E096);

const Set<String> _kRtl = {'he', 'ar'};

const Map<String, Map<String, String>> _kStrings = {
  "sets": {
    "en": "Sets",
    "es": "Series",
    "he": "סטים",
    "de": "Sätze",
    "fr": "Séries",
  },
  "volume": {
    "en": "Volume",
    "es": "Volumen",
    "he": "נפח",
    "de": "Volumen",
    "fr": "Volume",
  },
  "reps": {
    "en": "Reps",
    "es": "Reps",
    "he": "חזרות",
    "de": "Wdh.",
    "fr": "Reps",
  },
  "weightRep": {
    "en": "Weight/rep",
    "es": "Peso/rep",
    "he": "משקל לחזרה",
    "de": "Gew./Wdh.",
    "fr": "Poids/rep",
  },
  "totalTime": {
    "en": "Total time",
    "es": "Tiempo total",
    "he": "זמן כולל",
    "de": "Gesamtzeit",
    "fr": "Temps total",
  },
  "avgSet": {
    "en": "Avg set",
    "es": "Media/serie",
    "he": "ממוצע לסט",
    "de": "Ø Satz",
    "fr": "Moy./série",
  },
  "totalReps": {
    "en": "Total reps",
    "es": "Reps totales",
    "he": "סה״כ חזרות",
    "de": "Wdh. gesamt",
    "fr": "Reps totales",
  },
  "bestSet": {
    "en": "Best set",
    "es": "Mejor serie",
    "he": "סט שיא",
    "de": "Bester Satz",
    "fr": "Meilleure série",
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
    "es": "lbs",
    "he": "ליב׳",
    "de": "lbs",
    "fr": "lbs",
  },
};

String _tr(String lang, String key) {
  final m = _kStrings[key];
  return m == null ? key : (m[lang] ?? m['en'] ?? key);
}

/// One saved set, as stored.
class _SetRow {
  _SetRow({
    required this.reps,
    required this.weight,
    required this.isKg,
    required this.seconds,
    required this.isDrop,
  });

  final int reps;
  final double weight;
  final bool isKg;
  final int seconds;
  final bool isDrop;
}

/// The totals of one exercise in one workout.
class _Agg {
  int rows = 0;
  int sets = 0; // drop sets not counted
  int reps = 0; // drop sets counted
  int maxReps = 0; // most reps in one set
  int timed = 0;
  int bodyweight = 0;
  int seconds = 0;
  double weighted = 0; // sum of reps x weight, in the unit on screen
  bool assisted = false;

  bool get isTimed => rows > 0 && timed == rows;
  bool get isBodyweight => assisted || (rows > 0 && bodyweight == rows);
  double? get avgWeight => (isBodyweight || reps <= 0) ? null : weighted / reps;
  double get avgSetReps => sets > 0 ? reps / sets : 0;
  double get avgSetSeconds =>
      seconds / (sets > 0 ? sets : (rows > 0 ? rows : 1));
}

/// One stat column. [prev] is null when there is nothing to compare with.
class _Tile {
  _Tile({
    required this.label,
    required this.value,
    this.unit = '',
    required this.curr,
    this.prev,
    this.isTime = false,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final double curr;
  final double? prev;
  final bool isTime;
  final Color color;
}

class _ExerciseCompareCardState extends State<ExerciseCompareCard> {
  List<_SetRow> _curr = [];
  List<_SetRow>? _prev; // null = no previous session
  bool _assisted = false;
  bool _loaded = false;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ExerciseCompareCard old) {
    super.didUpdateWidget(old);
    if (old.workoutLogId != widget.workoutLogId ||
        old.exerciseId != widget.exerciseId) {
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

  /// duration_seconds is written in milliseconds by the workout save; older
  /// rows may hold plain seconds. A single set of 1000+ seconds does not
  /// happen, so a value that large is milliseconds.
  static int _seconds(dynamic v) {
    final int raw = _int(v);
    if (raw <= 0) return 0;
    return raw >= 1000 ? (raw / 1000).round() : raw;
  }

  // ---------- data ----------
  Future<List<_SetRow>> _readSets(dynamic db, String logId) async {
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT * FROM set_log WHERE workout_log_id = ? '
      'AND CAST(exercise_id AS INTEGER) = ?',
      [logId, widget.exerciseId],
    );
    return rows.map((r) {
      final String kgRaw = (r['is_kg'] ?? '').toString().trim();
      return _SetRow(
        reps: _int(r['reps']),
        weight: _dbl(r['weight']),
        isKg: kgRaw.isEmpty ? true : _int(kgRaw) != 0,
        seconds: _seconds(r['duration_seconds']),
        isDrop: _int(r['is_dropset']) == 1,
      );
    }).toList();
  }

  Future<void> _load() async {
    final int token = ++_token;
    final String logId = widget.workoutLogId.trim();
    List<_SetRow> curr = [];
    List<_SetRow>? prev;
    bool assisted = false;

    try {
      final db = SQLiteManager.instance.database;

      try {
        final ex = await db.rawQuery(
          'SELECT is_assisted FROM exercise WHERE id = ?',
          [widget.exerciseId],
        );
        if (ex.isNotEmpty) assisted = _int(ex.first['is_assisted']) == 1;
      } catch (_) {}

      curr = await _readSets(db, logId);

      // The previous workout of the same user that has this exercise.
      // Timestamps are normalized first: some are stored with a 'T' and
      // some with a space, and a raw string compare gets those wrong.
      try {
        const String ts =
            "COALESCE(datetime(replace(wl.created_at, ' ', 'T')), wl.created_at)";
        const String myTs =
            "COALESCE(datetime(replace(me.created_at, ' ', 'T')), me.created_at)";
        final found = await db.rawQuery(
          'SELECT wl.id AS id FROM workout_log wl '
          'JOIN workout_log me ON me.id = ? '
          'WHERE wl.user_id = me.user_id AND wl.id <> me.id '
          'AND $ts < $myTs '
          'AND EXISTS (SELECT 1 FROM set_log s '
          'WHERE s.workout_log_id = wl.id '
          'AND CAST(s.exercise_id AS INTEGER) = ?) '
          'ORDER BY $ts DESC LIMIT 1',
          [logId, widget.exerciseId],
        );
        if (found.isNotEmpty) {
          final String prevId = (found.first['id'] ?? '').toString();
          if (prevId.isNotEmpty) {
            final rows = await _readSets(db, prevId);
            if (rows.isNotEmpty) prev = rows;
          }
        }
      } catch (_) {}
    } catch (_) {}

    if (!mounted || token != _token) return;
    setState(() {
      _curr = curr;
      _prev = prev;
      _assisted = assisted;
      _loaded = true;
    });
  }

  _Agg _aggregate(List<_SetRow> rows, bool showKg) {
    final a = _Agg()..assisted = _assisted;
    for (final s in rows) {
      a.rows++;
      if (!s.isDrop) a.sets++;
      a.reps += s.reps;
      if (s.reps > a.maxReps) a.maxReps = s.reps;
      if (s.seconds > 0) {
        a.timed++;
        a.seconds += s.seconds;
      }
      if (s.weight <= 0) {
        a.bodyweight++;
      } else {
        // Stored as typed; converted only when the set's unit is not the
        // one on screen.
        final double w = s.isKg == showKg
            ? s.weight
            : (s.isKg ? s.weight * 2.20462 : s.weight * 0.453592);
        a.weighted += w * s.reps;
      }
    }
    return a;
  }

  // ---------- formatting ----------
  static double _round1(double v) => (v * 10).round() / 10;

  static String _num(double v) {
    final double r = _round1(v);
    return r == r.roundToDouble() ? r.toInt().toString() : r.toStringAsFixed(1);
  }

  static String _mmss(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  static String _signed(double v) {
    final double r = _round1(v);
    if (r > 0) return '+${_num(r)}';
    if (r < 0) return '-${_num(-r)}';
    return '0';
  }

  static String _signedTime(double seconds) {
    final int s = seconds.round();
    if (s > 0) return '+${_mmss(s)}';
    if (s < 0) return '-${_mmss(-s)}';
    return '0:00';
  }

  TextStyle _st(BuildContext ctx, double size, FontWeight w, Color c) {
    final th = FlutterFlowTheme.of(ctx);
    return th.bodyMedium.override(
      fontFamily: th.bodyMediumFamily,
      color: c,
      fontSize: size,
      fontWeight: w,
      letterSpacing: 0,
      useGoogleFonts: GoogleFonts.asMap().containsKey(th.bodyMediumFamily),
    );
  }

  // ---------- columns ----------
  List<_Tile> _tiles(String lang, bool showKg) {
    final _Agg c = _aggregate(_curr, showKg);
    final _Agg? p = _prev == null ? null : _aggregate(_prev!, showKg);
    final String unit = _tr(lang, showKg ? 'kg' : 'lbs');

    final _Tile sets = _Tile(
      label: _tr(lang, 'sets'),
      value: '${c.sets}',
      curr: c.sets.toDouble(),
      prev: p?.sets.toDouble(),
      color: _kSetsColor,
    );

    if (c.isTimed) {
      final bool cmp = p != null && p.isTimed;
      return [
        sets,
        _Tile(
          label: _tr(lang, 'totalTime'),
          value: _mmss(c.seconds),
          curr: c.seconds.toDouble(),
          prev: cmp ? p.seconds.toDouble() : null,
          isTime: true,
          color: _kVolumeColor,
        ),
        _Tile(
          label: _tr(lang, 'avgSet'),
          value: _mmss(c.avgSetSeconds.round()),
          curr: c.avgSetSeconds.roundToDouble(),
          prev: cmp ? p.avgSetSeconds.roundToDouble() : null,
          isTime: true,
          color: _kWeightColor,
        ),
      ];
    }

    final _Tile reps = _Tile(
      label: _tr(lang, 'reps'),
      value: '${c.reps}',
      curr: c.reps.toDouble(),
      prev: (p != null && !p.isTimed) ? p.reps.toDouble() : null,
      color: _kRepsColor,
    );

    if (c.isBodyweight) {
      final bool cmp = p != null && !p.isTimed && p.sets > 0;
      return [
        sets,
        // total reps = the volume of a bodyweight workout
        _Tile(
          label: _tr(lang, 'totalReps'),
          value: '${c.reps}',
          curr: c.reps.toDouble(),
          prev: (p != null && !p.isTimed) ? p.reps.toDouble() : null,
          color: _kVolumeColor,
        ),
        _Tile(
          label: _tr(lang, 'avgSet'),
          value: _num(c.avgSetReps),
          curr: _round1(c.avgSetReps),
          prev: cmp ? _round1(p.avgSetReps) : null,
          color: _kRepsColor,
        ),
        _Tile(
          label: _tr(lang, 'bestSet'),
          value: '${c.maxReps}',
          curr: c.maxReps.toDouble(),
          prev: cmp ? p.maxReps.toDouble() : null,
          color: _kWeightColor,
        ),
      ];
    }

    final bool sameKind = p != null && !p.isTimed && !p.isBodyweight;
    final double avg = c.avgWeight ?? 0;
    return [
      sets,
      _Tile(
        label: _tr(lang, 'volume'),
        value: _num(c.weighted),
        unit: unit,
        curr: c.weighted,
        prev: sameKind ? p.weighted : null,
        color: _kVolumeColor,
      ),
      reps,
      _Tile(
        label: _tr(lang, 'weightRep'),
        value: _num(avg),
        unit: unit,
        curr: avg,
        prev: sameKind ? p.avgWeight : null,
        color: _kWeightColor,
      ),
    ];
  }

  Widget _bar(BuildContext ctx, _Tile t) {
    final th = FlutterFlowTheme.of(ctx);
    double frac = 1;
    final double? prev = t.prev;
    if (prev != null) {
      final double top = math.max(t.curr, prev);
      frac = top <= 0 ? 0 : (t.curr / top).clamp(0.0, 1.0).toDouble();
    }
    return SizedBox(
      height: 12,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: th.alternate,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: frac,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: t.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext ctx, _Tile t) {
    final th = FlutterFlowTheme.of(ctx);
    final bool dark = Theme.of(ctx).brightness == Brightness.dark;
    final Color up = dark ? th.primary : const Color(0xFF007A5E);

    final double? prev = t.prev;
    int sign = 0;
    String change = '-';
    String percent = '-';
    if (prev != null) {
      final double diff =
          t.isTime ? (t.curr - prev).roundToDouble() : _round1(t.curr - prev);
      sign = diff > 0 ? 1 : (diff < 0 ? -1 : 0);
      change = t.isTime ? _signedTime(diff) : _signed(diff);
      if (prev > 0) {
        percent = '${_signed((t.curr - prev) / prev * 100)}%';
      }
    }
    final Color tone = sign > 0 ? up : th.secondaryText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 15,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                t.label,
                maxLines: 1,
                style: _st(ctx, 11.5, FontWeight.w500, th.secondaryText),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 28,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    t.value,
                    textDirection: ui.TextDirection.ltr,
                    style: _st(ctx, 22, FontWeight.w700, th.primaryText),
                  ),
                  if (t.unit.isNotEmpty) ...[
                    const SizedBox(width: 3),
                    Text(
                      t.unit,
                      style: _st(ctx, 11, FontWeight.w500, th.secondaryText),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 18,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Directionality(
                textDirection: ui.TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (sign != 0)
                      Icon(
                        sign > 0
                            ? Icons.arrow_drop_up_rounded
                            : Icons.arrow_drop_down_rounded,
                        size: 18,
                        color: tone,
                      ),
                    Text(
                      change,
                      style: _st(ctx, 12.5, FontWeight.w600, tone),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          _bar(ctx, t),
          const SizedBox(height: 5),
          SizedBox(
            height: 16,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                percent,
                textDirection: ui.TextDirection.ltr,
                maxLines: 1,
                style: _st(ctx, 12, FontWeight.w600, tone),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    String lang = 'en';
    try {
      final l = FFLocalizations.of(context).languageCode.trim().toLowerCase();
      if (l.isNotEmpty) lang = l;
    } catch (_) {}
    final bool rtl = _kRtl.contains(lang);

    bool showKg = true;
    try {
      showKg = FFAppState().isKg;
    } catch (_) {}

    Widget body;
    if (!_loaded || _curr.isEmpty) {
      body = const SizedBox.shrink();
    } else {
      final List<_Tile> tiles = _tiles(lang, showKg);
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            if (i > 0)
              Container(
                width: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: th.alternate,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            Expanded(child: _tile(context, tiles[i])),
          ],
        ],
      );
    }

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: body,
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
