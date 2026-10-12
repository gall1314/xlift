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
import 'dart:convert';
import 'xlift_log_add.dart';

/// ONE-SHOT CLOUD RESTORE: Supabase -> local SQLite, for one user.
///
/// Order (FK-safe): users -> workout -> workout_exercise -> exercise_sets ->
/// exercise (user's custom only) -> workout_log -> set_log -> set_analysis
/// (best-effort, skipped silently if the mirror differs)
///
/// Rules - Every Supabase call has a 20s timeout. Never hangs, never throws.
/// - Paged (no 1000-row cap, no IN-list URL limits except set_analysis, which
/// is chunked by 100 ids). - INSERT OR IGNORE by id -> rows that already
/// exist locally are kept as-is (restore never overwrites local edits).
/// `users` is the one exception: it is UPSERTed, because the cloud profile is
/// the source. - Safe to run again at any time (idempotent). - A failure in
/// one table is recorded and the run CONTINUES with the next table (children
/// of a failed parent simply won't match).
///
/// Column mapping (Supabase -> SQLite) handled here: users.is_kg bool -> 0/1;
/// date_of_birth kept as ISO text exercise_sets.order_index -> set_number;
/// target_reps text -> int; workout_id filled from the parent
/// workout_exercise; target_weight dropped exercise.no_video_illustration ->
/// no_video_ilustration (local typo); step_by_step / form_tips jsonb -> JSON
/// text; is_assisted -> 0 workout_log.duration (text, trigger-formatted) ->
/// duration_seconds as MILLISECONDS (app convention): "h:mm:ss"/"mm:ss"
/// parsed, numeric text taken as ms set_log: is_kg null -> 1, is_dropset null
/// -> 0 set_analysis: avg_depth (nullable real), reps_json (text; stored as
/// JSON text locally whatever type the cloud column is)
///
/// Returns: { success, counts:{table:{fetched,inserted,skipped}},
/// errors:[...], ms, debug_string }
Future<dynamic> restoreAllFromCloud(String? userId) async {
  final sw = Stopwatch()..start();
  const Duration callTimeout = Duration(seconds: 20);
  const int pageSize = 500;

  final String uId = (userId ?? '').trim();
  final Map<String, Map<String, int>> counts = {};
  final List<String> errors = [];
  final List<String> dbg = [];

  Map<String, dynamic> finish(bool ok) {
    final String debugString =
        '${dbg.join(' | ')} | ${sw.elapsedMilliseconds}ms'
        '${errors.isEmpty ? '' : ' | ERRORS: ${errors.join(' ; ')}'}';
    xliftLogAdd('[restore] DONE success=$ok $debugString');
    return {
      'success': ok,
      'counts': counts,
      'errors': errors,
      'ms': sw.elapsedMilliseconds,
      'debug_string': debugString,
    };
  }

  if (uId.isEmpty) {
    errors.add('userId is empty');
    return finish(false);
  }
  xliftLogAdd('[restore] START user=$uId');

  // ---------------- helpers ----------------
  int? toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim()) ??
        double.tryParse(v.toString().trim())?.toInt();
  }

  double? toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim());
  }

  String? toStr(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  int flag(dynamic v, int fallback) {
    if (v == null) return fallback;
    if (v is bool) return v ? 1 : 0;
    if (v is num) return v != 0 ? 1 : 0;
    final s = v.toString().toLowerCase();
    if (s == 'true' || s == '1') return 1;
    if (s == 'false' || s == '0') return 0;
    return fallback;
  }

  String? jsonText(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    try {
      return jsonEncode(v);
    } catch (_) {
      return v.toString();
    }
  }

  String nowIso() => DateTime.now().toIso8601String();

  /// workout_log.duration from Supabase (text via trigger) -> milliseconds.
  int durationToMs(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    final s = v.toString().trim();
    if (s.isEmpty) return 0;
    if (s.contains(':')) {
      final parts =
          s.split(':').map((p) => int.tryParse(p.trim()) ?? 0).toList();
      int seconds = 0;
      for (final p in parts) {
        seconds = seconds * 60 + p;
      }
      return seconds * 1000;
    }
    return int.tryParse(s) ?? double.tryParse(s)?.toInt() ?? 0;
  }

  Future<List<dynamic>> timed(String what, Future<dynamic> fut) async {
    final res = await fut.timeout(callTimeout, onTimeout: () {
      throw TimeoutException('$what: no response within '
          '${callTimeout.inSeconds}s');
    });
    return List<dynamic>.from(res as List);
  }

  /// Page through a table filtered by user_id.
  Future<List<Map<String, dynamic>>> fetchByUser(
      String table, String select) async {
    final out = <Map<String, dynamic>>[];
    int from = 0;
    while (true) {
      final page = await timed(
          '$table page@$from',
          SupaFlow.client
              .from(table)
              .select(select)
              .eq('user_id', uId)
              .order('id', ascending: true)
              .range(from, from + pageSize - 1));
      for (final r in page) {
        if (r is Map) out.add(Map<String, dynamic>.from(r));
      }
      if (page.length < pageSize) break;
      from += pageSize;
    }
    return out;
  }

  final db = SQLiteManager.instance.database;

  /// Run a list of (sql, args) inserts in one batch. Returns inserted count
  /// (INSERT OR IGNORE -> changes() tells us how many actually landed).
  Future<int> batchInsert(
      String table, List<List<dynamic>> rows, String sql) async {
    if (rows.isEmpty) return 0;
    final before = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
    final int cBefore = toInt(before.first['c']) ?? 0;
    final batch = db.batch();
    for (final args in rows) {
      batch.rawInsert(sql, args);
    }
    await batch.commit(noResult: true);
    final after = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
    final int cAfter = toInt(after.first['c']) ?? 0;
    return cAfter - cBefore;
  }

  void record(String table, int fetched, int inserted, {int skipped = 0}) {
    counts[table] = {
      'fetched': fetched,
      'inserted': inserted,
      'skipped': skipped,
    };
    dbg.add('$table ${fetched}f/${inserted}i'
        '${skipped > 0 ? '/${skipped}s' : ''}');
    xliftLogAdd('[restore] $table fetched=$fetched inserted=$inserted '
        'skipped=$skipped @${sw.elapsedMilliseconds}ms');
  }

  void fail(String table, Object e) {
    final msg = '$table: $e';
    errors.add(msg);
    dbg.add('$table FAIL');
    xliftLogAdd('[restore] $msg');
  }

  // ================= 1. users (UPSERT) =================
  try {
    final rows = await timed(
        'users', SupaFlow.client.from('users').select().eq('id', uId).limit(1));
    if (rows.isNotEmpty && rows.first is Map) {
      final u = Map<String, dynamic>.from(rows.first as Map);
      await db.rawInsert(
        'INSERT INTO users '
        '(id, email, username, profile_image_url, weight, height, is_kg, sex, '
        ' date_of_birth, height_is_cm, body_weight_is_kg) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) '
        'ON CONFLICT(id) DO UPDATE SET '
        ' email = excluded.email, username = excluded.username, '
        ' profile_image_url = excluded.profile_image_url, '
        ' weight = excluded.weight, height = excluded.height, '
        ' is_kg = excluded.is_kg, sex = excluded.sex, '
        ' date_of_birth = excluded.date_of_birth, '
        ' height_is_cm = excluded.height_is_cm, '
        ' body_weight_is_kg = excluded.body_weight_is_kg',
        [
          uId,
          toStr(u['email']),
          toStr(u['username']),
          toStr(u['profile_image_url']),
          toDouble(u['weight']),
          toDouble(u['height']),
          flag(u['is_kg'], 1),
          toStr(u['sex']),
          toStr(u['date_of_birth']),
          flag(u['height_is_cm'], 1),
          flag(u['body_weight_is_kg'], 1),
        ],
      );
      record('users', 1, 1);
    } else {
      record('users', 0, 0);
    }
  } catch (e) {
    fail('users', e);
  }

  // ================= 2-4. workout -> workout_exercise -> exercise_sets ====
  // One embedded fetch, paged by workout. exercise_sets has no user_id, so
  // it rides along with its parent.
  final Map<String, String> workoutIdByExerciseRow = {}; // we.id -> workout.id
  try {
    final List<List<dynamic>> wRows = [];
    final List<List<dynamic>> weRows = [];
    final List<List<dynamic>> esRows = [];
    int weSkipped = 0;

    int from = 0;
    const int wPage = 100;
    while (true) {
      final page = await timed(
          'workout page@$from',
          SupaFlow.client
              .from('workout')
              .select('*, workout_exercise(*, exercise_sets(*))')
              .eq('user_id', uId)
              .order('id', ascending: true)
              .range(from, from + wPage - 1));

      for (final w0 in page) {
        if (w0 is! Map) continue;
        final w = Map<String, dynamic>.from(w0);
        final String? wId = toStr(w['id']);
        if (wId == null) continue;

        wRows.add([
          wId,
          toStr(w['name']) ?? '',
          toStr(w['created_at']) ?? nowIso(),
          uId,
          flag(w['is_deleted'], 0),
        ]);

        final exs = w['workout_exercise'];
        if (exs is! List) continue;
        for (final we0 in exs) {
          if (we0 is! Map) continue;
          final we = Map<String, dynamic>.from(we0);
          final String? weId = toStr(we['id']);
          final int? exId = toInt(we['exercise_id']);
          if (weId == null) continue;
          if (exId == null) {
            // SQLite requires exercise_id NOT NULL.
            weSkipped++;
            continue;
          }
          workoutIdByExerciseRow[weId] = wId;
          weRows.add([
            weId,
            wId,
            exId,
            toStr(we['created_at']) ?? nowIso(),
            toInt(we['order']) ?? 0,
            toStr(we['exercise_name']) ?? '',
            toStr(we['user_id']) ?? uId,
            toInt(we['rest_seconds']),
            toStr(we['notes']),
            flag(we['is_superset'], 0),
            toStr(we['superset_group_id']),
          ]);

          final sets = we['exercise_sets'];
          if (sets is! List) continue;
          for (final s0 in sets) {
            if (s0 is! Map) continue;
            final s = Map<String, dynamic>.from(s0);
            final String? sId = toStr(s['id']);
            if (sId == null) continue;
            esRows.add([
              sId,
              weId,
              toInt(s['order_index']) ?? 1, // -> set_number
              toInt(s['target_reps']), // text -> int (null if not numeric)
              flag(s['is_warmup'], 0),
              s['is_dropset'] == null ? null : flag(s['is_dropset'], 0),
              toInt(s['drop_number']),
              wId,
              toInt(s['weighted']) ?? 1,
              toInt(s['duration_seconds']),
            ]);
          }
        }
      }
      if (page.length < wPage) break;
      from += wPage;
    }

    final int wIns = await batchInsert(
        'workout',
        wRows,
        'INSERT OR IGNORE INTO workout '
            '(id, name, created_at, user_id, is_deleted) VALUES (?, ?, ?, ?, ?)');
    record('workout', wRows.length, wIns);

    final int weIns = await batchInsert(
        'workout_exercise',
        weRows,
        'INSERT OR IGNORE INTO workout_exercise '
            '(id, workout_id, exercise_id, created_at, "order", exercise_name, '
            ' user_id, rest_seconds, notes, is_superset, superset_group_id) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
    record('workout_exercise', weRows.length, weIns, skipped: weSkipped);

    final int esIns = await batchInsert(
        'exercise_sets',
        esRows,
        'INSERT OR IGNORE INTO exercise_sets '
            '(id, workout_exercise_id, set_number, target_reps, is_warmup, '
            ' is_dropset, drop_number, workout_id, weighted, duration_seconds) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
    record('exercise_sets', esRows.length, esIns);
  } catch (e) {
    fail('workout tree', e);
  }

  // ================= 5. exercise (user's custom only) =================
  try {
    final rows = await timed(
        'exercise(custom)',
        SupaFlow.client
            .from('exercise')
            .select()
            .or('created_by_user_id.eq.$uId,owner_user_id.eq.$uId')
            .order('id', ascending: true));
    final List<List<dynamic>> exRows = [];
    for (final r0 in rows) {
      if (r0 is! Map) continue;
      final r = Map<String, dynamic>.from(r0);
      final int? id = toInt(r['id']);
      if (id == null) continue;
      exRows.add([
        id,
        toStr(r['name']),
        toStr(r['target_muscles']),
        toStr(r['short_description']),
        flag(r['is_bodyweight'], 0),
        flag(r['ai_form_analysis'], 0),
        toStr(r['long_description']),
        flag(r['is_public'], 0),
        toStr(r['created_by_user_id']) ?? toStr(r['owner_user_id']) ?? uId,
        flag(r['is_time_based'], 0),
        toStr(r['video']),
        toStr(r['illustration']),
        toStr(r['no_video_illustration']), // -> no_video_ilustration
        jsonText(r['step_by_step']),
        jsonText(r['form_tips']),
        toStr(r['equipment']),
        toStr(r['exercise_type']),
        0, // is_assisted - not in Supabase
        flag(r['is_deleted'], 0),
        flag(r['allows_bodyweight'], 0),
      ]);
    }
    final int ins = await batchInsert(
        'exercise',
        exRows,
        'INSERT OR IGNORE INTO exercise '
            '(id, name, target_muscles, short_description, is_bodyweight, '
            ' ai_form_analysis, long_description, is_public, created_by_user_id, '
            ' is_time_based, video, illustration, no_video_ilustration, '
            ' step_by_step, form_tips, equipment, exercise_type, is_assisted, '
            ' is_deleted, allows_bodyweight) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
    record('exercise', exRows.length, ins);
  } catch (e) {
    fail('exercise', e);
  }

  // ================= 6. workout_log =================
  final List<String> workoutLogIds = [];
  try {
    final rows = await fetchByUser('workout_log', '*');
    final List<List<dynamic>> wlRows = [];
    for (final r in rows) {
      final String? id = toStr(r['id']);
      final String? wId = toStr(r['workout_id']);
      if (id == null || wId == null) continue;
      workoutLogIds.add(id);
      wlRows.add([
        id,
        wId,
        uId,
        toStr(r['created_at']) ?? nowIso(),
        durationToMs(r['duration']),
        toDouble(r['volume']) ?? 0.0,
      ]);
    }
    final int ins = await batchInsert(
        'workout_log',
        wlRows,
        'INSERT OR IGNORE INTO workout_log '
            '(id, workout_id, user_id, created_at, duration_seconds, volume) '
            'VALUES (?, ?, ?, ?, ?, ?)');
    record('workout_log', wlRows.length, ins);
  } catch (e) {
    fail('workout_log', e);
  }

  // ================= 7. set_log =================
  final List<String> setLogIds = [];
  try {
    final rows = await fetchByUser('set_log', '*');
    final List<List<dynamic>> slRows = [];
    for (final r in rows) {
      final String? id = toStr(r['id']);
      if (id == null) continue;
      setLogIds.add(id);
      slRows.add([
        id,
        toStr(r['workout_log_id']),
        toInt(r['exercise_id']),
        toInt(r['set_number']),
        toInt(r['reps']),
        toDouble(r['weight']),
        toInt(r['duration_seconds']),
        toStr(r['created_at']) ?? nowIso(),
        r['is_kg'] == null ? 1 : flag(r['is_kg'], 1),
        flag(r['is_dropset'], 0),
        toInt(r['drop_number']),
        uId,
      ]);
    }
    final int ins = await batchInsert(
        'set_log',
        slRows,
        'INSERT OR IGNORE INTO set_log '
            '(id, workout_log_id, exercise_id, set_number, reps, weight, '
            ' duration_seconds, created_at, is_kg, is_dropset, drop_number, user_id) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
    record('set_log', slRows.length, ins);
  } catch (e) {
    fail('set_log', e);
  }

  // ================= 8. set_analysis (best-effort) =================
  // Supabase mirror has no user_id guarantee -> chunk by set_log ids.
  // avg_depth / reps_json may be missing on old rows -> NULL.
  try {
    final List<List<dynamic>> saRows = [];
    int fetched = 0;
    const int chunk = 100;
    for (int i = 0; i < setLogIds.length; i += chunk) {
      final ids = setLogIds.sublist(
          i, i + chunk > setLogIds.length ? setLogIds.length : i + chunk);
      final rows = await timed(
          'set_analysis chunk@$i',
          SupaFlow.client
              .from('set_analysis')
              .select()
              .inFilter('set_log_id', ids));
      for (final r0 in rows) {
        if (r0 is! Map) continue;
        final r = Map<String, dynamic>.from(r0);
        final String? id = toStr(r['id']);
        final String? sId = toStr(r['set_log_id']);
        if (id == null || sId == null) continue;
        fetched++;
        saRows.add([
          id,
          sId,
          toStr(r['analyzed_at']) ?? toStr(r['created_at']) ?? nowIso(),
          toDouble(r['score']),
          toInt(r['total_reps']),
          toInt(r['proper_reps']),
          jsonText(r['feedback']),
          toStr(r['technique_label']),
          toStr(r['technique_score_display']),
          toStr(r['form_tip']),
          toDouble(r['avg_depth']),
          jsonText(r['reps_json']), // text or jsonb -> JSON text
        ]);
      }
    }
    final int ins = await batchInsert(
        'set_analysis',
        saRows,
        'INSERT OR IGNORE INTO set_analysis '
            '(id, set_log_id, analyzed_at, score, total_reps, proper_reps, '
            ' feedback, technique_label, technique_score_display, form_tip, '
            ' avg_depth, reps_json) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
    record('set_analysis', fetched, ins);
  } catch (e) {
    // Mirror may not exist / differ - not fatal.
    dbg.add('set_analysis skipped');
    xliftLogAdd('[restore] set_analysis skipped: $e');
  }

  return finish(errors.isEmpty);
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
