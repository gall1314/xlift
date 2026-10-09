import '/backend/supabase/supabase.dart';
import '/components/setnew_off_v2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'after_workout_fix_offline_widget.dart'
    show AfterWorkoutFixOfflineWidget;
import 'package:flutter/material.dart';

class AfterWorkoutFixOfflineModel
    extends FlutterFlowModel<AfterWorkoutFixOfflineWidget> {
  ///  Local state fields for this page.

  WorkoutLogRow? workoutLog;

  bool animation = true;

  ///  State fields for stateful widgets in this page.

  // Models for setnewOffV2 dynamic component.
  late FlutterFlowDynamicModels<SetnewOffV2Model> setnewOffV2Models;

  @override
  void initState(BuildContext context) {
    setnewOffV2Models = FlutterFlowDynamicModels(() => SetnewOffV2Model());
  }

  @override
  void dispose() {
    setnewOffV2Models.dispose();
  }
}
