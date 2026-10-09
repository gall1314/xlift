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
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Custom Action - generateUuidV4] action in Button widget.
  String? uuid;
  // Stores action output result for [Custom Action - attachWorkoutExerciseIdToExerciseSets] action in Button widget.
  List<dynamic>? exsetsAttac;
  // Stores action output result for [Custom Action - attachWorkoutExerciseIdToDropSets] action in Button widget.
  List<dynamic>? dropattach;
  // Stores action output result for [Custom Action - mergeLoggedExerciseAndDropSetsForEdit] action in Button widget.
  List<dynamic>? full;
  // Stores action output result for [Custom Action - generateUuidV4] action in Button widget.
  String? uuid2;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
