import '/backend/sqlite/sqlite_manager.dart';
import '/components/delete_set_analysis_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'analyze2_app_after_model.dart';
export 'analyze2_app_after_model.dart';

/// Create a component ,
/// Create a compact, centered popup modal called Set Analysis Modal with a
/// premium, polished look.
///
/// Use a clean, modern design with balanced spacing, rounded corners, and
/// subtle drop shadow.
///
/// Top Bar:
///
/// Left: small circular icon button with a “Redo” ↻ icon.
///
/// Right: small circular icon button with an “X” close icon.
///
/// Video Section:
///
/// Container with 16:9 aspect ratio (similar size to a YouTube embed).
///
/// Overlay in the top-right corner: small pill-shaped "Download" ⬇️ button
/// with a contrasting color.
///
/// Score Section:
///
/// Display a donut chart for the score:
///
/// Thick, smooth ring with a gradient fill (color shifts from red → orange →
/// green depending on score).
///
/// Numeric score in large bold text inside the circle, with a smaller label
/// underneath for quality text (e.g., “Excellent”).
///
/// Ring should be visually prominent and feel premium — subtle shadow, smooth
/// edges.
///
/// To the right of the donut, a clean vertical list of two main stats:
///
/// “Total Reps” with its value.
///
/// “Proper Reps” with its value.
///
/// Keep typography modern, with bold numbers and muted labels.
///
/// Feedback Section:
///
/// Short vertical list of feedback items.
///
/// Each item in a rounded, light-colored container with an icon: ⚠️ for
/// critical issues, 💡 for tips.
///
/// Use consistent padding and equal spacing between items.
///
/// Bottom Button:
///
/// Large, full-width Confirm Analysis button with a high-contrast color and
/// slight elevation.
///
/// Rounded edges and bold text.
///
/// Use consistent padding between all sections, align elements neatly, and
/// ensure the score donut looks like a central, eye-catching element.
class Analyze2AppAfterWidget extends StatefulWidget {
  const Analyze2AppAfterWidget({
    super.key,
    this.videoUrl,
    this.video,
    required this.anlysis,
  });

  final FFUploadedFile? videoUrl;
  final String? video;
  final GetSetAnalysisRow? anlysis;

  @override
  State<Analyze2AppAfterWidget> createState() => _Analyze2AppAfterWidgetState();
}

