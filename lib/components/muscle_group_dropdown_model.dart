import '/flutter_flow/flutter_flow_util.dart';
import 'muscle_group_dropdown_widget.dart' show MuscleGroupDropdownWidget;
import 'package:flutter/material.dart';

class MuscleGroupDropdownModel
    extends FlutterFlowModel<MuscleGroupDropdownWidget> {
  ///  Local state fields for this component.

  String selected = 'All';

  ///  State fields for stateful widgets in this component.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
