import '/flutter_flow/flutter_flow_util.dart';
import 'drop_set_row_creation_widget.dart' show DropSetRowCreationWidget;
import 'package:flutter/material.dart';

class DropSetRowCreationModel
    extends FlutterFlowModel<DropSetRowCreationWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for REPS widget.
  FocusNode? repsFocusNode;
  TextEditingController? repsTextController;
  String? Function(BuildContext, String?)? repsTextControllerValidator;
  // Stores action output result for [Custom Action - updateDropSetValues] action in REPS widget.
  List<dynamic>? repsupd;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    repsFocusNode?.dispose();
    repsTextController?.dispose();
  }
}
