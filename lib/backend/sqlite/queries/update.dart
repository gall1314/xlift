import 'package:sqflite/sqflite.dart';

/// BEGIN MARKWORKOUTSYNCED
Future performMarkWorkoutSynced(
  Database database, {
  String? id,
}) {
  final query = '''
UPDATE Workout SET is_dirty = 0 WHERE id = :id;

''';
  return database.rawQuery(query);
}

/// END MARKWORKOUTSYNCED

/// BEGIN UPDATEWORKOUTISDIRTY
Future performUpdateWorkoutIsDirty(
  Database database, {
  String? id,
  int? isDirty,
}) {
  final query = '''
UPDATE Workout SET is_dirty = :isDirty WHERE id = :id;

''';
  return database.rawQuery(query);
}

/// END UPDATEWORKOUTISDIRTY

/// BEGIN INSERTWORKOUT
Future performInsertWorkout(
  Database database, {
  String? id,
  String? name,
  String? createdAt,
  String? userId,
}) {
  final query = '''
INSERT OR IGNORE INTO workout (
  id,
  name,
  created_at,
  user_id
  )
VALUES (
  '${id}',
  '${name}',
  '${createdAt}',
  '${userId}'
  );

''';
  return database.rawQuery(query);
}

/// END INSERTWORKOUT

/// BEGIN INSERTWORKOUTEXERCISE
Future performInsertWorkoutExercise(
  Database database, {
  String? id,
  String? workoutId,
  String? createdAt,
  int? order,
  int? exerciseId,
  int? restSeconds,
  String? exerciseName,
  String? userId,
  int? isSuperset,
  String? supersetGroupId,
}) {
  final query = '''
INSERT OR IGNORE INTO workout_exercise (
  id,
  workout_id,
  exercise_id,
  created_at,
  "order",
  exercise_name,
  user_id,
  rest_seconds,
  is_superset,
  superset_group_id
)
VALUES (
  '${id}',
  '${workoutId}',
  ${exerciseId},
  '${createdAt}',
  ${order},
  '${exerciseName}',
  '${userId}',
  ${restSeconds},
  ${isSuperset},
  '${supersetGroupId}'
);
''';
  return database.rawQuery(query);
}

/// END INSERTWORKOUTEXERCISE

/// BEGIN INSERTWORKOUTLOG
Future performInsertWorkoutLog(
  Database database, {
  String? workoutId,
  String? userId,
  String? createdAt,
  int? durationSeconds,
  int? isDirty,
  String? id,
}) {
  final query = '''
INSERT OR IGNORE INTO workout_log (
  id,
  workout_id,
  user_id,
  created_at,
  duration_seconds
 )
 VALUES (
  '${id}',
  '${workoutId}',
  '${userId}',
  '${createdAt}',
  ${durationSeconds}
   );


''';
  return database.rawQuery(query);
}

/// END INSERTWORKOUTLOG

/// BEGIN INSERTSETLOG
Future performInsertSetLog(
  Database database, {
  String? workoutLogId,
  int? exerciseId,
  int? setNumber,
  int? reps,
  double? weight,
  int? durationSeconds,
  String? createdAt,
}) {
  final query = '''
INSERT OR IGNORE INTO set_log (
  workout_log_id,
  exercise_id,
  set_number,
  reps,
  weight,
  duration_seconds,
  created_at
)
 VALUES (
  '${workoutLogId}',
  ${exerciseId},
  ${setNumber},
  ${reps},
  ${weight},
  ${durationSeconds},
  '${createdAt}'
);

''';
  return database.rawQuery(query);
}

/// END INSERTSETLOG

/// BEGIN INSERTUSER
Future performInsertUser(
  Database database, {
  String? id,
  String? username,
  String? email,
  int? isKg,
}) {
  final query = '''
INSERT OR IGNORE INTO users (
  id,
  email,
  username,
  is_kg
) 
VALUES (
  '${id}',
  '${email}',
  '${username}',
  ${isKg}
);

''';
  return database.rawQuery(query);
}

/// END INSERTUSER

/// BEGIN LATESTWORKOUTSUMMARY
Future performLatestWorkoutSummary(
  Database database,
) {
  final query = '''
CREATE VIEW IF NOT EXISTS LatestWorkoutSummary AS
WITH latestWorkout AS (
  SELECT id
  FROM WorkoutLog
  ORDER BY createdAt DESC
  LIMIT 1
)

SELECT
  sl.exerciseId,
  e.name AS exerciseName,
  e.isTimed,
  e.isBodyweight,
  COUNT(*) AS totalSets
FROM SetLog sl
JOIN latestWorkout lw ON sl.workoutLogId = lw.id
JOIN exerciseList e ON sl.exerciseId = e.id
GROUP BY sl.exerciseId;

''';
  return database.rawQuery(query);
}

