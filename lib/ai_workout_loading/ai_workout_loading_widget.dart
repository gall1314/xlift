import '/components/ai_loading_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'ai_workout_loading_model.dart';
export 'ai_workout_loading_model.dart';

class AiWorkoutLoadingWidget extends StatefulWidget {
  const AiWorkoutLoadingWidget({
    super.key,
    required this.goal,
    required this.expirence,
    required this.muscels,
  });

  final int? goal;
  final String? expirence;
  final List<String>? muscels;

  static String routeName = 'aiWorkoutLoading';
  static String routePath = '/aiWorkoutLoading';

  @override
  State<AiWorkoutLoadingWidget> createState() => _AiWorkoutLoadingWidgetState();
}

class _AiWorkoutLoadingWidgetState extends State<AiWorkoutLoadingWidget> {
  late AiWorkoutLoadingModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AiWorkoutLoadingModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.goal = functions.mapGoal(widget.goal!);
      safeSetState(() {});
      if (_model.goal != null && _model.goal != '') {
        _model.api = await actions.callWorkoutBuilder(
          widget.goal!,
          widget.expirence!,
          widget.muscels!.toList(),
        );
        if (_model.api != null) {
          context.goNamed(
            AiWorkoutViewWidget.routeName,
            queryParameters: {
              'result': serializeParam(
                _model.api,
                ParamType.JSON,
              ),
              'goal': serializeParam(
                widget.goal,
                ParamType.int,
              ),
            }.withoutNulls,
          );

          FFAppState().generationDates = functions
              .addGenerationDate(FFAppState().generationDates.toList())
              .toList()
              .cast<String>();
          safeSetState(() {});
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'no',
              style: TextStyle(
                color: FlutterFlowTheme.of(context).primaryText,
              ),
            ),
            duration: Duration(milliseconds: 4000),
            backgroundColor: FlutterFlowTheme.of(context).secondary,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Align(
            alignment: AlignmentDirectional(0.0, 0.0),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 35.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  wrapWithModel(
                    model: _model.aiLoadingModel,
                    updateCallback: () => safeSetState(() {}),
                    child: AiLoadingWidget(),
                  ),
                  Container(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    height: 10.0,
                    child: custom_widgets.AiLoadingBar(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      height: 10.0,
                    ),
                  ),
                  Text(
                    FFLocalizations.of(context).getText(
                      'zo8zv9tf' /* Building Your Workout ... */,
                    ),
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          fontSize: 26.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w800,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                  Container(
                    width: 300.0,
                    height: 50.0,
                    child: custom_widgets.RotatingLoadingText(
                      width: 300.0,
                      height: 50.0,
                      intervalMs: 2500,
                      textColor: FlutterFlowTheme.of(context).secondaryText,
                      fontSize: 14.0,
                    ),
                  ),
                ].divide(SizedBox(height: 30.0)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
