import '/backend/sqlite/sqlite_manager.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'row_offline_model.dart';
export 'row_offline_model.dart';

class RowOfflineWidget extends StatefulWidget {
  const RowOfflineWidget({
    super.key,
    this.data,
    this.index,
  });

  final ExerciseSessionComparisomRow? data;
  final int? index;

  @override
  State<RowOfflineWidget> createState() => _RowOfflineWidgetState();
}

class _RowOfflineWidgetState extends State<RowOfflineWidget> {
  late RowOfflineModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RowOfflineModel());
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
      height: 150.0,
      decoration: BoxDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 1,
            child: Container(
              width: 73.0,
              height: 150.0,
              decoration: BoxDecoration(),
              child: Padding(
                padding: EdgeInsets.all(3.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      FFLocalizations.of(context).getText(
                        '9ftmeg29' /* Sets */,
                      ),
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).secondaryText,
                            fontSize: 12.0,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                    ),
                    Text(
                      valueOrDefault<String>(
                        widget.data?.totalSets.toString(),
                        '4',
                      ),
                      textAlign: TextAlign.center,
                      style:
                          FlutterFlowTheme.of(context).headlineSmall.override(
                                font: GoogleFonts.interTight(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .fontStyle,
                                ),
                                fontSize: 22.0,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .headlineSmall
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .headlineSmall
                                    .fontStyle,
                              ),
                    ),
                    if (widget.data?.setsDiffPercent != null)
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            valueOrDefault<String>(
                              widget.data?.setsDiffAbsDisplay,
                              '-',
                            ),
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: valueOrDefault<Color>(
                                    valueOrDefault<double>(
                                              widget.data?.setsDiffPercent,
                                              4.0,
                                            ) <=
                                            0.0
                                        ? FlutterFlowTheme.of(context)
                                            .secondaryText
                                        : Color(0xFF007A5E),
                                    FlutterFlowTheme.of(context).secondary,
                                  ),
                                  fontSize: 12.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                          ),
                          Stack(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            children: [
                              if (widget.data!.setsDiffPercent! > 0.0)
                                Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Icon(
                                    Icons.arrow_drop_up,
                                    color: Color(0xFF007A5E),
                                    size: 20.0,
                                  ),
                                ),
                              if (widget.data!.setsDiffPercent! < 0.0)
                                Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Icon(
                                    Icons.arrow_drop_down,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    size: 20.0,
                                  ),
                                ),
                              if (widget.data?.setsDiffPercent == 0.0)
                                Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Text(
                                    FFLocalizations.of(context).getText(
                                      'kp3q0g57' /* - */,
                                    ),
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
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    Align(
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: LinearPercentIndicator(
                        percent: 1.0,
                        lineHeight: 12.0,
                        animation: true,
                        animateFromLastPercent: true,
                        progressColor: Color(0xFF5BC0EB),
                        backgroundColor:
                            FlutterFlowTheme.of(context).secondaryBackground,
                        barRadius: Radius.circular(40.0),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    if (widget.data?.setsDiffPercent != null)
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            valueOrDefault<String>(
                              widget.data?.setsDiffPercentDisplay,
                              '-',
                            ),
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: valueOrDefault<Color>(
                                    valueOrDefault<double>(
                                              widget.data?.setsDiffPercent,
                                              4.0,
                                            ) <=
                                            0.0
                                        ? FlutterFlowTheme.of(context)
                                            .secondaryText
                                        : Color(0xFF007A5E),
                                    FlutterFlowTheme.of(context).secondary,
                                  ),
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                          ),
                          Text(
                            FFLocalizations.of(context).getText(
                              'dwno1x40' /* % */,
                            ),
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: valueOrDefault<Color>(
                                    valueOrDefault<double>(
                                              widget.data?.setsDiffPercent,
                                              4.0,
                                            ) <=
                                            0.0
                                        ? FlutterFlowTheme.of(context)
                                            .secondaryText
                                        : Color(0xFF007A5E),
                                    FlutterFlowTheme.of(context).secondary,
                                  ),
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                          ),
                        ].divide(SizedBox(width: 3.0)),
                      ),
                  ].divide(SizedBox(height: 2.0)),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(),
          ),
          Container(
            decoration: BoxDecoration(),
          ),
          Container(
            decoration: BoxDecoration(),
          ),
          if (widget.data?.isHybridVolumeComparison == 0)
            SizedBox(
              height: 100.0,
              child: VerticalDivider(
                thickness: 2.0,
                color: FlutterFlowTheme.of(context).alternate,
              ),
            ),
          if (widget.data?.isHybridVolumeComparison == 0)
            Expanded(
              flex: 1,
              child: Container(
                width: 73.0,
                height: 150.0,
                decoration: BoxDecoration(),
                child: Padding(
                  padding: EdgeInsets.all(3.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        FFLocalizations.of(context).getText(
                          'ojfjmqk7' /* Volume */,
                        ),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).secondaryText,
                              fontSize: 12.0,
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            valueOrDefault<String>(
                              () {
                                if ((widget.data?.isBodyweightOnly == 1) &&
                                    (widget.data?.isTimeBased == 0)) {
                                  return widget.data?.volumeDiffPercent
                                      ?.toString();
                                } else if ((widget.data?.isBodyweightOnly ==
                                        1) &&
                                    (widget.data?.isTimeBased == 1)) {
                                  return functions.formatDurationFromDouble(
                                      widget.data!.totalVolume);
                                } else {
                                  return functions
                                      .formatDouble(widget.data!.totalVolume);
                                }
                              }(),
                              '-',
                            ),
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .headlineSmall
                                .override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .fontStyle,
                                  ),
                                  fontSize: 22.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .fontStyle,
                                ),
                          ),
                          Text(
                            () {
                              if ((widget.data?.isBodyweightOnly == 1) &&
                                  (widget.data?.isTimeBased == 0)) {
                                return '%';
                              } else if (widget.data?.isTimeBased == 1) {
                                return '';
                              } else if (widget.data?.isKg == 1) {
                                return 'Kg';
                              } else {
                                return 'Lbs';
                              }
                            }(),
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
                                  fontSize: 10.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                          ),
                        ].divide(SizedBox(width: 3.0)),
                      ),
                      if (widget.data?.volumeDiffPercent != null)
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              valueOrDefault<String>(
                                widget.data?.volumeDiffAbsDisplay,
                                '-',
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: valueOrDefault<Color>(
                                      valueOrDefault<double>(
                                                widget.data?.volumeDiffPercent,
                                                4.0,
                                              ) <=
                                              0.0
                                          ? FlutterFlowTheme.of(context)
                                              .secondaryText
                                          : Color(0xFF007A5E),
                                      FlutterFlowTheme.of(context).secondary,
                                    ),
                                    fontSize: 12.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                            Stack(
                              alignment: AlignmentDirectional(0.0, 0.0),
                              children: [
                                if (widget.data!.volumeDiffPercent! > 0.0)
                                  Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Icon(
                                      Icons.arrow_drop_up,
                                      color: Color(0xFF007A5E),
                                      size: 20.0,
                                    ),
                                  ),
                                if (widget.data!.volumeDiffPercent! < 0.0)
                                  Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Icon(
                                      Icons.arrow_drop_down,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: 20.0,
                                    ),
                                  ),
                                if (widget.data?.volumeDiffPercent == 0.0)
                                  Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Text(
                                      FFLocalizations.of(context).getText(
                                        'nn0xmhvt' /* - */,
                                      ),
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
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      Align(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: LinearPercentIndicator(
                          percent: 1.0,
                          lineHeight: 12.0,
                          animation: true,
                          animateFromLastPercent: true,
                          progressColor: Color(0xFF00C896),
                          backgroundColor:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          barRadius: Radius.circular(40.0),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      if (widget.data?.volumeDiffPercent != null)
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              valueOrDefault<String>(
                                (widget.data?.isBodyweightOnly == 1) &&
                                        (widget.data?.isTimeBased == 0)
                                    ? widget.data?.totalVolumeDisplay
                                    : valueOrDefault<String>(
                                        widget.data?.volumeDiffPercentDisplay,
                                        '-',
                                      ),
                                '-',
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: valueOrDefault<Color>(
                                      valueOrDefault<double>(
                                                widget.data?.volumeDiffPercent,
                                                4.0,
                                              ) <=
                                              0.0
                                          ? FlutterFlowTheme.of(context)
                                              .secondaryText
                                          : Color(0xFF007A5E),
                                      FlutterFlowTheme.of(context).secondary,
                                    ),
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                            Text(
                              valueOrDefault<String>(
                                (widget.data?.isBodyweightOnly == 1) &&
                                        (widget.data?.isTimeBased == 0)
                                    ? 'Reps'
                                    : '%',
                                '%',
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: valueOrDefault<Color>(
                                      valueOrDefault<double>(
                                                widget.data?.volumeDiffPercent,
                                                4.0,
                                              ) <=
                                              0.0
                                          ? FlutterFlowTheme.of(context)
                                              .secondaryText
                                          : Color(0xFF007A5E),
                                      FlutterFlowTheme.of(context).secondary,
                                    ),
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                          ].divide(SizedBox(width: 3.0)),
                        ),
                    ].divide(SizedBox(height: 2.0)),
                  ),
                ),
              ),
            ),
          SizedBox(
            height: 100.0,
            child: VerticalDivider(
              thickness: 2.0,
              color: FlutterFlowTheme.of(context).alternate,
            ),
          ),
          if (widget.data?.isTimeBased == 0)
            Expanded(
              flex: 1,
              child: Container(
                width: 73.0,
                height: 150.0,
                decoration: BoxDecoration(),
                child: Padding(
                  padding: EdgeInsets.all(3.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        FFLocalizations.of(context).getText(
                          'p3wq9jo6' /* Reps */,
                        ),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).secondaryText,
                              fontSize: 12.0,
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                      ),
                      Text(
                        valueOrDefault<String>(
                          widget.data?.totalReps?.toString(),
                          '-',
                        ),
                        textAlign: TextAlign.center,
                        style:
                            FlutterFlowTheme.of(context).headlineSmall.override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .fontStyle,
                                  ),
                                  fontSize: 22.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .fontStyle,
                                ),
                      ),
                      if (widget.data?.repsDiffPercent != null)
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              valueOrDefault<String>(
                                widget.data?.repsDiffAbsDisplay,
                                '(0)',
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: valueOrDefault<Color>(
                                      valueOrDefault<double>(
                                                widget.data?.repsDiffPercent,
                                                4.0,
                                              ) <=
                                              0.0
                                          ? FlutterFlowTheme.of(context)
                                              .secondaryText
                                          : Color(0xFF007A5E),
                                      FlutterFlowTheme.of(context).secondary,
                                    ),
                                    fontSize: 12.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                            Stack(
                              alignment: AlignmentDirectional(0.0, 0.0),
                              children: [
                                if (widget.data!.repsDiffPercent! > 0.0)
                                  Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Icon(
                                      Icons.arrow_drop_up,
                                      color: Color(0xFF007A5E),
                                      size: 20.0,
                                    ),
                                  ),
                                if (widget.data!.repsDiffPercent! < 0.0)
                                  Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Icon(
                                      Icons.arrow_drop_down,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: 20.0,
                                    ),
                                  ),
                                if (widget.data?.repsDiffPercent == 0.0)
                                  Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Text(
                                      FFLocalizations.of(context).getText(
                                        'qca2xxbu' /* - */,
                                      ),
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
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      Align(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: LinearPercentIndicator(
                          percent: 1.0,
                          lineHeight: 12.0,
                          animation: true,
                          animateFromLastPercent: true,
                          progressColor: Color(0xFF4A90E2),
                          backgroundColor:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          barRadius: Radius.circular(40.0),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      if (widget.data?.repsDiffPercent != null)
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              valueOrDefault<String>(
                                widget.data?.repsDiffPercentDisplay,
                                '0',
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: valueOrDefault<Color>(
                                      valueOrDefault<double>(
                                                widget.data?.repsDiffPercent,
                                                4.0,
                                              ) <=
                                              0.0
                                          ? FlutterFlowTheme.of(context)
                                              .secondaryText
                                          : Color(0xFF007A5E),
                                      FlutterFlowTheme.of(context).secondary,
                                    ),
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                            Text(
                              FFLocalizations.of(context).getText(
                                'ps3ilv9l' /* % */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: valueOrDefault<Color>(
                                      valueOrDefault<double>(
                                                widget.data?.repsDiffPercent,
                                                4.0,
                                              ) <=
                                              0.0
                                          ? FlutterFlowTheme.of(context)
                                              .secondaryText
                                          : Color(0xFF007A5E),
                                      FlutterFlowTheme.of(context).secondary,
                                    ),
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                          ].divide(SizedBox(width: 3.0)),
                        ),
                    ].divide(SizedBox(height: 2.0)),
                  ),
                ),
              ),
            ),
          if (!(widget.data?.isBodyweightOnly == 1 ? true : false))
            SizedBox(
              height: 100.0,
              child: VerticalDivider(
                thickness: 2.0,
                color: FlutterFlowTheme.of(context).alternate,
              ),
            ),
          if (!((widget.data?.isBodyweightOnly == 1) &&
              (widget.data?.isTimeBased == 0)))
            Expanded(
              flex: 1,
              child: Container(
                width: 73.0,
                height: 150.0,
                decoration: BoxDecoration(),
                child: Padding(
                  padding: EdgeInsets.all(3.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        valueOrDefault<String>(
                          widget.data?.isTimeBased == 1
                              ? 'Avg set'
                              : 'Weight\\Rep',
                          'Weight\\Rep',
                        ),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).secondaryText,
                              fontSize: 12.0,
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            valueOrDefault<String>(
                              widget.data?.isTimeBased == 1
                                  ? functions.formatDurationFromDouble(
                                      widget.data!.avgDurationPerSet!)
                                  : functions.formatDouble(
                                      widget.data!.avgWeightPerRep!),
                              '-',
                            ),
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .headlineSmall
                                .override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .fontStyle,
                                  ),
                                  fontSize: 22.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .fontStyle,
                                ),
                          ),
                          Text(
                            widget.data?.isTimeBased == 1
                                ? ''
                                : (FFAppState().isKg ? 'Kg' : 'Lbs'),
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
                                  fontSize: 10.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                          ),
                        ].divide(SizedBox(width: 3.0)),
                      ),
                      if (widget.data?.avgWeightDiffPercent != null)
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              valueOrDefault<String>(
                                widget.data?.avgWeightDiffAbsDisplay,
                                '0',
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: valueOrDefault<Color>(
                                      valueOrDefault<double>(
                                                widget
                                                    .data?.avgWeightDiffPercent,
                                                4.0,
                                              ) <=
                                              0.0
                                          ? FlutterFlowTheme.of(context)
                                              .secondaryText
                                          : FlutterFlowTheme.of(context)
                                              .success,
                                      FlutterFlowTheme.of(context).secondary,
                                    ),
                                    fontSize: 12.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                            Stack(
                              alignment: AlignmentDirectional(0.0, 0.0),
                              children: [
                                if (widget.data!.avgWeightDiffPercent! > 0.0)
                                  Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Icon(
                                      Icons.arrow_drop_up,
                                      color: Color(0xFF007A5E),
                                      size: 20.0,
                                    ),
                                  ),
                                if (widget.data!.avgWeightDiffPercent! < 0.0)
                                  Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Icon(
                                      Icons.arrow_drop_down,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: 20.0,
                                    ),
                                  ),
                                if (widget.data?.avgWeightDiffPercent == 0.0)
                                  Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Text(
                                      FFLocalizations.of(context).getText(
                                        '2o0onau1' /* - */,
                                      ),
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
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      Align(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: LinearPercentIndicator(
                          percent: 1.0,
                          lineHeight: 12.0,
                          animation: true,
                          animateFromLastPercent: true,
                          progressColor: Color(0xFF00E197),
                          backgroundColor:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          barRadius: Radius.circular(40.0),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      if (widget.data?.avgWeightDiffPercent != null)
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              valueOrDefault<String>(
                                widget.data?.isTimeBased == 1
                                    ? widget
                                        .data?.avgDurationDiffPercentDisplay
                                    : valueOrDefault<String>(
                                        widget
                                            .data?.avgWeightDiffPercentDisplay,
                                        '4',
                                      ),
                                '12',
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: valueOrDefault<Color>(
                                      valueOrDefault<double>(
                                                widget
                                                    .data?.avgWeightDiffPercent,
                                                4.0,
                                              ) <=
                                              0.0
                                          ? FlutterFlowTheme.of(context)
                                              .secondaryText
                                          : Color(0xFF007A5E),
                                      FlutterFlowTheme.of(context).secondary,
                                    ),
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                            Text(
                              FFLocalizations.of(context).getText(
                                'whzet04x' /* % */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: valueOrDefault<Color>(
                                      valueOrDefault<double>(
                                                widget
                                                    .data?.avgWeightDiffPercent,
                                                4.0,
                                              ) <=
                                              0.0
                                          ? FlutterFlowTheme.of(context)
                                              .secondaryText
                                          : FlutterFlowTheme.of(context)
                                              .success,
                                      FlutterFlowTheme.of(context).secondary,
                                    ),
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                          ].divide(SizedBox(width: 3.0)),
                        ),
                    ].divide(SizedBox(height: 2.0)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
