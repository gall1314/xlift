import '/components/activity_card_widget.dart';
import '/components/stat_card2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'engaging_modern_home_page_widget.dart'
    show EngagingModernHomePageWidget;
import 'package:flutter/material.dart';

class EngagingModernHomePageModel
    extends FlutterFlowModel<EngagingModernHomePageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for StatCard.
  late StatCard2Model statCardModel1;
  // Model for StatCard.
  late StatCard2Model statCardModel2;
  // Model for StatCard.
  late StatCard2Model statCardModel3;
  // Model for ActivityCard.
  late ActivityCardModel activityCardModel1;
  // Model for ActivityCard.
  late ActivityCardModel activityCardModel2;
  // Model for ActivityCard.
  late ActivityCardModel activityCardModel3;

  @override
  void initState(BuildContext context) {
    statCardModel1 = createModel(context, () => StatCard2Model());
    statCardModel2 = createModel(context, () => StatCard2Model());
    statCardModel3 = createModel(context, () => StatCard2Model());
    activityCardModel1 = createModel(context, () => ActivityCardModel());
    activityCardModel2 = createModel(context, () => ActivityCardModel());
    activityCardModel3 = createModel(context, () => ActivityCardModel());
  }

  @override
  void dispose() {
    statCardModel1.dispose();
    statCardModel2.dispose();
    statCardModel3.dispose();
    activityCardModel1.dispose();
    activityCardModel2.dispose();
    activityCardModel3.dispose();
  }
}
