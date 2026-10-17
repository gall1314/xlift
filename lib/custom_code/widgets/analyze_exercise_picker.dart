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

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

/// "Pick an exercise to analyze" — bottom sheet content.
///
/// Layout: search → Recent (exercises this user already analyzed, newest
/// first, with last score) → all AI-analyzable exercises grouped by primary
/// muscle, 3-column grid. Cards show the last score when one exists,
/// otherwise a small AI badge. Everything is loaded from SQLite by the
/// widget itself.
///
/// [onPick](exerciseId, exerciseName) fires on tap; FF dismisses the sheet
/// and continues. [onClose] fires from the X.
///
/// FF: Bottom Sheet, height ~85%, useSafeArea off, Width/Height Infinity.
class AnalyzeExercisePicker extends StatefulWidget {
  const AnalyzeExercisePicker({
    super.key,
    this.width,
    this.height,
    required this.userId,
    this.onPick,
    this.onClose,
  });

  final double? width;
  final double? height;
  final String userId;
  final Future Function(int exerciseId, String exerciseName)? onPick;
  final Future Function()? onClose;

  @override
  State<AnalyzeExercisePicker> createState() => _AnalyzeExercisePickerState();
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

class _Ex {
  final int id;
  final String name;
  final String? illustration;
  final String muscle;
  double? lastScore;
  DateTime? lastAt;
  _Ex(this.id, this.name, this.illustration, this.muscle);
}

const List<String> _kMuscleOrder = [
  'Legs',
  'Back',
  'Chest',
  'Shoulders',
  'Arms',
  'Core',
  'Other',
];

class _AnalyzeExercisePickerState extends State<AnalyzeExercisePicker> {
  List<_Ex> _all = [];
  bool _loading = true;
  String _query = '';
  String? _docsDir;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ---------- parsing helpers ----------
  static int? _i(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim());
  }

  static DateTime? _date(dynamic v) {
    final s = v?.toString().trim() ?? '';
    if (s.isEmpty || s == 'null') return null;
    if (RegExp(r'^\d+$').hasMatch(s)) {
      final n = int.parse(s);
      return DateTime.fromMillisecondsSinceEpoch(
              n < 100000000000 ? n * 1000 : n)
          .toLocal();
    }
    return DateTime.tryParse(s.replaceFirst(' ', 'T'))?.toLocal();
  }

  static String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'just now';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  static String _scoreStr(double s) {
    final q = (s * 2).round() / 2.0;
    return q == q.roundToDouble() ? q.round().toString() : q.toStringAsFixed(1);
  }

  // ---------- SQLite ----------
  /// Exercises with AI analysis + primary muscle. Schema for the muscle
  /// link differs between projects, so try the likely shapes in order.
  Future<List<Map<String, Object?>>> _queryExercises() async {
    final db = SQLiteManager.instance.database;
    const candidates = [
      // 1) join table exercise_muscle_group -> primary_muscle_group
      '''
      SELECT e.id AS id, e.name AS name, e.illustration AS illustration,
        (SELECT pmg.name FROM exercise_muscle_group emg
           JOIN primary_muscle_group pmg ON pmg.id = emg.primary_muscle_group_id
          WHERE emg.exercise_id = e.id LIMIT 1) AS muscle_group
      FROM exercise e
      WHERE CAST(e.ai_form_analysis AS INTEGER) = 1
      ORDER BY e.name COLLATE NOCASE''',
      // 2) direct FK on exercise
      '''
      SELECT e.id AS id, e.name AS name, e.illustration AS illustration,
        pmg.name AS muscle_group
      FROM exercise e
      LEFT JOIN primary_muscle_group pmg ON pmg.id = e.primary_muscle_group_id
      WHERE CAST(e.ai_form_analysis AS INTEGER) = 1
      ORDER BY e.name COLLATE NOCASE''',
      // 3) text column on exercise
      '''
      SELECT id, name, illustration, muscle_group
      FROM exercise
      WHERE CAST(ai_form_analysis AS INTEGER) = 1
      ORDER BY name COLLATE NOCASE''',
      // 4) no grouping
      '''
      SELECT id, name, illustration, NULL AS muscle_group
      FROM exercise
      WHERE CAST(ai_form_analysis AS INTEGER) = 1
      ORDER BY name COLLATE NOCASE''',
    ];
    for (final sql in candidates) {
      try {
        return await db.rawQuery(sql);
      } catch (_) {}
    }
    return const [];
  }

