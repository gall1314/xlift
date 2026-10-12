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

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui show TextDirection;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// AI Form Analysis for one exercise — self-contained.
///
/// Compact teaser card (score, delta, mini chart, 3 stats). Tapping it pushes
/// a full-screen page (same data, no reload) with a close button, big chart
/// with tappable points, "What's holding you back", tip and the last set
/// rep-by-rep. Loads getExerciseAnalyses(exerciseId, userId).
///
/// No analyses → non-tappable "preview" card showing what the user will get
/// once a set is analyzed.
///
/// [onSetTap](setLogId, analysis) fires from chart points / "Open set
/// analysis": the widget runs getSetAnalysis(setLogId) itself and hands over
/// the raw GetSetAnalysisRow. set_log.id is a UUID string.
class FormAnalysisCard extends StatefulWidget {
  const FormAnalysisCard({
    super.key,
    this.width,
    this.height,
    required this.exerciseId,
    required this.userId,
    this.exerciseName,
    this.onSetTap,
  });

  final double? width;
  final double? height;
  final int exerciseId;
  final String userId;
  final String? exerciseName;
  final Future Function(String setLogId, GetSetAnalysisRow analysis)? onSetTap;

  @override
  State<FormAnalysisCard> createState() => _FormAnalysisCardState();
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

class _Rep {
  final double score;
  final double? depth;
  final List<String> feedback;
  const _Rep(this.score, this.depth, this.feedback);
  bool get good => score >= 9.5;
}

class _Analysis {
  final String analysisId;
  final String setLogId; // UUID
  final int setNumber, totalReps, properReps;
  final double score;
  final double? avgDepth;
  final DateTime when;
  final List<String> feedback;
  final List<_Rep> reps;
  final String? label, tip;
  const _Analysis({
    required this.analysisId,
    required this.setLogId,
    required this.setNumber,
    required this.totalReps,
    required this.properReps,
    required this.score,
    required this.avgDepth,
    required this.when,
    required this.feedback,
    required this.reps,
    required this.label,
    required this.tip,
  });
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

const Color _kWarn = Color(0xFFF59E0B);
const Color _kWarnText = Color(0xFFB45309);

const List<String> _kMonths = [
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
String _fmtDate(DateTime d) => '${_kMonths[d.month - 1]} ${d.day}';

String _scoreStr(double s) {
  final q = (s * 2).round() / 2.0;
  return q == q.roundToDouble() ? q.round().toString() : q.toStringAsFixed(1);
}

String _labelFor(double s) {
  if (s >= 9.5) return 'Excellent';
  if (s >= 8.5) return 'Very good';
  if (s >= 7.0) return 'Good';
  if (s >= 5.5) return 'Fair';
  return 'Needs work';
}

double? _avgDepthOf(List<_Analysis> list) {
  final ds = list.map((e) => e.avgDepth).whereType<double>().toList();
  if (ds.isEmpty) return null;
  return ds.reduce((a, b) => a + b) / ds.length;
}

TextStyle _ts(BuildContext ctx, double size, FontWeight w, Color c,
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

/// Same look as the app's analytics cards: secondaryBackground, radius 16,
/// 1px alternate border.
Widget _cardBox(BuildContext ctx, {required Widget child}) {
  final th = FlutterFlowTheme.of(ctx);
  return Container(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
    decoration: BoxDecoration(
      color: th.secondaryBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: th.alternate, width: 1),
    ),
    child: child,
  );
}

Widget _aiBadge(BuildContext ctx) {
  final th = FlutterFlowTheme.of(ctx);
  return Container(
    width: 26,
    height: 26,
    decoration: BoxDecoration(
      color: th.primary.withOpacity(0.14),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(Icons.auto_awesome_rounded, size: 15, color: th.primary),
  );
}

Widget _chip(BuildContext ctx, String text, Color bg, Color fg) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration:
        BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: _ts(ctx, 12, FontWeight.w600, fg)),
  );
}

Widget _miniStat(BuildContext ctx, String label, String value,
    {Color? valueColor}) {
  final th = FlutterFlowTheme.of(ctx);
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: th.primaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _ts(ctx, 11, FontWeight.w500, th.secondaryText)),
          const SizedBox(height: 2),
          Text(value,
              style: _ts(ctx, 18, FontWeight.w800, valueColor ?? th.primary)),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Teaser (the widget placed in FF)
// ---------------------------------------------------------------------------

class _FormAnalysisCardState extends State<FormAnalysisCard> {
  late Future<List<_Analysis>> _future;
  bool _fullOpen = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant FormAnalysisCard old) {
    super.didUpdateWidget(old);
    if (old.exerciseId != widget.exerciseId || old.userId != widget.userId) {
      _future = _load();
    }
  }

