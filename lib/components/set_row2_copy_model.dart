import '/backend/api_requests/api_calls.dart';
import '/components/drop_set_widget.dart';
import '/components/time_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'set_row2_copy_widget.dart' show SetRow2CopyWidget;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class SetRow2CopyModel extends FlutterFlowModel<SetRow2CopyWidget> {
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
  // Stores action output result for [Custom Action - updateFlatSetValue] action in Button widget.
  List<dynamic>? doneTrueCopy;
  // Stores action output result for [Custom Action - removeDropSetsForExercise] action in Button widget.
  List<dynamic>? dropdrop4;
  // Stores action output result for [Custom Action - removeDropsetsFromLoggedSets] action in Button widget.
  List<dynamic>? droplloged2;
  // State field(s) for RepsField widget.
  FocusNode? repsFieldFocusNode;
  TextEditingController? repsFieldTextController;
  String? Function(BuildContext, String?)? repsFieldTextControllerValidator;
  // Stores action output result for [Custom Action - updateFlatSetValue] action in RepsField widget.
  List<dynamic>? repsUpdate;
  // State field(s) for WeightField widget.
  FocusNode? weightFieldFocusNode;
  TextEditingController? weightFieldTextController;
  String? Function(BuildContext, String?)? weightFieldTextControllerValidator;
  // Stores action output result for [Custom Action - updateFlatSetValue] action in WeightField widget.
  List<dynamic>? weightUpdate;
  // Stores action output result for [Custom Action - markSetWeighted] action in IconButton widget.
  List<dynamic>? weightupd;
  // Stores action output result for [Custom Action - updateSetAnalyzedVideo] action in IconButton widget.
  List<dynamic>? vidCopy2;
  AudioPlayer? soundPlayer1;
  // Stores action output result for [Custom Action - updateSetAnalysisResult] action in IconButton widget.
  List<dynamic>? res2;
  // Stores action output result for [Backend Call - API (AnalyzeSquat)] action in IconButton widget.
  ApiCallResponse? apiResultn0k2;
  // Stores action output result for [Custom Action - setExerciseLoadingState] action in IconButton widget.
  List<dynamic>? prosess2;
  bool isDataUploading_uploadDataSiv = false;
  FFUploadedFile uploadedLocalFile_uploadDataSiv =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // Stores action output result for [Custom Action - setExerciseLoadingState] action in IconButton widget.
  List<dynamic>? prosess;
  // Stores action output result for [Backend Call - API (AnalyzeSquat)] action in IconButton widget.
  ApiCallResponse? apiResultn0k;
  // Stores action output result for [Custom Action - updateSetAnalysisResult] action in IconButton widget.
  List<dynamic>? res;
  AudioPlayer? soundPlayer2;
  // Stores action output result for [Custom Action - updateSetAnalysisError] action in IconButton widget.
  List<dynamic>? error;
  // Model for time component.
  late TimeModel timeModel;
  // Stores action output result for [Custom Action - updateFlatSetValue] action in time widget.
  List<dynamic>? time;
  // Stores action output result for [Custom Action - updateFlatSetValue] action in time widget.
  List<dynamic>? done;
  // Model for dropSet component.
  late DropSetModel dropSetModel;
  // Stores action output result for [Custom Action - setLoggedSetIsDone] action in Container widget.
  List<dynamic>? doneFals;
  // Stores action output result for [Custom Action - updateFlatSetValue] action in Container widget.
  List<dynamic>? doneTrue;

  @override
  void initState(BuildContext context) {
    timeModel = createModel(context, () => TimeModel());
    dropSetModel = createModel(context, () => DropSetModel());
  }

  @override
  void dispose() {
    repsFieldFocusNode?.dispose();
    repsFieldTextController?.dispose();

    weightFieldFocusNode?.dispose();
    weightFieldTextController?.dispose();

    timeModel.dispose();
    dropSetModel.dispose();
  }
}
