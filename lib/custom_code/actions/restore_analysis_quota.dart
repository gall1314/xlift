// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '/app_state.dart';
import 'xlift_log_add.dart';

/// Restores the free-tier analysis quota on app init and writes it
/// DIRECTLY to App State `analysisCount` - no output wiring needed.
///
/// Count = distinct usage events in the current week from:
///   1. Supabase `analysis_usage` (already synced)
///   2. Hive `pendingAnalysisUsage` (queued offline, not yet synced)
/// De-duplicated by id.
///
/// PERIOD: calendar week, starting Monday 00:00 local time.
///
/// App State is updated ONLY if the server query succeeded. Offline /
/// logged out -> App State is left untouched.
/// NEVER throws.
Future restoreAnalysisQuota() async {
  // ---- period start (UTC) ----
  // Monday 00:00 local. The DateTime constructor normalizes the day
  // offset (month/year rollover, DST) - no Duration arithmetic needed.
  // Week starting Sunday instead? Use (now.weekday % 7).
  final DateTime now = DateTime.now();
  final DateTime periodStart =
      DateTime(now.year, now.month, now.day - (now.weekday - 1)).toUtc();
  final String periodStartIso = periodStart.toIso8601String();

  final Set<String> ids = {};
  int pendingCount = 0;

  // ---- 1. pending Hive events (works offline) ----
  try {
    await Hive.initFlutter(); // idempotent
    final Box box = await Hive.openBox('pendingAnalysisUsage');
    for (final key in box.keys.toList()) {
      final raw = box.get(key);
      if (raw is! Map) continue;
      final DateTime? usedAt =
          DateTime.tryParse((raw['used_at'] ?? '').toString());
      if (usedAt == null || usedAt.isBefore(periodStart)) continue;
      final String id = (raw['id'] ?? '').toString();
      if (id.isEmpty) continue;
      ids.add(id);
      pendingCount++;
    }
  } catch (e) {
    xliftLogAdd('[quota] hive read failed: $e');
  }

  // ---- 2. server events ----
  final String? uid = SupaFlow.client.auth.currentUser?.id;
  if (uid == null || uid.isEmpty) {
    xliftLogAdd('[quota] SKIPPED - no authenticated user, App State untouched');
    return;
  }

  try {
    final List<dynamic> rows = await SupaFlow.client
        .from('analysis_usage')
        .select('id')
        .eq('user_id', uid)
        .gte('used_at', periodStartIso)
        .timeout(const Duration(seconds: 8));

    int serverCount = 0;
    for (final r in rows) {
      if (r is! Map) continue;
      final String id = (r['id'] ?? '').toString();
      if (id.isEmpty) continue;
      ids.add(id);
      serverCount++;
    }

    final int count = ids.length;
    FFAppState().update(() {
      FFAppState().analysisCount = count;
    });

    xliftLogAdd('[quota] RESTORED analysisCount=$count server=$serverCount '
        'pending=$pendingCount since=$periodStartIso');
  } catch (e) {
    xliftLogAdd('[quota] FAILED - App State untouched '
        '(pending=$pendingCount since=$periodStartIso): $e');
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
