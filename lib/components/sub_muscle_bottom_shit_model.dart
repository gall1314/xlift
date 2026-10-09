import '/flutter_flow/flutter_flow_util.dart';
import 'sub_muscle_bottom_shit_widget.dart' show SubMuscleBottomShitWidget;
import 'package:flutter/material.dart';

class SubMuscleBottomShitModel
    extends FlutterFlowModel<SubMuscleBottomShitWidget> {
  ///  Local state fields for this component.

  dynamic selected;

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
