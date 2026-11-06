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
import '/flutter_flow/internationalization.dart' show FFLocalizations;

/// Exercise "Finish" / "Reopen" button for the live workout page.
///
/// Replaces the old exercise check that also marked every pre-filled set as
/// done. This button NEVER touches loggedSets. It only decides whether the
/// exercise is complete:
///
/// * Not complete, every set done        -> completes immediately. * Not
/// complete, some sets still open  -> bottom sheet listing saved vs. skipped
/// sets; "Finish" marks the exercise complete (open sets keep isDone=false,
/// so they are simply not saved). "Keep going" does nothing. * Complete ->
/// shows "Reopen"; tapping clears isComplete.
///
/// Data (all JSON lists, same shape as the App State lists): * exerciseSets -
/// the workout template; thiכs exercise's entry gives the set list
/// (setNumber, weighted, timerMode, targetReps). Read-only. * loggedSets -
/// flat {exerciseId, setNumber, isDone, reps, weight, weighted, durationMs}.
/// Read-only. * completedExercises - [{exerciseId, isComplete}].
///
/// onApply(completedExercises) returns the FULL completedExercises list with
/// only this exercise's entry updated (or added). The page writes it back
/// with one Update App State. The widget does not write App State itself.
///
/// Localization: reads the app languaגge from FFLocalizations; RTL for he.
class ExerciseFinishButton extends StatefulWidget {
  const ExerciseFinishButton({
    super.key,
    this.width,
    this.height,
    required this.exerciseId,
    this.exerciseName,
    required this.exerciseSets,
    required this.loggedSets,
    required this.completedExercises,
    this.onApply,
  });

  final double? width;
  final double? height;
  final int exerciseId;
  final String? exerciseName;
  final List<dynamic> exerciseSets;
  final List<dynamic> loggedSets;
  final List<dynamic> completedExercises;
  final Future Function(List<dynamic> completedExercises)? onApply;

  @override
  State<ExerciseFinishButton> createState() => _ExerciseFinishButtonState();
}

// ---------------------------------------------------------------------------
// Localization
// ---------------------------------------------------------------------------

const Set<String> _kRtl = {'he', 'ar'};

