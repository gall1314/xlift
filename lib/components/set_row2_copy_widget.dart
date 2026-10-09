import '/auth/supabase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/components/analysi_alert_widget.dart';
import '/components/analyze2_app_widget.dart';
import '/components/drop_set_widget.dart';
import '/components/set_alert2_widget.dart';
import '/components/set_optin_bottom_widget.dart';
import '/components/time_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:async';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'set_row2_copy_model.dart';
export 'set_row2_copy_model.dart';

class SetRow2CopyWidget extends StatefulWidget {
  const SetRow2CopyWidget({
    super.key,
    this.setNumber,
    this.exerciseName,
    bool? timed,
    required this.exerciseId,
    bool? ai,
    required this.startTimer,
    required this.bodyweight,
    required this.showRestTime,
    required this.allowsBodyweight,
    required this.closeIt,
    this.showError,
  })  : this.timed = timed ?? false,
        this.ai = ai ?? false;

  final int? setNumber;
  final String? exerciseName;
  final bool timed;
  final int? exerciseId;
  final bool ai;
  final Future Function()? startTimer;
  final bool? bodyweight;
  final bool? showRestTime;
  final bool? allowsBodyweight;
  final Future Function()? closeIt;
  final Future Function()? showError;

  @override
  State<SetRow2CopyWidget> createState() => _SetRow2CopyWidgetState();
}

