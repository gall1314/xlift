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

/// Bottom sheet shown when a free user has no custom exercises left.
///
/// Self-contained like WorkoutBreakdownSheet: the sheet background, rounded
/// top, grab handle and the content. Sizes itself to its content; tapping
/// outside it closes it. Put it in a bottom sheet with a transparent
/// background.
///
///  - [limit]: how many custom exercises the free plan includes (default 3).
///  - [onUpgrade]: the main button. Open the Pro page here (close the sheet
///    first in the same action if you want it gone). Not connected = the
///    button only closes the sheet.
///  - [onClose]: called after "Maybe later" closes the sheet (optional).
///
/// Localization: reads the app language from FFLocalizations (no parameter).
class CustomExerciseLimitSheet extends StatefulWidget {
  const CustomExerciseLimitSheet({
    super.key,
    this.width,
    this.height,
    this.limit,
    this.onUpgrade,
    this.onClose,
  });

  final double? width;
  final double? height; // ignored - the sheet sizes itself to its content
  final int? limit;
  final Future Function()? onUpgrade;
  final Future Function()? onClose;

  @override
  State<CustomExerciseLimitSheet> createState() =>
      _CustomExerciseLimitSheetState();
}

// ---------------------------------------------------------------------------
// Localization (order: en, es, he, de, fr)
// ---------------------------------------------------------------------------

const Set<String> _kRtl = {'he', 'ar'};
const List<String> _kLangs = ['en', 'es', 'he', 'de', 'fr'];

const Map<String, List<String>> _kS = {
  'title': [
    "You're out of free custom exercises",
    'Ya no te quedan ejercicios propios gratis',
    'נגמרו התרגילים המותאמים בחינם',
    'Keine kostenlosen eigenen Übungen mehr',
    "Plus d'exercices perso gratuits",
  ],
  'body': [
    'The free plan includes {n}. Go Pro for unlimited, or delete one to free a spot.',
    'El plan gratis incluye {n}. Con Pro no hay límite, o elimina uno para liberar un lugar.',
    'בחינם יש {n}. ב-Pro אין הגבלה, ואפשר גם למחוק תרגיל קיים כדי לפנות מקום.',
    'Kostenlos sind {n} enthalten. Mit Pro unbegrenzt, oder lösche eine, um Platz zu schaffen.',
    "L'offre gratuite en inclut {n}. Illimité avec Pro, ou supprimes-en un pour libérer une place.",
  ],
  'upgrade': [
    'Go Pro',
    'Pasar a Pro',
    'שדרוג ל-Pro',
    'Pro holen',
    'Passer à Pro',
  ],
  'later': [
    'Maybe later',
    'Quizá más tarde',
    'אולי אחר כך',
    'Vielleicht später',
    'Plus tard',
  ],
};

String _tr(String lang, String key, [Map<String, String>? vars]) {
  final List<String>? row = _kS[key];
  if (row == null) return key;
  final int i = _kLangs.indexOf(lang);
  String s = row[i < 0 ? 0 : i];
  if (vars != null) {
    vars.forEach((k, v) {
      s = s.replaceAll('{' + k + '}', v);
    });
  }
  return s;
}

String _langOf(BuildContext ctx) {
  try {
    final l = FFLocalizations.of(ctx).languageCode.trim().toLowerCase();
    return l.isEmpty ? 'en' : l;
  } catch (_) {
    return 'en';
  }
}

/// Theme text style at a real font weight (a Google Font is one file per
/// weight; the family is read from the theme style: "Inter_regular").
TextStyle _ts(BuildContext ctx, double size, FontWeight w, Color c,
    {double? height, double ls = 0}) {
  final TextStyle base = FlutterFlowTheme.of(ctx).bodyMedium;
  TextStyle s = base.copyWith(fontWeight: w);
  try {
    final String ff = base.fontFamily ?? '';
    final int cut = ff.lastIndexOf('_');
    final List<String> names = [cut > 0 ? ff.substring(0, cut) : ff];
    final List<String>? fallback = base.fontFamilyFallback;
    if (fallback != null && fallback.isNotEmpty) names.add(fallback.first);
    for (final String fam in names) {
      if (fam.isNotEmpty && GoogleFonts.asMap().containsKey(fam)) {
        s = GoogleFonts.getFont(fam, textStyle: base, fontWeight: w);
        break;
      }
    }
  } catch (_) {
    // Keep the plain theme style.
  }
  return s.copyWith(
    fontSize: size,
    color: c,
    height: height,
    letterSpacing: ls,
  );
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class _CustomExerciseLimitSheetState extends State<CustomExerciseLimitSheet> {
  Future<void> _close() async {
    await Navigator.of(context).maybePop();
  }

  Future<void> _later() async {
    HapticFeedback.selectionClick();
    final Future Function()? after = widget.onClose;
    await _close();
    if (after != null) after();
  }

  Future<void> _upgrade() async {
    HapticFeedback.selectionClick();
    if (widget.onUpgrade != null) {
      widget.onUpgrade?.call();
    } else {
      await _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);
    final FlutterFlowTheme th = FlutterFlowTheme.of(context);
    final Color primary = th.primary;
    final Color sheet = th.secondaryBackground;
    final Color ink = th.primaryText;
    final Color soft = th.secondaryText;
    final bool light = sheet.computeLuminance() > 0.5;
    final Color mint =
        Color.alphaBlend(primary.withAlpha(light ? 0x2E : 0x40), sheet);
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final int limit = (widget.limit ?? 3) < 1 ? 3 : (widget.limit ?? 3);

    final Widget sheetBox = Container(
      width: widget.width ?? double.infinity,
      decoration: BoxDecoration(
        color: sheet,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ink.withAlpha(38),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 26),
          // Lock on a soft tint of the brand colour, with the plan's limit.
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: mint,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(Icons.lock_rounded, color: primary, size: 30),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: mint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              limit.toString() + ' / ' + limit.toString(),
              textDirection: ui.TextDirection.ltr,
              style: _ts(context, 12, FontWeight.w700, primary, height: 1.2),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _tr(lang, 'title'),
            textAlign: TextAlign.center,
            style: _ts(context, 22, FontWeight.w700, ink,
                height: 1.2, ls: rtl ? 0 : -0.3),
          ),
          const SizedBox(height: 10),
          Text(
            _tr(lang, 'body', {'n': limit.toString()}),
            textAlign: TextAlign.center,
            style: _ts(context, 14.5, FontWeight.w400, soft, height: 1.45),
          ),
          const SizedBox(height: 24),
          Material(
            color: primary,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _upgrade,
              child: Container(
                height: 52,
                width: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _tr(lang, 'upgrade'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _ts(context, 16, FontWeight.w700, Colors.white,
                      height: 1.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _later,
            child: Container(
              height: 46,
              width: double.infinity,
              alignment: Alignment.center,
              child: Text(
                _tr(lang, 'later'),
                style: _ts(context, 14.5, FontWeight.w500, soft, height: 1.2),
              ),
            ),
          ),
        ],
      ),
    );

    return MediaQuery.withNoTextScaling(
      child: Directionality(
        textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _close,
                  child: const SizedBox.expand(),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: sheetBox,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
