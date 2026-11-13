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

/// Updates an EXISTING workout template in one atomic pass. The workout row
/// and its id survive; everything under it is wiped and rebuilt from the
/// current App State, exactly the way saveWorkoutTemplate builds a new one:
/// workout_exercises -> exercise_sets (warmups + working + drops, same merge)
/// -> Hive sync queues.
///
/// Empty/null name keeps the name that is already stored.
/// rest_seconds gets restDurations[exerciseId] AS-IS (ms, default 90000).
/// EXERCISE ORDER ("order" column) and WHICH exercises are saved both come
/// from exerciseSets - the on-screen list. alreadySelected is only a source
/// for the display name.
///
/// Deletions are queued in the Hive box 'pendingDeletes' as
/// { table, id, workout_id, user_id } - rename it to whatever your sync
/// worker reads.
///
/// GUARANTEE: ALWAYS returns a JSON map - never throws, never leaves the
/// Action Output empty (inner/outer/last-resort shields).
/// Returns JSON: { success, workoutId, name, exercises, sets, deleted, debug }.
Future<dynamic> updateWorkoutTemplate(
  String workoutId,
  String? workoutName,
  String userId,
  List<dynamic> alreadySelected,
  List<dynamic> exerciseSets,
  List<dynamic> loggedSets,
  List<dynamic>? dropSets,
  List<dynamic>? warmupList,
  dynamic restDurations,
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

  Map<String, dynamic> failure(String msg, String type) {
    xliftLogAdd('[TAG] FATAL at stage=$stage failedAt=$failedAt '
        'hang=$hangSuspect type=$type: $msg');
    return {
      'success': false,
      'workoutId': workoutId,
      'name': '',
      'error': msg,
      'debug': debugBlock(msg, type),
    };
  }

  // ================= OUTER SHIELD =================
  try {
    const Duration dbTimeout = Duration(seconds: 8);

    void mark(String step) {
      stepsDone.add(step);
      timings[step] = sw.elapsedMilliseconds;
      xliftLogAdd('[TAG] ✓ $step @${sw.elapsedMilliseconds}ms');
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

    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String && v.trim().isNotEmpty) return int.tryParse(v.trim());
      return null;
    }

    int toFlag(dynamic v) {
      if (v is int) return v == 1 ? 1 : 0;
      if (v is bool) return v ? 1 : 0;
      if (v is String) {
        return (v == '1' || v.toLowerCase() == 'true') ? 1 : 0;
      }
      return 0;
    }

    int restFor(int exerciseId) {
      if (restDurations is Map) {
        final dynamic v = restDurations[exerciseId.toString()];
        final int? parsed = toInt(v);
        if (parsed != null) return parsed;
      }
      return 90000;
    }

    // ---- inputs scan ----
    stage = 'scan-inputs';
    inputs = {
      'workoutIdSet': workoutId.trim().isNotEmpty,
      'nameGiven': (workoutName ?? '').trim().isNotEmpty,
      'userIdSet': userId.isNotEmpty,
      'selectedExercises': alreadySelected.length,
      'exerciseSetsItems': exerciseSets.length,
      'loggedSets': loggedSets.length,
      'dropSets': dropSets == null ? 0 : dropSets.length,
      'warmupItems': warmupList == null ? 0 : warmupList.length,
      'restDurationsIsMap': restDurations is Map,
    };
    xliftLogAdd('[TAG] START inputs=$inputs');
    mark('scan-inputs');

    // ---- validation ----
    stage = 'validate';
    if (workoutId.trim().isEmpty) {
      failedAt = 'validate';
      return failure('Missing workoutId', 'ValidationError');
    }
    if (userId.isEmpty) {
      failedAt = 'validate';
      return failure('Missing userId', 'ValidationError');
    }
    if (exerciseSets.isEmpty) {
      failedAt = 'validate';
      return failure('No exercises', 'ValidationError');
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

      final Box workoutBox = await guarded(
          'hive-open-workouts', () => Hive.openBox('pendingWorkouts'));
      final Box weBox = await guarded('hive-open-workoutExercises',
          () => Hive.openBox('pendingWorkoutExercises'));
      final Box setBox = await guarded(
          'hive-open-exerciseSets', () => Hive.openBox('pendingExerciseSets'));
      final Box delBox = await guarded(
          'hive-open-deletes', () => Hive.openBox('pendingDeletes'));
      mark('hive-open');

      // ---- the workout must exist and be ours ----
      final List existing = await guarded(
          'load-workout',
          () => db.rawQuery(
                'SELECT id, name FROM workout '
                'WHERE id = ? AND user_id = ? AND is_deleted = 0 LIMIT 1',
                [workoutId, userId],
              ));
      if (existing.isEmpty) {
        failedAt = 'load-workout';
        return failure(
            'Workout $workoutId not found for this user', 'NotFound');
      }
      final String storedName = (existing.first['name'] ?? '').toString();
      mark('load-workout');

      // ---- name (empty keeps the stored one) ----
      String name = (workoutName ?? '').trim();
      if (name.isEmpty) name = storedName;
      if (name != storedName) {
        await guarded(
            'update-workout-name',
            () => db.rawUpdate(
                  'UPDATE workout SET name = ? WHERE id = ? AND user_id = ?',
                  [name, workoutId, userId],
                ));
        await guarded(
            'hive-update-workout',
            () => workoutBox.add({
                  'id': workoutId,
                  'name': name,
                  'user_id': userId,
                }));
      }
      mark('name("$name")');

      // ---- wipe everything under the workout ----
      stage = 'wipe';
      final List oldSets = await guarded(
          'load-old-sets',
          () => db.rawQuery(
                'SELECT id FROM exercise_sets WHERE workout_id = ?',
                [workoutId],
              ));
      final List oldWes = await guarded(
          'load-old-workout_exercises',
          () => db.rawQuery(
                'SELECT id FROM workout_exercise WHERE workout_id = ?',
                [workoutId],
              ));

      for (final r in oldSets) {
        await guarded(
            'hive-queue-delete-set',
            () => delBox.add({
                  'table': 'exercise_sets',
                  'id': r['id'],
                  'workout_id': workoutId,
                  'user_id': userId,
                }));
      }
      for (final r in oldWes) {
        await guarded(
            'hive-queue-delete-workout_exercise',
            () => delBox.add({
                  'table': 'workout_exercise',
                  'id': r['id'],
                  'workout_id': workoutId,
                  'user_id': userId,
                }));
      }

      await guarded(
          'delete-exercise_sets',
          () => db.rawDelete(
                'DELETE FROM exercise_sets WHERE workout_id = ?',
                [workoutId],
              ));
      await guarded(
          'delete-workout_exercises',
          () => db.rawDelete(
                'DELETE FROM workout_exercise WHERE workout_id = ?',
                [workoutId],
              ));
      final int deleted = oldSets.length + oldWes.length;
      mark('wipe(we=${oldWes.length}, sets=${oldSets.length})');

      // ---- exercises: exerciseSets is the source of truth ----
      // The on-screen list decides which exercises exist and in what order.
      // alreadySelected is only consulted for the display name.
      stage = 'collect-exercises';
      final Map<int, String> nameBySelected = {};
      for (final raw in alreadySelected) {
        if (raw is! Map) continue;
        final int? id = toInt(raw['exerciseId'] ?? raw['exercise_id']);
        if (id == null) continue;
        final dynamic n =
            raw['exerciseName'] ?? raw['name'] ?? raw['exercise_name'];
        final String s = n == null ? '' : n.toString().trim();
        if (s.isNotEmpty) nameBySelected[id] = s;
      }

      // ordered, de-duplicated exercise list straight off the screen
      final List<Map<String, dynamic>> ordered = [];
      final Set<int> seen = {};
      for (final e in exerciseSets) {
        if (e is! Map) continue;
        final int? exId = toInt(e['exerciseId']);
        if (exId == null || exId <= 0 || !seen.add(exId)) continue;
        ordered.add(Map<String, dynamic>.from(e));
      }

      // name: selection -> the item itself -> the exercise table -> empty.
      // An unknown name never costs us the exercise; it is only a label.
      Future<String> nameFor(int exerciseId, Map<String, dynamic> item) async {
        final String fromSel = nameBySelected[exerciseId] ?? '';
        if (fromSel.isNotEmpty) return fromSel;
        final dynamic own =
            item['exerciseName'] ?? item['name'] ?? item['exercise_name'];
        final String fromItem = own == null ? '' : own.toString().trim();
        if (fromItem.isNotEmpty) return fromItem;
        try {
          final List rows = await db.rawQuery(
              'SELECT name FROM exercise WHERE id = ? LIMIT 1', [exerciseId]);
          if (rows.isNotEmpty) {
            final dynamic n = rows.first['name'];
            if (n != null) return n.toString().trim();
          }
        } catch (_) {
          // table named differently / not available - label stays empty
        }
        return '';
      }

      mark('collect-exercises(${ordered.length})');

      // ---- workout_exercises ----
      final Map<int, String> weIdByExerciseId = {};
      final Map<int, Map<String, dynamic>> exSetsById = {};
      int savedExercises = 0;
      int order = 0;

      for (final item in ordered) {
        final int exerciseId = toInt(item['exerciseId'])!;
        exSetsById[exerciseId] = item;

        final String exerciseName = await nameFor(exerciseId, item);
        if (exerciseName.isEmpty) {
          xliftLogAdd(
              '[updWT] WARN ex=$exerciseId - no name found, saving anyway');
        }

        order++;
        final int restMs = restFor(exerciseId);
        final int isSuperset = toFlag(item['isSuperset']);
        String? supersetGroupId;
        if (isSuperset == 1) {
          final dynamic gid = item['supersetGroupId'] ?? item['supersetId'];
          if (gid != null && gid.toString().trim().isNotEmpty) {
            supersetGroupId = gid.toString();
          }
        }

        final String weId = uuid();
        weIdByExerciseId[exerciseId] = weId;
        final String tag = 'ex=$exerciseId "$exerciseName"';

        await guarded(
            'insert-workout_exercise($tag)',
            () => db.rawInsert(
                  'INSERT OR IGNORE INTO workout_exercise '
                  '(id, workout_id, exercise_id, created_at, "order", '
                  'exercise_name, user_id, rest_seconds, is_superset, '
                  'superset_group_id) '
                  'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                  [
                    weId,
                    workoutId,
                    exerciseId,
                    nowIso,
                    order,
                    exerciseName,
                    userId,
                    restMs,
                    isSuperset,
                    supersetGroupId,
                  ],
                ));
        await guarded(
            'hive-add-workout_exercise($tag)',
            () => weBox.add({
                  'id': weId,
                  'workout_id': workoutId,
                  'order': order,
                  'exercise_id': exerciseId.toString(),
                  'exercise_name': exerciseName,
                  'user_id': userId,
                }));
        savedExercises++;
      }
      mark('workout_exercises($savedExercises)');

      // ---- merge sets ----
      stage = 'merge';
      final List<Map<String, dynamic>> logged = [];
      for (final l in loggedSets) {
        if (l is Map) logged.add(Map<String, dynamic>.from(l));
      }
      final List<Map<String, dynamic>> drops = [];
      if (dropSets != null) {
        for (final d in dropSets) {
          if (d is Map) drops.add(Map<String, dynamic>.from(d));
        }
      }

      final List<Map<String, dynamic>> merged = [];

      for (final ex in exSetsById.values) {
        final int exerciseId = toInt(ex['exerciseId'])!;
        final String? weId = weIdByExerciseId[exerciseId];
        if (weId == null) continue;

        final List<Map<String, dynamic>> workingSets = [];
        final dynamic rawSets = ex['sets'];
        if (rawSets is List) {
          for (final s in rawSets) {
            if (s is! Map) continue;
            final Map<String, dynamic> m = Map<String, dynamic>.from(s);
            m['isWarmup'] = 0;
            workingSets.add(m);
          }
        }

        final List<Map<String, dynamic>> warmupSets = [];
        if (warmupList != null) {
          for (final w in warmupList) {
            if (w is! Map) continue;
            if (toInt(w['exerciseId']) != exerciseId) continue;
            if (w['hidden'] == true) continue;
            final dynamic wSets = w['sets'];
            if (wSets is! List) break;
            for (final s in wSets) {
              if (s is! Map) continue;
              final Map<String, dynamic> m = Map<String, dynamic>.from(s);
              m['isWarmup'] = 1;
              warmupSets.add(m);
            }
            break;
          }
        }

        // warm-up and working sets both start at 1, so the carry-over chain
        // is kept per kind, not per set number.
        final Map<int, Map<String, dynamic>> resolvedWarm = {};
        final Map<int, Map<String, dynamic>> resolvedWork = {};

        final List<Map<String, dynamic>> allSets = [];
        allSets.addAll(warmupSets);
        allSets.addAll(workingSets);

        for (final s in allSets) {
          final int? setNumber = toInt(s['setNumber']);
          if (setNumber == null) continue;
          final int rowIsWarmup = toFlag(s['isWarmup']);

          final Map<String, dynamic> row = {
            'exerciseId': exerciseId,
            'workoutExerciseId': weId,
            'setNumber': setNumber,
            'isDropSet': 0,
            'dropNumber': null,
            'targetReps': toInt(s['targetReps']),
            'weighted': toFlag(s['weighted']),
            'isWarmup': rowIsWarmup,
            'durationSeconds': toInt(s['durationSeconds']),
          };

          if (rowIsWarmup == 1) {
            if (row['targetReps'] == null) {
              row['targetReps'] = toInt(s['reps']);
            }
          } else {
            Map<String, dynamic>? match;
            for (final l in logged) {
              if (toInt(l['exerciseId']) == exerciseId &&
                  toInt(l['setNumber']) == setNumber &&
                  toFlag(l['isDropSet']) == 0) {
                match = l;
                break;
              }
            }
            if (match != null) {
              if (match['targetReps'] != null) {
                row['targetReps'] = toInt(match['targetReps']);
              }
              if (match['durationSeconds'] != null) {
                row['durationSeconds'] = toInt(match['durationSeconds']);
              }
            }
          }

          // nothing typed? carry the previous set of the same kind
          final Map<int, Map<String, dynamic>> bucket =
              rowIsWarmup == 1 ? resolvedWarm : resolvedWork;
          if (setNumber > 1 && row['targetReps'] == null) {
            for (int prev = setNumber - 1; prev >= 1; prev--) {
              final Map<String, dynamic>? prevRow = bucket[prev];
              if (prevRow == null) continue;
              if (prevRow['targetReps'] != null) {
                row['targetReps'] = prevRow['targetReps'];
                break;
              }
            }
          }

          bucket[setNumber] = row;
          merged.add(row);
        }
      }

      // ---- drop sets: the plan says how many, loggedSets says what was typed
      for (final d in drops) {
        final int? exerciseId = toInt(d['exerciseId']);
        final int? parentSetNumber = toInt(d['parentSetNumber']);
        final int? dropOrder = toInt(d['dropOrder'] ?? d['dropNumber']);
        if (exerciseId == null || parentSetNumber == null) continue;
        final String? weId = weIdByExerciseId[exerciseId];
        if (weId == null) continue;

        int? dropReps = toInt(d['targetReps'] ?? d['reps']);
        for (final l in logged) {
          if (toInt(l['exerciseId']) != exerciseId) continue;
          if (toInt(l['setNumber']) != parentSetNumber) continue;
          if (toFlag(l['isDropSet']) != 1) continue;
          if (toInt(l['dropNumber'] ?? l['dropOrder']) != dropOrder) continue;
          if (l['targetReps'] != null) dropReps = toInt(l['targetReps']);
          break;
        }

        merged.add({
          'exerciseId': exerciseId,
          'workoutExerciseId': weId,
          'setNumber': parentSetNumber,
          'isDropSet': 1,
          'dropNumber': dropOrder,
          'targetReps': dropReps,
          'weighted': 1,
          'isWarmup': 0,
          'durationSeconds': null,
        });
      }
      mark('merge(${merged.length})');

      // ---- exercise_sets ----
      int savedSets = 0;
      for (final row in merged) {
        final String setId = uuid();
        final String tag = 'ex=${row['exerciseId']} n=${row['setNumber']} '
            'w=${row['isWarmup']} d=${row['isDropSet']}';

        await guarded(
            'insert-exercise_sets($tag)',
            () => db.rawInsert(
                  'INSERT INTO exercise_sets '
                  '(id, workout_id, workout_exercise_id, set_number, '
                  'drop_number, target_reps, duration_seconds, is_warmup, '
                  'is_dropset, weighted) '
                  'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                  [
                    setId,
                    workoutId,
                    row['workoutExerciseId'],
                    row['setNumber'],
                    row['dropNumber'],
                    row['targetReps'],
                    row['durationSeconds'],
                    row['isWarmup'],
                    row['isDropSet'],
                    row['weighted'],
                  ],
                ));
        await guarded(
            'hive-add-exercise_set($tag)',
            () => setBox.add({
                  'id': setId,
                  'workout_exercise_id': row['workoutExerciseId'],
                  'set_number': row['setNumber'],
                  'target_reps': row['targetReps'],
                  'is_warmup': row['isWarmup'],
                  'is_dropset': row['isDropSet'],
                  'drop_number': row['dropNumber'],
                  'workout_id': workoutId,
                  'weighted': row['weighted'] ?? 1,
                  'duration_seconds': row['durationSeconds'],
                }));
        savedSets++;
      }
      mark('exercise_sets($savedSets)');

      stage = 'done';
      xliftLogAdd('[TAG] DONE "$name" exercises=$savedExercises '
          'sets=$savedSets total=${sw.elapsedMilliseconds}ms');
      return {
        'success': true,
        'workoutId': workoutId,
        'name': name,
        'exercises': savedExercises,
        'sets': savedSets,
        'deleted': deleted,
        'ms': sw.elapsedMilliseconds,
        'debug': debugBlock(null, null),
      };
    } catch (e) {
      return failure(e.toString(), e.runtimeType.toString());
    }
  } catch (e) {
    try {
      return failure(e.toString(), e.runtimeType.toString());
    } catch (_) {
      return {
        'success': false,
        'workoutId': workoutId,
        'name': '',
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
