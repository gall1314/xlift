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

import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full "Workout Summary" page body (history view of one workout_log).
///
/// Loads everything itself from SQLite: history1(userId, workoutLogId) ->
/// hero card muscleGroupSammary(workoutLogId)          -> muscle distribution
/// workoutLogExercisesInfoById(workoutLogId) -> exercise cards
/// getSetLogs(workoutLogId, exerciseId)      -> set rows per exercise
/// getSetAnalysis(setLogId)                  -> AI badge per set
///
/// set_log.id and set_analysis.id are UUID strings.
///
/// Callbacks: [onExerciseTap](exerciseId, isPublic) from the ↗ button;
/// [onAnalysisTap](setLogId, analysisId, analysis) from the AI badge, where
/// analysis is the raw GetSetAnalysisRow.
class WorkoutSummaryView extends StatefulWidget {
  const WorkoutSummaryView({
    super.key,
    this.width,
    this.height,
    required this.workoutLogId,
    required this.userId,
    this.onBack,
    this.onCompare,
    this.onMore,
    this.onExerciseTap,
    this.onAnalysisTap,
  });

  final double? width;
  final double? height;
  final String workoutLogId;
  final String userId;
  final Future Function()? onBack;
  final Future Function()? onCompare;
  final Future Function()? onMore;
  final Future Function(int exerciseId, bool isPublic)? onExerciseTap;
  final Future Function(
          String setLogId, String analysisId, GetSetAnalysisRow analysis)?
      onAnalysisTap;

  @override
  State<WorkoutSummaryView> createState() => _WorkoutSummaryViewState();
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

class _Summary {
  final String name, createdAt, unitLabel;
  final int durationMs, volume, totalSets, exerciseCount;
  const _Summary({
    required this.name,
    required this.createdAt,
    required this.durationMs,
    required this.volume,
    required this.unitLabel,
    required this.totalSets,
    required this.exerciseCount,
  });
}

class _Muscle {
  final String name;
  final int sets;
  const _Muscle(this.name, this.sets);
}

class _SetRow {
  final String id; // set_log.id (UUID)
  final int setNumber;
  final int? reps, durationMs;
  final double? weight;
  final bool isKg;
  final Map<String, dynamic>? analysis; // null = no analysis for this set
  final GetSetAnalysisRow? analysisRow; // raw SQLite row (passed to callback)
  const _SetRow(this.id, this.setNumber, this.reps, this.weight,
      this.durationMs, this.isKg, this.analysis, this.analysisRow);
}

class _Exercise {
  final int id, setsCount;
  final String name, total;
  final int? pctChange;
  final bool isTimed, isBodyweight, isWeighted, isPublic;
  final String? illustration, equipment, muscleGroup;
  final List<_SetRow> sets;
  const _Exercise({
    required this.id,
    required this.name,
    required this.setsCount,
    required this.total,
    required this.pctChange,
    required this.isTimed,
    required this.isBodyweight,
    required this.isWeighted,
    required this.isPublic,
    required this.illustration,
    required this.equipment,
    required this.muscleGroup,
    required this.sets,
  });
}

class _PageData {
  final _Summary summary;
  final List<_Muscle> muscles;
  final List<_Exercise> exercises;
  const _PageData(this.summary, this.muscles, this.exercises);
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class _WorkoutSummaryViewState extends State<WorkoutSummaryView> {
  late Future<_PageData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant WorkoutSummaryView old) {
    super.didUpdateWidget(old);
    if (old.workoutLogId != widget.workoutLogId ||
        old.userId != widget.userId) {
      _future = _load();
    }
  }

  // ---------- helpers ----------
  static int _i(dynamic v, [int d = 0]) {
    if (v == null) return d;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? d;
  }

  static int? _iN(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final s = v.toString().trim();
    return s.isEmpty ? null : int.tryParse(s);
  }

  static double? _dN(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    return s.isEmpty ? null : double.tryParse(s);
  }

  static String _s(dynamic v, [String d = '']) => v == null ? d : v.toString();

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

