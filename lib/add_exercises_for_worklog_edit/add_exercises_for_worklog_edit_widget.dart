import '/auth/supabase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_exercises_for_worklog_edit_model.dart';
export 'add_exercises_for_worklog_edit_model.dart';

/// Create a page, Create a clean, modern “Add Exercises” screen in a light
/// theme.
///
/// Top app bar: left text button “Cancel”, centered title “Add Exercises”,
/// right text button “Done”.
/// Below, a rounded search bar labeled “Search exercise”. Under it, two large
/// pill-shaped filter buttons (e.g. “All Equipment”, “All Muscles”) with soft
/// borders.
/// Main content: scrollable list of exercises. Each row is a flat card with:
/// small muscle illustration on the left, bold exercise name, smaller gray
/// muscle group text under it. On the right, a circular icon button (plus or
/// arrow). Use generous vertical spacing and subtle separators.
/// When an exercise is selected, highlight the row with a slim colored bar on
/// the left and slightly tinted background.
/// Bottom: fixed full-width primary button with rounded corners, text like
/// “Add selected exercises”. Overall style: airy, iOS-like typography, light
/// grays, and a vibrant accent color that matches the main app.
class AddExercisesForWorklogEditWidget extends StatefulWidget {
  const AddExercisesForWorklogEditWidget({
    super.key,
    this.alreadySelceted,
    this.workoutLOgId,
  });

  final List<dynamic>? alreadySelceted;
  final String? workoutLOgId;

  static String routeName = 'addExercisesForWorklogEdit';
  static String routePath = '/addExercisesForWorklogEdit';

  @override
  State<AddExercisesForWorklogEditWidget> createState() =>
      _AddExercisesForWorklogEditWidgetState();
}

class _AddExercisesForWorklogEditWidgetState
    extends State<AddExercisesForWorklogEditWidget> {
  late AddExercisesForWorklogEditModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddExercisesForWorklogEditModel());
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
        body: Container(
          width: MediaQuery.sizeOf(context).width * 1.0,
          height: MediaQuery.sizeOf(context).height * 1.0,
          child: custom_widgets.ExercisePickerView(
            width: MediaQuery.sizeOf(context).width * 1.0,
            height: MediaQuery.sizeOf(context).height * 1.0,
            userId: currentUserUid,
            languageCode: FFLocalizations.of(context).languageCode,
            isLiveWorkout: true,
            originalSelection: widget.alreadySelceted,
            liveExerciseSets: FFAppState().exerciseSetsCreation,
            isPremium: false,
            onConfirm: (selected) async {
              _model.addedCopy =
                  await actions.addExercisesToExerciseSetsInWorkout(
                FFAppState().exerciseSetsCreation.toList(),
                selected.toList(),
              );
              FFAppState().exerciseSetsCreation =
                  _model.addedCopy!.toList().cast<dynamic>();
              safeSetState(() {});
              context.safePop();

              safeSetState(() {});
            },
            onOpenDetails: (exerciseId) async {
              context.pushNamed(
                ExerciseHistoryWidget.routeName,
                queryParameters: {
                  'exerciseId': serializeParam(
                    exerciseId,
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
            },
            onOpenCustomDetails: (exerciseId) async {
              context.pushNamed(
                ExerciseHistoryCustomWidget.routeName,
                queryParameters: {
                  'exerciseId': serializeParam(
                    exerciseId,
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
            },
            onCreate: () async {
              context.pushNamed(CreateUserExerciseWidget.routeName);
            },
            onBack: () async {
              context.safePop();
            },
            onLockedTap: () async {},
          ),
        ),
      ),
    );
  }
}
