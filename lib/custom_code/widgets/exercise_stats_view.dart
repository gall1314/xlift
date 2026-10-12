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
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// "By Exercise" stats tab: a Spotlight card that rotates through the user's
/// exercises (progress chart, best value, best set, sessions, AI form score)
/// and a list of all exercises with a trend line and % change.
///
/// Fully self-managed: runs one SQLite query itself (all sets of [userId] in
/// [timeRange]) and computesd everything in Dart. No FlutterFlow query
/// needed. Reloads when [userId] or [timeRange] changes.
///
/// [timeRange]: 'Last 7 days' | 'Last 30 days' | 'Last 90 days'; anything
/// else ('All', 'All time', empty) means no limit. [isDark]: the app's
/// dark-mode flag; picks the light or dark palette.
/// [onExerciseTap](exerciseId, isPublic): fired when a list row or the
/// Spotlight card is tapped. [onRangeChange](range): fired by the button in
/// the "nothing in this time range" empty state, with the shortest range that
/// contains the user's latest workout ('Last 30 days' | 'Last 90 days' | 'All
/// time').
///
/// Illustrations go through ExerciseAssetImage, so user-created exercises
/// (file name in exercise.illustration, stored under
/// Documents/exercise_images) and catalog assets both work.
///
/// Metric per exercise: estimated 1RM for weighted exercises, best reps for
/// bodyweight/assisted exercises, best time for timed exercises.
class ExerciseStatsView extends StatefulWidget {
  const ExerciseStatsView({
    super.key,
    this.width,
    this.height,
    required this.userId,
    this.timeRange,
    this.isDark,
    this.onExerciseTap,
    this.onRangeChange,
  });

  final double? width;
  final double? height;
  final String userId;
  final String? timeRange;
  final bool? isDark;
  final Future Function(int exerciseId, bool isPublic)? onExerciseTap;
  final Future Function(String range)? onRangeChange;

  @override
  State<ExerciseStatsView> createState() => _ExerciseStatsViewState();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

TextStyle _xs(BuildContext ctx, double size, FontWeight w, Color c,
    {double ls = 0, double? height}) {
  final th = FlutterFlowTheme.of(ctx);
  return th.bodyMedium.override(
    fontFamily: th.bodyMediumFamily,
    color: c,
    fontSize: size,
    fontWeight: w,
    letterSpacing: ls,
    lineHeight: height,
    useGoogleFonts: GoogleFonts.asMap().containsKey(th.bodyMediumFamily),
  );
}

int _toI(dynamic v, [int d = 0]) {
  if (v == null) return d;
  if (v is int) return v;
  if (v is num) return v.round();
  return num.tryParse(v.toString())?.round() ?? d;
}

double? _toD(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  final s = v.toString().trim();
  return s.isEmpty ? null : double.tryParse(s);
}

DateTime? _parseDt(dynamic raw) {
  final s = (raw ?? '').toString().trim();
  if (s.isEmpty) return null;
  final parsed = DateTime.tryParse(s);
  if (parsed == null) return null;
  return parsed.isUtc ? parsed.toLocal() : parsed;
}

String _num(double v) {
  if (v.abs() >= 100) return v.round().toString();
  final double r = (v * 10).round() / 10;
  return r == r.roundToDouble() ? r.toInt().toString() : r.toStringAsFixed(1);
}

String _mmss(double seconds) {
  final int s = seconds.round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

const List<String> _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];

String _shortDate(DateTime? dt) {
  if (dt == null) return '';
  return '${_monthNames[dt.month - 1]} ${dt.day}';
}

String _deltaText(int? d) {
  if (d == null) return 'New';
  if (d > 0) return '▲ $d%';
  if (d < 0) return '▼ ${d.abs()}%';
  return '0%';
}

/// "Last 7 days" -> "last 7 days", "All time" -> "all time".
String _lowerFirst(String s) =>
    s.isEmpty ? s : '${s[0].toLowerCase()}${s.substring(1)}';

// ---------------------------------------------------------------------------
// Palette (light / dark)
// ---------------------------------------------------------------------------

class _Pal {
  _Pal(BuildContext ctx, this.dark)
      : th = FlutterFlowTheme.of(ctx),
        heroBg = dark ? const Color(0xFF0F2524) : const Color(0xFFDDF3EF),
        heroInk = dark ? Colors.white : const Color(0xFF0B2F2D),
        heroSub = dark ? const Color(0xFFA9BDBB) : const Color(0xFF3F605D),
        accent = dark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E),
        tileBg = dark ? const Color(0x12FFFFFF) : Colors.white,
        tileLabel = dark ? const Color(0xFFA9BDBB) : const Color(0xFF5B6472),
        tileText = dark ? Colors.white : const Color(0xFF12161C),
        chipBg = dark ? const Color(0x1AFFFFFF) : Colors.white,
        up = dark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
        down = dark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
        flat = dark ? const Color(0xFFCBD5E1) : const Color(0xFF5B6472),
        rowSelected = dark ? const Color(0x245EEAD4) : const Color(0xFFDDF3EF),
        sparkIdle = dark ? const Color(0xFF6B7785) : const Color(0xFF9AA3AF),
        chartFill = dark ? const Color(0x245EEAD4) : const Color(0x210F766E);

