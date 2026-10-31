import '/backend/sqlite/queries/sqlite_row.dart';
import 'package:sqflite/sqflite.dart';

Future<List<T>> _readQuery<T>(
  Database database,
  String query,
  T Function(Map<String, dynamic>) create,
) =>
    database.rawQuery(query).then((r) => r.map((e) => create(e)).toList());

/// BEGIN GETDIRTYWORKOUTS
Future<List<GetdirtyworkoutsRow>> performGetdirtyworkouts(
  Database database, {
  String? userId,
}) {
  final query = '''
SELECT
  w.id                                   AS id,
  COALESCE(w.name, '')                   AS name,
  COALESCE((
    SELECT group_concat(pmg_name, ', ')
    FROM (
      SELECT DISTINCT pmg.name AS pmg_name
      FROM workout_exercise we
      JOIN exercise e
             ON e.id = we.exercise_id
      JOIN exercise_muscle_group emg
             ON emg.exercise_id = e.id
            AND COALESCE(emg.is_primary, 1) = 1
      JOIN muscle_group mg
             ON mg.id = emg.muscle_group_id
      JOIN primary_muscle_group pmg
             ON pmg.id = mg.primary_muscle_group_id
      WHERE we.workout_id = w.id
      ORDER BY pmg_name
    )
  ), '')                                  AS main_muscle_groups
FROM workout w
WHERE w.user_id = '${userId}'
  AND COALESCE(w.is_deleted, 0) = 0
ORDER BY w.created_at DESC;

''';
  return _readQuery(database, query, (d) => GetdirtyworkoutsRow(d));
}

class GetdirtyworkoutsRow extends SqliteRow {
  GetdirtyworkoutsRow(Map<String, dynamic> data) : super(data);

  String get id => data['id'] as String;
  String? get name => data['name'] as String?;
  String get mainMuscleGroups => data['main_muscle_groups'] as String;
}

/// END GETDIRTYWORKOUTS

/// BEGIN GETALLEXERCISES
Future<List<GetAllExercisesRow>> performGetAllExercises(
  Database database,
) {
  final query = '''
SELECT
  e.id             AS exercise_id,
  e.name           AS exercise_name,
  (SELECT p.name
     FROM exercise_muscle_group g
     JOIN muscle_group m ON m.id = g.muscle_group_id
     JOIN primary_muscle_group p ON p.id = m.primary_muscle_group_id
    WHERE g.exercise_id = e.id AND g.is_primary = 1
    ORDER BY g.id LIMIT 1) AS primary_muscle_1,
  (SELECT p.name
     FROM exercise_muscle_group g
     JOIN muscle_group m ON m.id = g.muscle_group_id
     JOIN primary_muscle_group p ON p.id = m.primary_muscle_group_id
    WHERE g.exercise_id = e.id AND g.is_primary = 1
      AND p.id <> (SELECT m1.primary_muscle_group_id
                     FROM exercise_muscle_group g1
                     JOIN muscle_group m1 ON m1.id = g1.muscle_group_id
                    WHERE g1.exercise_id = e.id AND g1.is_primary = 1
                    ORDER BY g1.id LIMIT 1)
    ORDER BY g.id LIMIT 1) AS primary_muscle_2,
  (SELECT m.name FROM exercise_muscle_group g JOIN muscle_group m ON m.id = g.muscle_group_id
    WHERE g.exercise_id = e.id ORDER BY g.is_primary DESC, g.id LIMIT 1 OFFSET 0) AS sub_muscle_1,
  (SELECT m.name FROM exercise_muscle_group g JOIN muscle_group m ON m.id = g.muscle_group_id
    WHERE g.exercise_id = e.id ORDER BY g.is_primary DESC, g.id LIMIT 1 OFFSET 1) AS sub_muscle_2,
  (SELECT m.name FROM exercise_muscle_group g JOIN muscle_group m ON m.id = g.muscle_group_id
    WHERE g.exercise_id = e.id ORDER BY g.is_primary DESC, g.id LIMIT 1 OFFSET 2) AS sub_muscle_3,
  e.equipment      AS equipment,
  e.exercise_type  AS exercise_type
FROM exercise e
WHERE e.is_deleted = 0
ORDER BY e.id;
''';
  return _readQuery(database, query, (d) => GetAllExercisesRow(d));
}

class GetAllExercisesRow extends SqliteRow {
  GetAllExercisesRow(Map<String, dynamic> data) : super(data);

  int get exerciseId => data['exercise_id'] as int;
  String get exerciseName => data['exercise_name'] as String;
  String get primaryMuscle1 => data['primary_muscle_1'] as String;
  String? get primaryMuscle2 => data['primary_muscle_2'] as String?;
  String? get subMuscle1 => data['sub_muscle_1'] as String?;
  String? get subMuscle2 => data['sub_muscle_2'] as String?;
  String? get subMuscle3 => data['sub_muscle_3'] as String?;
  String get equipment => data['equipment'] as String;
  String get exerciseType => data['exercise_type'] as String;
  int get isBodyweight => data['is_bodyweight'] as int;
  int get aiFormAnalysis => data['ai_form_analysis'] as int;
  int get isAssisted => data['is_assisted'] as int;
  int get isPublic => data['is_public'] as int;
}

/// END GETALLEXERCISES

/// BEGIN USER
Future<List<UserRow>> performUser(
  Database database, {
  String? userId,
}) {
  final query = '''
SELECT *
FROM users
WHERE id = '${userId}'
LIMIT 1;

''';
  return _readQuery(database, query, (d) => UserRow(d));
}

class UserRow extends SqliteRow {
  UserRow(Map<String, dynamic> data) : super(data);

  String get id => data['id'] as String;
  String get email => data['email'] as String;
  String get username => data['username'] as String;
  String? get dateOfBirth => data['date_of_birth'] as String?;
  String? get sex => data['sex'] as String?;
  double? get height => data['height'] as double?;
  double? get weight => data['weight'] as double?;
  int? get heightIsCm => data['height_is_cm'] as int?;
  int? get bodyWeightIsKg => data['body_weight_is_kg'] as int?;
}

/// END USER

/// BEGIN GETEXERCISESFORWORKOUT
Future<List<GetExercisesForWorkoutRow>> performGetExercisesForWorkout(
  Database database, {
  String? workoutId,
}) {
  final query = '''
SELECT
  we.id,
  we.exercise_id,
  we.exercise_name,
  we.order_index,
  e.ai_form_analysis,
  e.is_bodyweight,
  e.is_timed
FROM workout_exercise we
LEFT JOIN exercise_list e ON we.exercise_id = e.id
WHERE we.workout_id = '${workoutId}';

''';
  return _readQuery(database, query, (d) => GetExercisesForWorkoutRow(d));
}

class GetExercisesForWorkoutRow extends SqliteRow {
  GetExercisesForWorkoutRow(Map<String, dynamic> data) : super(data);

  String get id => data['id'] as String;
  int get exerciseId => data['exerciseId'] as int;
  String get exerciseName => data['exerciseName'] as String;
  int get order => data['order'] as int;
  int get aiFormAnalysis => data['aiFormAnalysis'] as int;
  int get isBodyweight => data['isBodyweight'] as int;
  int get isTimed => data['isTimed'] as int;
}

/// END GETEXERCISESFORWORKOUT

/// BEGIN GETEXERCISESSIMP
Future<List<GetExercisesSimpRow>> performGetExercisesSimp(
  Database database, {
  String? workoutId,
}) {
  final query = '''
SELECT
  we.id,
  we.exercise_id,
  we."order",
  we.rest_seconds,
  e.name AS exercise_name,
  COALESCE(e.is_public, 0) AS is_public,
  CASE WHEN COALESCE(e.is_bodyweight, false) THEN 1 ELSE 0 END AS is_bodyweight,
  CASE WHEN COALESCE(e.is_bodyweight, false) THEN 0 ELSE 1 END AS weighted_default,
  CASE WHEN COALESCE(e.is_assisted, false) THEN 1 ELSE 0 END AS is_assisted
FROM workout_exercise AS we
JOIN exercise AS e ON e.id = we.exercise_id
WHERE we.workout_id = '${workoutId}'
ORDER BY we."order", we.id;
''';
  return _readQuery(database, query, (d) => GetExercisesSimpRow(d));
}

class GetExercisesSimpRow extends SqliteRow {
  GetExercisesSimpRow(Map<String, dynamic> data) : super(data);

  String get id => data['id'] as String;
  int get exerciseId => data['exercise_id'] as int;
  int get order => data['order'] as int;
  String get exerciseName => data['exercise_name'] as String;
  int get isBodyweight => data['is_bodyweight'] as int;
  int get weightedDefault => data['weighted_default'] as int;
  int get restSeconds => data['rest_seconds'] as int;
  int get isAssisted => data['is_assisted'] as int;
  int get isPublic => data['is_public'] as int;
}

/// END GETEXERCISESSIMP

/// BEGIN EXERCISE2
Future<List<Exercise2Row>> performExercise2(
  Database database, {
  int? exerciseId,
}) {
  final query = '''
WITH set_counts AS (
  SELECT
    sl.exercise_id,

    SUM(
      CASE
        WHEN sl.weight IS NOT NULL AND sl.weight > 0 THEN 1
        ELSE 0
      END
    ) AS weighted_sets,

    SUM(
      CASE
        WHEN sl.weight IS NULL OR sl.weight = 0 THEN 1
        ELSE 0
      END
    ) AS bodyweight_sets

  FROM set_log sl
  WHERE sl.exercise_id = ${exerciseId}
  GROUP BY sl.exercise_id
)

SELECT
  e.*,

  CASE
    -- תרגיל זמן → פשוט מחזירים את הערך הקיים
    WHEN e.is_time_based = 1 THEN e.is_bodyweight

    -- אין סטים → הערך המקורי
    WHEN sc.exercise_id IS NULL THEN e.is_bodyweight

    -- יותר סטים בלי משקל
    WHEN sc.bodyweight_sets > sc.weighted_sets THEN 1

    -- אחרת → משקל דומיננטי
    ELSE 0
  END AS is_bodyweight_dominant

FROM exercise e
LEFT JOIN set_counts sc ON sc.exercise_id = e.id
WHERE e.id = ${exerciseId}
  AND e.is_deleted = 0;

''';
  return _readQuery(database, query, (d) => Exercise2Row(d));
}

class Exercise2Row extends SqliteRow {
  Exercise2Row(Map<String, dynamic> data) : super(data);

  int get isBodyweight => data['is_bodyweight'] as int;
  int get isTimeBased => data['is_time_based'] as int;
  int? get aiFormAnalysis => data['ai_form_analysis'] as int?;
  String get name => data['name'] as String;
  String? get equipment => data['equipment'] as String?;
  String? get stepByStep => data['step_by_step'] as String?;
  String? get formTips => data['form_tips'] as String?;
  String? get longDescription => data['long_description'] as String?;
  String? get video => data['video'] as String?;
  String? get noVideoIlustration => data['no_video_ilustration'] as String?;
  String? get illustration => data['illustration'] as String?;
  int get id => data['id'] as int;
  int get isBodyweightDominant => data['is_bodyweight_dominant'] as int;
  int get allowsBodyweight => data['allows_bodyweight'] as int;
  int get isAssisted => data['is_assisted'] as int;
  int get isPublic => data['is_public'] as int;
}

/// END EXERCISE2

/// BEGIN SMARTWORKOUT
Future<List<SmartWorkoutRow>> performSmartWorkout(
  Database database, {
  String? workoutId,
}) {
  final query = '''
SELECT 
  we.exercise_id,
  we.order_index,
  el.name AS exercise_name,
  el.is_timed,
  el.is_bodyweight,
  el.ai_form_analysis
FROM workout_exercise AS we
LEFT JOIN exercise_list AS el ON we.exercise_id = el.id
WHERE we.workout_id = '${workoutId}'
ORDER BY we.order_index ASC;

''';
  return _readQuery(database, query, (d) => SmartWorkoutRow(d));
}

class SmartWorkoutRow extends SqliteRow {
  SmartWorkoutRow(Map<String, dynamic> data) : super(data);

  int get exerciseId => data['exercise_id'] as int;
  int get order => data['order'] as int;
  String get exerciseName => data['exercise_name'] as String;
  int get isTimed => data['is_timed'] as int;
  int get isBodyweight => data['is_bodyweight'] as int;
  int get aiFormAnalysis => data['ai_form_analysis'] as int;
}

/// END SMARTWORKOUT

/// BEGIN WORKOUTSUMMARY
Future<List<WorkoutSummaryRow>> performWorkoutSummary(
  Database database, {
  String? workoutLogId,
}) {
  final query = '''
SELECT 
  sl.exercise_id,
  e.name AS exercise_name
FROM set_log sl
LEFT JOIN exercise_list e ON sl.exercise_id = e.id
WHERE sl.workout_log_id = ${workoutLogId}
GROUP BY sl.exercise_id;

''';
  return _readQuery(database, query, (d) => WorkoutSummaryRow(d));
}

class WorkoutSummaryRow extends SqliteRow {
  WorkoutSummaryRow(Map<String, dynamic> data) : super(data);

  String get exerciseName => data['exercise_name'] as String;
  int get exerciseId => data['exercise_id'] as int;
}

/// END WORKOUTSUMMARY

/// BEGIN GETLATESTWORKOUTSUMMARY
Future<List<GetLatestWorkoutSummaryRow>> performGetLatestWorkoutSummary(
  Database database,
) {
  final query = '''
SELECT * FROM LatestWorkoutSummary;

''';
  return _readQuery(database, query, (d) => GetLatestWorkoutSummaryRow(d));
}

class GetLatestWorkoutSummaryRow extends SqliteRow {
  GetLatestWorkoutSummaryRow(Map<String, dynamic> data) : super(data);

  int get exerciseId => data['exerciseId'] as int;
  String get exerciseName => data['exerciseName'] as String;
  int get isTimed => data['isTimed'] as int;
  int get isBodyweight => data['isBodyweight'] as int;
  int get totalSets => data['totalSets'] as int;
  double? get totalVolume => data['totalVolume'] as double?;
}

/// END GETLATESTWORKOUTSUMMARY

/// BEGIN GETSETLOGS
Future<List<GetSetLogsRow>> performGetSetLogs(
  Database database, {
  String? workoutLogId,
  int? exerciseId,
}) {
  final query = '''
SELECT
  id,
  CAST(set_number AS INTEGER) AS set_number,
  CASE
    WHEN TRIM(CAST(reps AS TEXT)) = '' THEN NULL
    ELSE CAST(reps AS INTEGER)
  END AS reps,                       -- Nullable
  CASE
    WHEN TRIM(CAST(weight AS TEXT)) = '' THEN NULL
    ELSE CAST(weight AS REAL)
  END AS weight,                     -- Nullable
  CASE
    WHEN TRIM(CAST(duration_seconds AS TEXT)) = '' THEN NULL
    ELSE CAST(duration_seconds AS INTEGER)
  END AS duration_seconds,           -- Nullable
  CAST(COALESCE(NULLIF(CAST(is_kg AS TEXT), ''), 1) AS INTEGER) AS is_kg
FROM set_log
WHERE workout_log_id = '${workoutLogId}'
  AND CAST(exercise_id AS INTEGER) = ${exerciseId}
  AND CAST(COALESCE(NULLIF(CAST(is_dropset AS TEXT), ''), 0) AS INTEGER) = 0
ORDER BY CAST(set_number AS INTEGER) ASC;
''';
  return _readQuery(database, query, (d) => GetSetLogsRow(d));
}

class GetSetLogsRow extends SqliteRow {
  GetSetLogsRow(Map<String, dynamic> data) : super(data);

  int get setNumber => data['set_number'] as int;
  int? get reps => data['reps'] as int?;
  double? get weight => data['weight'] as double?;
  int? get durationSeconds => data['duration_seconds'] as int?;
  int get isKg => data['is_kg'] as int;
  String get id => data['id'] as String;
}

/// END GETSETLOGS

/// BEGIN WORKOUTSUMMARY
Future<List<WorkoutsummaryRow>> performWorkoutsummary(
  Database database, {
  String? workoutLogId,
}) {
  final query = '''
SELECT DISTINCT
  sl.exercise_id,
  e.name,
  e.is_timed,
  e.is_bodyweight,
  e.ai_form_analysis
FROM set_log AS sl
LEFT JOIN exercise_list AS e ON sl.exercise_id = e.id
WHERE sl.workout_log_id = '${workoutLogId}'
ORDER BY sl.exercise_id;

''';
  return _readQuery(database, query, (d) => WorkoutsummaryRow(d));
}

class WorkoutsummaryRow extends SqliteRow {
  WorkoutsummaryRow(Map<String, dynamic> data) : super(data);

  int get exerciseId => data['exercise_id'] as int;
  String get name => data['name'] as String;
  int get isTimed => data['is_timed'] as int;
  int get isBodyweight => data['is_bodyweight'] as int;
  int get aiFormAnalysis => data['ai_form_analysis'] as int;
}

/// END WORKOUTSUMMARY

/// BEGIN SETLOGSIMPSELECT
Future<List<SetlogsimpselectRow>> performSetlogsimpselect(
  Database database,
) {
  final query = '''
SELECT *
FROM set_log
ORDER BY created_at ASC;

''';
  return _readQuery(database, query, (d) => SetlogsimpselectRow(d));
}

class SetlogsimpselectRow extends SqliteRow {
  SetlogsimpselectRow(Map<String, dynamic> data) : super(data);

  int? get reps => data['reps'] as int?;
  int? get weight => data['weight'] as int?;
  int get id => data['id'] as int;
  int get setNumber => data['set_number'] as int;
}

/// END SETLOGSIMPSELECT

/// BEGIN GETLATESTWORKOUTBASIC
Future<List<GetLatestWorkoutBasicRow>> performGetLatestWorkoutBasic(
  Database database,
) {
  final query = '''
SELECT * FROM LatestWorkoutWithVolume
''';
  return _readQuery(database, query, (d) => GetLatestWorkoutBasicRow(d));
}

class GetLatestWorkoutBasicRow extends SqliteRow {
  GetLatestWorkoutBasicRow(Map<String, dynamic> data) : super(data);

  int get exerciseId => data['exerciseId'] as int;
  int get totalSets => data['totalSets'] as int;
  String get exerciseName => data['exerciseName'] as String;
  double get totalVolume => data['totalVolume'] as double;
}

/// END GETLATESTWORKOUTBASIC

/// BEGIN SMARTWORKOUT1
Future<List<SmartWorkout1Row>> performSmartWorkout1(
  Database database, {
  String? userId,
}) {
  final query = '''
SELECT
  CAST(w.id AS TEXT) AS workout_id,
  w.name             AS workout_name,
  COUNT(we.exercise_id) AS exercise_count
FROM workout w
LEFT JOIN workout_exercise we ON we.workout_id = w.id
WHERE w.user_id = '${userId}'
  AND w.is_deleted = 0
GROUP BY w.id, w.name
ORDER BY datetime(w.created_at) DESC
LIMIT 3;

''';
  return _readQuery(database, query, (d) => SmartWorkout1Row(d));
}

class SmartWorkout1Row extends SqliteRow {
  SmartWorkout1Row(Map<String, dynamic> data) : super(data);

  String get workoutName => data['workout_name'] as String;
  String get workoutId => data['workout_id'] as String;
  int get exerciseCount => data['exercise_count'] as int;
}

/// END SMARTWORKOUT1

/// BEGIN GETWORKOUTTEMPLATE
Future<List<GetWorkoutTemplateRow>> performGetWorkoutTemplate(
  Database database,
) {
  final query = '''
SELECT
  name                           AS name,
  description                    AS description,
  CAST(estimated_time AS INTEGER) AS estimated_time,
  level                          AS level,
  main_muscles                   AS main_muscles,
  workout_id                     AS workout_id
FROM workout_template;

''';
  return _readQuery(database, query, (d) => GetWorkoutTemplateRow(d));
}

class GetWorkoutTemplateRow extends SqliteRow {
  GetWorkoutTemplateRow(Map<String, dynamic> data) : super(data);

  String get name => data['name'] as String;
  String get description => data['description'] as String;
  int get estimatedTime => data['estimated_time'] as int;
  String get level => data['level'] as String;
  String get mainMuscles => data['main_muscles'] as String;
  String get workoutId => data['workout_id'] as String;
}

/// END GETWORKOUTTEMPLATE

/// BEGIN GETWORKOUTEXERCISE
Future<List<GetworkoutExerciseRow>> performGetworkoutExercise(
  Database database, {
  String? workoutId,
}) {
  final query = '''
SELECT
  we.id,
  we.exercise_id,
  e.name AS exercise_name,
  we."order" AS "order",

  /* קבוצות שריר ראשיות (עד 2, מופרדות בפסיק) */
  COALESCE((
    SELECT GROUP_CONCAT(pmg_name, ', ')
    FROM (
      SELECT DISTINCT pmg.name AS pmg_name
      FROM exercise_muscle_group emg
      JOIN muscle_group mg           ON mg.id  = emg.muscle_group_id
      JOIN primary_muscle_group pmg  ON pmg.id = mg.primary_muscle_group_id
      WHERE emg.exercise_id = we.exercise_id
        AND COALESCE(emg.is_primary, 1) = 1
      ORDER BY pmg.name
      LIMIT 2
    )
  ), '') AS main_muscle_groups,

  /* אילוסטרציה מתוך exercise */
  CAST(e.illustration AS TEXT) AS illustration,

  /* המלצה לפי מיקום התרגיל */
  CASE we."order"
    WHEN 1 THEN wt.recommendation_1
    WHEN 2 THEN wt.recommendation_2
    WHEN 3 THEN wt.recommendation_3
    WHEN 4 THEN wt.recommendation_4
    WHEN 5 THEN wt.recommendation_5
    WHEN 6 THEN wt.recommendation_6
    WHEN 7 THEN wt.recommendation_7
    ELSE NULL
  END AS recommendation

FROM workout_exercise we
JOIN exercise e            ON e.id = we.exercise_id
LEFT JOIN workout_template wt  ON wt.workout_id = '${workoutId}'
WHERE we.workout_id = '${workoutId}'
ORDER BY we."order" ASC;
''';
  return _readQuery(database, query, (d) => GetworkoutExerciseRow(d));
}

class GetworkoutExerciseRow extends SqliteRow {
  GetworkoutExerciseRow(Map<String, dynamic> data) : super(data);

  String get id => data['id'] as String;
  String get exerciseName => data['exercise_name'] as String;
  int get order => data['order'] as int;
  int get exerciseId => data['exercise_id'] as int;
  String get mainMuscleGroups => data['main_muscle_groups'] as String;
  String? get illustration => data['illustration'] as String?;
  String? get recommendation => data['recommendation'] as String?;
}

/// END GETWORKOUTEXERCISE

/// BEGIN PREVIOSSET
Future<List<PreviosSetRow>> performPreviosSet(
  Database database, {
  int? exerciseId,
  int? setNumber,
}) {
  final query = '''
WITH s AS (
  SELECT
    CAST(set_number AS INTEGER) AS set_number,

    CASE
      WHEN TRIM(CAST(reps AS TEXT)) = '' THEN NULL
      ELSE CAST(reps AS INTEGER)
    END AS reps,                       -- Nullable

    CASE
      WHEN TRIM(CAST(weight AS TEXT)) = '' THEN NULL
      ELSE CAST(weight AS REAL)
    END AS weight,                     -- Nullable

    CASE
      WHEN TRIM(CAST(duration_seconds AS TEXT)) = '' THEN NULL
      ELSE CAST(duration_seconds AS INTEGER)
    END AS duration_seconds,           -- Nullable

    CAST(COALESCE(NULLIF(CAST(is_kg AS TEXT), ''), 1) AS INTEGER) AS is_kg,

    created_at,
    rowid
  FROM set_log
  WHERE CAST(exercise_id AS INTEGER) = ${exerciseId}
    AND CAST(set_number  AS INTEGER) = ${setNumber}
    AND CAST(COALESCE(NULLIF(CAST(is_dropset AS TEXT), ''), 0) AS INTEGER) = 0
),
-- מפתח מיון חוסן ל-created_at
s_sorted AS (
  SELECT s.*,
         CASE
           WHEN (typeof(created_at) IN ('integer','real'))
                OR (CAST(created_at AS TEXT) GLOB '[0-9]*')
             THEN CASE
                    WHEN ABS(CAST(created_at AS REAL)) >= 1000000000000.0
                      THEN CAST(created_at AS REAL)/1000.0  -- epoch millis -> sec
                    ELSE CAST(created_at AS REAL)
                  END
           WHEN SUBSTR(CAST(created_at AS TEXT),5,1)='-'
             AND SUBSTR(CAST(created_at AS TEXT),8,1)='-'
             THEN CAST(STRFTIME('%s', REPLACE(SUBSTR(CAST(created_at AS TEXT),1,19),'T',' ')) AS REAL)
           ELSE NULL
         END AS sort_key
  FROM s
),
pick AS (
  SELECT reps, weight, duration_seconds, is_kg
  FROM s_sorted
  ORDER BY sort_key DESC, rowid DESC
  LIMIT 1
),
fallback AS (
  SELECT NULL AS reps, NULL AS weight, NULL AS duration_seconds, 1 AS is_kg
)
SELECT * FROM pick
UNION ALL
SELECT * FROM fallback
WHERE NOT EXISTS (SELECT 1 FROM pick);

''';
  return _readQuery(database, query, (d) => PreviosSetRow(d));
}

class PreviosSetRow extends SqliteRow {
  PreviosSetRow(Map<String, dynamic> data) : super(data);

  int? get reps => data['reps'] as int?;
  double? get weight => data['weight'] as double?;
  int? get durationSeconds => data['duration_seconds'] as int?;
  int get isKg => data['is_kg'] as int;
}

/// END PREVIOSSET

/// BEGIN WORKOUTSUMMARYBYID
Future<List<WorkoutSummaryByIdRow>> performWorkoutSummaryById(
  Database database, {
  String? workoutLogId,
}) {
  final query = '''
WITH
  sets AS (
    SELECT *
    FROM set_log
    WHERE workout_log_id = '${workoutLogId}'
  ),
  weighted_sets AS (
    SELECT *
    FROM sets
    WHERE weight IS NOT NULL AND reps IS NOT NULL
  ),
  time_sets AS (
    SELECT *
    FROM sets
    WHERE IFNULL(duration_seconds, 0) > 0
  ),
  bodyweight_sets AS (
    SELECT *
    FROM sets
    WHERE IFNULL(duration_seconds, 0) = 0
      AND reps IS NOT NULL
      AND weight IS NULL
  )
SELECT
  /* משך האימון מה-workout_log */
  (SELECT COALESCE(duration_seconds, 0)
   FROM workout_log
   WHERE id = '${workoutLogId}')                        AS duration_seconds,

  /* מספר תרגילים שבוצעו */
  (SELECT COUNT(DISTINCT exercise_id) FROM sets)        AS exercises_count,

  /* סה"כ נפח לפי הכלל */
  CASE
    WHEN (SELECT COUNT(*) FROM weighted_sets) > 0 THEN
      COALESCE((SELECT SUM(reps * weight) FROM weighted_sets), 0)
    ELSE
      CASE
        WHEN (SELECT COUNT(*) FROM time_sets) >= (SELECT COUNT(*) FROM bodyweight_sets) THEN
          COALESCE((SELECT SUM(IFNULL(duration_seconds, 0)) FROM time_sets), 0)
        ELSE
          COALESCE((SELECT SUM(reps) FROM bodyweight_sets), 0)
      END
  END                                                   AS total_volume;

''';
  return _readQuery(database, query, (d) => WorkoutSummaryByIdRow(d));
}

class WorkoutSummaryByIdRow extends SqliteRow {
  WorkoutSummaryByIdRow(Map<String, dynamic> data) : super(data);

  int get durationSeconds => data['duration_seconds'] as int;
  int get exercisesCount => data['exercises_count'] as int;
  double get totalVolume => data['total_volume'] as double;
}

/// END WORKOUTSUMMARYBYID

/// BEGIN WORKOUTLOGSUMMARYBYID
Future<List<WorkoutLogSummaryByIdRow>> performWorkoutLogSummaryById(
  Database database, {
  String? workoutLogId,
}) {
  final query = '''
WITH sets AS (
  SELECT
    sl.workout_log_id,
    sl.exercise_id,

    -- חזרות כמספר
    CAST(COALESCE(sl.reps, 0) AS REAL) AS reps,

    -- ניקוי weight מטקסט/יחידות + המרה למספר
    CAST(
      CASE
        WHEN sl.weight IS NULL THEN '0'
        -- אם יש רווח, קח עד הרווח הראשון (לכיסוי "32 Kg")
        WHEN INSTR(TRIM(sl.weight), ' ') > 0
          THEN SUBSTR(TRIM(sl.weight), 1, INSTR(TRIM(sl.weight), ' ') - 1)
        -- אם מסתיים ב-kg / KG / Kg / lbs – חתוך את הסיומת
        WHEN LOWER(TRIM(sl.weight)) LIKE '%kg'
          THEN SUBSTR(TRIM(sl.weight), 1, LENGTH(TRIM(TRIM(sl.weight))) - 2)
        WHEN LOWER(TRIM(sl.weight)) LIKE '%lbs'
          THEN SUBSTR(TRIM(sl.weight), 1, LENGTH(TRIM(TRIM(sl.weight))) - 3)
        ELSE TRIM(sl.weight)
      END
    AS REAL) AS weight,

    COALESCE(e.is_assisted, 0) AS is_assisted
  FROM set_log sl
  LEFT JOIN exercise e ON e.id = sl.exercise_id
  WHERE sl.workout_log_id = '${workoutLogId}'  -- בלי פילטר על is_dropset
),
agg AS (
  SELECT
    COUNT(DISTINCT exercise_id) AS exercises_count,

    -- נפח כולל (כולל Assisted וכולל Drop Sets)
    CAST(
      COALESCE(
        SUM(CASE WHEN reps > 0 AND weight > 0
                 THEN reps * weight END),
        0
      ) AS INTEGER
    ) AS total_volume_including_assist,

    -- נפח בלי Assisted (אבל עדיין כולל Drop Sets)
    CAST(
      COALESCE(
        SUM(CASE WHEN is_assisted = 0 AND reps > 0 AND weight > 0
                 THEN reps * weight END),
        0
      ) AS INTEGER
    ) AS total_volume
  FROM sets
)
SELECT
  COALESCE(w.duration_seconds, 0) AS duration_millis,  -- אצלך זה בפועל ms
  COALESCE(agg.exercises_count, 0) AS exercises_count,
  agg.total_volume,
  agg.total_volume_including_assist
FROM workout_log w
LEFT JOIN agg ON 1 = 1
WHERE w.id = :'${workoutLogId}'

''';
  return _readQuery(database, query, (d) => WorkoutLogSummaryByIdRow(d));
}

class WorkoutLogSummaryByIdRow extends SqliteRow {
  WorkoutLogSummaryByIdRow(Map<String, dynamic> data) : super(data);

  int get durationMillis => data['duration_millis'] as int;
  int get exercisesCount => data['exercises_count'] as int;
  int? get totalVolume => data['total_volume'] as int?;
}

/// END WORKOUTLOGSUMMARYBYID

