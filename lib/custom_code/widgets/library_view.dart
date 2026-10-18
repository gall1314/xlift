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
import 'package:google_fonts/google_fonts.dart';

/// Self-managed Library screen content (nav bar / FAB live on the page).
///
/// Three tabs: Workouts (the user's), Templates (catalכog, driven by the
/// workout_template table), Exercises (catalog + the user's custom ones).
/// Runs its own SQLite queries, exposes navigation as callbacks. Fonts and
/// colors come from FlutterFlowTheme so it mכatches the rest of the app.
///
/// Parameters: userId                  - current user id (auth) initialTab -
/// 0 Workouts, 1 Templates, 2 Exercises canGenerate             - false =
/// Generate is shown locked and taps call onOpenPremium instead (null = true)
/// onStartWorkout          - (workoutId) onEditWorkout           -
/// (workoutId) onDeleteWorkout         - (workoutId)  widget reloads
/// afterwards onOpenTemplate          - (GetWorkoutTemplateRow, workoutId)
/// onUseTemplate           - (GetWorkoutTemplateRow, workoutId) widget
/// reloads afterwards onOpenExercise          - (exerciseId, isPublic)
/// onCreateWorkout         - the existing create bottom sheet
/// onGenerateWorkout       - AI generator onCreateCustomExercise  - custom
/// exercise flow onOpenPremium           - paywall bottom sheet
class LibraryView extends StatefulWidget {
  const LibraryView({
    super.key,
    this.width,
    this.height,
    required this.userId,
    this.initialTab,
    this.canGenerate,
    this.onStartWorkout,
    this.onEditWorkout,
    this.onDeleteWorkout,
    this.onOpenTemplate,
    this.onUseTemplate,
    this.onOpenExercise,
    this.onCreateWorkout,
    this.onGenerateWorkout,
    this.onCreateCustomExercise,
    this.onOpenPremium,
  });

  final double? width;
  final double? height;
  final String userId;
  final int? initialTab;
  final bool? canGenerate;
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
  final Future Function()? onOpenPremium;

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

// Space reserved at the bottom for the page's nav bar + FAB overhang.
const double _kBottomInset = 220;

// Horizontal page gutter.
const double _kGutter = 20;

// Minutes per working set, incl. rest and transitions.
const double _kMinPerSet = 3.5;

// App-wide container radius.
const double _kRadius = 16;
const double _kRadiusInner = 12;

// The one intentional dark surface (Start buttons), fixed in both themes.
const _kDark = Color(0xFF0F1D1B);
const _kOnDark = Color(0xFFF2F4F3);

const _kTabular = [FontFeature.tabularFigures()];

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------
class _Group {
  const _Group(this.id, this.name);
  final int id;
  final String name;
}

class _MuscleRef {
  const _MuscleRef({
    required this.mgId,
    required this.mgName,
    required this.pmgId,
    required this.pmgName,
    required this.isPrimary,
  });
  final int mgId;
  final String mgName;
  final int pmgId;
  final String pmgName;
  final bool isPrimary;
}

class _ExerciseItem {
  _ExerciseItem({
    required this.id,
    required this.name,
    required this.equipment,
    required this.hasFormCheck,
    required this.isPublic,
    required this.isCustom,
    required this.illustration,
    required this.muscles,
  });
  final int id;
  final String name;
  final String equipment;
  final bool hasFormCheck;
  final bool isPublic;
  final bool isCustom;
  final String? illustration;
  final List<_MuscleRef> muscles; // primary first

