import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'clean_minimal_tooltip_model.dart';
export 'clean_minimal_tooltip_model.dart';

/// Create a clean, minimal tooltip component for an in-app walkthrough
/// overlay in a fitness app.
///
/// PARAMETERS (component inputs):
/// - title (String) — short heading, e.g. "Start here"
/// - body (String) — one-line description, e.g. "Build your first workout in
/// under a minute."
/// - stepText (String, optional) — small step indicator, e.g. "1 of 3"
///
/// LAYOUT:
/// - A single rounded container, max width 300px, auto height, padding 16px
/// all sides.
/// - Vertical column: stepText on top (if provided), then title, then body.
/// 6px spacing between elements.
/// - No buttons inside the tooltip (navigation is handled by the walkthrough
/// itself).
///
/// STYLE:
/// - Background: dark charcoal (#1C1C1E), fully opaque.
/// - Border radius: 16px.
/// - Subtle border: 1px, #C6F542 at 40% opacity.
/// - Soft drop shadow: black at 30% opacity, blur 24, offset y 8.
/// - stepText: 11px, semi-bold, uppercase, letter spacing 1px, color #C6F542.
/// - title: 17px, bold, white (#FFFFFF).
/// - body: 14px, regular, light gray (#B8B8BC), line height 1.4.
/// - Left-aligned text.
///
/// FEEL: modern, minimal, premium. No icons, no images, no gradients. It
/// should look like a native part of a dark-themed fitness app with a lime
/// green (#C6F542) accent.
class CleanMinimalTooltipWidget extends StatefulWidget {
  const CleanMinimalTooltipWidget({
    super.key,
    String? stepText,
    String? title,
    String? body,
  })  : this.stepText = stepText ?? '',
        this.title = title ?? '',
        this.body = body ?? '';

  final String stepText;
  final String title;
  final String body;

  @override
  State<CleanMinimalTooltipWidget> createState() =>
      _CleanMinimalTooltipWidgetState();
}

class _CleanMinimalTooltipWidgetState extends State<CleanMinimalTooltipWidget> {
  late CleanMinimalTooltipModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CleanMinimalTooltipModel());
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
        maxWidth: 300.0,
      ),
      decoration: BoxDecoration(
        color: Color(0xFF1C1C1E),
        boxShadow: [
          BoxShadow(
            blurRadius: 24.0,
            color: Color(0x4D000000),
            offset: Offset(
              0.0,
              8.0,
            ),
            spreadRadius: 0.0,
          )
        ],
        borderRadius: BorderRadius.circular(16.0),
        shape: BoxShape.rectangle,
        border: Border.all(
          color: Color(0x66C6F542),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.stepText,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                      color: Color(0xFFC6F542),
                      fontSize: 11.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      lineHeight: 1.4,
                    ),
              ),
              Text(
                widget.title,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                      color: Colors.white,
                      fontSize: 17.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      lineHeight: 1.4,
                    ),
              ),
              Text(
                widget.body,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(
                        fontWeight: FontWeight.normal,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                      color: Color(0xFFB8B8BC),
                      fontSize: 14.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.normal,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      lineHeight: 1.4,
                    ),
              ),
            ].divide(SizedBox(height: 4.0)),
          ),
        ),
      ),
    );
  }
}
