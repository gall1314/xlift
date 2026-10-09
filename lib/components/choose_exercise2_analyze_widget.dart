import '/backend/sqlite/sqlite_manager.dart';
import '/components/camera_analyzer_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'choose_exercise2_analyze_model.dart';
export 'choose_exercise2_analyze_model.dart';

/// אתה צודק ואני מתנצל — הסתכלתי עכשיו שוב על שני הצילומים והטעות שלי ברורה.
///
/// ה-FlutterFlow דווקא ביצע מצוין (תמונה 1): רשימה אנכית, שלוש שורות, ריבועי
/// mint, בדיוק הפרומפט. הבעיה היא שהפרומפט שלי בכלל לא תיאר את הדיזיין שבחרת
/// — ה-Dock הנמוך מהדיזיינר (תמונה 2): sheet נמוך עם קרוסלה אופקית של כרטיסים
/// גדולים, swipe בין תרגילים, חצים ונקודות עמוד. אתה בחרת B ואני המשכתי לכתוב
/// פרומפטים של הרשימה האנכית שאני העדפתי. שגיאה שלי.
///
/// הנה הפרומפט הנכון, לפי הדיזיין שבחרת:
///
/// Full prompt — generate from scratch:
///
/// Design a bottom sheet component named ExercisePickerSheet, for Xlift — an
/// iOS fitness app, light theme, accent teal
/// #14B8A6.
///
/// This is a LOW, compact sheet (~30% of screen height) with a HORIZONTAL
/// swipeable carousel of exercise cards.
///
/// IMPORTANT — dynamic content: the cards are placeholders; the real list is
/// injected dynamically from a database. Show exactly 3 sample cards with
/// generic names "Exercise A", "Exercise B", "Exercise C". The third card
/// should be partially cut off at the right screen edge — a visual hint that
/// the row scrolls horizontally. Do not invent real exercise names.
///
/// Sheet structure (top to bottom):
///
/// White sheet, top corners radius 24, centered drag handle (36×4,
/// #E5E7EB)
/// Header row, horizontal padding 20: title "What are you training?" — 18sp,
/// bold,
/// #1A202C, left-aligned; on the right edge a small hint "swipe →" — 12sp,
/// #9CA3AF
/// 12px gap
/// The horizontal carousel — one row, scrolls horizontally, left padding 20,
/// 12px gap between cards
/// 12px gap, then 3 page-indicator dots centered: active dot teal
/// #14B8A6 (8×4 pill), inactive dots
/// #D1D5DB (4×4 circles)
/// 12px bottom padding
///
/// Card template — each of the 3 cards identical:
///
/// Width 130, height 150, white card, radius 16, border 1px
/// #E5E7EB
/// Inside, a Column, padding 10:
/// Image placeholder — fills the card width, height 90, radius 12, solid fill
///
/// #DCF5F0, completely empty (real exercise illustration injected in
/// production)
/// 8px gap
/// Exercise name — 14sp, semibold,
/// #1A202C, centered, up to 2 lines
/// Pressed state: card border
/// #14B8A6, background tint
/// #F0FBF9
///
/// Minimal, clean, clinical. No emojis, no badges, no search bar.
class ChooseExercise2AnalyzeWidget extends StatefulWidget {
  const ChooseExercise2AnalyzeWidget({super.key});

  @override
  State<ChooseExercise2AnalyzeWidget> createState() =>
      _ChooseExercise2AnalyzeWidgetState();
}

class _ChooseExercise2AnalyzeWidgetState
    extends State<ChooseExercise2AnalyzeWidget> {
  late ChooseExercise2AnalyzeModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ChooseExercise2AnalyzeModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GetAiexercisesRow>>(
      future: SQLiteManager.instance.getAiexercises(),
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
        final containerGetAiexercisesRowList = snapshot.data!;

        return Container(
          width: 935.0,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
            shape: BoxShape.rectangle,
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 12.0, 0.0, 12.0),
                          child: Container(
                            child: Container(
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: Container(
                                width: 36.0,
                                height: 4.0,
                                decoration: BoxDecoration(
                                  color: Color(0xFFE5E7EB),
                                  borderRadius: BorderRadius.circular(9999.0),
                                  shape: BoxShape.rectangle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            20.0, 0.0, 20.0, 0.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              FFLocalizations.of(context).getText(
                                'g5t98pf2' /* Pick an exercise to analyze */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    fontSize: 18.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                    lineHeight: 1.4,
                                  ),
                            ),
                            Text(
                              FFLocalizations.of(context).getText(
                                '83gl0uon' /* hint */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF9CA3AF),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                    lineHeight: 1.4,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  20.0, 0.0, 20.0, 0.0),
                              child: Container(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
                  child: Builder(
                    builder: (context) {
                      final aiEx =
                          containerGetAiexercisesRowList.map((e) => e).toList();

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: List.generate(aiEx.length, (aiExIndex) {
                            final aiExItem = aiEx[aiExIndex];
                            return Builder(
                              builder: (context) => InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  await showDialog(
                                    context: context,
                                    builder: (dialogContext) {
                                      return Dialog(
                                        elevation: 0,
                                        insetPadding: EdgeInsets.zero,
                                        backgroundColor: Colors.transparent,
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0)
                                                .resolve(
                                                    Directionality.of(context)),
                                        child: CameraAnalyzerWidget(
                                          exerciseId: aiExItem.id,
                                          analyze: (video) async {
                                            context.pushNamed(
                                              FullAnalyzingStatePageWidget
                                                  .routeName,
                                              queryParameters: {
                                                'videoFile': serializeParam(
                                                  video,
                                                  ParamType.FFUploadedFile,
                                                ),
                                                'exerciseName': serializeParam(
                                                  aiExItem.name,
                                                  ParamType.String,
                                                ),
                                                'exerciseId': serializeParam(
                                                  aiExItem.id,
                                                  ParamType.int,
                                                ),
                                                'isBodyweight': serializeParam(
                                                  aiExItem.isBodyweight,
                                                  ParamType.int,
                                                ),
                                              }.withoutNulls,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  width: 130.0,
                                  height: 160.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    borderRadius: BorderRadius.circular(16.0),
                                    shape: BoxShape.rectangle,
                                    border: Border.all(
                                      color: Color(0xFFE5E7EB),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          height: 90.0,
                                          decoration: BoxDecoration(
                                            color: Color(0xFFDCF5F0),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            shape: BoxShape.rectangle,
                                          ),
                                          child: Container(
                                            width: MediaQuery.sizeOf(context)
                                                    .width *
                                                1.0,
                                            height: 90.0,
                                            child: custom_widgets
                                                .ExerciseAssetImage(
                                              width: MediaQuery.sizeOf(context)
                                                      .width *
                                                  1.0,
                                              height: 90.0,
                                              exerciseName:
                                                  functions.exerciseImageName(
                                                      aiExItem.name),
                                              borderRadius: 18.0,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          height: 8.0,
                                        ),
                                        Text(
                                          aiExItem.name,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
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
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText,
                                                fontSize: 14.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                                lineHeight: 1.4,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).divide(SizedBox(width: 16.0)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
