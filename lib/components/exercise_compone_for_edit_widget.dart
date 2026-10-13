import '/backend/sqlite/sqlite_manager.dart';
import '/components/exercise_options_bottom_worklog_edit_widget.dart';
import '/components/set_row_edit_widget.dart';
import '/components/set_row_warm_up_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'exercise_compone_for_edit_model.dart';
export 'exercise_compone_for_edit_model.dart';

class ExerciseComponeForEditWidget extends StatefulWidget {
  const ExerciseComponeForEditWidget({
    super.key,
    required this.exerciseId,
  });

  final int? exerciseId;

  @override
  State<ExerciseComponeForEditWidget> createState() =>
      _ExerciseComponeForEditWidgetState();
}

class _ExerciseComponeForEditWidgetState
    extends State<ExerciseComponeForEditWidget> {
  late ExerciseComponeForEditModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ExerciseComponeForEditModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return FutureBuilder<List<Exercise2Row>>(
      future: SQLiteManager.instance.exercise2(
        exerciseId: widget.exerciseId!,
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
        final containerExercise2RowList = snapshot.data!;

        return Container(
          decoration: BoxDecoration(
            color: _model.complete
                ? FlutterFlowTheme.of(context).accent2
                : FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: FlutterFlowTheme.of(context).alternate,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (functions.isExerciseSuperset(
                                    FFAppState().exercisesets.toList(),
                                    widget.exerciseId!))
                                  Container(
                                    width: 95.0,
                                    height: 35.0,
                                    decoration: BoxDecoration(
                                      color: Color(0x8614B8A6),
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(5.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            FFLocalizations.of(context).getText(
                                              'll11uggv' /* Superset */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w500,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w500,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                          ),
                                        ].divide(SizedBox(width: 5.0)),
                                      ),
                                    ),
                                  ),
                                Container(
                                  width: MediaQuery.sizeOf(context).width * 1.0,
                                  height: 45.0,
                                  child: custom_widgets.ExerciseHeaderButton(
                                    width:
                                        MediaQuery.sizeOf(context).width * 1.0,
                                    height: 45.0,
                                    exerciseName: containerExercise2RowList
                                        .firstOrNull!.name,
                                    illustration: containerExercise2RowList
                                        .firstOrNull?.illustration,
                                    imageSize: 45.0,
                                    imageRadius: 8.0,
                                    gap: 12.0,
                                    textColor: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    fontSize: 16.0,
                                    maxLines: 1,
                                    onTap: () async {
                                      if (containerExercise2RowList
                                              .firstOrNull?.isPublic ==
                                          1) {
                                        context.pushNamed(
                                          ExerciseHistoryWidget.routeName,
                                          queryParameters: {
                                            'exerciseId': serializeParam(
                                              widget.exerciseId,
                                              ParamType.int,
                                            ),
                                            'overview': serializeParam(
                                              true,
                                              ParamType.bool,
                                            ),
                                            'analytics': serializeParam(
                                              false,
                                              ParamType.bool,
                                            ),
                                          }.withoutNulls,
                                        );
                                      } else {
                                        context.pushNamed(
                                          ExerciseHistoryCustomWidget.routeName,
                                          queryParameters: {
                                            'exerciseId': serializeParam(
                                              widget.exerciseId,
                                              ParamType.int,
                                            ),
                                            'overview': serializeParam(
                                              true,
                                              ParamType.bool,
                                            ),
                                            'analytics': serializeParam(
                                              false,
                                              ParamType.bool,
                                            ),
                                          }.withoutNulls,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ].divide(SizedBox(height: 6.0)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_model.complete)
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              FlutterFlowIconButton(
                                borderColor: Colors.transparent,
                                borderRadius: 18.0,
                                borderWidth: 1.0,
                                buttonSize: 36.0,
                                fillColor: FlutterFlowTheme.of(context).success,
                                icon: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18.0,
                                ),
                                onPressed: () async {
                                  _model.completExercise =
                                      await actions.markExerciseCompleted(
                                    FFAppState().exerciseSetsCretion.toList(),
                                    FFAppState().loggedSetsCreation.toList(),
                                    widget.exerciseId!,
                                  );
                                  FFAppState().loggedSetsCreation = _model
                                      .completExercise!
                                      .toList()
                                      .cast<dynamic>();
                                  safeSetState(() {});
                                  HapticFeedback.mediumImpact();
                                  _model.complete = true;
                                  safeSetState(() {});

                                  safeSetState(() {});
                                },
                              ),
                              FlutterFlowIconButton(
                                borderColor:
                                    FlutterFlowTheme.of(context).alternate,
                                borderRadius: 18.0,
                                borderWidth: 1.0,
                                buttonSize: 36.0,
                                fillColor: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                icon: Icon(
                                  Icons.more_vert,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 18.0,
                                ),
                                onPressed: () async {
                                  await showModalBottomSheet(
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    enableDrag: false,
                                    context: context,
                                    builder: (context) {
                                      return Padding(
                                        padding:
                                            MediaQuery.viewInsetsOf(context),
                                        child:
                                            ExerciseOptionsBottomWorklogEditWidget(
                                          exerciseId: widget.exerciseId!,
                                          exerciseName:
                                              containerExercise2RowList
                                                  .firstOrNull?.name,
                                          exerciseEquipment:
                                              containerExercise2RowList
                                                  .firstOrNull?.equipment,
                                        ),
                                      );
                                    },
                                  ).then((value) => safeSetState(() {}));
                                },
                              ),
                            ].divide(SizedBox(height: 5.0)),
                          ),
                        ].divide(SizedBox(width: 8.0)),
                      ),
                    if (_model.complete)
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onLongPress: () async {
                          _model.complete = false;
                          safeSetState(() {});
                        },
                        child: FlutterFlowIconButton(
                          borderColor:
                              FlutterFlowTheme.of(context).secondaryText,
                          borderRadius: 18.0,
                          borderWidth: 1.0,
                          buttonSize: 36.0,
                          fillColor:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          icon: Icon(
                            Icons.remove_done_sharp,
                            color: FlutterFlowTheme.of(context).secondaryText,
                            size: 18.0,
                          ),
                          onPressed: () {
                            print('IconButton pressed ...');
                          },
                        ),
                      ),
                  ],
                ),
                if (!_model.complete)
                  Container(
                    decoration: BoxDecoration(),
                    child: Visibility(
                      visible: true,
                      child: Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 0.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 10.0, 0.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40.0,
                                    height: 35.0,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Align(
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: Container(
                                        width: 80.0,
                                        decoration: BoxDecoration(),
                                        child: Text(
                                          FFLocalizations.of(context).getText(
                                            '6i971pli' /* Previous */,
                                          ),
                                          textAlign: TextAlign.center,
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.inter(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (containerExercise2RowList
                                          .firstOrNull?.isTimeBased ==
                                      1)
                                    Expanded(
                                      flex: 2,
                                      child: Align(
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  1.0, 0.0, 0.0, 0.0),
                                          child: Container(
                                            width: 160.0,
                                            height: 50.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                            ),
                                            child: Align(
                                              alignment: AlignmentDirectional(
                                                  0.0, 0.0),
                                              child: Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'et510nqa' /* Time */,
                                                ),
                                                textAlign: TextAlign.center,
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (containerExercise2RowList
                                          .firstOrNull?.isTimeBased ==
                                      0)
                                    Align(
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 0.0, 10.0, 0.0),
                                        child: Container(
                                          width: 80.0,
                                          decoration: BoxDecoration(),
                                          child: Align(
                                            alignment:
                                                AlignmentDirectional(0.0, 0.0),
                                            child: Padding(
                                              padding: EdgeInsets.all(5.0),
                                              child: Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'kelb741f' /* Reps */,
                                                ),
                                                textAlign: TextAlign.center,
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (containerExercise2RowList
                                          .firstOrNull?.isTimeBased ==
                                      0)
                                    Expanded(
                                      flex: 1,
                                      child: Align(
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0),
                                        child: Container(
                                          width: 80.0,
                                          height: 50.0,
                                          decoration: BoxDecoration(),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Align(
                                                alignment: AlignmentDirectional(
                                                    0.0, 0.0),
                                                child: Padding(
                                                  padding: EdgeInsets.all(5.0),
                                                  child: Text(
                                                    'Weight',
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                FFAppState().isKg
                                                    ? '(Kg)'
                                                    : '(Lbs)',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .labelSmall
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .fontStyle,
                                                          ),
                                                          fontSize: 10.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontStyle,
                                                        ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (containerExercise2RowList
                                          .firstOrNull?.aiFormAnalysis ==
                                      1)
                                    Container(
                                      width: 35.0,
                                      height: 35.0,
                                      decoration: BoxDecoration(),
                                    ),
                                ].divide(SizedBox(width: 6.0)),
                              ),
                            ),
                            if (_model.showWormUp)
                              Container(
                                width: MediaQuery.sizeOf(context).width * 1.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                ),
                                child: Builder(
                                  builder: (context) {
                                    final warmupSet = functions
                                        .formatWarmupSets(
                                            FFAppState().warmupSets.toList(),
                                            widget.exerciseId!)
                                        .toList();

                                    return ListView.separated(
                                      padding: EdgeInsets.zero,
                                      primary: false,
                                      shrinkWrap: true,
                                      scrollDirection: Axis.vertical,
                                      itemCount: warmupSet.length,
                                      separatorBuilder: (_, __) =>
                                          SizedBox(height: 8.0),
                                      itemBuilder: (context, warmupSetIndex) {
                                        final warmupSetItem =
                                            warmupSet[warmupSetIndex];
                                        return SetRowWarmUpWidget(
                                          key: Key(
                                              'Keyokf_${warmupSetIndex}_of_${warmupSet.length}'),
                                          exerciseId: widget.exerciseId!,
                                          weight: getJsonField(
                                            warmupSetItem,
                                            r'''$["weight"]''',
                                          ).toString(),
                                          reps: getJsonField(
                                            warmupSetItem,
                                            r'''$["repsText"]''',
                                          ).toString(),
                                          setNumber: getJsonField(
                                            warmupSetItem,
                                            r'''$["setNumber"]''',
                                          ),
                                          isTimed: true,
                                          isBodyweightOnly: true,
                                          show: () async {
                                            _model.showWormUp = false;
                                            safeSetState(() {});
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            Builder(
                              builder: (context) {
                                final setList = functions
                                    .getSetsForEditWorkout(
                                        widget.exerciseId!,
                                        FFAppState()
                                            .exerciseSetsCretion
                                            .toList())
                                    .toList();

                                return ListView.separated(
                                  padding: EdgeInsets.zero,
                                  primary: false,
                                  shrinkWrap: true,
                                  scrollDirection: Axis.vertical,
                                  itemCount: setList.length,
                                  separatorBuilder: (_, __) =>
                                      SizedBox(height: 8.0),
                                  itemBuilder: (context, setListIndex) {
                                    final setListItem = setList[setListIndex];
                                    return wrapWithModel(
                                      model: _model.setRowEditModels.getModel(
                                        '${widget.exerciseId?.toString()}${getJsonField(
                                          setListItem,
                                          r'''$["setNumber"]''',
                                        ).toString()}',
                                        setListIndex,
                                      ),
                                      updateCallback: () => safeSetState(() {}),
                                      child: SetRowEditWidget(
                                        key: Key(
                                          'Keye5x_${'${widget.exerciseId?.toString()}${getJsonField(
                                            setListItem,
                                            r'''$["setNumber"]''',
                                          ).toString()}'}',
                                        ),
                                        setNumber: getJsonField(
                                          setListItem,
                                          r'''$["setNumber"]''',
                                        ),
                                        timed: !(containerExercise2RowList
                                                    .firstOrNull?.isTimeBased ==
                                                1
                                            ? false
                                            : true),
                                        exerciseId: widget.exerciseId!,
                                        bodyweight: !(containerExercise2RowList
                                                    .firstOrNull
                                                    ?.isBodyweight ==
                                                1
                                            ? false
                                            : true),
                                        reps: getJsonField(
                                          setListItem,
                                          r'''$["reps"]''',
                                        ),
                                        weight: getJsonField(
                                          setListItem,
                                          r'''$["weight"]''',
                                        ),
                                        allowsBodyweight:
                                            containerExercise2RowList
                                                        .firstOrNull
                                                        ?.allowsBodyweight ==
                                                    1
                                                ? true
                                                : false,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 20.0, 0.0, 10.0),
                              child: FFButtonWidget(
                                onPressed: () async {
                                  HapticFeedback.selectionClick();
                                  _model.addSet =
                                      await actions.addSetToExercise(
                                    FFAppState().exerciseSetsCretion.toList(),
                                    widget.exerciseId!,
                                    containerExercise2RowList
                                                .firstOrNull?.isBodyweight ==
                                            1
                                        ? true
                                        : false,
                                  );
                                  FFAppState().exerciseSetsCretion =
                                      _model.addSet!.toList().cast<dynamic>();
                                  safeSetState(() {});

                                  safeSetState(() {});
                                },
                                text: FFLocalizations.of(context).getText(
                                  'uu87sx0m' /* Add set */,
                                ),
                                icon: Icon(
                                  Icons.add,
                                  size: 15.0,
                                ),
                                options: FFButtonOptions(
                                  width:
                                      MediaQuery.sizeOf(context).width * 0.329,
                                  height: 35.8,
                                  padding: EdgeInsets.all(10.0),
                                  iconAlignment: IconAlignment.start,
                                  iconPadding: EdgeInsets.all(0.0),
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  textStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        font: GoogleFonts.interTight(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        fontSize: 18.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontStyle,
                                      ),
                                  elevation: 0.0,
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).primary,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                            ),
                            Container(
                              width: MediaQuery.sizeOf(context).width * 1.0,
                              decoration: BoxDecoration(),
                            ),
                            Container(
                              width: MediaQuery.sizeOf(context).width * 1.0,
                              decoration: BoxDecoration(),
                            ),
                          ].divide(SizedBox(height: 5.0)),
                        ),
                      ),
                    ),
                  ),
              ].divide(SizedBox(height: 20.0)),
            ),
          ),
        );
      },
    );
  }
}
