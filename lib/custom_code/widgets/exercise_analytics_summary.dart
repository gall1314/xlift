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
import 'package:google_fonts/google_fonts.dart';

/// The three numbers under the exercise line chart, as one self-managed row:
/// last 7 days · best workout · improvement.
///
/// It reads the exercise and its logged sets itself and decides what to show
/// by the kind of exercise:
/// - timed (is_time_based): times ("1:30")
/// - assisted (is_assisted): reps; improvement also weighs the assistance
/// - bodyweight (most sets in the range have no weight): reps
/// - weighted: reps; improvement compares volume (reps x weight)
///
/// Drop sets count in the reps and in the volume.
///
/// Parameters:
/// - exerciseId (int)
/// - userId (String)
/// - timeRange (String, optional): the stored range value. Any text with
///   7 / 30 / 90 in it means that many days; anything else means all time.
///
/// "Last 7 days" is always the last 7 days, whatever the range is.
/// Improvement compares the first and the last workout inside the range and
/// shows a dash when there are fewer than two.
///
/// Localization: reads the app language from FFLocalizations (no parameter).
class ExerciseAnalyticsSummary extends StatefulWidget {
  const ExerciseAnalyticsSummary({
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
  State<ExerciseAnalyticsSummary> createState() =>
      _ExerciseAnalyticsSummaryState();
}

const Set<String> _kRtl = {"he", "ar"};

const Map<String, Map<String, String>> _kStrings = {
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
  "reps": {
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

class _Summary {
  const _Summary(this.week, this.best, this.improve);
  final String week;
  final String best;
  final String improve;
}

class _ExerciseAnalyticsSummaryState extends State<ExerciseAnalyticsSummary> {
  bool _isTimed = false;
  bool _isAssisted = false;
  bool _isBodyweightFlag = false;
  List<_SetRow> _sets = [];
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ExerciseAnalyticsSummary old) {
    super.didUpdateWidget(old);
    if (old.exerciseId != widget.exerciseId || old.userId != widget.userId) {
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

  _Summary _compute(String lang) {
    final DateTime now = DateTime.now();
    final int days = _rangeDays();
    final DateTime? from = days > 0 ? now.subtract(Duration(days: days)) : null;
    final DateTime weekFrom = now.subtract(const Duration(days: 7));

    final List<_SetRow> inRange = [
      for (final s in _sets)
        if (from == null || !s.when.isBefore(from)) s
    ];

    // kind of exercise
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

    // assisted: less help = harder, so a set scores more
    double maxAssist = 0;
    if (assisted) {
      for (final s in inRange) {
        if (s.weight > maxAssist) maxAssist = s.weight;
      }
    }

    int weekCount = 0;
    final Map<String, int> count = {}; // reps or seconds per workout
    final Map<String, double> score = {}; // what improvement compares
    final Map<String, DateTime> when = {};

    for (final s in inRange) {
      final int c = timed ? s.seconds : s.reps;
      if (c <= 0) continue;
      if (!s.when.isBefore(weekFrom)) weekCount += c;

      double v;
      if (timed) {
        v = s.seconds.toDouble();
      } else if (assisted) {
        final double help = s.weight < 1 ? 1 : s.weight;
        v = maxAssist > 0 ? s.reps * (maxAssist / help) : s.reps.toDouble();
      } else if (bodyweight) {
        v = s.reps.toDouble();
      } else {
        v = s.reps * s.weight;
      }

      count[s.logId] = (count[s.logId] ?? 0) + c;
      score[s.logId] = (score[s.logId] ?? 0) + v;
      final DateTime? old = when[s.logId];
      if (old == null || s.when.isBefore(old)) when[s.logId] = s.when;
    }

    int best = 0;
    count.forEach((_, v) {
      if (v > best) best = v;
    });

    String fmt(int v) {
      if (v <= 0) return "–";
      if (timed) return _ltr(_clock(v));
      return _ltr(v.toString()) + " " + (_kStrings["reps"]![lang] ?? "reps");
    }

    // improvement: first workout in the range against the last one
    String improve = "–";
    if (when.length >= 2) {
      final List<String> ids = when.keys.toList()
        ..sort((a, b) => when[a]!.compareTo(when[b]!));
      final double first = score[ids.first] ?? 0;
      final double last = score[ids.last] ?? 0;
      if (first > 0) {
        final int pct = (((last - first) * 100) / first).round();
        final String sign = pct > 0 ? "+" : (pct < 0 ? "−" : "");
        improve = _ltr(sign + pct.abs().toString() + "%");
      }
    }

    return _Summary(fmt(weekCount), fmt(best), improve);
  }

  // ---------- ui ----------
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

  @override
  Widget build(BuildContext context) {
    String lang = "en";
    try {
      final String l =
          FFLocalizations.of(context).languageCode.trim().toLowerCase();
      if (l.isNotEmpty) lang = l;
    } catch (_) {}
    final bool rtl = _kRtl.contains(lang);
    String t(String key) => _kStrings[key]![lang] ?? _kStrings[key]!["en"]!;

    final _Summary s = _compute(lang);

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cell(t("week"), s.week),
            _cell(t("best"), s.best),
            _cell(t("improve"), s.improve),
          ],
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
