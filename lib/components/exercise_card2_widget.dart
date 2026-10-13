import '/components/exercise_stat_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'exercise_card2_model.dart';
export 'exercise_card2_model.dart';

class ExerciseCard2Widget extends StatefulWidget {
  const ExerciseCard2Widget({
    super.key,
    String? imgDesc,
    String? name,
    String? target,
    String? sets,
    String? reps,
    String? rest,
  })  : this.imgDesc = imgDesc ??
            'https://dimg.dreamflow.cloud/v1/image/man%20performing%20barbell%20bench%20press',
        this.name = name ?? 'Bench Press',
        this.target = target ?? 'Chest',
        this.sets = sets ?? '3',
        this.reps = reps ?? '8-12',
        this.rest = rest ?? '60s';

  final String imgDesc;
  final String name;
  final String target;
  final String sets;
  final String reps;
  final String rest;

  @override
  State<ExerciseCard2Widget> createState() => _ExerciseCard2WidgetState();
}

class _ExerciseCard2WidgetState extends State<ExerciseCard2Widget> {
  late ExerciseCard2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ExerciseCard2Model());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120.0,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        shape: BoxShape.rectangle,
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Container(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 70.0,
                height: 70.0,
                child: custom_widgets.ExerciseAssetImage(
                  width: 70.0,
                  height: 70.0,
                  exerciseName: functions.exerciseImageName(widget.name),
                  borderRadius: 12.0,
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      valueOrDefault<String>(
                        widget.name,
                        'Bench Press',
                      ),
                      maxLines: 1,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).primaryText,
                            fontSize: 16.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                            lineHeight: 1.4,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).alternate,
                        borderRadius: BorderRadius.circular(4.0),
                        shape: BoxShape.rectangle,
                      ),
                      child: Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
                        child: Container(
                          child: Text(
                            valueOrDefault<String>(
                              widget.target,
                              'Chest',
                            ),
                            style: FlutterFlowTheme.of(context)
                                .labelSmall
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .labelSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .labelSmall
                                      .fontStyle,
                                  lineHeight: 1.4,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ].divide(SizedBox(height: 10.0)),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      wrapWithModel(
                        model: _model.exerciseStatModel1,
                        updateCallback: () => safeSetState(() {}),
                        child: ExerciseStatWidget(
                          label: 'REPS',
                          value: valueOrDefault<String>(
                            widget.reps,
                            '-',
                          ),
                        ),
                      ),
                      Expanded(
                        child: wrapWithModel(
                          model: _model.exerciseStatModel2,
                          updateCallback: () => safeSetState(() {}),
                          child: ExerciseStatWidget(
                            label: 'SETS',
                            value: valueOrDefault<String>(
                              widget.sets,
                              '3',
                            ),
                          ),
                        ),
                      ),
                    ].divide(SizedBox(height: 8.0)),
                  ),
                ].divide(SizedBox(width: 16.0)),
              ),
            ].divide(SizedBox(width: 16.0)),
          ),
        ),
      ),
    );
  }
}
