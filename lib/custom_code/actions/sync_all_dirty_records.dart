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

import 'dart:convert';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

Future<bool> syncAllDirtyRecords() async {
  print('[SYNC] ===== START ${DateTime.now().toIso8601String()} =====');

  // 1) אינטרנט (כמו אצלך)
  final online = await InternetConnectionCheckerPlus().hasConnection;
  print('[SYNC] online=$online');
  if (!online) return false;

  // 2) session של Supaעbase (קריטי ל-RLS)
  final client = Supabase.instance.client;
  final session = client.auth.currentSession;
  if (session == null) {
    print('[SYNC][ERR] No Supabase session/token → RLS will block');
    return false;
  }

  // 3) DB מקומי
  final db = await SQLiteManager.instance.database;

  // טבלאות וזהות שמית בין מקומי↔שרת
  const idCol = 'id';
  const order = ['workout', 'workout_log', 'workout_exercise', 'set_log'];

  // המרות טיפוסים נפוצות (0/1→bool, תאריכים→ISO)
  dynamic fixVal(String key, dynamic v) {
    if (v == null) return null;

    const boolKeys = {
      'is_kg',
      'is_dropset',
      'is_warmup',
      'is_timed',
      'is_bodyweight',
      'is_assisted',
      'is_deleted'
    };
    if (boolKeys.contains(key)) {
      if (v is bool) return v;
      if (v is int) return v != 0;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
    }

    const dateKeys = {'created_at', 'updated_at', 'performed_at', 'started_at'};
    if (dateKeys.contains(key)) {
      if (v is int) {
        return DateTime.fromMillisecondsSinceEpoch(v).toUtc().toIso8601String();
      }
      if (v is String) {
        final dt = DateTime.tryParse(v);
        if (dt != null) return dt.toUtc().toIso8601String();
        final s = v.trim().toLowerCase().replaceAll('ms', '').trim();
        final ms = int.tryParse(s);
        if (ms != null) {
          return DateTime.fromMillisecondsSinceEpoch(ms)
              .toUtc()
              .toIso8601String();
        }
      }
    }
    return v;
  }

  // לוג קצר של סכימת הטבלאות המקומיות (יעזור לאבחון)
  try {
    final tables =
        await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    print('[SYNC] local tables: ${tables.map((t) => t['name']).toList()}');
  } catch (e) {
    print('[SYNC][ERR] local DB not accessible: $e');
    return false;
  }

  for (final table in order) {
    List<Map<String, dynamic>> dirty = [];
    try {
      dirty = await db.query(table, where: 'is_dirty = 1');
    } catch (e) {
      print('[SYNC][ERR] Query failed on $table: $e');
      continue;
    }

    print('[SYNC] $table dirty=${dirty.length}');
    if (dirty.isEmpty) continue;

    // הסרת is_dirty + המרות טיפוסים
    final payload = dirty.map((row) {
      final m = Map<String, dynamic>.from(row)..remove('is_dirty');
      final fixed = <String, dynamic>{};
      m.forEach((k, v) => fixed[k] = fixVal(k, v));
      return fixed;
    }).toList();

    try {
      // 4) Upsert עם on_conflicft=id דרך Supabase client (מטפל ב־Authorfization עבורך)
      await client.from(table).upsert(payload, onConflict: idCol);

      // 5) אפס is_dirty מקומית
      final batch = db.batch();
      for (final row in dirty) {
        final idVal = row[idCol];
        if (idVal == null) continue;
        batch.update(
          table,
          {'is_dirty': 0},
          where: '$idCol = ?',
          whereArgs: [idVal],
        );
      }
      await batch.commit(noResult: true);

      print('[SYNC] $table upsert OK (${dirty.length})');
    } catch (e) {
      print('[SYNC][ERR] upsert $table failed: $e');
      // לא מאפסים is_dirty במקרה של כישלון
    }
  }

  print('[SYNC] DONE');
  return true;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