  // ---------- parsing ----------
  static int _i(dynamic v, [int d = 0]) {
    if (v == null) return d;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? d;
  }

  static double _d(dynamic v, [double d = 0]) {
    if (v == null) return d;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? d;
  }

  static double? _dN(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    return s.isEmpty || s == 'null' ? null : double.tryParse(s);
  }

  static String? _sN(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty || s == 'null' ? null : s;
  }

  static Map<String, dynamic> _rowMap(dynamic row) {
    try {
      final d = (row as dynamic).data;
      if (d is Map) return Map<String, dynamic>.from(d);
    } catch (_) {}
    if (row is Map) return Map<String, dynamic>.from(row);
    return const {};
  }

  static DateTime _parseDate(dynamic v) {
    final s = v?.toString().trim() ?? '';
    if (s.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    if (RegExp(r'^\d+$').hasMatch(s)) {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(s)).toLocal();
    }
    return DateTime.tryParse(s.replaceFirst(' ', 'T'))?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static bool _isIssue(String s) {
    final l = s.trim().toLowerCase();
    if (l.isEmpty) return false;
    if (l.startsWith('great form')) return false;
    if (l.startsWith("couldn't analyze")) return false;
    if (l.startsWith('could not analyze')) return false;
    return true;
  }

  static List<String> _parseFeedback(dynamic v) {
    final s = v?.toString().trim() ?? '';
    if (s.isEmpty) return const [];
    try {
      final j = jsonDecode(s);
      if (j is List) {
        return j.map((e) => e.toString().trim()).where(_isIssue).toList();
      }
    } catch (_) {}
    final sep = s.contains('|') ? '|' : (s.contains('\n') ? '\n' : ',');
    return s
        .split(sep)
        .map((e) => e.trim().replaceAll(RegExp(r'^[\[\]"]+|[\[\]"]+$'), ''))
        .where(_isIssue)
        .toList();
  }

  static List<_Rep> _parseReps(dynamic v) {
    final s = v?.toString().trim() ?? '';
    if (s.isEmpty || s == 'null') return const [];
    try {
      final j = jsonDecode(s);
      if (j is! List) return const [];
      return j.whereType<Map>().map((m) {
        final f = m['f'];
        return _Rep(
          _d(m['s']),
          _dN(m['d']),
          f is List ? f.map((e) => e.toString()).toList() : const [],
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<_Analysis>> _load() async {
    final rows = await SQLiteManager.instance.getExerciseAnalyses(
      exerciseId: widget.exerciseId,
      userId: widget.userId,
    );
    final out = <_Analysis>[];
    for (final r in rows) {
      final m = _rowMap(r);
      out.add(_Analysis(
        analysisId: m['analysis_id']?.toString() ?? '',
        setLogId: (m['set_log_id'] ?? '').toString().trim(),
        setNumber: _i(m['set_number']),
        totalReps: _i(m['total_reps']),
        properReps: _i(m['proper_reps']),
        score: _d(m['score']),
        avgDepth: _dN(m['avg_depth']),
        when: _parseDate(m['analyzed_at'] ?? m['workout_date']),
        feedback: _parseFeedback(m['feedback']),
        reps: _parseReps(m['reps_json']),
        label: _sN(m['technique_label']),
        tip: _sN(m['form_tip']),
      ));
    }
    out.sort((a, b) => a.when.compareTo(b.when));
    return out;
  }

  // ---------- open full page (internal route, same data) ----------
  void _openFull(List<_Analysis> list) {
    if (_fullOpen) return;
    _fullOpen = true;
    HapticFeedback.selectionClick();
    Navigator.of(context, rootNavigator: true)
        .push(PageRouteBuilder(
          opaque: true,
          transitionDuration: const Duration(milliseconds: 240),
          pageBuilder: (ctx, a, b) => _FormAnalysisFullPage(
            list: list,
            exerciseName: widget.exerciseName,
            onSetTap: widget.onSetTap,
          ),
          transitionsBuilder: (ctx, anim, sec, child) => SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0, 0.06), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: FadeTransition(opacity: anim, child: child),
          ),
        ))
        .whenComplete(() => _fullOpen = false);
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Align(
        alignment: Alignment.topCenter,
        child: FutureBuilder<List<_Analysis>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return _cardBox(
                context,
                child: SizedBox(
                  height: 120,
                  child: Center(
                      child: CircularProgressIndicator(color: th.primary)),
                ),
              );
            }
            final list = snap.data!;
            if (list.isEmpty) return _empty(context);
            return _teaser(context, list);
          },
        ),
      ),
    );
  }

