import 'package:flutter/foundation.dart';

import '/backend/sqlite/init.dart';
import 'queries/read.dart';
import 'queries/update.dart';

import 'package:sqflite/sqflite.dart';
export 'queries/read.dart';
export 'queries/update.dart';

class SQLiteManager {
  SQLiteManager._();

  static SQLiteManager? _instance;
  static SQLiteManager get instance => _instance ??= SQLiteManager._();

  static late Database _database;
  Database get database => _database;

  static Future initialize() async {
    if (kIsWeb) {
      return;
    }
    _database = await initializeDatabaseFromDbFile(
      'xliftoffline',
      'exercises_db_updated_full_(1)_(1)_(1)_(2)_(1)_(1)_(2)_(1).db',
    );
  }

  /// START READ QUERY CALLS

  Future<List<GetdirtyworkoutsRow>> getdirtyworkouts({
    String? userId,
  }) =>
      performGetdirtyworkouts(
        _database,
        userId: userId,
      );

  Future<List<GetAllExercisesRow>> getAllExercises() => performGetAllExercises(
        _database,
      );

  Future<List<UserRow>> user({
    String? userId,
  }) =>
      performUser(
        _database,
        userId: userId,
      );

  Future<List<GetExercisesForWorkoutRow>> getExercisesForWorkout({
    String? workoutId,
  }) =>
      performGetExercisesForWorkout(
        _database,
        workoutId: workoutId,
      );

  Future<List<GetExercisesSimpRow>> getExercisesSimp({
    String? workoutId,
  }) =>
      performGetExercisesSimp(
        _database,
        workoutId: workoutId,
      );

  Future<List<Exercise2Row>> exercise2({
    int? exerciseId,
  }) =>
      performExercise2(
        _database,
        exerciseId: exerciseId,
      );

  Future<List<SmartWorkoutRow>> smartWorkout({
    String? workoutId,
  }) =>
      performSmartWorkout(
        _database,
        workoutId: workoutId,
      );

  Future<List<WorkoutSummaryRow>> workoutSummary({
    String? workoutLogId,
  }) =>
      performWorkoutSummary(
        _database,
        workoutLogId: workoutLogId,
      );

  Future<List<GetLatestWorkoutSummaryRow>> getLatestWorkoutSummary() =>
      performGetLatestWorkoutSummary(
        _database,
      );

  Future<List<GetSetLogsRow>> getSetLogs({
    String? workoutLogId,
    int? exerciseId,
  }) =>
      performGetSetLogs(
        _database,
        workoutLogId: workoutLogId,
        exerciseId: exerciseId,
      );

  Future<List<WorkoutsummaryRow>> workoutsummary({
    String? workoutLogId,
  }) =>
      performWorkoutsummary(
        _database,
        workoutLogId: workoutLogId,
      );

  Future<List<SetlogsimpselectRow>> setlogsimpselect() =>
      performSetlogsimpselect(
        _database,
      );

  Future<List<GetLatestWorkoutBasicRow>> getLatestWorkoutBasic() =>
      performGetLatestWorkoutBasic(
        _database,
      );

  Future<List<SmartWorkout1Row>> smartWorkout1({
    String? userId,
  }) =>
      performSmartWorkout1(
        _database,
        userId: userId,
      );

  Future<List<GetWorkoutTemplateRow>> getWorkoutTemplate() =>
      performGetWorkoutTemplate(
        _database,
      );

  Future<List<GetworkoutExerciseRow>> getworkoutExercise({
    String? workoutId,
  }) =>
      performGetworkoutExercise(
        _database,
        workoutId: workoutId,
      );

  Future<List<PreviosSetRow>> previosSet({
    int? exerciseId,
    int? setNumber,
  }) =>
      performPreviosSet(
        _database,
        exerciseId: exerciseId,
        setNumber: setNumber,
      );

  Future<List<WorkoutSummaryByIdRow>> workoutSummaryById({
    String? workoutLogId,
  }) =>
      performWorkoutSummaryById(
        _database,
        workoutLogId: workoutLogId,
      );

