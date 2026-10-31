import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/instant_timer.dart';
import '/index.dart';
import 'add_exercises_v3_copy_widget.dart' show AddExercisesV3CopyWidget;
import 'package:flutter/material.dart';

class AddExercisesV3CopyModel
    extends FlutterFlowModel<AddExercisesV3CopyWidget> {
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

  InstantTimer? instantTimerHome;
  // Stores action output result for [Custom Action - initializeWorkoutExerciseSetsFromSelection] action in ExercisePickerView widget.
  List<dynamic>? add;
  // Stores action output result for [Custom Action - initializeExerciseRestTimes] action in ExercisePickerView widget.
  dynamic rest1;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    instantTimerHome?.cancel();
  }
}