  // ---------- SQLite ----------
  Future<_PageData> _load() async {
    final db = SQLiteManager.instance;
    final String wlId = widget.workoutLogId;

    final histRows =
        await db.history1(userId: widget.userId, workoutLogId: wlId);
    final h =
        histRows.isNotEmpty ? _rowMap(histRows.first) : <String, dynamic>{};
    final summary = _Summary(
      name: _s(h['workout_name'], 'Workout'),
      createdAt: _s(h['created_at']),
      durationMs: _i(h['duration_seconds']),
      volume: _i(h['volume']),
      unitLabel: _s(h['unit_label'], 'Kg'),
      totalSets: _i(h['total_sets']),
      exerciseCount: _i(h['exercise_count']),
    );

    final muscleRows = await db.muscleGroupSammary(workoutLogId: wlId);
    final muscles = muscleRows.map((r) {
      final m = _rowMap(r);
      return _Muscle(_s(m['muscle_group_name']), _i(m['sets_for_muscle']));
    }).toList()
      ..sort((a, b) => b.sets.compareTo(a.sets));

    final exRows = await db.workoutLogExercisesInfoById(workoutLogId: wlId);
    final exercises = <_Exercise>[];
    for (final r in exRows) {
      final m = _rowMap(r);
      final int exId = _i(m['exercise_id']);
      final setRows = await db.getSetLogs(workoutLogId: wlId, exerciseId: exId);
      final sets = <_SetRow>[];
      for (final sr in setRows) {
        final s = _rowMap(sr);
        final String setLogId = _s(s['id']);
        Map<String, dynamic>? analysis;
        GetSetAnalysisRow? analysisRow;
        if (setLogId.isNotEmpty) {
          try {
            final aRows = await db.getSetAnalysis(setLogId: setLogId);
            if (aRows.isNotEmpty) {
              analysisRow = aRows.first;
              analysis = _rowMap(analysisRow);
            }
          } catch (_) {}
        }
        sets.add(_SetRow(
          setLogId,
          _i(s['set_number']),
          _iN(s['reps']),
          _dN(s['weight']),
          _iN(s['duration_seconds']),
          _i(s['is_kg'], 1) == 1,
          analysis,
          analysisRow,
        ));
      }
      exercises.add(_Exercise(
        id: exId,
        name: _s(m['exercise_name']),
        setsCount: _i(m['exercise_sets_count']),
        total: _s(m['exercise_total']),
        pctChange: _iN(m['exercise_percentage_change']),
        isTimed: _i(m['is_timed']) == 1,
        isBodyweight: _i(m['is_bodyweight']) == 1,
        isWeighted: _i(m['is_weighted']) == 1,
        isPublic: _i(m['is_public'], 1) == 1,
        illustration: _sN(m['illustration']),
        equipment: _sN(m['equipment']),
        muscleGroup: _sN(m['muscle_group']),
        sets: sets,
      ));
    }

    return _PageData(summary, muscles, exercises);
  }

