import '/backend/sqlite/sqlite_manager.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'sub_muscles_full_checkbox_widget.dart'
    show SubMusclesFullCheckboxWidget;
import 'package:flutter/material.dart';

class SubMusclesFullCheckboxModel
    extends FlutterFlowModel<SubMusclesFullCheckboxWidget> {
  ///  Local state fields for this component.

  List<dynamic> selected = [];
  void addToSelected(dynamic item) => selected.add(item);
  void removeFromSelected(dynamic item) => selected.remove(item);
  void removeAtIndexFromSelected(int index) => selected.removeAt(index);
  void insertAtIndexInSelected(int index, dynamic item) =>
      selected.insert(index, item);
  void updateSelectedAtIndex(int index, Function(dynamic) updateFn) =>
      selected[index] = updateFn(selected[index]);

  ///  State fields for stateful widgets in this component.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // State field(s) for Checkbox widget.
  Map<SubMuscelsRow, bool> checkboxValueMap = {};
  List<SubMuscelsRow> get checkboxCheckedItems =>
      checkboxValueMap.entries.where((e) => e.value).map((e) => e.key).toList();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
