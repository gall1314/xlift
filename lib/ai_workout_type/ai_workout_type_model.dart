import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'ai_workout_type_widget.dart' show AiWorkoutTypeWidget;
import 'package:flutter/material.dart';

class AiWorkoutTypeModel extends FlutterFlowModel<AiWorkoutTypeWidget> {
  ///  Local state fields for this page.

  List<String> muscels = [];
  void addToMuscels(String item) => muscels.add(item);
  void removeFromMuscels(String item) => muscels.remove(item);
  void removeAtIndexFromMuscels(int index) => muscels.removeAt(index);
  void insertAtIndexInMuscels(int index, String item) =>
      muscels.insert(index, item);
  void updateMuscelsAtIndex(int index, Function(String) updateFn) =>
      muscels[index] = updateFn(muscels[index]);

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
