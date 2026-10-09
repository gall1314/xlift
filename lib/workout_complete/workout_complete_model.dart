import '/components/stat_item_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'workout_complete_widget.dart' show WorkoutCompleteWidget;
import 'package:flutter/material.dart';

class WorkoutCompleteModel extends FlutterFlowModel<WorkoutCompleteWidget> {
  ///  Local state fields for this page.

  bool animation = true;

  bool iscapturing = false;

  ///  State fields for stateful widgets in this page.

  // Model for StatItem.
  late StatItemModel statItemModel1;
  // Model for StatItem.
  late StatItemModel statItemModel2;
  // Model for StatItem.
  late StatItemModel statItemModel3;

  @override
  void initState(BuildContext context) {
    statItemModel1 = createModel(context, () => StatItemModel());
    statItemModel2 = createModel(context, () => StatItemModel());
    statItemModel3 = createModel(context, () => StatItemModel());
  }

  @override
  void dispose() {
    statItemModel1.dispose();
    statItemModel2.dispose();
    statItemModel3.dispose();
  }
}
