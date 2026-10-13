import '/backend/sqlite/sqlite_manager.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'setnew_off_v2_model.dart';
export 'setnew_off_v2_model.dart';

/// Create a component' that shows a specific set- it shold contain set
/// number' reps and weight
///
class SetnewOffV2Widget extends StatefulWidget {
  const SetnewOffV2Widget({
    super.key,
    this.workoutLogExerciseInfo,
    required this.workoutLogId,
  });

  final WorkoutLogExercisesInfoByIdRow? workoutLogExerciseInfo;
  final String? workoutLogId;

  @override
  State<SetnewOffV2Widget> createState() => _SetnewOffV2WidgetState();
}

class _SetnewOffV2WidgetState extends State<SetnewOffV2Widget> {
  late SetnewOffV2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SetnewOffV2Model());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () async {
        _model.open = !(_model.open ?? true);
        safeSetState(() {});
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
        ),
        child: Container(
          width: MediaQuery.sizeOf(context).width * 3.9,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: FlutterFlowTheme.of(context).alternate,
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Container(
                          width: 30.0,
                          height: 30.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).secondary,
                            shape: BoxShape.circle,
                          ),
                          child: Align(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Icon(
                              Icons.check_rounded,
                              color: FlutterFlowTheme.of(context).info,
                              size: 20.0,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              valueOrDefault<String>(
                                widget.workoutLogExerciseInfo?.exerciseName,
                                'Barbell Bent Over Row',
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                            if (!_model.open!)
                              InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  _model.open = true;
                                  safeSetState(() {});
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Text(
                                      '${widget.workoutLogExerciseInfo?.exerciseSetsCount.toString()} Sets',
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                          ),
                                    ),
                                    Icon(
                                      Icons.expand_more,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: 14.0,
                                    ),
                                  ].divide(SizedBox(width: 8.0)),
                                ),
                              ),
                          ],
                        ),
                      ].divide(SizedBox(width: 12.0)),
                    ),
                    if (!_model.open!)
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (widget.workoutLogExerciseInfo
                                  ?.exercisePercentageChange !=
                              null)
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  () {
                                    if (widget.workoutLogExerciseInfo
                                            ?.exercisePercentageChange ==
                                        null) {
                                      return '';
                                    } else if (widget.workoutLogExerciseInfo
                                            ?.exercisePercentageChange ==
                                        0) {
                                      return '';
                                    } else if (widget.workoutLogExerciseInfo!
                                            .exercisePercentageChange! <=
                                        -1) {
                                      return '${widget.workoutLogExerciseInfo?.exercisePercentageChange?.toString()}%';
                                    } else if (widget.workoutLogExerciseInfo!
                                            .exercisePercentageChange! >=
                                        1) {
                                      return '+${widget.workoutLogExerciseInfo?.exercisePercentageChange?.toString()}%';
                                    } else {
                                      return ' ';
                                    }
                                  }(),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: widget.workoutLogExerciseInfo!
                                                    .exercisePercentageChange! <=
                                                0
                                            ? FlutterFlowTheme.of(context)
                                                .secondaryText
                                            : FlutterFlowTheme.of(context)
                                                .success,
                                        fontSize: 13.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                                Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Container(
                                    width: 20.0,
                                    height: 20.0,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                    ),
                                    child: Stack(
                                      children: [
                                        if (widget.workoutLogExerciseInfo!
                                                .exercisePercentageChange! >
                                            0)
                                          Align(
                                            alignment:
                                                AlignmentDirectional(0.0, 0.0),
                                            child: Icon(
                                              Icons.arrow_drop_up,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .success,
                                              size: 20.0,
                                            ),
                                          ),
                                        if (widget.workoutLogExerciseInfo!
                                                .exercisePercentageChange! <=
                                            0)
                                          Align(
                                            alignment:
                                                AlignmentDirectional(0.0, 0.0),
                                            child: Icon(
                                              Icons.arrow_drop_down,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              size: 20.0,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          Text(
                            valueOrDefault<String>(
                              widget.workoutLogExerciseInfo?.exerciseTotal,
                              '-',
                            ),
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_model.open ?? true)
                  Container(
                    width: 312.4,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                    ),
                    child: Visibility(
                      visible: _model.open ?? true,
                      child: FutureBuilder<List<GetSetLogsRow>>(
                        future: SQLiteManager.instance.getSetLogs(
                          workoutLogId: widget.workoutLogId!,
                          exerciseId:
                              widget.workoutLogExerciseInfo!.exerciseId,
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
                          final listViewGetSetLogsRowList = snapshot.data!;

                          return ListView.builder(
                            padding: EdgeInsets.zero,
                            primary: false,
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            itemCount: listViewGetSetLogsRowList.length,
                            itemBuilder: (context, listViewIndex) {
                              final listViewGetSetLogsRow =
                                  listViewGetSetLogsRowList[listViewIndex];
                              return Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 50.0,
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .primaryBackground,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          border: Border.all(
                                            color: FlutterFlowTheme.of(context)
                                                .alternate,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  12.0, 12.0, 12.0, 12.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Set ${listViewGetSetLogsRow.setNumber.toString()}',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Text(
                                                    valueOrDefault<String>(
                                                      listViewGetSetLogsRow.reps ==
                                                              null
                                                          ? functions.formatDurationFromDouble(
                                                              listViewGetSetLogsRow
                                                                  .durationSeconds!
                                                                  .toDouble())
                                                          : '${listViewGetSetLogsRow.reps?.toString()} Reps',
                                                      '12 reps',
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodySmall
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodySmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodySmall
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                  Text(
                                                    valueOrDefault<String>(
                                                      listViewGetSetLogsRow
                                                                  .weight !=
                                                              null
                                                          ? '${formatNumber(
                                                              listViewGetSetLogsRow
                                                                  .weight,
                                                              formatType:
                                                                  FormatType
                                                                      .custom,
                                                              format: '',
                                                              locale: '',
                                                            )} ${FFAppState().isKg ? 'Kg' : 'Lbs'}'
                                                          : 'Bodyweight',
                                                      '800 Kg',
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodySmall
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodySmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodySmall
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ].divide(SizedBox(width: 16.0)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(2.0),
                                        child:
                                            FutureBuilder<List<GetDropSetsRow>>(
                                          future: SQLiteManager.instance
                                              .getDropSets(
                                            workoutLogId: widget.workoutLogId!,
                                            exerciseId: widget
                                                .workoutLogExerciseInfo!
                                                .exerciseId,
                                            setNumber:
                                                listViewGetSetLogsRow.setNumber,
                                          ),
                                          builder: (context, snapshot) {
                                            // Customize what your widget looks like when it's loading.
                                            if (!snapshot.hasData) {
                                              return Center(
                                                child: SizedBox(
                                                  width: 50.0,
                                                  height: 50.0,
                                                  child:
                                                      CircularProgressIndicator(
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                            Color>(
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .secondary,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                            final containerGetDropSetsRowList =
                                                snapshot.data!;

                                            return Container(
                                              decoration: BoxDecoration(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryBackground,
                                              ),
                                              child: Visibility(
                                                visible:
                                                    containerGetDropSetsRowList
                                                        .isNotEmpty,
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Builder(
                                                        builder: (context) {
                                                          final dropset =
                                                              containerGetDropSetsRowList
                                                                  .map((e) => e)
                                                                  .toList();

                                                          return ListView
                                                              .separated(
                                                            padding:
                                                                EdgeInsets.zero,
                                                            primary: false,
                                                            shrinkWrap: true,
                                                            scrollDirection:
                                                                Axis.vertical,
                                                            itemCount:
                                                                dropset.length,
                                                            separatorBuilder: (_,
                                                                    __) =>
                                                                SizedBox(
                                                                    height:
                                                                        10.0),
                                                            itemBuilder: (context,
                                                                dropsetIndex) {
                                                              final dropsetItem =
                                                                  dropset[
                                                                      dropsetIndex];
                                                              return Padding(
                                                                padding: EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        10.0,
                                                                        0.0,
                                                                        10.0,
                                                                        0.0),
                                                                child:
                                                                    Container(
                                                                  height: 46.0,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Color(
                                                                        0xFFF8FAFC),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            12.0),
                                                                    border:
                                                                        Border
                                                                            .all(
                                                                      color: Color(
                                                                          0xFFE6EDF5),
                                                                      width:
                                                                          1.0,
                                                                    ),
                                                                  ),
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                            12.0),
                                                                    child: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children:
                                                                          [
                                                                        Expanded(
                                                                          child:
                                                                              Row(
                                                                            mainAxisSize:
                                                                                MainAxisSize.max,
                                                                            children:
                                                                                [
                                                                              Icon(
                                                                                Icons.subdirectory_arrow_right,
                                                                                color: Color(0xFF64748B),
                                                                                size: 14.0,
                                                                              ),
                                                                              Expanded(
                                                                                child: Text(
                                                                                  'Drop ${dropsetItem.dropNumber.toString()}',
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        font: GoogleFonts.inter(
                                                                                          fontWeight: FontWeight.w500,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                        color: Color(0xFF334155),
                                                                                        fontSize: 14.0,
                                                                                        letterSpacing: 0.0,
                                                                                        fontWeight: FontWeight.w500,
                                                                                        fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                      ),
                                                                                ),
                                                                              ),
                                                                            ].divide(SizedBox(width: 8.0)),
                                                                          ),
                                                                        ),
                                                                        Flexible(
                                                                          child:
                                                                              Text(
                                                                            functions.formatDropSetShort(
                                                                                dropsetItem.reps,
                                                                                dropsetItem.weight,
                                                                                !(dropsetItem.isKg == 1 ? false : true)),
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                                  font: GoogleFonts.inter(
                                                                                    fontWeight: FontWeight.w600,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                  ),
                                                                                  color: Color(0xFF64748B),
                                                                                  fontSize: 13.0,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FontWeight.w600,
                                                                                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                ),
                                                                          ),
                                                                        ),
                                                                      ].divide(SizedBox(
                                                                              width: 8.0)),
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ].divide(SizedBox(height: 10.0)),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                if (_model.open ?? true)
                  InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      _model.open = false;
                      safeSetState(() {});
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.expand_less,
                          color: FlutterFlowTheme.of(context).secondaryText,
                          size: 24.0,
                        ),
                      ],
                    ),
                  ),
              ].divide(SizedBox(height: 12.0)),
            ),
          ),
        ),
      ),
    );
  }
}
