import '/backend/sqlite/sqlite_manager.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'add_exercises_mid_seission_widget.dart'
    show AddExercisesMidSeissionWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AddExercisesMidSeissionModel
    extends FlutterFlowModel<AddExercisesMidSeissionWidget> {
  ///  Local state fields for this page.

  List<dynamic> selected = [];
  void addToSelected(dynamic item) => selected.add(item);
  void removeFromSelected(dynamic item) => selected.remove(item);
  void removeAtIndexFromSelected(int index) => selected.removeAt(index);
  void insertAtIndexInSelected(int index, dynamic item) =>
      selected.insert(index, item);
  void updateSelectedAtIndex(int index, Function(dynamic) updateFn) =>
      selected[index] = updateFn(selected[index]);

  String primaryMuscle = 'All';

  String subMuscle = 'All';

  bool showSubMuscleDropdown = false;

  String? query;

  int? primaryId;

  bool aiOnly = false;

  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Custom Action - addExercisesToExerciseSetsInWorkout] action in Button widget.
  List<dynamic>? added;
  // Stores action output result for [Custom Action - addExercisesToRestTimes] action in Button widget.
  dynamic rest0;
  // Stores action output result for [Backend Call - SQLite (getUserExercise)] action in Text widget.
  List<GetUserExerciseRow>? exex;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
