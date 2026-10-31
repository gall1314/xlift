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

/// Rest-time button: a rounded, lightly tinted box holding [timer icon] Rest:
/// 02:00  [chevron].
///
/// The whole box is the tap target (min 44pt tall).
///
/// Time text comes from the existing custom function
/// formatExerciseRestTime(exerciseRestTimes, exerciseId) — same ms → mm:ss
/// logic, same "Off" for 0 (translated here), same 1:30 default.
///
/// Localization: reads the app language from FFLocalizations (no parameter).
/// Hebrew renders RTL; the mm:ss value itself stays LTR.
///
/// Press feedback: background darkens + slight shrink. [onTap] fires on
/// release (tap or long-press).
class RestTimeButton extends StatefulWidget {
  const RestTimeButton({
    super.key,
    this.width,
    this.height,
    required this.exerciseRestTimes,
    required this.exerciseId,
    this.textColor,
    this.fontSize,
    this.onTap,
  });

  final double? width;
  final double? height;
  final dynamic exerciseRestTimes;
  final int exerciseId;
  final Color? textColor;
  final double? fontSize;
  final Future Function()? onTap;

  @override
  State<RestTimeButton> createState() => _RestTimeButtonState();
}

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
  "rest": {
    "en": "Rest:",
    "es": "Descanso:",
    "he": "מנוחה:",
    "de": "Pause:",
    "fr": "Repos :"
  },
  "off": {"en": "Off", "es": "No", "he": "כבוי", "de": "Aus", "fr": "Off"},
  "restTime": {
    "en": "Rest time",
    "es": "Tiempo de descanso",
    "he": "זמן מנוחה",
    "de": "Pausenzeit",
    "fr": "Temps de repos"
  },
};

String _tr(String lang, String key) {
  final m = _kStrings[key];
  return m == null ? key : (m[lang] ?? m['en'] ?? key);
}

class _RestTimeButtonState extends State<RestTimeButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  String _label(String lang) {
    String s;
    try {
      s = formatExerciseRestTime(widget.exerciseRestTimes, widget.exerciseId);
    } catch (_) {
      return '01:30';
    }
    if (s.trim().toLowerCase() == 'off') return _tr(lang, 'off');
    return s;
  }

  void _fire() {
    _setPressed(false);
    HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);
    final Color color = widget.textColor ?? theme.primary;
    final double fs = widget.fontSize ?? 17;
    final String label = _label(lang);

    TextStyle textStyle(FontWeight w) => theme.bodyLarge.override(
          fontFamily: theme.bodyLargeFamily,
          color: color,
          fontSize: fs,
          fontWeight: w,
          useGoogleFonts:
              GoogleFonts.asMap().containsKey(theme.bodyLargeFamily),
        );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.timer_outlined, size: fs + 4, color: color),
        SizedBox(width: fs * 0.45),
        Text(_tr(lang, 'rest'), style: textStyle(FontWeight.w400)),
        SizedBox(width: fs * 0.5),
        Text(
          label,
          textDirection: ui.TextDirection.ltr,
          style: textStyle(FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.clip,
        ),
        SizedBox(width: fs * 0.2),
        Icon(Icons.keyboard_arrow_down_rounded, size: fs + 4, color: color),
      ],
    );

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      constraints: BoxConstraints(minHeight: widget.height ?? 44),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: color.withOpacity(_pressed ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Semantics(
        button: true,
        label: '${_tr(lang, 'restTime')} $label',
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: widget.width == null ? 1 : null,
          heightFactor: 1,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _setPressed(true),
            onTapCancel: () => _setPressed(false),
            onTapUp: (_) => _fire(),
            onLongPressStart: (_) => _setPressed(true),
            onLongPressEnd: (_) => _fire(),
            onLongPressCancel: () => _setPressed(false),
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: button,
            ),
          ),
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