  Future<List<WorkoutLogSummaryByIdRow>> workoutLogSummaryById({
    String? workoutLogId,
  }) =>
      performWorkoutLogSummaryById(
        _database,
        workoutLogId: workoutLogId,
      );

  Future<List<WorkoutLogExercisesInfoByIdRow>> workoutLogExercisesInfoById({
    String? workoutLogId,
  }) =>
      performWorkoutLogExercisesInfoById(
        _database,
        workoutLogId: workoutLogId,
      );

  Future<List<HistoryRow>> history({
    String? userId,
  }) =>
      performHistory(
        _database,
        userId: userId,
      );

  Future<List<GetExerciseMuscleListRow>> getExerciseMuscleList({
    int? exerciseId,
    int? isPrimary,
  }) =>
      performGetExerciseMuscleList(
        _database,
        exerciseId: exerciseId,
        isPrimary: isPrimary,
      );

  Future<List<GetDropSetsRow>> getDropSets({
    String? workoutLogId,
    int? exerciseId,
    int? setNumber,
  }) =>
      performGetDropSets(
        _database,
        workoutLogId: workoutLogId,
        exerciseId: exerciseId,
        setNumber: setNumber,
      );

  Future<List<GetprimaryMuscleGroupRow>> getprimaryMuscleGroup() =>
      performGetprimaryMuscleGroup(
        _database,
      );

  Future<List<Last7DaysStatsRow>> last7DaysStats({
    String? userId,
  }) =>
      performLast7DaysStats(
        _database,
        userId: userId,
      );

  Future<List<LatestWorkoutHomeRow>> latestWorkoutHome({
    String? userId,
  }) =>
      performLatestWorkoutHome(
        _database,
        userId: userId,
      );

  Future<List<HistoryWorkoutListEXRow>> historyWorkoutListEX({
    String? workoutLogId,
  }) =>
      performHistoryWorkoutListEX(
        _database,
        workoutLogId: workoutLogId,
      );

  Future<List<MuscleGroupSammaryRow>> muscleGroupSammary({
    String? workoutLogId,
  }) =>
      performMuscleGroupSammary(
        _database,
        workoutLogId: workoutLogId,
      );

  Future<List<PieGraphRow>> pieGraph({
    String? userId,
    String? timeRange,
  }) =>
      performPieGraph(
        _database,
        userId: userId,
        timeRange: timeRange,
      );

  Future<List<WorkoutCountRow>> workoutCount({
    String? userId,
    String? timeRange,
  }) =>
      performWorkoutCount(
        _database,
        userId: userId,
        timeRange: timeRange,
      );

  Future<List<TopMuscleRow>> topMuscle({
    String? timeRange,
    String? userId,
  }) =>
      performTopMuscle(
        _database,
        timeRange: timeRange,
        userId: userId,
      );

  Future<List<ExerciseSessionComparisomRow>> exerciseSessionComparisom({
    String? userId,
    int? exerciseId,
    int? isPremium,
  }) =>
      performExerciseSessionComparisom(
        _database,
        userId: userId,
        exerciseId: exerciseId,
        isPremium: isPremium,
      );

  Future<List<ExercisePrsRow>> exercisePrs({
    int? exerciseId,
    String? userId,
    String? timeRange,
  }) =>
      performExercisePrs(
        _database,
        exerciseId: exerciseId,
        userId: userId,
        timeRange: timeRange,
      );

  Future<List<Rm1Row>> rm1({
    int? exerciseId,
    String? userId,
    String? timeRange,
  }) =>
      performRm1(
        _database,
        exerciseId: exerciseId,
        userId: userId,
        timeRange: timeRange,
      );

  Future<List<ExerciseStatsRow>> exerciseStats({
    int? exerciseId,
    String? userId,
    String? timeRange,
  }) =>
      performExerciseStats(
        _database,
        exerciseId: exerciseId,
        userId: userId,
        timeRange: timeRange,
      );

  Future<List<ExerciseLineGraphRow>> exerciseLineGraph({
    String? userId,
    int? exerciseId,
    String? timeRange,
  }) =>
      performExerciseLineGraph(
        _database,
        userId: userId,
        exerciseId: exerciseId,
        timeRange: timeRange,
      );

