import '/auth/supabase_auth/auth_util.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/components/drop_set_creation_edit_widget.dart';
import '/components/set_optin_bottom_creation_widget.dart';
import '/components/time_for_creation_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'set_row_edit_temp_model.dart';
export 'set_row_edit_temp_model.dart';

class SetRowEditTempWidget extends StatefulWidget {
  const SetRowEditTempWidget({
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
  State<SetRowEditTempWidget> createState() => _SetRowEditTempWidgetState();
}

class _SetRowEditTempWidgetState extends State<SetRowEditTempWidget> {
  late SetRowEditTempModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SetRowEditTempModel());

    _model.repsFieldTextController ??= TextEditingController(
        text: functions
            .getInitialValueForSetField(
                FFAppState().loggedSetsCreation.toList(),
                FFAppState().exerciseSetsCretion.toList(),
                widget.exerciseId!,
                widget.setNumber!,
                'reps')
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
                      Stack(
                        children: [
                          Container(
                            width: 40.0,
                            height: 35.0,
                            decoration: BoxDecoration(),
                            child: Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Text(
                                valueOrDefault<String>(
                                  widget.setNumber?.toString(),
                                  '#',
                                ),
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
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
                          ),
                          FFButtonWidget(
                            onPressed: () async {
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
                                        _model.remove =
                                            await actions.removeSetFromExercise(
                                          FFAppState()
                                              .exerciseSetsCretion
                                              .toList(),
                                          widget.exerciseId!,
                                          widget.setNumber!,
                                        );
                                        _shouldSetState = true;
                                        FFAppState().exerciseSetsCretion =
                                            _model.remove!
                                                .toList()
                                                .cast<dynamic>();
                                        safeSetState(() {});
                                        if (_model.dropSet) {
                                          _model.droplloged = await actions
                                              .removeDropsetsFromLoggedSets(
                                            FFAppState()
                                                .loggedSetsCreation
                                                .toList(),
                                            widget.exerciseId!,
                                          );
                                          _shouldSetState = true;
                                          _model.dropdrop3 = await actions
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
                                            .dropdrop3!
                                            .toList()
                                            .cast<dynamic>();
                                        FFAppState().loggedSetsCreation = _model
                                            .droplloged!
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
                                        _model.dropdrop = await actions
                                            .removeDropSetsForExercise(
                                          FFAppState()
                                              .dropSetsCreation
                                              .toList(),
                                          widget.exerciseId!,
                                        );
                                        _model.remove2 = await actions
                                            .removeDropsetsFromLoggedSets(
                                          FFAppState()
                                              .loggedSetsCreation
                                              .toList(),
                                          widget.exerciseId!,
                                        );
                                        FFAppState().dropSetsCreation = _model
                                            .dropdrop!
                                            .toList()
                                            .cast<dynamic>();
                                        FFAppState().loggedSetsCreation = _model
                                            .remove2!
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
                            text: widget.setNumber!.toString(),
                            options: FFButtonOptions(
                              width: 40.0,
                              height: 35.0,
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 0.0),
                              iconPadding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 0.0),
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
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
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    fontSize: 2.0,
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
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            showLoadingIndicator: false,
                          ),
                        ],
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
                                valueOrDefault<String>(
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
                                  '-',
                                ),
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
                      if (functions.isSetDoneOffline(
                              FFAppState().loggedSets.toList(),
                              widget.exerciseId!,
                              widget.setNumber!) &&
                          widget.timed)
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Container(
                              height: 50.0,
                              decoration: BoxDecoration(),
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: Text(
                                valueOrDefault<String>(
                                  functions.getFormattedDurationWithFallback(
                                      FFAppState().loggedSets.toList(),
                                      widget.exerciseId!,
                                      widget.setNumber!),
                                  '-',
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
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
                          child: Container(
                            width: MediaQuery.sizeOf(context).width * 1.66,
                            height: 50.0,
                            decoration: BoxDecoration(),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (!widget.timed)
                                        Expanded(
                                          child: Stack(
                                            alignment:
                                                AlignmentDirectional(0.0, 0.0),
                                            children: [
                                              Align(
                                                alignment: AlignmentDirectional(
                                                    0.0, 0.0),
                                                child: Padding(
                                                  padding: EdgeInsets.all(5.0),
                                                  child: Container(
                                                    width: 80.0,
                                                    child: TextFormField(
                                                      controller: _model
                                                          .repsFieldTextController,
                                                      focusNode: _model
                                                          .repsFieldFocusNode,
                                                      onChanged: (_) =>
                                                          EasyDebounce.debounce(
                                                        '_model.repsFieldTextController',
                                                        Duration(
                                                            milliseconds: 0),
                                                        () async {
                                                          _model.updateTime =
                                                              await actions
                                                                  .updateLoggedSetForCreationV4(
                                                            FFAppState()
                                                                .loggedSetsCreation
                                                                .toList(),
                                                            widget.exerciseId!,
                                                            widget.setNumber!,
                                                            0,
                                                            0,
                                                            int.tryParse(_model
                                                                .repsFieldTextController
                                                                .text),
                                                            _model.durationMs,
                                                          );
                                                          FFAppState()
                                                                  .loggedSetsCreation =
                                                              _model.updateTime!
                                                                  .toList()
                                                                  .cast<
                                                                      dynamic>();
                                                          safeSetState(() {});

                                                          safeSetState(() {});
                                                        },
                                                      ),
                                                      autofocus: false,
                                                      obscureText: false,
                                                      decoration:
                                                          InputDecoration(
                                                        isDense: true,
                                                        labelStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                ),
                                                        hintText: functions
                                                            .getCreationHint(
                                                                FFAppState()
                                                                    .loggedSetsCreation
                                                                    .toList(),
                                                                widget
                                                                    .exerciseId!,
                                                                widget
                                                                    .setNumber!,
                                                                true),
                                                        hintStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                            color: Color(
                                                                0x00000000),
                                                            width: 0.0,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10.0),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                            color: Color(
                                                                0x00000000),
                                                            width: 0.0,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10.0),
                                                        ),
                                                        errorBorder:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .error,
                                                            width: 0.0,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10.0),
                                                        ),
                                                        focusedErrorBorder:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .error,
                                                            width: 0.0,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10.0),
                                                        ),
                                                      ),
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            font: GoogleFonts
                                                                .inter(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                            ),
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primaryText,
                                                            fontSize: 14.0,
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                      textAlign:
                                                          TextAlign.center,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      cursorColor:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                      validator: _model
                                                          .repsFieldTextControllerValidator
                                                          .asValidator(context),
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter
                                                            .allow(
                                                                RegExp('[0-9]'))
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (!widget.timed)
                                        Expanded(
                                          child: Stack(
                                            alignment:
                                                AlignmentDirectional(0.0, 0.0),
                                            children: [
                                              if (!widget.timed)
                                                Align(
                                                  alignment:
                                                      AlignmentDirectional(
                                                          -0.69, 0.0),
                                                  child: Container(
                                                    width: 80.0,
                                                    height: 100.0,
                                                    decoration: BoxDecoration(),
                                                    child: Visibility(
                                                      visible: functions
                                                          .isSetDoneOffline(
                                                              FFAppState()
                                                                  .loggedSets
                                                                  .toList(),
                                                              widget
                                                                  .exerciseId!,
                                                              widget
                                                                  .setNumber!),
                                                      child: Align(
                                                        alignment:
                                                            AlignmentDirectional(
                                                                0.0, 0.0),
                                                        child: Text(
                                                          functions.getLoggedValue(
                                                              FFAppState()
                                                                  .loggedSets
                                                                  .toList(),
                                                              widget
                                                                  .exerciseId!,
                                                              widget
                                                                  .setNumber!,
                                                              'weight'),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              if (functions
                                                  .showPlusButtonForCreation(
                                                      widget.bodyweight!,
                                                      _model
                                                          .overrideBodyweight))
                                                FlutterFlowIconButton(
                                                  borderRadius: 30.0,
                                                  buttonSize: 35.0,
                                                  fillColor:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .primary,
                                                  icon: Icon(
                                                    Icons.add,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .info,
                                                    size: 18.0,
                                                  ),
                                                  onPressed: () async {
                                                    _model.overrideBodyweight =
                                                        true;
                                                    safeSetState(() {});
                                                    _model.update = await actions
                                                        .updateLoggedSetForCreationV4(
                                                      FFAppState()
                                                          .loggedSetsCreation
                                                          .toList(),
                                                      widget.exerciseId!,
                                                      widget.setNumber!,
                                                      0,
                                                      0,
                                                      int.tryParse(_model
                                                          .repsFieldTextController
                                                          .text),
                                                      _model.durationMs,
                                                    );
                                                    FFAppState()
                                                            .loggedSetsCreation =
                                                        _model.update!
                                                            .toList()
                                                            .cast<dynamic>();
                                                    safeSetState(() {});

                                                    safeSetState(() {});
                                                  },
                                                ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ].divide(SizedBox(width: 6.0)),
                  ),
                ),
                if (functions.shouldShowDropTable(widget.exerciseId!,
                    widget.setNumber!, FFAppState().dropSetsCreation.toList()))
                  wrapWithModel(
                    model: _model.dropSetCreationEditModel,
                    updateCallback: () => safeSetState(() {}),
                    child: DropSetCreationEditWidget(
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
