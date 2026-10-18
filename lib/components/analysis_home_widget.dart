import '/components/bottom_sheet_no_free_left_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'analysis_home_model.dart';
export 'analysis_home_model.dart';

class AnalysisHomeWidget extends StatefulWidget {
  const AnalysisHomeWidget({super.key});

  @override
  State<AnalysisHomeWidget> createState() => _AnalysisHomeWidgetState();
}

class _AnalysisHomeWidgetState extends State<AnalysisHomeWidget> {
  late AnalysisHomeModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AnalysisHomeModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () async {
        if (!functions.canStartQuickAnalysis(FFAppState().isPremium,
            FFAppState().analysisCount, FFAppState().analysisCountMonth)) {
          await showModalBottomSheet(
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            enableDrag: false,
            context: context,
            builder: (context) {
              return Padding(
                padding: MediaQuery.viewInsetsOf(context),
                child: BottomSheetNoFreeLeftWidget(),
              );
            },
          ).then((value) => safeSetState(() {}));
        }
      },
      child: Container(
        height: 100.0,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              blurRadius: 12.0,
              color: Color(0x0F000000),
              offset: Offset(
                0.0,
                4.0,
              ),
              spreadRadius: 0.0,
            )
          ],
          gradient: LinearGradient(
            colors: [
              Theme.of(context).brightness == Brightness.light
                  ? FlutterFlowTheme.of(context).secondaryBackground
                  : Color(0xFF1A2E2C),
              Theme.of(context).brightness == Brightness.light
                  ? Color(0xFFEFFBF8)
                  : Color(0xFF0F2321)
            ],
            stops: [0.0, 1.0],
            begin: AlignmentDirectional(0.0, -1.0),
            end: AlignmentDirectional(0, 1.0),
          ),
          borderRadius: BorderRadius.circular(16.0),
          shape: BoxShape.rectangle,
          border: Border.all(
            color: Color(0x4014B8A6),
            width: 1.0,
          ),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(14.0, 0.0, 14.0, 0.0),
          child: Container(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44.0,
                  height: 44.0,
                  decoration: BoxDecoration(
                    color: Color(0xFF14B8A6),
                    borderRadius: BorderRadius.circular(12.0),
                    shape: BoxShape.rectangle,
                  ),
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24.0,
                  ),
                ),
                Container(
                  width: 12.0,
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        FFLocalizations.of(context).getText(
                          'fu74461j' /* Quick Form Check */,
                        ),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).primaryText,
                              fontSize: 16.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                              lineHeight: 1.2,
                            ),
                      ),
                      Container(
                        height: 3.0,
                      ),
                      Text(
                        FFLocalizations.of(context).getText(
                          'ojaod5ts' /* Record a set, get instant AI f... */,
                        ),
                        maxLines: 1,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.normal,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).secondaryText,
                              fontSize: 12.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.normal,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                              lineHeight: 1.4,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Container(
                        height: 4.0,
                      ),
                      if (!FFAppState().isPremium)
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0x1F14B8A6),
                            borderRadius: BorderRadius.circular(8.0),
                            shape: BoxShape.rectangle,
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                8.0, 2.0, 8.0, 2.0),
                            child: Container(
                              child: Text(
                                functions.analysisQuotaLabel(
                                    FFAppState().analysisCount,
                                    FFAppState().analysisCountMonth,
                                    FFAppState().isPremium),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: Color(0xFF0F766E),
                                      fontSize: 10.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                      lineHeight: 1.4,
                                    ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  width: 8.0,
                ),
                Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color(0x4D14B8A6),
                      width: 1.0,
                    ),
                  ),
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Icon(
                    Icons.videocam_outlined,
                    color: Color(0xFF14B8A6),
                    size: 18.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
