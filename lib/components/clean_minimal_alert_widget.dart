import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'clean_minimal_alert_model.dart';
export 'clean_minimal_alert_model.dart';

/// Create a clean, minimal alert dialog component for a dark-themed fitness
/// app.
///
/// The dialog informs the user that notifications are disabled and directs
/// them to enable them in the iOS Settings.
///
/// PARAMETERS (component inputs):
/// - title (String) — e.g. "Notifications are off"
/// - body (String) — e.g. "Turn on notifications to get an alert when your
/// rest timer ends."
/// - primaryButtonText (String) — e.g. "Open Settings"
/// - secondaryButtonText (String) — e.g. "Not now"
///
/// LAYOUT:
/// - Centered dialog card, max width 320px, auto height, padding 24px.
/// - Vertical column, center-aligned:
///   1. Circular icon container at top: 56x56px, background #C6F542 at 12%
/// opacity, containing a bell-off icon (notifications_off), 28px, color
/// #C6F542.
///   2. 16px gap, then title.
///   3. 8px gap, then body text.
///   4. 24px gap, then primary button (full width).
///   5. 8px gap, then secondary button (full width, text-only).
///
/// STYLE:
/// - Dialog background: dark charcoal (#1C1C1E), fully opaque.
/// - Border radius: 20px.
/// - Subtle border: 1px, white at 8% opacity.
/// - Soft drop shadow: black at 40% opacity, blur 32, offset y 12.
/// - title: 18px, bold, white (#FFFFFF), center-aligned.
/// - body: 14px, regular, light gray (#B8B8BC), line height 1.45,
/// center-aligned.
/// - Primary button: height 48px, background #C6F542, text #0D0D0F, 15px
/// semi-bold, border radius 14px.
/// - Secondary button: height 44px, transparent background, text #B8B8BC,
/// 14px regular.
///
/// FEEL: modern, minimal, premium, calm — informative rather than alarming.
/// No red colors, no warning triangles. No images or illustrations beyond the
/// single icon.
class CleanMinimalAlertWidget extends StatefulWidget {
  const CleanMinimalAlertWidget({
    super.key,
    String? title,
    String? body,
    String? primaryButtonText,
    String? secondaryButtonText,
  })  : this.title = title ?? '',
        this.body = body ?? '',
        this.primaryButtonText = primaryButtonText ?? '',
        this.secondaryButtonText = secondaryButtonText ?? '';

  final String title;
  final String body;
  final String primaryButtonText;
  final String secondaryButtonText;

  @override
  State<CleanMinimalAlertWidget> createState() =>
      _CleanMinimalAlertWidgetState();
}

class _CleanMinimalAlertWidgetState extends State<CleanMinimalAlertWidget> {
  late CleanMinimalAlertModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CleanMinimalAlertModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320.0,
      decoration: BoxDecoration(
        color: Color(0xFF1C1C1E),
        boxShadow: [
          BoxShadow(
            blurRadius: 32.0,
            color: Color(0x66000000),
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
          color: Color(0x14FFFFFF),
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
                  color: Color(0x1FC6F542),
                  borderRadius: BorderRadius.circular(9999.0),
                  shape: BoxShape.rectangle,
                ),
                alignment: AlignmentDirectional(0.0, 0.0),
                child: Icon(
                  Icons.notifications_off_rounded,
                  color: Color(0xFFC6F542),
                  size: 28.0,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: Colors.white,
                          fontSize: 18.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                          lineHeight: 1.4,
                        ),
                  ),
                  Text(
                    widget.body,
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
                          color: Color(0xFFB8B8BC),
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
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 0.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 48.0,
                      decoration: BoxDecoration(
                        color: Color(0xFFC6F542),
                        borderRadius: BorderRadius.circular(14.0),
                        shape: BoxShape.rectangle,
                      ),
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Text(
                        widget.primaryButtonText,
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
                    Container(
                      height: 44.0,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.rectangle,
                      ),
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Text(
                        widget.secondaryButtonText,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: Color(0xFFB8B8BC),
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
                  ].divide(SizedBox(height: 8.0)),
                ),
              ),
            ].divide(SizedBox(height: 16.0)),
          ),
        ),
      ),
    );
  }
}
