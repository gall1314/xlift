import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'add_exercises_mid_seission_copy_widget.dart'
    show AddExercisesMidSeissionCopyWidget;
import 'package:flutter/material.dart';

class AddExercisesMidSeissionCopyModel
    extends FlutterFlowModel<AddExercisesMidSeissionCopyWidget> {
  ///  Local state fields for this page.

  List<dynamic> selected = [];
  void addToSelected(dynamic item) => selected.add(item);
  void removeFromSelected(dynamic item) => selected.remove(item);
  void removeAtIndexFromSelected(int index) => selected.removeAt(index);
  void insertAtIndexInSelected(int index, dynamic item) =>
      selected.insert(index, item);
  void updateSelectedAtIndex(int index, Function(dynamic) updateFn) =>
      selected[index] = updateFn(selected[index]);

  String primaryMuscle = 'All';

  String subMuscle = 'All';

  bool showSubMuscleDropdown = false;

  String? query;

  int? primaryId;

  bool aiOnly = false;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - addExercisesToExerciseSetsInWorkout] action in ExercisePickerView widget.
  List<dynamic>? added;
  // Stores action output result for [Custom Action - addExercisesToRestTimes] action in ExercisePickerView widget.
  dynamic rest0;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