/// BEGIN WORKOUTLOGEXERCISESINFOBYID
Future<List<WorkoutLogExercisesInfoByIdRow>> performWorkoutLogExercisesInfoById(
  Database database, {
  String? workoutLogId,
}) {
  final query = '''
WITH current_workout AS (
  SELECT wl.id AS workout_log_id, wl.workout_id, wl.created_at
  FROM workout_log wl
  WHERE wl.id = '${workoutLogId}'
),
prev_workout AS (
  SELECT wl.id AS workout_log_id
  FROM workout_log wl
  JOIN current_workout cw ON cw.workout_id = wl.workout_id
  WHERE wl.created_at < cw.created_at
  ORDER BY wl.created_at DESC
  LIMIT 1
),
curr_base AS (
  SELECT
    s.exercise_id,
    e.name AS exercise_name,
    e.is_time_based AS is_timed,
    e.is_bodyweight,
    COALESCE(e.is_assisted, 0) AS is_assisted,
    COALESCE(e.is_public, 1)   AS is_public,
    e.equipment                AS equipment,        -- NEW
    e.illustration             AS illustration,     -- NEW
    (SELECT mg.name                                  -- NEW
       FROM exercise_muscle_group emg
       JOIN muscle_group mg ON mg.id = emg.muscle_group_id
      WHERE emg.exercise_id = e.id AND COALESCE(emg.is_primary,1) = 1
      LIMIT 1) AS muscle_group,
    COALESCE(s.reps, 0) AS reps,
    COALESCE(s.weight, 0) AS weight,
    COALESCE(s.duration_seconds, 0) AS dur_ms,
    COALESCE(s.is_kg, 1) AS is_kg,
    COALESCE(s.is_dropset, 0) AS is_dropset
  FROM set_log s
  JOIN current_workout cw ON s.workout_log_id = cw.workout_log_id
  JOIN exercise e ON e.id = s.exercise_id
),
curr_agg AS (
  SELECT
    exercise_id,
    MAX(exercise_name) AS exercise_name,
    MAX(is_timed)      AS is_timed,
    MAX(is_bodyweight) AS is_bodyweight,
    MAX(is_assisted)   AS is_assisted,
    MAX(is_public)     AS is_public,
    MAX(equipment)     AS equipment,      -- NEW
    MAX(illustration)  AS illustration,   -- NEW
    MAX(muscle_group)  AS muscle_group,   -- NEW
    COUNT(CASE WHEN is_dropset = 0 THEN 1 END) AS exercise_sets_count,
    CASE WHEN SUM(CASE WHEN weight > 0 THEN 1 END) > 0 THEN 1 ELSE 0 END AS has_weighted_set,
    SUM(reps) AS sum_reps_all,
    SUM(CASE WHEN weight > 0 THEN reps * weight ELSE 0 END) AS sum_weighted_volume,
    SUM(dur_ms) AS sum_dur_ms,
    CASE
      WHEN SUM(CASE WHEN is_dropset = 0 AND is_kg = 1 THEN 1 ELSE 0 END)
         >= SUM(CASE WHEN is_dropset = 0 AND is_kg = 0 THEN 1 ELSE 0 END)
      THEN 'Kg' ELSE 'Lbs'
    END AS unit_label,
    AVG(CASE WHEN is_dropset = 0 AND weight > 0 THEN weight END) AS avg_assist
  FROM curr_base
  GROUP BY exercise_id
),
curr_vals AS (
  SELECT
    exercise_id, exercise_name, is_timed, is_bodyweight, is_assisted, is_public,
    equipment, illustration, muscle_group,   -- NEW
    exercise_sets_count, has_weighted_set, sum_reps_all, sum_weighted_volume,
    sum_dur_ms, unit_label, avg_assist,
    CASE
      WHEN is_timed = 1 THEN CAST(sum_dur_ms / 1000 AS INTEGER)
      WHEN is_assisted = 1 THEN sum_reps_all
      WHEN has_weighted_set = 0 THEN sum_reps_all
      ELSE CAST(sum_weighted_volume AS INTEGER)
    END AS curr_numeric,
    CAST(sum_weighted_volume AS REAL) AS curr_assist_volume
  FROM curr_agg
),
prev_base AS (
  SELECT
    s.exercise_id,
    e.is_time_based AS is_timed,
    e.is_bodyweight,
    COALESCE(e.is_assisted, 0) AS is_assisted,
    COALESCE(s.reps, 0) AS reps,
    COALESCE(s.weight, 0) AS weight,
    COALESCE(s.duration_seconds, 0) AS dur_ms,
    COALESCE(s.is_dropset, 0) AS is_dropset
  FROM set_log s
  JOIN prev_workout pw ON s.workout_log_id = pw.workout_log_id
  JOIN exercise e ON e.id = s.exercise_id
),
prev_agg AS (
  SELECT
    exercise_id,
    MAX(is_timed)      AS is_timed,
    MAX(is_bodyweight) AS is_bodyweight,
    MAX(is_assisted)   AS is_assisted,
    CASE WHEN SUM(CASE WHEN weight > 0 THEN 1 END) > 0 THEN 1 ELSE 0 END AS has_weighted_set_prev,
    SUM(reps) AS sum_reps_all_prev,
    SUM(CASE WHEN weight > 0 THEN reps * weight ELSE 0 END) AS sum_weighted_volume_prev,
    SUM(dur_ms) AS sum_dur_ms_prev
  FROM prev_base
  GROUP BY exercise_id
),
prev_vals AS (
  SELECT
    exercise_id,
    CASE
      WHEN is_timed = 1 THEN CAST(sum_dur_ms_prev / 1000 AS INTEGER)
      WHEN is_assisted = 1 THEN sum_reps_all_prev
      WHEN has_weighted_set_prev = 0 THEN sum_reps_all_prev
      ELSE CAST(sum_weighted_volume_prev AS INTEGER)
    END AS prev_numeric,
    CAST(sum_weighted_volume_prev AS REAL) AS prev_assist_volume
  FROM prev_agg
)
SELECT
  c.exercise_id,
  c.exercise_name,
  c.exercise_sets_count,
  c.is_public,
  c.equipment,      -- NEW
  c.illustration,   -- NEW
  c.muscle_group,   -- NEW
  CASE
    WHEN c.is_timed = 1 THEN
      printf('%02d:%02d',
             CAST(c.sum_dur_ms / 1000 AS INTEGER) / 60,
             CAST(c.sum_dur_ms / 1000 AS INTEGER) % 60)
    WHEN c.is_assisted = 1 THEN CAST(c.sum_reps_all AS TEXT) || ' Reps'
    WHEN c.has_weighted_set = 0 THEN CAST(c.sum_reps_all AS TEXT) || ' Reps'
    ELSE CAST(CAST(c.sum_weighted_volume AS INTEGER) AS TEXT) || ' ' || c.unit_label
  END AS exercise_total,
  CASE
    WHEN c.is_assisted = 1 THEN
      CASE
        WHEN p.prev_assist_volume IS NULL OR p.prev_assist_volume = 0 THEN NULL
        ELSE CAST(((p.prev_assist_volume - c.curr_assist_volume) * 100.0 / p.prev_assist_volume) AS INTEGER)
      END
    ELSE
      CASE
        WHEN p.prev_numeric IS NULL OR p.prev_numeric = 0 THEN NULL
        ELSE CAST(((c.curr_numeric - p.prev_numeric) * 100.0 / p.prev_numeric) AS INTEGER)
      END
  END AS exercise_percentage_change,
  c.is_timed,
  c.is_bodyweight,
  CASE
    WHEN c.is_timed = 0 AND c.is_assisted = 0 AND c.is_bodyweight = 0 THEN 1
    ELSE 0
  END AS is_weighted
FROM curr_vals c
LEFT JOIN prev_vals p ON p.exercise_id = c.exercise_id
ORDER BY c.exercise_id;
''';
  return _readQuery(database, query, (d) => WorkoutLogExercisesInfoByIdRow(d));
}

class WorkoutLogExercisesInfoByIdRow extends SqliteRow {
  WorkoutLogExercisesInfoByIdRow(Map<String, dynamic> data) : super(data);

  int get exerciseId => data['exercise_id'] as int;
  String get exerciseName => data['exercise_name'] as String;
  int get exerciseSetsCount => data['exercise_sets_count'] as int;
  String get exerciseTotal => data['exercise_total'] as String;
  int? get exercisePercentageChange =>
      data['exercise_percentage_change'] as int?;
  int get isTimed => data['is_timed'] as int;
  int get isBodyweight => data['is_bodyweight'] as int;
  int get isWeighted => data['is_weighted'] as int;
  int get isPublic => data['is_public'] as int;
  String get equipment => data['equipment'] as String;
  String? get illustration => data['illustration'] as String?;
  String get muscleGroup => data['muscle_group'] as String;
}

/// END WORKOUTLOGEXERCISESINFOBYID

/// BEGIN HISTORY
Future<List<HistoryRow>> performHistory(
  Database database, {
  String? userId,
}) {
  final query = '''
SELECT
  wl.id AS workout_log_id,
  COALESCE(w.id, 0) AS workout_id,
  COALESCE(w.name, 'Workout') AS workout_name,
  COALESCE(wl.created_at, '') AS created_at,
  COALESCE(CAST(wl.duration_seconds AS INTEGER), 0) AS duration_seconds,
  COALESCE(CAST(wl.volume AS INTEGER), 0) AS volume,
  (
    SELECT COALESCE(CAST(COUNT(*) AS INTEGER), 0)
    FROM set_log sl
    WHERE sl.workout_log_id = wl.id
      AND COALESCE(sl.is_dropset, 0) = 0
  ) AS total_sets,
  (
    SELECT COALESCE(CAST(COUNT(DISTINCT sl.exercise_id) AS INTEGER), 0)
    FROM set_log sl
    WHERE sl.workout_log_id = wl.id
      AND COALESCE(sl.is_dropset, 0) = 0
  ) AS exercise_count,
  COALESCE((
    SELECT GROUP_CONCAT(pmg_name, ', ')
    FROM (
      SELECT DISTINCT pmg.name AS pmg_name
      FROM set_log sl
      JOIN exercise_muscle_group emg
             ON emg.exercise_id = sl.exercise_id
            AND emg.is_primary = 1
      JOIN muscle_group mg
             ON mg.id = emg.muscle_group_id
      JOIN primary_muscle_group pmg
             ON pmg.id = mg.primary_muscle_group_id
      WHERE sl.workout_log_id = wl.id
        AND COALESCE(sl.is_dropset, 0) = 0
      ORDER BY pmg.name
    )
  ), '') AS main_muscle_groups,
  (
    SELECT COALESCE(CAST(COUNT(DISTINCT sa.set_log_id) AS INTEGER), 0)
    FROM set_analysis sa
    JOIN set_log sl ON sl.id = sa.set_log_id
    WHERE sl.workout_log_id = wl.id
  ) AS analyzed_sets
FROM workout_log wl
LEFT JOIN workout w ON w.id = wl.workout_id
WHERE wl.user_id = '${userId}'
ORDER BY wl.created_at DESC;
''';
  return _readQuery(database, query, (d) => HistoryRow(d));
}

class HistoryRow extends SqliteRow {
  HistoryRow(Map<String, dynamic> data) : super(data);

  String get workoutLogId => data['workout_log_id'] as String;
  String get workoutName => data['workout_name'] as String;
  String get createdAt => data['created_at'] as String;
  int get durationSeconds => data['duration_seconds'] as int;
  int get volume => data['volume'] as int;
  int get totalSets => data['total_sets'] as int;
  String get mainMuscleGroups => data['main_muscle_groups'] as String;
  int get exerciseCount => data['exercise_count'] as int;
  String get workoutId => data['workout_id'] as String;
  int get analyzedSets => data['analyzed_sets'] as int;
}

/// END HISTORY

/// BEGIN GETEXERCISEMUSCLELIST
Future<List<GetExerciseMuscleListRow>> performGetExerciseMuscleList(
  Database database, {
  int? exerciseId,
  int? isPrimary,
}) {
  final query = '''
SELECT
  mg.name       AS muscle_name,
  mg.image_url  AS image_url
FROM exercise_muscle_group AS emg
JOIN muscle_group AS mg
  ON mg.id = emg.muscle_group_id
WHERE emg.exercise_id = ${exerciseId}
  AND emg.is_primary = ${isPrimary};

''';
  return _readQuery(database, query, (d) => GetExerciseMuscleListRow(d));
}

class GetExerciseMuscleListRow extends SqliteRow {
  GetExerciseMuscleListRow(Map<String, dynamic> data) : super(data);

  String get muscleName => data['muscle_name'] as String;
  String get imageUrl => data['image_url'] as String;
}

/// END GETEXERCISEMUSCLELIST

/// BEGIN GETDROPSETS
Future<List<GetDropSetsRow>> performGetDropSets(
  Database database, {
  String? workoutLogId,
  int? exerciseId,
  int? setNumber,
}) {
  final query = '''
SELECT
  CAST(exercise_id AS INTEGER)                                        AS exercise_id,
  CAST(set_number  AS INTEGER)                                        AS set_number,
  CAST(COALESCE(NULLIF(CAST(drop_number AS TEXT), ''), 0) AS INTEGER) AS drop_number,
  CAST(COALESCE(NULLIF(CAST(reps        AS TEXT), ''), 0) AS INTEGER) AS reps,
  CAST(COALESCE(NULLIF(TRIM(CAST(weight  AS TEXT)), ''), 0) AS REAL)  AS weight,
  CAST(COALESCE(NULLIF(CAST(is_kg       AS TEXT), ''), 1) AS INTEGER) AS is_kg
FROM set_log
WHERE CAST(workout_log_id AS TEXT) = '${workoutLogId}'
  AND CAST(exercise_id    AS INTEGER) = ${exerciseId}
  AND CAST(set_number     AS INTEGER) = ${setNumber}
  AND CAST(COALESCE(NULLIF(CAST(is_dropset AS TEXT), ''), 0) AS INTEGER) = 1
ORDER BY drop_number

''';
  return _readQuery(database, query, (d) => GetDropSetsRow(d));
}

class GetDropSetsRow extends SqliteRow {
  GetDropSetsRow(Map<String, dynamic> data) : super(data);

  int get exerciseId => data['exercise_id'] as int;
  int get setNumber => data['set_number'] as int;
  int get dropNumber => data['drop_number'] as int;
  int get reps => data['reps'] as int;
  double? get weight => data['weight'] as double?;
  int get isKg => data['is_kg'] as int;
}

/// END GETDROPSETS

/// BEGIN GETPRIMARYMUSCLEGROUP
Future<List<GetprimaryMuscleGroupRow>> performGetprimaryMuscleGroup(
  Database database,
) {
  final query = '''
SELECT * 
FROM primary_muscle__group;

''';
  return _readQuery(database, query, (d) => GetprimaryMuscleGroupRow(d));
}

class GetprimaryMuscleGroupRow extends SqliteRow {
  GetprimaryMuscleGroupRow(Map<String, dynamic> data) : super(data);

  int get id => data['id'] as int;
  String get name => data['name'] as String;
  String get ilustration => data['ilustration'] as String;
}

/// END GETPRIMARYMUSCLEGROUP

/// BEGIN LAST7DAYSSTATS
Future<List<Last7DaysStatsRow>> performLast7DaysStats(
  Database database, {
  String? userId,
}) {
  final query = '''
WITH recent_wl AS (
    SELECT DISTINCT sl.workout_log_id AS id
    FROM set_log sl
    WHERE sl.user_id = '${userId}'
      AND datetime(sl.created_at) >= datetime('now','localtime','-6 days','weekday 0','start of day')
),
sets AS (
    SELECT sl.*
    FROM set_log sl
    JOIN recent_wl r
      ON r.id = sl.workout_log_id
    WHERE sl.user_id = '${userId}'
)
SELECT
    -- מספר אימונים
    COALESCE(
        (SELECT COUNT(*) FROM recent_wl),
        0
    ) AS workout_count,

    -- מספר סטים (כולל bodyweight / timed)
    COALESCE((
        SELECT COUNT(*)
        FROM sets
        WHERE COALESCE(is_dropset, 0) = 0
    ), 0) AS total_sets,

    -- ווליום (רק weighted)
    COALESCE((
        SELECT SUM(CAST(sl.reps AS REAL) * CAST(sl.weight AS REAL))
        FROM sets sl
        JOIN exercise e
          ON e.id = sl.exercise_id
        WHERE sl.reps IS NOT NULL
          AND sl.weight IS NOT NULL
          AND COALESCE(sl.is_dropset, 0) = 0
          AND COALESCE(e.is_assisted, 0) = 0
    ), 0.0) AS total_volume;
''';
  return _readQuery(database, query, (d) => Last7DaysStatsRow(d));
}

class Last7DaysStatsRow extends SqliteRow {
  Last7DaysStatsRow(Map<String, dynamic> data) : super(data);

  int get totalSets => data['total_sets'] as int;
  int get workoutCount => data['workout_count'] as int;
  double get totalVolume => data['total_volume'] as double;
}

/// END LAST7DAYSSTATS

/// BEGIN  LATESTWORKOUTHOME
Future<List<LatestWorkoutHomeRow>> performLatestWorkoutHome(
  Database database, {
  String? userId,
}) {
  final query = '''
WITH last_wl AS (
    SELECT wl.id, wl.created_at
    FROM workout_log wl
    WHERE wl.user_id = '${userId}'
    -- אם זה סינגל-יוזר, אפשר להסיר
    ORDER BY wl.created_at DESC
    LIMIT 1
)
SELECT
    lw.id AS workout_log_id,
    lw.created_at AS created_at,
    (
        SELECT COUNT(*)
        FROM set_log s
        WHERE s.workout_log_id = lw.id
          AND COALESCE(s.is_dropset, 0) = 0
    ) AS total_sets,
    (
        SELECT group_concat(pmg_name, ', ')
        FROM (
            SELECT DISTINCT pmg.name AS pmg_name
            FROM set_log sl
            JOIN exercise_muscle_group emg
              ON emg.exercise_id = sl.exercise_id
             AND COALESCE(emg.is_primary, 1) = 1
            JOIN muscle_group mg
              ON mg.id = emg.muscle_group_id
            JOIN primary_muscle_group pmg
              ON pmg.id = mg.primary_muscle_group_id
            WHERE sl.workout_log_id = lw.id
              AND COALESCE(sl.is_dropset, 0) = 0
            ORDER BY pmg_name
        ) x
    ) AS main_muscle_groups
FROM last_wl lw;

''';
  return _readQuery(database, query, (d) => LatestWorkoutHomeRow(d));
}

class LatestWorkoutHomeRow extends SqliteRow {
  LatestWorkoutHomeRow(Map<String, dynamic> data) : super(data);

  int get totalSets => data['total_sets'] as int;
  String get createdAt => data['created_at'] as String;
  String get workoutLogId => data['workout_log_id'] as String;
  String? get mainMuscleGroups => data['main_muscle_groups'] as String?;
}

/// END  LATESTWORKOUTHOME

/// BEGIN HISTORYWORKOUTLISTEX
Future<List<HistoryWorkoutListEXRow>> performHistoryWorkoutListEX(
  Database database, {
  String? workoutLogId,
}) {
  final query = '''
-- params: :workout_log_id
SELECT
  sl.exercise_id,
  e.name AS exercise_name
FROM set_log sl
JOIN exercise_list e ON e.id = sl.exercise_id
WHERE sl.workout_log_id = :'${workoutLogId}'
GROUP BY sl.exercise_id;


''';
  return _readQuery(database, query, (d) => HistoryWorkoutListEXRow(d));
}

class HistoryWorkoutListEXRow extends SqliteRow {
  HistoryWorkoutListEXRow(Map<String, dynamic> data) : super(data);

  String get exerciseName => data['exercise_name'] as String;
  int get exerciseId => data['exercise_id'] as int;
}

/// END HISTORYWORKOUTLISTEX

/// BEGIN MUSCLEGROUPSAMMARY
Future<List<MuscleGroupSammaryRow>> performMuscleGroupSammary(
  Database database, {
  String? workoutLogId,
}) {
  final query = '''
WITH base AS (
  SELECT
    sl.workout_log_id,
    sl.exercise_id
  FROM set_log sl
  WHERE COALESCE(sl.is_dropset, 0) = 0
    AND sl.workout_log_id = '${workoutLogId}'
),
per_muscle AS (
  SELECT
    b.workout_log_id,
    mg.name AS muscle_group_name,
    COUNT(*) AS sets_for_muscle
  FROM base b
  JOIN exercise_muscle_group emg ON emg.exercise_id = b.exercise_id
  JOIN muscle_group mg           ON mg.id = emg.muscle_group_id
  WHERE COALESCE(emg.is_primary, 1) = 1
  GROUP BY b.workout_log_id, mg.id, mg.name
),
totals AS (
  SELECT
    b.workout_log_id,
    COUNT(*) AS total_sets_in_workout
  FROM base b
  JOIN exercise_muscle_group emg ON emg.exercise_id = b.exercise_id
  WHERE COALESCE(emg.is_primary, 1) = 1
  GROUP BY b.workout_log_id
)
SELECT
  p.muscle_group_name,
  p.sets_for_muscle,
  t.total_sets_in_workout
FROM per_muscle p
JOIN totals t USING (workout_log_id)
ORDER BY p.muscle_group_name ASC;

''';
  return _readQuery(database, query, (d) => MuscleGroupSammaryRow(d));
}

class MuscleGroupSammaryRow extends SqliteRow {
  MuscleGroupSammaryRow(Map<String, dynamic> data) : super(data);

  String get muscleGroupName => data['muscle_group_name'] as String;
  int get setsForMuscle => data['sets_for_muscle'] as int;
  int get totalSetsInWorkout => data['total_sets_in_workout'] as int;
}

/// END MUSCLEGROUPSAMMARY

/// BEGIN PIEGRAPH
Future<List<PieGraphRow>> performPieGraph(
  Database database, {
  String? userId,
  String? timeRange,
}) {
  final query = '''
WITH bounds AS (
  SELECT
    CASE '${timeRange}'
      WHEN 'Last 7 days'  THEN datetime('now','localtime','-7 days')
      WHEN 'Last 30 days' THEN datetime('now','localtime','-30 days')
      WHEN 'Last 90 days' THEN datetime('now','localtime','-90 days')
      ELSE datetime('1970-01-01')
    END AS from_ts,
    CASE '${timeRange}'
      WHEN 'All' THEN datetime('9999-12-31')
      ELSE datetime('now','localtime')
    END AS to_ts
),
base AS (
  SELECT sl.exercise_id
  FROM set_log sl
  JOIN workout_log wl ON wl.id = sl.workout_log_id
  JOIN bounds b
  WHERE wl.user_id = '${userId}'
    AND COALESCE(sl.is_dropset, 0) = 0
    AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
    AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
),
per_primary AS (
  SELECT
    COALESCE(pmg.name, mg.name, 'Other') AS primary_name,
    COUNT(*) AS sets_for_primary
  FROM base b
  JOIN exercise_muscle_group emg ON emg.exercise_id = b.exercise_id
  JOIN muscle_group mg           ON mg.id = emg.muscle_group_id
  LEFT JOIN primary_muscle_group pmg ON pmg.id = mg.primary_muscle_group_id
  WHERE COALESCE(emg.is_primary, 1) = 1
  GROUP BY COALESCE(pmg.id, mg.id)
),
totals AS (
  SELECT COALESCE(SUM(sets_for_primary), 0) AS total_sets
  FROM per_primary
)
SELECT
  p.primary_name      AS label,
  p.sets_for_primary  AS value,
  CASE WHEN t.total_sets > 0
       THEN CAST(ROUND(100.0 * p.sets_for_primary / t.total_sets, 0) AS INTEGER)
       ELSE 0 END AS pct,
  t.total_sets        AS total_sets
FROM per_primary p
CROSS JOIN totals t
ORDER BY value DESC;

''';
  return _readQuery(database, query, (d) => PieGraphRow(d));
}

class PieGraphRow extends SqliteRow {
  PieGraphRow(Map<String, dynamic> data) : super(data);

  String get label => data['label'] as String;
  int get value => data['value'] as int;
  int get pct => data['pct'] as int;
  int get totalSets => data['total_sets'] as int;
}

/// END PIEGRAPH

/// BEGIN WORKOUTCOUNT
Future<List<WorkoutCountRow>> performWorkoutCount(
  Database database, {
  String? userId,
  String? timeRange,
}) {
  final query = '''
WITH bounds AS (
  SELECT
    CASE '${timeRange}'
      WHEN 'Last 7 days'  THEN datetime('now','localtime','-7 days')
      WHEN 'Last 30 days' THEN datetime('now','localtime','-30 days')
      WHEN 'Last 90 days' THEN datetime('now','localtime','-90 days')
      ELSE datetime('1970-01-01')
    END AS from_ts,

    CASE '${timeRange}'
      WHEN 'All' THEN datetime('9999-12-31')
      ELSE datetime('now','localtime')
    END AS to_ts
)
SELECT
  CAST(wl.id AS TEXT)                                 AS id,
  wl.created_at                                       AS created_at,
  CAST(COALESCE(NULLIF(wl.volume, ''), 0) AS INTEGER) AS volume
FROM workout_log wl
JOIN bounds b
WHERE wl.user_id = '${userId}'
  AND wl.created_at IS NOT NULL
  AND wl.created_at <> ''

  -- convert to ISO
  AND datetime(replace(wl.created_at, ' ', 'T')) >= b.from_ts
  AND datetime(replace(wl.created_at, ' ', 'T')) <  b.to_ts

ORDER BY datetime(replace(wl.created_at,' ','T')) DESC;

''';
  return _readQuery(database, query, (d) => WorkoutCountRow(d));
}

class WorkoutCountRow extends SqliteRow {
  WorkoutCountRow(Map<String, dynamic> data) : super(data);

  String get createdAt => data['created_at'] as String;
  String get id => data['id'] as String;
  int get volume => data['volume'] as int;
}

/// END WORKOUTCOUNT

/// BEGIN TOPMUSCLE
Future<List<TopMuscleRow>> performTopMuscle(
  Database database, {
  String? timeRange,
  String? userId,
}) {
  final query = '''
WITH bounds AS (
  SELECT
    CASE '${timeRange}'
      WHEN 'Last 7 days'  THEN datetime('now','localtime','-7 days')
      WHEN 'Last 30 days' THEN datetime('now','localtime','-30 days')
      WHEN 'Last 90 days' THEN datetime('now','localtime','-90 days')
      ELSE datetime('1970-01-01')
    END AS from_ts,
    CASE '${timeRange}'
      WHEN 'All' THEN datetime('9999-12-31')
      ELSE datetime('now','localtime')
    END AS to_ts
),

-- כל הסטים הרלוונטיים בטווח זמן
base AS (
  SELECT sl.exercise_id
  FROM set_log sl
  JOIN workout_log wl ON wl.id = sl.workout_log_id
  JOIN bounds b
  WHERE wl.user_id = '${userId}'
    AND COALESCE(sl.is_dropset, 0) = 0
    AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
    AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
),

-- ממפה כל סט ל־PRIMARY MUSCLE GROUP שלו
per_primary AS (
  SELECT
    COALESCE(pmg.name, mg.name, 'Other') AS primary_name,
    COUNT(*) AS sets_for_primary
  FROM base b
  JOIN exercise_muscle_group emg ON emg.exercise_id = b.exercise_id
  JOIN muscle_group mg           ON mg.id = emg.muscle_group_id
  LEFT JOIN primary_muscle_group pmg ON pmg.id = mg.primary_muscle_group_id
  WHERE COALESCE(emg.is_primary, 1) = 1
  GROUP BY COALESCE(pmg.id, mg.id)
),

-- סך כל הסטים
totals AS (
  SELECT COALESCE(SUM(sets_for_primary), 0) AS total_sets
  FROM per_primary
),

-- בחירת ה־TOP 1
top_primary AS (
  SELECT
    p.primary_name,
    p.sets_for_primary
  FROM per_primary p
  ORDER BY p.sets_for_primary DESC, p.primary_name ASC
  LIMIT 1
)

SELECT
  CASE WHEN t.total_sets > 0 THEN tp.primary_name ELSE '-' END AS muscle_group_name,
  CASE WHEN t.total_sets > 0 THEN tp.sets_for_primary ELSE 0 END AS sets_for_primary,
  t.total_sets AS total_sets
FROM totals t
LEFT JOIN top_primary tp ON 1=1;

''';
  return _readQuery(database, query, (d) => TopMuscleRow(d));
}

class TopMuscleRow extends SqliteRow {
  TopMuscleRow(Map<String, dynamic> data) : super(data);

  String get muscleGroupName => data['muscle_group_name'] as String;
}

/// END TOPMUSCLE

/// BEGIN EXERCISESESSIONCOMPARISOM
Future<List<ExerciseSessionComparisomRow>> performExerciseSessionComparisom(
  Database database, {
  String? userId,
  int? exerciseId,
  int? isPremium,
}) {
  final query = '''
WITH limits AS (
  SELECT
    CASE
      WHEN ${isPremium} = 1 THEN datetime('1970-01-01')
      ELSE datetime('now','localtime','-30 days')
    END AS from_ts
),

base AS (
  SELECT
    sl.exercise_id,
    sl.workout_log_id,
    wl.user_id,
    wl.created_at,

    COUNT(*)                                   AS total_sets,
    SUM(COALESCE(sl.reps, 0))                  AS total_reps,
    MAX(COALESCE(sl.is_kg, 1))                 AS is_kg,

    SUM(CASE WHEN COALESCE(sl.duration_seconds, 0) > 0 THEN 1 ELSE 0 END) AS timed_sets,
    SUM(CASE WHEN sl.weight IS NULL OR sl.weight = 0 THEN 1 ELSE 0 END) AS bw_sets,

    COALESCE(e.is_assisted, 0)                 AS is_assisted,

    CASE
      WHEN COALESCE(e.is_assisted,0) = 1
        THEN 1.0 * SUM(COALESCE(sl.reps, 0))

      WHEN SUM(CASE WHEN COALESCE(sl.duration_seconds, 0) > 0 THEN 1 ELSE 0 END) = COUNT(*)
        THEN 1.0 * SUM(COALESCE(sl.duration_seconds, 0))

      WHEN SUM(CASE WHEN sl.weight IS NULL OR sl.weight = 0 THEN 1 ELSE 0 END) = COUNT(*)
        THEN 1.0 * SUM(COALESCE(sl.reps, 0))

      ELSE
        SUM(1.0 * COALESCE(sl.reps, 0) * COALESCE(sl.weight, 0))
    END AS total_volume,

    CASE
      WHEN COALESCE(e.is_assisted,0) = 1 THEN NULL
      WHEN SUM(CASE WHEN sl.weight IS NULL OR sl.weight = 0 THEN 1 ELSE 0 END) = COUNT(*) THEN NULL
      ELSE ROUND(
        (SUM(1.0 * COALESCE(sl.weight,0) * COALESCE(sl.reps,0)))
        / NULLIF(SUM(COALESCE(sl.reps,0)), 0),
        2
      )
    END AS avg_weight_per_rep,

    CASE
      WHEN COALESCE(e.is_assisted,0) = 1 THEN 1
      WHEN SUM(CASE WHEN sl.weight IS NULL OR sl.weight = 0 THEN 1 ELSE 0 END) = COUNT(*) THEN 1
      ELSE 0
    END AS is_bodyweight_only,

    CASE
      WHEN SUM(CASE WHEN COALESCE(sl.duration_seconds, 0) > 0 THEN 1 ELSE 0 END) = COUNT(*) THEN 1
      ELSE 0
    END AS is_time_based

  FROM set_log sl
  JOIN workout_log wl ON wl.id = sl.workout_log_id
  JOIN exercise e     ON e.id = sl.exercise_id
  JOIN limits l

  WHERE wl.user_id = '${userId}'
    AND sl.exercise_id = ${exerciseId}
    AND datetime(replace(wl.created_at,' ','T')) >= l.from_ts

  GROUP BY
    sl.exercise_id,
    sl.workout_log_id,
    wl.user_id,
    wl.created_at
),

ordered AS (
  SELECT
    b.*,
    ROW_NUMBER() OVER (
      PARTITION BY user_id, exercise_id
      ORDER BY created_at DESC
    ) AS session_rank
  FROM base b
),

joined AS (
  SELECT
    curr.*,

    COALESCE(prev.total_sets, 0)         AS prev_sets,
    COALESCE(prev.total_reps, 0)         AS prev_reps,
    COALESCE(prev.total_volume, 0)       AS prev_volume,
    COALESCE(prev.avg_weight_per_rep, 0) AS prev_avg_weight,
    prev.is_bodyweight_only              AS prev_is_bodyweight_only,

    CASE
      WHEN curr.total_sets > 0
        THEN (1.0 * curr.total_volume) / curr.total_sets
      ELSE NULL
    END AS avg_duration_per_set,

    CASE
      WHEN prev.total_sets > 0
        THEN (1.0 * prev.total_volume) / prev.total_sets
      ELSE NULL
    END AS prev_avg_duration_per_set,

    CASE
      WHEN curr.total_sets > 0 AND prev.total_sets > 0 THEN
        ROUND(
          (
            ((1.0*curr.total_volume)/curr.total_sets -
             (1.0*prev.total_volume)/prev.total_sets) * 100.0
          )
          / NULLIF((1.0*prev.total_volume)/prev.total_sets, 0),
          1
        )
      ELSE NULL
    END AS avg_duration_diff_percent,

    CASE
      WHEN curr.total_sets > 0 AND prev.total_sets > 0 THEN
        ROUND(
          (1.0*curr.total_volume)/curr.total_sets -
          (1.0*prev.total_volume)/prev.total_sets,
          2
        )
      ELSE NULL
    END AS avg_duration_diff_abs,

    CASE
      WHEN prev.is_bodyweight_only IS NULL THEN 0
      WHEN curr.is_bodyweight_only <> prev.is_bodyweight_only THEN 1
      ELSE 0
    END AS is_hybrid_volume_comparison,

    ROUND(
      100.0 * (curr.total_sets - COALESCE(prev.total_sets,0))
      / NULLIF(prev.total_sets, 0),
      1
    ) AS sets_diff_percent,

    ROUND(
      100.0 * (curr.total_reps - COALESCE(prev.total_reps,0))
      / NULLIF(prev.total_reps, 0),
      1
    ) AS reps_diff_percent,

    CASE
      WHEN curr.is_bodyweight_only = prev.is_bodyweight_only THEN
        ROUND(
          100.0 * (curr.total_volume - COALESCE(prev.total_volume,0))
          / NULLIF(prev.total_volume, 0),
          1
        )
      ELSE NULL
    END AS volume_diff_percent,

    (curr.total_sets - COALESCE(prev.total_sets,0)) AS sets_diff_abs,
    (curr.total_reps - COALESCE(prev.total_reps,0)) AS reps_diff_abs,

    CASE
      WHEN curr.is_bodyweight_only = prev.is_bodyweight_only
        THEN (curr.total_volume - COALESCE(prev.total_volume,0))
      ELSE NULL
    END AS volume_diff_abs,

    ROUND(
      100.0 * (curr.avg_weight_per_rep - COALESCE(prev.avg_weight_per_rep,0))
      / NULLIF(prev.avg_weight_per_rep, 0),
      1
    ) AS avg_weight_diff_percent,

    (curr.avg_weight_per_rep - COALESCE(prev.avg_weight_per_rep,0))
      AS avg_weight_diff_abs

  FROM ordered curr
  LEFT JOIN ordered prev
    ON  curr.user_id      = prev.user_id
    AND curr.exercise_id  = prev.exercise_id
    AND curr.session_rank = prev.session_rank - 1
)

SELECT
  j.exercise_id,
  j.workout_log_id,
  j.user_id,
  j.created_at,
  j.total_sets,
  j.total_reps,
  j.total_volume,
  j.avg_weight_per_rep,
  j.avg_duration_per_set,
  j.is_bodyweight_only,
  j.is_hybrid_volume_comparison,
  j.is_kg,
  j.sets_diff_percent,
  j.reps_diff_percent,
  j.volume_diff_percent,
  j.avg_weight_diff_percent,
  j.avg_duration_diff_percent,
  j.sets_diff_abs,
  j.reps_diff_abs,
  j.volume_diff_abs,
  j.avg_weight_diff_abs,
  j.avg_duration_diff_abs,
  j.is_time_based,

  -- ===== Display fields: rounded to 1 decimal, no trailing .0 =====
  CASE WHEN j.total_volume IS NULL THEN NULL
    ELSE RTRIM(RTRIM(printf('%.1f', j.total_volume), '0'), '.') END
    AS total_volume_display,

  CASE WHEN j.avg_weight_per_rep IS NULL THEN NULL
    ELSE RTRIM(RTRIM(printf('%.1f', j.avg_weight_per_rep), '0'), '.') END
    AS avg_weight_per_rep_display,

  CASE WHEN j.avg_duration_per_set IS NULL THEN NULL
    ELSE RTRIM(RTRIM(printf('%.1f', j.avg_duration_per_set), '0'), '.') END
    AS avg_duration_per_set_display,

  CASE WHEN j.sets_diff_percent IS NULL THEN NULL
    ELSE RTRIM(RTRIM(printf('%.1f', j.sets_diff_percent), '0'), '.') END
    AS sets_diff_percent_display,

  CASE WHEN j.reps_diff_percent IS NULL THEN NULL
    ELSE RTRIM(RTRIM(printf('%.1f', j.reps_diff_percent), '0'), '.') END
    AS reps_diff_percent_display,

  CASE WHEN j.volume_diff_percent IS NULL THEN NULL
    ELSE RTRIM(RTRIM(printf('%.1f', j.volume_diff_percent), '0'), '.') END
    AS volume_diff_percent_display,

  CASE WHEN j.avg_weight_diff_percent IS NULL THEN NULL
    ELSE RTRIM(RTRIM(printf('%.1f', j.avg_weight_diff_percent), '0'), '.') END
    AS avg_weight_diff_percent_display,

  CASE WHEN j.avg_duration_diff_percent IS NULL THEN NULL
    ELSE RTRIM(RTRIM(printf('%.1f', j.avg_duration_diff_percent), '0'), '.') END
    AS avg_duration_diff_percent_display,

  CASE WHEN j.sets_diff_abs IS NULL THEN NULL
    ELSE RTRIM(RTRIM(printf('%.1f', 1.0 * j.sets_diff_abs), '0'), '.') END
    AS sets_diff_abs_display,

  CASE WHEN j.reps_diff_abs IS NULL THEN NULL
    ELSE RTRIM(RTRIM(printf('%.1f', 1.0 * j.reps_diff_abs), '0'), '.') END
    AS reps_diff_abs_display,

  -- Time-based: volume is total ms -> show diff as [-]mm:ss (rounded to whole seconds)
  CASE WHEN j.volume_diff_abs IS NULL THEN NULL
    WHEN j.is_time_based = 1 THEN
      (CASE WHEN j.volume_diff_abs < 0 THEN '-' ELSE '' END) ||
      printf('%02d:%02d',
        CAST(ROUND(ABS(j.volume_diff_abs) / 1000.0) AS INTEGER) / 60,
        CAST(ROUND(ABS(j.volume_diff_abs) / 1000.0) AS INTEGER) % 60)
    ELSE RTRIM(RTRIM(printf('%.1f', j.volume_diff_abs), '0'), '.') END
    AS volume_diff_abs_display,

  CASE WHEN j.avg_weight_diff_abs IS NULL THEN NULL
    ELSE RTRIM(RTRIM(printf('%.1f', j.avg_weight_diff_abs), '0'), '.') END
    AS avg_weight_diff_abs_display,

  CASE WHEN j.avg_duration_diff_abs IS NULL THEN NULL
    ELSE RTRIM(RTRIM(printf('%.1f', j.avg_duration_diff_abs), '0'), '.') END
    AS avg_duration_diff_abs_display

FROM joined j
ORDER BY j.created_at DESC;
''';
  return _readQuery(database, query, (d) => ExerciseSessionComparisomRow(d));
}

