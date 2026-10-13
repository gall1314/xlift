import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'manual_for_creation_model.dart';
export 'manual_for_creation_model.dart';

/// Create a compact popup-style floating menu with a dark semi-transparent
/// background (#000000CC), rounded corners and padding.
///
/// The component should include 3 vertical options:
/// - Count Up
/// - Countdown
/// - Manual Entry
///
/// Each option should appear as a row with:
/// • A real icon on the left (use FlutterFlow icon sets, not emojis)
/// • Text label on the right
/// • Proper spacing between rows (e.g., 12px)
///
/// Use icons like:
/// - Count Up: timer icon (Material → Icons.timer)
/// - Countdown: hourglass icon (Feather or Fluent)
/// - Manual Entry: edit or keyboard icon (Material → Icons.edit or
/// Icons.keyboard)
///
/// Text should be white. Rows should be tap targets with onTap actions to be
/// added later.
///
/// Size should be ~250px wide, auto height. Background should be black with
/// 80% opacity. This is not a bottom sheet – it's a floating contextual
/// popup.
class ManualForCreationWidget extends StatefulWidget {
  const ManualForCreationWidget({
    super.key,
    required this.exerciseId,
    required this.setNumber,
    required this.timerMode,
    required this.curentMode,
    required this.countDownUpdate,
  });

  final int? exerciseId;
  final int? setNumber;
  final Future Function(int mode)? timerMode;
  final int? curentMode;
  final Future Function()? countDownUpdate;

  @override
  State<ManualForCreationWidget> createState() =>
      _ManualForCreationWidgetState();
}

class _ManualForCreationWidgetState extends State<ManualForCreationWidget> {
  late ManualForCreationModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ManualForCreationModel());
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
      width: 200.0,
      height: 150.0,
      decoration: BoxDecoration(
        color: Color(0xCC000000),
        borderRadius: BorderRadius.circular(12.0),
      ),
      alignment: AlignmentDirectional(0.0, 0.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: InkWell(
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () async {
                FFAppState().exercisesets = functions
                    .updateTimerModeForSet(
                        widget.exerciseId!,
                        widget.setNumber!,
                        2,
                        FFAppState().exercisesets.toList())
                    .toList()
                    .cast<dynamic>();
                safeSetState(() {});
                await widget.timerMode?.call(
                  2,
                );
                Navigator.pop(context);
              },
              child: Container(
                width: MediaQuery.sizeOf(context).width * 1.0,
                height: 50.0,
                decoration: BoxDecoration(),
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        color: Colors.white,
                        size: 24.0,
                      ),
                      Expanded(
                        child: Text(
                          FFLocalizations.of(context).getText(
                            '5c4jdtk1' /* Countdown */,
                          ),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Colors.white,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                        ),
                      ),
                      if (widget.curentMode == 2)
                        Icon(
                          Icons.check_rounded,
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          size: 24.0,
                        ),
                    ].divide(SizedBox(width: 12.0)),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () async {
                FFAppState().exercisesets = functions
                    .updateTimerModeForSet(
                        widget.exerciseId!,
                        widget.setNumber!,
                        3,
                        FFAppState().exercisesets.toList())
                    .toList()
                    .cast<dynamic>();
                safeSetState(() {});
                await widget.timerMode?.call(
                  3,
                );
                Navigator.pop(context);
              },
              child: Container(
                width: MediaQuery.sizeOf(context).width * 1.0,
                height: 50.0,
                decoration: BoxDecoration(),
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 24.0,
                      ),
                      Expanded(
                        child: Text(
                          FFLocalizations.of(context).getText(
                            'hmvt1nie' /* Manual Entry */,
                          ),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Colors.white,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                        ),
                      ),
                      if (widget.curentMode == 3)
                        Icon(
                          Icons.check_rounded,
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          size: 24.0,
                        ),
                    ].divide(SizedBox(width: 12.0)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
