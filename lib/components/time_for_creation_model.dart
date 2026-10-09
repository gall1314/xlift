import '/flutter_flow/flutter_flow_util.dart';
import 'time_for_creation_widget.dart' show TimeForCreationWidget;
import 'package:flutter/material.dart';

class TimeForCreationModel extends FlutterFlowModel<TimeForCreationWidget> {
  ///  Local state fields for this component.

  bool timerOn = false;

  int? selectedDuration;

  int? countDownValue = 90000;

  int timerMode = 2;

  int? updatedDuration;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
