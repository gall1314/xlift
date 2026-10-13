import '/backend/sqlite/sqlite_manager.dart';
import '/components/exercise_stats_place_holder_widget.dart';
import '/components/line_graph_place_holder_widget.dart';
import '/components/pie_graph_place_holder_widget.dart';
import '/components/restyle_the_existing3_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'master_page_widget.dart' show MasterPageWidget;
import 'package:flutter/material.dart';

class MasterPageModel extends FlutterFlowModel<MasterPageWidget> {
  ///  Local state fields for this page.

  int pageIndex = 3;

  String rangeSelectStats = 'All';

  String selectedMuscle = 'All';

  int heroIndex = 0;

  String libaryMuscle = 'All';

  String selectedMuscleStats = 'All';

  bool template = false;

  String historyRangeSelect = 'All';

  String selectedMuscleHistory = 'All';

  ///  State fields for stateful widgets in this page.

  // State field(s) for TabBar widget.
  TabController? tabBarController1;
  int get tabBarCurrentIndex1 =>
      tabBarController1 != null ? tabBarController1!.index : 0;
  int get tabBarPreviousIndex1 =>
      tabBarController1 != null ? tabBarController1!.previousIndex : 0;

  // Model for lineGraphPlaceHolder component.
  late LineGraphPlaceHolderModel lineGraphPlaceHolderModel;
  // Model for pieGraphPlaceHolder component.
  late PieGraphPlaceHolderModel pieGraphPlaceHolderModel;
  // Model for exerciseStatsPlaceHolder component.
  late ExerciseStatsPlaceHolderModel exerciseStatsPlaceHolderModel;
  // Model for RestyleTheExisting3 component.
  late RestyleTheExisting3Model restyleTheExisting3Model;
  // Stores action output result for [Backend Call - SQLite (workoutNum)] action in Button widget.
  List<WorkoutNumRow>? workouts;
  // Stores action output result for [Backend Call - SQLite (workoutNum)] action in DashedNewWorkoutButton widget.
  List<WorkoutNumRow>? workoutsCopy;
  // Stores action output result for [Custom Action - callWorkoutBuilder] action in Button widget.
  dynamic result;
  bool isDataUploading_uploadDataNme = false;
  FFUploadedFile uploadedLocalFile_uploadDataNme =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // Stores action output result for [Custom Action - analyzeDeadliftWithBarbellTest] action in Button widget.
  dynamic deadBarb;
  bool isDataUploading_uploadDataEut = false;
  FFUploadedFile uploadedLocalFile_uploadDataEut =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // Stores action output result for [Custom Action - testBarbellDetection] action in Button widget.
  dynamic barb;
  bool isDataUploading_field99999 = false;
  FFUploadedFile uploadedLocalFile_field99999 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // Stores action output result for [Custom Action - analyzeSquatVideoHeavyAction] action in Button widget.
  dynamic hevy;
  bool isDataUploading_uploadData5z999 = false;
  FFUploadedFile uploadedLocalFile_uploadData5z999 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // Stores action output result for [Custom Action - analyzeOverheadPressVideoAction] action in Button widget.
  dynamic press;
  bool isDataUploading_uploadData5z99 = false;
  FFUploadedFile uploadedLocalFile_uploadData5z99 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // Stores action output result for [Custom Action - analyzeStiffLegDeadliftVideoAction] action in Button widget.
  dynamic stiff;
  bool isDataUploading_uploadData5z7 = false;
  FFUploadedFile uploadedLocalFile_uploadData5z7 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // Stores action output result for [Custom Action - analyzeDeadliftVideoAction] action in Button widget.
  dynamic dead;
  bool isDataUploading_uploadData5zb = false;
  FFUploadedFile uploadedLocalFile_uploadData5zb =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // Stores action output result for [Custom Action - analyzeRomanianDeadliftVideoAction] action in Button widget.
  dynamic roman;
  bool isDataUploading_uploadData5zy = false;
  FFUploadedFile uploadedLocalFile_uploadData5zy =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // Stores action output result for [Custom Action - analyzeBulgarianVideoAction] action in Button widget.
  dynamic bulb;
  bool isDataUploading_uploadDataUxr = false;
  FFUploadedFile uploadedLocalFile_uploadDataUxr =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // Stores action output result for [Custom Action - analyzeBentRowVideoAction] action in Button widget.
  dynamic goodm;
  bool isDataUploading_uploadDataUxb = false;
  FFUploadedFile uploadedLocalFile_uploadDataUxb =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // Stores action output result for [Custom Action - analyzeBicepCurlVideoAction] action in Button widget.
  dynamic curl;
  bool isDataUploading_uploadDataUxg = false;
  FFUploadedFile uploadedLocalFile_uploadDataUxg =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // Stores action output result for [Custom Action - analyzePushupVideoAction] action in Button widget.
  dynamic push;
  bool isDataUploading_uploadData = false;
  FFUploadedFile uploadedLocalFile_uploadData =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // Stores action output result for [Custom Action - analyzeSquatVideoAction] action in Button widget.
  dynamic cc;
  bool isDataUploading_uploadData5z8 = false;
  FFUploadedFile uploadedLocalFile_uploadData5z8 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // Stores action output result for [Custom Action - analyzePullupVideoAction] action in Button widget.
  dynamic plp;
  bool isDataUploading_uploadDataUxb5 = false;
  FFUploadedFile uploadedLocalFile_uploadDataUxb5 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // Stores action output result for [Custom Action - analyzeDipsVideoAction] action in Button widget.
  dynamic dip;
  // State field(s) for TabBar widget.
  TabController? tabBarController2;
  int get tabBarCurrentIndex2 =>
      tabBarController2 != null ? tabBarController2!.index : 0;
  int get tabBarPreviousIndex2 =>
      tabBarController2 != null ? tabBarController2!.previousIndex : 0;

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // State field(s) for muscleDropdown widget.
  String? muscleDropdownValue;
  FormFieldController<String>? muscleDropdownValueController;
  // Stores action output result for [Backend Call - SQLite (workoutNum)] action in Button widget.
  List<WorkoutNumRow>? workouts2;
  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // Stores action output result for [Backend Call - SQLite (getworkoutExercise)] action in Button widget.
  List<GetworkoutExerciseRow>? exrecisess;
  // Stores action output result for [Custom Action - generateUuidV4] action in Button widget.
  String? uuid;
  // Stores action output result for [Custom Action - insertWorkoutExercises] action in Button widget.
  dynamic save;

  @override
  void initState(BuildContext context) {
    lineGraphPlaceHolderModel =
        createModel(context, () => LineGraphPlaceHolderModel());
    pieGraphPlaceHolderModel =
        createModel(context, () => PieGraphPlaceHolderModel());
    exerciseStatsPlaceHolderModel =
        createModel(context, () => ExerciseStatsPlaceHolderModel());
    restyleTheExisting3Model =
        createModel(context, () => RestyleTheExisting3Model());
  }

  @override
  void dispose() {
    tabBarController1?.dispose();
    lineGraphPlaceHolderModel.dispose();
    pieGraphPlaceHolderModel.dispose();
    exerciseStatsPlaceHolderModel.dispose();
    restyleTheExisting3Model.dispose();
    tabBarController2?.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