class _Analyze2AppAfterWidgetState extends State<Analyze2AppAfterWidget> {
  late Analyze2AppAfterModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Analyze2AppAfterModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Container(
        width: 380.0,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          boxShadow: [
            BoxShadow(
              blurRadius: 24.0,
              color: Color(0x33000000),
              offset: Offset(
                0.0,
                8.0,
              ),
              spreadRadius: 0.0,
            )
          ],
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(24.0, 24.0, 24.0, 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) => FlutterFlowIconButton(
                      borderColor: Colors.transparent,
                      borderRadius: 18.0,
                      borderWidth: 1.0,
                      buttonSize: 36.0,
                      fillColor: FlutterFlowTheme.of(context).primaryBackground,
                      icon: FaIcon(
                        FaIconData(const IconData(/* trashAlt */ 0xf2ed,
                            fontFamily: 'FontAwesomeRegular',
                            fontPackage: 'font_awesome_flutter')),
                        color: FlutterFlowTheme.of(context).primaryText,
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
                              child: DeleteSetAnalysisWidget(
                                analysisId: widget.anlysis!.id,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  FlutterFlowIconButton(
                    borderColor: Colors.transparent,
                    borderRadius: 18.0,
                    borderWidth: 1.0,
                    buttonSize: 36.0,
                    fillColor: FlutterFlowTheme.of(context).primaryBackground,
                    icon: Icon(
                      Icons.close,
                      color: FlutterFlowTheme.of(context).primaryText,
                      size: 18.0,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      CircularPercentIndicator(
                        percent:
                            functions.normalizeScore(widget.anlysis!.score!),
                        radius: 47.5,
                        lineWidth: 12.0,
                        animation: true,
                        animateFromLastPercent: true,
                        progressColor: FlutterFlowTheme.of(context).success,
                        backgroundColor: FlutterFlowTheme.of(context).alternate,
                        center: Text(
                          widget.anlysis!.techniqueScoreDisplay!,
                          style: FlutterFlowTheme.of(context)
                              .headlineMedium
                              .override(
                                font: GoogleFonts.interTight(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .headlineMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineMedium
                                      .fontStyle,
                                ),
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .fontStyle,
                              ),
                        ),
                      ),
                      Text(
                        valueOrDefault<String>(
                          widget.anlysis?.techniqueLabel,
                          '-',
                        ),
                        style:
                            FlutterFlowTheme.of(context).titleMedium.override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context).success,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontStyle,
                                ),
                      ),
                    ].divide(SizedBox(height: 5.0)),
                  ),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FFLocalizations.of(context).getText(
                                's1sqhrs6' /* Total Reps */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                            ),
                            Text(
                              valueOrDefault<String>(
                                widget.anlysis?.totalReps?.toString(),
                                '-',
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .titleLarge
                                  .override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleLarge
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleLarge
                                        .fontStyle,
                                  ),
                            ),
                          ].divide(SizedBox(height: 4.0)),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FFLocalizations.of(context).getText(
                                'k5mks4ti' /* Proper Reps */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                            ),
                            Text(
                              valueOrDefault<String>(
                                widget.anlysis?.properReps?.toString(),
                                '-',
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .titleLarge
                                  .override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleLarge
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleLarge
                                        .fontStyle,
                                  ),
                            ),
                          ].divide(SizedBox(height: 4.0)),
                        ),
                      ].divide(SizedBox(height: 12.0)),
                    ),
                  ),
                ].divide(SizedBox(width: 16.0)),
              ),
              if (widget.anlysis?.formTip != null &&
                  widget.anlysis?.formTip != '')
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(12.0, 12.0, 12.0, 12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Icon(
                          Icons.lightbulb,
                          color: FlutterFlowTheme.of(context).primary,
                          size: 20.0,
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                FFLocalizations.of(context).getText(
                                  '4h9vuh5a' /* Form Tip */,
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
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                              Text(
                                valueOrDefault<String>(
                                  widget.anlysis?.formTip,
                                  '-',
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ].divide(SizedBox(width: 12.0)),
                    ),
                  ),
                ),
              Align(
                alignment: AlignmentDirectional(-1.0, 0.0),
                child: Text(
                  FFLocalizations.of(context).getText(
                    'iyh9kiby' /* Feedback */,
                  ),
                  style: FlutterFlowTheme.of(context).titleLarge.override(
                        font: GoogleFonts.interTight(
                          fontWeight: FlutterFlowTheme.of(context)
                              .titleLarge
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).titleLarge.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).titleLarge.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleLarge.fontStyle,
                      ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Builder(
                    builder: (context) {
                      final feedback = functions
                              .parseFeedback(widget.anlysis!.feedback!)
                              ?.toList() ??
                          [];

                      return ListView.separated(
                        padding: EdgeInsets.zero,
                        primary: false,
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        itemCount: feedback.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.0),
                        itemBuilder: (context, feedbackIndex) {
                          final feedbackItem = feedback[feedbackIndex];
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .primaryBackground,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  12.0, 12.0, 12.0, 12.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Stack(
                                    children: [
                                      if (widget.anlysis?.score != 10.0)
                                        Icon(
                                          Icons.warning,
                                          color: FlutterFlowTheme.of(context)
                                              .warning,
                                          size: 20.0,
                                        ),
                                      if (widget.anlysis?.score == 10.0)
                                        Icon(
                                          Icons.check_circle_sharp,
                                          color: FlutterFlowTheme.of(context)
                                              .secondary,
                                          size: 20.0,
                                        ),
                                    ],
                                  ),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          feedbackItem,
                                          style: FlutterFlowTheme.of(context)
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
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontStyle,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ].divide(SizedBox(width: 12.0)),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ].divide(SizedBox(height: 8.0)),
              ),
            ].divide(SizedBox(height: 20.0)),
          ),
        ),
      ),
    );
  }
}
