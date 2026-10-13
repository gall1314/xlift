import '/components/ai_loading_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'ai_workout_loading_widget.dart' show AiWorkoutLoadingWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AiWorkoutLoadingModel extends FlutterFlowModel<AiWorkoutLoadingWidget> {
  ///  Local state fields for this page.

  String? goal;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - callWorkoutBuilder] action in aiWorkoutLoading widget.
  dynamic api;
  // Model for aiLoading component.
  late AiLoadingModel aiLoadingModel;

  @override
  void initState(BuildContext context) {
    aiLoadingModel = createModel(context, () => AiLoadingModel());
  }

  @override
  void dispose() {
    aiLoadingModel.dispose();
  }
}
