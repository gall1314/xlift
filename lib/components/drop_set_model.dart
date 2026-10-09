import '/components/deop_set_row_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'drop_set_widget.dart' show DropSetWidget;
import 'package:flutter/material.dart';

class DropSetModel extends FlutterFlowModel<DropSetWidget> {
  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Custom Action - removeDropRowForParentByLabel] action in IconButton widget.
  List<dynamic>? deleteDrop;
  // Stores action output result for [Custom Action - removeDropSetFromLoggedSetsAction] action in IconButton widget.
  List<dynamic>? removeFromLogged;
  // Models for deopSetRow dynamic component.
  late FlutterFlowDynamicModels<DeopSetRowModel> deopSetRowModels;
  // Stores action output result for [Custom Action - addNextDropRow] action in Button widget.
  List<dynamic>? addDrop2;

  @override
  void initState(BuildContext context) {
    deopSetRowModels = FlutterFlowDynamicModels(() => DeopSetRowModel());
  }

  @override
  void dispose() {
    deopSetRowModels.dispose();
  }
}
