import '/components/set_row2_for_creation_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'exercise_componet_for_creation_widget.dart'
    show ExerciseComponetForCreationWidget;
import 'package:flutter/material.dart';

class ExerciseComponetForCreationModel
    extends FlutterFlowModel<ExerciseComponetForCreationWidget> {
  ///  Local state fields for this component.

  bool complete = false;

  bool restTime = false;

  bool showWormUp = false;

  ///  State fields for stateful widgets in this component.

  // Models for setRow2ForCreation dynamic component.
  late FlutterFlowDynamicModels<SetRow2ForCreationModel>
      setRow2ForCreationModels;
  // Stores action output result for [Custom Action - addSetToExercise] action in Button widget.
  List<dynamic>? addSet;

  @override
  void initState(BuildContext context) {
    setRow2ForCreationModels =
        FlutterFlowDynamicModels(() => SetRow2ForCreationModel());
  }

  @override
  void dispose() {
    setRow2ForCreationModels.dispose();
  }
}
