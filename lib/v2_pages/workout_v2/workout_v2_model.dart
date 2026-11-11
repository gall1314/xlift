import '/backend/sqlite/sqlite_manager.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
    show TutorialCoachMark;
import 'workout_v2_widget.dart' show WorkoutV2Widget;
import 'package:flutter/material.dart';

class WorkoutV2Model extends FlutterFlowModel<WorkoutV2Widget> {
  ///  Local state fields for this page.

  bool restEnabled = true;

  ///  State fields for stateful widgets in this page.

  TutorialCoachMark? workoutFirstController;
  // Stores action output result for [Backend Call - SQLite (getExercisesSimp)] action in workoutV2 widget.
  List<GetExercisesSimpRow>? simp;
  // Stores action output result for [Backend Call - SQLite (getExerciseSetsForWorkout)] action in workoutV2 widget.
  List<GetExerciseSetsForWorkoutRow>? sets;
  // Stores action output result for [Custom Action - initializeExerciseSetsFromSimpleQueryV2] action in workoutV2 widget.
  List<dynamic>? set1;
  // Stores action output result for [Custom Action - initializeDropSetsFromSave] action in workoutV2 widget.
  List<dynamic>? drops;
  // Stores action output result for [Custom Action - initializeExerciseRestTimes] action in workoutV2 widget.
  dynamic rest1;
  // Stores action output result for [Custom Action - saveWorkoutComplete] action in WorkoutPage widget.
  dynamic saveCopy;
  // Stores action output result for [Custom Action - removeExerciseFromExerciseSets] action in WorkoutPage widget.
  List<dynamic>? remove;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    workoutFirstController?.finish();
  }
}
