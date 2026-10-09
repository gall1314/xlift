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

import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'xlift_log_add.dart';

/// Queues ONE form-analysis usage event (free-tier quota) in Hive.
///
/// Call right after an analysis finishes - independent of whether the
/// workout is saved later. Only successful analyses count (>= 1 rep);
/// failed analyses (no pose, 0 reps) are not charged to the user.
///
/// Writes to Hive only (fast, offline-safe). The upload to Supabase
/// `analysis_usage` happens in syncAllPending like every other queue.
/// `used_at` is UTC so the server-side 7-day window is exact.
///
/// NEVER throws. Returns true if an event was queued.
Future<bool> logAnalysisUsage(dynamic analysisResult) async {
  try {
    int reps = 0;
    if (analysisResult is Map) {
      final dynamic v =
          analysisResult['squat_count'] ?? analysisResult['total_reps'];
      if (v is num) {
        reps = v.toInt();
      } else if (v != null) {
        reps = int.tryParse(v.toString()) ?? 0;
      }
    }

    if (reps <= 0) {
      xliftLogAdd('[usage] SKIPPED - analysis has no reps (not charged)');
      return false;
    }

    // RFC 4122 v4 UUID - makes retries idempotent (upsert on id).
    final Random rnd = Random.secure();
    final List<int> b = List<int>.generate(16, (_) => rnd.nextInt(256));
    b[6] = (b[6] & 0x0F) | 0x40;
    b[8] = (b[8] & 0x3F) | 0x80;
    final String h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    final String id = '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';

    await Hive.initFlutter(); // idempotent
    final Box box = await Hive.openBox('pendingAnalysisUsage');
    await box.add({
      'id': id,
      'used_at': DateTime.now().toUtc().toIso8601String(),
    });

    xliftLogAdd('[usage] QUEUED id=$id reps=$reps pending=${box.length}');
    return true;
  } catch (e) {
    xliftLogAdd('[usage] FAILED to queue: $e');
    return false;
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
