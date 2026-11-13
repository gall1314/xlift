import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'replace_new_creation_model.dart';
export 'replace_new_creation_model.dart';

class ReplaceNewCreationWidget extends StatefulWidget {
  const ReplaceNewCreationWidget({
    super.key,
    required this.exerciseId,
    required this.workoutId,
  });

  final int? exerciseId;
  final String? workoutId;

  @override
  State<ReplaceNewCreationWidget> createState() =>
      _ReplaceNewCreationWidgetState();
}

class _ReplaceNewCreationWidgetState extends State<ReplaceNewCreationWidget> {
  late ReplaceNewCreationModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReplaceNewCreationModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Container(
      width: MediaQuery.sizeOf(context).width * 1.0,
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: custom_widgets.ReplaceExercisePicker(
        width: MediaQuery.sizeOf(context).width * 1.0,
        height: MediaQuery.sizeOf(context).height * 0.8,
        exerciseId: widget.exerciseId!,
        loggedSets: FFAppState().loggedSets,
        onReplace: (exerciseId, exerciseName, updatePlan) async {
          _model.replace = await actions.replaceExerciseInExerciseSets(
            FFAppState().exerciseSetsCreation.toList(),
            exerciseId,
            exerciseId,
          );
          FFAppState().exerciseSetsCreation =
              _model.replace!.toList().cast<dynamic>();
          safeSetState(() {});
          context.safePop();

          safeSetState(() {});
        },
        onClose: () async {
          Navigator.pop(context);
        },
        onCreate: () async {
          context.pushNamed(CreateUserExerciseMidSessionWidget.routeName);
        },
      ),
    );
  }
}
