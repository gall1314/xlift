import '/backend/sqlite/sqlite_manager.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'edit_workout_v2_model.dart';
export 'edit_workout_v2_model.dart';

/// Create a page, Create a clean, modern **“Create Workout”** screen in a
/// light theme.
///
/// Top app bar: back arrow on the left, centered title “Create Workout”,
/// subtle shadow.
/// Below: full-width text field labeled “Workout name” (rounded corners, soft
/// border).
/// Main area: empty state. Center an outline dumbbell icon inside a soft
/// card, with short text under it: “Get started by adding exercises to your
/// workout.” Use friendly, neutral wording.
/// At the bottom: a large rounded primary button **“+ Add exercise”** (full
/// width, fixed above the safe-area). Button is vibrant (teal/blue) with
/// white text.
/// Overall style: lots of white space, subtle gray dividers, medium-rounded
/// cards, iOS-like typography, calm fitness vibe. No exercise list yet – only
/// this empty state layout.
class EditWorkoutV2Widget extends StatefulWidget {
  const EditWorkoutV2Widget({
    super.key,
    this.alreadySelceted,
    required this.shouldInit,
    this.workoutName,
    required this.workoutId,
  });

  final List<dynamic>? alreadySelceted;
  final bool? shouldInit;
  final String? workoutName;
  final String? workoutId;

  static String routeName = 'editWorkoutV2';
  static String routePath = '/editWorkoutV2';

  @override
  State<EditWorkoutV2Widget> createState() => _EditWorkoutV2WidgetState();
}

class _EditWorkoutV2WidgetState extends State<EditWorkoutV2Widget> {
  late EditWorkoutV2Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditWorkoutV2Model());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (widget.shouldInit!) {
        _model.simp = await SQLiteManager.instance.getExercisesSimp(
          workoutId: widget.workoutId,
        );
        _model.sets = await SQLiteManager.instance.getExerciseSetsForWorkout(
          workoutId: widget.workoutId!,
        );
        _model.set1 = await actions.initializeExerciseSetsForEdit(
          _model.simp!.toList(),
          _model.sets!.toList(),
        );
        _model.drop1 = await actions.initializeDropSetsFromSave(
          _model.sets?.toList(),
          _model.simp?.toList(),
        );
        FFAppState().exerciseSetsCreation =
            _model.set1!.toList().cast<dynamic>();
        FFAppState().dropSetsCreation = _model.drop1!.toList().cast<dynamic>();
        safeSetState(() {});
        _model.rest1 = await actions.initializeExerciseRestTimes(
          FFAppState().exerciseSetsCreation.toList(),
        );
        FFAppState().restTimerCreation = _model.rest1!;
        safeSetState(() {});
      }
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
          child: custom_widgets.WorkoutPage(
            width: MediaQuery.sizeOf(context).width * 1.0,
            height: MediaQuery.sizeOf(context).height * 1.0,
            isLiveWorkout: false,
            isWorkoutLogEdit: false,
            isTemplateMode: true,
            workoutName: widget.workoutName,
            showCameraGuidance: false,
            onBack: () async {},
            onFinish: () async {},
            onAddExercises: () async {},
            onAddExercisesEdit: () async {
              context.pushNamed(AddExercisesForEditWidget.routeName);
            },
            onAddExercisesTemplate: () async {
              context.pushNamed(AddExercisesForWorklogEditWidget.routeName);
            },
            onSave: () async {},
            onWorkoutNameChanged: (name) async {},
            onWorkoutDateChanged: (date) async {},
            onDurationChanged: (minutes) async {},
            onHeaderTap: (exerciseId) async {},
            onCustomHeaderTap: (exerciseId) async {},
            onReplaceExercise: (exerciseId) async {},
            onSupersetTap: (exerciseId) async {},
            onViewHistory: (exerciseId) async {},
            onCustomViewHistory: (exerciseId) async {},
            onReorder: () async {},
            onRemoveExercise: (exerciseId) async {},
            onResultTap: (exerciseId, exerciseName, setNumber, video) async {},
            onLockTap: () async {},
            onStartRest: (exerciseId, exerciseName, setNumber, restMs) async {},
            onDontShowAgain: () async {},
          ),
        ),
      ),
    );
  }
}
