import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'manage_subscription_widget.dart' show ManageSubscriptionWidget;
import 'package:flutter/material.dart';

class ManageSubscriptionModel
    extends FlutterFlowModel<ManageSubscriptionWidget> {
  ///  Local state fields for this page.

  int type = 0;

  int pick = 0;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - isMonthlyPlan] action in manageSubscription widget.
  bool? monthly;
  // Stores action output result for [RevenueCat - Purchase] action in Container widget.
  bool? month;
  // Stores action output result for [RevenueCat - Purchase] action in Container widget.
  bool? year;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
