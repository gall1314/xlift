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

import 'dart:ui' as ui show TextDirection;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// =============================================================================
// RemoveAnalysisAlert — the "delete this analysis?" card, in five languages.
//
// Two wordings, picked by [isPermanent]:
//   false (default) — editing a logged workout: the removal only happens when
//                     the workout is saved, so nothing is called "permanent".
//   true            — the history screen: the row goes straight away.
//
// Show it inside a Dialog or a Bottom Sheet and wire the two callbacks; the
// widget never pops the route itself, so the caller stays in control.
// onConfirm carries back the exercise and set the analysis belongs to -
// looked up from analysisId when they were not passed in.
// Give it width ∞ and height ∞ in FF.
// =============================================================================

const Set<String> _kRtl = {'he', 'ar'};

String _langOf(BuildContext ctx) {
  try {
    final l = FFLocalizations.of(ctx).languageCode.trim().toLowerCase();
    return l.isEmpty ? 'en' : l;
  } catch (_) {
    return 'en';
  }
}

const Map<String, Map<String, String>> _kStrings = {
  // pending (edit) wording
  "titlePending": {
    "en": "Remove this analysis?",
    "es": "¿Quitar este análisis?",
    "he": "להסיר את הניתוח?",
    "de": "Diese Analyse entfernen?",
    "fr": "Supprimer cette analyse ?",
  },
  "bodyPending": {
    "en":
        "The form score and feedback for this set will be removed when you save the workout. Your set itself stays.",
    "es":
        "La puntuación de técnica y los comentarios de esta serie se quitarán al guardar el entreno. La serie se mantiene.",
    "he":
        "ציון הטכניקה והמשוב לסט הזה יימחקו כשתשמור את האימון. הסט עצמו יישאר.",
    "de":
        "Technikwertung und Feedback dieses Satzes werden entfernt, sobald du das Workout speicherst. Der Satz selbst bleibt.",
    "fr":
        "La note technique et les retours de cette série seront supprimés à l’enregistrement de la séance. La série, elle, reste.",
  },
  "confirmPending": {
    "en": "Remove",
    "es": "Quitar",
    "he": "הסר",
    "de": "Entfernen",
    "fr": "Supprimer",
  },
  // permanent (history) wording
  "titlePermanent": {
    "en": "Delete this analysis?",
    "es": "¿Eliminar este análisis?",
    "he": "למחוק את הניתוח?",
    "de": "Diese Analyse löschen?",
    "fr": "Supprimer cette analyse ?",
  },
  "bodyPermanent": {
    "en":
        "This permanently removes the form score and feedback for this set. Your set stays in history.",
    "es":
        "Esto elimina definitivamente la puntuación de técnica y los comentarios de esta serie. La serie permanece en el historial.",
    "he":
        "פעולה זו מוחקת לצמיתות את ציון הטכניקה והמשוב לסט הזה. הסט יישאר בהיסטוריה.",
    "de":
        "Das löscht Technikwertung und Feedback dieses Satzes endgültig. Der Satz bleibt im Verlauf.",
    "fr":
        "Cela supprime définitivement la note technique et les retours de cette série. La série reste dans l’historique.",
  },
  "confirmPermanent": {
    "en": "Delete",
    "es": "Eliminar",
    "he": "מחק",
    "de": "Löschen",
    "fr": "Supprimer",
  },
  "cancel": {
    "en": "Cancel",
    "es": "Cancelar",
    "he": "ביטול",
    "de": "Abbrechen",
    "fr": "Annuler",
  },
};

String _tr(String lang, String key) {
  final m = _kStrings[key];
  return m == null ? key : (m[lang] ?? m['en'] ?? key);
}

class RemoveAnalysisAlert extends StatefulWidget {
  const RemoveAnalysisAlert({
    super.key,
    this.width,
    this.height,
    this.isPermanent = false,
    this.analysisId,
    this.exerciseId,
    this.setNumber,
    this.onCancel,
    this.onConfirm,
  });

  final double? width;
  final double? height;

