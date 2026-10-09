import '/backend/sqlite/sqlite_manager.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'prof_edit_v2_widget.dart' show ProfEditV2Widget;
import 'package:flutter/material.dart';

class ProfEditV2Model extends FlutterFlowModel<ProfEditV2Widget> {
  ///  Local state fields for this page.

  String? birthday;

  String? sex;

  double? weight;

  double? height;

  bool isBodyweightKg = true;

  bool isHeightCm = true;

  String? tempProf;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - SQLite (user)] action in profEditV2 widget.
  List<UserRow>? user;
  // Stores action output result for [Custom Action - pickAndSaveProfilePhoto] action in Button widget.
  String? prof;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Custom Action - checkInternet] action in Button widget.
  bool? inernet;
  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<UsersRow>? newser;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
