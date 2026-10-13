import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'create_workout_v2_widget.dart' show CreateWorkoutV2Widget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CreateWorkoutV2Model extends FlutterFlowModel<CreateWorkoutV2Widget> {
  ///  Local state fields for this page.

  bool shouldInit = false;

  String? workoutName;

  bool show = false;

  List<dynamic> selected = [];
  void addToSelected(dynamic item) => selected.add(item);
  void removeFromSelected(dynamic item) => selected.remove(item);
  void removeAtIndexFromSelected(int index) => selected.removeAt(index);
  void insertAtIndexInSelected(int index, dynamic item) =>
      selected.insert(index, item);
  void updateSelectedAtIndex(int index, Function(dynamic) updateFn) =>
      selected[index] = updateFn(selected[index]);

  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Custom Action - saveWorkoutTemplate] action in Button widget.
  dynamic save;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
