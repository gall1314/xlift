import '/backend/sqlite/sqlite_manager.dart';
import '/components/restyle_the_existing3_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/instant_timer.dart';
import '/index.dart';
import 'home_page_widget.dart' show HomePageWidget;
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
    show TutorialCoachMark;
import 'package:flutter/material.dart';

class HomePageModel extends FlutterFlowModel<HomePageWidget> {
  ///  Local state fields for this page.

  UserRow? user;

  String? video;

  bool down = true;

  FFUploadedFile? video2;

  List<WorkoutHomeRow> workoutDisplay = [];
  void addToWorkoutDisplay(WorkoutHomeRow item) => workoutDisplay.add(item);
  void removeFromWorkoutDisplay(WorkoutHomeRow item) =>
      workoutDisplay.remove(item);
  void removeAtIndexFromWorkoutDisplay(int index) =>
      workoutDisplay.removeAt(index);
  void insertAtIndexInWorkoutDisplay(int index, WorkoutHomeRow item) =>
      workoutDisplay.insert(index, item);
  void updateWorkoutDisplayAtIndex(
          int index, Function(WorkoutHomeRow) updateFn) =>
      workoutDisplay[index] = updateFn(workoutDisplay[index]);

  int heroIndex = 0;

  ///  State fields for stateful widgets in this page.

  TutorialCoachMark? homeFirstVisitController;
  // Stores action output result for [Custom Action - resetAnalysisQuotaIfNeeded] action in HomePage widget.
  int? count;
  InstantTimer? instantTimer;
  // Model for RestyleTheExisting3 component.
  late RestyleTheExisting3Model restyleTheExisting3Model;
  // Stores action output result for [Backend Call - SQLite (workoutNum)] action in Button widget.
  List<WorkoutNumRow>? workouts;
  // Stores action output result for [Backend Call - SQLite (workoutNum)] action in DashedNewWorkoutButton widget.
  List<WorkoutNumRow>? workoutsCopy;

  @override
  void initState(BuildContext context) {
    restyleTheExisting3Model =
        createModel(context, () => RestyleTheExisting3Model());
  }

  @override
  void dispose() {
    homeFirstVisitController?.finish();
    instantTimer?.cancel();
    restyleTheExisting3Model.dispose();
  }
}
