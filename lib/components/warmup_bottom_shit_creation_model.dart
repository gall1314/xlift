import '/backend/sqlite/sqlite_manager.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'warmup_bottom_shit_creation_widget.dart'
    show WarmupBottomShitCreationWidget;
import 'package:flutter/material.dart';

class WarmupBottomShitCreationModel
    extends FlutterFlowModel<WarmupBottomShitCreationWidget> {
  ///  Local state fields for this component.

  int numberSets = 3;

  double? weight;

  bool manual = false;

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - SQLite (previosSet)] action in warmupBottomShitCreation widget.
  List<PreviosSetRow>? weight2;
  // Stores action output result for [Custom Action - applyWarmupSimpleUnits] action in Button widget.
  List<dynamic>? warmup;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
