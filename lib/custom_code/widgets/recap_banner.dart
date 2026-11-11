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

import 'package:intl/intl.dart' as intl show NumberFormat;

/// Entry card for the training recap, made for the top of the Statistics
/// Overview tab: "Your recap · Last 7 days / 4 workouts · 5,820 kg" with a
/// play button. Tapping it fires [onTap] (navigate to the Recap page and
/// pass the same time range to RecapView).
///
/// Fully self-managed: counts the workouts and sums the volume itself, with
/// the same rules as RecapView (saved workout volume, or the sets when a
/// workout has none), so both always show the same numbers. Reloads when
/// [userId] or [timeRange] changes.
///
/// [timeRange]: 'Last 7 days' | 'Last 30 days' (default) | 'Last 90 days' |
/// 'This month' | 'This year'; anything else ('All time') means no limit.
///
/// With no workouts in the range the card stays in place, shows a short
/// "no workouts yet" line, hides the play button and ignores taps.
///
/// Look: flat, no shadow, tinted with the theme primary (the same mint as
/// the range selector). Recommended size: width infinity, height 76.
///
/// Localization: reads the app language from FFLocalizations (no parameter).
class RecapBanner extends StatefulWidget {
  const RecapBanner({
    super.key,
    this.width,
    this.height,
    required this.userId,
    this.timeRange,
    this.onTap,
  });

  final double? width;
  final double? height;
  final String userId;
  final String? timeRange;
  final Future Function()? onTap;

  @override
  State<RecapBanner> createState() => _RecapBannerState();
}

// ---------------------------------------------------------------------------
// Texts (order: en, es, he, de, fr)
// ---------------------------------------------------------------------------

const List<String> _rbLangs = ['en', 'es', 'he', 'de', 'fr'];

const Map<String, List<String>> _rbS = {
  'recap': [
    'Your recap',
    'Tu resumen',
    'הריקאפ שלך',
    'Dein Recap',
    'Ton récap'
  ],
  'workouts': ['workouts', 'entrenos', 'אימונים', 'Workouts', 'séances'],
  'workout1': ['1 workout', '1 entreno', 'אימון אחד', '1 Workout', '1 séance'],
  'empty': [
    'No workouts in this range yet',
    'Aún no hay entrenos aquí',
    'עדיין אין אימונים בטווח הזה',
    'Noch keine Workouts hier',
    'Pas encore de séance ici',
  ],
  'Last 7 days': [
    'Last 7 days',
    'Últimos 7 días',
    '7 הימים האחרונים',
    'Letzte 7 Tage',
    '7 derniers jours',
  ],
  'Last 30 days': [
    'Last 30 days',
    'Últimos 30 días',
    '30 הימים האחרונים',
    'Letzte 30 Tage',
    '30 derniers jours',
  ],
  'Last 90 days': [
    'Last 90 days',
    'Últimos 90 días',
    '90 הימים האחרונים',
    'Letzte 90 Tage',
    '90 derniers jours',
  ],
  'This month': [
    'This month',
    'Este mes',
    'החודש',
    'Dieser Monat',
    'Ce mois-ci'
  ],
  'This year': ['This year', 'Este año', 'השנה', 'Dieses Jahr', 'Cette année'],
  'All time': ['All time', 'Todo', 'כל הזמן', 'Gesamt', 'Depuis le début'],
};

String _rbTr(String lang, String key) {
  final List<String>? row = _rbS[key];
  if (row == null) return key;
  final int i = _rbLangs.indexOf(lang);
  return row[i < 0 ? 0 : i];
}

String _rbLang(BuildContext ctx) {
  try {
    final l = FFLocalizations.of(ctx).languageCode.trim().toLowerCase();
    return l.isEmpty ? 'en' : l;
  } catch (_) {
    return 'en';
  }
}

String _rbRangeLabel(String lang, String key) {
  const List<String> known = [
    'Last 7 days',
    'Last 30 days',
    'Last 90 days',
    'This month',
    'This year',
  ];
  return _rbTr(lang, known.contains(key) ? key : 'All time');
}

// ---------------------------------------------------------------------------
// Data helpers (same rules as RecapView)
// ---------------------------------------------------------------------------

DateTime? _rbRangeStart(String key, DateTime today) {
  switch (key) {
    case 'Last 7 days':
      return DateTime(today.year, today.month, today.day - 6);
    case 'Last 30 days':
      return DateTime(today.year, today.month, today.day - 29);
    case 'Last 90 days':
      return DateTime(today.year, today.month, today.day - 89);
    case 'This month':
      return DateTime(today.year, today.month, 1);
    case 'This year':
      return DateTime(today.year, 1, 1);
    default:
      return null; // All time
  }
}

double _rbToD(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().trim()) ?? 0.0;
}

DateTime? _rbParseDt(dynamic raw) {
  final s = (raw ?? '').toString().trim();
  if (s.isEmpty) return null;
  final parsed = DateTime.tryParse(s);
  if (parsed == null) return null;
  return parsed.isUtc ? parsed.toLocal() : parsed;
}

