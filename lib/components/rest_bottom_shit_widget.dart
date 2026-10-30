import '/components/analyze2_app_widget.dart';
import '/components/cancel_rest_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_timer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'rest_bottom_shit_model.dart';
export 'rest_bottom_shit_model.dart';

/// Create a component Create a modern, minimalistic bottom sheet timer
/// component for a fitness workout app.
///
/// It should be triggered after marking a set as complete.
///
/// Requirements:
/// - Display the selected rest time in big bold numbers (e.g., "01:30")
/// - A circular countdown animation or progress ring
/// - A large button to pause/resume the timer
/// - A smaller icon button to stop and close the timer
/// - Background should be dark or blurred with soft shadows
/// - Add a subtle haptic feedback or bounce animation when the timer starts
/// or resumes
/// - When timer ends, change color to green and show “Time’s up” with a close
/// button
///
/// Make sure it's clean and compact, optimized for mobile. Text should be
/// centered and buttons intuitive.
class RestBottomShitWidget extends StatefulWidget {
  const RestBottomShitWidget({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
  });

  final int? exerciseId;
  final String? exerciseName;
  final int? setNumber;

  @override
  State<RestBottomShitWidget> createState() => _RestBottomShitWidgetState();
}

class _RestBottomShitWidgetState extends State<RestBottomShitWidget> {
  late RestBottomShitModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RestBottomShitModel());

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.timerController.onStartTimer();
      await actions.scheduleRestNotification(
        functions.getRestSecondsForExercise(
            FFAppState().restTimers, widget.exerciseId!),
        true,
        widget.exerciseName,
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Container(
      width: 393.0,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).uiAlerts,
        boxShadow: [
          BoxShadow(
            blurRadius: 8.0,
            color: Color(0x33000000),
            offset: Offset(
              0.0,
              -2.0,
            ),
            spreadRadius: 0.0,
          )
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  FFLocalizations.of(context).getText(
                    'sejf5l86' /* Rest Timer */,
                  ),
                  style: FlutterFlowTheme.of(context).labelMedium.override(
                        font: GoogleFonts.inter(
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontWeight,
                          fontStyle: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontStyle,
                        ),
                        color: Color(0x99FFFFFF),
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).labelMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelMedium.fontStyle,
                      ),
                ),
              ].divide(SizedBox(height: 8.0)),
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Stack(
                    alignment: AlignmentDirectional(0.0, 0.0),
                    children: [
                      Align(
                        alignment: AlignmentDirectional(0.0, -1.0),
                        child: FlutterFlowTimer(
                          initialTime: functions.getRestDurationForExercise(
                              FFAppState().restTimers, widget.exerciseId!),
                          getDisplayTime: (value) =>
                              StopWatchTimer.getDisplayTime(
                            value,
                            hours: false,
                            milliSecond: false,
                          ),
                          controller: _model.timerController,
                          updateStateInterval: Duration(milliseconds: 1000),
                          onChanged: (value, displayTime, shouldUpdate) {
                            _model.timerMilliseconds = value;
                            _model.timerValue = displayTime;
                            if (shouldUpdate) safeSetState(() {});
                          },
                          onEnded: () async {
                            if (FFAppState().vibration) {
                              HapticFeedback.vibrate();
                            }
                            if (FFAppState().sound) {
                              _model.soundPlayer ??= AudioPlayer();
                              if (_model.soundPlayer!.playing) {
                                await _model.soundPlayer!.stop();
                              }
                              _model.soundPlayer!.setVolume(0.78);
                              _model.soundPlayer!
                                  .setAsset('assets/audios/ui-sound-374228.mp3')
                                  .then((_) => _model.soundPlayer!.play());
                            }
                            Navigator.pop(context);
                          },
                          textAlign: TextAlign.center,
                          style: FlutterFlowTheme.of(context)
                              .displayLarge
                              .override(
                                font: GoogleFonts.interTight(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .displayLarge
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .displayLarge
                                      .fontStyle,
                                ),
                                color: Colors.white,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .displayLarge
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .displayLarge
                                    .fontStyle,
                              ),
                        ),
                      ),
                      if (functions.hasAnalysisToShow(
                          FFAppState().workoutAnalysisState.toList(),
                          widget.exerciseId!,
                          widget.setNumber!))
                        Align(
                          alignment: AlignmentDirectional(1.08, 0.82),
                          child: Builder(
                            builder: (context) => Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  30.0, 0.0, 0.0, 0.0),
                              child: Container(
                                width: 60.0,
                                height: 60.0,
                                child: custom_widgets.RestAnalysisBadge(
                                  width: 60.0,
                                  height: 60.0,
                                  accentColor:
                                      FlutterFlowTheme.of(context).primary,
                                  analysisList:
                                      FFAppState().workoutAnalysisState,
                                  exerciseId: widget.exerciseId,
                                  setNumber: widget.setNumber,
                                  onTap: (exerciseId, setNumber) async {
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
                                            videoReady: (url) async {},
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FlutterFlowIconButton(
                      borderColor: Colors.transparent,
                      borderRadius: 22.0,
                      borderWidth: 1.0,
                      buttonSize: 44.0,
                      fillColor: Color(0x33FFFFFF),
                      icon: Icon(
                        Icons.restart_alt,
                        color: Colors.white,
                        size: 24.0,
                      ),
                      onPressed: () async {
                        _model.timerController.onResetTimer();

                        _model.timerController.onStartTimer();
                      },
                    ),
                    Stack(
                      children: [
                        if (_model.timerOn)
                          FFButtonWidget(
                            onPressed: () async {
                              _model.timerOn = false;
                              safeSetState(() {});
                              _model.timerController.onStopTimer();
                              await actions.cancelRestNotification();
                            },
                            text: FFLocalizations.of(context).getText(
                              '63zlom13' /* Pause */,
                            ),
                            options: FFButtonOptions(
                              width: 140.0,
                              height: 50.0,
                              padding: EdgeInsets.all(8.0),
                              iconPadding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 0.0),
                              color: FlutterFlowTheme.of(context).primary,
                              textStyle: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                    ),
                                    color: Colors.white,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                              elevation: 0.0,
                              borderSide: BorderSide(
                                color: Colors.transparent,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                            showLoadingIndicator: false,
                          ),
                        if (!_model.timerOn)
                          FFButtonWidget(
                            onPressed: () async {
                              _model.timerOn = true;
                              safeSetState(() {});
                              _model.timerController.onStartTimer();
                              await actions.scheduleRestNotification(
                                functions.msToSeconds(_model.timerMilliseconds),
                                true,
                                '',
                              );
                            },
                            text: FFLocalizations.of(context).getText(
                              'r3nsru9k' /* Continue */,
                            ),
                            options: FFButtonOptions(
                              width: 140.0,
                              height: 50.0,
                              padding: EdgeInsets.all(8.0),
                              iconPadding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 0.0),
                              color: FlutterFlowTheme.of(context).primary,
                              textStyle: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                    ),
                                    color: Colors.white,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                              elevation: 0.0,
                              borderSide: BorderSide(
                                color: Colors.transparent,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                            showLoadingIndicator: false,
                          ),
                      ],
                    ),
                    Builder(
                      builder: (context) => FlutterFlowIconButton(
                        borderColor: Colors.transparent,
                        borderRadius: 22.0,
                        borderWidth: 1.0,
                        buttonSize: 44.0,
                        fillColor: Color(0x33FFFFFF),
                        icon: Icon(
                          Icons.stop_rounded,
                          color: Colors.white,
                          size: 24.0,
                        ),
                        onPressed: () async {
                          await showDialog(
                            context: context,
                            builder: (dialogContext) {
                              return Dialog(
                                elevation: 0,
                                insetPadding: EdgeInsets.zero,
                                backgroundColor: Colors.transparent,
                                alignment: AlignmentDirectional(0.0, 0.0)
                                    .resolve(Directionality.of(context)),
                                child: CancelRestWidget(
                                  cancelTimer: () async {
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ].divide(SizedBox(width: 20.0)),
                ),
              ].divide(SizedBox(height: 16.0)),
            ),
          ].divide(SizedBox(height: 24.0)),
        ),
      ),
    );
  }
}
