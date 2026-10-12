import '/auth/supabase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'workout_breakdown_model.dart';
export 'workout_breakdown_model.dart';

class WorkoutBreakdownWidget extends StatefulWidget {
  const WorkoutBreakdownWidget({
    super.key,
    required this.workoutLogId,
  });

  final String? workoutLogId;

  @override
  State<WorkoutBreakdownWidget> createState() => _WorkoutBreakdownWidgetState();
}

class _WorkoutBreakdownWidgetState extends State<WorkoutBreakdownWidget> {
  late WorkoutBreakdownModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WorkoutBreakdownModel());
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
      child: custom_widgets.WorkoutBreakdownSheet(
        width: MediaQuery.sizeOf(context).width * 1.0,
        height: MediaQuery.sizeOf(context).height * 1.0,
        workoutLogId: widget.workoutLogId!,
        userId: currentUserUid,
        isDark: Theme.of(context).brightness == Brightness.dark,
        accentColor: FlutterFlowTheme.of(context).primary,
        initiallyExpanded: false,
      ),
    );
  }
}
