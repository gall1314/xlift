import '/auth/supabase_auth/auth_util.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';

Future initSyncBlock(BuildContext context) async {
  bool? hasCopy;

  hasCopy = await actions.checkInternet();
  FFAppState().hasConnection = hasCopy;
}

Future restore(BuildContext context) async {
  dynamic user;
  List<WorkoutRow>? workout;
  List<dynamic>? workoutExercise;
  List<dynamic>? workoutLogs;
  List<dynamic>? exerciseSets;
  List<dynamic>? setlogs;

  user = await actions.fetchUserDirect(
    currentUserUid,
  );
  FFAppState().user = functions.buildUserAppState(user!);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        user!.toString(),
        style: TextStyle(),
      ),
      duration: Duration(milliseconds: 4000),
      backgroundColor: FlutterFlowTheme.of(context).secondary,
    ),
  );
  await actions.restoreAnalysisQuota();
  workout = await WorkoutTable().queryRows(
    queryFn: (q) => q
        .eqOrNull(
          'user_id',
          currentUserUid,
        )
        .eqOrNull(
          'is_deleted',
          0,
        ),
  );
  for (int loop1Index = 0;
      loop1Index < workout.map((e) => e).toList().length;
      loop1Index++) {
    final currentLoop1Item = workout.map((e) => e).toList()[loop1Index];
    await SQLiteManager.instance.insertWorkout(
      id: currentLoop1Item.id,
      name: currentLoop1Item.name!,
      createdAt: currentLoop1Item.createdAt.toString(),
      userId: currentUserUid,
    );
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        workout.firstOrNull!.name!,
        style: TextStyle(),
      ),
      duration: Duration(milliseconds: 4000),
      backgroundColor: FlutterFlowTheme.of(context).secondary,
    ),
  );
  workoutExercise = await actions.fetchWorkoutExercisesDirect(
    currentUserUid,
  );
  for (int loop2Index = 0;
      loop2Index < workoutExercise.map((e) => e).toList().length;
      loop2Index++) {
    final currentLoop2Item =
        workoutExercise.map((e) => e).toList()[loop2Index];
    await SQLiteManager.instance.insertWorkoutExercise(
      id: getJsonField(
        currentLoop2Item,
        r'''$["id"]''',
      ).toString(),
      workoutId: getJsonField(
        currentLoop2Item,
        r'''$["workout_id"]''',
      ).toString(),
      createdAt: getJsonField(
        currentLoop2Item,
        r'''$["created_at"]''',
      ).toString(),
      order: getJsonField(
        currentLoop2Item,
        r'''$["order"]''',
      ),
      exerciseId: getJsonField(
        currentLoop2Item,
        r'''$["order"]''',
      ),
      restSeconds: getJsonField(
        currentLoop2Item,
        r'''$["rest_seconds"]''',
      ),
      exerciseName: getJsonField(
        currentLoop2Item,
        r'''$["exercise_name"]''',
      ).toString(),
      userId: currentUserUid,
      isSuperset: getJsonField(
        currentLoop2Item,
        r'''$["is_superset"]''',
      ),
      supersetGroupId: getJsonField(
        currentLoop2Item,
        r'''$["superset_group_id"]''',
      ).toString(),
    );
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        workoutExercise.firstOrNull!.toString(),
        style: TextStyle(),
      ),
      duration: Duration(milliseconds: 4000),
      backgroundColor: FlutterFlowTheme.of(context).secondary,
    ),
  );
  workoutLogs = await actions.fetchWorkoutLogsDirect(
    currentUserUid,
  );
  for (int loop3Index = 0;
      loop3Index < workoutLogs.map((e) => e).toList().length;
      loop3Index++) {
    final currentLoop3Item = workoutLogs.map((e) => e).toList()[loop3Index];
    await SQLiteManager.instance.insertWorkoutLog(
      workoutId: getJsonField(
        currentLoop3Item,
        r'''$["workout_id"]''',
      ).toString(),
      userId: currentUserUid,
      createdAt: getJsonField(
        currentLoop3Item,
        r'''$["created_at"]''',
      ).toString(),
      durationSeconds: getJsonField(
        currentLoop3Item,
        r'''$["duration"]''',
      ),
      isDirty: 0,
      id: getJsonField(
        currentLoop3Item,
        r'''$["id"]''',
      ).toString(),
    );
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        workoutLogs.firstOrNull!.toString(),
        style: TextStyle(),
      ),
      duration: Duration(milliseconds: 4000),
      backgroundColor: FlutterFlowTheme.of(context).secondary,
    ),
  );
  exerciseSets = await actions.fetchExerciseSetsDirect(
    currentUserUid,
  );
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'exercise sets',
        style: TextStyle(),
      ),
      duration: Duration(milliseconds: 4000),
      backgroundColor: FlutterFlowTheme.of(context).secondary,
    ),
  );
  for (int loop4Index = 0;
      loop4Index < exerciseSets.map((e) => e).toList().length;
      loop4Index++) {
    final currentLoop4Item = exerciseSets.map((e) => e).toList()[loop4Index];
    await SQLiteManager.instance.insertExerciseSts(
      workoutExerciseId: getJsonField(
        currentLoop4Item,
        r'''$["workout_exercise_id"]''',
      ).toString(),
      setNumber: getJsonField(
        currentLoop4Item,
        r'''$["set_number"]''',
      ),
      targetReps: getJsonField(
        currentLoop4Item,
        r'''$["target_reps"]''',
      ),
      isWarmup: getJsonField(
        currentLoop4Item,
        r'''$["is_warmup"]''',
      ),
      isDropset: getJsonField(
        currentLoop4Item,
        r'''$["is_dropset"]''',
      ),
      dropNumber: getJsonField(
        currentLoop4Item,
        r'''$["drop_number"]''',
      ),
      workoutId: getJsonField(
        currentLoop4Item,
        r'''$["workout_id"]''',
      ).toString(),
      id: getJsonField(
        currentLoop4Item,
        r'''$["id"]''',
      ).toString(),
      weighted: getJsonField(
        currentLoop4Item,
        r'''$["weighted"]''',
      ),
      durationSeconds: getJsonField(
        currentLoop4Item,
        r'''$["duration_seconds "]''',
      ),
    );
  }
  setlogs = await actions.fetchSetLogsDirect(
    currentUserUid,
  );
  for (int loop5Index = 0;
      loop5Index < setlogs.map((e) => e).toList().length;
      loop5Index++) {
    final currentLoop5Item = setlogs.map((e) => e).toList()[loop5Index];
    await SQLiteManager.instance.setLogTest(
      workoutLogId: getJsonField(
        currentLoop5Item,
        r'''$["workout_log_id"]''',
      ).toString(),
      createdAt: getJsonField(
        currentLoop5Item,
        r'''$["created_at"]''',
      ).toString(),
      exerciseId: getJsonField(
        currentLoop5Item,
        r'''$["exercise_id"]''',
      ),
      setNumber: getJsonField(
        currentLoop5Item,
        r'''$["set_number"]''',
      ),
      reps: getJsonField(
        currentLoop5Item,
        r'''$["reps"]''',
      ),
      weight: getJsonField(
        currentLoop5Item,
        r'''$["weight"]''',
      ),
      durationSeconds: getJsonField(
        currentLoop5Item,
        r'''$["duration_seconds"]''',
      ),
      isKg: getJsonField(
        currentLoop5Item,
        r'''$["is_kg"]''',
      ),
      isDropSet: getJsonField(
        currentLoop5Item,
        r'''$["is_dropset"]''',
      ),
      dropNumber: getJsonField(
        currentLoop5Item,
        r'''$["drop_number"]''',
      ),
      id: getJsonField(
        currentLoop5Item,
        r'''$["id"]''',
      ).toString(),
      userId: currentUserUid,
    );
  }
}
