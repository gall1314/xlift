import '/components/exercise_stat_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'exercise_card2_widget.dart' show ExerciseCard2Widget;
import 'package:flutter/material.dart';

class ExerciseCard2Model extends FlutterFlowModel<ExerciseCard2Widget> {
  ///  State fields for stateful widgets in this component.

  // Model for ExerciseStat.
  late ExerciseStatModel exerciseStatModel1;
  // Model for ExerciseStat.
  late ExerciseStatModel exerciseStatModel2;

  @override
  void initState(BuildContext context) {
    exerciseStatModel1 = createModel(context, () => ExerciseStatModel());
    exerciseStatModel2 = createModel(context, () => ExerciseStatModel());
  }

  @override
  void dispose() {
    exerciseStatModel1.dispose();
    exerciseStatModel2.dispose();
  }
}
