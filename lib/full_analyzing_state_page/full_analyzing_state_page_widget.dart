import '/components/ai_loading_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'full_analyzing_state_page_model.dart';
export 'full_analyzing_state_page_model.dart';

/// Design a full-screen "analyzing" state for Xlift — an iOS fitness app.
///
/// DARK theme for this screen: background
/// #0E1420 (deep navy), accent teal
/// #2DD4BF.
///
/// This screen shows while the AI analyzes a recorded exercise video (20-40
/// seconds). Centered, calm, premium — think Apple-style processing screen,
/// not a casino.
///
/// Layout, all centered vertically and horizontally:
///
/// Loader placeholder — empty Container, 150×150, centered (production
/// injects a custom animated widget here — reserve the space, draw nothing
/// inside)
/// 24px gap
/// Title: "Analyzing your deadlift..." — 20sp, bold, white
/// 8px gap
/// Status line: "Tracking joints and bar path" — 14sp,
/// #8FA3B8 (this text rotates through pipeline stages in production, single
/// line)
/// 32px gap
/// A subtle horizontal progress bar placeholder — Container 220×4, radius 2,
/// fill
/// #1E293B, centered (production injects an animated bar widget)
///
/// Bottom of screen, 24px from bottom edge, centered: small hint text — "This
/// usually takes about 30 seconds" — 12sp,
/// #64748B
///
/// No cancel button, no navigation, no other elements. Keep it minimal: dark,
/// one glowing focal point, quiet text.
class FullAnalyzingStatePageWidget extends StatefulWidget {
  const FullAnalyzingStatePageWidget({
    super.key,
    this.exerciseName,
    required this.videoFile,
    required this.exerciseId,
    required this.isBodyweight,
  });

  final String? exerciseName;
  final FFUploadedFile? videoFile;
  final int? exerciseId;
  final int? isBodyweight;

  static String routeName = 'FullAnalyzingStatePage';
  static String routePath = '/fullAnalyzingStatePage';

  @override
  State<FullAnalyzingStatePageWidget> createState() =>
      _FullAnalyzingStatePageWidgetState();
}

class _FullAnalyzingStatePageWidgetState
    extends State<FullAnalyzingStatePageWidget> {
  late FullAnalyzingStatePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FullAnalyzingStatePageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.result = await actions.analyzeExerciseVideoAction(
        widget.videoFile!,
        widget.exerciseName!,
        12.0,
      );
      if (_model.result != null) {
        context.pushNamed(
          FullResultPageWidget.routeName,
          queryParameters: {
            'analysis': serializeParam(
              _model.result,
              ParamType.JSON,
            ),
            'exerciseName': serializeParam(
              widget.exerciseName,
              ParamType.String,
            ),
            'exerciseId': serializeParam(
              widget.exerciseId,
              ParamType.int,
            ),
            'isBodyweight': serializeParam(
              widget.isBodyweight,
              ParamType.int,
            ),
          }.withoutNulls,
        );
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Color(0xFF0E1420),
        body: Stack(
          alignment: AlignmentDirectional(-1.0, -1.0),
          children: [
            Container(
              alignment: AlignmentDirectional(0.0, 0.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  wrapWithModel(
                    model: _model.aiLoadingModel,
                    updateCallback: () => safeSetState(() {}),
                    child: AiLoadingWidget(),
                  ),
                  Container(
                    height: 24.0,
                  ),
                  Text(
                    'Analyzing your ${widget.exerciseName}...',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: Colors.white,
                          fontSize: 20.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                          lineHeight: 1.4,
                        ),
                  ),
                  Container(
                    height: 8.0,
                  ),
                  Text(
                    FFLocalizations.of(context).getText(
                      'at083w6n' /* Tracking joints and bar path */,
                    ),
                    maxLines: 1,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: Color(0xFF8FA3B8),
                          fontSize: 14.0,
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                          lineHeight: 1.4,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Container(
                    height: 32.0,
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2.0),
                    child: Container(
                      width: 220.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(2.0),
                        shape: BoxShape.rectangle,
                      ),
                      child: Container(
                        width: MediaQuery.sizeOf(context).width * 1.0,
                        height: 10.0,
                        child: custom_widgets.AiLoadingBar(
                          width: MediaQuery.sizeOf(context).width * 1.0,
                          height: 10.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: AlignmentDirectional(0.0, 1.0),
              child: Container(
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
                  child: Container(
                    child: Text(
                      FFLocalizations.of(context).getText(
                        'qwgrvacy' /* This usually takes about 30 se... */,
                      ),
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            color: Color(0xFF64748B),
                            fontSize: 12.0,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                            lineHeight: 1.4,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