/// {n} count, {x} exercise name.
const Map<String, Map<String, String>> _kStrings = {
  "finish": {
    "en": "Finish",
    "es": "Terminar",
    "he": "סיים",
    "de": "Fertig",
    "fr": "Terminer",
  },
  "reopen": {
    "en": "Reopen",
    "es": "Reabrir",
    "he": "פתח מחדש",
    "de": "Öffnen",
    "fr": "Rouvrir",
  },
  "finishTitle": {
    "en": "Finish {x}?",
    "es": "¿Terminar {x}?",
    "he": "לסיים את {x}?",
    "de": "{x} beenden?",
    "fr": "Terminer {x} ?",
  },
  "finishBody": {
    "en":
        "{d} of {t} sets are done. The {n} unchecked sets were not performed and won't be saved.",
    "es":
        "{d} de {t} series hechas. Las {n} series sin marcar no se realizaron y no se guardarán.",
    "he": "{d} מתוך {t} סטים בוצעו. {n} הסטים שלא סומנו לא בוצעו ולא יישמרו.",
    "de":
        "{d} von {t} Sätzen erledigt. Die {n} nicht abgehakten Sätze wurden nicht ausgeführt und werden nicht gespeichert.",
    "fr":
        "{d} séries sur {t} faites. Les {n} séries non cochées n'ont pas été réalisées et ne seront pas enregistrées.",
  },
  "finishBodyNone": {
    "en": "No sets are checked. Nothing from this exercise will be saved.",
    "es": "Ninguna serie está marcada. No se guardará nada de este ejercicio.",
    "he": "אף סט לא סומן. שום דבר מהתרגיל הזה לא יישמר.",
    "de": "Kein Satz ist abgehakt. Von dieser Übung wird nichts gespeichert.",
    "fr": "Aucune série cochée. Rien de cet exercice ne sera enregistré.",
  },
  "finishSkip": {
    "en": "Finish · skip {n}",
    "es": "Terminar · omitir {n}",
    "he": "סיים · דלג על {n}",
    "de": "Fertig · {n} überspringen",
    "fr": "Terminer · passer {n}",
  },
  "keepGoing": {
    "en": "Keep going",
    "es": "Seguir",
    "he": "המשך",
    "de": "Weitermachen",
    "fr": "Continuer",
  },
  "set": {
    "en": "Set {n}",
    "es": "Serie {n}",
    "he": "סט {n}",
    "de": "Satz {n}",
    "fr": "Série {n}",
  },
  "saved": {
    "en": "saved",
    "es": "guardada",
    "he": "נשמר",
    "de": "gespeichert",
    "fr": "enregistrée",
  },
  "skipped": {
    "en": "skipped",
    "es": "omitida",
    "he": "דולג",
    "de": "übersprungen",
    "fr": "passée",
  },
  "exercise": {
    "en": "exercise",
    "es": "ejercicio",
    "he": "התרגיל",
    "de": "Übung",
    "fr": "l'exercice",
  },
};

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _ExerciseFinishButtonState extends State<ExerciseFinishButton> {
  bool _down = false;
  bool _sheetOpen = false;

  // ---------- localization ----------
  String get _lang {
    try {
      final l = FFLocalizations.of(context).languageCode.trim().toLowerCase();
      final b = l.split('_').first;
      return b.isEmpty ? 'en' : b;
    } catch (_) {
      return 'en';
    }
  }

  bool get _isRtl => _kRtl.contains(_lang);

  String _t(String key, {int? n, int? d, int? t, String? x}) {
    final m = _kStrings[key];
    var s = m == null ? key : (m[_lang] ?? m['en'] ?? key);
    if (n != null) s = s.replaceAll('{n}', '$n');
    if (d != null) s = s.replaceAll('{d}', '$d');
    if (t != null) s = s.replaceAll('{t}', '$t');
    if (x != null) s = s.replaceAll('{x}', x);
    return s;
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

  // ---------- helpers ----------
  static int? _int(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static bool _bool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v == 1;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }

  static Map<String, dynamic> _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  // ---------- data views ----------
  bool get _isComplete {
    for (final e in widget.completedExercises) {
      final m = _map(e);
      if (_int(m['exerciseId']) == widget.exerciseId) {
        return _bool(m['isComplete']);
      }
    }
    return false;
  }

  /// Template sets for this exercise, sorted by setNumber.
  List<Map<String, dynamic>> get _templateSets {
    for (final e in widget.exerciseSets) {
      final m = _map(e);
      if (_int(m['exerciseId']) != widget.exerciseId) continue;
      final raw = m['sets'];
      if (raw is! List) return const [];
      final out = raw.map(_map).toList()
        ..sort((a, b) =>
            (_int(a['setNumber']) ?? 0).compareTo(_int(b['setNumber']) ?? 0));
      return out;
    }
    return const [];
  }

  /// Logged entry for a set number, if any.
  Map<String, dynamic>? _logged(int setNumber) {
    for (final e in widget.loggedSets) {
      final m = _map(e);
      if (_int(m['exerciseId']) == widget.exerciseId &&
          _int(m['setNumber']) == setNumber) {
        return m;
      }
    }
    return null;
  }

  String _name() {
    final n = (widget.exerciseName ?? '').trim();
    if (n.isNotEmpty) return n;
    for (final e in widget.exerciseSets) {
      final m = _map(e);
      if (_int(m['exerciseId']) == widget.exerciseId) {
        final s = (m['exerciseName'] ?? '').toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return _t('exercise');
  }

  static String _fmtW(double w) =>
      w == w.roundToDouble() ? w.toInt().toString() : w.toStringAsFixed(1);

  /// "10 × 80 kg" / "12" / "45s" / "—"
  String _setLabel(Map<String, dynamic> tpl, Map<String, dynamic>? log) {
    final timeBased = _int(tpl['timerMode']) == 2;
    final weighted = _bool(tpl['weighted']);
    if (timeBased) {
      final ms = _int(log?['durationMs']) ?? 0;
      if (ms > 0) return '${(ms / 1000).round()}s';
      final s = _int(tpl['durationSeconds']);
      return s != null && s > 0 ? '${s}s' : '—';
    }
    final reps = _int(log?['reps']);
    final weight = _dbl(log?['weight']);
    if (reps == null && weight == null) {
      final tr = (tpl['targetReps'] ?? '').toString().trim();
      return tr.isEmpty ? '—' : tr;
    }
    final r = reps?.toString() ?? '—';
    if (!weighted || weight == null) return r;
    return '$r × ${_fmtW(weight)} kg';
  }

  // ---------- mutation (pure: copy, touch only this exercise) ----------
  List<dynamic> _withComplete(bool complete) {
    final out = widget.completedExercises
        .map((e) => e is Map ? Map<String, dynamic>.from(e) : e)
        .toList();
    final idx = out.indexWhere(
        (e) => e is Map && _int(e['exerciseId']) == widget.exerciseId);
    if (idx >= 0) {
      (out[idx] as Map<String, dynamic>)['isComplete'] = complete;
    } else {
      out.add(<String, dynamic>{
        'exerciseId': widget.exerciseId,
        'isComplete': complete,
      });
    }
    return out;
  }

  Future<void> _apply({required bool complete}) async {
    HapticFeedback.mediumImpact();
    await widget.onApply?.call(_withComplete(complete));
  }

  // ---------- tap ----------
  Future<void> _onTap() async {
    if (_isComplete) {
      await _apply(complete: false);
      return;
    }
    final tpl = _templateSets;
    final total = tpl.length;
    int done = 0;
    for (final s in tpl) {
      final sn = _int(s['setNumber']);
      if (sn != null && _bool(_logged(sn)?['isDone'])) done++;
    }
    final pending = total - done;

    if (total == 0 || pending == 0) {
      await _apply(complete: true);
      return;
    }
    await _openSheet(tpl, done, total, pending);
  }

  Future<void> _openSheet(
      List<Map<String, dynamic>> tpl, int done, int total, int pending) async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    FocusScope.of(context).unfocus();
    final th = FlutterFlowTheme.of(context);
    final name = _name();

    final rows = <_Row>[
      for (final s in tpl)
        _Row(
          label: _t('set', n: _int(s['setNumber']) ?? 0),
          value: _setLabel(s, _logged(_int(s['setNumber']) ?? -1)),
          done: _bool(_logged(_int(s['setNumber']) ?? -1)?['isDone']),
        ),
    ];

    final bool? confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: _isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: _FinishSheet(
          title: _t('finishTitle', x: name),
          body: done == 0
              ? _t('finishBodyNone')
              : _t('finishBody', d: done, t: total, n: pending),
          rows: rows,
          primaryLabel: _t('finishSkip', n: pending),
          secondaryLabel: _t('keepGoing'),
          savedLabel: _t('saved'),
          skippedLabel: _t('skipped'),
          style: _ts,
          theme: th,
        ),
      ),
    );
    _sheetOpen = false;
    if (confirm == true && mounted) await _apply(complete: true);
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final complete = _isComplete;
    final label = complete ? _t('reopen') : _t('finish');
    final icon = complete ? Icons.undo_rounded : Icons.check_rounded;

    final Widget pill = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      height: 34,
      padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 12, 0),
      decoration: BoxDecoration(
        color: complete ? th.secondaryBackground : th.primary,
        borderRadius: BorderRadius.circular(17),
        border: complete ? Border.all(color: th.alternate, width: 1.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: complete ? th.primaryText : Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: _ts(
                13, FontWeight.w600, complete ? th.primaryText : Colors.white),
          ),
        ],
      ),
    );

    return Directionality(
      textDirection: _isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _down = true),
            onTapCancel: () => setState(() => _down = false),
            onTapUp: (_) => setState(() => _down = false),
            onTap: _onTap,
            child: AnimatedScale(
              scale: _down ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 110),
              child: pill,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet
