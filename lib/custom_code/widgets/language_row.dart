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

/// Single source of truth for supported languages.
/// Flip `enabled` to show/hide a language in the picker.
/// `code` must match the keys in the DB JSON ({"en":..,"es":..}).
class AppLanguage {
  final String code;
  final String nativeName;
  final String englishName;
  final bool enabled;
  const AppLanguage(this.code, this.nativeName, this.englishName,
      {required this.enabled});
}

const List<AppLanguage> kAppLanguages = [
  AppLanguage('en', 'English', 'English', enabled: true),
  AppLanguage('es', 'Español', 'Spanish', enabled: true),
  AppLanguage('he', 'עברית', 'Hebrew', enabled: false),
  AppLanguage('de', 'Deutsch', 'German', enabled: false),
  AppLanguage('fr', 'Français', 'French', enabled: false),
];

/// Device language code (e.g. 'he') if it's one of our *enabled*
/// languages, otherwise 'en'. Use at startup for first-run default.
String deviceLanguageOrEnglish() {
  for (final l in ui.PlatformDispatcher.instance.locales) {
    final code = l.languageCode.toLowerCase();
    if (kAppLanguages.any((a) => a.enabled && a.code == code)) return code;
  }
  return 'en';
}

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

  /// One callback per language. Each should contain "Set App Language"
  /// for that language (plus anything else, e.g. saving to profile).
  final Future Function()? onEnglish;
  final Future Function()? onSpanish;
  final Future Function()? onHebrew;
  final Future Function()? onGerman;
  final Future Function()? onFrench;

  @override
  State<LanguageRow> createState() => _LanguageRowState();
}

class _LanguageRowState extends State<LanguageRow> {
  List<AppLanguage> get _enabled =>
      kAppLanguages.where((l) => l.enabled).toList();

  AppLanguage _current(BuildContext context) {
    final code = FFLocalizations.of(context).languageCode;
    return kAppLanguages.firstWhere(
      (l) => l.code == code,
      orElse: () => kAppLanguages.first,
    );
  }

  Future Function()? _callbackFor(String code) {
    switch (code) {
      case 'en':
        return widget.onEnglish;
      case 'es':
        return widget.onSpanish;
      case 'he':
        return widget.onHebrew;
      case 'de':
        return widget.onGerman;
      case 'fr':
        return widget.onFrench;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return InkWell(
      onTap: () => _openSheet(context),
      child: Container(
        width: widget.width,
        height: widget.height ?? 56,
        padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
        child: Row(
          children: [
            Icon(Icons.language_outlined, size: 22, color: theme.secondaryText),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                'Language',
                style: theme.bodyLarge.override(
                  fontFamily: theme.bodyLargeFamily,
                  fontSize: 16,
                  useGoogleFonts:
                      GoogleFonts.asMap().containsKey(theme.bodyLargeFamily),
                ),
              ),
            ),
            Text(
              _current(context).nativeName,
              style: theme.bodyLarge.override(
                fontFamily: theme.bodyLargeFamily,
                fontSize: 16,
                color: theme.secondaryText,
                useGoogleFonts:
                    GoogleFonts.asMap().containsKey(theme.bodyLargeFamily),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                size: 22, color: theme.secondaryText),
          ],
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final theme = FlutterFlowTheme.of(context);
    String selected = _current(context).code;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Container(
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              padding: EdgeInsets.only(
                top: 10,
                bottom: MediaQuery.of(ctx).padding.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.alternate,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Language',
                            style: theme.headlineSmall.override(
                              fontFamily: theme.headlineSmallFamily,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              useGoogleFonts: GoogleFonts.asMap()
                                  .containsKey(theme.headlineSmallFamily),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            'Done',
                            style: theme.bodyLarge.override(
                              fontFamily: theme.bodyLargeFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: theme.primary,
                              useGoogleFonts: GoogleFonts.asMap()
                                  .containsKey(theme.bodyLargeFamily),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._enabled.map((lang) {
                    final isSelected = lang.code == selected;
                    return InkWell(
                      onTap: () async {
                        setSheet(() => selected = lang.code);
                        await _callbackFor(lang.code)?.call();
                        if (mounted) setState(() {});
                      },
                      child: SizedBox(
                        height: 60,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              24, 0, 24, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang.nativeName,
                                      style: theme.bodyLarge.override(
                                        fontFamily: theme.bodyLargeFamily,
                                        fontSize: 16,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        useGoogleFonts: GoogleFonts.asMap()
                                            .containsKey(theme.bodyLargeFamily),
                                      ),
                                    ),
                                    Text(
                                      lang.englishName,
                                      style: theme.bodySmall.override(
                                        fontFamily: theme.bodySmallFamily,
                                        fontSize: 13,
                                        color: theme.secondaryText,
                                        useGoogleFonts: GoogleFonts.asMap()
                                            .containsKey(theme.bodySmallFamily),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              isSelected
                                  ? Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: theme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check_rounded,
                                          size: 16, color: Colors.white),
                                    )
                                  : Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: theme.alternate, width: 2),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  Padding(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(32, 14, 32, 0),
                    child: Text(
                      'Exercise names and tips switch with the app language. Your own custom exercises stay as you wrote them.',
                      textAlign: TextAlign.center,
                      style: theme.bodySmall.override(
                        fontFamily: theme.bodySmallFamily,
                        fontSize: 12,
                        color: theme.secondaryText,
                        lineHeight: 1.5,
                        useGoogleFonts: GoogleFonts.asMap()
                            .containsKey(theme.bodySmallFamily),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
