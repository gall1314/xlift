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

/// Saves a workout TEMPLATE in one atomic pass: workout ->
/// workout_exercises -> exercise_sets (warmups + working + drops,
/// merged like the old merge action) -> Hive sync queues.
/// workout_exercise ids are generated internally. Empty/null name ->
/// "Unnamed Workout N". rest_seconds gets restDurations[exerciseId]
/// AS-IS (ms, default 90000). Superset flags come from exerciseSets.
/// All progress lines go through xliftLogAdd -> visible live in the
/// DebugConsole widget AND in the real console.
///
/// GUARANTEE: ALWAYS returns a JSON map - never throws, never leaves
/// the Action Output empty (inner/outer/last-resort shields).
/// Returns JSON: { success, workoutId, name, exercises, sets, debug }.
Future<dynamic> saveWorkoutTemplate(
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
    xliftLogAdd('[saveWT] FATAL at stage=$stage failedAt=$failedAt '
        'hang=$hangSuspect type=$type: $msg');
    return {
      'success': false,
      'workoutId': '',
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
      xliftLogAdd('[saveWT] ✓ $step @${sw.elapsedMilliseconds}ms');
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
      'nameGiven': (workoutName ?? '').trim().isNotEmpty,
      'userIdSet': userId.isNotEmpty,
      'selectedExercises': alreadySelected.length,
      'exerciseSetsItems': exerciseSets.length,
      'loggedSets': loggedSets.length,
      'dropSets': dropSets == null ? 0 : dropSets.length,
      'warmupItems': warmupList == null ? 0 : warmupList.length,
      'restDurationsIsMap': restDurations is Map,
    };
    xliftLogAdd('[saveWT] START inputs=$inputs');
    mark('scan-inputs');

    // ---- validation ----
    stage = 'validate';
    if (userId.isEmpty) {
      failedAt = 'validate';
      return failure('Missing userId', 'ValidationError');
    }
    if (alreadySelected.isEmpty) {
      failedAt = 'validate';
      return failure('No exercises selected', 'ValidationError');
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
      mark('hive-open');

      // ---- 1. workout name ----
      String name = (workoutName ?? '').trim();
      if (name.isEmpty) {
        final List rows = await guarded(
            'count-unnamed',
            () => db.rawQuery(
                  'SELECT COUNT(*) AS c FROM workout '
                  'WHERE user_id = ? AND is_deleted = 0 AND name LIKE ?',
                  [userId, 'Unnamed Workout%'],
                ));
        int c = 0;
        if (rows.isNotEmpty) {
          c = toInt(rows.first['c']) ?? 0;
        }
        name = 'Unnamed Workout ${c + 1}';
      }
      mark('name("$name")');

      // ---- 2. workout ----
      final String workoutId = uuid();
      await guarded(
          'insert-workout',
          () => db.rawInsert(
                'INSERT OR IGNORE INTO workout '
                '(id, name, created_at, user_id, is_deleted) '
                'VALUES (?, ?, ?, ?, 0)',
                [workoutId, name, nowIso, userId],
              ));
      await guarded(
          'hive-add-workout',
          () => workoutBox.add({
                'id': workoutId,
                'name': name,
                'user_id': userId,
              }));
      mark('workout');

      // exerciseSets keyed by exerciseId (superset info + sets)
      final Map<int, Map<String, dynamic>> exSetsById = {};
      for (final e in exerciseSets) {
        if (e is! Map) continue;
        final int? exId = toInt(e['exerciseId']);
        if (exId == null) continue;
        exSetsById[exId] = Map<String, dynamic>.from(e);
      }

      // ---- 3. workout_exercises ----
      final Map<int, String> weIdByExerciseId = {};
      int savedExercises = 0;
      int order = 0;

      for (final raw in alreadySelected) {
        if (raw is! Map) continue;
        final int? exerciseId = toInt(raw['exerciseId'] ?? raw['exercise_id']);
        if (exerciseId == null || exerciseId <= 0) continue;

        final dynamic rawName =
            raw['exerciseName'] ?? raw['name'] ?? raw['exercise_name'];
        final String exerciseName = rawName == null ? '' : rawName.toString();
        if (exerciseName.isEmpty) {
          xliftLogAdd('[saveWT] SKIP ex=$exerciseId - missing exerciseName');
          continue;
        }

        order++;
        final Map<String, dynamic>? exInfo = exSetsById[exerciseId];
        final int restMs = restFor(exerciseId);
        final int isSuperset =
            toFlag(exInfo == null ? null : exInfo['isSuperset']);
        String? supersetGroupId;
        if (isSuperset == 1 &&
            exInfo != null &&
            exInfo['supersetGroupId'] != null) {
          supersetGroupId = exInfo['supersetGroupId'].toString();
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

      // ---- 4. merge sets ----
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
        if (weId == null) {
          xliftLogAdd('[saveWT] merge SKIP ex=$exerciseId - not in selection');
          continue;
        }

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

        final List<Map<String, dynamic>> allSets = [];
        allSets.addAll(warmupSets);
        allSets.addAll(workingSets);
        final Map<int, Map<String, dynamic>> resolved = {};

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
            'durationSeconds': null,
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
              if (match.containsKey('targetReps')) {
                row['targetReps'] = toInt(match['targetReps']);
              }
              if (match.containsKey('durationSeconds')) {
                row['durationSeconds'] = toInt(match['durationSeconds']);
              }
            }
          }

          if (setNumber > 1 && row['targetReps'] == null) {
            for (int prev = setNumber - 1; prev >= 1; prev--) {
              final Map<String, dynamic>? prevRow = resolved[prev];
              if (prevRow == null) continue;
              if (prevRow['isWarmup'] == row['isWarmup'] &&
                  prevRow['targetReps'] != null) {
                row['targetReps'] = prevRow['targetReps'];
                break;
              }
            }
          }

          resolved[setNumber] = row;
          merged.add(row);
        }
      }

      for (final d in drops) {
        final int? exerciseId = toInt(d['exerciseId']);
        final int? parentSetNumber = toInt(d['parentSetNumber']);
        final int? dropOrder = toInt(d['dropOrder']);
        if (exerciseId == null || parentSetNumber == null) continue;
        final String? weId = weIdByExerciseId[exerciseId];
        if (weId == null) continue;

        merged.add({
          'exerciseId': exerciseId,
          'workoutExerciseId': weId,
          'setNumber': parentSetNumber,
          'isDropSet': 1,
          'dropNumber': dropOrder,
          'targetReps': toInt(d['reps']),
          'weighted': 1,
          'isWarmup': 0,
          'durationSeconds': null,
        });
      }
      mark('merge(${merged.length})');

      // ---- 5. exercise_sets ----
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
      xliftLogAdd('[saveWT] DONE "$name" exercises=$savedExercises '
          'sets=$savedSets total=${sw.elapsedMilliseconds}ms');
      return {
        'success': true,
        'workoutId': workoutId,
        'name': name,
        'exercises': savedExercises,
        'sets': savedSets,
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
        'workoutId': '',
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
