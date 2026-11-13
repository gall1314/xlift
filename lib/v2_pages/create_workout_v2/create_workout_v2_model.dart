import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'create_workout_v2_widget.dart' show CreateWorkoutV2Widget;
import 'package:flutter/material.dart';

class CreateWorkoutV2Model extends FlutterFlowModel<CreateWorkoutV2Widget> {
  ///  Local state fields for this page.

  bool shouldInit = false;

  String? workoutName;

  bool show = false;

  List<dynamic> selected = [];
  void addToSelected(dynamic item) => selected.add(item);
  void removeFromSelected(dynamic item) => selected.remove(item);
  void removeAtIndexFromSelected(int index) => selected.removeAt(index);
  void insertAtIndexInSelected(int index, dynamic item) =>
      selected.insert(index, item);
  void updateSelectedAtIndex(int index, Function(dynamic) updateFn) =>
      selected[index] = updateFn(selected[index]);

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - saveWorkoutTemplate] action in WorkoutPage widget.
  dynamic saveCopy;
  // Stores action output result for [Custom Action - saveWorkoutTemplate] action in WorkoutPage widget.
  dynamic saveCopy2;
  // Stores action output result for [Custom Action - removeExerciseFromExerciseSets] action in WorkoutPage widget.
  List<dynamic>? remove;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
