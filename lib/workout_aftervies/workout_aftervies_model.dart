import '/backend/sqlite/sqlite_manager.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/instant_timer.dart';
import '/index.dart';
import 'workout_aftervies_widget.dart' show WorkoutAfterviesWidget;
import 'package:flutter/material.dart';

class WorkoutAfterviesModel extends FlutterFlowModel<WorkoutAfterviesWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - SQLite (historyWorkoutListEX)] action in workoutAftervies widget.
  List<HistoryWorkoutListEXRow>? data;
  InstantTimer? instantTimer;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    instantTimer?.cancel();
  }
}
