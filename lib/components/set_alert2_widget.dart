import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_timer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'set_alert2_model.dart';
export 'set_alert2_model.dart';

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
class SetAlert2Widget extends StatefulWidget {
  const SetAlert2Widget({
    super.key,
    this.errorMesseage,
  });

  final String? errorMesseage;

  @override
  State<SetAlert2Widget> createState() => _SetAlert2WidgetState();
}

class _SetAlert2WidgetState extends State<SetAlert2Widget> {
  late SetAlert2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SetAlert2Model());

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
    return Container(
      width: MediaQuery.sizeOf(context).width * 0.88,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Color(0x33F1F5F9)
            : Color(0x80000000),
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
                  widget.errorMesseage,
                  '-',
                ),
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                      color: Colors.white,
                      fontSize: 15.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
              ),
            ),
            Opacity(
              opacity: 0.0,
              child: Align(
                alignment: AlignmentDirectional(0.0, 0.0),
                child: FlutterFlowTimer(
                  initialTime: _model.timerInitialTimeMs,
                  getDisplayTime: (value) => StopWatchTimer.getDisplayTime(
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
                  },
                  textAlign: TextAlign.start,
                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                        font: GoogleFonts.interTight(
                          fontWeight: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .fontWeight,
                          fontStyle: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .fontStyle,
                        ),
                        color: FlutterFlowTheme.of(context).alternate,
                        fontSize: 1.0,
                        letterSpacing: 0.0,
                        fontWeight: FlutterFlowTheme.of(context)
                            .headlineSmall
                            .fontWeight,
                        fontStyle: FlutterFlowTheme.of(context)
                            .headlineSmall
                            .fontStyle,
                      ),
                ),
              ),
            ),
            FFButtonWidget(
              onPressed: () async {
                _model.timerController.onStopTimer();
                Navigator.pop(context);
              },
              text: FFLocalizations.of(context).getText(
                'ks1gvb8h' /* Close */,
              ),
              options: FFButtonOptions(
                width: MediaQuery.sizeOf(context).width * 0.3,
                height: 40.0,
                padding: EdgeInsets.all(8.0),
                iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                color: Color(0xFF10B6A6),
                textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                      font: GoogleFonts.interTight(
                        fontWeight:
                            FlutterFlowTheme.of(context).titleSmall.fontWeight,
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
                borderSide: BorderSide(
                  color: Colors.transparent,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