  Iterable<_MuscleRef> get primary => muscles.where((m) => m.isPrimary);
}

class _WorkoutItem {
  _WorkoutItem({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.lastDoneAt,
    required this.exerciseCount,
    required this.setCount,
    required this.fcCount,
    required this.estMinutes,
    required this.muscles,
    required this.refs,
  });
  final String id;
  final String name;
  final DateTime? createdAt;
  final DateTime? lastDoneAt;
  final int exerciseCount;
  final int setCount;
  final int fcCount;
  final int estMinutes;
  final List<String> muscles;
  final List<_MuscleRef> refs; // primary refs of all exercises
}

class _TemplateItem {
  _TemplateItem({
    required this.key,
    required this.workoutId,
    required this.name,
    required this.level,
    required this.exerciseCount,
    required this.setCount,
    required this.fcCount,
    required this.estMinutes,
    required this.muscles,
    required this.refs,
    required this.raw,
  });
  final String key;
  final String workoutId;
  final String name;
  final String level;
  final int exerciseCount;
  final int setCount;
  final int fcCount;
  final int estMinutes;
  final List<String> muscles;
  final List<_MuscleRef> refs;
  final Map<String, dynamic> raw; // the workout_template row as stored
}

class _LibraryData {
  _LibraryData({
    required this.workouts,
    required this.templates,
    required this.templatesTotal,
    required this.exercises,
    required this.primaryGroups,
    required this.subGroups,
  });
  final List<_WorkoutItem> workouts;
  final List<_TemplateItem> templates;
  final int templatesTotal;
  final List<_ExerciseItem> exercises;
  final List<_Group> primaryGroups;
  final Map<int, List<_Group>> subGroups;
}

class _PickItem {
  const _PickItem(this.id, this.label, this.count);
  final int? id;
  final String label;
  final int count;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class _LibraryViewState extends State<LibraryView> {
  int _tab = 0;
  final TextEditingController _search = TextEditingController();
  String _query = '';
  int? _pmgId;
  int? _mgId;
  bool _fcOnly = false;
  String? _busyTemplate;

  _LibraryData? _data;
  String? _error;

  // Palette, resolved from FlutterFlowTheme in didChangeDependencies.
  Color _bg = const Color(0xFFF2F4F3);
  Color _card = const Color(0xFFFFFFFF);
  Color _cardSub = const Color(0xFFEEF1F0);
  Color _line = const Color(0xFFE2E7E5);
  Color _ink = const Color(0xFF0F1D1B);
  Color _inkMuted = const Color(0xFF5B6966);
  Color _inkFaint = const Color(0xFF9AAAA6);
  Color _accent = const Color(0xFF13B094);
  Color _accentDeep = const Color(0xFF0B7D6B);
  Color _accentTint = const Color(0xFFE1F4EF);

  @override
  void initState() {
    super.initState();
    _tab = (widget.initialTab ?? 0).clamp(0, 2);
    _load();
  }

  @override
  void didUpdateWidget(covariant LibraryView old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId) _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final th = FlutterFlowTheme.of(context);
    _bg = th.primaryBackground;
    _card = th.secondaryBackground;
    _ink = th.primaryText;
    _inkMuted = th.secondaryText;
    _line = th.alternate;
    _cardSub = Color.alphaBlend(_ink.withOpacity(0.05), _card);
    _inkFaint = Color.alphaBlend(_inkMuted.withOpacity(0.55), _card);

    final p = th.primary;
    final h = HSLColor.fromColor(p);
    _accent = p;
    _accentDeep =
        h.withLightness((h.lightness * 0.72).clamp(0.0, 1.0)).toColor();
    _accentTint = Color.alphaBlend(p.withOpacity(0.13), _card);
  }

