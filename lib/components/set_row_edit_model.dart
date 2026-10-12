import '/components/drop_set_creation_widget.dart';
import '/components/time_for_creation_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'set_row_edit_widget.dart' show SetRowEditWidget;
import 'package:flutter/material.dart';

class SetRowEditModel extends FlutterFlowModel<SetRowEditWidget> {
  ///  Local state fields for this component.

  bool ai = false;

  FFUploadedFile? videoUrl;

  bool expand = false;

  bool weighted = false;

  int? durationMs;

  dynamic result;

  bool dropSet = false;

  bool loadingResult = false;

  bool analysisDone = false;

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
  // Stores action output result for [Custom Action - updateFlatSetValue] action in SetNumberButton widget.
  List<dynamic>? doneTrueCopyCopy;
  // Model for timeForCreation component.
  late TimeForCreationModel timeForCreationModel;
  // Stores action output result for [Custom Action - updateFlatSetValue] action in RepsField widget.
  List<dynamic>? repsUpdateCopy;
  // Stores action output result for [Custom Action - updateFlatSetValue] action in WeightField widget.
  List<dynamic>? weightUpdate2;
  // Model for dropSetCreation component.
  late DropSetCreationModel dropSetCreationModel;
  // Stores action output result for [Custom Action - updateFlatSetValue] action in Container widget.
  List<dynamic>? doneFals;
  // Stores action output result for [Custom Action - updateFlatSetValue] action in Container widget.
  List<dynamic>? doneTrue;

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
