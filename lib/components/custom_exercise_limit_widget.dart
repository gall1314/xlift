import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'custom_exercise_limit_model.dart';
export 'custom_exercise_limit_model.dart';

class CustomExerciseLimitWidget extends StatefulWidget {
  const CustomExerciseLimitWidget({super.key});

  @override
  State<CustomExerciseLimitWidget> createState() =>
      _CustomExerciseLimitWidgetState();
}

class _CustomExerciseLimitWidgetState extends State<CustomExerciseLimitWidget> {
  late CustomExerciseLimitModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomExerciseLimitModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 1.0,
      height: MediaQuery.sizeOf(context).height * 1.0,
      child: custom_widgets.CustomExerciseLimitSheet(
        width: MediaQuery.sizeOf(context).width * 1.0,
        height: MediaQuery.sizeOf(context).height * 1.0,
        limit: 3,
        onUpgrade: () async {},
        onClose: () async {
          Navigator.pop(context);
        },
      ),
    );
  }
}