// ---------------------------------------------------------------------------

class _Row {
  const _Row({required this.label, required this.value, required this.done});
  final String label;
  final String value;
  final bool done;
}

class _FinishSheet extends StatelessWidget {
  const _FinishSheet({
    required this.title,
    required this.body,
    required this.rows,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.savedLabel,
    required this.skippedLabel,
    required this.style,
    required this.theme,
  });

  final String title;
  final String body;
  final List<_Row> rows;
  final String primaryLabel;
  final String secondaryLabel;
  final String savedLabel;
  final String skippedLabel;
  final TextStyle Function(double, FontWeight, Color) style;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    final th = theme;
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double maxH = MediaQuery.of(context).size.height * 0.8;
    final Color muted = th.secondaryText;
    final Color faint = Color.alphaBlend(
        th.secondaryText.withOpacity(0.55), th.secondaryBackground);
    final Color sub = Color.alphaBlend(
        th.primaryText.withOpacity(0.05), th.secondaryBackground);

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: th.secondaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: th.alternate,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(title, style: style(18, FontWeight.w700, th.primaryText)),
          const SizedBox(height: 6),
          Text(body,
              style: style(14, FontWeight.w400, muted).copyWith(height: 1.45)),
          const SizedBox(height: 16),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: sub,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final r in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(r.label,
                                style: style(13, FontWeight.w400,
                                    r.done ? muted : faint)),
                          ),
                          Text(
                            r.value,
                            style: style(13, FontWeight.w600,
                                    r.done ? th.primaryText : faint)
                                .copyWith(
                              decoration: r.done
                                  ? TextDecoration.none
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 84,
                            child: Text(
                              r.done ? savedLabel : skippedLabel,
                              textAlign: TextAlign.end,
                              style: style(13, FontWeight.w600,
                                  r.done ? th.primary : faint),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SheetButton(
            label: primaryLabel,
            filled: true,
            theme: th,
            style: style,
            onTap: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 8),
          _SheetButton(
            label: secondaryLabel,
            filled: false,
            theme: th,
            style: style,
            onTap: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.filled,
    required this.theme,
    required this.style,
    required this.onTap,
  });
  final String label;
  final bool filled;
  final FlutterFlowTheme theme;
  final TextStyle Function(double, FontWeight, Color) style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final th = theme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? th.primary : th.secondaryBackground,
          borderRadius: BorderRadius.circular(14),
          border: filled ? null : Border.all(color: th.alternate, width: 1.5),
        ),
        child: Text(
          label,
          style: style(
              15, FontWeight.w600, filled ? Colors.white : th.primaryText),
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