class ExerciseSessionComparisomRow extends SqliteRow {
  ExerciseSessionComparisomRow(Map<String, dynamic> data) : super(data);

  int get exerciseId => data['exercise_id'] as int;
  String get workoutLogId => data['workout_log_id'] as String;
  String get createdAt => data['created_at'] as String;
  int get totalSets => data['total_sets'] as int;
  int? get totalReps => data['total_reps'] as int?;
  double get totalVolume => data['total_volume'] as double;
  double? get avgWeightPerRep => data['avg_weight_per_rep'] as double?;
  double? get avgDurationPerSet => data['avg_duration_per_set'] as double?;
  int get isBodyweightOnly => data['is_bodyweight_only'] as int;
  int get isHybridVolumeComparison =>
      data['is_hybrid_volume_comparison'] as int;
  double? get setsDiffPercent => data['sets_diff_percent'] as double?;
  double? get repsDiffPercent => data['reps_diff_percent'] as double?;
  double? get volumeDiffPercent => data['volume_diff_percent'] as double?;
  double? get avgWeightDiffPercent =>
      data['avg_weight_diff_percent'] as double?;
  double? get avgDurationDiffPercent =>
      data['avg_duration_diff_percent'] as double?;
  int? get setsDiffAbs => data['sets_diff_abs'] as int?;
  int? get repsDiffAbs => data['reps_diff_abs'] as int?;
  double? get volumeDiffAbs => data['volume_diff_abs'] as double?;
  double? get avgWeightDiffAbs => data['avg_weight_diff_abs'] as double?;
  double? get avgDurationDiffAbs => data['avg_duration_diff_abs'] as double?;
  int get isTimeBased => data['is_time_based'] as int;
  String? get totalVolumeDisplay => data['total_volume_display'] as String?;
  String? get avgWeightPerRepDisplay =>
      data['avg_weight_per_rep_display'] as String?;
  String? get avgDurationPerSetDisplay =>
      data['avg_duration_per_set_display'] as String?;
  String? get setsDiffPercentDisplay =>
      data['sets_diff_percent_display'] as String?;
  String? get repsDiffPercentDisplay =>
      data['reps_diff_percent_display'] as String?;
  String? get volumeDiffPercentDisplay =>
      data['volume_diff_percent_display'] as String?;
  String? get avgWeightDiffPercentDisplay =>
      data['avg_weight_diff_percent_display'] as String?;
  String? get avgDurationDiffPercentDisplay =>
      data['avg_duration_diff_percent_display'] as String?;
  String? get setsDiffAbsDisplay => data['sets_diff_abs_display'] as String?;
  String? get repsDiffAbsDisplay => data['reps_diff_abs_display'] as String?;
  String? get volumeDiffAbsDisplay =>
      data['volume_diff_abs_display'] as String?;
  String? get avgWeightDiffAbsDisplay =>
      data['avg_weight_diff_abs_display'] as String?;
  String? get avgDiffDurationAbsDisplay =>
      data['avg_diff_duration_abs_display'] as String?;
  int get isKg => data['is_kg'] as int;
}

/// END EXERCISESESSIONCOMPARISOM

/// BEGIN EXERCISEPRS
Future<List<ExercisePrsRow>> performExercisePrs(
  Database database, {
  int? exerciseId,
  String? userId,
  String? timeRange,
}) {
  final query = '''
WITH bounds AS (
  SELECT
    CASE '${timeRange}'
      WHEN 'Last 7 days'  THEN datetime('now','localtime','-7 days')
      WHEN 'Last 30 days' THEN datetime('now','localtime','-30 days')
      WHEN 'Last 90 days' THEN datetime('now','localtime','-90 days')
      ELSE datetime('1970-01-01')
    END AS from_ts,
    CASE '${timeRange}'
      WHEN 'All' THEN datetime('9999-12-31')
      ELSE datetime('now','localtime')
    END AS to_ts
),

ex AS (
  -- האם התרגיל time-based
  SELECT IFNULL((
    SELECT COALESCE(is_time_based, 0)
    FROM exercise
    WHERE id = ${exerciseId}
    LIMIT 1
  ), 0) AS is_time_based
),

majority AS (
  -- האם רוב הסטים הם bodyweight
  SELECT
    CASE
      WHEN COUNT(*) = 0 THEN 0
      WHEN 1.0 * SUM(CASE WHEN IFNULL(sl.weight,0) > 0 THEN 1 ELSE 0 END) / COUNT(*) >= 0.5
        THEN 0
      ELSE 1
    END AS is_bodyweight
  FROM set_log sl
  JOIN workout_log wl ON wl.id = sl.workout_log_id
  JOIN bounds b
  WHERE sl.exercise_id = ${exerciseId}
    AND wl.user_id = '${userId}'
    AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
    AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
),

sessions AS (
  -- נפח פר סשן (מסונן זמן + משתמש)
  SELECT
    sl.workout_log_id,
    SUM(
      CASE
        WHEN (SELECT is_time_based FROM ex) = 1
          THEN IFNULL(sl.duration_seconds, 0)
        WHEN (SELECT is_bodyweight FROM majority) = 1
          THEN IFNULL(sl.reps, 0)
        ELSE CAST(IFNULL(sl.reps, 0) AS REAL)
           * CAST(IFNULL(sl.weight, 0) AS REAL)
      END
    ) AS session_volume
  FROM set_log sl
  JOIN workout_log wl ON wl.id = sl.workout_log_id
  JOIN bounds b
  WHERE sl.exercise_id = ${exerciseId}
    AND wl.user_id = '${userId}'
    AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
    AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
  GROUP BY sl.workout_log_id
)

SELECT
  -- מקס חזרות
  CAST(IFNULL((
    SELECT MAX(IFNULL(sl.reps,0))
    FROM set_log sl
    JOIN workout_log wl ON wl.id = sl.workout_log_id
    JOIN bounds b
    WHERE sl.exercise_id = ${exerciseId}
      AND wl.user_id = '${userId}'
      AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
      AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
  ), 0) AS INTEGER) AS max_reps,

  -- מקס משקל
  CAST(IFNULL((
    SELECT ROUND(MAX(NULLIF(CAST(sl.weight AS REAL), 0)), 0)
    FROM set_log sl
    JOIN workout_log wl ON wl.id = sl.workout_log_id
    JOIN bounds b
    WHERE sl.exercise_id = ${exerciseId}
      AND wl.user_id = '${userId}'
      AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
      AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
  ), 0) AS INTEGER) AS max_weight,

  -- מקס ווליום לסשן
  CAST(IFNULL((
    SELECT ROUND(MAX(session_volume), 0)
    FROM sessions
  ), 0) AS INTEGER) AS max_volume;

''';
  return _readQuery(database, query, (d) => ExercisePrsRow(d));
}

class ExercisePrsRow extends SqliteRow {
  ExercisePrsRow(Map<String, dynamic> data) : super(data);

  int? get maxVolume => data['max_volume'] as int?;
  int? get maxWeight => data['max_weight'] as int?;
  int? get maxReps => data['max_reps'] as int?;
}

/// END EXERCISEPRS

/// BEGIN RM1
Future<List<Rm1Row>> performRm1(
  Database database, {
  int? exerciseId,
  String? userId,
  String? timeRange,
}) {
  final query = '''
-- Params:
-- ${exerciseId}  (INTEGER)
-- "${userId}"    (TEXT)
-- "${timeRange}" (TEXT)

WITH bounds AS (
  SELECT
    CASE '${timeRange}'
      WHEN 'Last 7 days'  THEN datetime('now','localtime','-7 days')
      WHEN 'Last 30 days' THEN datetime('now','localtime','-30 days')
      WHEN 'Last 90 days' THEN datetime('now','localtime','-90 days')
      ELSE datetime('1970-01-01')
    END AS from_ts,
    CASE '${timeRange}'
      WHEN 'All' THEN datetime('9999-12-31')
      ELSE datetime('now','localtime')
    END AS to_ts
),

filtered AS (
  SELECT
    sl.weight,
    sl.reps,
    wl.created_at
  FROM set_log sl
  JOIN workout_log wl ON wl.id = sl.workout_log_id
  JOIN exercise e     ON e.id  = sl.exercise_id
  JOIN bounds b
  WHERE sl.exercise_id = ${exerciseId}
    AND wl.user_id     = '${userId}'
    AND COALESCE(e.is_time_based, 0) = 0
    AND COALESCE(sl.weight, 0) > 0
    AND COALESCE(sl.reps,   0) > 0
    AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
    AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
),

picked AS (
  SELECT
    weight,
    reps
  FROM filtered
  ORDER BY weight DESC, reps DESC, created_at DESC
  LIMIT 1
)

SELECT
  CAST(
    IFNULL(
      ROUND( (weight * (1.0 + reps / 30.0)) * 2.0 ) / 2.0,
      0.0
    ) AS REAL
  ) AS estimated_1rm
FROM picked;

''';
  return _readQuery(database, query, (d) => Rm1Row(d));
}

class Rm1Row extends SqliteRow {
  Rm1Row(Map<String, dynamic> data) : super(data);

  double? get estimated1rm => data['estimated_1rm'] as double?;
}

/// END RM1

/// BEGIN EXERCISESTATS
Future<List<ExerciseStatsRow>> performExerciseStats(
  Database database, {
  int? exerciseId,
  String? userId,
  String? timeRange,
}) {
  final query = '''
-- Params:
-- ${exerciseId}  (INTEGER)
-- "${userId}"    (TEXT)
-- "${timeRange}" (TEXT)

WITH bounds AS (
  SELECT
    CASE '${timeRange}'
      WHEN 'Last 7 days'  THEN datetime('now','localtime','-7 days')
      WHEN 'Last 30 days' THEN datetime('now','localtime','-30 days')
      WHEN 'Last 90 days' THEN datetime('now','localtime','-90 days')
      ELSE datetime('1970-01-01')
    END AS from_ts,
    CASE '${timeRange}'
      WHEN 'All' THEN datetime('9999-12-31')
      ELSE datetime('now','localtime')
    END AS to_ts,

    -- קבועים ל־current week
    datetime('now','localtime','-7 days') AS start_7d,
    datetime('now','localtime')           AS end_now
),

ex AS (
  SELECT
    e.id AS exercise_id,
    COALESCE(e.is_time_based, 0) AS is_time_based,
    COALESCE(e.is_bodyweight, 0) AS is_bodyweight
  FROM exercise e
  WHERE e.id = ${exerciseId}
),

sets AS (
  SELECT
    sl.workout_log_id,
    COALESCE(sl.created_at, wl.created_at) AS set_created_at,
    COALESCE(sl.reps, 0)                   AS reps,
    COALESCE(sl.weight, 0)                 AS weight,
    COALESCE(sl.duration_seconds, 0) * 1000 AS duration_ms
  FROM set_log sl
  JOIN workout_log wl ON wl.id = sl.workout_log_id
  JOIN bounds b
  WHERE sl.exercise_id = ${exerciseId}
    AND wl.user_id = '${userId}'
    AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
    AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
),

majority AS (
  SELECT
    CASE
      WHEN COUNT(*) = 0 THEN NULL
      WHEN 1.0 * SUM(CASE WHEN weight > 0 THEN 1 ELSE 0 END) / COUNT(*) >= 0.5
        THEN 0
      ELSE 1
    END AS inferred_is_bodyweight
  FROM sets
),

per_session_count AS (
  SELECT
    workout_log_id,
    MIN(set_created_at) AS session_created_at,
    SUM(
      CASE
        WHEN (SELECT is_time_based FROM ex) = 1
          THEN duration_ms
        ELSE reps
      END
    ) AS session_count_value
  FROM sets
  GROUP BY workout_log_id
),

per_session_volume AS (
  SELECT
    workout_log_id,
    MIN(set_created_at) AS session_created_at,
    SUM(
      CASE
        WHEN (SELECT is_time_based FROM ex) = 1
          THEN duration_ms
        WHEN COALESCE((SELECT inferred_is_bodyweight FROM majority),
                      (SELECT is_bodyweight FROM ex), 0) = 1
          THEN reps
        ELSE CAST(reps AS REAL) * CAST(weight AS REAL)
      END
    ) AS session_volume_value
  FROM sets
  GROUP BY workout_log_id
),

current_7d AS (
  -- intentionally always last 7 days
  SELECT
    COALESCE(SUM(
      CASE
        WHEN (SELECT is_time_based FROM ex) = 1
          THEN duration_ms
        ELSE reps
      END
    ), 0) AS current_week_value
  FROM sets, bounds
  WHERE set_created_at >= start_7d
    AND set_created_at <  end_now
),

best_session AS (
  SELECT COALESCE(MAX(session_count_value), 0) AS best_session_value
  FROM per_session_count
),

first_last AS (
  SELECT
    (SELECT session_volume_value
     FROM per_session_volume
     ORDER BY session_created_at ASC
     LIMIT 1) AS first_value,
    (SELECT session_volume_value
     FROM per_session_volume
     ORDER BY session_created_at DESC
     LIMIT 1) AS last_value
),

improve AS (
  SELECT
    CASE
      WHEN first_value IS NULL OR last_value IS NULL THEN 0
      WHEN first_value = 0 THEN 0
      ELSE CAST(
        ROUND(((last_value - first_value) * 100.0) / first_value, 0)
        AS INTEGER
      )
    END AS improvement_percent
  FROM first_last
)

SELECT
  CAST(COALESCE((SELECT best_session_value  FROM best_session), 0) AS INTEGER) AS best_session_value,
  CAST(COALESCE((SELECT current_week_value  FROM current_7d),   0) AS INTEGER) AS current_week_value,
  CAST(COALESCE((SELECT improvement_percent FROM improve),      0) AS INTEGER) AS improvement_percent,
  CAST(COALESCE((SELECT is_time_based       FROM ex),           0) AS INTEGER) AS is_time_based;

''';
  return _readQuery(database, query, (d) => ExerciseStatsRow(d));
}

class ExerciseStatsRow extends SqliteRow {
  ExerciseStatsRow(Map<String, dynamic> data) : super(data);

  int? get bestSessionValue => data['best_session_value'] as int?;
  int? get currentWeekValue => data['current_week_value'] as int?;
  int? get improvementPercent => data['improvement_percent'] as int?;
  int get isTimeBased => data['is_time_based'] as int;
}

/// END EXERCISESTATS

/// BEGIN EXERCISELINEGRAPH
Future<List<ExerciseLineGraphRow>> performExerciseLineGraph(
  Database database, {
  String? userId,
  int? exerciseId,
  String? timeRange,
}) {
  final query = '''
WITH bounds AS (
  SELECT
    CASE '${timeRange}'
      WHEN 'Last 7 days'  THEN datetime('now','localtime','-7 days')
      WHEN 'Last 30 days' THEN datetime('now','localtime','-30 days')
      WHEN 'Last 90 days' THEN datetime('now','localtime','-90 days')
      ELSE datetime('1970-01-01')
    END AS from_ts,
    CASE '${timeRange}'
      WHEN 'All' THEN datetime('9999-12-31')
      ELSE datetime('now','localtime')
    END AS to_ts
)

SELECT
  wl.user_id                                               AS user_id,
  CAST(sl.exercise_id    AS INTEGER)                       AS exercise_id,
  CAST(sl.workout_log_id AS INTEGER)                       AS workout_log_id,

  MIN(
    CASE
      WHEN typeof(sl.created_at) = 'integer'
        THEN date(sl.created_at / 1000, 'unixepoch')
      ELSE date(sl.created_at)
    END
  )                                                        AS session_date,

  -- total_reps כ-DOUBLE
  CAST(
    SUM(
      CAST(COALESCE(NULLIF(CAST(sl.reps AS TEXT), ''), '0') AS INTEGER)
    ) AS REAL
  )                                                        AS total_reps,

  -- total_volume
  SUM(
    CAST(COALESCE(NULLIF(CAST(sl.reps   AS TEXT), ''), '0') AS INTEGER)
    *
    CAST(COALESCE(NULLIF(TRIM(CAST(sl.weight AS TEXT)), ''), '0') AS REAL)
  )                                                        AS total_volume,

  -- max_weight_in_set
  MAX(
    CAST(COALESCE(NULLIF(TRIM(CAST(sl.weight AS TEXT)), ''), '0') AS REAL)
  )                                                        AS max_weight_in_set,

  -- total_sets כ-DOUBLE
  CAST(COUNT(*) AS REAL)                                   AS total_sets

FROM set_log sl
JOIN workout_log wl ON wl.id = sl.workout_log_id
JOIN bounds b

WHERE CAST(sl.exercise_id AS INTEGER) = ${exerciseId}
  AND CAST(wl.user_id AS TEXT) = '${userId}'
  AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
  AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts

GROUP BY wl.user_id, sl.exercise_id, sl.workout_log_id
ORDER BY session_date ASC;

''';
  return _readQuery(database, query, (d) => ExerciseLineGraphRow(d));
}

class ExerciseLineGraphRow extends SqliteRow {
  ExerciseLineGraphRow(Map<String, dynamic> data) : super(data);

  String get sessionDate => data['session_date'] as String;
  double get totalReps => data['total_reps'] as double;
  double get totalVolume => data['total_volume'] as double;
  double get maxWeightInSet => data['max_weight_in_set'] as double;
  double get totalSets => data['total_sets'] as double;
}

/// END EXERCISELINEGRAPH

/// BEGIN SMARTREPLACE
Future<List<SmartReplaceRow>> performSmartReplace(
  Database database, {
  int? exerciseId,
}) {
  final query = '''
WITH target AS (
  SELECT e.id AS exercise_id, e.exercise_type AS target_type, e.equipment AS target_equipment
  FROM exercise e
  WHERE e.id = ${exerciseId}
),
-- שרירים גדולים של היעד
target_pmg AS (
  SELECT DISTINCT pmg.id AS pmg_id
  FROM exercise e
  JOIN exercise_muscle_group emg ON emg.exercise_id = e.id AND emg.is_primary = 1
  JOIN muscle_group mg ON mg.id = emg.muscle_group_id
  JOIN primary_muscle_group pmg ON pmg.id = mg.primary_muscle_group_id
  WHERE e.id = ${exerciseId}
),
-- שרירים קטנים של היעד
target_mg AS (
  SELECT DISTINCT mg.id AS mg_id
  FROM exercise e
  JOIN exercise_muscle_group emg ON emg.exercise_id = e.id AND emg.is_primary = 1
  JOIN muscle_group mg ON mg.id = emg.muscle_group_id
  WHERE e.id = ${exerciseId}
),
-- מועמדים
candidates AS (
  SELECT e.id, e.name, e.exercise_type, e.equipment
  FROM exercise e
  WHERE e.id <> ${exerciseId}
),
-- קבוצות שרירים (גדול+קטן) לכל מועמד
cand_groups AS (
  SELECT
    e.id AS exercise_id,
    pmg.id AS pmg_id,
    pmg.name AS pmg_name,
    mg.id AS mg_id,
    mg.name AS mg_name
  FROM exercise e
  JOIN exercise_muscle_group emg ON emg.exercise_id = e.id AND emg.is_primary = 1
  JOIN muscle_group mg ON mg.id = emg.muscle_group_id
  JOIN primary_muscle_group pmg ON pmg.id = mg.primary_muscle_group_id
  WHERE e.id <> ${exerciseId}
),
scored AS (
  SELECT
    c.id,
    c.name,
    c.exercise_type,
    c.equipment,

    -- שרירים גדולים כמחרוזת (Distinct)
    (SELECT GROUP_CONCAT(pmg_name, ', ')
     FROM (SELECT DISTINCT pmg_name FROM cand_groups WHERE exercise_id = c.id)
    ) AS primary_muscles,

    -- חפיפות גדולות/קטנות
    COUNT(DISTINCT CASE WHEN cg.pmg_id IN (SELECT pmg_id FROM target_pmg) THEN cg.pmg_id END) AS overlap_primary,
    COUNT(DISTINCT CASE WHEN cg.mg_id  IN (SELECT mg_id  FROM target_mg ) THEN cg.mg_id  END) AS overlap_small,

    -- כמות קבוצות אצל המועמד
    COUNT(DISTINCT cg.pmg_id) AS candidate_primary_count,
    COUNT(DISTINCT cg.mg_id)  AS candidate_small_count,

    -- התאמות סוג/ציוד
    CASE WHEN c.exercise_type = (SELECT target_type FROM target) THEN 1 ELSE 0 END AS type_match,
    CASE WHEN c.equipment     = (SELECT target_equipment FROM target) THEN 1 ELSE 0 END AS equipment_match,

    -- התאמה מלאה בגדול (עם guard כשאין בכלל ליעד)
    CASE
      WHEN (SELECT COUNT(*) FROM target_pmg) > 0
       AND COUNT(DISTINCT CASE WHEN cg.pmg_id IN (SELECT pmg_id FROM target_pmg) THEN cg.pmg_id END) = (SELECT COUNT(*) FROM target_pmg)
       AND COUNT(DISTINCT cg.pmg_id) = (SELECT COUNT(*) FROM target_pmg)
      THEN 1 ELSE 0
    END AS full_primary_match,

    -- התאמה מלאה בקטן (Side Delts וכו') עם guard
    CASE
      WHEN (SELECT COUNT(*) FROM target_mg) > 0
       AND COUNT(DISTINCT CASE WHEN cg.mg_id IN (SELECT mg_id FROM target_mg) THEN cg.mg_id END) = (SELECT COUNT(*) FROM target_mg)
       AND COUNT(DISTINCT cg.mg_id)  = (SELECT COUNT(*) FROM target_mg)
      THEN 1 ELSE 0
    END AS full_small_match
  FROM candidates c
  LEFT JOIN cand_groups cg ON cg.exercise_id = c.id
  GROUP BY c.id
),
ranked AS (
  SELECT
    s.*,
    -- משקלים: קודם קטן מלא, אח"כ גדול מלא, אח"כ חפיפות, ואז סוג/ציוד
    (s.full_small_match   * 5000) +
    (s.full_primary_match * 1000) +
    (s.overlap_small      *  200) +
    (s.overlap_primary    *  100) +
    (s.type_match         *   10) +
    (s.equipment_match    *    1) AS match_score
  FROM scored s
)
SELECT
  r.id,
  r.name,
  r.primary_muscles,                 -- TEXT (לרינדור)
  r.exercise_type,                   -- TEXT
  r.equipment AS equipment_type,     -- TEXT
  COALESCE(e.illustration, e.no_video_ilustration) AS illustration, -- TEXT/NULL
  CASE WHEN COALESCE(e.is_assisted, 0) IN (1, 'true', 'TRUE') THEN 1 ELSE 0 END AS is_assisted, -- INTEGER 0/1
  CASE WHEN COALESCE(e.is_public, 0)   IN (1, 'true', 'TRUE') THEN 1 ELSE 0 END AS is_public,   -- INTEGER 0/1
  r.match_score                      -- INTEGER
FROM ranked r
JOIN exercise e ON e.id = r.id
WHERE r.overlap_primary >= 1
ORDER BY
  r.full_small_match   DESC,         -- 1) אותו muscleGroup קטן? קודם.
  r.full_primary_match DESC,         -- 2) סט מלא בגדול.
  r.overlap_small      DESC,         -- 3) כמה חפיפות בקטן.
  r.overlap_primary    DESC,         -- 4) כמה חפיפות בגדול.
  r.type_match         DESC,         -- 5) סוג זהה.
  r.equipment_match    DESC,         -- 6) ציוד זהה.
  r.match_score        DESC
LIMIT 25;
''';
  return _readQuery(database, query, (d) => SmartReplaceRow(d));
}

class SmartReplaceRow extends SqliteRow {
  SmartReplaceRow(Map<String, dynamic> data) : super(data);

  int get id => data['id'] as int;
  String get name => data['name'] as String;
  String get exerciseType => data['exercise_type'] as String;
  String get equipmentType => data['equipment_type'] as String;
  String? get primaryMuscles => data['primary_muscles'] as String?;
  int get matchScore => data['match_score'] as int;
  String get illustration => data['illustration'] as String;
  int get isPublic => data['is_public'] as int;
  int get isAssisted => data['is_assisted'] as int;
}

/// END SMARTREPLACE

/// BEGIN VOLUMEOVERVIEW
Future<List<VolumeOverviewRow>> performVolumeOverview(
  Database database, {
  String? userId,
}) {
  final query = '''
SELECT
  wl.id AS workoutLogId,
  SUBSTR(CAST(wl.created_at AS TEXT), 1, 10) AS workoutDate, -- YYYY-MM-DD
  ROUND(
    COALESCE(
      wl.volume,
      (
        SELECT SUM(
                 CASE
                   WHEN IFNULL(s.weight,0) > 0
                     THEN IFNULL(s.weight,0) * IFNULL(s.reps,0)
                   WHEN IFNULL(s.duration_seconds,0) > 0
                     THEN IFNULL(s.duration_seconds,0) * 1.0
                   ELSE IFNULL(s.reps,0)
                 END
               )
        FROM set_log s
        WHERE s.workout_log_id = wl.id
      )
    ), 1
  ) AS workoutVolume
FROM workout_log wl
WHERE wl.user_id = '${userId}'
ORDER BY wl.created_at ASC;

''';
  return _readQuery(database, query, (d) => VolumeOverviewRow(d));
}

class VolumeOverviewRow extends SqliteRow {
  VolumeOverviewRow(Map<String, dynamic> data) : super(data);

  String get workoutDate => data['workoutDate'] as String;
  double get workoutVolume => data['workoutVolume'] as double;
}

/// END VOLUMEOVERVIEW

/// BEGIN TEST
Future<List<TestRow>> performTest(
  Database database, {
  String? workoutLogId,
}) {
  final query = '''
SELECT COUNT(*) AS sets_count
FROM set_log
WHERE workout_log_id = '${workoutLogId}'
  AND COALESCE(is_dropset, 0) = 0;

''';
  return _readQuery(database, query, (d) => TestRow(d));
}

class TestRow extends SqliteRow {
  TestRow(Map<String, dynamic> data) : super(data);

  int get setsCount => data['sets_count'] as int;
}

/// END TEST

/// BEGIN MOSTTIMES EXERCISE
Future<List<MostTimesExerciseRow>> performMostTimesExercise(
  Database database, {
  String? timeRange,
  String? userId,
}) {
  final query = '''
-- פרמטרים:
-- ${userId}     (TEXT)
-- ${timeRange}  (TEXT)  -- 'All' | 'Last 7 days' | 'Last 30 days' | 'Last 90 days'

WITH params AS (
  SELECT '${timeRange}' AS time_range,
         '${userId}'    AS user_id
),
cutoff AS (
  SELECT CASE
           WHEN time_range = 'Last 7 days'  THEN datetime('now','localtime','-7 days')
           WHEN time_range = 'Last 30 days' THEN datetime('now','localtime','-30 days')
           WHEN time_range = 'Last 90 days' THEN datetime('now','localtime','-90 days')
           ELSE NULL
         END AS min_dt
  FROM params
),
filtered AS (
  SELECT sl.exercise_id, sl.workout_log_id
  FROM set_log sl
  JOIN workout_log wl ON wl.id = sl.workout_log_id
  JOIN params p ON wl.user_id = p.user_id
  LEFT JOIN cutoff c ON 1=1
  WHERE COALESCE(sl.is_dropset, 0) = 0
    AND (
         c.min_dt IS NULL
         OR datetime(replace(wl.created_at,' ','T')) >= c.min_dt
        )
)
SELECT 
    e.id   AS exercise_id,
    e.name AS exercise_name,
    COUNT(DISTINCT f.workout_log_id) AS times_performed
FROM filtered f
JOIN exercise e ON e.id = f.exercise_id
GROUP BY e.id, e.name
ORDER BY times_performed DESC, exercise_name ASC
LIMIT 1;

''';
  return _readQuery(database, query, (d) => MostTimesExerciseRow(d));
}

class MostTimesExerciseRow extends SqliteRow {
  MostTimesExerciseRow(Map<String, dynamic> data) : super(data);

  String? get exerciseName => data['exercise_name'] as String?;
  int? get timesPerformed => data['times_performed'] as int?;
  int? get exerciseId => data['exercise_id'] as int?;
}

/// END MOSTTIMES EXERCISE

/// BEGIN MOST IMPROVED EXERCISE
Future<List<MostImprovedExerciseRow>> performMostImprovedExercise(
  Database database, {
  String? userId,
  String? timeRange,
}) {
  final query = '''
-- קלט:
-- ${userId}    (TEXT)
-- ${timeRange} (TEXT)  -- 'All' | 'Last 7 days' | 'Last 30 days' | 'Last 90 days'

WITH params AS (
  SELECT '${userId}' AS user_id, '${timeRange}' AS time_range
),

cutoff AS (
  SELECT CASE
           WHEN time_range = 'Last 7 days'  THEN datetime('now','localtime','-7 days')
           WHEN time_range = 'Last 30 days' THEN datetime('now','localtime','-30 days')
           WHEN time_range = 'Last 90 days' THEN datetime('now','localtime','-90 days')
           ELSE NULL
         END AS min_dt
  FROM params
),

sets_filtered AS (
  SELECT
    sl.*,
    wl.created_at
  FROM set_log sl
  JOIN workout_log wl
    ON wl.id = sl.workout_log_id
  JOIN params p
    ON wl.user_id = p.user_id
  LEFT JOIN cutoff c
    ON 1 = 1
  WHERE COALESCE(sl.is_dropset, 0) = 0
    AND (
          c.min_dt IS NULL
          OR datetime(replace(wl.created_at,' ','T')) >= c.min_dt
        )
),

session_values AS (
  SELECT
    s.exercise_id,
    s.workout_log_id,
    wl.created_at,

    CASE
      -- תרגילי זמן
      WHEN SUM(CASE WHEN s.duration_seconds IS NOT NULL THEN 1 ELSE 0 END) = COUNT(*)
        THEN SUM(COALESCE(s.duration_seconds, 0))

      -- תרגילי משקל גוף
      WHEN SUM(CASE WHEN s.weight IS NULL OR s.weight = 0 THEN 1 ELSE 0 END) = COUNT(*)
        THEN SUM(COALESCE(s.reps, 0))

      -- משקולות / אסיסט
      ELSE SUM(1.0 * COALESCE(s.reps, 0) * COALESCE(s.weight, 0))
    END AS value
  FROM sets_filtered s
  JOIN workout_log wl
    ON wl.id = s.workout_log_id
  GROUP BY s.exercise_id, s.workout_log_id, wl.created_at
),

ranked AS (
  SELECT
    sv.*,
    ROW_NUMBER() OVER (
      PARTITION BY sv.exercise_id
      ORDER BY datetime(replace(sv.created_at,' ','T')) ASC
    )  AS rn_first,
    ROW_NUMBER() OVER (
      PARTITION BY sv.exercise_id
      ORDER BY datetime(replace(sv.created_at,' ','T')) DESC
    ) AS rn_last
  FROM session_values sv
),

first_last AS (
  SELECT
    exercise_id,
    MAX(CASE WHEN rn_first = 1 THEN value END) AS first_value,
    MAX(CASE WHEN rn_last  = 1 THEN value END) AS last_value,
    COUNT(*) AS sessions_count
  FROM ranked
  GROUP BY exercise_id
  HAVING sessions_count >= 2
     AND first_value IS NOT NULL
     AND last_value  IS NOT NULL
     AND first_value <> 0
)

SELECT
  e.id   AS exercise_id,
  e.name AS exercise_name,

  -- 🔥 חישוב שיפור:
  -- רגיל:   (last - first) / first
  -- אסיסט:  (first - last) / first
  CAST(
    ROUND(
      CASE
        WHEN COALESCE(e.is_assisted, 0) = 1
          THEN (fl.first_value - fl.last_value) * 100.0 / fl.first_value
        ELSE (fl.last_value - fl.first_value) * 100.0 / fl.first_value
      END
    ) AS INTEGER
  ) || '%' AS improvement_pct

FROM first_last fl
JOIN exercise e
  ON e.id = fl.exercise_id

ORDER BY
  CAST(
    ROUND(
      CASE
        WHEN COALESCE(e.is_assisted, 0) = 1
          THEN (fl.first_value - fl.last_value) * 100.0 / fl.first_value
        ELSE (fl.last_value - fl.first_value) * 100.0 / fl.first_value
      END
    ) AS INTEGER
  ) DESC,
  exercise_name ASC

LIMIT 1;

''';
  return _readQuery(database, query, (d) => MostImprovedExerciseRow(d));
}

