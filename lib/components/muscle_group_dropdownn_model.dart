import '/flutter_flow/flutter_flow_util.dart';
import 'muscle_group_dropdownn_widget.dart' show MuscleGroupDropdownnWidget;
import 'package:flutter/material.dart';

class MuscleGroupDropdownnModel
    extends FlutterFlowModel<MuscleGroupDropdownnWidget> {
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
