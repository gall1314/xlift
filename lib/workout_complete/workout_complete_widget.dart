import '/auth/supabase_auth/auth_util.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/components/stat_item_widget.dart';
import '/components/workout_breakdown_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'workout_complete_model.dart';
export 'workout_complete_model.dart';

/// Build: Workout Complete screen (static, dark poster)
///
/// Create a new page WorkoutCompletePage.
///
/// Full-screen, no AppBar, no bottom nav. Static placeholder data for now —
/// no bindings, no backend calls, no bottom sheet. This is layout and styling
/// only.
///
/// Canvas
///
/// Background: fixed dark, independent of app theme. Solid
/// #0F1F1E with a subtle radial glow of the brand teal (
/// #1AAE9F at ~12% opacity) centered behind the hero number. If a radial
/// gradient is hard, a vertical gradient
/// #14302D (top) →
/// #0F1F1E (bottom) is fine.
/// SafeArea on. Content in a single Column, MainAxisAlignment.spaceBetween so
/// the header sits at the top and the actions sit at the bottom; everything
/// else centered vertically in between.
/// Horizontal padding 24.
///
/// Header (top-left aligned)
///
/// Eyebrow: WORKOUT COMPLETE — 11px, letter-spacing 1.5, white at 60%
/// opacity, uppercase.
/// Title: Pull — Day B · Back — 22px, bold, white.
/// Subtitle: Sat, Sep 6 · 18:42 — 13px, white at 60%.
///
/// Hero block (centered)
///
/// Pill badge: NEW PERSONAL RECORD — outlined pill, 1px border teal
/// #2CD4C3, text teal, 11px, letter-spacing 1.5, padding 6×14, radius 999.
/// (Static visible for now; will be conditional later.)
/// Gap 16.
/// Exercise name: Deadlift — 16px, white, medium weight.
/// Hero number: 150 — 120px, extra-bold, teal
/// #2CD4C3, tight letter-spacing (-4). Unit kg — 28px, bold, teal,
/// baseline-aligned to the right of the number with 6px gap. Use a Row with
/// CrossAxisAlignment.baseline.
/// Gap 8.
/// Previous best 145 kg — 14px, white at 55%.
/// Gap 16.
/// Comparison chip: 10,081 kg total · ▲ 6.3% vs last Pull day — filled pill,
/// background white at 10%, text white 13px, medium weight, padding 8×16,
/// radius 999.
///
/// Stats strip
///
/// Thin 1px divider, white at 12%, above the strip.
/// Row of 3 equal columns separated by 1px vertical lines (white at 12%,
/// height 36):
/// 52:41 / Duration
/// 18 / Sets
/// 87 / Solid form
/// Number: 26px, bold, white, condensed feel (tight letter-spacing -1).
/// Label: 12px, white at 55%.
///
/// Breakdown trigger (placeholder only)
///
/// Outlined pill button, full width, 1px border white at 25%, radius 999,
/// height 44. Text 5 exercises · 18 sets in white 14px medium, plus a
/// chevron-down icon (white, 18px) to the right. No action wired yet.
///
/// Actions (bottom)
///
/// Primary: Done — full width, height 56, radius 999, background teal
/// #1AAE9F, text white 16px bold. Action: navigate back to Home.
/// Gap 12.
/// Secondary: Share — text button, white 15px medium, centered. No action
/// yet.
/// Bottom padding 16 above the home indicator.
///
/// Type
///
/// Use the app's existing font family for everything except the hero number.
/// For the hero number, if Google Fonts is available in this project use
/// Anton; otherwise the app font at weight 900.
///
/// Rules
///
/// Do not use Material default elevation/shadows on the buttons.
/// No emoji anywhere.
/// Every color above is a literal hex for now; we'll move them into the theme
/// once the layout is approved.
/// Do not add a bottom sheet, exercise list, or any scrolling. The page
/// should fit one screen on an iPhone 13/14-sized viewport without overflow;
/// if it overflows, reduce the hero number size before reducing anything
/// else.
class WorkoutCompleteWidget extends StatefulWidget {
  const WorkoutCompleteWidget({
    super.key,
    required this.workoutLogId,
  });

  final String? workoutLogId;

  static String routeName = 'workoutComplete';
  static String routePath = '/workoutComplete';

  @override
  State<WorkoutCompleteWidget> createState() => _WorkoutCompleteWidgetState();
}

