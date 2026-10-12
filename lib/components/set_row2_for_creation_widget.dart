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
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
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

    _model.repsFieldTextController ??= TextEditingController(
        text: functions
            .getInitialLoggedSetValue(FFAppState().loggedSetsCreation.toList(),
                widget.exerciseId!, widget.setNumber!, 'reps')
            ?.toString());
    _model.repsFieldFocusNode ??= FocusNode();
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
                      Align(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: FutureBuilder<List<CorrectedPreviosSetRow>>(
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
                            final containerCorrectedPreviosSetRowList =
                                snapshot.data!;

                            return Container(
                              width: 80.0,
                              decoration: BoxDecoration(),
                              child: Text(
                                functions.correctedFormatPreviousSet(
                                    containerCorrectedPreviosSetRowList
                                        .firstOrNull?.reps,
                                    containerCorrectedPreviosSetRowList
                                        .firstOrNull?.weight,
                                    containerCorrectedPreviosSetRowList
                                        .firstOrNull?.durationeconds,
                                    containerCorrectedPreviosSetRowList
                                                .firstOrNull?.isKg ==
                                            0
                                        ? false
                                        : true),
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
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
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            );
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
                                int.tryParse(
                                    _model.repsFieldTextController.text),
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
                      if (!widget.timed)
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Padding(
                              padding: EdgeInsets.all(5.0),
                              child: Container(
                                width: 80.0,
                                child: TextFormField(
                                  controller: _model.repsFieldTextController,
                                  focusNode: _model.repsFieldFocusNode,
                                  onChanged: (_) => EasyDebounce.debounce(
                                    '_model.repsFieldTextController',
                                    Duration(milliseconds: 0),
                                    () async {
                                      _model.updateReps = await actions
                                          .updateLoggedSetForCreationV4(
                                        FFAppState()
                                            .loggedSetsCreation
                                            .toList(),
                                        widget.exerciseId!,
                                        widget.setNumber!,
                                        0,
                                        0,
                                        int.tryParse(_model
                                            .repsFieldTextController.text),
                                        _model.durationMs,
                                      );
                                      FFAppState().loggedSetsCreation = _model
                                          .updateReps!
                                          .toList()
                                          .cast<dynamic>();
                                      safeSetState(() {});

                                      safeSetState(() {});
                                    },
                                  ),
                                  autofocus: false,
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                        ),
                                    hintText: functions
                                        .getHintFromPreviousSetForCreation(
                                            FFAppState()
                                                .loggedSetsCreation
                                                .toList(),
                                            widget.exerciseId!,
                                            widget.setNumber!,
                                            'reps')
                                        .toString(),
                                    hintStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                        ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0x00000000),
                                        width: 0.0,
                                      ),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0x00000000),
                                        width: 0.0,
                                      ),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 0.0,
                                      ),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 0.0,
                                      ),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
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
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                        fontSize: 14.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  cursorColor:
                                      FlutterFlowTheme.of(context).primaryText,
                                  validator: _model
                                      .repsFieldTextControllerValidator
                                      .asValidator(context),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp('[0-9]'))
                                  ],
                                ),
                              ),
                            ),
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
                                        FlutterFlowTheme.of(context).secondary,
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
