import '/flutter_flow/flutter_flow_timer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'set_row_data_widget.dart' show SetRowDataWidget;
import 'package:flutter/material.dart';

class SetRowDataModel extends FlutterFlowModel<SetRowDataWidget> {
  ///  Local state fields for this component.

  bool isChecked = false;

  int? weightValue;

  bool timeOn = false;

  bool showTimer = true;

  int? currentDurationSeconds;

  int? timervalue2;

  int? repsValue;

  dynamic setData;

  bool isCheckedFalse = false;

  List<dynamic> loggedSets = [];
  void addToLoggedSets(dynamic item) => loggedSets.add(item);
  void removeFromLoggedSets(dynamic item) => loggedSets.remove(item);
  void removeAtIndexFromLoggedSets(int index) => loggedSets.removeAt(index);
  void insertAtIndexInLoggedSets(int index, dynamic item) =>
      loggedSets.insert(index, item);
  void updateLoggedSetsAtIndex(int index, Function(dynamic) updateFn) =>
      loggedSets[index] = updateFn(loggedSets[index]);

  ///  State fields for stateful widgets in this component.

  // State field(s) for RepsField widget.
  FocusNode? repsFieldFocusNode;
  TextEditingController? repsFieldTextController;
  String? Function(BuildContext, String?)? repsFieldTextControllerValidator;
  // State field(s) for Timer widget.
  final timerInitialTimeMs = 0;
  int timerMilliseconds = 0;
  String timerValue = StopWatchTimer.getDisplayTime(
    0,
    hours: false,
    milliSecond: false,
  );
  FlutterFlowTimerController timerController =
      FlutterFlowTimerController(StopWatchTimer(mode: StopWatchMode.countUp));

  // State field(s) for minutesTens widget.
  FocusNode? minutesTensFocusNode;
  TextEditingController? minutesTensTextController;
  String? Function(BuildContext, String?)? minutesTensTextControllerValidator;
  // State field(s) for minutesUnits widget.
  FocusNode? minutesUnitsFocusNode;
  TextEditingController? minutesUnitsTextController;
  String? Function(BuildContext, String?)? minutesUnitsTextControllerValidator;
  // State field(s) for secondsTens widget.
  FocusNode? secondsTensFocusNode;
  TextEditingController? secondsTensTextController;
  String? Function(BuildContext, String?)? secondsTensTextControllerValidator;
  // State field(s) for secondsUnits widget.
  FocusNode? secondsUnitsFocusNode;
  TextEditingController? secondsUnitsTextController;
  String? Function(BuildContext, String?)? secondsUnitsTextControllerValidator;
  // State field(s) for WeightField widget.
  FocusNode? weightFieldFocusNode;
  TextEditingController? weightFieldTextController;
  String? Function(BuildContext, String?)? weightFieldTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    repsFieldFocusNode?.dispose();
    repsFieldTextController?.dispose();

    timerController.dispose();
    minutesTensFocusNode?.dispose();
    minutesTensTextController?.dispose();

    minutesUnitsFocusNode?.dispose();
    minutesUnitsTextController?.dispose();

    secondsTensFocusNode?.dispose();
    secondsTensTextController?.dispose();

    secondsUnitsFocusNode?.dispose();
    secondsUnitsTextController?.dispose();

    weightFieldFocusNode?.dispose();
    weightFieldTextController?.dispose();
  }
}
