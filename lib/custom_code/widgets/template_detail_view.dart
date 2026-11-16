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

import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// The page of ONE workout template: name, level, time, muscle pills with
/// their small illustrations, the list of exercises with the recommended
/// sets x reps, and a "save" button.
///
/// Opened by LibraryView when a template is tapped (it pushes this widget
/// as a full page), so it needs no FlutterFlow page of its own.
///
/// Self-managed: reads the template's exercises, their primary muscle
/// groups (with illustrations) and the recommendations from SQLite itself.
///
/// Parameters:
/// - workoutId: the workout the template's exercises hang off.
/// - name, level, minutes: header texts.
/// - muscles: comma-separated list, already in the app language. Used only
///   as a text fallback when no muscle groups are found in the database.
///
/// Callbacks:
/// - onBack: the back button.
/// - onSave: the "save to my workouts" button (shows a spinner while it
///   runs).
/// - onExerciseTap(exerciseId, isPublic): a tap on an exercise row.
///
/// Localization: reads the app language from FFLocalizations (no parameter).
/// Exercise and muscle names go through localizedName; the recommendation
/// text ("4 sets × 6–8 reps") is rebuilt in the app language. Hebrew renders
/// RTL.
class TemplateDetailView extends StatefulWidget {
  const TemplateDetailView({
    super.key,
    this.width,
    this.height,
    required this.workoutId,
    this.name,
    this.level,
    this.minutes,
    this.muscles,
    this.onBack,
    this.onSave,
    this.onExerciseTap,
  });

  final double? width;
  final double? height;
  final String workoutId;
  final String? name;
  final String? level;
  final int? minutes;
  final String? muscles;
  final Future Function()? onBack;
  final Future Function()? onSave;
  final Future Function(int exerciseId, bool isPublic)? onExerciseTap;

  @override
  State<TemplateDetailView> createState() => _TemplateDetailViewState();
}

const Set<String> _kRtl = {'he', 'ar'};

// The most muscle pills shown under the title.
const int _kMaxMuscles = 5;

const Map<String, Map<String, String>> _kStrings = {
  "template": {
    "en": "Workout template",
    "es": "Plantilla de entreno",
    "he": "תבנית אימון",
    "de": "Workout-Vorlage",
    "fr": "Modèle de séance",
  },
  "exercises": {
    "en": "Exercises",
    "es": "Ejercicios",
    "he": "תרגילים",
    "de": "Übungen",
    "fr": "Exercices",
  },
  "exCount": {
    "en": "{n} exercises",
    "es": "{n} ejercicios",
    "he": "{n} תרגילים",
    "de": "{n} Übungen",
    "fr": "{n} exercices",
  },
  "minutes": {
    "en": "{n} min",
    "es": "{n} min",
    "he": "{n} דק׳",
    "de": "{n} Min.",
    "fr": "{n} min",
  },
  "save": {
    "en": "Save to My Workouts",
    "es": "Guardar en mis entrenos",
    "he": "שמירה באימונים שלי",
    "de": "In meine Workouts",
    "fr": "Ajouter à mes séances",
  },
  "rec": {
    "en": "{n} sets × {r} reps",
    "es": "{n} series × {r} reps",
    "he": "{n} סטים × {r} חזרות",
    "de": "{n} Sätze × {r} Wdh.",
    "fr": "{n} séries × {r} reps",
  },
  "max": {
    "en": "max",
    "es": "máx.",
    "he": "מקסימום",
    "de": "max.",
    "fr": "max",
  },
  "eachLeg": {
    "en": "each leg",
    "es": "por pierna",
    "he": "לכל רגל",
    "de": "pro Bein",
    "fr": "par jambe",
  },
  "empty": {
    "en": "No exercises in this template",
    "es": "Esta plantilla no tiene ejercicios",
    "he": "אין תרגילים בתבנית הזו",
    "de": "Keine Übungen in dieser Vorlage",
    "fr": "Aucun exercice dans ce modèle",
  },
};

