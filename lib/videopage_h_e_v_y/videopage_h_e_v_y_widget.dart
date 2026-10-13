import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'videopage_h_e_v_y_model.dart';
export 'videopage_h_e_v_y_model.dart';

class VideopageHEVYWidget extends StatefulWidget {
  const VideopageHEVYWidget({
    super.key,
    required this.videop,
    required this.analysisResult,
  });

  final String? videop;
  final dynamic analysisResult;

  static String routeName = 'videopageHEVY';
  static String routePath = '/videopageHEVY';

  @override
  State<VideopageHEVYWidget> createState() => _VideopageHEVYWidgetState();
}

class _VideopageHEVYWidgetState extends State<VideopageHEVYWidget> {
  late VideopageHEVYModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VideopageHEVYModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            FFLocalizations.of(context).getText(
              '428xgxdf' /* Page Title */,
            ),
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.interTight(
                    fontWeight:
                        FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                  ),
                  color: Colors.white,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                ),
          ),
          actions: [],
          centerTitle: true,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: Container(
            width: 350.0,
            height: 680.0,
            child: custom_widgets.SquatAnalyzedVideoPlayerHeavy(
              width: 350.0,
              height: 680.0,
              showSkeleton: true,
              showBoundingBox: true,
              videoVolume: 0.7,
              lockFeet: false,
              analysisResult: widget.analysisResult!,
            ),
          ),
        ),
      ),
    );
  }
}