class MostImprovedExerciseRow extends SqliteRow {
  MostImprovedExerciseRow(Map<String, dynamic> data) : super(data);

  String? get improvementPct => data['improvement_pct'] as String?;
  String? get exerciseName => data['exercise_name'] as String?;
  int? get exerciseId => data['exercise_id'] as int?;
}

/// END MOST IMPROVED EXERCISE

/// BEGIN TOTAL EXERCISES FOR TIME
Future<List<TotalExercisesForTimeRow>> performTotalExercisesForTime(
  Database database, {
  String? userId,
  String? timeRange,
}) {
  final query = '''
-- קלט:
-- ${userId}    (TEXT)
-- ${timeRange} (TEXT)  -- 'All' | 'Last 7 days' | 'Last 30 days' | 'Last 90 days'

WITH params AS (
  SELECT '${userId}' AS user_id, '${timeRange}' AS time_range
),
cutoff AS (
  SELECT CASE
           WHEN time_range = 'Last 7 days'  THEN datetime('now','localtime','-7 days')
           WHEN time_range = 'Last 30 days' THEN datetime('now','localtime','-30 days')
           WHEN time_range = 'Last 90 days' THEN datetime('now','localtime','-90 days')
           ELSE NULL
         END AS min_dt
  FROM params
),
filtered AS (
  SELECT sl.exercise_id
  FROM set_log sl
  JOIN workout_log wl ON wl.id = sl.workout_log_id
  JOIN params p ON wl.user_id = p.user_id
  LEFT JOIN cutoff c ON 1=1
  WHERE COALESCE(sl.is_dropset, 0) = 0
    AND (
          c.min_dt IS NULL OR 
          datetime(replace(wl.created_at,' ','T')) >= c.min_dt
        )
)
SELECT COUNT(DISTINCT exercise_id) AS total_exercises
FROM filtered;

''';
  return _readQuery(database, query, (d) => TotalExercisesForTimeRow(d));
}

class TotalExercisesForTimeRow extends SqliteRow {
  TotalExercisesForTimeRow(Map<String, dynamic> data) : super(data);

  int? get totalExercises => data['total_exercises'] as int?;
}

/// END TOTAL EXERCISES FOR TIME

/// BEGIN TOP VOLUME EXERCISE
Future<List<TopVolumeExerciseRow>> performTopVolumeExercise(
  Database database, {
  String? userId,
  String? timeRange,
}) {
  final query = '''
WITH params AS (
  SELECT '${userId}' AS user_id, '${timeRange}' AS time_range
),

cutoff AS (
  SELECT CASE
           WHEN time_range = 'Last 7 days'  THEN datetime('now','localtime','-7 days')
           WHEN time_range = 'Last 30 days' THEN datetime('now','localtime','-30 days')
           WHEN time_range = 'Last 90 days' THEN datetime('now','localtime','-90 days')
           ELSE NULL
         END AS min_dt
  FROM params
),

sets_filtered AS (
  SELECT
    sl.*
  FROM set_log sl
  JOIN workout_log wl
    ON wl.id = sl.workout_log_id
  JOIN exercise e
    ON e.id = sl.exercise_id
  JOIN params p
    ON wl.user_id = p.user_id
  LEFT JOIN cutoff c
    ON 1 = 1
  WHERE COALESCE(sl.is_dropset, 0) = 0
    AND COALESCE(e.is_assisted, 0) = 0
    AND sl.weight IS NOT NULL
    AND sl.weight > 0
    AND sl.reps IS NOT NULL
    AND (
         c.min_dt IS NULL
         OR datetime(replace(wl.created_at,' ','T')) >= c.min_dt
    )
),

exercise_volume AS (
  SELECT
    s.exercise_id,
    SUM(
      s.reps *
      CASE
        WHEN s.is_kg = 1 THEN s.weight
        ELSE s.weight * 0.453592
      END
    ) AS total_volume
  FROM sets_filtered s
  GROUP BY s.exercise_id
)

SELECT
  e.id   AS exercise_id,
  e.name AS exercise_name,
  ROUND(ev.total_volume, 1) AS total_volume,
  'kg' AS volume_unit
FROM exercise_volume ev
JOIN exercise e
  ON e.id = ev.exercise_id
WHERE ev.total_volume > 0
ORDER BY ev.total_volume DESC
LIMIT 1;

''';
  return _readQuery(database, query, (d) => TopVolumeExerciseRow(d));
}

class TopVolumeExerciseRow extends SqliteRow {
  TopVolumeExerciseRow(Map<String, dynamic> data) : super(data);

  int? get exerciseId => data['exercise_id'] as int?;
  String? get exerciseName => data['exercise_name'] as String?;
  double? get totalVolume => data['total_volume'] as double?;
  String? get volumeUnit => data['volume_unit'] as String?;
}

/// END TOP VOLUME EXERCISE

/// BEGIN EXERCISE PERFPRMANCE
Future<List<ExercisePerfprmanceRow>> performExercisePerfprmance(
  Database database, {
  String? userId,
  String? timeRange,
}) {
  final query = '''
-- ${userId} (TEXT)
-- ${timeRange} (TEXT)

WITH params AS (
  SELECT '${userId}' AS user_id, '${timeRange}' AS time_range
),

cutoff AS (
  SELECT CASE
           WHEN time_range = 'Last 7 days'  THEN datetime('now','localtime','-7 days')
           WHEN time_range = 'Last 30 days' THEN datetime('now','localtime','-30 days')
           WHEN time_range = 'Last 90 days' THEN datetime('now','localtime','-90 days')
           ELSE NULL
         END AS min_dt
  FROM params
),

-- ---------- סטים רלוונטיים ----------
sets_filtered AS (
  SELECT
    sl.*,
    wl.created_at,
    (COALESCE(sl.duration_seconds, 0) / 1000.0) AS duration_sec,
    COALESCE(e.is_assisted, 0) AS is_assisted
  FROM set_log sl
  JOIN workout_log wl ON wl.id = sl.workout_log_id
  JOIN exercise e ON e.id = sl.exercise_id
  JOIN params p ON wl.user_id = p.user_id
  LEFT JOIN cutoff c ON 1=1
  WHERE COALESCE(sl.is_dropset, 0) = 0
    AND (
      c.min_dt IS NULL
      OR datetime(replace(wl.created_at,' ','T')) >= c.min_dt
    )
),

-- ---------- סכימת ווליום ----------
agg AS (
  SELECT
    s.exercise_id,

    -- משקולות (רק אם לא Assisted)
    SUM(
      CASE
        WHEN s.is_assisted = 0 AND s.weight > 0 AND s.is_kg = 1
          THEN 1.0 * s.reps * s.weight
        ELSE 0
      END
    ) AS vol_kg,

    SUM(
      CASE
        WHEN s.is_assisted = 0 AND s.weight > 0 AND s.is_kg = 2
          THEN 1.0 * s.reps * (s.weight * 0.453592)
        ELSE 0
      END
    ) AS vol_lbs,

    -- Bodyweight + Assisted → חזרות
    SUM(
      CASE
        WHEN s.weight IS NULL OR s.weight = 0 OR s.is_assisted = 1
          THEN COALESCE(s.reps,0)
        ELSE 0
      END
    ) AS reps_sum,

    SUM(COALESCE(s.duration_sec,0)) AS sec_sum
  FROM sets_filtered s
  GROUP BY s.exercise_id
),

-- ---------- תצוגת ווליום ----------
volume_str AS (
  SELECT
    a.exercise_id,
    CASE
      WHEN a.vol_kg > 0 THEN CAST(ROUND(a.vol_kg) AS INTEGER) || ' kg'
      WHEN a.vol_lbs > 0 THEN CAST(ROUND(a.vol_lbs) AS INTEGER) || ' lbs'
      WHEN a.reps_sum > 0 THEN CAST(ROUND(a.reps_sum) AS INTEGER) || ' Reps'
      ELSE printf('%02d:%02d',
                  CAST(a.sec_sum AS INTEGER) / 60,
                  CAST(a.sec_sum AS INTEGER) % 60)
    END AS volume_str
  FROM agg a
),

-- ---------- ערכי סשן ----------
session_values AS (
  SELECT
    s.exercise_id,
    s.workout_log_id,
    wl.created_at,
    s.is_assisted,

    CASE
      WHEN SUM(CASE WHEN s.duration_sec > 0 THEN 1 ELSE 0 END) = COUNT(*)
        THEN SUM(s.duration_sec)

      WHEN s.is_assisted = 1
        THEN SUM(COALESCE(s.reps,0))

      WHEN SUM(CASE WHEN s.weight IS NULL OR s.weight = 0 THEN 1 ELSE 0 END) = COUNT(*)
        THEN SUM(COALESCE(s.reps,0))

      ELSE
        SUM(
          1.0 * COALESCE(s.reps,0) *
          CASE
            WHEN s.is_kg = 1 THEN s.weight
            ELSE s.weight * 0.453592
          END
        )
    END AS value
  FROM sets_filtered s
  JOIN workout_log wl ON wl.id = s.workout_log_id
  GROUP BY s.exercise_id, s.workout_log_id, wl.created_at, s.is_assisted
),

ranked AS (
  SELECT
    sv.*,
    ROW_NUMBER() OVER (PARTITION BY sv.exercise_id ORDER BY datetime(replace(sv.created_at,' ','T')) ASC)  AS rn_first,
    ROW_NUMBER() OVER (PARTITION BY sv.exercise_id ORDER BY datetime(replace(sv.created_at,' ','T')) DESC) AS rn_last
  FROM session_values sv
),

first_last AS (
  SELECT
    exercise_id,
    MAX(CASE WHEN rn_first = 1 THEN value END) AS first_value,
    MAX(CASE WHEN rn_last  = 1 THEN value END) AS last_value,
    MAX(is_assisted) AS is_assisted,
    COUNT(*) AS sessions_count
  FROM ranked
  GROUP BY exercise_id
),

percent_change AS (
  SELECT
    exercise_id,
    CASE
      WHEN sessions_count < 2 OR first_value = 0 THEN NULL
      WHEN is_assisted = 1
        THEN CAST(ROUND((first_value - last_value) * 100.0 / first_value) AS INTEGER)
      ELSE
        CAST(ROUND((last_value - first_value) * 100.0 / first_value) AS INTEGER)
    END AS percent_change
  FROM first_last
)

SELECT
  e.id   AS exercise_id,
  e.name AS exercise_name,
  COALESCE(e.illustration, e.no_video_ilustration) AS illustration,
  e.is_public,
  vs.volume_str,
  pc.percent_change
FROM volume_str vs
JOIN exercise e ON e.id = vs.exercise_id
LEFT JOIN percent_change pc ON pc.exercise_id = vs.exercise_id
ORDER BY e.name ASC;

''';
  return _readQuery(database, query, (d) => ExercisePerfprmanceRow(d));
}

class ExercisePerfprmanceRow extends SqliteRow {
  ExercisePerfprmanceRow(Map<String, dynamic> data) : super(data);

  String? get exerciseName => data['exercise_name'] as String?;
  String? get illustration => data['illustration'] as String?;
  int? get exerciseId => data['exercise_id'] as int?;
  String? get volumeStr => data['volume_str'] as String?;
  int? get percentChange => data['percent_change'] as int?;
  int get isPublic => data['is_public'] as int;
}

/// END EXERCISE PERFPRMANCE

/// BEGIN BY MUSCLE KPI
Future<List<ByMuscleKpiRow>> performByMuscleKpi(
  Database database, {
  String? muscleName,
  String? rangeLabel,
  String? userId,
}) {
  final query = '''
WITH
params AS (
  SELECT
    '${userId}'     AS userId,
    '${muscleName}' AS muscleName,    -- למשל "Chest"
    '${rangeLabel}' AS rangeLabel,    -- "All" | "Last 7 days" | "Last 30 days" | "Last 90 days"
    DATE('now')     AS today,

    CASE '${rangeLabel}'
      WHEN 'Last 7 days'  THEN DATE('now','-7 days')
      WHEN 'Last 30 days' THEN DATE('now','-30 days')
      WHEN 'Last 90 days' THEN DATE('now','-90 days')
      ELSE NULL
    END AS startDate
),
win AS (
  SELECT CASE
    WHEN startDate IS NULL THEN NULL
    ELSE CAST(JULIANDAY(today) - JULIANDAY(startDate) AS INTEGER)
  END AS daysLen
  FROM params
),

-- -------- סטים בטווח הנוכחי --------
curr_sets AS (
  SELECT s.*
  FROM set_log s
  JOIN workout_log wl ON wl.id = s.workout_log_id
  JOIN exercise e ON e.id = s.exercise_id
  JOIN exercise_muscle_group emg ON emg.exercise_id = e.id AND emg.is_primary = 1
  JOIN muscle_group mg ON mg.id = emg.muscle_group_id
  JOIN primary_muscle_group pmg ON pmg.id = mg.primary_muscle_group_id
  JOIN params p
  WHERE wl.user_id = p.userId
    AND pmg.name = p.muscleName
    AND (
          p.startDate IS NULL
          OR DATE(replace(s.created_at,' ','T')) >= p.startDate
        )
),

-- -------- סטים בטווח ההשוואה הקודם --------
prev_sets AS (
  SELECT s.*
  FROM set_log s
  JOIN workout_log wl ON wl.id = s.workout_log_id
  JOIN exercise e ON e.id = s.exercise_id
  JOIN exercise_muscle_group emg ON emg.exercise_id = e.id AND emg.is_primary = 1
  JOIN muscle_group mg ON mg.id = emg.muscle_group_id
  JOIN primary_muscle_group pmg ON pmg.id = mg.primary_muscle_group_id
  JOIN params p
  JOIN win w
  WHERE wl.user_id = p.userId
    AND pmg.name = p.muscleName
    AND p.startDate IS NOT NULL
    AND DATE(replace(s.created_at,' ','T')) >= DATE(p.startDate, printf('-%d days', w.daysLen))
    AND DATE(replace(s.created_at,' ','T')) <  p.startDate
),

-- -------- אגרגציה לטווח הנוכחי --------
curr_agg AS (
  SELECT
    SUM(
        CASE
          WHEN COALESCE(s.weight,0) > 0 THEN s.weight * COALESCE(s.reps,0)
          WHEN COALESCE(s.duration_seconds,0) > 0 THEN s.duration_seconds * 1.0
          ELSE COALESCE(s.reps,0)
        END
    ) AS totalVolume,
    COUNT(*) AS totalSets
  FROM curr_sets s
),

-- -------- אגרגציה לטווח ההשוואה --------
prev_agg AS (
  SELECT
    SUM(
        CASE
          WHEN COALESCE(s.weight,0) > 0 THEN s.weight * COALESCE(s.reps,0)
          WHEN COALESCE(s.duration_seconds,0) > 0 THEN s.duration_seconds * 1.0
          ELSE COALESCE(s.reps,0)
        END
    ) AS totalVolume,
    COUNT(*) AS totalSets
  FROM prev_sets s
)

SELECT
  ROUND(COALESCE(c.totalVolume,0),1) AS kpiTotalVolume,
  COALESCE(c.totalSets,0)           AS kpiTotalSets,
  CASE
    WHEN (SELECT startDate FROM params) IS NULL
      OR COALESCE(p.totalVolume,0) = 0
      THEN NULL
    ELSE ROUND(100.0 * (c.totalVolume - p.totalVolume) / p.totalVolume, 1)
  END AS kpiPctChange
FROM curr_agg c
LEFT JOIN prev_agg p;

''';
  return _readQuery(database, query, (d) => ByMuscleKpiRow(d));
}

class ByMuscleKpiRow extends SqliteRow {
  ByMuscleKpiRow(Map<String, dynamic> data) : super(data);

  double? get kpiTotalVolume => data['kpiTotalVolume'] as double?;
  int? get kpiTotalSets => data['kpiTotalSets'] as int?;
  double? get kpiPctChange => data['kpiPctChange'] as double?;
}

/// END BY MUSCLE KPI

/// BEGIN LAST TRAINED MUSCLE
Future<List<LastTrainedMuscleRow>> performLastTrainedMuscle(
  Database database, {
  String? userId,
  String? muscleName,
}) {
  final query = '''
WITH
last_time AS (
  SELECT
    MAX(s.created_at) AS lastAt
  FROM set_log s
  JOIN workout_log wl ON wl.id = s.workout_log_id
  JOIN exercise e ON e.id = s.exercise_id
  JOIN exercise_muscle_group emg
       ON emg.exercise_id = e.id AND emg.is_primary = 1
  JOIN muscle_group mg ON mg.id = emg.muscle_group_id
  JOIN primary_muscle_group pmg ON pmg.id = mg.primary_muscle_group_id
  WHERE wl.user_id = '${userId}'
    AND pmg.name = '${muscleName}'
),

diffs AS (
  SELECT
    -- ❗️לא מחזירים NULL
    COALESCE(lastAt, '') AS lastAtSafe,

    CASE
      WHEN lastAt IS NULL THEN -1
      ELSE CAST(
        (JULIANDAY('now','localtime') - JULIANDAY(lastAt)) * 1440
        AS INTEGER
      )
    END AS minutesSinceSafe
  FROM last_time
)

SELECT
  lastAtSafe AS lastAt,

  CASE
    WHEN minutesSinceSafe < 0      THEN 'No data'
    WHEN minutesSinceSafe < 60     THEN 'Last trained ' || minutesSinceSafe || 'm ago'
    WHEN minutesSinceSafe < 1440   THEN 'Last trained ' || (minutesSinceSafe / 60) || 'h ago'
    ELSE                                'Last trained ' || (minutesSinceSafe / 1440) || 'd ago'
  END AS lastTrainedText,

  CASE
    WHEN minutesSinceSafe < 0      THEN '#C8CDD5'
    WHEN minutesSinceSafe < 1440   THEN '#E85A5A'
    WHEN minutesSinceSafe < 2880   THEN '#F1A24A'
    WHEN minutesSinceSafe < 10080  THEN '#2CCAAE'
    ELSE                                '#C8CDD5'
  END AS statusColorHex

FROM diffs;

''';
  return _readQuery(database, query, (d) => LastTrainedMuscleRow(d));
}

class LastTrainedMuscleRow extends SqliteRow {
  LastTrainedMuscleRow(Map<String, dynamic> data) : super(data);

  String get statusColorHex => data['statusColorHex'] as String;
  String get lastAt => data['lastAt'] as String;
}

/// END LAST TRAINED MUSCLE

/// BEGIN VOLUME BY MUSCLE
Future<List<VolumeByMuscleRow>> performVolumeByMuscle(
  Database database, {
  String? muscleName,
  String? rangeLabel,
  String? userId,
}) {
  final query = '''
WITH
params AS (
  SELECT
    '${userId}'     AS userId,
    '${muscleName}' AS muscleName,
    '${rangeLabel}' AS rangeLabel,
    DATE('now')     AS today,

    CASE '${rangeLabel}'
      WHEN 'Last 7 days'  THEN DATE('now','-7 days')
      WHEN 'Last 30 days' THEN DATE('now','-30 days')
      WHEN 'Last 90 days' THEN DATE('now','-90 days')
      ELSE NULL
    END AS startDate
),

-- נרמול created_at לפורמט תאריך
wl_norm AS (
  SELECT
    wl.*,
    DATE(replace(CAST(wl.created_at AS TEXT),' ','T')) AS created_date
  FROM workout_log wl
)

SELECT
  w.created_date AS workoutDate,
  ROUND(
    SUM(
      CASE
        WHEN COALESCE(s.weight,0) > 0
          THEN s.weight * COALESCE(s.reps,0)
        WHEN COALESCE(s.duration_seconds,0) > 0
          THEN s.duration_seconds * 1.0
        ELSE
          COALESCE(s.reps,0)
      END
    ),
    1
  ) AS muscleVolume
FROM set_log s
JOIN wl_norm w                 ON w.id = s.workout_log_id
JOIN exercise e                ON e.id = s.exercise_id
JOIN exercise_muscle_group emg ON emg.exercise_id = e.id AND emg.is_primary = 1
JOIN muscle_group mg           ON mg.id = emg.muscle_group_id
JOIN primary_muscle_group pmg  ON pmg.id = mg.primary_muscle_group_id
JOIN params p                  ON 1=1
WHERE w.user_id = p.userId
  AND COALESCE(e.is_assisted, 0) = 0        -- ❗ החרגת Assisted
  AND LOWER(TRIM(pmg.name)) = LOWER(TRIM(p.muscleName))
  AND (p.startDate IS NULL OR w.created_date >= p.startDate)
GROUP BY w.id, w.created_date
ORDER BY w.created_date ASC;

''';
  return _readQuery(database, query, (d) => VolumeByMuscleRow(d));
}

class VolumeByMuscleRow extends SqliteRow {
  VolumeByMuscleRow(Map<String, dynamic> data) : super(data);

  String? get workoutDate => data['workoutDate'] as String?;
  double? get muscleVolume => data['muscleVolume'] as double?;
}

/// END VOLUME BY MUSCLE

/// BEGIN EXERCISE BY MUSCLE
Future<List<ExerciseByMuscleRow>> performExerciseByMuscle(
  Database database, {
  String? userId,
  String? muscleName,
  String? rangeLabel,
}) {
  final query = '''
WITH
params AS (
  SELECT
    '${userId}'      AS userId,
    '${muscleName}'  AS muscleName,   -- לדוגמה "Chest"
    '${rangeLabel}'  AS rangeLabel,   -- "All" | "Last 7 days" | "Last 30 days" | "Last 90 days"
    DATE('now')      AS today,

    CASE '${rangeLabel}'
      WHEN 'Last 7 days'  THEN DATE('now','-7 days')
      WHEN 'Last 30 days' THEN DATE('now','-30 days')
      WHEN 'Last 90 days' THEN DATE('now','-90 days')
      ELSE NULL
    END AS startDate
)

SELECT
  e.name AS exerciseName,
  COUNT(*) AS setCount,
  COALESCE(e.illustration, e.no_video_ilustration) AS illustrationUrl
FROM set_log s
JOIN workout_log wl            ON wl.id = s.workout_log_id
JOIN exercise e                ON e.id = s.exercise_id
JOIN exercise_muscle_group emg ON emg.exercise_id = e.id AND emg.is_primary = 1
JOIN muscle_group mg           ON mg.id = emg.muscle_group_id
JOIN primary_muscle_group pmg  ON pmg.id = mg.primary_muscle_group_id
JOIN params p
WHERE wl.user_id = p.userId
  AND pmg.name = p.muscleName
  AND (
        p.startDate IS NULL
        OR DATE(replace(wl.created_at,' ','T')) >= p.startDate
      )
GROUP BY e.id, e.name, illustrationUrl
ORDER BY setCount DESC, e.name ASC;

''';
  return _readQuery(database, query, (d) => ExerciseByMuscleRow(d));
}

class ExerciseByMuscleRow extends SqliteRow {
  ExerciseByMuscleRow(Map<String, dynamic> data) : super(data);

  String? get illustrationUrl => data['illustrationUrl'] as String?;
  String get exerciseName => data['exerciseName'] as String;
  int get setCount => data['setCount'] as int;
}

/// END EXERCISE BY MUSCLE

/// BEGIN SUB MUSCLE DISTRIBUTION
Future<List<SubMuscleDistributionRow>> performSubMuscleDistribution(
  Database database, {
  String? userId,
  String? muscleName,
  String? rangeLabel,
}) {
  final query = '''
WITH
params AS (
  SELECT
    '${userId}'      AS userId,
    '${muscleName}'  AS muscleName,   -- primary_muscle_group.name
    '${rangeLabel}'  AS rangeLabel,
    DATE('now')      AS today,

    CASE '${rangeLabel}'
      WHEN 'Last 7 days'  THEN DATE('now','-7 days')
      WHEN 'Last 30 days' THEN DATE('now','-30 days')
      WHEN 'Last 90 days' THEN DATE('now','-90 days')
      ELSE NULL
    END AS startDate
),

-- נרמול תאריך אימון ל־YYYY-MM-DD
wl_norm AS (
  SELECT
    wl.*,
    DATE(replace(CAST(wl.created_at AS TEXT),' ','T')) AS created_date
  FROM workout_log wl
),

-- סטים רלוונטיים
filtered_sets AS (
  SELECT
    s.id,
    s.workout_log_id,
    s.exercise_id,
    s.reps,
    s.weight,
    s.duration_seconds,
    w.created_date,
    mg.id   AS sub_muscle_id,
    mg.name AS sub_muscle_name
  FROM set_log s
  JOIN wl_norm w                 ON w.id = s.workout_log_id
  JOIN exercise e                ON e.id = s.exercise_id
  JOIN exercise_muscle_group emg ON emg.exercise_id = e.id AND emg.is_primary = 1
  JOIN muscle_group mg           ON mg.id = emg.muscle_group_id
  JOIN primary_muscle_group pmg  ON pmg.id = mg.primary_muscle_group_id
  JOIN params p
  WHERE w.user_id = p.userId
    AND LOWER(TRIM(pmg.name)) = LOWER(TRIM(p.muscleName))
    AND (p.startDate IS NULL OR w.created_date >= p.startDate)
),

-- כמה סטים לכל תת־שריר
sub_counts AS (
  SELECT
    sub_muscle_id,
    sub_muscle_name,
    COUNT(*) AS setsCount
  FROM filtered_sets
  GROUP BY sub_muscle_id, sub_muscle_name
),

-- סה״כ סטים
total_counts AS (
  SELECT COALESCE(SUM(setsCount), 0) AS totalSets
  FROM sub_counts
),

-- האם להציג טבלה?
eligibility AS (
  SELECT CASE WHEN COUNT(*) >= 2 THEN 1 ELSE 0 END AS showTable
  FROM sub_counts
)

SELECT
  sc.sub_muscle_name AS subMuscleName,
  CASE
    WHEN tc.totalSets = 0 THEN 0
    ELSE CAST(ROUND(100.0 * sc.setsCount / tc.totalSets) AS INTEGER)
  END AS percentInt,
  CASE
    WHEN tc.totalSets = 0 THEN 0.0
    ELSE ROUND(1.0 * sc.setsCount / tc.totalSets, 2)
  END AS progress,
  el.showTable AS showTable
FROM sub_counts sc
CROSS JOIN total_counts tc
CROSS JOIN eligibility el
ORDER BY percentInt DESC, subMuscleName ASC;

''';
  return _readQuery(database, query, (d) => SubMuscleDistributionRow(d));
}

class SubMuscleDistributionRow extends SqliteRow {
  SubMuscleDistributionRow(Map<String, dynamic> data) : super(data);

  String get subMuscleName => data['subMuscleName'] as String;
  int get percentInt => data['percentInt'] as int;
  double get progress => data['progress'] as double;
  int get showTable => data['showTable'] as int;
}

/// END SUB MUSCLE DISTRIBUTION

/// BEGIN HISTORY 1
Future<List<History1Row>> performHistory1(
  Database database, {
  String? userId,
  String? workoutLogId,
}) {
  final query = '''
-- params:
-- ${userId} (TEXT)
-- ${workoutLogId} (INTEGER)

SELECT
  wl.id AS workout_log_id,
  COALESCE(w.name, 'Workout') AS workout_name,
  COALESCE(wl.created_at, '') AS created_at,
  COALESCE(CAST(wl.duration_seconds AS INTEGER), 0) AS duration_seconds,
  COALESCE(CAST(wl.volume AS INTEGER), 0) AS volume,

  -- רוב היחידות באימון → "Kg" או "Lbs"
  COALESCE((
    SELECT CASE
             WHEN SUM(CASE WHEN COALESCE(sl.is_kg,1)=1 THEN 1 ELSE 0 END)
                >= SUM(CASE WHEN COALESCE(sl.is_kg,1)=0 THEN 1 ELSE 0 END)
             THEN 'Kg' ELSE 'Lbs'
           END
    FROM set_log sl
    WHERE sl.workout_log_id = wl.id
      AND COALESCE(sl.is_dropset, 0) = 0
  ), 'Kg') AS unit_label,

  (
    SELECT COALESCE(CAST(COUNT(*) AS INTEGER), 0)
    FROM set_log sl
    WHERE sl.workout_log_id = wl.id
      AND COALESCE(sl.is_dropset, 0) = 0
  ) AS total_sets,

  (
    SELECT COALESCE(CAST(COUNT(DISTINCT sl.exercise_id) AS INTEGER), 0)
    FROM set_log sl
    WHERE sl.workout_log_id = wl.id
      AND COALESCE(sl.is_dropset, 0) = 0
  ) AS exercise_count,

  COALESCE((
    SELECT GROUP_CONCAT(pmg_name, ', ')
    FROM (
      SELECT DISTINCT pmg.name AS pmg_name
      FROM set_log sl
      JOIN exercise_muscle_group emg
        ON emg.exercise_id = sl.exercise_id AND emg.is_primary = 1
      JOIN muscle_group mg
        ON mg.id = emg.muscle_group_id
      JOIN primary_muscle_group pmg
        ON pmg.id = mg.primary_muscle_group_id
      WHERE sl.workout_log_id = wl.id
        AND COALESCE(sl.is_dropset, 0) = 0
      ORDER BY pmg.name
    )
  ), '') AS main_muscle_groups

FROM workout_log wl
LEFT JOIN workout w ON w.id = wl.workout_id
WHERE wl.user_id = '${userId}'
  AND wl.id = '${workoutLogId}'
LIMIT 1;

''';
  return _readQuery(database, query, (d) => History1Row(d));
}

class History1Row extends SqliteRow {
  History1Row(Map<String, dynamic> data) : super(data);

  String get mainMuscleGroups => data['main_muscle_groups'] as String;
  String get createdAt => data['created_at'] as String;
  int get durationSeconds => data['duration_seconds'] as int;
  int get volume => data['volume'] as int;
  String get workoutName => data['workout_name'] as String;
  String get workoutLogId => data['workout_log_id'] as String;
  int get exerciseCount => data['exercise_count'] as int;
  int get totalSets => data['total_sets'] as int;
  String get unitLabel => data['unit_label'] as String;
}

/// END HISTORY 1

/// BEGIN GETALLSETS
Future<List<GetAllSetsRow>> performGetAllSets(
  Database database, {
  String? workoutLogId,
}) {
  final query = '''
SELECT
  CAST(exercise_id AS INTEGER)                AS exercise_id,
  CAST(set_number  AS INTEGER)                AS set_number,

  CASE WHEN TRIM(CAST(reps AS TEXT)) = '' 
       THEN NULL
       ELSE CAST(reps AS INTEGER)
  END                                        AS reps,

  CASE WHEN TRIM(CAST(weight AS TEXT)) = ''  
       THEN NULL
       ELSE CAST(weight AS REAL)
  END                                        AS weight,

  CASE WHEN TRIM(CAST(duration_seconds AS TEXT)) = '' 
       THEN NULL
       ELSE CAST(duration_seconds AS INTEGER)
  END                                        AS duration_seconds,

  CAST(COALESCE(NULLIF(CAST(is_kg AS TEXT), ''), 1) AS INTEGER) 
                                             AS is_kg,

  -- 🔥 השדות החסרים
  CAST(COALESCE(NULLIF(CAST(is_dropset AS TEXT), ''), 0) AS INTEGER)
                                             AS is_dropset,

  CAST(COALESCE(NULLIF(CAST(drop_number AS TEXT), ''), 1) AS INTEGER)
                                             AS drop_number

FROM set_log
WHERE workout_log_id = '${workoutLogId}'

ORDER BY
  CAST(exercise_id AS INTEGER) ASC,
  CAST(set_number  AS INTEGER) ASC,
  CAST(COALESCE(drop_number, 0) AS INTEGER) ASC;

''';
  return _readQuery(database, query, (d) => GetAllSetsRow(d));
}

class GetAllSetsRow extends SqliteRow {
  GetAllSetsRow(Map<String, dynamic> data) : super(data);

  int? get durationSeconds => data['duration_seconds'] as int?;
  int get isKg => data['is_kg'] as int;
  int get exerciseId => data['exercise_id'] as int;
  int get setNumber => data['set_number'] as int;
  int? get reps => data['reps'] as int?;
  double? get weight => data['weight'] as double?;
  int? get dropNumber => data['drop_number'] as int?;
  int get isDropset => data['is_dropset'] as int;
}

/// END GETALLSETS