/// END LATESTWORKOUTSUMMARY

/// BEGIN SETLOGTEST
Future performSetLogTest(
  Database database, {
  String? workoutLogId,
  String? createdAt,
  int? exerciseId,
  int? setNumber,
  int? reps,
  double? weight,
  int? durationSeconds,
  int? isKg,
  int? isDropSet,
  int? dropNumber,
  String? id,
  String? userId,
}) {
  final query = '''
INSERT OR IGNORE INTO set_log (
  id,
  workout_log_id,
  created_at,
  exercise_id,
  set_number,
  reps,
  weight,
  duration_seconds,
  is_kg,
  is_dropset,
  drop_number,
  user_id
) VALUES (
  '${id}',
  '${workoutLogId}',
  '${createdAt}',
  ${exerciseId},
  ${setNumber},
  ${reps},
  ${weight},
  ${durationSeconds},
  ${isKg},
  ${isDropSet},
  ${dropNumber},
  '${userId}'
);

''';
  return database.rawQuery(query);
}

/// END SETLOGTEST

/// BEGIN LASTWEEKSTATA
Future performLastWeekStata(
  Database database,
) {
  final query = '''
SELECT
  COUNT(DISTINCT wl.id) AS workoutCount,
  COUNT(*) AS totalSets,
  SUM(sl.reps * sl.weight) AS totalVolume
FROM SetLog sl
JOIN WorkoutLog wl ON sl.workoutLogId = wl.id
WHERE wl.createdAt >= strftime('%Y-%m-%d %H:%M:%S', 'now', '-7 days')
  AND sl.reps IS NOT NULL
  AND sl.weight IS NOT NULL;

''';
  return database.rawQuery(query);
}

/// END LASTWEEKSTATA

/// BEGIN LATESTWORKOUTBASIC
Future performLatestWorkoutBasic(
  Database database,
) {
  final query = '''
DROP VIEW IF EXISTS LatestWorkoutWithVolume;
CREATE VIEW LatestWorkoutWithVolume AS
SELECT
  sl.exerciseId,
  e.name AS exerciseName,
  COUNT(*) AS totalSets,
  COALESCE(SUM(
    CASE WHEN sl.reps IS NOT NULL AND sl.weight IS NOT NULL
         THEN sl.reps * sl.weight
         ELSE 0 END
  ), 0) AS totalVolume
FROM SetLog sl
JOIN exerciseList e ON e.id = sl.exerciseId
WHERE sl.workoutLogId = (
  SELECT id
  FROM WorkoutLog
  ORDER BY datetime(createdAt) DESC
  LIMIT 1
)
GROUP BY sl.exerciseId, e.name;

''';
  return database.rawQuery(query);
}

/// END LATESTWORKOUTBASIC

/// BEGIN LASTWORKOUTSUMMARY
Future performLastWorkoutSummary(
  Database database,
) {
  final query = '''
DROP VIEW IF EXISTS lastWorkoutSummary;

CREATE VIEW lastWorkoutSummary AS
WITH wl_last AS (
  SELECT *
  FROM WorkoutLog
  WHERE createdAt = (SELECT MAX(createdAt) FROM WorkoutLog)
)
SELECT
  CAST(WL.id AS TEXT) AS workoutLogId,

  -- מספר סטים בפועל
  (SELECT COUNT(*) FROM SetLog SL2 WHERE SL2.workoutLogId = WL.id) AS totalSets,

  -- זמן יחסי (נרמול ISO8601: מחליפים T ב-רווח ומסירים Z)
  CASE
    WHEN ((strftime('%s','now')
          - strftime('%s', replace(replace(WL.createdAt,'T',' '),'Z',''))) / 3600.0) < 1
      THEN 'less than an hour ago'
    WHEN ((strftime('%s','now')
          - strftime('%s', replace(replace(WL.createdAt,'T',' '),'Z',''))) / 3600.0) < 24
      THEN CAST(CAST(((strftime('%s','now')
          - strftime('%s', replace(replace(WL.createdAt,'T',' '),'Z',''))) / 3600) AS INTEGER) AS TEXT) || ' hours ago'
    ELSE CAST(CAST(((strftime('%s','now')
          - strftime('%s', replace(replace(WL.createdAt,'T',' '),'Z',''))) / 86400) AS INTEGER) AS TEXT) || ' days ago'
  END AS timeAgo,

  -- קבוצות שריר ראשיות
  (
    SELECT group_concat(pmg_name, ', ')
    FROM (
      SELECT DISTINCT PMG.name AS pmg_name
      FROM SetLog SL
      JOIN exerciseMuscleGroup EMG
           ON EMG.exerciseId = SL.exerciseId
          AND EMG.isPrimary = 1
      JOIN muscleGroup MG
           ON MG.id = EMG.muscleGroupId
      JOIN primaryMuscleGroup PMG
           ON PMG.id = MG.primaryMuscleGroupId
      WHERE SL.workoutLogId = WL.id
    )
  ) AS mainMuscles
FROM wl_last WL;


''';
  return database.rawQuery(query);
}

