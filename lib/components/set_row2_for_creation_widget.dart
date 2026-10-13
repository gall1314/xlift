import '/auth/supabase_auth/auth_util.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/components/drop_set_creation_widget.dart';
import '/components/set_optin_bottom_creation_widget.dart';
import '/components/time_for_creation_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'set_row2_for_creation_model.dart';
export 'set_row2_for_creation_model.dart';

class SetRow2ForCreationWidget extends StatefulWidget {
  const SetRow2ForCreationWidget({
    super.key,
    this.setNumber,
    bool? timed,
    required this.exerciseId,
    required this.bodyweight,
    this.exerciseName,
    required this.allowsBodyweight,
  }) : this.timed = timed ?? false;

  final int? setNumber;
  final bool timed;
  final int? exerciseId;
  final bool? bodyweight;
  final String? exerciseName;
  final bool? allowsBodyweight;

  @override
  State<SetRow2ForCreationWidget> createState() =>
      _SetRow2ForCreationWidgetState();
}

class _SetRow2ForCreationWidgetState extends State<SetRow2ForCreationWidget> {
  late SetRow2ForCreationModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SetRow2ForCreationModel());

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      safeSetState(() {});
    });
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Align(
      alignment: AlignmentDirectional(0.0, -1.0),
      child: Container(
        width: 320.0,
        decoration: BoxDecoration(
          color: functions.getSetBackgroundColor(widget.setNumber!,
              Theme.of(context).brightness == Brightness.dark),
          borderRadius: BorderRadius.circular(12.0),
          shape: BoxShape.rectangle,
        ),
        alignment: AlignmentDirectional(0.0, 0.0),
        child: Stack(
          alignment: AlignmentDirectional(0.0, -1.0),
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 40.0,
                        height: 35.0,
                        child: custom_widgets.SetNumberButton(
                          width: 40.0,
                          height: 35.0,
                          label: widget.setNumber?.toString(),
                          fillColor:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          chevronColor:
                              FlutterFlowTheme.of(context).secondaryText,
                          showChevron: true,
                          enableHaptic: true,
                          onTap: () async {
                            await showModalBottomSheet(
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              enableDrag: false,
                              context: context,
                              builder: (context) {
                                return Padding(
                                  padding: MediaQuery.viewInsetsOf(context),
                                  child: SetOptinBottomCreationWidget(
                                    exerciseId: widget.exerciseId!,
                                    setNumber: widget.setNumber!,
                                    isDropSet: false,
                                    isTimed: widget.timed,
                                    removeSet: () async {
                                      var _shouldSetState = false;
                                      _model.removeCopy =
                                          await actions.removeSetFromExercise(
                                        FFAppState()
                                            .exerciseSetsCretion
                                            .toList(),
                                        widget.exerciseId!,
                                        widget.setNumber!,
                                      );
                                      _shouldSetState = true;
                                      FFAppState().exerciseSetsCretion = _model
                                          .removeCopy!
                                          .toList()
                                          .cast<dynamic>();
                                      safeSetState(() {});
                                      if (_model.dropSet) {
                                        _model.dropllogedCopy = await actions
                                            .removeDropsetsFromLoggedSets(
                                          FFAppState()
                                              .loggedSetsCreation
                                              .toList(),
                                          widget.exerciseId!,
                                        );
                                        _shouldSetState = true;
                                        _model.dropdrop3Copy = await actions
                                            .removeDropSetsForExercise(
                                          FFAppState()
                                              .dropSetsCreation
                                              .toList(),
                                          widget.exerciseId!,
                                        );
                                        _shouldSetState = true;
                                      } else {
                                        return;
                                      }

                                      FFAppState().dropSetsCreation = _model
                                          .dropdrop3Copy!
                                          .toList()
                                          .cast<dynamic>();
                                      FFAppState().loggedSetsCreation = _model
                                          .dropllogedCopy!
                                          .toList()
                                          .cast<dynamic>();
                                      safeSetState(() {});
                                    },
                                    addDropSet: () async {
                                      _model.dropSet = true;
                                      safeSetState(() {});
                                    },
                                    removeDropset: () async {
                                      _model.dropSet = false;
                                      safeSetState(() {});
                                      _model.dropdropCopy = await actions
                                          .removeDropSetsForExercise(
                                        FFAppState().dropSetsCreation.toList(),
                                        widget.exerciseId!,
                                      );
                                      _model.remove2Copy = await actions
                                          .removeDropsetsFromLoggedSets(
                                        FFAppState()
                                            .loggedSetsCreation
                                            .toList(),
                                        widget.exerciseId!,
                                      );
                                      FFAppState().dropSetsCreation = _model
                                          .dropdropCopy!
                                          .toList()
                                          .cast<dynamic>();
                                      FFAppState().loggedSetsCreation = _model
                                          .remove2Copy!
                                          .toList()
                                          .cast<dynamic>();
                                      safeSetState(() {});
                                    },
                                    reset: () async {
                                      safeSetState(() {});
                                    },
                                  ),
                                );
                              },
                            ).then((value) => safeSetState(() {}));

                            safeSetState(() {});
                          },
                        ),
                      ),
                      if (!functions.isSetDoneOffline(
                              FFAppState().loggedSets.toList(),
                              widget.exerciseId!,
                              widget.setNumber!) &&
                          widget.timed)
                        wrapWithModel(
                          model: _model.timeForCreationModel,
                          updateCallback: () => safeSetState(() {}),
                          child: TimeForCreationWidget(
                            exerciseId: widget.exerciseId!,
                            setNumber: widget.setNumber,
                            exerciseName: widget.exerciseName,
                            timerMode: () async {},
                            updatedDuration: (ms) async {
                              _model.durationMs = ms;
                              safeSetState(() {});
                              _model.updateTime2 =
                                  await actions.updateLoggedSetForCreationV4(
                                FFAppState().loggedSetsCreation.toList(),
                                widget.exerciseId!,
                                widget.setNumber!,
                                0,
                                0,
                                0,
                                ms,
                              );
                              FFAppState().loggedSetsCreation =
                                  _model.updateTime2!.toList().cast<dynamic>();
                              safeSetState(() {});
                              safeSetState(() {});

                              safeSetState(() {});
                            },
                          ),
                        ),
                      FutureBuilder<List<CorrectedPreviosSetRow>>(
                        future: SQLiteManager.instance.correctedPreviosSet(
                          exerciseId: widget.exerciseId!,
                          setNumber: widget.setNumber!,
                          userId: currentUserUid,
                        ),
                        builder: (context, snapshot) {
                          // Customize what your widget looks like when it's loading.
                          if (!snapshot.hasData) {
                            return Center(
                              child: SizedBox(
                                width: 50.0,
                                height: 50.0,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    FlutterFlowTheme.of(context).secondary,
                                  ),
                                ),
                              ),
                            );
                          }
                          final previousSetButtonCorrectedPreviosSetRowList =
                              snapshot.data!;

                          return Container(
                            width: 80.0,
                            height: 45.0,
                            child: custom_widgets.PreviousSetButton(
                              width: 80.0,
                              height: 45.0,
                              text: functions.correctedFormatPreviousSet(
                                  previousSetButtonCorrectedPreviosSetRowList
                                      .firstOrNull?.reps,
                                  previousSetButtonCorrectedPreviosSetRowList
                                      .firstOrNull?.weight,
                                  previousSetButtonCorrectedPreviosSetRowList
                                      .firstOrNull?.durationeconds,
                                  previousSetButtonCorrectedPreviosSetRowList
                                              .firstOrNull?.isKg ==
                                          0
                                      ? false
                                      : true),
                              exerciseId: widget.exerciseId,
                              setNumber: widget.setNumber,
                              textColor:
                                  FlutterFlowTheme.of(context).secondaryText,
                              fontSize: 14.0,
                              fontWeight: 400,
                              loggedSets: FFAppState().loggedSetsCreation,
                              onTap: () async {
                                _model.updateRepsCopyCopy =
                                    await actions.updateLoggedSetForCreationV4(
                                  FFAppState().loggedSetsCreation.toList(),
                                  widget.exerciseId!,
                                  widget.setNumber!,
                                  0,
                                  0,
                                  previousSetButtonCorrectedPreviosSetRowList
                                      .firstOrNull?.reps,
                                  _model.durationMs,
                                );
                                FFAppState().loggedSetsCreation = _model
                                    .updateRepsCopyCopy!
                                    .toList()
                                    .cast<dynamic>();
                                safeSetState(() {});

                                safeSetState(() {});
                              },
                            ),
                          );
                        },
                      ),
                      Container(
                        width: 80.0,
                        height: 45.0,
                        child: custom_widgets.RepsField(
                          width: 80.0,
                          height: 45.0,
                          exerciseId: widget.exerciseId,
                          setNumber: widget.setNumber,
                          value: functions.getInitialLoggedSetValue(
                              FFAppState().loggedSetsCreation.toList(),
                              widget.exerciseId!,
                              widget.setNumber!,
                              'reps'),
                          fontSize: 14.0,
                          fontWeight: 700,
                          textColor: FlutterFlowTheme.of(context).primaryText,
                          hintColor: FlutterFlowTheme.of(context).secondaryText,
                          focusColor: FlutterFlowTheme.of(context).primary,
                          isDark:
                              Theme.of(context).brightness == Brightness.dark,
                          hintText: functions
                              .getHintFromPreviousSetForCreation(
                                  FFAppState().loggedSetsCreation.toList(),
                                  widget.exerciseId!,
                                  widget.setNumber!,
                                  'reps')
                              .toString(),
                          loggedSets: FFAppState().loggedSetsCreation,
                          onValueCommitted: (value) async {
                            _model.updateRepsCopy =
                                await actions.updateLoggedSetForCreationV4(
                              FFAppState().loggedSetsCreation.toList(),
                              widget.exerciseId!,
                              widget.setNumber!,
                              0,
                              0,
                              value,
                              _model.durationMs,
                            );
                            FFAppState().loggedSetsCreation =
                                _model.updateRepsCopy!.toList().cast<dynamic>();
                            safeSetState(() {});

                            safeSetState(() {});
                          },
                        ),
                      ),
                      if (!widget.timed)
                        Expanded(
                          child: Container(
                            width: 80.0,
                            decoration: BoxDecoration(),
                            child: Stack(
                              alignment: AlignmentDirectional(0.0, 0.0),
                              children: [
                                if (!widget.timed)
                                  Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Text(
                                      FFLocalizations.of(context).getText(
                                        'dzdq7d11' /* - */,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                if (functions.showPlusWeightButton(
                                    widget.bodyweight! ? 1 : 0,
                                    FFAppState().exerciseSetsCretion.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!))
                                  FlutterFlowIconButton(
                                    borderRadius: 30.0,
                                    buttonSize: 35.0,
                                    fillColor:
                                        FlutterFlowTheme.of(context).primary,
                                    icon: Icon(
                                      Icons.add,
                                      color: FlutterFlowTheme.of(context).info,
                                      size: 18.0,
                                    ),
                                    onPressed: () async {
                                      _model.weighted3 =
                                          await actions.markSetWeightedInt(
                                        FFAppState()
                                            .exerciseSetsCretion
                                            .toList(),
                                        widget.exerciseId!,
                                        widget.setNumber!,
                                      );
                                      FFAppState().exerciseSetsCretion = _model
                                          .weighted3!
                                          .toList()
                                          .cast<dynamic>();
                                      safeSetState(() {});

                                      safeSetState(() {});
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ].divide(SizedBox(width: 6.0)),
                  ),
                ),
                if (_model.dropSet)
                  wrapWithModel(
                    model: _model.dropSetCreationModel,
                    updateCallback: () => safeSetState(() {}),
                    child: DropSetCreationWidget(
                      exerciseId: widget.exerciseId!,
                      setNumber: widget.setNumber!,
                      allowsBodyweight: widget.allowsBodyweight!,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