// Template levels, keyed by the stored value in lower case.
const Map<String, Map<String, String>> _kLevels = {
  "beginner": {
    "en": "Beginner",
    "es": "Principiante",
    "he": "מתחילים",
    "de": "Anfänger",
    "fr": "Débutant",
  },
  "intermediate": {
    "en": "Intermediate",
    "es": "Intermedio",
    "he": "בינוניים",
    "de": "Mittelstufe",
    "fr": "Intermédiaire",
  },
  "advanced": {
    "en": "Advanced",
    "es": "Avanzado",
    "he": "מתקדמים",
    "de": "Fortgeschritten",
    "fr": "Avancé",
  },
};

String _tr(String lang, String key, {int? n, String? r}) {
  final m = _kStrings[key];
  var s = m == null ? key : (m[lang] ?? m['en'] ?? key);
  if (n != null) s = s.replaceAll('{n}', '$n');
  if (r != null) s = s.replaceAll('{r}', r);
  return s;
}

class _Ex {
  _Ex({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.illustration,
    required this.isPublic,
    required this.recommendation,
  });

  final int id;
  final String name; // localized
  final String nameEn; // English, for the image lookup
  final String? illustration;
  final bool isPublic;
  final String recommendation; // raw English text from the template
}

class _Muscle {
  const _Muscle({
    required this.name,
    this.nameEn = '',
    this.image = '',
  });

  final String name; // localized
  final String nameEn; // English, for the image lookup ('' = text only)
  final String image; // primary_muscle_group.ilustration
}

