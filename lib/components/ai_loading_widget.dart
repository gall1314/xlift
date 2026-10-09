import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'ai_loading_model.dart';
export 'ai_loading_model.dart';

class AiLoadingWidget extends StatefulWidget {
  const AiLoadingWidget({super.key});

  @override
  State<AiLoadingWidget> createState() => _AiLoadingWidgetState();
}

class _AiLoadingWidgetState extends State<AiLoadingWidget> {
  late AiLoadingModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AiLoadingModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional(0.0, 0.0),
      child: Container(
        width: 250.0,
        height: 250.0,
        child: custom_widgets.AiLoadingIndicator(
          width: 250.0,
          height: 250.0,
        ),
      ),
    );
  }
}
