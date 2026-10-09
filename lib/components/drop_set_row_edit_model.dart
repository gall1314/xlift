import '/flutter_flow/flutter_flow_util.dart';
import 'drop_set_row_edit_widget.dart' show DropSetRowEditWidget;
import 'package:flutter/material.dart';

class DropSetRowEditModel extends FlutterFlowModel<DropSetRowEditWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for REPS widget.
  FocusNode? repsFocusNode;
  TextEditingController? repsTextController;
  String? Function(BuildContext, String?)? repsTextControllerValidator;
  // Stores action output result for [Custom Action - updateDropSetValues] action in REPS widget.
  List<dynamic>? repsupd;
  // State field(s) for Weight widget.
  FocusNode? weightFocusNode;
  TextEditingController? weightTextController;
  String? Function(BuildContext, String?)? weightTextControllerValidator;
  // Stores action output result for [Custom Action - updateDropSetValues] action in Weight widget.
  List<dynamic>? weightupd;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    repsFocusNode?.dispose();
    repsTextController?.dispose();

    weightFocusNode?.dispose();
    weightTextController?.dispose();
  }
}
