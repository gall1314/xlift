import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bottom_sheet_no_free_templates_model.dart';
export 'bottom_sheet_no_free_templates_model.dart';

/// Design a bottom sheet component named OutOfChecksSheet, for Xlift — an iOS
/// fitness app, light theme, accent teal
/// #14B8A6.
///
/// This sheet appears when a free user taps "Quick Form Check" but has used
/// all free AI analyses this month. It's a soft, non-aggressive paywall nudge
/// — clean and calm, not pushy.
///
/// Sheet:
///
/// White background, top corners radius 24, centered drag handle (36×4,
/// #E5E7EB)
/// Height wraps content (~40% of screen)
/// Horizontal padding 24, all content centered
///
/// Content, top to bottom:
///
/// 20px gap after the handle
/// Icon square — 72×72, radius 18, solid
/// #14B8A6, with a white lock icon (lock_rounded) 32px, centered
/// 20px gap
/// Title: "You're out of free checks" — 22sp, bold,
/// #1A202C, centered
/// 8px gap
/// Body text: "Pro includes unlimited AI form analysis, rep-by-rep breakdowns
/// and progress tracking." — 14sp, regular,
/// #6B7280, centered, max 2 lines
/// 24px gap
/// Primary button: full-width, solid
/// #14B8A6, radius 16, height 54, text "Go Pro — unlimited checks" — 16sp,
/// bold, white
/// 12px gap
/// Secondary: plain text button, no fill, no border — "Maybe later" — 15sp,
/// medium,
/// #6B7280, centered
/// 24px bottom padding
///
/// No close X, no extra decorations, no prices on this sheet (pricing lives
/// on the paywall page the primary button opens).
class BottomSheetNoFreeTemplatesWidget extends StatefulWidget {
  const BottomSheetNoFreeTemplatesWidget({super.key});

  @override
  State<BottomSheetNoFreeTemplatesWidget> createState() =>
      _BottomSheetNoFreeTemplatesWidgetState();
}

class _BottomSheetNoFreeTemplatesWidgetState
    extends State<BottomSheetNoFreeTemplatesWidget> {
  late BottomSheetNoFreeTemplatesModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BottomSheetNoFreeTemplatesModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        shape: BoxShape.rectangle,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 24.0),
        child: Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
                child: Container(
                  child: InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 36.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(9999.0),
                        shape: BoxShape.rectangle,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 20.0,
              ),
              Container(
                width: 72.0,
                height: 72.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primary,
                  borderRadius: BorderRadius.circular(18.0),
                  shape: BoxShape.rectangle,
                ),
                alignment: AlignmentDirectional(0.0, 0.0),
                child: Icon(
                  Icons.lock_rounded,
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  size: 32.0,
                ),
              ),
              Container(
                height: 20.0,
              ),
              Text(
                FFLocalizations.of(context).getText(
                  'dlf9vuoc' /* Workout slots are full */,
                ),
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                      color: Color(0xFF1A202C),
                      fontSize: 22.0,
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
                  'oee4cgby' /* Free includes 3 saved workouts... */,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(
                        fontWeight:
                            FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).secondaryText,
                      fontSize: 14.0,
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      lineHeight: 1.4,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                height: 24.0,
              ),
              Container(
                height: 12.0,
              ),
              FFButtonWidget(
                onPressed: () async {
                  context.pushNamed(PremiumPaywallPageWidget.routeName);
                },
                text: FFLocalizations.of(context).getText(
                  'wqrggdhn' /* Go Pro — unlimited workouts */,
                ),
                options: FFButtonOptions(
                  width: MediaQuery.sizeOf(context).width * 1.0,
                  height: 50.0,
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  iconPadding:
                      EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  color: FlutterFlowTheme.of(context).primary,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        font: GoogleFonts.interTight(
                          fontWeight: FlutterFlowTheme.of(context)
                              .titleSmall
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).titleSmall.fontStyle,
                        ),
                        color: Colors.white,
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).titleSmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleSmall.fontStyle,
                      ),
                  elevation: 0.0,
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              FFButtonWidget(
                onPressed: () async {
                  context.pushNamed(MasterPageWidget.routeName);
                },
                text: FFLocalizations.of(context).getText(
                  '7u8hn702' /* Manage my workouts */,
                ),
                options: FFButtonOptions(
                  height: 40.0,
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  iconPadding:
                      EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        font: GoogleFonts.interTight(
                          fontWeight: FontWeight.normal,
                          fontStyle:
                              FlutterFlowTheme.of(context).titleSmall.fontStyle,
                        ),
                        color: FlutterFlowTheme.of(context).secondaryText,
                        fontSize: 14.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.normal,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleSmall.fontStyle,
                      ),
                  elevation: 0.0,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