  // ---------- formatting ----------
  static String _durationLabel(int ms) {
    final int totalMin = (ms / 60000).round();
    if (totalMin < 60) return '${totalMin}m';
    final int h = totalMin ~/ 60, m = totalMin % 60;
    return m == 0 ? '${h}h' : '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  static String _mmss(int ms) {
    final int s = (ms / 1000).round();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  static String _weightStr(double w) {
    if (w == w.roundToDouble()) return w.toInt().toString();
    String t = w.toStringAsFixed(1);
    if (t.endsWith('.0')) t = t.substring(0, t.length - 2);
    return t;
  }

  static const List<Color> _muscleColors = [
    Color(0xFF0F766E),
    Color(0xFF14B8A6),
    Color(0xFF5EEAD4),
    Color(0xFFB2F0E6),
    Color(0xFF115E59),
    Color(0xFF2DD4BF),
  ];

  TextStyle _t(BuildContext ctx, double size, FontWeight w, Color c,
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

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Container(
        color: th.primaryBackground,
        child: FutureBuilder<_PageData>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load workout\n${snap.error}',
                      textAlign: TextAlign.center,
                      style:
                          _t(context, 14, FontWeight.w500, th.secondaryText)),
                ),
              );
            }
            if (!snap.hasData) {
              return Center(
                  child: CircularProgressIndicator(color: th.primary));
            }
            final d = snap.data!;
            return Column(
              children: [
                _header(context, d.summary),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    children: [
                      _hero(context, d.summary),
                      const SizedBox(height: 14),
                      if (d.muscles.isNotEmpty) ...[
                        _muscleCard(context, d.muscles),
                        const SizedBox(height: 20),
                      ],
                      _exercisesHeader(context, d),
                      const SizedBox(height: 10),
                      for (final e in d.exercises) ...[
                        _exerciseCard(context, e),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------- header ----------
  Widget _header(BuildContext ctx, _Summary s) {
    final th = FlutterFlowTheme.of(ctx);
    String date = '';
    try {
      date = formatNiceDate(s.createdAt);
    } catch (_) {}
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Row(
        children: [
          _circleBtn(ctx, Icons.chevron_left_rounded, widget.onBack),
          Expanded(
            child: Text(date,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _t(ctx, 16, FontWeight.w500, th.secondaryText)),
          ),
          _circleBtn(ctx, Icons.more_horiz_rounded, widget.onMore),
        ],
      ),
    );
  }

  Widget _circleBtn(BuildContext ctx, IconData icon, Future Function()? cb) {
    final th = FlutterFlowTheme.of(ctx);
    return _Pressable(
      onTap: cb == null ? null : () => cb(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: th.secondaryBackground,
          shape: BoxShape.circle,
          border: Border.all(color: th.alternate.withOpacity(0.6)),
        ),
        child: Icon(icon, size: 24, color: th.primaryText),
      ),
    );
  }

  // ---------- hero ----------
  Widget _hero(BuildContext ctx, _Summary s) {
    String vol;
    try {
      vol = formatCompactNumber(s.volume.toDouble());
    } catch (_) {
      vol = s.volume.toString();
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF14B8A6), Color(0xFF2DD4BF), Color(0xFF5EEAD4)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14B8A6).withOpacity(0.30),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WORKOUT',
                        style: _t(ctx, 12, FontWeight.w700,
                            Colors.white.withOpacity(0.85),
                            ls: 1.5)),
                    const SizedBox(height: 2),
                    Text(s.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _t(ctx, 32, FontWeight.w800, Colors.white,
                            height: 1.1)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _Pressable(
                onTap:
                    widget.onCompare == null ? null : () => widget.onCompare!(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text('Compare',
                      style: _t(
                          ctx, 15, FontWeight.w600, const Color(0xFF0F766E))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _stat(ctx, '${s.totalSets}', 'Sets'),
              const SizedBox(width: 8),
              _stat(ctx, '${s.exerciseCount}', 'Exercises'),
              const SizedBox(width: 8),
              _stat(ctx, _durationLabel(s.durationMs), 'Duration'),
              const SizedBox(width: 8),
              _stat(ctx, vol, 'Volume ${s.unitLabel.toLowerCase()}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext ctx, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: _t(ctx, 22, FontWeight.w800, Colors.white)),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  style: _t(
                      ctx, 11, FontWeight.w600, Colors.white.withOpacity(0.9))),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- muscle distribution ----------
  Widget _muscleCard(BuildContext ctx, List<_Muscle> ms) {
    final th = FlutterFlowTheme.of(ctx);
    final int total = ms.fold(0, (a, m) => a + m.sets);
    final int safeTotal = total == 0 ? 1 : total;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: th.secondaryBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: th.alternate.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Muscle Distribution',
              style: _t(ctx, 18, FontWeight.w700, th.primaryText)),
          const SizedBox(height: 2),
          Text(
              '${ms.length} muscle group${ms.length == 1 ? '' : 's'} · $total sets',
              style: _t(ctx, 13, FontWeight.w500, th.secondaryText)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  for (int i = 0; i < ms.length; i++) ...[
                    Expanded(
                      flex: ms[i].sets <= 0 ? 1 : ms[i].sets,
                      child: Container(
                          color: _muscleColors[i % _muscleColors.length]),
                    ),
                    if (i < ms.length - 1) const SizedBox(width: 3),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (ctx2, c) {
            final double colW = (c.maxWidth - 16) / 2;
            return Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                for (int i = 0; i < ms.length; i++)
                  SizedBox(
                    width: colW,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _muscleColors[i % _muscleColors.length],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(ms[i].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  _t(ctx, 14, FontWeight.w500, th.primaryText)),
                        ),
                        Text('${(ms[i].sets * 100 / safeTotal).round()}%',
                            style:
                                _t(ctx, 14, FontWeight.w700, th.primaryText)),
                      ],
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ---------- exercises ----------
  Widget _exercisesHeader(BuildContext ctx, _PageData d) {
    final th = FlutterFlowTheme.of(ctx);
    final int n = d.exercises.length;
    return Row(
      children: [
        Expanded(
          child: Text('Exercises',
              style: _t(ctx, 20, FontWeight.w700, th.primaryText)),
        ),
        Text('$n exercise${n == 1 ? '' : 's'} · ${d.summary.totalSets} sets',
            style: _t(ctx, 13, FontWeight.w500, th.secondaryText)),
      ],
    );
  }

  Widget _exerciseCard(BuildContext ctx, _Exercise e) {
    final th = FlutterFlowTheme.of(ctx);
    final bool anyAi = e.sets.any((s) => s.analysisRow != null);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: th.secondaryBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: th.alternate.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: th.alternate.withOpacity(0.6)),
                  color: th.primaryBackground,
                ),
                padding: const EdgeInsets.all(2),
                child: ExerciseAssetImage(
                  width: 58,
                  height: 58,
                  exerciseName: exerciseImageName(e.name),
                  borderRadius: 12,
                  illustration: e.illustration,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _t(ctx, 18, FontWeight.w700, th.primaryText,
                            height: 1.15)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: _tags(ctx, e)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _Pressable(
                onTap: widget.onExerciseTap == null
                    ? null
                    : () => widget.onExerciseTap!(e.id, e.isPublic),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: th.primaryBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: th.alternate.withOpacity(0.6)),
                  ),
                  child: Icon(Icons.arrow_outward_rounded,
                      size: 20, color: th.secondaryText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                SizedBox(
                    width: 44,
                    child: Text('SET',
                        style: _t(ctx, 11, FontWeight.w700, th.secondaryText,
                            ls: 1))),
                Expanded(
                  child: Center(
                    child: Text(e.isTimed ? 'TIME' : 'REPS',
                        style: _t(ctx, 11, FontWeight.w700, th.secondaryText,
                            ls: 1)),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(e.isTimed ? '' : 'WEIGHT',
                        style: _t(ctx, 11, FontWeight.w700, th.secondaryText,
                            ls: 1)),
                  ),
                ),
                if (anyAi) const SizedBox(width: 44),
              ],
            ),
          ),
          const SizedBox(height: 6),
          for (final s in e.sets) ...[
            _setRow(ctx, e, s, anyAi),
            const SizedBox(height: 6),
          ],
          if (e.sets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No sets logged',
                  style: _t(ctx, 13, FontWeight.w500, th.secondaryText)),
            ),
        ],
      ),
    );
  }

  List<Widget> _tags(BuildContext ctx, _Exercise e) {
    final th = FlutterFlowTheme.of(ctx);
    final List<Widget> out = [];

    Widget chip(String text, Color bg, Color fg,
        {FontWeight w = FontWeight.w600}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: _t(ctx, 12, w, fg)),
      );
    }

    final Color tealBg = th.primary.withOpacity(0.12), tealFg = th.primary;
    final Color greyBg = th.alternate.withOpacity(0.5),
        greyFg = th.secondaryText;

    if (e.muscleGroup != null) out.add(chip(e.muscleGroup!, tealBg, tealFg));
    if (e.equipment != null) {
      out.add(chip(e.equipment!, greyBg, greyFg));
    } else if (e.isBodyweight) {
      out.add(chip('Bodyweight', greyBg, greyFg));
    }
    if (e.isTimed) out.add(chip('Timed', greyBg, greyFg));
    if (e.muscleGroup == null && e.total.trim().isNotEmpty) {
      out.add(chip(e.total, tealBg, tealFg));
    }
    if (e.pctChange != null && e.pctChange != 0) {
      final bool up = e.pctChange! > 0;
      out.add(chip(
        '${up ? '+' : ''}${e.pctChange}%',
        (up ? const Color(0xFF16A34A) : const Color(0xFFDC2626))
            .withOpacity(0.12),
        up ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
        w: FontWeight.w700,
      ));
    }
    return out;
  }

  Widget _setRow(BuildContext ctx, _Exercise e, _SetRow s, bool reserveAi) {
    final th = FlutterFlowTheme.of(ctx);

    Widget big(String v, String unit) => RichText(
          text: TextSpan(children: [
            TextSpan(
                text: v, style: _t(ctx, 17, FontWeight.w700, th.primaryText)),
            if (unit.isNotEmpty)
              TextSpan(
                  text: ' $unit',
                  style: _t(ctx, 12, FontWeight.w500, th.secondaryText)),
          ]),
        );
    Widget dash() =>
        Text('—', style: _t(ctx, 17, FontWeight.w700, th.secondaryText));

    Widget mid, right;
    final bool hasW = (s.weight ?? 0) > 0;
    if (e.isTimed) {
      mid = s.durationMs == null ? dash() : big(_mmss(s.durationMs!), 'min');
      right = hasW ? big(_weightStr(s.weight!), s.isKg ? 'kg' : 'lbs') : dash();
    } else {
      mid = s.reps == null ? dash() : big('${s.reps}', 'reps');
      if (hasW) {
        right = big(_weightStr(s.weight!), s.isKg ? 'kg' : 'lbs');
      } else if (e.isBodyweight || !e.isWeighted) {
        right = Text('BW', style: _t(ctx, 17, FontWeight.w700, th.primaryText));
      } else {
        right = dash();
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: th.primaryBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: th.secondaryBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: th.alternate.withOpacity(0.6)),
            ),
            alignment: Alignment.center,
            child: Text('${s.setNumber}',
                style: _t(ctx, 15, FontWeight.w700, th.primaryText)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Center(child: mid)),
          Expanded(child: Center(child: right)),
          if (reserveAi)
            SizedBox(
              width: 44,
              child: s.analysisRow == null
                  ? null
                  : Align(
                      alignment: Alignment.centerRight,
                      child: _Pressable(
                        onTap: widget.onAnalysisTap == null
                            ? null
                            : () => widget.onAnalysisTap!(
                                  s.id,
                                  _s(s.analysis?['id']),
                                  s.analysisRow!,
                                ),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: th.primary.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.auto_awesome_rounded,
                              size: 18, color: th.primary),
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Press feedback (fade + shrink)
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
        scale: _down ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: AnimatedOpacity(
          opacity: _down ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: widget.child,
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
