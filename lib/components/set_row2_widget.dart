import '/auth/supabase_auth/auth_util.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/components/analysi_alert_widget.dart';
import '/components/analysis_lottie_widget.dart';
import '/components/analyze2_app_widget.dart';
import '/components/camera_analyzer_widget.dart';
import '/components/drop_set_widget.dart';
import '/components/set_alert2_widget.dart';
import '/components/set_optin_bottom_widget.dart';
import '/components/time_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:async';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'set_row2_model.dart';
export 'set_row2_model.dart';

class SetRow2Widget extends StatefulWidget {
  const SetRow2Widget({
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
  final Future Function(int setNumber, int exerciseId)? startTimer;
  final bool? bodyweight;
  final bool? showRestTime;
  final bool? allowsBodyweight;
  final Future Function()? closeIt;
  final Future Function()? showError;

  @override
  State<SetRow2Widget> createState() => _SetRow2WidgetState();
}

class _SetRow2WidgetState extends State<SetRow2Widget> {
  late SetRow2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SetRow2Model());

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
                        Builder(
                          builder: (context) => Container(
                            width: 45.0,
                            height: 35.0,
                            child: custom_widgets.SetNumberButton(
                              width: 45.0,
                              height: 35.0,
                              label: widget.setNumber?.toString(),
                              fontSize: 10.0,
                              fontWeight: 600,
                              textColor:
                                  FlutterFlowTheme.of(context).primaryText,
                              fillColor: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              chevronColor:
                                  FlutterFlowTheme.of(context).secondaryText,
                              showChevron: !functions.isSetDoneOffline(
                                  FFAppState().loggedSets.toList(),
                                  widget.exerciseId!,
                                  widget.setNumber!),
                              borderColor:
                                  FlutterFlowTheme.of(context).alternate,
                              borderWidth: 1.5,
                              borderRadius: 14.0,
                              enableHaptic: FFAppState().vibration,
                              onTap: () async {
                                await showModalBottomSheet(
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  enableDrag: false,
                                  context: context,
                                  builder: (context) {
                                    return Padding(
                                      padding: MediaQuery.viewInsetsOf(context),
                                      child: SetOptinBottomWidget(
                                        exerciseId: widget.exerciseId!,
                                        setNumber: widget.setNumber!,
                                        isDropSet: _model.dropSet,
                                        isTimed:
                                            !(widget.timed ? false : true),
                                        removeSet: () async {
                                          var _shouldSetState = false;
                                          _model.removeCopy = await actions
                                              .removeSetFromExercise(
                                            FFAppState().exercisesets.toList(),
                                            widget.exerciseId!,
                                            widget.setNumber!,
                                          );
                                          _shouldSetState = true;
                                          FFAppState().exercisesets = _model
                                              .removeCopy!
                                              .toList()
                                              .cast<dynamic>();
                                          safeSetState(() {});
                                          if (_model.dropSet) {
                                            _model.dropllogedCopy = await actions
                                                .removeDropsetsFromLoggedSets(
                                              FFAppState().loggedSets.toList(),
                                              widget.exerciseId!,
                                            );
                                            _shouldSetState = true;
                                            _model.dropdrop3Copy = await actions
                                                .removeDropSetsForExercise(
                                              FFAppState().dropSets.toList(),
                                              widget.exerciseId!,
                                            );
                                            _shouldSetState = true;
                                          } else {
                                            return;
                                          }

                                          FFAppState().dropSets = _model
                                              .dropdrop3Copy!
                                              .toList()
                                              .cast<dynamic>();
                                          FFAppState().loggedSets = _model
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
                                            FFAppState().dropSets.toList(),
                                            widget.exerciseId!,
                                          );
                                          _model.remove2Copy = await actions
                                              .removeDropsetsFromLoggedSets(
                                            FFAppState().loggedSets.toList(),
                                            widget.exerciseId!,
                                          );
                                          FFAppState().dropSets = _model
                                              .dropdropCopy!
                                              .toList()
                                              .cast<dynamic>();
                                          FFAppState().loggedSets = _model
                                              .remove2Copy!
                                              .toList()
                                              .cast<dynamic>();
                                          safeSetState(() {});
                                        },
                                        markExercise: () async {
                                          if (functions.canCompleteSetFromState(
                                              FFAppState().loggedSets.toList(),
                                              widget.exerciseId!,
                                              widget.setNumber!,
                                              _model.durationMs,
                                              FFAppState().dropSets.toList(),
                                              FFAppState()
                                                  .exercisesets
                                                  .toList(),
                                              widget.allowsBodyweight!,
                                              widget.timed)) {
                                            _model.doneTrueCopyCopy =
                                                await actions
                                                    .updateFlatSetValue(
                                              FFAppState().loggedSets.toList(),
                                              widget.exerciseId!,
                                              widget.setNumber!,
                                              functions.getRepsFromLoggedSetsV2(
                                                  FFAppState()
                                                      .loggedSets
                                                      .toList(),
                                                  widget.exerciseId!,
                                                  widget.setNumber!,
                                                  FFAppState()
                                                      .exercisesets
                                                      .toList()),
                                              functions.getWeightFromLoggedSets(
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
                                            await widget.startTimer?.call(
                                              widget.setNumber!,
                                              widget.exerciseId!,
                                            );
                                            FFAppState().loggedSets = _model
                                                .doneTrueCopyCopy!
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
                                                                .loggedSets
                                                                .toList(),
                                                            FFAppState()
                                                                .dropSets
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
                                        reset: () async {
                                          safeSetState(() {
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
                                          _model.droplloged2Copy = await actions
                                              .removeDropsetsFromLoggedSets(
                                            FFAppState().loggedSets.toList(),
                                            widget.exerciseId!,
                                          );
                                          _model.dropdrop4Copy = await actions
                                              .removeDropSetsForExercise(
                                            FFAppState().dropSets.toList(),
                                            widget.exerciseId!,
                                          );
                                          FFAppState().loggedSets = _model
                                              .droplloged2Copy!
                                              .toList()
                                              .cast<dynamic>();
                                          FFAppState().dropSets = _model
                                              .dropdrop4Copy!
                                              .toList()
                                              .cast<dynamic>();
                                          FFAppState().update(() {});
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
                              height: 40.0,
                              child: custom_widgets.PreviousSetButton(
                                width: 80.0,
                                height: 40.0,
                                text: valueOrDefault<String>(
                                  functions.correctedFormatPreviousSet(
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
                                  '-',
                                ),
                                textColor:
                                    FlutterFlowTheme.of(context).secondaryText,
                                fontSize: 14.0,
                                exerciseId: widget.exerciseId,
                                setNumber: widget.setNumber,
                                loggedSets: FFAppState().loggedSets,
                                fontWeight: 400,
                                onTap: () async {
                                  _model.update =
                                      await actions.updateFlatSetValue(
                                    FFAppState().loggedSets.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!,
                                    previousSetButtonCorrectedPreviosSetRowList
                                        .firstOrNull?.reps,
                                    previousSetButtonCorrectedPreviosSetRowList
                                        .firstOrNull?.weight,
                                    previousSetButtonCorrectedPreviosSetRowList
                                        .firstOrNull?.durationeconds,
                                    false,
                                    FFAppState().exercisesets.toList(),
                                  );
                                  FFAppState().loggedSets =
                                      _model.update!.toList().cast<dynamic>();
                                  safeSetState(() {});

                                  safeSetState(() {});
                                },
                              ),
                            );
                          },
                        ),
                        if (!widget.timed)
                          Expanded(
                            child: Container(
                              width: 80.0,
                              height: 50.0,
                              child: custom_widgets.RepsField(
                                width: 80.0,
                                height: 50.0,
                                exerciseId: widget.exerciseId,
                                setNumber: widget.setNumber,
                                value: functions.getInitialSetValue(
                                    FFAppState().loggedSets.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!,
                                    'reps'),
                                fontSize: 14.0,
                                fontWeight: 700,
                                textColor:
                                    FlutterFlowTheme.of(context).primaryText,
                                hintColor:
                                    FlutterFlowTheme.of(context).secondaryText,
                                isDark: Theme.of(context).brightness ==
                                    Brightness.dark,
                                hintText: functions
                                    .getHintFromPreviousSetV2(
                                        FFAppState().loggedSets.toList(),
                                        FFAppState().exercisesets.toList(),
                                        widget.exerciseId!,
                                        widget.setNumber!,
                                        'reps')
                                    .toString(),
                                loggedSets: FFAppState().loggedSets,
                                onValueCommitted: (value) async {
                                  _model.repsUpdateCopy =
                                      await actions.updateFlatSetValue(
                                    FFAppState().loggedSets.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!,
                                    functions.getRepsWithFallback(
                                        value,
                                        FFAppState().loggedSets.toList(),
                                        widget.exerciseId!,
                                        widget.setNumber!,
                                        FFAppState().exercisesets.toList()),
                                    functions.getWeightFromLoggedSets(
                                        FFAppState().loggedSets.toList(),
                                        widget.exerciseId!,
                                        widget.setNumber!),
                                    _model.durationMs,
                                    false,
                                    FFAppState().exercisesets.toList(),
                                  );
                                  FFAppState().loggedSets = _model
                                      .repsUpdateCopy!
                                      .toList()
                                      .cast<dynamic>();
                                  _model.updatePage(() {});

                                  safeSetState(() {});
                                },
                              ),
                            ),
                          ),
                        if (!widget.timed)
                          Expanded(
                            child: Container(
                              width: 80.0,
                              height: 50.0,
                              child: custom_widgets.WeightField(
                                width: 80.0,
                                height: 50.0,
                                isKg: FFAppState().isKg,
                                fontSize: 14.0,
                                isDark: Theme.of(context).brightness ==
                                    Brightness.dark,
                                hintText: functions
                                    .getHintFromPreviousSetV2(
                                        FFAppState().loggedSets.toList(),
                                        FFAppState().exercisesets.toList(),
                                        widget.exerciseId!,
                                        widget.setNumber!,
                                        'weight')
                                    .toString(),
                                fontWeight: 700,
                                textColor:
                                    FlutterFlowTheme.of(context).primaryText,
                                hintColor:
                                    FlutterFlowTheme.of(context).secondaryText,
                                showAsPlusButton: functions.showPlusButton(
                                    widget.exerciseId!,
                                    widget.setNumber!,
                                    FFAppState().loggedSets.toList(),
                                    FFAppState().exercisesets.toList(),
                                    widget.timed),
                                plusButtonSize: 35.0,
                                exerciseId: widget.exerciseId,
                                setNumber: widget.setNumber,
                                loggedSets: FFAppState().loggedSets,
                                onValueCommitted: (value) async {
                                  _model.weightUpdateCopy =
                                      await actions.updateFlatSetValue(
                                    FFAppState().loggedSets.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!,
                                    functions.getRepsFromLoggedSetsV2(
                                        FFAppState().loggedSets.toList(),
                                        widget.exerciseId!,
                                        widget.setNumber!,
                                        FFAppState().exercisesets.toList()),
                                    value,
                                    _model.durationMs,
                                    false,
                                    FFAppState().exercisesets.toList(),
                                  );
                                  FFAppState().loggedSets = _model
                                      .weightUpdateCopy!
                                      .toList()
                                      .cast<dynamic>();
                                  _model.updatePage(() {});

                                  safeSetState(() {});
                                },
                              ),
                            ),
                          ),
                        if (widget.ai && (widget.exerciseId != 33))
                          Container(
                            width: 35.0,
                            height: 35.0,
                            decoration: BoxDecoration(),
                            child: Visibility(
                              visible: widget.ai && (widget.exerciseId != 33),
                              child: Stack(
                                alignment: AlignmentDirectional(0.0, 0.0),
                                children: [
                                  if (functions.shouldShowErrorButton(
                                      FFAppState()
                                          .workoutAnalysisState
                                          .toList(),
                                      widget.exerciseId!,
                                      widget.setNumber!))
                                    Builder(
                                      builder: (context) =>
                                          FlutterFlowIconButton(
                                        borderColor:
                                            FlutterFlowTheme.of(context)
                                                .warning,
                                        borderRadius: 40.0,
                                        borderWidth: 2.5,
                                        buttonSize: 35.0,
                                        icon: Icon(
                                          Icons.error_outline,
                                          color: FlutterFlowTheme.of(context)
                                              .warning,
                                          size: 18.0,
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
                                                alignment: AlignmentDirectional(
                                                        0.0, 0.0)
                                                    .resolve(Directionality.of(
                                                        context)),
                                                child: AnalysiAlertWidget(
                                                  video: _model.videoUrl,
                                                  exerciseId:
                                                      widget.exerciseId!,
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
                                                    _model.result = await actions
                                                        .analyzeExerciseVideoAction(
                                                      _model.videoUrl!,
                                                      widget.exerciseName!,
                                                      10.0,
                                                    );
                                                    if (functions
                                                        .isAnalysisValid(
                                                            _model.result!)) {
                                                      _model.result2 = await actions
                                                          .updateSetAnalysisResult(
                                                        FFAppState()
                                                            .workoutAnalysisState
                                                            .toList(),
                                                        widget.exerciseId!,
                                                        widget.setNumber!,
                                                        _model.result!,
                                                      );
                                                      unawaited(
                                                        () async {
                                                          await actions
                                                              .sendAnalysisFinishedNotification(
                                                            widget
                                                                .exerciseName,
                                                            false,
                                                          );
                                                        }(),
                                                      );
                                                      FFAppState()
                                                              .workoutAnalysisState =
                                                          _model.result2!
                                                              .toList()
                                                              .cast<dynamic>();
                                                      FFAppState()
                                                              .analysisCount =
                                                          FFAppState()
                                                                  .analysisCount +
                                                              1;
                                                      safeSetState(() {});
                                                      if (FFAppState().sound) {
                                                        _model.soundPlayer1 ??=
                                                            AudioPlayer();
                                                        if (_model.soundPlayer1!
                                                            .playing) {
                                                          await _model
                                                              .soundPlayer1!
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
                                                        builder:
                                                            (dialogContext) {
                                                          return Dialog(
                                                            elevation: 0,
                                                            insetPadding:
                                                                EdgeInsets.zero,
                                                            backgroundColor:
                                                                Colors
                                                                    .transparent,
                                                            alignment: AlignmentDirectional(
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
                                                              videoReady:
                                                                  (url) async {},
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    } else {
                                                      _model.error2 = await actions
                                                          .updateSetAnalysisError(
                                                        FFAppState()
                                                            .workoutAnalysisState
                                                            .toList(),
                                                        widget.exerciseId!,
                                                        widget.setNumber!,
                                                      );
                                                      FFAppState()
                                                              .workoutAnalysisState =
                                                          _model.error2!
                                                              .toList()
                                                              .cast<dynamic>();
                                                      safeSetState(() {});
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
                                  if (functions.shouldShowLockButton(
                                      FFAppState()
                                          .workoutAnalysisState
                                          .toList(),
                                      widget.exerciseId!,
                                      widget.setNumber!,
                                      FFAppState().isPremium,
                                      FFAppState().analysisCount))
                                    FlutterFlowIconButton(
                                      borderColor:
                                          FlutterFlowTheme.of(context).primary,
                                      borderRadius: 40.0,
                                      borderWidth: 2.5,
                                      buttonSize: 35.0,
                                      icon: FaIcon(
                                        FaIconData(const IconData(
                                            /* lock */ 0xf023,
                                            fontFamily: 'FontAwesomeSolid',
                                            fontPackage:
                                                'font_awesome_flutter')),
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        size: 18.0,
                                      ),
                                      onPressed: () async {
                                        context.pushNamed(
                                            PremiumPaywallPageWidget.routeName);
                                      },
                                    ),
                                  if (functions.isSetLoading(
                                      FFAppState()
                                          .workoutAnalysisState
                                          .toList(),
                                      widget.exerciseId!,
                                      widget.setNumber!))
                                    wrapWithModel(
                                      model: _model.analysisLottieModel,
                                      updateCallback: () => safeSetState(() {}),
                                      child: AnalysisLottieWidget(),
                                    ),
                                  if (functions.shouldShowCameraButton(
                                      FFAppState()
                                          .workoutAnalysisState
                                          .toList(),
                                      widget.exerciseId!,
                                      widget.setNumber!,
                                      FFAppState().analysisCount,
                                      FFAppState().isPremium,
                                      FFAppState().loggedSets.toList()))
                                    Builder(
                                      builder: (context) => Container(
                                        width: 35.0,
                                        height: 35.0,
                                        child: custom_widgets.AiFormButton(
                                          width: 35.0,
                                          height: 35.0,
                                          size: 35.0,
                                          iconSize: 18.0,
                                          borderWidth: 2.5,
                                          enabled: true,
                                          animate: false,
                                          onTap: () async {
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
                                                  child: CameraAnalyzerWidget(
                                                    exerciseId:
                                                        widget.exerciseId!,
                                                    exerciseName:
                                                        widget.exerciseName!,
                                                    analyze: (video,
                                                        exerciseName,
                                                        exerciseId) async {
                                                      _model.videoUrl = video;
                                                      safeSetState(() {});
                                                    },
                                                  ),
                                                );
                                              },
                                            );

                                            if (_model.videoUrl != null &&
                                                (_model.videoUrl?.bytes
                                                        ?.isNotEmpty ??
                                                    false)) {
                                              _model.prosesssCopy =
                                                  await actions
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
                                                  _model.prosesssCopy!
                                                      .toList()
                                                      .cast<dynamic>();
                                              safeSetState(() {});
                                              _model.result3Copy = await actions
                                                  .analyzeExerciseVideoAction(
                                                _model.videoUrl!,
                                                widget.exerciseName!,
                                                10.0,
                                              );
                                              if (functions.isAnalysisValid(
                                                  _model.result3Copy!)) {
                                                _model.resCopy = await actions
                                                    .updateSetAnalysisResult(
                                                  FFAppState()
                                                      .workoutAnalysisState
                                                      .toList(),
                                                  widget.exerciseId!,
                                                  widget.setNumber!,
                                                  _model.result3Copy!,
                                                );
                                                await actions.logAnalysisUsage(
                                                  _model.result3Copy!,
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
                                                    _model.resCopy!
                                                        .toList()
                                                        .cast<dynamic>();
                                                FFAppState().analysisCount =
                                                    FFAppState().analysisCount +
                                                        1;
                                                safeSetState(() {});
                                                if (FFAppState().sound) {
                                                  _model.soundPlayer2 ??=
                                                      AudioPlayer();
                                                  if (_model
                                                      .soundPlayer2!.playing) {
                                                    await _model.soundPlayer2!
                                                        .stop();
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
                                                      child: Analyze2AppWidget(
                                                        exercise: widget
                                                            .exerciseName!,
                                                        exerciseId:
                                                            widget.exerciseId!,
                                                        setNumber:
                                                            widget.setNumber!,
                                                        videoReady:
                                                            (url) async {},
                                                      ),
                                                    );
                                                  },
                                                );
                                              } else {
                                                _model.errorCopy = await actions
                                                    .updateSetAnalysisError(
                                                  FFAppState()
                                                      .workoutAnalysisState
                                                      .toList(),
                                                  widget.exerciseId!,
                                                  widget.setNumber!,
                                                );
                                                FFAppState()
                                                        .workoutAnalysisState =
                                                    _model.errorCopy!
                                                        .toList()
                                                        .cast<dynamic>();
                                                safeSetState(() {});
                                              }
                                            }

                                            safeSetState(() {});
                                          },
                                        ),
                                      ),
                                    ),
                                  if (functions.isSetAnalysisDone(
                                      FFAppState()
                                          .workoutAnalysisState
                                          .toList(),
                                      widget.exerciseId!,
                                      widget.setNumber!))
                                    Builder(
                                      builder: (context) => Container(
                                        width: 35.0,
                                        height: 35.0,
                                        child: custom_widgets.AiScoreRing(
                                          width: 35.0,
                                          height: 35.0,
                                          score: functions.getSetAnalysisField(
                                              FFAppState()
                                                  .workoutAnalysisState
                                                  .toList(),
                                              widget.exerciseId!,
                                              widget.setNumber!,
                                              'technique_score'),
                                          size: 35.0,
                                          isDark:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark,
                                          onTap: () async {
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
                                                  child: Analyze2AppWidget(
                                                    exercise:
                                                        widget.exerciseName!,
                                                    exerciseId:
                                                        widget.exerciseId!,
                                                    setNumber:
                                                        widget.setNumber!,
                                                    videoUrl: _model.videoUrl,
                                                    videoReady: (url) async {
                                                      _model.vidCopy = await actions
                                                          .updateSetAnalyzedVideo(
                                                        FFAppState()
                                                            .workoutAnalysisState
                                                            .toList(),
                                                        widget.exerciseId!,
                                                        widget.setNumber!,
                                                        'gggh',
                                                      );
                                                      FFAppState()
                                                              .workoutAnalysisState =
                                                          _model.vidCopy!
                                                              .toList()
                                                              .cast<dynamic>();
                                                      safeSetState(() {});
                                                    },
                                                  ),
                                                );
                                              },
                                            );

                                            safeSetState(() {});
                                          },
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
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
                                    functions.getRepsFromLoggedSetsV2(
                                        FFAppState().loggedSets.toList(),
                                        widget.exerciseId!,
                                        widget.setNumber!,
                                        FFAppState().exercisesets.toList()),
                                    functions.getWeightFromLoggedSets(
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
                                    functions.getRepsFromLoggedSetsV2(
                                        FFAppState().loggedSets.toList(),
                                        widget.exerciseId!,
                                        widget.setNumber!,
                                        FFAppState().exercisesets.toList()),
                                    functions.getWeightFromLoggedSets(
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
                              FFAppState().update(() {});

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
                                    functions.getRepsFromLoggedSetsV2(
                                        FFAppState().loggedSets.toList(),
                                        widget.exerciseId!,
                                        widget.setNumber!,
                                        FFAppState().exercisesets.toList()),
                                    functions.getWeightFromLoggedSets(
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
                                  FFAppState().loggedSets =
                                      _model.doneTrue!.toList().cast<dynamic>();
                                  FFAppState().update(() {});
                                  if (FFAppState().notifacations) {
                                    await actions.cancelRestNotification();
                                  }
                                  HapticFeedback.heavyImpact();
                                  await widget.startTimer?.call(
                                    widget.setNumber!,
                                    widget.exerciseId!,
                                  );
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
