import '/auth/supabase_auth/auth_util.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/components/exercise_componet_forn_edit2_widget.dart';
import '/components/place_holder_widget.dart';
import '/components/rest_shit_creation_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'edit_workout_v2_model.dart';
export 'edit_workout_v2_model.dart';

/// Create a page, Create a clean, modern **“Create Workout”** screen in a
/// light theme.
///
/// Top app bar: back arrow on the left, centered title “Create Workout”,
/// subtle shadow.
/// Below: full-width text field labeled “Workout name” (rounded corners, soft
/// border).
/// Main area: empty state. Center an outline dumbbell icon inside a soft
/// card, with short text under it: “Get started by adding exercises to your
/// workout.” Use friendly, neutral wording.
/// At the bottom: a large rounded primary button **“+ Add exercise”** (full
/// width, fixed above the safe-area). Button is vibrant (teal/blue) with
/// white text.
/// Overall style: lots of white space, subtle gray dividers, medium-rounded
/// cards, iOS-like typography, calm fitness vibe. No exercise list yet – only
/// this empty state layout.
class EditWorkoutV2Widget extends StatefulWidget {
  const EditWorkoutV2Widget({
    super.key,
    this.alreadySelceted,
    required this.shouldInit,
    this.workoutName,
    required this.workoutId,
  });

  final List<dynamic>? alreadySelceted;
  final bool? shouldInit;
  final String? workoutName;
  final String? workoutId;

  static String routeName = 'editWorkoutV2';
  static String routePath = '/editWorkoutV2';

  @override
  State<EditWorkoutV2Widget> createState() => _EditWorkoutV2WidgetState();
}