/// END LASTWORKOUTSUMMARY

/// BEGIN DELETEWOREX
Future performDeleteWorex(
  Database database, {
  String? workoutId,
}) {
  final query = '''
DELETE FROM workout_exercise
WHERE workout_id = '${workoutId}'; 
''';
  return database.rawQuery(query);
}

/// END DELETEWOREX

/// BEGIN UPDATEWORKOUT
Future performUpdateWorkout(
  Database database, {
  String? workoutId,
  String? newName,
}) {
  final query = '''
UPDATE workout
SET name = '${newName}'
WHERE id = '${workoutId}';  
''';
  return database.rawQuery(query);
}

/// END UPDATEWORKOUT

/// BEGIN DELETEWORKOUT
Future performDeleteWorkout(
  Database database, {
  String? workoutId,
}) {
  final query = '''
UPDATE workout
SET is_deleted = 1
WHERE id = '${workoutId}';   -- אם id הוא TEXT:  WHERE id = '${workoutId}'

''';
  return database.rawQuery(query);
}

/// END DELETEWORKOUT

/// BEGIN UPDATE WORKOUTLOGVOLUME
Future performUPDATEWorkoutLogVolume(
  Database database, {
  double? newVolume,
  String? workoutLogId,
}) {
  final query = '''
UPDATE workout_log
SET volume = ${newVolume}
WHERE id = '${workoutLogId}';

''';
  return database.rawQuery(query);
}

/// END UPDATE WORKOUTLOGVOLUME

/// BEGIN EXERCISEMUSCLELIST
Future performExerciseMuscleList(
  Database database,
) {
  final query = '''
DROP VIEW IF EXISTS exerciseMuscleList;

CREATE VIEW exerciseMuscleList AS
SELECT
  emg.exerciseId                       AS exerciseId,
  mg.id                                AS muscleGroupId,
  mg.name                              AS muscleName,
  mg.imageUrl                          AS imageUrl,
  mg.primaryMuscleGroupId              AS primaryMuscleGroupId,  -- אופציונלי לשימוש עתידי
  CASE
    WHEN emg.isPrimary IN (1, '1', 't', 'true', 'TRUE') THEN 1
    ELSE 0
  END                                  AS isPrimary
FROM exerciseMuscleGroup emg
JOIN muscleGroup mg ON mg.id = emg.muscleGroupId;

''';
  return database.rawQuery(query);
}

/// END EXERCISEMUSCLELIST

/// BEGIN DELETE WORKOUTLOG
Future performDeleteWorkoutLog(
  Database database, {
  String? workoutLogId,
}) {
  final query = '''
DELETE FROM workout_log
WHERE id = '${workoutLogId}';
''';
  return database.rawQuery(query);
}

/// END DELETE WORKOUTLOG

/// BEGIN DELETE SETLOGS
Future performDeleteSetLogs(
  Database database, {
  String? workoutLogId,
}) {
  final query = '''
DELETE FROM set_log
WHERE workout_log_id = '${workoutLogId}';

''';
  return database.rawQuery(query);
}

/// END DELETE SETLOGS

/// BEGIN UPDATE WORKOUTLOG
Future performUpdateWorkoutLog(
  Database database, {
  String? workoutLogId,
  String? newDate,
  int? newDuration,
}) {
  final query = '''
UPDATE workout_log
SET 
  created_at = '${newDate}'

,            -- תאריך/שעה חדשים
  duration_seconds = ${newDuration}   -- משך האימון בשניות
WHERE id = '${workoutLogId}'


''';
  return database.rawQuery(query);
}

