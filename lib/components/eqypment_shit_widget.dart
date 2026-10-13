import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'eqypment_shit_model.dart';
export 'eqypment_shit_model.dart';

class EqypmentShitWidget extends StatefulWidget {
  const EqypmentShitWidget({
    super.key,
    this.selected,
    required this.callback,
  });

  final String? selected;
  final Future Function(String selected)? callback;

  @override
  State<EqypmentShitWidget> createState() => _EqypmentShitWidgetState();
}

class _EqypmentShitWidgetState extends State<EqypmentShitWidget> {
  late EqypmentShitModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EqypmentShitModel());
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
      child: custom_widgets.EquipmentPickerSheet(
        width: MediaQuery.sizeOf(context).width * 1.0,
        height: MediaQuery.sizeOf(context).height * 1.0,
        selected: widget.selected,
        accentColor: FlutterFlowTheme.of(context).secondary,
        onSelect: (equipment) async {
          await widget.callback?.call(
            equipment,
          );
        },
      ),
    );
  }
}
