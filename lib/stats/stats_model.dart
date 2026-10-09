import '/components/exercise_stats_place_holder_widget.dart';
import '/components/line_graph_place_holder_widget.dart';
import '/components/muscle_line_graph_plc_widget.dart';
import '/components/pie_graph_place_holder_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/instant_timer.dart';
import '/index.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'stats_widget.dart' show StatsWidget;
import 'package:flutter/material.dart';

class StatsModel extends FlutterFlowModel<StatsWidget> {
  ///  Local state fields for this page.

  List<dynamic> graphData = [];
  void addToGraphData(dynamic item) => graphData.add(item);
  void removeFromGraphData(dynamic item) => graphData.remove(item);
  void removeAtIndexFromGraphData(int index) => graphData.removeAt(index);
  void insertAtIndexInGraphData(int index, dynamic item) =>
      graphData.insert(index, item);
  void updateGraphDataAtIndex(int index, Function(dynamic) updateFn) =>
      graphData[index] = updateFn(graphData[index]);

  String rangeSelect = 'Last 30 days';

  List<dynamic> lineGraph = [];
  void addToLineGraph(dynamic item) => lineGraph.add(item);
  void removeFromLineGraph(dynamic item) => lineGraph.remove(item);
  void removeAtIndexFromLineGraph(int index) => lineGraph.removeAt(index);
  void insertAtIndexInLineGraph(int index, dynamic item) =>
      lineGraph.insert(index, item);
  void updateLineGraphAtIndex(int index, Function(dynamic) updateFn) =>
      lineGraph[index] = updateFn(lineGraph[index]);

  String workoutId = 'all';

  bool pieGraph = false;

  List<Color> colors = [
    Color(4282090230),
    Color(4279286145),
    Color(4294626325),
    Color(4294677052),
    Color(4287323382),
    Color(4278630100),
    Color(4293870660),
    Color(4293675161),
    Color(4288455599)
  ];
  void addToColors(Color item) => colors.add(item);
  void removeFromColors(Color item) => colors.remove(item);
  void removeAtIndexFromColors(int index) => colors.removeAt(index);
  void insertAtIndexInColors(int index, Color item) =>
      colors.insert(index, item);
  void updateColorsAtIndex(int index, Function(Color) updateFn) =>
      colors[index] = updateFn(colors[index]);

  dynamic byExerciseData;

  List<dynamic> exerciseList = [];
  void addToExerciseList(dynamic item) => exerciseList.add(item);
  void removeFromExerciseList(dynamic item) => exerciseList.remove(item);
  void removeAtIndexFromExerciseList(int index) => exerciseList.removeAt(index);
  void insertAtIndexInExerciseList(int index, dynamic item) =>
      exerciseList.insert(index, item);
  void updateExerciseListAtIndex(int index, Function(dynamic) updateFn) =>
      exerciseList[index] = updateFn(exerciseList[index]);

  bool fullList = false;

  String? query;

  bool overview = true;

  String selectedMuscle = 'Chest';

  String all = 'All';

  ///  State fields for stateful widgets in this page.

  InstantTimer? instantTimerHome;
  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  // Model for lineGraphPlaceHolder component.
  late LineGraphPlaceHolderModel lineGraphPlaceHolderModel;
  // Model for pieGraphPlaceHolder component.
  late PieGraphPlaceHolderModel pieGraphPlaceHolderModel;
  // State field(s) for Carousel widget.
  CarouselSliderController? carouselController;
  int carouselCurrentIndex = 1;

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Model for exerciseStatsPlaceHolder component.
  late ExerciseStatsPlaceHolderModel exerciseStatsPlaceHolderModel;
  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // Model for muscleLineGraphPlc component.
  late MuscleLineGraphPlcModel muscleLineGraphPlcModel;

  @override
  void initState(BuildContext context) {
    lineGraphPlaceHolderModel =
        createModel(context, () => LineGraphPlaceHolderModel());
    pieGraphPlaceHolderModel =
        createModel(context, () => PieGraphPlaceHolderModel());
    exerciseStatsPlaceHolderModel =
        createModel(context, () => ExerciseStatsPlaceHolderModel());
    muscleLineGraphPlcModel =
        createModel(context, () => MuscleLineGraphPlcModel());
  }

  @override
  void dispose() {
    instantTimerHome?.cancel();
    tabBarController?.dispose();
    lineGraphPlaceHolderModel.dispose();
    pieGraphPlaceHolderModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();

    exerciseStatsPlaceHolderModel.dispose();
    muscleLineGraphPlcModel.dispose();
  }
}