/// END UPDATE WORKOUTLOG

/// BEGIN CREATEUSEREXERCISE
Future performCreateUserExercise(
  Database database, {
  int? id,
  String? userId,
  String? name,
  String? equipment,
  int? isBodyweight,
  int? isTimed,
  int? allowsBodyweight,
  String? illustration,
}) {
  final query = '''
INSERT INTO exercise (
  id,
  created_by_user_id,
  name,
  equipment,
  is_bodyweight,
  allows_bodyweight,
  is_time_based,
  is_public,
  is_deleted,
  illustration
)
VALUES (
  ${id},
  '${userId}',
  '${name}',
  '${equipment}',
  ${isBodyweight},
  ${allowsBodyweight},
  ${isTimed},
  0,   -- user exercise: not public
  0,
  CASE WHEN '${illustration}' IN ('', 'null') THEN NULL ELSE '${illustration}' END
);
''';
  return database.rawQuery(query);
}

/// END CREATEUSEREXERCISE

/// BEGIN INSERTWORKOUTEXERCISE1
Future performInsertWorkoutExercise1(
  Database database, {
  String? id,
  String? workoutId,
  int? order,
  int? exerciseId,
  String? exerciseName,
  String? userId,
  DateTime? createdAt,
}) {
  final query = '''
INSERT INTO workout_exercise (
  id,
  workout_id,
  exercise_id,
  created_at,
  "order",
  exercise_name,
  user_id
)
VALUES (
  '${id}',
  '${workoutId}',
  '${exerciseId}',
  '${createdAt}',
  '${order}',
  '${exerciseName}',
  '${userId}'
);

''';
  return database.rawQuery(query);
}

/// END INSERTWORKOUTEXERCISE1

/// BEGIN USEREXERCISEMUSCLEGROUP
Future performUserExerciseMuscleGroup(
  Database database, {
  int? id,
  int? muscleGroupId,
  int? exerciseId,
  int? isPrimary,
}) {
  final query = '''
INSERT INTO exercise_muscle_group (
  id,
  muscle_group_id,
  is_primary,
  exercise_id
)
VALUES (
  ${id},               -- חובה! מזהה רשומה בטבלה
  ${muscleGroupId},    -- מזהה השריר הקטן
  ${isPrimary},        -- 1 = primary, 0 = secondary
  ${exerciseId}        -- מזהה התרגיל החדש
);

''';
  return database.rawQuery(query);
}

/// END USEREXERCISEMUSCLEGROUP

/// BEGIN INSERTEXERCISESTS
Future performInsertExerciseSts(
  Database database, {
  String? workoutExerciseId,
  int? setNumber,
  int? targetReps,
  int? isWarmup,
  int? isDropset,
  int? dropNumber,
  String? workoutId,
  String? id,
  int? weighted,
  int? durationSeconds,
}) {
  final query = '''
INSERT INTO exercise_sets (
  id,
  workout_id,
  workout_exercise_id,
  set_number,
  drop_number,
  target_reps,
  duration_seconds,
  is_warmup,
  is_dropset,
  weighted
)
VALUES (
  '${id}',
  '${workoutId}',
  '${workoutExerciseId}',
  ${setNumber},
  ${dropNumber},
  ${targetReps},
  ${durationSeconds},
  ${isWarmup},
  ${isDropset},
  ${weighted}
);

''';
  return database.rawQuery(query);
}

/// END INSERTEXERCISESTS

/// BEGIN WOREXTEST
Future performWorexTest(
  Database database,
) {
  final query = '''
INSERT INTO workout_exercise (
  id,
  workout_id,
  exercise_id,
  created_at,
  "order",
  exercise_name,
  rest_seconds
)
VALUES (
  'test_id_123',
  'test_workout_123',
  77,
  '2025-01-01T10:00:00Z',
  1,
  'Test Name',
  60
);

''';
  return database.rawQuery(query);
}

/// END WOREXTEST

/// BEGIN UODATEPROFILE
Future performUodateProfile(
  Database database, {
  String? profileImage,
  String? userId,
}) {
  final query = '''
UPDATE users
SET profile_image_url = ${profileImage}
WHERE id = '${userId}';

''';
  return database.rawQuery(query);
}

/// END UODATEPROFILE

