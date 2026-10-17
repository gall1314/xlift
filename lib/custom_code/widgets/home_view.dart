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

/// Self-managed Home screen content (nav bar / FAB live on the page).
///
/// Runs its own SQLite queries, holds its own state, exposes navigation as
/// callbacks.
///
/// Parameters: userId              - current user id (auth) isPremium - true
/// hides the form-check quota meter analysisCount       -
/// FFAppState().analysisCount analysisCountMonth  -
/// FFAppState().analysisCountMonth ("YYYY-MM") onStartWorkout      -
/// (workoutId) start a saved workout onOpenSummary       - (workoutLogId)
/// open workout summary onOpenLastAnalysis  - (GetSetAnalysisRow) show the
/// last analysis; the camera itself is the page's FAB onOpenStats,
/// onOpenLibrary, onOpenSettings onCreateWorkout     - open the existing
/// create bottom sheet
class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    this.width,
    this.height,
    required this.userId,
    this.isPremium = false,
    this.analysisCount = 0,
    this.analysisCountMonth = '',
    this.onStartWorkout,
    this.onOpenSummary,
    this.onOpenLastAnalysis,
    this.onOpenStats,
    this.onOpenLibrary,
    this.onOpenSettings,
    this.onCreateWorkout,
  });

  final double? width;
  final double? height;
  final String userId;
  final bool isPremium;
  final int analysisCount;
  final String analysisCountMonth;
  final Future Function(String workoutId)? onStartWorkout;
  final Future Function(String workoutLogId)? onOpenSummary;
  final Future Function(GetSetAnalysisRow analysis)? onOpenLastAnalysis;
  final Future Function()? onOpenStats;
  final Future Function()? onOpenLibrary;
  final Future Function()? onOpenSettings;
  final Future Function()? onCreateWorkout;

  @override
  State<HomeView> createState() => _HomeViewState();
}

// Free-tier form-check quota (mirrors canStartQuickAnalysis).
const int _kFreeMonthlyLimit = 5;

// Space reserved at the bottom for the page's nav bar + FAB overhang.
const double _kBottomInset = 170;

// Horizontal page gutter.
const double _kGutter = 20;

// Minutes per working set, incl. rest and transitions.
const double _kMinPerSet = 3.5;

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------
const _kBg = Color(0xFFF2F4F3);
const _kInk = Color(0xFF0F1D1B);
const _kInkMuted = Color(0xFF5B6966);
const _kInkFaint = Color(0xFF9AAAA6);
const _kCard = Color(0xFFFFFFFF);
const _kCardSub = Color(0xFFEEF1F0);
const _kLine = Color(0xFFE2E7E5);
const _kAccent = Color(0xFF13B094);
const _kAccentOnDark = Color(0xFF3FD2B6);
const _kAccentDeep = Color(0xFF0B7D6B);
const _kAccentTint = Color(0xFFE1F4EF);

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------
class _WorkoutRow {
  _WorkoutRow({
    required this.id,
    required this.name,
    required this.exerciseCount,
    required this.lastDoneAt,
    required this.muscles,
    required this.formCheckCount,
    required this.estMinutes,
  });
  final String id;
  final String name;
  final int exerciseCount;
  final DateTime? lastDoneAt;
  final List<String> muscles;
  final int formCheckCount;
  final int estMinutes;

  bool get isRested =>
      lastDoneAt == null ||
      DateTime.now().difference(lastDoneAt!) >= const Duration(hours: 48);
}

class _LastWorkout {
  _LastWorkout({
    required this.logId,
    required this.name,
    required this.at,
    required this.durationSec,
    required this.volume,
    required this.sets,
    required this.muscles,
    required this.prCount,
  });
  final String logId;
  final String name;
  final DateTime at;
  final int durationSec;
  final double volume;
  final int sets;
  final List<String> muscles;
  final int prCount;
}

class _WeekStats {
  _WeekStats({
    required this.workouts,
    required this.sets,
    required this.volume,
    required this.perDay,
  });
  final int workouts;
  final int sets;
  final double volume;
  final List<int> perDay; // Sun..Sat
}

