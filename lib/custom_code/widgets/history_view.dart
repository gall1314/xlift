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

/// Full History page body: search field, period + muscle filter pills (both
/// bottom sheets built in), workout cards and empty states.
///
/// Fully self-managed, no page state needed: loads from the SQLite query
/// history(userId) and filters in memory, so search / period / muscle always
/// stay in sync.
///
/// Period: Last 7 days, Last 30 days, Last 90 days, All time. When
/// [isPremium] is false, "Last 90 days" and "All time" are locked (tapping
/// one fires [onLockedTap]) and the default is "Last 30 days"; for premium
/// the default is "All time".
///
/// Callbacks: [onWorkoutTap](workoutLogId) from a card tap and
/// [onMenuTap](workoutLogId) from the card's options button. The list reloads
/// when either action finishes.
///
/// Optional: change [reloadToken] (any different int) to force a reload.
/// Pull-to-refresh also reloads.
class HistoryView extends StatefulWidget {
  const HistoryView({
    super.key,
    this.width,
    this.height,
    required this.userId,
    this.isPremium,
    this.reloadToken,
    this.onWorkoutTap,
    this.onMenuTap,
    this.onLockedTap,
  });

  final double? width;
  final double? height;
  final String userId;
  final bool? isPremium;
  final int? reloadToken;
  final Future Function(String workoutLogId)? onWorkoutTap;
  final Future Function(String workoutLogId)? onMenuTap;
  final Future Function()? onLockedTap;

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

TextStyle _hs(BuildContext ctx, double size, FontWeight w, Color c,
    {double ls = 0, double? height}) {
  final th = FlutterFlowTheme.of(ctx);
  return th.bodyMedium.override(
    fontFamily: th.bodyMediumFamily,
    color: c,
    fontSize: size,
    fontWeight: w,
    letterSpacing: ls,
    lineHeight: height,
    useGoogleFonts: GoogleFonts.asMap().containsKey(th.bodyMediumFamily),
  );
}

bool _isDark(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark;

/// Darker teal for text on light surfaces; theme primary in dark mode.
Color _accent(BuildContext ctx) =>
    _isDark(ctx) ? FlutterFlowTheme.of(ctx).primary : const Color(0xFF0F766E);

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.round();
  return num.tryParse(v.toString())?.round() ?? 0;
}

DateTime? _parseDate(String raw) {
  if (raw.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(raw.trim());
  if (parsed == null) return null;
  return parsed.isUtc ? parsed.toLocal() : parsed;
}

List<String> _splitMuscles(dynamic v) => (v ?? '')
    .toString()
    .split(',')
    .map((m) => m.trim())
    .where((m) => m.isNotEmpty)
    .toList();

// ---------------------------------------------------------------------------
// Page state
// ---------------------------------------------------------------------------

class _HistoryViewState extends State<HistoryView> {
  static const List<String> _periods = [
    'Last 7 days',
    'Last 30 days',
    'Last 90 days',
    'All time',
  ];
  // Same order as _periods. 0 = no limit.
  static const List<int> _periodDays = [7, 30, 90, 0];
  static const List<bool> _periodPremiumOnly = [false, false, true, true];

  static const String _allMuscles = 'All';
  static const String _musclePlaceholder = 'All muscles';
  static const String _lockedResult = '__locked__';

  final TextEditingController _search = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String _q = '';
  late String _period;
  String? _muscle; // null = all muscles
  bool _sheetOpen = false;
  static List<String>? _muscleCache; // loaded once per run

  bool get _premium => widget.isPremium ?? false;
  String get _defaultPeriod => _premium ? 'All time' : 'Last 30 days';

  @override
  void initState() {
    super.initState();
    _period = _defaultPeriod;
    _load();
  }

  @override
  void didUpdateWidget(covariant HistoryView old) {
    super.didUpdateWidget(old);
    if (old.isPremium != widget.isPremium) {
      final bool oldPremium = old.isPremium ?? false;
      final String oldDefault = oldPremium ? 'All time' : 'Last 30 days';
      final int idx = _periods.indexOf(_period);
      final bool nowLocked = idx >= 0 && _periodPremiumOnly[idx] && !_premium;
      if (_period == oldDefault || nowLocked) _period = _defaultPeriod;
    }
    if (old.userId != widget.userId || old.reloadToken != widget.reloadToken) {
      _load();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static Map<String, dynamic> _rowMap(dynamic row) {
    try {
      final d = (row as dynamic).data;
      if (d is Map) return Map<String, dynamic>.from(d);
    } catch (_) {}
    if (row is Map) return Map<String, dynamic>.from(row);
    return const {};
  }

  // ---------- data ----------
  Future<void> _load() async {
    final List<Map<String, dynamic>> out = [];
    try {
      final rows = await SQLiteManager.instance.history(userId: widget.userId);
      for (final r in rows) {
        out.add(_rowMap(r));
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _rows = out;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> _filtered() {
    final int idx = _periods.indexOf(_period);
    final int days = idx >= 0 ? _periodDays[idx] : 0;
    final DateTime? cutoff =
        days > 0 ? DateTime.now().subtract(Duration(days: days)) : null;
    final String q = _q.toLowerCase();
    final String? muscle = _muscle?.toLowerCase();

    return _rows.where((r) {
      if (cutoff != null) {
        final dt = _parseDate((r['created_at'] ?? '').toString());
        if (dt != null && dt.isBefore(cutoff)) return false;
      }
      final muscles = _splitMuscles(r['main_muscle_groups'])
          .map((m) => m.toLowerCase())
          .toList();
      if (muscle != null && !muscles.contains(muscle)) return false;
      if (q.isNotEmpty) {
        final name = (r['workout_name'] ?? '').toString().toLowerCase();
        final bool hit = name.contains(q) || muscles.any((m) => m.contains(q));
        if (!hit) return false;
      }
      return true;
    }).toList();
  }

  void _clearFilters() {
    _search.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _q = '';
      _period = _defaultPeriod;
      _muscle = null;
    });
  }

  // ---------- sheets ----------
  Future<List<String>> _loadMuscles() async {
    if (_muscleCache != null) return _muscleCache!;
    final List<String> out = [];
    try {
      final rows = await SQLiteManager.instance.database.rawQuery(
        'SELECT DISTINCT name FROM primary_muscle_group '
        'WHERE name IS NOT NULL AND TRIM(name) <> \'\' '
        'ORDER BY name ASC',
      );
      for (final r in rows) {
        final n = r['name']?.toString().trim();
        if (n != null && n.isNotEmpty) out.add(n);
      }
    } catch (_) {}
    _muscleCache = out;
    return out;
  }

  Future<void> _openMuscleSheet() async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    FocusScope.of(context).unfocus();
    final List<String> muscles = await _loadMuscles();
    if (!mounted) {
      _sheetOpen = false;
      return;
    }
    final String? picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MuscleSheet(
        title: 'Choose Muscle group',
        allLabel: _allMuscles,
        muscles: muscles,
        selected: _muscle,
      ),
    );
    _sheetOpen = false;
    if (picked == null || !mounted) return; // dismissed
    setState(() => _muscle = picked == _allMuscles ? null : picked);
  }

  Future<void> _openPeriodSheet() async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    FocusScope.of(context).unfocus();
    final String? picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PeriodSheet(
        title: 'Select Time Range',
        periods: _periods,
        premiumOnly: _periodPremiumOnly,
        isPremium: _premium,
        selected: _period,
        lockedResult: _lockedResult,
      ),
    );
    _sheetOpen = false;
    if (picked == null) return; // dismissed
    if (picked == _lockedResult) {
      await widget.onLockedTap?.call();
      return;
    }
    if (mounted) setState(() => _period = picked);
  }

  // ---------- card actions ----------
  Future<void> _tapWorkout(String id) async {
    FocusScope.of(context).unfocus();
    await widget.onWorkoutTap?.call(id);
    if (mounted) _load();
  }

  Future<void> _tapMenu(String id) async {
    FocusScope.of(context).unfocus();
    await widget.onMenuTap?.call(id);
    if (mounted) _load();
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final List<Map<String, dynamic>> filtered =
        _loading ? const [] : _filtered();
    final bool hasActiveFilters =
        _q.isNotEmpty || _muscle != null || _period != _defaultPeriod;

    Widget body;
    if (_loading) {
      body = Center(child: CircularProgressIndicator(color: th.primary));
    } else if (_rows.isEmpty) {
      body = const _EmptyState(
        icon: Icons.fitness_center_rounded,
        title: 'No workouts yet',
        subtitle: 'Finish a workout and it will show up here.',
      );
    } else if (filtered.isEmpty && hasActiveFilters) {
      body = _EmptyState(
        icon: Icons.filter_alt_outlined,
        title: 'No workouts match',
        subtitle: 'Try a different time range or muscle group.',
        buttonLabel: 'Clear filters',
        onButtonTap: _clearFilters,
      );
    } else if (filtered.isEmpty) {
      body = _EmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'No recent workouts',
        subtitle: 'Nothing logged in the ${_period.toLowerCase()}.',
      );
    } else {
      body = RefreshIndicator(
        color: th.primary,
        onRefresh: _load,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final String id = (filtered[i]['workout_log_id'] ?? '').toString();
            return _WorkoutCard(
              key: ValueKey(id),
              data: filtered[i],
              onTap: () => _tapWorkout(id),
              onMenuTap: () => _tapMenu(id),
            );
          },
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Container(
        color: th.primaryBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _searchField(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: SizedBox(
                height: 44,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      child: _FilterPill(
                        icon: Icons.calendar_today_outlined,
                        label: _period,
                        active: _period != _defaultPeriod,
                        onTap: _openPeriodSheet,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _FilterPill(
                        icon: Icons.fitness_center_rounded,
                        label: _muscle ?? _musclePlaceholder,
                        active: _muscle != null,
                        onTap: _openMuscleSheet,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _searchField(BuildContext ctx) {
    final th = FlutterFlowTheme.of(ctx);
    final bool dark = _isDark(ctx);
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: th.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: dark ? Border.all(color: th.alternate) : null,
        boxShadow: dark
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
        children: [
          Icon(Icons.search_rounded, size: 20, color: th.secondaryText),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _q = v.trim()),
              textInputAction: TextInputAction.search,
              cursorColor: th.primary,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Search workouts',
                hintStyle: _hs(ctx, 15, FontWeight.w400, th.secondaryText),
              ),
              style: _hs(ctx, 15, FontWeight.w400, th.primaryText),
            ),
          ),
          if (_q.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _search.clear();
                setState(() => _q = '');
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
                child: Icon(Icons.close_rounded,
                    size: 18, color: th.secondaryText),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Workout card
// ---------------------------------------------------------------------------

class _WorkoutCard extends StatefulWidget {
  const _WorkoutCard({
    super.key,
    required this.data,
    required this.onTap,
    required this.onMenuTap,
  });

  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  @override
  State<_WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<_WorkoutCard> {
  bool _down = false;
  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _formatDate(String raw) {
    final dt = _parseDate(raw);
    if (dt == null) return raw.trim();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final int diff = today.difference(day).inDays;
    final String time = '${_two(dt.hour)}:${_two(dt.minute)}';
    if (diff == 0) return 'Today · $time';
    if (diff == 1) return 'Yesterday · $time';
    final String base =
        '${_weekdays[dt.weekday - 1]}, ${_months[dt.month - 1]} ${dt.day}';
    if (dt.year != now.year) return '$base, ${dt.year} · $time';
    return '$base · $time';
  }

  static String _formatThousands(int n) {
    final String s = n.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return n < 0 ? '-$buf' : buf.toString();
  }

  // The history query's duration_seconds column is stored in MILLISECONDS
  // (same as WorkoutSummaryView reads it). Returns [value, unit].
  static List<String> _formatDuration(int ms) {
    final int seconds = (ms / 1000).round();
    if (seconds < 60) return ['$seconds', 'sec'];
    final int minutes = (seconds / 60).round();
    if (minutes < 60) return ['$minutes', 'min'];
    return ['${minutes ~/ 60}:${_two(minutes % 60)}', 'h'];
  }

  Widget _statTile(BuildContext ctx, IconData icon, String label, String value,
      [String? unit]) {
    final th = FlutterFlowTheme.of(ctx);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: th.primaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: th.secondaryText),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _hs(ctx, 12, FontWeight.w500, th.secondaryText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: _hs(ctx, 18, FontWeight.w700, th.primaryText),
                  ),
                  if (unit != null && unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: _hs(ctx, 12, FontWeight.w500, th.secondaryText),
                    ),
                ],
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final bool dark = _isDark(context);
    final Color accent = _accent(context);
    final Map<String, dynamic> d = widget.data;

    final String name = (d['workout_name'] ?? 'Workout').toString();
    final String dateLabel = _formatDate((d['created_at'] ?? '').toString());
    final int totalSets = _toInt(d['total_sets']);
    final int volume = _toInt(d['volume']);
    final List<String> duration =
        _formatDuration(_toInt(d['duration_seconds']));
    final int analyzedSets = _toInt(d['analyzed_sets']);
    final List<String> muscles = _splitMuscles(d['main_muscle_groups']);

    final Widget card = Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: th.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
        border: dark ? Border.all(color: th.alternate) : null,
        boxShadow: dark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A101828),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
                BoxShadow(
                  color: Color(0x0F101828),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: name + AI badge + date, options button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _hs(
                                context, 20, FontWeight.w700, th.primaryText,
                                ls: -0.2),
                          ),
                        ),
                        if (analyzedSets > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
                            decoration: BoxDecoration(
                              color: th.primary.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome_rounded,
                                    size: 12, color: accent),
                                const SizedBox(width: 4),
                                Text(
                                  analyzedSets == 1
                                      ? '1 set analyzed'
                                      : '$analyzedSets sets analyzed',
                                  style:
                                      _hs(context, 12, FontWeight.w600, accent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (dateLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        dateLabel,
                        style:
                            _hs(context, 13, FontWeight.w400, th.secondaryText),
                      ),
                    ],
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(12, -10),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Workout options',
                    icon: Icon(Icons.more_vert_rounded,
                        size: 20, color: th.secondaryText),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      widget.onMenuTap();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Stats
          Row(
            children: [
              Expanded(
                child: _statTile(
                    context, Icons.layers_outlined, 'Sets', '$totalSets'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statTile(context, Icons.fitness_center_rounded,
                    'Volume', _formatThousands(volume), 'kg'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statTile(context, Icons.schedule_rounded, 'Time',
                    duration[0], duration[1]),
              ),
            ],
          ),

          // Muscle chips
          if (muscles.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final m in muscles)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: th.primaryBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      m,
                      style: _hs(context, 12, FontWeight.w500, th.primaryText),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          // Footer hint
          Container(
            height: 46,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: th.alternate)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'View full summary',
                  style: _hs(context, 14, FontWeight.w600, accent),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: accent),
              ],
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: card,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButtonTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: th.alternate,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: th.secondaryText),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: _hs(context, 18, FontWeight.w700, th.primaryText),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: _hs(context, 14, FontWeight.w400, th.secondaryText,
                  height: 1.4),
            ),
            if (buttonLabel != null) ...[
              const SizedBox(height: 20),
              _PillButton(label: buttonLabel!, onTap: onButtonTap),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Solid pill button with press feedback
// ---------------------------------------------------------------------------

class _PillButton extends StatefulWidget {
  const _PillButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
  bool _down = false;
  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) {
        _set(false);
        HapticFeedback.selectionClick();
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: AnimatedOpacity(
          opacity: _down ? 0.7 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: _hs(context, 14, FontWeight.w600, Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter pill (icon + label + chevron, press feedback, active tint)
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
    final bool dark = _isDark(context);
    final Color accent = _accent(context);
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
              border: (!widget.active && dark)
                  ? Border.all(color: th.alternate)
                  : null,
              boxShadow: (widget.active || dark)
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
                    style: _hs(
                      context,
                      14,
                      widget.active ? FontWeight.w600 : FontWeight.w500,
                      fg,
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
    required this.title,
    required this.periods,
    required this.premiumOnly,
    required this.isPremium,
    required this.selected,
    required this.lockedResult,
  });

  final String title;
  final List<String> periods;
  final List<bool> premiumOnly;
  final bool isPremium;
  final String selected;
  final String lockedResult;

  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final Color accent = _accent(context);
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    // No SafeArea: the sheet background runs to the screen edge; the
    // home-indicator space is added as padding inside it.
    return Container(
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
            style: _hs(context, 20, FontWeight.w600, th.primaryText),
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
          SizedBox(height: 8 + bottomInset),
        ],
      ),
    );
  }

  Widget _row(
      BuildContext context, FlutterFlowTheme th, Color accent, int index) {
    final String label = periods[index];
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
              style: _hs(context, 17,
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

// ---------------------------------------------------------------------------
// Muscle bottom sheet
// ---------------------------------------------------------------------------

class _MuscleSheet extends StatefulWidget {
  const _MuscleSheet({
    required this.title,
    required this.allLabel,
    required this.muscles,
    required this.selected,
  });

  final String title;
  final String allLabel;
  final List<String> muscles;
  final String? selected; // null = All

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
    final double maxH = MediaQuery.of(context).size.height * 0.85;
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final List<String> filtered = _q.isEmpty
        ? widget.muscles
        : widget.muscles
            .where((m) => m.toLowerCase().contains(_q.toLowerCase()))
            .toList();
    final bool showAll =
        _q.isEmpty || widget.allLabel.toLowerCase().contains(_q.toLowerCase());

    final TextStyle rowStyle =
        _hs(context, 18, FontWeight.w500, th.primaryText);

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

    // No SafeArea: the sheet background runs to the screen edge; the
    // home-indicator space is part of the list's bottom padding so the last
    // row can still scroll clear of it.
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
            widget.title,
            style: _hs(context, 26, FontWeight.w600, th.primaryText),
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
                        hintText: 'Search Muscle',
                        hintStyle:
                            _hs(context, 16, FontWeight.w400, th.secondaryText),
                      ),
                      style: _hs(context, 16, FontWeight.w400, th.primaryText),
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
              padding: EdgeInsets.only(bottom: 12 + bottomInset),
              children: [
                if (showAll) ...[
                  row(
                    leading: Icon(Icons.grid_view_rounded,
                        size: 30, color: th.primaryText),
                    text: widget.allLabel,
                    selected: widget.selected == null,
                    onTap: () => Navigator.of(context).pop(widget.allLabel),
                  ),
                  Divider(height: 1, color: th.alternate),
                ],
                for (int i = 0; i < filtered.length; i++) ...[
                  row(
                    leading: ExerciseAssetImage(
                      width: 70,
                      height: 70,
                      exerciseName: exerciseImageName(filtered[i]),
                      borderRadius: 8,
                    ),
                    text: filtered[i],
                    selected: widget.selected == filtered[i],
                    onTap: () => Navigator.of(context).pop(filtered[i]),
                  ),
                  if (i < filtered.length - 1)
                    Divider(height: 1, color: th.alternate),
                ],
                if (!showAll && filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No muscle groups found',
                        style:
                            _hs(context, 14, FontWeight.w400, th.secondaryText),
                      ),
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