class _WorkoutCompleteWidgetState extends State<WorkoutCompleteWidget> {
  late WorkoutCompleteModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WorkoutCompleteModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      HapticFeedback.lightImpact();
      await Future.delayed(
        Duration(
          milliseconds: 1500,
        ),
      );
      _model.animation = false;
      safeSetState(() {});
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WorkoutHeroStatRow>>(
      future: SQLiteManager.instance.workoutHeroStat(
        workoutLogId: widget.workoutLogId!,
        userId: currentUserUid,
      ),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: Color(0x00FFFFFF),
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).secondary,
                  ),
                ),
              ),
            ),
          );
        }
        final workoutCompleteWorkoutHeroStatRowList = snapshot.data!;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: Color(0x00FFFFFF),
            body: SafeArea(
              left: false,
              top: false,
              right: false,
              bottom: false,
              child: Container(
                height: MediaQuery.sizeOf(context).height * 1.0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF14302D), Color(0xFF0F1F1E)],
                    stops: [0.0, 1.0],
                    begin: AlignmentDirectional(0.0, -1.0),
                    end: AlignmentDirectional(0, 1.0),
                  ),
                  shape: BoxShape.rectangle,
                ),
                child: Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(24.0, 60.0, 24.0, 34.0),
                  child: Container(
                    child: Stack(
                      children: [
                        if (!_model.animation)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Align(
                                              alignment: AlignmentDirectional(
                                                  -1.0, -1.0),
                                              child: Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'wpugqjh5' /* WORKOUT COMPLETE */,
                                                ),
                                                textAlign: TextAlign.start,
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
                                                      color: Color(0x99FFFFFF),
                                                      fontSize: 11.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                      lineHeight: 1.5,
                                                    ),
                                              ),
                                            ),
                                            Align(
                                              alignment: AlignmentDirectional(
                                                  -1.0, -1.0),
                                              child: Text(
                                                valueOrDefault<String>(
                                                  workoutCompleteWorkoutHeroStatRowList
                                                      .firstOrNull?.workoutName,
                                                  'workout_name',
                                                ),
                                                style:
                                                    FlutterFlowTheme.of(context)
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
                                                          color: Colors.white,
                                                          fontSize: 22.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
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
                                                  -1.0, -1.0),
                                              child: Text(
                                                valueOrDefault<String>(
                                                  workoutCompleteWorkoutHeroStatRowList
                                                      .firstOrNull?.dateText,
                                                  'duration_text',
                                                ),
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
                                                      color: Color(0x99FFFFFF),
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
                                              ),
                                            ),
                                          ].divide(SizedBox(height: 4.0)),
                                        ),
                                      ),
                                      if (!_model.iscapturing)
                                        Align(
                                          alignment:
                                              AlignmentDirectional(1.0, 0.0),
                                          child: FlutterFlowIconButton(
                                            borderColor:
                                                FlutterFlowTheme.of(context)
                                                    .alternate,
                                            borderRadius: 40.0,
                                            borderWidth: 2.0,
                                            buttonSize: 40.0,
                                            fillColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                            icon: Icon(
                                              Icons.ios_share,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              size: 20.0,
                                            ),
                                            onPressed: () async {
                                              _model.iscapturing = true;
                                              safeSetState(() {});
                                              await actions.shareWorkoutPoster(
                                                context,
                                                0.0,
                                                0.0,
                                                '',
                                              );
                                              _model.iscapturing = false;
                                              safeSetState(() {});
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                ]
                                    .divide(SizedBox(height: 4.0))
                                    .addToEnd(SizedBox(height: 80.0)),
                              ),
                              Container(
                                height: 350.0,
                                decoration: BoxDecoration(),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(9999.0),
                                        shape: BoxShape.rectangle,
                                        border: Border.all(
                                          color: Color(0xFF2CD4C3),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            14.0, 6.0, 14.0, 6.0),
                                        child: Container(
                                          child: Text(
                                            valueOrDefault<String>(
                                              workoutCompleteWorkoutHeroStatRowList
                                                  .firstOrNull?.badge,
                                              '-',
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  color: Color(0xFF2CD4C3),
                                                  fontSize: 11.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                  lineHeight: 1.5,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          valueOrDefault<String>(
                                            workoutCompleteWorkoutHeroStatRowList
                                                .firstOrNull?.heroTitle,
                                            '-',
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
                                                color: Colors.white,
                                                fontSize: 16.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w500,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                                lineHeight: 1.4,
                                              ),
                                        ),
                                        Container(
                                          width: 300.0,
                                          height: 150.0,
                                          child: custom_widgets.HeroCounter(
                                            width: 300.0,
                                            height: 150.0,
                                            value:
                                                workoutCompleteWorkoutHeroStatRowList
                                                    .firstOrNull!.heroValue,
                                            unit:
                                                workoutCompleteWorkoutHeroStatRowList
                                                    .firstOrNull?.heroUnit,
                                            color: FlutterFlowTheme.of(context)
                                                .secondary,
                                            unitColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondary,
                                            fontSize: 110.0,
                                            unitFontSize: 28.0,
                                            useThousandsSeparator: true,
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                'z5r6sr0i' /* Previous best 145 kg */,
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
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
                                                            Color(0x8CFFFFFF),
                                                        fontSize: 14.0,
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
                                            ),
                                          ].divide(SizedBox(width: 6.0)),
                                        ),
                                      ].divide(SizedBox(height: 4.0)),
                                    ),
                                    if (workoutCompleteWorkoutHeroStatRowList
                                                .firstOrNull?.comparison !=
                                            null &&
                                        workoutCompleteWorkoutHeroStatRowList
                                                .firstOrNull?.comparison !=
                                            '')
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Color(0x1AFFFFFF),
                                          borderRadius:
                                              BorderRadius.circular(9999.0),
                                          shape: BoxShape.rectangle,
                                        ),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 8.0, 16.0, 8.0),
                                          child: Container(
                                            child: Text(
                                              valueOrDefault<String>(
                                                workoutCompleteWorkoutHeroStatRowList
                                                    .firstOrNull?.comparison,
                                                '-',
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                        color: Colors.white,
                                                        fontSize: 13.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                        lineHeight: 1.4,
                                                      ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ].divide(SizedBox(height: 20.0)),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Divider(
                                        height: 16.0,
                                        thickness: 1.0,
                                        indent: 0.0,
                                        endIndent: 0.0,
                                        color: Color(0x1FFFFFFF),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: wrapWithModel(
                                              model: _model.statItemModel1,
                                              updateCallback: () =>
                                                  safeSetState(() {}),
                                              child: StatItemWidget(
                                                value:
                                                    workoutCompleteWorkoutHeroStatRowList
                                                        .firstOrNull
                                                        ?.durationText,
                                                label: 'Duration',
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: 1.0,
                                            height: 36.0,
                                            decoration: BoxDecoration(
                                              color: Color(0x1FFFFFFF),
                                              shape: BoxShape.rectangle,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: wrapWithModel(
                                              model: _model.statItemModel2,
                                              updateCallback: () =>
                                                  safeSetState(() {}),
                                              child: StatItemWidget(
                                                value:
                                                    workoutCompleteWorkoutHeroStatRowList
                                                        .firstOrNull?.setsText,
                                                label: 'Sets',
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: 1.0,
                                            height: 36.0,
                                            decoration: BoxDecoration(
                                              color: Color(0x1FFFFFFF),
                                              shape: BoxShape.rectangle,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: wrapWithModel(
                                              model: _model.statItemModel3,
                                              updateCallback: () =>
                                                  safeSetState(() {}),
                                              child: StatItemWidget(
                                                value:
                                                    workoutCompleteWorkoutHeroStatRowList
                                                        .firstOrNull
                                                        ?.stat3Value,
                                                label:
                                                    workoutCompleteWorkoutHeroStatRowList
                                                        .firstOrNull
                                                        ?.stat3Label,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ].divide(SizedBox(height: 16.0)),
                                  ),
                                  if (!_model.iscapturing)
                                    InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        await showModalBottomSheet(
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          enableDrag: false,
                                          context: context,
                                          builder: (context) {
                                            return GestureDetector(
                                              onTap: () {
                                                FocusScope.of(context)
                                                    .unfocus();
                                                FocusManager
                                                    .instance.primaryFocus
                                                    ?.unfocus();
                                              },
                                              child: Padding(
                                                padding:
                                                    MediaQuery.viewInsetsOf(
                                                        context),
                                                child: WorkoutBreakdownWidget(
                                                  workoutLogId:
                                                      widget.workoutLogId!,
                                                ),
                                              ),
                                            );
                                          },
                                        ).then((value) => safeSetState(() {}));
                                      },
                                      child: Container(
                                        height: 44.0,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(9999.0),
                                          shape: BoxShape.rectangle,
                                          border: Border.all(
                                            color: Color(0x40FFFFFF),
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  20.0, 0.0, 20.0, 0.0),
                                          child: Container(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Spacer(),
                                                Text(
                                                  valueOrDefault<String>(
                                                    workoutCompleteWorkoutHeroStatRowList
                                                        .firstOrNull
                                                        ?.breakdownLabel,
                                                    'breakdown_label',
                                                  ),
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                        color: Colors.white,
                                                        fontSize: 14.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                        lineHeight: 1.4,
                                                      ),
                                                ),
                                                Icon(
                                                  Icons
                                                      .keyboard_arrow_down_rounded,
                                                  color: Colors.white,
                                                  size: 18.0,
                                                ),
                                                Spacer(),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ].divide(SizedBox(height: 40.0)),
                              ),
                              if (!_model.iscapturing)
                                FFButtonWidget(
                                  onPressed: () async {
                                    context
                                        .pushNamed(MasterPageWidget.routeName);
                                  },
                                  text: FFLocalizations.of(context).getText(
                                    'nxjer796' /* Done */,
                                  ),
                                  options: FFButtonOptions(
                                    height: 50.0,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        16.0, 0.0, 16.0, 0.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: FlutterFlowTheme.of(context).primary,
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
                                          color: Colors.white,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    elevation: 0.0,
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 16.0, 0.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children:
                                      <Widget>[].divide(SizedBox(height: 16.0)),
                                ),
                              ),
                            ].divide(SizedBox(height: 10.0)),
                          ),
                        if (_model.animation)
                          Align(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Lottie.asset(
                              'assets/jsons/Success_animation.json',
                              width: 393.0,
                              height: 393.0,
                              fit: BoxFit.contain,
                              repeat: false,
                              animate: true,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