  /// true → the history wording ("permanently"). false → the edit wording
  /// ("when you save the workout").
  final bool isPermanent;

  /// Which set this is about. Pass whichever you have:
  ///
  ///   analysisId  — the set_analysis row; the widget looks the set up
  ///                 itself (SELECT through set_log) when confirmed.
  ///   exerciseId + setNumber — already known, used as-is and no query runs.
  ///
  /// Either way onConfirm hands both numbers back, so the caller can feed
  /// removeAnalysisFromState straight from the callback.
  final String? analysisId;
  final int? exerciseId;
  final int? setNumber;

  final Future Function()? onCancel;
  final Future Function(int exerciseId, int setNumber)? onConfirm;

  @override
  State<RemoveAnalysisAlert> createState() => _RemoveAnalysisAlertState();
}

class _RemoveAnalysisAlertState extends State<RemoveAnalysisAlert> {
  bool _busy = false;

  /// Resolves the set behind the analysis, then reports back once.
  Future<void> _confirm() async {
    if (_busy) return;
    final cb = widget.onConfirm;
    if (cb == null) return;

    int ex = widget.exerciseId ?? 0;
    int sn = widget.setNumber ?? 0;

    final String aId = (widget.analysisId ?? '').trim();
    if ((ex <= 0 || sn <= 0) && aId.isNotEmpty) {
      setState(() => _busy = true);
      try {
        final List rows = await SQLiteManager.instance.database.rawQuery(
          'SELECT s.exercise_id AS ex, s.set_number AS sn '
          'FROM set_analysis a '
          'INNER JOIN set_log s ON s.id = a.set_log_id '
          'WHERE a.id = ? LIMIT 1',
          [aId],
        );
        if (rows.isNotEmpty && rows.first is Map) {
          final Map r = rows.first as Map;
          int toInt(dynamic v) {
            if (v is int) return v;
            if (v is num) return v.toInt();
            return int.tryParse(v == null ? '' : v.toString()) ?? 0;
          }

          ex = toInt(r['ex']);
          sn = toInt(r['sn']);
        }
      } catch (_) {
        // fall through with whatever we had - the caller still gets a call
      }
      if (!mounted) return;
      setState(() => _busy = false);
    }

    await cb(ex, sn);
  }

  static TextStyle _ts(
          FlutterFlowTheme th, double size, FontWeight w, Color c) =>
      th.bodyMedium.override(
        fontFamily: th.bodyMediumFamily,
        color: c,
        fontSize: size,
        fontWeight: w,
        useGoogleFonts: GoogleFonts.asMap().containsKey(th.bodyMediumFamily),
      );

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color border =
        dark ? const Color(0xFF2A3644) : const Color(0xFFE3E7EB);

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Container(
        width: widget.width,
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _tr(lang, widget.isPermanent ? 'titlePermanent' : 'titlePending'),
              textAlign: TextAlign.center,
              style: _ts(theme, 26, FontWeight.w700, theme.primaryText),
            ),
            const SizedBox(height: 12),
            Text(
              _tr(lang, widget.isPermanent ? 'bodyPermanent' : 'bodyPending'),
              textAlign: TextAlign.center,
              style: _ts(theme, 17, FontWeight.w400, theme.secondaryText),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: _Tap(
                    onTap: () => widget.onCancel?.call(),
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.primaryBackground,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: border),
                      ),
                      child: Text(_tr(lang, 'cancel'),
                          maxLines: 1,
                          style: _ts(
                              theme, 18, FontWeight.w600, theme.primaryText)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Tap(
                    onTap: _confirm,
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.primary.withOpacity(_busy ? 0.6 : 1.0),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Text(
                          _tr(
                              lang,
                              widget.isPermanent
                                  ? 'confirmPermanent'
                                  : 'confirmPending'),
                          maxLines: 1,
                          style: _ts(theme, 18, FontWeight.w600, Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tap extends StatefulWidget {
  const _Tap({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;
  @override
  State<_Tap> createState() => _TapState();
}

class _TapState extends State<_Tap> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
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
