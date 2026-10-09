import '/components/thank_for_premium_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'simple_clean_thank_widget.dart' show SimpleCleanThankWidget;
import 'package:flutter/material.dart';

class SimpleCleanThankModel extends FlutterFlowModel<SimpleCleanThankWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for thankForPremium component.
  late ThankForPremiumModel thankForPremiumModel;

  @override
  void initState(BuildContext context) {
    thankForPremiumModel = createModel(context, () => ThankForPremiumModel());
  }

  @override
  void dispose() {
    thankForPremiumModel.dispose();
  }
}
