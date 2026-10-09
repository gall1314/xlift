import '/flutter_flow/flutter_flow_timer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'time_widget.dart' show TimeWidget;
import 'package:flutter/material.dart';

class TimeModel extends FlutterFlowModel<TimeWidget> {
  ///  Local state fields for this component.

  bool timerOn = false;

  int? selectedDuration;

  int? countDownValue = 90000;

  int timerMode = 1;

  int? updatedDuration;

  String countUpValue = '00:00';

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Custom Action - updateFlatSetTime] action in IconButton widget.
  List<dynamic>? time;
  // State field(s) for minutesTens widget.
  FocusNode? minutesTensFocusNode;
  TextEditingController? minutesTensTextController;
  String? Function(BuildContext, String?)? minutesTensTextControllerValidator;
  // State field(s) for minutesUnits widget.
  FocusNode? minutesUnitsFocusNode;
  TextEditingController? minutesUnitsTextController;
  String? Function(BuildContext, String?)? minutesUnitsTextControllerValidator;
  // State field(s) for SecondsTens widget.
  FocusNode? secondsTensFocusNode;
  TextEditingController? secondsTensTextController;
  String? Function(BuildContext, String?)? secondsTensTextControllerValidator;
  // State field(s) for SecondsUnits widget.
  FocusNode? secondsUnitsFocusNode;
  TextEditingController? secondsUnitsTextController;
  String? Function(BuildContext, String?)? secondsUnitsTextControllerValidator;
  // Stores action output result for [Custom Action - updateFlatSetValue] action in Container widget.
  List<dynamic>? timeupd;
  // State field(s) for countDownTimer widget.
  final countDownTimerInitialTimeMs = 0;
  int countDownTimerMilliseconds = 0;
  String countDownTimerValue = StopWatchTimer.getDisplayTime(
    0,
    hours: false,
    milliSecond: false,
  );
  FlutterFlowTimerController countDownTimerController =
      FlutterFlowTimerController(StopWatchTimer(mode: StopWatchMode.countDown));

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    minutesTensFocusNode?.dispose();
    minutesTensTextController?.dispose();

    minutesUnitsFocusNode?.dispose();
    minutesUnitsTextController?.dispose();

    secondsTensFocusNode?.dispose();
    secondsTensTextController?.dispose();

    secondsUnitsFocusNode?.dispose();
    secondsUnitsTextController?.dispose();

    countDownTimerController.dispose();
  }
}
