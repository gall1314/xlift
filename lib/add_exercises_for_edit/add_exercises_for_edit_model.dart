import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/instant_timer.dart';
import '/index.dart';
import 'add_exercises_for_edit_widget.dart' show AddExercisesForEditWidget;
import 'package:flutter/material.dart';

class AddExercisesForEditModel
    extends FlutterFlowModel<AddExercisesForEditWidget> {
  ///  Local state fields for this page.

  List<int> selected = [];
  void addToSelected(int item) => selected.add(item);
  void removeFromSelected(int item) => selected.remove(item);
  void removeAtIndexFromSelected(int index) => selected.removeAt(index);
  void insertAtIndexInSelected(int index, int item) =>
      selected.insert(index, item);
  void updateSelectedAtIndex(int index, Function(int) updateFn) =>
      selected[index] = updateFn(selected[index]);

  String primaryMuscle = 'All';

  String subMuscle = 'All';

  bool showSubMuscleDropdown = false;

  String? query;

  int? primaryId;

  bool aiOnly = false;

  ///  State fields for stateful widgets in this page.

  InstantTimer? instantTimerHome;
  // Stores action output result for [Custom Action - syncExerciseSetsWithSelectedIds] action in ExercisePickerView widget.
  List<dynamic>? updatedListCopy;
  // Stores action output result for [Custom Action - syncExerciseRestTimesWithSelectedIds] action in ExercisePickerView widget.
  dynamic newRestCopy;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    instantTimerHome?.cancel();
  }
}