  // ---------- empty: dimmed preview of the real card, not tappable ----------
  Widget _empty(BuildContext ctx) {
    final th = FlutterFlowTheme.of(ctx);
    final Color dim = th.secondaryText.withOpacity(0.45);
    return _cardBox(
      ctx,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _aiBadge(ctx),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Form Analysis',
                        style: _ts(ctx, 18, FontWeight.w700, th.primaryText)),
                    Text('Technique score over time',
                        style: _ts(ctx, 13, FontWeight.w500, th.secondaryText)),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                      text: '—',
                      style: _ts(ctx, 30, FontWeight.w800, dim, height: 1.0)),
                  TextSpan(
                      text: ' /10', style: _ts(ctx, 13, FontWeight.w600, dim)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: CustomPaint(
              size: Size.infinite,
              painter: _PlaceholderChartPainter(
                color: th.primary.withOpacity(0.35),
                grid: th.alternate.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStat(ctx, 'Perfect reps', '—', valueColor: dim),
              const SizedBox(width: 8),
              _miniStat(ctx, 'Avg depth', '—', valueColor: dim),
              const SizedBox(width: 8),
              _miniStat(ctx, 'Best', '—', valueColor: dim),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: th.alternate.withOpacity(0.6)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.videocam_outlined, size: 18, color: th.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Analyze a set with AI to see your technique score, depth and what to fix.',
                  style: _ts(ctx, 13, FontWeight.w500, th.secondaryText,
                      height: 1.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- teaser ----------
  Widget _teaser(BuildContext ctx, List<_Analysis> list) {
    final th = FlutterFlowTheme.of(ctx);
    final last = list.last;
    final double? delta =
        list.length >= 2 ? last.score - list[list.length - 2].score : null;
    final int shown = math.min(list.length, 8);
    final recent = list.sublist(list.length - shown);
    final int totalReps = list.fold(0, (a, b) => a + b.totalReps);
    final int properReps = list.fold(0, (a, b) => a + b.properReps);
    final int perfectPct =
        totalReps == 0 ? 0 : (properReps * 100 / totalReps).round();
    final double best = list.map((e) => e.score).reduce(math.max);
    final double avg =
        list.map((e) => e.score).reduce((a, b) => a + b) / list.length;
    final double? avgDepth = _avgDepthOf(list);

    return _Pressable(
      onTap: () => _openFull(list),
      child: _cardBox(
        ctx,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _aiBadge(ctx),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Form Analysis',
                          style: _ts(ctx, 18, FontWeight.w700, th.primaryText)),
                      Text(
                          'Technique score, last $shown set${shown == 1 ? '' : 's'}',
                          style:
                              _ts(ctx, 13, FontWeight.w500, th.secondaryText)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                            text: _scoreStr(last.score),
                            style: _ts(ctx, 30, FontWeight.w800, th.primary,
                                height: 1.0)),
                        TextSpan(
                            text: ' /10',
                            style: _ts(
                                ctx, 13, FontWeight.w600, th.secondaryText)),
                      ]),
                    ),
                    if (delta != null)
                      Text(
                        '${delta >= 0 ? '+' : ''}${_scoreStr(delta)} vs. last',
                        style: _ts(ctx, 12, FontWeight.w600,
                            delta >= 0 ? th.primary : _kWarn),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 70,
              child: _ScoreChart(
                points: recent,
                accent: th.primary,
                warn: _kWarn,
                grid: th.alternate.withOpacity(0.6),
                compact: true,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmtDate(recent.first.when),
                    style: _ts(ctx, 11, FontWeight.w500, th.secondaryText)),
                Text(_fmtDate(recent.last.when),
                    style: _ts(ctx, 11, FontWeight.w500, th.secondaryText)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _miniStat(ctx, 'Perfect reps', '$perfectPct%'),
                const SizedBox(width: 8),
                avgDepth != null
                    ? _miniStat(
                        ctx, 'Avg depth', '${(avgDepth * 100).round()}%')
                    : _miniStat(ctx, 'Avg score', _scoreStr(avg)),
                const SizedBox(width: 8),
                _miniStat(ctx, 'Best', _scoreStr(best)),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: th.alternate.withOpacity(0.6)),
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Tap for full analysis',
                      style: _ts(ctx, 14, FontWeight.w600, th.primary)),
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: th.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full page (pushed by the teaser)
// ---------------------------------------------------------------------------

class _FormAnalysisFullPage extends StatefulWidget {
  const _FormAnalysisFullPage({
    required this.list,
    required this.exerciseName,
    required this.onSetTap,
  });

  final List<_Analysis> list;
  final String? exerciseName;
  final Future Function(String setLogId, GetSetAnalysisRow analysis)? onSetTap;

  @override
  State<_FormAnalysisFullPage> createState() => _FormAnalysisFullPageState();
}

class _FormAnalysisFullPageState extends State<_FormAnalysisFullPage> {
  int? _selectedRep;
  bool _firing = false;

  /// Loads the set's analysis row and hands it to the FF callback.
  Future<void> _fireSetTap(String setLogId) async {
    final cb = widget.onSetTap;
    if (cb == null || _firing || setLogId.isEmpty) return;
    _firing = true;
    try {
      final rows =
          await SQLiteManager.instance.getSetAnalysis(setLogId: setLogId);
      if (rows.isNotEmpty) await cb(setLogId, rows.first);
    } catch (_) {
    } finally {
      _firing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final list = widget.list;
    final last = list.last;
    final double? delta =
        list.length >= 2 ? last.score - list[list.length - 2].score : null;
    final int totalReps = list.fold(0, (a, b) => a + b.totalReps);
    final int properReps = list.fold(0, (a, b) => a + b.properReps);
    final int perfectPct =
        totalReps == 0 ? 0 : (properReps * 100 / totalReps).round();
    final double best = list.map((e) => e.score).reduce(math.max);
    final double avg =
        list.map((e) => e.score).reduce((a, b) => a + b) / list.length;
    final double? avgDepth = _avgDepthOf(list);

    final Map<String, int> issues = {};
    for (final a in list) {
      for (final f in a.feedback.toSet()) {
        issues[f] = (issues[f] ?? 0) + 1;
      }
    }
    final issueList = issues.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String? tip;
    for (final a in list.reversed) {
      if (a.tip != null) {
        tip = a.tip;
        break;
      }
    }

    return Scaffold(
      backgroundColor: th.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _aiBadge(context),
                            const SizedBox(width: 8),
                            Text('Form Analysis',
                                style: _ts(context, 20, FontWeight.w700,
                                    th.primaryText)),
                          ],
                        ),
                        if (widget.exerciseName != null)
                          Text(widget.exerciseName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _ts(context, 13, FontWeight.w500,
                                  th.secondaryText)),
                      ],
                    ),
                  ),
                  _Pressable(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: th.secondaryBackground,
                        shape: BoxShape.circle,
                        border: Border.all(color: th.alternate),
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 22, color: th.primaryText),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _cardBox(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text('Technique score across analyzed sets',
                              style: _ts(context, 13, FontWeight.w500,
                                  th.secondaryText)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(children: [
                                      TextSpan(
                                          text: _scoreStr(last.score),
                                          style: _ts(context, 44,
                                              FontWeight.w800, th.primary,
                                              height: 1.0)),
                                      TextSpan(
                                          text: ' / 10',
                                          style: _ts(
                                              context,
                                              16,
                                              FontWeight.w600,
                                              th.secondaryText)),
                                    ]),
                                  ),
                                  Text(last.label ?? _labelFor(last.score),
                                      style: _ts(context, 15, FontWeight.w700,
                                          th.primaryText)),
                                ],
                              ),
                            ),
                            if (delta != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _chip(
                                    context,
                                    '${delta >= 0 ? '▲ +' : '▼ '}${_scoreStr(delta)}',
                                    (delta >= 0 ? th.primary : _kWarn)
                                        .withOpacity(0.12),
                                    delta >= 0 ? th.primary : _kWarnText,
                                  ),
                                  const SizedBox(height: 4),
                                  Text('vs. previous set',
                                      style: _ts(context, 12, FontWeight.w500,
                                          th.secondaryText)),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.fromLTRB(8, 10, 10, 6),
                          decoration: BoxDecoration(
                            color: th.primaryBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: th.alternate),
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 160,
                                child: _ScoreChart(
                                  points: list,
                                  accent: th.primary,
                                  warn: _kWarn,
                                  grid: th.alternate.withOpacity(0.7),
                                  labelColor: th.secondaryText,
                                  compact: false,
                                  onPointTap: widget.onSetTap == null
                                      ? null
                                      : (a) => _fireSetTap(a.setLogId),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 26),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_fmtDate(list.first.when),
                                        style: _ts(context, 11, FontWeight.w500,
                                            th.secondaryText)),
                                    Text(_fmtDate(list.last.when),
                                        style: _ts(context, 11, FontWeight.w500,
                                            th.secondaryText)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _bigStat(context, 'Perfect reps', '$perfectPct%'),
                            _vDiv(context),
                            avgDepth != null
                                ? _bigStat(context, 'Avg depth',
                                    '${(avgDepth * 100).round()}%')
                                : _bigStat(
                                    context, 'Avg score', _scoreStr(avg)),
                            _vDiv(context),
                            _bigStat(context, 'Best score', _scoreStr(best)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _cardBox(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text("What's holding you back",
                                  style: _ts(context, 17, FontWeight.w700,
                                      th.primaryText)),
                            ),
                            Text(
                                '${list.length} set${list.length == 1 ? '' : 's'} · $totalReps reps',
                                style: _ts(context, 12, FontWeight.w500,
                                    th.secondaryText)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (issueList.isEmpty)
                          Row(
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 18, color: th.primary),
                              const SizedBox(width: 8),
                              Text('No issues detected — great form!',
                                  style: _ts(context, 14, FontWeight.w600,
                                      th.primaryText)),
                            ],
                          ),
                        for (final e in issueList) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Text(e.key,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: _ts(context, 14, FontWeight.w600,
                                        th.primaryText)),
                              ),
                              const SizedBox(width: 8),
                              Text('${e.value} of ${list.length} sets',
                                  style: _ts(context, 12, FontWeight.w500,
                                      th.secondaryText)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: e.value / list.length,
                              minHeight: 7,
                              backgroundColor: th.alternate.withOpacity(0.5),
                              valueColor: AlwaysStoppedAnimation(
                                e.value / list.length >= 0.5
                                    ? _kWarn
                                    : th.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (tip != null) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: th.primary.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lightbulb_rounded,
                                    size: 18, color: th.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(tip,
                                      style: _ts(context, 13, FontWeight.w500,
                                          th.primaryText,
                                          height: 1.3)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _cardBox(context, child: _lastSet(context, last)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lastSet(BuildContext ctx, _Analysis last) {
    final th = FlutterFlowTheme.of(ctx);
    final bool hasReps = last.reps.isNotEmpty;
    final int? sel = (_selectedRep != null &&
            hasReps &&
            _selectedRep! >= 0 &&
            _selectedRep! < last.reps.length)
        ? _selectedRep
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Last set, rep by rep',
                  style: _ts(ctx, 17, FontWeight.w700, th.primaryText)),
            ),
            Text('${last.properReps}/${last.totalReps} perfect',
                style: _ts(ctx, 12, FontWeight.w600, th.secondaryText)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
            '${_fmtDate(last.when)} · Set ${last.setNumber} · ${last.label ?? _labelFor(last.score)}',
            style: _ts(ctx, 12, FontWeight.w500, th.secondaryText)),
        const SizedBox(height: 12),
        if (hasReps) ...[
          LayoutBuilder(builder: (ctx2, c) {
            const double gap = 6;
            final int n = last.reps.length;
            final int perRow = n <= 8 ? n : 8;
            final double w = (c.maxWidth - gap * (perRow - 1)) / perRow;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (int i = 0; i < n; i++)
                  _Pressable(
                    onTap: () => setState(
                        () => _selectedRep = _selectedRep == i ? null : i),
                    child: Container(
                      width: w,
                      height: w.clamp(34.0, 52.0),
                      decoration: BoxDecoration(
                        color: last.reps[i].good
                            ? th.primary
                            : _kWarn.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: sel == i ? th.primaryText : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(_scoreStr(last.reps[i].score),
                          style: _ts(ctx, 13, FontWeight.w800, Colors.white)),
                    ),
                  ),
              ],
            );
          }),
          if (sel != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: th.primaryBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Rep ${sel + 1}',
                          style: _ts(ctx, 14, FontWeight.w700, th.primaryText)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_scoreStr(last.reps[sel].score)} · ${_labelFor(last.reps[sel].score)}'
                          '${last.reps[sel].depth != null ? ' · Depth ${(last.reps[sel].depth! * 100).round()}%' : ''}',
                          style:
                              _ts(ctx, 13, FontWeight.w500, th.secondaryText),
                        ),
                      ),
                    ],
                  ),
                  if (last.reps[sel].feedback.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final f in last.reps[sel].feedback)
                          _chip(ctx, f, _kWarn.withOpacity(0.12), _kWarnText),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    Text('Perfect rep',
                        style: _ts(ctx, 13, FontWeight.w600, th.primary)),
                  ],
                ],
              ),
            ),
          ],
        ] else ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (last.properReps > 0)
                    Expanded(
                        flex: last.properReps,
                        child: Container(color: th.primary)),
                  if (last.totalReps - last.properReps > 0) ...[
                    if (last.properReps > 0) const SizedBox(width: 2),
                    Expanded(
                        flex: last.totalReps - last.properReps,
                        child: Container(color: _kWarn.withOpacity(0.7))),
                  ],
                  if (last.totalReps <= 0)
                    Expanded(
                        child: Container(color: th.alternate.withOpacity(0.5))),
                ],
              ),
            ),
          ),
          if (last.feedback.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final f in last.feedback)
                  _chip(ctx, f, _kWarn.withOpacity(0.12), _kWarnText),
              ],
            ),
          ],
        ],
        if (widget.onSetTap != null) ...[
          const SizedBox(height: 12),
          Center(
            child: _Pressable(
              onTap: () => _fireSetTap(last.setLogId),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Open set analysis',
                      style: _ts(ctx, 14, FontWeight.w600, th.primary)),
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: th.primary),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _bigStat(BuildContext ctx, String label, String value) {
    final th = FlutterFlowTheme.of(ctx);
    return Expanded(
      child: Column(
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _ts(ctx, 12, FontWeight.w500, th.secondaryText)),
          const SizedBox(height: 2),
          Text(value, style: _ts(ctx, 22, FontWeight.w800, th.primary)),
        ],
      ),
    );
  }

  Widget _vDiv(BuildContext ctx) => Container(
        width: 1,
        height: 36,
        color: FlutterFlowTheme.of(ctx).alternate,
      );
}

