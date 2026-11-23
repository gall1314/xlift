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
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'xlift_log_add.dart';

bool _syncAllRunning = false;

// ---------- analysis reports: the attached video ----------

const String _kReportBucket = 'analysis-reports';
const String _kReportVideoDir = 'report_videos';

/// Videos up to this size go up as they are.
const int _kReportVideoKeepBytes = 8 * 1024 * 1024;

/// Nothing bigger than this is uploaded (the Free plan stops at 50 MB).
const int _kReportVideoMaxBytes = 45 * 1024 * 1024;

/// Shrinks a report video to 720p without sound. Tries the encoders this
/// build may have, one after the other; if none works the original file is
/// returned and the caller decides by its size.
///
/// Encoded ONCE per video: the result is kept next to the source, and a
/// retry of the upload reuses it instead of encoding again. The encode
/// writes to a .tmp name and is renamed only when it finished, so a file
/// left by an interrupted run is never taken for a finished one.
Future<File> _shrinkReportVideo(File src) async {
  try {
    if (src.lengthSync() <= _kReportVideoKeepBytes) return src;
  } catch (_) {
    return src;
  }
  final File done = File(src.path + '.small.mp4');
  try {
    if (done.existsSync() && done.lengthSync() > 0) return done;
  } catch (_) {}
  final String out = src.path + '.small.tmp.mp4';
  final List<List<String>> encoders = [
    if (Platform.isIOS) ['-c:v', 'h264_videotoolbox', '-b:v', '1800k'],
    ['-c:v', 'libx264', '-crf', '28', '-preset', 'veryfast'],
    ['-c:v', 'mpeg4', '-q:v', '7'],
  ];
  for (final enc in encoders) {
    try {
      final File f = File(out);
      if (f.existsSync()) f.deleteSync();
      final session = await FFmpegKit.executeWithArguments([
        '-y',
        '-i',
        src.path,
        '-vf',
        "scale='if(gt(iw,ih),-2,720)':'if(gt(iw,ih),720,-2)'",
        '-an',
        ...enc,
        '-movflags',
        '+faststart',
        out,
      ]).timeout(const Duration(seconds: 180));
      final rc = await session.getReturnCode();
      if (ReturnCode.isSuccess(rc) && f.existsSync() && f.lengthSync() > 0) {
        return await f.rename(done.path);
      }
    } catch (e) {
      // No FFmpegKit.cancel() here: it stops EVERY running session, the
      // analyzer's frame extraction included.
      xliftLogAdd('[syncAll] report video encode failed: $e');
    }
  }
  return src;
}

