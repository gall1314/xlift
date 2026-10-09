import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'exercise_history_place_holder_model.dart';
export 'exercise_history_place_holder_model.dart';

class ExerciseHistoryPlaceHolderWidget extends StatefulWidget {
  const ExerciseHistoryPlaceHolderWidget({super.key});

  @override
  State<ExerciseHistoryPlaceHolderWidget> createState() =>
      _ExerciseHistoryPlaceHolderWidgetState();
}

class _ExerciseHistoryPlaceHolderWidgetState
    extends State<ExerciseHistoryPlaceHolderWidget> {
  late ExerciseHistoryPlaceHolderModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ExerciseHistoryPlaceHolderModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 323.7,
      height: 345.28,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            color: FlutterFlowTheme.of(context).secondaryText,
            size: 60.0,
          ),
          Text(
            FFLocalizations.of(context).getText(
              '5m1els28' /* No Sets Logged */,
            ),
            style: FlutterFlowTheme.of(context).headlineSmall.override(
                  font: GoogleFonts.interTight(
                    fontWeight:
                        FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                  ),
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                ),
          ),
          Text(
            FFLocalizations.of(context).getText(
              '8xyf4f4m' /* Start training to build histor... */,
            ),
            textAlign: TextAlign.center,
            style: FlutterFlowTheme.of(context).labelMedium.override(
                  font: GoogleFonts.inter(
                    fontWeight:
                        FlutterFlowTheme.of(context).labelMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelMedium.fontStyle,
                  ),
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).labelMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                ),
          ),
        ].divide(SizedBox(height: 5.0)),
      ),
    );
  }
}
