import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'paywall_final_model.dart';
export 'paywall_final_model.dart';

class PaywallFinalWidget extends StatefulWidget {
  const PaywallFinalWidget({super.key});

  static String routeName = 'paywallFinal';
  static String routePath = '/paywallFinal';

  @override
  State<PaywallFinalWidget> createState() => _PaywallFinalWidgetState();
}

class _PaywallFinalWidgetState extends State<PaywallFinalWidget> {
  late PaywallFinalModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PaywallFinalModel());
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
          child: custom_widgets.PaywallView(
            width: MediaQuery.sizeOf(context).width * 1.0,
            height: MediaQuery.sizeOf(context).height * 1.0,
            onClose: () async {
              context.safePop();
            },
            onPurchased: () async {
              FFAppState().isPremium = true;
              safeSetState(() {});
            },
            onOpenTerms: () async {
              await launchURL(
                  'https://docs.google.com/document/d/1cWUt2qPeCEgUHytTRbMkomw6QLaP5Ctj9lCsWzOgw2Q/edit?usp=sharing');
            },
            onOpenPrivacy: () async {
              await launchURL(
                  'https://docs.google.com/document/d/1ByRIeU1FcEoXFC3s3pF5PNH-iKnPEZO8rYhGLs9AGBc/edit?usp=sharing');
            },
          ),
        ),
      ),
    );
  }
}
