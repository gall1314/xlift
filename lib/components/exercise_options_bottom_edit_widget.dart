import '/components/remove_exercise_from_workout_alert_widget.dart';
import '/components/reorder_creation_widget.dart';
import '/components/superset_creation_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'exercise_options_bottom_edit_model.dart';
export 'exercise_options_bottom_edit_model.dart';

/// Create a component,
/// "Design a clean and modern Bottom Sheet for a fitness tracking app.
///
/// The sheet should have a light background (not dark), rounded top corners,
/// and a subtle shadow for depth. Each option row should be spacious with an
/// icon on the left and clear text on the right. Use a simple and readable
/// font, medium size, and keep good padding between elements.
///
/// Highlight destructive actions (like Delete Set) in red, while toggle
/// actions (like Warm-up or Dropset) should use accent colors (green/blue).
/// The overall style should feel minimal, intuitive, and easy to tap with one
/// hand. Make sure the layout looks good in light mode, with high contrast
/// and no heavy dark overlays."
class ExerciseOptionsBottomEditWidget extends StatefulWidget {
  const ExerciseOptionsBottomEditWidget({
    super.key,
    required this.exerciseId,
    this.exerciseName,
    this.exerciseEquipment,
  });

  final int? exerciseId;
  final String? exerciseName;
  final String? exerciseEquipment;

  @override
  State<ExerciseOptionsBottomEditWidget> createState() =>
      _ExerciseOptionsBottomEditWidgetState();
}

class _ExerciseOptionsBottomEditWidgetState
    extends State<ExerciseOptionsBottomEditWidget> {
  late ExerciseOptionsBottomEditModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ExerciseOptionsBottomEditModel());
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
            blurRadius: 8.0,
            color: Color(0x33000000),
            offset: Offset(
              0.0,
              -2.0,
            ),
            spreadRadius: 0.0,
          )
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
              child: Container(
                width: 40.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).alternate,
                  borderRadius: BorderRadius.circular(2.0),
                ),
                alignment: AlignmentDirectional(0.0, 0.0),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          HapticFeedback.selectionClick();

                          context.pushNamed(
                            ReplaceExercisePageCreationWidget.routeName,
                            queryParameters: {
                              'exerciseId': serializeParam(
                                widget.exerciseId,
                                ParamType.int,
                              ),
                            }.withoutNulls,
                          );

                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          height: 56.0,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 16.0, 16.0, 16.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.refresh,
                                  color: FlutterFlowTheme.of(context).primary,
                                  size: 24.0,
                                ),
                                Expanded(
                                  child: Text(
                                    FFLocalizations.of(context).getText(
                                      '8geuog8j' /* Replace Exercise */,
                                    ),
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
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_right_rounded,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 24.0,
                                ),
                              ].divide(SizedBox(width: 16.0)),
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
                          HapticFeedback.selectionClick();
                          Navigator.pop(context);
                          await showModalBottomSheet(
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            enableDrag: false,
                            context: context,
                            builder: (context) {
                              return Padding(
                                padding: MediaQuery.viewInsetsOf(context),
                                child: SupersetCreationWidget(
                                  currentExerciseId: widget.exerciseId!,
                                ),
                              );
                            },
                          ).then((value) => safeSetState(() {}));
                        },
                        child: Container(
                          width: double.infinity,
                          height: 56.0,
                          decoration: BoxDecoration(),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 16.0, 16.0, 16.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Icon(
                                  Icons.link,
                                  color: Color(0xFF8B5CF6),
                                  size: 24.0,
                                ),
                                Expanded(
                                  child: Text(
                                    FFLocalizations.of(context).getText(
                                      'jwcmvr9b' /* Superset */,
                                    ),
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
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_right_rounded,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 24.0,
                                ),
                              ].divide(SizedBox(width: 16.0)),
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
                          HapticFeedback.selectionClick();

                          context.pushNamed(
                            ExerciseHistoryWidget.routeName,
                            queryParameters: {
                              'exerciseId': serializeParam(
                                widget.exerciseId,
                                ParamType.int,
                              ),
                              'overview': serializeParam(
                                false,
                                ParamType.bool,
                              ),
                              'analytics': serializeParam(
                                false,
                                ParamType.bool,
                              ),
                            }.withoutNulls,
                          );

                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          height: 56.0,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 16.0, 16.0, 16.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.bar_chart_rounded,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 24.0,
                                ),
                                Expanded(
                                  child: Text(
                                    FFLocalizations.of(context).getText(
                                      'q24v9kyr' /*  View History */,
                                    ),
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
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_right_rounded,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 24.0,
                                ),
                              ].divide(SizedBox(width: 16.0)),
                            ),
                          ),
                        ),
                      ),
                      if (FFAppState().exerciseSetsCretion.length > 1)
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            Navigator.pop(context);
                            await showModalBottomSheet(
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              enableDrag: false,
                              context: context,
                              builder: (context) {
                                return Padding(
                                  padding: MediaQuery.viewInsetsOf(context),
                                  child: ReorderCreationWidget(),
                                );
                              },
                            ).then((value) => safeSetState(() {}));
                          },
                          child: Container(
                            width: double.infinity,
                            height: 56.0,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                            ),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 16.0, 16.0, 16.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.reorder_rounded,
                                    color: Color(0xFF6B7280),
                                    size: 24.0,
                                  ),
                                  Expanded(
                                    child: Text(
                                      FFLocalizations.of(context).getText(
                                        'qqj0lsek' /* Reorder */,
                                      ),
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
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_right_rounded,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    size: 24.0,
                                  ),
                                ].divide(SizedBox(width: 16.0)),
                              ),
                            ),
                          ),
                        ),
                      Container(
                        width: double.infinity,
                        height: 1.0,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).alternate,
                        ),
                      ),
                      Builder(
                        builder: (context) => InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            if (functions.exerciseHasLoggedValuesFlat(
                                FFAppState().loggedSetsCreation.toList(),
                                widget.exerciseId!)) {
                              await showDialog(
                                context: context,
                                builder: (dialogContext) {
                                  return Dialog(
                                    elevation: 0,
                                    insetPadding: EdgeInsets.zero,
                                    backgroundColor: Colors.transparent,
                                    alignment: AlignmentDirectional(0.0, 0.0)
                                        .resolve(Directionality.of(context)),
                                    child: RemoveExerciseFromWorkoutAlertWidget(
                                      exerciseId: widget.exerciseId!,
                                      closeBottom: () async {
                                        Navigator.pop(context);
                                      },
                                    ),
                                  );
                                },
                              );
                            } else {
                              _model.remove =
                                  await actions.removeExerciseFromExerciseSets(
                                FFAppState().exerciseSetsCretion.toList(),
                                widget.exerciseId!,
                              );
                              FFAppState().exerciseSetsCretion =
                                  _model.remove!.toList().cast<dynamic>();
                              safeSetState(() {});
                              Navigator.pop(context);
                            }

                            safeSetState(() {});
                          },
                          child: Container(
                            width: double.infinity,
                            height: 56.0,
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 16.0, 16.0, 16.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: FlutterFlowTheme.of(context).error,
                                    size: 24.0,
                                  ),
                                  Expanded(
                                    child: Text(
                                      FFLocalizations.of(context).getText(
                                        'iw69eigi' /* Remove Exercise */,
                                      ),
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
                                            color: FlutterFlowTheme.of(context)
                                                .error,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                ].divide(SizedBox(width: 16.0)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ].divide(SizedBox(height: 16.0)),
                  ),
                ),
              ],
            ),
          ].divide(SizedBox(height: 4.0)),
        ),
      ),
    );
  }
}
