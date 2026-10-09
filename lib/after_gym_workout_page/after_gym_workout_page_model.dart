import '/components/exercise_row_widget.dart';
import '/components/stat_card_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'after_gym_workout_page_widget.dart' show AfterGymWorkoutPageWidget;
import 'package:flutter/material.dart';

class AfterGymWorkoutPageModel
    extends FlutterFlowModel<AfterGymWorkoutPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for StatCard.
  late StatCardModel statCardModel1;
  // Model for StatCard.
  late StatCardModel statCardModel2;
  // Model for StatCard.
  late StatCardModel statCardModel3;
  // Model for StatCard.
  late StatCardModel statCardModel4;
  // Model for ExerciseRow.
  late ExerciseRowModel exerciseRowModel1;
  // Model for ExerciseRow.
  late ExerciseRowModel exerciseRowModel2;
  // Model for ExerciseRow.
  late ExerciseRowModel exerciseRowModel3;
  // Model for ExerciseRow.
  late ExerciseRowModel exerciseRowModel4;

  @override
  void initState(BuildContext context) {
    statCardModel1 = createModel(context, () => StatCardModel());
    statCardModel2 = createModel(context, () => StatCardModel());
    statCardModel3 = createModel(context, () => StatCardModel());
    statCardModel4 = createModel(context, () => StatCardModel());
    exerciseRowModel1 = createModel(context, () => ExerciseRowModel());
    exerciseRowModel2 = createModel(context, () => ExerciseRowModel());
    exerciseRowModel3 = createModel(context, () => ExerciseRowModel());
    exerciseRowModel4 = createModel(context, () => ExerciseRowModel());
  }

  @override
  void dispose() {
    statCardModel1.dispose();
    statCardModel2.dispose();
    statCardModel3.dispose();
    statCardModel4.dispose();
    exerciseRowModel1.dispose();
    exerciseRowModel2.dispose();
    exerciseRowModel3.dispose();
    exerciseRowModel4.dispose();
  }
}
