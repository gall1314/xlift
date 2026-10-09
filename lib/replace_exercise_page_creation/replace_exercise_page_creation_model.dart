import '/backend/sqlite/sqlite_manager.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'replace_exercise_page_creation_widget.dart'
    show ReplaceExercisePageCreationWidget;
import 'package:flutter/material.dart';

class ReplaceExercisePageCreationModel
    extends FlutterFlowModel<ReplaceExercisePageCreationWidget> {
  ///  Local state fields for this page.

  dynamic idToReplace;

  String primaryMuscle = 'All';

  String subMuscle = 'All';

  bool showSubMuscleDropdown = false;

  String? query;

  int? primaryId;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - SQLite (smartReplace)] action in replaceExercisePageCreation widget.
  List<SmartReplaceRow>? smrt;
  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Custom Action - replaceExerciseInExerciseSets] action in Button widget.
  List<dynamic>? replace;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tabBarController?.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
