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

import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable time-range pill: calendar icon + current range + chevron. Opens
/// the "Select Time Range" bottom sheet itself.
///
/// Options: Last 7 days, Last 30 days, Last 90 days, All time. When
/// [isPremium] is false, "Last 90 days" and "All time" are locked: tapping
/// one closes the sheet and fires [onLockedTap] (e.g. open the paywall).
/// Picking an unlocked row fires [onChanged](range) with the row label
/// exactly as written.
///
/// [value] = current range (optional; null/empty/"All" = default, which is
/// "All time" for premium and "Last 30 days" otherwise). The widget keeps
/// its own selection, so binding [value] to page state is not required.
///
/// A non-default range gets a teal tint. [alignRight] pushes the pill to the
/// end of the widget's box (e.g. in a page header).
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

  /// Known label -> that label; empty/"All" -> default; anything else as is.
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
    final String? picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RangeSheet(
        title: 'Select Time Range',
        ranges: _ranges,
        premiumOnly: _premiumOnly,
        isPremium: _premium,
        selected: _range,
        lockedResult: _lockedResult,
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
                    _range,
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

    return SizedBox(
      width: widget.width,
      height: widget.height ?? 44,
      child: Align(
        alignment: (widget.alignRight ?? false)
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: pill,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet
// ---------------------------------------------------------------------------

class _RangeSheet extends StatelessWidget {
  const _RangeSheet({
    required this.title,
    required this.ranges,
    required this.premiumOnly,
    required this.isPremium,
    required this.selected,
    required this.lockedResult,
  });

  final String title;
  final List<String> ranges;
  final List<bool> premiumOnly;
  final bool isPremium;
  final String selected;
  final String lockedResult;

  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final Color accent = _accentOf(context);

    return SafeArea(
      top: false,
      child: Container(
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
              title,
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _row(
      BuildContext context, FlutterFlowTheme th, Color accent, int index) {
    final String label = ranges[index];
    final bool locked = premiumOnly[index] && !isPremium;
    final bool isSelected = !locked && label == selected;
    final Color fg =
        locked ? th.secondaryText : (isSelected ? accent : th.primaryText);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop(locked ? lockedResult : label);
      },
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
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
