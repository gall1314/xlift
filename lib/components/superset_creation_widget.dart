import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'superset_creation_model.dart';
export 'superset_creation_model.dart';

class SupersetCreationWidget extends StatefulWidget {
  const SupersetCreationWidget({
    super.key,
    required this.currentExerciseId,
  });

  final int? currentExerciseId;

  @override
  State<SupersetCreationWidget> createState() => _SupersetCreationWidgetState();
}

class _SupersetCreationWidgetState extends State<SupersetCreationWidget> {
  late SupersetCreationModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SupersetCreationModel());
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
      height: MediaQuery.sizeOf(context).height * 1.0,
      child: custom_widgets.SupersetPartnerSheet(
        width: MediaQuery.sizeOf(context).width * 1.0,
        height: MediaQuery.sizeOf(context).height * 1.0,
        currentExerciseId: widget.currentExerciseId!,
        accentColor: FlutterFlowTheme.of(context).primary,
        items: FFAppState().exerciseSetsCretion,
        onSelect: (selectedItem) async {
          _model.superset = await actions.pairSupersetSimple(
            FFAppState().exerciseSetsCretion.toList(),
            widget.currentExerciseId!,
            getJsonField(
              selectedItem,
              r'''$["exerciseId"]''',
            ),
          );
          FFAppState().exerciseSetsCretion =
              _model.superset!.toList().cast<dynamic>();
          _model.updatePage(() {});

          safeSetState(() {});
        },
      ),
    );
  }
}
