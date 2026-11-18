import '/auth/supabase_auth/auth_util.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'prof_edit_v2_model.dart';
export 'prof_edit_v2_model.dart';

/// Design a clean, minimal Edit Profile mobile screen for a fitness app,
/// inspired by modern apps like Hevy,
/// This screen should focus on identity only, not body measurements.
///
/// Layout:
///
/// Very light background, no cards-heavy look.
///
/// Top app bar with back arrow on the left and “Done” text button on the
/// right.
///
/// Centered circular profile avatar at the top.
///
/// Text button below avatar: “Change Picture”.
///
/// Sections:
///
/// Section title: “Public profile data”.
///
/// Text input: Name
///
/// Optional multiline text input: Bio
///
/// Section title: “Private data”.
///
/// Row item: Sex with “Select” action on the right.
///
/// Row item: Birthday with “Select” action on the right.
///
/// Behavior:
///
/// No save button at the bottom.
///
/// Changes are confirmed via the “Done” button.
///
/// No height, weight, or body metrics on this screen.
///
/// Style:
///
/// Very clean, airy layout with generous vertical spacing.
///
/// iOS-style list rows for selectable fields.
///
/// Subtle separators, no heavy borders.
///
/// Calm, premium, modern fitness app aesthetic.
///
/// MVP-ready, simple, and elegant.
class ProfEditV2Widget extends StatefulWidget {
  const ProfEditV2Widget({super.key});

  static String routeName = 'profEditV2';
  static String routePath = '/profEditV2';

  @override
  State<ProfEditV2Widget> createState() => _ProfEditV2WidgetState();
}

class _ProfEditV2WidgetState extends State<ProfEditV2Widget> {
  late ProfEditV2Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfEditV2Model());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.user = await SQLiteManager.instance.user(
        userId: currentUserUid,
      );
      _model.birthday = _model.user?.firstOrNull?.dateOfBirth;
      _model.sex = _model.user?.firstOrNull?.sex;
      _model.weight = _model.user?.firstOrNull?.weight;
      _model.height = _model.height;
      _model.isBodyweightKg =
          _model.user?.firstOrNull?.bodyWeightIsKg == 1 ? true : false;
      _model.isHeightCm =
          _model.user?.firstOrNull?.heightIsCm == 1 ? true : false;
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
    context.watch<FFAppState>();

    return FutureBuilder<List<UserRow>>(
      future: SQLiteManager.instance.user(
        userId: currentUserUid,
      ),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
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
        final profEditV2UserRowList = snapshot.data!;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            body: Container(
              width: MediaQuery.sizeOf(context).width * 1.0,
              height: MediaQuery.sizeOf(context).height * 1.0,
              child: custom_widgets.ProfileEditView(
                width: MediaQuery.sizeOf(context).width * 1.0,
                height: MediaQuery.sizeOf(context).height * 1.0,
                username: _model.user?.firstOrNull?.username,
                sex: profEditV2UserRowList.firstOrNull?.sex,
                dateOfBirth: profEditV2UserRowList.firstOrNull?.dateOfBirth,
                bodyHeight: profEditV2UserRowList.firstOrNull?.height,
                heightIsCm: _model.isHeightCm,
                weight: profEditV2UserRowList.firstOrNull?.weight,
                weightIsKg: FFAppState().bodyWeightIsKg,
                photoFileName: FFAppState().profile,
                onBack: () async {
                  context.safePop();
                },
                onSave: (username, sex, dateOfBirth, height, heightIsCm, weight,
                    weightIsKg, workoutIsKg, photo) async {
                  _model.inernetCopy = await actions.checkInternet();
                  if (_model.inernetCopy!) {
                    await UsersTable().update(
                      data: {
                        'username': username,
                        'date_of_birth': supaSerialize<DateTime>(
                            functions.isoStringToDateTime(dateOfBirth)),
                        'sex': sex,
                        'weight': weight,
                        'height': height,
                        'height_is_cm': FFAppState().heightIsCm ? 1 : 0,
                        'body_weight_is_kg':
                            FFAppState().bodyWeightIsKg ? 1 : 0,
                        'profile_image_url': photo,
                      },
                      matchingRows: (rows) => rows.eqOrNull(
                        'id',
                        currentUserUid,
                      ),
                    );
                    await SQLiteManager.instance.updateUsersMeasurs(
                      userId: currentUserUid,
                      height: height,
                      weight: weight,
                      heightIsCm: _model.isHeightCm ? 1 : 0,
                      bodyWeightIsKg: _model.isBodyweightKg ? 1 : 0,
                      sex: _model.sex,
                      dateOfBirth: dateOfBirth,
                    );
                    if (_model.tempProf != null && _model.tempProf != '') {
                      FFAppState().profile = photo;
                      safeSetState(() {});
                    }
                    context.safePop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'no inernet',
                          style: TextStyle(
                            color: FlutterFlowTheme.of(context).primaryText,
                          ),
                        ),
                        duration: Duration(milliseconds: 4000),
                        backgroundColor: FlutterFlowTheme.of(context).secondary,
                      ),
                    );
                  }

                  safeSetState(() {});
                },
                onUnitsChanged: (units) async {
                  FFAppState().isKg = getJsonField(
                    units,
                    r'''$["workout_is_kg"]''',
                  );
                  FFAppState().heightIsCm = getJsonField(
                    units,
                    r'''$["height_is_cm"]''',
                  );
                  FFAppState().bodyWeightIsKg = getJsonField(
                    units,
                    r'''$["weight_is_kg"]''',
                  );
                  safeSetState(() {});
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
