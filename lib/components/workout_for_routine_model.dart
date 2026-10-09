import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'workout_for_routine_widget.dart' show WorkoutForRoutineWidget;
import 'package:flutter/material.dart';

class WorkoutForRoutineModel extends FlutterFlowModel<WorkoutForRoutineWidget> {
  ///  Local state fields for this component.

  int timesAweek = 1;

  ///  State fields for stateful widgets in this component.

  // State field(s) for DropDown widget.
  int? dropDownValue1;
  FormFieldController<int>? dropDownValueController1;
  // Stores action output result for [Custom Action - updateWorkoutScheduleItem] action in DropDown widget.
  List<dynamic>? upd;
  // State field(s) for DropDown widget.
  int? dropDownValue2;
  FormFieldController<int>? dropDownValueController2;
  // Stores action output result for [Custom Action - updateWorkoutScheduleItem] action in DropDown widget.
  List<dynamic>? updCopy;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