class _SetRow2CopyWidgetState extends State<SetRow2CopyWidget> {
  late SetRow2CopyModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SetRow2CopyModel());

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      safeSetState(() {});
    });

    _model.repsFieldTextController ??= TextEditingController(
        text: functions
            .getInitialSetValue(FFAppState().loggedSets.toList(),
                widget.exerciseId!, widget.setNumber!, 'reps')
            ?.toString());
    _model.repsFieldFocusNode ??= FocusNode();

    _model.weightFieldTextController ??= TextEditingController(
        text: functions
            .getInitialSetValue(FFAppState().loggedSets.toList(),
                widget.exerciseId!, widget.setNumber!, 'weight')
            ?.toString());
    _model.weightFieldFocusNode ??= FocusNode();
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
      child: InkWell(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () async {
          if (functions.isSetDoneOffline(FFAppState().loggedSets.toList(),
              widget.exerciseId!, widget.setNumber!)) {
            _model.expand = !_model.expand;
            safeSetState(() {});
          } else {
            return;
          }
        },
        child: Container(
          width: 320.0,
          decoration: BoxDecoration(
            color: functions.isSetDoneOffline(FFAppState().loggedSets.toList(),
                    widget.exerciseId!, widget.setNumber!)
                ? FlutterFlowTheme.of(context).accent2
                : functions.getSetBackgroundColor(widget.setNumber!,
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
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
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
                            if (!functions.isSetDoneOffline(
                                FFAppState().loggedSets.toList(),
                                widget.exerciseId!,
                                widget.setNumber!))
                              Builder(
                                builder: (context) => FFButtonWidget(
                                  onPressed: () async {
                                    await showModalBottomSheet(
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      enableDrag: false,
                                      context: context,
                                      builder: (context) {
                                        return Padding(
                                          padding:
                                              MediaQuery.viewInsetsOf(context),
                                          child: SetOptinBottomWidget(
                                            exerciseId: widget.exerciseId!,
                                            setNumber: widget.setNumber!,
                                            isDropSet: _model.dropSet,
                                            isTimed:
                                                !(widget.timed ? false : true),
                                            removeSet: () async {
                                              var _shouldSetState = false;
                                              _model.remove = await actions
                                                  .removeSetFromExercise(
                                                FFAppState()
                                                    .exercisesets
                                                    .toList(),
                                                widget.exerciseId!,
                                                widget.setNumber!,
                                              );
                                              _shouldSetState = true;
                                              FFAppState().exercisesets = _model
                                                  .remove!
                                                  .toList()
                                                  .cast<dynamic>();
                                              safeSetState(() {});
                                              if (_model.dropSet) {
                                                _model.droplloged = await actions
                                                    .removeDropsetsFromLoggedSets(
                                                  FFAppState()
                                                      .loggedSets
                                                      .toList(),
                                                  widget.exerciseId!,
                                                );
                                                _shouldSetState = true;
                                                _model.dropdrop3 = await actions
                                                    .removeDropSetsForExercise(
                                                  FFAppState()
                                                      .dropSets
                                                      .toList(),
                                                  widget.exerciseId!,
                                                );
                                                _shouldSetState = true;
                                              } else {
                                                return;
                                              }

                                              FFAppState().dropSets = _model
                                                  .dropdrop3!
                                                  .toList()
                                                  .cast<dynamic>();
                                              FFAppState().loggedSets = _model
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
                                                FFAppState().dropSets.toList(),
                                                widget.exerciseId!,
                                              );
                                              _model.remove2 = await actions
                                                  .removeDropsetsFromLoggedSets(
                                                FFAppState()
                                                    .loggedSets
                                                    .toList(),
                                                widget.exerciseId!,
                                              );
                                              FFAppState().dropSets = _model
                                                  .dropdrop!
                                                  .toList()
                                                  .cast<dynamic>();
                                              FFAppState().loggedSets = _model
                                                  .remove2!
                                                  .toList()
                                                  .cast<dynamic>();
                                              safeSetState(() {});
                                            },
                                            markExercise: () async {
                                              if (functions
                                                  .canCompleteSetFromState(
                                                      FFAppState()
                                                          .loggedSets
                                                          .toList(),
                                                      widget.exerciseId!,
                                                      widget.setNumber!,
                                                      _model.durationMs,
                                                      FFAppState()
                                                          .dropSets
                                                          .toList(),
                                                      FFAppState()
                                                          .exercisesets
                                                          .toList(),
                                                      widget.allowsBodyweight!,
                                                      widget.timed)) {
                                                _model.doneTrueCopy =
                                                    await actions
                                                        .updateFlatSetValue(
                                                  FFAppState()
                                                      .loggedSets
                                                      .toList(),
                                                  widget.exerciseId!,
                                                  widget.setNumber!,
                                                  functions.getRepsWithFallback(
                                                      int.tryParse(_model
                                                          .repsFieldTextController
                                                          .text),
                                                      FFAppState()
                                                          .loggedSets
                                                          .toList(),
                                                      widget.exerciseId!,
                                                      widget.setNumber!,
                                                      FFAppState()
                                                          .exercisesets
                                                          .toList()),
                                                  functions.getFieldWithFallback(
                                                      double.tryParse(_model
                                                          .weightFieldTextController
                                                          .text),
                                                      FFAppState()
                                                          .loggedSets
                                                          .toList(),
                                                      widget.exerciseId!,
                                                      widget.setNumber!),
                                                  _model.durationMs,
                                                  true,
                                                  FFAppState()
                                                      .exercisesets
                                                      .toList(),
                                                );
                                                HapticFeedback.heavyImpact();
                                                await widget.startTimer?.call();
                                                FFAppState().loggedSets = _model
                                                    .doneTrueCopy!
                                                    .toList()
                                                    .cast<dynamic>();
                                                safeSetState(() {});
                                              } else {
                                                HapticFeedback.vibrate();
                                                await showDialog(
                                                  context: context,
                                                  builder: (dialogContext) {
                                                    return Dialog(
                                                      elevation: 0,
                                                      insetPadding:
                                                          EdgeInsets.zero,
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      alignment:
                                                          AlignmentDirectional(
                                                                  0.0, 0.0)
                                                              .resolve(
                                                                  Directionality.of(
                                                                      context)),
                                                      child: SetAlert2Widget(
                                                        errorMesseage:
                                                            functions.buildSetErrorMessage(
                                                                FFAppState()
                                                                    .loggedSets
                                                                    .toList(),
                                                                FFAppState()
                                                                    .dropSets
                                                                    .toList(),
                                                                widget
                                                                    .exerciseId!,
                                                                widget
                                                                    .setNumber!,
                                                                _model
                                                                    .durationMs,
                                                                widget.timed,
                                                                widget
                                                                    .allowsBodyweight!,
                                                                FFAppState()
                                                                    .exercisesets
                                                                    .toList()),
                                                      ),
                                                    );
                                                  },
                                                );
                                              }
                                            },
                                            reset: () async {
                                              safeSetState(() {
                                                _model.repsFieldTextController
                                                    ?.clear();
                                                _model.weightFieldTextController
                                                    ?.clear();
                                                _model.timeModel
                                                    .minutesUnitsTextController
                                                    ?.clear();
                                                _model.timeModel
                                                    .secondsTensTextController
                                                    ?.clear();
                                                _model.timeModel
                                                    .minutesTensTextController
                                                    ?.clear();
                                                _model.timeModel
                                                    .secondsUnitsTextController
                                                    ?.clear();
                                              });
                                              _model.droplloged2 = await actions
                                                  .removeDropsetsFromLoggedSets(
                                                FFAppState()
                                                    .loggedSets
                                                    .toList(),
                                                widget.exerciseId!,
                                              );
                                              _model.dropdrop4 = await actions
                                                  .removeDropSetsForExercise(
                                                FFAppState().dropSets.toList(),
                                                widget.exerciseId!,
                                              );
                                              FFAppState().loggedSets = _model
                                                  .droplloged2!
                                                  .toList()
                                                  .cast<dynamic>();
                                              FFAppState().dropSets = _model
                                                  .dropdrop4!
                                                  .toList()
                                                  .cast<dynamic>();
                                              safeSetState(() {});
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
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          fontSize: 2.0,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    elevation: 0.0,
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .alternate,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(14.0),
                                  ),
                                  showLoadingIndicator: false,
                                ),
                              ),
                          ],
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
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
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
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
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
                        if (!widget.timed)
                          Expanded(
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 1.66,
                              height: 50.0,
                              decoration: BoxDecoration(),
                              alignment: AlignmentDirectional(0.0, 0.0),
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
                                            child: InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                if (functions.isSetDoneOffline(
                                                    FFAppState()
                                                        .loggedSets
                                                        .toList(),
                                                    widget.exerciseId!,
                                                    widget.setNumber!)) {
                                                  _model.expand =
                                                      !_model.expand;
                                                  safeSetState(() {});
                                                } else {
                                                  return;
                                                }
                                              },
                                              child: Stack(
                                                alignment: AlignmentDirectional(
                                                    0.0, 0.0),
                                                children: [
                                                  if (!functions
                                                      .isSetDoneOffline(
                                                          FFAppState()
                                                              .loggedSets
                                                              .toList(),
                                                          widget.exerciseId!,
                                                          widget.setNumber!))
                                                    Align(
                                                      alignment:
                                                          AlignmentDirectional(
                                                              0.0, 0.0),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.all(5.0),
                                                        child: Container(
                                                          width: 80.0,
                                                          child: TextFormField(
                                                            controller: _model
                                                                .repsFieldTextController,
                                                            focusNode: _model
                                                                .repsFieldFocusNode,
                                                            onChanged: (_) =>
                                                                EasyDebounce
                                                                    .debounce(
                                                              '_model.repsFieldTextController',
                                                              Duration(
                                                                  milliseconds:
                                                                      0),
                                                              () async {
                                                                _model.repsUpdate =
                                                                    await actions
                                                                        .updateFlatSetValue(
                                                                  FFAppState()
                                                                      .loggedSets
                                                                      .toList(),
                                                                  widget
                                                                      .exerciseId!,
                                                                  widget
                                                                      .setNumber!,
                                                                  functions.getRepsWithFallback(
                                                                      int.tryParse(_model
                                                                          .repsFieldTextController
                                                                          .text),
                                                                      FFAppState()
                                                                          .loggedSets
                                                                          .toList(),
                                                                      widget
                                                                          .exerciseId!,
                                                                      widget
                                                                          .setNumber!,
                                                                      FFAppState()
                                                                          .exercisesets
                                                                          .toList()),
                                                                  functions.getFieldWithFallback(
                                                                      double.tryParse(_model
                                                                          .weightFieldTextController
                                                                          .text),
                                                                      FFAppState()
                                                                          .loggedSets
                                                                          .toList(),
                                                                      widget
                                                                          .exerciseId!,
                                                                      widget
                                                                          .setNumber!),
                                                                  _model
                                                                      .durationMs,
                                                                  false,
                                                                  FFAppState()
                                                                      .exercisesets
                                                                      .toList(),
                                                                );
                                                                FFAppState()
                                                                        .loggedSets =
                                                                    _model
                                                                        .repsUpdate!
                                                                        .toList()
                                                                        .cast<
                                                                            dynamic>();
                                                                safeSetState(
                                                                    () {});

                                                                safeSetState(
                                                                    () {});
                                                              },
                                                            ),
                                                            autofocus: false,
                                                            readOnly: functions
                                                                .isSetDoneOffline(
                                                                    FFAppState()
                                                                        .loggedSets
                                                                        .toList(),
                                                                    widget
                                                                        .exerciseId!,
                                                                    widget
                                                                        .setNumber!),
                                                            obscureText: false,
                                                            decoration:
                                                                InputDecoration(
                                                              isDense: true,
                                                              labelStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .inter(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .labelMedium
                                                                              .fontStyle,
                                                                        ),
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .labelMedium
                                                                            .fontStyle,
                                                                      ),
                                                              hintText: functions
                                                                  .getHintFromPreviousSetV2(
                                                                      FFAppState()
                                                                          .loggedSets
                                                                          .toList(),
                                                                      FFAppState()
                                                                          .exercisesets
                                                                          .toList(),
                                                                      widget
                                                                          .exerciseId!,
                                                                      widget
                                                                          .setNumber!,
                                                                      'reps')
                                                                  .toString(),
                                                              hintStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .inter(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .labelMedium
                                                                              .fontStyle,
                                                                        ),
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontStyle: FlutterFlowTheme.of(context)
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
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
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
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
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
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                  fontSize:
                                                                      14.0,
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
                                                            textAlign: TextAlign
                                                                .center,
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            cursorColor:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                            validator: _model
                                                                .repsFieldTextControllerValidator
                                                                .asValidator(
                                                                    context),
                                                            inputFormatters: [
                                                              FilteringTextInputFormatter
                                                                  .allow(RegExp(
                                                                      '[0-9]'))
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  if (functions
                                                      .isSetDoneOffline(
                                                          FFAppState()
                                                              .loggedSets
                                                              .toList(),
                                                          widget.exerciseId!,
                                                          widget.setNumber!))
                                                    InkWell(
                                                      splashColor:
                                                          Colors.transparent,
                                                      focusColor:
                                                          Colors.transparent,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      onTap: () async {
                                                        _model.expand =
                                                            !_model.expand;
                                                        safeSetState(() {});
                                                      },
                                                      child: Container(
                                                        width: 80.0,
                                                        height: 100.0,
                                                        decoration:
                                                            BoxDecoration(),
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
                                                                  'reps'),
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    font: GoogleFonts
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
                                                ],
                                              ),
                                            ),
                                          ),
                                        if (!widget.timed)
                                          Expanded(
                                            child: InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                if (functions.isSetDoneOffline(
                                                    FFAppState()
                                                        .loggedSets
                                                        .toList(),
                                                    widget.exerciseId!,
                                                    widget.setNumber!)) {
                                                  _model.expand =
                                                      !_model.expand;
                                                  safeSetState(() {});
                                                } else {
                                                  return;
                                                }
                                              },
                                              child: Stack(
                                                alignment: AlignmentDirectional(
                                                    0.0, 0.0),
                                                children: [
                                                  if (!widget.timed)
                                                    Align(
                                                      alignment:
                                                          AlignmentDirectional(
                                                              -0.69, 0.0),
                                                      child: InkWell(
                                                        splashColor:
                                                            Colors.transparent,
                                                        focusColor:
                                                            Colors.transparent,
                                                        hoverColor:
                                                            Colors.transparent,
                                                        highlightColor:
                                                            Colors.transparent,
                                                        onTap: () async {
                                                          if (functions
                                                              .isSetDoneOffline(
                                                                  FFAppState()
                                                                      .loggedSets
                                                                      .toList(),
                                                                  widget
                                                                      .exerciseId!,
                                                                  widget
                                                                      .setNumber!)) {
                                                            _model.expand =
                                                                !_model.expand;
                                                            safeSetState(() {});
                                                          } else {
                                                            return;
                                                          }
                                                        },
                                                        child: Container(
                                                          width: 80.0,
                                                          height: 100.0,
                                                          decoration:
                                                              BoxDecoration(),
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
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontStyle: FlutterFlowTheme.of(context)
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
                                                    ),
                                                  if (functions
                                                      .shouldShowWeightFieldOffline(
                                                          widget.exerciseId!,
                                                          widget.setNumber!,
                                                          FFAppState()
                                                              .loggedSets
                                                              .toList(),
                                                          FFAppState()
                                                              .exercisesets
                                                              .toList(),
                                                          widget.timed))
                                                    Align(
                                                      alignment:
                                                          AlignmentDirectional(
                                                              0.0, 0.0),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.all(5.0),
                                                        child: Container(
                                                          width: 80.0,
                                                          child: TextFormField(
                                                            controller: _model
                                                                .weightFieldTextController,
                                                            focusNode: _model
                                                                .weightFieldFocusNode,
                                                            onChanged: (_) =>
                                                                EasyDebounce
                                                                    .debounce(
                                                              '_model.weightFieldTextController',
                                                              Duration(
                                                                  milliseconds:
                                                                      0),
                                                              () async {
                                                                _model.weightUpdate =
                                                                    await actions
                                                                        .updateFlatSetValue(
                                                                  FFAppState()
                                                                      .loggedSets
                                                                      .toList(),
                                                                  widget
                                                                      .exerciseId!,
                                                                  widget
                                                                      .setNumber!,
                                                                  functions.getRepsWithFallback(
                                                                      int.tryParse(_model
                                                                          .repsFieldTextController
                                                                          .text),
                                                                      FFAppState()
                                                                          .loggedSets
                                                                          .toList(),
                                                                      widget
                                                                          .exerciseId!,
                                                                      widget
                                                                          .setNumber!,
                                                                      FFAppState()
                                                                          .exercisesets
                                                                          .toList()),
                                                                  functions.getFieldWithFallback(
                                                                      double.tryParse(_model
                                                                          .weightFieldTextController
                                                                          .text),
                                                                      FFAppState()
                                                                          .loggedSets
                                                                          .toList(),
                                                                      widget
                                                                          .exerciseId!,
                                                                      widget
                                                                          .setNumber!),
                                                                  _model
                                                                      .durationMs,
                                                                  false,
                                                                  FFAppState()
                                                                      .exercisesets
                                                                      .toList(),
                                                                );
                                                                FFAppState()
                                                                        .loggedSets =
                                                                    _model
                                                                        .weightUpdate!
                                                                        .toList()
                                                                        .cast<
                                                                            dynamic>();
                                                                safeSetState(
                                                                    () {});

                                                                safeSetState(
                                                                    () {});
                                                              },
                                                            ),
                                                            autofocus: false,
                                                            readOnly: functions
                                                                .isSetDoneOffline(
                                                                    FFAppState()
                                                                        .loggedSets
                                                                        .toList(),
                                                                    widget
                                                                        .exerciseId!,
                                                                    widget
                                                                        .setNumber!),
                                                            obscureText: false,
                                                            decoration:
                                                                InputDecoration(
                                                              isDense: true,
                                                              labelStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .inter(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .labelMedium
                                                                              .fontStyle,
                                                                        ),
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .labelMedium
                                                                            .fontStyle,
                                                                      ),
                                                              hintText: functions
                                                                  .getHintFromPreviousSetV2(
                                                                      FFAppState()
                                                                          .loggedSets
                                                                          .toList(),
                                                                      FFAppState()
                                                                          .exercisesets
                                                                          .toList(),
                                                                      widget
                                                                          .exerciseId!,
                                                                      widget
                                                                          .setNumber!,
                                                                      'weight')
                                                                  .toString(),
                                                              hintStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .inter(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .labelMedium
                                                                              .fontStyle,
                                                                        ),
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontStyle: FlutterFlowTheme.of(context)
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
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
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
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
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
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                  fontSize:
                                                                      14.0,
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
                                                            textAlign: TextAlign
                                                                .center,
                                                            keyboardType:
                                                                const TextInputType
                                                                    .numberWithOptions(
                                                                    decimal:
                                                                        true),
                                                            cursorColor:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                            validator: _model
                                                                .weightFieldTextControllerValidator
                                                                .asValidator(
                                                                    context),
                                                            inputFormatters: [
                                                              FilteringTextInputFormatter
                                                                  .allow(RegExp(
                                                                      '[a-zA-Z0-9]'))
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  if (functions.showPlusButton(
                                                      widget.exerciseId!,
                                                      widget.setNumber!,
                                                      FFAppState()
                                                          .loggedSets
                                                          .toList(),
                                                      FFAppState()
                                                          .exercisesets
                                                          .toList(),
                                                      widget.timed))
                                                    FlutterFlowIconButton(
                                                      borderRadius: 30.0,
                                                      buttonSize: 35.0,
                                                      fillColor:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondary,
                                                      icon: Icon(
                                                        Icons.add,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .info,
                                                        size: 18.0,
                                                      ),
                                                      onPressed: () async {
                                                        _model.weighted = true;
                                                        safeSetState(() {});
                                                        _model.weightupd =
                                                            await actions
                                                                .markSetWeighted(
                                                          FFAppState()
                                                              .exercisesets
                                                              .toList(),
                                                          widget.exerciseId!,
                                                          widget.setNumber!,
                                                        );
                                                        FFAppState()
                                                                .exercisesets =
                                                            _model.weightupd!
                                                                .toList()
                                                                .cast<
                                                                    dynamic>();
                                                        safeSetState(() {});

                                                        safeSetState(() {});
                                                      },
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (widget.ai)
                          Stack(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            children: [
                              if (functions.isSetLoading(
                                  FFAppState().workoutAnalysisState.toList(),
                                  widget.exerciseId!,
                                  widget.setNumber!))
                                Lottie.asset(
                                  'assets/jsons/AI_logo_Foriday.json',
                                  width: 35.0,
                                  height: 35.0,
                                  fit: BoxFit.contain,
                                  animate: true,
                                ),
                              if (functions.shouldShowErrorButton(
                                  FFAppState().workoutAnalysisState.toList(),
                                  widget.exerciseId!,
                                  widget.setNumber!))
                                Builder(
                                  builder: (context) => FlutterFlowIconButton(
                                    borderColor:
                                        FlutterFlowTheme.of(context).warning,
                                    borderRadius: 40.0,
                                    borderWidth: 2.5,
                                    buttonSize: 35.0,
                                    icon: Icon(
                                      Icons.error_outline,
                                      color:
                                          FlutterFlowTheme.of(context).warning,
                                      size: 18.0,
                                    ),
                                    onPressed: () async {
                                      await showDialog(
                                        context: context,
                                        builder: (dialogContext) {
                                          return Dialog(
                                            elevation: 0,
                                            insetPadding: EdgeInsets.zero,
                                            backgroundColor: Colors.transparent,
                                            alignment: AlignmentDirectional(
                                                    0.0, 0.0)
                                                .resolve(
                                                    Directionality.of(context)),
                                            child: AnalysiAlertWidget(
                                              video: _model.videoUrl,
                                              exerciseId: widget.exerciseId!,
                                              setNumber: widget.setNumber!,
                                              exerciseName:
                                                  widget.exerciseName!,
                                              retry: () async {
                                                _model.prosess2 = await actions
                                                    .setExerciseLoadingState(
                                                  FFAppState()
                                                      .workoutAnalysisState
                                                      .toList(),
                                                  widget.exerciseId!,
                                                  widget.setNumber!,
                                                  true,
                                                );
                                                FFAppState()
                                                        .workoutAnalysisState =
                                                    _model.prosess2!
                                                        .toList()
                                                        .cast<dynamic>();
                                                safeSetState(() {});
                                                _model.apiResultn0k2 =
                                                    await AnalyzeSquatCall.call(
                                                  video: _model.videoUrl,
                                                  exerciseType:
                                                      widget.exerciseName,
                                                  fast: true,
                                                );

                                                if ((_model.apiResultn0k2
                                                        ?.succeeded ??
                                                    true)) {
                                                  _model.res2 = await actions
                                                      .updateSetAnalysisResult(
                                                    FFAppState()
                                                        .workoutAnalysisState
                                                        .toList(),
                                                    widget.exerciseId!,
                                                    widget.setNumber!,
                                                    (_model.apiResultn0k2
                                                            ?.jsonBody ??
                                                        ''),
                                                  );
                                                  unawaited(
                                                    () async {
                                                      await actions
                                                          .sendAnalysisFinishedNotification(
                                                        widget.exerciseName,
                                                        false,
                                                      );
                                                    }(),
                                                  );
                                                  FFAppState()
                                                          .workoutAnalysisState =
                                                      _model.res2!
                                                          .toList()
                                                          .cast<dynamic>();
                                                  safeSetState(() {});
                                                  if (FFAppState().sound) {
                                                    _model.soundPlayer1 ??=
                                                        AudioPlayer();
                                                    if (_model.soundPlayer1!
                                                        .playing) {
                                                      await _model.soundPlayer1!
                                                          .stop();
                                                    }
                                                    _model.soundPlayer1!
                                                        .setVolume(0.72);
                                                    _model.soundPlayer1!
                                                        .setAsset(
                                                            'assets/audios/sample_pop_notification02_kofi_by_miraclei-360096.mp3')
                                                        .then((_) => _model
                                                            .soundPlayer1!
                                                            .play());
                                                  }
                                                  await showDialog(
                                                    context: context,
                                                    builder: (dialogContext) {
                                                      return Dialog(
                                                        elevation: 0,
                                                        insetPadding:
                                                            EdgeInsets.zero,
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        alignment:
                                                            AlignmentDirectional(
                                                                    0.0, 0.0)
                                                                .resolve(
                                                                    Directionality.of(
                                                                        context)),
                                                        child:
                                                            Analyze2AppWidget(
                                                          exercise: widget
                                                              .exerciseName!,
                                                          exerciseId: widget
                                                              .exerciseId!,
                                                          setNumber: widget
                                                              .setNumber!,
                                                          videoUrl:
                                                              _model.videoUrl,
                                                          videoReady:
                                                              (url) async {
                                                            _model.vidCopy2 =
                                                                await actions
                                                                    .updateSetAnalyzedVideo(
                                                              FFAppState()
                                                                  .workoutAnalysisState
                                                                  .toList(),
                                                              widget
                                                                  .exerciseId!,
                                                              widget
                                                                  .setNumber!,
                                                              getJsonField(
                                                                (_model.apiResultn0k2
                                                                        ?.jsonBody ??
                                                                    ''),
                                                                r'''$["video_path"]''',
                                                              ).toString(),
                                                            );
                                                            FFAppState()
                                                                    .workoutAnalysisState =
                                                                _model.vidCopy2!
                                                                    .toList()
                                                                    .cast<
                                                                        dynamic>();
                                                            safeSetState(() {});
                                                          },
                                                        ),
                                                      );
                                                    },
                                                  );
                                                }
                                              },
                                            ),
                                          );
                                        },
                                      );

                                      safeSetState(() {});
                                    },
                                  ),
                                ),
                              if (functions.isSetAnalysisDone(
                                  FFAppState().workoutAnalysisState.toList(),
                                  widget.exerciseId!,
                                  widget.setNumber!))
                                Builder(
                                  builder: (context) => FlutterFlowIconButton(
                                    borderColor:
                                        FlutterFlowTheme.of(context).secondary,
                                    borderRadius: 40.0,
                                    borderWidth: 2.5,
                                    buttonSize: 35.0,
                                    icon: Icon(
                                      Icons.assignment_outlined,
                                      color: FlutterFlowTheme.of(context)
                                          .secondary,
                                      size: 18.0,
                                    ),
                                    onPressed: () async {
                                      await showDialog(
                                        context: context,
                                        builder: (dialogContext) {
                                          return Dialog(
                                            elevation: 0,
                                            insetPadding: EdgeInsets.zero,
                                            backgroundColor: Colors.transparent,
                                            alignment: AlignmentDirectional(
                                                    0.0, 0.0)
                                                .resolve(
                                                    Directionality.of(context)),
                                            child: Analyze2AppWidget(
                                              exercise: widget.exerciseName!,
                                              exerciseId: widget.exerciseId!,
                                              setNumber: widget.setNumber!,
                                              videoUrl: _model.videoUrl,
                                              videoReady: (url) async {},
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              if (functions.shouldShowCameraButton(
                                  FFAppState().workoutAnalysisState.toList(),
                                  widget.exerciseId!,
                                  widget.setNumber!,
                                  FFAppState().analysisCount,
                                  FFAppState().isPremium))
                                Builder(
                                  builder: (context) => FlutterFlowIconButton(
                                    borderColor:
                                        FlutterFlowTheme.of(context).secondary,
                                    borderRadius: 40.0,
                                    borderWidth: 2.5,
                                    buttonSize: 35.0,
                                    icon: Icon(
                                      Icons.camera_alt,
                                      color: FlutterFlowTheme.of(context)
                                          .secondary,
                                      size: 18.0,
                                    ),
                                    onPressed: () async {
                                      final selectedMedia =
                                          await selectMediaWithSourceBottomSheet(
                                        context: context,
                                        allowPhoto: false,
                                        allowVideo: true,
                                      );
                                      if (selectedMedia != null &&
                                          selectedMedia.every((m) =>
                                              validateFileFormat(
                                                  m.storagePath, context))) {
                                        safeSetState(() => _model
                                                .isDataUploading_uploadDataSiv =
                                            true);
                                        var selectedUploadedFiles =
                                            <FFUploadedFile>[];

                                        try {
                                          selectedUploadedFiles = selectedMedia
                                              .map((m) => FFUploadedFile(
                                                    name: m.storagePath
                                                        .split('/')
                                                        .last,
                                                    bytes: m.bytes,
                                                    height:
                                                        m.dimensions?.height,
                                                    width: m.dimensions?.width,
                                                    blurHash: m.blurHash,
                                                    originalFilename:
                                                        m.originalFilename,
                                                  ))
                                              .toList();
                                        } finally {
                                          _model.isDataUploading_uploadDataSiv =
                                              false;
                                        }
                                        if (selectedUploadedFiles.length ==
                                            selectedMedia.length) {
                                          safeSetState(() {
                                            _model.uploadedLocalFile_uploadDataSiv =
                                                selectedUploadedFiles.first;
                                          });
                                        } else {
                                          safeSetState(() {});
                                          return;
                                        }
                                      }

                                      _model.videoUrl = _model
                                          .uploadedLocalFile_uploadDataSiv;
                                      safeSetState(() {});
                                      if (_model.videoUrl != null &&
                                          (_model.videoUrl?.bytes?.isNotEmpty ??
                                              false)) {
                                        _model.prosess = await actions
                                            .setExerciseLoadingState(
                                          FFAppState()
                                              .workoutAnalysisState
                                              .toList(),
                                          widget.exerciseId!,
                                          widget.setNumber!,
                                          true,
                                        );
                                        FFAppState().workoutAnalysisState =
                                            _model.prosess!
                                                .toList()
                                                .cast<dynamic>();
                                        safeSetState(() {});
                                        _model.apiResultn0k =
                                            await AnalyzeSquatCall.call(
                                          video: _model.videoUrl,
                                          exerciseType: widget.exerciseName,
                                          fast: true,
                                        );

                                        if ((_model.apiResultn0k?.succeeded ??
                                            true)) {
                                          _model.res = await actions
                                              .updateSetAnalysisResult(
                                            FFAppState()
                                                .workoutAnalysisState
                                                .toList(),
                                            widget.exerciseId!,
                                            widget.setNumber!,
                                            (_model.apiResultn0k?.jsonBody ??
                                                ''),
                                          );
                                          unawaited(
                                            () async {
                                              await actions
                                                  .sendAnalysisFinishedNotification(
                                                widget.exerciseName,
                                                false,
                                              );
                                            }(),
                                          );
                                          FFAppState().workoutAnalysisState =
                                              _model.res!
                                                  .toList()
                                                  .cast<dynamic>();
                                          safeSetState(() {});
                                          if (FFAppState().sound) {
                                            _model.soundPlayer2 ??=
                                                AudioPlayer();
                                            if (_model.soundPlayer2!.playing) {
                                              await _model.soundPlayer2!.stop();
                                            }
                                            _model.soundPlayer2!
                                                .setVolume(0.72);
                                            _model.soundPlayer2!
                                                .setAsset(
                                                    'assets/audios/sample_pop_notification02_kofi_by_miraclei-360096.mp3')
                                                .then((_) => _model
                                                    .soundPlayer2!
                                                    .play());
                                          }
                                          await showDialog(
                                            context: context,
                                            builder: (dialogContext) {
                                              return Dialog(
                                                elevation: 0,
                                                insetPadding: EdgeInsets.zero,
                                                backgroundColor:
                                                    Colors.transparent,
                                                alignment: AlignmentDirectional(
                                                        0.0, 0.0)
                                                    .resolve(Directionality.of(
                                                        context)),
                                                child: Analyze2AppWidget(
                                                  exercise:
                                                      widget.exerciseName!,
                                                  exerciseId:
                                                      widget.exerciseId!,
                                                  setNumber: widget.setNumber!,
                                                  videoUrl: _model.videoUrl,
                                                  videoReady: (url) async {},
                                                ),
                                              );
                                            },
                                          );
                                        } else {
                                          _model.error = await actions
                                              .updateSetAnalysisError(
                                            FFAppState()
                                                .workoutAnalysisState
                                                .toList(),
                                            widget.exerciseId!,
                                            widget.setNumber!,
                                          );
                                          FFAppState().workoutAnalysisState =
                                              _model.error!
                                                  .toList()
                                                  .cast<dynamic>();
                                          safeSetState(() {});
                                        }
                                      }

                                      safeSetState(() {});
                                    },
                                  ),
                                ),
                            ],
                          ),
                        if (!functions.isSetDoneOffline(
                                FFAppState().loggedSets.toList(),
                                widget.exerciseId!,
                                widget.setNumber!) &&
                            widget.timed)
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 5.0, 0.0),
                            child: wrapWithModel(
                              model: _model.timeModel,
                              updateCallback: () => safeSetState(() {}),
                              child: TimeWidget(
                                exerciseId: widget.exerciseId!,
                                setNumber: widget.setNumber,
                                exerciseName: widget.exerciseName,
                                timerMode: () async {},
                                updatedDuration: (ms) async {
                                  _model.durationMs = ms;
                                  safeSetState(() {});
                                  _model.time =
                                      await actions.updateFlatSetValue(
                                    FFAppState().loggedSets.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!,
                                    functions.getRepsWithFallback(
                                        int.tryParse(_model
                                            .repsFieldTextController.text),
                                        FFAppState().loggedSets.toList(),
                                        widget.exerciseId!,
                                        widget.setNumber!,
                                        FFAppState().exercisesets.toList()),
                                    functions.getFieldWithFallback(
                                        double.tryParse(_model
                                            .weightFieldTextController.text),
                                        FFAppState().loggedSets.toList(),
                                        widget.exerciseId!,
                                        widget.setNumber!),
                                    _model.durationMs,
                                    functions.isSetDoneOffline(
                                        FFAppState().loggedSets.toList(),
                                        widget.exerciseId!,
                                        widget.setNumber!),
                                    FFAppState().exercisesets.toList(),
                                  );
                                  FFAppState().loggedSets =
                                      _model.time!.toList().cast<dynamic>();
                                  safeSetState(() {});

                                  safeSetState(() {});
                                },
                                done: () async {
                                  _model.done =
                                      await actions.updateFlatSetValue(
                                    FFAppState().loggedSets.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!,
                                    functions.getRepsWithFallback(
                                        int.tryParse(_model
                                            .repsFieldTextController.text),
                                        FFAppState().loggedSets.toList(),
                                        widget.exerciseId!,
                                        widget.setNumber!,
                                        FFAppState().exercisesets.toList()),
                                    functions.getFieldWithFallback(
                                        double.tryParse(_model
                                            .weightFieldTextController.text),
                                        FFAppState().loggedSets.toList(),
                                        widget.exerciseId!,
                                        widget.setNumber!),
                                    _model.durationMs,
                                    true,
                                    FFAppState().exercisesets.toList(),
                                  );
                                  FFAppState().loggedSets =
                                      _model.done!.toList().cast<dynamic>();
                                  safeSetState(() {});

                                  safeSetState(() {});
                                },
                              ),
                            ),
                          ),
                      ].divide(SizedBox(width: 6.0)),
                    ),
                  ),
                  if (functions.shouldShowDropTable(widget.exerciseId!,
                      widget.setNumber!, FFAppState().dropSets.toList()))
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 8.0),
                      child: wrapWithModel(
                        model: _model.dropSetModel,
                        updateCallback: () => safeSetState(() {}),
                        child: DropSetWidget(
                          exerciseId: widget.exerciseId!,
                          setNumber: widget.setNumber!,
                          allowsBodyweight: widget.allowsBodyweight!,
                        ),
                      ),
                    ),
                  Align(
                    alignment: AlignmentDirectional(0.0, 1.0),
                    child: Stack(
                      alignment: AlignmentDirectional(0.0, 1.0),
                      children: [
                        if (functions.isSetDoneOffline(
                                FFAppState().loggedSets.toList(),
                                widget.exerciseId!,
                                widget.setNumber!) &&
                            _model.expand)
                          InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              _model.doneFals =
                                  await actions.setLoggedSetIsDone(
                                FFAppState().loggedSets.toList(),
                                widget.exerciseId!,
                                widget.setNumber!,
                                false,
                              );
                              _model.expand = false;
                              safeSetState(() {});
                              FFAppState().loggedSets =
                                  _model.doneFals!.toList().cast<dynamic>();
                              safeSetState(() {});

                              safeSetState(() {});
                            },
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 1.0,
                              height: 27.5,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(12.0),
                                  bottomRight: Radius.circular(12.0),
                                ),
                                border: Border.all(
                                  color: FlutterFlowTheme.of(context).alternate,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.remove_done_sharp,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    size: 24.0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (!functions.isSetDoneOffline(
                            FFAppState().loggedSets.toList(),
                            widget.exerciseId!,
                            widget.setNumber!))
                          Builder(
                            builder: (context) => InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                if (functions.canCompleteSetFromState(
                                    FFAppState().loggedSets.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!,
                                    _model.durationMs,
                                    FFAppState().dropSets.toList(),
                                    FFAppState().exercisesets.toList(),
                                    widget.allowsBodyweight!,
                                    widget.timed)) {
                                  _model.doneTrue =
                                      await actions.updateFlatSetValue(
                                    FFAppState().loggedSets.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!,
                                    functions.getRepsWithFallback(
                                        int.tryParse(_model
                                            .repsFieldTextController.text),
                                        FFAppState().loggedSets.toList(),
                                        widget.exerciseId!,
                                        widget.setNumber!,
                                        FFAppState().exercisesets.toList()),
                                    functions.getFieldWithFallback(
                                        double.tryParse(_model
                                            .weightFieldTextController.text),
                                        FFAppState().loggedSets.toList(),
                                        widget.exerciseId!,
                                        widget.setNumber!),
                                    functions
                                        .resolveDurationSecondsForLoggedSet(
                                            _model.durationMs,
                                            FFAppState().exercisesets.toList(),
                                            widget.exerciseId!,
                                            widget.setNumber!),
                                    true,
                                    FFAppState().exercisesets.toList(),
                                  );
                                  if (FFAppState().notifacations) {
                                    await actions.cancelRestNotification();
                                  }
                                  FFAppState().loggedSets =
                                      _model.doneTrue!.toList().cast<dynamic>();
                                  safeSetState(() {});
                                  HapticFeedback.heavyImpact();
                                  await widget.startTimer?.call();
                                } else {
                                  if (FFAppState().vibration) {
                                    HapticFeedback.vibrate();
                                  }
                                  await showDialog(
                                    context: context,
                                    builder: (dialogContext) {
                                      return Dialog(
                                        elevation: 0,
                                        insetPadding: EdgeInsets.zero,
                                        backgroundColor: Colors.transparent,
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0)
                                                .resolve(
                                                    Directionality.of(context)),
                                        child: SetAlert2Widget(
                                          errorMesseage:
                                              functions.buildSetErrorMessage(
                                                  FFAppState()
                                                      .loggedSets
                                                      .toList(),
                                                  FFAppState()
                                                      .dropSets
                                                      .toList(),
                                                  widget.exerciseId!,
                                                  widget.setNumber!,
                                                  _model.durationMs,
                                                  widget.timed,
                                                  widget.allowsBodyweight!,
                                                  FFAppState()
                                                      .exercisesets
                                                      .toList()),
                                        ),
                                      );
                                    },
                                  );
                                }

                                safeSetState(() {});
                              },
                              child: Container(
                                width: MediaQuery.sizeOf(context).width * 1.0,
                                height: 27.5,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).accent2,
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(12.0),
                                    bottomRight: Radius.circular(12.0),
                                  ),
                                  border: Border.all(
                                    color:
                                        FlutterFlowTheme.of(context).alternate,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_rounded,
                                      color:
                                          FlutterFlowTheme.of(context).success,
                                      size: 24.0,
                                    ),
                                    if (functions.showRestForExercise(
                                        FFAppState().restTimers,
                                        widget.exerciseId!))
                                      Text(
                                        '+ ${functions.formatExerciseRestTime(FFAppState().restTimers, widget.exerciseId!)}',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.inter(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .success,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                  ].divide(SizedBox(width: 8.0)),
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
