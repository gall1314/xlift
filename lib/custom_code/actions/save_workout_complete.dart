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
import 'package:hive_flutter/hive_flutter.dart';
import 'xlift_log_add.dart';

/// Saves the ENTIRE workout in one atomic pass, bypassing FlutterFlow's
/// Backend Call layer: workout_log -> regular sets -> drop sets ->
/// volume -> analyses. Every row is written BOTH to SQLite AND queued
/// in Hive. Total volume (reps x weight, skipping assisted exercises
/// via exerciseSets[].isAssisted) is computed IN-MEMORY during the set
/// loops and written straight to workout_log.volume - no read query,
/// no separate update step.
///
/// SET NUMBERING: loggedSets arrives in ENTRY order (not display order),
/// so regular sets are first sorted by (exerciseId, setNumber), then done
/// sets are renumbered sequentially PER EXERCISE (done sets 1,3 -> saved
/// as 1,2). Drop sets and analyses are matched to their parent by the
/// ORIGINAL setNumber (that's how they arrive from App State) but
/// persisted with the renumbered value so parent/drop stay consistent.
///
/// DURATION: duration_seconds is written as NULL unless the set carries a
/// positive duration - a regular set never stores 0 there, so downstream
/// queries can rely on "NULL = not time-based".
///
/// ANALYSIS EXTRAS (set_analysis.avg_depth, set_analysis.reps_json):
/// derived from analysis['reps'] — avg of reps[i].depth_pct (NULL when no
/// rep carries a depth) and a compact per-rep JSON list
/// [{"s":score,"d":depth_pct,"f":[feedback...]}, ...]. form_tip is read
/// from analysis['form_tip'] OR analysis['tip'] (the analyzers emit 'tip').
///
/// FIRST-ANALYSIS PROBE: the first set_analysis row is captured twice -
/// the map handed to INSERT ("written") and the row read back from SQLite
/// right after ("stored") - and returned as `firstAnalysisJson` for
/// on-device inspection (Snackbar / Text).
///
/// ALL arguments are NULLABLE on purpose: FlutterFlow silently skips
/// launching a custom action when a required argument's binding
/// resolves to null. Validation happens INSIDE, loudly.
///
/// GUARANTEE: ALWAYS returns a JSON map - never throws, never leaves
/// the Action Output empty.
///   $.success  -> true / false
///   $.message  -> user-facing text for a Snackbar when success == false
///                 (empty string on success)
///   $.workoutLogId, sets, drops, analyses, volume, ms, firstAnalysis,
///   firstAnalysisJson, debug
Future<dynamic> saveWorkoutComplete(
  String? workoutId,
  String? userId,
  int? durationMs,
  List<dynamic>? loggedSets,
  List<dynamic>? analysisList,
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
    xliftLogAdd('[saveWC] FATAL at stage=$stage failedAt=$failedAt '
        'hang=$hangSuspect type=$type: $msg');
    return {
      'success': false,
      'message': message,
      'workoutLogId': '',
      'sets': 0,
      'drops': 0,
      'analyses': 0,
      'volume': 0.0,
      'ms': sw.elapsedMilliseconds,
      'error': msg,
      'firstAnalysis': null,
      'firstAnalysisJson': 'no analysis (failed at $stage: $msg)',
      'debug': debugBlock(msg, type),
    };
  }

  const String MSG_NO_SETS = 'Mark at least one set as done to finish.';
  const String MSG_GENERIC = "Couldn't save your workout. Please try again.";

  // ================= OUTER SHIELD =================
  try {
    const Duration dbTimeout = Duration(seconds: 8);

    void mark(String step) {
      stepsDone.add(step);
      timings[step] = sw.elapsedMilliseconds;
      xliftLogAdd('[saveWC] ✓ $step @${sw.elapsedMilliseconds}ms');
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
    final String wId = (workoutId ?? '').trim();
    final String uId = (userId ?? '').trim();
    final int durMs = durationMs ?? 0;
    final List<dynamic> sets = loggedSets ?? [];
    final List<dynamic> analyses = analysisList ?? [];
    final List<dynamic> exSets = exerciseSets ?? [];
    xliftLogAdd('[saveWC] args: workoutId=${wId.isEmpty ? "NULL!" : "ok"} '
        'userId=${uId.isEmpty ? "NULL!" : "ok"} '
        'durationMs=${durationMs == null ? "NULL!" : durMs} '
        'loggedSets=${loggedSets == null ? "NULL!" : sets.length} '
        'analysisList=${analysisList == null ? "null(ok)" : analyses.length} '
        'exerciseSets=${exerciseSets == null ? "null(!volume counts all)" : exSets.length}');
    mark('normalize-args');

    // ---- assisted exercise ids from exerciseSets (no DB read) ----
    final Set<int> assistedIds = {};
    for (final e in exSets) {
      if (e is! Map) continue;
      final int? exId = asIntOrNull(e['exerciseId'] ?? e['exercise_id']);
      if (exId == null) continue;
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
      'workoutId': wId,
      'workoutIdWasNull': workoutId == null,
      'userIdSet': uId.isNotEmpty,
      'durationMs': durMs,
      'durationMsWasNull': durationMs == null,
      'loggedSetsWasNull': loggedSets == null,
      'loggedSetsTotal': sets.length,
      'loggedSetsDone': doneCount,
      'dropItems': dropCount,
      'analysisItems': analyses.length,
      'analysesDone': analysisDoneCount,
      'assistedExercises': assistedIds.length,
    };
    xliftLogAdd('[saveWC] START inputs=$inputs');
    mark('scan-inputs');

    // ---- validation (loud + exact) ----
    stage = 'validate';
    if (wId.isEmpty) {
      failedAt = 'validate';
      return failure(
          workoutId == null
              ? 'workoutId binding resolved to NULL - check the binding on '
                  'the Finish button'
              : 'workoutId is empty',
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
      // Not a bug - nothing is checked. Nothing gets written.
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
      final String nowIso = DateTime.now().toIso8601String();
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
      mark('hive-open');

      // ---- 1. workout_log ----
      final String workoutLogId = uuid();
      await guarded(
          'insert-workout_log',
          () => db.rawInsert(
                'INSERT OR IGNORE INTO workout_log '
                '(id, workout_id, user_id, created_at, duration_seconds) '
                'VALUES (?, ?, ?, ?, ?)',
                [workoutLogId, wId, uId, nowIso, durMs],
              ));
      await guarded(
          'hive-add-workout_log',
          () => logBox.add({
                'id': workoutLogId,
                'workout_id': wId,
                'user_id': uId,
                'duration': durMs,
              }));
      mark('workout_log');

      // ---- 2. regular sets (volume accumulated in-memory) ----
      // loggedSets is in ENTRY order, not display order - sort a copy by
      // (exerciseId, setNumber) so renumbering follows the on-screen order.
      final List<dynamic> orderedSets = List<dynamic>.from(sets)
        ..sort((a, b) {
          final int ea = a is Map ? asInt(a['exerciseId']) : 0;
          final int eb = b is Map ? asInt(b['exerciseId']) : 0;
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
                    workoutLogId,
                    nowIso,
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
                  'workout_log_id': workoutLogId,
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

      // ---- 3. drop sets (volume accumulated too) ----
      int savedDrops = 0;
      for (final item in sets) {
        if (item is! Map) continue;
        if (!truthy(item['isDropSet'])) continue;

        final int exerciseId = asInt(item['exerciseId']);
        final int setNumber = asInt(item['setNumber']);
        final int dropOrder = asInt(item['dropOrder']);
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
                    workoutLogId,
                    nowIso,
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
                  'workout_log_id': workoutLogId,
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

      // ---- 4. volume: computed in-memory, written directly ----
      await guarded(
          'update-volume',
          () => db.rawUpdate(
                'UPDATE workout_log SET volume = ? WHERE id = ?',
                [totalVolume, workoutLogId],
              ));
      mark('volume($totalVolume)');

      // ---- 5. analyses ----
      // Linked via setIdByKey using the ORIGINAL setNumber - unchanged.
      int savedAnalyses = 0;
      int skippedAnalyses = 0;
      Map<String, dynamic>? firstAnalysisWritten;
      Map<String, dynamic>? firstAnalysisStored;
      String? firstAnalysisReadbackError;

      for (final item in analyses) {
        if (item is! Map) continue;
        final int exerciseId = asInt(item['exerciseId']);
        final dynamic aSets = item['sets'];
        if (aSets is! List) continue;

        for (final s in aSets) {
          if (s is! Map) continue;
          if (s['analysisDone'] != true) continue;
          final dynamic analysis = s['analysis'];
          if (analysis is! Map) continue;

          final int setNumber = asInt(s['setNumber']);
          final String? linkedSetId = setIdByKey['$exerciseId|$setNumber'];
          if (linkedSetId == null) {
            skippedAnalyses++;
            xliftLogAdd('[saveWC] analysis SKIPPED ex=$exerciseId '
                'n=$setNumber - parent set not done/saved');
            continue;
          }

          String feedbackJson = '[]';
          final dynamic fb = analysis['feedback'];
          if (fb is List) {
            feedbackJson = jsonEncode(fb);
          } else if (fb is String && fb.trim().isNotEmpty) {
            feedbackJson = fb;
          }

          // ---- per-rep extras: avg_depth + reps_json ----
          final List<dynamic> repsList =
              analysis['reps'] is List ? analysis['reps'] as List : const [];
          final List<Map<String, dynamic>> compactReps = [];
          double depthSum = 0.0;
          int depthCount = 0;
          for (final r in repsList) {
            if (r is! Map) continue;
            final double? d = asDoubleOrNull(r['depth_pct']);
            if (d != null) {
              depthSum += d;
              depthCount++;
            }
            final dynamic rf = r['feedback'];
            compactReps.add({
              's': asDouble(r['score']),
              'd': d,
              'f': rf is List
                  ? rf.map((e) => e.toString()).toList()
                  : <String>[],
            });
          }
          final double? avgDepth =
              depthCount == 0 ? null : depthSum / depthCount;
          final String repsJson = jsonEncode(compactReps);

          final String analysisId = uuid();
          final double score = asDouble(analysis['technique_score']);
          final int totalReps = asIntOrNull(analysis['squat_count']) ??
              asIntOrNull(analysis['rep_count']) ??
              repsList.length;
          final int properReps = asInt(analysis['good_reps']);
          final String label = analysis['technique_label'] == null
              ? ''
              : analysis['technique_label'].toString();
          final String scoreDisplay =
              analysis['technique_score_display'] == null
                  ? ''
                  : analysis['technique_score_display'].toString();
          // Analyzers emit 'tip'; accept both keys.
          final dynamic tipRaw = analysis['form_tip'] ?? analysis['tip'];
          final String formTip = tipRaw == null ? '' : tipRaw.toString();
          final String tag = 'analysis ex=$exerciseId n=$setNumber';

          final Map<String, dynamic> rowWritten = {
            'id': analysisId,
            'set_log_id': linkedSetId,
            'analyzed_at': nowIso,
            'score': score,
            'total_reps': totalReps,
            'proper_reps': properReps,
            'feedback': feedbackJson,
            'technique_label': label,
            'technique_score_display': scoreDisplay,
            'form_tip': formTip,
            'avg_depth': avgDepth,
            'reps_json': repsJson,
          };

          await guarded(
              'insert-set_analysis($tag)',
              () => db.rawInsert(
                    'INSERT OR REPLACE INTO set_analysis '
                    '(id, set_log_id, analyzed_at, score, total_reps, '
                    'proper_reps, feedback, technique_label, '
                    'technique_score_display, form_tip, avg_depth, reps_json) '
                    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                    [
                      analysisId,
                      linkedSetId,
                      nowIso,
                      score,
                      totalReps,
                      properReps,
                      feedbackJson,
                      label,
                      scoreDisplay,
                      formTip,
                      avgDepth,
                      repsJson,
                    ],
                  ));
          await guarded('hive-add-set_analysis($tag)',
              () => analysisBox.add(Map<String, dynamic>.from(rowWritten)));
          savedAnalyses++;

          // ---- FIRST-ANALYSIS PROBE ----
          if (savedAnalyses == 1) {
            firstAnalysisWritten = {
              ...rowWritten,
              '_exerciseId': exerciseId,
              '_setNumber': setNumber,
              '_savedSetNo': savedSetNoByKey['$exerciseId|$setNumber'],
              '_analysisKeys': analysis.keys.map((k) => k.toString()).toList(),
            };
            try {
              final List<dynamic> rows = await guarded(
                  'readback-set_analysis($tag)',
                  () => db.rawQuery(
                        'SELECT * FROM set_analysis WHERE id = ?',
                        [analysisId],
                      ));
              if (rows.isNotEmpty && rows.first is Map) {
                firstAnalysisStored =
                    Map<String, dynamic>.from(rows.first as Map);
              } else {
                firstAnalysisReadbackError =
                    'row not found after insert (id=$analysisId)';
              }
            } catch (e) {
              firstAnalysisReadbackError = e.toString();
              failedAt = null; // readback is diagnostic only - not fatal
            }
            xliftLogAdd('[saveWC] firstAnalysis written=$firstAnalysisWritten '
                'stored=$firstAnalysisStored err=$firstAnalysisReadbackError');
          }
        }
      }
      mark('analyses($savedAnalyses,skipped=$skippedAnalyses)');

      final Map<String, dynamic>? firstAnalysis = firstAnalysisWritten == null
          ? null
          : {
              'written': firstAnalysisWritten,
              'stored': firstAnalysisStored,
              'readbackError': firstAnalysisReadbackError,
            };
      String firstAnalysisJson;
      try {
        firstAnalysisJson = firstAnalysis == null
            ? 'no analysis saved (analysisItems=${analyses.length}, '
                'analysesDone=$analysisDoneCount, skipped=$skippedAnalyses)'
            : jsonEncode(firstAnalysis);
      } catch (e) {
        firstAnalysisJson = 'firstAnalysis not encodable: $e';
      }

      stage = 'done';
      xliftLogAdd('[saveWC] DONE sets=$savedSets drops=$savedDrops '
          'analyses=$savedAnalyses volume=$totalVolume '
          'total=${sw.elapsedMilliseconds}ms');
      return {
        'success': true,
        'message': '',
        'workoutLogId': workoutLogId,
        'sets': savedSets,
        'drops': savedDrops,
        'analyses': savedAnalyses,
        'volume': totalVolume,
        'ms': sw.elapsedMilliseconds,
        'firstAnalysis': firstAnalysis,
        'firstAnalysisJson': firstAnalysisJson,
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
        'workoutLogId': '',
        'sets': 0,
        'drops': 0,
        'analyses': 0,
        'volume': 0.0,
        'ms': 0,
        'error': 'Unrecoverable: $e',
        'firstAnalysis': null,
        'firstAnalysisJson': 'unrecoverable: $e',
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
