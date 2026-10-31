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
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

/// "Pick an exercise to analyze" — bottom sheet content.
///
/// Layout: search → Recent (exercises this user already analyzed, newest
/// first, with last score) → all AI-analyzable exercises grouped by primary
/// muscle, 3-column grid. Cards show the last score when one exists,
/// otherwise a small AI badge. Everything is loaded from SQLite by the widget
/// itself.
///
/// Localization: `languageCode` drives UI strings, exercise / muscle names
/// (via localizedName) and text direction (RTL for 'he'). Image lookups use
/// the English exercise name.
///
/// [onPick](exerciseId, exerciseName) fires on tap — exerciseName is the
/// ENGLISH name (stable key for analyzers). [onClose] fires from the X.
///
/// FF: Bottom Sheet, height ~85%, useSafeArea off, Width/Height Infinity.
class AnalyzeExercisePicker extends StatefulWidget {
  const AnalyzeExercisePicker({
    super.key,
    this.width,
    this.height,
    required this.userId,
    this.languageCode,
    this.onPick,
    this.onClose,
  });

  final double? width;
  final double? height;
  final String userId;
  final String? languageCode;
  final Future Function(int exerciseId, String exerciseName)? onPick;
  final Future Function()? onClose;

  @override
  State<AnalyzeExercisePicker> createState() => _AnalyzeExercisePickerState();
}

// ---------------------------------------------------------------------------
// Localization
// ---------------------------------------------------------------------------

const Set<String> _kRtl = {'he', 'ar'};

const Map<String, Map<String, String>> _kStrings = {
  "title": {
    "en": "Pick an exercise to analyze",
    "es": "Elige un ejercicio para analizar",
    "he": "בחר תרגיל לניתוח",
    "de": "Übung zur Analyse wählen",
    "fr": "Choisir un exercice à analyser",
  },
  "loading": {
    "en": "Loading…",
    "es": "Cargando…",
    "he": "טוען…",
    "de": "Lädt…",
    "fr": "Chargement…",
  },
  "countWithAi": {
    "en": "{n} exercises with AI form analysis",
    "es": "{n} ejercicios con análisis de técnica IA",
    "he": "{n} תרגילים עם ניתוח טכניקה AI",
    "de": "{n} Übungen mit KI-Technikanalyse",
    "fr": "{n} exercices avec analyse IA de la technique",
  },
  "searchExercise": {
    "en": "Search exercise",
    "es": "Buscar ejercicio",
    "he": "חיפוש תרגיל",
    "de": "Übung suchen",
    "fr": "Rechercher un exercice",
  },
  "recent": {
    "en": "Recent",
    "es": "Recientes",
    "he": "אחרונים",
    "de": "Zuletzt",
    "fr": "Récents",
  },
  "results": {
    "en": "Results",
    "es": "Resultados",
    "he": "תוצאות",
    "de": "Ergebnisse",
    "fr": "Résultats",
  },
  "other": {
    "en": "Other",
    "es": "Otros",
    "he": "אחר",
    "de": "Sonstige",
    "fr": "Autres",
  },
  "noneAvailable": {
    "en": "No exercises available",
    "es": "No hay ejercicios disponibles",
    "he": "אין תרגילים זמינים",
    "de": "Keine Übungen verfügbar",
    "fr": "Aucun exercice disponible",
  },
  "noMatch": {
    "en": "No exercises match \"{q}\"",
    "es": "Ningún ejercicio coincide con \"{q}\"",
    "he": "אין תרגילים התואמים ל-\"{q}\"",
    "de": "Keine Übungen passen zu \"{q}\"",
    "fr": "Aucun exercice ne correspond à \"{q}\"",
  },
  "justNow": {
    "en": "just now",
    "es": "ahora mismo",
    "he": "עכשיו",
    "de": "gerade eben",
    "fr": "à l'instant",
  },
  "hoursAgo": {
    "en": "{n}h ago",
    "es": "hace {n} h",
    "he": "לפני {n} שע׳",
    "de": "vor {n} Std.",
    "fr": "il y a {n} h",
  },
  "daysAgo": {
    "en": "{n}d ago",
    "es": "hace {n} d",
    "he": "לפני {n} ימים",
    "de": "vor {n} T.",
    "fr": "il y a {n} j",
  },
  "weeksAgo": {
    "en": "{n}w ago",
    "es": "hace {n} sem.",
    "he": "לפני {n} שב׳",
    "de": "vor {n} Wo.",
    "fr": "il y a {n} sem.",
  },
  "monthsAgo": {
    "en": "{n}mo ago",
    "es": "hace {n} meses",
    "he": "לפני {n} חוד׳",
    "de": "vor {n} Mon.",
    "fr": "il y a {n} mois",
  },
};

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

