import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'camera_analyzer_model.dart';
export 'camera_analyzer_model.dart';

class CameraAnalyzerWidget extends StatefulWidget {
  const CameraAnalyzerWidget({
    super.key,
    required this.exerciseId,
    required this.analyze,
    required this.exerciseName,
  });

  final int? exerciseId;
  final Future Function(FFUploadedFile video)? analyze;
  final String? exerciseName;

  @override
  State<CameraAnalyzerWidget> createState() => _CameraAnalyzerWidgetState();
}

class _CameraAnalyzerWidgetState extends State<CameraAnalyzerWidget> {
  late CameraAnalyzerModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CameraAnalyzerModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 1.0,
      height: MediaQuery.sizeOf(context).height * 1.0,
      child: custom_widgets.XliftCameraRecorder(
        width: MediaQuery.sizeOf(context).width * 1.0,
        height: MediaQuery.sizeOf(context).height * 1.0,
        exerciseName: widget.exerciseName,
        showGuidance: true,
        onVideoRecorded: (videoFile) async {
          await widget.analyze?.call(
            videoFile,
          );
          Navigator.pop(context);
        },
        onClose: () async {
          Navigator.pop(context);
        },
        onDontShowAgain: () async {},
      ),
    );
  }
}