  Future<List<SmartReplaceRow>> smartReplace({
    int? exerciseId,
  }) =>
      performSmartReplace(
        _database,
        exerciseId: exerciseId,
      );

  Future<List<VolumeOverviewRow>> volumeOverview({
    String? userId,
  }) =>
      performVolumeOverview(
        _database,
        userId: userId,
      );

  Future<List<TestRow>> test({
    String? workoutLogId,
  }) =>
      performTest(
        _database,
        workoutLogId: workoutLogId,
      );

  Future<List<MostTimesExerciseRow>> mostTimesExercise({
    String? timeRange,
    String? userId,
  }) =>
      performMostTimesExercise(
        _database,
        timeRange: timeRange,
        userId: userId,
      );

  Future<List<MostImprovedExerciseRow>> mostImprovedExercise({
    String? userId,
    String? timeRange,
  }) =>
      performMostImprovedExercise(
        _database,
        userId: userId,
        timeRange: timeRange,
      );

  Future<List<TotalExercisesForTimeRow>> totalExercisesForTime({
    String? userId,
    String? timeRange,
  }) =>
      performTotalExercisesForTime(
        _database,
        userId: userId,
        timeRange: timeRange,
      );

  Future<List<TopVolumeExerciseRow>> topVolumeExercise({
    String? userId,
    String? timeRange,
  }) =>
      performTopVolumeExercise(
        _database,
        userId: userId,
        timeRange: timeRange,
      );

  Future<List<ExercisePerfprmanceRow>> exercisePerfprmance({
    String? userId,
    String? timeRange,
  }) =>
      performExercisePerfprmance(
        _database,
        userId: userId,
        timeRange: timeRange,
      );

  Future<List<ByMuscleKpiRow>> byMuscleKpi({
    String? muscleName,
    String? rangeLabel,
    String? userId,
  }) =>
      performByMuscleKpi(
        _database,
        muscleName: muscleName,
        rangeLabel: rangeLabel,
        userId: userId,
      );

  Future<List<LastTrainedMuscleRow>> lastTrainedMuscle({
    String? userId,
    String? muscleName,
  }) =>
      performLastTrainedMuscle(
        _database,
        userId: userId,
        muscleName: muscleName,
      );

  Future<List<VolumeByMuscleRow>> volumeByMuscle({
    String? muscleName,
    String? rangeLabel,
    String? userId,
  }) =>
      performVolumeByMuscle(
        _database,
        muscleName: muscleName,
        rangeLabel: rangeLabel,
        userId: userId,
      );

  Future<List<ExerciseByMuscleRow>> exerciseByMuscle({
    String? userId,
    String? muscleName,
    String? rangeLabel,
  }) =>
      performExerciseByMuscle(
        _database,
        userId: userId,
        muscleName: muscleName,
        rangeLabel: rangeLabel,
      );

  Future<List<SubMuscleDistributionRow>> subMuscleDistribution({
    String? userId,
    String? muscleName,
    String? rangeLabel,
  }) =>
      performSubMuscleDistribution(
        _database,
        userId: userId,
        muscleName: muscleName,
        rangeLabel: rangeLabel,
      );

  Future<List<History1Row>> history1({
    String? userId,
    String? workoutLogId,
  }) =>
      performHistory1(
        _database,
        userId: userId,
        workoutLogId: workoutLogId,
      );

  Future<List<GetAllSetsRow>> getAllSets({
    String? workoutLogId,
  }) =>
      performGetAllSets(
        _database,
        workoutLogId: workoutLogId,
      );

  Future<List<WorkoutComparisonRow>> workoutComparison({
    String? workoutLogIdA,
    String? workoutLogIdB,
  }) =>
      performWorkoutComparison(
        _database,
        workoutLogIdA: workoutLogIdA,
        workoutLogIdB: workoutLogIdB,
      );

  Future<List<CompareMuscelsRow>> compareMuscels({
    String? workoutLogIdB,
    String? workoutLogIdA,
  }) =>
      performCompareMuscels(
        _database,
        workoutLogIdB: workoutLogIdB,
        workoutLogIdA: workoutLogIdA,
      );

