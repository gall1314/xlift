import '/components/analyze2_app_widget.dart';
import '/components/camera_analyzer_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:async';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'analysi_alert_model.dart';
export 'analysi_alert_model.dart';

/// Create a component,Design a minimal bottom alert component for a fitness
/// app.
///
/// Component name: SimpleAlertCard
///
/// Purpose: Show a short message with a clear Close button. Visuals only—no
/// logic.
///
/// Placement & size
///
/// Appears near the bottom, centered horizontally.
///
/// Max width: 88% of screen (cap at ~360px), min width ~220px.
///
/// Bottom margin above safe area: 16px.
///
/// Container
///
/// Background: black, translucent rgba(0,0,0,0.78).
///
/// Corner radius: 16px.
///
/// Padding: 16px (top/left/right), 12px bottom (button has its own height).
///
/// Subtle soft shadow/elevation.
///
/// Layout (vertical)
///
/// Message text on top
///
/// Color: white #FFFFFF
///
/// Size: 15–16 pt, medium/semibold, line-height ~120%
///
/// Up to 2 lines; ellipsis if longer
///
/// Close button below the text
///
/// Height 40px, full width inside the card
///
/// Corner radius 10–12px
///
/// Label: “Close” (title case)
///
/// Style: Solid accent (teal #10B6A6) with white text
///
/// Pressed state: darken teal by ~8%
///
/// Optional secondary style (variant): Ghost – white text with 1px white @
/// 24% border, transparent fill
///
/// Spacing
///
/// Gap between text and button: 10–12px.
///
/// Internal content centered; use Auto Layout.
///
/// Accessibility
///
/// Text contrast ≥ 4.5:1 on the translucent surface.
///
/// Button touch target ≥ 44px high including padding.
///
/// Motion (visual spec only)
///
/// Enter: fade-in + slide-up 10–12px (180ms)
///
/// Exit: fade-out + slide-down 8px (150ms)
///
/// Variants
///
/// solid (teal button) and ghost (outlined white button)
///
/// Light/Dark modes use the same black translucent container.
///
/// Sample copy
///
/// “Cannot complete — add reps.”
///
/// “Select a duration for this set.”
///
/// “Add reps to Drop 1.”
///
/// Export
///
/// One reusable component with Auto Layout constraints, both button variants,
/// and hover/pressed button states.
class AnalysiAlertWidget extends StatefulWidget {
  const AnalysiAlertWidget({
    super.key,
    this.video,
    required this.retry,
    required this.exerciseId,
    required this.setNumber,
    required this.exerciseName,
  });

  final FFUploadedFile? video;
  final Future Function()? retry;
  final int? exerciseId;
  final int? setNumber;
  final String? exerciseName;

  @override
  State<AnalysiAlertWidget> createState() => _AnalysiAlertWidgetState();
}