// ---------------------------------------------------------------------------
// Placeholder chart (empty state)
// ---------------------------------------------------------------------------

class _PlaceholderChartPainter extends CustomPainter {
  _PlaceholderChartPainter({required this.color, required this.grid});
  final Color color, grid;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width, h = size.height;
    final dp = Paint()
      ..color = grid
      ..strokeWidth = 1;
    double x = 0;
    while (x < w) {
      canvas.drawLine(Offset(x, 6), Offset(math.min(x + 5, w), 6), dp);
      x += 9;
    }
    final pts = [
      Offset(0, h * 0.78),
      Offset(w * 0.2, h * 0.70),
      Offset(w * 0.4, h * 0.74),
      Offset(w * 0.6, h * 0.48),
      Offset(w * 0.8, h * 0.36),
      Offset(w, h * 0.22),
    ];
    final area = Path()..moveTo(0, h);
    for (final p in pts) {
      area.lineTo(p.dx, p.dy);
    }
    area
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.35), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      line.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (final p in pts) {
      canvas.drawCircle(p, 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _PlaceholderChartPainter old) =>
      old.color != color || old.grid != grid;
}

// ---------------------------------------------------------------------------
// Score chart
// ---------------------------------------------------------------------------

class _ScoreChart extends StatelessWidget {
  const _ScoreChart({
    required this.points,
    required this.accent,
    required this.warn,
    required this.grid,
    required this.compact,
    this.labelColor,
    this.onPointTap,
  });

