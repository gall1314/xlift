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

/// Copies a catalog template into the user's own workouts in one pass:
/// workout -> workout_exercises -> exercise_sets. Every row is written to
/// SQLite AND queued in the same Hive boxes saveWorkoutTemplate uses
/// (pendingWorkouts / pendingWorkoutExercises / pendingExerciseSets), with
/// the same map shapes, so the existing sync picks it up unchanged.
///
/// templateWorkoutId is what LibraryView hands to onUseTemplate. The
/// template row is looked up by workout_id first, then by id, and the
/// exercises are read from whichever of the two the rows hang off.
/// Name = workout_template.name (fallback: the source workout's name),
/// de-duplicated against the user's workouts ("Legs" -> "Legs 2").
/// All ids (workout, workout_exercise, exercise_sets, superset groups) are
/// generated here. rest_seconds / notes / superset flags / set details are
/// copied as stored.
///
/// GUARANTEE: ALWAYS returns a JSON map - never throws.
///   $.success    -> true / false
///   $.message    -> user-facing text for a Snackbar (empty on success)
///   $.workoutId, $.name, $.exercises, $.sets, $.ms, $.debug
Future<dynamic> saveTemplateAsWorkout(
  String? templateWorkoutId,
  String? userId,
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
    xliftLogAdd('[saveTpl] FATAL at stage=$stage failedAt=$failedAt '
        'hang=$hangSuspect type=$type: $msg');
    return {
      'success': false,
      'message': message,
      'workoutId': '',
      'name': '',
      'exercises': 0,
      'sets': 0,
      'ms': sw.elapsedMilliseconds,
      'error': msg,
      'debug': debugBlock(msg, type),
    };
  }

  const String MSG_GENERIC = "Couldn't save this template. Please try again.";
  const String MSG_NOT_FOUND = "Couldn't find this template on the device.";
  const String MSG_EMPTY = 'This template has no exercises yet.';

  // ================= OUTER SHIELD =================
  try {
    const Duration dbTimeout = Duration(seconds: 8);

    void mark(String step) {
      stepsDone.add(step);
      timings[step] = sw.elapsedMilliseconds;
      xliftLogAdd('[saveTpl] ✓ $step @${sw.elapsedMilliseconds}ms');
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

    int flag(dynamic v) {
      if (v is bool) return v ? 1 : 0;
      final int? i = toInt(v);
      return i == 1 ? 1 : 0;
    }

    String str(dynamic v) => v == null ? '' : v.toString().trim();

    String? strOrNull(dynamic v) {
      final String s = str(v);
      return s.isEmpty ? null : s;
    }

    // ---- normalize args (validate INSIDE, loudly) ----
    stage = 'normalize-args';
    final String srcId = (templateWorkoutId ?? '').trim();
    final String uId = (userId ?? '').trim();
    inputs = {
      'templateWorkoutId': srcId,
      'templateWorkoutIdWasNull': templateWorkoutId == null,
      'userIdSet': uId.isNotEmpty,
    };
    xliftLogAdd('[saveTpl] START inputs=$inputs');
    mark('normalize-args');

    // ---- validation ----
    stage = 'validate';
    if (srcId.isEmpty) {
      failedAt = 'validate';
      return failure(
          templateWorkoutId == null
              ? 'templateWorkoutId binding resolved to NULL - check the '
                  'onUseTemplate callback parameter'
              : 'templateWorkoutId is empty',
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
    mark('validate');

    // ================= INNER (DB work) =================
    try {
      stage = 'db-handle';
      final db = SQLiteManager.instance.database;
      final String nowIso = DateTime.now().toIso8601String();
      mark('db-handle');

      // ---- 1. template row (by workout_id, then by id) ----
      final List tRows = await guarded(
          'read-template',
          () => db.rawQuery(
                'SELECT id, name, workout_id FROM workout_template '
                'WHERE workout_id = ? OR id = ? LIMIT 1',
                [srcId, srcId],
              ));
      String templateName = '';
      String sourceWorkoutId = srcId;
      String altWorkoutId = '';
      if (tRows.isNotEmpty) {
        final Map t = tRows.first as Map;
        templateName = str(t['name']);
        final String wid = str(t['workout_id']);
        final String tid = str(t['id']);
        sourceWorkoutId = wid.isNotEmpty ? wid : tid;
        altWorkoutId = wid.isNotEmpty ? tid : '';
      }
      mark('template(found=${tRows.isNotEmpty}, "$templateName")');

      // ---- 2. source exercises (try the alternate link if empty) ----
      List weRows = await guarded(
          'read-workout_exercises',
          () => db.rawQuery(
                'SELECT * FROM workout_exercise WHERE workout_id = ? '
                'ORDER BY "order", created_at',
                [sourceWorkoutId],
              ));
      if (weRows.isEmpty &&
          altWorkoutId.isNotEmpty &&
          altWorkoutId != sourceWorkoutId) {
        final List alt = await guarded(
            'read-workout_exercises(alt)',
            () => db.rawQuery(
                  'SELECT * FROM workout_exercise WHERE workout_id = ? '
                  'ORDER BY "order", created_at',
                  [altWorkoutId],
                ));
        if (alt.isNotEmpty) {
          sourceWorkoutId = altWorkoutId;
          weRows = alt;
        }
      }
      if (weRows.isEmpty) {
        failedAt = 'read-workout_exercises';
        return failure(
            'No workout_exercise rows for template $srcId '
                '(looked at workout_id=$sourceWorkoutId)',
            'NotFound',
            tRows.isEmpty ? MSG_NOT_FOUND : MSG_EMPTY);
      }
      mark('workout_exercises-read(${weRows.length})');

      // Name fallback: the source workout's own name.
      if (templateName.isEmpty) {
        final List wRows = await guarded(
            'read-source-workout',
            () => db.rawQuery(
                  'SELECT name FROM workout WHERE id = ? LIMIT 1',
                  [sourceWorkoutId],
                ));
        if (wRows.isNotEmpty) {
          templateName = str((wRows.first as Map)['name']);
        }
      }
      if (templateName.isEmpty) templateName = 'Template workout';

      // ---- 3. source sets (via workout_exercise ids, not es.workout_id) ----
      final List<String> srcWeIds = [];
      for (final r in weRows) {
        final String id = str((r as Map)['id']);
        if (id.isNotEmpty) srcWeIds.add(id);
      }
      List esRows = const [];
      if (srcWeIds.isNotEmpty) {
        final String ph = List.filled(srcWeIds.length, '?').join(',');
        esRows = await guarded(
            'read-exercise_sets',
            () => db.rawQuery(
                  'SELECT * FROM exercise_sets '
                  'WHERE workout_exercise_id IN ($ph) '
                  'ORDER BY set_number, COALESCE(is_dropset, 0), '
                  'COALESCE(drop_number, 0)',
                  srcWeIds,
                ));
      }
      mark('exercise_sets-read(${esRows.length})');

      // ---- 4. Hive (idempotent init) ----
      await guarded('hive-init', () => Hive.initFlutter());
      final Box workoutBox = await guarded(
          'hive-open-workouts', () => Hive.openBox('pendingWorkouts'));
      final Box weBox = await guarded('hive-open-workoutExercises',
          () => Hive.openBox('pendingWorkoutExercises'));
      final Box setBox = await guarded(
          'hive-open-exerciseSets', () => Hive.openBox('pendingExerciseSets'));
      mark('hive-open');

      // ---- 5. unique name among the user's workouts ----
      String name = templateName;
      final List nRows = await guarded(
          'read-names',
          () => db.rawQuery(
                'SELECT name FROM workout '
                'WHERE user_id = ? AND COALESCE(is_deleted, 0) = 0 '
                'AND (name = ? OR name LIKE ?)',
                [uId, templateName, '$templateName %'],
              ));
      final Set<String> taken = {};
      for (final r in nRows) {
        taken.add(str((r as Map)['name']).toLowerCase());
      }
      if (taken.contains(name.toLowerCase())) {
        int n = 2;
        while (taken.contains('$templateName $n'.toLowerCase())) {
          n++;
        }
        name = '$templateName $n';
      }
      mark('name("$name")');

      // ---- 6. workout ----
      final String workoutId = uuid();
      await guarded(
          'insert-workout',
          () => db.rawInsert(
                'INSERT OR IGNORE INTO workout '
                '(id, name, created_at, user_id, is_deleted) '
                'VALUES (?, ?, ?, ?, 0)',
                [workoutId, name, nowIso, uId],
              ));
      await guarded(
          'hive-add-workout',
          () => workoutBox.add({
                'id': workoutId,
                'name': name,
                'user_id': uId,
              }));
      mark('workout');

      // ---- 7. workout_exercises (new ids, superset groups re-keyed) ----
      final Map<String, String> weIdByOld = {};
      final Map<String, String> supersetGroupByOld = {};
      int order = 0;
      int savedExercises = 0;

      for (final raw in weRows) {
        final Map r = raw as Map;
        final int exerciseId = toInt(r['exercise_id']) ?? 0;
        if (exerciseId <= 0) continue;

        String exerciseName = str(r['exercise_name']);
        if (exerciseName.isEmpty) {
          final List eRows = await guarded(
              'read-exercise-name($exerciseId)',
              () => db.rawQuery(
                    'SELECT name FROM exercise WHERE id = ? LIMIT 1',
                    [exerciseId],
                  ));
          if (eRows.isNotEmpty) {
            exerciseName = str((eRows.first as Map)['name']);
          }
        }
        if (exerciseName.isEmpty) exerciseName = 'Exercise $exerciseId';

        order++;
        final String oldId = str(r['id']);
        final int restMs = toInt(r['rest_seconds']) ?? 90000;
        final int isSuperset = flag(r['is_superset']);
        final String? oldGroup = strOrNull(r['superset_group_id']);
        String? supersetGroupId;
        if (isSuperset == 1 && oldGroup != null) {
          supersetGroupId = supersetGroupByOld.putIfAbsent(oldGroup, uuid);
        }
        final String? notes = strOrNull(r['notes']);

        final String weId = uuid();
        if (oldId.isNotEmpty) weIdByOld[oldId] = weId;
        final String tag = 'ex=$exerciseId "$exerciseName"';

        await guarded(
            'insert-workout_exercise($tag)',
            () => db.rawInsert(
                  'INSERT OR IGNORE INTO workout_exercise '
                  '(id, workout_id, exercise_id, created_at, "order", '
                  'exercise_name, user_id, rest_seconds, notes, is_superset, '
                  'superset_group_id) '
                  'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                  [
                    weId,
                    workoutId,
                    exerciseId,
                    nowIso,
                    order,
                    exerciseName,
                    uId,
                    restMs,
                    notes,
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
                  'user_id': uId,
                }));
        savedExercises++;
      }
      if (savedExercises == 0) {
        failedAt = 'workout_exercises';
        return failure(
            'Template rows had no valid exercise_id', 'NotFound', MSG_EMPTY);
      }
      mark('workout_exercises($savedExercises)');

      // ---- 8. exercise_sets (copied as stored, re-parented) ----
      int savedSets = 0;
      for (final raw in esRows) {
        final Map r = raw as Map;
        final String? newWeId = weIdByOld[str(r['workout_exercise_id'])];
        if (newWeId == null) continue;

        final String setId = uuid();
        final int setNumber = toInt(r['set_number']) ?? 1;
        final int isWarmup = flag(r['is_warmup']);
        final int isDrop = flag(r['is_dropset']);
        final int? dropNumber = toInt(r['drop_number']);
        final int? targetReps = toInt(r['target_reps']);
        final int weighted = r['weighted'] == null
            ? 1
            : ((toInt(r['weighted']) ?? 1) == 0 ? 0 : 1);
        final int? durationSeconds = toInt(r['duration_seconds']);
        final String tag = 'we=$newWeId n=$setNumber w=$isWarmup d=$isDrop';

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
                    newWeId,
                    setNumber,
                    dropNumber,
                    targetReps,
                    durationSeconds,
                    isWarmup,
                    isDrop,
                    weighted,
                  ],
                ));
        await guarded(
            'hive-add-exercise_set($tag)',
            () => setBox.add({
                  'id': setId,
                  'workout_exercise_id': newWeId,
                  'set_number': setNumber,
                  'target_reps': targetReps,
                  'is_warmup': isWarmup,
                  'is_dropset': isDrop,
                  'drop_number': dropNumber,
                  'workout_id': workoutId,
                  'weighted': weighted,
                  'duration_seconds': durationSeconds,
                }));
        savedSets++;
      }
      mark('exercise_sets($savedSets)');

      stage = 'done';
      xliftLogAdd('[saveTpl] DONE "$name" from $sourceWorkoutId '
          'exercises=$savedExercises sets=$savedSets '
          'total=${sw.elapsedMilliseconds}ms');
      return {
        'success': true,
        'message': '',
        'workoutId': workoutId,
        'name': name,
        'exercises': savedExercises,
        'sets': savedSets,
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
        'workoutId': '',
        'name': '',
        'exercises': 0,
        'sets': 0,
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
