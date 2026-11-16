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
  "appearance": {
    "en": "Appearance",
    "es": "Apariencia",
    "he": "מראה",
    "de": "Darstellung",
    "fr": "Apparence"
  },
  "system": {
    "en": "System",
    "es": "Sistema",
    "he": "לפי המכשיר",
    "de": "System",
    "fr": "Système"
  },
  "light": {
    "en": "Light",
    "es": "Claro",
    "he": "בהיר",
    "de": "Hell",
    "fr": "Clair"
  },
  "dark": {
    "en": "Dark",
    "es": "Oscuro",
    "he": "כהה",
    "de": "Dunkel",
    "fr": "Sombre"
  },
  "done": {
    "en": "Done",
    "es": "Listo",
    "he": "סיום",
    "de": "Fertig",
    "fr": "OK"
  },
};

String _tr(String lang, String key) {
  final m = _kStrings[key];
  return m == null ? key : (m[lang] ?? m['en'] ?? key);
}

String _modeKey(ThemeMode m) {
  switch (m) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    default:
      return 'system';
  }
}

/// Settings row "Appearance · Light ›".
///
/// No outer padding - drop it in the same Container as the other preference
/// rows. Tap opens a bottom sheet with System / Light / Dark.
///
/// A pick switches the app theme itself and stores it (FlutterFlow's own
/// mechanism, same as the "Set Dark Mode Settings" action), so it survives a
/// restart. No parameters and no callbacks.
///
/// Localization: reads the app language from FFLocalizations. Hebrew renders
/// RTL.
class ThemeRow extends StatefulWidget {
  const ThemeRow({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<ThemeRow> createState() => _ThemeRowState();
}

class _ThemeRowState extends State<ThemeRow> {
  ThemeMode get _mode {
    try {
      return FlutterFlowTheme.themeMode;
    } catch (_) {
      return ThemeMode.system;
    }
  }

  void _apply(ThemeMode mode) {
    try {
      setDarkModeSetting(context, mode);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _openSheet() async {
    HapticFeedback.selectionClick();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ThemeSheet(
        selected: _mode,
        onPick: (mode) {
          Navigator.of(context).pop();
          _apply(mode);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);

    TextStyle st(Color c) => theme.bodyMedium.override(
          fontFamily: theme.bodyMediumFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: c,
          letterSpacing: 0,
          useGoogleFonts:
              GoogleFonts.asMap().containsKey(theme.bodyMediumFamily),
        );

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openSheet,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.brightness_6_outlined,
                  size: 24, color: theme.secondaryText),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _tr(lang, 'appearance'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: st(theme.primaryText),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                _tr(lang, _modeKey(_mode)),
                style: st(theme.secondaryText),
              ),
              const SizedBox(width: 8),
              // Same chevron as the other FF rows, in every language.
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: theme.primaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet
// ---------------------------------------------------------------------------

class _ThemeSheet extends StatelessWidget {
  const _ThemeSheet({required this.selected, required this.onPick});
  final ThemeMode selected;
  final void Function(ThemeMode mode) onPick;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);
    final double bottom = MediaQuery.of(context).padding.bottom;

    TextStyle title(Color c, {FontWeight w = FontWeight.w400}) =>
        theme.bodyMedium.override(
          fontFamily: theme.bodyMediumFamily,
          fontSize: 16,
          fontWeight: w,
          color: c,
          letterSpacing: 0,
          useGoogleFonts:
              GoogleFonts.asMap().containsKey(theme.bodyMediumFamily),
        );

    Widget check(bool on) => Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? theme.primary : Colors.transparent,
            border: on ? null : Border.all(color: theme.alternate, width: 2),
          ),
          child: on
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : null,
        );

    Widget row(ThemeMode mode, IconData icon) {
      final bool on = mode == selected;
      return InkWell(
        onTap: () => onPick(mode),
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(icon, size: 22, color: theme.secondaryText),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _tr(lang, _modeKey(mode)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: title(theme.primaryText,
                        w: on ? FontWeight.w600 : FontWeight.w400),
                  ),
                ),
                const SizedBox(width: 12),
                check(on),
              ],
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: EdgeInsets.only(top: 10, bottom: 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.alternate,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _tr(lang, 'appearance'),
                      style: theme.headlineSmall.override(
                        fontFamily: theme.headlineSmallFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                        useGoogleFonts: GoogleFonts.asMap()
                            .containsKey(theme.headlineSmallFamily),
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(_tr(lang, 'done'),
                          style: title(theme.primary, w: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ),
            row(ThemeMode.system, Icons.phone_iphone_rounded),
            row(ThemeMode.light, Icons.light_mode_outlined),
            row(ThemeMode.dark, Icons.dark_mode_outlined),
          ],
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
