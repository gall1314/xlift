import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'reorder_creation_model.dart';
export 'reorder_creation_model.dart';

class ReorderCreationWidget extends StatefulWidget {
  const ReorderCreationWidget({super.key});

  @override
  State<ReorderCreationWidget> createState() => _ReorderCreationWidgetState();
}

class _ReorderCreationWidgetState extends State<ReorderCreationWidget> {
  late ReorderCreationModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReorderCreationModel());
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
      child: custom_widgets.ReorderExercisesSheet(
        width: MediaQuery.sizeOf(context).width * 1.0,
        height: MediaQuery.sizeOf(context).height * 1.0,
        items: FFAppState().exerciseSetsCretion,
        accentColor: FlutterFlowTheme.of(context).secondary,
        onSave: (reorderedItems) async {
          FFAppState().exerciseSetsCretion =
              reorderedItems.toList().cast<dynamic>();
          FFAppState().update(() {});
        },
      ),
    );
  }
}
