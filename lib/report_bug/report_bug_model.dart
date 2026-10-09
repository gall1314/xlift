import '/flutter_flow/flutter_flow_util.dart';
import 'report_bug_widget.dart' show ReportBugWidget;
import 'package:flutter/material.dart';

class ReportBugModel extends FlutterFlowModel<ReportBugWidget> {
  ///  Local state fields for this page.

  String? body;

  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  bool isDataUploading_uploadData0dw = false;
  FFUploadedFile uploadedLocalFile_uploadData0dw =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
