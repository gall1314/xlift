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

/// History filter row: two pills side by side, aligned to the start.
///
/// Both bottom sheets are built in. Sheet surfaces run to the very bottom of
/// the screen (no safe-area gap); content keeps a small inset above the home
/// indicator.
///
/// Period pill: opens "Select Time Range" (keys: Last 7 days, Last 30 days,
/// Last 90 days, All time — shown translated). When [isPremium] is false,
/// "Last 90 days" and "All time" are locked: tapping one closes the sheet and
/// fires [onLockedTap]. Picking an unlocked row fires [onPeriodChanged](key)
/// with the ENGLISH key. Default when [periodValue] is null/empty/"All": "All
/// time" for premium, "Last 30 days" otherwise.
///
/// Muscle pill: opens "Choose Muscle group" (primary muscle groups read from
/// SQLite, shown translated) and fires [onMuscleChanged](muscle) with the
/// ENGLISH muscle name, or "All". [muscleValue] is also the English name.
///
/// Localization: reads the app language from FFLocalizations (no parameter).
/// Hebrew renders RTL.
class HistoryFilterBar extends StatefulWidget {
  const HistoryFilterBar({
    super.key,
    this.width,
    this.height,
    this.isPremium,
    this.periodValue,
    this.muscleValue,
    this.onPeriodChanged,
    this.onMuscleChanged,
    this.onLockedTap,
  });

  final double? width;
  final double? height;
  final bool? isPremium;
  final String? periodValue;
  final String? muscleValue;
  final Future Function(String period)? onPeriodChanged;
  final Future Function(String muscle)? onMuscleChanged;
  final Future Function()? onLockedTap;

  @override
  State<HistoryFilterBar> createState() => _HistoryFilterBarState();
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
  "selectRange": {
    "en": "Select Time Range",
    "es": "Elige el periodo",
    "he": "בחר טווח זמן",
    "de": "Zeitraum wählen",
    "fr": "Choisir la période",
  },
  "chooseMuscleGroup": {
    "en": "Choose Muscle group",
    "es": "Elige grupo muscular",
    "he": "בחר קבוצת שרירים",
    "de": "Muskelgruppe wählen",
    "fr": "Choisir un groupe musculaire",
  },
  "all": {
    "en": "All",
    "es": "Todos",
    "he": "הכל",
    "de": "Alle",
    "fr": "Tous",
  },
  "allMuscles": {
    "en": "All muscles",
    "es": "Todos los músculos",
    "he": "כל השרירים",
    "de": "Alle Muskeln",
    "fr": "Tous les muscles",
  },
  "searchMuscle": {
    "en": "Search Muscle",
    "es": "Buscar músculo",
    "he": "חיפוש שריר",
    "de": "Muskel suchen",
    "fr": "Rechercher un muscle",
  },
  "noMuscleGroups": {
    "en": "No muscle groups found",
    "es": "No se encontraron grupos musculares",
    "he": "לא נמצאו קבוצות שרירים",
    "de": "Keine Muskelgruppen gefunden",
    "fr": "Aucun groupe musculaire trouvé",
  },
};

String _tr(String lang, String key) {
  final m = _kStrings[key];
  return m == null ? key : (m[lang] ?? m['en'] ?? key);
}

class _MuscleOpt {
  const _MuscleOpt(this.en, this.label);
  final String en; // key sent in callbacks, image lookup
  final String label; // localized
}

/// Bottom padding inside a sheet that reaches the screen edge: keeps the last
/// row above the home indicator without leaving a visible gap.
double _sheetBottomPad(BuildContext ctx) {
  final double inset = MediaQuery.of(ctx).padding.bottom;
  return inset > 0 ? inset - 4 : 8;
}

class _HistoryFilterBarState extends State<HistoryFilterBar> {
  static const String _allValue = 'All'; // value sent in onMuscleChanged
  static const String _allResult = '__all__';
  static const String _lockedResult = '__locked__';

