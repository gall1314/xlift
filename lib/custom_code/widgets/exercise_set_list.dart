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
import 'package:google_fonts/google_fonts.dart';

/// The set table of ONE exercise inside ONE logged workout (the list inside
/// each card of the exercise History tab).
///
/// Self-managed: reads set_log itself, no FlutterFlow query needed. Shows
/// every set with its reps or time and its weight, and each drop set
/// directly under its parent set ("Drop 1", "Drop 2"), not numbered as a set
/// of its own.
///
/// - Timed sets show the time (45 sec / 1:15 min) instead of reps.
/// - A set with no weight shows "Bodyweight" (a timed set shows a dash).
/// - Weights are stored as typed, each with its own unit (is_kg); a value is
///   converted only when its unit is not the one the app shows.
///
/// HEIGHT: a 24 header, then each set row is 52 and each drop row is 44,
/// every row followed by a 6 gap. Total = 24 + sets * 58 + drops * 50.
/// The custom function setListHeight(dropFlags) returns that number for the
/// widget's height field; keep the two in sync.
///
/// Localization: reads the app language from FFLocalizations (no parameter);
/// Hebrew renders RTL with Hebrew unit labels.
class ExerciseSetList extends StatefulWidget {
  const ExerciseSetList({
    super.key,
    this.width,
    this.height,
    required this.workoutLogId,
    required this.exerciseId,
  });

  final double? width;
  final double? height;
  final String workoutLogId;
  final int exerciseId;

  @override
  State<ExerciseSetList> createState() => _ExerciseSetListState();
}

// Layout constants: setListHeight() depends on these.
const double _kHeaderH = 24;
const double _kRowH = 52;
const double _kDropH = 44;
const double _kRowGap = 6;

const Set<String> _kRtl = {'he', 'ar'};

const Map<String, Map<String, String>> _kStrings = {
  "set": {
    "en": "Set",
    "es": "Serie",
    "he": "סט",
    "de": "Satz",
    "fr": "Série",
  },
  "reps": {
    "en": "Reps",
    "es": "Reps",
    "he": "חזרות",
    "de": "Wdh.",
    "fr": "Reps",
  },
  "time": {
    "en": "Time",
    "es": "Tiempo",
    "he": "זמן",
    "de": "Zeit",
    "fr": "Durée",
  },
  "weight": {
    "en": "Weight",
    "es": "Peso",
    "he": "משקל",
    "de": "Gewicht",
    "fr": "Poids",
  },
  "drop": {
    "en": "Drop {n}",
    "es": "Drop {n}",
    "he": "דרופ {n}",
    "de": "Drop {n}",
    "fr": "Drop {n}",
  },
  "bodyweight": {
    "en": "Bodyweight",
    "es": "Peso corporal",
    "he": "משקל גוף",
    "de": "Körpergewicht",
    "fr": "Poids du corps",
  },
  "kg": {
    "en": "kg",
    "es": "kg",
    "he": "ק״ג",
    "de": "kg",
    "fr": "kg",
  },
  "lbs": {
    "en": "lbs",
    "es": "lbs",
    "he": "ליב׳",
    "de": "lbs",
    "fr": "lbs",
  },
  "sec": {
    "en": "sec",
    "es": "s",
    "he": "שנ׳",
    "de": "Sek.",
    "fr": "s",
  },
  "min": {
    "en": "min",
    "es": "min",
    "he": "דק׳",
    "de": "Min.",
    "fr": "min",
  },
};

String _tr(String lang, String key, {int? n}) {
  final m = _kStrings[key];
  var s = m == null ? key : (m[lang] ?? m['en'] ?? key);
  if (n != null) s = s.replaceAll('{n}', '$n');
  return s;
}

class _SetRow {
  _SetRow({
    required this.rid,
    required this.number,
    required this.reps,
    required this.weight,
    required this.isKg,
    required this.seconds,
    required this.isDrop,
    required this.dropOrder,
  });

  final int rid; // read order, used as a stable tie-breaker
  final int number; // set_number as stored (0 = missing)
  final int reps;
  final double weight;
  final bool isKg;
  final int seconds;
  final bool isDrop;
  final int dropOrder; // 0 = not stored
  final List<_SetRow> drops = [];
}