void _deleteReportVideoFiles(File? src) {
  if (src == null) return;
  for (final String path in [
    src.path,
    src.path + '.small.mp4',
    src.path + '.small.tmp.mp4',
  ]) {
    try {
      final File f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }
}

/// Syncs ALL pending offline queues to Supabase in FK-safe order: custom
/// exercises: exercise -> exercise_muscle_group templates:        workout ->
/// workout_exercise -> exercise_sets history:          workout_log -> set_log
/// -> set_analysis quota:            analysis_usage (independent) weekly
/// plan:      training_plan (independent, one row per user)
///
/// OFFLINE-SAFE: a 3s DNS probe runs first.
///
/// No network -> returns at once with `offline - sync skipped`, queues
/// untouched, no Supabase calls. RE-ENTRANT-SAFE: a second call while one is
/// running returns at once.
///
/// BATCHED: each queue is upserted in chunks of [batchSize] rows (one request
/// per chunk). If a chunk is rejected, its rows are retried one by one so the
/// offending row is identified and the good ones still land.
///
/// Cloud columns match SQLite 1:1 - rows are sent as queued, no translation.
///
/// Hive entries are deleted ONLY after Supabase accepted the row (key-based,
/// no index-shift bugs) - OR when the row can never land ("drop"). Every call
/// has a hard timeout - NEVER hangs, NEVER throws.
///
/// Per-row rules: - RLS mismatch (row user_id / created_by_user_id !=
/// signed-in user) -> stop queue, report. - workout_exercise 23503 on
/// exercise_id (exercise not in the cloud) -> DROP that row, remember its id,
/// continue. - exercise_sets 23503 on workout_exercise_id (orphan) -> DROP,
/// continue. Sets whose parent was dropped in this run are dropped up-front.
/// - workout_log 23503 on workout_id (template missing) -> re-send with
/// workout_id = null. - anything else -> stop that queue, retry next sync.
///
/// DELETES: after the uploads, the Hive box `pendingWorkoutLogDeletes`
/// (filled by deleteWorkoutComplete) is sent - set_analysis -> set_log ->
/// workout_log per deleted workout. An entry leaves the box only after
/// Supabase accepted all three deletes; on a failure the rest stays queued
/// for the next sync. They run last, so a workout uploaded earlier in the
/// same run is still removed.
///
/// ANALYSIS REPORTS: last of all, the Hive box `pendingAnalysisReports`
/// (filled by the AnalysisReportButton widget) is sent to `analysis_report`.
/// A report with a video uploads the video first (shrunk to 720p, bucket
/// `analysis-reports`, path <user id>/<report id>.mp4) and only then inserts
/// the row, so the row never points at a file that is not there. A video that
/// failed 3 times is given up and the report goes without it.
///
/// Returns JSON: { success, exercises, exerciseMuscleGroups, workouts,
/// workoutExercises, exerciseSets, workoutLogs, setLogs, analyses, usage,
/// workoutDeletes, reports, errors, pending, debug_string }
Future<dynamic> syncAllPending() async {
  final sw = Stopwatch()..start();
  const Duration callTimeout = Duration(seconds: 20);
  const int batchSize = 50;
  const String deletesBox = 'pendingWorkoutLogDeletes';
  const String reportsBox = 'pendingAnalysisReports';

  // FK-safe order: parents before children.
  const List<List<String>> queues = [
    ['pendingExercises', 'exercise'],
    ['pendingExerciseMuscleGroups', 'exercise_muscle_group'],
    ['pendingWorkouts', 'workout'],
    ['pendingWorkoutExercises', 'workout_exercise'],
    ['pendingExerciseSets', 'exercise_sets'],
    ['pendingWorkoutLogs', 'workout_log'],
    ['pendingSetLogs', 'set_log'],
    ['pendingSetAnalyses', 'set_analysis'],
    ['pendingAnalysisUsage', 'analysis_usage'],
    ['pendingTrainingPlans', 'training_plan'],
  ];

  Map<String, dynamic> skippedResult(String msg, Map<String, int> pending) => {
        'success': false,
        'exercises': 0,
        'exerciseMuscleGroups': 0,
        'workouts': 0,
        'workoutExercises': 0,
        'exerciseSets': 0,
        'workoutLogs': 0,
        'setLogs': 0,
        'analyses': 0,
        'usage': 0,
        'workoutDeletes': 0,
        'reports': 0,
        'errors': msg,
        'pending': pending,
        'debug_string': '$msg | ${sw.elapsedMilliseconds}ms',
      };

  Future<Map<String, int>> countPending() async {
    final Map<String, int> p = {};
    for (final q in queues) {
      try {
        p[q[1]] = (await Hive.openBox(q[0])).length;
      } catch (_) {}
    }
    try {
      p['workout_log_deletes'] = (await Hive.openBox(deletesBox)).length;
    } catch (_) {}
    try {
      p['analysis_reports'] = (await Hive.openBox(reportsBox)).length;
    } catch (_) {}
    return p;
  }

  // ---------- Re-entrancy guard ----------
  if (_syncAllRunning) {
    xliftLogAdd('[syncAll] already running - skipped');
    return skippedResult('already running - skipped', {});
  }
  _syncAllRunning = true;

  try {
    xliftLogAdd('[syncAll] START');

    // ---------- Connectivity probe ----------
    bool online = false;
    try {
      final r = await InternetAddress.lookup('supabase.co')
          .timeout(const Duration(seconds: 3));
      online = r.isNotEmpty && r.first.rawAddress.isNotEmpty;
    } catch (_) {
      online = false;
    }
    if (!online) {
      const msg = 'offline - sync skipped, queues kept';
      xliftLogAdd('[syncAll] $msg');
      return skippedResult(msg, await countPending());
    }

    final errors = <String>[];
    final Map<String, int> pendingAfter = {};
    final Map<String, int> syncedByTable = {};
    final List<String> dbgLines = [];
    final Set<String> skippedWorkoutExerciseIds = {};

    // ---------- Auth guard ----------
    String? uid = SupaFlow.client.auth.currentUser?.id;
    final session = SupaFlow.client.auth.currentSession;
    final bool expired = session?.isExpired ?? true;
    if (uid == null || expired) {
      try {
        final res = await SupaFlow.client.auth
            .refreshSession()
            .timeout(const Duration(seconds: 10));
        uid = res.user?.id ?? SupaFlow.client.auth.currentUser?.id;
        xliftLogAdd('[syncAll] session refreshed, uid=$uid');
      } catch (e) {
        xliftLogAdd('[syncAll] refreshSession failed: $e');
      }
    }
    if (uid == null) {
      const msg = 'not signed in - sync skipped, queues kept';
      xliftLogAdd('[syncAll] $msg');
      return skippedResult(msg, await countPending());
    }
    final String userId = uid;

    Future<void> upsertRows(String table, List<Map<String, dynamic>> rows) {
      return SupaFlow.client.from(table).upsert(rows).timeout(callTimeout,
          onTimeout: () {
        throw TimeoutException('no response within ${callTimeout.inSeconds}s');
      });
    }

    /// Returns: 'ok' | 'drop' (remove from Hive, continue) | throws (stop).
    Future<String> sendOne(String table, Map<String, dynamic> row) async {
      try {
        await upsertRows(table, [row]);
        return 'ok';
      } catch (e) {
        final String es = e.toString();
        final bool fk = es.contains('23503');
        if (fk && table == 'workout_exercise' && es.contains('exercise_id')) {
          skippedWorkoutExerciseIds.add('${row['id']}');
          xliftLogAdd('[syncAll] workout_exercise ${row['id']}: exercise '
              '${row['exercise_id']} not in cloud - dropped');
          return 'drop';
        }
        if (fk &&
            table == 'exercise_sets' &&
            es.contains('workout_exercise_id')) {
          xliftLogAdd('[syncAll] exercise_sets ${row['id']}: parent '
              '${row['workout_exercise_id']} not in cloud (orphan) - dropped');
          return 'drop';
        }
        if (fk &&
            table == 'workout_log' &&
            es.contains('workout_id') &&
            row['workout_id'] != null) {
          xliftLogAdd('[syncAll] workout_log ${row['id']}: template '
              '${row['workout_id']} not in cloud, retrying with null');
          final retry = Map<String, dynamic>.from(row)..['workout_id'] = null;
          await upsertRows(table, [retry]);
          return 'ok';
        }
        rethrow;
      }
    }

    Future<int> syncBox(String boxName, String table) async {
      int synced = 0;
      int skipped = 0;
      int pendingBefore = 0;
      String? failMsg;
      String? failKeys;
      try {
        final box = await Hive.openBox(boxName);
        pendingBefore = box.length;
        if (box.isEmpty) {
          pendingAfter[table] = 0;
          dbgLines.add('$table: nothing pending');
          return 0;
        }

        final List<MapEntry<dynamic, Map<String, dynamic>>> items = [];
        for (final key in box.keys.toList()) {
          final raw = box.get(key);
          if (raw is Map) {
            items.add(MapEntry(key, Map<String, dynamic>.from(raw)));
          }
        }
        xliftLogAdd('[syncAll] $boxName: ${items.length} pending');

        // Orphan pre-filter: sets whose parent was dropped in this run.
        if (table == 'exercise_sets' && skippedWorkoutExerciseIds.isNotEmpty) {
          final orphans = items
              .where((it) => skippedWorkoutExerciseIds
                  .contains('${it.value['workout_exercise_id']}'))
              .toList();
          for (final it in orphans) {
            await box.delete(it.key);
            items.remove(it);
            skipped++;
          }
          if (orphans.isNotEmpty) {
            xliftLogAdd('[syncAll] exercise_sets: ${orphans.length} orphan '
                'rows dropped');
          }
          if (items.isEmpty) {
            pendingAfter[table] = box.length;
            dbgLines
                .add('$table: sent 0 ($skipped skipped), left ${box.length}');
            return 0;
          }
        }

        // RLS guard: every owned row must belong to this user.
        for (final it in items) {
          final rowUid = (it.value['user_id'] ?? it.value['created_by_user_id'])
              ?.toString();
          if (rowUid != null && rowUid.isNotEmpty && rowUid != userId) {
            failMsg = 'row owner=$rowUid != signed-in $userId';
            failKeys = it.value.keys.join(',');
            xliftLogAdd('[syncAll] $table $failMsg');
            errors.add('$table: $failMsg');
            pendingAfter[table] = box.length;
            dbgLines.add('$table: sent 0, left ${box.length} FAIL [$failMsg]');
            return 0;
          }
        }

        bool stop = false;
        for (int start = 0; start < items.length && !stop; start += batchSize) {
          final chunk =
              items.sublist(start, (start + batchSize).clamp(0, items.length));

          bool chunkOk = false;
          try {
            await upsertRows(table, chunk.map((e) => e.value).toList());
            chunkOk = true;
          } catch (e) {
            xliftLogAdd('[syncAll] $table chunk@$start failed, '
                'falling back to per-row: $e');
          }
          if (chunkOk) {
            for (final it in chunk) {
              await box.delete(it.key);
            }
            synced += chunk.length;
            continue;
          }

          for (final it in chunk) {
            try {
              final r = await sendOne(table, it.value);
              await box.delete(it.key); // 'ok' landed, 'drop' can never land
              if (r == 'ok') {
                synced++;
              } else {
                skipped++;
              }
            } catch (e) {
              failMsg = e.toString();
              failKeys = it.value.keys.join(',');
              xliftLogAdd('[syncAll] $table row failed: $failMsg '
                  'keys=[$failKeys]');
              errors.add('$table: $failMsg');
              stop = true;
              break;
            }
          }
        }
        pendingAfter[table] = box.length;
      } catch (e) {
        failMsg = 'box error: $e';
        xliftLogAdd('[syncAll] $boxName $failMsg');
        errors.add('$boxName: $e');
        pendingAfter[table] = pendingBefore;
      }

      final int left = pendingAfter[table] ?? pendingBefore;
      final String sk = skipped > 0 ? ' ($skipped skipped)' : '';
      if (failMsg == null) {
        dbgLines.add('$table: sent $synced$sk, left $left');
      } else {
        dbgLines.add('$table: sent $synced$sk, left $left FAIL [$failMsg]'
            '${failKeys != null ? ' keys=[$failKeys]' : ''}');
      }
      return synced;
    }

    for (final q in queues) {
      syncedByTable[q[1]] = await syncBox(q[0], q[1]);
    }

    // ---------- Queued workout deletes ----------
    // Children before parents. Deleting rows that are not in the cloud is a
    // no-op, so a workout that was never uploaded just leaves the queue.
    int deletesSent = 0;
    try {
      final box = await Hive.openBox(deletesBox);
      String? failMsg;
      for (final key in box.keys.toList()) {
        final raw = box.get(key);
        if (raw is! Map) {
          await box.delete(key);
          continue;
        }
        final String wid = (raw['workout_log_id'] ?? key).toString();
        final List<String> sids = [
          for (final x in (raw['set_log_ids'] as List? ?? const []))
            x.toString(),
        ];
        try {
          if (sids.isNotEmpty) {
            final String inList = '(${sids.map((x) => '"$x"').join(',')})';
            await SupaFlow.client
                .from('set_analysis')
                .delete()
                .filter('set_log_id', 'in', inList)
                .timeout(callTimeout);
          }
          await SupaFlow.client
              .from('set_log')
              .delete()
              .eq('workout_log_id', wid)
              .timeout(callTimeout);
          await SupaFlow.client
              .from('workout_log')
              .delete()
              .eq('id', wid)
              .timeout(callTimeout);
          await box.delete(key);
          deletesSent++;
        } catch (e) {
          failMsg = e.toString();
          xliftLogAdd('[syncAll] workout delete failed ($wid): $failMsg');
          errors.add('workout_log delete: $failMsg');
          break; // keep the rest queued, retry next sync
        }
      }
      pendingAfter['workout_log_deletes'] = box.length;
      if (deletesSent > 0 || box.isNotEmpty) {
        dbgLines.add('workout deletes: sent $deletesSent, left ${box.length}'
            '${failMsg != null ? ' FAIL [$failMsg]' : ''}');
      }
    } catch (e) {
      xliftLogAdd('[syncAll] $deletesBox box error: $e');
      errors.add('$deletesBox: $e');
    }

    // ---------- Queued analysis reports ----------
    // Video first, then the row (see the header). One report failing never
    // blocks the others: it stays queued and the loop moves on.
    int reportsSent = 0;
    try {
      final box = await Hive.openBox(reportsBox);
      String? failMsg;
      Directory? docs;
      for (final key in box.keys.toList()) {
        final raw = box.get(key);
        if (raw is! Map) {
          await box.delete(key);
          continue;
        }
        final Map<String, dynamic> entry = Map<String, dynamic>.from(raw);
        Map<String, dynamic> row;
        try {
          row = Map<String, dynamic>.from(
              jsonDecode((entry['row_json'] ?? '').toString()) as Map);
        } catch (_) {
          await box.delete(key); // unreadable: can never land
          continue;
        }
        // another account's report waits for its owner
        if ((row['user_id'] ?? '').toString() != userId) continue;

        final String localName = (entry['video_local'] ?? '').toString();
        final int attempts = (entry['video_attempts'] is int)
            ? entry['video_attempts'] as int
            : 0;
        File? localFile;
        String? videoPath;
        bool retryLater = false;

        if (localName.isNotEmpty) {
          try {
            docs ??= await getApplicationDocumentsDirectory();
            final File f =
                File(docs.path + '/' + _kReportVideoDir + '/' + localName);
            if (f.existsSync()) localFile = f;
          } catch (_) {}
        }

        if (localFile != null && attempts < 3) {
          try {
            final File toSend = await _shrinkReportVideo(localFile);
            if (toSend.lengthSync() <= _kReportVideoMaxBytes) {
              final String objectPath =
                  userId + '/' + row['id'].toString() + '.mp4';
              try {
                await SupaFlow.client.storage
                    .from(_kReportBucket)
                    .upload(objectPath, toSend,
                        fileOptions:
                            const FileOptions(contentType: 'video/mp4'))
                    .timeout(const Duration(seconds: 180));
              } catch (e) {
                // a retry after an upload that did land: the file is there
                final String es = e.toString().toLowerCase();
                final bool exists = es.contains('already exists') ||
                    es.contains('duplicate') ||
                    es.contains('409');
                if (!exists) rethrow;
              }
              videoPath = objectPath;
            } else {
              xliftLogAdd('[syncAll] report ${row['id']}: video too big, '
                  'sent without it');
            }
          } catch (e) {
            entry['video_attempts'] = attempts + 1;
            await box.put(key, entry);
            failMsg = e.toString();
            xliftLogAdd('[syncAll] report video upload failed '
                '(${attempts + 1}/3): $failMsg');
            retryLater = true;
          }
        }
        if (retryLater) continue;

        row['video_path'] = videoPath;
        try {
          await SupaFlow.client
              .from('analysis_report')
              .insert(row)
              .timeout(callTimeout);
        } catch (e) {
          // 23505 = this report already landed on an earlier try
          if (!e.toString().contains('23505')) {
            failMsg = e.toString();
            xliftLogAdd('[syncAll] analysis_report insert failed: $failMsg');
            errors.add('analysis_report: $failMsg');
            continue;
          }
        }
        await box.delete(key);
        _deleteReportVideoFiles(localFile);
        reportsSent++;
      }
      pendingAfter['analysis_reports'] = box.length;
      if (reportsSent > 0 || box.isNotEmpty) {
        dbgLines.add('reports: sent $reportsSent, left ${box.length}'
            '${failMsg != null ? ' FAIL [$failMsg]' : ''}');
      }
    } catch (e) {
      xliftLogAdd('[syncAll] $reportsBox box error: $e');
      errors.add('$reportsBox: $e');
    }

    final String debugString =
        'uid=${userId.substring(0, 8)} | ${dbgLines.join(' | ')} | '
        '${sw.elapsedMilliseconds}ms';
    xliftLogAdd('[syncAll] DONE $debugString');

    return {
      'success': errors.isEmpty,
      'exercises': syncedByTable['exercise'] ?? 0,
      'exerciseMuscleGroups': syncedByTable['exercise_muscle_group'] ?? 0,
      'workouts': syncedByTable['workout'] ?? 0,
      'workoutExercises': syncedByTable['workout_exercise'] ?? 0,
      'exerciseSets': syncedByTable['exercise_sets'] ?? 0,
      'workoutLogs': syncedByTable['workout_log'] ?? 0,
      'setLogs': syncedByTable['set_log'] ?? 0,
      'analyses': syncedByTable['set_analysis'] ?? 0,
      'usage': syncedByTable['analysis_usage'] ?? 0,
      'workoutDeletes': deletesSent,
      'reports': reportsSent,
      'errors': errors.join(' | '),
      'pending': pendingAfter,
      'debug_string': debugString,
    };
  } finally {
    _syncAllRunning = false;
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