class _AnalysiAlertWidgetState extends State<AnalysiAlertWidget> {
  late AnalysiAlertModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AnalysiAlertModel());
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
      width: MediaQuery.sizeOf(context).width * 0.88,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).uiAlerts,
        boxShadow: [
          BoxShadow(
            blurRadius: 12.0,
            color: Color(0x33000000),
            offset: Offset(
              0.0,
              4.0,
            ),
            spreadRadius: 0.0,
          )
        ],
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
              child: Text(
                valueOrDefault<String>(
                  functions.getAnalysisErrorMessage(
                      FFAppState().workoutAnalysisState.toList(),
                      widget.exerciseId!,
                      widget.setNumber!,
                      widget.exerciseName!),
                  '-',
                ),
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      fontSize: 15.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: FFButtonWidget(
                    onPressed: () async {
                      Navigator.pop(context);
                      await widget.retry?.call();
                    },
                    text: FFLocalizations.of(context).getText(
                      '2aibzhq7' /* Retry */,
                    ),
                    options: FFButtonOptions(
                      width: MediaQuery.sizeOf(context).width * 0.3,
                      height: 35.0,
                      padding: EdgeInsets.all(8.0),
                      iconPadding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      color: FlutterFlowTheme.of(context).primary,
                      textStyle:
                          FlutterFlowTheme.of(context).titleSmall.override(
                                font: GoogleFonts.interTight(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
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
                        color: Colors.transparent,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                Expanded(
                  child: Builder(
                    builder: (context) => FFButtonWidget(
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
                              child: CameraAnalyzerWidget(
                                exerciseId: widget.exerciseId!,
                                exerciseName: widget.exerciseName!,
                                analyze: (video) async {
                                  _model.videoUrl = video;
                                  safeSetState(() {});
                                },
                              ),
                            );
                          },
                        );

                        if (_model.videoUrl != null &&
                            (_model.videoUrl?.bytes?.isNotEmpty ?? false)) {
                          _model.prosesss =
                              await actions.setExerciseLoadingState(
                            FFAppState().workoutAnalysisState.toList(),
                            widget.exerciseId!,
                            widget.setNumber!,
                            true,
                          );
                          FFAppState().workoutAnalysisState =
                              _model.prosesss!.toList().cast<dynamic>();
                          safeSetState(() {});
                          _model.result =
                              await actions.analyzeExerciseVideoAction(
                            _model.videoUrl!,
                            widget.exerciseName!,
                            10.0,
                          );
                          if (functions.isAnalysisValid(_model.result!)) {
                            _model.res = await actions.updateSetAnalysisResult(
                              FFAppState().workoutAnalysisState.toList(),
                              widget.exerciseId!,
                              widget.setNumber!,
                              _model.result!,
                            );
                            unawaited(
                              () async {
                                await actions.sendAnalysisFinishedNotification(
                                  widget.exerciseName,
                                  false,
                                );
                              }(),
                            );
                            FFAppState().workoutAnalysisState =
                                _model.res!.toList().cast<dynamic>();
                            FFAppState().analysisCount =
                                FFAppState().analysisCount + 1;
                            safeSetState(() {});
                            if (FFAppState().sound) {
                              _model.soundPlayer ??= AudioPlayer();
                              if (_model.soundPlayer!.playing) {
                                await _model.soundPlayer!.stop();
                              }
                              _model.soundPlayer!.setVolume(0.72);
                              _model.soundPlayer!
                                  .setAsset(
                                      'assets/audios/sample_pop_notification02_kofi_by_miraclei-360096.mp3')
                                  .then((_) => _model.soundPlayer!.play());
                            }
                            await showDialog(
                              context: context,
                              builder: (dialogContext) {
                                return Dialog(
                                  elevation: 0,
                                  insetPadding: EdgeInsets.zero,
                                  backgroundColor: Colors.transparent,
                                  alignment: AlignmentDirectional(0.0, 0.0)
                                      .resolve(Directionality.of(context)),
                                  child: Analyze2AppWidget(
                                    exercise: widget.exerciseName!,
                                    exerciseId: widget.exerciseId!,
                                    setNumber: widget.setNumber!,
                                    videoReady: (url) async {},
                                  ),
                                );
                              },
                            );
                          } else {
                            _model.error = await actions.updateSetAnalysisError(
                              FFAppState().workoutAnalysisState.toList(),
                              widget.exerciseId!,
                              widget.setNumber!,
                            );
                            FFAppState().workoutAnalysisState =
                                _model.error!.toList().cast<dynamic>();
                            safeSetState(() {});
                          }
                        }

                        safeSetState(() {});
                      },
                      text: FFLocalizations.of(context).getText(
                        'wqdff70u' /* Retake video */,
                      ),
                      options: FFButtonOptions(
                        width: MediaQuery.sizeOf(context).width * 0.3,
                        height: 35.0,
                        padding: EdgeInsets.all(8.0),
                        iconPadding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: FlutterFlowTheme.of(context).alternate,
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
                              color: FlutterFlowTheme.of(context).secondaryText,
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
                          color: Colors.transparent,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
              ].divide(SizedBox(width: 16.0)),
            ),
          ],
        ),
      ),
    );
  }
}
