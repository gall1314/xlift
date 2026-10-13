import '/flutter_flow/flutter_flow_util.dart';
import 'analysi_alert_widget.dart' show AnalysiAlertWidget;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AnalysiAlertModel extends FlutterFlowModel<AnalysiAlertWidget> {
  ///  Local state fields for this component.

  bool showNever = false;

  FFUploadedFile? videoUrl;

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Custom Action - setExerciseLoadingState] action in Button widget.
  List<dynamic>? prosesss;
  // Stores action output result for [Custom Action - analyzeExerciseVideoAction] action in Button widget.
  dynamic result;
  // Stores action output result for [Custom Action - updateSetAnalysisResult] action in Button widget.
  List<dynamic>? res;
  AudioPlayer? soundPlayer;
  // Stores action output result for [Custom Action - updateSetAnalysisError] action in Button widget.
  List<dynamic>? error;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
