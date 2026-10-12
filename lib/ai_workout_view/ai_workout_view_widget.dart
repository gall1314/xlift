import '/auth/supabase_auth/auth_util.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/components/discard_ui_workout_widget.dart';
import '/components/exercise_card2_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ai_workout_view_model.dart';
export 'ai_workout_view_model.dart';

/// Design a single mobile screen for a fitness app called "Xlift" — the
/// generated workout result screen.
///
/// Light theme. Design only — no logic, no navigation, no data
/// binding.Background: clean white (#FFFFFF).Top: a back arrow on the left
/// and a close (X) icon on the right.Header block (below the top bar):
///
/// A small pill/badge in lime green (#C6F542) with dark text, e.g.
/// "STRENGTH".
/// A large bold dark workout title, e.g. "Chest & Triceps".
/// A small row of two info items below the title: a clock icon with "45 min",
/// a dot separator, then "6 exercises". Gray text.
/// Exercise list (main content, scrollable):
/// A vertical list of exercise cards. Each card:
///
/// Full width, white, 16px rounded corners, thin light-gray border (#E6E8EB),
/// subtle shadow.
/// Horizontal layout: on the left, a 64x64 rounded image placeholder (light
/// gray) for the exercise illustration. Then a column with: the exercise name
/// in bold dark (16px, e.g. "Bench Press"), and below it a small gray muscle
/// tag (e.g. "Chest").
/// On the right side of the card, three small stacked stats, each with a tiny
/// label above a bold value: "SETS 3", "REPS 8-12", "REST 60s".
/// Show 3-4 example cards with different placeholder names (Bench Press,
/// Incline DB Fly, Tricep Pushdowns).Bottom (two buttons, stacked, fixed at
/// the bottom):
///
/// Primary button (top): full-width, lime-green (#C6F542) background, dark
/// text, with a play icon — "Start Workout".
/// Secondary button (below it): full-width, white background with a
/// lime-green border and dark text, with a bookmark/save icon — "Save
/// Workout".
/// Style: modern, clean, premium, generous spacing, rounded corners, bold
/// sans-serif headings. iPhone size (390px wide).
class AiWorkoutViewWidget extends StatefulWidget {
  const AiWorkoutViewWidget({
    super.key,
    required this.result,
    required this.goal,
  });

  final dynamic result;
  final int? goal;

  static String routeName = 'aiWorkoutView';
  static String routePath = '/aiWorkoutView';

  @override
  State<AiWorkoutViewWidget> createState() => _AiWorkoutViewWidgetState();
}

