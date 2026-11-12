import '/backend/sqlite/sqlite_manager.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'edit_workout_v2_widget.dart' show EditWorkoutV2Widget;
import 'package:flutter/material.dart';

class EditWorkoutV2Model extends FlutterFlowModel<EditWorkoutV2Widget> {
  ///  Local state fields for this page.

  bool shouldInit = false;

  String? workoutName;

  bool show = false;

  bool nameError = false;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - SQLite (getExercisesSimp)] action in editWorkoutV2 widget.
  List<GetExercisesSimpRow>? simp;
  // Stores action output result for [Backend Call - SQLite (getExerciseSetsForWorkout)] action in editWorkoutV2 widget.
  List<GetExerciseSetsForWorkoutRow>? sets;
  // Stores action output result for [Custom Action - initializeExerciseSetsForEdit] action in editWorkoutV2 widget.
  List<dynamic>? set1;
  // Stores action output result for [Custom Action - initializeDropSetsFromSave] action in editWorkoutV2 widget.
  List<dynamic>? drop1;
  // Stores action output result for [Custom Action - initializeExerciseRestTimes] action in editWorkoutV2 widget.
  dynamic rest1;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