/// BEGIN WORKOUTCOMPARISON
Future<List<WorkoutComparisonRow>> performWorkoutComparison(
  Database database, {
  String? workoutLogIdA,
  String? workoutLogIdB,
}) {
  final query = '''
-- params: ${workoutLogIdA}, ${workoutLogIdB}

WITH
/* ====== RAW LOGS (ms ב-INTEGER) ====== */
a_log AS (
  SELECT
    TRIM(CAST(wl.id AS TEXT)) AS id,
    wl.created_at,
    CAST(COALESCE(wl.duration_seconds,0) AS INTEGER) AS ms,         -- ms
    CAST(COALESCE(wl.volume,0) AS INTEGER)           AS volume,
    COALESCE(w.name,'Workout')                       AS workout_name
  FROM workout_log wl
  LEFT JOIN workout w ON w.id = wl.workout_id
  WHERE TRIM(CAST(wl.id AS TEXT)) = TRIM('${workoutLogIdA}')
),
b_log AS (
  SELECT
    TRIM(CAST(wl.id AS TEXT)) AS id,
    wl.created_at,
    CAST(COALESCE(wl.duration_seconds,0) AS INTEGER) AS ms,         -- ms
    CAST(COALESCE(wl.volume,0) AS INTEGER)           AS volume,
    COALESCE(w.name,'Workout')                       AS workout_name
  FROM workout_log wl
  LEFT JOIN workout w ON w.id = wl.workout_id
  WHERE TRIM(CAST(wl.id AS TEXT)) = TRIM('${workoutLogIdB}')
),

/* ====== FALLBACK: סכום משכי סטים (גם ms) ====== */
a_sets_ms AS (
  SELECT TRIM(CAST(workout_log_id AS TEXT)) AS id,
         CAST(COALESCE(SUM(CAST(COALESCE(duration_seconds,0) AS INTEGER)),0) AS INTEGER) AS sum_ms
  FROM set_log
  WHERE TRIM(CAST(workout_log_id AS TEXT)) = TRIM('${workoutLogIdA}')
),
b_sets_ms AS (
  SELECT TRIM(CAST(workout_log_id AS TEXT)) AS id,
         CAST(COALESCE(SUM(CAST(COALESCE(duration_seconds,0) AS INTEGER)),0) AS INTEGER) AS sum_ms
  FROM set_log
  WHERE TRIM(CAST(workout_log_id AS TEXT)) = TRIM('${workoutLogIdB}')
),

/* ====== AGG של סטים: ספירת סטים ותרגילים (ללא דרופסט) ====== */
a_agg AS (
  SELECT
    TRIM(CAST(sl.workout_log_id AS TEXT)) AS id,
    SUM(CASE WHEN COALESCE(sl.is_dropset,0)=0 THEN 1 ELSE 0 END) AS total_sets,
    COUNT(DISTINCT CASE WHEN COALESCE(sl.is_dropset,0)=0 THEN CAST(sl.exercise_id AS INTEGER) END)
      AS exercise_count
  FROM set_log sl
  WHERE TRIM(CAST(sl.workout_log_id AS TEXT)) = TRIM('${workoutLogIdA}')
),
b_agg AS (
  SELECT
    TRIM(CAST(sl.workout_log_id AS TEXT)) AS id,
    SUM(CASE WHEN COALESCE(sl.is_dropset,0)=0 THEN 1 ELSE 0 END) AS total_sets,
    COUNT(DISTINCT CASE WHEN COALESCE(sl.is_dropset,0)=0 THEN CAST(sl.exercise_id AS INTEGER) END)
      AS exercise_count
  FROM set_log sl
  WHERE TRIM(CAST(sl.workout_log_id AS TEXT)) = TRIM('${workoutLogIdB}')
),

/* ====== A סיכום ====== */
a AS (
  SELECT
    COALESCE(al.id, TRIM('${workoutLogIdA}')) AS id,
    COALESCE(al.workout_name,'Workout')       AS workout_name,
    al.created_at,
    /* אם ms ביומן >0 נשתמש בו, אחרת fallback לסכום סטים */
    CASE WHEN COALESCE(al.ms,0) > 0 THEN al.ms ELSE COALESCE(asm.sum_ms,0) END AS ms,
    COALESCE(aag.total_sets,0)     AS total_sets,
    COALESCE(aag.exercise_count,0) AS exercise_count,
    COALESCE(al.volume,0)          AS volume
  FROM a_log al
  LEFT JOIN a_sets_ms asm ON asm.id = al.id
  LEFT JOIN a_agg    aag ON aag.id = COALESCE(al.id, TRIM('${workoutLogIdA}'))
  UNION ALL
  /* אם אין שורה ביומן כלל: נבנה מרק סכום הסטים כדי שלא נחזיר NULL */
  SELECT
    TRIM('${workoutLogIdA}')            AS id,
    'Workout'                           AS workout_name,
    NULL                                 AS created_at,
    COALESCE(asm.sum_ms,0)              AS ms,
    COALESCE(aag.total_sets,0)          AS total_sets,
    COALESCE(aag.exercise_count,0)      AS exercise_count,
    0                                    AS volume
  FROM a_sets_ms asm
  LEFT JOIN a_agg aag ON aag.id = asm.id
  WHERE NOT EXISTS(SELECT 1 FROM a_log)
  LIMIT 1
),

/* ====== B סיכום ====== */
b AS (
  SELECT
    COALESCE(bl.id, TRIM('${workoutLogIdB}')) AS id,
    COALESCE(bl.workout_name,'Workout')       AS workout_name,
    bl.created_at,
    CASE WHEN COALESCE(bl.ms,0) > 0 THEN bl.ms ELSE COALESCE(bsm.sum_ms,0) END AS ms,
    COALESCE(bag.total_sets,0)     AS total_sets,
    COALESCE(bag.exercise_count,0) AS exercise_count,
    COALESCE(bl.volume,0)          AS volume
  FROM b_log bl
  LEFT JOIN b_sets_ms bsm ON bsm.id = bl.id
  LEFT JOIN b_agg    bag ON bag.id = COALESCE(bl.id, TRIM('${workoutLogIdB}'))
  UNION ALL
  SELECT
    TRIM('${workoutLogIdB}')       AS id,
    'Workout'                      AS workout_name,
    NULL                            AS created_at,
    COALESCE(bsm.sum_ms,0)         AS ms,
    COALESCE(bag.total_sets,0)     AS total_sets,
    COALESCE(bag.exercise_count,0) AS exercise_count,
    0                               AS volume
  FROM b_sets_ms bsm
  LEFT JOIN b_agg bag ON bag.id = bsm.id
  WHERE NOT EXISTS(SELECT 1 FROM b_log)
  LIMIT 1
)

/* ====== FINAL: שורה אחת עם A, B והפרשים ====== */
SELECT
  /* ----- A ----- */
  a.id            AS a_id,
  a.workout_name  AS a_name,
  a.created_at    AS a_created_at,
  a.ms            AS a_duration_ms,
  /* שניות (עיגול), ואם 0<ms<1000 נציג 1 */
  CASE WHEN a.ms > 0 AND a.ms < 1000 THEN 1 ELSE CAST(ROUND(a.ms/1000.0) AS INTEGER) END AS a_duration_seconds,
  /* תצוגה קצרה h/m/s */
  CASE
    WHEN a.ms >= 3600000 THEN CAST(a.ms/3600000 AS INTEGER) || 'h ' || CAST((a.ms%3600000)/60000 AS INTEGER) || 'm'
    WHEN a.ms >= 60000   THEN CAST(a.ms/60000   AS INTEGER) || 'm'
    WHEN a.ms > 0        THEN CAST(CASE WHEN a.ms < 1000 THEN 1 ELSE CAST(ROUND(a.ms/1000.0) AS INTEGER) END AS TEXT) || 's'
    ELSE '0s'
  END AS a_duration_display,
  /* תצוגת HH:MM:SS */
  printf('%02d:%02d:%02d',
         CAST(a.ms/3600000 AS INTEGER),
         CAST((a.ms%3600000)/60000 AS INTEGER),
         CAST(((a.ms%60000)+500)/1000 AS INTEGER)) AS a_duration_hhmmss,
  a.total_sets        AS a_total_sets,
  a.exercise_count    AS a_exercise_count,
  a.volume            AS a_volume,

  /* ----- B ----- */
  b.id            AS b_id,
  b.workout_name  AS b_name,
  b.created_at    AS b_created_at,
  b.ms            AS b_duration_ms,
  CASE WHEN b.ms > 0 AND b.ms < 1000 THEN 1 ELSE CAST(ROUND(b.ms/1000.0) AS INTEGER) END AS b_duration_seconds,
  CASE
    WHEN b.ms >= 3600000 THEN CAST(b.ms/3600000 AS INTEGER) || 'h ' || CAST((b.ms%3600000)/60000 AS INTEGER) || 'm'
    WHEN b.ms >= 60000   THEN CAST(b.ms/60000   AS INTEGER) || 'm'
    WHEN b.ms > 0        THEN CAST(CASE WHEN b.ms < 1000 THEN 1 ELSE CAST(ROUND(b.ms/1000.0) AS INTEGER) END AS TEXT) || 's'
    ELSE '0s'
  END AS b_duration_display,
  printf('%02d:%02d:%02d',
         CAST(b.ms/3600000 AS INTEGER),
         CAST((b.ms%3600000)/60000 AS INTEGER),
         CAST(((b.ms%60000)+500)/1000 AS INTEGER)) AS b_duration_hhmmss,
  b.total_sets        AS b_total_sets,
  b.exercise_count    AS b_exercise_count,
  b.volume            AS b_volume,

  /* ----- Diffs ----- */
  (a.ms - b.ms) AS diff_duration_ms,
  CAST(ROUND((a.ms - b.ms)/1000.0)  AS INTEGER) AS diff_duration_seconds,
  CAST(ROUND((a.ms - b.ms)/60000.0) AS INTEGER) AS diff_duration_minutes,
  CASE
    WHEN ABS(a.ms - b.ms) >= 3600000 THEN CAST((a.ms - b.ms)/3600000 AS INTEGER) || 'h ' || CAST((ABS(a.ms - b.ms)%3600000)/60000 AS INTEGER) || 'm'
    WHEN ABS(a.ms - b.ms) >= 60000   THEN CAST((a.ms - b.ms)/60000   AS INTEGER) || 'm'
    WHEN ABS(a.ms - b.ms) >= 1000    THEN CAST((a.ms - b.ms)/1000    AS INTEGER) || 's'
    ELSE '0s'
  END AS diff_duration_display,

  (a.total_sets     - b.total_sets)      AS diff_total_sets,
  (a.exercise_count - b.exercise_count)  AS diff_exercise_count,
  (a.volume         - b.volume)          AS diff_volume
FROM a, b;

''';
  return _readQuery(database, query, (d) => WorkoutComparisonRow(d));
}

class WorkoutComparisonRow extends SqliteRow {
  WorkoutComparisonRow(Map<String, dynamic> data) : super(data);

  String get aId => data['a_id'] as String;
  String get aCreatedAt => data['a_created_at'] as String;
  int get aDurationSeconds => data['a_duration_seconds'] as int;
  int get aTotalSets => data['a_total_sets'] as int;
  int get aExerciseCount => data['a_exercise_count'] as int;
  int? get aVolume => data['a_volume'] as int?;
  String get bId => data['b_id'] as String;
  String get bCreatedAt => data['b_created_at'] as String;
  int get bDurationSeconds => data['b_duration_seconds'] as int;
  int get bTotalSets => data['b_total_sets'] as int;
  int get bExerciseCount => data['b_exercise_count'] as int;
  int? get bVolume => data['b_volume'] as int?;
  String get aName => data['a_name'] as String;
  String get bName => data['b_name'] as String;
  int? get diffVolume => data['diff_volume'] as int?;
  int get diffDurationMinutes => data['diff_duration_minutes'] as int;
  int get diffTotalSets => data['diff_total_sets'] as int;
  int get diffExerciseCount => data['diff_exercise_count'] as int;
  String get diffDurationDisplay => data['diff_duration_display'] as String;
  int get aDurationMs => data['a_duration_ms'] as int;
  int get bDurationMs => data['b_duration_ms'] as int;
}

/// END WORKOUTCOMPARISON

/// BEGIN COMPARE MUSCELS
Future<List<CompareMuscelsRow>> performCompareMuscels(
  Database database, {
  String? workoutLogIdB,
  String? workoutLogIdA,
}) {
  final query = '''
-- params: ${workoutLogIdA}, ${workoutLogIdB}

WITH
base_a AS (
  SELECT CAST(s.set_number AS INTEGER) AS pos, CAST(s.exercise_id AS INTEGER) AS exercise_id
  FROM set_log s
  WHERE CAST(COALESCE(s.is_dropset,0) AS INTEGER)=0
    AND TRIM(CAST(s.workout_log_id AS TEXT))=TRIM('${workoutLogIdA}')
),
per_a AS (
  SELECT mg.id AS muscle_id, mg.name AS muscle_name, CAST(COUNT(*) AS INTEGER) AS sets_for_muscle
  FROM base_a b
  JOIN exercise_muscle_group emg ON emg.exercise_id=b.exercise_id
  JOIN muscle_group mg           ON mg.id=emg.muscle_group_id
  WHERE CAST(COALESCE(emg.is_primary,1) AS INTEGER)=1
  GROUP BY mg.id, mg.name
),
total_a AS (
  SELECT CAST(COUNT(*) AS INTEGER) AS total_sets
  FROM base_a b
  JOIN exercise_muscle_group emg ON emg.exercise_id=b.exercise_id
  WHERE CAST(COALESCE(emg.is_primary,1) AS INTEGER)=1
),
pos_a AS (
  SELECT mg.id AS muscle_id, MIN(b.pos) AS pos_a
  FROM base_a b
  JOIN exercise_muscle_group emg ON emg.exercise_id=b.exercise_id
  JOIN muscle_group mg           ON mg.id=emg.muscle_group_id
  WHERE CAST(COALESCE(emg.is_primary,1) AS INTEGER)=1
  GROUP BY mg.id
),

base_b AS (
  SELECT CAST(s.set_number AS INTEGER) AS pos, CAST(s.exercise_id AS INTEGER) AS exercise_id
  FROM set_log s
  WHERE CAST(COALESCE(s.is_dropset,0) AS INTEGER)=0
    AND TRIM(CAST(s.workout_log_id AS TEXT))=TRIM('${workoutLogIdB}')
),
per_b AS (
  SELECT mg.id AS muscle_id, mg.name AS muscle_name, CAST(COUNT(*) AS INTEGER) AS sets_for_muscle
  FROM base_b b
  JOIN exercise_muscle_group emg ON emg.exercise_id=b.exercise_id
  JOIN muscle_group mg           ON mg.id=emg.muscle_group_id
  WHERE CAST(COALESCE(emg.is_primary,1) AS INTEGER)=1
  GROUP BY mg.id, mg.name
),
total_b AS (
  SELECT CAST(COUNT(*) AS INTEGER) AS total_sets
  FROM base_b b
  JOIN exercise_muscle_group emg ON emg.exercise_id=b.exercise_id
  WHERE CAST(COALESCE(emg.is_primary,1) AS INTEGER)=1
),
pos_b AS (
  SELECT mg.id AS muscle_id, MIN(b.pos) AS pos_b
  FROM base_b b
  JOIN exercise_muscle_group emg ON emg.exercise_id=b.exercise_id
  JOIN muscle_group mg           ON mg.id=emg.muscle_group_id
  WHERE CAST(COALESCE(emg.is_primary,1) AS INTEGER)=1
  GROUP BY mg.id
),

muscles AS (
  SELECT muscle_id FROM per_a
  UNION
  SELECT muscle_id FROM per_b
),
names AS (
  SELECT muscle_id, MAX(muscle_name) AS muscle_name
  FROM (
    SELECT muscle_id, muscle_name FROM per_a
    UNION ALL
    SELECT muscle_id, muscle_name FROM per_b
  )
  GROUP BY muscle_id
),
ordering AS (
  SELECT
    m.muscle_id,
    pa.pos_a,
    pb.pos_b,
    CAST(CASE WHEN pa.pos_a IS NOT NULL THEN pa.pos_a
              ELSE 1000000 + COALESCE(pb.pos_b,0) END AS INTEGER) AS order_key
  FROM muscles m
  LEFT JOIN pos_a pa ON pa.muscle_id=m.muscle_id
  LEFT JOIN pos_b pb ON pb.muscle_id=m.muscle_id
)

SELECT
  n.muscle_name AS name,
  CAST(COALESCE(pa.sets_for_muscle,0) AS INTEGER) AS sets,
  CAST(COALESCE(ta.total_sets,0) AS INTEGER)      AS total,
  CAST(CASE WHEN COALESCE(ta.total_sets,0)=0 THEN 0.0
            ELSE (COALESCE(pa.sets_for_muscle,0)*1.0)/ta.total_sets END AS REAL) AS ratio,
  CAST(ROUND(100.0 * (CASE WHEN COALESCE(ta.total_sets,0)=0 THEN 0.0
                           ELSE (COALESCE(pa.sets_for_muscle,0)*1.0)/ta.total_sets END)) AS INTEGER) AS ratio_percent,
  CAST(ROUND(100.0 * (CASE WHEN COALESCE(ta.total_sets,0)=0 THEN 0.0
                           ELSE (COALESCE(pa.sets_for_muscle,0)*1.0)/ta.total_sets END)) AS INTEGER) || '%' AS percent_str,
  CAST(1 AS INTEGER) AS is_workout_a,
  o.order_key
FROM muscles m
LEFT JOIN per_a   pa ON pa.muscle_id=m.muscle_id
LEFT JOIN total_a ta ON 1=1
JOIN ordering     o  ON o.muscle_id=m.muscle_id
LEFT JOIN names   n  ON n.muscle_id=m.muscle_id
WHERE COALESCE(pa.sets_for_muscle,0) > 0

UNION ALL

SELECT
  n.muscle_name AS name,
  CAST(COALESCE(pb.sets_for_muscle,0) AS INTEGER) AS sets,
  CAST(COALESCE(tb.total_sets,0) AS INTEGER)      AS total,
  CAST(CASE WHEN COALESCE(tb.total_sets,0)=0 THEN 0.0
            ELSE (COALESCE(pb.sets_for_muscle,0)*1.0)/tb.total_sets END AS REAL) AS ratio,
  CAST(ROUND(100.0 * (CASE WHEN COALESCE(tb.total_sets,0)=0 THEN 0.0
                           ELSE (COALESCE(pb.sets_for_muscle,0)*1.0)/tb.total_sets END)) AS INTEGER) AS ratio_percent,
  CAST(ROUND(100.0 * (CASE WHEN COALESCE(tb.total_sets,0)=0 THEN 0.0
                           ELSE (COALESCE(pb.sets_for_muscle,0)*1.0)/tb.total_sets END)) AS INTEGER) || '%' AS percent_str,
  CAST(0 AS INTEGER) AS is_workout_a,
  o.order_key
FROM muscles m
LEFT JOIN per_b   pb ON pb.muscle_id=m.muscle_id
LEFT JOIN total_b tb ON 1=1
JOIN ordering     o  ON o.muscle_id=m.muscle_id
LEFT JOIN names   n  ON n.muscle_id=m.muscle_id
WHERE COALESCE(pb.sets_for_muscle,0) > 0

ORDER BY o.order_key ASC, is_workout_a DESC, name ASC;

''';
  return _readQuery(database, query, (d) => CompareMuscelsRow(d));
}

class CompareMuscelsRow extends SqliteRow {
  CompareMuscelsRow(Map<String, dynamic> data) : super(data);

  String get name => data['name'] as String;
  int get sets => data['sets'] as int;
  double get ratio => data['ratio'] as double;
  String get percentStr => data['percent_str'] as String;
  int get isWorkoutA => data['is_workout_a'] as int;
  int get orderKey => data['order_key'] as int;
}

/// END COMPARE MUSCELS

/// BEGIN EXERCISES COMPARISON
Future<List<ExercisesComparisonRow>> performExercisesComparison(
  Database database, {
  String? workoutLogIdA,
  String? workoutLogIdB,
}) {
  final query = '''
-- params: ${workoutLogIdA}, ${workoutLogIdB}

WITH
/* ---------- A ---------- */
base_a AS (
  SELECT
    CAST(s.set_number AS INTEGER) AS pos,
    s.exercise_id,
    e.name AS exercise_name,
    COALESCE(e.is_time_based, 0)  AS is_time_based,
    COALESCE(e.is_bodyweight, 0)  AS is_bodyweight,
    COALESCE(e.is_assisted, 0)    AS is_assisted,
    COALESCE(s.reps, 0)           AS reps,
    COALESCE(s.weight, 0)         AS weight,
    COALESCE(s.duration_seconds, 0) AS dur_sec,
    COALESCE(s.is_kg, 1)          AS is_kg,
    COALESCE(s.is_dropset, 0)     AS is_dropset
  FROM set_log s
  JOIN exercise e ON e.id = s.exercise_id
  WHERE TRIM(CAST(s.workout_log_id AS TEXT)) = TRIM('${workoutLogIdA}')
),
agg_a AS (
  SELECT
    exercise_id,
    MAX(exercise_name) AS exercise_name,
    MAX(is_time_based) AS is_time_based,
    MAX(is_bodyweight) AS is_bodyweight,
    MAX(is_assisted)   AS is_assisted,
    COUNT(CASE WHEN is_dropset = 0 THEN 1 END) AS sets_count,
    CASE WHEN SUM(CASE WHEN weight > 0 THEN 1 END) > 0 THEN 1 ELSE 0 END AS has_weighted,
    SUM(reps) AS sum_reps,
    SUM(CASE WHEN weight > 0 THEN reps * weight ELSE 0 END) AS sum_weighted_volume,
    SUM(dur_sec) AS sum_dur_sec,
    CASE
      WHEN SUM(CASE WHEN is_dropset = 0 AND is_kg = 1 THEN 1 END)
         >= SUM(CASE WHEN is_dropset = 0 AND is_kg = 0 THEN 1 END)
      THEN 'kg' ELSE 'lbs'
    END AS unit_label
  FROM base_a
  GROUP BY exercise_id
),
fmt_a AS (
  SELECT
    CAST(exercise_id AS INTEGER) AS exercise_id,
    exercise_name,
    LOWER(TRIM(
      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(exercise_name,'(',''),')',''),'-',' '),',',''), '  ',' ')
    )) AS name_key,
    sets_count,
    CASE
      WHEN is_time_based = 1
        THEN printf('%02d:%02d', CAST(sum_dur_sec AS INTEGER)/60, CAST(sum_dur_sec AS INTEGER)%60)
      WHEN is_assisted = 1
        THEN CAST(sum_reps AS TEXT) || ' Reps'
      WHEN is_bodyweight = 1 AND has_weighted = 0
        THEN CAST(sum_reps AS TEXT) || ' Reps'
      ELSE
        CASE
          WHEN sum_weighted_volume >= 1000
            THEN printf('%.1fk %s', sum_weighted_volume/1000.0, unit_label)
          ELSE printf('%d %s', CAST(sum_weighted_volume AS INTEGER), unit_label)
        END
    END AS total_str
  FROM agg_a
),
pos_a AS (
  SELECT f.name_key, MIN(b.pos) AS pos_a
  FROM base_a b
  JOIN fmt_a f ON f.exercise_id = b.exercise_id
  GROUP BY f.name_key
),

/* ---------- B ---------- */
base_b AS (
  SELECT
    CAST(s.set_number AS INTEGER) AS pos,
    s.exercise_id,
    e.name AS exercise_name,
    COALESCE(e.is_time_based, 0)  AS is_time_based,
    COALESCE(e.is_bodyweight, 0)  AS is_bodyweight,
    COALESCE(e.is_assisted, 0)    AS is_assisted,
    COALESCE(s.reps, 0)           AS reps,
    COALESCE(s.weight, 0)         AS weight,
    COALESCE(s.duration_seconds, 0) AS dur_sec,
    COALESCE(s.is_kg, 1)          AS is_kg,
    COALESCE(s.is_dropset, 0)     AS is_dropset
  FROM set_log s
  JOIN exercise e ON e.id = s.exercise_id
  WHERE TRIM(CAST(s.workout_log_id AS TEXT)) = TRIM('${workoutLogIdB}')
),
agg_b AS (
  SELECT
    exercise_id,
    MAX(exercise_name) AS exercise_name,
    MAX(is_time_based) AS is_time_based,
    MAX(is_bodyweight) AS is_bodyweight,
    MAX(is_assisted)   AS is_assisted,
    COUNT(CASE WHEN is_dropset = 0 THEN 1 END) AS sets_count,
    CASE WHEN SUM(CASE WHEN weight > 0 THEN 1 END) > 0 THEN 1 ELSE 0 END AS has_weighted,
    SUM(reps) AS sum_reps,
    SUM(CASE WHEN weight > 0 THEN reps * weight ELSE 0 END) AS sum_weighted_volume,
    SUM(dur_sec) AS sum_dur_sec,
    CASE
      WHEN SUM(CASE WHEN is_dropset = 0 AND is_kg = 1 THEN 1 END)
         >= SUM(CASE WHEN is_dropset = 0 AND is_kg = 0 THEN 1 END)
      THEN 'kg' ELSE 'lbs'
    END AS unit_label
  FROM base_b
  GROUP BY exercise_id
),
fmt_b AS (
  SELECT
    CAST(exercise_id AS INTEGER) AS exercise_id,
    exercise_name,
    LOWER(TRIM(
      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(exercise_name,'(',''),')',''),'-',' '),',',''), '  ',' ')
    )) AS name_key,
    sets_count,
    CASE
      WHEN is_time_based = 1
        THEN printf('%02d:%02d', CAST(sum_dur_sec AS INTEGER)/60, CAST(sum_dur_sec AS INTEGER)%60)
      WHEN is_assisted = 1
        THEN CAST(sum_reps AS TEXT) || ' Reps'
      WHEN is_bodyweight = 1 AND has_weighted = 0
        THEN CAST(sum_reps AS TEXT) || ' Reps'
      ELSE
        CASE
          WHEN sum_weighted_volume >= 1000
            THEN printf('%.1fk %s', sum_weighted_volume/1000.0, unit_label)
          ELSE printf('%d %s', CAST(sum_weighted_volume AS INTEGER), unit_label)
        END
    END AS total_str
  FROM agg_b
),
pos_b AS (
  SELECT f.name_key, MIN(b.pos) AS pos_b
  FROM base_b b
  JOIN fmt_b f ON f.exercise_id = b.exercise_id
  GROUP BY f.name_key
),

/* ---------- ordering ---------- */
keys AS (
  SELECT name_key FROM fmt_a
  UNION
  SELECT name_key FROM fmt_b
),
ordering AS (
  SELECT
    k.name_key,
    CAST(
      CASE
        WHEN a.pos_a IS NOT NULL THEN a.pos_a
        ELSE 1000000 + COALESCE(b.pos_b,0)
      END AS INTEGER
    ) AS order_key
  FROM keys k
  LEFT JOIN pos_a a ON a.name_key = k.name_key
  LEFT JOIN pos_b b ON b.name_key = k.name_key
)

/* ---------- output ---------- */
SELECT
  a.exercise_name AS name,
  a.total_str || ' (' || a.sets_count || ' sets)' AS display,
  COALESCE(a.sets_count, 0) AS sets,
  1 AS is_workout_a,
  o.order_key
FROM fmt_a a
JOIN ordering o ON o.name_key = a.name_key

UNION ALL

SELECT
  b.exercise_name AS name,
  b.total_str || ' (' || b.sets_count || ' sets)' AS display,
  COALESCE(b.sets_count, 0) AS sets,
  0 AS is_workout_a,
  o.order_key
FROM fmt_b b
JOIN ordering o ON o.name_key = b.name_key

ORDER BY order_key ASC, is_workout_a DESC, name ASC;

''';
  return _readQuery(database, query, (d) => ExercisesComparisonRow(d));
}

class ExercisesComparisonRow extends SqliteRow {
  ExercisesComparisonRow(Map<String, dynamic> data) : super(data);

  String get name => data['name'] as String;
  String get display => data['display'] as String;
  int get sets => data['sets'] as int;
  int get isWorkoutA => data['is_workout_a'] as int;
  int get orderKey => data['order_key'] as int;
}

/// END EXERCISES COMPARISON

/// BEGIN EXERCISESFOREDIT
Future<List<ExercisesForEditRow>> performExercisesForEdit(
  Database database, {
  String? workoutLogId,
}) {
  final query = '''
-- ${workoutLogId}

WITH ex AS (
  SELECT DISTINCT
    s.exercise_id,
    e.name AS exercise_name,
    COALESCE(e.is_bodyweight, 0) AS is_bodyweight,
    COALESCE(e.is_assisted, 0)   AS is_assisted
  FROM set_log s
  LEFT JOIN exercise e
    ON e.id = s.exercise_id
  WHERE s.workout_log_id = '${workoutLogId}'
)

SELECT
  json_group_array(
    json_object(
      'exerciseId',  ex.exercise_id,
      'name',        ex.exercise_name,
      'isBodyweight', ex.is_bodyweight,
      'isAssisted',   ex.is_assisted,

      -- ברירת מחדל להצגת שדה משקל בסט חדש
      'defaultWeightedNewSet',
        CASE
          WHEN ex.is_bodyweight = 1 OR ex.is_assisted = 1 THEN 0
          ELSE 1
        END,

      -- הסט הבא
      'nextSetNumber',
        (SELECT COUNT(*)
         FROM set_log s0
         WHERE s0.workout_log_id = '${workoutLogId}'
           AND s0.exercise_id    = ex.exercise_id) + 1,

      -- הסטים
      'sets',
        COALESCE((
          SELECT json_group_array(
                   json_object(
                     'setNumber', rn,
                     'reps',              s.reps,
                     'weight',            s.weight,
                     'duration_seconds',  s.duration_seconds,
                     'isKg',              COALESCE(s.is_kg, 1),
                     'isDropset',         COALESCE(s.is_dropset, 0),
                     'weighted',
                       CASE
                         WHEN COALESCE(s.weight, 0) > 0
                              AND ex.is_assisted = 0
                         THEN 1 ELSE 0
                       END
                   )
                 )
          FROM (
            SELECT
              s2.*,
              (
                SELECT COUNT(*)
                FROM set_log z
                WHERE z.workout_log_id = s2.workout_log_id
                  AND z.exercise_id    = s2.exercise_id
                  AND (
                        COALESCE(z.set_number, 0) < COALESCE(s2.set_number, 0)
                        OR (
                             COALESCE(z.set_number, 0) = COALESCE(s2.set_number, 0)
                             AND z.id <= s2.id
                           )
                      )
              ) AS rn
            FROM set_log s2
            WHERE s2.workout_log_id = '${workoutLogId}'
              AND s2.exercise_id    = ex.exercise_id
            ORDER BY COALESCE(s2.set_number, 0), s2.id
          ) s
        ), json('[]'))
    )
  ) AS exercises
FROM ex
ORDER BY ex.exercise_name ASC;

''';
  return _readQuery(database, query, (d) => ExercisesForEditRow(d));
}

class ExercisesForEditRow extends SqliteRow {
  ExercisesForEditRow(Map<String, dynamic> data) : super(data);

  List<dynamic>? get exercises => data['exercises'] as List<dynamic>?;
}

/// END EXERCISESFOREDIT

/// BEGIN GETMUSCLES
Future<List<GetMusclesRow>> performGetMuscles(
  Database database,
) {
  final query = '''
SELECT 
  id, 
  name 
FROM muscle_group 
ORDER BY name;

''';
  return _readQuery(database, query, (d) => GetMusclesRow(d));
}

class GetMusclesRow extends SqliteRow {
  GetMusclesRow(Map<String, dynamic> data) : super(data);

  int get id => data['id'] as int;
  String get name => data['name'] as String;
}

/// END GETMUSCLES

/// BEGIN CORRECTEDGETEXERCICESIMP
Future<List<CorrectedGetExerciceSimpRow>> performCorrectedGetExerciceSimp(
  Database database, {
  String? workoutID,
}) {
  final query = '''
SELECT
  we.id,
  we.exercise_id,
  we."order",
  e.name AS exercise_name,
  COALESCE(e.is_bodyweight, 0) AS is_bodyweight,   -- 0/1
  CASE WHEN COALESCE(e.is_bodyweight, 0) = 1 THEN 0 ELSE 1 END AS weighted_default -- 0/1: BW→0, others→1
FROM workout_exercise AS we
JOIN exercise AS e ON e.id = we.exercise_id
WHERE we.workout_id = '${workoutID}'
ORDER BY we."order", we.id;
''';
  return _readQuery(database, query, (d) => CorrectedGetExerciceSimpRow(d));
}

class CorrectedGetExerciceSimpRow extends SqliteRow {
  CorrectedGetExerciceSimpRow(Map<String, dynamic> data) : super(data);

  String get id => data['id'] as String;
  int get exerciseId => data['exercise_id'] as int;
  int get order => data['order'] as int;
  String get exerciseName => data['exercise_name'] as String;
  int get isBodyweight => data['is_bodyweight'] as int;
  int get weightedDefault => data['weighted_default'] as int;
}

/// END CORRECTEDGETEXERCICESIMP

/// BEGIN CORRECTEDPREVIOSSET
Future<List<CorrectedPreviosSetRow>> performCorrectedPreviosSet(
  Database database, {
  int? exerciseId,
  int? setNumber,
  String? userId,
}) {
  final query = '''
WITH filtered_sets AS (
  SELECT
    CAST(set_number AS INTEGER) AS set_number,
    CASE 
      WHEN reps IS NULL OR TRIM(CAST(reps AS TEXT)) = '' 
      THEN NULL 
      ELSE CAST(reps AS INTEGER) 
    END AS reps,
    CASE 
      WHEN weight IS NULL OR TRIM(CAST(weight AS TEXT)) = '' 
      THEN NULL 
      ELSE CAST(weight AS REAL) 
    END AS weight,
    CASE 
      WHEN duration_seconds IS NULL OR TRIM(CAST(duration_seconds AS TEXT)) = '' 
      THEN NULL 
      ELSE CAST(duration_seconds AS INTEGER) 
    END AS duration_seconds,
    COALESCE(CAST(is_kg AS INTEGER), 1) AS is_kg,
    created_at,
    rowid
  FROM set_log
  WHERE CAST(exercise_id AS INTEGER) = $exerciseId
    AND CAST(set_number AS INTEGER) = $setNumber
    AND COALESCE(CAST(is_dropset AS INTEGER), 0) = 0
    AND user_id = '$userId'
    ),
parsed_timestamps AS (
  SELECT 
    reps,
    weight,
    duration_seconds,
    is_kg,
    rowid,
    CASE
      WHEN typeof(created_at) IN ('integer', 'real') THEN
        CASE 
          WHEN CAST(created_at AS REAL) >= 1000000000000.0
          THEN CAST(created_at AS REAL) / 1000.0
          ELSE CAST(created_at AS REAL)
        END
      
      WHEN typeof(created_at) = 'text' 
           AND LENGTH(TRIM(CAST(created_at AS TEXT))) > 0
           AND TRIM(CAST(created_at AS TEXT)) GLOB '[0-9]*[0-9]' THEN
        CASE 
          WHEN CAST(created_at AS REAL) >= 1000000000000.0
          THEN CAST(created_at AS REAL) / 1000.0
          ELSE CAST(created_at AS REAL)
        END
      
      WHEN typeof(created_at) = 'text'
           AND CAST(created_at AS TEXT) LIKE '____-__-%' THEN
        CAST(STRFTIME('%s', 
          SUBSTR(
            REPLACE(CAST(created_at AS TEXT), 'T', ' '),
            1, 
            19
          )
        ) AS REAL)
      
      ELSE NULL
    END AS sort_key
  FROM filtered_sets
),
most_recent AS (
  SELECT 
    reps,
    weight,
    duration_seconds,
    is_kg
  FROM parsed_timestamps
  WHERE sort_key IS NOT NULL
  ORDER BY sort_key DESC, rowid DESC
  LIMIT 1
)
SELECT 
  COALESCE(
    (SELECT reps FROM most_recent),
    NULL
  ) AS reps,
  COALESCE(
    (SELECT weight FROM most_recent),
    NULL
  ) AS weight,
  COALESCE(
    (SELECT duration_seconds FROM most_recent),
    NULL
  ) AS duration_seconds,
  COALESCE(
    (SELECT is_kg FROM most_recent),
    1
  ) AS is_kg;
''';
  return _readQuery(database, query, (d) => CorrectedPreviosSetRow(d));
}

