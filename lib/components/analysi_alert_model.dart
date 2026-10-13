import '/components/analyze2_app_widget.dart';
import '/components/camera_analyzer_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:async';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import 'analysi_alert_widget.dart' show AnalysiAlertWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

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
