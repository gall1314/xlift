import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'muscle_line_graph_plc_model.dart';
export 'muscle_line_graph_plc_model.dart';

class MuscleLineGraphPlcWidget extends StatefulWidget {
  const MuscleLineGraphPlcWidget({super.key});

  @override
  State<MuscleLineGraphPlcWidget> createState() =>
      _MuscleLineGraphPlcWidgetState();
}

class _MuscleLineGraphPlcWidgetState extends State<MuscleLineGraphPlcWidget> {
  late MuscleLineGraphPlcModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MuscleLineGraphPlcModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 323.7,
      height: 200.0,
      decoration: BoxDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FaIconData(const IconData(/* chartLine */ 0xf201,
                fontFamily: 'FontAwesomeSolid',
                fontPackage: 'font_awesome_flutter')),
            color: FlutterFlowTheme.of(context).alternate,
            size: 48.0,
          ),
          Text(
            FFLocalizations.of(context).getText(
              '34wwdwhd' /* No muscle volume data */,
            ),
            style: FlutterFlowTheme.of(context).headlineSmall.override(
                  font: GoogleFonts.interTight(
                    fontWeight:
                        FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                  ),
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                ),
          ),
          Text(
            FFLocalizations.of(context).getText(
              '7jqishjh' /* Log workouts for this muscle t... */,
            ),
            textAlign: TextAlign.center,
            style: FlutterFlowTheme.of(context).labelMedium.override(
                  font: GoogleFonts.inter(
                    fontWeight:
                        FlutterFlowTheme.of(context).labelMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelMedium.fontStyle,
                  ),
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).labelMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                ),
          ),
        ].divide(SizedBox(height: 5.0)),
      ),
    );
  }
}
