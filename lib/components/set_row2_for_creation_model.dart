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

  // Stores action output result for [Custom Action - removeDropSetsForExercise] action in SetNumberButton widget.
  List<dynamic>? dropdrop3Copy;
  // Stores action output result for [Custom Action - removeDropsetsFromLoggedSets] action in SetNumberButton widget.
  List<dynamic>? dropllogedCopy;
  // Stores action output result for [Custom Action - removeSetFromExercise] action in SetNumberButton widget.
  List<dynamic>? removeCopy;
  // Stores action output result for [Custom Action - removeDropsetsFromLoggedSets] action in SetNumberButton widget.
  List<dynamic>? remove2Copy;
  // Stores action output result for [Custom Action - removeDropSetsForExercise] action in SetNumberButton widget.
  List<dynamic>? dropdropCopy;
  // Model for timeForCreation component.
  late TimeForCreationModel timeForCreationModel;
  // Stores action output result for [Custom Action - updateLoggedSetForCreationV4] action in timeForCreation widget.
  List<dynamic>? updateTime2;
  // Stores action output result for [Custom Action - updateLoggedSetForCreationV4] action in PreviousSetButton widget.
  List<dynamic>? updateRepsCopyCopy;
  // Stores action output result for [Custom Action - updateLoggedSetForCreationV4] action in RepsField widget.
  List<dynamic>? updateRepsCopy;
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
    dropSetCreationModel.dispose();
  }
}