String _rbFmtInt(String lang, num v) {
  try {
    return intl.NumberFormat.decimalPattern(lang).format(v.round());
  } catch (_) {
    return v.round().toString();
  }
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class _RecapBannerState extends State<RecapBanner> {
  int _workouts = 0;
  double _volume = 0.0;
  bool _loaded = false;
  int _req = 0;

  String get _range {
    final String r = (widget.timeRange ?? '').trim();
    return r.isEmpty ? 'Last 30 days' : r;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RecapBanner old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId || old.timeRange != widget.timeRange) {
      _load();
    }
  }

  Future<void> _load() async {
    final int req = ++_req;
    int workouts = 0;
    double volume = 0.0;
    try {
      final db = SQLiteManager.instance.database;
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      final DateTime? from = _rbRangeStart(_range, today);

      final wRows = await db.rawQuery(
        'SELECT id, created_at, volume FROM workout_log WHERE user_id = ?',
        [widget.userId],
      );
      final Map<String, double> saved = {};
      for (final r in wRows) {
        final String id = (r['id'] ?? '').toString();
        final DateTime? dt = _rbParseDt(r['created_at']);
        if (id.isEmpty || dt == null) continue;
        if (from != null && dt.isBefore(from)) continue;
        saved[id] = _rbToD(r['volume']);
      }
      workouts = saved.length;

      // Only when a workout has no saved volume: fall back to its sets.
      final Map<String, double> calc = {};
      if (saved.values.any((v) => v <= 0)) {
        final sRows = await db.rawQuery(
          'SELECT sl.workout_log_id AS wid, '
          'SUM((CASE WHEN COALESCE(sl.is_kg, 1) = 1 THEN sl.weight '
          'ELSE sl.weight * 0.453592 END) * sl.reps) AS vol '
          'FROM set_log sl '
          'JOIN workout_log wl ON wl.id = sl.workout_log_id '
          'JOIN exercise e ON e.id = sl.exercise_id '
          'WHERE wl.user_id = ? AND COALESCE(e.is_assisted, 0) = 0 '
          'AND sl.weight > 0 AND sl.reps > 0 '
          'GROUP BY sl.workout_log_id',
          [widget.userId],
        );
        for (final r in sRows) {
          calc[(r['wid'] ?? '').toString()] = _rbToD(r['vol']);
        }
      }
      for (final e in saved.entries) {
        volume += e.value > 0 ? e.value : (calc[e.key] ?? 0.0);
      }
    } catch (_) {}

    if (!mounted || req != _req) return;
    setState(() {
      _workouts = workouts;
      _volume = volume;
      _loaded = true;
    });
  }

  String _title(String lang) {
    if (!_loaded) return '';
    if (_workouts <= 0) return _rbTr(lang, 'empty');
    final String w = _workouts == 1
        ? _rbTr(lang, 'workout1')
        : _rbFmtInt(lang, _workouts) + ' ' + _rbTr(lang, 'workouts');
    if (_volume < 1) return w;
    return w + ' · ' + _rbFmtInt(lang, _volume) + ' kg';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final String lang = _rbLang(context);
    final bool has = _loaded && _workouts > 0;

    final Color primary = theme.primary;
    final bool light = theme.secondaryBackground.computeLuminance() > 0.5;
    final Color ink = light ? Colors.black : Colors.white;
    final Color bg = Color.alphaBlend(
      primary.withAlpha(light ? 0x38 : 0x40),
      theme.secondaryBackground,
    );
    final Color border = primary.withAlpha(0x59);
    final Color strong = Color.lerp(primary, ink, light ? 0.68 : 0.78)!;
    final Color soft = Color.lerp(primary, ink, light ? 0.42 : 0.5)!;

    final TextStyle eyebrow = theme.bodyMedium.copyWith(
      fontSize: 12.0,
      height: 1.2,
      fontWeight: FontWeight.w600,
      color: soft,
    );
    final TextStyle title = theme.bodyMedium.copyWith(
      fontSize: has ? 17.0 : 15.0,
      height: 1.25,
      fontWeight: FontWeight.w700,
      color: has ? strong : soft,
    );

    final BorderRadius radius = BorderRadius.circular(18.0);

    return MediaQuery.withNoTextScaling(
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 76.0,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: border, width: 1.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: has
                ? () {
                    widget.onTap?.call();
                  }
                : null,
            splashColor: primary.withAlpha(0x22),
            highlightColor: primary.withAlpha(0x14),
            child: Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 14.0, 0.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _rbTr(lang, 'recap') +
                              ' · ' +
                              _rbRangeLabel(lang, _range),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: eyebrow,
                        ),
                        const SizedBox(height: 4.0),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            _title(lang),
                            maxLines: 1,
                            style: title,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (has) ...[
                    const SizedBox(width: 12.0),
                    Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 26.0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
