import '/components/drop_set_row_edit_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'drop_set_creation_model.dart';
export 'drop_set_creation_model.dart';

class DropSetCreationWidget extends StatefulWidget {
  const DropSetCreationWidget({
    super.key,
    required this.exerciseId,
    required this.setNumber,
    required this.allowsBodyweight,
  });

  final int? exerciseId;
  final int? setNumber;
  final bool? allowsBodyweight;

  @override
  State<DropSetCreationWidget> createState() => _DropSetCreationWidgetState();
}

class _DropSetCreationWidgetState extends State<DropSetCreationWidget> {
  late DropSetCreationModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DropSetCreationModel());
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
                    .getDropRowsForSet(FFAppState().dropSetsCreation.toList(),
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
                            Container(
                              width: 35.0,
                              height: 35.0,
                              decoration: BoxDecoration(),
                            ),
                            if (functions.canShowDeleteDropButton(
                                FFAppState().dropSetsCreation.toList(),
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
                                    FFAppState().dropSetsCreation.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!,
                                    getJsonField(
                                      dropListItem,
                                      r'''$["label"]''',
                                    ).toString(),
                                  );
                                  _model.removeFromLogged = await actions
                                      .removeDropSetFromLoggedSetsAction(
                                    FFAppState().loggedSetsCreation.toList(),
                                    widget.exerciseId!,
                                    widget.setNumber!,
                                    getJsonField(
                                      dropListItem,
                                      r'''$["dropOrder"]''',
                                    ),
                                  );
                                  FFAppState().dropSetsCreation = _model
                                      .deleteDrop!
                                      .toList()
                                      .cast<dynamic>();
                                  FFAppState().loggedSetsCreation = _model
                                      .removeFromLogged!
                                      .toList()
                                      .cast<dynamic>();
                                  safeSetState(() {});

                                  safeSetState(() {});
                                },
                              ),
                          ],
                        ),
                        DropSetRowEditWidget(
                          key: Key(
                              'Keyc3r_${dropListIndex}_of_${dropList.length}'),
                          parentSetNumber: widget.setNumber!,
                          dropNumber: getJsonField(
                            dropListItem,
                            r'''$["dropOrder"]''',
                          ),
                          exerciseId: widget.exerciseId!,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (!functions.isSetDoneOffline(
              FFAppState().loggedSetsCreation.toList(),
              widget.exerciseId!,
              widget.setNumber!))
            FFButtonWidget(
              onPressed: () async {
                _model.addDrop = await actions.addNextDropRow(
                  FFAppState().dropSetsCreation.toList(),
                  widget.exerciseId!,
                  widget.setNumber!,
                );
                FFAppState().dropSetsCreation =
                    _model.addDrop!.toList().cast<dynamic>();
                safeSetState(() {});

                safeSetState(() {});
              },
              text: FFLocalizations.of(context).getText(
                '7tx24w02' /* Drop */,
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