  static const List<String> _periods = [
    'Last 7 days',
    'Last 30 days',
    'Last 90 days',
    'All time',
  ];
  // Same order as _periods: true = premium only.
  static const List<bool> _periodPremiumOnly = [false, false, true, true];

  String? _muscleEn; // null = All
  late String _period;
  bool _sheetOpen = false;
  static List<String>? _rawCache; // raw DB names, loaded once per run
  List<_MuscleOpt> _opts = const [];

  bool get _premium => widget.isPremium ?? false;
  String get _defaultPeriod => _premium ? 'All time' : 'Last 30 days';

  @override
  void initState() {
    super.initState();
    _muscleEn = _normMuscle(widget.muscleValue);
    _period = _normPeriod(widget.periodValue);
  }

  @override
  void didUpdateWidget(covariant HistoryFilterBar old) {
    super.didUpdateWidget(old);
    if (old.muscleValue != widget.muscleValue) {
      _muscleEn = _normMuscle(widget.muscleValue);
    }
    if (old.periodValue != widget.periodValue ||
        old.isPremium != widget.isPremium) {
      _period = _normPeriod(widget.periodValue);
    }
  }

  /// null = no muscle filter ("All", "All muscles", empty).
  String? _normMuscle(String? v) {
    final s = (v ?? '').trim();
    final l = s.toLowerCase();
    if (s.isEmpty || l == 'all' || l == 'all muscles') return null;
    return s;
  }

  /// Known key -> that key; empty/"All" -> default; anything else as is.
  String _normPeriod(String? v) {
    final s = (v ?? '').trim();
    final l = s.toLowerCase();
    if (s.isEmpty || l == 'all') return _defaultPeriod;
    for (final p in _periods) {
      if (p.toLowerCase() == l) return p;
    }
    return s;
  }

  Future<List<_MuscleOpt>> _loadMuscles(String lang) async {
    if (_rawCache == null) {
      final List<String> out = [];
      try {
        final rows = await SQLiteManager.instance.database.rawQuery(
          'SELECT name FROM primary_muscle_group '
          'WHERE name IS NOT NULL AND TRIM(name) <> \'\' '
          'ORDER BY id ASC',
        );
        for (final r in rows) {
          final n = r['name']?.toString().trim();
          if (n != null && n.isNotEmpty) out.add(n);
        }
      } catch (_) {}
      _rawCache = out;
    }
    final opts = [
      for (final r in _rawCache!)
        _MuscleOpt(localizedName(r, 'en'), localizedName(r, lang)),
    ]..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return opts;
  }

  /// Localized label for the currently selected muscle (English key).
  String _muscleLabel(String lang) {
    final en = _muscleEn;
    if (en == null) return _tr(lang, 'allMuscles');
    for (final o in _opts) {
      if (o.en == en) return o.label;
    }
    return en;
  }