  final List<_Analysis> points;
  final Color accent, warn, grid;
  final Color? labelColor;
  final bool compact;
  final void Function(_Analysis a)? onPointTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      final painter = _ScoreChartPainter(
        points: points,
        accent: accent,
        warn: warn,
        grid: grid,
        labelColor: labelColor,
        compact: compact,
      );
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: onPointTap == null
            ? null
            : (d) {
                final i = painter.nearestPoint(size, d.localPosition);
                if (i != null) {
                  HapticFeedback.selectionClick();
                  onPointTap!(points[i]);
                }
              },
        child: CustomPaint(size: size, painter: painter),
      );
    });
  }
}

class _ScoreChartPainter extends CustomPainter {
  _ScoreChartPainter({
    required this.points,
    required this.accent,
    required this.warn,
    required this.grid,
    required this.compact,
    this.labelColor,
  });

  final List<_Analysis> points;
  final Color accent, warn, grid;
  final Color? labelColor;
  final bool compact;

  static const double _minY = 4.0, _maxY = 10.0;

  double get _left => compact ? 0 : 26;
  double get _top => compact ? 6 : 8;
  double get _bottom => compact ? 6 : 8;

  Offset _pt(Size s, int i) {
    final double w = s.width - _left;
    final double h = s.height - _top - _bottom;
    final double x = points.length == 1
        ? _left + w / 2
        : _left + w * i / (points.length - 1);
    final double v = points[i].score.clamp(_minY, _maxY);
    final double y = _top + h * (1 - (v - _minY) / (_maxY - _minY));
    return Offset(x, y);
  }

