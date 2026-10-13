import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'drop_set_row_edit_model.dart';
export 'drop_set_row_edit_model.dart';

class DropSetRowEditWidget extends StatefulWidget {
  const DropSetRowEditWidget({
    super.key,
    required this.dropNumber,
    required this.exerciseId,
    required this.parentSetNumber,
  });

  final int? dropNumber;
  final int? exerciseId;
  final int? parentSetNumber;

  @override
  State<DropSetRowEditWidget> createState() => _DropSetRowEditWidgetState();
}

class _DropSetRowEditWidgetState extends State<DropSetRowEditWidget> {
  late DropSetRowEditModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DropSetRowEditModel());

    _model.repsTextController ??= TextEditingController(
        text: functions
            .getInitialValueForDropSetField(
                FFAppState().loggedSetsCreation.toList(),
                FFAppState().dropSetsCreation.toList(),
                widget.exerciseId!,
                widget.parentSetNumber!,
                widget.dropNumber,
                'reps')
            ?.toString());
    _model.repsFocusNode ??= FocusNode();

    _model.weightTextController ??= TextEditingController(
        text: functions
            .getInitialValueForDropSetField(
                FFAppState().loggedSetsCreation.toList(),
                FFAppState().dropSetsCreation.toList(),
                widget.exerciseId!,
                widget.parentSetNumber!,
                widget.dropNumber,
                'weight')
            ?.toString());
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

    return Container(
      width: 275.0,
      height: 47.5,
      decoration: BoxDecoration(
        color: functions.isSetDoneOffline(
                FFAppState().loggedSetsCreation.toList(),
                widget.exerciseId!,
                widget.parentSetNumber!)
            ? FlutterFlowTheme.of(context).accent2
            : FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              'Drop ${widget.dropNumber?.toString()}',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).secondaryText,
                    fontSize: 12.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
            ),
          ),
          Expanded(
            child: Container(
              width: 200.0,
              child: TextFormField(
                controller: _model.repsTextController,
                focusNode: _model.repsFocusNode,
                onChanged: (_) => EasyDebounce.debounce(
                  '_model.repsTextController',
                  Duration(milliseconds: 0),
                  () async {
                    _model.repsupd = await actions.updateDropSetValues(
                      FFAppState().dropSetsCreation.toList(),
                      widget.exerciseId!,
                      widget.parentSetNumber!,
                      widget.dropNumber!,
                      int.tryParse(_model.repsTextController.text),
                    );
                    FFAppState().dropSetsCreation =
                        _model.repsupd!.toList().cast<dynamic>();
                    safeSetState(() {});

                    safeSetState(() {});
                  },
                ),
                autofocus: false,
                obscureText: false,
                decoration: InputDecoration(
                  isDense: true,
                  labelStyle: FlutterFlowTheme.of(context).labelMedium.override(
                        font: GoogleFonts.inter(
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontWeight,
                          fontStyle: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).labelMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelMedium.fontStyle,
                      ),
                  hintText: FFLocalizations.of(context).getText(
                    'zejd8gy3' /* 0 */,
                  ),
                  hintStyle: FlutterFlowTheme.of(context).labelMedium.override(
                        font: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontStyle: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontStyle,
                        ),
                        fontSize: 12.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w500,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelMedium.fontStyle,
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
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                      fontSize: 12.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w500,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                cursorColor: FlutterFlowTheme.of(context).primaryText,
                enableInteractiveSelection: true,
                validator:
                    _model.repsTextControllerValidator.asValidator(context),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9]'))
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: 200.0,
              child: TextFormField(
                controller: _model.weightTextController,
                focusNode: _model.weightFocusNode,
                onChanged: (_) => EasyDebounce.debounce(
                  '_model.weightTextController',
                  Duration(milliseconds: 0),
                  () async {
                    _model.weightupd = await actions.updateDropSetValues(
                      FFAppState().dropSetsCreation.toList(),
                      widget.exerciseId!,
                      widget.parentSetNumber!,
                      widget.dropNumber!,
                      int.tryParse(_model.repsTextController.text),
                    );
                    FFAppState().dropSetsCreation =
                        _model.weightupd!.toList().cast<dynamic>();
                    safeSetState(() {});

                    safeSetState(() {});
                  },
                ),
                autofocus: false,
                obscureText: false,
                decoration: InputDecoration(
                  isDense: true,
                  labelStyle: FlutterFlowTheme.of(context).labelMedium.override(
                        font: GoogleFonts.inter(
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontWeight,
                          fontStyle: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).labelMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelMedium.fontStyle,
                      ),
                  hintText: valueOrDefault<String>(
                    functions
                        .getDropHint(
                            FFAppState().loggedSetsCreation.toList(),
                            FFAppState().dropSetsCreation.toList(),
                            widget.exerciseId!,
                            widget.parentSetNumber!,
                            widget.dropNumber!.toString())
                        .toString(),
                    '0',
                  ),
                  hintStyle: FlutterFlowTheme.of(context).labelMedium.override(
                        font: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontStyle: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontStyle,
                        ),
                        fontSize: 12.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w500,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelMedium.fontStyle,
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
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                      fontSize: 12.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w500,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                textAlign: TextAlign.center,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                cursorColor: FlutterFlowTheme.of(context).primaryText,
                enableInteractiveSelection: true,
                validator:
                    _model.weightTextControllerValidator.asValidator(context),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9]'))
                ],
              ),
            ),
          ),
        ]
            .divide(SizedBox(width: 15.0))
            .addToStart(SizedBox(width: 10.0))
            .addToEnd(SizedBox(width: 15.0)),
      ),
    );
  }
}
