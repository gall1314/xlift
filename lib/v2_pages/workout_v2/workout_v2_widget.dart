import '/auth/supabase_auth/auth_util.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/components/analyze2_app_widget.dart';
import '/components/remove_exercise_from_workout_alert_widget.dart';
import '/components/reorder_widget.dart';
import '/components/replace_new_widget.dart';
import '/components/rest_bottom_shit_widget.dart';
import '/components/superset_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'workout_v2_model.dart';
export 'workout_v2_model.dart';

class WorkoutV2Widget extends StatefulWidget {
  const WorkoutV2Widget({
    super.key,
    required this.workoutId,
  });

  final String? workoutId;

  static String routeName = 'workoutV2';
  static String routePath = '/workoutV2';

  @override
  State<WorkoutV2Widget> createState() => _WorkoutV2WidgetState();
}

class _WorkoutV2WidgetState extends State<WorkoutV2Widget> {
  late WorkoutV2Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WorkoutV2Model());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (!FFAppState().workout) {
        FFAppState().activeWorkoutTime = '00:00';
        FFAppState().activeWorkoutStartTime = getCurrentTimestamp;
        safeSetState(() {});
        _model.simp = await SQLiteManager.instance.getExercisesSimp(
          workoutId: widget.workoutId,
        );
        _model.sets = await SQLiteManager.instance.getExerciseSetsForWorkout(
          workoutId: widget.workoutId!,
        );
        _model.set1 = await actions.initializeExerciseSetsFromSimpleQueryV2(
          _model.simp!.toList(),
          FFAppState().exercisesets.toList(),
          _model.sets!.toList(),
        );
        _model.drops = await actions.initializeDropSetsFromSave(
          _model.sets?.toList(),
          _model.simp?.toList(),
        );
        FFAppState().exercisesets = _model.set1!.toList().cast<dynamic>();
        FFAppState().activeWorkoutDet = <String, dynamic>{
          'id': widget.workoutId,
        };
        FFAppState().workout = true;
        FFAppState().dropSets = _model.drops!.toList().cast<dynamic>();
        safeSetState(() {});
        await actions.initLocalNotifications();
        _model.rest1 = await actions.initializeExerciseRestTimes(
          FFAppState().exercisesets.toList(),
        );
        FFAppState().restTimers = _model.rest1!;
        safeSetState(() {});
      }
    });
  }

  @override
  void dispose() {
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
        body: Builder(
          builder: (context) => Container(
            width: MediaQuery.sizeOf(context).width * 1.0,
            height: MediaQuery.sizeOf(context).height * 1.0,
            child: custom_widgets.WorkoutPage(
              width: MediaQuery.sizeOf(context).width * 1.0,
              height: MediaQuery.sizeOf(context).height * 1.0,
              showCameraGuidance: true,
              mode: 'live',
              onBack: () async {
                context.pop();
              },
              onFinish: (workoutName, workoutDate, durationMs) async {
                _model.saveCopy = await actions.saveWorkoutComplete(
                  widget.workoutId,
                  currentUserUid,
                  functions
                      .workoutDurationMs(FFAppState().activeWorkoutStartTime!),
                  FFAppState().loggedSets.toList(),
                  FFAppState().workoutAnalysisState.toList(),
                  FFAppState().exercisesets.toList(),
                );
                if (getJsonField(
                  _model.saveCopy,
                  r'''$["success"]''',
                )) {
                  FFAppState().deleteExercisesets(resetState: true);
                  FFAppState().deleteLoggedSets(resetState: true);
                  FFAppState().dropSets = [];
                  FFAppState().deleteRestTimers(resetState: true);
                  FFAppState().deleteWarmupSets(resetState: true);
                  FFAppState().workout = false;
                  FFAppState().deleteCompletedExercises(resetState: true);
                  FFAppState().deleteWorkoutAnalysisState(resetState: true);
                  FFAppState().deleteActiveWorkoutStartTime(resetState: true);
                  safeSetState(() {});

                  context.goNamed(
                    WorkoutCompleteWidget.routeName,
                    queryParameters: {
                      'workoutLogId': serializeParam(
                        getJsonField(
                          _model.saveCopy,
                          r'''$["workoutLogId"]''',
                        ).toString(),
                        ParamType.String,
                      ),
                    }.withoutNulls,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        getJsonField(
                          _model.saveCopy,
                          r'''$["message"]''',
                        ).toString(),
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).primaryText,
                        ),
                      ),
                      duration: Duration(milliseconds: 4000),
                      backgroundColor: FlutterFlowTheme.of(context).secondary,
                    ),
                  );
                }

                safeSetState(() {});
              },
              onAddExercises: () async {
                context.pushNamed(
                  AddExercisesMidSeissionCopyWidget.routeName,
                  queryParameters: {
                    'workoutId': serializeParam(
                      widget.workoutId,
                      ParamType.String,
                    ),
                    'addUserEx': serializeParam(
                      false,
                      ParamType.bool,
                    ),
                  }.withoutNulls,
                );
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
                          exerciseId: exerciseId,
                          workoutId: widget.workoutId!,
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
                        child: SupersetWidget(
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
                        child: ReorderWidget(),
                      ),
                    );
                  },
                ).then((value) => safeSetState(() {}));
              },
              onRemoveExercise: (exerciseId) async {
                if (functions.exerciseHasLoggedValuesFlat(
                    FFAppState().loggedSets.toList(), exerciseId)) {
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
                  _model.remove = await actions.removeExerciseFromExerciseSets(
                    FFAppState().exercisesets.toList(),
                    exerciseId,
                  );
                  FFAppState().exercisesets =
                      _model.remove!.toList().cast<dynamic>();
                  safeSetState(() {});
                  Navigator.pop(context);
                }

                safeSetState(() {});
              },
              onResultTap:
                  (exerciseId, exerciseName, setNumber, video, setLogId) async {
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
                        child: Analyze2AppWidget(
                          exercise: exerciseName,
                          exerciseId: exerciseId,
                          setNumber: setNumber,
                          videoReady: (url) async {},
                        ),
                      ),
                    );
                  },
                );
              },
              onLockTap: () async {
                context.pushNamed(PremiumPaywallPageWidget.routeName);
              },
              onStartRest: (exerciseId, exerciseName, setNumber, restMs) async {
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
                        child: RestBottomShitWidget(
                          exerciseId: exerciseId,
                          exerciseName: exerciseName,
                          setNumber: setNumber,
                        ),
                      ),
                    );
                  },
                ).then((value) => safeSetState(() {}));
              },
              onDontShowAgain: () async {},
            ),
          ),
        ),
      ),
    );
  }
}
