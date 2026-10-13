import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'video2_model.dart';
export 'video2_model.dart';

/// Create a component,
/// Create a Video Popup with a clean, modern, mobile-friendly design.
///
/// The popup should include:
///
/// Header row at the top:
///
/// Left: close button (✕)
///
/// Center: title text “Analyzed Video”
///
/// Main content:
///
/// Large video player (16:9 aspect ratio) with rounded corners and basic
/// controls (play/pause, scrubber, volume).
///
/// The player always shows the analyzed video only (no switching between
/// versions).
///
/// Footer section:
///
/// Single outlined button labeled Download Original Video (tapping downloads
/// the unprocessed video file).
///
/// Style:
///
/// Rounded corners (24), generous padding.
///
/// Keep layout simple and focused on the video.
///
/// Dark background outside the popup for focus.
class Video2Widget extends StatefulWidget {
  const Video2Widget({
    super.key,
    this.video,
    required this.exerciseId,
    required this.setNumber,
  });

  final String? video;
  final int? exerciseId;
  final int? setNumber;

  @override
  State<Video2Widget> createState() => _Video2WidgetState();
}

class _Video2WidgetState extends State<Video2Widget> {
  late Video2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Video2Model());
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
        color: FlutterFlowTheme.of(context).secondaryBackground,
        boxShadow: [
          BoxShadow(
            blurRadius: 24.0,
            color: Color(0x66000000),
            offset: Offset(
              0.0,
              8.0,
            ),
            spreadRadius: 0.0,
          )
        ],
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FlutterFlowIconButton(
                  borderColor: Colors.transparent,
                  borderRadius: 20.0,
                  buttonSize: 40.0,
                  fillColor: Colors.transparent,
                  icon: Icon(
                    Icons.close,
                    color: FlutterFlowTheme.of(context).primaryText,
                    size: 24.0,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                ),
                Expanded(
                  child: Text(
                    FFLocalizations.of(context).getText(
                      '7neaekml' /* Analyzed Video */,
                    ),
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).titleMedium.override(
                          font: GoogleFonts.interTight(
                            fontWeight: FlutterFlowTheme.of(context)
                                .titleMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleMedium
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .titleMedium
                              .fontWeight,
                          fontStyle: FlutterFlowTheme.of(context)
                              .titleMedium
                              .fontStyle,
                        ),
                  ),
                ),
                Container(
                  width: 36.0,
                  height: 36.0,
                  child: custom_widgets.SaveAnalyzedVideoButton(
                    width: 36.0,
                    height: 36.0,
                    accentColor: FlutterFlowTheme.of(context).primary,
                    analysisResult: functions.getSetByExerciseAndNumber(
                        FFAppState().workoutAnalysisState.toList(),
                        widget.exerciseId!,
                        widget.setNumber!),
                    compact: true,
                  ),
                ),
              ],
            ),
            Container(
              width: 270.0,
              height: 488.0,
              child: custom_widgets.AnalyzedVideoPlayerV2(
                width: 270.0,
                height: 488.0,
                showSkeleton: true,
                showBarbellBox: false,
                videoVolume: 0.7,
                lockFeet: false,
                autoplay: true,
                analysisResult: functions.getSetByExerciseAndNumber(
                    FFAppState().workoutAnalysisState.toList(),
                    widget.exerciseId!,
                    widget.setNumber!),
              ),
            ),
            FFButtonWidget(
              onPressed: () async {
                await actions.saveVideoToGallery(
                  functions.getSetVideoPath(
                      FFAppState().workoutAnalysisState.toList(),
                      widget.exerciseId!,
                      widget.setNumber!),
                );
              },
              text: FFLocalizations.of(context).getText(
                'sybuu4wg' /* Download Original Video */,
              ),
              icon: Icon(
                Icons.save_alt,
                size: 15.0,
              ),
              options: FFButtonOptions(
                width: double.infinity,
                height: 48.0,
                padding: EdgeInsets.all(8.0),
                iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                color: Colors.transparent,
                textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                      font: GoogleFonts.interTight(
                        fontWeight:
                            FlutterFlowTheme.of(context).titleSmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleSmall.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).primary,
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).titleSmall.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).titleSmall.fontStyle,
                    ),
                elevation: 0.0,
                borderSide: BorderSide(
                  color: FlutterFlowTheme.of(context).primary,
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ].divide(SizedBox(height: 20.0)),
        ),
      ),
    );
  }
}
