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

/// Self-managed Library screen content (nav bar / FAB live on the page).
///
/// Three tabs: Workouts (user's), Templates (rows in workout_template),
/// Exercises (catalog + custom). Runs its own SQLite, owns its filter state.
///
/// Parameters: userId               - current user id initialTab           -
/// 0 workouts, 1 templates, 2 exercises onStartWorkout       - (workoutId)
/// onEditWorkout        - (workoutId) onDeleteWorkout      - (workoutId) page
/// runs the delete, widget reloads onOpenTemplate       -
/// (GetWorkoutTemplateRow template, String workoutId) navigate to the
/// template page onUseTemplate        - (GetWorkoutTemplateRow template,
/// String workoutId) copy the template into my workouts; widget reloads
/// onOpenExercise       - (int exerciseId, bool isPublic) onCreateWorkout -
/// existing create bottom sheet onGenerateWorkout    - AI generator entry
/// onCreateCustomExercise
class LibraryView extends StatefulWidget {
  const LibraryView({
    super.key,
    this.width,
    this.height,
    required this.userId,
    this.initialTab = 0,
    this.onStartWorkout,
    this.onEditWorkout,
    this.onDeleteWorkout,
    this.onOpenTemplate,
    this.onUseTemplate,
    this.onOpenExercise,
    this.onCreateWorkout,
    this.onGenerateWorkout,
    this.onCreateCustomExercise,
  });

  final double? width;
  final double? height;
  final String userId;
  final int initialTab;
  final Future Function(String workoutId)? onStartWorkout;
  final Future Function(String workoutId)? onEditWorkout;
  final Future Function(String workoutId)? onDeleteWorkout;
  final Future Function(GetWorkoutTemplateRow template, String workoutId)?
      onOpenTemplate;
  final Future Function(GetWorkoutTemplateRow template, String workoutId)?
      onUseTemplate;
  final Future Function(int exerciseId, bool isPublic)? onOpenExercise;
  final Future Function()? onCreateWorkout;
  final Future Function()? onGenerateWorkout;
  final Future Function()? onCreateCustomExercise;

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

// ---------------------------------------------------------------------------
// Design tokens (same as HomeView)
// ---------------------------------------------------------------------------
const _kBg = Color(0xFFF2F4F3);
const _kInk = Color(0xFF0F1D1B);
const _kInkMuted = Color(0xFF5B6966);
const _kInkFaint = Color(0xFF9AAAA6);
const _kCard = Color(0xFFFFFFFF);
const _kCardSub = Color(0xFFEEF1F0);
const _kSeg = Color(0xFFE6EAE8);
const _kAccent = Color(0xFF13B094);
const _kAccentDeep = Color(0xFF0B7D6B);
const _kAccentTint = Color(0xFFE1F4EF);
const _kDanger = Color(0xFFD92D20);

// Space reserved at the bottom for the page's nav bar + FAB overhang.
const double _kBottomInset = 170;

// Minutes per working set, incl. rest and transitions.
const double _kMinPerSet = 3.5;

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------
class _MuscleGroup {
  _MuscleGroup({required this.id, required this.name, required this.subs});
  final int id;
  final String name;
  final List<_SubMuscle> subs;
}

class _SubMuscle {
  _SubMuscle({required this.id, required this.name});
  final int id;
  final String name;
}

class _WorkoutItem {
  _WorkoutItem({
    required this.id,
    required this.name,
    required this.exerciseCount,
    required this.setCount,
    required this.lastDoneAt,
    required this.muscles,
    required this.muscleIds,
    required this.formCheckCount,
    required this.firstExerciseName,
    this.estimatedTime,
    this.level,
  });
  final String id;
  final String name;
  final int exerciseCount;
  final int setCount;
  final DateTime? lastDoneAt;
  final List<String> muscles;
  final Set<int> muscleIds; // primary_muscle_group ids + muscle_group ids
  final int formCheckCount;
  final String firstExerciseName;
  final int? estimatedTime;
  final String? level;

