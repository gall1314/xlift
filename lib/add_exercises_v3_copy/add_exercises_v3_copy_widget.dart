import '/auth/supabase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/instant_timer.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'add_exercises_v3_copy_model.dart';
export 'add_exercises_v3_copy_model.dart';

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
class AddExercisesV3CopyWidget extends StatefulWidget {
  const AddExercisesV3CopyWidget({
    super.key,
    this.alreadySelceted,
    this.workoutName,
    required this.addUserEx,
  });

  final List<dynamic>? alreadySelceted;
  final String? workoutName;
  final bool? addUserEx;

  static String routeName = 'addExercisesV3Copy';
  static String routePath = '/addExercisesV3Copy';

  @override
  State<AddExercisesV3CopyWidget> createState() =>
      _AddExercisesV3CopyWidgetState();
}

class _AddExercisesV3CopyWidgetState extends State<AddExercisesV3CopyWidget> {
  late AddExercisesV3CopyModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddExercisesV3CopyModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (widget.addUserEx!) {
        _model.selected = widget.alreadySelceted!.toList().cast<dynamic>();
        safeSetState(() {});
      } else {
        _model.selected = widget.alreadySelceted!.toList().cast<dynamic>();
        safeSetState(() {});
      }

      if (FFAppState().workout) {
        _model.instantTimerHome = InstantTimer.periodic(
          duration: Duration(milliseconds: 1000),
          callback: (timer) async {
            FFAppState().activeWorkoutTime =
                functions.calculateElapsedTimeFormatted(
                    FFAppState().activeWorkoutStartTime!, getCurrentTimestamp);
            safeSetState(() {});
          },
          startImmediately: false,
        );
      } else {
        return;
      }
    });
  }

  @override
  void dispose() {
    // On page dispose action.
    () async {
      _model.instantTimerHome?.cancel();
    }();

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
            workoutName: widget.workoutName,
            originalSelection: widget.alreadySelceted,
            isLiveWorkout: false,
            onConfirm: (selected) async {
              _model.add =
                  await actions.initializeWorkoutExerciseSetsFromSelection(
                selected.toList(),
                FFAppState().exerciseSetsCreation.toList(),
              );
              FFAppState().exerciseSetsCreation =
                  _model.add!.toList().cast<dynamic>();
              safeSetState(() {});
              _model.rest1 = await actions.initializeExerciseRestTimes(
                FFAppState().exerciseSetsCreation.toList(),
              );
              FFAppState().restTimerCreation = _model.rest1!;
              safeSetState(() {});

              context.goNamed(
                CreateWorkoutV2Widget.routeName,
                queryParameters: {
                  'shouldInit': serializeParam(
                    false,
                    ParamType.bool,
                  ),
                  'alreadySelceted': serializeParam(
                    selected,
                    ParamType.JSON,
                    isList: true,
                  ),
                  'workoutName': serializeParam(
                    widget.workoutName,
                    ParamType.String,
                  ),
                }.withoutNulls,
              );

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
