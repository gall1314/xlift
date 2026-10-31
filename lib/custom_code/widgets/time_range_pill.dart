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

/// Reusable time-range pill: calendar icon + current range + chevron.
///
/// Opens the "Select Time Range" bottom sheet itself. The sheet's surface
/// runs to the very bottom of the screen (no safe-area gap); the rows keep a
/// small inset above the home indicator.
///
/// Options (internal keys, always English): 'Last 7 days', 'Last 30 days',
/// 'Last 90 days', 'All time'. The user sees them translated; [onChanged] and
/// [value] always use the English key, so the stats widgets keep working
/// unchanged. When [isPremium] is false, "Last 90 days" and "All time" are
/// locked: tapping one closes the sheet and fires [onLockedTap].
///
/// [value] = current range key (optional; null/empty/"All" = default, which
/// is "All time" for premium and "Last 30 days" otherwise). The widget keeps
/// its own selection, so binding [value] to page state is not required.
///
/// Localization: reads the app language from FFLocalizations (no parameter).
/// Hebrew renders RTL.
///
/// A non-default range gets a teal tint. [alignRight] pushes the pill to the
/// end of the widget's box (trailing edge in RTL).
class TimeRangePill extends StatefulWidget {
  const TimeRangePill({
    super.key,
    this.width,
    this.height,
    this.value,
    this.isPremium,
    this.alignRight,
    this.onChanged,
    this.onLockedTap,
  });

  final double? width;
  final double? height;
  final String? value;
  final bool? isPremium;
  final bool? alignRight;
  final Future Function(String range)? onChanged;
  final Future Function()? onLockedTap;

  @override
  State<TimeRangePill> createState() => _TimeRangePillState();
}

// ---------------------------------------------------------------------------
// Localization
// ---------------------------------------------------------------------------

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
  "title": {
    "en": "Select Time Range",
    "es": "Elige el periodo",
    "he": "בחר טווח זמן",
    "de": "Zeitraum wählen",
    "fr": "Choisir la période",
  },
  "Last 7 days": {
    "en": "Last 7 days",
    "es": "Últimos 7 días",
    "he": "7 ימים אחרונים",
    "de": "Letzte 7 Tage",
    "fr": "7 derniers jours",
  },
  "Last 30 days": {
    "en": "Last 30 days",
    "es": "Últimos 30 días",
    "he": "30 ימים אחרונים",
    "de": "Letzte 30 Tage",
    "fr": "30 derniers jours",
  },
  "Last 90 days": {
    "en": "Last 90 days",
    "es": "Últimos 90 días",
    "he": "90 ימים אחרונים",
    "de": "Letzte 90 Tage",
    "fr": "90 derniers jours",
  },
  "All time": {
    "en": "All time",
    "es": "Todo el historial",
    "he": "כל הזמן",
    "de": "Gesamter Zeitraum",
    "fr": "Toute la période",
  },
};

String _tr(String lang, String key) {
  final m = _kStrings[key];
  return m == null ? key : (m[lang] ?? m['en'] ?? key);
}

TextStyle _ts(BuildContext ctx, double size, FontWeight w, Color c) {
  final th = FlutterFlowTheme.of(ctx);
  return th.bodyMedium.override(
    fontFamily: th.bodyMediumFamily,
    color: c,
    fontSize: size,
    fontWeight: w,
    useGoogleFonts: GoogleFonts.asMap().containsKey(th.bodyMediumFamily),
  );
}

