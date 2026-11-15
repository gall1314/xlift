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
import 'package:intl/intl.dart' as intl show DateFormat;

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
/// Localization: reads the app language from FFLocalizations (no parameter);
/// Hebrew renders RTL, the charts stay left-to-right (oldest -> newest). The
/// analyzer's own texts (feedback, tip) are stored in English and shown
/// through the custom function localizeAnalysisText.
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
// Localization
// ---------------------------------------------------------------------------

const Set<String> _kRtl = {'he', 'ar'};

String _langOf(BuildContext ctx) {
  try {
    final l = FFLocalizations.of(ctx).languageCode.trim().toLowerCase();
    return l.isEmpty ? 'en' : l;
  } catch (_) {
    return 'en';
  }
}

ui.TextDirection _dirOf(String lang) =>
    _kRtl.contains(lang) ? ui.TextDirection.rtl : ui.TextDirection.ltr;

/// {n} / {m} are numbers. Stat labels are short on purpose - the tiles are
/// a third of the card.
const Map<String, Map<String, String>> _kStrings = {
  "formAnalysis": {
    "en": "Form Analysis",
    "es": "Análisis de técnica",
    "he": "ניתוח טכניקה",
    "de": "Technik-Analyse",
    "fr": "Analyse technique"
  },
  "scoreOverTime": {
    "en": "Technique score over time",
    "es": "Tu técnica a lo largo del tiempo",
    "he": "ציון טכניקה לאורך זמן",
    "de": "Technikwert im Zeitverlauf",
    "fr": "Score technique dans le temps"
  },
  "lastSets1": {
    "en": "Technique score, last set",
    "es": "Técnica, última serie",
    "he": "ציון טכניקה, הסט האחרון",
    "de": "Technikwert, letzter Satz",
    "fr": "Score technique, dernière série"
  },
  "lastSetsN": {
    "en": "Technique score, last {n} sets",
    "es": "Técnica, últimas {n} series",
    "he": "ציון טכניקה, {n} סטים אחרונים",
    "de": "Technikwert, letzte {n} Sätze",
    "fr": "Score technique, {n} dernières séries"
  },
  "vsLast": {
    "en": "vs. last",
    "es": "vs. anterior",
    "he": "מול הקודם",
    "de": "ggü. letztem",
    "fr": "vs précédent"
  },
  "perfectReps": {
    "en": "Perfect reps",
    "es": "Reps perfectas",
    "he": "חזרות מושלמות",
    "de": "Perfekte Wdh.",
    "fr": "Reps parfaites"
  },
  "avgDepth": {
    "en": "Avg depth",
    "es": "Prof. media",
    "he": "עומק ממוצע",
    "de": "Ø Tiefe",
    "fr": "Prof. moy."
  },
  "avgScore": {
    "en": "Avg score",
    "es": "Punt. media",
    "he": "ציון ממוצע",
    "de": "Ø Wert",
    "fr": "Score moy."
  },
  "best": {
    "en": "Best",
    "es": "Mejor",
    "he": "שיא",
    "de": "Bestwert",
    "fr": "Meilleur"
  },
  "bestScore": {
    "en": "Best score",
    "es": "Mejor punt.",
    "he": "ציון שיא",
    "de": "Bestwert",
    "fr": "Meilleur score"
  },
  "emptyHint": {
    "en":
        "Analyze a set with AI to see your technique score, depth and what to fix.",
    "es":
        "Analiza una serie con IA para ver tu puntuación, la profundidad y qué corregir.",
    "he": "נתחו סט עם AI כדי לראות ציון טכניקה, עומק ומה לתקן.",
    "de":
        "Analysiere einen Satz mit KI und sieh Technikwert, Tiefe und was du verbessern kannst.",
    "fr":
        "Analyse une série avec l’IA pour voir ton score, la profondeur et quoi corriger."
  },
  "tapFull": {
    "en": "Tap for full analysis",
    "es": "Ver el análisis completo",
    "he": "לניתוח המלא",
    "de": "Zur vollständigen Analyse",
    "fr": "Voir l’analyse complète"
  },
  "acrossSets": {
    "en": "Technique score across analyzed sets",
    "es": "Puntuación en las series analizadas",
    "he": "ציון טכניקה בסטים שנותחו",
    "de": "Technikwert der analysierten Sätze",
    "fr": "Score technique des séries analysées"
  },
  "vsPrev": {
    "en": "vs. previous set",
    "es": "vs. serie anterior",
    "he": "מול הסט הקודם",
    "de": "ggü. vorherigem Satz",
    "fr": "vs série précédente"
  },
  "holding": {
    "en": "What’s holding you back",
    "es": "Qué te frena",
    "he": "מה מעכב אותך",
    "de": "Was dich bremst",
    "fr": "Ce qui te freine"
  },
  "setsReps1": {
    "en": "{n} set · {m} reps",
    "es": "{n} serie · {m} reps",
    "he": "סט {n} · {m} חזרות",
    "de": "{n} Satz · {m} Wdh.",
    "fr": "{n} série · {m} reps"
  },
  "setsRepsN": {
    "en": "{n} sets · {m} reps",
    "es": "{n} series · {m} reps",
    "he": "{n} סטים · {m} חזרות",
    "de": "{n} Sätze · {m} Wdh.",
    "fr": "{n} séries · {m} reps"
  },
  "noIssues": {
    "en": "No issues detected — great form!",
    "es": "Sin problemas: ¡gran técnica!",
    "he": "לא זוהו בעיות, טכניקה מצוינת!",
    "de": "Keine Probleme – starke Technik!",
    "fr": "Aucun problème : super technique !"
  },
  "ofSets": {
    "en": "{n} of {m} sets",
    "es": "{n} de {m} series",
    "he": "{n} מתוך {m} סטים",
    "de": "{n} von {m} Sätzen",
    "fr": "{n} sur {m} séries"
  },
  "lastSetRep": {
    "en": "Last set, rep by rep",
    "es": "Última serie, rep a rep",
    "he": "הסט האחרון, חזרה אחר חזרה",
    "de": "Letzter Satz, Wdh. für Wdh.",
    "fr": "Dernière série, rep par rep"
  },
  "perfectCount": {
    "en": "{n}/{m} perfect",
    "es": "{n}/{m} perfectas",
    "he": "{n}/{m} מושלמות",
    "de": "{n}/{m} perfekt",
    "fr": "{n}/{m} parfaites"
  },
  "setN": {
    "en": "Set {n}",
    "es": "Serie {n}",
    "he": "סט {n}",
    "de": "Satz {n}",
    "fr": "Série {n}"
  },
  "repN": {
    "en": "Rep {n}",
    "es": "Rep {n}",
    "he": "חזרה {n}",
    "de": "Wdh. {n}",
    "fr": "Rep {n}"
  },
  "depthPct": {
    "en": "Depth {n}%",
    "es": "Prof. {n}%",
    "he": "עומק {n}%",
    "de": "Tiefe {n}%",
    "fr": "Prof. {n}%"
  },
  "perfectRep": {
    "en": "Perfect rep",
    "es": "Rep perfecta",
    "he": "חזרה מושלמת",
    "de": "Perfekte Wdh.",
    "fr": "Rep parfaite"
  },
  "openSet": {
    "en": "Open set analysis",
    "es": "Abrir análisis de la serie",
    "he": "לניתוח הסט",
    "de": "Satz-Analyse öffnen",
    "fr": "Ouvrir l’analyse de la série"
  },
  "excellentCaps": {
    "en": "EXCELLENT",
    "es": "EXCELENTE",
    "he": "מצוין",
    "de": "EXZELLENT",
    "fr": "EXCELLENT"
  },
  // score labels
  "lExcellent": {
    "en": "Excellent",
    "es": "Excelente",
    "he": "מצוין",
    "de": "Exzellent",
    "fr": "Excellent"
  },
  "lVeryGood": {
    "en": "Very good",
    "es": "Muy bien",
    "he": "טוב מאוד",
    "de": "Sehr gut",
    "fr": "Très bien"
  },
  "lGood": {"en": "Good", "es": "Bien", "he": "טוב", "de": "Gut", "fr": "Bien"},
  "lFair": {
    "en": "Fair",
    "es": "Regular",
    "he": "סביר",
    "de": "Okay",
    "fr": "Correct"
  },
  "lNeedsWork": {
    "en": "Needs work",
    "es": "A mejorar",
    "he": "דורש שיפור",
    "de": "Ausbaufähig",
    "fr": "À travailler"
  },
};

