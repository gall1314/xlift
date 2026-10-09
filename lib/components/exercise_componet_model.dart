import '/components/set_row2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'exercise_componet_widget.dart' show ExerciseComponetWidget;
import 'package:flutter/material.dart';

class ExerciseComponetModel extends FlutterFlowModel<ExerciseComponetWidget> {
  ///  Local state fields for this component.

  bool complete = false;

  bool restTime = true;

  bool showWormUp = false;

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Custom Action - markExerciseCompletedV2] action in IconButton widget.
  List<dynamic>? mark2;
  // Stores action output result for [Custom Action - setExerciseComplete] action in IconButton widget.
  List<dynamic>? comp;
  // Stores action output result for [Custom Action - setExerciseComplete] action in IconButton widget.
  List<dynamic>? compno;
  // Models for setRow2 dynamic component.
  late FlutterFlowDynamicModels<SetRow2Model> setRow2Models;
  // Stores action output result for [Custom Action - addSetToExercise] action in Button widget.
  List<dynamic>? addSet;

  @override
  void initState(BuildContext context) {
    setRow2Models = FlutterFlowDynamicModels(() => SetRow2Model());
  }

  @override
  void dispose() {
    setRow2Models.dispose();
  }
}