/// BEGIN UPDATEBODYMESURS
Future performUpdateBodyMesurs(
  Database database, {
  int? age,
  double? weight,
  double? height,
  String? userId,
}) {
  final query = '''
UPDATE users
SET
  age    = ${age},
  weight = ${weight},
  height = ${height}
WHERE id = '${userId}';

''';
  return database.rawQuery(query);
}

/// END UPDATEBODYMESURS

/// BEGIN SMARTWOREX
Future performSmartWorex(
  Database database, {
  String? id,
  String? workoutId,
  String? createdAt,
  int? order,
  String? userId,
  int? restSeconds,
  int? exerciseId,
}) {
  final query = '''
INSERT INTO workout_exercise (
  id,
  workout_id,
  exercise_id,
  created_at,
  "order",
  exercise_name,
  user_id,
  rest_seconds
)
SELECT
  '${id}'              AS id,
  '${workoutId}'       AS workout_id,
  e.id                 AS exercise_id,
  '${createdAt}'       AS created_at,
  ${order}             AS "order",
  e.name               AS exercise_name,
  '${userId}'          AS user_id,
  ${restSeconds}       AS rest_seconds
FROM exercise e
WHERE e.id = ${exerciseId}
  AND e.is_deleted = 0;

''';
  return database.rawQuery(query);
}

/// END SMARTWOREX

/// BEGIN DELETEEXERCISESETS
Future performDeleteExerciseSets(
  Database database, {
  String? workoutId,
}) {
  final query = '''
DELETE FROM exercise_sets
 WHERE workout_id = '${workoutId}'; 

''';
  return database.rawQuery(query);
}

/// END DELETEEXERCISESETS

/// BEGIN UPDATEUSERSMEASURS
Future performUpdateUsersMeasurs(
  Database database, {
  double? height,
  double? weight,
  int? heightIsCm,
  int? bodyWeightIsKg,
  String? sex,
  String? dateOfBirth,
  String? userId,
}) {
  final query = '''
UPDATE users
SET
  height = ${height},
  weight = ${weight},
  height_is_cm = ${heightIsCm},
  body_weight_is_kg = ${bodyWeightIsKg},
  sex = '${sex}',
  date_of_birth = '${dateOfBirth}'
WHERE id = '${userId}';

''';
  return database.rawQuery(query);
}

/// END UPDATEUSERSMEASURS

/// BEGIN WEEKLYROUTINE
Future performWeeklyroutine(
  Database database, {
  String? userId,
  String? routineName,
  int? isActive,
  String? createdAt,
  String? routineId,
}) {
  final query = '''
INSERT INTO weekly_routine (
  id,
  user_id,
  name,
  is_active,
  created_at
)
VALUES (
  '${routineId}',
  '${userId}',
  '${routineName}',
  ${isActive},
  '${createdAt}'
);


''';
  return database.rawQuery(query);
}

/// END WEEKLYROUTINE

/// BEGIN WEEKLYROUTINEDAY
Future performWeeklyroutineday(
  Database database, {
  String? routineId,
  int? dayIndex,
  String? workoutId,
  int? restHours,
}) {
  final query = '''
INSERT INTO weekly_routine_day (
  routine_id,
  day_index,
  workout_id,
  rest_hours
)
VALUES (
  '${routineId}',
  ${dayIndex},
  '${workoutId}',
  ${restHours}
);

''';
  return database.rawQuery(query);
}

/// END WEEKLYROUTINEDAY

/// BEGIN DELETEUSEREXERCISE
Future performDeleteUserExercise(
  Database database, {
  int? exerciseId,
}) {
  final query = '''
UPDATE exercise
SET is_deleted = 1
WHERE id = ${exerciseId}
  AND is_public = 0;

''';
  return database.rawQuery(query);
}

/// END DELETEUSEREXERCISE

/// BEGIN DELETEWOREXUSEREX
Future performDeleteWorexUserEx(
  Database database, {
  int? exerciseId,
  String? userId,
}) {
  final query = '''
DELETE FROM workout_exercise
WHERE exercise_id = ${exerciseId}
  AND user_id = '${userId}';

''';
  return database.rawQuery(query);
}

/// END DELETEWOREXUSEREX