/// Darker teal for text on light surfaces; theme primary in dark mode.
Color _accentOf(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
    ? FlutterFlowTheme.of(ctx).primary
    : const Color(0xFF0F766E);

class _TimeRangePillState extends State<TimeRangePill> {
  static const List<String> _ranges = [
    'Last 7 days',
    'Last 30 days',
    'Last 90 days',
    'All time',
  ];
  // Same order as _ranges: true = premium only.
  static const List<bool> _premiumOnly = [false, false, true, true];
  static const String _lockedResult = '__locked__';

  late String _range;
  bool _sheetOpen = false;
  bool _down = false;

  bool get _premium => widget.isPremium ?? false;
  String get _defaultRange => _premium ? 'All time' : 'Last 30 days';

  @override
  void initState() {
    super.initState();
    _range = _norm(widget.value);
  }

  @override
  void didUpdateWidget(covariant TimeRangePill old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _range = _norm(widget.value);
    } else if (old.isPremium != widget.isPremium) {
      final bool oldPremium = old.isPremium ?? false;
      final String oldDefault = oldPremium ? 'All time' : 'Last 30 days';
      final int idx = _ranges.indexOf(_range);
      final bool nowLocked = idx >= 0 && _premiumOnly[idx] && !_premium;
      if (_range == oldDefault || nowLocked) _range = _defaultRange;
    }
  }

  /// Known key -> that key; empty/"All" -> default; anything else as is.
  String _norm(String? v) {
    final String s = (v ?? '').trim();
    final String l = s.toLowerCase();
    if (s.isEmpty || l == 'all') return _defaultRange;
    for (final r in _ranges) {
      if (r.toLowerCase() == l) return r;
    }
    return s;
  }

  void _setDown(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  Future<void> _openSheet() async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    final String lang = _langOf(context);
    final String? picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection:
            _kRtl.contains(lang) ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: _RangeSheet(
          lang: lang,
          ranges: _ranges,
          premiumOnly: _premiumOnly,
          isPremium: _premium,
          selected: _range,
          lockedResult: _lockedResult,
        ),
      ),
    );
    _sheetOpen = false;
    if (picked == null) return; // dismissed
    if (picked == _lockedResult) {
      await widget.onLockedTap?.call();
      return;
    }
    if (mounted) setState(() => _range = picked);
    await widget.onChanged?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color accent = _accentOf(context);
    final bool active = _range != _defaultRange;
    final Color fg = active ? accent : th.primaryText;
    final Color iconColor = active ? accent : th.secondaryText;

    final Widget pill = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setDown(true),
      onTapCancel: () => _setDown(false),
      onTapUp: (_) {
        _setDown(false);
        HapticFeedback.selectionClick();
        _openSheet();
      },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: AnimatedOpacity(
          opacity: _down ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: active
                  ? th.primary.withOpacity(0.18)
                  : th.secondaryBackground,
              borderRadius: BorderRadius.circular(999),
              border:
                  (!active && dark) ? Border.all(color: th.alternate) : null,
              boxShadow: (active || dark)
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x0A101828),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _tr(lang, _range),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _ts(context, 14,
                        active ? FontWeight.w600 : FontWeight.w500, fg),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: iconColor),
              ],
            ),
          ),
        ),
      ),
    );

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: SizedBox(
        width: widget.width,
        height: widget.height ?? 44,
        child: Align(
          alignment: (widget.alignRight ?? false)
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: pill,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet
// ---------------------------------------------------------------------------

class _RangeSheet extends StatelessWidget {
  const _RangeSheet({
    required this.lang,
    required this.ranges,
    required this.premiumOnly,
    required this.isPremium,
    required this.selected,
    required this.lockedResult,
  });

  final String lang;
  final List<String> ranges;
  final List<bool> premiumOnly;
  final bool isPremium;
  final String selected;
  final String lockedResult;

  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final Color accent = _accentOf(context);
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    // No SafeArea: the sheet surface reaches the screen edge. The rows get a
    // small inset so the last one isn't under the home indicator.
    return Container(
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset - 4 : 8),
      decoration: BoxDecoration(
        color: th.secondaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: th.alternate,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            _tr(lang, 'title'),
            style: _ts(context, 20, FontWeight.w600, th.primaryText),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < ranges.length; i++) ...[
            _row(context, th, accent, i),
            if (i < ranges.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(height: 1, color: th.alternate),
              ),
          ],
        ],
      ),
    );
  }

  Widget _row(
      BuildContext context, FlutterFlowTheme th, Color accent, int index) {
    final String key = ranges[index];
    final bool locked = premiumOnly[index] && !isPremium;
    final bool isSelected = !locked && key == selected;
    final Color fg =
        locked ? th.secondaryText : (isSelected ? accent : th.primaryText);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        // Always return the English key, never the translated label.
        Navigator.of(context).pop(locked ? lockedResult : key);
      },
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _tr(lang, key),
              style: _ts(context, 17,
                  isSelected ? FontWeight.w600 : FontWeight.w500, fg),
            ),
            if (locked) ...[
              const SizedBox(width: 8),
              Icon(Icons.lock_outline_rounded, size: 18, color: fg),
            ],
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_rounded, size: 20, color: accent),
            ],
          ],
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
