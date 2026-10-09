import '/components/button_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'destructive_confirmation_dialog_widget.dart'
    show DestructiveConfirmationDialogWidget;
import 'package:flutter/material.dart';

class DestructiveConfirmationDialogModel
    extends FlutterFlowModel<DestructiveConfirmationDialogWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for Button.
  late ButtonModel buttonModel;

  @override
  void initState(BuildContext context) {
    buttonModel = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    buttonModel.dispose();
  }
}
