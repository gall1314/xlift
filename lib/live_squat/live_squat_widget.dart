import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'live_squat_model.dart';
export 'live_squat_model.dart';

class LiveSquatWidget extends StatefulWidget {
  const LiveSquatWidget({super.key});

  static String routeName = 'liveSquat';
  static String routePath = '/liveSquat';

  @override
  State<LiveSquatWidget> createState() => _LiveSquatWidgetState();
}

class _LiveSquatWidgetState extends State<LiveSquatWidget> {
  late LiveSquatModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LiveSquatModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: MediaQuery.sizeOf(context).width * 1.0,
            height: MediaQuery.sizeOf(context).height * 1.0,
            child: custom_widgets.LiveSquatCameraWidget(
              width: MediaQuery.sizeOf(context).width * 1.0,
              height: MediaQuery.sizeOf(context).height * 1.0,
              useFrontCamera: true,
              videoVolume: 0.7,
              showDebugOverlay: false,
              onSessionComplete: () async {},
              onClose: () async {
                context.safePop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