  int get estMinutes {
    if (estimatedTime != null && estimatedTime! > 0) return estimatedTime!;
    final sets = setCount == 0 ? exerciseCount * 3 : setCount;
    return math.max(15, (sets * _kMinPerSet).round());
  }
}

class _ExerciseItem {
  _ExerciseItem({
    required this.id,
    required this.name,
    required this.equipment,
    required this.primaryGroupId,
    required this.primaryGroupName,
    required this.subMuscles,
    required this.subMuscleIds,
    required this.hasFormCheck,
    required this.isCustom,
    required this.isPublic,
    required this.illustration,
  });
  final int id;
  final String name;
  final String equipment;
  final int primaryGroupId;
  final String primaryGroupName;
  final List<String> subMuscles;
  final Set<int> subMuscleIds;
  final bool hasFormCheck;
  final bool isCustom;
  final bool isPublic;
  final String illustration;
}

class _LibData {
  _LibData({
    required this.groups,
    required this.workouts,
    required this.templates,
    required this.exercises,
  });
  final List<_MuscleGroup> groups;
  final List<_WorkoutItem> workouts;
  final List<_WorkoutItem> templates;
  final List<_ExerciseItem> exercises;
}

class _PickItem<T> {
  const _PickItem({required this.value, required this.label});
  final T value;
  final String label;
}

class _PickResult {
  const _PickResult(this.value);
  final Object? value;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class _LibraryViewState extends State<LibraryView> {
  _LibData? _data;
  String? _error;

  late int _tab = widget.initialTab.clamp(0, 2);
  final _searchCtl = TextEditingController();
  String _query = '';

  // Filters (shared across tabs; sub-muscle only meaningful with a group)
  int? _groupId;
  int? _subId;
  bool _formCheckOnly = false;

  static const Object _kPickCancel = Object();

  @override
  void initState() {
    super.initState();
    _searchCtl.addListener(() {
      final q = _searchCtl.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
    _load();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await _fetch();
      if (mounted) setState(() => _data = d);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  /// Loads the template row for this workout and hands it (plus the workout
  /// id) to the given callback. Builds the FlutterFlow row class directly
  /// from SQLite so we don't depend on the generated query's parameter name.
  Future<void> _withTemplate(
    _WorkoutItem t,
    Future Function(GetWorkoutTemplateRow template, String workoutId)? cb, {
    bool reloadAfter = false,
  }) async {
    if (cb == null) return;
    try {
      final rows = await SQLiteManager.instance.database.rawQuery(
        'SELECT * FROM workout_template WHERE workout_id = ? LIMIT 1',
        [t.id],
      );
      if (rows.isEmpty) return;
      final row = GetWorkoutTemplateRow(Map<String, dynamic>.from(rows.first));
      await cb(row, t.id);
      if (reloadAfter && mounted) await _load();
    } catch (_) {}
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

  static String _str(dynamic v) => (v ?? '').toString().trim();

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

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

  static String _templateName(String raw) {
    var s = raw.trim();
    s = s.replaceAll(RegExp(r'[\s\-–]*template\s*$', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'[\s\-–]+$'), '');
    return _cap(s.isEmpty ? raw : s);
  }

  static String _displayName(_WorkoutItem w) {
    if (w.name.isNotEmpty &&
        !w.name.toLowerCase().startsWith('unnamed workout')) {
      return _cap(w.name);
    }
    if (w.muscles.isNotEmpty) return w.muscles.take(2).join(' & ');
    return 'Workout';
  }

  // ------------------------------- fetch ------------------------------------

  Future<_LibData> _fetch() async {
    final db = SQLiteManager.instance.database;
    final uid = widget.userId;

    // --- muscle taxonomy ---
    final gRows = await db
        .rawQuery('SELECT id, name FROM primary_muscle_group ORDER BY name');
    final sRows = await db.rawQuery(
        'SELECT id, name, primary_muscle_group_id FROM muscle_group ORDER BY name');
    final groups = <_MuscleGroup>[];
    for (final g in gRows) {
      final gid = _int(g['id']);
      groups.add(_MuscleGroup(
        id: gid,
        name: _str(g['name']),
        subs: [
          for (final s in sRows)
            if (_int(s['primary_muscle_group_id']) == gid)
              _SubMuscle(id: _int(s['id']), name: _str(s['name'])),
        ],
      ));
    }

    // --- workouts + templates (one pass) ---
    // A workout is a template iff it has a row in workout_template.
    final wRows = await db.rawQuery('''
      SELECT
        w.id, w.name, w.user_id,
        CASE WHEN wt.workout_id IS NOT NULL THEN 1 ELSE 0 END AS is_public,
        COUNT(DISTINCT we.id) AS exercise_count,
        MAX(wl.created_at)    AS last_done_at,
        SUM(CASE WHEN e.ai_form_analysis = 1 THEN 1 ELSE 0 END) AS fc_count,
        (SELECT COUNT(*) FROM exercise_sets es WHERE es.workout_id = w.id) AS set_count,
        (SELECT we2.exercise_name FROM workout_exercise we2
           WHERE we2.workout_id = w.id ORDER BY we2."order" ASC LIMIT 1) AS first_ex,
        wt.estimated_time, wt.level
      FROM workout w
      LEFT JOIN workout_exercise we ON we.workout_id = w.id
      LEFT JOIN exercise e          ON e.id = we.exercise_id
      LEFT JOIN workout_log wl      ON wl.workout_id = w.id AND wl.user_id = ?
      LEFT JOIN workout_template wt ON wt.workout_id = w.id
      WHERE COALESCE(w.is_deleted, 0) = 0
        AND (w.user_id = ? OR wt.workout_id IS NOT NULL)
      GROUP BY w.id
    ''', [uid, uid]);

    final workouts = <_WorkoutItem>[];
    final templates = <_WorkoutItem>[];
    for (final r in wRows) {
      final id = _str(r['id']);
      final mRows = await db.rawQuery('''
        SELECT pmg.id AS gid, pmg.name AS gname, mg.id AS sid
        FROM workout_exercise we
        JOIN exercise_muscle_group emg
          ON emg.exercise_id = we.exercise_id AND emg.is_primary = 1
        JOIN muscle_group mg          ON mg.id = emg.muscle_group_id
        JOIN primary_muscle_group pmg ON pmg.id = mg.primary_muscle_group_id
        WHERE we.workout_id = ?
      ''', [id]);
      final counts = <String, int>{};
      final ids = <int>{};
      for (final m in mRows) {
        final gn = _str(m['gname']);
        counts[gn] = (counts[gn] ?? 0) + 1;
        ids.add(_int(m['gid']));
        ids.add(_int(m['sid']));
      }
      final muscles = counts.keys.toList()
        ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

      final isTemplate = _int(r['is_public']) == 1;
      final item = _WorkoutItem(
        id: id,
        name: isTemplate ? _templateName(_str(r['name'])) : _str(r['name']),
        exerciseCount: _int(r['exercise_count']),
        setCount: _int(r['set_count']),
        lastDoneAt: _parse(r['last_done_at']),
        muscles: muscles.take(3).toList(),
        muscleIds: ids,
        formCheckCount: _int(r['fc_count']),
        firstExerciseName: _str(r['first_ex']),
        estimatedTime:
            r['estimated_time'] == null ? null : _int(r['estimated_time']),
        level: r['level'] == null ? null : _str(r['level']),
      );
      if (isTemplate) {
        templates.add(item);
      } else {
        workouts.add(item);
      }
    }
    // Workouts: most recently done first, never-done last.
    workouts.sort((a, b) {
      final al = a.lastDoneAt, bl = b.lastDoneAt;
      if (al == null && bl == null) return 0;
      if (al == null) return 1;
      if (bl == null) return -1;
      return bl.compareTo(al);
    });
    templates.sort((a, b) => a.name.compareTo(b.name));

    // --- exercises ---
    final eRows = await db.rawQuery('''
      SELECT e.id, e.name, e.equipment, e.ai_form_analysis, e.illustration,
             e.created_by_user_id, COALESCE(e.is_public, 1) AS is_public
      FROM exercise e
      WHERE COALESCE(e.is_deleted, 0) = 0
        AND (COALESCE(e.is_public, 1) = 1 OR e.created_by_user_id = ?)
      ORDER BY e.name
    ''', [uid]);
    final emRows = await db.rawQuery('''
      SELECT emg.exercise_id, emg.is_primary, mg.id AS sid, mg.name AS sname,
             pmg.id AS gid, pmg.name AS gname
      FROM exercise_muscle_group emg
      JOIN muscle_group mg          ON mg.id = emg.muscle_group_id
      JOIN primary_muscle_group pmg ON pmg.id = mg.primary_muscle_group_id
    ''');
    final byEx = <int, List<Map<String, Object?>>>{};
    for (final m in emRows) {
      byEx.putIfAbsent(_int(m['exercise_id']), () => []).add(m);
    }
    final exercises = <_ExerciseItem>[];
    for (final r in eRows) {
      final eid = _int(r['id']);
      final ms = byEx[eid] ?? const [];
      final prim = ms.where((m) => _int(m['is_primary']) == 1).toList();
      final head =
          prim.isNotEmpty ? prim.first : (ms.isNotEmpty ? ms.first : null);
      final subNames = <String>[];
      final subIds = <int>{};
      for (final m in [
        ...prim,
        ...ms.where((m) => _int(m['is_primary']) != 1)
      ]) {
        final n = _str(m['sname']);
        if (n.isNotEmpty && !subNames.contains(n)) subNames.add(n);
        subIds.add(_int(m['sid']));
        subIds.add(_int(m['gid']));
      }
      final createdBy = _str(r['created_by_user_id']);
      exercises.add(_ExerciseItem(
        id: eid,
        name: _str(r['name']),
        equipment: _str(r['equipment']),
        primaryGroupId: head == null ? -1 : _int(head['gid']),
        primaryGroupName: head == null ? 'Other' : _str(head['gname']),
        subMuscles: subNames.take(2).toList(),
        subMuscleIds: subIds,
        hasFormCheck: _int(r['ai_form_analysis']) == 1,
        isCustom: createdBy.isNotEmpty && createdBy == uid,
        isPublic: _int(r['is_public']) == 1,
        illustration: _str(r['illustration']),
      ));
    }

    return _LibData(
      groups: groups,
      workouts: workouts,
      templates: templates,
      exercises: exercises,
    );
  }

  // ------------------------------ filtering ---------------------------------

  bool _matchMuscle(Set<int> ids) {
    if (_subId != null) return ids.contains(_subId);
    if (_groupId != null) return ids.contains(_groupId);
    return true;
  }

  List<_WorkoutItem> _filterWorkouts(List<_WorkoutItem> src) => src.where((w) {
        if (_query.isNotEmpty &&
            !_displayName(w).toLowerCase().contains(_query) &&
            !w.muscles.any((m) => m.toLowerCase().contains(_query))) {
          return false;
        }
        if (_formCheckOnly && w.formCheckCount == 0) return false;
        return _matchMuscle(w.muscleIds);
      }).toList();

  List<_ExerciseItem> _filterExercises(List<_ExerciseItem> src) =>
      src.where((e) {
        if (_query.isNotEmpty &&
            !e.name.toLowerCase().contains(_query) &&
            !e.equipment.toLowerCase().contains(_query)) {
          return false;
        }
        if (_formCheckOnly && !e.hasFormCheck) return false;
        return _matchMuscle({...e.subMuscleIds, e.primaryGroupId});
      }).toList();

  String get _groupLabel {
    final d = _data;
    if (d == null || _groupId == null) return 'All muscles';
    final g = d.groups.where((g) => g.id == _groupId);
    return g.isEmpty ? 'All muscles' : g.first.name;
  }

  String get _subLabel {
    final d = _data;
    if (d == null || _groupId == null) return '';
    if (_subId == null) return 'All';
    for (final g in d.groups) {
      for (final s in g.subs) {
        if (s.id == _subId) return s.name;
      }
    }
    return 'All';
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
                      child: Text('Library failed to load\n$_error',
                          textAlign: TextAlign.center,
                          style: _body(13, color: _kInkMuted)),
                    ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(),
                      const SizedBox(height: 18),
                      _tabs(),
                      const SizedBox(height: 14),
                      _searchRow(d),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: _kAccent,
                    onRefresh: _load,
                    child: _tab == 0
                        ? _workoutsList(d)
                        : _tab == 1
                            ? _templatesList(d)
                            : _exercisesList(d),
                  ),
                ),
              ],
            ),
    );
  }

