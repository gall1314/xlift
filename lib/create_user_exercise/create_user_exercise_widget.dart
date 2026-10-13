import '/auth/supabase_auth/auth_util.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/components/eqypment_shit_widget.dart';
import '/components/exercyse_type_bottom_widget.dart';
import '/components/muscle_group_dropdown_widget.dart';
import '/components/sub_muscle_bottom_shit_widget.dart';
import '/components/sub_muscles_full_checkbox_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'create_user_exercise_model.dart';
export 'create_user_exercise_model.dart';

/// Create a page, Create a full-page “Create Exercise” screen that closely
/// follows the HEVY app design.
///
/// Use a clean white background with minimal dividers and no cards or rounded
/// containers. At the top place a navigation bar with a back button, centered
/// title “Create Exercise”, and a blue “Save” button on the right. Below,
/// center a large circular photo placeholder with a thin gray stroke and a
/// small camera icon inside, followed by a blue “Add Asset” text link.
/// Under this, recreate HEVY-style input rows: a light gray section title
/// such as “Exercise Name”, then a simple row: left-aligned label in black,
/// and a blue “Select” value on the next line. Each field should be separated
/// by thin iOS-style dividers. Keep spacing minimal, flat, and native
/// iOS-like. No cards, no shadows, no rounded boxes. The structure must look
/// almost identical to HEVY: clean, flat, simple typography, thin dividers,
/// and lightweight UI.
class CreateUserExerciseWidget extends StatefulWidget {
  const CreateUserExerciseWidget({
    super.key,
    this.alreadySelected,
    this.workoutName,
  });

  final List<dynamic>? alreadySelected;
  final String? workoutName;

  static String routeName = 'createUserExercise';
  static String routePath = '/createUserExercise';

  @override
  State<CreateUserExerciseWidget> createState() =>
      _CreateUserExerciseWidgetState();
}