  Future<List<ExercisesComparisonRow>> exercisesComparison({
    String? workoutLogIdA,
    String? workoutLogIdB,
  }) =>
      performExercisesComparison(
        _database,
        workoutLogIdA: workoutLogIdA,
        workoutLogIdB: workoutLogIdB,
      );

  Future<List<ExercisesForEditRow>> exercisesForEdit({
    String? workoutLogId,
  }) =>
      performExercisesForEdit(
        _database,
        workoutLogId: workoutLogId,
      );

  Future<List<GetMusclesRow>> getMuscles() => performGetMuscles(
        _database,
      );

  Future<List<CorrectedGetExerciceSimpRow>> correctedGetExerciceSimp({
    String? workoutID,
  }) =>
      performCorrectedGetExerciceSimp(
        _database,
        workoutID: workoutID,
      );

  Future<List<CorrectedPreviosSetRow>> correctedPreviosSet({
    int? exerciseId,
    int? setNumber,
    String? userId,
  }) =>
      performCorrectedPreviosSet(
        _database,
        exerciseId: exerciseId,
        setNumber: setNumber,
        userId: userId,
      );

  Future<List<CorrectedLatestWorkoutHomeRow>> correctedLatestWorkoutHome({
    String? userId,
  }) =>
      performCorrectedLatestWorkoutHome(
        _database,
        userId: userId,
      );

  Future<List<GetWorkoutLogRow>> getWorkoutLog({
    String? workoutlogid,
  }) =>
      performGetWorkoutLog(
        _database,
        workoutlogid: workoutlogid,
      );

  Future<List<VolumeOnlyRow>> volumeOnly({
    String? workoutLogId,
  }) =>
      performVolumeOnly(
        _database,
        workoutLogId: workoutLogId,
      );

  Future<List<ExercisesAndDurationRow>> exercisesAndDuration({
    String? workoutLogId,
  }) =>
      performExercisesAndDuration(
        _database,
        workoutLogId: workoutLogId,
      );

  Future<List<GetExercisesMetadataRowRow>> getExercisesMetadataRow({
    List<int>? exerciseIdsList,
  }) =>
      performGetExercisesMetadataRow(
        _database,
        exerciseIdsList: exerciseIdsList,
      );

  Future<List<UnamedWorkoutsRow>> unamedWorkouts({
    String? userId,
  }) =>
      performUnamedWorkouts(
        _database,
        userId: userId,
      );

  Future<List<VolumeOverviewWithRangeRow>> volumeOverviewWithRange({
    String? userId,
    String? rangeLabel,
  }) =>
      performVolumeOverviewWithRange(
        _database,
        userId: userId,
        rangeLabel: rangeLabel,
      );

  Future<List<GetExerciseSetsForWorkoutRow>> getExerciseSetsForWorkout({
    String? workoutId,
  }) =>
      performGetExerciseSetsForWorkout(
        _database,
        workoutId: workoutId,
      );

  Future<List<WorkoutCountSimpleRow>> workoutCountSimple({
    String? userId,
  }) =>
      performWorkoutCountSimple(
        _database,
        userId: userId,
      );

  Future<List<VolumeByTimeRow>> volumeByTime({
    String? timeRange,
    String? userId,
  }) =>
      performVolumeByTime(
        _database,
        timeRange: timeRange,
        userId: userId,
      );

  Future<List<VolumeForMuscleTimeRow>> volumeForMuscleTime({
    String? rangeLabel,
    String? muscleName,
    String? userId,
  }) =>
      performVolumeForMuscleTime(
        _database,
        rangeLabel: rangeLabel,
        muscleName: muscleName,
        userId: userId,
      );

  Future<List<SetsForMuscleByTimeRow>> setsForMuscleByTime({
    String? userId,
    String? muscleName,
    String? rangeLabel,
  }) =>
      performSetsForMuscleByTime(
        _database,
        userId: userId,
        muscleName: muscleName,
        rangeLabel: rangeLabel,
      );