  // --- header ---
  Widget _header() {
    final Widget action = _tab == 2
        ? _smallButton(
            icon: Icons.add_rounded,
            label: 'Custom',
            onTap: () => widget.onCreateCustomExercise?.call(),
          )
        : _smallButton(
            icon: Icons.auto_awesome_rounded,
            label: 'Generate',
            tinted: true,
            onTap: () => widget.onGenerateWorkout?.call(),
          );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text('Library', style: _display(32))),
        action,
      ],
    );
  }

  Widget _smallButton({
    required IconData icon,
    required String label,
    bool tinted = false,
    VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: tinted ? _kAccentTint : _kCard,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: tinted ? _kAccentDeep : _kInk),
              const SizedBox(width: 6),
              Text(label,
                  style: _body(13,
                      color: tinted ? _kAccentDeep : _kInk,
                      w: FontWeight.w600)),
            ],
          ),
        ),
      );

  // --- segmented tabs ---
  Widget _tabs() {
    const labels = ['Workouts', 'Templates', 'Exercises'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kSeg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _tab = i),
                child: Container(
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _tab == i ? _kCard : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    labels[i],
                    style: _body(13,
                        color: _tab == i ? _kInk : _kInkMuted,
                        w: _tab == i ? FontWeight.w600 : FontWeight.w500),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- search + filters ---
  Widget _searchRow(_LibData d) {
    final hint = _tab == 0
        ? 'Search workouts'
        : _tab == 1
            ? 'Search templates'
            : 'Search ${d.exercises.length} exercises';
    final fcCount = _tab == 2
        ? d.exercises.where((e) => e.hasFormCheck).length
        : (_tab == 0 ? d.workouts : d.templates)
            .where((w) => w.formCheckCount > 0)
            .length;

    return Column(
      children: [
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 18, color: _kInkMuted),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchCtl,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: _body(14, color: _kInkMuted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: _body(14),
                ),
              ),
              if (_query.isNotEmpty)
                GestureDetector(
                  onTap: () => _searchCtl.clear(),
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: _kInkMuted),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _chip(
              label: _groupLabel,
              selected: _groupId != null,
              trailing: Icons.keyboard_arrow_down_rounded,
              onTap: () => _pickGroup(d),
            ),
            if (_groupId != null) ...[
              const SizedBox(width: 8),
              _chip(
                label: _subLabel,
                selected: _subId != null,
                trailing: Icons.keyboard_arrow_down_rounded,
                onTap: () => _pickSub(d),
              ),
            ],
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _formCheckOnly = !_formCheckOnly),
              child: Container(
                height: 36,
                padding: const EdgeInsets.fromLTRB(8, 0, 10, 0),
                decoration: BoxDecoration(
                  color: _formCheckOnly ? _kAccentTint : _kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: _formCheckOnly
                      ? Border.all(color: _kAccent, width: 1.5)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AiFormBadge(iconSize: 16, showLabel: false),
                    const SizedBox(width: 5),
                    Text('$fcCount',
                        style: _body(13,
                            color: _formCheckOnly ? _kAccentDeep : _kInk,
                            w: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    IconData? trailing,
    VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? _kInk : _kCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: _body(13,
                      color: selected ? _kBg : _kInk,
                      w: selected ? FontWeight.w600 : FontWeight.w500)),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                Icon(trailing, size: 16, color: selected ? _kBg : _kInkFaint),
              ],
            ],
          ),
        ),
      );

  // --- muscle pickers (bottom sheets) ---
  Future<void> _pickGroup(_LibData d) async {
    final picked = await _showPicker<int?>(
      title: 'Muscle group',
      items: [
        const _PickItem(value: null, label: 'All muscles'),
        for (final g in d.groups) _PickItem(value: g.id, label: g.name),
      ],
      current: _groupId,
    );
    if (identical(picked, _kPickCancel)) return;
    setState(() {
      _groupId = picked as int?;
      _subId = null;
    });
  }

  Future<void> _pickSub(_LibData d) async {
    final g = d.groups.where((g) => g.id == _groupId);
    if (g.isEmpty) return;
    final picked = await _showPicker<int?>(
      title: g.first.name,
      items: [
        const _PickItem(value: null, label: 'All'),
        for (final s in g.first.subs) _PickItem(value: s.id, label: s.name),
      ],
      current: _subId,
    );
    if (identical(picked, _kPickCancel)) return;
    setState(() => _subId = picked as int?);
  }

  Future<Object?> _showPicker<T>({
    required String title,
    required List<_PickItem<T>> items,
    required T current,
  }) async {
    final res = await showModalBottomSheet<Object?>(
      context: context,
      backgroundColor: _kBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        final maxH = MediaQuery.of(ctx).size.height * 0.7;
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _kInkFaint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(title, style: _display(20, w: FontWeight.w700)),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final it = items[i];
                      final sel = it.value == current;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            Navigator.of(ctx).pop(_PickResult(it.value)),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: sel ? _kAccentTint : _kCard,
                            borderRadius: BorderRadius.circular(14),
                            border: sel
                                ? Border.all(color: _kAccent, width: 1.5)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(it.label,
                                    style: _body(15,
                                        w: sel
                                            ? FontWeight.w600
                                            : FontWeight.w500)),
                              ),
                              if (sel)
                                const Icon(Icons.check_rounded,
                                    size: 20, color: _kAccentDeep),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (res is _PickResult) return res.value;
    return _kPickCancel;
  }

  // --- lists ---
  Widget _workoutsList(_LibData d) {
    final list = _filterWorkouts(d.workouts);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, _kBottomInset),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (d.workouts.isEmpty)
          _empty(
            'No workouts yet',
            'Build one yourself, use a template, or let the AI generate one.',
          )
        else if (list.isEmpty)
          _empty('Nothing matches', 'Try another muscle or clear the search.')
        else
          for (final w in list) ...[
            _workoutRow(w),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 4),
        _dashedButton(
          icon: Icons.add_rounded,
          label: 'New workout',
          onTap: () => widget.onCreateWorkout?.call(),
        ),
      ],
    );
  }

  Widget _templatesList(_LibData d) {
    final list = _filterWorkouts(d.templates);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, _kBottomInset),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (list.isEmpty)
          _empty(
              'No templates match', 'Try another muscle or clear the search.')
        else
          for (final t in list) ...[
            _templateRow(t),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _exercisesList(_LibData d) {
    final list = _filterExercises(d.exercises);
    final custom = list.where((e) => e.isCustom).toList();
    final byGroup = <String, List<_ExerciseItem>>{};
    for (final e in list.where((e) => !e.isCustom)) {
      byGroup.putIfAbsent(e.primaryGroupName, () => []).add(e);
    }
    final groupNames = byGroup.keys.toList()..sort();
    final fc = list.where((e) => e.hasFormCheck).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, _kBottomInset),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Row(
          children: [
            Text(
              (_groupId == null ? 'All exercises' : _groupLabel).toUpperCase(),
              style: _eyebrow(),
            ),
            const Spacer(),
            Text('${list.length} exercises · $fc with form check',
                style: _body(12, color: _kInkMuted)),
          ],
        ),
        const SizedBox(height: 10),
        if (list.isEmpty)
          _empty(
              'No exercises match', 'Try another muscle or clear the search.'),
        if (custom.isNotEmpty) ...[
          Text('CUSTOM', style: _eyebrow()),
          const SizedBox(height: 8),
          _exerciseGroupCard(custom),
          const SizedBox(height: 16),
        ],
        for (final g in groupNames) ...[
          Text(g.toUpperCase(), style: _eyebrow()),
          const SizedBox(height: 8),
          _exerciseGroupCard(byGroup[g]!),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // --- workout row + anchored menu ---
  Widget _workoutRow(_WorkoutItem w) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onEditWorkout?.call(w.id),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_displayName(w),
                      style: _body(16, w: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    '${w.exerciseCount} exercises · ~${w.estMinutes} min · ${_ago(w.lastDoneAt)}',
                    style: _body(12, color: _kInkMuted),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          w.muscles.isEmpty ? '—' : w.muscles.join(' · '),
                          style: _body(12, color: _kInkMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (w.formCheckCount > 0) ...[
                        const SizedBox(width: 8),
                        const AiFormBadge(iconSize: 13, showLabel: false),
                        const SizedBox(width: 3),
                        Text('${w.formCheckCount}',
                            style: _body(12,
                                color: _kAccentDeep, w: FontWeight.w600)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => widget.onStartWorkout?.call(w.id),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _kInk,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text('Start',
                    style: _body(13, color: _kBg, w: FontWeight.w600)),
              ),
            ),
            _MoreButton(onTap: (anchor) => _workoutMenu(w, anchor)),
          ],
        ),
      ),
    );
  }

  /// Small popup anchored to the three-dot button (Edit / Delete).
  Future<void> _workoutMenu(_WorkoutItem w, RenderBox anchor) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final topLeft = anchor.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight = anchor
        .localToGlobal(anchor.size.bottomRight(Offset.zero), ancestor: overlay);
    final position = RelativeRect.fromRect(
      Rect.fromPoints(topLeft, bottomRight),
      Offset.zero & overlay.size,
    );

    final action = await showMenu<String>(
      context: context,
      position: position,
      color: _kCard,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 170),
      items: [
        PopupMenuItem<String>(
          value: 'edit',
          height: 46,
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18, color: _kInk),
              const SizedBox(width: 12),
              Text('Edit', style: _body(15, w: FontWeight.w500)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'delete',
          height: 46,
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded,
                  size: 18, color: _kDanger),
              const SizedBox(width: 12),
              Text('Delete',
                  style: _body(15, color: _kDanger, w: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
    if (!mounted || action == null) return;
    if (action == 'edit') {
      await widget.onEditWorkout?.call(w.id);
    } else if (action == 'delete') {
      await widget.onDeleteWorkout?.call(w.id);
      if (mounted) await _load();
    }
  }

  // --- template row: tap = open template page, Use = copy to my workouts ---
  Widget _templateRow(_WorkoutItem t) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _withTemplate(t, widget.onOpenTemplate),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            ExerciseAssetImage(
              width: 56,
              height: 56,
              exerciseName: exerciseImageName(t.firstExerciseName),
              borderRadius: 12,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name,
                      style: _body(16, w: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    '${t.exerciseCount} exercises · ~${t.estMinutes} min'
                    '${t.level == null || t.level!.isEmpty ? '' : ' · ${t.level}'}',
                    style: _body(12, color: _kInkMuted),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          t.muscles.isEmpty ? '—' : t.muscles.join(' · '),
                          style: _body(12, color: _kInkMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (t.formCheckCount > 0) ...[
                        const SizedBox(width: 8),
                        const AiFormBadge(iconSize: 13, showLabel: false),
                        const SizedBox(width: 3),
                        Text('${t.formCheckCount}',
                            style: _body(12,
                                color: _kAccentDeep, w: FontWeight.w600)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () =>
                  _withTemplate(t, widget.onUseTemplate, reloadAfter: true),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _kInk,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text('Use',
                    style: _body(13, color: _kBg, w: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- exercises ---
  Widget _exerciseGroupCard(List<_ExerciseItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _exerciseRow(items[i]),
            if (i < items.length - 1)
              const Divider(
                  height: 1, color: _kCardSub, indent: 12, endIndent: 12),
          ],
        ],
      ),
    );
  }

  Widget _exerciseRow(_ExerciseItem e) {
    final sub = [
      if (e.equipment.isNotEmpty) e.equipment,
      if (e.subMuscles.isNotEmpty) e.subMuscles.join(', '),
    ].join(' · ');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onOpenExercise?.call(e.id, e.isPublic),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            if (e.isCustom && e.illustration.isEmpty)
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _kInk,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  e.name.isEmpty ? '?' : e.name[0].toUpperCase(),
                  style: _display(18, color: _kBg),
                ),
              )
            else
              ExerciseAssetImage(
                width: 52,
                height: 52,
                exerciseName: exerciseImageName(e.name),
                illustration: e.isCustom ? e.illustration : null,
                borderRadius: 12,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.name,
                      style: _body(15, w: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(sub.isEmpty ? (e.isCustom ? 'Custom' : '—') : sub,
                      style: _body(12, color: _kInkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (e.hasFormCheck) ...[
              const SizedBox(width: 8),
              const AiFormBadge(showLabel: true, iconSize: 14),
            ],
          ],
        ),
      ),
    );
  }

  // --- misc ---
  Widget _empty(String title, String body) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(title, style: _body(16, w: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(body,
                textAlign: TextAlign.center,
                style: _body(13, color: _kInkMuted)),
          ],
        ),
      );

  Widget _dashedButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kInkFaint, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: _kInk),
              const SizedBox(width: 8),
              Text(label, style: _body(14, w: FontWeight.w600)),
            ],
          ),
        ),
      );
}

/// Three-dot button that hands its own RenderBox to the tap handler so the
/// menu can be anchored right under it.
class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.onTap});
  final void Function(RenderBox anchor) onTap;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final box = ctx.findRenderObject() as RenderBox?;
          if (box != null) onTap(box);
        },
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.more_vert_rounded, size: 18, color: _kInkMuted),
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
