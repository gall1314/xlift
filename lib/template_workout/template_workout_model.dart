import '/backend/sqlite/sqlite_manager.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/instant_timer.dart';
import '/index.dart';
import 'template_workout_widget.dart' show TemplateWorkoutWidget;
import 'package:flutter/material.dart';

class TemplateWorkoutModel extends FlutterFlowModel<TemplateWorkoutWidget> {
  ///  Local state fields for this page.

  WorkoutTemplateRow? workoutTemplate;

  ///  State fields for stateful widgets in this page.

  InstantTimer? instantTimerHome;
  // Stores action output result for [Backend Call - SQLite (getworkoutExercise)] action in Button widget.
  List<GetworkoutExerciseRow>? exrecises;
  // Stores action output result for [Custom Action - generateUuidV4] action in Button widget.
  String? uuid;
  // Stores action output result for [Custom Action - generateUuidV4] action in Button widget.
  String? uuid2;
  // Stores action output result for [Backend Call - SQLite (getExerciseSetsForWorkout)] action in Button widget.
  List<GetExerciseSetsForWorkoutRow>? sets;
  // Stores action output result for [Custom Action - generateUuidV4] action in Button widget.
  String? uuid3;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    instantTimerHome?.cancel();
  }
}