class _ExerciseSetListState extends State<ExerciseSetList> {
  List<_SetRow> _sets = [];
  bool _loaded = false;
  bool _timeBased = false;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ExerciseSetList old) {
    super.didUpdateWidget(old);
    if (old.workoutLogId != widget.workoutLogId ||
        old.exerciseId != widget.exerciseId) {
      _load();
    }
  }

  // ---------- parsing ----------
  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.round();
    return num.tryParse(v.toString().trim())?.round() ?? 0;
  }

  static double _dbl(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim()) ?? 0;
  }

  /// duration_seconds is written in milliseconds by the workout save; older
  /// rows may hold plain seconds. A single set of 1000+ seconds does not
  /// happen, so a value that large is milliseconds.
  static int _seconds(dynamic v) {
    final int raw = _int(v);
    if (raw <= 0) return 0;
    return raw >= 1000 ? (raw / 1000).round() : raw;
  }

  // ---------- data ----------
  Future<void> _load() async {
    final int token = ++_token;
    final String logId = widget.workoutLogId.trim();
    final List<_SetRow> parents = [];
    bool timeBased = false;

    try {
      final db = SQLiteManager.instance.database;

      try {
        final ex = await db.rawQuery(
          'SELECT is_time_based FROM exercise WHERE id = ?',
          [widget.exerciseId],
        );
        if (ex.isNotEmpty) timeBased = _int(ex.first['is_time_based']) == 1;
      } catch (_) {}

      List<Map<String, Object?>> rows;
      const String where = 'FROM set_log WHERE workout_log_id = ? '
          'AND CAST(exercise_id AS INTEGER) = ?';
      try {
        rows = await db.rawQuery(
          'SELECT rowid AS _rid, * $where ORDER BY rowid ASC',
          [logId, widget.exerciseId],
        );
      } catch (_) {
        rows = await db.rawQuery(
          'SELECT * $where',
          [logId, widget.exerciseId],
        );
      }

      final List<_SetRow> all = [];
      for (int i = 0; i < rows.length; i++) {
        final r = rows[i];
        final String kgRaw = (r['is_kg'] ?? '').toString().trim();
        all.add(_SetRow(
          rid: r['_rid'] == null ? i : _int(r['_rid']),
          number: _int(r['set_number']),
          reps: _int(r['reps']),
          weight: _dbl(r['weight']),
          isKg: kgRaw.isEmpty ? true : _int(kgRaw) != 0,
          seconds: _seconds(r['duration_seconds']),
          isDrop: _int(r['is_dropset']) == 1,
          dropOrder: _int(r['drop_order']),
        ));
      }

      // Parent sets, in set order.
      parents.addAll(all.where((s) => !s.isDrop));
      parents.sort((a, b) {
        final c = a.number.compareTo(b.number);
        return c != 0 ? c : a.rid.compareTo(b.rid);
      });

      // Each drop goes under its parent: the set with the same set_number,
      // else the last set saved before it, else the first set.
      for (final d in all.where((s) => s.isDrop)) {
        if (parents.isEmpty) break;
        _SetRow? parent;
        if (d.number > 0) {
          for (final p in parents) {
            if (p.number == d.number) {
              parent = p;
              break;
            }
          }
        }
        if (parent == null) {
          for (final p in parents) {
            if (p.rid < d.rid && (parent == null || p.rid > parent.rid)) {
              parent = p;
            }
          }
        }
        (parent ?? parents.first).drops.add(d);
      }
      for (final p in parents) {
        p.drops.sort((a, b) {
          final c = a.dropOrder.compareTo(b.dropOrder);
          return c != 0 ? c : a.rid.compareTo(b.rid);
        });
      }
    } catch (_) {}

    if (!mounted || token != _token) return;
    setState(() {
      _sets = parents;
      _timeBased = timeBased;
      _loaded = true;
    });
  }

  // ---------- formatting ----------
  static String _num(double v) {
    final double r = (v * 10).round() / 10;
    return r == r.roundToDouble() ? r.toInt().toString() : r.toStringAsFixed(1);
  }

  TextStyle _st(BuildContext ctx, double size, FontWeight w, Color c) {
    final th = FlutterFlowTheme.of(ctx);
    return th.bodyMedium.override(
      fontFamily: th.bodyMediumFamily,
      color: c,
      fontSize: size,
      fontWeight: w,
      letterSpacing: 0,
      useGoogleFonts: GoogleFonts.asMap().containsKey(th.bodyMediumFamily),
    );
  }

  /// "11 reps" / "45 sec" / "1:15 min": the number bold, the unit muted.
  Widget _value(BuildContext ctx, String value, String unit) {
    final th = FlutterFlowTheme.of(ctx);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value,
            style: _st(ctx, 17, FontWeight.w700, th.primaryText),
          ),
          if (unit.isNotEmpty)
            TextSpan(
              text: ' $unit',
              style: _st(ctx, 12, FontWeight.w500, th.secondaryText),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }

  Widget _amount(BuildContext ctx, String lang, _SetRow s, bool timed) {
    if (timed) {
      if (s.seconds < 60) {
        return _value(ctx, '${s.seconds}', _tr(lang, 'sec'));
      }
      final String mmss =
          '${s.seconds ~/ 60}:${(s.seconds % 60).toString().padLeft(2, '0')}';
      return _value(ctx, mmss, _tr(lang, 'min'));
    }
    return _value(ctx, '${s.reps}', _tr(lang, 'reps'));
  }

  Widget _weight(
      BuildContext ctx, String lang, _SetRow s, bool timed, bool showKg) {
    final th = FlutterFlowTheme.of(ctx);
    if (s.weight <= 0) {
      return Text(
        timed ? '–' : _tr(lang, 'bodyweight'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: _st(ctx, 13, FontWeight.w500, th.secondaryText),
      );
    }
    // Stored as typed; converted only when the set's unit is not the one
    // on screen.
    final double shown = s.isKg == showKg
        ? s.weight
        : (s.isKg ? s.weight * 2.20462 : s.weight * 0.453592);
    return _value(ctx, _num(shown), _tr(lang, showKg ? 'kg' : 'lbs'));
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    String lang = 'en';
    try {
      final l = FFLocalizations.of(context).languageCode.trim().toLowerCase();
      if (l.isNotEmpty) lang = l;
    } catch (_) {}
    final bool rtl = _kRtl.contains(lang);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color accent = dark ? th.primary : const Color(0xFF0F766E);

    bool showKg = true;
    try {
      showKg = FFAppState().isKg;
    } catch (_) {}

    Widget body;
    if (!_loaded || _sets.isEmpty) {
      body = const SizedBox.shrink();
    } else {
      // A timed exercise, or sets that carry a time and no reps.
      bool isTimed(_SetRow s) => s.seconds > 0 && (_timeBased || s.reps <= 0);
      final bool anyTimed = _sets.any(isTimed);
      final bool allTimed = _sets.every(isTimed);

      final List<Widget> children = [
        // Column labels
        SizedBox(
          height: _kHeaderH,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 6),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    _tr(lang, 'set'),
                    maxLines: 1,
                    style: _st(context, 12, FontWeight.w500, th.secondaryText),
                  ),
                ),
                Expanded(
                  child: Text(
                    allTimed
                        ? _tr(lang, 'time')
                        : (anyTimed
                            ? '${_tr(lang, 'reps')} / ${_tr(lang, 'time')}'
                            : _tr(lang, 'reps')),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _st(context, 12, FontWeight.w500, th.secondaryText),
                  ),
                ),
                Expanded(
                  child: Text(
                    _tr(lang, 'weight'),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _st(context, 12, FontWeight.w500, th.secondaryText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ];

      for (int i = 0; i < _sets.length; i++) {
        final s = _sets[i];
        final bool timed = isTimed(s);

        // Set row
        children.add(Container(
          height: _kRowH,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: th.primaryBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: th.secondaryBackground,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '${s.number > 0 ? s.number : i + 1}',
                      style: _st(context, 15, FontWeight.w700, th.primaryText),
                    ),
                  ),
                ),
              ),
              Expanded(child: _amount(context, lang, s, timed)),
              Expanded(child: _weight(context, lang, s, timed, showKg)),
            ],
          ),
        ));
        children.add(const SizedBox(height: _kRowGap));

        // Its drop sets: tinted, indented, lower than a set row, labelled
        // instead of numbered (see HEIGHT above).
        for (int d = 0; d < s.drops.length; d++) {
          final drop = s.drops[d];
          final bool dropTimed = isTimed(drop);
          children.add(Padding(
            padding: const EdgeInsetsDirectional.only(start: 20),
            child: Container(
              height: _kDropH,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                    th.primary.withOpacity(dark ? 0.16 : 0.09),
                    th.secondaryBackground),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: th.secondaryBackground,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      _tr(lang, 'drop', n: d + 1),
                      maxLines: 1,
                      style: _st(context, 12, FontWeight.w700, accent),
                    ),
                  ),
                  Expanded(child: _amount(context, lang, drop, dropTimed)),
                  Expanded(
                      child: _weight(context, lang, drop, dropTimed, showKg)),
                ],
              ),
            ),
          ));
          children.add(const SizedBox(height: _kRowGap));
        }
      }

      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: body,
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
