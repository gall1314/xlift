import '/components/drop_set_creation_widget.dart';
import '/components/time_for_creation_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'set_row2_for_creation_widget.dart' show SetRow2ForCreationWidget;
import 'package:flutter/material.dart';

class SetRow2ForCreationModel
    extends FlutterFlowModel<SetRow2ForCreationWidget> {
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
  List<dynamic>? updateReps;
  // Stores action output result for [Custom Action - markSetWeightedInt] action in IconButton widget.
  List<dynamic>? weighted3;
  // Model for dropSetCreation component.
  late DropSetCreationModel dropSetCreationModel;

  @override
  void initState(BuildContext context) {
    timeForCreationModel = createModel(context, () => TimeForCreationModel());
    dropSetCreationModel = createModel(context, () => DropSetCreationModel());
  }

  @override
  void dispose() {
    timeForCreationModel.dispose();
    repsFieldFocusNode?.dispose();
    repsFieldTextController?.dispose();

    dropSetCreationModel.dispose();
  }
}
