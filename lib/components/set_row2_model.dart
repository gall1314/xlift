import '/components/analysis_lottie_widget.dart';
import '/components/drop_set_widget.dart';
import '/components/time_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'set_row2_widget.dart' show SetRow2Widget;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class SetRow2Model extends FlutterFlowModel<SetRow2Widget> {
  ///  Local state fields for this component.

  bool ai = false;

  FFUploadedFile? videoUrl;

  bool expand = false;

  bool weighted = false;

  int? durationMs;

  dynamic result1;

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
  // Stores action output result for [Custom Action - removeDropSetsForExercise] action in SetNumberButton widget.
  List<dynamic>? dropdrop4Copy;
  // Stores action output result for [Custom Action - removeDropsetsFromLoggedSets] action in SetNumberButton widget.
  List<dynamic>? droplloged2Copy;
  // Stores action output result for [Custom Action - updateFlatSetValue] action in PreviousSetButton widget.
  List<dynamic>? update;
  // Stores action output result for [Custom Action - updateFlatSetValue] action in RepsField widget.
  List<dynamic>? repsUpdateCopy;
  // Stores action output result for [Custom Action - updateFlatSetValue] action in WeightField widget.
  List<dynamic>? weightUpdateCopy;
  // Stores action output result for [Custom Action - updateSetAnalysisError] action in IconButton widget.
  List<dynamic>? error2;
  AudioPlayer? soundPlayer1;
  // Stores action output result for [Custom Action - updateSetAnalysisResult] action in IconButton widget.
  List<dynamic>? result2;
  // Stores action output result for [Custom Action - analyzeExerciseVideoAction] action in IconButton widget.
  dynamic result;
  // Stores action output result for [Custom Action - setExerciseLoadingState] action in IconButton widget.
  List<dynamic>? prosess2;
  // Model for analysisLottie component.
  late AnalysisLottieModel analysisLottieModel;
  // Stores action output result for [Custom Action - setExerciseLoadingState] action in AiFormButton widget.
  List<dynamic>? prosesssCopy;
  // Stores action output result for [Custom Action - analyzeExerciseVideoAction] action in AiFormButton widget.
  dynamic result3Copy;
  // Stores action output result for [Custom Action - updateSetAnalysisResult] action in AiFormButton widget.
  List<dynamic>? resCopy;
  AudioPlayer? soundPlayer2;
  // Stores action output result for [Custom Action - updateSetAnalysisError] action in AiFormButton widget.
  List<dynamic>? errorCopy;
  // Stores action output result for [Custom Action - updateSetAnalyzedVideo] action in AiScoreRing widget.
  List<dynamic>? vidCopy;
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
    analysisLottieModel = createModel(context, () => AnalysisLottieModel());
    timeModel = createModel(context, () => TimeModel());
    dropSetModel = createModel(context, () => DropSetModel());
  }

  @override
  void dispose() {
    analysisLottieModel.dispose();
    timeModel.dispose();
    dropSetModel.dispose();
  }
}
