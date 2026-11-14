import '/auth/supabase_auth/auth_util.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/components/analyze2_app_after_edit_widget.dart';
import '/components/remove_exercise_from_workout_alert_widget.dart';
import '/components/reorder_creation_widget.dart';
import '/components/replace_new_widget.dart';
import '/components/superset_creation_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/instant_timer.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'workout_log_edit_v2_model.dart';
export 'workout_log_edit_v2_model.dart';

class WorkoutLogEditV2Widget extends StatefulWidget {
  const WorkoutLogEditV2Widget({
    super.key,
    required this.workoutLogId,
  });

  final String? workoutLogId;

  static String routeName = 'workoutLogEditV2';
  static String routePath = '/workoutLogEditV2';

  @override
  State<WorkoutLogEditV2Widget> createState() => _WorkoutLogEditV2WidgetState();
}

class _WorkoutLogEditV2WidgetState extends State<WorkoutLogEditV2Widget> {
  late WorkoutLogEditV2Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WorkoutLogEditV2Model());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.sets = await SQLiteManager.instance.getAllSets(
        workoutLogId: widget.workoutLogId!,
      );
      _model.exEdit = await SQLiteManager.instance.exercisesForEdit(
        workoutLogId: widget.workoutLogId!,
      );
      _model.set1 = await actions.buildExerciseSetsForEdit(
        context,
        _model.exEdit!.toList(),
        _model.sets!.toList(),
      );
      FFAppState().exerciseSetsCreation = _model.set1!.toList().cast<dynamic>();
      safeSetState(() {});
      _model.logged = await actions.buildLoggedSetsCheckedFromGetAllSets(
        _model.sets!.toList(),
      );
      _model.drop1 = await actions.initializeDropSetsFromSetLog(
        _model.sets?.toList(),
      );
      _model.workoutLog = await SQLiteManager.instance.history1(
        userId: currentUserUid,
        workoutLogId: widget.workoutLogId!,
      );
      _model.durationMs = _model.workoutLog?.firstOrNull?.durationSeconds;
      _model.date = _model.workoutLog?.firstOrNull?.createdAt;
      safeSetState(() {});
      FFAppState().loggedSetsCreation = _model.logged!.toList().cast<dynamic>();
      FFAppState().dropSetsCreation = _model.drop1!.toList().cast<dynamic>();
      safeSetState(() {});
      if (FFAppState().workout) {
        _model.instantTimerHome = InstantTimer.periodic(
          duration: Duration(milliseconds: 1000),
          callback: (timer) async {
            FFAppState().activeWorkoutTime =
                functions.calculateElapsedTimeFormatted(
                    FFAppState().activeWorkoutStartTime!, getCurrentTimestamp);
            safeSetState(() {});
          },
          startImmediately: false,
        );
      }
    });
  }

  @override
  void dispose() {
    // On page dispose action.
    () async {
      _model.instantTimerHome?.cancel();
    }();

    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return FutureBuilder<List<History1Row>>(
      future: SQLiteManager.instance.history1(
        workoutLogId: widget.workoutLogId!,
        userId: currentUserUid,
      ),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).secondary,
                  ),
                ),
              ),
            ),
          );
        }
        final workoutLogEditV2History1RowList = snapshot.data!;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Builder(
              builder: (context) => Container(
                width: MediaQuery.sizeOf(context).width * 1.0,
                height: MediaQuery.sizeOf(context).height * 1.0,
                child: custom_widgets.WorkoutPage(
                  width: MediaQuery.sizeOf(context).width * 1.0,
                  height: MediaQuery.sizeOf(context).height * 1.0,
                  workoutName: '',
                  showCameraGuidance: false,
                  mode: 'logEdit',
                  workoutDate: _model.workoutLog?.firstOrNull?.createdAt,
                  onBack: () async {
                    FFAppState().completedExercisesCreation = [];
                    FFAppState().exerciseSetsCreation = [];
                    FFAppState().loggedSetsCreation = [];
                    FFAppState().dropSetsCreation = [];
                    FFAppState().restTimerCreation = null;
                    safeSetState(() {});
                    context.safePop();
                  },
                  onFinish: (workoutName, workoutDate, durationMs) async {
                    _model.saveCopy2 = await actions.updateWorkoutComplete(
                      widget.workoutLogId,
                      currentUserUid,
                      durationMs,
                      workoutDate,
                      FFAppState().loggedSetsCreation.toList(),
                      FFAppState().analysisStateCreation.toList(),
                      FFAppState().exerciseSetsCreation.toList(),
                    );
                    FFAppState().warmUpCreation = [];
                    FFAppState().restTimerCreation = null;
                    FFAppState().dropSetsCreation = [];
                    FFAppState().loggedSetsCreation = [];
                    FFAppState().exerciseSetsCreation = [];
                    safeSetState(() {});

                    context.pushNamed(
                      MasterPageWidget.routeName,
                      queryParameters: {
                        'initialTab': serializeParam(
                          2,
                          ParamType.int,
                        ),
                      }.withoutNulls,
                    );

                    await actions.syncAllPending();

                    safeSetState(() {});
                  },
                  onAddExercises: () async {
                    context
                        .pushNamed(AddExercisesForWorklogEditWidget.routeName);
                  },
                  onHeaderTap: (exerciseId) async {
                    context.pushNamed(
                      ExerciseHistoryWidget.routeName,
                      queryParameters: {
                        'exerciseId': serializeParam(
                          exerciseId,
                          ParamType.int,
                        ),
                        'overview': serializeParam(
                          true,
                          ParamType.bool,
                        ),
                        'analytics': serializeParam(
                          false,
                          ParamType.bool,
                        ),
                      }.withoutNulls,
                    );
                  },
                  onCustomHeaderTap: (exerciseId) async {
                    context.pushNamed(
                      ExerciseHistoryCustomWidget.routeName,
                      queryParameters: {
                        'exerciseId': serializeParam(
                          exerciseId,
                          ParamType.int,
                        ),
                        'overview': serializeParam(
                          true,
                          ParamType.bool,
                        ),
                        'analytics': serializeParam(
                          false,
                          ParamType.bool,
                        ),
                      }.withoutNulls,
                    );
                  },
                  onReplaceExercise: (exerciseId) async {
                    await showModalBottomSheet(
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      enableDrag: false,
                      context: context,
                      builder: (context) {
                        return GestureDetector(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          child: Padding(
                            padding: MediaQuery.viewInsetsOf(context),
                            child: ReplaceNewWidget(
                              exerciseId: 0,
                              workoutId: '',
                            ),
                          ),
                        );
                      },
                    ).then((value) => safeSetState(() {}));
                  },
                  onSupersetTap: (exerciseId) async {
                    await showModalBottomSheet(
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      enableDrag: false,
                      context: context,
                      builder: (context) {
                        return GestureDetector(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          child: Padding(
                            padding: MediaQuery.viewInsetsOf(context),
                            child: SupersetCreationWidget(
                              currentExerciseId: exerciseId,
                            ),
                          ),
                        );
                      },
                    ).then((value) => safeSetState(() {}));
                  },
                  onViewHistory: (exerciseId) async {
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
                          false,
                          ParamType.bool,
                        ),
                      }.withoutNulls,
                    );
                  },
                  onCustomViewHistory: (exerciseId) async {
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
                  },
                  onReorder: () async {
                    await showModalBottomSheet(
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      enableDrag: false,
                      context: context,
                      builder: (context) {
                        return GestureDetector(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          child: Padding(
                            padding: MediaQuery.viewInsetsOf(context),
                            child: ReorderCreationWidget(),
                          ),
                        );
                      },
                    ).then((value) => safeSetState(() {}));
                  },
                  onRemoveExercise: (exerciseId) async {
                    if (functions.exerciseHasLoggedValuesFlat(
                        FFAppState().loggedSetsCreation.toList(), exerciseId)) {
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
                              child: RemoveExerciseFromWorkoutAlertWidget(
                                exerciseId: exerciseId,
                                closeBottom: () async {
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      _model.remove =
                          await actions.removeExerciseFromExerciseSets(
                        FFAppState().exerciseSetsCreation.toList(),
                        exerciseId,
                      );
                      FFAppState().exerciseSetsCreation =
                          _model.remove!.toList().cast<dynamic>();
                      safeSetState(() {});
                      Navigator.pop(context);
                    }

                    safeSetState(() {});
                  },
                  onResultTap: (exerciseId, exerciseName, setNumber, video,
                      setLogId) async {
                    _model.anal = await SQLiteManager.instance.getSetAnalysis(
                      setLogId: '',
                    );
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
                            child: Analyze2AppAfterEditWidget(
                              anlysis: _model.anal!.firstOrNull!,
                            ),
                          ),
                        );
                      },
                    );

                    safeSetState(() {});
                  },
                  onLockTap: () async {},
                  onUnitChanged: (isKg) async {},
                  onStartRest:
                      (exerciseId, exerciseName, setNumber, restMs) async {},
                  onDontShowAgain: () async {},
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
