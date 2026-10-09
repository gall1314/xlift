import '/backend/sqlite/sqlite_manager.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'replace_new_model.dart';
export 'replace_new_model.dart';

class ReplaceNewWidget extends StatefulWidget {
  const ReplaceNewWidget({
    super.key,
    required this.exerciseId,
    required this.workoutId,
  });

  final int? exerciseId;
  final String? workoutId;

  @override
  State<ReplaceNewWidget> createState() => _ReplaceNewWidgetState();
}

class _ReplaceNewWidgetState extends State<ReplaceNewWidget> {
  late ReplaceNewModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReplaceNewModel());
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
      height: MediaQuery.sizeOf(context).height * 1.0,
      child: custom_widgets.ReplaceExercisePicker(
        width: MediaQuery.sizeOf(context).width * 1.0,
        height: MediaQuery.sizeOf(context).height * 1.0,
        exerciseId: widget.exerciseId!,
        loggedSets: FFAppState().loggedSets,
        onReplace: (exerciseId, exerciseName, updatePlan) async {
          _model.replace = await actions.replaceExerciseInExerciseSets(
            FFAppState().exercisesets.toList(),
            widget.exerciseId!,
            <String, dynamic>{
              'id': exerciseId,
              'name': exerciseId,
            },
          );
          FFAppState().exercisesets = _model.replace!.toList().cast<dynamic>();
          safeSetState(() {});
          if (updatePlan) {
            await SQLiteManager.instance.replaceExerciseInPlan(
              workoutId: widget.workoutId!,
              oldExerciseId: widget.exerciseId!,
              newExerciseId: exerciseId,
            );
          }
          Navigator.pop(context);

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
