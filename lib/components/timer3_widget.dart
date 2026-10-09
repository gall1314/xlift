import '/components/cancel_rest_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_timer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/permissions_util.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'timer3_model.dart';
export 'timer3_model.dart';

/// Create a component,Design a clean, modern white bottom sheet for a
/// time-based exercise in a fitness app.
///
/// The layout already exists and should not change.
/// Focus on improving color hierarchy and visual clarity.
///
/// Guidelines:
/// - White background
/// - Countdown timer is the main focus, using a dark neutral color
/// - Use one primary brand color (green) only for the main action button
/// - Progress bar should use a muted version of the brand color
/// - Secondary control icons (pause / stop) should be neutral gray
/// - Avoid using multiple saturated colors
/// - The design should feel calm, focused, and professional
/// - No dark overlays, no dramatic contrast
///
/// The result should feel like an integrated part of the workout flow, not a
/// modal interruption.
class Timer3Widget extends StatefulWidget {
  const Timer3Widget({
    super.key,
    required this.exerciseName,
    required this.ms,
    required this.done,
  });

  final String? exerciseName;
  final int? ms;
  final Future Function()? done;

  @override
  State<Timer3Widget> createState() => _Timer3WidgetState();
}

class _Timer3WidgetState extends State<Timer3Widget> {
  late Timer3Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Timer3Model());

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.timerController.onStartTimer();
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
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Container(
        width: 395.0,
        height: 268.74,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          boxShadow: [
            BoxShadow(
              blurRadius: 8.0,
              color: Color(0x1A000000),
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
          padding: EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    valueOrDefault<String>(
                      widget.exerciseName,
                      'Exercise Name',
                    ),
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: Color(0xFF57636C),
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                ].divide(SizedBox(height: 8.0)),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FFButtonWidget(
                          onPressed: () async {
                            _model.timerController.timer.setPresetTime(
                              mSec: functions.adjustMsByFiveSeconds(
                                  _model.timerMilliseconds, false),
                              add: false,
                            );
                            _model.timerController.onResetTimer();

                            _model.timerController.onStartTimer();
                            await actions.cancelRestNotification();
                            await actions.scheduleRestNotification(
                              _model.timerMilliseconds,
                              false,
                              widget.exerciseName,
                            );
                          },
                          text: FFLocalizations.of(context).getText(
                            'zols1ih5' /* -5 */,
                          ),
                          options: FFButtonOptions(
                            width: 56.0,
                            height: 56.0,
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 0.0, 16.0, 0.0),
                            iconPadding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 0.0),
                            color: Color(0xFFF1F4F8),
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
                                      .secondaryText,
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
                            ),
                            borderRadius: BorderRadius.circular(100.0),
                          ),
                        ),
                        Expanded(
                          child: FlutterFlowTimer(
                            initialTime: widget.ms!,
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
                              Navigator.pop(context);
                              await widget.done?.call();
                              HapticFeedback.lightImpact();
                              _model.soundPlayer ??= AudioPlayer();
                              if (_model.soundPlayer!.playing) {
                                await _model.soundPlayer!.stop();
                              }
                              _model.soundPlayer!.setVolume(0.84);
                              _model.soundPlayer!
                                  .setAsset('assets/audios/ui-sound-374228.mp3')
                                  .then((_) => _model.soundPlayer!.play());
                            },
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .headlineSmall
                                .override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .fontStyle,
                                  ),
                                  fontSize: 64.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .fontStyle,
                                ),
                          ),
                        ),
                        FFButtonWidget(
                          onPressed: () async {
                            _model.timerController.timer.setPresetTime(
                              mSec: functions.adjustMsByFiveSeconds(
                                  _model.timerMilliseconds, true),
                              add: false,
                            );
                            _model.timerController.onResetTimer();

                            _model.timerController.onStartTimer();
                            await actions.cancelRestNotification();
                            if (FFAppState().notifacations) {
                              await actions.scheduleRestNotification(
                                _model.timerMilliseconds,
                                false,
                                widget.exerciseName,
                              );
                            }
                          },
                          text: FFLocalizations.of(context).getText(
                            '5qwcpps9' /* +5 */,
                          ),
                          options: FFButtonOptions(
                            width: 56.0,
                            height: 56.0,
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 0.0, 16.0, 0.0),
                            iconPadding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 0.0),
                            color: Color(0xFFF1F4F8),
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
                                      .secondaryText,
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
                            ),
                            borderRadius: BorderRadius.circular(100.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ].divide(SizedBox(height: 16.0)),
              ),
              LinearPercentIndicator(
                percent: functions.calculateRestProgress(
                    widget.ms!, _model.timerMilliseconds),
                width: MediaQuery.sizeOf(context).width * 1.0,
                lineHeight: 8.0,
                animation: true,
                animateFromLastPercent: true,
                progressColor: FlutterFlowTheme.of(context).secondary,
                backgroundColor: FlutterFlowTheme.of(context).accent4,
                padding: EdgeInsets.zero,
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FlutterFlowIconButton(
                    borderColor: FlutterFlowTheme.of(context).alternate,
                    borderRadius: 22.0,
                    borderWidth: 1.0,
                    buttonSize: 44.0,
                    fillColor: Color(0xFFF1F4F8),
                    icon: Icon(
                      Icons.restart_alt,
                      color: FlutterFlowTheme.of(context).secondaryText,
                      size: 24.0,
                    ),
                    onPressed: () async {
                      _model.timerController.timer.setPresetTime(
                        mSec: widget.ms!,
                        add: false,
                      );
                      _model.timerController.onResetTimer();

                      _model.timerController.onStartTimer();
                      await actions.cancelRestNotification();
                      await actions.scheduleRestNotification(
                        _model.timerMilliseconds,
                        false,
                        widget.exerciseName,
                      );
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
                            'e9m3cdeb' /* Pause */,
                          ),
                          options: FFButtonOptions(
                            width: 140.0,
                            height: 50.0,
                            padding: EdgeInsets.all(8.0),
                            iconPadding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 0.0),
                            color: FlutterFlowTheme.of(context).secondary,
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
                        ),
                      if (!_model.timerOn)
                        FFButtonWidget(
                          onPressed: () async {
                            _model.timerOn = true;
                            safeSetState(() {});
                            _model.timerController.onStartTimer();
                            if (await getPermissionStatus(
                                notificationsPermission)) {
                              await actions.scheduleRestNotification(
                                _model.timerMilliseconds,
                                false,
                                widget.exerciseName,
                              );
                            }
                          },
                          text: FFLocalizations.of(context).getText(
                            'h6h23c84' /* Continue */,
                          ),
                          options: FFButtonOptions(
                            width: 140.0,
                            height: 50.0,
                            padding: EdgeInsets.all(8.0),
                            iconPadding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 0.0),
                            color: FlutterFlowTheme.of(context).secondary,
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
                        ),
                    ],
                  ),
                  Builder(
                    builder: (context) => FlutterFlowIconButton(
                      borderColor: FlutterFlowTheme.of(context).alternate,
                      borderRadius: 22.0,
                      borderWidth: 1.0,
                      buttonSize: 44.0,
                      fillColor: Color(0xFFF1F4F8),
                      icon: Icon(
                        Icons.stop_rounded,
                        color: FlutterFlowTheme.of(context).secondaryText,
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
            ].divide(SizedBox(height: 20.0)),
          ),
        ),
      ),
    );
  }
}
