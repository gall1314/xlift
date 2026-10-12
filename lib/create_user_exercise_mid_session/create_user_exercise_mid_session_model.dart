import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'create_user_exercise_mid_session_widget.dart'
    show CreateUserExerciseMidSessionWidget;
import 'package:flutter/material.dart';

class CreateUserExerciseMidSessionModel
    extends FlutterFlowModel<CreateUserExerciseMidSessionWidget> {
  ///  Local state fields for this page.

  dynamic primaryMuscle;

  dynamic subMuscle;

  String equipment = 'All';

  int isAsissted = 0;

  int isBodyweight = 0;

  int isTimed = 0;

  String type = 'All';

  bool nameError = false;

  bool nulltype = false;

  bool muscleErorr = false;

  bool hasPrimaryMuscle = false;

  bool submitAttempted = false;

  List<dynamic> secondaryMuscels = [];
  void addToSecondaryMuscels(dynamic item) => secondaryMuscels.add(item);
  void removeFromSecondaryMuscels(dynamic item) =>
      secondaryMuscels.remove(item);
  void removeAtIndexFromSecondaryMuscels(int index) =>
      secondaryMuscels.removeAt(index);
  void insertAtIndexInSecondaryMuscels(int index, dynamic item) =>
      secondaryMuscels.insert(index, item);
  void updateSecondaryMuscelsAtIndex(int index, Function(dynamic) updateFn) =>
      secondaryMuscels[index] = updateFn(secondaryMuscels[index]);

  int allowBodyweight = 0;

  bool regular = false;

  FFUploadedFile? tempImage;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - generateUniqueExerciseId] action in Button widget.
  int? idCopy;
  // Stores action output result for [Custom Action - generateUniqueExerciseId] action in Button widget.
  int? id2Copy;
  // Stores action output result for [Custom Action - generateUniqueExerciseId] action in Button widget.
  int? id3;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // State field(s) for Switch widget.
  bool? switchValue;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
