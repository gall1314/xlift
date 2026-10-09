import '/components/set_row_edit_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'exercise_compone_for_edit_widget.dart'
    show ExerciseComponeForEditWidget;
import 'package:flutter/material.dart';

class ExerciseComponeForEditModel
    extends FlutterFlowModel<ExerciseComponeForEditWidget> {
  ///  Local state fields for this component.

  bool complete = false;

  bool restTime = false;

  bool showWormUp = false;

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Custom Action - markExerciseCompleted] action in IconButton widget.
  List<dynamic>? completExercise;
  // Models for setRowEdit dynamic component.
  late FlutterFlowDynamicModels<SetRowEditModel> setRowEditModels;
  // Stores action output result for [Custom Action - addSetToExercise] action in Button widget.
  List<dynamic>? addSet;

  @override
  void initState(BuildContext context) {
    setRowEditModels = FlutterFlowDynamicModels(() => SetRowEditModel());
  }

  @override
  void dispose() {
    setRowEditModels.dispose();
  }
}