  Future<List<MusclePctChangeRow>> musclePctChange({
    String? userId,
    String? muscleName,
    String? rangeLabel,
  }) =>
      performMusclePctChange(
        _database,
        userId: userId,
        muscleName: muscleName,
        rangeLabel: rangeLabel,
      );

  Future<List<GetRecentExercisesRow>> getRecentExercises({
    String? userId,
  }) =>
      performGetRecentExercises(
        _database,
        userId: userId,
      );

  Future<List<GetUserExercisesRow>> getUserExercises({
    String? currentUserId,
  }) =>
      performGetUserExercises(
        _database,
        currentUserId: currentUserId,
      );

  Future<List<GetSubMuscelsRow>> getSubMuscels({
    int? primaryId,
  }) =>
      performGetSubMuscels(
        _database,
        primaryId: primaryId,
      );

  Future<List<ExercisePrsTimedRow>> exercisePrsTimed({
    String? userId,
    int? exerciseId,
    String? timeRange,
  }) =>
      performExercisePrsTimed(
        _database,
        userId: userId,
        exerciseId: exerciseId,
        timeRange: timeRange,
      );

  Future<List<TimedExerciseLineGraphRow>> timedExerciseLineGraph({
    String? userId,
    int? exerciseId,
    String? timeRange,
  }) =>
      performTimedExerciseLineGraph(
        _database,
        userId: userId,
        exerciseId: exerciseId,
        timeRange: timeRange,
      );

  Future<List<TimeBasedExerciseAnalyticsRow>> timeBasedExerciseAnalytics({
    String? userId,
    int? exerciseId,
    String? timeRange,
  }) =>
      performTimeBasedExerciseAnalytics(
        _database,
        userId: userId,
        exerciseId: exerciseId,
        timeRange: timeRange,
      );

  Future<List<ExercisePrsBodyweightRow>> exercisePrsBodyweight({
    int? exerciseId,
    String? timeRange,
    String? userId,
  }) =>
      performExercisePrsBodyweight(
        _database,
        exerciseId: exerciseId,
        timeRange: timeRange,
        userId: userId,
      );

  Future<List<ExerciseBodyweightLineGraphRow>> exerciseBodyweightLineGraph({
    int? exerciseId,
    String? userId,
    String? timeRange,
  }) =>
      performExerciseBodyweightLineGraph(
        _database,
        exerciseId: exerciseId,
        userId: userId,
        timeRange: timeRange,
      );

  Future<List<BodyweightExerciseAnalyticsRow>> bodyweightExerciseAnalytics({
    int? exerciseId,
    String? userId,
    String? timeRange,
  }) =>
      performBodyweightExerciseAnalytics(
        _database,
        exerciseId: exerciseId,
        userId: userId,
        timeRange: timeRange,
      );

  Future<List<SubMuscelsRow>> subMuscels() => performSubMuscels(
        _database,
      );

  Future<List<DynamicvolumeRow>> dynamicvolume({
    String? workoutLogId,
  }) =>
      performDynamicvolume(
        _database,
        workoutLogId: workoutLogId,
      );

  Future<List<GetPrimaryMuscelsRow>> getPrimaryMuscels() =>
      performGetPrimaryMuscels(
        _database,
      );

  Future<List<HasExerciseDataRow>> hasExerciseData({
    String? timeRange,
    String? userId,
  }) =>
      performHasExerciseData(
        _database,
        timeRange: timeRange,
        userId: userId,
      );

  Future<List<ExercisePrsAssistedRow>> exercisePrsAssisted({
    String? exerciseId,
    String? userId,
    String? timeRange,
  }) =>
      performExercisePrsAssisted(
        _database,
        exerciseId: exerciseId,
        userId: userId,
        timeRange: timeRange,
      );

  Future<List<ExerciseLineGraphAssistedRow>> exerciseLineGraphAssisted({
    int? exerciseId,
    String? userId,
    String? timeRange,
  }) =>
      performExerciseLineGraphAssisted(
        _database,
        exerciseId: exerciseId,
        userId: userId,
        timeRange: timeRange,
      );

  Future<List<AssistedAnalyticsRow>> assistedAnalytics({
    String? userId,
    int? exerciseId,
    String? timeRange,
  }) =>
      performAssistedAnalytics(
        _database,
        userId: userId,
        exerciseId: exerciseId,
        timeRange: timeRange,
      );