  final bool dark;
  final FlutterFlowTheme th;
  final Color heroBg, heroInk, heroSub, accent;
  final Color tileBg, tileLabel, tileText, chipBg;
  final Color up, down, flat;
  final Color rowSelected, sparkIdle, chartFill;

  Color delta(int? d) {
    if (d == null || d == 0) return flat;
    return d > 0 ? up : down;
  }
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

class _ExStat {
  _ExStat({
    required this.id,
    required this.name,
    required this.isPublic,
    required this.illustration,
    required this.series,
    required this.prIndex,
    required this.firstDate,
    required this.lastDate,
    required this.big,
    required this.bigUnit,
    required this.bestSet,
    required this.sessions,
    required this.form,
    required this.deltaPct,
  });

  final int id;
  final String name;
  final bool isPublic;
  final String? illustration;
  final List<double> series; // one value per session, oldest first
  final int prIndex;
  final DateTime? firstDate, lastDate;
  final String big, bigUnit, bestSet;
  final int sessions;
  final double? form; // average AI form score, null = no analysis
  final int? deltaPct; // null = fewer than 2 sessions
}

List<_ExStat> _aggregate(List<Map<String, Object?>> rows) {
  final Map<int, List<Map<String, Object?>>> byEx = {};
  final List<int> order = [];
  for (final r in rows) {
    final int id = _toI(r['exercise_id']);
    if (!byEx.containsKey(id)) {
      byEx[id] = [];
      order.add(id);
    }
    byEx[id]!.add(r);
  }

  final List<_ExStat> out = [];
  for (final id in order) {
    final sets = byEx[id]!;
    final first = sets.first;
    final bool assisted = _toI(first['is_assisted']) == 1;

    bool allTimed = true, allNoWeight = true;
    int lbsSets = 0, weightedSets = 0;
    for (final s in sets) {
      final double dur = _toD(s['duration_seconds']) ?? 0;
      final double w = _toD(s['weight']) ?? 0;
      if (dur <= 0) allTimed = false;
      if (w > 0) {
        allNoWeight = false;
        weightedSets++;
        if (_toI(s['is_kg'], 1) != 1) lbsSets++;
      }
    }
    // 0 = weighted (est. 1RM), 1 = reps, 2 = timed
    final int kind = allTimed ? 2 : ((assisted || allNoWeight) ? 1 : 0);
    final bool useLbs = kind == 0 && lbsSets * 2 > weightedSets;
    final String unit = useLbs ? 'lb' : 'kg';

    final List<String> sessionIds = [];
    final Map<String, double> sessionVal = {};
    final Map<String, DateTime?> sessionDate = {};
    double bestMetric = -1;
    String bestSet = '–';
    double formSum = 0;
    int formN = 0;

    for (final s in sets) {
      final String wid = (s['workout_log_id'] ?? '').toString();
      final int reps = _toI(s['reps']);
      final double wRaw = _toD(s['weight']) ?? 0;
      final bool isKg = _toI(s['is_kg'], 1) == 1;
      // duration_seconds is stored in milliseconds
      final double durSec = (_toD(s['duration_seconds']) ?? 0) / 1000.0;
      final double? fs = _toD(s['form_score']);
      if (fs != null) {
        formSum += fs;
        formN++;
      }

      double? metric;
      String label = '';
      if (kind == 2) {
        if (durSec > 0) {
          metric = durSec;
          label = _mmss(durSec);
        }
      } else if (kind == 1) {
        if (reps > 0) {
          metric = reps.toDouble();
          label = assisted ? '$reps reps' : 'BW × $reps';
        }
      } else {
        if (wRaw > 0 && reps > 0) {
          final double w = useLbs
              ? (isKg ? wRaw * 2.20462 : wRaw)
              : (isKg ? wRaw : wRaw * 0.453592);
          metric = reps == 1 ? w : w * (1 + reps / 30.0); // Epley
          label = '${_num(w)} $unit × $reps';
        }
      }
      if (metric == null) continue;

      if (!sessionVal.containsKey(wid)) {
        sessionIds.add(wid);
        sessionVal[wid] = metric;
        sessionDate[wid] = _parseDt(s['created_at']);
      } else if (metric > sessionVal[wid]!) {
        sessionVal[wid] = metric;
      }
      if (metric > bestMetric) {
        bestMetric = metric;
        bestSet = label;
      }
    }
    if (sessionIds.isEmpty) continue;

    final List<double> series = [for (final w in sessionIds) sessionVal[w]!];
    int prIndex = 0;
    for (int i = 1; i < series.length; i++) {
      if (series[i] > series[prIndex]) prIndex = i;
    }
    final double best = series[prIndex];

    int? delta;
    if (series.length >= 2 && series.first > 0) {
      delta = ((series.last - series.first) * 100.0 / series.first).round();
    }

    String big, bigUnit;
    if (kind == 2) {
      big = _mmss(best);
      bigUnit = 'best time';
    } else if (kind == 1) {
      big = best.round().toString();
      bigUnit = 'reps, best set';
    } else {
      big = _num(best);
      bigUnit = '$unit est. 1RM';
    }

    final String ill = (first['illustration'] ?? '').toString().trim();
    out.add(_ExStat(
      id: id,
      name: (first['exercise_name'] ?? '').toString(),
      isPublic: _toI(first['is_public'], 1) == 1,
      illustration: (ill.isEmpty || ill == 'null') ? null : ill,
      series: series,
      prIndex: prIndex,
      firstDate: sessionDate[sessionIds.first],
      lastDate: sessionDate[sessionIds.last],
      big: big,
      bigUnit: bigUnit,
      bestSet: bestSet,
      sessions: sessionIds.length,
      form: formN > 0 ? formSum / formN : null,
      deltaPct: delta,
    ));
  }
  return out;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _ExerciseStatsViewState extends State<ExerciseStatsView> {
  static const List<String> _sortLabels = [
    'Most trained',
    'Most improved',
    'A–Z',
  ];
  static const Duration _rotateEvery = Duration(seconds: 4);

  final TextEditingController _search = TextEditingController();
  List<_ExStat> _all = [];
  bool _loading = true;
  int _sort = 0;
  bool _searchOpen = false;
  String _q = '';
  int? _spotId;
  bool _playing = true;
  Timer? _timer;
  int _loadToken = 0;

  /// Set only when the current range returned nothing but the user does have
  /// data: the shortest range that contains their latest workout.
  String? _suggestedRange;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(_rotateEvery, (_) => _advance());
  }

  @override
  void didUpdateWidget(covariant ExerciseStatsView old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId || old.timeRange != widget.timeRange) {
      _load();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  // ---------- data ----------
  String? _cutoffModifier() {
    switch ((widget.timeRange ?? '').trim()) {
      case 'Last 7 days':
        return '-7 days';
      case 'Last 30 days':
        return '-30 days';
      case 'Last 90 days':
        return '-90 days';
      default:
        return null; // All / All time
    }
  }

  /// When the current range is empty: finds the user's latest workout that
  /// has sets and returns the shortest range containing it, or null when the
  /// user has no data at all.
  Future<String?> _findSuggestedRange() async {
    try {
      final rows = await SQLiteManager.instance.database.rawQuery(
        "SELECT MAX(datetime(replace(wl.created_at,' ','T'))) AS last_dt "
        'FROM set_log sl '
        'JOIN workout_log wl ON wl.id = sl.workout_log_id '
        'WHERE wl.user_id = ? AND COALESCE(sl.is_dropset, 0) = 0',
        [widget.userId],
      );
      if (rows.isEmpty) return null;
      final String raw = (rows.first['last_dt'] ?? '').toString().trim();
      if (raw.isEmpty || raw == 'null') return null;
      final DateTime? last = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
      if (last == null) return 'All time';
      final double days = DateTime.now().difference(last).inHours / 24.0;
      if (days <= 29.5) return 'Last 30 days';
      if (days <= 89.5) return 'Last 90 days';
      return 'All time';
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    final int token = ++_loadToken;
    final String? modifier = _cutoffModifier();
    final String cutoffClause = modifier == null
        ? ''
        : "AND datetime(replace(wl.created_at,' ','T')) >= "
            "datetime('now','localtime', ?) ";
    final String sql = 'SELECT '
        'sl.exercise_id AS exercise_id, '
        'e.name AS exercise_name, '
        'e.is_public AS is_public, '
        'COALESCE(e.illustration, e.no_video_ilustration) AS illustration, '
        'COALESCE(e.is_assisted, 0) AS is_assisted, '
        'sl.workout_log_id AS workout_log_id, '
        'wl.created_at AS created_at, '
        'sl.reps AS reps, '
        'sl.weight AS weight, '
        'sl.is_kg AS is_kg, '
        'sl.duration_seconds AS duration_seconds, '
        '(SELECT AVG(sa.score) FROM set_analysis sa '
        ' WHERE sa.set_log_id = sl.id AND sa.score IS NOT NULL) AS form_score '
        'FROM set_log sl '
        'JOIN workout_log wl ON wl.id = sl.workout_log_id '
        'JOIN exercise e ON e.id = sl.exercise_id '
        'WHERE wl.user_id = ? '
        'AND COALESCE(sl.is_dropset, 0) = 0 '
        '$cutoffClause'
        "ORDER BY datetime(replace(wl.created_at,' ','T')) ASC, "
        'sl.created_at ASC';

    List<_ExStat> out = [];
    try {
      final rows = await SQLiteManager.instance.database.rawQuery(
        sql,
        modifier == null ? [widget.userId] : [widget.userId, modifier],
      );
      out = _aggregate(rows);
    } catch (_) {}

    // Empty with a time limit: is the range hiding data, or is there none?
    String? suggested;
    if (out.isEmpty && modifier != null) {
      suggested = await _findSuggestedRange();
      // Never suggest the range that is already selected.
      if (suggested == (widget.timeRange ?? '').trim()) suggested = 'All time';
    }

    if (!mounted || token != _loadToken) return;
    setState(() {
      _all = out;
      _suggestedRange = suggested;
      _loading = false;
    });
  }

  /// The list as shown: filtered by search, sorted by the current mode.
  List<_ExStat> _view() {
    final String q = _q.toLowerCase();
    final List<_ExStat> list = q.isEmpty
        ? List<_ExStat>.from(_all)
        : _all.where((e) => e.name.toLowerCase().contains(q)).toList();
    int byName(_ExStat a, _ExStat b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (_sort == 0) {
      list.sort((a, b) {
        final c = b.sessions.compareTo(a.sessions);
        return c != 0 ? c : byName(a, b);
      });
    } else if (_sort == 1) {
      list.sort((a, b) {
        final int av = a.deltaPct ?? -1000000;
        final int bv = b.deltaPct ?? -1000000;
        final c = bv.compareTo(av);
        return c != 0 ? c : byName(a, b);
      });
    } else {
      list.sort(byName);
    }
    return list;
  }

  void _advance() {
    if (!_playing || !mounted || _loading) return;
    final view = _view();
    if (view.length < 2) return;
    final int i = view.indexWhere((e) => e.id == _spotId);
    final int next = (i < 0 ? 1 : i + 1) % view.length;
    setState(() => _spotId = view[next].id);
  }

  void _togglePlay() {
    HapticFeedback.selectionClick();
    setState(() => _playing = !_playing);
  }

  void _cycleSort() {
    HapticFeedback.selectionClick();
    setState(() => _sort = (_sort + 1) % _sortLabels.length);
  }

  void _toggleSearch() {
    HapticFeedback.selectionClick();
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _search.clear();
        _q = '';
      }
    });
  }

  void _openExercise(_ExStat e) {
    HapticFeedback.selectionClick();
    widget.onExerciseTap?.call(e.id, e.isPublic);
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final p = _Pal(context, widget.isDark ?? false);

    Widget body;
    if (_loading) {
      body = Center(child: CircularProgressIndicator(color: p.th.primary));
    } else if (_all.isEmpty && _suggestedRange != null) {
      // The time range hides the data.
      final String current = (widget.timeRange ?? '').trim();
      final String suggested = _suggestedRange!;
      body = _emptyState(
        context,
        p,
        icon: Icons.calendar_today_outlined,
        title: 'No workouts in the ${_lowerFirst(current)}',
        subtitle: 'Your latest workout is older than that.',
        buttonLabel: 'Show ${_lowerFirst(suggested)}',
        onButtonTap: () {
          HapticFeedback.selectionClick();
          widget.onRangeChange?.call(suggested);
        },
      );
    } else if (_all.isEmpty) {
      // No data at all.
      body = _emptyState(
        context,
        p,
        icon: Icons.show_chart_rounded,
        title: 'No exercise data yet',
        subtitle: 'Finish a workout and your progress will show up here.',
      );
    } else {
      final view = _view();
      _ExStat? spot;
      if (view.isNotEmpty) {
        spot =
            view.firstWhere((e) => e.id == _spotId, orElse: () => view.first);
      }
      body = ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          if (spot != null) ...[
            _hero(context, p, spot, view.length > 1),
            const SizedBox(height: 14),
          ],
          _listHeader(context, p),
          if (_searchOpen) ...[
            const SizedBox(height: 10),
            _searchField(context, p),
          ],
          const SizedBox(height: 12),
          if (view.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('No exercises match',
                    style:
                        _xs(context, 14, FontWeight.w500, p.th.secondaryText)),
              ),
            )
          else
            _listCard(context, p, view, spot?.id),
        ],
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: body,
    );
  }

  // ---------- spotlight ----------
  Widget _hero(BuildContext ctx, _Pal p, _ExStat e, bool canRotate) {
    final Color deltaColor = p.delta(e.deltaPct);
    final String from = _shortDate(e.firstDate);
    final String to = e.sessions > 1 ? _shortDate(e.lastDate) : '';

    final Widget content = Column(
      key: ValueKey<int>(e.id),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            e.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _xs(ctx, 20, FontWeight.w700, p.heroInk, ls: -0.2),
          ),
        ),
        const SizedBox(height: 12),
        // Big number + delta
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                e.big,
                style: _xs(ctx, 48, FontWeight.w800, p.heroInk,
                    ls: -1.4, height: 1.05),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  e.bigUnit,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _xs(ctx, 14, FontWeight.w500, p.heroSub),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: p.chipBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _deltaText(e.deltaPct),
                  style: _xs(ctx, 13, FontWeight.w700, deltaColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Chart
        SizedBox(
          height: 100,
          width: double.infinity,
          child: CustomPaint(
            painter: _HeroChartPainter(
              series: e.series,
              prIndex: e.prIndex,
              lineColor: p.accent,
              fillColor: p.chartFill,
              dotFill: p.dark ? p.heroBg : Colors.white,
              dotStroke: p.dark ? Colors.white : p.accent,
              labelStyle: _xs(ctx, 11, FontWeight.w700, p.heroInk),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(from, style: _xs(ctx, 11, FontWeight.w500, p.heroSub)),
              Text(to, style: _xs(ctx, 11, FontWeight.w500, p.heroSub)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Stat tiles
        Row(
          children: [
            Expanded(child: _heroTile(ctx, p, 'Best set', e.bestSet, false)),
            const SizedBox(width: 8),
            Expanded(
                child: _heroTile(ctx, p, 'Sessions', '${e.sessions}', false)),
            const SizedBox(width: 8),
            Expanded(
              child: _heroTile(ctx, p, 'AI form',
                  e.form == null ? '–' : e.form!.toStringAsFixed(1), true),
            ),
          ],
        ),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openExercise(e),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.heroBg,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label + play/pause (stays fixed while the content switches)
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'SPOTLIGHT',
                      style: _xs(ctx, 11, FontWeight.w700, p.accent, ls: 1.4),
                    ),
                  ),
                ),
                if (canRotate)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _togglePlay,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: p.chipBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 20,
                        color: p.heroInk,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 36),
              ],
            ),
            const SizedBox(height: 2),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topLeft,
                children: [
                  ...previous,
                  if (current != null) current,
                ],
              ),
              child: content,
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroTile(
      BuildContext ctx, _Pal p, String label, String value, bool sparkle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.tileBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sparkle) ...[
                Icon(Icons.auto_awesome_rounded, size: 11, color: p.accent),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _xs(ctx, 11, FontWeight.w500, p.tileLabel),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: _xs(ctx, 15, FontWeight.w700, p.tileText),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- list header ----------
  Widget _listHeader(BuildContext ctx, _Pal p) {
    final List<BoxShadow>? shadow = p.dark
        ? null
        : const [
            BoxShadow(
              color: Color(0x0A101828),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ];
    final Border? border = p.dark ? Border.all(color: p.th.alternate) : null;

    return Row(
      children: [
        Expanded(
          child: Text(
            'Your exercises',
            style: _xs(ctx, 18, FontWeight.w700, p.th.primaryText, ls: -0.2),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleSearch,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _searchOpen ? p.rowSelected : p.th.secondaryBackground,
              shape: BoxShape.circle,
              border: _searchOpen ? null : border,
              boxShadow: _searchOpen ? null : shadow,
            ),
            child: Icon(
              _searchOpen ? Icons.close_rounded : Icons.search_rounded,
              size: 20,
              color: _searchOpen ? p.accent : p.th.secondaryText,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _cycleSort,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: p.th.secondaryBackground,
              borderRadius: BorderRadius.circular(999),
              border: border,
              boxShadow: shadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_vert_rounded,
                    size: 16, color: p.th.secondaryText),
                const SizedBox(width: 4),
                Text(
                  _sortLabels[_sort],
                  style: _xs(ctx, 13, FontWeight.w500, p.th.primaryText),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _searchField(BuildContext ctx, _Pal p) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: p.th.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: p.dark ? Border.all(color: p.th.alternate) : null,
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: p.th.secondaryText),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _search,
              autofocus: true,
              onChanged: (v) => setState(() => _q = v.trim()),
              textInputAction: TextInputAction.search,
              cursorColor: p.th.primary,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Search exercises',
                hintStyle: _xs(ctx, 15, FontWeight.w400, p.th.secondaryText),
              ),
              style: _xs(ctx, 15, FontWeight.w400, p.th.primaryText),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- list ----------
  Widget _listCard(BuildContext ctx, _Pal p, List<_ExStat> view, int? spotId) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: p.th.secondaryBackground,
        borderRadius: BorderRadius.circular(22),
        border: p.dark ? Border.all(color: p.th.alternate) : null,
        boxShadow: p.dark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A101828),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
                BoxShadow(
                  color: Color(0x0F101828),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < view.length; i++) ...[
            if (i > 0) const SizedBox(height: 2),
            _row(ctx, p, view[i], view[i].id == spotId),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext ctx, _Pal p, _ExStat e, bool selected) {
    final String sub =
        'Best ${e.bestSet} · ${e.sessions} session${e.sessions == 1 ? '' : 's'}';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openExercise(e),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? p.rowSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 44,
                height: 44,
                color: p.dark ? p.th.primaryBackground : Colors.white,
                child: ExerciseAssetImage(
                  width: 44,
                  height: 44,
                  exerciseName: exerciseImageName(e.name),
                  borderRadius: 12,
                  illustration: e.illustration,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _xs(ctx, 15, FontWeight.w600, p.th.primaryText),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _xs(ctx, 12, FontWeight.w400, p.th.secondaryText),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 52,
                  height: 18,
                  child: CustomPaint(
                    painter: _SparkPainter(
                      series: e.series,
                      color: selected ? p.accent : p.sparkIdle,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _deltaText(e.deltaPct),
                  style: _xs(ctx, 12, FontWeight.w700, p.delta(e.deltaPct)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- empty ----------
  Widget _emptyState(
    BuildContext ctx,
    _Pal p, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? buttonLabel,
    VoidCallback? onButtonTap,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: p.th.alternate,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: p.th.secondaryText),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: _xs(ctx, 18, FontWeight.w700, p.th.primaryText),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: _xs(ctx, 14, FontWeight.w400, p.th.secondaryText,
                  height: 1.4),
            ),
            if (buttonLabel != null) ...[
              const SizedBox(height: 20),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onButtonTap,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        buttonLabel,
                        style: _xs(ctx, 14, FontWeight.w600, Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------

/// Maps a series to points inside [size] with the given paddings. A single
/// value (or a flat series) becomes a line across the middle.
List<Offset> _seriesPoints(List<double> series, Size size, double padX,
    double padTop, double padBottom) {
  if (series.isEmpty) return const [];
  if (series.length == 1) {
    final double y = size.height / 2;
    return [Offset(padX, y), Offset(size.width - padX, y)];
  }
  double mn = series.first, mx = series.first;
  for (final v in series) {
    mn = math.min(mn, v);
    mx = math.max(mx, v);
  }
  final bool isFlat = (mx - mn) == 0;
  final double span = isFlat ? 1 : (mx - mn);
  final double w = size.width - 2 * padX;
  final double h = size.height - padTop - padBottom;
  return [
    for (int i = 0; i < series.length; i++)
      Offset(
        padX + w * i / (series.length - 1),
        isFlat ? size.height / 2 : padTop + h * (1 - (series[i] - mn) / span),
      ),
  ];
}

class _HeroChartPainter extends CustomPainter {
  _HeroChartPainter({
    required this.series,
    required this.prIndex,
    required this.lineColor,
    required this.fillColor,
    required this.dotFill,
    required this.dotStroke,
    required this.labelStyle,
  });

  final List<double> series;
  final int prIndex;
  final Color lineColor, fillColor, dotFill, dotStroke;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = _seriesPoints(series, size, 10, 26, 8);
    if (pts.isEmpty) return;

    final Path line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      line.lineTo(pts[i].dx, pts[i].dy);
    }
    final Path area = Path.from(line)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();

    canvas.drawPath(area, Paint()..color = fillColor);
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // PR marker (middle of the flat line when there is a single session)
    final Offset pr = series.length == 1
        ? Offset(size.width / 2, size.height / 2)
        : pts[math.min(math.max(prIndex, 0), pts.length - 1)];
    canvas.drawCircle(pr, 5, Paint()..color = dotFill);
    canvas.drawCircle(
      pr,
      5,
      Paint()
        ..color = dotStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final tp = TextPainter(
      text: TextSpan(text: 'PR', style: labelStyle),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final double lx =
        math.min(math.max(pr.dx - tp.width / 2, 0.0), size.width - tp.width);
    tp.paint(canvas, Offset(lx, pr.dy - 10 - tp.height));
  }

  @override
  bool shouldRepaint(covariant _HeroChartPainter old) =>
      old.series != series ||
      old.lineColor != lineColor ||
      old.fillColor != fillColor ||
      old.dotFill != dotFill;
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.series, required this.color});

  final List<double> series;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = _seriesPoints(series, size, 2, 3, 3);
    if (pts.isEmpty) return;
    final Path line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      line.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.series != series || old.color != color;
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