class _TemplateDetailViewState extends State<TemplateDetailView> {
  List<_Ex> _items = [];
  List<_Muscle> _muscles = [];
  bool _loaded = false;
  bool _saving = false;
  String _lang = 'en';
  int _token = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    String l = 'en';
    try {
      final c = FFLocalizations.of(context).languageCode.trim().toLowerCase();
      if (c.isNotEmpty) l = c;
    } catch (_) {}
    if (!_loaded || l != _lang) {
      _lang = l;
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant TemplateDetailView old) {
    super.didUpdateWidget(old);
    if (old.workoutId != widget.workoutId) _load();
  }

  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.round();
    return num.tryParse(v.toString().trim())?.round() ?? 0;
  }

  static String _str(dynamic v) => v == null ? '' : v.toString().trim();

  // ---------- data ----------
  Future<void> _load() async {
    final int token = ++_token;
    final String wid = widget.workoutId.trim();
    final String lang = _lang;
    final List<_Ex> out = [];
    final List<_Muscle> muscles = [];

    try {
      final db = SQLiteManager.instance.database;

      final exRows = await db.rawQuery(
        'SELECT we.exercise_id AS exercise_id, we."order" AS ord, '
        'e.name AS name, CAST(e.illustration AS TEXT) AS illustration, '
        'e.is_public AS is_public '
        'FROM workout_exercise we '
        'JOIN exercise e ON e.id = we.exercise_id '
        'WHERE we.workout_id = ? ORDER BY we."order" ASC',
        [wid],
      );

      // Primary muscle groups of the template's exercises, most used first.
      // Read row by row (not joined into one string) because the names are
      // stored as JSON with commas.
      try {
        final mRows = await db.rawQuery(
          'SELECT emg.exercise_id AS exercise_id, pmg.id AS pmg_id, '
          'pmg.name AS name, pmg.ilustration AS image '
          'FROM exercise_muscle_group emg '
          'JOIN muscle_group mg ON mg.id = emg.muscle_group_id '
          'JOIN primary_muscle_group pmg '
          'ON pmg.id = mg.primary_muscle_group_id '
          'WHERE COALESCE(emg.is_primary, 1) = 1 AND emg.exercise_id IN '
          '(SELECT exercise_id FROM workout_exercise WHERE workout_id = ?)',
          [wid],
        );
        final Map<int, Set<int>> exByGroup = {};
        final Map<int, Map<String, Object?>> rowByGroup = {};
        final List<int> order = [];
        for (final r in mRows) {
          final int g = _int(r['pmg_id']);
          if (!rowByGroup.containsKey(g)) {
            rowByGroup[g] = r;
            order.add(g);
          }
          exByGroup.putIfAbsent(g, () => <int>{}).add(_int(r['exercise_id']));
        }
        // Most exercises first; ties keep the order they were found in.
        final Map<int, int> pos = {
          for (int i = 0; i < order.length; i++) order[i]: i,
        };
        order.sort((a, b) {
          final int c = exByGroup[b]!.length.compareTo(exByGroup[a]!.length);
          return c != 0 ? c : pos[a]!.compareTo(pos[b]!);
        });
        for (final g in order.take(_kMaxMuscles)) {
          final r = rowByGroup[g]!;
          final String raw = _str(r['name']);
          final String n = localizedName(raw, lang).toString();
          if (n.isEmpty) continue;
          muscles.add(_Muscle(
            name: n,
            nameEn: localizedName(raw, 'en').toString(),
            image: _str(r['image']),
          ));
        }
      } catch (_) {}

      // The recommendations sit on the template row, one column per
      // position in the workout.
      Map<String, Object?> tpl = {};
      try {
        final tRows = await db.rawQuery(
          'SELECT * FROM workout_template WHERE workout_id = ? OR id = ? '
          'LIMIT 1',
          [wid, wid],
        );
        if (tRows.isNotEmpty) tpl = tRows.first;
      } catch (_) {}

      for (final r in exRows) {
        final String rawName = _str(r['name']);
        final String ill = _str(r['illustration']);
        final String pub = _str(r['is_public']);
        out.add(_Ex(
          id: _int(r['exercise_id']),
          name: localizedName(rawName, lang).toString(),
          nameEn: localizedName(rawName, 'en').toString(),
          illustration: (ill.isEmpty || ill == 'null') ? null : ill,
          isPublic: pub.isEmpty ? true : _int(pub) != 0,
          recommendation: _str(tpl['recommendation_${_int(r['ord'])}']),
        ));
      }
    } catch (_) {}

    // Nothing in the database: fall back to the text passed in.
    if (muscles.isEmpty) {
      for (final s in (widget.muscles ?? '').split(',')) {
        final String n = s.trim();
        if (n.isNotEmpty && muscles.length < _kMaxMuscles) {
          muscles.add(_Muscle(name: n));
        }
      }
    }

    if (!mounted || token != _token) return;
    setState(() {
      _items = out;
      _muscles = muscles;
      _loaded = true;
    });
  }

  // ---------- formatting ----------
  String _level(String raw) {
    final m = _kLevels[raw.trim().toLowerCase()];
    return m == null ? raw : (m[_lang] ?? m['en'] ?? raw);
  }

  /// "4 sets × 6–8 reps" in the app language. The stored text follows one
  /// pattern; anything that does not match is shown as stored.
  String _recommendation(String raw) {
    if (raw.isEmpty || _lang == 'en') return raw;
    final m = RegExp(
      r'^(\d+)\s*sets?\s*[×x]\s*(.+?)\s*reps?\s*(\(each leg\))?$',
      caseSensitive: false,
    ).firstMatch(raw.trim());
    if (m == null) return raw;
    final int sets = int.tryParse(m.group(1) ?? '') ?? 0;
    String range = (m.group(2) ?? '').trim();
    if (range.toLowerCase() == 'max') {
      range = _tr(_lang, 'max');
    } else {
      // Keep "6–8" left-to-right inside a right-to-left line.
      range = '\u2066$range\u2069';
    }
    String out = _tr(_lang, 'rec', n: sets, r: range);
    if (m.group(3) != null) out = '$out (${_tr(_lang, 'eachLeg')})';
    return out;
  }

  TextStyle _st(double size, FontWeight w, Color c, {double? height}) {
    final th = FlutterFlowTheme.of(context);
    return th.bodyMedium
        .override(
          fontFamily: th.bodyMediumFamily,
          color: c,
          fontSize: size,
          fontWeight: w,
          letterSpacing: 0,
          useGoogleFonts: GoogleFonts.asMap().containsKey(th.bodyMediumFamily),
        )
        .copyWith(height: height);
  }

  // ---------- actions ----------
  Future<void> _save() async {
    final cb = widget.onSave;
    if (cb == null || _saving) return;
    HapticFeedback.selectionClick();
    setState(() => _saving = true);
    try {
      await cb();
    } catch (_) {}
    if (mounted) setState(() => _saving = false);
  }

  // ---------- pieces ----------
  Widget _topBar() {
    final th = FlutterFlowTheme.of(context);
    final bool rtl = _kRtl.contains(_lang);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(6, 2, 0, 0),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onBack?.call(),
          child: SizedBox(
            width: 44,
            height: 44,
            // Chevron icons flip themselves in RTL; forcing LTR means the
            // icon picked here is the one that is drawn.
            child: Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Icon(
                rtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                size: 30,
                color: th.primaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaItem(IconData icon, String text) {
    final th = FlutterFlowTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: th.secondaryText),
        const SizedBox(width: 6),
        Text(text, style: _st(14, FontWeight.w400, th.secondaryText)),
      ],
    );
  }

  Widget _header() {
    final th = FlutterFlowTheme.of(context);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color accent = dark ? th.primary : const Color(0xFF0F766E);

    final String level = (widget.level ?? '').trim();
    final int minutes = widget.minutes ?? 0;
    final List<Widget> meta = [
      if (level.isNotEmpty)
        _metaItem(Icons.signal_cellular_alt_rounded, _level(level)),
      if (minutes > 0)
        _metaItem(Icons.schedule_rounded, _tr(_lang, 'minutes', n: minutes)),
      if (_items.isNotEmpty)
        _metaItem(Icons.fitness_center_rounded,
            _tr(_lang, 'exCount', n: _items.length)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr(_lang, 'template'),
            style: _st(13, FontWeight.w600, accent),
          ),
          const SizedBox(height: 2),
          Text(
            (widget.name ?? '').trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _st(34, FontWeight.w700, th.primaryText, height: 1.18),
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 16, runSpacing: 6, children: meta),
          ],
        ],
      ),
    );
  }

  Widget _musclePill(_Muscle m) {
    final th = FlutterFlowTheme.of(context);
    final bool hasImage = m.nameEn.isNotEmpty;
    return Container(
      height: 44,
      padding: EdgeInsetsDirectional.fromSTEB(hasImage ? 4 : 14, 4, 14, 4),
      decoration: BoxDecoration(
        color: th.primary.withOpacity(0.22),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImage) ...[
            ClipOval(
              child: Container(
                width: 36,
                height: 36,
                color: Colors.white,
                child: ExerciseAssetImage(
                  width: 36,
                  height: 36,
                  // Assets are keyed by the English name.
                  exerciseName: exerciseImageName(m.nameEn).toString(),
                  fallbackAsset: m.image.isEmpty
                      ? null
                      : (m.image.contains('/')
                          ? m.image
                          : 'assets/images/${m.image}'),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              m.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _st(14, FontWeight.w600, th.primaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseRow(_Ex e) {
    final th = FlutterFlowTheme.of(context);
    final bool rtl = _kRtl.contains(_lang);
    final String rec = _recommendation(e.recommendation);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onExerciseTap?.call(e.id, e.isPublic),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            ExerciseAssetImage(
              width: 48,
              height: 48,
              // Assets are keyed by the English name in every language.
              exerciseName: exerciseImageName(e.nameEn).toString(),
              illustration: e.illustration,
              borderRadius: 12,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        _st(16, FontWeight.w600, th.primaryText, height: 1.25),
                  ),
                  if (rec.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      rec,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _st(13, FontWeight.w400, th.secondaryText),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Icon(
                rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                size: 20,
                color: th.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exerciseCard() {
    final th = FlutterFlowTheme.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: th.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _items.length; i++) ...[
            if (i > 0) Container(height: 1, color: th.alternate),
            _exerciseRow(_items[i]),
          ],
        ],
      ),
    );
  }

  Widget _saveButton() {
    final th = FlutterFlowTheme.of(context);
    final double bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: th.primaryBackground,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottom),
      child: Material(
        color: th.primary,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _saving ? null : _save,
          child: SizedBox(
            height: 54,
            child: Center(
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _tr(_lang, 'save'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _st(17, FontWeight.w600, Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final bool rtl = _kRtl.contains(_lang);

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Container(
        width: widget.width,
        height: widget.height,
        color: th.primaryBackground,
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  _header(),
                  if (_muscles.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final m in _muscles) _musclePill(m),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _tr(_lang, 'exercises'),
                      style: _st(18, FontWeight.w700, th.primaryText),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_loaded && _items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        _tr(_lang, 'empty'),
                        textAlign: TextAlign.center,
                        style: _st(14, FontWeight.w400, th.secondaryText),
                      ),
                    ),
                  if (_items.isNotEmpty) _exerciseCard(),
                ],
              ),
            ),
            _saveButton(),
          ],
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
