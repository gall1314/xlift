import '/auth/supabase_auth/auth_util.dart';
import '/components/camera_analyzer_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'package:flutter/material.dart';
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
    return Builder(
      builder: (context) => Container(
        width: MediaQuery.sizeOf(context).width * 1.0,
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: custom_widgets.AnalyzeExercisePicker(
          width: MediaQuery.sizeOf(context).width * 1.0,
          height: MediaQuery.sizeOf(context).height * 0.8,
          userId: currentUserUid,
          onPick: (exerciseId, exerciseName) async {
            await showDialog(
              context: context,
              builder: (dialogContext) {
                return Dialog(
                  elevation: 0,
                  insetPadding: EdgeInsets.zero,
                  backgroundColor: Colors.transparent,
                  alignment: AlignmentDirectional(0.0, 0.0)
                      .resolve(Directionality.of(context)),
                  child: CameraAnalyzerWidget(
                    exerciseId: exerciseId,
                    exerciseName: exerciseId.toString(),
                    analyze: (video, exerciseName, exerciseId) async {
                      context.pushNamed(
                        FullAnalyzingStatePageWidget.routeName,
                        queryParameters: {
                          'videoFile': serializeParam(
                            video,
                            ParamType.FFUploadedFile,
                          ),
                          'exerciseName': serializeParam(
                            exerciseName,
                            ParamType.String,
                          ),
                          'exerciseId': serializeParam(
                            exerciseId,
                            ParamType.int,
                          ),
                          'isBodyweight': serializeParam(
                            0,
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
          onClose: () async {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
