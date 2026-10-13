import '/backend/sqlite/sqlite_manager.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'sub_muscle_bottom_shit_model.dart';
export 'sub_muscle_bottom_shit_model.dart';

class SubMuscleBottomShitWidget extends StatefulWidget {
  const SubMuscleBottomShitWidget({
    super.key,
    required this.callback,
    required this.selected,
    required this.primaryId,
    this.subMuscleId,
  });

  final Future Function(String selected, int id)? callback;
  final String? selected;
  final int? primaryId;
  final int? subMuscleId;

  @override
  State<SubMuscleBottomShitWidget> createState() =>
      _SubMuscleBottomShitWidgetState();
}

class _SubMuscleBottomShitWidgetState extends State<SubMuscleBottomShitWidget> {
  late SubMuscleBottomShitModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SubMuscleBottomShitModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 445.1,
      height: 550.0,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              height: 32.0,
              decoration: BoxDecoration(),
              child: InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 14.0, 0.0, 10.0),
                      child: InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 40.0,
                          height: 4.0,
                          decoration: BoxDecoration(
                            color: Color(0xFFD6D6D6),
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 25.0, 0.0, 10.0),
              child: Text(
                FFLocalizations.of(context).getText(
                  'ah1oqfbm' /* Choose Muscle group */,
                ),
                style: FlutterFlowTheme.of(context).titleLarge.override(
                      font: GoogleFonts.interTight(
                        fontWeight:
                            FlutterFlowTheme.of(context).titleLarge.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleLarge.fontStyle,
                      ),
                      fontSize: 25.0,
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).titleLarge.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).titleLarge.fontStyle,
                    ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 8.0),
              child: Container(
                width: double.infinity,
                child: TextFormField(
                  controller: _model.textController,
                  focusNode: _model.textFieldFocusNode,
                  autofocus: false,
                  textInputAction: TextInputAction.search,
                  obscureText: false,
                  decoration: InputDecoration(
                    hintText: FFLocalizations.of(context).getText(
                      'wleqw6qg' /* Search Muscle */,
                    ),
                    hintStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).secondaryText,
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).primary,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0x00000000),
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0x00000000),
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    filled: true,
                    fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                    contentPadding:
                        EdgeInsetsDirectional.fromSTEB(20.0, 16.0, 20.0, 16.0),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: FlutterFlowTheme.of(context).secondaryText,
                      size: 20.0,
                    ),
                  ),
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.inter(
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                  cursorColor: FlutterFlowTheme.of(context).primary,
                  validator:
                      _model.textControllerValidator.asValidator(context),
                ),
              ),
            ),
            Container(
              height: 380.0,
              decoration: BoxDecoration(),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    if (functions.shouldShowMuscle(
                        'Chest', _model.textController.text))
                      Divider(
                        height: 0.5,
                        thickness: 1.0,
                        color: FlutterFlowTheme.of(context).alternate,
                      ),
                    FutureBuilder<List<GetSubMuscelsRow>>(
                      future: SQLiteManager.instance.getSubMuscels(
                        primaryId: widget.primaryId!,
                      ),
                      builder: (context, snapshot) {
                        // Customize what your widget looks like when it's loading.
                        if (!snapshot.hasData) {
                          return Center(
                            child: SizedBox(
                              width: 50.0,
                              height: 50.0,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  FlutterFlowTheme.of(context).secondary,
                                ),
                              ),
                            ),
                          );
                        }
                        final listViewGetSubMuscelsRowList = snapshot.data!;

                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          primary: false,
                          shrinkWrap: true,
                          scrollDirection: Axis.vertical,
                          itemCount: listViewGetSubMuscelsRowList.length,
                          itemBuilder: (context, listViewIndex) {
                            final listViewGetSubMuscelsRow =
                                listViewGetSubMuscelsRowList[listViewIndex];
                            return Visibility(
                              visible: functions.shouldShowMuscle(
                                  listViewGetSubMuscelsRow.name,
                                  _model.textController.text),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  await widget.callback?.call(
                                    listViewGetSubMuscelsRow.name,
                                    listViewGetSubMuscelsRow.id,
                                  );
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  width: 400.7,
                                  height: 85.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(5.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 70.0,
                                          height: 70.0,
                                          child:
                                              custom_widgets.ExerciseAssetImage(
                                            width: 70.0,
                                            height: 70.0,
                                            exerciseName:
                                                functions.exerciseImageName(
                                                    listViewGetSubMuscelsRow
                                                        .name),
                                            borderRadius: 8.0,
                                          ),
                                        ),
                                        Expanded(
                                          child: Align(
                                            alignment:
                                                AlignmentDirectional(-1.0, 0.0),
                                            child: Text(
                                              listViewGetSubMuscelsRow.name,
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .titleMedium
                                                  .override(
                                                    font:
                                                        GoogleFonts.interTight(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleMedium
                                                              .fontStyle,
                                                    ),
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.w500,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleMedium
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        if (widget.selected ==
                                            listViewGetSubMuscelsRow.name)
                                          Icon(
                                            Icons.check,
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            size: 24.0,
                                          ),
                                      ].divide(SizedBox(width: 20.0)),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