  /// Latest analysis per exercise for this user (score + when).
  Future<List<Map<String, Object?>>> _queryRecent() async {
    try {
      return await SQLiteManager.instance.database.rawQuery('''
        SELECT CAST(sl.exercise_id AS INTEGER) AS exercise_id,
               sa.score AS score, sa.analyzed_at AS analyzed_at
        FROM set_analysis sa
        JOIN set_log sl ON sl.id = sa.set_log_id
        JOIN workout_log wl ON wl.id = sl.workout_log_id
        WHERE wl.user_id = ?
        ORDER BY sa.analyzed_at DESC
        LIMIT 300
      ''', [widget.userId]);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _load() async {
    try {
      _docsDir = (await getApplicationDocumentsDirectory()).path;
    } catch (_) {}

    final rows = await _queryExercises();
    final byId = <int, _Ex>{};
    for (final r in rows) {
      final id = _i(r['id']);
      final name = (r['name'] ?? '').toString().trim();
      if (id == null || name.isEmpty) continue;
      final ill = r['illustration']?.toString().trim();
      final mg = (r['muscle_group'] ?? '').toString().trim();
      byId[id] = _Ex(id, name, (ill == null || ill.isEmpty) ? null : ill,
          mg.isEmpty ? 'Other' : mg);
    }

    // Newest-first, so the first row per exercise is its latest analysis.
    for (final r in await _queryRecent()) {
      final id = _i(r['exercise_id']);
      final ex = id == null ? null : byId[id];
      if (ex == null || ex.lastAt != null) continue;
      ex.lastScore = _d(r['score']);
      ex.lastAt = _date(r['analyzed_at']) ?? DateTime.now();
    }

    if (mounted) {
      setState(() {
        _all = byId.values.toList();
        _loading = false;
      });
    }
  }

  // ---------- derived ----------
  List<_Ex> get _recent {
    final r = _all.where((e) => e.lastAt != null).toList()
      ..sort((a, b) => b.lastAt!.compareTo(a.lastAt!));
    return r.take(6).toList();
  }

  /// Ordered (muscle, exercises) sections.
  List<MapEntry<String, List<_Ex>>> get _sections {
    final map = <String, List<_Ex>>{};
    for (final e in _all) {
      map.putIfAbsent(e.muscle, () => []).add(e);
    }
    final keys = map.keys.toList()
      ..sort((a, b) {
        final ia = _kMuscleOrder.indexOf(a), ib = _kMuscleOrder.indexOf(b);
        if (ia != -1 && ib != -1) return ia.compareTo(ib);
        if (ia != -1) return -1;
        if (ib != -1) return 1;
        return a.compareTo(b);
      });
    return [
      for (final k in keys)
        MapEntry(k, map[k]!..sort((a, b) => a.name.compareTo(b.name)))
    ];
  }

  List<_Ex> get _searchResults {
    final q = _query.trim().toLowerCase();
    return _all.where((e) => e.name.toLowerCase().contains(q)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  ImageProvider _imageFor(_Ex e) {
    final ill = e.illustration;
    if (ill != null && ill.startsWith('assets/')) return AssetImage(ill);
    if (ill != null && _docsDir != null) {
      final f = File(ill.startsWith('/') ? ill : '$_docsDir/$ill');
      if (f.existsSync()) return FileImage(f);
      final f2 = File('$_docsDir/exercise_images/$ill');
      if (f2.existsSync()) return FileImage(f2);
    }
    return AssetImage('assets/images/${e.name.replaceAll(' ', '_')}.jpg');
  }

  TextStyle _ts(double size, FontWeight w, Color c) {
    final th = FlutterFlowTheme.of(context);
    return th.bodyMedium.override(
      fontFamily: th.bodyMediumFamily,
      color: c,
      fontSize: size,
      fontWeight: w,
      useGoogleFonts: GoogleFonts.asMap().containsKey(th.bodyMediumFamily),
    );
  }

  void _pick(_Ex e) {
    HapticFeedback.selectionClick();
    widget.onPick?.call(e.id, e.name);
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bool searching = _query.trim().isNotEmpty;

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: th.primaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: th.alternate,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pick an exercise to analyze',
                          style: _ts(22, FontWeight.w700, th.primaryText)),
                      const SizedBox(height: 2),
                      Text(
                        _loading
                            ? 'Loading…'
                            : '${_all.length} exercises with AI form analysis',
                        style: _ts(13, FontWeight.w500, th.secondaryText),
                      ),
                    ],
                  ),
                ),
                if (widget.onClose != null)
                  GestureDetector(
                    onTap: () => widget.onClose!(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: th.secondaryBackground,
                        shape: BoxShape.circle,
                        border: Border.all(color: th.alternate),
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 20, color: th.primaryText),
                    ),
                  ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: th.secondaryBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: th.alternate),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search_rounded, size: 20, color: th.secondaryText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged: (v) => setState(() => _query = v),
                      style: _ts(15, FontWeight.w500, th.primaryText),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Search exercise',
                        hintStyle: _ts(15, FontWeight.w400, th.secondaryText),
                      ),
                    ),
                  ),
                  if (searching)
                    GestureDetector(
                      onTap: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(Icons.cancel_rounded,
                            size: 18, color: th.secondaryText),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: th.primary))
                : searching
                    ? _searchList(bottomInset)
                    : _browseList(bottomInset),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, [int? count]) {
    final th = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, style: _ts(15, FontWeight.w700, th.primaryText)),
          if (count != null) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text('$count',
                  style: _ts(12, FontWeight.w600, th.secondaryText)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _grid(List<_Ex> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _card(items[i]),
    );
  }

  Widget _browseList(double bottomInset) {
    final recent = _recent;
    final sections = _sections;
    return ListView(
      padding: EdgeInsets.only(bottom: 16 + bottomInset),
      children: [
        if (recent.isNotEmpty) ...[
          _sectionHeader('Recent'),
          SizedBox(
            height: 142,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: recent.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) =>
                  SizedBox(width: 112, child: _card(recent[i], showAgo: true)),
            ),
          ),
        ],
        for (final s in sections) ...[
          _sectionHeader(s.key, s.value.length),
          _grid(s.value),
        ],
        if (sections.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text('No exercises available',
                  style: _ts(15, FontWeight.w500,
                      FlutterFlowTheme.of(context).secondaryText)),
            ),
          ),
      ],
    );
  }

  Widget _searchList(double bottomInset) {
    final th = FlutterFlowTheme.of(context);
    final res = _searchResults;
    if (res.isEmpty) {
      return Center(
        child: Text('No exercises match "${_query.trim()}"',
            style: _ts(15, FontWeight.w500, th.secondaryText)),
      );
    }
    return ListView(
      padding: EdgeInsets.only(bottom: 16 + bottomInset),
      children: [
        _sectionHeader('Results', res.length),
        _grid(res),
      ],
    );
  }

  Widget _card(_Ex e, {bool showAgo = false}) {
    final th = FlutterFlowTheme.of(context);
    final double? score = e.lastScore;
    const Color warn = Color(0xFFF59E0B);

    return _Pressable(
      onTap: () => _pick(e),
      child: Container(
        decoration: BoxDecoration(
          color: th.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: th.alternate),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image(
                        image: _imageFor(e),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.fitness_center_rounded,
                              size: 30, color: th.secondaryText),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: score == null
                        ? Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: th.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.auto_awesome_rounded,
                                size: 12, color: th.primary),
                          )
                        : Container(
                            height: 20,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: score >= 8 ? th.primary : warn,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(_scoreStr(score),
                                style: _ts(11, FontWeight.w800, Colors.white)),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              e.name,
              maxLines: showAgo ? 1 : 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: _ts(12.5, FontWeight.w600, th.primaryText),
            ),
            if (showAgo && e.lastAt != null) ...[
              const SizedBox(height: 2),
              Text(_ago(e.lastAt!),
                  style: _ts(10.5, FontWeight.w500, th.secondaryText)),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Press feedback
// ---------------------------------------------------------------------------

class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) {
        _set(false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: _down ? 0.7 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: widget.child,
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
