import '/components/manual_for_creation_widget.dart';
import '/components/timed_exercise_picker_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'time_for_creation_model.dart';
export 'time_for_creation_model.dart';

class TimeForCreationWidget extends StatefulWidget {
  const TimeForCreationWidget({
    super.key,
    required this.timerMode,
    required this.exerciseId,
    this.setNumber,
    required this.updatedDuration,
    this.exerciseName,
  });

  final Future Function()? timerMode;
  final int? exerciseId;
  final int? setNumber;
  final Future Function(int ms)? updatedDuration;
  final String? exerciseName;

  @override
  State<TimeForCreationWidget> createState() => _TimeForCreationWidgetState();
}

class _TimeForCreationWidgetState extends State<TimeForCreationWidget> {
  late TimeForCreationModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TimeForCreationModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180.0,
      height: 50.0,
      decoration: BoxDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Align(
            alignment: AlignmentDirectional(0.0, -1.0),
            child: Container(
              width: 145.0,
              height: 50.0,
              decoration: BoxDecoration(),
              child: Stack(
                alignment: AlignmentDirectional(0.0, 0.0),
                children: [
                  if (_model.timerMode == 2)
                    Align(
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 50.0, 0.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                await showModalBottomSheet(
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  enableDrag: false,
                                  context: context,
                                  builder: (context) {
                                    return Padding(
                                      padding: MediaQuery.viewInsetsOf(context),
                                      child: TimedExercisePickerWidget(
                                        exerciseId: widget.exerciseId!,
                                        initial: _model.countDownValue!,
                                        selected: (ms) async {
                                          _model.countDownValue = ms;
                                          _model.updatedDuration = ms;
                                          safeSetState(() {});
                                          await widget.updatedDuration?.call(
                                            ms,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ).then((value) => safeSetState(() {}));
                              },
                              child: Container(
                                decoration: BoxDecoration(),
                                child: Text(
                                  valueOrDefault<String>(
                                    functions.formatMillisToMMSS(
                                        _model.countDownValue?.toDouble()),
                                    '1:30',
                                  ),
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
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ),
                            ),
                          ].divide(SizedBox(width: 10.0)),
                        ),
                      ),
                    ),
                  if (_model.timerMode == 3)
                    Align(
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Container(
                        width: 135.0,
                        height: 42.0,
                        child: custom_widgets.TimeInputFields(
                          width: 135.0,
                          height: 42.0,
                          textSize: 14.0,
                          onChanged: (durationMs) async {
                            _model.updatedDuration = durationMs;
                            safeSetState(() {});
                            await widget.updatedDuration?.call(
                              durationMs!,
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Builder(
            builder: (context) => FlutterFlowIconButton(
              borderRadius: 30.0,
              buttonSize: 35.0,
              fillColor: FlutterFlowTheme.of(context).primary,
              icon: Icon(
                Icons.more_vert,
                color: FlutterFlowTheme.of(context).info,
                size: 18.0,
              ),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (dialogContext) {
                    return Dialog(
                      elevation: 0,
                      insetPadding: EdgeInsets.zero,
                      backgroundColor: Colors.transparent,
                      alignment: AlignmentDirectional(0.0, 0.0)
                          .resolve(Directionality.of(context)),
                      child: ManualForCreationWidget(
                        exerciseId: widget.exerciseId!,
                        setNumber: widget.setNumber!,
                        curentMode: _model.timerMode,
                        timerMode: (mode) async {
                          _model.timerMode = mode;
                          safeSetState(() {});
                        },
                        countDownUpdate: () async {
                          _model.updatedDuration = _model.countDownValue;
                          safeSetState(() {});
                          await widget.updatedDuration?.call(
                            _model.updatedDuration!,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
