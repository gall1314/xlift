import '/components/time_warmup_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'set_row_warm_up_creation_widget.dart' show SetRowWarmUpCreationWidget;
import 'package:flutter/material.dart';

class SetRowWarmUpCreationModel
    extends FlutterFlowModel<SetRowWarmUpCreationWidget> {
  ///  Local state fields for this component.

  bool weighted = false;

  ///  State fields for stateful widgets in this component.

  // State field(s) for reps widget.
  FocusNode? repsFocusNode;
  TextEditingController? repsTextController;
  String? Function(BuildContext, String?)? repsTextControllerValidator;
  // Stores action output result for [Custom Action - updateWarmupSetField] action in reps widget.
  List<dynamic>? repsud;
  // State field(s) for weight widget.
  FocusNode? weightFocusNode;
  TextEditingController? weightTextController;
  String? Function(BuildContext, String?)? weightTextControllerValidator;
  // Stores action output result for [Custom Action - updateWarmupSetField] action in weight widget.
  List<dynamic>? weightUpdate;
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