  Future<List<WorkoutNumRow>> workoutNum({
    String? userId,
  }) =>
      performWorkoutNum(
        _database,
        userId: userId,
      );

  Future<List<WorkoutsForRoutineRow>> workoutsForRoutine({
    String? workoutId,
    String? userId,
  }) =>
      performWorkoutsForRoutine(
        _database,
        workoutId: workoutId,
        userId: userId,
      );

  Future<List<GetUserExerciseRow>> getUserExercise({
    String? userId,
  }) =>
      performGetUserExercise(
        _database,
        userId: userId,
      );

  Future<List<GetWorklogsCountRow>> getWorklogsCount({
    String? userId,
  }) =>
      performGetWorklogsCount(
        _database,
        userId: userId,
      );

  Future<List<GetMuscleRow>> getMuscle({
    int? id,
  }) =>
      performGetMuscle(
        _database,
        id: id,
      );

  Future<List<GetExerciseRow>> getExercise({
    int? exerciseId,
  }) =>
      performGetExercise(
        _database,
        exerciseId: exerciseId,
      );

  Future<List<GetSetanalysisRow>> getSetanalysis({
    String? setLogId,
  }) =>
      performGetSetanalysis(
        _database,
        setLogId: setLogId,
      );

  Future<List<WorkoutHomeRow>> workoutHome({
    String? userId,
  }) =>
      performWorkoutHome(
        _database,
        userId: userId,
      );

  Future<List<GetUserRow>> getUser({
    String? userId,
  }) =>
      performGetUser(
        _database,
        userId: userId,
      );

  Future<List<GetAiexercisesRow>> getAiexercises() => performGetAiexercises(
        _database,
      );

  Future<List<WorkoutHeroStatRow>> workoutHeroStat({
    String? workoutLogId,
    String? userId,
  }) =>
      performWorkoutHeroStat(
        _database,
        workoutLogId: workoutLogId,
        userId: userId,
      );

  Future<List<WorkoutBreakdownSetsRow>> workoutBreakdownSets({
    String? workoutLogId,
    String? userId,
  }) =>
      performWorkoutBreakdownSets(
        _database,
        workoutLogId: workoutLogId,
        userId: userId,
      );

  Future<List<WeekWorkoutDaysRow>> weekWorkoutDays({
    String? userId,
  }) =>
      performWeekWorkoutDays(
        _database,
        userId: userId,
      );

  /// END READ QUERY CALLS

  /// START UPDATE QUERY CALLS

  Future markWorkoutSynced({
    String? id,
  }) =>
      performMarkWorkoutSynced(
        _database,
        id: id,
      );

  Future updateWorkoutIsDirty({
    String? id,
    int? isDirty,
  }) =>
      performUpdateWorkoutIsDirty(
        _database,
        id: id,
        isDirty: isDirty,
      );

  Future insertWorkout({
    String? id,
    String? name,
    String? createdAt,
    String? userId,
  }) =>
      performInsertWorkout(
        _database,
        id: id,
        name: name,
        createdAt: createdAt,
        userId: userId,
      );

  Future insertWorkoutExercise({
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
  }) =>
      performInsertWorkoutExercise(
        _database,
        id: id,
        workoutId: workoutId,
        createdAt: createdAt,
        order: order,
        exerciseId: exerciseId,
        restSeconds: restSeconds,
        exerciseName: exerciseName,
        userId: userId,
        isSuperset: isSuperset,
        supersetGroupId: supersetGroupId,
      );

  Future insertWorkoutLog({
    String? workoutId,
    String? userId,
    String? createdAt,
    int? durationSeconds,
    int? isDirty,
    String? id,
  }) =>
      performInsertWorkoutLog(
        _database,
        workoutId: workoutId,
        userId: userId,
        createdAt: createdAt,
        durationSeconds: durationSeconds,
        isDirty: isDirty,
        id: id,
      );

