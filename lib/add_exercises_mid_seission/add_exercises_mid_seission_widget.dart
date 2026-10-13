import '/auth/supabase_auth/auth_util.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/components/muscle_group_dropdownn_widget.dart';
import '/components/sub_muscle_bottom_shit_widget.dart';
import '/components/upgrade_alert_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/revenue_cat_util.dart' as revenue_cat;
import '/index.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'add_exercises_mid_seission_model.dart';
export 'add_exercises_mid_seission_model.dart';

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
class AddExercisesMidSeissionWidget extends StatefulWidget {
  const AddExercisesMidSeissionWidget({
    super.key,
    this.alreadySelceted,
    required this.workoutId,
    required this.addUserEx,
    this.userExlist,
  });

  final List<dynamic>? alreadySelceted;
  final String? workoutId;
  final bool? addUserEx;
  final List<dynamic>? userExlist;

  static String routeName = 'addExercisesMidSeission';
  static String routePath = '/addExercisesMidSeission';

  @override
  State<AddExercisesMidSeissionWidget> createState() =>
      _AddExercisesMidSeissionWidgetState();
}

class _AddExercisesMidSeissionWidgetState
    extends State<AddExercisesMidSeissionWidget> {
  late AddExercisesMidSeissionModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddExercisesMidSeissionModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (widget.addUserEx!) {
        _model.selected = widget.userExlist!.toList().cast<dynamic>();
        safeSetState(() {});
      } else {
        _model.selected = widget.alreadySelceted!.toList().cast<dynamic>();
        safeSetState(() {});
      }
    });

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
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
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: AppBar(
            backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
            iconTheme: IconThemeData(
                color: FlutterFlowTheme.of(context).secondaryText),
            automaticallyImplyLeading: false,
            leading: FlutterFlowIconButton(
              borderRadius: 8.0,
              buttonSize: 60.0,
              icon: Icon(
                Icons.chevron_left,
                color: FlutterFlowTheme.of(context).secondaryText,
                size: 30.0,
              ),
              onPressed: () async {
                context.safePop();
              },
            ),
            title: Text(
              FFLocalizations.of(context).getText(
                'e6mmratz' /* Add Exercises */,
              ),
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).primaryText,
                    fontSize: 16.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
            ),
            actions: [
              Align(
                alignment: AlignmentDirectional(0.0, 0.0),
                child: Builder(
                  builder: (context) => Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        _model.exex =
                            await SQLiteManager.instance.getUserExercise(
                          userId: currentUserUid,
                        );
                        if (_model.exex!.length < 3) {
                          context.pushNamed(
                              CreateUserExerciseMidSessionWidget.routeName);
                        } else {
                          final isEntitled =
                              await revenue_cat.isEntitled('Xliftfinal Pro') ??
                                  false;
                          if (!isEntitled) {
                            await revenue_cat.loadOfferings();
                          }

                          if (isEntitled) {
                            context.pushNamed(
                                CreateUserExerciseMidSessionWidget.routeName);
                          } else {
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
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                    },
                                    child: UpgradeAlertWidget(),
                                  ),
                                );
                              },
                            );
                          }
                        }

                        safeSetState(() {});
                      },
                      child: Text(
                        FFLocalizations.of(context).getText(
                          'y57lsxr5' /* Create */,
                        ),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: Color(0xFF20B2AA),
                              fontSize: 17.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            centerTitle: true,
            elevation: 1.0,
          ),
        ),
        body: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  decoration: BoxDecoration(),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 16.0, 0.0, 0.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Container(
                                width: double.infinity,
                                child: TextFormField(
                                  controller: _model.textController,
                                  focusNode: _model.textFieldFocusNode,
                                  onChanged: (_) => EasyDebounce.debounce(
                                    '_model.textController',
                                    Duration(milliseconds: 0),
                                    () async {
                                      _model.query = _model.textController.text;
                                      safeSetState(() {});
                                    },
                                  ),
                                  autofocus: false,
                                  textInputAction: TextInputAction.search,
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    hintText:
                                        FFLocalizations.of(context).getText(
                                      'nhg86t0p' /* Search exercise */,
                                    ),
                                    hintStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(24.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(24.0),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0x00000000),
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(24.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0x00000000),
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(24.0),
                                    ),
                                    filled: true,
                                    fillColor: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    contentPadding:
                                        EdgeInsetsDirectional.fromSTEB(
                                            20.0, 16.0, 20.0, 16.0),
                                    prefixIcon: Icon(
                                      Icons.search_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: 20.0,
                                    ),
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.inter(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                  cursorColor:
                                      FlutterFlowTheme.of(context).primary,
                                  validator: _model.textControllerValidator
                                      .asValidator(context),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Align(
                                      alignment:
                                          AlignmentDirectional(-1.0, 0.0),
                                      child: InkWell(
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
                                                  child:
                                                      MuscleGroupDropdownnWidget(
                                                    selected:
                                                        _model.primaryMuscle,
                                                    callback:
                                                        (selected, id) async {
                                                      _model.primaryMuscle =
                                                          selected;
                                                      _model.subMuscle = 'All';
                                                      _model.primaryId = id;
                                                      safeSetState(() {});
                                                    },
                                                    all: () async {
                                                      _model.subMuscle = 'All';
                                                      safeSetState(() {});
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                          ).then(
                                              (value) => safeSetState(() {}));
                                        },
                                        child: Container(
                                          width:
                                              MediaQuery.sizeOf(context).width *
                                                  0.5,
                                          height: 44.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                            borderRadius:
                                                BorderRadius.circular(22.0),
                                            border: Border.all(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .alternate,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(10.0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Expanded(
                                                  child: Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                            0.0, 0.0),
                                                    child: Text(
                                                      _model.primaryMuscle ==
                                                              'All'
                                                          ? 'All muscles'
                                                          : _model
                                                              .primaryMuscle,
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            font: GoogleFonts
                                                                .inter(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              fontStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                            ),
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if ((_model.primaryMuscle == 'Shoulders') ||
                                      (_model.primaryMuscle == 'Legs') ||
                                      (_model.primaryMuscle == 'Back'))
                                    Expanded(
                                      flex: 1,
                                      child: Align(
                                        alignment:
                                            AlignmentDirectional(-1.0, 0.0),
                                        child: InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () async {
                                            await showModalBottomSheet(
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
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
                                                    child:
                                                        SubMuscleBottomShitWidget(
                                                      selected:
                                                          _model.subMuscle,
                                                      primaryId:
                                                          _model.primaryId!,
                                                      callback:
                                                          (selected, id) async {
                                                        _model.subMuscle =
                                                            selected;
                                                        safeSetState(() {});
                                                      },
                                                    ),
                                                  ),
                                                );
                                              },
                                            ).then(
                                                (value) => safeSetState(() {}));
                                          },
                                          child: Container(
                                            width: MediaQuery.sizeOf(context)
                                                    .width *
                                                0.5,
                                            height: 45.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              borderRadius:
                                                  BorderRadius.circular(22.0),
                                              border: Border.all(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .alternate,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(10.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    child: Align(
                                                      alignment:
                                                          AlignmentDirectional(
                                                              0.0, 0.0),
                                                      child: Text(
                                                        _model.subMuscle,
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Stack(
                                    children: [
                                      if (!_model.aiOnly)
                                        Container(
                                          width: 40.0,
                                          height: 40.0,
                                          child: custom_widgets.AiFormButton(
                                            width: 40.0,
                                            height: 40.0,
                                            size: 40.0,
                                            iconSize: 24.0,
                                            gradientEndColor: Color(0xFF90969C),
                                            iconColor: Color(0xFF90969C),
                                            borderColor: Color(0xFF90969C),
                                            borderWidth: 2.0,
                                            enabled: true,
                                            onTap: () async {
                                              _model.aiOnly = true;
                                              safeSetState(() {});
                                            },
                                          ),
                                        ),
                                      if (_model.aiOnly)
                                        Container(
                                          width: 40.0,
                                          height: 40.0,
                                          child: custom_widgets.AiFormButton(
                                            width: 40.0,
                                            height: 40.0,
                                            size: 40.0,
                                            iconSize: 24.0,
                                            backgroundColor:
                                                FlutterFlowTheme.of(context)
                                                    .primary,
                                            gradientEndColor:
                                                FlutterFlowTheme.of(context)
                                                    .tertiary,
                                            iconColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                            borderColor:
                                                FlutterFlowTheme.of(context)
                                                    .primary,
                                            borderWidth: 2.0,
                                            enabled: true,
                                            onTap: () async {
                                              _model.aiOnly = false;
                                              safeSetState(() {});
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                ].divide(SizedBox(width: 10.0)),
                              ),
                            ].divide(SizedBox(height: 16.0)),
                          ),
                        ),
                        FutureBuilder<List<GetRecentExercisesRow>>(
                          future: SQLiteManager.instance.getRecentExercises(
                            userId: currentUserUid,
                          ),
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
                            final containerGetRecentExercisesRowList =
                                snapshot.data!;

                            return Container(
                              width: MediaQuery.sizeOf(context).width * 11.0,
                              height: 620.0,
                              decoration: BoxDecoration(),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    if (functions
                                            .shouldShowWorkoutExercisesHeader(
                                                containerGetRecentExercisesRowList
                                                    .toList(),
                                                _model.query,
                                                _model.primaryMuscle,
                                                _model.subMuscle,
                                                FFAppState()
                                                    .exercisesets
                                                    .toList(),
                                                _model.aiOnly) ??
                                        true)
                                      Align(
                                        alignment:
                                            AlignmentDirectional(-1.0, 0.0),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 18.0, 0.0, 16.0),
                                          child: Text(
                                            FFLocalizations.of(context).getText(
                                              'gqsmh6b7' /* Recent Exercises */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .labelLarge
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelLarge
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelLarge
                                                            .fontStyle,
                                                  ),
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelLarge
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelLarge
                                                          .fontStyle,
                                                ),
                                          ),
                                        ),
                                      ),
                                    if (containerGetRecentExercisesRowList
                                        .isNotEmpty)
                                      Expanded(
                                        child: Builder(
                                          builder: (context) {
                                            final recents =
                                                containerGetRecentExercisesRowList
                                                    .map((e) => e)
                                                    .toList();

                                            return ListView.builder(
                                              padding: EdgeInsets.zero,
                                              primary: false,
                                              shrinkWrap: true,
                                              scrollDirection: Axis.vertical,
                                              itemCount: recents.length,
                                              itemBuilder:
                                                  (context, recentsIndex) {
                                                final recentsItem =
                                                    recents[recentsIndex];
                                                return Visibility(
                                                  visible: functions
                                                      .shouldShowExerciseDuringWorkout(
                                                          recentsItem
                                                              .exerciseName,
                                                          _model.query,
                                                          _model.primaryMuscle,
                                                          recentsItem
                                                              .primaryMuscle1,
                                                          recentsItem
                                                              .primaryMuscle2,
                                                          recentsItem
                                                              .subMuscle1,
                                                          recentsItem
                                                              .subMuscle2,
                                                          recentsItem
                                                              .subMuscle3,
                                                          _model.subMuscle,
                                                          recentsItem
                                                              .exerciseId,
                                                          FFAppState()
                                                              .exercisesets
                                                              .toList(),
                                                          _model.aiOnly,
                                                          recentsItem
                                                              .aiFormAnalysis),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                0.0, 10.0),
                                                    child: InkWell(
                                                      splashColor:
                                                          Colors.transparent,
                                                      focusColor:
                                                          Colors.transparent,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      onTap: () async {
                                                        _model.selected = functions
                                                            .toggleExerciseSelectionMid(
                                                                _model.selected
                                                                    .toList(),
                                                                recentsItem
                                                                    .exerciseId,
                                                                recentsItem
                                                                    .exerciseName,
                                                                recentsItem.isBodyweight ==
                                                                        0
                                                                    ? false
                                                                    : true)!
                                                            .toList()
                                                            .cast<dynamic>();
                                                        safeSetState(() {});
                                                        HapticFeedback
                                                            .selectionClick();
                                                      },
                                                      child: Container(
                                                        width: double.infinity,
                                                        height: 90.0,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryBackground,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      14.0),
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      16.0,
                                                                      16.0,
                                                                      16.0,
                                                                      16.0),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            children: [
                                                              if (functions.isExerciseSelected2(
                                                                  _model
                                                                      .selected
                                                                      .toList(),
                                                                  recentsItem
                                                                      .exerciseId))
                                                                Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          5.0,
                                                                          0.0),
                                                                  child:
                                                                      Container(
                                                                    width: 4.0,
                                                                    height:
                                                                        60.0,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primary,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              2.0),
                                                                    ),
                                                                  ),
                                                                ),
                                                              Container(
                                                                width: 60.0,
                                                                height: 60.0,
                                                                child: custom_widgets
                                                                    .ExerciseAssetImage(
                                                                  width: 60.0,
                                                                  height: 60.0,
                                                                  exerciseName:
                                                                      functions.exerciseImageName(
                                                                          recentsItem
                                                                              .exerciseName),
                                                                  borderRadius:
                                                                      8.0,
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Align(
                                                                      alignment:
                                                                          AlignmentDirectional(
                                                                              0.0,
                                                                              0.0),
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            0.0,
                                                                            4.0),
                                                                        child:
                                                                            Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          children:
                                                                              [
                                                                            Text(
                                                                              recentsItem.exerciseName,
                                                                              style: FlutterFlowTheme.of(context).titleMedium.override(
                                                                                    font: GoogleFonts.interTight(
                                                                                      fontWeight: FontWeight.w600,
                                                                                      fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                    ),
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FontWeight.w600,
                                                                                    fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                  ),
                                                                            ),
                                                                            if (recentsItem.aiFormAnalysis ==
                                                                                1)
                                                                              Container(
                                                                                width: 50.0,
                                                                                height: 28.0,
                                                                                child: custom_widgets.AiFormBadge(
                                                                                  width: 50.0,
                                                                                  height: 28.0,
                                                                                  showLabel: true,
                                                                                  isDark: Theme.of(context).brightness == Brightness.dark,
                                                                                  iconSize: 18.0,
                                                                                  color: FlutterFlowTheme.of(context).primary,
                                                                                ),
                                                                              ),
                                                                          ].divide(SizedBox(width: 8.0)),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      recentsItem
                                                                          .primaryMuscle1,
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodySmall
                                                                          .override(
                                                                            font:
                                                                                GoogleFonts.inter(
                                                                              fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                              fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                            ),
                                                                            color:
                                                                                FlutterFlowTheme.of(context).secondaryText,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                          ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              FlutterFlowIconButton(
                                                                borderColor:
                                                                    FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondaryText,
                                                                borderRadius:
                                                                    40.0,
                                                                borderWidth:
                                                                    2.0,
                                                                buttonSize:
                                                                    30.0,
                                                                icon: Icon(
                                                                  Icons
                                                                      .query_stats,
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                  size: 14.0,
                                                                ),
                                                                onPressed:
                                                                    () async {
                                                                  context
                                                                      .pushNamed(
                                                                    ExerciseHistoryWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'exerciseId':
                                                                          serializeParam(
                                                                        recentsItem
                                                                            .exerciseId,
                                                                        ParamType
                                                                            .int,
                                                                      ),
                                                                      'overview':
                                                                          serializeParam(
                                                                        true,
                                                                        ParamType
                                                                            .bool,
                                                                      ),
                                                                      'analytics':
                                                                          serializeParam(
                                                                        false,
                                                                        ParamType
                                                                            .bool,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                              ),
                                                            ].divide(SizedBox(
                                                                width: 16.0)),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    Expanded(
                                      child: FutureBuilder<
                                          List<GetUserExercisesRow>>(
                                        future: SQLiteManager.instance
                                            .getUserExercises(
                                          currentUserId: currentUserUid,
                                        ),
                                        builder: (context, snapshot) {
                                          // Customize what your widget looks like when it's loading.
                                          if (!snapshot.hasData) {
                                            return Center(
                                              child: SizedBox(
                                                width: 50.0,
                                                height: 50.0,
                                                child:
                                                    CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    FlutterFlowTheme.of(context)
                                                        .secondary,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                          final containerGetUserExercisesRowList =
                                              snapshot.data!;

                                          return Container(
                                            width: MediaQuery.sizeOf(context)
                                                    .width *
                                                1.0,
                                            decoration: BoxDecoration(),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                if (functions
                                                        .shouldShowWorkoutExercisesHeaderU(
                                                            containerGetUserExercisesRowList
                                                                .toList(),
                                                            _model.query,
                                                            _model
                                                                .primaryMuscle,
                                                            _model.subMuscle,
                                                            FFAppState()
                                                                .exercisesets
                                                                .toList(),
                                                            _model.aiOnly) ??
                                                    true)
                                                  Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                            -1.0, 0.0),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  16.0,
                                                                  18.0,
                                                                  0.0,
                                                                  16.0),
                                                      child: Text(
                                                        FFLocalizations.of(
                                                                context)
                                                            .getText(
                                                          'kt9efzhx' /* Custom Exercises */,
                                                        ),
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelLarge
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelLarge
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelLarge
                                                                        .fontStyle,
                                                                  ),
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelLarge
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelLarge
                                                                      .fontStyle,
                                                                ),
                                                      ),
                                                    ),
                                                  ),
                                                if (containerGetUserExercisesRowList
                                                    .isNotEmpty)
                                                  Expanded(
                                                    child: Builder(
                                                      builder: (context) {
                                                        final customs =
                                                            containerGetUserExercisesRowList
                                                                .map((e) => e)
                                                                .toList();

                                                        return ListView.builder(
                                                          padding:
                                                              EdgeInsets.zero,
                                                          primary: false,
                                                          shrinkWrap: true,
                                                          scrollDirection:
                                                              Axis.vertical,
                                                          itemCount:
                                                              customs.length,
                                                          itemBuilder: (context,
                                                              customsIndex) {
                                                            final customsItem =
                                                                customs[
                                                                    customsIndex];
                                                            return Visibility(
                                                              visible: functions.shouldShowExerciseDuringWorkout(
                                                                  customsItem
                                                                      .exerciseName,
                                                                  _model.query,
                                                                  _model
                                                                      .primaryMuscle,
                                                                  customsItem
                                                                      .primaryMuscle1,
                                                                  customsItem
                                                                      .primaryMuscle2,
                                                                  customsItem
                                                                      .subMuscle1,
                                                                  customsItem
                                                                      .subMuscle2,
                                                                  customsItem
                                                                      .subMuscle3,
                                                                  _model
                                                                      .subMuscle,
                                                                  customsItem
                                                                      .exerciseId,
                                                                  FFAppState()
                                                                      .exercisesets
                                                                      .toList(),
                                                                  _model.aiOnly,
                                                                  0),
                                                              child: Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            0.0,
                                                                            10.0),
                                                                child: InkWell(
                                                                  splashColor:
                                                                      Colors
                                                                          .transparent,
                                                                  focusColor: Colors
                                                                      .transparent,
                                                                  hoverColor: Colors
                                                                      .transparent,
                                                                  highlightColor:
                                                                      Colors
                                                                          .transparent,
                                                                  onTap:
                                                                      () async {
                                                                    _model.selected = functions
                                                                        .toggleExerciseSelectionMid(
                                                                            _model.selected
                                                                                .toList(),
                                                                            customsItem
                                                                                .exerciseId,
                                                                            customsItem
                                                                                .exerciseName,
                                                                            customsItem.isBodyweight == 0
                                                                                ? false
                                                                                : true)!
                                                                        .toList()
                                                                        .cast<
                                                                            dynamic>();
                                                                    safeSetState(
                                                                        () {});
                                                                    HapticFeedback
                                                                        .selectionClick();
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    width: double
                                                                        .infinity,
                                                                    height:
                                                                        90.0,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              14.0),
                                                                    ),
                                                                    child:
                                                                        Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          16.0,
                                                                          16.0,
                                                                          16.0,
                                                                          16.0),
                                                                      child:
                                                                          Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        children:
                                                                            [
                                                                          if (functions.isExerciseSelected2(
                                                                              _model.selected.toList(),
                                                                              customsItem.exerciseId))
                                                                            Padding(
                                                                              padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 5.0, 0.0),
                                                                              child: Container(
                                                                                width: 4.0,
                                                                                height: 60.0,
                                                                                decoration: BoxDecoration(
                                                                                  color: FlutterFlowTheme.of(context).primary,
                                                                                  borderRadius: BorderRadius.circular(2.0),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          Container(
                                                                            width:
                                                                                60.0,
                                                                            height:
                                                                                60.0,
                                                                            child:
                                                                                custom_widgets.ExerciseAssetImage(
                                                                              width: 60.0,
                                                                              height: 60.0,
                                                                              exerciseName: functions.exerciseImageName(customsItem.exerciseName),
                                                                              borderRadius: 8.0,
                                                                            ),
                                                                          ),
                                                                          Expanded(
                                                                            child:
                                                                                Column(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                Padding(
                                                                                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 4.0),
                                                                                  child: Text(
                                                                                    customsItem.exerciseName,
                                                                                    style: FlutterFlowTheme.of(context).titleMedium.override(
                                                                                          font: GoogleFonts.interTight(
                                                                                            fontWeight: FontWeight.w600,
                                                                                            fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                          ),
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FontWeight.w600,
                                                                                          fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                        ),
                                                                                  ),
                                                                                ),
                                                                                Text(
                                                                                  customsItem.primaryMuscle1,
                                                                                  style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                                        font: GoogleFonts.inter(
                                                                                          fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                        ),
                                                                                        color: FlutterFlowTheme.of(context).secondaryText,
                                                                                        letterSpacing: 0.0,
                                                                                        fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                        fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                      ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          FlutterFlowIconButton(
                                                                            borderColor:
                                                                                FlutterFlowTheme.of(context).secondaryText,
                                                                            borderRadius:
                                                                                40.0,
                                                                            borderWidth:
                                                                                2.0,
                                                                            buttonSize:
                                                                                30.0,
                                                                            icon:
                                                                                Icon(
                                                                              Icons.query_stats,
                                                                              color: FlutterFlowTheme.of(context).secondaryText,
                                                                              size: 14.0,
                                                                            ),
                                                                            onPressed:
                                                                                () async {
                                                                              context.pushNamed(
                                                                                ExerciseHistoryWidget.routeName,
                                                                                queryParameters: {
                                                                                  'exerciseId': serializeParam(
                                                                                    customsItem.exerciseId,
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
                                                                          ),
                                                                        ].divide(SizedBox(width: 16.0)),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        );
                                                      },
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.sizeOf(context).width *
                                          1.0,
                                      decoration: BoxDecoration(),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Align(
                                            alignment:
                                                AlignmentDirectional(-1.0, 0.0),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      16.0, 18.0, 0.0, 16.0),
                                              child: Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  't0s77qqf' /* All Exercises */,
                                                ),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .labelLarge
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelLarge
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelLarge
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelLarge
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelLarge
                                                                  .fontStyle,
                                                        ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: FutureBuilder<
                                                List<GetAllExercisesRow>>(
                                              future: SQLiteManager.instance
                                                  .getAllExercises(),
                                              builder: (context, snapshot) {
                                                // Customize what your widget looks like when it's loading.
                                                if (!snapshot.hasData) {
                                                  return Center(
                                                    child: SizedBox(
                                                      width: 50.0,
                                                      height: 50.0,
                                                      child:
                                                          CircularProgressIndicator(
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                Color>(
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondary,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }
                                                final listViewGetAllExercisesRowList =
                                                    snapshot.data!;

                                                return ListView.builder(
                                                  padding: EdgeInsets.zero,
                                                  primary: false,
                                                  shrinkWrap: true,
                                                  scrollDirection:
                                                      Axis.vertical,
                                                  itemCount:
                                                      listViewGetAllExercisesRowList
                                                          .length,
                                                  itemBuilder:
                                                      (context, listViewIndex) {
                                                    final listViewGetAllExercisesRow =
                                                        listViewGetAllExercisesRowList[
                                                            listViewIndex];
                                                    return Visibility(
                                                      visible: functions.shouldShowExerciseDuringWorkout(
                                                          listViewGetAllExercisesRow
                                                              .exerciseName,
                                                          _model.query,
                                                          _model.primaryMuscle,
                                                          listViewGetAllExercisesRow
                                                              .primaryMuscle1,
                                                          listViewGetAllExercisesRow
                                                              .primaryMuscle2,
                                                          listViewGetAllExercisesRow
                                                              .subMuscle1!,
                                                          listViewGetAllExercisesRow
                                                              .subMuscle2,
                                                          listViewGetAllExercisesRow
                                                              .subMuscle3,
                                                          _model.subMuscle,
                                                          listViewGetAllExercisesRow
                                                              .exerciseId,
                                                          FFAppState()
                                                              .exercisesets
                                                              .toList(),
                                                          _model.aiOnly,
                                                          listViewGetAllExercisesRow
                                                              .aiFormAnalysis),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    0.0,
                                                                    0.0,
                                                                    0.0,
                                                                    10.0),
                                                        child: InkWell(
                                                          splashColor: Colors
                                                              .transparent,
                                                          focusColor: Colors
                                                              .transparent,
                                                          hoverColor: Colors
                                                              .transparent,
                                                          highlightColor: Colors
                                                              .transparent,
                                                          onTap: () async {
                                                            _model.selected = functions
                                                                .toggleExerciseSelectionMid(
                                                                    _model
                                                                        .selected
                                                                        .toList(),
                                                                    listViewGetAllExercisesRow
                                                                        .exerciseId,
                                                                    listViewGetAllExercisesRow
                                                                        .exerciseName,
                                                                    listViewGetAllExercisesRow.isBodyweight ==
                                                                            0
                                                                        ? false
                                                                        : true)!
                                                                .toList()
                                                                .cast<
                                                                    dynamic>();
                                                            safeSetState(() {});
                                                            HapticFeedback
                                                                .selectionClick();
                                                          },
                                                          child: Container(
                                                            width:
                                                                double.infinity,
                                                            height: 90.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondaryBackground,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          14.0),
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          16.0,
                                                                          16.0,
                                                                          16.0,
                                                                          16.0),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                children: [
                                                                  if (functions.isExerciseSelected2(
                                                                      _model
                                                                          .selected
                                                                          .toList(),
                                                                      listViewGetAllExercisesRow
                                                                          .exerciseId))
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          5.0,
                                                                          0.0),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            4.0,
                                                                        height:
                                                                            60.0,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color:
                                                                              FlutterFlowTheme.of(context).primary,
                                                                          borderRadius:
                                                                              BorderRadius.circular(2.0),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  Container(
                                                                    width: 60.0,
                                                                    height:
                                                                        60.0,
                                                                    child: custom_widgets
                                                                        .ExerciseAssetImage(
                                                                      width:
                                                                          60.0,
                                                                      height:
                                                                          60.0,
                                                                      exerciseName:
                                                                          functions
                                                                              .exerciseImageName(listViewGetAllExercisesRow.exerciseName),
                                                                      borderRadius:
                                                                          8.0,
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    child:
                                                                        Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Align(
                                                                          alignment: AlignmentDirectional(
                                                                              0.0,
                                                                              0.0),
                                                                          child:
                                                                              Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                0.0,
                                                                                0.0,
                                                                                0.0,
                                                                                4.0),
                                                                            child:
                                                                                Row(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              children: [
                                                                                Text(
                                                                                  listViewGetAllExercisesRow.exerciseName,
                                                                                  style: FlutterFlowTheme.of(context).titleMedium.override(
                                                                                        font: GoogleFonts.interTight(
                                                                                          fontWeight: FontWeight.w600,
                                                                                          fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                        ),
                                                                                        letterSpacing: 0.0,
                                                                                        fontWeight: FontWeight.w600,
                                                                                        fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                      ),
                                                                                ),
                                                                                if (listViewGetAllExercisesRow.aiFormAnalysis == 1)
                                                                                  Container(
                                                                                    width: 50.0,
                                                                                    height: 28.0,
                                                                                    child: custom_widgets.AiFormBadge(
                                                                                      width: 50.0,
                                                                                      height: 28.0,
                                                                                      showLabel: true,
                                                                                      isDark: Theme.of(context).brightness == Brightness.dark,
                                                                                      iconSize: 18.0,
                                                                                      color: FlutterFlowTheme.of(context).primary,
                                                                                    ),
                                                                                  ),
                                                                              ].divide(SizedBox(width: 8.0)),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            listViewGetAllExercisesRow.primaryMuscle1,
                                                                            '-',
                                                                          ),
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .bodySmall
                                                                              .override(
                                                                                font: GoogleFonts.inter(
                                                                                  fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                ),
                                                                                color: FlutterFlowTheme.of(context).secondaryText,
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                              ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  FlutterFlowIconButton(
                                                                    borderColor:
                                                                        FlutterFlowTheme.of(context)
                                                                            .secondaryText,
                                                                    borderRadius:
                                                                        40.0,
                                                                    borderWidth:
                                                                        2.0,
                                                                    buttonSize:
                                                                        30.0,
                                                                    icon: Icon(
                                                                      Icons
                                                                          .query_stats,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryText,
                                                                      size:
                                                                          14.0,
                                                                    ),
                                                                    onPressed:
                                                                        () async {
                                                                      context
                                                                          .pushNamed(
                                                                        ExerciseHistoryWidget
                                                                            .routeName,
                                                                        queryParameters:
                                                                            {
                                                                          'exerciseId':
                                                                              serializeParam(
                                                                            listViewGetAllExercisesRow.exerciseId,
                                                                            ParamType.int,
                                                                          ),
                                                                          'overview':
                                                                              serializeParam(
                                                                            true,
                                                                            ParamType.bool,
                                                                          ),
                                                                          'analytics':
                                                                              serializeParam(
                                                                            false,
                                                                            ParamType.bool,
                                                                          ),
                                                                        }.withoutNulls,
                                                                      );
                                                                    },
                                                                  ),
                                                                ].divide(SizedBox(
                                                                    width:
                                                                        16.0)),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_model.selected.length > 0)
              Align(
                alignment: AlignmentDirectional(0.0, 1.0),
                child: Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 16.0),
                  child: FFButtonWidget(
                    onPressed: () async {
                      _model.added =
                          await actions.addExercisesToExerciseSetsInWorkout(
                        FFAppState().exercisesets.toList(),
                        _model.selected.toList(),
                      );
                      _model.rest0 = await actions.addExercisesToRestTimes(
                        FFAppState().restTimers,
                        _model.selected.toList(),
                      );
                      FFAppState().exercisesets =
                          _model.added!.toList().cast<dynamic>();
                      FFAppState().restTimers = _model.rest0!;
                      safeSetState(() {});

                      context.pushNamed(
                        WorkoutV2Widget.routeName,
                        queryParameters: {
                          'workoutId': serializeParam(
                            widget.workoutId,
                            ParamType.String,
                          ),
                        }.withoutNulls,
                      );

                      safeSetState(() {});
                    },
                    text: valueOrDefault<String>(
                      'Add ${_model.selected.length.toString()} ${_model.selected.length > 1 ? 'exercise' : 'exercise'}',
                      '9',
                    ),
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 52.0,
                      padding: EdgeInsets.all(8.0),
                      iconPadding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      color: FlutterFlowTheme.of(context).primary,
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
                      borderRadius: BorderRadius.circular(16.0),
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
