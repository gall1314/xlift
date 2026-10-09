import '/auth/supabase_auth/auth_util.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/components/discard_and_start_new_analysis_widget.dart';
import '/components/video2_full_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'full_result_page_model.dart';
export 'full_result_page_model.dart';

/// Design a full result page for Xlift — an iOS fitness app, light theme, app
/// background
/// #F0F2F5, accent teal
/// #14B8A6, standard white cards radius 16 with soft low shadow.
///
/// This is the result screen shown after an AI form analysis of one exercise
/// set. Clean and clinical, matching an existing app — do NOT make it
/// flashier than a standard app screen: no gradients, no glows, no confetti.
///
/// Layout, top to bottom, 16px horizontal page padding, 12px gaps between
/// cards:
///
/// Header row (no card): back chevron on the left, page title "Deadlift —
/// Form Check" — 18sp, bold,
/// #1A202C, centered
/// Score card (white card): horizontal row —
/// Left: circular progress ring, 96px, teal
/// #14B8A6 progress on
/// #E5E7EB track, showing "7.5" — 28sp bold — with "SCORE" caption 10sp
/// #6B7280 under the number, and label "Very Good" — 14sp semibold teal —
/// below the ring
/// Right column: "Total Reps" caption with value "6" (22sp bold
/// #1A202C), then "Proper Reps" caption with value "5" (22sp bold
/// #1A202C)
/// Form tip card (white card): small lightbulb icon in teal, title "Form Tip"
/// 14sp semibold, one line of placeholder text 13sp
/// #6B7280
/// Video button: full-width teal
/// #14B8A6 filled button, radius 14, height 52, white text "View Video" 16sp
/// semibold
/// Feedback card (white card): title "Feedback" 16sp bold
/// #1A202C, then 4 feedback rows — each: 22px circular status icon on the
/// left (teal check for positive, amber
/// #F59E0B exclamation for warnings — make rows 1-3 checks and row 4 amber),
/// placeholder text 13sp
/// #374151, max 2 lines. 10px gap between rows, thin
/// #F3F4F6 divider between them
/// Primary CTA: full-width teal filled button, radius 14, height 52: "Start
/// workout with Deadlift" — 16sp semibold white
/// Secondary CTA: full-width ghost button, no fill, no border: "Done" — 15sp
/// medium
/// #6B7280, centered, 8px below
///
/// Scrollable if content overflows. No delete button, no close X — navigation
/// is only via the two bottom CTAs and the back chevron.
class FullResultPageWidget extends StatefulWidget {
  const FullResultPageWidget({
    super.key,
    this.exerciseName,
    required this.analysis,
    required this.exerciseId,
    required this.isBodyweight,
  });

  final String? exerciseName;
  final dynamic analysis;
  final int? exerciseId;
  final int? isBodyweight;

  static String routeName = 'FullResultPage';
  static String routePath = '/fullResultPage';

  @override
  State<FullResultPageWidget> createState() => _FullResultPageWidgetState();
}

