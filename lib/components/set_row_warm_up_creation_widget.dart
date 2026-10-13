import '/components/time_warmup_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'set_row_warm_up_creation_model.dart';
export 'set_row_warm_up_creation_model.dart';

class SetRowWarmUpCreationWidget extends StatefulWidget {
  const SetRowWarmUpCreationWidget({
    super.key,
    required this.exerciseId,
    required this.setNumber,
    required this.show,
    required this.isTimed,
    required this.isBodyweightOnly,
    this.exerciseName,
  });

  final int? exerciseId;
  final int? setNumber;
  final Future Function()? show;
  final bool? isTimed;
  final bool? isBodyweightOnly;
  final String? exerciseName;

  @override
  State<SetRowWarmUpCreationWidget> createState() =>
      _SetRowWarmUpCreationWidgetState();
}

class _SetRowWarmUpCreationWidgetState
    extends State<SetRowWarmUpCreationWidget> {
  late SetRowWarmUpCreationModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SetRowWarmUpCreationModel());

    _model.repsTextController ??= TextEditingController();
    _model.repsFocusNode ??= FocusNode();

    _model.weightTextController ??= TextEditingController();
    _model.weightFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Align(
      alignment: AlignmentDirectional(0.0, -1.0),
      child: Container(
        width: 320.0,
        decoration: BoxDecoration(
          color: functions.getSetBackgroundColor(widget.setNumber!,
              Theme.of(context).brightness == Brightness.dark),
          borderRadius: BorderRadius.circular(12.0),
          shape: BoxShape.rectangle,
        ),
        alignment: AlignmentDirectional(0.0, 0.0),
        child: Stack(
          alignment: AlignmentDirectional(0.0, -1.0),
          children: [
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 40.0,
                            height: 40.0,
                            decoration: BoxDecoration(),
                            child: Icon(
                              Icons.local_fire_department_outlined,
                              color: FlutterFlowTheme.of(context).tertiary,
                              size: 24.0,
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: Container(
                          width: 80.0,
                          decoration: BoxDecoration(),
                          child: Text(
                            FFLocalizations.of(context).getText(
                              'g57k0wto' /* - */,
                            ),
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
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
                      ),
                      Expanded(
                        child: Container(
                          width: MediaQuery.sizeOf(context).width * 1.66,
                          height: 50.0,
                          decoration: BoxDecoration(),
                          child: Stack(
                            children: [
                              Align(
                                alignment: AlignmentDirectional(0.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (!widget.isTimed!)
                                      Expanded(
                                        child: Container(
                                          width: 200.0,
                                          child: TextFormField(
                                            controller:
                                                _model.repsTextController,
                                            focusNode: _model.repsFocusNode,
                                            onChanged: (_) =>
                                                EasyDebounce.debounce(
                                              '_model.repsTextController',
                                              Duration(milliseconds: 2000),
                                              () async {
                                                _model.repsud = await actions
                                                    .updateWarmupSetField(
                                                  FFAppState()
                                                      .warmUpCreation
                                                      .toList(),
                                                  widget.exerciseId!,
                                                  widget.setNumber!,
                                                  'reps',
                                                  _model
                                                      .repsTextController.text,
                                                );
                                                FFAppState().warmUpCreation =
                                                    _model.repsud!
                                                        .toList()
                                                        .cast<dynamic>();
                                                safeSetState(() {});

                                                safeSetState(() {});
                                              },
                                            ),
                                            autofocus: false,
                                            obscureText: false,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              labelStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontStyle,
                                                        ),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontStyle,
                                                      ),
                                              hintText:
                                                  functions.getWarmupSetField(
                                                      FFAppState()
                                                          .warmUpCreation
                                                          .toList(),
                                                      widget.exerciseId!,
                                                      widget.setNumber!,
                                                      'reps'),
                                              hintStyle: FlutterFlowTheme.of(
                                                      context)
                                                  .labelMedium
                                                  .override(
                                                    font: GoogleFonts.inter(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .fontStyle,
                                                    ),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryText,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.bold,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelMedium
                                                            .fontStyle,
                                                  ),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Color(0x00000000),
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Color(0x00000000),
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              focusedErrorBorder:
                                                  OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight: FontWeight.bold,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.bold,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                            textAlign: TextAlign.center,
                                            keyboardType: TextInputType.number,
                                            cursorColor:
                                                FlutterFlowTheme.of(context)
                                                    .primaryText,
                                            enableInteractiveSelection: true,
                                            validator: _model
                                                .repsTextControllerValidator
                                                .asValidator(context),
                                          ),
                                        ),
                                      ),
                                    if (!widget.isTimed!)
                                      Expanded(
                                        child: Container(
                                          width: 200.0,
                                          decoration: BoxDecoration(),
                                          child: Stack(
                                            alignment:
                                                AlignmentDirectional(0.0, 0.0),
                                            children: [
                                              if (!widget.isBodyweightOnly!)
                                                Container(
                                                  width: 200.0,
                                                  child: TextFormField(
                                                    controller: _model
                                                        .weightTextController,
                                                    focusNode:
                                                        _model.weightFocusNode,
                                                    onChanged: (_) =>
                                                        EasyDebounce.debounce(
                                                      '_model.weightTextController',
                                                      Duration(
                                                          milliseconds: 2000),
                                                      () async {
                                                        _model.weightUpdate =
                                                            await actions
                                                                .updateWarmupSetField(
                                                          FFAppState()
                                                              .warmUpCreation
                                                              .toList(),
                                                          widget.exerciseId!,
                                                          widget.setNumber!,
                                                          'weight',
                                                          _model
                                                              .weightTextController
                                                              .text,
                                                        );
                                                        FFAppState()
                                                                .warmUpCreation =
                                                            _model.weightUpdate!
                                                                .toList()
                                                                .cast<
                                                                    dynamic>();
                                                        safeSetState(() {});

                                                        safeSetState(() {});
                                                      },
                                                    ),
                                                    autofocus: false,
                                                    obscureText: false,
                                                    decoration: InputDecoration(
                                                      isDense: true,
                                                      labelStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                ),
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontStyle,
                                                              ),
                                                      hintText: functions
                                                          .getWarmupSetField(
                                                              FFAppState()
                                                                  .warmUpCreation
                                                                  .toList(),
                                                              widget
                                                                  .exerciseId!,
                                                              widget
                                                                  .setNumber!,
                                                              'weight'),
                                                      hintStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryText,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontStyle,
                                                              ),
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color:
                                                              Color(0x00000000),
                                                          width: 1.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color:
                                                              Color(0x00000000),
                                                          width: 1.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      errorBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .error,
                                                          width: 1.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      focusedErrorBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .error,
                                                          width: 1.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primaryText,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                    textAlign: TextAlign.center,
                                                    keyboardType:
                                                        const TextInputType
                                                            .numberWithOptions(
                                                            decimal: true),
                                                    cursorColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primaryText,
                                                    enableInteractiveSelection:
                                                        true,
                                                    validator: _model
                                                        .weightTextControllerValidator
                                                        .asValidator(context),
                                                  ),
                                                ),
                                              if (widget.isBodyweightOnly ??
                                                  true)
                                                Align(
                                                  alignment:
                                                      AlignmentDirectional(
                                                          0.0, 0.0),
                                                  child: Text(
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                      '4vdz6ylw' /* - */,
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ].divide(SizedBox(width: 15.0)),
                                ),
                              ),
                              if (widget.isTimed ?? true)
                                Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Builder(
                                    builder: (context) => wrapWithModel(
                                      model: _model.timeWarmupModel,
                                      updateCallback: () => safeSetState(() {}),
                                      child: TimeWarmupWidget(
                                        exerciseId: widget.exerciseId!,
                                        setNumber: widget.setNumber,
                                        exerciseName: widget.exerciseName,
                                        done: () async {},
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ].divide(SizedBox(width: 6.0)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
