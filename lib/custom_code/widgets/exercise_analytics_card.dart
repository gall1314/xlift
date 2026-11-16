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
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

/// The whole "Exercise Analytics" card as one self-managed widget: title,
/// choice chips, line chart and the three numbers under it.
///
/// It reads the exercise and its logged sets itself (one point per workout)
/// and picks the chips by the kind of exercise: - weighted:   Reps · Max
/// weight · Volume - assisted:   Reps · Assistance · Volume (reps weighed by
/// the assistance) - bodyweight: Reps · Best set - timed:      Total time ·
/// Longest set
///
/// Under the chart: last 7 days · best workout · improvement (first workout
/// in the range against the last one). Drop sets count in reps and volume.
/// With no data in the range the chart area shows a placeholder.
///
/// Parameters: - exerciseId (int) - userId (String) - timeRange (String,
/// optional): the stored range value. Any text with 7 / 30 / 90 in it means
/// that many days; anything else means all time.
///
/// Localization: reads the app language from FFLocalizations (no parameter).
class ExerciseAnalyticsCard extends StatefulWidget {
  const ExerciseAnalyticsCard({
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
  State<ExerciseAnalyticsCard> createState() => _ExerciseAnalyticsCardState();
}

const Set<String> _kRtl = {"he", "ar"};

const Map<String, Map<String, String>> _kStrings = {
  "title": {
    "en": "Exercise Analytics",
    "es": "Análisis del ejercicio",
    "he": "ניתוח התרגיל",
    "de": "Übungsanalyse",
    "fr": "Analyse de l’exercice",
  },
  "sub": {
    "en": "Track your progress over time",
    "es": "Sigue tu progreso en el tiempo",
    "he": "עקבו אחר ההתקדמות שלכם לאורך זמן",
    "de": "Verfolge deinen Fortschritt",
    "fr": "Suivez vos progrès dans le temps",
  },
  "reps": {
    "en": "Reps",
    "es": "Reps",
    "he": "חזרות",
    "de": "Wdh.",
    "fr": "Reps",
  },
  "maxWeight": {
    "en": "Max Weight",
    "es": "Peso máx.",
    "he": "משקל מקסימלי",
    "de": "Max. Gewicht",
    "fr": "Poids max",
  },
  "volume": {
    "en": "Volume",
    "es": "Volumen",
    "he": "נפח",
    "de": "Volumen",
    "fr": "Volume",
  },
  "assist": {
    "en": "Assistance",
    "es": "Asistencia",
    "he": "סיוע",
    "de": "Unterstützung",
    "fr": "Assistance",
  },
  "bestSet": {
    "en": "Best set",
    "es": "Mejor serie",
    "he": "סט שיא",
    "de": "Bester Satz",
    "fr": "Meilleure série",
  },
  "totalTime": {
    "en": "Total time",
    "es": "Tiempo total",
    "he": "זמן כולל",
    "de": "Gesamtzeit",
    "fr": "Temps total",
  },
  "longest": {
    "en": "Longest set",
    "es": "Serie más larga",
    "he": "הסט הארוך",
    "de": "Längster Satz",
    "fr": "Série la plus longue",
  },
  "empty": {
    "en": "No data in this range yet",
    "es": "Aún no hay datos en este periodo",
    "he": "אין עדיין נתונים בטווח הזה",
    "de": "Noch keine Daten in diesem Zeitraum",
    "fr": "Pas encore de données sur cette période",
  },
  "week": {
    "en": "Last 7 days",
    "es": "Últimos 7 días",
    "he": "7 ימים אחרונים",
    "de": "Letzte 7 Tage",
    "fr": "7 derniers jours",
  },
  "best": {
    "en": "Best workout",
    "es": "Mejor entreno",
    "he": "האימון הטוב ביותר",
    "de": "Bestes Workout",
    "fr": "Meilleure séance",
  },
  "improve": {
    "en": "Improvement",
    "es": "Mejora",
    "he": "שיפור",
    "de": "Fortschritt",
    "fr": "Progression",
  },
  "repsUnit": {
    "en": "reps",
    "es": "reps",
    "he": "חזרות",
    "de": "Wdh.",
    "fr": "reps",
  },
};

/// One logged set, already cleaned up.
class _SetRow {
  _SetRow(this.logId, this.when, this.reps, this.weight, this.seconds);
  final String logId;
  final DateTime when;
  final int reps;
  final double weight; // in the app's unit, 0 when none
  final int seconds; // 0 when not timed
}

/// One workout of this exercise: everything a chip can chart.
class _Session {
  _Session(this.when);
  DateTime when;
  int reps = 0;
  int maxReps = 0;
  double volume = 0;
  double maxWeight = 0;
  double assistSum = 0;
  int assistCount = 0;
  double score = 0; // assisted: reps weighed by the assistance
  int seconds = 0;
  int maxSeconds = 0;
}

/// A chip: its label key and the value it charts for a workout.
class _Metric {
  const _Metric(this.key, this.value, this.isTime);
  final String key;
  final double Function(_Session s) value;
  final bool isTime;
}

class _ExerciseAnalyticsCardState extends State<ExerciseAnalyticsCard> {
  bool _isTimed = false;
  bool _isAssisted = false;
  bool _isBodyweightFlag = false;
  List<_SetRow> _sets = [];
  int _metric = 0;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ExerciseAnalyticsCard old) {
    super.didUpdateWidget(old);
    if (old.exerciseId != widget.exerciseId || old.userId != widget.userId) {
      _metric = 0;
      _load();
    }
  }

  // ---------- parsing ----------
  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return double.tryParse(v.toString().trim())?.toInt() ?? 0;
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim()) ?? 0;
  }

  static bool _truthy(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final String s = v.toString().trim().toLowerCase();
    return s == "true" || s == "1";
  }

  /// ISO text ("2026-11-10 12:00:00" / with a T) or an epoch in s / ms.
  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    if (v is num) {
      final int n = v.toInt();
      if (n <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(
          n >= 1000000000000 ? n : n * 1000);
    }
    final String s = v.toString().trim();
    if (s.isEmpty) return null;
    final int? n = int.tryParse(s);
    if (n != null) return _asDate(n);
    final DateTime? d = DateTime.tryParse(s.replaceFirst(" ", "T"));
    return d?.toLocal();
  }

  // ---------- data ----------
  Future<void> _load() async {
    final int token = ++_token;
    final int exerciseId = widget.exerciseId;
    final String uid = widget.userId;
    final bool appKg = FFAppState().isKg;

    bool timed = false;
    bool assisted = false;
    bool bodyweight = false;
    final List<_SetRow> out = [];

    try {
      final db = SQLiteManager.instance.database;
      final ex = await db.rawQuery(
        "SELECT * FROM exercise WHERE CAST(id AS INTEGER) = ? LIMIT 1",
        [exerciseId],
      );
      if (ex.isNotEmpty) {
        final r = ex.first;
        timed = _truthy(r["is_time_based"]);
        assisted = _truthy(r["is_assisted"]);
        bodyweight = _truthy(r["is_bodyweight"]);
      }

      final rows = await db.rawQuery(
        "SELECT sl.reps, sl.weight, sl.duration_seconds, sl.is_kg, "
        "sl.workout_log_id, wl.created_at AS wl_created_at "
        "FROM set_log sl "
        "JOIN workout_log wl ON wl.id = sl.workout_log_id "
        "WHERE CAST(sl.exercise_id AS INTEGER) = ? "
        "AND CAST(wl.user_id AS TEXT) = ?",
        [exerciseId, uid],
      );
      for (final r in rows) {
        final DateTime? when = _asDate(r["wl_created_at"]);
        if (when == null) continue;

        // stored in the unit it was logged in: convert to the app's unit
        double w = _asDouble(r["weight"]);
        if (w > 0) {
          final dynamic rawKg = r["is_kg"];
          final bool loggedKg = rawKg == null ? true : _truthy(rawKg);
          if (loggedKg && !appKg) w = w * 2.20462;
          if (!loggedKg && appKg) w = w / 2.20462;
        } else {
          w = 0;
        }

        // 1000 and up was saved in milliseconds
        int sec = _asInt(r["duration_seconds"]);
        if (sec >= 1000) sec = (sec / 1000).round();
        if (sec < 0) sec = 0;

        int reps = _asInt(r["reps"]);
        if (reps < 0) reps = 0;

        out.add(_SetRow(
            (r["workout_log_id"] ?? "").toString(), when, reps, w, sec));
      }
    } catch (_) {}

    if (!mounted || token != _token) return;
    setState(() {
      _isTimed = timed;
      _isAssisted = assisted;
      _isBodyweightFlag = bodyweight;
      _sets = out;
    });
  }

  /// Days in the selected range, 0 = all time.
  int _rangeDays() {
    final String raw = widget.timeRange ?? "";
    final RegExpMatch? m = RegExp(r"\d+").firstMatch(raw);
    if (m == null) return 0;
    return int.tryParse(m.group(0) ?? "") ?? 0;
  }

  static String _clock(int seconds) {
    final int s = seconds < 0 ? 0 : seconds;
    final int h = s ~/ 3600;
    final int m = (s % 3600) ~/ 60;
    final String ss = (s % 60).toString().padLeft(2, "0");
    if (h > 0) {
      return h.toString() + ":" + m.toString().padLeft(2, "0") + ":" + ss;
    }
    return m.toString() + ":" + ss;
  }

  /// Left-to-right isolate: keeps a number / time intact in a Hebrew line.
  static String _ltr(String s) => "\u2066" + s + "\u2069";

  // ---------- styling ----------
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

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    final th = FlutterFlowTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? th.primary : th.primaryBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: _st(
              15, FontWeight.w500, selected ? Colors.white : th.secondaryText),
        ),
      ),
    );
  }

  Widget _cell(String title, String value) {
    final th = FlutterFlowTheme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(title,
                  maxLines: 1,
                  style: _st(14, FontWeight.w400, th.secondaryText)),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  maxLines: 1, style: _st(20, FontWeight.w700, th.primary)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    String lang = "en";
    try {
      final String l =
          FFLocalizations.of(context).languageCode.trim().toLowerCase();
      if (l.isNotEmpty) lang = l;
    } catch (_) {}
    final bool rtl = _kRtl.contains(lang);
    String t(String key) {
      final Map<String, String>? m = _kStrings[key];
      if (m == null) return key;
      return m[lang] ?? m["en"] ?? key;
    }

    // ----- the sets inside the selected range -----
    final DateTime now = DateTime.now();
    final int days = _rangeDays();
    final DateTime? from = days > 0 ? now.subtract(Duration(days: days)) : null;
    final DateTime weekFrom = now.subtract(const Duration(days: 7));
    final List<_SetRow> inRange = [
      for (final s in _sets)
        if (from == null || !s.when.isBefore(from)) s
    ];

    // ----- kind of exercise -----
    final bool timed = _isTimed;
    bool bodyweight = _isBodyweightFlag;
    if (!timed && inRange.isNotEmpty) {
      int withWeight = 0;
      for (final s in inRange) {
        if (s.weight > 0) withWeight++;
      }
      bodyweight = withWeight * 2 < inRange.length;
    }
    final bool assisted = !timed && _isAssisted;

    // assisted: the most help used in the range is the baseline
    double maxAssist = 0;
    if (assisted) {
      for (final s in inRange) {
        if (s.weight > maxAssist) maxAssist = s.weight;
      }
    }

    // ----- one entry per workout -----
    final Map<String, _Session> byLog = {};
    int weekCount = 0;
    for (final s in inRange) {
      final int c = timed ? s.seconds : s.reps;
      if (c <= 0) continue;
      if (!s.when.isBefore(weekFrom)) weekCount += c;

      final _Session x = byLog.putIfAbsent(s.logId, () => _Session(s.when));
      if (s.when.isBefore(x.when)) x.when = s.when;
      x.reps += s.reps;
      if (s.reps > x.maxReps) x.maxReps = s.reps;
      x.seconds += s.seconds;
      if (s.seconds > x.maxSeconds) x.maxSeconds = s.seconds;
      if (s.weight > 0) {
        x.volume += s.reps * s.weight;
        if (s.weight > x.maxWeight) x.maxWeight = s.weight;
        x.assistSum += s.weight;
        x.assistCount++;
      }
      // less help = a harder rep = a higher score (1.0 to 2.0 per rep)
      final double factor =
          maxAssist > 0 ? 1.0 + (maxAssist - s.weight) / maxAssist : 1.0;
      x.score += s.reps * factor;
    }
    final List<_Session> sessions = byLog.values.toList()
      ..sort((a, b) => a.when.compareTo(b.when));

    // ----- chips for this kind of exercise -----
    final List<_Metric> metrics;
    if (timed) {
      metrics = [
        _Metric("totalTime", (s) => s.seconds.toDouble(), true),
        _Metric("longest", (s) => s.maxSeconds.toDouble(), true),
      ];
    } else if (assisted) {
      metrics = [
        _Metric("reps", (s) => s.reps.toDouble(), false),
        _Metric("assist",
            (s) => s.assistCount == 0 ? 0 : s.assistSum / s.assistCount, false),
        _Metric("volume", (s) => s.score, false),
      ];
    } else if (bodyweight) {
      metrics = [
        _Metric("reps", (s) => s.reps.toDouble(), false),
        _Metric("bestSet", (s) => s.maxReps.toDouble(), false),
      ];
    } else {
      metrics = [
        _Metric("reps", (s) => s.reps.toDouble(), false),
        _Metric("maxWeight", (s) => s.maxWeight, false),
        _Metric("volume", (s) => s.volume, false),
      ];
    }
    final int sel = _metric < metrics.length ? _metric : 0;
    final _Metric metric = metrics[sel];

    // ----- chart data -----
    final List<double> values = [for (final s in sessions) metric.value(s)];
    final List<String> dates = [];
    for (final s in sessions) {
      String d;
      try {
        d = intl.DateFormat.MMMd(lang).format(s.when);
      } catch (_) {
        d = s.when.day.toString() + "/" + s.when.month.toString();
      }
      dates.add(d);
    }

    // ----- the three numbers under the chart -----
    int best = 0;
    for (final s in sessions) {
      final int c = timed ? s.seconds : s.reps;
      if (c > best) best = c;
    }
    String fmt(int v) {
      if (v <= 0) return "-";
      if (timed) return _ltr(_clock(v));
      return _ltr(v.toString()) + " " + t("repsUnit");
    }

    String improve = "-";
    if (sessions.length >= 2) {
      double score(_Session s) {
        if (timed) return s.seconds.toDouble();
        if (assisted) return s.score;
        if (bodyweight) return s.reps.toDouble();
        return s.volume;
      }

      final double first = score(sessions.first);
      final double last = score(sessions.last);
      if (first > 0) {
        final int pct = (((last - first) * 100) / first).round();
        final String sign = pct > 0 ? "+" : (pct < 0 ? "−" : "");
        improve = _ltr(sign + pct.abs().toString() + "%");
      }
    }

    final Color lineColor =
        dark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);
    final Color gridColor = th.alternate.withOpacity(dark ? 0.5 : 0.7);

    final Widget chartArea = Container(
      decoration: BoxDecoration(
        color: th.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: th.alternate),
      ),
      clipBehavior: Clip.antiAlias,
      child: values.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: th.primary.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.show_chart_rounded,
                          size: 28, color: th.primary),
                    ),
                    const SizedBox(height: 12),
                    Text(t("empty"),
                        textAlign: TextAlign.center,
                        style: _st(14, FontWeight.w500, th.secondaryText)),
                  ],
                ),
              ),
            )
          : CustomPaint(
              size: Size.infinite,
              painter: _LinePainter(
                values: values,
                dates: dates,
                isTime: metric.isTime,
                rtl: rtl,
                line: lineColor,
                fill: lineColor.withOpacity(0.12),
                grid: gridColor,
                label: _st(11, FontWeight.w400, th.secondaryText),
              ),
            ),
    );

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Container(
        width: widget.width,
        height: widget.height,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
        decoration: BoxDecoration(
          color: th.secondaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: th.alternate),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t("title"),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: _st(18, FontWeight.w600, th.primaryText)),
            const SizedBox(height: 8),
            Text(t("sub"),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _st(14, FontWeight.w400, th.secondaryText)),
            const SizedBox(height: 16),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < metrics.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      _chip(t(metrics[i].key), i == sel, () {
                        if (i == sel) return;
                        HapticFeedback.selectionClick();
                        setState(() => _metric = i);
                      }),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: chartArea),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cell(t("week"), fmt(weekCount)),
                _cell(t("best"), fmt(best)),
                _cell(t("improve"), improve),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Area line chart: horizontal grid with values on the left, up to four
