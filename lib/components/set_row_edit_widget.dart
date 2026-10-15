import '/backend/sqlite/sqlite_manager.dart';
import '/components/drop_set_creation_widget.dart';
import '/components/set_alert2_widget.dart';
import '/components/set_optin_bottom_edit_widget.dart';
import '/components/time_for_creation_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'set_row_edit_model.dart';
export 'set_row_edit_model.dart';

class SetRowEditWidget extends StatefulWidget {
  const SetRowEditWidget({
    super.key,
    this.setNumber,
    bool? timed,
    required this.exerciseId,
    required this.bodyweight,
    this.reps,
    this.weight,
    this.duration,
    required this.allowsBodyweight,
    this.exerciseName,
  }) : this.timed = timed ?? false;

  final int? setNumber;
  final bool timed;
  final int? exerciseId;
  final bool? bodyweight;
  final int? reps;
  final double? weight;
  final int? duration;
  final bool? allowsBodyweight;
  final String? exerciseName;

  @override
  State<SetRowEditWidget> createState() => _SetRowEditWidgetState();
}

class _SetRowEditWidgetState extends State<SetRowEditWidget> {
  late SetRowEditModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SetRowEditModel());

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
      child: InkWell(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () async {
          if (functions.isSetDoneOffline(
              FFAppState().loggedSetsCreation.toList(),
              widget.exerciseId!,
              widget.setNumber!)) {
            _model.expand = !_model.expand;
            safeSetState(() {});
          } else {
            return;
          }
        },
        child: Container(
          width: 320.0,
          decoration: BoxDecoration(
            color: functions.isSetDoneOffline(
                    FFAppState().loggedSetsCreation.toList(),
                    widget.exerciseId!,
                    widget.setNumber!)
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
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) => Container(
                            width: 40.0,
                            height: 35.0,
                            child: custom_widgets.SetNumberButton(
                              width: 40.0,
                              height: 35.0,
                              label: widget.setNumber?.toString(),
                              fillColor: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
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
                                      child: SetOptinBottomEditWidget(
                                        exerciseId: widget.exerciseId!,
                                        setNumber: widget.setNumber!,
                                        isDropSet: _model.dropSet,
                                        isTimed: widget.timed,
                                        removeSet: () async {
                                          var _shouldSetState = false;
                                          _model.removeCopy = await actions
                                              .removeSetFromExercise(
                                            FFAppState()
                                                .exerciseSetsCretion
                                                .toList(),
                                            widget.exerciseId!,
                                            widget.setNumber!,
                                          );
                                          _shouldSetState = true;
                                          FFAppState().exerciseSetsCretion =
                                              _model.removeCopy!
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
                                          FFAppState().loggedSetsCreation =
                                              _model.dropllogedCopy!
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
                                            FFAppState()
                                                .dropSetsCreation
                                                .toList(),
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
                                          FFAppState().loggedSetsCreation =
                                              _model.remove2Copy!
                                                  .toList()
                                                  .cast<dynamic>();
                                          safeSetState(() {});
                                        },
                                        reset: () async {
                                          safeSetState(() {});
                                        },
                                        markSet: () async {
                                          if (functions.canCompleteSetFromState(
                                              FFAppState()
                                                  .loggedSetsCreation
                                                  .toList(),
                                              widget.exerciseId!,
                                              widget.setNumber!,
                                              _model.durationMs,
                                              FFAppState()
                                                  .dropSetsCreation
                                                  .toList(),
                                              FFAppState()
                                                  .exerciseSetsCretion
                                                  .toList(),
                                              widget.allowsBodyweight!,
                                              widget.timed)) {
                                            _model.doneTrueCopyCopy =
                                                await actions
                                                    .updateFlatSetValue(
                                              FFAppState()
                                                  .loggedSetsCreation
                                                  .toList(),
                                              widget.exerciseId!,
                                              widget.setNumber!,
                                              functions.getRepsFromLoggedSetsV2(
                                                  FFAppState()
                                                      .loggedSetsCreation
                                                      .toList(),
                                                  widget.exerciseId!,
                                                  widget.setNumber!,
                                                  FFAppState()
                                                      .exerciseSetsCretion
                                                      .toList()),
                                              functions.getWeightFromLoggedSets(
                                                  FFAppState()
                                                      .loggedSets
                                                      .toList(),
                                                  widget.exerciseId!,
                                                  widget.setNumber!),
                                              functions.resolveSetDurationMs(
                                                  _model.durationMs,
                                                  FFAppState()
                                                      .exerciseSetsCretion
                                                      .toList(),
                                                  widget.exerciseId!,
                                                  widget.setNumber!,
                                                  FFAppState()
                                                      .loggedSetsCreation
                                                      .toList()),
                                              true,
                                              FFAppState()
                                                  .exerciseSetsCretion
                                                  .toList(),
                                            );
                                            HapticFeedback.heavyImpact();
                                            FFAppState().loggedSetsCreation =
                                                _model.doneTrueCopyCopy!
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
                                                  insetPadding: EdgeInsets.zero,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  alignment:
                                                      AlignmentDirectional(
                                                              0.0, 0.0)
                                                          .resolve(
                                                              Directionality.of(
                                                                  context)),
                                                  child: SetAlert2Widget(
                                                    errorMesseage: functions
                                                        .buildSetErrorMessage(
                                                            FFAppState()
                                                                .loggedSetsCreation
                                                                .toList(),
                                                            FFAppState()
                                                                .dropSetsCreation
                                                                .toList(),
                                                            widget.exerciseId!,
                                                            widget.setNumber!,
                                                            _model.durationMs,
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
                                      ),
                                    );
                                  },
                                ).then((value) => safeSetState(() {}));

                                safeSetState(() {});
                              },
                            ),
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
                              },
                            ),
                          ),
                        FutureBuilder<List<PreviosSetRow>>(
                          future: SQLiteManager.instance.previosSet(
                            exerciseId: widget.exerciseId!,
                            setNumber: widget.setNumber!,
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
                            final previousSetButtonPreviosSetRowList =
                                snapshot.data!;

                            return Container(
                              width: 80.0,
                              height: 45.0,
                              child: custom_widgets.PreviousSetButton(
                                width: 80.0,
                                height: 45.0,
                                text: functions.formatPreviousSet(
                                    previousSetButtonPreviosSetRowList
                                        .firstOrNull?.reps,
                                    previousSetButtonPreviosSetRowList
                                        .firstOrNull?.weight,
                                    previousSetButtonPreviosSetRowList
                                        .firstOrNull?.durationSeconds,
                                    previousSetButtonPreviosSetRowList
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
                                  _model.repsUpdateCopyCopy =
                                      await actions.updateFlatSetValue(
                                    FFAppState().loggedSetsCreation.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!,
                                    previousSetButtonPreviosSetRowList
                                        .firstOrNull?.reps,
                                    widget.weight,
                                    _model.durationMs,
                                    functions.isSetDone(
                                        widget.exerciseId!,
                                        widget.setNumber!,
                                        FFAppState()
                                            .loggedSetsCreation
                                            .toList()),
                                    FFAppState().exercisesets.toList(),
                                  );
                                  FFAppState().loggedSetsCreation = _model
                                      .repsUpdateCopyCopy!
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
                          height: 50.0,
                          child: custom_widgets.RepsField(
                            width: 80.0,
                            height: 50.0,
                            exerciseId: widget.exerciseId,
                            setNumber: widget.setNumber,
                            value: functions.getRepsForSetFromLoggedSets(
                                FFAppState().loggedSetsCreation.toList(),
                                widget.exerciseId!,
                                widget.setNumber!),
                            fontSize: 14.0,
                            fontWeight: 700,
                            textColor: FlutterFlowTheme.of(context).primaryText,
                            hintColor:
                                FlutterFlowTheme.of(context).secondaryText,
                            isDark:
                                Theme.of(context).brightness == Brightness.dark,
                            hintText: valueOrDefault<String>(
                              functions
                                  .getHintFromPreviousSet(
                                      FFAppState().loggedSetsCreation.toList(),
                                      widget.exerciseId!,
                                      widget.setNumber!,
                                      'reps')
                                  .toString(),
                              '0',
                            ),
                            loggedSets: FFAppState().loggedSetsCreation,
                            onValueCommitted: (value) async {
                              _model.repsUpdateCopy =
                                  await actions.updateFlatSetValue(
                                FFAppState().loggedSetsCreation.toList(),
                                widget.exerciseId!,
                                widget.setNumber!,
                                functions.getRepsWithFallback(
                                    value,
                                    FFAppState().loggedSetsCreation.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!,
                                    FFAppState().exerciseSetsCretion.toList()),
                                functions.getWeightFromLoggedSets(
                                    FFAppState().loggedSetsCreation.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!),
                                _model.durationMs,
                                functions.isSetDone(
                                    widget.exerciseId!,
                                    widget.setNumber!,
                                    FFAppState().loggedSetsCreation.toList()),
                                FFAppState().exercisesets.toList(),
                              );
                              FFAppState().loggedSetsCreation = _model
                                  .repsUpdateCopy!
                                  .toList()
                                  .cast<dynamic>();
                              safeSetState(() {});

                              safeSetState(() {});
                            },
                          ),
                        ),
                        Container(
                          width: 80.0,
                          height: 50.0,
                          child: custom_widgets.WeightField(
                            width: 80.0,
                            height: 50.0,
                            exerciseId: widget.exerciseId,
                            setNumber: widget.setNumber,
                            value: functions.getWeightForSetFromLoggedSets(
                                FFAppState().loggedSetsCreation.toList(),
                                widget.exerciseId!,
                                widget.setNumber!),
                            isKg: FFAppState().isKg,
                            fontSize: 14.0,
                            fontWeight: 700,
                            textColor: FlutterFlowTheme.of(context).primaryText,
                            hintColor:
                                FlutterFlowTheme.of(context).secondaryText,
                            isDark:
                                Theme.of(context).brightness == Brightness.dark,
                            hintText: valueOrDefault<String>(
                              functions
                                  .getHintFromPreviousSet(
                                      FFAppState().loggedSetsCreation.toList(),
                                      widget.exerciseId!,
                                      widget.setNumber!,
                                      'weight')
                                  .toString(),
                              '0',
                            ),
                            showAsPlusButton: functions.showPlusButton(
                                widget.exerciseId!,
                                widget.setNumber!,
                                FFAppState().loggedSets.toList(),
                                FFAppState().exerciseSetsCretion.toList(),
                                widget.timed),
                            plusButtonSize: 35.0,
                            loggedSets: FFAppState().loggedSetsCreation,
                            onValueCommitted: (value) async {
                              _model.weightUpdate2 =
                                  await actions.updateFlatSetValue(
                                FFAppState().loggedSetsCreation.toList(),
                                widget.exerciseId!,
                                widget.setNumber!,
                                functions.getRepsFromLoggedSetsV2(
                                    FFAppState().loggedSetsCreation.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!,
                                    FFAppState().exerciseSetsCretion.toList()),
                                functions.getWeightFromLoggedSets(
                                    FFAppState().loggedSetsCreation.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!),
                                _model.durationMs,
                                false,
                                FFAppState().exerciseSetsCretion.toList(),
                              );
                              FFAppState().loggedSetsCreation = _model
                                  .weightUpdate2!
                                  .toList()
                                  .cast<dynamic>();
                              safeSetState(() {});

                              safeSetState(() {});
                            },
                          ),
                        ),
                      ].divide(SizedBox(width: 6.0)),
                    ),
                  ),
                  if (functions.shouldShowDropTable(
                      widget.exerciseId!,
                      widget.setNumber!,
                      FFAppState().dropSetsCreation.toList()))
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 8.0),
                      child: wrapWithModel(
                        model: _model.dropSetCreationModel,
                        updateCallback: () => safeSetState(() {}),
                        child: DropSetCreationWidget(
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
                                FFAppState().loggedSetsCreation.toList(),
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
                                  await actions.updateFlatSetValue(
                                FFAppState().loggedSetsCreation.toList(),
                                widget.exerciseId!,
                                widget.setNumber!,
                                functions.getRepsFromLoggedSetsV2(
                                    FFAppState().loggedSetsCreation.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!,
                                    FFAppState().exerciseSetsCretion.toList()),
                                functions.getWeightFromLoggedSets(
                                    FFAppState().loggedSets.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!),
                                _model.durationMs,
                                false,
                                FFAppState().exerciseSetsCretion.toList(),
                              );
                              _model.expand = false;
                              safeSetState(() {});
                              FFAppState().loggedSetsCreation =
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
                            FFAppState().loggedSetsCreation.toList(),
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
                                    FFAppState().loggedSetsCreation.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!,
                                    _model.durationMs,
                                    FFAppState().dropSetsCreation.toList(),
                                    FFAppState().exerciseSetsCretion.toList(),
                                    widget.allowsBodyweight!,
                                    widget.timed)) {
                                  _model.doneTrue =
                                      await actions.updateFlatSetValue(
                                    FFAppState().loggedSetsCreation.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!,
                                    functions.getRepsFromLoggedSetsV2(
                                        FFAppState()
                                            .loggedSetsCreation
                                            .toList(),
                                        widget.exerciseId!,
                                        widget.setNumber!,
                                        FFAppState()
                                            .exerciseSetsCretion
                                            .toList()),
                                    functions.getWeightFromLoggedSets(
                                        FFAppState().loggedSets.toList(),
                                        widget.exerciseId!,
                                        widget.setNumber!),
                                    functions.resolveSetDurationMs(
                                        _model.durationMs,
                                        FFAppState()
                                            .exerciseSetsCretion
                                            .toList(),
                                        widget.exerciseId!,
                                        widget.setNumber!,
                                        FFAppState()
                                            .loggedSetsCreation
                                            .toList()),
                                    true,
                                    FFAppState().exerciseSetsCretion.toList(),
                                  );
                                  FFAppState().loggedSetsCreation =
                                      _model.doneTrue!.toList().cast<dynamic>();
                                  safeSetState(() {});
                                  HapticFeedback.heavyImpact();
                                } else {
                                  HapticFeedback.vibrate();
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
                                                      .loggedSetsCreation
                                                      .toList(),
                                                  FFAppState()
                                                      .dropSetsCreation
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
