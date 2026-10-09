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

/// Full "exercise breakdown" bottom sheet for the Workout Complete screen.
///
/// Self-contained: sheet background + rounded top + grab handle + padding +
/// scrolling, AND the content. Sizes itself to the content up to
/// maxHeightFraction of the screen (default 0.88), then scrolls - whatever
/// height FF hands it (Infinite / 100% / Screen Height all work). The area
/// above the sheet is transparent and closes it on tap.
///
/// Runs the `workoutBreakdownSets` SQLite query itself (one row per set,
/// drops included) and groups by exercise. Each exercise is a collapsible
/// row: thumbnail · name · "MUSCLE · N sets · total" · % change chip · PR
/// chip · avg form score chip · chevron. Expanded: one line per set ("Set 1
/// 10 × 60 kg" / "10 reps · Bodyweight" / "01:30"), drop sets nested, per-set
/// PR mark and form score.
///
/// Open it with a Bottom Sheet action, transparent background, and put ONLY
/// this widget in the component.
///
/// Thumbnails: assets/images/<name with spaces -> '_'>.jpg - same rule as
/// ExerciseAssetImage + exerciseImageName().
class WorkoutBreakdownSheet extends StatefulWidget {
  const WorkoutBreakdownSheet({
    super.key,
    this.width,
    this.height,
    required this.workoutLogId,
    required this.userId,
    this.isDark,
    this.accentColor,
    this.sheetColor,
    this.maxHeightFraction,
    this.initiallyExpanded = false,
  });

  final double? width;
  final double? height; // ignored - sheet sizes itself to content
  final String workoutLogId;
  final String userId;
  final bool? isDark;
  final Color? accentColor;
  final Color? sheetColor; // default: white / dark surface
  final double? maxHeightFraction; // default 0.88 of screen height
  final bool initiallyExpanded;

  @override
  State<WorkoutBreakdownSheet> createState() => _WorkoutBreakdownSheetState();
}

class _SetRow {
  final int setNumber;
  final bool isDrop;
  final int dropNumber;
  final int reps;
  final double weight;
  final int durSec;
  final double? score;
  final bool isPr;
  _SetRow({
    required this.setNumber,
    required this.isDrop,
    required this.dropNumber,
    required this.reps,
    required this.weight,
    required this.durSec,
    required this.score,
    required this.isPr,
  });
}

class _Exercise {
  final int id;
  final String name;
  final String muscle;
  final bool isTimed;
  final bool isBodyweight;
  final bool isAssisted;
  final String unit;
  final int setsCount;
  final String total;
  final int? pctChange;
  final List<_SetRow> sets = [];
  _Exercise({
    required this.id,
    required this.name,
    required this.muscle,
    required this.isTimed,
    required this.isBodyweight,
    required this.isAssisted,
    required this.unit,
    required this.setsCount,
    required this.total,
    required this.pctChange,
  });

  bool get hasPr => sets.any((s) => s.isPr);
  double? get avgScore {
    final scored = sets.where((s) => s.score != null).toList();
    if (scored.isEmpty) return null;
    return scored.map((s) => s.score!).reduce((a, b) => a + b) / scored.length;
  }
}

class _WorkoutBreakdownSheetState extends State<WorkoutBreakdownSheet> {
  final Set<int> _open = {};
  List<_Exercise> _exercises = [];
  bool _loading = true;
  String? _error;