  Future<void> _openMuscleSheet() async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    final String lang = _langOf(context);
    final opts = await _loadMuscles(lang);
    if (!mounted) {
      _sheetOpen = false;
      return;
    }
    setState(() => _opts = opts);
    final String? picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection:
            _kRtl.contains(lang) ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: _MuscleSheet(
          lang: lang,
          options: opts,
          selectedEn: _muscleEn,
          allResult: _allResult,
        ),
      ),
    );
    _sheetOpen = false;
    if (picked == null) return; // dismissed
    final String? newSel = picked == _allResult ? null : picked;
    if (mounted) setState(() => _muscleEn = newSel);
    await widget.onMuscleChanged?.call(newSel ?? _allValue);
  }

  Future<void> _openPeriodSheet() async {
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
        child: _PeriodSheet(
          lang: lang,
          periods: _periods,
          premiumOnly: _periodPremiumOnly,
          isPremium: _premium,
          selected: _period,
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
    if (mounted) setState(() => _period = picked);
    await widget.onPeriodChanged?.call(picked);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preload muscle labels so a pre-selected muscle shows translated.
    if (_muscleEn != null && _opts.isEmpty) {
      final lang = _langOf(context);
      _loadMuscles(lang).then((o) {
        if (mounted) setState(() => _opts = o);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String lang = _langOf(context);
    return Directionality(
      textDirection:
          _kRtl.contains(lang) ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: SizedBox(
        width: widget.width,
        height: widget.height ?? 44,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: _FilterPill(
                icon: Icons.calendar_today_outlined,
                label: _tr(lang, _period),
                active: _period != _defaultPeriod,
                onTap: _openPeriodSheet,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: _FilterPill(
                icon: Icons.fitness_center_rounded,
                label: _muscleLabel(lang),
                active: _muscleEn != null,
                onTap: _openMuscleSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pill button (icon + label + chevron, press feedback, active tint)
// ---------------------------------------------------------------------------

class _FilterPill extends StatefulWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_FilterPill> createState() => _FilterPillState();
}

class _FilterPillState extends State<_FilterPill> {
  bool _down = false;
  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // Darker teal for text on a light tint; theme primary in dark mode.
    final Color accent = isDark ? th.primary : const Color(0xFF0F766E);
    final Color fg = widget.active ? accent : th.primaryText;
    final Color iconColor = widget.active ? accent : th.secondaryText;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) {
        _set(false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: AnimatedOpacity(
          opacity: _down ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: widget.active
                  ? th.primary.withOpacity(0.18)
                  : th.secondaryBackground,
              borderRadius: BorderRadius.circular(999),
              border: (!widget.active && isDark)
                  ? Border.all(color: th.alternate)
                  : null,
              boxShadow: (widget.active || isDark)
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
                Icon(widget.icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: th.bodyMedium.override(
                      fontFamily: th.bodyMediumFamily,
                      color: fg,
                      fontSize: 14,
                      fontWeight:
                          widget.active ? FontWeight.w600 : FontWeight.w500,
                      useGoogleFonts:
                          GoogleFonts.asMap().containsKey(th.bodyMediumFamily),
                    ),
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
  }
}

// ---------------------------------------------------------------------------
// Period bottom sheet
// ---------------------------------------------------------------------------

class _PeriodSheet extends StatelessWidget {
  const _PeriodSheet({
    required this.lang,
    required this.periods,
    required this.premiumOnly,
    required this.isPremium,
    required this.selected,
    required this.lockedResult,
  });

  final String lang;
  final List<String> periods;
  final List<bool> premiumOnly;
  final bool isPremium;
  final String selected;
  final String lockedResult;

  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accent = isDark ? th.primary : const Color(0xFF0F766E);

    return Container(
      padding: EdgeInsets.only(bottom: _sheetBottomPad(context)),
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
            _tr(lang, 'selectRange'),
            style: th.headlineMedium.override(
              fontFamily: th.headlineMediumFamily,
              color: th.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              useGoogleFonts:
                  GoogleFonts.asMap().containsKey(th.headlineMediumFamily),
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < periods.length; i++) ...[
            _row(context, th, accent, i),
            if (i < periods.length - 1)
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
    final String key = periods[index];
    final bool locked = premiumOnly[index] && !isPremium;
    final bool isSelected = !locked && key == selected;
    final Color fg =
        locked ? th.secondaryText : (isSelected ? accent : th.primaryText);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        // Always return the English key.
        Navigator.of(context).pop(locked ? lockedResult : key);
      },
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _tr(lang, key),
              style: th.bodyLarge.override(
                fontFamily: th.bodyLargeFamily,
                color: fg,
                fontSize: 17,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                useGoogleFonts:
                    GoogleFonts.asMap().containsKey(th.bodyLargeFamily),
              ),
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

// ---------------------------------------------------------------------------
// Muscle bottom sheet
// ---------------------------------------------------------------------------

class _MuscleSheet extends StatefulWidget {
  const _MuscleSheet({
    required this.lang,
    required this.options,
    required this.selectedEn,
    required this.allResult,
  });

  final String lang;
  final List<_MuscleOpt> options;
  final String? selectedEn; // null = All
  final String allResult;

  @override
  State<_MuscleSheet> createState() => _MuscleSheetState();
}

class _MuscleSheetState extends State<_MuscleSheet> {
  final TextEditingController _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final String lang = widget.lang;
    final double maxH = MediaQuery.of(context).size.height * 0.85;
    final String q = _q.toLowerCase();
    final List<_MuscleOpt> filtered = q.isEmpty
        ? widget.options
        : widget.options
            .where((m) =>
                m.label.toLowerCase().contains(q) ||
                m.en.toLowerCase().contains(q))
            .toList();
    final String allLabel = _tr(lang, 'all');
    final bool showAll = q.isEmpty || allLabel.toLowerCase().contains(q);

    TextStyle rowStyle = th.bodyLarge.override(
      fontFamily: th.bodyLargeFamily,
      color: th.primaryText,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      useGoogleFonts: GoogleFonts.asMap().containsKey(th.bodyLargeFamily),
    );

    Widget row({
      required Widget leading,
      required String text,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              SizedBox(width: 70, height: 70, child: Center(child: leading)),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: rowStyle)),
              if (selected)
                Icon(Icons.check_rounded, size: 26, color: th.primary),
            ],
          ),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
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
          const SizedBox(height: 18),
          Text(
            _tr(lang, 'chooseMuscleGroup'),
            style: th.headlineMedium.override(
              fontFamily: th.headlineMediumFamily,
              color: th.primaryText,
              fontSize: 26,
              fontWeight: FontWeight.w600,
              useGoogleFonts:
                  GoogleFonts.asMap().containsKey(th.headlineMediumFamily),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: th.secondaryBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: th.alternate),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 22, color: th.secondaryText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged: (v) => setState(() => _q = v.trim()),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: _tr(lang, 'searchMuscle'),
                        hintStyle: th.bodyMedium.override(
                          fontFamily: th.bodyMediumFamily,
                          color: th.secondaryText,
                          fontSize: 16,
                          useGoogleFonts: GoogleFonts.asMap()
                              .containsKey(th.bodyMediumFamily),
                        ),
                      ),
                      style: th.bodyMedium.override(
                        fontFamily: th.bodyMediumFamily,
                        color: th.primaryText,
                        fontSize: 16,
                        useGoogleFonts: GoogleFonts.asMap()
                            .containsKey(th.bodyMediumFamily),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.only(bottom: _sheetBottomPad(context) + 4),
              children: [
                if (showAll) ...[
                  row(
                    leading: Icon(Icons.grid_view_rounded,
                        size: 30, color: th.primaryText),
                    text: allLabel,
                    selected: widget.selectedEn == null,
                    onTap: () => Navigator.of(context).pop(widget.allResult),
                  ),
                  Divider(height: 1, color: th.alternate),
                ],
                for (int i = 0; i < filtered.length; i++) ...[
                  row(
                    leading: ExerciseAssetImage(
                      width: 70,
                      height: 70,
                      // Images are keyed by the English name.
                      exerciseName: exerciseImageName(filtered[i].en),
                      borderRadius: 8,
                    ),
                    text: filtered[i].label,
                    selected: widget.selectedEn == filtered[i].en,
                    onTap: () => Navigator.of(context).pop(filtered[i].en),
                  ),
                  if (i < filtered.length - 1)
                    Divider(height: 1, color: th.alternate),
                ],
                if (!showAll && filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(_tr(lang, 'noMuscleGroups'),
                          style: th.bodyMedium.override(
                            fontFamily: th.bodyMediumFamily,
                            color: th.secondaryText,
                            useGoogleFonts: GoogleFonts.asMap()
                                .containsKey(th.bodyMediumFamily),
                          )),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
