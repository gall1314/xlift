import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'add_exercises_for_worklog_edit_widget.dart'
    show AddExercisesForWorklogEditWidget;
import 'package:flutter/material.dart';

class AddExercisesForWorklogEditModel
    extends FlutterFlowModel<AddExercisesForWorklogEditWidget> {
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

  bool? aiOnly = false;

  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Custom Action - addExercisesToExerciseSetsInWorkout] action in Button widget.
  List<dynamic>? added;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