  Future<void> _load() async {
    try {
      final d = await _fetch();
      if (!mounted) return;
      setState(() {
        _data = d;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  // ------------------------------ helpers -----------------------------------

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString().trim() ?? '') ?? 0;
  }

  static String _str(dynamic v) => (v ?? '').toString().trim();

  static DateTime? _parse(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final dt = DateTime.tryParse(s);
    if (dt == null) return null;
    return dt.isUtc ? dt.toLocal() : dt;
  }

  static int _estimate(int exerciseCount, int setCount) {
    final sets = setCount == 0 ? exerciseCount * 3 : setCount;
    return math.max(15, (sets * _kMinPerSet).round());
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String _ago(DateTime? dt) {
    if (dt == null) return 'never done';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'done just now';
    if (diff.inHours < 24) return 'done ${diff.inHours}h ago';
    if (diff.inDays == 1) return 'done yesterday';
    if (diff.inDays < 7) return 'done ${diff.inDays}d ago';
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    if (diff.inDays < 14) return 'done last ${days[dt.weekday % 7]}';
    return 'done ${(diff.inDays / 7).floor()}w ago';
  }

  /// Top primary muscle groups by how many exercises hit them.
  static List<String> _topGroups(Iterable<_MuscleRef> refs, {int max = 3}) {
    final counts = <String, int>{};
    final order = <String>[];
    for (final r in refs) {
      if (r.pmgName.isEmpty) continue;
      if (!counts.containsKey(r.pmgName)) order.add(r.pmgName);
      counts[r.pmgName] = (counts[r.pmgName] ?? 0) + 1;
    }
    order.sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return order.take(max).toList();
  }

  // ------------------------------- fetch ------------------------------------

  Future<_LibraryData> _fetch() async {
    final db = SQLiteManager.instance.database;
    final uid = widget.userId;

    // --- muscle taxonomy ---
    final pmgRows = await db
        .rawQuery('SELECT id, name FROM primary_muscle_group ORDER BY id');
    final mgRows = await db
        .rawQuery('SELECT id, name, primary_muscle_group_id FROM muscle_group '
            'ORDER BY name COLLATE NOCASE');
    final emgRows = await db.rawQuery('''
      SELECT emg.exercise_id, emg.muscle_group_id, emg.is_primary,
             mg.name AS mg_name, mg.primary_muscle_group_id AS pmg_id,
             pmg.name AS pmg_name
      FROM exercise_muscle_group emg
      JOIN muscle_group mg            ON mg.id = emg.muscle_group_id
      LEFT JOIN primary_muscle_group pmg ON pmg.id = mg.primary_muscle_group_id
      ORDER BY emg.exercise_id, emg.is_primary DESC, emg.id
    ''');

    final primaryGroups = <_Group>[
      for (final r in pmgRows) _Group(_int(r['id']), _str(r['name'])),
    ];
    final subGroups = <int, List<_Group>>{};
    for (final r in mgRows) {
      subGroups
          .putIfAbsent(_int(r['primary_muscle_group_id']), () => [])
          .add(_Group(_int(r['id']), _str(r['name'])));
    }
    final exMuscles = <int, List<_MuscleRef>>{};
    for (final r in emgRows) {
      exMuscles.putIfAbsent(_int(r['exercise_id']), () => []).add(_MuscleRef(
            mgId: _int(r['muscle_group_id']),
            mgName: _str(r['mg_name']),
            pmgId: _int(r['pmg_id']),
            pmgName: _str(r['pmg_name']),
            isPrimary: _int(r['is_primary']) == 1,
          ));
    }

    // --- exercises: catalog + the user's custom ones ---
    final exRows = await db.rawQuery('''
      SELECT id, name, equipment, ai_form_analysis, is_public,
             created_by_user_id, illustration
      FROM exercise
      WHERE COALESCE(is_deleted, 0) = 0
        AND (COALESCE(is_public, 0) = 1 OR created_by_user_id = ?)
      ORDER BY name COLLATE NOCASE
    ''', [uid]);
    final exercises = <_ExerciseItem>[];
    final fcIds = <int>{};
    for (final r in exRows) {
      final id = _int(r['id']);
      final isPublic = _int(r['is_public']) == 1;
      final createdBy = _str(r['created_by_user_id']);
      final fc = _int(r['ai_form_analysis']) == 1;
      if (fc) fcIds.add(id);
      final ill = _str(r['illustration']);
      exercises.add(_ExerciseItem(
        id: id,
        name: _str(r['name']),
        equipment: _str(r['equipment']),
        hasFormCheck: fc,
        isPublic: isPublic,
        isCustom: !isPublic || (uid.isNotEmpty && createdBy == uid),
        illustration: ill.isEmpty ? null : ill,
        muscles: exMuscles[id] ?? const [],
      ));
    }

    // --- the user's workouts (template workouts excluded) ---
    final wRows = await db.rawQuery('''
      SELECT w.id, w.name, w.created_at
      FROM workout w
      WHERE w.user_id = ? AND COALESCE(w.is_deleted, 0) = 0
        AND NOT EXISTS (
          SELECT 1 FROM workout_template t
          WHERE t.workout_id = w.id OR t.id = w.id
        )
      ORDER BY w.created_at DESC
    ''', [uid]);

    // --- templates: driven by workout_template, no dependency on a
    //     matching row in workout ---
    final tRows = await db.rawQuery('''
      SELECT wt.*,
             w.name AS _workout_name,
             (SELECT COUNT(*) FROM workout_exercise x
               WHERE x.workout_id = wt.workout_id) AS _cnt_wid,
             (SELECT COUNT(*) FROM workout_exercise x
               WHERE x.workout_id = wt.id) AS _cnt_id
      FROM workout_template wt
      LEFT JOIN workout w ON w.id = wt.workout_id
      ORDER BY wt.rowid
    ''');

    // Linked workout id per template: whichever column the exercises
    // actually hang off (workout_id first, id as fallback).
    final tLinked = <String>[];
    for (final r in tRows) {
      final wid = _str(r['workout_id']);
      final tid = _str(r['id']);
      String linked;
      if (_int(r['_cnt_wid']) > 0) {
        linked = wid;
      } else if (_int(r['_cnt_id']) > 0) {
        linked = tid;
      } else {
        linked = wid.isNotEmpty ? wid : tid;
      }
      tLinked.add(linked);
    }

    // --- per-workout exercise ids + set counts, one query each ---
    final ids = <String>{};
    for (final r in wRows) {
      ids.add(_str(r['id']));
    }
    ids.addAll(tLinked);
    ids.remove('');
    final exIdsByWorkout = <String, List<int>>{};
    final setCountByWorkout = <String, int>{};
    if (ids.isNotEmpty) {
      final list = ids.toList();
      final ph = List.filled(list.length, '?').join(',');
      final weRows = await db.rawQuery(
        'SELECT workout_id, exercise_id FROM workout_exercise '
        'WHERE workout_id IN ($ph) ORDER BY "order"',
        list,
      );
      for (final r in weRows) {
        exIdsByWorkout
            .putIfAbsent(_str(r['workout_id']), () => [])
            .add(_int(r['exercise_id']));
      }
      final esRows = await db.rawQuery(
        'SELECT we.workout_id AS workout_id, COUNT(*) AS c '
        'FROM exercise_sets es '
        'JOIN workout_exercise we ON we.id = es.workout_exercise_id '
        'WHERE we.workout_id IN ($ph) GROUP BY we.workout_id',
        list,
      );
      for (final r in esRows) {
        setCountByWorkout[_str(r['workout_id'])] = _int(r['c']);
      }
    }

    final lastDone = <String, DateTime?>{};
    final wlRows = await db.rawQuery(
      'SELECT workout_id, MAX(created_at) AS last_at FROM workout_log '
      'WHERE user_id = ? GROUP BY workout_id',
      [uid],
    );
    for (final r in wlRows) {
      lastDone[_str(r['workout_id'])] = _parse(r['last_at']);
    }

    List<_MuscleRef> primaryRefsOf(List<int> exIds) {
      final out = <_MuscleRef>[];
      for (final id in exIds.toSet()) {
        for (final m in exMuscles[id] ?? const <_MuscleRef>[]) {
          if (m.isPrimary) out.add(m);
        }
      }
      return out;
    }

    int fcCountOf(List<int> exIds) =>
        exIds.toSet().where(fcIds.contains).length;

    // --- build workouts ---
    final workouts = <_WorkoutItem>[];
    for (final r in wRows) {
      final id = _str(r['id']);
      final exIds = exIdsByWorkout[id] ?? const <int>[];
      final refs = primaryRefsOf(exIds);
      final sets = setCountByWorkout[id] ?? 0;
      var name = _str(r['name']);
      final groups = _topGroups(refs);
      if (name.isEmpty || name.toLowerCase().startsWith('unnamed workout')) {
        if (groups.isNotEmpty) name = groups.take(2).join(' & ');
      }
      workouts.add(_WorkoutItem(
        id: id,
        name: name.isEmpty ? 'Workout' : _cap(name),
        createdAt: _parse(r['created_at']),
        lastDoneAt: lastDone[id],
        exerciseCount: exIds.toSet().length,
        setCount: sets,
        fcCount: fcCountOf(exIds),
        estMinutes: _estimate(exIds.toSet().length, sets),
        muscles: groups,
        refs: refs,
      ));
    }
    // Most recently used first, never-done by creation date.
    workouts.sort((a, b) {
      final ad = a.lastDoneAt ?? a.createdAt ?? DateTime(2000);
      final bd = b.lastDoneAt ?? b.createdAt ?? DateTime(2000);
      return bd.compareTo(ad);
    });

    // --- build templates ---
    final templates = <_TemplateItem>[];
    for (int i = 0; i < tRows.length; i++) {
      final r = tRows[i];
      final linked = tLinked[i];
      final exIds = exIdsByWorkout[linked] ?? const <int>[];
      final refs = primaryRefsOf(exIds);
      final sets = setCountByWorkout[linked] ?? 0;
      final exCount = exIds.toSet().length;

      var name = _str(r['name']);
      if (name.isEmpty) name = _str(r['_workout_name']);
      if (name.isEmpty) name = 'Template';

      var groups = _topGroups(refs);
      if (groups.isEmpty) {
        // Fall back to the catalog's own text.
        groups = _str(r['main_muscles'])
            .split(RegExp(r'[,/·|]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .take(3)
            .toList();
      }

      var est = _int(r['estimated_time']);
      if (est > 300) est = est ~/ 60; // stored in seconds
      if (est <= 0) est = _estimate(exCount, sets);

      final raw = Map<String, dynamic>.from(r)
        ..remove('_workout_name')
        ..remove('_cnt_wid')
        ..remove('_cnt_id');

      final tplId = _str(r['id']);
      templates.add(_TemplateItem(
        key: '$tplId|$linked|$i',
        workoutId: linked,
        name: _cap(name),
        level: _cap(_str(r['level']).toLowerCase()),
        exerciseCount: exCount,
        setCount: sets,
        fcCount: fcCountOf(exIds),
        estMinutes: est,
        muscles: groups,
        refs: refs,
        raw: raw,
      ));
    }

    return _LibraryData(
      workouts: workouts,
      templates: templates,
      templatesTotal: tRows.length,
      exercises: exercises,
      primaryGroups: primaryGroups,
      subGroups: subGroups,
    );
  }

  // ------------------------------ filtering ---------------------------------

  bool _muscleMatch(Iterable<_MuscleRef> refs, {int? pmgId, int? mgId}) {
    final p = pmgId ?? _pmgId;
    final m = mgId ?? _mgId;
    if (p == null) return true;
    if (m != null) return refs.any((r) => r.mgId == m);
    return refs.any((r) => r.pmgId == p);
  }

  bool _textMatch(List<String> parts) =>
      _query.isEmpty || parts.join(' ').toLowerCase().contains(_query);

  List<_WorkoutItem> _filteredWorkouts({bool applyFc = true}) {
    final d = _data;
    if (d == null) return const [];
    return d.workouts
        .where((w) => _textMatch([w.name, ...w.muscles]))
        .where((w) => _muscleMatch(w.refs))
        .where((w) => !applyFc || !_fcOnly || w.fcCount > 0)
        .toList();
  }

  List<_TemplateItem> _filteredTemplates({bool applyFc = true}) {
    final d = _data;
    if (d == null) return const [];
    return d.templates
        .where((t) => _textMatch([t.name, t.level, ...t.muscles]))
        .where((t) => _muscleMatch(t.refs))
        .where((t) => !applyFc || !_fcOnly || t.fcCount > 0)
        .toList();
  }

  List<_ExerciseItem> _filteredExercises({bool applyFc = true}) {
    final d = _data;
    if (d == null) return const [];
    return d.exercises
        .where((e) => _textMatch(
            [e.name, e.equipment, for (final m in e.muscles) m.mgName]))
        .where((e) => _muscleMatch(e.primary))
        .where((e) => !applyFc || !_fcOnly || e.hasFormCheck)
        .toList();
  }

  /// Items in the current tab that carry form check (before the toggle).
  int _fcAvailable() {
    switch (_tab) {
      case 0:
        return _filteredWorkouts(applyFc: false)
            .where((w) => w.fcCount > 0)
            .length;
      case 1:
        return _filteredTemplates(applyFc: false)
            .where((t) => t.fcCount > 0)
            .length;
      default:
        return _filteredExercises(applyFc: false)
            .where((e) => e.hasFormCheck)
            .length;
    }
  }

  /// Items in the current tab for a muscle choice (search/fc ignored).
  int _countFor(int? pmgId, int? mgId) {
    final d = _data;
    if (d == null) return 0;
    bool ok(Iterable<_MuscleRef> refs) {
      if (pmgId == null) return true;
      if (mgId != null) return refs.any((r) => r.mgId == mgId);
      return refs.any((r) => r.pmgId == pmgId);
    }

    switch (_tab) {
      case 0:
        return d.workouts.where((w) => ok(w.refs)).length;
      case 1:
        return d.templates.where((t) => ok(t.refs)).length;
      default:
        return d.exercises.where((e) => ok(e.primary)).length;
    }
  }

  // ------------------------------ actions -----------------------------------

  Future<void> _openTemplate(_TemplateItem t) async {
    final cb = widget.onOpenTemplate;
    if (cb == null) return;
    try {
      await cb(
          GetWorkoutTemplateRow(Map<String, dynamic>.from(t.raw)), t.workoutId);
    } catch (_) {}
  }

  Future<void> _useTemplate(_TemplateItem t) async {
    final cb = widget.onUseTemplate;
    if (cb == null || _busyTemplate != null) return;
    setState(() => _busyTemplate = t.key);
    try {
      await cb(
          GetWorkoutTemplateRow(Map<String, dynamic>.from(t.raw)), t.workoutId);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _busyTemplate = null);
    await _load();
  }

  Future<void> _showWorkoutMenu(BuildContext anchor, _WorkoutItem w) async {
    final box = anchor.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(anchor).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight =
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay);
    final position = RelativeRect.fromRect(
      Rect.fromPoints(topLeft, bottomRight),
      Offset.zero & overlay.size,
    );

    final choice = await showMenu<String>(
      context: anchor,
      position: position,
      color: _card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kRadiusInner),
        side: BorderSide(color: _line),
      ),
      items: [
        PopupMenuItem<String>(
          value: 'edit',
          height: 44,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: _ink),
              const SizedBox(width: 10),
              Text('Edit', style: _body(14, w: FontWeight.w500)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          height: 44,
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded,
                  size: 18, color: Color(0xFFD64545)),
              const SizedBox(width: 10),
              Text('Delete',
                  style: _body(14,
                      color: const Color(0xFFD64545), w: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
    if (!mounted || choice == null) return;
    if (choice == 'edit') {
      await widget.onEditWorkout?.call(w.id);
    } else if (choice == 'delete') {
      await widget.onDeleteWorkout?.call(w.id);
      if (mounted) await _load();
    }
  }

  Future<void> _pickPrimary() async {
    final d = _data;
    if (d == null) return;
    final items = <_PickItem>[
      _PickItem(null, 'All muscles', _countFor(null, null)),
      for (final g in d.primaryGroups)
        _PickItem(g.id, g.name, _countFor(g.id, null)),
    ];
    final picked = await _showPicker(
        title: 'Muscle group', items: items, selected: _pmgId);
    if (picked == null || !mounted) return;
    setState(() {
      _pmgId = picked.id;
      _mgId = null;
    });
  }

  Future<void> _pickSub() async {
    final d = _data;
    final p = _pmgId;
    if (d == null || p == null) return;
    final pName = d.primaryGroups
        .firstWhere((g) => g.id == p, orElse: () => const _Group(0, 'group'))
        .name;
    final subs = d.subGroups[p] ?? const <_Group>[];
    final items = <_PickItem>[
      _PickItem(null, 'All ${pName.toLowerCase()}', _countFor(p, null)),
      for (final g in subs) _PickItem(g.id, g.name, _countFor(p, g.id)),
    ];
    final picked =
        await _showPicker(title: pName, items: items, selected: _mgId);
    if (picked == null || !mounted) return;
    setState(() => _mgId = picked.id);
  }

  Future<_PickItem?> _showPicker({
    required String title,
    required List<_PickItem> items,
    required int? selected,
  }) {
    return showModalBottomSheet<_PickItem>(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final maxH = MediaQuery.of(ctx).size.height * 0.72;
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _kGutter),
                  child: Row(
                    children: [
                      Text(title, style: _display(20, w: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (_, i) {
                      final it = items[i];
                      final on = it.id == selected;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(ctx).pop(it),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: on ? _accentTint : Colors.transparent,
                            borderRadius: BorderRadius.circular(_kRadiusInner),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  it.label,
                                  style: _body(15,
                                      w: on ? FontWeight.w600 : FontWeight.w500,
                                      color: on ? _accentDeep : _ink),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text('${it.count}',
                                  style: _body(13, color: _inkMuted)),
                              if (on) ...[
                                const SizedBox(width: 10),
                                Icon(Icons.check_rounded,
                                    size: 18, color: _accentDeep),
                              ],
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
  }

  // ------------------------------ typography --------------------------------
  // Built from the app theme so Library uses the same family as every page.

  TextStyle _ts(
    double size, {
    Color? color,
    FontWeight w = FontWeight.w400,
    double height = 1.25,
    double letterSpacing = 0,
    bool display = false,
  }) {
    final th = FlutterFlowTheme.of(context);
    final fam = display ? th.headlineMediumFamily : th.bodyMediumFamily;
    final base = display ? th.headlineMedium : th.bodyMedium;
    return base
        .override(
          fontFamily: fam,
          color: color ?? _ink,
          fontSize: size,
          fontWeight: w,
          lineHeight: height,
          letterSpacing: letterSpacing,
          useGoogleFonts: GoogleFonts.asMap().containsKey(fam),
        )
        .copyWith(fontFeatures: _kTabular);
  }

  TextStyle _display(double size,
          {Color? color, FontWeight w = FontWeight.w800}) =>
      _ts(size,
          color: color,
          w: w,
          height: 1.05,
          letterSpacing: -size * 0.02,
          display: true);

  TextStyle _body(double size,
          {Color? color, FontWeight w = FontWeight.w400}) =>
      _ts(size, color: color, w: w);

  TextStyle _eyebrow({Color? color}) => _ts(11,
      color: color ?? _inkMuted, w: FontWeight.w600, letterSpacing: 1.4);

  Widget _gutter(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: _kGutter),
        child: child,
      );

  // --------------------------------- UI -------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _gutter(_header()),
          const SizedBox(height: 16),
          _gutter(_tabs()),
          const SizedBox(height: 12),
          _gutter(_searchField()),
          const SizedBox(height: 8),
          _gutter(_filterRow()),
          const SizedBox(height: 12),
          Expanded(child: _content()),
        ],
      ),
    );
  }

  // --- header: title + context action ---
  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text('Library', style: _display(32))),
        const SizedBox(width: 12),
        _headerAction(),
      ],
    );
  }

  Widget _headerAction() {
    if (_tab == 2) {
      return _pillButton(
        icon: Icons.add_rounded,
        label: 'Custom',
        bg: _card,
        fg: _ink,
        onTap: () => widget.onCreateCustomExercise?.call(),
      );
    }
    if (!(widget.canGenerate ?? true)) {
      // Locked: quota used up on the free tier. Tap opens the paywall.
      return _pillButton(
        icon: Icons.lock_rounded,
        label: 'Generate',
        bg: _cardSub,
        fg: _inkMuted,
        onTap: () => widget.onOpenPremium?.call(),
      );
    }
    return _pillButton(
      icon: Icons.auto_awesome_rounded,
      label: 'Generate',
      bg: _accentTint,
      fg: _accentDeep,
      onTap: () => widget.onGenerateWorkout?.call(),
    );
  }

  // --- segmented tabs ---
  Widget _tabs() {
    const labels = ['Workouts', 'Templates', 'Exercises'];
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Color.alphaBlend(_ink.withOpacity(0.07), _bg),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_tab == i) return;
                  setState(() {
                    _tab = i;
                    _fcOnly = false;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    color: _tab == i ? _card : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: _body(
                      13,
                      color: _tab == i ? _ink : _inkMuted,
                      w: _tab == i ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- search ---
  Widget _searchField() {
    String hint;
    if (_tab == 0) {
      hint = 'Search workouts';
    } else if (_tab == 1) {
      hint = 'Search templates';
    } else {
      final n = _data?.exercises.length ?? 0;
      hint = n > 0 ? 'Search $n exercises' : 'Search exercises';
    }
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(_kRadiusInner),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: _inkMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              style: _body(14),
              cursorColor: _accent,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: _body(14, color: _inkMuted),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _search.clear();
                setState(() => _query = '');
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 18, color: _inkMuted),
              ),
            ),
        ],
      ),
    );
  }

