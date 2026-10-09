import '/components/time_warmup_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'set_row_warm_up_widget.dart' show SetRowWarmUpWidget;
import 'package:flutter/material.dart';

class SetRowWarmUpModel extends FlutterFlowModel<SetRowWarmUpWidget> {
  ///  Local state fields for this component.

  bool expand = false;

  bool weighted = false;

  bool done = false;

  ///  State fields for stateful widgets in this component.

  // State field(s) for reps widget.
  FocusNode? repsFocusNode;
  TextEditingController? repsTextController;
  String? Function(BuildContext, String?)? repsTextControllerValidator;
  // State field(s) for weight widget.
  FocusNode? weightFocusNode;
  TextEditingController? weightTextController;
  String? Function(BuildContext, String?)? weightTextControllerValidator;
  // Model for timeWarmup component.
  late TimeWarmupModel timeWarmupModel;

  @override
  void initState(BuildContext context) {
    timeWarmupModel = createModel(context, () => TimeWarmupModel());
  }

  @override
  void dispose() {
    repsFocusNode?.dispose();
    repsTextController?.dispose();

    weightFocusNode?.dispose();
    weightTextController?.dispose();

    timeWarmupModel.dispose();
  }
}