  Future insertSetLog({
    String? workoutLogId,
    int? exerciseId,
    int? setNumber,
    int? reps,
    double? weight,
    int? durationSeconds,
    String? createdAt,
  }) =>
      performInsertSetLog(
        _database,
        workoutLogId: workoutLogId,
        exerciseId: exerciseId,
        setNumber: setNumber,
        reps: reps,
        weight: weight,
        durationSeconds: durationSeconds,
        createdAt: createdAt,
      );

  Future insertUser({
    String? id,
    String? username,
    String? email,
    int? isKg,
  }) =>
      performInsertUser(
        _database,
        id: id,
        username: username,
        email: email,
        isKg: isKg,
      );

  Future latestWorkoutSummary() => performLatestWorkoutSummary(
        _database,
      );

  Future setLogTest({
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
  }) =>
      performSetLogTest(
        _database,
        workoutLogId: workoutLogId,
        createdAt: createdAt,
        exerciseId: exerciseId,
        setNumber: setNumber,
        reps: reps,
        weight: weight,
        durationSeconds: durationSeconds,
        isKg: isKg,
        isDropSet: isDropSet,
        dropNumber: dropNumber,
        id: id,
        userId: userId,
      );

  Future lastWeekStata() => performLastWeekStata(
        _database,
      );

  Future latestWorkoutBasic() => performLatestWorkoutBasic(
        _database,
      );

  Future lastWorkoutSummary() => performLastWorkoutSummary(
        _database,
      );

  Future deleteWorex({
    String? workoutId,
  }) =>
      performDeleteWorex(
        _database,
        workoutId: workoutId,
      );

  Future updateWorkout({
    String? workoutId,
    String? newName,
  }) =>
      performUpdateWorkout(
        _database,
        workoutId: workoutId,
        newName: newName,
      );

  Future deleteWorkout({
    String? workoutId,
  }) =>
      performDeleteWorkout(
        _database,
        workoutId: workoutId,
      );

  Future uPDATEWorkoutLogVolume({
    double? newVolume,
    String? workoutLogId,
  }) =>
      performUPDATEWorkoutLogVolume(
        _database,
        newVolume: newVolume,
        workoutLogId: workoutLogId,
      );

  Future exerciseMuscleList() => performExerciseMuscleList(
        _database,
      );

  Future deleteWorkoutLog({
    String? workoutLogId,
  }) =>
      performDeleteWorkoutLog(
        _database,
        workoutLogId: workoutLogId,
      );

  Future deleteSetLogs({
    String? workoutLogId,
  }) =>
      performDeleteSetLogs(
        _database,
        workoutLogId: workoutLogId,
      );

  Future updateWorkoutLog({
    String? workoutLogId,
    String? newDate,
    int? newDuration,
  }) =>
      performUpdateWorkoutLog(
        _database,
        workoutLogId: workoutLogId,
        newDate: newDate,
        newDuration: newDuration,
      );

  Future createUserExercise({
    int? id,
    String? userId,
    String? name,
    String? equipment,
    int? isBodyweight,
    int? isTimed,
    int? allowsBodyweight,
  }) =>
      performCreateUserExercise(
        _database,
        id: id,
        userId: userId,
        name: name,
        equipment: equipment,
        isBodyweight: isBodyweight,
        isTimed: isTimed,
        allowsBodyweight: allowsBodyweight,
      );

  Future insertWorkoutExercise1({
    String? id,
    String? workoutId,
    int? order,
    int? exerciseId,
    String? exerciseName,
    String? userId,
    DateTime? createdAt,
  }) =>
      performInsertWorkoutExercise1(
        _database,
        id: id,
        workoutId: workoutId,
        order: order,
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        userId: userId,
        createdAt: createdAt,
      );

  Future userExerciseMuscleGroup({
    int? id,
    int? muscleGroupId,
    int? exerciseId,
    int? isPrimary,
  }) =>
      performUserExerciseMuscleGroup(
        _database,
        id: id,
        muscleGroupId: muscleGroupId,
        exerciseId: exerciseId,
        isPrimary: isPrimary,
      );