  // --- filters: muscle group (+ sub muscle) and form-check toggle ---
  Widget _filterRow() {
    final d = _data;
    _Group? pmg;
    _Group? mg;
    List<_Group> subs = const [];
    if (d != null && _pmgId != null) {
      for (final g in d.primaryGroups) {
        if (g.id == _pmgId) pmg = g;
      }
      subs = d.subGroups[_pmgId] ?? const [];
      if (_mgId != null) {
        for (final g in subs) {
          if (g.id == _mgId) mg = g;
        }
      }
    }
    final fcAvail = _fcAvailable();

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _filterChip(
                  label: pmg?.name ?? 'All muscles',
                  active: pmg != null,
                  onTap: _pickPrimary,
                  onClear: pmg == null
                      ? null
                      : () => setState(() {
                            _pmgId = null;
                            _mgId = null;
                          }),
                ),
                if (pmg != null && subs.length > 1) ...[
                  const SizedBox(width: 6),
                  _filterChip(
                    label: mg?.name ?? 'All ${pmg.name.toLowerCase()}',
                    active: mg != null,
                    onTap: _pickSub,
                    onClear:
                        mg == null ? null : () => setState(() => _mgId = null),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: fcAvail == 0 && !_fcOnly
              ? null
              : () => setState(() => _fcOnly = !_fcOnly),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _fcOnly ? _accentTint : _card,
              borderRadius: BorderRadius.circular(_kRadiusInner),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AiFormBadge(
                  width: 18,
                  height: 18,
                  showLabel: false,
                  iconSize: 18,
                  color:
                      _fcOnly ? _accentDeep : (fcAvail == 0 ? _inkFaint : _ink),
                ),
                const SizedBox(width: 6),
                Text(
                  '$fcAvail',
                  style: _body(
                    13,
                    w: FontWeight.w600,
                    color: _fcOnly
                        ? _accentDeep
                        : (fcAvail == 0 ? _inkFaint : _ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final fg = active ? _accentDeep : _ink;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.only(left: 12, right: 8),
        decoration: BoxDecoration(
          color: active ? _accentTint : _card,
          borderRadius: BorderRadius.circular(_kRadiusInner),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: _body(13,
                    color: fg, w: active ? FontWeight.w600 : FontWeight.w500)),
            const SizedBox(width: 4),
            if (onClear == null)
              Icon(Icons.expand_more_rounded, size: 18, color: fg)
            else
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.close_rounded, size: 16, color: fg),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- tab content ---
  Widget _content() {
    final d = _data;
    if (d == null) {
      return Center(
        child: _error == null
            ? CircularProgressIndicator(color: _accent, strokeWidth: 2)
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Library failed to load\n$_error',
                  textAlign: TextAlign.center,
                  style: _body(13, color: _inkMuted),
                ),
              ),
      );
    }

    List<Widget> children;
    switch (_tab) {
      case 0:
        children = _workoutsTab(d);
        break;
      case 1:
        children = _templatesTab(d);
        break;
      default:
        children = _exercisesTab(d);
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, _kBottomInset),
        physics: const AlwaysScrollableScrollPhysics(),
        children: children,
      ),
    );
  }

  List<Widget> _workoutsTab(_LibraryData d) {
    final list = _filteredWorkouts();
    final filtered = _query.isNotEmpty || _pmgId != null || _fcOnly;
    return [
      if (list.isEmpty)
        _gutter(_emptyCard(
          d.workouts.isEmpty ? 'No workouts yet' : 'No workouts match',
          d.workouts.isEmpty
              ? 'Create one below, or start from a template.'
              : 'Try another muscle or clear the search.',
        ))
      else
        for (int i = 0; i < list.length; i++) ...[
          _gutter(_workoutRow(list[i])),
          if (i < list.length - 1) const SizedBox(height: 8),
        ],
      if (!filtered || list.isNotEmpty) ...[
        const SizedBox(height: 10),
        _gutter(_dashedButton(
          'New workout',
          onTap: () => widget.onCreateWorkout?.call(),
        )),
      ],
    ];
  }

  List<Widget> _templatesTab(_LibraryData d) {
    final list = _filteredTemplates();
    if (list.isEmpty) {
      final none = d.templatesTotal == 0;
      return [
        _gutter(_emptyCard(
          none ? 'No templates on this device' : 'No templates match',
          none
              ? "The template catalog hasn't been loaded yet."
              : 'Try another muscle or clear the search.',
        )),
      ];
    }
    return [
      for (int i = 0; i < list.length; i++) ...[
        _gutter(_templateRow(list[i])),
        if (i < list.length - 1) const SizedBox(height: 8),
      ],
    ];
  }

  List<Widget> _exercisesTab(_LibraryData d) {
    final list = _filteredExercises();
    if (list.isEmpty) {
      return [
        _gutter(_emptyCard(
          'No exercises match',
          'Try another muscle or clear the search.',
        )),
      ];
    }

    // Custom first, then by primary muscle group (catalog order).
    final custom = list.where((e) => e.isCustom).toList();
    final byGroup = <int, List<_ExerciseItem>>{};
    final other = <_ExerciseItem>[];
    for (final e in list) {
      if (e.isCustom) continue;
      final p = e.primary.isEmpty ? null : e.primary.first;
      if (p == null || p.pmgName.isEmpty) {
        other.add(e);
      } else {
        byGroup.putIfAbsent(p.pmgId, () => []).add(e);
      }
    }

    final sections = <MapEntry<String, List<_ExerciseItem>>>[];
    if (custom.isNotEmpty) sections.add(MapEntry('Custom', custom));
    for (final g in d.primaryGroups) {
      final items = byGroup[g.id];
      if (items != null && items.isNotEmpty)
        sections.add(MapEntry(g.name, items));
    }
    // Groups not in primary_muscle_group (defensive).
    for (final entry in byGroup.entries) {
      if (d.primaryGroups.any((g) => g.id == entry.key)) continue;
      sections
          .add(MapEntry(entry.value.first.primary.first.pmgName, entry.value));
    }
    if (other.isNotEmpty) sections.add(MapEntry('Other', other));

    return [
      for (int s = 0; s < sections.length; s++) ...[
        _gutter(Text(sections[s].key.toUpperCase(), style: _eyebrow())),
        const SizedBox(height: 8),
        _gutter(Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(_kRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < sections[s].value.length; i++) ...[
                _exerciseRow(sections[s].value[i]),
                if (i < sections[s].value.length - 1)
                  Divider(height: 1, thickness: 1, indent: 76, color: _cardSub),
              ],
            ],
          ),
        )),
        if (s < sections.length - 1) const SizedBox(height: 18),
      ],
    ];
  }

  // --- rows ---

  Widget _workoutRow(_WorkoutItem w) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(_kRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.name,
                    style: _body(16, w: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  '${w.exerciseCount} exercises · ~${w.estMinutes} min · ${_ago(w.lastDoneAt)}',
                  style: _body(12, color: _inkMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _musclesLine(w.muscles, w.fcCount),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _solidButton('Start', onTap: () => widget.onStartWorkout?.call(w.id)),
          Builder(
            builder: (ctx) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showWorkoutMenu(ctx, w),
              child: SizedBox(
                width: 36,
                height: 36,
                child:
                    Icon(Icons.more_vert_rounded, size: 20, color: _inkMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _templateRow(_TemplateItem t) {
    final busy = _busyTemplate == t.key;
    final meta = <String>[
      if (t.level.isNotEmpty) t.level,
      '~${t.estMinutes} min',
      '${t.exerciseCount} exercises',
    ].join(' · ');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openTemplate(t),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(_kRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name,
                      style: _body(16, w: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(meta,
                      style: _body(12, color: _inkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  _musclesLine(t.muscles, t.fcCount),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _outlineButton(
              'Use',
              busy: busy,
              onTap: busy ? null : () => _useTemplate(t),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exerciseRow(_ExerciseItem e) {
    final prim = e.primary.map((m) => m.mgName).where((s) => s.isNotEmpty);
    final sub = <String>[
      if (e.equipment.isNotEmpty) _cap(e.equipment),
      if (prim.isNotEmpty) prim.take(2).join(', '),
    ].join(' · ');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onOpenExercise?.call(e.id, e.isPublic),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            ExerciseAssetImage(
              width: 52,
              height: 52,
              exerciseName: exerciseImageName(e.name).toString(),
              illustration: e.illustration,
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
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(sub,
                        style: _body(12, color: _inkMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            if (e.hasFormCheck) ...[
              const SizedBox(width: 8),
              const AiFormBadge(showLabel: true, iconSize: 13),
            ],
          ],
        ),
      ),
    );
  }

  Widget _musclesLine(List<String> muscles, int fcCount) {
    return Row(
      children: [
        Flexible(
          child: Text(
            muscles.isEmpty ? '—' : muscles.join(' · '),
            style: _body(12, color: _inkMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (fcCount > 0) ...[
          const SizedBox(width: 8),
          AiFormBadge(
            width: 13,
            height: 13,
            showLabel: false,
            iconSize: 13,
            color: _accentDeep,
          ),
          const SizedBox(width: 3),
          Text('$fcCount',
              style: _body(12, color: _accentDeep, w: FontWeight.w600)),
        ],
      ],
    );
  }

  // ------------------------------ primitives --------------------------------

  Widget _emptyCard(String title, String subtitle) => Container(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(_kRadius),
        ),
        child: Column(
          children: [
            Text(title,
                style: _body(16, w: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle,
                style: _body(13, color: _inkMuted),
                textAlign: TextAlign.center),
          ],
        ),
      );

  Widget _pillButton({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
    VoidCallback? onTap,
  }) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 6),
              Text(label, style: _body(13, color: fg, w: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _solidButton(String label, {VoidCallback? onTap}) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _kDark,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: _body(13, color: _kOnDark, w: FontWeight.w600)),
        ),
      );

  Widget _outlineButton(String label,
          {VoidCallback? onTap, bool busy = false}) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _ink, width: 1.5),
          ),
          alignment: Alignment.center,
          child: busy
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _ink),
                )
              : Text(label, style: _body(13, w: FontWeight.w600)),
        ),
      );

  Widget _dashedButton(String label, {VoidCallback? onTap}) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_kRadius),
            border: Border.all(color: _inkFaint, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 20, color: _ink),
              const SizedBox(width: 8),
              Text(label, style: _body(14, w: FontWeight.w600)),
            ],
          ),
        ),
      );
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