  int? nearestPoint(Size s, Offset p) {
    int? best;
    double bestD = 22 * 22;
    for (int i = 0; i < points.length; i++) {
      final d = (_pt(s, i) - p).distanceSquared;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final double w = size.width - _left;
    final double h = size.height - _top - _bottom;

    if (!compact) {
      final gp = Paint()
        ..color = grid
        ..strokeWidth = 1;
      for (final v in [4.0, 6.0, 8.0, 10.0]) {
        final double y = _top + h * (1 - (v - _minY) / (_maxY - _minY));
        canvas.drawLine(Offset(_left, y), Offset(size.width, y), gp);
        final tp = TextPainter(
          text: TextSpan(
              text: v.toInt().toString(),
              style: TextStyle(
                  color: labelColor ?? grid,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(0, y - tp.height / 2));
      }
    }

    final double yEx = _top + h * (1 - (9.5 - _minY) / (_maxY - _minY));
    final dp = Paint()
      ..color = accent.withOpacity(0.55)
      ..strokeWidth = 1;
    double x = _left;
    while (x < size.width) {
      canvas.drawLine(
          Offset(x, yEx), Offset(math.min(x + 5, size.width), yEx), dp);
      x += 9;
    }
    if (!compact) {
      final tp = TextPainter(
        text: TextSpan(
            text: 'EXCELLENT',
            style: TextStyle(
                color: accent,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - tp.width, yEx - tp.height - 2));
    }

    final pts = List.generate(points.length, (i) => _pt(size, i));

    if (pts.length >= 2) {
      final area = Path()..moveTo(pts.first.dx, _top + h);
      for (final p in pts) {
        area.lineTo(p.dx, p.dy);
      }
      area.lineTo(pts.last.dx, _top + h);
      area.close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [accent.withOpacity(0.22), accent.withOpacity(0.02)],
          ).createShader(Rect.fromLTWH(_left, _top, w, h)),
      );
      final line = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < pts.length; i++) {
        line.lineTo(pts[i].dx, pts[i].dy);
      }
      canvas.drawPath(
        line,
        Paint()
          ..color = accent
          ..strokeWidth = compact ? 2 : 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final double r = compact ? 3.5 : 5;
    for (int i = 0; i < pts.length; i++) {
      final bool good = points[i].score >= 9.5;
      final bool low = points[i].score < 7.0;
      final Color c = low ? warn : accent;
      canvas.drawCircle(pts[i], r, Paint()..color = Colors.white);
      canvas.drawCircle(
          pts[i],
          r,
          Paint()
            ..color = c
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      if (good || i == pts.length - 1) {
        canvas.drawCircle(pts[i], r - 1.5, Paint()..color = c);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreChartPainter old) =>
      old.points != points || old.accent != accent || old.compact != compact;
}

// ---------------------------------------------------------------------------
// Press feedback
// ---------------------------------------------------------------------------

class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;
  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) {
        _set(false);
        HapticFeedback.selectionClick();
        widget.onTap!();
      },
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: AnimatedOpacity(
          opacity: _down ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: widget.child,
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