  Future insertExerciseSts({
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
  }) =>
      performInsertExerciseSts(
        _database,
        workoutExerciseId: workoutExerciseId,
        setNumber: setNumber,
        targetReps: targetReps,
        isWarmup: isWarmup,
        isDropset: isDropset,
        dropNumber: dropNumber,
        workoutId: workoutId,
        id: id,
        weighted: weighted,
        durationSeconds: durationSeconds,
      );

  Future worexTest() => performWorexTest(
        _database,
      );

  Future uodateProfile({
    String? profileImage,
    String? userId,
  }) =>
      performUodateProfile(
        _database,
        profileImage: profileImage,
        userId: userId,
      );

  Future updateBodyMesurs({
    int? age,
    double? weight,
    double? height,
    String? userId,
  }) =>
      performUpdateBodyMesurs(
        _database,
        age: age,
        weight: weight,
        height: height,
        userId: userId,
      );

  Future smartWorex({
    String? id,
    String? workoutId,
    String? createdAt,
    int? order,
    String? userId,
    int? restSeconds,
    int? exerciseId,
  }) =>
      performSmartWorex(
        _database,
        id: id,
        workoutId: workoutId,
        createdAt: createdAt,
        order: order,
        userId: userId,
        restSeconds: restSeconds,
        exerciseId: exerciseId,
      );

  Future deleteExerciseSets({
    String? workoutId,
  }) =>
      performDeleteExerciseSets(
        _database,
        workoutId: workoutId,
      );

  Future updateUsersMeasurs({
    double? height,
    double? weight,
    int? heightIsCm,
    int? bodyWeightIsKg,
    String? sex,
    String? dateOfBirth,
    String? userId,
  }) =>
      performUpdateUsersMeasurs(
        _database,
        height: height,
        weight: weight,
        heightIsCm: heightIsCm,
        bodyWeightIsKg: bodyWeightIsKg,
        sex: sex,
        dateOfBirth: dateOfBirth,
        userId: userId,
      );

  Future weeklyroutine({
    String? userId,
    String? routineName,
    int? isActive,
    String? createdAt,
    String? routineId,
  }) =>
      performWeeklyroutine(
        _database,
        userId: userId,
        routineName: routineName,
        isActive: isActive,
        createdAt: createdAt,
        routineId: routineId,
      );

  Future weeklyroutineday({
    String? routineId,
    int? dayIndex,
    String? workoutId,
    int? restHours,
  }) =>
      performWeeklyroutineday(
        _database,
        routineId: routineId,
        dayIndex: dayIndex,
        workoutId: workoutId,
        restHours: restHours,
      );

  Future deleteUserExercise({
    int? exerciseId,
  }) =>
      performDeleteUserExercise(
        _database,
        exerciseId: exerciseId,
      );

  Future deleteWorexUserEx({
    int? exerciseId,
    String? userId,
  }) =>
      performDeleteWorexUserEx(
        _database,
        exerciseId: exerciseId,
        userId: userId,
      );

  Future insertSetANalysis({
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
  }) =>
      performInsertSetANalysis(
        _database,
        id: id,
        setLogId: setLogId,
        analyzedAt: analyzedAt,
        score: score,
        totalReps: totalReps,
        properReps: properReps,
        feedback: feedback,
        techniqueLabel: techniqueLabel,
        techniqueScoreDisplay: techniqueScoreDisplay,
        formTip: formTip,
      );

  Future deleteUser({
    String? userId,
  }) =>
      performDeleteUser(
        _database,
        userId: userId,
      );

  Future insertdeletedWorkout({
    String? id,
    String? name,
    String? createdAt,
    String? userId,
  }) =>
      performInsertdeletedWorkout(
        _database,
        id: id,
        name: name,
        createdAt: createdAt,
        userId: userId,
      );

  Future deletSetAnalysis({
    String? analysisId,
  }) =>
      performDeletSetAnalysis(
        _database,
        analysisId: analysisId,
      );

  Future replaceExerciseInPlan({
    String? workoutId,
    int? oldExerciseId,
    int? newExerciseId,
  }) =>
      performReplaceExerciseInPlan(
        _database,
        workoutId: workoutId,
        oldExerciseId: oldExerciseId,
        newExerciseId: newExerciseId,
      );

  /// END UPDATE QUERY CALLS
}
