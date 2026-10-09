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

/// One row of 7 day dots for the current week. Filled = trained that day,
/// ring = today. Runs the `weekWorkoutDays` SQLite query itself.
/// Reloads when userId or refreshTrigger changes.
class WeeklyProgressStrip extends StatefulWidget {
  const WeeklyProgressStrip({
    super.key,
    this.width,
    this.height,
    this.userId,
    this.startOnMonday,
    this.accentColor,
    this.refreshTrigger,
  });

  final double? width;
  final double? height;
  final String? userId;
  final bool? startOnMonday;
  final Color? accentColor;
  final String? refreshTrigger;

  @override
  State<WeeklyProgressStrip> createState() => _WeeklyProgressStripState();
}

class _WeeklyProgressStripState extends State<WeeklyProgressStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  Set<DateTime> _days = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WeeklyProgressStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.refreshTrigger != widget.refreshTrigger) {
      _load();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  DateTime _day(DateTime d) {
    final l = d.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  DateTime? _parse(dynamic v) {
    if (v == null) return null;
    DateTime fromEpoch(num n) =>
        DateTime.fromMillisecondsSinceEpoch((n > 1e12 ? n : n * 1000).toInt());
    if (v is num) return fromEpoch(v);
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final n = num.tryParse(s);
    if (n != null) return fromEpoch(n);
    return DateTime.tryParse(s.replaceFirst(' ', 'T'));
  }

  Future<void> _load() async {
    final uid = (widget.userId ?? '').trim();
    if (uid.isEmpty) {
      if (mounted) setState(() => _days = {});
      return;
    }
    try {
      final rows = await SQLiteManager.instance.weekWorkoutDays(userId: uid);
      final days = <DateTime>{};
      for (final r in rows) {
        final d = _parse(r.data['created_at']);
        if (d != null) days.add(_day(d));
      }
      if (!mounted) return;
      final first = !_loaded;
      setState(() {
        _days = days;
        _loaded = true;
      });
      if (first) _ctrl.forward(from: 0);
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final accent = widget.accentColor ?? theme.primary;
    final textColor = theme.primaryText;
    final muted = theme.secondaryText;
    final idleBorder = theme.alternate;
    final mondayFirst = widget.startOnMonday ?? false;

    final today = _day(DateTime.now());
    final offset = mondayFirst ? today.weekday - 1 : today.weekday % 7;
    final weekStart = DateTime(today.year, today.month, today.day - offset);

    final letters = mondayFirst
        ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    final weekDays = List.generate(
        7, (i) => DateTime(weekStart.year, weekStart.month, weekStart.day + i));
    final trained = weekDays.where(_days.contains).length;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Semantics(
        label: 'This week: trained $trained ${trained == 1 ? 'day' : 'days'}',
        child: Row(
          children: List.generate(7, (i) {
            final day = weekDays[i];
            final isDone = _days.contains(day);
            final isToday = day == today;
            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    letters[i],
                    style: TextStyle(
                      color: isToday ? textColor : muted,
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _dot(i, isDone, isToday, accent, idleBorder),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _dot(
      int i, bool isDone, bool isToday, Color accent, Color idleBorder) {
    const size = 28.0;
    if (!isDone) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isToday ? accent : idleBorder,
            width: isToday ? 2 : 1.5,
          ),
        ),
      );
    }
    final start = (i * 0.08).clamp(0.0, 0.55);
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, start + 0.45, curve: Curves.easeOutBack),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
