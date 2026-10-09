import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/instant_timer.dart';
import '/index.dart';
import 'exercise_history_custom_widget.dart' show ExerciseHistoryCustomWidget;
import 'package:flutter/material.dart';

class ExerciseHistoryCustomModel
    extends FlutterFlowModel<ExerciseHistoryCustomWidget> {
  ///  Local state fields for this page.

  bool stepByStep = false;

  List<Color> colors = [
    Color(4281193663),
    Color(4279286145),
    Color(4280472558),
    Color(4279150057),
    Color(4278630100),
    Color(4282090230)
  ];
  void addToColors(Color item) => colors.add(item);
  void removeFromColors(Color item) => colors.remove(item);
  void removeAtIndexFromColors(int index) => colors.removeAt(index);
  void insertAtIndexInColors(int index, Color item) =>
      colors.insert(index, item);
  void updateColorsAtIndex(int index, Function(Color) updateFn) =>
      colors[index] = updateFn(colors[index]);

  List<dynamic> data = [];
  void addToData(dynamic item) => data.add(item);
  void removeFromData(dynamic item) => data.remove(item);
  void removeAtIndexFromData(int index) => data.removeAt(index);
  void insertAtIndexInData(int index, dynamic item) => data.insert(index, item);
  void updateDataAtIndex(int index, Function(dynamic) updateFn) =>
      data[index] = updateFn(data[index]);

  String timeRange = 'All';

  ///  State fields for stateful widgets in this page.

  InstantTimer? instantTimerHome;
  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  // State field(s) for ChoiceChips widget.
  FormFieldController<List<String>>? choiceChipsValueController;
  String? get choiceChipsValue =>
      choiceChipsValueController?.value?.firstOrNull;
  set choiceChipsValue(String? val) =>
      choiceChipsValueController?.value = val != null ? [val] : [];
  // State field(s) for assistedChips widget.
  FormFieldController<List<String>>? assistedChipsValueController;
  String? get assistedChipsValue =>
      assistedChipsValueController?.value?.firstOrNull;
  set assistedChipsValue(String? val) =>
      assistedChipsValueController?.value = val != null ? [val] : [];

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    instantTimerHome?.cancel();
    tabBarController?.dispose();
  }
}
