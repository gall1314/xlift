import '/auth/supabase_auth/auth_util.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/components/remove_exercise_from_workout_alert_widget.dart';
import '/components/reorder_creation_widget.dart';
import '/components/replace_new_widget.dart';
import '/components/superset_creation_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
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
        body: Builder(
          builder: (context) => Container(
            width: MediaQuery.sizeOf(context).width * 1.0,
            height: MediaQuery.sizeOf(context).height * 1.0,
            child: custom_widgets.WorkoutPage(
              width: MediaQuery.sizeOf(context).width * 1.0,
              height: MediaQuery.sizeOf(context).height * 1.0,
              workoutName: widget.workoutName,
              showCameraGuidance: false,
              mode: 'templateEdit',
              onBack: () async {
                context.safePop();
              },
              onFinish: (workoutName, workoutDate, durationMs) async {
                _model.saveCopy2 = await actions.updateWorkoutTemplate(
                  widget.workoutId!,
                  workoutName,
                  currentUserUid,
                  widget.alreadySelceted!.toList(),
                  FFAppState().exerciseSetsCreation.toList(),
                  FFAppState().loggedSetsCreation.toList(),
                  FFAppState().dropSetsCreation.toList(),
                  FFAppState().warmUpCreation.toList(),
                  FFAppState().restTimerCreation,
                );
                FFAppState().warmUpCreation = [];
                FFAppState().restTimerCreation = null;
                FFAppState().dropSetsCreation = [];
                FFAppState().loggedSetsCreation = [];
                FFAppState().exerciseSetsCreation = [];
                safeSetState(() {});

                context.pushNamed(MasterPageWidget.routeName);

                await actions.syncAllPending();

                safeSetState(() {});
              },
              onAddExercises: () async {
                context.pushNamed(AddExercisesForEditWidget.routeName);
              },
              onHeaderTap: (exerciseId) async {
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
              onCustomHeaderTap: (exerciseId) async {
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
              onReplaceExercise: (exerciseId) async {
                await showModalBottomSheet(
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  enableDrag: false,
                  context: context,
                  builder: (context) {
                    return GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      child: Padding(
                        padding: MediaQuery.viewInsetsOf(context),
                        child: ReplaceNewWidget(
                          exerciseId: 0,
                          workoutId: '',
                        ),
                      ),
                    );
                  },
                ).then((value) => safeSetState(() {}));
              },
              onSupersetTap: (exerciseId) async {
                await showModalBottomSheet(
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  enableDrag: false,
                  context: context,
                  builder: (context) {
                    return GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      child: Padding(
                        padding: MediaQuery.viewInsetsOf(context),
                        child: SupersetCreationWidget(
                          currentExerciseId: exerciseId,
                        ),
                      ),
                    );
                  },
                ).then((value) => safeSetState(() {}));
              },
              onViewHistory: (exerciseId) async {
                context.pushNamed(
                  ExerciseHistoryWidget.routeName,
                  queryParameters: {
                    'exerciseId': serializeParam(
                      exerciseId,
                      ParamType.int,
                    ),
                    'overview': serializeParam(
                      false,
                      ParamType.bool,
                    ),
                    'analytics': serializeParam(
                      false,
                      ParamType.bool,
                    ),
                  }.withoutNulls,
                );
              },
              onCustomViewHistory: (exerciseId) async {
                context.pushNamed(
                  ExerciseHistoryCustomWidget.routeName,
                  queryParameters: {
                    'exerciseId': serializeParam(
                      exerciseId,
                      ParamType.int,
                    ),
                    'overview': serializeParam(
                      false,
                      ParamType.bool,
                    ),
                    'analytics': serializeParam(
                      false,
                      ParamType.bool,
                    ),
                  }.withoutNulls,
                );
              },
              onReorder: () async {
                await showModalBottomSheet(
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  enableDrag: false,
                  context: context,
                  builder: (context) {
                    return GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      child: Padding(
                        padding: MediaQuery.viewInsetsOf(context),
                        child: ReorderCreationWidget(),
                      ),
                    );
                  },
                ).then((value) => safeSetState(() {}));
              },
              onRemoveExercise: (exerciseId) async {
                if (functions.exerciseHasLoggedValuesFlat(
                    FFAppState().loggedSetsCreation.toList(), exerciseId)) {
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
                          child: RemoveExerciseFromWorkoutAlertWidget(
                            exerciseId: exerciseId,
                            closeBottom: () async {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  _model.remove = await actions.removeExerciseFromExerciseSets(
                    FFAppState().exerciseSetsCreation.toList(),
                    exerciseId,
                  );
                  FFAppState().exerciseSetsCreation =
                      _model.remove!.toList().cast<dynamic>();
                  safeSetState(() {});
                  Navigator.pop(context);
                }

                safeSetState(() {});
              },
              onResultTap: (exerciseId, exerciseName, setNumber, video,
                  setLogId) async {},
              onLockTap: () async {},
              onStartRest:
                  (exerciseId, exerciseName, setNumber, restMs) async {},
              onDontShowAgain: () async {},
            ),
          ),
        ),
      ),
    );
  }
}
