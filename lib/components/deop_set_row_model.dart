import '/flutter_flow/flutter_flow_util.dart';
import 'deop_set_row_widget.dart' show DeopSetRowWidget;
import 'package:flutter/material.dart';

class DeopSetRowModel extends FlutterFlowModel<DeopSetRowWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for REPS widget.
  FocusNode? repsFocusNode;
  TextEditingController? repsTextController;
  String? Function(BuildContext, String?)? repsTextControllerValidator;
  // Stores action output result for [Custom Action - upsertDropSetInLoggedSetsAction] action in REPS widget.
  List<dynamic>? addDropToLogged;
  // State field(s) for Weight widget.
  FocusNode? weightFocusNode;
  TextEditingController? weightTextController;
  String? Function(BuildContext, String?)? weightTextControllerValidator;
  // Stores action output result for [Custom Action - upsertDropSetInLoggedSetsAction] action in Weight widget.
  List<dynamic>? addDropToLogged2;

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
