import '/auth/supabase_auth/auth_util.dart';
import '/components/analyze2_app_after_widget.dart';
import '/components/edit_delte2_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'workout_summary_view_model.dart';
export 'workout_summary_view_model.dart';

class WorkoutSummaryViewWidget extends StatefulWidget {
  const WorkoutSummaryViewWidget({
    super.key,
    required this.workoutLogId,
  });

  final String? workoutLogId;

  static String routeName = 'workoutSummaryView';
  static String routePath = '/workoutSummaryView';

  @override
  State<WorkoutSummaryViewWidget> createState() =>
      _WorkoutSummaryViewWidgetState();
}

class _WorkoutSummaryViewWidgetState extends State<WorkoutSummaryViewWidget> {
  late WorkoutSummaryViewModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WorkoutSummaryViewModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Builder(
            builder: (context) => Container(
              width: double.infinity,
              height: double.infinity,
              child: custom_widgets.WorkoutSummaryView(
                width: double.infinity,
                height: double.infinity,
                workoutLogId: widget.workoutLogId!,
                userId: currentUserUid,
                onBack: () async {
                  context.safePop();
                },
                onCompare: () async {
                  context.pushNamed(
                    CompareSelectWidget.routeName,
                    queryParameters: {
                      'workoutLogAId': serializeParam(
                        widget.workoutLogId,
                        ParamType.String,
                      ),
                    }.withoutNulls,
                  );
                },
                onMore: () async {
                  await showAlignedDialog(
                    context: context,
                    isGlobal: false,
                    avoidOverflow: true,
                    targetAnchor: AlignmentDirectional(0.0, 0.0)
                        .resolve(Directionality.of(context)),
                    followerAnchor: AlignmentDirectional(0.0, 0.0)
                        .resolve(Directionality.of(context)),
                    builder: (dialogContext) {
                      return Material(
                        color: Colors.transparent,
                        child: GestureDetector(
                          onTap: () {
                            FocusScope.of(dialogContext).unfocus();
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          child: EditDelte2Widget(
                            workoutLogId: widget.workoutLogId!,
                          ),
                        ),
                      );
                    },
                  );
                },
                onExerciseTap: (exerciseId, isPublic) async {
                  if (isPublic) {
                    context.pushNamed(
                      ExerciseHistoryWidget.routeName,
                      queryParameters: {
                        'exerciseId': serializeParam(
                          exerciseId,
                          ParamType.int,
                        ),
                        'overview': serializeParam(
                          false,
                          ParamType.bool,
                        ),
                        'analytics': serializeParam(
                          true,
                          ParamType.bool,
                        ),
                      }.withoutNulls,
                    );
                  } else {
                    context.pushNamed(
                      ExerciseHistoryCustomWidget.routeName,
                      queryParameters: {
                        'exerciseId': serializeParam(
                          exerciseId,
                          ParamType.int,
                        ),
                        'overview': serializeParam(
                          false,
                          ParamType.bool,
                        ),
                        'analytics': serializeParam(
                          false,
                          ParamType.bool,
                        ),
                      }.withoutNulls,
                    );
                  }
                },
                onAnalysisTap: (setLogId, analysisId, analysis) async {
                  await showDialog(
                    context: context,
                    builder: (dialogContext) {
                      return Dialog(
                        elevation: 0,
                        insetPadding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                        alignment: AlignmentDirectional(0.0, 0.0)
                            .resolve(Directionality.of(context)),
                        child: GestureDetector(
                          onTap: () {
                            FocusScope.of(dialogContext).unfocus();
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          child: Analyze2AppAfterWidget(
                            anlysis: analysis,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