class _FullResultPageWidgetState extends State<FullResultPageWidget> {
  late FullResultPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FullResultPageModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.chevron_left,
              color: FlutterFlowTheme.of(context).secondaryText,
              size: 30.0,
            ),
            onPressed: () async {
              context.pushNamed(HomePageWidget.routeName);
            },
          ),
          title: Text(
            '${widget.exerciseName} Analysis Completed',
            style: FlutterFlowTheme.of(context).titleMedium.override(
                  font: GoogleFonts.interTight(
                    fontWeight:
                        FlutterFlowTheme.of(context).titleMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleMedium.fontStyle,
                  ),
                  fontSize: 16.0,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).titleMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                ),
          ),
          actions: [],
          centerTitle: true,
          elevation: 1.0,
        ),
        body: Stack(
          alignment: AlignmentDirectional(0.0, -1.0),
          children: [
            SingleChildScrollView(
              primary: false,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Container(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 12.0,
                                  color: Color(0x0A000000),
                                  offset: Offset(
                                    0.0,
                                    4.0,
                                  ),
                                  spreadRadius: 0.0,
                                )
                              ],
                              borderRadius: BorderRadius.circular(16.0),
                              shape: BoxShape.rectangle,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Container(
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        CircularPercentIndicator(
                                          percent: 1.0,
                                          radius: 47.5,
                                          lineWidth: 12.0,
                                          animation: true,
                                          animateFromLastPercent: true,
                                          progressColor:
                                              FlutterFlowTheme.of(context)
                                                  .success,
                                          backgroundColor:
                                              FlutterFlowTheme.of(context)
                                                  .alternate,
                                          center: Text(
                                            getJsonField(
                                              widget.analysis,
                                              r'''$["technique_score_display"]''',
                                            ).toString(),
                                            style: FlutterFlowTheme.of(context)
                                                .headlineMedium
                                                .override(
                                                  font: GoogleFonts.interTight(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .headlineMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .headlineMedium
                                                            .fontStyle,
                                                  ),
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .headlineMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .headlineMedium
                                                          .fontStyle,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          getJsonField(
                                            widget.analysis,
                                            r'''$["technique_label"]''',
                                          ).toString(),
                                          style: FlutterFlowTheme.of(context)
                                              .titleMedium
                                              .override(
                                                font: GoogleFonts.interTight(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleMedium
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .success,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .fontStyle,
                                              ),
                                        ),
                                      ].divide(SizedBox(height: 5.0)),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 100.0,
                                        decoration: BoxDecoration(),
                                      ),
                                    ),
                                    Flexible(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'dmhlqoy9' /* Total Reps */,
                                                ),
                                                style: FlutterFlowTheme.of(
                                                        context)
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
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText,
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
                                              ),
                                              Text(
                                                getJsonField(
                                                  widget.analysis,
                                                  r'''$["squat_count"]''',
                                                ).toString(),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .titleLarge
                                                        .override(
                                                          font: GoogleFonts
                                                              .interTight(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleLarge
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleLarge
                                                                  .fontStyle,
                                                        ),
                                              ),
                                            ].divide(SizedBox(height: 4.0)),
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'jlj8teaj' /* Proper Reps */,
                                                ),
                                                style: FlutterFlowTheme.of(
                                                        context)
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
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText,
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
                                              ),
                                              Text(
                                                getJsonField(
                                                  widget.analysis,
                                                  r'''$["good_reps"]''',
                                                ).toString(),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .titleLarge
                                                        .override(
                                                          font: GoogleFonts
                                                              .interTight(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleLarge
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleLarge
                                                                  .fontStyle,
                                                        ),
                                              ),
                                            ].divide(SizedBox(height: 4.0)),
                                          ),
                                        ].divide(SizedBox(height: 12.0)),
                                      ),
                                    ),
                                  ].divide(SizedBox(width: 24.0)),
                                ),
                              ),
                            ),
                          ),
                          if (getJsonField(
                                widget.analysis,
                                r'''$["form_tip"]''',
                              ) !=
                              null)
                            Container(
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 12.0,
                                    color: Color(0x0A000000),
                                    offset: Offset(
                                      0.0,
                                      4.0,
                                    ),
                                    spreadRadius: 0.0,
                                  )
                                ],
                                borderRadius: BorderRadius.circular(16.0),
                                shape: BoxShape.rectangle,
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Container(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.lightbulb_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .secondary,
                                        size: 20.0,
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Align(
                                              alignment: AlignmentDirectional(
                                                  -1.0, 0.0),
                                              child: Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'nt3lhro3' /* Form Tip */,
                                                ),
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                      fontSize: 14.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                      lineHeight: 1.4,
                                                    ),
                                              ),
                                            ),
                                            Align(
                                              alignment: AlignmentDirectional(
                                                  -1.0, 0.0),
                                              child: Text(
                                                getJsonField(
                                                  widget.analysis,
                                                  r'''$["form_tip"]''',
                                                ).toString(),
                                                maxLines: 1,
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
                                                      color: Color(0xFF6B7280),
                                                      fontSize: 13.0,
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
                                                      lineHeight: 1.4,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ].divide(SizedBox(height: 4.0)),
                                        ),
                                      ),
                                    ].divide(SizedBox(width: 8.0)),
                                  ),
                                ),
                              ),
                            ),
                          Builder(
                            builder: (context) => FFButtonWidget(
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
                                      child: GestureDetector(
                                        onTap: () {
                                          FocusScope.of(dialogContext)
                                              .unfocus();
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                        },
                                        child: Video2FullWidget(
                                          exerciseId: widget.exerciseId!,
                                          video: getJsonField(
                                            widget.analysis,
                                            r'''$["video_path"]''',
                                          ).toString(),
                                          analysisResult: widget.analysis!,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              text: FFLocalizations.of(context).getText(
                                'pmmqjyi3' /* View Video */,
                              ),
                              options: FFButtonOptions(
                                width: double.infinity,
                                height: 48.0,
                                padding: EdgeInsets.all(8.0),
                                iconPadding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 0.0),
                                color: FlutterFlowTheme.of(context).secondary,
                                textStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .override(
                                      font: GoogleFonts.interTight(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context).info,
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
                                  color: Colors.transparent,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 12.0,
                                  color: Color(0x0A000000),
                                  offset: Offset(
                                    0.0,
                                    4.0,
                                  ),
                                  spreadRadius: 0.0,
                                )
                              ],
                              borderRadius: BorderRadius.circular(16.0),
                              shape: BoxShape.rectangle,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Container(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          FFLocalizations.of(context).getText(
                                            'saor8l81' /* Feedback */,
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
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                                fontSize: 16.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.bold,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                                lineHeight: 1.4,
                                              ),
                                        ),
                                      ].divide(SizedBox(height: 16.0)),
                                    ),
                                  ),
                                ),
                                ListView(
                                  padding: EdgeInsets.zero,
                                  primary: false,
                                  shrinkWrap: true,
                                  scrollDirection: Axis.vertical,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            12.0, 12.0, 12.0, 12.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Stack(
                                              children: [
                                                if (!functions
                                                    .showPerfectScoreIcon(
                                                        getJsonField(
                                                  widget.analysis,
                                                  r'''$["technique_score"]''',
                                                ))!)
                                                  Icon(
                                                    Icons.warning,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .warning,
                                                    size: 20.0,
                                                  ),
                                                if (functions
                                                        .showPerfectScoreIcon(
                                                            getJsonField(
                                                      widget.analysis,
                                                      r'''$["technique_score"]''',
                                                    )) ??
                                                    true)
                                                  Icon(
                                                    Icons.check_circle_sharp,
                                                    color: FlutterFlowTheme.of(
                                                            context)
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
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                      'lhx7ymxp' /* Try going deeper on your squat... */,
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .labelMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
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
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
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
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ].divide(SizedBox(width: 12.0)),
                                        ),
                                      ),
                                    ),
                                  ].divide(SizedBox(height: 8.0)),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 12.0, 0.0, 24.0),
                            child: Container(
                              child: Container(
                                width: 0.0,
                                height: 0.0,
                              ),
                            ),
                          ),
                        ].divide(SizedBox(height: 20.0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: AlignmentDirectional(0.0, 1.0),
              child: Builder(
                builder: (context) => Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 16.0),
                  child: FFButtonWidget(
                    onPressed: () async {
                      if (FFAppState().workout) {
                        await showDialog(
                          context: context,
                          builder: (dialogContext) {
                            return Dialog(
                              elevation: 0,
                              insetPadding: EdgeInsets.zero,
                              backgroundColor: Colors.transparent,
                              alignment: AlignmentDirectional(0.0, 0.0)
                                  .resolve(Directionality.of(context)),
                              child: GestureDetector(
                                onTap: () {
                                  FocusScope.of(dialogContext).unfocus();
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                                child: DiscardAndStartNewAnalysisWidget(
                                  startAnalysis: () async {
                                    _model.uuidA =
                                        await actions.generateUuidV4();
                                    await SQLiteManager.instance
                                        .insertdeletedWorkout(
                                      name: functions.quickCheckWorkoutName(
                                          widget.exerciseName!),
                                      id: _model.uuidA!,
                                      createdAt: getCurrentTimestamp.toString(),
                                      userId: currentUserUid,
                                    );
                                    _model.uuid2A =
                                        await actions.generateUuidV4();
                                    await SQLiteManager.instance
                                        .insertWorkoutExercise(
                                      id: _model.uuid2A!,
                                      workoutId: _model.uuidA!,
                                      createdAt: getCurrentTimestamp.toString(),
                                      order: 0,
                                      exerciseId: widget.exerciseId!,
                                      restSeconds: 0,
                                      exerciseName: widget.exerciseName!,
                                      userId: currentUserUid,
                                      isSuperset: 0,
                                      supersetGroupId: '',
                                    );
                                    _model.uuid3A =
                                        await actions.generateUuidV4();
                                    await SQLiteManager.instance
                                        .insertExerciseSts(
                                      workoutExerciseId: _model.uuid2A!,
                                      setNumber: 1,
                                      targetReps: getJsonField(
                                        widget.analysis,
                                        r'''$["squat_count"]''',
                                      ),
                                      isWarmup: 0,
                                      isDropset: 0,
                                      dropNumber: 0,
                                      workoutId: _model.uuidA!,
                                      id: _model.uuid3A!,
                                      weighted:
                                          widget.isBodyweight == 0 ? 1 : 0,
                                      durationSeconds: 0,
                                    );
                                    _model.analA =
                                        await actions.updateSetAnalysisResult(
                                      FFAppState()
                                          .workoutAnalysisState
                                          .toList(),
                                      widget.exerciseId!,
                                      1,
                                      widget.analysis!,
                                    );
                                    FFAppState().workoutAnalysisState =
                                        _model.analA!.toList().cast<dynamic>();
                                    safeSetState(() {});
                                    FFAppState().deleteExercisesets();
                                    FFAppState().exercisesets = [];

                                    FFAppState().deleteLoggedSets();
                                    FFAppState().loggedSets = [];

                                    FFAppState().dropSets = [];
                                    FFAppState().deleteRestTimers();
                                    FFAppState().restTimers = null;

                                    FFAppState().deleteWarmupSets();
                                    FFAppState().warmupSets = [];

                                    FFAppState().workout = false;
                                    FFAppState().deleteCompletedExercises();
                                    FFAppState().completedExercises = [];

                                    FFAppState().deleteWorkoutAnalysisState();
                                    FFAppState().workoutAnalysisState = [];

                                    FFAppState().deleteActiveWorkoutStartTime();
                                    FFAppState().activeWorkoutStartTime = null;

                                    safeSetState(() {});

                                    context.pushNamed(
                                      WorkoutV2Widget.routeName,
                                      queryParameters: {
                                        'workoutId': serializeParam(
                                          _model.uuidA,
                                          ParamType.String,
                                        ),
                                      }.withoutNulls,
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        _model.uuid = await actions.generateUuidV4();
                        await SQLiteManager.instance.insertdeletedWorkout(
                          name: functions
                              .quickCheckWorkoutName(widget.exerciseName!),
                          id: _model.uuid!,
                          createdAt: getCurrentTimestamp.toString(),
                          userId: currentUserUid,
                        );
                        _model.uuid2 = await actions.generateUuidV4();
                        await SQLiteManager.instance.insertWorkoutExercise(
                          id: _model.uuid2!,
                          workoutId: _model.uuid!,
                          createdAt: getCurrentTimestamp.toString(),
                          order: 0,
                          exerciseId: widget.exerciseId!,
                          restSeconds: 0,
                          exerciseName: widget.exerciseName!,
                          userId: currentUserUid,
                          isSuperset: 0,
                          supersetGroupId: '',
                        );
                        _model.uuid3 = await actions.generateUuidV4();
                        await SQLiteManager.instance.insertExerciseSts(
                          workoutExerciseId: _model.uuid2!,
                          setNumber: 1,
                          targetReps: getJsonField(
                            widget.analysis,
                            r'''$["squat_count"]''',
                          ),
                          isWarmup: 0,
                          isDropset: 0,
                          dropNumber: 0,
                          workoutId: _model.uuid!,
                          id: _model.uuid3!,
                          weighted: widget.isBodyweight == 0 ? 1 : 0,
                          durationSeconds: 0,
                        );
                        _model.anal = await actions.updateSetAnalysisResult(
                          FFAppState().workoutAnalysisState.toList(),
                          widget.exerciseId!,
                          1,
                          widget.analysis!,
                        );
                        FFAppState().deleteExercisesets();
                        FFAppState().exercisesets = [];

                        FFAppState().deleteLoggedSets();
                        FFAppState().loggedSets = [];

                        FFAppState().dropSets = [];
                        FFAppState().deleteRestTimers();
                        FFAppState().restTimers = null;

                        FFAppState().deleteWarmupSets();
                        FFAppState().warmupSets = [];

                        FFAppState().workout = false;
                        FFAppState().deleteCompletedExercises();
                        FFAppState().completedExercises = [];

                        FFAppState().deleteWorkoutAnalysisState();
                        FFAppState().workoutAnalysisState = [];

                        FFAppState().deleteActiveWorkoutStartTime();
                        FFAppState().activeWorkoutStartTime = null;

                        safeSetState(() {});
                        FFAppState().workoutAnalysisState =
                            _model.anal!.toList().cast<dynamic>();
                        safeSetState(() {});

                        context.pushNamed(
                          WorkoutV2Widget.routeName,
                          queryParameters: {
                            'workoutId': serializeParam(
                              _model.uuid,
                              ParamType.String,
                            ),
                          }.withoutNulls,
                        );
                      }

                      safeSetState(() {});
                    },
                    text: FFLocalizations.of(context).getText(
                      '96wal5wp' /* Continue as Workout */,
                    ),
                    options: FFButtonOptions(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      height: 50.0,
                      padding:
                          EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                      iconPadding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      color: FlutterFlowTheme.of(context).secondary,
                      textStyle:
                          FlutterFlowTheme.of(context).titleSmall.override(
                                font: GoogleFonts.interTight(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                                color: Colors.white,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontStyle,
                              ),
                      elevation: 0.0,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    showLoadingIndicator: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