class _EditWorkoutV2WidgetState extends State<EditWorkoutV2Widget> {
  late EditWorkoutV2Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditWorkoutV2Model());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (widget.shouldInit!) {
        _model.simp = await SQLiteManager.instance.getExercisesSimp(
          workoutId: widget.workoutId,
        );
        _model.sets = await SQLiteManager.instance.getExerciseSetsForWorkout(
          workoutId: widget.workoutId!,
        );
        _model.set1 = await actions.initializeExerciseSetsForEdit(
          _model.simp!.toList(),
          _model.sets!.toList(),
        );
        _model.drop1 = await actions.initializeDropSetsFromSave(
          _model.sets?.toList(),
          _model.simp?.toList(),
        );
        FFAppState().exerciseSetsCretion =
            _model.set1!.toList().cast<dynamic>();
        FFAppState().dropSetsCreation = _model.drop1!.toList().cast<dynamic>();
        safeSetState(() {});
        _model.rest1 = await actions.initializeExerciseRestTimes(
          FFAppState().exerciseSetsCretion.toList(),
        );
        FFAppState().restTimerCreation = _model.rest1!;
        safeSetState(() {});
      }
    });

    _model.textController ??= TextEditingController(text: widget.workoutName);
    _model.textFieldFocusNode ??= FocusNode();
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
              FFAppState().dropSetsCreation = [];
              FFAppState().restTimerCreation = null;
              FFAppState().exerciseSetsCretion = [];
              FFAppState().loggedSetsCreation = [];
              safeSetState(() {});

              context.goNamed(
                LibraryWidget.routeName,
                queryParameters: {
                  'template': serializeParam(
                    false,
                    ParamType.bool,
                  ),
                }.withoutNulls,
              );
            },
          ),
          title: Text(
            FFLocalizations.of(context).getText(
              '1eaq2q45' /* Edit Workout */,
            ),
            style: FlutterFlowTheme.of(context).headlineSmall.override(
                  font: GoogleFonts.interTight(
                    fontWeight:
                        FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                  ),
                  fontSize: 16.0,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                ),
          ),
          actions: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(10.0, 10.0, 10.0, 10.0),
              child: FFButtonWidget(
                onPressed: functions.isExerciseSetsEmpty(
                        FFAppState().exerciseSetsCretion.toList())
                    ? null
                    : () async {
                        if (_model.textController.text == '') {
                          _model.nameError = true;
                          safeSetState(() {});
                        } else {
                          await SQLiteManager.instance.deleteWorex(
                            workoutId: widget.workoutId!,
                          );
                          await SQLiteManager.instance.updateWorkout(
                            workoutId: widget.workoutId!,
                            newName: _model.textController.text,
                          );
                          for (int loop1Index = 0;
                              loop1Index <
                                  FFAppState()
                                      .exerciseSetsCretion
                                      .map((e) => e)
                                      .toList()
                                      .length;
                              loop1Index++) {
                            final currentLoop1Item = FFAppState()
                                .exerciseSetsCretion
                                .map((e) => e)
                                .toList()[loop1Index];
                            _model.uuid = await actions.generateUuidV4();
                            await SQLiteManager.instance.smartWorex(
                              id: _model.uuid!,
                              workoutId: widget.workoutId!,
                              createdAt: getCurrentTimestamp.toString(),
                              order: loop1Index,
                              userId: currentUserUid,
                              restSeconds: functions.getRestDurationForExercise(
                                  FFAppState().restTimerCreation,
                                  getJsonField(
                                    currentLoop1Item,
                                    r'''$["exerciseId"]''',
                                  )),
                              exerciseId: getJsonField(
                                currentLoop1Item,
                                r'''$["exerciseId"]''',
                              ),
                            );
                            _model.exsetsAttac = await actions
                                .attachWorkoutExerciseIdToExerciseSets(
                              FFAppState().exerciseSetsCretion.toList(),
                              getJsonField(
                                currentLoop1Item,
                                r'''$["exerciseId"]''',
                              ),
                              _model.uuid!,
                            );
                            _model.dropattach =
                                await actions.attachWorkoutExerciseIdToDropSets(
                              FFAppState().dropSetsCreation.toList(),
                              getJsonField(
                                currentLoop1Item,
                                r'''$["exerciseId"]''',
                              ),
                              _model.uuid!,
                            );
                            FFAppState().exerciseSetsCretion =
                                _model.exsetsAttac!.toList().cast<dynamic>();
                            FFAppState().dropSetsCreation =
                                _model.dropattach!.toList().cast<dynamic>();
                            safeSetState(() {});
                          }
                          _model.full = await actions
                              .mergeLoggedExerciseAndDropSetsForEdit(
                            FFAppState().exerciseSetsCretion.toList(),
                            FFAppState().loggedSetsCreation.toList(),
                            FFAppState().dropSetsCreation.toList(),
                          );
                          await SQLiteManager.instance.deleteExerciseSets(
                            workoutId: widget.workoutId!,
                          );
                          for (int loop2Index = 0;
                              loop2Index < _model.full!.length;
                              loop2Index++) {
                            final currentLoop2Item = _model.full![loop2Index];
                            _model.uuid2 = await actions.generateUuidV4();
                            await SQLiteManager.instance.insertExerciseSts(
                              workoutExerciseId: getJsonField(
                                currentLoop2Item,
                                r'''$["workoutExerciseId"]''',
                              ).toString(),
                              setNumber: getJsonField(
                                currentLoop2Item,
                                r'''$["setNumber"]''',
                              ),
                              targetReps: getJsonField(
                                currentLoop2Item,
                                r'''$["targetReps"]''',
                              ),
                              isWarmup: 0,
                              isDropset: getJsonField(
                                currentLoop2Item,
                                r'''$["isDropSet"]''',
                              ),
                              dropNumber: getJsonField(
                                currentLoop2Item,
                                r'''$["dropNumber"]''',
                              ),
                              workoutId: widget.workoutId!,
                              id: _model.uuid2!,
                              weighted: getJsonField(
                                currentLoop2Item,
                                r'''$["weighted"]''',
                              ),
                              durationSeconds: getJsonField(
                                currentLoop2Item,
                                r'''$["durationSeconds"]''',
                              ),
                            );
                          }

                          context.pushNamed(
                            MasterPageWidget.routeName,
                            queryParameters: {
                              'initialTab': serializeParam(
                                4,
                                ParamType.int,
                              ),
                            }.withoutNulls,
                          );

                          FFAppState().exerciseSetsCretion = [];
                          FFAppState().loggedSetsCreation = [];
                          safeSetState(() {});
                        }

                        safeSetState(() {});
                      },
                text: FFLocalizations.of(context).getText(
                  '62rcsx1a' /* Save */,
                ),
                options: FFButtonOptions(
                  height: 16.0,
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  iconPadding:
                      EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  color: FlutterFlowTheme.of(context).secondary,
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
                    width: 0.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                  disabledColor:
                      FlutterFlowTheme.of(context).secondaryBackground,
                  disabledTextColor: FlutterFlowTheme.of(context).alternate,
                ),
              ),
            ),
          ],
          centerTitle: true,
          elevation: 1.0,
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                child: Container(
                  width: double.infinity,
                  child: TextFormField(
                    controller: _model.textController,
                    focusNode: _model.textFieldFocusNode,
                    onChanged: (_) => EasyDebounce.debounce(
                      '_model.textController',
                      Duration(milliseconds: 0),
                      () async {
                        _model.workoutName = _model.textController.text;
                        safeSetState(() {});
                      },
                    ),
                    autofocus: false,
                    textInputAction: TextInputAction.done,
                    obscureText: false,
                    decoration: InputDecoration(
                      labelStyle:
                          FlutterFlowTheme.of(context).bodyLarge.override(
                                font: GoogleFonts.inter(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyLarge
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyLarge
                                      .fontStyle,
                                ),
                                fontSize: 16.0,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .fontStyle,
                              ),
                      alignLabelWithHint: true,
                      hintText: functions.shouldShowWorkoutNameError(
                              _model.nameError, _model.workoutName)
                          ? 'Workout name is required'
                          : 'Enter workout name',
                      hintStyle: FlutterFlowTheme.of(context)
                          .bodyMedium
                          .override(
                            font: GoogleFonts.inter(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            color: functions.shouldShowWorkoutNameError(
                                    _model.nameError, _model.workoutName)
                                ? FlutterFlowTheme.of(context).error
                                : FlutterFlowTheme.of(context).secondaryText,
                            fontSize: 16.0,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: FlutterFlowTheme.of(context).alternate,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: FlutterFlowTheme.of(context).primary,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0x00000000),
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0x00000000),
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      filled: true,
                      fillColor:
                          FlutterFlowTheme.of(context).secondaryBackground,
                      contentPadding: EdgeInsetsDirectional.fromSTEB(
                          16.0, 16.0, 16.0, 16.0),
                    ),
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          font: GoogleFonts.inter(
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyLarge
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyLarge
                                .fontStyle,
                          ),
                          fontSize: 16.0,
                          letterSpacing: 0.0,
                          fontWeight:
                              FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                        ),
                    cursorColor: FlutterFlowTheme.of(context).primary,
                    validator:
                        _model.textControllerValidator.asValidator(context),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                child: Container(
                  child: Builder(
                    builder: (context) {
                      final exercise = functions
                          .buildExerciseTableFromSets(
                              FFAppState().exerciseSetsCretion.toList())
                          .toList();
                      if (exercise.isEmpty) {
                        return PlaceHolderWidget();
                      }

                      return ListView.separated(
                        padding: EdgeInsets.zero,
                        primary: false,
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        itemCount: exercise.length,
                        separatorBuilder: (_, __) => SizedBox(height: 20.0),
                        itemBuilder: (context, exerciseIndex) {
                          final exerciseItem = exercise[exerciseIndex];
                          return ExerciseComponetFornEdit2Widget(
                            key: Key(
                                'Keys9p_${exerciseIndex}_of_${exercise.length}'),
                            exerciseId: getJsonField(
                              exerciseItem,
                              r'''$["exerciseId"]''',
                            ),
                            selectRest: () async {
                              await showModalBottomSheet(
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                enableDrag: false,
                                context: context,
                                builder: (context) {
                                  return GestureDetector(
                                    onTap: () {
                                      FocusScope.of(context).unfocus();
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                    },
                                    child: Padding(
                                      padding: MediaQuery.viewInsetsOf(context),
                                      child: RestShitCreationWidget(
                                        exerciseId: getJsonField(
                                          exerciseItem,
                                          r'''$["exerciseId"]''',
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ).then((value) => safeSetState(() {}));
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                child: FFButtonWidget(
                  onPressed: () async {
                    context.goNamed(
                      AddExercisesForEditWidget.routeName,
                      queryParameters: {
                        'workoutName': serializeParam(
                          widget.workoutName,
                          ParamType.String,
                        ),
                        'workoutId': serializeParam(
                          widget.workoutId,
                          ParamType.String,
                        ),
                      }.withoutNulls,
                    );
                  },
                  text: FFLocalizations.of(context).getText(
                    '40roqkvg' /* Add exercises */,
                  ),
                  options: FFButtonOptions(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    height: 55.0,
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                    iconPadding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                    color: FlutterFlowTheme.of(context).secondary,
                    textStyle: FlutterFlowTheme.of(context).titleSmall.override(
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
                          fontStyle:
                              FlutterFlowTheme.of(context).titleSmall.fontStyle,
                        ),
                    elevation: 0.0,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
              ),
            ]
                .divide(SizedBox(height: 24.0))
                .addToStart(SizedBox(height: 24.0))
                .addToEnd(SizedBox(height: 100.0)),
          ),
        ),
      ),
    );
  }
}
