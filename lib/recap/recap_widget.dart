import '/auth/supabase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'recap_model.dart';
export 'recap_model.dart';

class RecapWidget extends StatefulWidget {
  const RecapWidget({
    super.key,
    this.timeRange,
  });

  final String? timeRange;

  static String routeName = 'recap';
  static String routePath = '/recap';

  @override
  State<RecapWidget> createState() => _RecapWidgetState();
}

class _RecapWidgetState extends State<RecapWidget> {
  late RecapModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RecapModel());
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
        body: Container(
          width: MediaQuery.sizeOf(context).width * 1.0,
          height: MediaQuery.sizeOf(context).height * 1.0,
          child: custom_widgets.RecapView(
            width: MediaQuery.sizeOf(context).width * 1.0,
            height: MediaQuery.sizeOf(context).height * 1.0,
            userId: currentUserUid,
            timeRange: widget.timeRange,
            demoMode: false,
            onClose: () async {
              context.safePop();
            },
          ),
        ),
      ),
    );
  }
}
