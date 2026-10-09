import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'clean_minimal_alert2_model.dart';
export 'clean_minimal_alert2_model.dart';

/// Create a clean, minimal alert dialog component for a fitness app, light
/// theme.
///
/// The dialog informs the user that notifications are disabled and directs
/// them to enable them in the iOS Settings. All texts are fixed — no
/// parameters.
///
/// LAYOUT:
/// - Centered dialog card, max width 320px, auto height, padding 24px.
/// - Vertical column, center-aligned:
///   1. Circular icon container at top: 56x56px, background #C6F542 at 15%
/// opacity, containing a bell-off icon (notifications_off), 28px, color
/// #5A7A0E.
///   2. 16px gap, then title text: "Notifications are off"
///   3. 8px gap, then body text: "Turn on notifications to get an alert when
/// your rest timer ends."
///   4. 24px gap, then primary button (full width) with text: "Open Settings"
///   5. 8px gap, then secondary button (full width, text-only) with text:
/// "Not now"
///
/// STYLE:
/// - Dialog background: white (#FFFFFF), fully opaque.
/// - Border radius: 20px.
/// - Subtle border: 1px, black at 6% opacity.
/// - Soft drop shadow: black at 15% opacity, blur 32, offset y 12.
/// - Title: 18px, bold, near-black (#0D0D0F), center-aligned.
/// - Body: 14px, regular, medium gray (#6B6B70), line height 1.45,
/// center-aligned.
/// - Primary button: height 48px, background #C6F542, text #0D0D0F, 15px
/// semi-bold, border radius 14px.
/// - Secondary button: height 44px, transparent background, text #6B6B70,
/// 14px regular.
///
/// FEEL: modern, minimal, premium, calm — informative rather than alarming.
/// No red colors, no warning triangles. No images or illustrations beyond the
/// single icon. No component parameters — all text values are hardcoded
/// exactly as written above.
/// </br>
class CleanMinimalAlert2Widget extends StatefulWidget {
  const CleanMinimalAlert2Widget({super.key});

  @override
  State<CleanMinimalAlert2Widget> createState() =>
      _CleanMinimalAlert2WidgetState();
}

class _CleanMinimalAlert2WidgetState extends State<CleanMinimalAlert2Widget> {
  late CleanMinimalAlert2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CleanMinimalAlert2Model());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: 320.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 32.0,
            color: Color(0x26000000),
            offset: Offset(
              0.0,
              12.0,
            ),
            spreadRadius: 0.0,
          )
        ],
        borderRadius: BorderRadius.circular(20.0),
        shape: BoxShape.rectangle,
        border: Border.all(
          color: Color(0x0F000000),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56.0,
                height: 56.0,
                decoration: BoxDecoration(
                  color: Color(0x26C6F542),
                  borderRadius: BorderRadius.circular(9999.0),
                  shape: BoxShape.rectangle,
                ),
                alignment: AlignmentDirectional(0.0, 0.0),
                child: Icon(
                  Icons.notifications_off_rounded,
                  color: Color(0xFF5A7A0E),
                  size: 28.0,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    FFLocalizations.of(context).getText(
                      'zjehw6bv' /* Notifications are off */,
                    ),
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: Color(0xFF0D0D0F),
                          fontSize: 18.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                          lineHeight: 1.4,
                        ),
                  ),
                  Text(
                    FFLocalizations.of(context).getText(
                      'p1oi08v6' /* Turn on notifications to get a... */,
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
                          color: Color(0xFF6B6B70),
                          fontSize: 14.0,
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                          lineHeight: 1.45,
                        ),
                  ),
                ].divide(SizedBox(height: 8.0)),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      await actions.openNotificationSettings();
                    },
                    child: Container(
                      height: 48.0,
                      decoration: BoxDecoration(
                        color: Color(0xFFC6F542),
                        borderRadius: BorderRadius.circular(14.0),
                        shape: BoxShape.rectangle,
                      ),
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Text(
                        FFLocalizations.of(context).getText(
                          'dwwarzte' /* Open Settings */,
                        ),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: Color(0xFF0D0D0F),
                              fontSize: 15.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                              lineHeight: 1.4,
                            ),
                      ),
                    ),
                  ),
                  InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 44.0,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.rectangle,
                      ),
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Text(
                        FFLocalizations.of(context).getText(
                          'ap6c6a5o' /* Not now */,
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
                              color: Color(0xFF6B6B70),
                              fontSize: 14.0,
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
                ].divide(SizedBox(height: 8.0)),
              ),
            ].divide(SizedBox(height: 16.0)),
          ),
        ),
      ),
    );
  }
}
