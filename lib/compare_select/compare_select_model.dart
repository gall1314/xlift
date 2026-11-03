import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/instant_timer.dart';
import '/index.dart';
import 'compare_select_widget.dart' show CompareSelectWidget;
import 'package:flutter/material.dart';

class CompareSelectModel extends FlutterFlowModel<CompareSelectWidget> {
  ///  Local state fields for this page.

  String? searchQuery;

  String selectedRange = 'Last 30 days';

  String selectedMuscle = 'All';

  String? workoutLogBId;

  ///  State fields for stateful widgets in this page.

  InstantTimer? instantTimer;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    instantTimer?.cancel();
  }
}