/// dates along the bottom. Time always runs left to right.
class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.dates,
    required this.isTime,
    required this.rtl,
    required this.line,
    required this.fill,
    required this.grid,
    required this.label,
  });

  final List<double> values;
  final List<String> dates;
  final bool isTime;
  final bool rtl;
  final Color line;
  final Color fill;
  final Color grid;
  final TextStyle label;

  static String _clock(int seconds) {
    final int s = seconds < 0 ? 0 : seconds;
    final int m = s ~/ 60;
    return m.toString() + ":" + (s % 60).toString().padLeft(2, "0");
  }

  /// A round step that splits [max] into about four parts.
  static double _step(double max) {
    if (max <= 0) return 1;
    final double raw = max / 4;
    final double pow10 =
        math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final double n = raw / pow10;
    double nice;
    if (n <= 1) {
      nice = 1;
    } else if (n <= 2) {
      nice = 2;
    } else if (n <= 2.5) {
      nice = 2.5;
    } else if (n <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * pow10;
  }

  String _tick(double v, double step) {
    if (isTime) return _clock(v.round());
    if (step < 1 || step != step.roundToDouble()) {
      String s = v.toStringAsFixed(1);
      if (s.endsWith(".0")) s = s.substring(0, s.length - 2);
      return s;
    }
    if (v >= 10000) return (v / 1000).toStringAsFixed(0) + "k";
    return v.round().toString();
  }

  TextPainter _text(String s, ui.TextDirection dir) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: label),
      textDirection: dir,
      maxLines: 1,
    );
    tp.layout();
    return tp;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;

    double max = 0;
    for (final v in values) {
      if (v > max) max = v;
    }
    double step = _step(max);
    if (isTime) {
      // whole seconds, and round minutes once the values are long enough
      step = step < 1 ? 1 : step.ceilToDouble();
      if (max >= 240) step = (step / 60).ceil() * 60.0;
    }
    int ticks = max <= 0 ? 1 : (max / step).ceil();
    if (ticks < 1) ticks = 1;
    final double top = step * ticks;

    // room for the widest value on the left
    double gutter = 0;
    for (int i = 0; i <= ticks; i++) {
      final double w = _text(_tick(step * i, step), ui.TextDirection.ltr).width;
      if (w > gutter) gutter = w;
    }
    final double left = gutter + 16;
    const double right = 16;
    const double padTop = 14;
    const double bottom = 30;
    final double w = size.width - left - right;
    final double h = size.height - padTop - bottom;
    if (w <= 0 || h <= 0) return;

    // grid + values
    final Paint gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (int i = 0; i <= ticks; i++) {
      final double y = padTop + h * (1 - i / ticks);
      canvas.drawLine(Offset(left, y), Offset(left + w, y), gridPaint);
      final tp = _text(_tick(step * i, step), ui.TextDirection.ltr);
      tp.paint(canvas, Offset(left - 8 - tp.width, y - tp.height / 2));
    }

    // points
    final int n = values.length;
    final List<Offset> pts = [];
    for (int i = 0; i < n; i++) {
      final double x = n == 1 ? left + w / 2 : left + w * i / (n - 1);
      final double y = padTop + h * (1 - (values[i] / top).clamp(0.0, 1.0));
      pts.add(Offset(x, y));
    }

    final Paint linePaint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    if (n == 1) {
      canvas.drawCircle(pts.first, 4, Paint()..color = line);
    } else {
      final Path area = Path()..moveTo(pts.first.dx, padTop + h);
      for (final p in pts) {
        area.lineTo(p.dx, p.dy);
      }
      area
        ..lineTo(pts.last.dx, padTop + h)
        ..close();
      canvas.drawPath(area, Paint()..color = fill);

      final Path path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < n; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // up to four dates
    final List<int> idx = [];
    if (n <= 4) {
      for (int i = 0; i < n; i++) {
        idx.add(i);
      }
    } else {
      for (int i = 0; i < 4; i++) {
        final int k = (i * (n - 1) / 3).round();
        if (!idx.contains(k)) idx.add(k);
      }
    }
    final ui.TextDirection dateDir =
        rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr;
    double lastEnd = -1;
    for (final k in idx) {
      if (k >= dates.length) continue;
      final tp = _text(dates[k], dateDir);
      double x = pts[k].dx - tp.width / 2;
      if (x < 4) x = 4;
      if (x + tp.width > size.width - 4) x = size.width - 4 - tp.width;
      if (x < lastEnd + 6) continue; // would sit on the previous date
      tp.paint(canvas, Offset(x, padTop + h + 8));
      lastEnd = x + tp.width;
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => true;
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
