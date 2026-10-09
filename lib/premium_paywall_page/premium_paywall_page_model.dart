import '/components/feature_row_widget.dart';
import '/components/price_card_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'premium_paywall_page_widget.dart' show PremiumPaywallPageWidget;
import 'package:flutter/material.dart';

class PremiumPaywallPageModel
    extends FlutterFlowModel<PremiumPaywallPageWidget> {
  ///  Local state fields for this page.

  bool yearly = false;

  ///  State fields for stateful widgets in this page.

  // Model for FeatureRow.
  late FeatureRowModel featureRowModel1;
  // Model for FeatureRow.
  late FeatureRowModel featureRowModel2;
  // Model for FeatureRow.
  late FeatureRowModel featureRowModel3;
  // Model for FeatureRow.
  late FeatureRowModel featureRowModel4;
  // Model for PriceCard.
  late PriceCardModel priceCardModel1;
  // Model for PriceCard.
  late PriceCardModel priceCardModel2;
  // Stores action output result for [RevenueCat - Purchase] action in Button widget.
  bool? month;
  // Stores action output result for [RevenueCat - Purchase] action in Button widget.
  bool? year;

  @override
  void initState(BuildContext context) {
    featureRowModel1 = createModel(context, () => FeatureRowModel());
    featureRowModel2 = createModel(context, () => FeatureRowModel());
    featureRowModel3 = createModel(context, () => FeatureRowModel());
    featureRowModel4 = createModel(context, () => FeatureRowModel());
    priceCardModel1 = createModel(context, () => PriceCardModel());
    priceCardModel2 = createModel(context, () => PriceCardModel());
  }

  @override
  void dispose() {
    featureRowModel1.dispose();
    featureRowModel2.dispose();
    featureRowModel3.dispose();
    featureRowModel4.dispose();
    priceCardModel1.dispose();
    priceCardModel2.dispose();
  }
}
