import '/backend/sqlite/sqlite_manager.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'superset_bottom_shit_model.dart';
export 'superset_bottom_shit_model.dart';

/// Create a component,
/// Design a bottom sheet called “Choose Superset Partner” — visuals only, no
/// logic.
///
/// Style
///
/// Rounded top corners (20–24px).
///
/// Light background surface with soft shadow.
///
/// App accent color: mint/teal for highlights.
///
/// Padding: 16–20 all around.
///
/// Layout
///
/// Header row
///
/// Left: bold title “Choose Superset Partner” (16–18sp).
///
/// Right: circular close (X) icon button.
///
/// Divider line below header.
///
/// Search field (static, non-functional)
///
/// Full-width rounded input style.
///
/// Leading search icon.
///
/// Placeholder text “Search exercise…”.
///
/// Scrollable list of sample exercises
///
/// Each row:
///
/// Left: Exercise name in medium weight (14–16sp).
///
/// Subtitle below in muted gray “in workout”.
///
/// Right: radio-style circle indicator (unchecked).
///
/// Example selected row: tinted mint background (opacity ~10%), 1px mint
/// border, radio indicator checked.
///
/// Footer buttons
///
/// Primary full-width button “Create Superset” (teal background, white text).
///
/// Secondary text button “Cancel” below in muted gray.
///
/// Overall look
///
/// Clean, minimal fitness-app aesthetic.
///
/// Compact spacing (8–12 between rows).
///
/// Typography modern and readable.
class SupersetBottomShitWidget extends StatefulWidget {
  const SupersetBottomShitWidget({
    super.key,
    required this.exerciseId,
  });

  final int? exerciseId;

  @override
  State<SupersetBottomShitWidget> createState() =>
      _SupersetBottomShitWidgetState();
}

class _SupersetBottomShitWidgetState extends State<SupersetBottomShitWidget> {
  late SupersetBottomShitModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SupersetBottomShitModel());
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
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  FFLocalizations.of(context).getText(
                    'b8ku8qol' /* Choose Superset Partner */,
                  ),
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        font: GoogleFonts.interTight(
                          fontWeight: FontWeight.bold,
                          fontStyle: FlutterFlowTheme.of(context)
                              .titleMedium
                              .fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.bold,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleMedium.fontStyle,
                      ),
                ),
                FlutterFlowIconButton(
                  borderColor: Colors.transparent,
                  borderRadius: 16.0,
                  buttonSize: 32.0,
                  fillColor: Colors.transparent,
                  icon: Icon(
                    Icons.close_rounded,
                    color: FlutterFlowTheme.of(context).secondaryText,
                    size: 20.0,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            Container(
              width: double.infinity,
              height: 1.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).alternate,
              ),
            ),
            Container(
              decoration: BoxDecoration(),
              child: Builder(
                builder: (context) {
                  final exercise = functions
                      .buildExerciseTableFromSets(
                          FFAppState().exercisesets.toList())
                      .toList();

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    itemCount: exercise.length,
                    itemBuilder: (context, exerciseIndex) {
                      final exerciseItem = exercise[exerciseIndex];
                      return Visibility(
                        visible: widget.exerciseId !=
                            getJsonField(
                              exerciseItem,
                              r'''$["exerciseId"]''',
                            ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              12.0, 0.0, 12.0, 12.0),
                          child: FutureBuilder<List<Exercise2Row>>(
                            future: SQLiteManager.instance.exercise2(
                              exerciseId: getJsonField(
                                exerciseItem,
                                r'''$["exerciseId"]''',
                              ),
                            ),
                            builder: (context, snapshot) {
                              // Customize what your widget looks like when it's loading.
                              if (!snapshot.hasData) {
                                return Center(
                                  child: SizedBox(
                                    width: 50.0,
                                    height: 50.0,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        FlutterFlowTheme.of(context).secondary,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final containerExercise2RowList = snapshot.data!;

                              return InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  HapticFeedback.selectionClick();
                                  _model.selectedExerciseId = getJsonField(
                                    exerciseItem,
                                    r'''$["exerciseId"]''',
                                  );
                                  safeSetState(() {});
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(
                                      color: _model.selectedExerciseId ==
                                              getJsonField(
                                                exerciseItem,
                                                r'''$["exerciseId"]''',
                                              )
                                          ? FlutterFlowTheme.of(context)
                                              .secondary
                                          : FlutterFlowTheme.of(context)
                                              .primaryBackground,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Container(
                                                width: 40.0,
                                                height: 40.0,
                                                child: custom_widgets
                                                    .ExerciseAssetImage(
                                                  width: 40.0,
                                                  height: 40.0,
                                                  exerciseName: functions
                                                      .exerciseImageName(
                                                          containerExercise2RowList
                                                              .firstOrNull!
                                                              .name),
                                                  borderRadius: 12.0,
                                                ),
                                              ),
                                              Expanded(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      valueOrDefault<String>(
                                                        containerExercise2RowList
                                                            .firstOrNull?.name,
                                                        'name',
                                                      ),
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            font: GoogleFonts
                                                                .inter(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                            ),
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                    ),
                                                    Text(
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'aexc1ufy' /* in workout */,
                                                      ),
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelSmall
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelSmall
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelSmall
                                                                      .fontStyle,
                                                                ),
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryText,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .fontStyle,
                                                              ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ].divide(SizedBox(width: 10.0)),
                                          ),
                                        ),
                                        if (_model.selectedExerciseId ==
                                            getJsonField(
                                              exerciseItem,
                                              r'''$["exerciseId"]''',
                                            ))
                                          Align(
                                            alignment:
                                                AlignmentDirectional(1.0, 0.0),
                                            child: Icon(
                                              Icons.check_circle,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .success,
                                              size: 25.0,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FFButtonWidget(
                  onPressed: (_model.selectedExerciseId == null)
                      ? null
                      : () async {
                          _model.superset = await actions.pairSupersetSimple(
                            FFAppState().exercisesets.toList(),
                            widget.exerciseId!,
                            _model.selectedExerciseId!,
                          );
                          FFAppState().exercisesets =
                              _model.superset!.toList().cast<dynamic>();
                          safeSetState(() {});
                          Navigator.pop(context);

                          safeSetState(() {});
                        },
                  text: FFLocalizations.of(context).getText(
                    'ljsqf977' /* Create Superset */,
                  ),
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 48.0,
                    padding: EdgeInsets.all(8.0),
                    iconPadding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                    color: FlutterFlowTheme.of(context).secondary,
                    textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          font: GoogleFonts.interTight(
                            fontWeight: FlutterFlowTheme.of(context)
                                .titleSmall
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleSmall
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).info,
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .titleSmall
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).titleSmall.fontStyle,
                        ),
                    elevation: 0.0,
                    borderSide: BorderSide(
                      color: Colors.transparent,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                    disabledColor:
                        FlutterFlowTheme.of(context).primaryBackground,
                    disabledTextColor: FlutterFlowTheme.of(context).secondary,
                  ),
                ),
              ].divide(SizedBox(height: 12.0)),
            ),
          ].divide(SizedBox(height: 16.0)),
        ),
      ),
    );
  }
}
