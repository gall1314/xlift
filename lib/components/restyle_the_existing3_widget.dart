import '/components/discard_and_start_new_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'restyle_the_existing3_model.dart';
export 'restyle_the_existing3_model.dart';

/// Restyle the existing QuickStartWorkout component into a COMPACT single-row
/// version.
///
/// Keep the same component parameters (workoutName, workoutMeta,
/// contextLabel) — only change the layout and styling:
///
/// LAYOUT:
/// - Total height: 56px. A single horizontal Row with two elements, 10px gap:
///   1. Main button (expanded, fills remaining width)
///   2. Swap button (56x56px square)
/// - No card wrapper, no section label, no large title — the whole component
/// is just these two buttons.
///
/// MAIN BUTTON:
/// - Height 56px, border radius 16px.
/// - Background: green gradient from #1FC77D (top left) to #0FA463 (bottom
/// right).
/// - Shadow: #1D9E75 at 35% opacity, blur 18, offset y 6.
/// - Content: centered horizontally, a Row with a play icon (white, 16px) and
/// a two-line Column (left-aligned):
///   - Line 1: "Start Workout" — white, 15px, bold.
///   - Line 2: workoutName + " · " + contextLabel (e.g. "Push Day · last done
/// 6d ago") — white at 85% opacity, 11px, single line, ellipsis overflow.
/// - Minimum tap target: full button.
///
/// SWAP BUTTON:
/// - 56x56px, border radius 16px.
/// - Background: white. Border: 1.5px solid #1D9E75 at 30% opacity.
/// - Icon: swap-horizontal, 22px, color #0F6E56.
///
/// FEEL: compact, confident, energetic. Same footprint as a standard
/// full-width primary button — this replaces a large hero card, so it must
/// stay slim (56px total height), with the workout context living in the
/// small second line.
class RestyleTheExisting3Widget extends StatefulWidget {
  const RestyleTheExisting3Widget({
    super.key,
    required this.replace,
    required this.workout,
    required this.workoutsCount,
  });

  final Future Function()? replace;
  final dynamic workout;
  final int? workoutsCount;

  @override
  State<RestyleTheExisting3Widget> createState() =>
      _RestyleTheExisting3WidgetState();
}

class _RestyleTheExisting3WidgetState extends State<RestyleTheExisting3Widget> {
  late RestyleTheExisting3Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RestyleTheExisting3Model());
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
      height: 56.0,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 1,
            child: Builder(
              builder: (context) => InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  if (FFAppState().workout) {
                    await showDialog(
                      context: context,
                      builder: (dialogContext) {
                        return Dialog(
                          elevation: 0,
                          insetPadding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                          alignment: AlignmentDirectional(0.0, 0.0)
                              .resolve(Directionality.of(context)),
                          child: DiscardAndStartNewWidget(
                            workoutId: getJsonField(
                              widget.workout,
                              r'''$["id"]''',
                            ).toString(),
                            startAnalysis: () async {},
                          ),
                        );
                      },
                    );
                  } else {
                    context.goNamed(
                      WorkoutV2Widget.routeName,
                      queryParameters: {
                        'workoutId': serializeParam(
                          getJsonField(
                            widget.workout,
                            r'''$["id"]''',
                          ).toString(),
                          ParamType.String,
                        ),
                      }.withoutNulls,
                    );
                  }
                },
                child: Container(
                  height: 56.0,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 18.0,
                        color: Color(0x591D9E75),
                        offset: Offset(
                          0.0,
                          6.0,
                        ),
                        spreadRadius: 0.0,
                      )
                    ],
                    gradient: LinearGradient(
                      colors: [Color(0xFF1FC77D), Color(0xFF0FA463)],
                      stops: [0.0, 1.0],
                      begin: AlignmentDirectional(0.0, -1.0),
                      end: AlignmentDirectional(0, 1.0),
                    ),
                    borderRadius: BorderRadius.circular(16.0),
                    shape: BoxShape.rectangle,
                  ),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                    child: Container(
                      child: Container(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 32.0,
                            ),
                            Expanded(
                              flex: 1,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getJsonField(
                                      widget.workout,
                                      r'''$["name"]''',
                                    ).toString(),
                                    maxLines: 1,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: Colors.white,
                                          fontSize: 15.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                          lineHeight: 1.4,
                                        ),
                                  ),
                                  Text(
                                    valueOrDefault<String>(
                                      '${getJsonField(
                                        widget.workout,
                                        r'''$["exerciseCount"]''',
                                      ).toString()} Exercises · ${getJsonField(
                                        widget.workout,
                                        r'''$["lastDone"]''',
                                      ).toString()}',
                                      ' · ',
                                    ),
                                    maxLines: 1,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: Color(0xD9FFFFFF),
                                          fontSize: 11.0,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                          lineHeight: 1.4,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ].divide(SizedBox(height: 0.0)),
                              ),
                            ),
                          ].divide(SizedBox(width: 12.0)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.workoutsCount! > 1)
            FlutterFlowIconButton(
              borderColor: FlutterFlowTheme.of(context).accent2,
              borderRadius: 16.0,
              borderWidth: 1.5,
              buttonSize: 56.0,
              fillColor: FlutterFlowTheme.of(context).secondaryBackground,
              icon: Icon(
                Icons.swap_horiz_sharp,
                color: Color(0xFF0FA463),
                size: 24.0,
              ),
              onPressed: () async {
                await widget.replace?.call();
              },
            ),
        ].divide(SizedBox(width: 10.0)),
      ),
    );
  }
}
