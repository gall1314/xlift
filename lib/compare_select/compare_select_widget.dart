import '/auth/supabase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/instant_timer.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'compare_select_model.dart';
export 'compare_select_model.dart';

class CompareSelectWidget extends StatefulWidget {
  const CompareSelectWidget({
    super.key,
    required this.workoutLogAId,
  });

  final String? workoutLogAId;

  static String routeName = 'compareSelect';
  static String routePath = '/compareSelect';

  @override
  State<CompareSelectWidget> createState() => _CompareSelectWidgetState();
}

class _CompareSelectWidgetState extends State<CompareSelectWidget> {
  late CompareSelectModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CompareSelectModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.searchQuery = '';
      safeSetState(() {});
      _model.instantTimer = InstantTimer.periodic(
        duration: Duration(milliseconds: 1000),
        callback: (timer) async {
          if (FFAppState().workout) {
            FFAppState().activeWorkoutTime =
                functions.calculateElapsedTimeFormatted(
                    FFAppState().activeWorkoutStartTime!, getCurrentTimestamp);
            safeSetState(() {});
          } else {
            return;
          }
        },
        startImmediately: false,
      );
    });
  }

  @override
  void dispose() {
    // On page dispose action.
    () async {
      _model.instantTimer?.cancel();
    }();

    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Container(
          width: MediaQuery.sizeOf(context).width * 1.0,
          height: MediaQuery.sizeOf(context).height * 1.0,
          child: custom_widgets.HistoryView(
            width: MediaQuery.sizeOf(context).width * 1.0,
            height: MediaQuery.sizeOf(context).height * 1.0,
            userId: currentUserUid,
            isPremium: FFAppState().isPremium,
            compareMode: true,
            excludeWorkoutLogId: widget.workoutLogAId,
            onWorkoutTap: (workoutLogId) async {},
            onMenuTap: (workoutLogId) async {},
            onLockedTap: () async {},
            onCompare: (workoutLogId) async {
              context.pushNamed(
                WorkoutComparisonWidget.routeName,
                queryParameters: {
                  'idA': serializeParam(
                    widget.workoutLogAId,
                    ParamType.String,
                  ),
                  'idB': serializeParam(
                    workoutLogId,
                    ParamType.String,
                  ),
                }.withoutNulls,
              );
            },
          ),
        ),
      ),
    );
  }
}