class _AiWorkoutViewWidgetState extends State<AiWorkoutViewWidget> {
  late AiWorkoutViewModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AiWorkoutViewModel());
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
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        body: Align(
          alignment: AlignmentDirectional(0.0, 1.0),
          child: Stack(
            alignment: AlignmentDirectional(-1.0, -1.0),
            children: [
              Stack(
                children: [
                  SingleChildScrollView(
                    primary: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                24.0, 16.0, 24.0, 16.0),
                            child: Container(
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Container(
                                    width: 100.0,
                                    height: 35.0,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Builder(
                                        builder: (context) =>
                                            FlutterFlowIconButton(
                                          borderRadius: 8.0,
                                          buttonSize: 40.0,
                                          fillColor: Colors.transparent,
                                          icon: Icon(
                                            Icons.close_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            size: 24.0,
                                          ),
                                          onPressed: () async {
                                            await showDialog(
                                              context: context,
                                              builder: (dialogContext) {
                                                return Dialog(
                                                  elevation: 0,
                                                  insetPadding: EdgeInsets.zero,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  alignment:
                                                      AlignmentDirectional(
                                                              0.0, 0.0)
                                                          .resolve(
                                                              Directionality.of(
                                                                  context)),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      FocusScope.of(
                                                              dialogContext)
                                                          .unfocus();
                                                      FocusManager
                                                          .instance.primaryFocus
                                                          ?.unfocus();
                                                    },
                                                    child:
                                                        DiscardUiWorkoutWidget(),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              24.0, 0.0, 24.0, 24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFC6F542),
                                  borderRadius: BorderRadius.circular(9999.0),
                                  shape: BoxShape.rectangle,
                                ),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      12.0, 6.0, 12.0, 6.0),
                                  child: Container(
                                    child: Text(
                                      functions.mapGoal(widget.goal!),
                                      style: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelLarge
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelLarge
                                                    .fontStyle,
                                            lineHeight: 1.4,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                getJsonField(
                                  widget.result,
                                  r'''$["workout_name"]''',
                                ).toString(),
                                style: FlutterFlowTheme.of(context)
                                    .headlineLarge
                                    .override(
                                      font: GoogleFonts.interTight(
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineLarge
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .headlineLarge
                                          .fontStyle,
                                      lineHeight: 1.4,
                                    ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    size: 16.0,
                                  ),
                                  Text(
                                    getJsonField(
                                      widget.result,
                                      r'''$["estimated_duration_minutes"]''',
                                    ).toString(),
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontStyle,
                                          lineHeight: 1.4,
                                        ),
                                  ),
                                  Text(
                                    FFLocalizations.of(context).getText(
                                      'k67sgjjy' /* Minutes */,
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelSmall
                                                    .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelSmall
                                                  .fontStyle,
                                        ),
                                  ),
                                  Text(
                                    FFLocalizations.of(context).getText(
                                      'u70684v5' /* • */,
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontStyle,
                                          lineHeight: 1.4,
                                        ),
                                  ),
                                  Icon(
                                    Icons.fitness_center_rounded,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    size: 16.0,
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Text(
                                        valueOrDefault<String>(
                                          functions
                                              .aiWorkoutExercisesCountLabel(
                                                  getJsonField(
                                            widget.result,
                                            r'''$["exercises"]''',
                                            true,
                                          )!),
                                          '-',
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              font: GoogleFonts.inter(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodySmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodySmall
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontStyle,
                                              lineHeight: 1.4,
                                            ),
                                      ),
                                    ],
                                  ),
                                ].divide(SizedBox(width: 4.0)),
                              ),
                            ].divide(SizedBox(height: 16.0)),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  24.0, 0.0, 24.0, 0.0),
                              child: SingleChildScrollView(
                                primary: false,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 12.0, 0.0, 0.0),
                                      child: Builder(
                                        builder: (context) {
                                          final exercise = getJsonField(
                                            widget.result,
                                            r'''$["exercises"]''',
                                          ).toList();

                                          return ListView.separated(
                                            padding: EdgeInsets.zero,
                                            primary: false,
                                            shrinkWrap: true,
                                            scrollDirection: Axis.vertical,
                                            itemCount: exercise.length,
                                            separatorBuilder: (_, __) =>
                                                SizedBox(height: 16.0),
                                            itemBuilder:
                                                (context, exerciseIndex) {
                                              final exerciseItem =
                                                  exercise[exerciseIndex];
                                              return FutureBuilder<
                                                  List<GetExerciseRow>>(
                                                future: SQLiteManager.instance
                                                    .getExercise(
                                                  exerciseId: getJsonField(
                                                    exerciseItem,
                                                    r'''$["exercise_id"]''',
                                                  ),
                                                ),
                                                builder: (context, snapshot) {
                                                  // Customize what your widget looks like when it's loading.
                                                  if (!snapshot.hasData) {
                                                    return Center(
                                                      child: SizedBox(
                                                        width: 50.0,
                                                        height: 50.0,
                                                        child:
                                                            CircularProgressIndicator(
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                  Color>(
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondary,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                  final exerciseCardGetExerciseRowList =
                                                      snapshot.data!;

                                                  return ExerciseCard2Widget(
                                                    key: Key(
                                                        'Keyzul_${exerciseIndex}_of_${exercise.length}'),
                                                    imgDesc:
                                                        'https://dimg.dreamflow.cloud/v1/image/man%20performing%20barbell%20bench%20press',
                                                    name:
                                                        exerciseCardGetExerciseRowList
                                                            .firstOrNull
                                                            ?.exerciseName,
                                                    target:
                                                        exerciseCardGetExerciseRowList
                                                            .firstOrNull
                                                            ?.subMuscle1,
                                                    sets: functions
                                                        .countItems(
                                                            getJsonField(
                                                          exerciseItem,
                                                          r'''$["sets"]''',
                                                          true,
                                                        )!)
                                                        .toString(),
                                                    reps: getJsonField(
                                                      exerciseItem,
                                                      r'''$["reps"]''',
                                                    ).toString(),
                                                    rest: getJsonField(
                                                      exerciseItem,
                                                      r'''$["rest_seconds"]''',
                                                    ).toString(),
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional(0.0, 0.96),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                24.0, 24.0, 24.0, 24.0),
                            child: FFButtonWidget(
                              onPressed: () async {
                                _model.uuid = await actions.generateUuidV4();
                                await SQLiteManager.instance.insertWorkout(
                                  id: _model.uuid!,
                                  name: getJsonField(
                                    widget.result,
                                    r'''$["workout_name"]''',
                                  ).toString(),
                                  createdAt: dateTimeFormat(
                                    "yyyy-MM-ddTHH:mm:ssZ",
                                    getCurrentTimestamp,
                                    locale: FFLocalizations.of(context)
                                        .languageCode,
                                  ),
                                  userId: currentUserUid,
                                );
                                for (int loop1Index = 0;
                                    loop1Index <
                                        getJsonField(
                                          widget.result,
                                          r'''$["exercises"]''',
                                          true,
                                        )!
                                            .length;
                                    loop1Index++) {
                                  final currentLoop1Item = getJsonField(
                                    widget.result,
                                    r'''$["exercises"]''',
                                    true,
                                  )![loop1Index];
                                  _model.uuid2 = await actions.generateUuidV4();
                                  _model.ex =
                                      await SQLiteManager.instance.exercise2(
                                    exerciseId: getJsonField(
                                      currentLoop1Item,
                                      r'''$["exercise_id"]''',
                                    ),
                                  );
                                  await SQLiteManager.instance
                                      .insertWorkoutExercise(
                                    id: _model.uuid2!,
                                    workoutId: _model.uuid!,
                                    createdAt: dateTimeFormat(
                                      "yyyy-MM-ddTHH:mm:ssZ",
                                      getCurrentTimestamp,
                                      locale: FFLocalizations.of(context)
                                          .languageCode,
                                    ),
                                    order: loop1Index,
                                    exerciseId: getJsonField(
                                      currentLoop1Item,
                                      r'''$["exercise_id"]''',
                                    ),
                                    restSeconds:
                                        functions.secondsToMs(getJsonField(
                                      currentLoop1Item,
                                      r'''$["rest_seconds"]''',
                                    )),
                                    exerciseName: _model.ex!.firstOrNull!.name,
                                    userId: currentUserUid,
                                    isSuperset: 0,
                                    supersetGroupId: '',
                                  );
                                  for (int loop2Index = 0;
                                      loop2Index <
                                          getJsonField(
                                            currentLoop1Item,
                                            r'''$["sets"]''',
                                            true,
                                          )!
                                              .length;
                                      loop2Index++) {
                                    final currentLoop2Item = getJsonField(
                                      currentLoop1Item,
                                      r'''$["sets"]''',
                                      true,
                                    )![loop2Index];
                                    _model.uuid3 =
                                        await actions.generateUuidV4();
                                    await SQLiteManager.instance
                                        .insertExerciseSts(
                                      workoutExerciseId: _model.uuid2!,
                                      setNumber: getJsonField(
                                        currentLoop2Item,
                                        r'''$["set_number"]''',
                                      ),
                                      targetReps: getJsonField(
                                        currentLoop2Item,
                                        r'''$["target_reps"]''',
                                      ),
                                      isWarmup: 0,
                                      isDropset: 0,
                                      dropNumber: 0,
                                      workoutId: _model.uuid!,
                                      id: _model.uuid3!,
                                      weighted: getJsonField(
                                        currentLoop1Item,
                                        r'''$["weighted"]''',
                                      ),
                                      durationSeconds: 0,
                                    );
                                    await actions.saveExerciseSetOffline(
                                      _model.uuid3!,
                                      _model.uuid2!,
                                      getJsonField(
                                        currentLoop2Item,
                                        r'''$["set_number"]''',
                                      ),
                                      getJsonField(
                                        currentLoop2Item,
                                        r'''$["target_reps"]''',
                                      ),
                                      0,
                                      0,
                                      0,
                                      _model.uuid,
                                      getJsonField(
                                        currentLoop1Item,
                                        r'''$["weighted"]''',
                                      ),
                                      0,
                                    );
                                  }
                                }

                                context.pushNamed(MasterPageWidget.routeName);

                                safeSetState(() {});
                              },
                              text: FFLocalizations.of(context).getText(
                                'yknk7dq0' /* Save Workout */,
                              ),
                              options: FFButtonOptions(
                                width: MediaQuery.sizeOf(context).width * 1.0,
                                height: 50.0,
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 16.0, 0.0),
                                iconPadding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 0.0),
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
                                      color: Colors.white,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                elevation: 0.0,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ),
                        ),
                      ],
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
}
