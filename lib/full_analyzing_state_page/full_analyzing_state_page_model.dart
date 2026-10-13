import '/components/ai_loading_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'full_analyzing_state_page_widget.dart'
    show FullAnalyzingStatePageWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FullAnalyzingStatePageModel
    extends FlutterFlowModel<FullAnalyzingStatePageWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - analyzeExerciseVideoAction] action in FullAnalyzingStatePage widget.
  dynamic result;
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