class _LastScore {
  _LastScore({
    required this.setLogId,
    required this.score,
    required this.exerciseName,
    required this.at,
  });
  final String setLogId;
  final double score;
  final String exerciseName;
  final DateTime at;
}

class _HomeData {
  _HomeData({
    required this.workouts,
    required this.lastWorkout,
    required this.week,
    required this.lastScore,
  });
  final List<_WorkoutRow> workouts;
  final _LastWorkout? lastWorkout;
  final _WeekStats week;
  final _LastScore? lastScore;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class _HomeViewState extends State<HomeView> {
  _HomeData? _data;
  String? _error;
  int _heroOffset = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await _fetch();
      if (mounted) setState(() => _data = d);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  /// Opens the last analysis via the FlutterFlow-generated query so the
  /// page receives a real GetSetAnalysisRow.
  Future<void> _openLastAnalysis(String setLogId) async {
    if (widget.onOpenLastAnalysis == null) return;
    try {
      final rows =
          await SQLiteManager.instance.getSetAnalysis(setLogId: setLogId);
      if (rows.isNotEmpty) await widget.onOpenLastAnalysis!(rows.first);
    } catch (_) {}
  }

  /// Checks used this month, with the same self-healing month check as
  /// canStartQuickAnalysis: a stale month means a fresh quota.
  int get _usedThisMonth {
    final now = DateTime.now();
    final cur = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final used = widget.analysisCountMonth == cur ? widget.analysisCount : 0;
    return used.clamp(0, _kFreeMonthlyLimit);
  }

  // ------------------------------ helpers -----------------------------------

  static DateTime? _parse(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final dt = DateTime.tryParse(s);
    if (dt == null) return null;
    return dt.isUtc ? dt.toLocal() : dt;
  }

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double _dbl(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  static DateTime _startOfWeekSunday(DateTime now) {
    final d = DateTime(now.year, now.month, now.day);
    return d.subtract(Duration(days: d.weekday % 7));
  }

  static List<String> _topMuscles(List<Map<String, Object?>> rows) {
    final out = <String>[];
    for (final r in rows) {
      final n = (r['name'] ?? '').toString();
      if (n.isNotEmpty && !out.contains(n)) out.add(n);
      if (out.length == 3) break;
    }
    return out;
  }

  static int _estimate(int exerciseCount, int setCount) {
    final sets = setCount == 0 ? exerciseCount * 3 : setCount;
    return math.max(15, (sets * _kMinPerSet).round());
  }

  // ------------------------------- fetch ------------------------------------

  Future<_HomeData> _fetch() async {
    final db = SQLiteManager.instance.database;
    final uid = widget.userId;
    final now = DateTime.now();

    // --- saved workouts ---
    final wRows = await db.rawQuery('''
      SELECT
        w.id, w.name, w.created_at,
        COUNT(DISTINCT we.id) AS exercise_count,
        MAX(wl.created_at)    AS last_done_at,
        SUM(CASE WHEN e.ai_form_analysis = 1 THEN 1 ELSE 0 END) AS fc_count,
        (SELECT COUNT(*) FROM exercise_sets es WHERE es.workout_id = w.id) AS set_count
      FROM workout w
      LEFT JOIN workout_exercise we ON we.workout_id = w.id
      LEFT JOIN exercise e          ON e.id = we.exercise_id
      LEFT JOIN workout_log wl      ON wl.workout_id = w.id
      WHERE w.user_id = ? AND COALESCE(w.is_deleted, 0) = 0
      GROUP BY w.id, w.name, w.created_at
    ''', [uid]);

    final workouts = <_WorkoutRow>[];
    for (final r in wRows) {
      final id = (r['id'] ?? '').toString();
      final mRows = await db.rawQuery('''
        SELECT pmg.name AS name, COUNT(*) AS cnt
        FROM workout_exercise we
        JOIN exercise_muscle_group emg
          ON emg.exercise_id = we.exercise_id AND emg.is_primary = 1
        JOIN muscle_group mg           ON mg.id = emg.muscle_group_id
        JOIN primary_muscle_group pmg  ON pmg.id = mg.primary_muscle_group_id
        WHERE we.workout_id = ?
        GROUP BY pmg.name ORDER BY cnt DESC
      ''', [id]);
      final exCount = _int(r['exercise_count']);
      workouts.add(_WorkoutRow(
        id: id,
        name: (r['name'] ?? '').toString().trim(),
        exerciseCount: exCount,
        lastDoneAt: _parse(r['last_done_at']),
        muscles: _topMuscles(mRows),
        formCheckCount: _int(r['fc_count']),
        estMinutes: _estimate(exCount, _int(r['set_count'])),
      ));
    }

    // Rested first (never / >=7d), then oldest-done.
    workouts.sort((a, b) {
      int tier(_WorkoutRow w) {
        if (w.lastDoneAt == null) return 0;
        return now.difference(w.lastDoneAt!).inDays >= 7 ? 0 : 1;
      }

      final t = tier(a).compareTo(tier(b));
      if (t != 0) return t;
      final al = a.lastDoneAt, bl = b.lastDoneAt;
      if (al == null && bl == null) return 0;
      if (al == null) return 1;
      if (bl == null) return -1;
      return al.compareTo(bl);
    });

    // --- last workout ---
    _LastWorkout? last;
    final lRows = await db.rawQuery('''
      SELECT wl.id, wl.workout_id, wl.created_at, wl.duration_seconds, wl.volume,
             w.name,
             (SELECT COUNT(*) FROM set_log s
               WHERE s.workout_log_id = wl.id AND s.is_dropset = 0) AS sets
      FROM workout_log wl
      LEFT JOIN workout w ON w.id = wl.workout_id
      WHERE wl.user_id = ?
      ORDER BY wl.created_at DESC LIMIT 1
    ''', [uid]);
    if (lRows.isNotEmpty) {
      final r = lRows.first;
      final logId = (r['id'] ?? '').toString();
      final at = _parse(r['created_at']) ?? now;
      final mRows = await db.rawQuery('''
        SELECT pmg.name AS name, COUNT(*) AS cnt
        FROM set_log s
        JOIN exercise_muscle_group emg
          ON emg.exercise_id = s.exercise_id AND emg.is_primary = 1
        JOIN muscle_group mg           ON mg.id = emg.muscle_group_id
        JOIN primary_muscle_group pmg  ON pmg.id = mg.primary_muscle_group_id
        WHERE s.workout_log_id = ?
        GROUP BY pmg.name ORDER BY cnt DESC
      ''', [logId]);
      final prRows = await db.rawQuery('''
        SELECT COUNT(*) AS prs FROM (
          SELECT s.exercise_id, MAX(s.weight) AS mw
          FROM set_log s WHERE s.workout_log_id = ? AND s.is_dropset = 0
          GROUP BY s.exercise_id
        ) cur
        WHERE cur.mw > COALESCE((
          SELECT MAX(p.weight) FROM set_log p
          JOIN workout_log pl ON pl.id = p.workout_log_id
          WHERE p.exercise_id = cur.exercise_id AND p.user_id = ?
            AND pl.created_at < ?
        ), 0)
      ''', [logId, uid, r['created_at']]);
      // duration_seconds currently receives milliseconds from saveWorkoutComplete.
      final rawDur = _int(r['duration_seconds']);
      final durSec = rawDur > 20000 ? rawDur ~/ 1000 : rawDur;
      last = _LastWorkout(
        logId: logId,
        name: (r['name'] ?? '').toString().trim(),
        at: at,
        durationSec: durSec,
        volume: _dbl(r['volume']),
        sets: _int(r['sets']),
        muscles: _topMuscles(mRows),
        prCount: prRows.isEmpty ? 0 : _int(prRows.first['prs']),
      );
    }

    // --- this week (Sun..Sat, local) ---
    final weekStart = _startOfWeekSunday(now);
    final wkRows = await db.rawQuery('''
      SELECT wl.id, wl.created_at, wl.volume,
             (SELECT COUNT(*) FROM set_log s
               WHERE s.workout_log_id = wl.id AND s.is_dropset = 0) AS sets
      FROM workout_log wl WHERE wl.user_id = ?
      ORDER BY wl.created_at DESC LIMIT 60
    ''', [uid]);
    final perDay = List<int>.filled(7, 0);
    int wkWorkouts = 0, wkSets = 0;
    double wkVol = 0;
    for (final r in wkRows) {
      final at = _parse(r['created_at']);
      if (at == null || at.isBefore(weekStart)) continue;
      wkWorkouts++;
      wkSets += _int(r['sets']);
      wkVol += _dbl(r['volume']);
      perDay[at.weekday % 7]++;
    }

    // --- last form score ---
    _LastScore? lastScore;
    final aRows = await db.rawQuery('''
      SELECT sa.set_log_id, sa.score, sa.analyzed_at, e.name
      FROM set_analysis sa
      JOIN set_log s        ON s.id = sa.set_log_id
      LEFT JOIN exercise e  ON e.id = s.exercise_id
      WHERE s.user_id = ?
      ORDER BY sa.analyzed_at DESC LIMIT 1
    ''', [uid]);
    if (aRows.isNotEmpty) {
      final r = aRows.first;
      lastScore = _LastScore(
        setLogId: (r['set_log_id'] ?? '').toString(),
        score: _dbl(r['score']),
        exerciseName: (r['name'] ?? '').toString(),
        at: _parse(r['analyzed_at']) ?? now,
      );
    }

    return _HomeData(
      workouts: workouts,
      lastWorkout: last,
      week: _WeekStats(
        workouts: wkWorkouts,
        sets: wkSets,
        volume: wkVol,
        perDay: perDay,
      ),
      lastScore: lastScore,
    );
  }

  // ------------------------------ formatting --------------------------------

  static String _greeting(DateTime now) {
    final h = now.hour;
    if (h < 5) return 'Good night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String _dateLine(DateTime now) {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    const months = [
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
    return '${days[now.weekday % 7]}, ${months[now.month - 1]} ${now.day}';
  }

  static String _ago(DateTime? dt) {
    if (dt == null) return 'never done';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'just now';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    if (diff.inDays < 14) return 'last ${days[dt.weekday % 7]}';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  static String _dayShort(DateTime dt) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final today = DateTime.now();
    if (dt.year == today.year &&
        dt.month == today.month &&
        dt.day == today.day) {
      return 'Today';
    }
    final y = today.subtract(const Duration(days: 1));
    if (dt.year == y.year && dt.month == y.month && dt.day == y.day) {
      return 'Yesterday';
    }
    return days[dt.weekday % 7];
  }

  static String _duration(int sec) {
    final h = sec ~/ 3600, m = (sec % 3600) ~/ 60;
    if (h == 0) return '${m}m';
    return '$h:${m.toString().padLeft(2, '0')}';
  }

  static String _kg(double v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String _displayName(_WorkoutRow w) {
    if (w.name.isNotEmpty &&
        !w.name.toLowerCase().startsWith('unnamed workout')) {
      return _cap(w.name);
    }
    if (w.muscles.isNotEmpty) return w.muscles.take(2).join(' & ');
    return 'Workout';
  }

  static String _score(double s) {
    final r = (s * 10).round() / 10;
    return r == r.roundToDouble() ? r.toInt().toString() : r.toStringAsFixed(1);
  }

  // --------------------------------- UI -------------------------------------

  TextStyle _display(double size,
          {Color color = _kInk, FontWeight w = FontWeight.w800}) =>
      TextStyle(
        fontSize: size,
        fontWeight: w,
        color: color,
        height: 1.05,
        letterSpacing: -size * 0.02,
      );

  TextStyle _body(double size,
          {Color color = _kInk, FontWeight w = FontWeight.w400}) =>
      TextStyle(fontSize: size, fontWeight: w, color: color, height: 1.25);

  TextStyle _eyebrow({Color color = _kInkMuted}) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 1.4,
      );

  Widget _gutter(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: _kGutter),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Container(
      width: widget.width,
      height: widget.height,
      color: _kBg,
      child: d == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator(
                      color: _kAccent, strokeWidth: 2)
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Home failed to load\n$_error',
                        textAlign: TextAlign.center,
                        style: _body(13, color: _kInkMuted),
                      ),
                    ),
            )
          : RefreshIndicator(
              color: _kAccent,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, _kBottomInset),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _gutter(_header()),
                  const SizedBox(height: 20),
                  _gutter(_hero(d)),
                  const SizedBox(height: 12),
                  _gutter(_formCheckCard(d)),
                  const SizedBox(height: 12),
                  _gutter(_weekCard(d)),
                  if (d.lastWorkout != null) ...[
                    const SizedBox(height: 12),
                    _gutter(_lastWorkoutCard(d.lastWorkout!)),
                  ],
                  const SizedBox(height: 24),
                  _myWorkouts(d),
                ],
              ),
            ),
    );
  }

  // --- header: greeting only, settings on the right ---
  Widget _header() {
    final now = DateTime.now();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_dateLine(now).toUpperCase(), style: _eyebrow()),
              const SizedBox(height: 6),
              Text(
                _greeting(now),
                style: _display(32),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => widget.onOpenSettings?.call(),
          child: Container(
            width: 44,
            height: 44,
            decoration:
                const BoxDecoration(color: _kCard, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.settings_rounded, size: 20, color: _kInk),
          ),
        ),
      ],
    );
  }

  // --- hero: Up next ---
  Widget _hero(_HomeData d) {
    if (d.workouts.isEmpty) {
      return _darkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('START HERE', style: _eyebrow(color: _kAccentOnDark)),
            const SizedBox(height: 14),
            Text('Build your first\nworkout', style: _display(30, color: _kBg)),
            const SizedBox(height: 8),
            Text('Pick exercises yourself or let the AI build one.',
                style: _body(13, color: _kInkFaint)),
            const SizedBox(height: 18),
            _primaryButton('Create workout',
                onTap: () => widget.onCreateWorkout?.call()),
          ],
        ),
      );
    }

    final w = d.workouts[_heroOffset % d.workouts.length];
    final rested = w.muscles.isNotEmpty && w.isRested;
    return _darkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('UP NEXT', style: _eyebrow(color: _kAccentOnDark)),
              const Spacer(),
              if (rested) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: _kAccentOnDark, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('Recovered', style: _body(12, color: _kInkFaint)),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _displayName(w),
            style: _display(34, color: _kBg),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '${w.exerciseCount} exercises · ~${w.estMinutes} min · ${_ago(w.lastDoneAt)}',
            style: _body(13, color: _kInkFaint),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final m in w.muscles) _pillDark(m),
              if (w.formCheckCount > 0)
                _pillDark(
                  '${w.formCheckCount} with form check',
                  icon: const _FormCheckIcon(size: 12, color: _kAccentOnDark),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _primaryButton(
                  'Start workout',
                  icon: Icons.play_arrow_rounded,
                  onTap: () => widget.onStartWorkout?.call(w.id),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: d.workouts.length > 1
                    ? () => setState(() => _heroOffset++)
                    : null,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: d.workouts.length > 1 ? _kBg : _kInkFaint,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- form check card: quota + last score. Camera lives on the FAB. ---
  Widget _formCheckCard(_HomeData d) {
    final left = _kFreeMonthlyLimit - _usedThisMonth;
    final ls = d.lastScore;

    String subtitle;
    if (ls == null) {
      subtitle = widget.isPremium
          ? 'Unlimited · film a set with the camera below'
          : '$left of $_kFreeMonthlyLimit free this month · film a set with the camera below';
    } else if (widget.isPremium) {
      subtitle = 'Unlimited · tap for your last analysis';
    } else {
      subtitle = '$left of $_kFreeMonthlyLimit free checks left this month';
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: ls == null ? null : () => _openLastAnalysis(ls.setLogId),
      child: _lightCard(
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _kAccentTint,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const _FormCheckIcon(size: 24, color: _kAccentDeep),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Form check', style: _body(16, w: FontWeight.w600)),
                  const SizedBox(height: 5),
                  Text(subtitle,
                      style: _body(12, color: _kInkMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (!widget.isPremium) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (int i = 0; i < _kFreeMonthlyLimit; i++) ...[
                          Expanded(
                            child: Container(
                              height: 5,
                              decoration: BoxDecoration(
                                color: i < left ? _kAccent : _kLine,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          if (i < _kFreeMonthlyLimit - 1)
                            const SizedBox(width: 4),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (ls != null) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 84,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ScoreRing(score: ls.score, label: _score(ls.score)),
                    const SizedBox(height: 5),
                    Text(
                      '${ls.exerciseName.split(' ').last} · ${_dayShort(ls.at)}',
                      style: _body(10, color: _kInkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- this week: circles like the original, centered stats ---
  Widget _weekCard(_HomeData d) {
    const letters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final today = DateTime.now().weekday % 7;
    final wk = d.week;
    return _lightCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('This week', style: _body(14, w: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: () => widget.onOpenStats?.call(),
                child: Row(
                  children: [
                    Text('Full stats',
                        style:
                            _body(12, color: _kAccentDeep, w: FontWeight.w500)),
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: _kAccentDeep),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (int i = 0; i < 7; i++)
                Expanded(
                  child: Column(
                    children: [
                      _dayDot(done: wk.perDay[i] > 0, today: i == today),
                      const SizedBox(height: 7),
                      Text(
                        letters[i],
                        style: _body(
                          11,
                          color: i == today || wk.perDay[i] > 0
                              ? _kInk
                              : _kInkMuted,
                          w: i == today ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _kCardSub),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat('${wk.workouts}', 'workouts'),
              _stat('${wk.sets}', 'sets'),
              _stat(_kg(wk.volume), 'kg volume'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayDot({required bool done, required bool today}) {
    if (done) {
      return Container(
        width: 36,
        height: 36,
        decoration:
            const BoxDecoration(color: _kAccent, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: today ? _kCard : Colors.transparent,
        border: Border.all(
          color: today ? _kAccent : _kLine,
          width: today ? 2 : 1.5,
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value, style: _display(26), textAlign: TextAlign.center),
            const SizedBox(height: 3),
            Text(label,
                style: _body(11, color: _kInkMuted),
                textAlign: TextAlign.center),
          ],
        ),
      );

  // --- last workout ---
  Widget _lastWorkoutCard(_LastWorkout l) {
    final hh = l.at.hour.toString().padLeft(2, '0');
    final mm = l.at.minute.toString().padLeft(2, '0');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onOpenSummary?.call(l.logId),
      child: _lightCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LAST WORKOUT · ${_dayShort(l.at).toUpperCase()} $hh:$mm',
                    style: _eyebrow(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(l.name.isEmpty ? 'Workout' : _cap(l.name),
                          style: _display(20, w: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l.muscles.join(' · '),
                          style: _body(12, color: _kInkMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text.rich(TextSpan(
                    style: _body(13),
                    children: [
                      TextSpan(
                          text:
                              '${_duration(l.durationSec)} · ${_kg(l.volume)} kg · ${l.sets} sets'),
                      if (l.prCount > 0)
                        TextSpan(
                          text: ' · ${l.prCount} PR${l.prCount > 1 ? 's' : ''}',
                          style: _body(13,
                              color: _kAccentDeep, w: FontWeight.w600),
                        ),
                    ],
                  )),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _kInk, width: 1.5),
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  size: 22, color: _kInk),
            ),
          ],
        ),
      ),
    );
  }

  // --- my workouts: full-bleed horizontal shelf ---
  Widget _myWorkouts(_HomeData d) {
    final list = d.workouts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _gutter(Row(
          children: [
            Text('My workouts', style: _display(20, w: FontWeight.w700)),
            const Spacer(),
            if (list.isNotEmpty)
              GestureDetector(
                onTap: () => widget.onOpenLibrary?.call(),
                child: Text('See all ${list.length}',
                    style: _body(12, color: _kAccentDeep, w: FontWeight.w500)),
              ),
          ],
        )),
        const SizedBox(height: 12),
        if (list.isNotEmpty)
          SizedBox(
            height: 156,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _kGutter),
              physics: const BouncingScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _workoutCard(list[i]),
            ),
          ),
        const SizedBox(height: 12),
        _gutter(GestureDetector(
          onTap: () => widget.onCreateWorkout?.call(),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kInkFaint, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, size: 20, color: _kInk),
                const SizedBox(width: 8),
                Text('Create workout', style: _body(14, w: FontWeight.w600)),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _workoutCard(_WorkoutRow w) {
    return GestureDetector(
      onTap: () => widget.onStartWorkout?.call(w.id),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _displayName(w),
              style: _body(16, w: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text('${w.exerciseCount} exercises · ~${w.estMinutes} min',
                style: _body(12, color: _kInkMuted)),
            const SizedBox(height: 8),
            Text(
              w.muscles.isEmpty ? '—' : w.muscles.join(' · '),
              style: _body(12, color: _kInkMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    w.lastDoneAt == null
                        ? 'Never done'
                        : 'Done ${_ago(w.lastDoneAt)}',
                    style: _body(11, color: _kInkMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: _kInk,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text('Start',
                      style: _body(13, color: _kBg, w: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------ primitives --------------------------------

  Widget _darkCard({required Widget child}) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kInk,
          borderRadius: BorderRadius.circular(24),
        ),
        child: child,
      );

  Widget _lightCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) =>
      Container(
        padding: padding,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      );

  Widget _pillDark(String text, {Widget? icon}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon, const SizedBox(width: 5)],
            Text(text,
                style: _body(12,
                    color: const Color(0xFFD7E0DE), w: FontWeight.w500)),
          ],
        ),
      );

  Widget _primaryButton(String label, {IconData? icon, VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: _kAccent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: _kInk),
                const SizedBox(width: 6),
              ],
              Text(label, style: _body(16, w: FontWeight.w600)),
            ],
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Score ring
// ---------------------------------------------------------------------------
class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.label});
  final double score;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(50, 50),
            painter: _RingPainter(score.clamp(0, 10) / 10),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _kInk,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const r = 21.0;
    final bg = Paint()
      ..color = _kLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final fg = Paint()
      ..color = _kAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, bg);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * t,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// Unified form-check icon: video camera with a sparkle
// ---------------------------------------------------------------------------
class _FormCheckIcon extends StatelessWidget {
  const _FormCheckIcon({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FormCheckPainter(color)),
    );
  }
}

class _FormCheckPainter extends CustomPainter {
  _FormCheckPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3 * s, 7 * s, 13 * s, 10 * s),
        Radius.circular(2 * s),
      ),
      stroke,
    );
    final lens = Path()
      ..moveTo(16 * s, 10 * s)
      ..lineTo(21 * s, 7 * s)
      ..lineTo(21 * s, 17 * s)
      ..lineTo(16 * s, 14 * s);
    canvas.drawPath(lens, stroke);
    final sp = Path()
      ..moveTo(19 * s, 1.5 * s)
      ..lineTo(19.7 * s, 3.3 * s)
      ..lineTo(21.5 * s, 4 * s)
      ..lineTo(19.7 * s, 4.7 * s)
      ..lineTo(19 * s, 6.5 * s)
      ..lineTo(18.3 * s, 4.7 * s)
      ..lineTo(16.5 * s, 4 * s)
      ..lineTo(18.3 * s, 3.3 * s)
      ..close();
    canvas.drawPath(sp, fill);
  }

  @override
  bool shouldRepaint(_FormCheckPainter old) => old.color != color;
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
