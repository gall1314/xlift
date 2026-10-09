import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'exercise_stats_place_holder_model.dart';
export 'exercise_stats_place_holder_model.dart';

class ExerciseStatsPlaceHolderWidget extends StatefulWidget {
  const ExerciseStatsPlaceHolderWidget({super.key});

  @override
  State<ExerciseStatsPlaceHolderWidget> createState() =>
      _ExerciseStatsPlaceHolderWidgetState();
}

class _ExerciseStatsPlaceHolderWidgetState
    extends State<ExerciseStatsPlaceHolderWidget> {
  late ExerciseStatsPlaceHolderModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ExerciseStatsPlaceHolderModel());
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
              'zekrnvm0' /* No Data for This Period */,
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
              'u1bdzrku' /* Log workouts or adjust the tim... */,
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
