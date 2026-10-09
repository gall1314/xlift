import '/backend/sqlite/sqlite_manager.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/instant_timer.dart';
import '/index.dart';
import 'workout_log_edit_v2_widget.dart' show WorkoutLogEditV2Widget;
import 'package:flutter/material.dart';

class WorkoutLogEditV2Model extends FlutterFlowModel<WorkoutLogEditV2Widget> {
  ///  Local state fields for this page.

  String? date;

  int? durationMs;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - SQLite (getAllSets)] action in workoutLogEditV2 widget.
  List<GetAllSetsRow>? sets;
  // Stores action output result for [Backend Call - SQLite (exercisesForEdit)] action in workoutLogEditV2 widget.
  List<ExercisesForEditRow>? exEdit;
  // Stores action output result for [Custom Action - buildExerciseSetsForEdit] action in workoutLogEditV2 widget.
  List<dynamic>? set1;
  // Stores action output result for [Custom Action - buildLoggedSetsCheckedFromGetAllSets] action in workoutLogEditV2 widget.
  List<dynamic>? logged;
  // Stores action output result for [Custom Action - initializeDropSetsFromSetLog] action in workoutLogEditV2 widget.
  List<dynamic>? drop1;
  // Stores action output result for [Backend Call - SQLite (history 1)] action in workoutLogEditV2 widget.
  List<History1Row>? workoutLog;
  InstantTimer? instantTimerHome;
  // Stores action output result for [Custom Action - getAllSets] action in Button widget.
  List<dynamic>? setsk;
  // Stores action output result for [Custom Action - generateUuidV4] action in Button widget.
  String? uuid;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    instantTimerHome?.cancel();
  }
}
