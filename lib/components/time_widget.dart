import '/components/manual_widget.dart';
import '/components/timed_exercise_picker_widget.dart';
import '/components/timer3_widget.dart';
import '/components/timer_count_up_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_timer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'time_model.dart';
export 'time_model.dart';

class TimeWidget extends StatefulWidget {
  const TimeWidget({
    super.key,
    required this.timerMode,
    required this.exerciseId,
    this.setNumber,
    required this.updatedDuration,
    this.exerciseName,
    required this.done,
  });

  final Future Function()? timerMode;
  final int? exerciseId;
  final int? setNumber;
  final Future Function(int ms)? updatedDuration;
  final String? exerciseName;
  final Future Function()? done;

  @override
  State<TimeWidget> createState() => _TimeWidgetState();
}

class _TimeWidgetState extends State<TimeWidget> {
  late TimeModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TimeModel());

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.countDownValue = getJsonField(
        functions.getInitialTimerValueForSet(FFAppState().exercisesets.toList(),
            widget.exerciseId!, widget.setNumber!),
        r'''$["durationSeconds"]''',
      );
      _model.timerMode = getJsonField(
        functions.getInitialTimerValueForSet(FFAppState().exercisesets.toList(),
            widget.exerciseId!, widget.setNumber!),
        r'''$["timerMode"]''',
      );
      safeSetState(() {});
    });

    _model.minutesTensTextController ??= TextEditingController();
    _model.minutesTensFocusNode ??= FocusNode();

    _model.minutesUnitsTextController ??= TextEditingController();
    _model.minutesUnitsFocusNode ??= FocusNode();

    _model.secondsTensTextController ??= TextEditingController();
    _model.secondsTensFocusNode ??= FocusNode();

    _model.secondsUnitsTextController ??= TextEditingController();
    _model.secondsUnitsFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
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
                  if (_model.timerMode == 1)
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 50.0, 0.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              if (!_model.timerOn)
                                Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: FlutterFlowIconButton(
                                    borderColor:
                                        FlutterFlowTheme.of(context).primary,
                                    borderRadius: 30.0,
                                    borderWidth: 1.5,
                                    buttonSize: 30.0,
                                    fillColor: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    icon: Icon(
                                      Icons.play_arrow,
                                      color:
                                          FlutterFlowTheme.of(context).success,
                                      size: 14.0,
                                    ),
                                    onPressed: () async {
                                      await showModalBottomSheet(
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        enableDrag: false,
                                        context: context,
                                        builder: (context) {
                                          return Padding(
                                            padding: MediaQuery.viewInsetsOf(
                                                context),
                                            child: TimerCountUpWidget(
                                              exerciseName:
                                                  widget.exerciseName!,
                                              done: (ms) async {
                                                _model.countUpValue = functions
                                                    .formatMsToMmSs(ms);
                                                safeSetState(() {});
                                                _model.time = await actions
                                                    .updateFlatSetTime(
                                                  FFAppState()
                                                      .loggedSets
                                                      .toList(),
                                                  widget.exerciseId!,
                                                  widget.setNumber!,
                                                  ms,
                                                  false,
                                                );
                                                FFAppState().loggedSets = _model
                                                    .time!
                                                    .toList()
                                                    .cast<dynamic>();
                                                safeSetState(() {});
                                              },
                                            ),
                                          );
                                        },
                                      ).then((value) => safeSetState(() {}));

                                      _model.timerOn = false;
                                      safeSetState(() {});

                                      safeSetState(() {});
                                    },
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            _model.countUpValue,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
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
                        ].divide(SizedBox(width: 10.0)),
                      ),
                    ),
                  if (_model.timerMode == 4)
                    Align(
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: TextFormField(
                                controller: _model.minutesTensTextController,
                                focusNode: _model.minutesTensFocusNode,
                                onChanged: (_) => EasyDebounce.debounce(
                                  '_model.minutesTensTextController',
                                  Duration(milliseconds: 0),
                                  () async {
                                    _model.updatedDuration =
                                        functions.getDurationFromTextFields(
                                            _model
                                                .minutesTensTextController.text,
                                            _model.minutesUnitsTextController
                                                .text,
                                            _model
                                                .secondsTensTextController.text,
                                            _model.secondsUnitsTextController
                                                .text);
                                    safeSetState(() {});
                                    await widget.updatedDuration?.call(
                                      _model.updatedDuration!,
                                    );
                                  },
                                ),
                                autofocus: false,
                                obscureText: false,
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelStyle: FlutterFlowTheme.of(context)
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
                                  hintText: FFLocalizations.of(context).getText(
                                    '9dmtmyq4' /* 0 */,
                                  ),
                                  hintStyle: FlutterFlowTheme.of(context)
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
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0x00000000),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0x00000000),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                maxLengthEnforcement:
                                    MaxLengthEnforcement.enforced,
                                buildCounter: (context,
                                        {required currentLength,
                                        required isFocused,
                                        maxLength}) =>
                                    null,
                                keyboardType: TextInputType.number,
                                cursorColor:
                                    FlutterFlowTheme.of(context).primaryText,
                                validator: _model
                                    .minutesTensTextControllerValidator
                                    .asValidator(context),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: 200.0,
                              child: TextFormField(
                                controller: _model.minutesUnitsTextController,
                                focusNode: _model.minutesUnitsFocusNode,
                                onChanged: (_) => EasyDebounce.debounce(
                                  '_model.minutesUnitsTextController',
                                  Duration(milliseconds: 0),
                                  () async {
                                    _model.updatedDuration =
                                        functions.getDurationFromTextFields(
                                            _model
                                                .minutesTensTextController.text,
                                            _model.minutesUnitsTextController
                                                .text,
                                            _model
                                                .secondsTensTextController.text,
                                            _model.secondsUnitsTextController
                                                .text);
                                    safeSetState(() {});
                                    await widget.updatedDuration?.call(
                                      _model.updatedDuration!,
                                    );
                                  },
                                ),
                                autofocus: false,
                                obscureText: false,
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelStyle: FlutterFlowTheme.of(context)
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
                                  hintText: FFLocalizations.of(context).getText(
                                    '3bsz70t5' /* 0 */,
                                  ),
                                  hintStyle: FlutterFlowTheme.of(context)
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
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0x00000000),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0x00000000),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                maxLengthEnforcement:
                                    MaxLengthEnforcement.enforced,
                                buildCounter: (context,
                                        {required currentLength,
                                        required isFocused,
                                        maxLength}) =>
                                    null,
                                keyboardType: TextInputType.number,
                                cursorColor:
                                    FlutterFlowTheme.of(context).primaryText,
                                validator: _model
                                    .minutesUnitsTextControllerValidator
                                    .asValidator(context),
                              ),
                            ),
                          ),
                          Align(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Text(
                              FFLocalizations.of(context).getText(
                                '4yq05tvl' /* : */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
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
                          Expanded(
                            child: Container(
                              width: 200.0,
                              child: TextFormField(
                                controller: _model.secondsTensTextController,
                                focusNode: _model.secondsTensFocusNode,
                                onChanged: (_) => EasyDebounce.debounce(
                                  '_model.secondsTensTextController',
                                  Duration(milliseconds: 0),
                                  () async {
                                    _model.updatedDuration =
                                        functions.getDurationFromTextFields(
                                            _model
                                                .minutesTensTextController.text,
                                            _model.minutesUnitsTextController
                                                .text,
                                            _model
                                                .secondsTensTextController.text,
                                            _model.secondsUnitsTextController
                                                .text);
                                    safeSetState(() {});
                                    await widget.updatedDuration?.call(
                                      _model.updatedDuration!,
                                    );
                                  },
                                ),
                                autofocus: false,
                                obscureText: false,
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelStyle: FlutterFlowTheme.of(context)
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
                                  hintText: FFLocalizations.of(context).getText(
                                    '2q07fxz3' /* 0 */,
                                  ),
                                  hintStyle: FlutterFlowTheme.of(context)
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
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0x00000000),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0x00000000),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                maxLengthEnforcement:
                                    MaxLengthEnforcement.enforced,
                                buildCounter: (context,
                                        {required currentLength,
                                        required isFocused,
                                        maxLength}) =>
                                    null,
                                keyboardType: TextInputType.number,
                                cursorColor:
                                    FlutterFlowTheme.of(context).primaryText,
                                validator: _model
                                    .secondsTensTextControllerValidator
                                    .asValidator(context),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: 200.0,
                              child: TextFormField(
                                controller: _model.secondsUnitsTextController,
                                focusNode: _model.secondsUnitsFocusNode,
                                onChanged: (_) => EasyDebounce.debounce(
                                  '_model.secondsUnitsTextController',
                                  Duration(milliseconds: 0),
                                  () async {
                                    _model.updatedDuration =
                                        functions.getDurationFromTextFields(
                                            _model
                                                .minutesTensTextController.text,
                                            _model.minutesUnitsTextController
                                                .text,
                                            _model
                                                .secondsTensTextController.text,
                                            _model.secondsUnitsTextController
                                                .text);
                                    safeSetState(() {});
                                    await widget.updatedDuration?.call(
                                      _model.updatedDuration!,
                                    );
                                  },
                                ),
                                autofocus: false,
                                obscureText: false,
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelStyle: FlutterFlowTheme.of(context)
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
                                  hintText: FFLocalizations.of(context).getText(
                                    'p9c1dceb' /* 0 */,
                                  ),
                                  hintStyle: FlutterFlowTheme.of(context)
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
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0x00000000),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0x00000000),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                maxLengthEnforcement:
                                    MaxLengthEnforcement.enforced,
                                buildCounter: (context,
                                        {required currentLength,
                                        required isFocused,
                                        maxLength}) =>
                                    null,
                                keyboardType: TextInputType.number,
                                cursorColor:
                                    FlutterFlowTheme.of(context).primaryText,
                                validator: _model
                                    .secondsUnitsTextControllerValidator
                                    .asValidator(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                            Stack(
                              children: [
                                if (!_model.timerOn)
                                  Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: FlutterFlowIconButton(
                                      borderColor: FlutterFlowTheme.of(context)
                                          .secondary,
                                      borderRadius: 30.0,
                                      borderWidth: 1.5,
                                      buttonSize: 30.0,
                                      fillColor: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      icon: Icon(
                                        Icons.play_arrow,
                                        color: FlutterFlowTheme.of(context)
                                            .success,
                                        size: 14.0,
                                      ),
                                      onPressed: () async {
                                        _model.timerOn = true;
                                        safeSetState(() {});
                                        await widget.updatedDuration?.call(
                                          _model.countDownValue!,
                                        );
                                        await showModalBottomSheet(
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          enableDrag: false,
                                          context: context,
                                          builder: (context) {
                                            return Padding(
                                              padding: MediaQuery.viewInsetsOf(
                                                  context),
                                              child: Timer3Widget(
                                                exerciseName:
                                                    widget.exerciseName!,
                                                ms: _model.countDownValue!,
                                                done: () async {
                                                  await widget.done?.call();
                                                  _model.timerOn = false;
                                                  safeSetState(() {});
                                                },
                                              ),
                                            );
                                          },
                                        ).then((value) => safeSetState(() {}));

                                        await actions.scheduleRestNotification(
                                          functions.msToSeconds(_model
                                              .countDownTimerMilliseconds),
                                          false,
                                          widget.exerciseName,
                                        );
                                      },
                                    ),
                                  ),
                                if (_model.timerOn)
                                  Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: FlutterFlowIconButton(
                                      borderColor: FlutterFlowTheme.of(context)
                                          .secondary,
                                      borderRadius: 30.0,
                                      borderWidth: 1.2,
                                      buttonSize: 30.0,
                                      fillColor: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      icon: Icon(
                                        Icons.pause_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .secondary,
                                        size: 14.0,
                                      ),
                                      onPressed: () async {
                                        _model.countDownTimerController
                                            .onStopTimer();
                                        _model.timerOn = false;
                                        safeSetState(() {});
                                        await actions.cancelRestNotification();
                                      },
                                    ),
                                  ),
                              ],
                            ),
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
                                          _model.timeupd =
                                              await actions.updateFlatSetValue(
                                            FFAppState().loggedSets.toList(),
                                            widget.exerciseId!,
                                            widget.setNumber!,
                                            0,
                                            0.0,
                                            _model.updatedDuration,
                                            false,
                                            FFAppState().exercisesets.toList(),
                                          );
                                          FFAppState().loggedSets = _model
                                              .timeupd!
                                              .toList()
                                              .cast<dynamic>();
                                          safeSetState(() {});
                                          _model.countDownTimerController.timer
                                              .setPresetTime(
                                            mSec: ms,
                                            add: false,
                                          );
                                          _model.countDownTimerController
                                              .onResetTimer();

                                          await widget.updatedDuration?.call(
                                            _model.countDownValue!,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ).then((value) => safeSetState(() {}));

                                safeSetState(() {});
                              },
                              child: Container(
                                decoration: BoxDecoration(),
                                child: FlutterFlowTimer(
                                  initialTime: _model.countDownValue!,
                                  getDisplayTime: (value) =>
                                      StopWatchTimer.getDisplayTime(
                                    value,
                                    hours: false,
                                    milliSecond: false,
                                  ),
                                  controller: _model.countDownTimerController,
                                  updateStateInterval:
                                      Duration(milliseconds: 1000),
                                  onChanged:
                                      (value, displayTime, shouldUpdate) {
                                    _model.countDownTimerMilliseconds = value;
                                    _model.countDownTimerValue = displayTime;
                                    if (shouldUpdate) safeSetState(() {});
                                  },
                                  textAlign: TextAlign.start,
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
                        decoration: BoxDecoration(),
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
                                _model.updatedDuration!,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Builder(
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
                        child: ManualWidget(
                          exerciseId: widget.exerciseId!,
                          setNumber: widget.setNumber!,
                          curentMode: _model.timerMode,
                          countDownUpdate: () async {
                            _model.updatedDuration = _model.countDownValue;
                            safeSetState(() {});
                            await widget.updatedDuration?.call(
                              _model.updatedDuration!,
                            );
                          },
                          timerMode: (mode) async {
                            _model.timerMode = mode;
                            _model.timerOn = false;
                            safeSetState(() {});
                            _model.countDownTimerController.timer.setPresetTime(
                              mSec: _model.countDownValue!,
                              add: false,
                            );
                            _model.countDownTimerController.onResetTimer();

                            _model.countDownTimerController.timer
                                .setPresetTime(mSec: 0, add: false);
                            _model.countDownTimerController.onResetTimer();
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
