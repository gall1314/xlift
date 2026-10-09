import '/components/drop_set_creation_edit_widget.dart';
import '/components/time_for_creation_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'set_row_edit_temp_widget.dart' show SetRowEditTempWidget;
import 'package:flutter/material.dart';

class SetRowEditTempModel extends FlutterFlowModel<SetRowEditTempWidget> {
  ///  Local state fields for this component.

  bool weighted = false;

  int? durationMs;

  bool dropSet = false;

  bool overrideBodyweight = false;

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Custom Action - removeDropSetsForExercise] action in Button widget.
  List<dynamic>? dropdrop3;
  // Stores action output result for [Custom Action - removeDropsetsFromLoggedSets] action in Button widget.
  List<dynamic>? droplloged;
  // Stores action output result for [Custom Action - removeSetFromExercise] action in Button widget.
  List<dynamic>? remove;
  // Stores action output result for [Custom Action - removeDropsetsFromLoggedSets] action in Button widget.
  List<dynamic>? remove2;
  // Stores action output result for [Custom Action - removeDropSetsForExercise] action in Button widget.
  List<dynamic>? dropdrop;
  // Model for timeForCreation component.
  late TimeForCreationModel timeForCreationModel;
  // Stores action output result for [Custom Action - updateLoggedSetForCreationV4] action in timeForCreation widget.
  List<dynamic>? updateTime2;
  // State field(s) for RepsField widget.
  FocusNode? repsFieldFocusNode;
  TextEditingController? repsFieldTextController;
  String? Function(BuildContext, String?)? repsFieldTextControllerValidator;
  // Stores action output result for [Custom Action - updateLoggedSetForCreationV4] action in RepsField widget.
  List<dynamic>? updateTime;
  // Stores action output result for [Custom Action - updateLoggedSetForCreationV4] action in IconButton widget.
  List<dynamic>? update;
  // Model for dropSetCreationEdit component.
  late DropSetCreationEditModel dropSetCreationEditModel;

  @override
  void initState(BuildContext context) {
    timeForCreationModel = createModel(context, () => TimeForCreationModel());
    dropSetCreationEditModel =
        createModel(context, () => DropSetCreationEditModel());
  }

  @override
  void dispose() {
    timeForCreationModel.dispose();
    repsFieldFocusNode?.dispose();
    repsFieldTextController?.dispose();

    dropSetCreationEditModel.dispose();
  }
}