class _Ex {
  final int id;
  final String name; // localized (display)
  final String nameEn; // English (assets, callback, search)
  final String? illustration;
  final int muscleId; // primary_muscle_group.id, 9999 = other
  final String muscle; // localized group name
  double? lastScore;
  DateTime? lastAt;
  _Ex(this.id, this.name, this.nameEn, this.illustration, this.muscleId,
      this.muscle);
}

// Section order by primary_muscle_group.id (language independent).
// 6 Legs, 2 Back, 1 Chest, 3 Shoulders, 4 Biceps, 5 Triceps, 7 Core,
// 9 Forearms, 8 Neck.
const List<int> _kMuscleOrder = [6, 2, 1, 3, 4, 5, 7, 9, 8];
const int _kOtherId = 9999;

class _AnalyzeExercisePickerState extends State<AnalyzeExercisePicker> {
  List<_Ex> _all = [];
  bool _loading = true;
  String _query = '';
  String? _docsDir;
  final TextEditingController _search = TextEditingController();

  String get _lang {
    final l = (widget.languageCode ?? 'en').trim().toLowerCase();
    return l.isEmpty ? 'en' : l;
  }

  bool get _isRtl => _kRtl.contains(_lang);

  String _t(String key, {int? n, String? q}) {
    final m = _kStrings[key];
    var s = m == null ? key : (m[_lang] ?? m['en'] ?? key);
    if (n != null) s = s.replaceAll('{n}', '$n');
    if (q != null) s = s.replaceAll('{q}', q);
    return s;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AnalyzeExercisePicker old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId ||
        old.languageCode != widget.languageCode) {
      _load();
    }
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

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return _t('justNow');
    if (diff.inHours < 24) return _t('hoursAgo', n: diff.inHours);
    if (diff.inDays < 7) return _t('daysAgo', n: diff.inDays);
    if (diff.inDays < 30) return _t('weeksAgo', n: (diff.inDays / 7).floor());
    return _t('monthsAgo', n: (diff.inDays / 30).floor());
  }

  static String _scoreStr(double s) {
    final q = (s * 2).round() / 2.0;
    return q == q.roundToDouble() ? q.round().toString() : q.toStringAsFixed(1);
  }

  // ---------- SQLite ----------
  /// Exercises with AI analysis + their primary muscle group
  /// (exercise_muscle_group → muscle_group → primary_muscle_group).
  Future<List<Map<String, Object?>>> _queryExercises() async {
    final db = SQLiteManager.instance.database;
    try {
      return await db.rawQuery('''
        SELECT e.id AS id, e.name AS name, e.illustration AS illustration,
          (SELECT pmg.id
             FROM exercise_muscle_group emg
             JOIN muscle_group mg ON mg.id = emg.muscle_group_id
             JOIN primary_muscle_group pmg ON pmg.id = mg.primary_muscle_group_id
            WHERE emg.exercise_id = e.id
            ORDER BY emg.is_primary DESC, emg.id
            LIMIT 1) AS pmg_id,
          (SELECT pmg.name
             FROM exercise_muscle_group emg
             JOIN muscle_group mg ON mg.id = emg.muscle_group_id
             JOIN primary_muscle_group pmg ON pmg.id = mg.primary_muscle_group_id
            WHERE emg.exercise_id = e.id
            ORDER BY emg.is_primary DESC, emg.id
            LIMIT 1) AS pmg_name
        FROM exercise e
        WHERE CAST(e.ai_form_analysis AS INTEGER) = 1
          AND COALESCE(e.is_deleted, 0) = 0
      ''');
    } catch (_) {}
    // Fallback: no grouping.
    try {
      return await db.rawQuery('''
        SELECT id, name, illustration, NULL AS pmg_id, NULL AS pmg_name
        FROM exercise
        WHERE CAST(ai_form_analysis AS INTEGER) = 1
      ''');
    } catch (_) {
      return const [];
    }
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

    final lang = _lang;
    final rows = await _queryExercises();
    final byId = <int, _Ex>{};
    for (final r in rows) {
      final id = _i(r['id']);
      final rawName = (r['name'] ?? '').toString().trim();
      if (id == null || rawName.isEmpty) continue;
      final ill = r['illustration']?.toString().trim();
      final pmgId = _i(r['pmg_id']);
      final rawPmg = (r['pmg_name'] ?? '').toString().trim();
      final pmgName = rawPmg.isEmpty ? '' : localizedName(rawPmg, lang);
      byId[id] = _Ex(
        id,
        localizedName(rawName, lang),
        localizedName(rawName, 'en'),
        (ill == null || ill.isEmpty) ? null : ill,
        pmgId ?? _kOtherId,
        pmgName.isEmpty ? _t('other') : pmgName,
      );
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

  static int _byName(_Ex a, _Ex b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());

  /// Ordered (muscle, exercises) sections.
  List<MapEntry<String, List<_Ex>>> get _sections {
    final map = <int, List<_Ex>>{};
    final names = <int, String>{};
    for (final e in _all) {
      map.putIfAbsent(e.muscleId, () => []).add(e);
      names[e.muscleId] = e.muscle;
    }
    final keys = map.keys.toList()
      ..sort((a, b) {
        if (a == _kOtherId) return 1;
        if (b == _kOtherId) return -1;
        final ia = _kMuscleOrder.indexOf(a), ib = _kMuscleOrder.indexOf(b);
        if (ia != -1 && ib != -1) return ia.compareTo(ib);
        if (ia != -1) return -1;
        if (ib != -1) return 1;
        return a.compareTo(b);
      });
    return [for (final k in keys) MapEntry(names[k]!, map[k]!..sort(_byName))];
  }

  List<_Ex> get _searchResults {
    final q = _query.trim().toLowerCase();
    return _all
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            e.nameEn.toLowerCase().contains(q))
        .toList()
      ..sort(_byName);
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
    return AssetImage('assets/images/${e.nameEn.replaceAll(' ', '_')}.jpg');
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
    // English name: a stable key for analyzer selection downstream.
    widget.onPick?.call(e.id, e.nameEn);
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bool searching = _query.trim().isNotEmpty;

    return Directionality(
      textDirection: _isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Container(
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
              padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 12, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_t('title'),
                            style: _ts(22, FontWeight.w700, th.primaryText)),
                        const SizedBox(height: 2),
                        Text(
                          _loading
                              ? _t('loading')
                              : _t('countWithAi', n: _all.length),
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
                    Icon(Icons.search_rounded,
                        size: 20, color: th.secondaryText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: (v) => setState(() => _query = v),
                        style: _ts(15, FontWeight.w500, th.primaryText),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: _t('searchExercise'),
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
          _sectionHeader(_t('recent')),
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
              child: Text(_t('noneAvailable'),
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
        child: Text(_t('noMatch', q: _query.trim()),
            style: _ts(15, FontWeight.w500, th.secondaryText)),
      );
    }
    return ListView(
      padding: EdgeInsets.only(bottom: 16 + bottomInset),
      children: [
        _sectionHeader(_t('results'), res.length),
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
                  PositionedDirectional(
                    top: 0,
                    end: 0,
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
