import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'ai_loading_bar_model.dart';
export 'ai_loading_bar_model.dart';

class AiLoadingBarWidget extends StatefulWidget {
  const AiLoadingBarWidget({super.key});

  @override
  State<AiLoadingBarWidget> createState() => _AiLoadingBarWidgetState();
}

class _AiLoadingBarWidgetState extends State<AiLoadingBarWidget> {
  late AiLoadingBarModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AiLoadingBarModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300.0,
      height: 15.0,
      child: custom_widgets.AiLoadingBar(
        width: 300.0,
        height: 15.0,
      ),
    );
  }
}