  // ---------- loading ----------

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WorkoutBreakdownSheet old) {
    super.didUpdateWidget(old);
    if (old.workoutLogId != widget.workoutLogId ||
        old.userId != widget.userId) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await SQLiteManager.instance.workoutBreakdownSets(
        workoutLogId: widget.workoutLogId,
        userId: widget.userId,
      );
      if (!mounted) return;
      _parse(rows);
      setState(() => _loading = false);
    } catch (e) {
      print('[breakdown] query failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ---------- parsing ----------

  static dynamic _get(dynamic row, String key) {
    if (row == null) return null;
    if (row is Map) return row[key];
    try {
      return row.data[key];
    } catch (_) {
      return null;
    }
  }

  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static int? _intN(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double _dbl(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static double? _dblN(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static bool _bool(dynamic v) => _int(v) != 0;

  static String _str(dynamic v) => v == null ? '' : v.toString();

  void _parse(List<dynamic> rows) {
    final Map<int, _Exercise> byId = {};
    final List<int> order = [];
    for (final r in rows) {
      final int exId = _int(_get(r, 'exercise_id'));
      if (!byId.containsKey(exId)) {
        byId[exId] = _Exercise(
          id: exId,
          name: _str(_get(r, 'exercise_name')),
          muscle: _str(_get(r, 'muscle')),
          isTimed: _bool(_get(r, 'is_timed')),
          isBodyweight: _bool(_get(r, 'is_bodyweight')),
          isAssisted: _bool(_get(r, 'is_assisted')),
          unit: _str(_get(r, 'unit_label')).isEmpty
              ? 'kg'
              : _str(_get(r, 'unit_label')),
          setsCount: _int(_get(r, 'sets_count')),
          total: _str(_get(r, 'exercise_total')),
          pctChange: _intN(_get(r, 'pct_change')),
        );
        order.add(exId);
      }
      byId[exId]!.sets.add(_SetRow(
            setNumber: _int(_get(r, 'set_number')),
            isDrop: _bool(_get(r, 'is_dropset')),
            dropNumber: _int(_get(r, 'drop_number')),
            reps: _int(_get(r, 'reps')),
            weight: _dbl(_get(r, 'weight')),
            durSec: _int(_get(r, 'dur_sec')),
            score: _dblN(_get(r, 'set_score')),
            isPr: _bool(_get(r, 'is_pr')),
          ));
    }
    _exercises = order.map((id) => byId[id]!).toList();
    _open.clear();
    if (widget.initiallyExpanded) _open.addAll(order);
  }

  // ---------- formatting ----------

  /// Same rule as ExerciseAssetImage + exerciseImageName().
  static String _assetPath(String exerciseName) =>
      'assets/images/${exerciseName.replaceAll(' ', '_')}.jpg';

  static String _num(double v) {
    String s = v.toStringAsFixed(2);
    while (s.endsWith('0')) s = s.substring(0, s.length - 1);
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    final int dot = s.indexOf('.');
    final String intPart = dot < 0 ? s : s.substring(0, dot);
    final String frac = dot < 0 ? '' : s.substring(dot);
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final int fromEnd = intPart.length - i;
      out.write(intPart[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) out.write(',');
    }
    return out.toString() + frac;
  }

  static String _time(int sec) {
    if (sec >= 3600) {
      return '${sec ~/ 3600}:${((sec % 3600) ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}';
    }
    return '${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}';
  }

  /// "10 × 60 kg" | "10 reps · Bodyweight" | "10 reps · −20 kg assist" | "01:30"
  String _setLine(_Exercise ex, _SetRow s) {
    if (ex.isTimed) return _time(s.durSec);
    if (ex.isAssisted) {
      return s.weight > 0
          ? '${s.reps} reps · −${_num(s.weight)} ${ex.unit} assist'
          : '${s.reps} reps';
    }
    if (s.weight <= 0) return '${s.reps} reps · Bodyweight';
    return '${s.reps} × ${_num(s.weight)} ${ex.unit}';
  }

  static String _score(double v) {
    String s = v.toStringAsFixed(1);
    if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
    return s;
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final bool dark =
        widget.isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final Color accent = widget.accentColor ?? const Color(0xFF1AAE9F);
    final Color sheet =
        widget.sheetColor ?? (dark ? const Color(0xFF141A21) : Colors.white);
    final Color text = dark ? Colors.white : const Color(0xFF111827);
    final Color muted = text.withOpacity(0.55);
    final Color line = text.withOpacity(0.08);
    final Color tile = dark ? const Color(0xFF1F2A2A) : const Color(0xFFEEF1F4);
    const Color down = Color(0xFFE5484D);

    final MediaQueryData media = MediaQuery.of(context);
    final double maxH = media.size.height * (widget.maxHeightFraction ?? 0.88);
    final double bottomInset = media.padding.bottom;

    Widget body;
    if (_loading) {
      body = SizedBox(
        height: 120,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: accent),
          ),
        ),
      );
    } else if (_error != null || _exercises.isEmpty) {
      body = SizedBox(
        height: 80,
        child: Center(
          child: Text(
            _error != null ? 'Could not load breakdown' : 'No sets logged',
            style: TextStyle(fontSize: 13, color: muted),
          ),
        ),
      );
    } else {
      final int totalSets = _exercises.fold(0, (n, e) => n + e.setsCount);
      final bool allOpen = _exercises.every((e) => _open.contains(e.id));

      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_exercises.length} EXERCISES · $totalSets SETS',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() {
                    if (allOpen) {
                      _open.clear();
                    } else {
                      _open.addAll(_exercises.map((e) => e.id));
                    }
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      allOpen ? 'Collapse all' : 'Expand all',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (int i = 0; i < _exercises.length; i++) ...[
            _exerciseRow(_exercises[i], accent, text, muted, tile, down),
            if (i < _exercises.length - 1)
              Divider(height: 1, thickness: 1, color: line),
          ],
        ],
      );
    }

    // The sheet itself: content-sized, capped at maxH, scrolls beyond.
    final Widget sheetBox = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Container(
        width: widget.width ?? double.infinity,
        decoration: BoxDecoration(
          color: sheet,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // grab handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 14),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: text.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomInset),
                child: body,
              ),
            ),
          ],
        ),
      ),
    );

    // Whatever height FF forces on us (Infinite / 100% / fixed), Align
    // loosens it so the sheet sizes itself and sits at the bottom. The
    // transparent area above closes the sheet on tap, like a real barrier.
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: const SizedBox.expand(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {}, // swallow taps on the sheet itself
              child: sheetBox,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color fg, Color bg, {double size = 11}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _thumb(_Exercise ex, Color tile, Color muted) {
    final Widget fallback =
        Icon(Icons.fitness_center_rounded, size: 20, color: muted);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        color: tile,
        child: Image.asset(
          _assetPath(ex.name),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      ),
    );
  }

  Widget _exerciseRow(_Exercise ex, Color accent, Color text, Color muted,
      Color tile, Color down) {
    final bool open = _open.contains(ex.id);
    final int? pct = ex.pctChange;
    final double? avg = ex.avgScore;

    final String meta = [
      if (ex.muscle.isNotEmpty) ex.muscle.toUpperCase(),
      '${ex.setsCount} ${ex.setsCount == 1 ? 'set' : 'sets'}',
      if (ex.total.isNotEmpty) ex.total,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            if (open) {
              _open.remove(ex.id);
            } else {
              _open.add(ex.id);
            }
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                _thumb(ex, tile, muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (pct != null) ...[
                  _chip(
                    pct >= 0 ? '▲ $pct%' : '▼ ${-pct}%',
                    pct > 0 ? accent : (pct < 0 ? down : muted),
                    (pct > 0 ? accent : (pct < 0 ? down : muted))
                        .withOpacity(0.12),
                  ),
                  const SizedBox(width: 6),
                ],
                if (ex.hasPr) ...[
                  _chip('PR', Colors.white, accent),
                  const SizedBox(width: 6),
                ],
                if (avg != null) ...[
                  _chip(_score(avg), accent, accent.withOpacity(0.12),
                      size: 12),
                  const SizedBox(width: 6),
                ],
                Container(
                  width: 32,
                  height: 32,
                  decoration:
                      BoxDecoration(color: tile, shape: BoxShape.circle),
                  child: AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20, color: muted),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: open
              ? Padding(
                  padding: const EdgeInsets.only(left: 60, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final s in ex.sets)
                        _setRow(ex, s, accent, text, muted),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _setRow(
      _Exercise ex, _SetRow s, Color accent, Color text, Color muted) {
    final bool drop = s.isDrop;
    return Padding(
      padding: EdgeInsets.only(left: drop ? 16 : 0),
      child: SizedBox(
        height: 34,
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(
                drop ? '↳' : 'Set ${s.setNumber}',
                style: TextStyle(fontSize: 13, color: muted),
              ),
            ),
            Expanded(
              child: Text(
                _setLine(ex, s),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: drop ? FontWeight.w400 : FontWeight.w500,
                  color: drop ? muted : text,
                ),
              ),
            ),
            if (s.isPr)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  'PR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            if (s.score != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child:
                    _chip(_score(s.score!), accent, accent.withOpacity(0.12)),
              ),
          ],
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
