import '/auth/supabase_auth/auth_util.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/components/exercise_componet_widget.dart';
import '/components/rest_bottom_shit_widget.dart';
import '/components/rest_shit_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/walkthroughs/workout_first.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
    show TutorialCoachMark;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
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
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.chevron_left,
              color: FlutterFlowTheme.of(context).secondaryText,
              size: 30.0,
            ),
            onPressed: () async {
              context.goNamed(MasterPageWidget.routeName);
            },
          ),
          title: Align(
            alignment: AlignmentDirectional(0.0, 0.0),
            child: Container(
              width: 160.0,
              height: 50.0,
              child: custom_widgets.WorkoutClock(
                width: 160.0,
                height: 50.0,
                fontSize: 22.0,
                color: FlutterFlowTheme.of(context).primaryText,
                startedAt: FFAppState().activeWorkoutStartTime!,
              ),
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.all(5.0),
              child: FFButtonWidget(
                onPressed: functions.shouldDisableFinishButton(
                        FFAppState().loggedSets.toList())
                    ? null
                    : () async {
                        _model.save = await actions.saveWorkoutComplete(
                          widget.workoutId,
                          currentUserUid,
                          functions.workoutDurationMs(
                              FFAppState().activeWorkoutStartTime!),
                          FFAppState().loggedSets.toList(),
                          FFAppState().workoutAnalysisState.toList(),
                          FFAppState().exercisesets.toList(),
                        );
                        if (getJsonField(
                          _model.save,
                          r'''$["success"]''',
                        )) {
                          FFAppState().deleteExercisesets();
                          FFAppState().exercisesets = [];

                          FFAppState().deleteLoggedSets();
                          FFAppState().loggedSets = [];

                          FFAppState().dropSets = [];
                          FFAppState().deleteRestTimers();
                          FFAppState().restTimers = null;

                          FFAppState().deleteWarmupSets();
                          FFAppState().warmupSets = [];

                          FFAppState().workout = false;
                          FFAppState().deleteCompletedExercises();
                          FFAppState().completedExercises = [];

                          FFAppState().deleteWorkoutAnalysisState();
                          FFAppState().workoutAnalysisState = [];

                          FFAppState().deleteActiveWorkoutStartTime();
                          FFAppState().activeWorkoutStartTime = null;

                          safeSetState(() {});

                          context.goNamed(
                            WorkoutCompleteWidget.routeName,
                            queryParameters: {
                              'workoutLogId': serializeParam(
                                getJsonField(
                                  _model.save,
                                  r'''$["workoutLogId"]''',
                                ).toString(),
                                ParamType.String,
                              ),
                            }.withoutNulls,
                          );

                          _model.de = await actions.syncAllPending();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                getJsonField(
                                  _model.de,
                                  r'''$["debug_string"]''',
                                ).toString(),
                                style: TextStyle(
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                ),
                              ),
                              duration: Duration(milliseconds: 4000),
                              backgroundColor:
                                  FlutterFlowTheme.of(context).secondary,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                valueOrDefault<String>(
                                  getJsonField(
                                    _model.save,
                                    r'''$["message"]''',
                                  )?.toString(),
                                  '-',
                                ),
                                style: TextStyle(
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                ),
                              ),
                              duration: Duration(milliseconds: 4000),
                              backgroundColor:
                                  FlutterFlowTheme.of(context).secondary,
                            ),
                          );
                        }

                        safeSetState(() {});
                      },
                text: FFLocalizations.of(context).getText(
                  'u58x2bqu' /* Finish */,
                ),
                options: FFButtonOptions(
                  height: 16.6,
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  iconPadding:
                      EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  color: FlutterFlowTheme.of(context).primary,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        font: GoogleFonts.interTight(
                          fontWeight: FlutterFlowTheme.of(context)
                              .titleSmall
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).titleSmall.fontStyle,
                        ),
                        color: Colors.white,
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).titleSmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleSmall.fontStyle,
                      ),
                  elevation: 0.0,
                  borderSide: BorderSide(
                    color: functions.shouldDisableFinishButton(
                            FFAppState().loggedSets.toList())
                        ? FlutterFlowTheme.of(context).alternate
                        : FlutterFlowTheme.of(context).primary,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                  disabledColor:
                      FlutterFlowTheme.of(context).secondaryBackground,
                  disabledTextColor: FlutterFlowTheme.of(context).alternate,
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(10.0),
            child: LinearPercentIndicator(
              percent: functions.workoutProgress(
                  FFAppState().exercisesets.toList(),
                  FFAppState().loggedSets.toList()),
              width: MediaQuery.sizeOf(context).width * 1.0,
              lineHeight: 4.0,
              animation: true,
              animateFromLastPercent: true,
              progressColor: FlutterFlowTheme.of(context).primary,
              backgroundColor: FlutterFlowTheme.of(context).accent4,
              padding: EdgeInsets.zero,
            ),
          ),
          centerTitle: true,
          elevation: 1.0,
        ),
        body: Container(
          decoration: BoxDecoration(),
          child: Stack(
            children: [
              Stack(
                alignment: AlignmentDirectional(0.0, 0.0),
                children: [
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(),
                            child: Builder(
                              builder: (context) {
                                final exercise = functions
                                    .buildExerciseTableFromSets(
                                        FFAppState().exercisesets.toList())
                                    .toList();

                                return ListView.separated(
                                  padding: EdgeInsets.zero,
                                  primary: false,
                                  shrinkWrap: true,
                                  scrollDirection: Axis.vertical,
                                  itemCount: exercise.length,
                                  separatorBuilder: (_, __) =>
                                      SizedBox(height: 20.0),
                                  itemBuilder: (context, exerciseIndex) {
                                    final exerciseItem =
                                        exercise[exerciseIndex];
                                    return wrapWithModel(
                                      model: _model.exerciseComponetModels
                                          .getModel(
                                        '${getJsonField(
                                          exerciseItem,
                                          r'''$["exerciseId"]''',
                                        ).toString()}${exerciseIndex.toString()}',
                                        exerciseIndex,
                                      ),
                                      updateCallback: () => safeSetState(() {}),
                                      child: ExerciseComponetWidget(
                                        key: Key(
                                          'Key1u3_${'${getJsonField(
                                            exerciseItem,
                                            r'''$["exerciseId"]''',
                                          ).toString()}${exerciseIndex.toString()}'}',
                                        ),
                                        exerciseId: getJsonField(
                                          exerciseItem,
                                          r'''$["exerciseId"]''',
                                        ),
                                        exerciseName: getJsonField(
                                          exerciseItem,
                                          r'''$["exerciseName"]''',
                                        ).toString(),
                                        workoutId: widget.workoutId!,
                                        startTimer:
                                            (setNumber, exerciseId) async {
                                          if (functions.shouldStartRestTimer2(
                                              FFAppState().restTimers,
                                              getJsonField(
                                                exerciseItem,
                                                r'''$["exerciseId"]''',
                                              ),
                                              _model.restEnabled)) {
                                            await showModalBottomSheet(
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              isDismissible: false,
                                              enableDrag: false,
                                              context: context,
                                              builder: (context) {
                                                return GestureDetector(
                                                  onTap: () {
                                                    FocusScope.of(context)
                                                        .unfocus();
                                                    FocusManager
                                                        .instance.primaryFocus
                                                        ?.unfocus();
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        MediaQuery.viewInsetsOf(
                                                            context),
                                                    child: RestBottomShitWidget(
                                                      exerciseId: exerciseId,
                                                      exerciseName:
                                                          getJsonField(
                                                        exerciseItem,
                                                        r'''$["exerciseName"]''',
                                                      ).toString(),
                                                      setNumber: setNumber,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ).then(
                                                (value) => safeSetState(() {}));
                                          } else {
                                            return;
                                          }
                                        },
                                        selectRest: () async {
                                          await showModalBottomSheet(
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            enableDrag: false,
                                            context: context,
                                            builder: (context) {
                                              return GestureDetector(
                                                onTap: () {
                                                  FocusScope.of(context)
                                                      .unfocus();
                                                  FocusManager
                                                      .instance.primaryFocus
                                                      ?.unfocus();
                                                },
                                                child: Padding(
                                                  padding:
                                                      MediaQuery.viewInsetsOf(
                                                          context),
                                                  child: RestShitWidget(
                                                    exerciseId: getJsonField(
                                                      exerciseItem,
                                                      r'''$["exerciseId"]''',
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ).then(
                                              (value) => safeSetState(() {}));
                                        },
                                        closeIt: () async {
                                          Navigator.pop(context);
                                        },
                                        showError: () async {},
                                      ),
                                    ).addWalkthrough(
                                      container1u3esfep,
                                      _model.workoutFirstController,
                                      listIndex: exerciseIndex,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          FFButtonWidget(
                            onPressed: () async {
                              context.pushNamed(
                                AddExercisesMidSeissionWidget.routeName,
                                queryParameters: {
                                  'addUserEx': serializeParam(
                                    false,
                                    ParamType.bool,
                                  ),
                                  'workoutId': serializeParam(
                                    widget.workoutId,
                                    ParamType.String,
                                  ),
                                }.withoutNulls,
                              );
                            },
                            text: FFLocalizations.of(context).getText(
                              'toj7tcqv' /* Add Exercise */,
                            ),
                            icon: Icon(
                              Icons.add,
                              size: 15.0,
                            ),
                            options: FFButtonOptions(
                              width: double.infinity,
                              height: 50.0,
                              padding: EdgeInsets.all(8.0),
                              iconPadding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 0.0),
                              iconColor: FlutterFlowTheme.of(context).info,
                              color: FlutterFlowTheme.of(context).primary,
                              textStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context).info,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                              elevation: 0.0,
                              borderSide: BorderSide(
                                color: Colors.transparent,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                          ),
                        ]
                            .divide(SizedBox(height: 16.0))
                            .addToStart(SizedBox(height: 20.0))
                            .addToEnd(SizedBox(height: 20.0)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  TutorialCoachMark createPageWalkthrough(BuildContext context) =>
      TutorialCoachMark(
        targets: createWalkthroughTargets(context),
        onFinish: () async {
          safeSetState(() => _model.workoutFirstController = null);
        },
        onSkip: () {
          return true;
        },
      );
}
