import '/backend/sqlite/sqlite_manager.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/instant_timer.dart';
import '/index.dart';
import 'workout_afterview_widget.dart' show WorkoutAfterviewWidget;
import 'package:flutter/material.dart';

class WorkoutAfterviewModel extends FlutterFlowModel<WorkoutAfterviewWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - SQLite (historyWorkoutListEX)] action in workoutAfterview widget.
  List<HistoryWorkoutListEXRow>? data;
  InstantTimer? instantTimer;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    instantTimer?.cancel();
  }
}