class CorrectedPreviosSetRow extends SqliteRow {
  CorrectedPreviosSetRow(Map<String, dynamic> data) : super(data);

  int? get reps => data['reps'] as int?;
  double? get weight => data['weight'] as double?;
  int? get durationeconds => data['durationeconds'] as int?;
  int get isKg => data['is_kg'] as int;
}

/// END CORRECTEDPREVIOSSET

/// BEGIN CORRECTEDLATESTWORKOUTHOME
Future<List<CorrectedLatestWorkoutHomeRow>> performCorrectedLatestWorkoutHome(
  Database database, {
  String? userId,
}) {
  final query = '''
WITH last_wl AS (
    SELECT wl.id, wl.created_at
    FROM workout_log wl
    WHERE wl.user_id = '${userId}'
    -- אם זה סינגל-יוזר, אפשר להסיר
    ORDER BY wl.created_at DESC
    LIMIT 1
)
SELECT
    lw.id AS workout_log_id,
    lw.created_at AS created_at,
    (
        SELECT COUNT(*)
        FROM set_log s
        WHERE s.workout_log_id = lw.id
          AND COALESCE(s.is_dropset, 0) = 0
    ) AS total_sets,
    COALESCE((
        SELECT group_concat(pmg_name, ', ')
        FROM (
            SELECT DISTINCT pmg.name AS pmg_name
            FROM set_log sl
            JOIN exercise_muscle_group emg
              ON emg.exercise_id = sl.exercise_id
             AND COALESCE(emg.is_primary, 1) = 1
            JOIN muscle_group mg
              ON mg.id = emg.muscle_group_id
            JOIN primary_muscle_group pmg
              ON pmg.id = mg.primary_muscle_group_id
            WHERE sl.workout_log_id = lw.id
              AND COALESCE(sl.is_dropset, 0) = 0
            ORDER BY pmg_name
        ) x
    ), '') AS main_muscle_groups
FROM last_wl lw;

''';
  return _readQuery(database, query, (d) => CorrectedLatestWorkoutHomeRow(d));
}

class CorrectedLatestWorkoutHomeRow extends SqliteRow {
  CorrectedLatestWorkoutHomeRow(Map<String, dynamic> data) : super(data);

  int get totalSets => data['total_sets'] as int;
  String get createdAt => data['created_at'] as String;
  String get workoutLogId => data['workout_log_id'] as String;
  String get mainMuscleGroups => data['main_muscle_groups'] as String;
}

/// END CORRECTEDLATESTWORKOUTHOME

/// BEGIN GETWORKOUTLOG
Future<List<GetWorkoutLogRow>> performGetWorkoutLog(
  Database database, {
  String? workoutlogid,
}) {
  final query = '''
SELECT *
FROM workout_log
WHERE id = '${workoutlogid}'
''';
  return _readQuery(database, query, (d) => GetWorkoutLogRow(d));
}

class GetWorkoutLogRow extends SqliteRow {
  GetWorkoutLogRow(Map<String, dynamic> data) : super(data);

  String get createdAt => data['created_at'] as String;
  int get durationSeconds => data['duration_seconds'] as int;
}

/// END GETWORKOUTLOG

/// BEGIN VOLUMEONLY
Future<List<VolumeOnlyRow>> performVolumeOnly(
  Database database, {
  String? workoutLogId,
}) {
  final query = '''
SELECT 
  CAST(
    COALESCE(
      SUM(
        CAST(COALESCE(sl.reps, 0) AS REAL) *
        CAST(
          CASE
            WHEN sl.weight IS NULL OR TRIM(sl.weight) = '' THEN 0

            WHEN INSTR(TRIM(sl.weight), ' ') > 0
              THEN SUBSTR(TRIM(sl.weight), 1, INSTR(TRIM(sl.weight), ' ') - 1)

            WHEN LOWER(TRIM(sl.weight)) LIKE '%kg'
              THEN SUBSTR(TRIM(sl.weight), 1, LENGTH(TRIM(sl.weight)) - 2)

            WHEN LOWER(TRIM(sl.weight)) LIKE '%lbs'
              THEN SUBSTR(TRIM(sl.weight), 1, LENGTH(TRIM(sl.weight)) - 3)

            ELSE TRIM(sl.weight)
          END
        AS REAL)
      ),
      0.0
    )
  AS REAL) AS total_volume
FROM set_log sl
JOIN exercise e
  ON e.id = sl.exercise_id
WHERE sl.workout_log_id = '${workoutLogId}'
  AND e.is_assisted = 0;


''';
  return _readQuery(database, query, (d) => VolumeOnlyRow(d));
}

class VolumeOnlyRow extends SqliteRow {
  VolumeOnlyRow(Map<String, dynamic> data) : super(data);

  double get totalVolume => data['total_volume'] as double;
}

/// END VOLUMEONLY

/// BEGIN EXERCISESANDDURATION
Future<List<ExercisesAndDurationRow>> performExercisesAndDuration(
  Database database, {
  String? workoutLogId,
}) {
  final query = '''
WITH exercise_ids AS (
  SELECT DISTINCT exercise_id
  FROM set_log
  WHERE workout_log_id = '${workoutLogId}'
)

SELECT
  COALESCE(w.duration_seconds, 0) AS duration_millis,
  (SELECT COUNT(*) FROM exercise_ids) AS exercises_count
FROM workout_log w
WHERE w.id = '${workoutLogId}';

''';
  return _readQuery(database, query, (d) => ExercisesAndDurationRow(d));
}

class ExercisesAndDurationRow extends SqliteRow {
  ExercisesAndDurationRow(Map<String, dynamic> data) : super(data);

  int get exercisesCount => data['exercises_count'] as int;
  int get durationMillis => data['duration_millis'] as int;
}

/// END EXERCISESANDDURATION

/// BEGIN GETEXERCISESMETADATAROW
Future<List<GetExercisesMetadataRowRow>> performGetExercisesMetadataRow(
  Database database, {
  List<int>? exerciseIdsList,
}) {
  final exerciseIds = exerciseIdsList;
  final query = '''
SELECT
  e.id AS exercise_id,
  e.name AS name,
  CAST(e.is_bodyweight AS INTEGER) AS is_bodyweight,
  CAST(e.is_timed AS INTEGER)      AS is_timed,
  e.exercise_type AS exercise_type,
  e.equipment     AS equipment
FROM exercise_list e
WHERE e.id IN (${exerciseIds});

''';
  return _readQuery(database, query, (d) => GetExercisesMetadataRowRow(d));
}

class GetExercisesMetadataRowRow extends SqliteRow {
  GetExercisesMetadataRowRow(Map<String, dynamic> data) : super(data);

  int get exerciseId => data['exercise_id'] as int;
  int get isBodyweight => data['is_bodyweight'] as int;
  int get isTimed => data['is_timed'] as int;
  String get exerciseType => data['exercise_type'] as String;
  String get equipment => data['equipment'] as String;
}

/// END GETEXERCISESMETADATAROW

/// BEGIN UNAMEDWORKOUTS
Future<List<UnamedWorkoutsRow>> performUnamedWorkouts(
  Database database, {
  String? userId,
}) {
  final query = '''
SELECT COUNT(*) AS unnamed_count
FROM workout
WHERE user_id = '${userId}'
  AND is_deleted = 0
  AND name LIKE 'Unnamed Workout%';

''';
  return _readQuery(database, query, (d) => UnamedWorkoutsRow(d));
}

class UnamedWorkoutsRow extends SqliteRow {
  UnamedWorkoutsRow(Map<String, dynamic> data) : super(data);

  int get unnamedCount => data['unnamed_count'] as int;
}

/// END UNAMEDWORKOUTS

/// BEGIN VOLUMEOVERVIEWWITHRANGE
Future<List<VolumeOverviewWithRangeRow>> performVolumeOverviewWithRange(
  Database database, {
  String? userId,
  String? rangeLabel,
}) {
  final query = '''
WITH bounds AS (
  SELECT
    CASE '${rangeLabel}'
      WHEN 'Last 7 days'  THEN datetime('now','localtime','-7 days')
      WHEN 'Last 30 days' THEN datetime('now','localtime','-30 days')
      WHEN 'Last 90 days' THEN datetime('now','localtime','-90 days')
      ELSE NULL
    END AS startDate
),

workout_volume AS (
  SELECT
    wl.id AS workoutLogId,
    wl.created_at AS workoutDate,
    SUM(
      CASE
        WHEN IFNULL(s.weight, 0) > 0
         AND IFNULL(s.reps,   0) > 0
          THEN s.weight * s.reps
        ELSE 0
      END
    ) AS workoutVolume
  FROM workout_log wl
  JOIN set_log s
    ON s.workout_log_id = wl.id
  JOIN bounds
  WHERE wl.user_id = '${userId}'
    AND (
      bounds.startDate IS NULL
      OR datetime(replace(wl.created_at,' ','T')) >= datetime(bounds.startDate)
    )
  GROUP BY wl.id, wl.created_at
)

SELECT
  workoutLogId,
  workoutDate,
  ROUND(workoutVolume, 1) AS workoutVolume
FROM workout_volume
WHERE workoutVolume > 0
ORDER BY datetime(replace(workoutDate,' ','T')) ASC;

''';
  return _readQuery(database, query, (d) => VolumeOverviewWithRangeRow(d));
}

class VolumeOverviewWithRangeRow extends SqliteRow {
  VolumeOverviewWithRangeRow(Map<String, dynamic> data) : super(data);

  String get workoutDate => data['workoutDate'] as String;
  double get workoutVolume => data['workoutVolume'] as double;
}

/// END VOLUMEOVERVIEWWITHRANGE

/// BEGIN GETEXERCISESETSFORWORKOUT
Future<List<GetExerciseSetsForWorkoutRow>> performGetExerciseSetsForWorkout(
  Database database, {
  String? workoutId,
}) {
  final query = '''
SELECT
  es.id,
  es.workout_id,
  es.workout_exercise_id,
  es.set_number,
  es.drop_number,
  es.target_reps,
  es.is_warmup,
  es.is_dropset,
  es.weighted,          -- כוונת משקל (0/1)
  es.duration_seconds
FROM exercise_sets AS es
WHERE es.workout_id = '${workoutId}'
ORDER BY 
  es.workout_exercise_id,
  es.set_number,
  COALESCE(es.drop_number, 0);

''';
  return _readQuery(database, query, (d) => GetExerciseSetsForWorkoutRow(d));
}

class GetExerciseSetsForWorkoutRow extends SqliteRow {
  GetExerciseSetsForWorkoutRow(Map<String, dynamic> data) : super(data);

  String get id => data['id'] as String;
  String get workoutId => data['workout_id'] as String;
  int get setNumber => data['set_number'] as int;
  int? get dropNumber => data['drop_number'] as int?;
  int? get targetReps => data['target_reps'] as int?;
  int get isWarmup => data['is_warmup'] as int;
  int get isDropset => data['is_dropset'] as int;
  String get workoutExerciseId => data['workout_exercise_id'] as String;
  int get weighted => data['weighted'] as int;
  int? get durationSeconds => data['duration_seconds'] as int?;
}

/// END GETEXERCISESETSFORWORKOUT

/// BEGIN WORKOUTCOUNTSIMPLE
Future<List<WorkoutCountSimpleRow>> performWorkoutCountSimple(
  Database database, {
  String? userId,
}) {
  final query = '''
SELECT
  wl.id AS id,
  wl.created_at AS created_at,
  CAST(COALESCE(NULLIF(wl.volume, ''), 0) AS DOUBLE) AS volume
FROM workout_log wl
WHERE wl.user_id = '${userId}'
ORDER BY wl.created_at DESC;

''';
  return _readQuery(database, query, (d) => WorkoutCountSimpleRow(d));
}

class WorkoutCountSimpleRow extends SqliteRow {
  WorkoutCountSimpleRow(Map<String, dynamic> data) : super(data);

  double? get volume => data['volume'] as double?;
  String get createdAt => data['created_at'] as String;
  String get id => data['id'] as String;
}

/// END WORKOUTCOUNTSIMPLE

/// BEGIN VOLUMEBYTIME
Future<List<VolumeByTimeRow>> performVolumeByTime(
  Database database, {
  String? timeRange,
  String? userId,
}) {
  final query = '''
WITH bounds AS (
  SELECT
    CASE '${timeRange}'
      WHEN 'Last 7 days'  THEN datetime('now','localtime','-7 days')
      WHEN 'Last 30 days' THEN datetime('now','localtime','-30 days')
      WHEN 'Last 90 days' THEN datetime('now','localtime','-90 days')
      ELSE datetime('1970-01-01')
    END AS from_ts,
    CASE '${timeRange}'
      WHEN 'All' THEN datetime('9999-12-31')
      ELSE datetime('now','localtime')
    END AS to_ts
),

workouts AS (
  SELECT
    wl.id,
    CAST(
      COALESCE(
        wl.volume,
        (
          SELECT SUM(
            CASE
              WHEN IFNULL(s.weight,0) > 0
                THEN IFNULL(s.weight,0) * IFNULL(s.reps,0)
              ELSE 0
            END
          )
          FROM set_log s
          WHERE s.workout_log_id = wl.id
        )
      ) AS INTEGER
    ) AS workout_volume
  FROM workout_log wl
  JOIN bounds b
  WHERE wl.user_id = '${userId}'
    AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
    AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
),

agg AS (
  SELECT
    CAST(COALESCE(SUM(workout_volume), 0) AS INTEGER) AS total_volume,
    CAST(COALESCE(COUNT(id), 0) AS INTEGER)           AS workout_count
  FROM workouts
)

SELECT
  a.total_volume,
  a.workout_count
FROM (SELECT 1) anchor
LEFT JOIN agg a ON 1 = 1;

''';
  return _readQuery(database, query, (d) => VolumeByTimeRow(d));
}

class VolumeByTimeRow extends SqliteRow {
  VolumeByTimeRow(Map<String, dynamic> data) : super(data);

  int get totalVolume => data['total_volume'] as int;
}

/// END VOLUMEBYTIME

/// BEGIN VOLUMEFORMUSCLETIME
Future<List<VolumeForMuscleTimeRow>> performVolumeForMuscleTime(
  Database database, {
  String? rangeLabel,
  String? muscleName,
  String? userId,
}) {
  final query = '''
WITH params AS (
  SELECT
    '${userId}'     AS userId,
    '${muscleName}' AS muscleName,
    '${rangeLabel}' AS rangeLabel,
    CASE '${rangeLabel}'
      WHEN 'Last 7 days'  THEN DATE('now','-7 days')
      WHEN 'Last 30 days' THEN DATE('now','-30 days')
      WHEN 'Last 90 days' THEN DATE('now','-90 days')
      ELSE NULL
    END AS startDate
),
filtered_sets AS (
  SELECT
    s.reps,
    s.weight,
    s.duration_seconds,
    COALESCE(e.is_assisted, 0) AS is_assisted
  FROM set_log s
  JOIN workout_log wl            ON wl.id = s.workout_log_id
  JOIN exercise e                ON e.id = s.exercise_id
  JOIN exercise_muscle_group emg ON emg.exercise_id = e.id AND emg.is_primary = 1
  JOIN muscle_group mg           ON mg.id = emg.muscle_group_id
  JOIN primary_muscle_group pmg  ON pmg.id = mg.primary_muscle_group_id
  JOIN params p
  WHERE wl.user_id = p.userId
    AND LOWER(TRIM(pmg.name)) = LOWER(TRIM(p.muscleName))
    AND (
          p.startDate IS NULL
          OR DATE(replace(wl.created_at,' ','T')) >= p.startDate
        )
),
agg AS (
  SELECT
    SUM(
      CASE
        WHEN is_assisted = 0 AND weight > 0
          THEN weight * COALESCE(reps, 0)
        ELSE 0
      END
    ) AS weighted_volume,
    SUM(
      CASE
        WHEN (weight IS NULL OR weight = 0 OR is_assisted = 1)
             AND reps > 0
          THEN reps
        ELSE 0
      END
    ) AS reps_volume,
    SUM(
      CASE
        WHEN duration_seconds > 0
          THEN duration_seconds
        ELSE 0
      END
    ) AS time_volume_seconds
  FROM filtered_sets
)
SELECT
  CASE
    WHEN weighted_volume > 0 THEN
      CASE
        WHEN weighted_volume >= 1000
          THEN CAST(CAST(weighted_volume / 1000 AS INTEGER) AS TEXT) || 'K'
        ELSE CAST(CAST(weighted_volume AS INTEGER) AS TEXT)
      END
    WHEN reps_volume > 0 AND time_volume_seconds > 0 THEN
      CASE
        WHEN reps_volume >= time_volume_seconds
          THEN CAST(reps_volume AS TEXT) || ' Reps'
        ELSE printf('%02d:%02d', time_volume_seconds / 60, time_volume_seconds % 60)
      END
    WHEN reps_volume > 0 THEN
      CAST(reps_volume AS TEXT) || ' Reps'
    WHEN time_volume_seconds > 0 THEN
      printf('%02d:%02d', time_volume_seconds / 60, time_volume_seconds % 60)
    ELSE '-'
  END AS display_volume
FROM agg;
''';
  return _readQuery(database, query, (d) => VolumeForMuscleTimeRow(d));
}

class VolumeForMuscleTimeRow extends SqliteRow {
  VolumeForMuscleTimeRow(Map<String, dynamic> data) : super(data);

  String? get displayVolume => data['display_volume'] as String?;
}

/// END VOLUMEFORMUSCLETIME

/// BEGIN SETSFORMUSCLEBYTIME
Future<List<SetsForMuscleByTimeRow>> performSetsForMuscleByTime(
  Database database, {
  String? userId,
  String? muscleName,
  String? rangeLabel,
}) {
  final query = '''
WITH
params AS (
  SELECT
    '${userId}'     AS userId,
    '${muscleName}' AS muscleName,
    '${rangeLabel}' AS rangeLabel,
    DATE('now')     AS today,
    CASE '${rangeLabel}'
      WHEN 'Last 7 days'  THEN DATE('now','-7 days')
      WHEN 'Last 30 days' THEN DATE('now','-30 days')
      WHEN 'Last 90 days' THEN DATE('now','-90 days')
      ELSE NULL
    END AS startDate
),
raw_count AS (
  SELECT
    COUNT(*) AS totalSets
  FROM set_log s
  JOIN workout_log wl            ON wl.id = s.workout_log_id
  JOIN exercise_muscle_group emg ON emg.exercise_id = s.exercise_id AND emg.is_primary = 1
  JOIN muscle_group mg           ON mg.id = emg.muscle_group_id
  JOIN primary_muscle_group pmg  ON pmg.id = mg.primary_muscle_group_id
  JOIN params p
  WHERE wl.user_id = p.userId
    AND LOWER(TRIM(pmg.name)) = LOWER(TRIM(p.muscleName))
    AND (
          p.startDate IS NULL
          OR DATE(replace(wl.created_at,' ','T')) >= p.startDate
        )
)
SELECT
  CASE
    WHEN COALESCE((SELECT totalSets FROM raw_count), 0) = 0 THEN '-'
    ELSE CAST((SELECT totalSets FROM raw_count) AS TEXT)
  END AS totalSets
LIMIT 1;
''';
  return _readQuery(database, query, (d) => SetsForMuscleByTimeRow(d));
}

class SetsForMuscleByTimeRow extends SqliteRow {
  SetsForMuscleByTimeRow(Map<String, dynamic> data) : super(data);

  String get totalSets => data['totalSets'] as String;
}

/// END SETSFORMUSCLEBYTIME

/// BEGIN MUSCLEPCTCHANGE
Future<List<MusclePctChangeRow>> performMusclePctChange(
  Database database, {
  String? userId,
  String? muscleName,
  String? rangeLabel,
}) {
  final query = '''
-- INPUT:
-- ${userId}
-- ${muscleName}
-- ${rangeLabel}
WITH params AS (
  SELECT
    '${userId}'     AS userId,
    '${muscleName}' AS muscleName,
    '${rangeLabel}' AS rangeLabel,
    DATE('now')     AS today,
    CASE '${rangeLabel}'
      WHEN 'Last 7 days'  THEN DATE('now','-7 days')
      WHEN 'Last 30 days' THEN DATE('now','-30 days')
      WHEN 'Last 90 days' THEN DATE('now','-90 days')
      ELSE NULL
    END AS startDate
),
wl_norm AS (
  SELECT
    wl.*,
    DATE(replace(CAST(wl.created_at AS TEXT),' ','T')) AS created_date
  FROM workout_log wl
),
session_values AS (
  SELECT
    s.exercise_id,
    s.workout_log_id,
    w.created_date,
    COALESCE(e.is_assisted, 0) AS is_assisted,
    CASE
      WHEN COALESCE(s.duration_seconds, 0) > 0
        THEN s.duration_seconds * 1.0
      WHEN COALESCE(e.is_assisted, 0) = 1
        THEN COALESCE(s.reps, 0)
      WHEN COALESCE(s.weight, 0) > 0
        THEN COALESCE(s.weight, 0) * COALESCE(s.reps, 0)
      ELSE COALESCE(s.reps, 0)
    END AS value
  FROM set_log s
  JOIN wl_norm w                 ON w.id = s.workout_log_id
  JOIN exercise e                ON e.id = s.exercise_id
  JOIN exercise_muscle_group emg ON emg.exercise_id = e.id AND emg.is_primary = 1
  JOIN muscle_group mg           ON mg.id = emg.muscle_group_id
  JOIN primary_muscle_group pmg  ON pmg.id = mg.primary_muscle_group_id
  JOIN params p
  WHERE w.user_id = p.userId
    AND LOWER(TRIM(pmg.name)) = LOWER(TRIM(p.muscleName))
    AND (p.startDate IS NULL OR w.created_date >= p.startDate)
),
ordered AS (
  SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY created_date ASC,  workout_log_id ASC)  AS rn_first,
    ROW_NUMBER() OVER (ORDER BY created_date DESC, workout_log_id DESC) AS rn_last,
    COUNT(*)     OVER ()                                                AS rowCount
  FROM session_values
),
first_last AS (
  SELECT
    CASE WHEN COALESCE((SELECT rowCount FROM ordered LIMIT 1), 0) < 2
         THEN 0.0
         ELSE COALESCE((SELECT value FROM ordered WHERE rn_first = 1), 0.0)
    END AS firstValue,
    CASE WHEN COALESCE((SELECT rowCount FROM ordered LIMIT 1), 0) < 2
         THEN 0.0
         ELSE COALESCE((SELECT value FROM ordered WHERE rn_last  = 1), 0.0)
    END AS lastValue,
    COALESCE((SELECT is_assisted FROM ordered LIMIT 1), 0) AS is_assisted,
    COALESCE((SELECT rowCount    FROM ordered LIMIT 1), 0) AS rowCount
),
calc AS (
  SELECT
    firstValue,
    lastValue,
    is_assisted,
    rowCount,
    CASE
      WHEN rowCount < 2 OR firstValue = 0 THEN 0.0
      WHEN is_assisted = 1
        THEN ROUND(100.0 * (firstValue - lastValue) / firstValue, 1)
      ELSE
        ROUND(100.0 * (lastValue - firstValue) / firstValue, 1)
    END AS pctChange
  FROM first_last
)
SELECT
  firstValue,
  lastValue,
  pctChange,
  CASE
    WHEN rowCount < 2 THEN '-'
    WHEN firstValue = 0 THEN '0%'
    ELSE
      (CASE WHEN pctChange > 0 THEN '+' ELSE '' END) ||
      (CASE
         WHEN pctChange = CAST(pctChange AS INTEGER)
           THEN CAST(CAST(pctChange AS INTEGER) AS TEXT)
         ELSE CAST(pctChange AS TEXT)
       END) || '%'
  END AS pctChangeStr
FROM calc
LIMIT 1;
''';
  return _readQuery(database, query, (d) => MusclePctChangeRow(d));
}

class MusclePctChangeRow extends SqliteRow {
  MusclePctChangeRow(Map<String, dynamic> data) : super(data);

  double? get pctChange => data['pctChange'] as double?;
  String? get pctChangeStr => data['pctChangeStr'] as String?;
}

/// END MUSCLEPCTCHANGE

/// BEGIN GETRECENTEXERCISES
Future<List<GetRecentExercisesRow>> performGetRecentExercises(
  Database database, {
  String? userId,
}) {
  final query = '''
WITH recent_exercises AS (
  SELECT
    s.exercise_id,
    MAX(s.created_at) AS last_used
  FROM set_log s
  WHERE s.user_id = '${userId}'
    AND strftime('%s', s.created_at) >= strftime('%s', datetime('now', '-30 days'))
  GROUP BY s.exercise_id
)

SELECT
  ev.*,
  e.is_bodyweight,
  e.ai_form_analysis,
  CASE WHEN COALESCE(e.is_assisted, 0) IN (1, 'true', 'TRUE') THEN 1 ELSE 0 END AS is_assisted, -- INTEGER 0/1
  CASE WHEN COALESCE(e.is_public, 0)   IN (1, 'true', 'TRUE') THEN 1 ELSE 0 END AS is_public    -- INTEGER 0/1
FROM exercise_view ev
JOIN recent_exercises r
  ON r.exercise_id = ev.exercise_id
JOIN exercise e
  ON e.id = ev.exercise_id
ORDER BY r.last_used DESC;
''';
  return _readQuery(database, query, (d) => GetRecentExercisesRow(d));
}

class GetRecentExercisesRow extends SqliteRow {
  GetRecentExercisesRow(Map<String, dynamic> data) : super(data);

  int get exerciseId => data['exercise_id'] as int;
  String get exerciseName => data['exercise_name'] as String;
  String? get illustration => data['illustration'] as String?;
  String get primaryMuscle1 => data['primary_muscle_1'] as String;
  String? get primaryMuscle2 => data['primary_muscle_2'] as String?;
  String get subMuscle1 => data['sub_muscle_1'] as String;
  String? get subMuscle2 => data['sub_muscle_2'] as String?;
  String? get subMuscle3 => data['sub_muscle_3'] as String?;
  String get equipment => data['equipment'] as String;
  String get exerciseType => data['exercise_type'] as String;
  int get isBodyweight => data['is_bodyweight'] as int;
  int get aiFormAnalysis => data['ai_form_analysis'] as int;
  int get isAssisted => data['is_assisted'] as int;
  int get isPublic => data['is_public'] as int;
}

/// END GETRECENTEXERCISES

/// BEGIN GETUSEREXERCISES
Future<List<GetUserExercisesRow>> performGetUserExercises(
  Database database, {
  String? currentUserId,
}) {
  final query = '''
SELECT
  ranked.ID AS exercise_id,
  ranked.Name AS exercise_name,
  ranked.illustration,
  ranked.equipment,
  ranked.exercise_type,
  ranked.is_bodyweight,
  ranked.is_assisted,
  0 AS is_public,                    -- user-created exercises only

  MAX(CASE WHEN ranked.pmg_row = 1 THEN ranked.primary_name END) AS primary_muscle_1,
  MAX(CASE WHEN ranked.pmg_row = 2 THEN ranked.primary_name END) AS primary_muscle_2,

  MAX(CASE WHEN ranked.mg_row = 1 THEN ranked.sub_name END) AS sub_muscle_1,
  MAX(CASE WHEN ranked.mg_row = 2 THEN ranked.sub_name END) AS sub_muscle_2,
  MAX(CASE WHEN ranked.mg_row = 3 THEN ranked.sub_name END) AS sub_muscle_3

FROM (
    SELECT
      e.id AS ID,
      e.name AS Name,
      e.illustration,
      e.equipment,
      e.exercise_type,
      e.is_bodyweight,
      CASE WHEN COALESCE(e.is_assisted, 0) IN (1, 'true', 'TRUE') THEN 1 ELSE 0 END AS is_assisted,

      pmg.name AS primary_name,
      mg.name AS sub_name,

      ROW_NUMBER() OVER (
        PARTITION BY e.id ORDER BY pmg.name
      ) AS pmg_row,

      ROW_NUMBER() OVER (
        PARTITION BY e.id ORDER BY mg.name
      ) AS mg_row

    FROM exercise e
    JOIN exercise_muscle_group emg
      ON e.id = emg.exercise_id
    JOIN muscle_group mg
      ON emg.muscle_group_id = mg.id
    JOIN primary_muscle_group pmg
      ON mg.primary_muscle_group_id = pmg.id

    WHERE e.is_public = 0
      AND e.created_by_user_id = '${currentUserId}'
      AND e.is_deleted = 0        -- ✅ סינון תרגילים מחוקים
) ranked

GROUP BY
  ranked.ID,
  ranked.Name,
  ranked.illustration,
  ranked.equipment,
  ranked.exercise_type,
  ranked.is_bodyweight,
  ranked.is_assisted

ORDER BY ranked.Name ASC;
''';
  return _readQuery(database, query, (d) => GetUserExercisesRow(d));
}

class GetUserExercisesRow extends SqliteRow {
  GetUserExercisesRow(Map<String, dynamic> data) : super(data);

  String get exerciseName => data['exercise_name'] as String;
  int get exerciseId => data['exercise_id'] as int;
  String get primaryMuscle1 => data['primary_muscle_1'] as String;
  String? get primaryMuscle2 => data['primary_muscle_2'] as String?;
  String get subMuscle1 => data['sub_muscle_1'] as String;
  String? get subMuscle2 => data['sub_muscle_2'] as String?;
  String? get subMuscle3 => data['sub_muscle_3'] as String?;
  String? get exerciseType => data['exercise_type'] as String?;
  String? get equipment => data['equipment'] as String?;
  String? get illustration => data['illustration'] as String?;
  int get isBodyweight => data['is_bodyweight'] as int;
  int get isPublic => data['is_public'] as int;
  int get isAssisted => data['is_assisted'] as int;
}

/// END GETUSEREXERCISES

/// BEGIN GETSUBMUSCELS
Future<List<GetSubMuscelsRow>> performGetSubMuscels(
  Database database, {
  int? primaryId,
}) {
  final query = '''
SELECT
  mg.id,
  mg.name,
  mg.image_url
FROM muscle_group mg
WHERE mg.primary_muscle_group_id = ${primaryId}
ORDER BY mg.name ASC;

''';
  return _readQuery(database, query, (d) => GetSubMuscelsRow(d));
}

class GetSubMuscelsRow extends SqliteRow {
  GetSubMuscelsRow(Map<String, dynamic> data) : super(data);

  int get id => data['id'] as int;
  String get name => data['name'] as String;
  String get imageUrl => data['image_url'] as String;
}

/// END GETSUBMUSCELS

/// BEGIN EXERCISEPRSTIMED
Future<List<ExercisePrsTimedRow>> performExercisePrsTimed(
  Database database, {
  String? userId,
  int? exerciseId,
  String? timeRange,
}) {
  final query = '''
-- Params:
-- ${exerciseId}  (INTEGER)
-- "${userId}"    (TEXT)
-- "${timeRange}" (TEXT)

WITH bounds AS (
  SELECT
    CASE '${timeRange}'
      WHEN 'Last 7 days'  THEN datetime('now','localtime','-7 days')
      WHEN 'Last 30 days' THEN datetime('now','localtime','-30 days')
      WHEN 'Last 90 days' THEN datetime('now','localtime','-90 days')
      ELSE datetime('1970-01-01')
    END AS from_ts,
    CASE '${timeRange}'
      WHEN 'All' THEN datetime('9999-12-31')
      ELSE datetime('now','localtime')
    END AS to_ts
),

per_session AS (
  SELECT
    sl.workout_log_id,
    SUM(sl.duration_seconds) AS session_time
  FROM set_log sl
  JOIN workout_log wl ON wl.id = sl.workout_log_id
  JOIN bounds b
  WHERE sl.exercise_id = ${exerciseId}
    AND wl.user_id = '${userId}'
    AND sl.duration_seconds > 0
    AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
    AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
  GROUP BY sl.workout_log_id
)

SELECT
  MAX(sl.duration_seconds) AS max_duration,
  AVG(sl.duration_seconds) AS avg_duration,
  MAX(ps.session_time)    AS max_session_time
FROM set_log sl
JOIN workout_log wl ON wl.id = sl.workout_log_id
JOIN bounds b
LEFT JOIN per_session ps USING (workout_log_id)
WHERE sl.exercise_id = ${exerciseId}
  AND wl.user_id = '${userId}'
  AND sl.duration_seconds > 0
  AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
  AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts;

''';
  return _readQuery(database, query, (d) => ExercisePrsTimedRow(d));
}

class ExercisePrsTimedRow extends SqliteRow {
  ExercisePrsTimedRow(Map<String, dynamic> data) : super(data);

  int? get maxDuration => data['max_duration'] as int?;
  double? get avgDuration => data['avg_duration'] as double?;
  int? get maxSessionTime => data['max_session_time'] as int?;
}

/// END EXERCISEPRSTIMED