String _tr(String lang, String key, {int? n, int? m}) {
  final map = _kStrings[key];
  var s = map == null ? key : (map[lang] ?? map['en'] ?? key);
  if (n != null) s = s.replaceAll('{n}', '$n');
  if (m != null) s = s.replaceAll('{m}', '$m');
  return s;
}

/// The label stored with an analysis is English ("Very good"); show it in
/// the app language when it is one of the known ones, as stored otherwise.
String _locLabel(String lang, String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'excellent':
      return _tr(lang, 'lExcellent');
    case 'very good':
      return _tr(lang, 'lVeryGood');
    case 'good':
      return _tr(lang, 'lGood');
    case 'fair':
      return _tr(lang, 'lFair');
    case 'needs work':
      return _tr(lang, 'lNeedsWork');
    default:
      return raw;
  }
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

String _fmtDate(String lang, DateTime d) {
  try {
    return intl.DateFormat.MMMd(lang).format(d);
  } catch (_) {
    return intl.DateFormat.MMMd().format(d);
  }
}

String _scoreStr(double s) {
  final q = (s * 2).round() / 2.0;
  return q == q.roundToDouble() ? q.round().toString() : q.toStringAsFixed(1);
}

String _labelFor(String lang, double s) {
  if (s >= 9.5) return _tr(lang, 'lExcellent');
  if (s >= 8.5) return _tr(lang, 'lVeryGood');
  if (s >= 7.0) return _tr(lang, 'lGood');
  if (s >= 5.5) return _tr(lang, 'lFair');
  return _tr(lang, 'lNeedsWork');
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
    // tracking looks wrong on Hebrew glyphs
    letterSpacing: _kRtl.contains(_langOf(ctx)) ? 0 : ls,
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

Widget _chip(BuildContext ctx, String text, Color bg, Color fg,
    {bool ltr = false}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration:
        BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(text,
        textDirection: ltr ? ui.TextDirection.ltr : null,
        style: _ts(ctx, 12, FontWeight.w600, fg)),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(label,
                maxLines: 1,
                style: _ts(ctx, 11, FontWeight.w500, th.secondaryText)),
          ),
          const SizedBox(height: 2),
          Text(value,
              textDirection: ui.TextDirection.ltr,
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
    return Directionality(
      textDirection: _dirOf(_langOf(context)),
      child: SizedBox(
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
      ),
    );
  }

  // ---------- empty: dimmed preview of the real card, not tappable ----------
  Widget _empty(BuildContext ctx) {
    final th = FlutterFlowTheme.of(ctx);
    final String lang = _langOf(ctx);
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
                    Text(_tr(lang, 'formAnalysis'),
                        style: _ts(ctx, 18, FontWeight.w700, th.primaryText)),
                    Text(_tr(lang, 'scoreOverTime'),
                        style: _ts(ctx, 13, FontWeight.w500, th.secondaryText)),
                  ],
                ),
              ),
              RichText(
                textDirection: ui.TextDirection.ltr,
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
              _miniStat(ctx, _tr(lang, 'perfectReps'), '—', valueColor: dim),
              const SizedBox(width: 8),
              _miniStat(ctx, _tr(lang, 'avgDepth'), '—', valueColor: dim),
              const SizedBox(width: 8),
              _miniStat(ctx, _tr(lang, 'best'), '—', valueColor: dim),
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
                  _tr(lang, 'emptyHint'),
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
    final String lang = _langOf(ctx);
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
                      Text(_tr(lang, 'formAnalysis'),
                          style: _ts(ctx, 18, FontWeight.w700, th.primaryText)),
                      Text(
                          shown == 1
                              ? _tr(lang, 'lastSets1')
                              : _tr(lang, 'lastSetsN', n: shown),
                          style:
                              _ts(ctx, 13, FontWeight.w500, th.secondaryText)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RichText(
                      textDirection: ui.TextDirection.ltr,
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
                        '\u2066${delta >= 0 ? '+' : ''}${_scoreStr(delta)}\u2069 ${_tr(lang, 'vsLast')}',
                        style: _ts(ctx, 12, FontWeight.w600,
                            delta >= 0 ? th.primary : _kWarn),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // a time axis (oldest -> newest): left-to-right in every language
            Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Column(
                children: [
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
                      Text(_fmtDate(lang, recent.first.when),
                          style:
                              _ts(ctx, 11, FontWeight.w500, th.secondaryText)),
                      Text(_fmtDate(lang, recent.last.when),
                          style:
                              _ts(ctx, 11, FontWeight.w500, th.secondaryText)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _miniStat(ctx, _tr(lang, 'perfectReps'), '$perfectPct%'),
                const SizedBox(width: 8),
                avgDepth != null
                    ? _miniStat(ctx, _tr(lang, 'avgDepth'),
                        '${(avgDepth * 100).round()}%')
                    : _miniStat(ctx, _tr(lang, 'avgScore'), _scoreStr(avg)),
                const SizedBox(width: 8),
                _miniStat(ctx, _tr(lang, 'best'), _scoreStr(best)),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: th.alternate.withOpacity(0.6)),
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_tr(lang, 'tapFull'),
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
    final String lang = _langOf(context);
    String? exName = widget.exerciseName;
    if (exName != null) {
      try {
        // the name may arrive as stored ({"en":..,"he":..})
        final String loc = localizedName(exName, lang).trim();
        if (loc.isNotEmpty) exName = loc;
      } catch (_) {}
    }
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

    return Directionality(
      textDirection: _dirOf(lang),
      child: Scaffold(
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
                              Text(_tr(lang, 'formAnalysis'),
                                  style: _ts(context, 20, FontWeight.w700,
                                      th.primaryText)),
                            ],
                          ),
                          if (exName != null)
                            Text(exName,
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
                            child: Text(_tr(lang, 'acrossSets'),
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
                                      textDirection: ui.TextDirection.ltr,
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
                                    Text(
                                        last.label != null
                                            ? _locLabel(lang, last.label!)
                                            : _labelFor(lang, last.score),
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
                                      ltr: true,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(_tr(lang, 'vsPrev'),
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
                            // a time axis: left-to-right in every language
                            child: Directionality(
                              textDirection: ui.TextDirection.ltr,
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
                                      excellentLabel:
                                          _tr(lang, 'excellentCaps'),
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
                                        Text(_fmtDate(lang, list.first.when),
                                            style: _ts(
                                                context,
                                                11,
                                                FontWeight.w500,
                                                th.secondaryText)),
                                        Text(_fmtDate(lang, list.last.when),
                                            style: _ts(
                                                context,
                                                11,
                                                FontWeight.w500,
                                                th.secondaryText)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _bigStat(context, _tr(lang, 'perfectReps'),
                                  '$perfectPct%'),
                              _vDiv(context),
                              avgDepth != null
                                  ? _bigStat(context, _tr(lang, 'avgDepth'),
                                      '${(avgDepth * 100).round()}%')
                                  : _bigStat(context, _tr(lang, 'avgScore'),
                                      _scoreStr(avg)),
                              _vDiv(context),
                              _bigStat(context, _tr(lang, 'bestScore'),
                                  _scoreStr(best)),
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
                                child: Text(_tr(lang, 'holding'),
                                    style: _ts(context, 17, FontWeight.w700,
                                        th.primaryText)),
                              ),
                              Text(
                                  _tr(
                                      lang,
                                      list.length == 1
                                          ? 'setsReps1'
                                          : 'setsRepsN',
                                      n: list.length,
                                      m: totalReps),
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
                                Expanded(
                                  child: Text(_tr(lang, 'noIssues'),
                                      style: _ts(context, 14, FontWeight.w600,
                                          th.primaryText)),
                                ),
                              ],
                            ),
                          for (final e in issueList) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Text(localizeAnalysisText(e.key, lang),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: _ts(context, 14, FontWeight.w600,
                                          th.primaryText)),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                    _tr(lang, 'ofSets',
                                        n: e.value, m: list.length),
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
                                    child: Text(localizeAnalysisText(tip, lang),
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
      ),
    );
  }

  Widget _lastSet(BuildContext ctx, _Analysis last) {
    final th = FlutterFlowTheme.of(ctx);
    final String lang = _langOf(ctx);
    String labelOf(_Analysis a) =>
        a.label != null ? _locLabel(lang, a.label!) : _labelFor(lang, a.score);
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
              child: Text(_tr(lang, 'lastSetRep'),
                  style: _ts(ctx, 17, FontWeight.w700, th.primaryText)),
            ),
            Text(
                _tr(lang, 'perfectCount',
                    n: last.properReps, m: last.totalReps),
                style: _ts(ctx, 12, FontWeight.w600, th.secondaryText)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
            '${_fmtDate(lang, last.when)} · ${_tr(lang, 'setN', n: last.setNumber)} · ${labelOf(last)}',
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
                          textDirection: ui.TextDirection.ltr,
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
                      Text(_tr(lang, 'repN', n: sel + 1),
                          style: _ts(ctx, 14, FontWeight.w700, th.primaryText)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_scoreStr(last.reps[sel].score)} · ${_labelFor(lang, last.reps[sel].score)}'
                          '${last.reps[sel].depth != null ? ' · ${_tr(lang, 'depthPct', n: (last.reps[sel].depth! * 100).round())}' : ''}',
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
                          _chip(ctx, localizeAnalysisText(f, lang),
                              _kWarn.withOpacity(0.12), _kWarnText),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    Text(_tr(lang, 'perfectRep'),
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
                  _chip(ctx, localizeAnalysisText(f, lang),
                      _kWarn.withOpacity(0.12), _kWarnText),
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
                  Text(_tr(lang, 'openSet'),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label,
                maxLines: 1,
                style: _ts(ctx, 12, FontWeight.w500, th.secondaryText)),
          ),
          const SizedBox(height: 2),
          Text(value,
              textDirection: ui.TextDirection.ltr,
              style: _ts(ctx, 22, FontWeight.w800, th.primary)),
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
    this.excellentLabel,
    this.onPointTap,
  });

  final List<_Analysis> points;
  final Color accent, warn, grid;
  final Color? labelColor;
  final String? excellentLabel;
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
        excellentLabel: excellentLabel,
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
    this.excellentLabel,
  });

  final List<_Analysis> points;
  final Color accent, warn, grid;
  final Color? labelColor;
  final String? excellentLabel;
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
            text: excellentLabel ?? 'EXCELLENT',
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
