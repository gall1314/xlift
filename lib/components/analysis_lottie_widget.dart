import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'analysis_lottie_model.dart';
export 'analysis_lottie_model.dart';

class AnalysisLottieWidget extends StatefulWidget {
  const AnalysisLottieWidget({super.key});

  @override
  State<AnalysisLottieWidget> createState() => _AnalysisLottieWidgetState();
}

class _AnalysisLottieWidgetState extends State<AnalysisLottieWidget> {
  late AnalysisLottieModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AnalysisLottieModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 35.0,
      height: 35.0,
      child: custom_widgets.AiSparkleIndicator(
        width: 35.0,
        height: 35.0,
        sparkleColor: FlutterFlowTheme.of(context).primary,
      ),
    );
  }
}
