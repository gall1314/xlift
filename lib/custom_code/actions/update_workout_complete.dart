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
import 'xlift_log_add.dart';

/// Updates an EXISTING workout_log in one atomic pass - the edit twin of
/// saveWorkoutComplete. The workout_log row and its id survive; everything
/// under it is wiped (set_analysis -> set_log) and rebuilt from the current
/// App State, with the same ordering, renumbering, volume and analysis
/// rules. Every row is written BOTH to SQLite AND queued in Hive.
///
/// NOTHING IS COMPARED: date, duration and volume are simply written as they
/// arrive. Pass the current value and an "unchanged" field stays the same by
/// definition. A null / empty date or a null duration keeps what is already
/// stored - that is the only fallback.
///
/// DATE: workoutDate is a String (anything DateTime.parse understands). It
/// becomes workout_log.created_at AND the created_at of every set_log row
/// rebuilt under it, so an edited workout keeps one consistent timestamp
/// instead of drifting to "now". The cloud row gets the same instant in UTC.
///
/// DURATION: written to duration_seconds exactly as it arrives, in the same
/// unit saveWorkoutComplete used - pass it the same way the workout was
/// saved.
///
/// ANALYSES are never created here - a logged workout cannot be analysed
/// again. The ones already stored are carried over: each set_analysis row
/// keeps its id and is re-pointed at the rebuilt set_log of the same
/// (exercise_id, set_number). analysisState is the whitelist - a set whose
/// analysis the user removed on screen, or whose set is gone, has its row
/// deleted. Passing null drops every analysis of this workout.
///
/// DELETIONS are queued in the Hive box 'pendingDeletes' as
/// { table, id, workout_log_id, user_id } - rename it to whatever your sync
/// worker reads, otherwise the old rows survive in the cloud and the sets
/// come back doubled.
///
/// ALL arguments are NULLABLE on purpose: FlutterFlow silently skips
/// launching a custom action when a required argument's binding resolves to
/// null. Validation happens INSIDE, loudly.
///
/// GUARANTEE: ALWAYS returns a JSON map - never throws, never leaves the
/// Action Output empty.
///   $.success  -> true / false
///   $.message  -> user-facing text for a Snackbar when success == false
///   $.workoutLogId, sets, drops, analyses, deleted, volume, duration,
///   createdAt, ms, debug
Future<dynamic> updateWorkoutComplete(
  String? workoutLogId,
  String? userId,
  int? durationMs,
  String? workoutDate,
  List<dynamic>? loggedSets,
  List<dynamic>? analysisState,
  List<dynamic>? exerciseSets,
) async {
  final sw = Stopwatch()..start();

  String stage = 'init';
  String? failedAt;
  bool hangSuspect = false;
  final List<String> stepsDone = [];
  final Map<String, int> timings = {};
  Map<String, dynamic> inputs = {};

  Map<String, dynamic> debugBlock(String? error, String? errorType) {
    return {
      'stage': stage,
      'stepsDone': stepsDone,
      'failedAt': failedAt,
      'error': error,
      'errorType': errorType,
      'hangSuspect': hangSuspect,
      'inputs': inputs,
      'timingsMs': timings,
      'totalMs': sw.elapsedMilliseconds,
    };
  }

  /// [message] is what the user sees. [msg] is the technical reason (log).
  Map<String, dynamic> failure(String msg, String type, String message) {
    xliftLogAdd('[updWC] FATAL at stage=$stage failedAt=$failedAt '
        'hang=$hangSuspect type=$type: $msg');
    return {
      'success': false,
      'message': message,
      'workoutLogId': (workoutLogId ?? ''),
      'sets': 0,
      'drops': 0,
      'analyses': 0,
      'deleted': 0,
      'volume': 0.0,
      'ms': sw.elapsedMilliseconds,
      'error': msg,
      'debug': debugBlock(msg, type),
    };
  }

  const String MSG_NO_SETS = 'Mark at least one set as done to save.';
  const String MSG_GENERIC = "Couldn't save your changes. Please try again.";
  const String MSG_MISSING = "This workout couldn't be found.";

  // ================= OUTER SHIELD =================
  try {
    const Duration dbTimeout = Duration(seconds: 8);

    void mark(String step) {
      stepsDone.add(step);
      timings[step] = sw.elapsedMilliseconds;
      xliftLogAdd('[updWC] ✓ $step @${sw.elapsedMilliseconds}ms');
    }

    Future<dynamic> guarded(String step, Future<dynamic> Function() fn) async {
      stage = step;
      try {
        return await fn().timeout(dbTimeout, onTimeout: () {
          hangSuspect = true;
          throw TimeoutException(
              'DB call "$step" did not return within ${dbTimeout.inSeconds}s '
              '- connection likely held by another open query/transaction');
        });
      } catch (e) {
        failedAt = step;
        rethrow;
      }
    }

    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v == null ? '' : v.toString()) ?? 0;
    }

    int? asIntOrNull(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    double asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v == null ? '' : v.toString()) ?? 0.0;
    }

    double? asDoubleOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    bool truthy(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v == null) return false;
      final String s = v.toString().trim().toLowerCase();
      return s == 'true' || s == '1';
    }

    int uuidCounter = 0;
    String uuid() {
      final int now = DateTime.now().microsecondsSinceEpoch;
      final int salt = Object().hashCode ^ (uuidCounter++);
      String hex(int v, int width) {
        return v.toRadixString(16).padLeft(width, '0').substring(0, width);
      }

      final String a = hex(now & 0xFFFFFFFF, 8);
      final String b = hex((now >> 32) & 0xFFFF, 4);
      final String c = hex(salt & 0xFFF, 3);
      final String d = hex((salt >> 12) & 0xFFF, 3);
      final String e = hex(((now ^ (salt << 20)) & 0xFFFFFFFFFFFF), 12);
      return '$a-$b-4$c-8$d-$e';
    }

    // ---- normalize nullable args (validate INSIDE, loudly) ----
    stage = 'normalize-args';
    final String logId = (workoutLogId ?? '').trim();
    final String uId = (userId ?? '').trim();
    final String dateRaw = (workoutDate ?? '').trim();
    final List<dynamic> sets = loggedSets ?? [];
    final List<dynamic> analyses = analysisState ?? [];
    final List<dynamic> exSets = exerciseSets ?? [];
    xliftLogAdd('[updWC] args: workoutLogId=${logId.isEmpty ? "NULL!" : "ok"} '
        'userId=${uId.isEmpty ? "NULL!" : "ok"} '
        'durationMs=${durationMs == null ? "keep" : durationMs} '
        'workoutDate=${dateRaw.isEmpty ? "keep" : dateRaw} '
        'loggedSets=${loggedSets == null ? "NULL!" : sets.length} '
        'analysisState=${analysisState == null ? "null(=drop all)" : analyses.length} '
        'exerciseSets=${exerciseSets == null ? "null(!volume counts all)" : exSets.length}');
    mark('normalize-args');

    // ---- assisted ids + workout order from exerciseSets (no DB read) ----
    final Set<int> assistedIds = {};
    final Map<int, int> orderByExercise = {}; // exerciseId -> position
    for (int i = 0; i < exSets.length; i++) {
      final e = exSets[i];
      if (e is! Map) continue;
      final int? exId = asIntOrNull(e['exerciseId'] ?? e['exercise_id']);
      if (exId == null) continue;
      orderByExercise.putIfAbsent(exId, () => i);
      if (truthy(e['isAssisted'] ?? e['is_assisted'])) {
        assistedIds.add(exId);
      }
    }

    // ---- inputs scan ----
    stage = 'scan-inputs';
    int doneCount = 0, dropCount = 0, analysisDoneCount = 0;
    for (final it in sets) {
      if (it is! Map) continue;
      final bool isDrop = truthy(it['isDropSet']);
      if (isDrop) dropCount++;
      if (!isDrop && truthy(it['isDone'])) doneCount++;
    }
    for (final it in analyses) {
      if (it is! Map) continue;
      final dynamic aSets = it['sets'];
      if (aSets is! List) continue;
      for (final s in aSets) {
        if (s is Map && s['analysisDone'] == true) analysisDoneCount++;
      }
    }
    inputs = {
      'workoutLogId': logId,
      'workoutLogIdWasNull': workoutLogId == null,
      'userIdSet': uId.isNotEmpty,
      'durationMs': durationMs,
      'durationKept': durationMs == null,
      'workoutDate': dateRaw,
      'dateKept': dateRaw.isEmpty,
      'loggedSetsWasNull': loggedSets == null,
      'loggedSetsTotal': sets.length,
      'loggedSetsDone': doneCount,
      'dropItems': dropCount,
      'analysisItems': analyses.length,
      'analysesDone': analysisDoneCount,
      'assistedExercises': assistedIds.length,
    };
    xliftLogAdd('[updWC] START inputs=$inputs');
    mark('scan-inputs');

    // ---- validation (loud + exact) ----
    stage = 'validate';
    if (logId.isEmpty) {
      failedAt = 'validate';
      return failure(
          workoutLogId == null
              ? 'workoutLogId binding resolved to NULL - check the binding on '
                  'the Save button'
              : 'workoutLogId is empty',
          'ValidationError',
          MSG_GENERIC);
    }
    if (uId.isEmpty) {
      failedAt = 'validate';
      return failure(
          userId == null
              ? 'userId binding resolved to NULL - check auth state'
              : 'userId is empty',
          'ValidationError',
          MSG_GENERIC);
    }
    if (loggedSets == null) {
      failedAt = 'validate';
      return failure(
          'loggedSets binding resolved to NULL - check the app state binding',
          'ValidationError',
          MSG_GENERIC);
    }
    if (doneCount == 0 && dropCount == 0) {
      failedAt = 'validate';
      return failure(
          'No completed sets to save (loggedSets has ${sets.length} items, '
              '0 done)',
          'ValidationError',
          MSG_NO_SETS);
    }
    mark('validate');

    // ================= INNER (DB work) =================
    try {
      stage = 'db-handle';
      final db = SQLiteManager.instance.database;
      mark('db-handle');

      // Hive must be initialized before opening boxes (idempotent).
      await guarded('hive-init', () => Hive.initFlutter());
      mark('hive-init');

      final Box logBox = await guarded(
          'hive-open-workoutLogs', () => Hive.openBox('pendingWorkoutLogs'));
      final Box setBox = await guarded(
          'hive-open-setLogs', () => Hive.openBox('pendingSetLogs'));
      final Box analysisBox = await guarded(
          'hive-open-analyses', () => Hive.openBox('pendingSetAnalyses'));
      final Box delBox = await guarded(
          'hive-open-deletes', () => Hive.openBox('pendingDeletes'));
      mark('hive-open');

      // ---- 1. the log must exist and be ours ----
      final List existing = await guarded(
          'load-workout_log',
          () => db.rawQuery(
                'SELECT id, workout_id, created_at, duration_seconds '
                'FROM workout_log WHERE id = ? AND user_id = ? LIMIT 1',
                [logId, uId],
              ));
      if (existing.isEmpty) {
        failedAt = 'load-workout_log';
        return failure('workout_log $logId not found for this user', 'NotFound',
            MSG_MISSING);
      }
      final Map storedLog = Map<String, dynamic>.from(existing.first as Map);
      final String workoutIdOfLog = (storedLog['workout_id'] ?? '').toString();
      mark('load-workout_log');

      // ---- 2. resolve date + duration (no comparing, just resolving) ----
      stage = 'resolve-fields';
      DateTime whenDt;
      if (dateRaw.isNotEmpty) {
        whenDt = DateTime.tryParse(dateRaw) ??
            DateTime.tryParse((storedLog['created_at'] ?? '').toString()) ??
            DateTime.now();
      } else {
        whenDt =
            DateTime.tryParse((storedLog['created_at'] ?? '').toString()) ??
                DateTime.now();
      }
      // Local SQLite keeps local time (what the stats queries compare to).
      final String whenIso = whenDt.toIso8601String();
      // The cloud row gets the same instant as an explicit UTC timestamp.
      final String whenUtcIso = whenDt.toUtc().toIso8601String();
      final int durValue = durationMs ?? asInt(storedLog['duration_seconds']);
      mark('resolve-fields(date=$whenIso dur=$durValue)');

      // ---- 3. read what is there now (nothing is deleted yet) ----
      // set_analysis has an FK to set_log, so the old set rows can only go
      // once every analysis has been moved to a new one.
      stage = 'read-existing';
      final List oldSets = await guarded(
          'load-old-set_logs',
          () => db.rawQuery(
                'SELECT id FROM set_log WHERE workout_log_id = ?',
                [logId],
              ));
      final List oldAnalyses = await guarded(
          'load-old-set_analyses',
          () => db.rawQuery(
                'SELECT a.*, s.exercise_id AS _ex, s.set_number AS _sn '
                'FROM set_analysis a '
                'INNER JOIN set_log s ON s.id = a.set_log_id '
                'WHERE s.workout_log_id = ?',
                [logId],
              ));
      // key "exerciseId|setNumber" -> the stored row
      final Map<String, Map<String, dynamic>> analysisByKey = {};
      for (final r in oldAnalyses) {
        if (r is! Map) continue;
        final Map<String, dynamic> row = Map<String, dynamic>.from(r);
        analysisByKey['${asInt(row['_ex'])}|${asInt(row['_sn'])}'] = row;
      }
      mark(
          'read-existing(sets=${oldSets.length}, analyses=${oldAnalyses.length})');

      // ---- 4. regular sets (volume accumulated in-memory) ----
      // loggedSets is in ENTRY order, not display order - sort a copy by
      // (position in exerciseSets, setNumber) so insertion and renumbering
      // follow the on-screen workout order.
      final List<dynamic> orderedSets = List<dynamic>.from(sets)
        ..sort((a, b) {
          final int ea = a is Map ? asInt(a['exerciseId']) : 0;
          final int eb = b is Map ? asInt(b['exerciseId']) : 0;
          final int pa = orderByExercise[ea] ?? 1 << 30;
          final int pb = orderByExercise[eb] ?? 1 << 30;
          if (pa != pb) return pa.compareTo(pb);
          if (ea != eb) return ea.compareTo(eb);
          final int na = a is Map ? asInt(a['setNumber']) : 0;
          final int nb = b is Map ? asInt(b['setNumber']) : 0;
          return na.compareTo(nb);
        });

      // Keys below use the ORIGINAL setNumber (what drops/analyses carry).
      final Map<String, String> setIdByKey = {};
      final Map<String, int> savedSetNoByKey = {}; // original key -> saved no.
      final Map<int, int> nextSetNoByExercise = {}; // running counter per ex.
      final Set<String> doneParents = {};
      int savedSets = 0;
      double totalVolume = 0.0;

      for (final item in orderedSets) {
        if (item is! Map) continue;
        if (truthy(item['isDropSet'])) continue;
        if (!truthy(item['isDone'])) continue;

        final int exerciseId = asInt(item['exerciseId']);
        final int setNumber = asInt(item['setNumber']);
        final String key = '$exerciseId|$setNumber';

        // Renumber sequentially per exercise: done sets 1,3 -> 1,2.
        final int savedSetNo = (nextSetNoByExercise[exerciseId] ?? 0) + 1;
        nextSetNoByExercise[exerciseId] = savedSetNo;
        savedSetNoByKey[key] = savedSetNo;

        final String setLogId = uuid();
        setIdByKey[key] = setLogId;
        doneParents.add(key);

        final int? reps = asIntOrNull(item['reps']);
        final double? weight = asDoubleOrNull(item['weight']);
        // NULL unless positive: a regular set never stores 0 in
        // duration_seconds (downstream treats NULL as "not time-based").
        final int? rawDur = asIntOrNull(item['durationMs']);
        final int? durSetMs = (rawDur != null && rawDur > 0) ? rawDur : null;
        final String tag = 'set ex=$exerciseId n=$setNumber->$savedSetNo';

        await guarded(
            'insert-set_log($tag)',
            () => db.rawInsert(
                  'INSERT OR IGNORE INTO set_log '
                  '(id, workout_log_id, created_at, exercise_id, set_number, '
                  'reps, weight, duration_seconds, is_kg, is_dropset, '
                  'drop_number, user_id) '
                  'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                  [
                    setLogId,
                    logId,
                    whenIso,
                    exerciseId,
                    savedSetNo,
                    reps,
                    weight,
                    durSetMs,
                    1,
                    0,
                    0,
                    uId,
                  ],
                ));
        await guarded(
            'hive-add-set_log($tag)',
            () => setBox.add({
                  'id': setLogId,
                  'user_id': uId,
                  'workout_log_id': logId,
                  'exercise_id': exerciseId.toString(),
                  'set_number': savedSetNo,
                  'reps': reps,
                  'weight': weight,
                  'duration_seconds': durSetMs,
                  'is_kg': 1,
                  'is_dropset': 0,
                  'drop_number': null,
                }));
        savedSets++;

        if (!assistedIds.contains(exerciseId)) {
          totalVolume += (reps ?? 0) * (weight ?? 0.0);
        }
      }
      mark('sets($savedSets)');

      // ---- 5. drop sets (volume accumulated too) ----
      int savedDrops = 0;
      for (final item in sets) {
        if (item is! Map) continue;
        if (!truthy(item['isDropSet'])) continue;

        final int exerciseId = asInt(item['exerciseId']);
        final int setNumber = asInt(item['setNumber']);
        final int dropOrder = asInt(item['dropOrder'] ?? item['dropNumber']);
        final int reps = asInt(item['reps']);
        if (reps <= 0) continue;
        final String key = '$exerciseId|$setNumber';
        if (!doneParents.contains(key)) continue;

        // Persist under the parent's RENUMBERED set_number.
        final int savedSetNo = savedSetNoByKey[key] ?? setNumber;

        final String dropId = uuid();
        final double? weight = asDoubleOrNull(item['weight']);
        final String tag =
            'drop ex=$exerciseId n=$setNumber->$savedSetNo o=$dropOrder';

        await guarded(
            'insert-set_log($tag)',
            () => db.rawInsert(
                  'INSERT OR IGNORE INTO set_log '
                  '(id, workout_log_id, created_at, exercise_id, set_number, '
                  'reps, weight, duration_seconds, is_kg, is_dropset, '
                  'drop_number, user_id) '
                  'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                  [
                    dropId,
                    logId,
                    whenIso,
                    exerciseId,
                    savedSetNo,
                    reps,
                    weight,
                    null,
                    1,
                    1,
                    dropOrder,
                    uId,
                  ],
                ));
        await guarded(
            'hive-add-set_log($tag)',
            () => setBox.add({
                  'id': dropId,
                  'user_id': uId,
                  'workout_log_id': logId,
                  'exercise_id': exerciseId.toString(),
                  'set_number': savedSetNo,
                  'reps': reps,
                  'weight': weight,
                  'duration_seconds': null,
                  'is_kg': 1,
                  'is_dropset': 1,
                  'drop_number': dropOrder,
                }));
        savedDrops++;

        if (!assistedIds.contains(exerciseId)) {
          totalVolume += reps * (weight ?? 0.0);
        }
      }
      mark('drops($savedDrops)');

      // ---- 6. workout_log: volume + duration + date, written as-is ----
      await guarded(
          'update-workout_log',
          () => db.rawUpdate(
                'UPDATE workout_log SET volume = ?, duration_seconds = ?, '
                'created_at = ? WHERE id = ? AND user_id = ?',
                [totalVolume, durValue, whenIso, logId, uId],
              ));
      await guarded(
          'hive-update-workout_log',
          () => logBox.add({
                'id': logId,
                'workout_id': workoutIdOfLog,
                'user_id': uId,
                'duration': durValue,
                'created_at': whenUtcIso,
                'volume': totalVolume,
              }));
      mark('workout_log(volume=$totalVolume dur=$durValue)');

      // ---- 7. carry the saved analyses over to the new set rows ----
      // analysisState is the whitelist: an analysis the user removed on
      // screen is simply not in it any more, so its row goes.
      stage = 'relink-analyses';
      final Set<String> keepKeys = {};
      for (final item in analyses) {
        if (item is! Map) continue;
        final int exerciseId = asInt(item['exerciseId']);
        final dynamic aSets = item['sets'];
        if (aSets is! List) continue;
        for (final sItem in aSets) {
          if (sItem is! Map) continue;
          if (sItem['analysisDone'] != true) continue;
          keepKeys.add('$exerciseId|${asInt(sItem['setNumber'])}');
        }
      }

      int movedAnalyses = 0;
      int droppedAnalyses = 0;
      for (final entry in analysisByKey.entries) {
        final String key = entry.key;
        final Map<String, dynamic> row = entry.value;
        final String analysisId = (row['id'] ?? '').toString();
        final String? newSetId = setIdByKey[key];
        final bool keep = newSetId != null && keepKeys.contains(key);

        if (keep) {
          await guarded(
              'update-set_analysis($key)',
              () => db.rawUpdate(
                    'UPDATE set_analysis SET set_log_id = ? WHERE id = ?',
                    [newSetId, analysisId],
                  ));
          // same row, new parent - the cloud upsert just updates set_log_id
          final Map<String, dynamic> cloudRow = Map<String, dynamic>.from(row)
            ..remove('_ex')
            ..remove('_sn');
          cloudRow['set_log_id'] = newSetId;
          await guarded('hive-update-set_analysis($key)',
              () => analysisBox.add(cloudRow));
          movedAnalyses++;
        } else {
          await guarded(
              'delete-set_analysis($key)',
              () => db.rawDelete(
                    'DELETE FROM set_analysis WHERE id = ?',
                    [analysisId],
                  ));
          await guarded(
              'hive-queue-delete-set_analysis($key)',
              () => delBox.add({
                    'table': 'set_analysis',
                    'id': analysisId,
                    'workout_log_id': logId,
                    'user_id': uId,
                  }));
          droppedAnalyses++;
          xliftLogAdd('[updWC] analysis DROPPED $key - '
              '${newSetId == null ? "set no longer saved" : "removed by user"}');
        }
      }
      mark('analyses(moved=$movedAnalyses, dropped=$droppedAnalyses)');

      // ---- 8. only now the old set rows can go ----
      stage = 'wipe-old-sets';
      for (final r in oldSets) {
        await guarded(
            'hive-queue-delete-set_log',
            () => delBox.add({
                  'table': 'set_log',
                  'id': r['id'],
                  'workout_log_id': logId,
                  'user_id': uId,
                }));
      }
      final List<String> oldIds = [];
      for (final r in oldSets) {
        final String id = (r['id'] ?? '').toString();
        if (id.isNotEmpty) oldIds.add(id);
      }
      if (oldIds.isNotEmpty) {
        final String marks = List.filled(oldIds.length, '?').join(',');
        await guarded(
            'delete-old-set_logs',
            () => db.rawDelete(
                  'DELETE FROM set_log WHERE id IN ($marks)',
                  oldIds,
                ));
      }
      final int deleted = oldIds.length + droppedAnalyses;
      mark('wipe-old-sets(${oldIds.length})');

      stage = 'done';
      xliftLogAdd('[updWC] DONE sets=$savedSets drops=$savedDrops '
          'analyses=$movedAnalyses dropped=$droppedAnalyses volume=$totalVolume '
          'total=${sw.elapsedMilliseconds}ms');
      return {
        'success': true,
        'message': '',
        'workoutLogId': logId,
        'sets': savedSets,
        'drops': savedDrops,
        'analyses': movedAnalyses,
        'analysesDropped': droppedAnalyses,
        'deleted': deleted,
        'volume': totalVolume,
        'duration': durValue,
        'createdAt': whenIso,
        'ms': sw.elapsedMilliseconds,
        'debug': debugBlock(null, null),
      };
    } catch (e) {
      return failure(e.toString(), e.runtimeType.toString(), MSG_GENERIC);
    }
  } catch (e) {
    try {
      return failure(e.toString(), e.runtimeType.toString(), MSG_GENERIC);
    } catch (_) {
      return {
        'success': false,
        'message': MSG_GENERIC,
        'workoutLogId': (workoutLogId ?? ''),
        'sets': 0,
        'drops': 0,
        'analyses': 0,
        'deleted': 0,
        'volume': 0.0,
        'ms': 0,
        'error': 'Unrecoverable: $e',
        'debug': {
          'stage': stage,
          'failedAt': failedAt,
          'note': 'debug block itself failed to build',
        },
      };
    }
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
