import '/components/deop_set_row_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'drop_set_model.dart';
export 'drop_set_model.dart';

class DropSetWidget extends StatefulWidget {
  const DropSetWidget({
    super.key,
    required this.exerciseId,
    required this.setNumber,
    required this.allowsBodyweight,
  });

  final int? exerciseId;
  final int? setNumber;
  final bool? allowsBodyweight;

  @override
  State<DropSetWidget> createState() => _DropSetWidgetState();
}

class _DropSetWidgetState extends State<DropSetWidget> {
  late DropSetModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DropSetModel());
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
      width: MediaQuery.sizeOf(context).width * 1.0,
      decoration: BoxDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 0.0),
            child: Builder(
              builder: (context) {
                final dropList = functions
                    .getDropRowsForSet(FFAppState().dropSets.toList(),
                        widget.exerciseId!, widget.setNumber!)
                    .toList();

                return ListView.separated(
                  padding: EdgeInsets.zero,
                  primary: false,
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  itemCount: dropList.length,
                  separatorBuilder: (_, __) => SizedBox(height: 7.0),
                  itemBuilder: (context, dropListIndex) {
                    final dropListItem = dropList[dropListIndex];
                    return Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Stack(
                          children: [
                            if (functions.canShowDeleteDropButton(
                                    FFAppState().dropSets.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!) &&
                                !functions.isSetDoneOffline(
                                    FFAppState().loggedSets.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!))
                              FlutterFlowIconButton(
                                borderRadius: 8.0,
                                buttonSize: 35.0,
                                icon: Icon(
                                  Icons.delete_outline_outlined,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 20.0,
                                ),
                                onPressed: () async {
                                  _model.deleteDrop = await actions
                                      .removeDropRowForParentByLabel(
                                    FFAppState().dropSets.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!,
                                    getJsonField(
                                      dropListItem,
                                      r'''$["label"]''',
                                    ).toString(),
                                  );
                                  _model.removeFromLogged = await actions
                                      .removeDropSetFromLoggedSetsAction(
                                    FFAppState().loggedSets.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!,
                                    getJsonField(
                                      dropListItem,
                                      r'''$["dropOrder"]''',
                                    ),
                                  );
                                  FFAppState().dropSets = _model.deleteDrop!
                                      .toList()
                                      .cast<dynamic>();
                                  FFAppState().loggedSets = _model
                                      .removeFromLogged!
                                      .toList()
                                      .cast<dynamic>();
                                  safeSetState(() {});

                                  safeSetState(() {});
                                },
                              ),
                            if (!(functions.canShowDeleteDropButton(
                                    FFAppState().dropSets.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!) &&
                                !functions.isSetDoneOffline(
                                    FFAppState().loggedSets.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!)))
                              Container(
                                width: 35.0,
                                height: 35.0,
                                decoration: BoxDecoration(),
                              ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              5.0, 0.0, 0.0, 0.0),
                          child: wrapWithModel(
                            model: _model.deopSetRowModels.getModel(
                              '${getJsonField(
                                dropListItem,
                                r'''$["label"]''',
                              ).toString()}${widget.exerciseId?.toString()}${widget.setNumber?.toString()}',
                              dropListIndex,
                            ),
                            updateCallback: () => safeSetState(() {}),
                            child: DeopSetRowWidget(
                              key: Key(
                                'Key97q_${'${getJsonField(
                                  dropListItem,
                                  r'''$["label"]''',
                                ).toString()}${widget.exerciseId?.toString()}${widget.setNumber?.toString()}'}',
                              ),
                              dropNumber: getJsonField(
                                dropListItem,
                                r'''$["dropOrder"]''',
                              ),
                              exerciseId: widget.exerciseId!,
                              parentSetNumber: widget.setNumber!,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (!functions.isSetDoneOffline(FFAppState().loggedSets.toList(),
              widget.exerciseId!, widget.setNumber!))
            FFButtonWidget(
              onPressed: () async {
                _model.addDrop2 = await actions.addNextDropRow(
                  FFAppState().dropSets.toList(),
                  widget.exerciseId!,
                  widget.setNumber!,
                );
                FFAppState().dropSets =
                    _model.addDrop2!.toList().cast<dynamic>();
                safeSetState(() {});

                safeSetState(() {});
              },
              text: FFLocalizations.of(context).getText(
                '46454wwc' /* Drop */,
              ),
              icon: Icon(
                Icons.add,
                size: 15.0,
              ),
              options: FFButtonOptions(
                height: 30.0,
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                color: FlutterFlowTheme.of(context).primaryBackground,
                textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                      font: GoogleFonts.interTight(
                        fontWeight:
                            FlutterFlowTheme.of(context).titleSmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleSmall.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).secondary,
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).titleSmall.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).titleSmall.fontStyle,
                    ),
                elevation: 0.0,
                borderSide: BorderSide(
                  color: FlutterFlowTheme.of(context).secondary,
                ),
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
        ].divide(SizedBox(height: 10.0)),
      ),
    );
  }
}