/// BEGIN TIMEDEXERCISELINEGRAPH
Future<List<TimedExerciseLineGraphRow>> performTimedExerciseLineGraph(
  Database database, {
  String? userId,
  int? exerciseId,
  String? timeRange,
}) {
  final query = '''
-- Params:
-- ${exerciseId}  (INTEGER)
-- "${userId}"    (TEXT)
-- "${timeRange}" (TEXT)

WITH bounds AS (
  SELECT
    CASE '${timeRange}'
      WHEN 'Last 7 days'  THEN datetime('now','localtime','-7 days')
      WHEN 'Last 30 days' THEN datetime('now','localtime','-30 days')
      WHEN 'Last 90 days' THEN datetime('now','localtime','-90 days')
      ELSE datetime('1970-01-01')
    END AS from_ts,
    CASE '${timeRange}'
      WHEN 'All' THEN datetime('9999-12-31')
      ELSE datetime('now','localtime')
    END AS to_ts
)

SELECT
  wl.user_id                              AS user_id,
  CAST(sl.exercise_id AS INTEGER)         AS exercise_id,

  -- יום האימון
  CASE
    WHEN typeof(sl.created_at) = 'integer'
      THEN date(sl.created_at / 1000, 'unixepoch')
    ELSE date(sl.created_at)
  END                                     AS session_date,

  -- זמן כולל ביום (DOUBLE)
  SUM(
    CASE
      WHEN sl.duration_seconds IS NOT NULL
        THEN sl.duration_seconds * 1.0
      ELSE 0.0
    END
  )                                       AS total_duration_ms,

  -- הסט הארוך ביותר ביום
  CAST(
    MAX(
      CASE
        WHEN sl.duration_seconds IS NOT NULL
          THEN sl.duration_seconds
        ELSE 0
      END
    ) AS INTEGER
  )                                       AS max_duration_ms,

  -- מספר סטים ביום
  CAST(COUNT(*) AS INTEGER)               AS total_sets

FROM set_log sl
JOIN workout_log wl ON wl.id = sl.workout_log_id
JOIN bounds b

WHERE CAST(sl.exercise_id AS INTEGER) = ${exerciseId}
  AND CAST(wl.user_id AS TEXT) = '${userId}'
  AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
  AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts

GROUP BY
  wl.user_id,
  sl.exercise_id,
  session_date

ORDER BY session_date ASC;

''';
  return _readQuery(database, query, (d) => TimedExerciseLineGraphRow(d));
}

class TimedExerciseLineGraphRow extends SqliteRow {
  TimedExerciseLineGraphRow(Map<String, dynamic> data) : super(data);

  int get exerciseId => data['exercise_id'] as int;
  String get workoutLogId => data['workout_log_id'] as String;
  String get sessionDate => data['session_date'] as String;
  double? get totalDurationMs => data['total_duration_ms'] as double?;
  int? get maxDurationInSet => data['max_duration_in_set'] as int?;
  int? get totalSets => data['total_sets'] as int?;
}

/// END TIMEDEXERCISELINEGRAPH

/// BEGIN TIMEBASEDEXERCISEANALYTICS
Future<List<TimeBasedExerciseAnalyticsRow>> performTimeBasedExerciseAnalytics(
  Database database, {
  String? userId,
  int? exerciseId,
  String? timeRange,
}) {
  final query = '''
-- Params:
-- ${exerciseId}  (INTEGER)
-- "${userId}"    (TEXT)
-- "${timeRange}" (TEXT)

WITH bounds AS (
  SELECT
    CASE '${timeRange}'
      WHEN 'Last 7 days'  THEN datetime('now','localtime','-7 days')
      WHEN 'Last 30 days' THEN datetime('now','localtime','-30 days')
      WHEN 'Last 90 days' THEN datetime('now','localtime','-90 days')
      ELSE datetime('1970-01-01')
    END AS from_ts,
    CASE '${timeRange}'
      WHEN 'All' THEN datetime('9999-12-31')
      ELSE datetime('now','localtime')
    END AS to_ts,

    -- קבועים ל-current week
    (strftime('%s','now','-7 days') * 1000) AS start_7d_ms
),

cleaned AS (
  SELECT
    sl.duration_seconds,
    sl.workout_log_id,

    -- תאריך הסשן
    DATE(
      CASE
        WHEN typeof(sl.created_at) = 'integer'
          THEN datetime(sl.created_at / 1000, 'unixepoch')
        ELSE sl.created_at
      END
    ) AS session_date,

    -- timestamp מספרי למיון
    CASE
      WHEN typeof(sl.created_at) = 'integer'
        THEN sl.created_at
      ELSE strftime('%s', sl.created_at) * 1000
    END AS created_at_ts

  FROM set_log sl
  JOIN workout_log wl ON wl.id = sl.workout_log_id
  JOIN bounds b
  WHERE sl.exercise_id = ${exerciseId}
    AND wl.user_id = '${userId}'
    AND sl.duration_seconds IS NOT NULL
    AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
    AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
),

session_totals AS (
  SELECT
    workout_log_id,
    session_date,
    MIN(created_at_ts) AS session_ts,
    SUM(duration_seconds) AS total_time
  FROM cleaned
  GROUP BY workout_log_id, session_date
),

ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY session_ts ASC)  AS rn_first,
    ROW_NUMBER() OVER (ORDER BY session_ts DESC) AS rn_last
  FROM session_totals
),

first_last AS (
  SELECT
    MAX(CASE WHEN rn_first = 1 THEN total_time END) AS first_time,
    MAX(CASE WHEN rn_last  = 1 THEN total_time END) AS last_time
  FROM ranked
)

SELECT
  -- 🔹 סך זמן בשבוע האחרון (INT) — תמיד 7 ימים אחורה
  COALESCE(
    (
      SELECT SUM(total_time)
      FROM session_totals, bounds
      WHERE session_ts >= start_7d_ms
    ),
    0
  ) AS current_week_seconds,

  -- 🔹 הסשן הארוך ביותר בטווח הנבחר
  COALESCE(
    (
      SELECT MAX(total_time)
      FROM session_totals
    ),
    0
  ) AS best_session_seconds,

  -- 🔹 אחוז שינוי (DOUBLE)
  COALESCE(
    (
      SELECT
        CASE
          WHEN first_time IS NULL OR first_time = 0
            THEN 0.0
          ELSE CAST(
            ROUND(
              ((last_time - first_time) * 100.0 / first_time) * 2
            ) / 2.0
            AS REAL
          )
        END
      FROM first_last
    ),
    0.0
  ) AS improvement_percent,

  -- 🔹 הסט הארוך ביותר בטווח
  COALESCE(
    (
      SELECT MAX(duration_seconds)
      FROM cleaned
    ),
    0
  ) AS longest_set_seconds;

''';
  return _readQuery(database, query, (d) => TimeBasedExerciseAnalyticsRow(d));
}

class TimeBasedExerciseAnalyticsRow extends SqliteRow {
  TimeBasedExerciseAnalyticsRow(Map<String, dynamic> data) : super(data);

  int? get currentWeekSeconds => data['current_week_seconds'] as int?;
  int? get bestSessionSeconds => data['best_session_seconds'] as int?;
  double? get improvementPercent => data['improvement_percent'] as double?;
  int? get longestSetSeconds => data['longest_set_seconds'] as int?;
}

/// END TIMEBASEDEXERCISEANALYTICS

/// BEGIN EXERCISEPRSBODYWEIGHT
Future<List<ExercisePrsBodyweightRow>> performExercisePrsBodyweight(
  Database database, {
  int? exerciseId,
  String? timeRange,
  String? userId,
}) {
  final query = '''
-- Params:
-- ${exerciseId}  (INTEGER)
-- "${userId}"    (TEXT)
-- "${timeRange}" (TEXT)

WITH bounds AS (
  SELECT
    CASE '${timeRange}'
      WHEN 'Last 7 days'  THEN datetime('now','localtime','-7 days')
      WHEN 'Last 30 days' THEN datetime('now','localtime','-30 days')
      WHEN 'Last 90 days' THEN datetime('now','localtime','-90 days')
      ELSE datetime('1970-01-01')
    END AS from_ts,
    CASE '${timeRange}'
      WHEN 'All' THEN datetime('9999-12-31')
      ELSE datetime('now','localtime')
    END AS to_ts
),

base AS (
  SELECT
    sl.reps,
    sl.workout_log_id
  FROM set_log sl
  JOIN workout_log wl ON wl.id = sl.workout_log_id
  JOIN bounds b
  WHERE sl.exercise_id = ${exerciseId}
    AND wl.user_id = '${userId}'
    AND sl.reps IS NOT NULL
    AND sl.reps > 0
    AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
    AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
),

sessions AS (
  SELECT
    workout_log_id,
    SUM(reps) AS session_reps
  FROM base
  GROUP BY workout_log_id
)

SELECT
  -- 1️⃣ Max Reps (סט בודד)
  CAST(
    IFNULL(
      (SELECT MAX(reps) FROM base),
      0
    ) AS INTEGER
  ) AS max_reps,

  -- 2️⃣ Max Session Reps (אימון אחד)
  CAST(
    IFNULL(
      (SELECT MAX(session_reps) FROM sessions),
      0
    ) AS INTEGER
  ) AS max_session_reps,

  -- 3️⃣ Avg Reps (ממוצע כללי, עיגול ל־0.5)
  CAST(
    IFNULL(
      ROUND((SELECT AVG(reps) FROM base) * 2, 0) / 2.0,
      0
    ) AS REAL
  ) AS avg_reps;

''';
  return _readQuery(database, query, (d) => ExercisePrsBodyweightRow(d));
}

class ExercisePrsBodyweightRow extends SqliteRow {
  ExercisePrsBodyweightRow(Map<String, dynamic> data) : super(data);

  double? get avgReps => data['avg_reps'] as double?;
  int? get maxSessionReps => data['max_session_reps'] as int?;
  int? get maxReps => data['max_reps'] as int?;
}

/// END EXERCISEPRSBODYWEIGHT

/// BEGIN EXERCISEBODYWEIGHTLINEGRAPH
Future<List<ExerciseBodyweightLineGraphRow>> performExerciseBodyweightLineGraph(
  Database database, {
  int? exerciseId,
  String? userId,
  String? timeRange,
}) {
  final query = '''
-- Params:
-- ${exerciseId}  (INTEGER)
-- "${userId}"    (TEXT)
-- "${timeRange}" (TEXT)

WITH bounds AS (
  SELECT
    CASE '${timeRange}'
      WHEN 'Last 7 days'  THEN datetime('now','localtime','-7 days')
      WHEN 'Last 30 days' THEN datetime('now','localtime','-30 days')
      WHEN 'Last 90 days' THEN datetime('now','localtime','-90 days')
      ELSE datetime('1970-01-01')
    END AS from_ts,
    CASE '${timeRange}'
      WHEN 'All' THEN datetime('9999-12-31')
      ELSE datetime('now','localtime')
    END AS to_ts
)

SELECT
  DATE(wl.created_at)        AS session_date,
  MAX(sl.reps * 1.0)         AS max_reps
FROM set_log sl
JOIN workout_log wl
  ON wl.id = sl.workout_log_id
JOIN bounds b
WHERE sl.exercise_id = ${exerciseId}
  AND wl.user_id = '${userId}'
  AND sl.reps IS NOT NULL
  AND sl.reps > 0
  AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
  AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
GROUP BY wl.id
ORDER BY session_date ASC;

''';
  return _readQuery(database, query, (d) => ExerciseBodyweightLineGraphRow(d));
}

class ExerciseBodyweightLineGraphRow extends SqliteRow {
  ExerciseBodyweightLineGraphRow(Map<String, dynamic> data) : super(data);

  double get maxReps => data['max_reps'] as double;
  String get sessionDate => data['session_date'] as String;
}

/// END EXERCISEBODYWEIGHTLINEGRAPH

/// BEGIN BODYWEIGHTEXERCISEANALYTICS
Future<List<BodyweightExerciseAnalyticsRow>> performBodyweightExerciseAnalytics(
  Database database, {
  int? exerciseId,
  String? userId,
  String? timeRange,
}) {
  final query = '''
-- Params:
-- ${exerciseId}  (INTEGER)
-- "${userId}"    (TEXT)
-- "${timeRange}" (TEXT)

WITH bounds AS (
  SELECT
    CASE '${timeRange}'
      WHEN 'Last 7 days'  THEN datetime('now','localtime','-7 days')
      WHEN 'Last 30 days' THEN datetime('now','localtime','-30 days')
      WHEN 'Last 90 days' THEN datetime('now','localtime','-90 days')
      ELSE datetime('1970-01-01')
    END AS from_ts,
    CASE '${timeRange}'
      WHEN 'All' THEN datetime('9999-12-31')
      ELSE datetime('now','localtime')
    END AS to_ts
),

base AS (
  SELECT
    sl.reps,
    wl.created_at,
    wl.id AS workout_id
  FROM set_log sl
  JOIN workout_log wl ON wl.id = sl.workout_log_id
  JOIN bounds b
  WHERE sl.exercise_id = ${exerciseId}
    AND wl.user_id = '${userId}'
    AND sl.reps IS NOT NULL
    AND sl.reps > 0
    AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
    AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
),

-- סיכום חזרות לכל סשן
session_totals AS (
  SELECT
    workout_id,
    MIN(created_at) AS session_created_at,
    SUM(reps) AS total_reps
  FROM base
  GROUP BY workout_id
),

-- דירוג סשנים לפי זמן
ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY session_created_at ASC)  AS rn_first,
    ROW_NUMBER() OVER (ORDER BY session_created_at DESC) AS rn_last
  FROM session_totals
),

first_last AS (
  SELECT
    MAX(CASE WHEN rn_first = 1 THEN total_reps END) AS first_reps,
    MAX(CASE WHEN rn_last  = 1 THEN total_reps END) AS last_reps
  FROM ranked
)

SELECT
  -- 1️⃣ Current week: max reps (INT) — תמיד 7 ימים אחורה
  IFNULL(
    (
      SELECT MAX(reps)
      FROM base
      WHERE DATE(created_at) >= DATE('now', 'weekday 0', '-6 days')
    ),
    0
  ) AS current_week_reps,

  -- 2️⃣ Sessions count (INT) — לפי timeRange
  IFNULL(
    (SELECT COUNT(DISTINCT workout_id) FROM base),
    0
  ) AS sessions,

  -- 3️⃣ Change percent (REAL) — לפי timeRange
  IFNULL(
    (
      SELECT
        CASE
          WHEN first_reps IS NULL OR first_reps = 0
            THEN 0.0
          ELSE CAST(
            ROUND(
              (((last_reps - first_reps) * 100.0) / first_reps) * 2
            ) / 2.0
            AS REAL
          )
        END
      FROM first_last
    ),
    0.0
  ) AS improvement_percent;

''';
  return _readQuery(database, query, (d) => BodyweightExerciseAnalyticsRow(d));
}

class BodyweightExerciseAnalyticsRow extends SqliteRow {
  BodyweightExerciseAnalyticsRow(Map<String, dynamic> data) : super(data);

  double? get improvementPercent => data['improvement_percent'] as double?;
  int get currentWeekReps => data['current_week_reps'] as int;
  int get sessions => data['sessions'] as int;
}

/// END BODYWEIGHTEXERCISEANALYTICS

/// BEGIN SUBMUSCELS
Future<List<SubMuscelsRow>> performSubMuscels(
  Database database,
) {
  final query = '''
SELECT *FROM muscle_group
''';
  return _readQuery(database, query, (d) => SubMuscelsRow(d));
}

class SubMuscelsRow extends SqliteRow {
  SubMuscelsRow(Map<String, dynamic> data) : super(data);

  int get id => data['id'] as int;
  String get imageUrl => data['image_url'] as String;
  String get name => data['name'] as String;
}

/// END SUBMUSCELS

/// BEGIN DYNAMICVOLUME
Future<List<DynamicvolumeRow>> performDynamicvolume(
  Database database, {
  String? workoutLogId,
}) {
  final query = '''
WITH agg AS (
  SELECT
    COALESCE(SUM(
      CASE
        WHEN e.is_assisted != 1
             AND COALESCE(s.weight, 0) > 0
             AND COALESCE(s.reps, 0) > 0
          THEN COALESCE(s.weight, 0) * COALESCE(s.reps, 0)
        ELSE 0
      END
    ), 0) AS total_volume,

    -- ⏱️ שומר מילישניות
    COALESCE(SUM(COALESCE(s.duration_seconds, 0)), 0)
      AS total_duration_ms,

    COALESCE(SUM(
      CASE
        WHEN COALESCE(s.reps, 0) > 0 THEN s.reps
        ELSE 0
      END
    ), 0) AS total_reps
  FROM set_log s
  JOIN exercise e
    ON e.id = s.exercise_id
  WHERE s.workout_log_id = '${workoutLogId}'
)

SELECT
  CASE
    -- ======================
    -- 🏋️‍♂️ Volume
    -- ======================
    WHEN total_volume > 0 THEN
      CASE
        WHEN total_volume >= 1000 THEN
          CAST(CAST(total_volume / 1000 AS INTEGER) AS TEXT) || 'K'
        WHEN total_volume = CAST(total_volume AS INTEGER) THEN
          CAST(CAST(total_volume AS INTEGER) AS TEXT)
        ELSE
          CAST(total_volume AS TEXT)
      END

    -- ======================
    -- ⏱️ Duration (ms → mm:ss)
    -- ======================
    WHEN total_duration_ms > 0 THEN
      printf(
        '%02d:%02d',
        CAST((total_duration_ms / 1000) / 60 AS INTEGER),
        CAST((total_duration_ms / 1000) % 60 AS INTEGER)
      )

    -- ======================
    -- 🔁 Reps
    -- ======================
    WHEN total_reps > 0 THEN
      CAST(total_reps AS INTEGER) || ' Reps'

    ELSE
      'No data'
  END AS dynamic_volume
FROM agg;

''';
  return _readQuery(database, query, (d) => DynamicvolumeRow(d));
}

class DynamicvolumeRow extends SqliteRow {
  DynamicvolumeRow(Map<String, dynamic> data) : super(data);

  String get dynamicVolume => data['dynamic_volume'] as String;
}

/// END DYNAMICVOLUME

/// BEGIN GETPRIMARYMUSCELS
Future<List<GetPrimaryMuscelsRow>> performGetPrimaryMuscels(
  Database database,
) {
  final query = '''
SELECT * FROM primary_muscle_group ;

''';
  return _readQuery(database, query, (d) => GetPrimaryMuscelsRow(d));
}

class GetPrimaryMuscelsRow extends SqliteRow {
  GetPrimaryMuscelsRow(Map<String, dynamic> data) : super(data);

  int get id => data['id'] as int;
  String get name => data['name'] as String;
  String get ilustration => data['ilustration'] as String;
}

/// END GETPRIMARYMUSCELS

/// BEGIN HASEXERCISEDATA
Future<List<HasExerciseDataRow>> performHasExerciseData(
  Database database, {
  String? timeRange,
  String? userId,
}) {
  final query = '''
-- פרמטרים:
-- ${userId}    (TEXT)
-- ${timeRange} (TEXT)

WITH params AS (
  SELECT '${userId}' AS user_id, '${timeRange}' AS time_range
),

cutoff AS (
  SELECT
    CASE
      WHEN time_range = 'Last 7 days'  THEN datetime('now','localtime','-7 days')
      WHEN time_range = 'Last 30 days' THEN datetime('now','localtime','-30 days')
      WHEN time_range = 'Last 90 days' THEN datetime('now','localtime','-90 days')
      ELSE NULL   -- All
    END AS min_dt
  FROM params
)

SELECT
  CASE
    WHEN EXISTS (
      SELECT 1
      FROM set_log sl
      JOIN workout_log wl ON wl.id = sl.workout_log_id
      JOIN params p ON wl.user_id = p.user_id
      LEFT JOIN cutoff c ON 1=1
      WHERE COALESCE(sl.is_dropset, 0) = 0
        AND (
          c.min_dt IS NULL
          OR datetime(replace(wl.created_at,' ','T')) >= c.min_dt
        )
      LIMIT 1
    )
    THEN 1
    ELSE 0
  END AS has_data;

''';
  return _readQuery(database, query, (d) => HasExerciseDataRow(d));
}

class HasExerciseDataRow extends SqliteRow {
  HasExerciseDataRow(Map<String, dynamic> data) : super(data);

  int get hasData => data['has_data'] as int;
}

/// END HASEXERCISEDATA

/// BEGIN EXERCISEPRSASSISTED
Future<List<ExercisePrsAssistedRow>> performExercisePrsAssisted(
  Database database, {
  String? exerciseId,
  String? userId,
  String? timeRange,
}) {
  final query = '''
-- Params:
-- ${exerciseId}  (INTEGER)
-- "${userId}"    (TEXT)
-- "${timeRange}" (TEXT)

WITH bounds AS (
  SELECT
    CASE '${timeRange}'
      WHEN 'Last 7 days'  THEN datetime('now','localtime','-7 days')
      WHEN 'Last 30 days' THEN datetime('now','localtime','-30 days')
      WHEN 'Last 90 days' THEN datetime('now','localtime','-90 days')
      ELSE datetime('1970-01-01')
    END AS from_ts,
    CASE '${timeRange}'
      WHEN 'All' THEN datetime('9999-12-31')
      ELSE datetime('now','localtime')
    END AS to_ts
),

ex AS (
  SELECT IFNULL((
    SELECT COALESCE(is_time_based, 0)
    FROM exercise
    WHERE id = ${exerciseId}
    LIMIT 1
  ), 0) AS is_time_based
),

majority AS (
  SELECT
    CASE
      WHEN COUNT(*) = 0 THEN 0
      WHEN 1.0 * SUM(CASE WHEN IFNULL(sl.weight,0) > 0 THEN 1 ELSE 0 END) / COUNT(*) >= 0.5
        THEN 0
      ELSE 1
    END AS is_bodyweight
  FROM set_log sl
  JOIN workout_log wl ON wl.id = sl.workout_log_id
  JOIN bounds b
  WHERE sl.exercise_id = ${exerciseId}
    AND wl.user_id = '${userId}'
    AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
    AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
),

-- נפח פר סשן (Volume / Time / Reps לפי סוג תרגיל)
sessions AS (
  SELECT
    sl.workout_log_id,
    SUM(
      CASE
        WHEN (SELECT is_time_based FROM ex) = 1
          THEN IFNULL(sl.duration_seconds, 0)
        WHEN (SELECT is_bodyweight FROM majority) = 1
          THEN IFNULL(sl.reps, 0)
        ELSE CAST(IFNULL(sl.reps, 0) AS REAL)
           * CAST(IFNULL(sl.weight, 0) AS REAL)
      END
    ) AS session_volume
  FROM set_log sl
  JOIN workout_log wl ON wl.id = sl.workout_log_id
  JOIN bounds b
  WHERE sl.exercise_id = ${exerciseId}
    AND wl.user_id = '${userId}'
    AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
    AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
  GROUP BY sl.workout_log_id
),

-- חזרות פר סשן (נטו Reps)
sessions_reps AS (
  SELECT
    sl.workout_log_id,
    SUM(IFNULL(sl.reps, 0)) AS session_reps
  FROM set_log sl
  JOIN workout_log wl ON wl.id = sl.workout_log_id
  JOIN bounds b
  WHERE sl.exercise_id = ${exerciseId}
    AND wl.user_id = '${userId}'
    AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
    AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
  GROUP BY sl.workout_log_id
)

SELECT
  -- מקס חזרות לסט
  CAST(IFNULL((
    SELECT MAX(IFNULL(sl.reps,0))
    FROM set_log sl
    JOIN workout_log wl ON wl.id = sl.workout_log_id
    JOIN bounds b
    WHERE sl.exercise_id = ${exerciseId}
      AND wl.user_id = '${userId}'
      AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
      AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
  ), 0) AS INTEGER) AS max_reps,

  -- מקס חזרות לסשן
  CAST(IFNULL((
    SELECT MAX(session_reps)
    FROM sessions_reps
  ), 0) AS INTEGER) AS max_session_reps,

  -- מקס משקל
  CAST(IFNULL((
    SELECT ROUND(MAX(NULLIF(CAST(sl.weight AS REAL), 0)), 0)
    FROM set_log sl
    JOIN workout_log wl ON wl.id = sl.workout_log_id
    JOIN bounds b
    WHERE sl.exercise_id = ${exerciseId}
      AND wl.user_id = '${userId}'
      AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
      AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
  ), 0) AS INTEGER) AS max_weight,

  -- מקס נפח לסשן
  CAST(IFNULL((
    SELECT ROUND(MAX(session_volume), 0)
    FROM sessions
  ), 0) AS INTEGER) AS max_volume,

  -- מינימום עזרה (Assisted)
  IFNULL((
    SELECT MIN(CAST(sl.weight AS REAL))
    FROM set_log sl
    JOIN workout_log wl ON wl.id = sl.workout_log_id
    JOIN bounds b
    WHERE sl.exercise_id = ${exerciseId}
      AND wl.user_id = '${userId}'
      AND IFNULL(sl.weight, 0) > 0
      AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
      AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
  ), 0.0) AS min_assistance;

''';
  return _readQuery(database, query, (d) => ExercisePrsAssistedRow(d));
}

class ExercisePrsAssistedRow extends SqliteRow {
  ExercisePrsAssistedRow(Map<String, dynamic> data) : super(data);

  int? get maxReps => data['max_reps'] as int?;
  int? get maxSessionReps => data['max_session_reps'] as int?;
  double? get minAssistance => data['min_assistance'] as double?;
}

/// END EXERCISEPRSASSISTED

/// BEGIN EXERCISELINEGRAPHASSISTED
Future<List<ExerciseLineGraphAssistedRow>> performExerciseLineGraphAssisted(
  Database database, {
  int? exerciseId,
  String? userId,
  String? timeRange,
}) {
  final query = '''
-- Params:
-- ${exerciseId}  (INTEGER)
-- "${userId}"    (TEXT)
-- "${timeRange}" (TEXT)

WITH bounds AS (
  SELECT
    CASE '${timeRange}'
      WHEN 'Last 7 days'  THEN datetime('now','localtime','-7 days')
      WHEN 'Last 30 days' THEN datetime('now','localtime','-30 days')
      WHEN 'Last 90 days' THEN datetime('now','localtime','-90 days')
      ELSE datetime('1970-01-01')
    END AS from_ts,
    CASE '${timeRange}'
      WHEN 'All' THEN datetime('9999-12-31')
      ELSE datetime('now','localtime')
    END AS to_ts
),

max_assist AS (
  -- Ground Zero: האסיסט הכי גבוה שנעשה אי פעם (בתוך טווח הזמן)
  SELECT
    CAST(MAX(COALESCE(sl.weight, 0)) AS REAL) AS max_assist
  FROM set_log sl
  JOIN workout_log wl ON wl.id = sl.workout_log_id
  JOIN bounds b
  WHERE sl.exercise_id = ${exerciseId}
    AND wl.user_id = '${userId}'
    AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
    AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
),

session_sets AS (
  -- כל הסטים הרלוונטיים
  SELECT
    sl.workout_log_id,

    DATE(
      CASE
        WHEN typeof(wl.created_at) = 'integer'
          THEN datetime(wl.created_at / 1000, 'unixepoch')
        ELSE wl.created_at
      END
    ) AS session_date,

    CAST(COALESCE(sl.reps, 0)   AS REAL) AS reps,
    CAST(COALESCE(sl.weight, 0) AS REAL) AS assist_weight

  FROM set_log sl
  JOIN workout_log wl ON wl.id = sl.workout_log_id
  JOIN bounds b
  WHERE sl.exercise_id = ${exerciseId}
    AND wl.user_id = '${userId}'
    AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
    AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
),

scored_sets AS (
  -- חישוב ציון לכל סט
  SELECT
    ss.workout_log_id,
    ss.session_date,
    ss.reps,
    ss.assist_weight,

    CAST(
      CASE
        WHEN ma.max_assist IS NULL OR ma.max_assist = 0
          THEN 1.0
        ELSE
          1.0 + (ma.max_assist - ss.assist_weight) / ma.max_assist
      END
      AS REAL
    ) AS rep_score

  FROM session_sets ss
  CROSS JOIN max_assist ma
)

SELECT
  session_date,

  -- סך חזרות
  CAST(SUM(reps) AS REAL) AS total_reps,

  -- אסיסט ממוצע בסשן
  CAST(
    ROUND(
      AVG(CASE WHEN assist_weight > 0 THEN assist_weight ELSE NULL END),
      2
    ) AS REAL
  ) AS avg_assist,

  -- 🎯 ציון סשן לגרף
  CAST(
    ROUND(
      SUM(reps * rep_score),
      2
    ) AS REAL
  ) AS session_score

FROM scored_sets
GROUP BY workout_log_id, session_date
ORDER BY session_date ASC;

''';
  return _readQuery(database, query, (d) => ExerciseLineGraphAssistedRow(d));
}

class ExerciseLineGraphAssistedRow extends SqliteRow {
  ExerciseLineGraphAssistedRow(Map<String, dynamic> data) : super(data);

  String get sessionDate => data['session_date'] as String;
  double get totalReps => data['total_reps'] as double;
  double get avgAssist => data['avg_assist'] as double;
  double get sessionScore => data['session_score'] as double;
}

/// END EXERCISELINEGRAPHASSISTED

/// BEGIN ASSISTEDANALYTICS
Future<List<AssistedAnalyticsRow>> performAssistedAnalytics(
  Database database, {
  String? userId,
  int? exerciseId,
  String? timeRange,
}) {
  final query = '''
-- Params:
-- ${exerciseId}  (INTEGER)
-- '${userId}'    (TEXT)
-- '${timeRange}' (TEXT)

WITH bounds AS (
  SELECT
    CASE '${timeRange}'
      WHEN 'Last 7 days'  THEN datetime('now','localtime','-7 days')
      WHEN 'Last 30 days' THEN datetime('now','localtime','-30 days')
      WHEN 'Last 90 days' THEN datetime('now','localtime','-90 days')
      ELSE datetime('1970-01-01')
    END AS from_ts,
    CASE '${timeRange}'
      WHEN 'All' THEN datetime('9999-12-31')
      ELSE datetime('now','localtime')
    END AS to_ts,

    -- קבועים ל־current week
    datetime('now','localtime','-7 days') AS start_7d,
    datetime('now','localtime')           AS end_now
),

sets AS (
  SELECT
    sl.workout_log_id,
    COALESCE(sl.created_at, wl.created_at) AS set_created_at,
    COALESCE(sl.reps, 0)                   AS reps,
    COALESCE(sl.weight, 0)                 AS assist_weight
  FROM set_log sl
  JOIN workout_log wl ON wl.id = sl.workout_log_id
  JOIN bounds b
  WHERE sl.exercise_id = ${exerciseId}
    AND wl.user_id = '${userId}'
    AND COALESCE(sl.reps,0) > 0
    AND datetime(replace(wl.created_at,' ','T')) >= b.from_ts
    AND datetime(replace(wl.created_at,' ','T')) <  b.to_ts
),

-- Ground zero: אסיסט מקסימלי בתוך הטווח
max_assist AS (
  SELECT
    COALESCE(MAX(assist_weight), 1) AS max_assist_weight
  FROM sets
),

scored_sets AS (
  SELECT
    s.workout_log_id,
    s.set_created_at,
    s.reps,
    s.assist_weight,
    CAST(
      s.reps * ((SELECT max_assist_weight FROM max_assist) / NULLIF(s.assist_weight,1))
      AS REAL
    ) AS set_score
  FROM sets s
),

per_session AS (
  SELECT
    workout_log_id,
    MIN(set_created_at) AS session_created_at,
    SUM(reps)           AS session_reps,
    SUM(set_score)      AS session_score
  FROM scored_sets
  GROUP BY workout_log_id
),

-- Current week תמיד 7 ימים אחרונים
current_7d AS (
  SELECT
    COALESCE(SUM(reps), 0) AS current_week_reps
  FROM sets, bounds
  WHERE set_created_at >= start_7d
    AND set_created_at <  end_now
),

best_session AS (
  SELECT
    COALESCE(MAX(session_reps), 0) AS best_session_reps
  FROM per_session
),

first_last AS (
  SELECT
    (SELECT session_score
     FROM per_session
     ORDER BY session_created_at ASC
     LIMIT 1) AS first_score,
    (SELECT session_score
     FROM per_session
     ORDER BY session_created_at DESC
     LIMIT 1) AS last_score
),

improve AS (
  SELECT
    CASE
      WHEN first_score IS NULL OR last_score IS NULL THEN 0
      WHEN first_score = 0 THEN 0
      ELSE CAST(
        ROUND(((last_score - first_score) * 100.0) / first_score, 0)
        AS INTEGER
      )
    END AS improvement_percent
  FROM first_last
)

SELECT
  CAST((SELECT best_session_reps   FROM best_session) AS INTEGER) AS best_session_value,
  CAST((SELECT current_week_reps   FROM current_7d)   AS INTEGER) AS current_week_value,
  CAST((SELECT improvement_percent FROM improve)      AS INTEGER) AS improvement_percent,
  0 AS is_time_based;

''';
  return _readQuery(database, query, (d) => AssistedAnalyticsRow(d));
}

class AssistedAnalyticsRow extends SqliteRow {
  AssistedAnalyticsRow(Map<String, dynamic> data) : super(data);

  int? get bestSessionValue => data['best_session_value'] as int?;
  int? get currentWeekValue => data['current_week_value'] as int?;
  int? get improvementPercent => data['improvement_percent'] as int?;
}

/// END ASSISTEDANALYTICS

/// BEGIN WORKOUTNUM
Future<List<WorkoutNumRow>> performWorkoutNum(
  Database database, {
  String? userId,
}) {
  final query = '''
SELECT *
FROM workout
WHERE user_id = '${userId}'
  AND is_deleted = 0;

''';
  return _readQuery(database, query, (d) => WorkoutNumRow(d));
}

class WorkoutNumRow extends SqliteRow {
  WorkoutNumRow(Map<String, dynamic> data) : super(data);

  String get id => data['id'] as String;
}

/// END WORKOUTNUM

/// BEGIN WORKOUTSFORROUTINE
Future<List<WorkoutsForRoutineRow>> performWorkoutsForRoutine(
  Database database, {
  String? workoutId,
  String? userId,
}) {
  final query = '''
SELECT
  w.id AS id,
  w.name AS name,
  (
    SELECT group_concat(pmg_name, ', ')
    FROM (
      SELECT DISTINCT pmg.name AS pmg_name
      FROM workout_exercise we
      JOIN exercise e
        ON e.id = we.exercise_id
      JOIN exercise_muscle_group emg
        ON emg.exercise_id = e.id
       AND COALESCE(emg.is_primary, 1) = 1
      JOIN muscle_group mg
        ON mg.id = emg.muscle_group_id
      JOIN primary_muscle_group pmg
        ON pmg.id = mg.primary_muscle_group_id
      WHERE we.workout_id = w.id
      ORDER BY pmg_name
    )
  ) AS main_muscle_groups
FROM workout w
WHERE w.id = '${workoutId}'
  AND '${workoutId}' IS NOT NULL
  AND '${workoutId}' != ''
  AND w.user_id = '${userId}'
  AND COALESCE(w.is_deleted, 0) = 0
LIMIT 1;

''';
  return _readQuery(database, query, (d) => WorkoutsForRoutineRow(d));
}

class WorkoutsForRoutineRow extends SqliteRow {
  WorkoutsForRoutineRow(Map<String, dynamic> data) : super(data);

