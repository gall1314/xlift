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

/// Settings row "Units ›".
///
/// Matches the other settings rows: 24 icon in secondary text color and a 14
/// / regular label in primary text color.
///
/// No outer padding: drop it in the same Container as the other preference
/// rows. Tap opens a bottom sheet with three two-way switches: workout weight
/// (kg / lbs), height (cm / in), body weight (kg / lbs).
///
/// The widget does NOT save anything itself. It shows the current values it
/// is given and fires a callback on every change: - [workoutIsKg],
/// [heightIsCm], [bodyIsKg]: the current values (default true when not set).
/// - [onWorkoutWeightChanged](isKg), [onHeightChanged](isCm),
/// [onBodyWeightChanged](isKg): fired with the new value.
///
/// Localization: reads the app language from FFLocalizations (no parameter).
/// Hebrew renders RTL.
class UnitsRow extends StatefulWidget {
  const UnitsRow({
    super.key,
    this.width,
    this.height,
    this.workoutIsKg,
    this.heightIsCm,
    this.bodyIsKg,
    this.onWorkoutWeightChanged,
    this.onHeightChanged,
    this.onBodyWeightChanged,
  });

  final double? width;
  final double? height;
  final bool? workoutIsKg;
  final bool? heightIsCm;
  final bool? bodyIsKg;
  final Future Function(bool isKg)? onWorkoutWeightChanged;
  final Future Function(bool isCm)? onHeightChanged;
  final Future Function(bool isKg)? onBodyWeightChanged;

  @override
  State<UnitsRow> createState() => _UnitsRowState();
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
  "units": {
    "en": "Units",
    "es": "Unidades",
    "he": "יחידות מידה",
    "de": "Einheiten",
    "fr": "Unités"
  },
  "workout": {
    "en": "Workout weight",
    "es": "Peso en el entreno",
    "he": "משקל באימון",
    "de": "Trainingsgewicht",
    "fr": "Poids à l'entraînement"
  },
  "heightLabel": {
    "en": "Height",
    "es": "Altura",
    "he": "גובה",
    "de": "Größe",
    "fr": "Taille"
  },
  "body": {
    "en": "Body weight",
    "es": "Peso corporal",
    "he": "משקל גוף",
    "de": "Körpergewicht",
    "fr": "Poids du corps"
  },
  "kg": {"en": "kg", "es": "kg", "he": "ק״ג", "de": "kg", "fr": "kg"},
  "lbs": {"en": "lbs", "es": "lbs", "he": "ליב׳", "de": "lbs", "fr": "lbs"},
  "cm": {"en": "cm", "es": "cm", "he": "ס״מ", "de": "cm", "fr": "cm"},
  "inch": {"en": "in", "es": "in", "he": "אינץ׳", "de": "in", "fr": "in"},
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

class _UnitsRowState extends State<UnitsRow> {
  Future<void> _openSheet() async {
    HapticFeedback.selectionClick();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UnitsSheet(
        workoutIsKg: widget.workoutIsKg ?? true,
        heightIsCm: widget.heightIsCm ?? true,
        bodyIsKg: widget.bodyIsKg ?? true,
        onWorkout: (v) async => widget.onWorkoutWeightChanged?.call(v),
        onHeight: (v) async => widget.onHeightChanged?.call(v),
        onBody: (v) async => widget.onBodyWeightChanged?.call(v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);

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
              Icon(Icons.monitor_weight_outlined,
                  size: 24, color: theme.secondaryText),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _tr(lang, 'units'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium.override(
                    fontFamily: theme.bodyMediumFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: theme.primaryText,
                    useGoogleFonts:
                        GoogleFonts.asMap().containsKey(theme.bodyMediumFamily),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Same chevron as the other rows, in every language.
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

class _UnitsSheet extends StatefulWidget {
  const _UnitsSheet({
    required this.workoutIsKg,
    required this.heightIsCm,
    required this.bodyIsKg,
    required this.onWorkout,
    required this.onHeight,
    required this.onBody,
  });

  final bool workoutIsKg;
  final bool heightIsCm;
  final bool bodyIsKg;
  final Future<void> Function(bool) onWorkout;
  final Future<void> Function(bool) onHeight;
  final Future<void> Function(bool) onBody;

  @override
  State<_UnitsSheet> createState() => _UnitsSheetState();
}

class _UnitsSheetState extends State<_UnitsSheet> {
  late bool _workoutKg = widget.workoutIsKg;
  late bool _heightCm = widget.heightIsCm;
  late bool _bodyKg = widget.bodyIsKg;

  TextStyle _st(double size, FontWeight w, Color c) {
    final theme = FlutterFlowTheme.of(context);
    return theme.bodyMedium.override(
      fontFamily: theme.bodyMediumFamily,
      fontSize: size,
      fontWeight: w,
      color: c,
      useGoogleFonts: GoogleFonts.asMap().containsKey(theme.bodyMediumFamily),
    );
  }

  /// One label + two-way switch. [first] is true when the first option is
  /// the selected one.
  Widget _group({
    required String label,
    required String firstText,
    required String secondText,
    required bool first,
    required void Function(bool first) onPick,
  }) {
    final theme = FlutterFlowTheme.of(context);

    Widget option(String text, bool selected, bool value) => Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (selected) return;
              HapticFeedback.selectionClick();
              onPick(value);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? theme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                text,
                style: _st(
                  15,
                  selected ? FontWeight.w600 : FontWeight.w500,
                  selected ? Colors.white : theme.secondaryText,
                ),
              ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _st(16, FontWeight.w400, theme.primaryText),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 168,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.primaryBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                option(firstText, first, true),
                option(secondText, !first, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);
    final double bottom = MediaQuery.of(context).padding.bottom;

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
                      _tr(lang, 'units'),
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
                          style: _st(16, FontWeight.w500, theme.primary)),
                    ),
                  ),
                ],
              ),
            ),
            _group(
              label: _tr(lang, 'workout'),
              firstText: _tr(lang, 'kg'),
              secondText: _tr(lang, 'lbs'),
              first: _workoutKg,
              onPick: (v) {
                setState(() => _workoutKg = v);
                widget.onWorkout(v);
              },
            ),
            Divider(height: 1, thickness: 1, color: theme.alternate),
            _group(
              label: _tr(lang, 'heightLabel'),
              firstText: _tr(lang, 'cm'),
              secondText: _tr(lang, 'inch'),
              first: _heightCm,
              onPick: (v) {
                setState(() => _heightCm = v);
                widget.onHeight(v);
              },
            ),
            Divider(height: 1, thickness: 1, color: theme.alternate),
            _group(
              label: _tr(lang, 'body'),
              firstText: _tr(lang, 'kg'),
              secondText: _tr(lang, 'lbs'),
              first: _bodyKg,
              onPick: (v) {
                setState(() => _bodyKg = v);
                widget.onBody(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then a
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
