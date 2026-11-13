import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'delete_set_analysis_edit_model.dart';
export 'delete_set_analysis_edit_model.dart';

/// Create a component, alert popup- you sure you want to delte this workout
class DeleteSetAnalysisEditWidget extends StatefulWidget {
  const DeleteSetAnalysisEditWidget({
    super.key,
    required this.analysisId,
  });

  final String? analysisId;

  @override
  State<DeleteSetAnalysisEditWidget> createState() =>
      _DeleteSetAnalysisEditWidgetState();
}

class _DeleteSetAnalysisEditWidgetState
    extends State<DeleteSetAnalysisEditWidget> {
  late DeleteSetAnalysisEditModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DeleteSetAnalysisEditModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Container(
      width: MediaQuery.sizeOf(context).width * 1.0,
      height: double.infinity,
      child: custom_widgets.RemoveAnalysisAlert(
        width: MediaQuery.sizeOf(context).width * 1.0,
        height: double.infinity,
        isPermanent: false,
        analysisId: widget.analysisId,
        onCancel: () async {
          Navigator.pop(context);
        },
        onConfirm: (exerciseId, setNumber) async {
          _model.remove = await actions.removeAnalysisFromState(
            FFAppState().analysisStateCreation.toList(),
            exerciseId,
            setNumber,
          );
          FFAppState().analysisStateCreation =
              _model.remove!.toList().cast<dynamic>();
          safeSetState(() {});
          Navigator.pop(context);

          safeSetState(() {});
        },
      ),
    );
  }
}
