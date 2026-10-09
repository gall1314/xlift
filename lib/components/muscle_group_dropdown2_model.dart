import '/flutter_flow/flutter_flow_util.dart';
import 'muscle_group_dropdown2_widget.dart' show MuscleGroupDropdown2Widget;
import 'package:flutter/material.dart';

class MuscleGroupDropdown2Model
    extends FlutterFlowModel<MuscleGroupDropdown2Widget> {
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