/// BEGIN INSERTSETANALYSIS
Future performInsertSetANalysis(
  Database database, {
  String? id,
  String? setLogId,
  String? analyzedAt,
  double? score,
  int? totalReps,
  int? properReps,
  String? feedback,
  String? techniqueLabel,
  String? techniqueScoreDisplay,
  String? formTip,
}) {
  final query = '''
INSERT INTO set_analysis (
  id,
  set_log_id,
  analyzed_at,
  score,
  total_reps,
  proper_reps,
  feedback,
  technique_label,
  technique_score_display,
  form_tip
) VALUES (
  '${id}',
  '${setLogId}',
  '${analyzedAt}',
  ${score},
  ${totalReps},
  ${properReps},
  '${feedback}',
  '${techniqueLabel}',
  '${techniqueScoreDisplay}',
  '${formTip}'
);
''';
  return database.rawQuery(query);
}

/// END INSERTSETANALYSIS

/// BEGIN DELETEUSER
Future performDeleteUser(
  Database database, {
  String? userId,
}) {
  final query = '''
-- 1. ניתוחי סטים
DELETE FROM set_analysis
WHERE set_log_id IN (SELECT id FROM set_log WHERE user_id = '${userId}');

-- 2. לוג הסטים
DELETE FROM set_log WHERE user_id = '${userId}';

-- 3. סטים מוגדרים
DELETE FROM exercise_sets
WHERE workout_exercise_id IN (SELECT id FROM workout_exercise WHERE user_id = '${userId}');

-- 4. תרגילים בתוך אימונים
DELETE FROM workout_exercise WHERE user_id = '${userId}';

-- 5. תבניות אימון
DELETE FROM workout_template
WHERE workout_id IN (SELECT id FROM workout WHERE user_id = '${userId}');

-- 6. ימי שגרה שבועית
DELETE FROM weekly_routine_day
WHERE routine_id IN (SELECT id FROM weekly_routine WHERE user_id = '${userId}');

-- 7. שגרה שבועית
DELETE FROM weekly_routine WHERE user_id = '${userId}';

-- 8. לוגי אימון
DELETE FROM workout_log WHERE user_id = '${userId}';

-- 9. אימונים
DELETE FROM workout WHERE user_id = '${userId}';

-- 10. שיוכי שריר של תרגילי המשתמש (לפני מחיקת התרגילים עצמם)
DELETE FROM exercise_muscle_group
WHERE exercise_id IN (SELECT id FROM exercise WHERE created_by_user_id = '${userId}');

-- 11. תרגילים מותאמים אישית שהמשתמש יצר
DELETE FROM exercise WHERE created_by_user_id = '${userId}';

-- 12. המשתמש עצמו (שקול לדלג מקומית — ראה הערה קודמת)
DELETE FROM users WHERE id = '${userId}';
''';
  return database.rawQuery(query);
}

/// END DELETEUSER

/// BEGIN INSERTDELETEDWORKOUT
Future performInsertdeletedWorkout(
  Database database, {
  String? id,
  String? name,
  String? createdAt,
  String? userId,
}) {
  final query = '''
INSERT OR IGNORE INTO workout (
  id,
  name,
  created_at,
  user_id,
  is_deleted
  )
VALUES (
  '${id}',
  '${name}',
  '${createdAt}',
  '${userId}',
   1
  );

''';
  return database.rawQuery(query);
}

/// END INSERTDELETEDWORKOUT

/// BEGIN DELETSETANALYSIS
Future performDeletSetAnalysis(
  Database database, {
  String? analysisId,
}) {
  final query = '''
DELETE FROM set_analysis
WHERE id = '${analysisId}';
''';
  return database.rawQuery(query);
}

/// END DELETSETANALYSIS

/// BEGIN REPLACEEXERCISEINPLAN
Future performReplaceExerciseInPlan(
  Database database, {
  String? workoutId,
  int? oldExerciseId,
  int? newExerciseId,
}) {
  final query = '''
-- params: ${workoutId} (String), ${oldExerciseId} (Integer), ${newExerciseId} (Integer)
-- Permanently swaps the exercise in the saved plan. Keeps order, rest,
-- notes and superset grouping. Name is read from the catalog, so names
-- with apostrophes (Farmer's Walk) can't break the query.

UPDATE workout_exercise
SET exercise_id   = ${newExerciseId},
    exercise_name = COALESCE(
      (SELECT name FROM exercise WHERE id = ${newExerciseId}),
      (SELECT exercise_name FROM exercise_view WHERE exercise_id = ${newExerciseId}),
      exercise_name
    )
WHERE workout_id  = '${workoutId}'
  AND exercise_id = ${oldExerciseId};
''';
  return database.rawQuery(query);
}

/// END REPLACEEXERCISEINPLAN
