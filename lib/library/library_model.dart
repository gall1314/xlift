import '/backend/sqlite/sqlite_manager.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/instant_timer.dart';
import '/index.dart';
import 'library_widget.dart' show LibraryWidget;
import 'package:flutter/material.dart';

class LibraryModel extends FlutterFlowModel<LibraryWidget> {
  ///  Local state fields for this page.

  String? query;

  String muscle = 'All';

  ///  State fields for stateful widgets in this page.

  InstantTimer? instantTimer;
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
  // State field(s) for muscleDropdown widget.
  String? muscleDropdownValue;
  FormFieldController<String>? muscleDropdownValueController;
  // Stores action output result for [Backend Call - SQLite (workoutNum)] action in Button widget.
  List<WorkoutNumRow>? workoutsCopy;
  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // Stores action output result for [Backend Call - SQLite (getworkoutExercise)] action in Button widget.
  List<GetworkoutExerciseRow>? exrecises;
  // Stores action output result for [Custom Action - generateUuidV4] action in Button widget.
  String? uuid;
  // Stores action output result for [Custom Action - generateUuidV4] action in Button widget.
  String? uuid2;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    instantTimer?.cancel();
    tabBarController?.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
