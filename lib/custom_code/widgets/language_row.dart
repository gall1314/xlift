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

import 'dart:ui' as ui show TextDirection, PlatformDispatcher;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Languages
// ---------------------------------------------------------------------------

class AppLanguage {
  const AppLanguage(this.code, this.nativeName, this.englishName,
      {this.enabled = true});
  final String code;
  final String nativeName;
  final String englishName;
  final bool enabled;
}

/// All shipped. To pull one back, add `enabled: false`. Every enabled code
/// must also exist in FF → Settings → Languages.
const List<AppLanguage> kAppLanguages = [
  AppLanguage('en', 'English', 'English'),
  AppLanguage('es', 'Español', 'Spanish'),
  AppLanguage('he', 'עברית', 'Hebrew'),
  AppLanguage('de', 'Deutsch', 'German'),
  AppLanguage('fr', 'Français', 'French'),
];

List<AppLanguage> get kEnabledLanguages =>
    kAppLanguages.where((l) => l.enabled).toList();

AppLanguage? languageByCode(String? code) {
  if (code == null) return null;
  final c = code.trim().toLowerCase();
  for (final l in kAppLanguages) {
    if (l.code == c) return l;
  }
  return null;
}

/// The phone's language if we ship it, else null.
AppLanguage? deviceLanguageIfSupported() {
  try {
    final locale = ui.PlatformDispatcher.instance.locale;
    final l = languageByCode(locale.languageCode);
    return (l != null && l.enabled) ? l : null;
  } catch (_) {
    return null;
  }
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
  "language": {
    "en": "Language",
    "es": "Idioma",
    "he": "שפה",
    "de": "Sprache",
    "fr": "Langue"
  },
  "device": {
    "en": "Device language",
    "es": "Idioma del dispositivo",
    "he": "שפת המכשיר",
    "de": "Gerätesprache",
    "fr": "Langue de l'appareil"
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

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Settings row "Language · English ›".
///
/// No outer padding — drop it in the same Container as the other preference
/// rows. Tap opens a bottom sheet with "Device language" (only when the
/// phone's language is one we ship) followed by every enabled language.
///
/// A pick switches the app language itself AND stores it (so it survives a
/// restart), then fires the matching callback for anything extra you want to
/// do (saving to the profile, say). The callbacks may stay empty.
class LanguageRow extends StatefulWidget {
  const LanguageRow({
    super.key,
    this.width,
    this.height,
    this.onEnglish,
    this.onSpanish,
    this.onHebrew,
    this.onGerman,
    this.onFrench,
  });

  final double? width;
  final double? height;
  final Future Function()? onEnglish;
  final Future Function()? onSpanish;
  final Future Function()? onHebrew;
  final Future Function()? onGerman;
  final Future Function()? onFrench;

  @override
  State<LanguageRow> createState() => _LanguageRowState();
}

class _LanguageRowState extends State<LanguageRow> {
  Future<void> _apply(String code) async {
    // 1. switch + persist (FF's own mechanism, same as "Set App Language")
    try {
      setAppLanguage(context, code);
    } catch (_) {}
    try {
      await FFLocalizations.storeLocale(code);
    } catch (_) {}
    // 2. anything extra wired in FF
    switch (code) {
      case 'en':
        await widget.onEnglish?.call();
        break;
      case 'es':
        await widget.onSpanish?.call();
        break;
      case 'he':
        await widget.onHebrew?.call();
        break;
      case 'de':
        await widget.onGerman?.call();
        break;
      case 'fr':
        await widget.onFrench?.call();
        break;
    }
  }

  Future<void> _openSheet() async {
    HapticFeedback.selectionClick();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LanguageSheet(
        onPick: (code) async {
          Navigator.of(context).pop();
          await _apply(code);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);
    final AppLanguage current = languageByCode(lang) ?? kAppLanguages.first;

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
              Icon(Icons.language_rounded, size: 24, color: theme.primaryText),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _tr(lang, 'language'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium.override(
                    fontFamily: theme.bodyMediumFamily,
                    fontSize: 16,
                    useGoogleFonts:
                        GoogleFonts.asMap().containsKey(theme.bodyMediumFamily),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                current.nativeName,
                style: theme.bodyMedium.override(
                  fontFamily: theme.bodyMediumFamily,
                  fontSize: 16,
                  color: theme.secondaryText,
                  useGoogleFonts:
                      GoogleFonts.asMap().containsKey(theme.bodyMediumFamily),
                ),
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

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.onPick});
  final Future<void> Function(String code) onPick;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);
    final AppLanguage? device = deviceLanguageIfSupported();
    final List<AppLanguage> langs = kEnabledLanguages;
    final double bottom = MediaQuery.of(context).padding.bottom;

    TextStyle title(Color c, {FontWeight w = FontWeight.w400}) =>
        theme.bodyMedium.override(
          fontFamily: theme.bodyMediumFamily,
          fontSize: 16,
          fontWeight: w,
          color: c,
          useGoogleFonts:
              GoogleFonts.asMap().containsKey(theme.bodyMediumFamily),
        );
    TextStyle sub() => theme.bodySmall.override(
          fontFamily: theme.bodySmallFamily,
          fontSize: 13,
          color: theme.secondaryText,
          useGoogleFonts:
              GoogleFonts.asMap().containsKey(theme.bodySmallFamily),
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

    Widget row({
      required String main,
      required String secondary,
      required bool selected,
      required VoidCallback onTap,
    }) =>
        InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(main,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: title(theme.primaryText,
                                w: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400)),
                        const SizedBox(height: 2),
                        Text(secondary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: sub()),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  check(selected),
                ],
              ),
            ),
          ),
        );

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
                      _tr(lang, 'language'),
                      style: theme.headlineSmall.override(
                        fontFamily: theme.headlineSmallFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
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
            if (device != null) ...[
              row(
                main: _tr(lang, 'device'),
                secondary: device.nativeName,
                selected: false,
                onTap: () => onPick(device.code),
              ),
              Divider(height: 1, thickness: 1, color: theme.alternate),
            ],
            for (final l in langs)
              row(
                main: l.nativeName,
                secondary: l.englishName,
                selected: l.code == lang,
                onTap: () => onPick(l.code),
              ),
          ],
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
