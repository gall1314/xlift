import '/backend/sqlite/sqlite_manager.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/instant_timer.dart';
import '/index.dart';
import 'add_exercises_for_edit_widget.dart' show AddExercisesForEditWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AddExercisesForEditModel
    extends FlutterFlowModel<AddExercisesForEditWidget> {
  ///  Local state fields for this page.

  List<int> selected = [];
  void addToSelected(int item) => selected.add(item);
  void removeFromSelected(int item) => selected.remove(item);
  void removeAtIndexFromSelected(int index) => selected.removeAt(index);
  void insertAtIndexInSelected(int index, int item) =>
      selected.insert(index, item);
  void updateSelectedAtIndex(int index, Function(int) updateFn) =>
      selected[index] = updateFn(selected[index]);

  String primaryMuscle = 'All';

  String subMuscle = 'All';

  bool showSubMuscleDropdown = false;

  String? query;

  int? primaryId;

  bool aiOnly = false;

  ///  State fields for stateful widgets in this page.

  InstantTimer? instantTimerHome;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Custom Action - syncExerciseSetsWithSelectedIds] action in Button widget.
  List<dynamic>? updatedList;
  // Stores action output result for [Custom Action - syncExerciseRestTimesWithSelectedIds] action in Button widget.
  dynamic newRest;
  // Stores action output result for [Backend Call - SQLite (getUserExercise)] action in Text widget.
  List<GetUserExerciseRow>? exex;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    instantTimerHome?.cancel();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
