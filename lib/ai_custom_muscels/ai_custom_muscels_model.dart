import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'ai_custom_muscels_widget.dart' show AiCustomMuscelsWidget;
import 'package:flutter/material.dart';

class AiCustomMuscelsModel extends FlutterFlowModel<AiCustomMuscelsWidget> {
  ///  Local state fields for this page.

  List<String> selectedMuscels = [];
  void addToSelectedMuscels(String item) => selectedMuscels.add(item);
  void removeFromSelectedMuscels(String item) => selectedMuscels.remove(item);
  void removeAtIndexFromSelectedMuscels(int index) =>
      selectedMuscels.removeAt(index);
  void insertAtIndexInSelectedMuscels(int index, String item) =>
      selectedMuscels.insert(index, item);
  void updateSelectedMuscelsAtIndex(int index, Function(String) updateFn) =>
      selectedMuscels[index] = updateFn(selectedMuscels[index]);

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
