import '/backend/sqlite/sqlite_manager.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'select_workouts_widget.dart' show SelectWorkoutsWidget;
import 'package:flutter/material.dart';

class SelectWorkoutsModel extends FlutterFlowModel<SelectWorkoutsWidget> {
  ///  Local state fields for this page.

  List<String> workouts = [];
  void addToWorkouts(String item) => workouts.add(item);
  void removeFromWorkouts(String item) => workouts.remove(item);
  void removeAtIndexFromWorkouts(int index) => workouts.removeAt(index);
  void insertAtIndexInWorkouts(int index, String item) =>
      workouts.insert(index, item);
  void updateWorkoutsAtIndex(int index, Function(String) updateFn) =>
      workouts[index] = updateFn(workouts[index]);

  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // State field(s) for muscleDropdown widget.
  String? muscleDropdownValue;
  FormFieldController<String>? muscleDropdownValueController;
  // State field(s) for Checkbox widget.
  Map<GetdirtyworkoutsRow, bool> checkboxValueMap = {};
  List<GetdirtyworkoutsRow> get checkboxCheckedItems =>
      checkboxValueMap.entries.where((e) => e.value).map((e) => e.key).toList();

  // Stores action output result for [Custom Action - initializeWorkoutScheduleState] action in Button widget.
  List<dynamic>? init;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