class _CreateUserExerciseWidgetState extends State<CreateUserExerciseWidget> {
  late CreateUserExerciseModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CreateUserExerciseModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    _model.switchValue = false;
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            borderRadius: 0.0,
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
              'nqz65u4k' /* Create Exercise */,
            ),
            style: FlutterFlowTheme.of(context).titleMedium.override(
                  font: GoogleFonts.interTight(
                    fontWeight: FontWeight.w600,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleMedium.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontSize: 16.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                  fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                ),
          ),
          actions: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(10.0, 10.0, 10.0, 10.0),
              child: FFButtonWidget(
                onPressed: () async {
                  _model.nameError =
                      functions.hasNameError(_model.textController.text);
                  _model.nulltype = functions.hasTypeError(_model.type);
                  _model.muscleErorr =
                      functions.hasPrimaryMuscleError(_model.hasPrimaryMuscle);
                  _model.submitAttempted = true;
                  safeSetState(() {});
                  if (functions.canSaveUserExercise(_model.textController.text,
                      _model.primaryMuscle!, _model.type)!) {
                    _model.idCopy = await actions.generateUniqueExerciseId();
                    await SQLiteManager.instance.createUserExercise(
                      id: _model.idCopy!,
                      userId: currentUserUid,
                      name: _model.textController.text,
                      equipment: 'Dumbbell',
                      isBodyweight: _model.isBodyweight,
                      isTimed: _model.isTimed,
                      allowsBodyweight: _model.allowBodyweight,
                      illustration: _model.tempPhoto?.originalFilename,
                    );
                    _model.id2Copy = await actions.generateUniqueExerciseId();
                    await SQLiteManager.instance.userExerciseMuscleGroup(
                      id: _model.id2Copy!,
                      muscleGroupId: getJsonField(
                        _model.primaryMuscle,
                        r'''$["id"]''',
                      ),
                      exerciseId: _model.idCopy!,
                      isPrimary: 1,
                    );
                    for (int loop1Index = 0;
                        loop1Index <
                            _model.secondaryMuscels
                                .map((e) => e)
                                .toList()
                                .length;
                        loop1Index++) {
                      final currentLoop1Item = _model.secondaryMuscels
                          .map((e) => e)
                          .toList()[loop1Index];
                      _model.id3 = await actions.generateUniqueExerciseId();
                      await SQLiteManager.instance.userExerciseMuscleGroup(
                        id: _model.id3!,
                        muscleGroupId: getJsonField(
                          currentLoop1Item,
                          r'''$["id"]''',
                        ),
                        exerciseId: _model.idCopy!,
                        isPrimary: 0,
                      );
                    }

                    context.goNamed(
                      AddExercisesV3Widget.routeName,
                      queryParameters: {
                        'adduserEx': serializeParam(
                          functions.addExerciseToSelected(
                              widget.alreadySelected?.toList(),
                              _model.idCopy!,
                              _model.textController.text),
                          ParamType.JSON,
                          isList: true,
                        ),
                        'addUserEx': serializeParam(
                          true,
                          ParamType.bool,
                        ),
                        'workoutName': serializeParam(
                          widget.workoutName,
                          ParamType.String,
                        ),
                        'alreadySelceted': serializeParam(
                          widget.alreadySelected,
                          ParamType.JSON,
                          isList: true,
                        ),
                      }.withoutNulls,
                    );
                  } else {
                    safeSetState(() {});
                  }

                  safeSetState(() {});
                },
                text: FFLocalizations.of(context).getText(
                  '72373tu5' /* Create */,
                ),
                options: FFButtonOptions(
                  height: 12.0,
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  iconPadding:
                      EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  color: FlutterFlowTheme.of(context).primary,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        font: GoogleFonts.interTight(
                          fontWeight: FlutterFlowTheme.of(context)
                              .titleSmall
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).titleSmall.fontStyle,
                        ),
                        color: Colors.white,
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).titleSmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleSmall.fontStyle,
                      ),
                  elevation: 0.0,
                  borderSide: BorderSide(
                    width: 0.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ],
          centerTitle: true,
          elevation: 1.0,
        ),
        body: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 32.0, 0.0, 32.0),
                  child: Container(
                    width: 180.0,
                    height: 180.0,
                    child: custom_widgets.ExerciseImagePicker(
                      width: 180.0,
                      height: 180.0,
                      size: 180.0,
                      existingIllustration: '',
                      onImagePicked: (image) async {
                        _model.tempPhoto = image;
                        safeSetState(() {});
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional(0.0, -1.0),
                          child: Container(
                            width: MediaQuery.sizeOf(context).width * 1.0,
                            child: TextFormField(
                              controller: _model.textController,
                              focusNode: _model.textFieldFocusNode,
                              autofocus: false,
                              enabled: true,
                              obscureText: false,
                              decoration: InputDecoration(
                                isDense: true,
                                labelStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                hintText: _model.nameError
                                    ? 'Please Enter Exercise Name'
                                    : 'Exercise Name',
                                hintStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: _model.nameError
                                          ? FlutterFlowTheme.of(context).error
                                          : FlutterFlowTheme.of(context)
                                              .secondaryText,
                                      fontSize: _model.nameError ? 12.0 : 18.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x00000000),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x00000000),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
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
                                  FlutterFlowTheme.of(context).primaryText,
                              enableInteractiveSelection: true,
                              validator: _model.textControllerValidator
                                  .asValidator(context),
                            ),
                          ),
                        ),
                      ),
                      Divider(
                        height: 0.5,
                        thickness: 0.8,
                        indent: 16.0,
                        color: FlutterFlowTheme.of(context).alternate,
                      ),
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
                                  FocusScope.of(context).unfocus();
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                                child: Padding(
                                  padding: MediaQuery.viewInsetsOf(context),
                                  child: MuscleGroupDropdownWidget(
                                    selected: getJsonField(
                                      _model.primaryMuscle,
                                      r'''$["name"]''',
                                    ).toString(),
                                    callback: (selected, id) async {
                                      _model.primaryMuscle = <String, dynamic>{
                                        'name': selected,
                                        'id': id,
                                      };
                                      _model.hasPrimaryMuscle = true;
                                      safeSetState(() {});
                                    },
                                    subMusceldBottom: (primaryId) async {
                                      await showModalBottomSheet(
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        enableDrag: false,
                                        context: context,
                                        builder: (context) {
                                          return GestureDetector(
                                            onTap: () {
                                              FocusScope.of(context).unfocus();
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                            },
                                            child: Padding(
                                              padding: MediaQuery.viewInsetsOf(
                                                  context),
                                              child: SubMuscleBottomShitWidget(
                                                selected: getJsonField(
                                                  _model.subMuscle,
                                                  r'''$["name"]''',
                                                ).toString(),
                                                primaryId: primaryId,
                                                callback: (selected, id) async {
                                                  _model.primaryMuscle =
                                                      <String, dynamic>{
                                                    'name': selected,
                                                    'id': id,
                                                  };
                                                  _model.hasPrimaryMuscle =
                                                      true;
                                                  safeSetState(() {});
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ).then((value) => safeSetState(() {}));
                                    },
                                  ),
                                ),
                              );
                            },
                          ).then((value) => safeSetState(() {}));
                        },
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'bsm5jymd' /* Primary Muscels */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.inter(
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                        fontSize: 17.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 2.0, 0.0, 0.0),
                                  child: Text(
                                    functions.getPrimaryMuscleLabel(
                                        _model.submitAttempted,
                                        _model.hasPrimaryMuscle,
                                        getJsonField(
                                          _model.primaryMuscle,
                                          r'''$["name"]''',
                                        ).toString()),
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: functions
                                                  .shouldShowPrimaryMuscleError(
                                                      _model.submitAttempted,
                                                      _model.hasPrimaryMuscle,
                                                      getJsonField(
                                                        _model.primaryMuscle,
                                                        r'''$["name"]''',
                                                      ).toString())
                                              ? FlutterFlowTheme.of(context)
                                                  .error
                                              : FlutterFlowTheme.of(context)
                                                  .primary,
                                          fontSize: 17.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Divider(
                        height: 0.5,
                        thickness: 0.8,
                        indent: 16.0,
                        color: FlutterFlowTheme.of(context).alternate,
                      ),
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
                                  FocusScope.of(context).unfocus();
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                                child: Padding(
                                  padding: MediaQuery.viewInsetsOf(context),
                                  child: EqypmentShitWidget(
                                    selected: _model.equipment,
                                    callback: (selected) async {
                                      _model.equipment = selected;
                                      safeSetState(() {});
                                    },
                                  ),
                                ),
                              );
                            },
                          ).then((value) => safeSetState(() {}));
                        },
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Text(
                                      FFLocalizations.of(context).getText(
                                        'i1gvpvw9' /* Equipment */,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight: FontWeight.normal,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            fontSize: 17.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 2.0, 0.0, 0.0),
                                  child: Text(
                                    valueOrDefault<String>(
                                      _model.equipment == 'All'
                                          ? 'Select'
                                          : _model.equipment,
                                      '-',
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          fontSize: 17.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Divider(
                        height: 0.5,
                        thickness: 0.5,
                        indent: 16.0,
                        color: FlutterFlowTheme.of(context).alternate,
                      ),
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
                                  FocusScope.of(context).unfocus();
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                                child: Padding(
                                  padding: MediaQuery.viewInsetsOf(context),
                                  child: SubMusclesFullCheckboxWidget(
                                    selected: _model.secondaryMuscels,
                                    callback: (selected) async {
                                      _model.secondaryMuscels =
                                          selected.toList().cast<dynamic>();
                                      safeSetState(() {});
                                    },
                                  ),
                                ),
                              );
                            },
                          ).then((value) => safeSetState(() {}));
                        },
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    '75kamj2s' /* Secondary Muscels */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.inter(
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                        fontSize: 17.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 2.0, 0.0, 0.0),
                                      child: Text(
                                        functions.getSecondaryMusclesLabel(
                                            _model.secondaryMuscels.toList()),
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.inter(
                                                fontWeight: FontWeight.normal,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              fontSize: 17.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.normal,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                    if (_model.secondaryMuscels.length == 0)
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            8.0, 2.0, 0.0, 0.0),
                                        child: Text(
                                          FFLocalizations.of(context).getText(
                                            'is82pj6x' /* (optinal) */,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.inter(
                                                  fontWeight: FontWeight.normal,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText,
                                                fontSize: 17.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.normal,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Divider(
                        height: 0.5,
                        thickness: 0.8,
                        indent: 16.0,
                        color: FlutterFlowTheme.of(context).alternate,
                      ),
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
                                  FocusScope.of(context).unfocus();
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                                child: Padding(
                                  padding: MediaQuery.viewInsetsOf(context),
                                  child: ExercyseTypeBottomWidget(
                                    selected: _model.type,
                                    regular: () async {
                                      _model.type = 'Weight & Reps';
                                      _model.regular = true;
                                      safeSetState(() {});
                                    },
                                    bodyweight: () async {
                                      _model.type = 'Bodyweight';
                                      _model.isBodyweight = 1;
                                      _model.regular = false;
                                      safeSetState(() {});
                                    },
                                    timed: () async {
                                      _model.type = 'Timed';
                                      _model.isBodyweight = 1;
                                      _model.isTimed = 1;
                                      _model.regular = false;
                                      safeSetState(() {});
                                    },
                                    asissted: () async {
                                      _model.type = 'Asissted';
                                      _model.isAsissted = 1;
                                      _model.regular = false;
                                      safeSetState(() {});
                                    },
                                  ),
                                ),
                              );
                            },
                          ).then((value) => safeSetState(() {}));
                        },
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    '2i4tvohf' /* Exercise Type */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.inter(
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                        fontSize: 17.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 2.0, 0.0, 0.0),
                                  child: Text(
                                    functions.getExerciseTypeLabel(
                                        _model.nulltype, _model.type),
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: functions
                                                  .shouldShowExerciseTypeErrorColor(
                                                      _model.nulltype,
                                                      _model.type)
                                              ? FlutterFlowTheme.of(context)
                                                  .error
                                              : FlutterFlowTheme.of(context)
                                                  .primary,
                                          fontSize: 17.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_model.regular)
                        Divider(
                          height: 0.5,
                          thickness: 0.5,
                          indent: 16.0,
                          color: FlutterFlowTheme.of(context).alternate,
                        ),
                      if (_model.regular)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            FFLocalizations.of(context).getText(
                                              'j75z2nzd' /* Allows Bodyweight */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                  fontSize: 17.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.normal,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 2.0, 0.0, 0.0),
                                            child: Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                'ulryx0lr' /* Can be done without weight */,
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondaryText,
                                                        fontSize: 17.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch.adaptive(
                                      value: _model.switchValue!,
                                      onChanged: (newValue) async {
                                        safeSetState(() =>
                                            _model.switchValue = newValue);
                                        if (newValue) {
                                          _model.allowBodyweight = 1;
                                          safeSetState(() {});
                                        } else {
                                          _model.allowBodyweight = 0;
                                          safeSetState(() {});
                                        }
                                      },
                                      activeColor: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      activeTrackColor:
                                          FlutterFlowTheme.of(context).primary,
                                      inactiveTrackColor:
                                          FlutterFlowTheme.of(context)
                                              .alternate,
                                      inactiveThumbColor:
                                          FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ].divide(SizedBox(height: 10.0)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