  String? get id => data['id'] as String?;
  String? get name => data['name'] as String?;
  String? get mainMuscleGroups => data['main_muscle_groups'] as String?;
}

/// END WORKOUTSFORROUTINE

/// BEGIN GETUSEREXERCISE
Future<List<GetUserExerciseRow>> performGetUserExercise(
  Database database, {
  String? userId,
}) {
  final query = '''
SELECT *
FROM exercise
WHERE created_by_user_id = '${userId}'
  AND is_public = 0
  AND is_deleted = 0;

''';
  return _readQuery(database, query, (d) => GetUserExerciseRow(d));
}

class GetUserExerciseRow extends SqliteRow {
  GetUserExerciseRow(Map<String, dynamic> data) : super(data);

  int get id => data['id'] as int;
}

/// END GETUSEREXERCISE

/// BEGIN GETWORKLOGSCOUNT
Future<List<GetWorklogsCountRow>> performGetWorklogsCount(
  Database database, {
  String? userId,
}) {
  final query = '''
SELECT COUNT(*) AS workoutCount
FROM workout_log
WHERE user_id = '${userId}';
''';
  return _readQuery(database, query, (d) => GetWorklogsCountRow(d));
}

class GetWorklogsCountRow extends SqliteRow {
  GetWorklogsCountRow(Map<String, dynamic> data) : super(data);

  int get workoutCount => data['workoutCount'] as int;
}

/// END GETWORKLOGSCOUNT

/// BEGIN GET MUSCLE
Future<List<GetMuscleRow>> performGetMuscle(
  Database database, {
  int? id,
}) {
  final query = '''
SELECT *FROM primary_muscle_group WHERE id = ${id}
''';
  return _readQuery(database, query, (d) => GetMuscleRow(d));
}

class GetMuscleRow extends SqliteRow {
  GetMuscleRow(Map<String, dynamic> data) : super(data);

  String get ilustration => data['ilustration'] as String;
  String get name => data['name'] as String;
}

/// END GET MUSCLE

/// BEGIN GETEXERCISE
Future<List<GetExerciseRow>> performGetExercise(
  Database database, {
  int? exerciseId,
}) {
  final query = '''
SELECT
  ev.*,
  e.is_bodyweight,
  e.ai_form_analysis
FROM exercise_view ev
JOIN exercise e
  ON e.id = ev.exercise_id
WHERE ev.exercise_id = ${exerciseId};
''';
  return _readQuery(database, query, (d) => GetExerciseRow(d));
}

class GetExerciseRow extends SqliteRow {
  GetExerciseRow(Map<String, dynamic> data) : super(data);

  String get exerciseName => data['exercise_name'] as String;
  String get primaryMuscle1 => data['primary_muscle_1'] as String;
  String get subMuscle1 => data['sub_muscle_1'] as String;
}

/// END GETEXERCISE

/// BEGIN GETSETANALYSIS
Future<List<GetSetAnalysisRow>> performGetSetAnalysis(
  Database database, {
  String? setLogId,
}) {
  final query = '''
SELECT *
FROM set_analysis
WHERE set_log_id = '${setLogId}'
ORDER BY analyzed_at DESC
LIMIT 1;
''';
  return _readQuery(database, query, (d) => GetSetAnalysisRow(d));
}

class GetSetAnalysisRow extends SqliteRow {
  GetSetAnalysisRow(Map<String, dynamic> data) : super(data);

  String? get setLogId => data['set_log_id'] as String?;
  String? get analyzedAt => data['analyzed_at'] as String?;
  double? get score => data['score'] as double?;
  int? get totalReps => data['total_reps'] as int?;
  int? get properReps => data['proper_reps'] as int?;
  String? get feedback => data['feedback'] as String?;
  String? get techniqueScoreDisplay =>
      data['technique_score_display'] as String?;
  String? get techniqueLabel => data['technique_label'] as String?;
  String? get formTip => data['form_tip'] as String?;
  String get id => data['id'] as String;
}

/// END GETSETANALYSIS

/// BEGIN WORKOUTHOME
Future<List<WorkoutHomeRow>> performWorkoutHome(
  Database database, {
  String? userId,
}) {
  final query = '''
SELECT
  w.id,
  w.name,
  COUNT(DISTINCT we.id) AS exercise_count,
  MAX(wl.created_at) AS last_done_at
FROM workout w
LEFT JOIN workout_exercise we ON we.workout_id = w.id
LEFT JOIN workout_log wl ON wl.workout_id = w.id
WHERE w.user_id = '${userId}'
  AND COALESCE(w.is_deleted, 0) = 0
GROUP BY w.id, w.name
ORDER BY
  CASE
    WHEN MAX(wl.created_at) IS NULL THEN 1
    WHEN MAX(wl.created_at) < datetime('now', '-7 days') THEN 1
    ELSE 0
  END ASC,
  CASE
    WHEN MAX(wl.created_at) IS NULL
         OR MAX(wl.created_at) < datetime('now', '-7 days')
      THEN NULL
    ELSE MAX(wl.created_at)
  END ASC,
  MAX(wl.created_at) DESC,
  MAX(w.created_at) DESC;
''';
  return _readQuery(database, query, (d) => WorkoutHomeRow(d));
}

class WorkoutHomeRow extends SqliteRow {
  WorkoutHomeRow(Map<String, dynamic> data) : super(data);

  int get exerciseCount => data['exercise_count'] as int;
  String? get lastDoneAt => data['last_done_at'] as String?;
  String get id => data['id'] as String;
  String get name => data['name'] as String;
}

/// END WORKOUTHOME

/// BEGIN GETUSER
Future<List<GetUserRow>> performGetUser(
  Database database, {
  String? userId,
}) {
  final query = '''
SELECT
  id,
  email,
  username,
  profile_image_url,
  weight,
  height,
  is_kg,
  sex,
  date_of_birth,
  height_is_cm,
  body_weight_is_kg
FROM users
WHERE id = '${userId}'
LIMIT 1;
''';
  return _readQuery(database, query, (d) => GetUserRow(d));
}

class GetUserRow extends SqliteRow {
  GetUserRow(Map<String, dynamic> data) : super(data);

  String get id => data['id'] as String;
  String get email => data['email'] as String;
  String get username => data['username'] as String;
  double? get weight => data['weight'] as double?;
  int get isKg => data['is_kg'] as int;
  String get dateOfBirth => data['date_of_birth'] as String;
}

/// END GETUSER

/// BEGIN GETAIEXERCISES
Future<List<GetAiexercisesRow>> performGetAiexercises(
  Database database,
) {
  final query = '''
SELECT * FROM exercise WHERE ai_form_analysis = 1 AND id != 33
''';
  return _readQuery(database, query, (d) => GetAiexercisesRow(d));
}

class GetAiexercisesRow extends SqliteRow {
  GetAiexercisesRow(Map<String, dynamic> data) : super(data);

  int get id => data['id'] as int;
  String get name => data['name'] as String;
  int get isBodyweight => data['is_bodyweight'] as int;
}

/// END GETAIEXERCISES

/// BEGIN WORKOUTHEROSTAT
Future<List<WorkoutHeroStatRow>> performWorkoutHeroStat(
  Database database, {
  String? workoutLogId,
  String? userId,
}) {
  final query = '''
-- params: ${workoutLogId}, ${userId}
-- Returns ONE row (all String):
--   workout_name, date_text,
--   hero_value, hero_unit, hero_title, hero_subtitle, badge, comparison,
--   duration_text, sets_text, stat3_value, stat3_label, breakdown_label
-- Run AFTER saveWorkoutComplete. duration_seconds is stored in MILLISECONDS.

WITH
cur AS (
  SELECT
    wl.id,
    wl.workout_id,
    wl.created_at,
    COALESCE(wl.volume, 0)                    AS volume,
    COALESCE(wl.duration_seconds, 0) / 1000   AS duration,
    COALESCE(NULLIF(TRIM(w.name), ''), 'this workout') AS workout_name
  FROM workout_log wl
  LEFT JOIN workout w ON w.id = wl.workout_id
  WHERE TRIM(CAST(wl.id AS TEXT)) = TRIM('${workoutLogId}')
),
cur_sets AS (
  SELECT s.id, s.exercise_id,
         COALESCE(s.reps, 0)       AS reps,
         COALESCE(s.weight, 0)     AS weight,
         COALESCE(s.is_dropset, 0) AS is_dropset
  FROM set_log s
  WHERE TRIM(CAST(s.workout_log_id AS TEXT)) = TRIM('${workoutLogId}')
),
cur_stats AS (
  SELECT
    COALESCE(SUM(reps), 0)                     AS total_reps,
    COUNT(CASE WHEN is_dropset = 0 THEN 1 END) AS sets_count,
    COUNT(DISTINCT exercise_id)                AS exercises_count
  FROM cur_sets
),

/* form score: average over analysed sets of this workout */
form AS (
  SELECT AVG(a.score) AS avg_score, COUNT(*) AS n
  FROM set_analysis a
  WHERE a.set_log_id IN (SELECT id FROM cur_sets)
    AND a.score IS NOT NULL
),

/* PR: weight only, non-assisted, needs history */
today_max AS (
  SELECT c.exercise_id, MAX(c.weight) AS today_best
  FROM cur_sets c
  JOIN exercise e ON e.id = c.exercise_id
  WHERE c.weight > 0 AND COALESCE(e.is_assisted, 0) = 0
  GROUP BY c.exercise_id
),
hist_max AS (
  SELECT s.exercise_id, MAX(COALESCE(s.weight, 0)) AS prev_best
  FROM set_log s
  WHERE TRIM(CAST(s.user_id AS TEXT)) = TRIM('${userId}')
    AND TRIM(CAST(s.workout_log_id AS TEXT)) <> TRIM('${workoutLogId}')
    AND s.exercise_id IN (SELECT exercise_id FROM today_max)
  GROUP BY s.exercise_id
),
prs AS (
  SELECT e.name AS exercise_name, t.today_best, h.prev_best,
         (t.today_best - h.prev_best) * 100.0 / h.prev_best AS improve_pct
  FROM today_max t
  JOIN hist_max h ON h.exercise_id = t.exercise_id
  JOIN exercise e ON e.id = t.exercise_id
  WHERE h.prev_best > 0 AND t.today_best > h.prev_best
),
top_pr AS (
  SELECT * FROM prs ORDER BY improve_pct DESC, today_best DESC LIMIT 1
),
pr_count AS (
  SELECT COUNT(*) AS n FROM prs
),

/* exercises never done before (any workout) */
new_moves AS (
  SELECT e.name
  FROM (SELECT DISTINCT exercise_id FROM cur_sets) c
  JOIN exercise e ON e.id = c.exercise_id
  WHERE NOT EXISTS (
    SELECT 1 FROM set_log s
    WHERE s.exercise_id = c.exercise_id
      AND TRIM(CAST(s.user_id AS TEXT)) = TRIM('${userId}')
      AND TRIM(CAST(s.workout_log_id AS TEXT)) <> TRIM('${workoutLogId}')
  )
  ORDER BY e.name
),
new_moves_agg AS (
  SELECT COUNT(*) AS n, MIN(name) AS first_name FROM new_moves
),

/* previous workout of the same template + best volume ever */
prev_log AS (
  SELECT w.id,
         COALESCE(w.volume, 0)                  AS volume,
         COALESCE(w.duration_seconds, 0) / 1000 AS duration
  FROM workout_log w, cur
  WHERE w.workout_id = cur.workout_id
    AND w.id <> cur.id
    AND w.created_at < cur.created_at
    AND TRIM(CAST(w.user_id AS TEXT)) = TRIM('${userId}')
  ORDER BY w.created_at DESC
  LIMIT 1
),
best_vol AS (
  SELECT MAX(COALESCE(w.volume, 0)) AS v
  FROM workout_log w, cur
  WHERE w.workout_id = cur.workout_id
    AND w.id <> cur.id
    AND TRIM(CAST(w.user_id AS TEXT)) = TRIM('${userId}')
),

/* total workouts logged (including this one) */
workout_no AS (
  SELECT COUNT(*) AS n
  FROM workout_log w, cur
  WHERE TRIM(CAST(w.user_id AS TEXT)) = TRIM('${userId}')
    AND w.created_at <= cur.created_at
),

/* muscle with the most sets today */
top_muscle AS (
  SELECT mg.name AS muscle
  FROM cur_sets c
  JOIN exercise_muscle_group emg ON emg.exercise_id = c.exercise_id
  JOIN muscle_group mg ON mg.id = emg.muscle_group_id
  WHERE COALESCE(emg.is_primary, 0) = 1 AND c.is_dropset = 0
  GROUP BY mg.name
  ORDER BY COUNT(*) DESC, mg.name
  LIMIT 1
),

resolved AS (
  SELECT
    CASE
      WHEN (SELECT n FROM pr_count) > 0                                 THEN 'pr'
      WHEN cur.volume > 0
       AND (SELECT v FROM best_vol) IS NOT NULL
       AND cur.volume > (SELECT v FROM best_vol)                        THEN 'volume_record'
      WHEN (SELECT id FROM prev_log) IS NULL                            THEN 'first'
      ELSE                                                                   'volume'
    END AS t
  FROM cur
),

hero_num AS (
  SELECT
    CASE r.t
      WHEN 'pr' THEN p.today_best
      ELSE CASE WHEN cur.volume > 0 THEN cur.volume ELSE st.total_reps END
    END AS v
  FROM cur
  CROSS JOIN cur_stats st
  CROSS JOIN resolved r
  LEFT JOIN top_pr p ON 1 = 1
),

/* "▲ 6.3% vs last Pull day" - empty when nothing to compare to */
delta AS (
  SELECT
    CASE
      WHEN pl.volume IS NULL OR pl.volume = 0 OR cur.volume = 0 THEN ''
      WHEN cur.volume >= pl.volume
        THEN '▲ ' || printf('%.1f', (cur.volume - pl.volume) * 100.0 / pl.volume) || '% vs last ' || cur.workout_name
      ELSE '▼ ' || printf('%.1f', (pl.volume - cur.volume) * 100.0 / pl.volume) || '% vs last ' || cur.workout_name
    END AS s,
    CASE
      WHEN pl.volume IS NULL OR pl.volume = 0 OR cur.volume = 0 THEN 0
      WHEN cur.volume > pl.volume THEN 1
      ELSE -1
    END AS dir,
    CASE
      WHEN pl.duration IS NULL OR pl.duration <= 0 OR cur.duration <= 0 THEN 0
      WHEN cur.duration < pl.duration AND cur.volume >= pl.volume THEN 1
      ELSE 0
    END AS faster
  FROM cur
  LEFT JOIN prev_log pl ON 1 = 1
),

/* "Sat, Sep 6 · 18:42" */
date_fmt AS (
  SELECT
    CASE strftime('%w', cur.created_at)
      WHEN '0' THEN 'Sun' WHEN '1' THEN 'Mon' WHEN '2' THEN 'Tue'
      WHEN '3' THEN 'Wed' WHEN '4' THEN 'Thu' WHEN '5' THEN 'Fri'
      ELSE 'Sat'
    END
    || ', ' ||
    CASE strftime('%m', cur.created_at)
      WHEN '01' THEN 'Jan' WHEN '02' THEN 'Feb' WHEN '03' THEN 'Mar'
      WHEN '04' THEN 'Apr' WHEN '05' THEN 'May' WHEN '06' THEN 'Jun'
      WHEN '07' THEN 'Jul' WHEN '08' THEN 'Aug' WHEN '09' THEN 'Sep'
      WHEN '10' THEN 'Oct' WHEN '11' THEN 'Nov' ELSE 'Dec'
    END
    || ' ' || CAST(CAST(strftime('%d', cur.created_at) AS INTEGER) AS TEXT)
    || ' · ' || strftime('%H:%M', cur.created_at) AS s
  FROM cur
)

SELECT
  cur.workout_name AS workout_name,
  df.s             AS date_text,

  RTRIM(RTRIM(printf('%.2f', hn.v), '0'), '.') AS hero_value,

  CASE
    WHEN r.t = 'pr' OR cur.volume > 0 THEN 'kg'
    ELSE 'reps'
  END AS hero_unit,

  CASE r.t
    WHEN 'pr' THEN p.exercise_name
    ELSE CASE WHEN cur.volume > 0 THEN 'Total volume' ELSE 'Total reps' END
  END AS hero_title,

  CASE r.t
    WHEN 'pr'            THEN 'Previous best ' || RTRIM(RTRIM(printf('%.2f', p.prev_best), '0'), '.') || ' kg'
    WHEN 'volume_record' THEN 'Highest volume for ' || cur.workout_name
    WHEN 'first'         THEN 'First ' || cur.workout_name || ' logged'
    ELSE ''
  END AS hero_subtitle,

  /* badge ladder - always non-empty */
  CASE
    WHEN r.t = 'pr' THEN
      CASE WHEN pc.n = 1 THEN 'NEW PERSONAL RECORD'
           ELSE pc.n || ' NEW PERSONAL RECORDS' END
    WHEN r.t = 'volume_record'                        THEN 'VOLUME RECORD'
    WHEN nm.n > 0 AND r.t <> 'first' THEN
      CASE WHEN nm.n = 1 THEN 'NEW MOVE: ' || UPPER(nm.first_name)
           ELSE nm.n || ' NEW MOVES' END
    WHEN r.t = 'first'                                THEN 'FIRST TIME'
    WHEN d.dir = 1                                    THEN 'UP FROM LAST TIME'
    WHEN d.faster = 1                                 THEN 'FASTER THAN LAST TIME'
    WHEN wn.n IN (10, 25) OR (wn.n >= 50 AND wn.n % 50 = 0)
                                                      THEN 'WORKOUT #' || wn.n
    WHEN tm.muscle IS NOT NULL                        THEN UPPER(tm.muscle) || ' DAY DONE'
    ELSE                                                   'SHOWED UP'
  END AS badge,

  CASE
    WHEN r.t = 'pr' AND d.s <> ''
      THEN RTRIM(RTRIM(printf('%.2f', cur.volume), '0'), '.') || ' kg total · ' || d.s
    WHEN r.t = 'pr' AND cur.volume > 0
      THEN RTRIM(RTRIM(printf('%.2f', cur.volume), '0'), '.') || ' kg total'
    ELSE d.s
  END AS comparison,

  /* duration: m:ss, or h:mm:ss over an hour */
  CASE
    WHEN CAST(cur.duration AS INTEGER) >= 3600
      THEN printf('%d:%02d:%02d',
                  CAST(cur.duration AS INTEGER) / 3600,
                  (CAST(cur.duration AS INTEGER) % 3600) / 60,
                  CAST(cur.duration AS INTEGER) % 60)
    ELSE printf('%d:%02d',
                CAST(cur.duration AS INTEGER) / 60,
                CAST(cur.duration AS INTEGER) % 60)
  END AS duration_text,

  CAST(st.sets_count AS TEXT) AS sets_text,

  /* third stat: form score if any analysis, else total reps */
  CASE
    WHEN f.n > 0 THEN RTRIM(RTRIM(printf('%.1f', f.avg_score), '0'), '.')
    ELSE CAST(st.total_reps AS TEXT)
  END AS stat3_value,

  CASE
    WHEN f.n > 0 THEN 'Form'
    ELSE 'Reps'
  END AS stat3_label,

  /* "5 exercises · 18 sets" */
  CAST(st.exercises_count AS TEXT)
    || CASE WHEN st.exercises_count = 1 THEN ' exercise' ELSE ' exercises' END
    || ' · '
    || CAST(st.sets_count AS TEXT)
    || CASE WHEN st.sets_count = 1 THEN ' set' ELSE ' sets' END
  AS breakdown_label

FROM cur
CROSS JOIN cur_stats st
CROSS JOIN pr_count pc
CROSS JOIN resolved r
CROSS JOIN hero_num hn
CROSS JOIN delta d
CROSS JOIN form f
CROSS JOIN date_fmt df
CROSS JOIN new_moves_agg nm
CROSS JOIN workout_no wn
LEFT JOIN top_muscle tm ON 1 = 1
LEFT JOIN top_pr   p  ON 1 = 1
LEFT JOIN prev_log pl ON 1 = 1;
''';
  return _readQuery(database, query, (d) => WorkoutHeroStatRow(d));
}

class WorkoutHeroStatRow extends SqliteRow {
  WorkoutHeroStatRow(Map<String, dynamic> data) : super(data);

  String get heroValue => data['hero_value'] as String;
  String get heroUnit => data['hero_unit'] as String;
  String get heroTitle => data['hero_title'] as String;
  String get heroSubtitle => data['hero_subtitle'] as String;
  String get badge => data['badge'] as String;
  String get comparison => data['comparison'] as String;
  String get stat3Label => data['stat3_label'] as String;
  String get stat3Value => data['stat3_value'] as String;
  String get durationText => data['duration_text'] as String;
  String get setsText => data['sets_text'] as String;
  String get workoutName => data['workout_name'] as String;
  String get dateText => data['date_text'] as String;
  String get breakdownLabel => data['breakdown_label'] as String;
}

/// END WORKOUTHEROSTAT

/// BEGIN WORKOUTBREAKDOWNSETS
Future<List<WorkoutBreakdownSetsRow>> performWorkoutBreakdownSets(
  Database database, {
  String? workoutLogId,
  String? userId,
}) {
  final query = '''
-- params: ${workoutLogId}, ${userId}
-- ONE ROW PER SET (drop sets included). Exercise-level fields repeat on
-- every row of that exercise. WorkoutBreakdownSheet calls this itself.
-- duration_seconds is stored in MILLISECONDS.

WITH
cur AS (
  SELECT id, workout_id, created_at
  FROM workout_log
  WHERE TRIM(CAST(id AS TEXT)) = TRIM('${workoutLogId}')
),
prev AS (
  SELECT w.id
  FROM workout_log w, cur
  WHERE w.workout_id = cur.workout_id
    AND w.id <> cur.id
    AND w.created_at < cur.created_at
    AND TRIM(CAST(w.user_id AS TEXT)) = TRIM('${userId}')
  ORDER BY w.created_at DESC
  LIMIT 1
),

/* ---------- current sets ---------- */
base AS (
  SELECT
    s.rowid                           AS rid,
    s.id                              AS set_log_id,
    s.exercise_id,
    e.name                            AS exercise_name,
    COALESCE(e.is_time_based, 0)      AS is_timed,
    COALESCE(e.is_bodyweight, 0)      AS is_bodyweight,
    COALESCE(e.is_assisted, 0)        AS is_assisted,
    CAST(s.set_number AS INTEGER)     AS set_number,
    COALESCE(s.is_dropset, 0)         AS is_dropset,
    COALESCE(s.drop_number, 0)        AS drop_number,
    COALESCE(s.reps, 0)               AS reps,
    COALESCE(s.weight, 0)             AS weight,
    COALESCE(s.duration_seconds, 0)   AS dur_ms,
    COALESCE(s.is_kg, 1)              AS is_kg
  FROM set_log s
  JOIN cur ON TRIM(CAST(s.workout_log_id AS TEXT)) = TRIM(CAST(cur.id AS TEXT))
  JOIN exercise e ON e.id = s.exercise_id
),

/* primary muscle per exercise */
muscle AS (
  SELECT emg.exercise_id, MIN(mg.name) AS muscle
  FROM exercise_muscle_group emg
  JOIN muscle_group mg ON mg.id = emg.muscle_group_id
  WHERE COALESCE(emg.is_primary, 0) = 1
  GROUP BY emg.exercise_id
),

/* per-set form score */
scores AS (
  SELECT set_log_id, score
  FROM set_analysis
  WHERE score IS NOT NULL
),

/* historical best weight per exercise (excluding this workout) -> PR flag */
hist AS (
  SELECT s.exercise_id, MAX(COALESCE(s.weight, 0)) AS best
  FROM set_log s, cur
  WHERE TRIM(CAST(s.user_id AS TEXT)) = TRIM('${userId}')
    AND TRIM(CAST(s.workout_log_id AS TEXT)) <> TRIM(CAST(cur.id AS TEXT))
    AND s.exercise_id IN (SELECT exercise_id FROM base)
  GROUP BY s.exercise_id
),

/* ---------- exercise totals (current) ---------- */
ex_agg AS (
  SELECT
    exercise_id,
    MAX(is_timed)      AS is_timed,
    MAX(is_assisted)   AS is_assisted,
    COUNT(CASE WHEN is_dropset = 0 THEN 1 END) AS sets_count,
    CASE WHEN SUM(CASE WHEN weight > 0 THEN 1 END) > 0 THEN 1 ELSE 0 END AS has_weighted,
    SUM(reps) AS sum_reps,
    SUM(CASE WHEN weight > 0 THEN reps * weight ELSE 0 END) AS sum_vol,
    SUM(dur_ms) AS sum_dur_ms,
    CASE
      WHEN SUM(CASE WHEN is_dropset = 0 AND is_kg = 1 THEN 1 ELSE 0 END)
         >= SUM(CASE WHEN is_dropset = 0 AND is_kg = 0 THEN 1 ELSE 0 END)
      THEN 'kg' ELSE 'lbs'
    END AS unit_label
  FROM base
  GROUP BY exercise_id
),
ex_vals AS (
  SELECT
    exercise_id, is_assisted, sets_count, unit_label,
    CASE
      WHEN is_timed = 1       THEN printf('%02d:%02d', CAST(sum_dur_ms / 1000 AS INTEGER) / 60,
                                                        CAST(sum_dur_ms / 1000 AS INTEGER) % 60)
      WHEN is_assisted = 1    THEN CAST(sum_reps AS TEXT) || ' reps'
      WHEN has_weighted = 0   THEN CAST(sum_reps AS TEXT) || ' reps'
      ELSE CAST(CAST(sum_vol AS INTEGER) AS TEXT) || ' ' || unit_label
    END AS exercise_total,
    CASE
      WHEN is_timed = 1       THEN CAST(sum_dur_ms / 1000 AS INTEGER)
      WHEN is_assisted = 1    THEN sum_reps
      WHEN has_weighted = 0   THEN sum_reps
      ELSE CAST(sum_vol AS INTEGER)
    END AS cur_numeric,
    CAST(sum_vol AS REAL) AS cur_assist_vol
  FROM ex_agg
),

/* ---------- exercise totals (previous workout) ---------- */
prev_base AS (
  SELECT
    s.exercise_id,
    COALESCE(e.is_time_based, 0)    AS is_timed,
    COALESCE(e.is_assisted, 0)      AS is_assisted,
    COALESCE(s.reps, 0)             AS reps,
    COALESCE(s.weight, 0)           AS weight,
    COALESCE(s.duration_seconds, 0) AS dur_ms
  FROM set_log s
  JOIN prev ON TRIM(CAST(s.workout_log_id AS TEXT)) = TRIM(CAST(prev.id AS TEXT))
  JOIN exercise e ON e.id = s.exercise_id
),
prev_vals AS (
  SELECT
    exercise_id,
    CASE
      WHEN MAX(is_timed) = 1     THEN CAST(SUM(dur_ms) / 1000 AS INTEGER)
      WHEN MAX(is_assisted) = 1  THEN SUM(reps)
      WHEN SUM(CASE WHEN weight > 0 THEN 1 ELSE 0 END) = 0 THEN SUM(reps)
      ELSE CAST(SUM(CASE WHEN weight > 0 THEN reps * weight ELSE 0 END) AS INTEGER)
    END AS prev_numeric,
    CAST(SUM(CASE WHEN weight > 0 THEN reps * weight ELSE 0 END) AS REAL) AS prev_assist_vol
  FROM prev_base
  GROUP BY exercise_id
)

/* ---------- output: one row per set ---------- */
SELECT
  b.exercise_id,
  b.exercise_name,
  COALESCE(m.muscle, '')                     AS muscle,
  b.is_timed,
  b.is_bodyweight,
  b.is_assisted,
  x.unit_label,
  x.sets_count,
  x.exercise_total,
  CASE
    WHEN x.is_assisted = 1 THEN
      CASE WHEN p.prev_assist_vol IS NULL OR p.prev_assist_vol = 0 THEN NULL
           ELSE CAST(((p.prev_assist_vol - x.cur_assist_vol) * 100.0 / p.prev_assist_vol) AS INTEGER) END
    ELSE
      CASE WHEN p.prev_numeric IS NULL OR p.prev_numeric = 0 THEN NULL
           ELSE CAST(((x.cur_numeric - p.prev_numeric) * 100.0 / p.prev_numeric) AS INTEGER) END
  END                                        AS pct_change,

  b.set_log_id,
  b.set_number,
  b.is_dropset,
  b.drop_number,
  b.reps,
  CAST(b.weight AS REAL)                     AS weight,
  CAST(b.dur_ms / 1000 AS INTEGER)           AS dur_sec,
  sc.score                                   AS set_score,
  CASE
    WHEN b.is_assisted = 0 AND b.weight > 0
     AND h.best IS NOT NULL AND h.best > 0 AND b.weight > h.best
    THEN 1 ELSE 0
  END                                        AS is_pr,

  MIN(b.rid) OVER (PARTITION BY b.exercise_id) AS ex_order

FROM base b
JOIN ex_vals x        ON x.exercise_id = b.exercise_id
LEFT JOIN prev_vals p ON p.exercise_id = b.exercise_id
LEFT JOIN muscle m    ON m.exercise_id = b.exercise_id
LEFT JOIN scores sc   ON sc.set_log_id = b.set_log_id
LEFT JOIN hist h      ON h.exercise_id = b.exercise_id
ORDER BY ex_order, b.set_number, b.is_dropset, b.drop_number;
''';
  return _readQuery(database, query, (d) => WorkoutBreakdownSetsRow(d));
}

class WorkoutBreakdownSetsRow extends SqliteRow {
  WorkoutBreakdownSetsRow(Map<String, dynamic> data) : super(data);

  int get exerciseId => data['exercise_id'] as int;
  String get exerciseName => data['exercise_name'] as String;
  String get muscle => data['muscle'] as String;
  int get isTimed => data['is_timed'] as int;
  int get isBodyweight => data['is_bodyweight'] as int;
  int get isAssisted => data['is_assisted'] as int;
  String get unitLabel => data['unit_label'] as String;
  int get setsCount => data['sets_count'] as int;
  String get exerciseTotal => data['exercise_total'] as String;
  int? get pctChange => data['pct_change'] as int?;
  String get setLogId => data['set_log_id'] as String;
  int get setNumber => data['set_number'] as int;
  int get isDropset => data['is_dropset'] as int;
  int get dropNumber => data['drop_number'] as int;
  int get reps => data['reps'] as int;
  double get weight => data['weight'] as double;
  int get durSec => data['dur_sec'] as int;
  double? get setScore => data['set_score'] as double?;
  int get isPr => data['is_pr'] as int;
  int get exOrder => data['ex_order'] as int;
}

/// END WORKOUTBREAKDOWNSETS

/// BEGIN WEEKWORKOUTDAYS
Future<List<WeekWorkoutDaysRow>> performWeekWorkoutDays(
  Database database, {
  String? userId,
}) {
  final query = '''
-- params: ${userId}
-- One row per workout from the last 8 days. The widget converts each row to a
-- local calendar day and keeps only the current week (8 days = timezone buffer).

SELECT CAST(created_at AS TEXT) AS created_at
FROM workout_log
WHERE TRIM(CAST(user_id AS TEXT)) = TRIM('${userId}')
  AND created_at IS NOT NULL
  AND DATE(replace(CAST(created_at AS TEXT), ' ', 'T')) >= DATE('now', '-8 days')
ORDER BY created_at DESC;
''';
  return _readQuery(database, query, (d) => WeekWorkoutDaysRow(d));
}

class WeekWorkoutDaysRow extends SqliteRow {
  WeekWorkoutDaysRow(Map<String, dynamic> data) : super(data);

  String get createdAt => data['created_at'] as String;
}

/// END WEEKWORKOUTDAYS

/// BEGIN GETEXERCISEANALYSES
Future<List<GetExerciseAnalysesRow>> performGetExerciseAnalyses(
  Database database, {
  String? userId,
  int? exerciseId,
}) {
  final query = '''
SELECT
  sa.id            AS analysis_id,
  sa.set_log_id    AS set_log_id,
  sa.analyzed_at   AS analyzed_at,
  sa.score         AS score,
  sa.total_reps    AS total_reps,
  sa.proper_reps   AS proper_reps,
  sa.feedback      AS feedback,
  sa.technique_label AS technique_label,
  sa.technique_score_display AS technique_score_display,
  sa.form_tip      AS form_tip,
  sl.set_number    AS set_number,
  sl.weight        AS weight,
  sl.reps          AS reps,
  COALESCE(sl.is_kg, 1) AS is_kg,
  wl.id            AS workout_log_id,
  wl.created_at    AS workout_date
FROM set_analysis sa
JOIN set_log sl     ON sl.id = sa.set_log_id
JOIN workout_log wl ON wl.id = sl.workout_log_id
WHERE CAST(sl.exercise_id AS INTEGER) = ${exerciseId}
  AND wl.user_id = '${userId}'
  AND sa.analyzed_at = (
    SELECT MAX(s2.analyzed_at) FROM set_analysis s2
    WHERE s2.set_log_id = sa.set_log_id
  )
ORDER BY sa.analyzed_at ASC;
''';
  return _readQuery(database, query, (d) => GetExerciseAnalysesRow(d));
}

class GetExerciseAnalysesRow extends SqliteRow {
  GetExerciseAnalysesRow(Map<String, dynamic> data) : super(data);

  String get analysisId => data['analysis_id'] as String;
  String get setLogId => data['set_log_id'] as String;
  String get analyzedAt => data['analyzed_at'] as String;
  double? get score => data['score'] as double?;
  int? get totalReps => data['total_reps'] as int?;
  int? get properReps => data['proper_reps'] as int?;
  String? get feedback => data['feedback'] as String?;
  String? get techniqueLabel => data['technique_label'] as String?;
  String? get techniqueScoreDisplay =>
      data['technique_score_display'] as String?;
  String? get formTip => data['form_tip'] as String?;
  double? get avgDepth => data['avg_depth'] as double?;
  String? get repsJson => data['reps_json'] as String?;
  int? get setNumber => data['set_number'] as int?;
  double? get weight => data['weight'] as double?;
  int? get reps => data['reps'] as int?;
  int get isKg => data['is_kg'] as int;
  String get workoutLogId => data['workout_log_id'] as String;
  String? get workoutDate => data['workout_date'] as String?;
}

/// END GETEXERCISEANALYSES
