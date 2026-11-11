import '/auth/supabase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'training_score_model.dart';
export 'training_score_model.dart';

class TrainingScoreWidget extends StatefulWidget {
  const TrainingScoreWidget({super.key});

  static String routeName = 'trainingScore';
  static String routePath = '/trainingScore';

  @override
  State<TrainingScoreWidget> createState() => _TrainingScoreWidgetState();
}

class _TrainingScoreWidgetState extends State<TrainingScoreWidget> {
  late TrainingScoreModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TrainingScoreModel());
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
        body: SafeArea(
          left: false,
          top: false,
          right: false,
          bottom: false,
          child: Container(
            width: MediaQuery.sizeOf(context).width * 1.0,
            height: MediaQuery.sizeOf(context).height * 1.0,
            child: custom_widgets.TrainingScore(
              width: MediaQuery.sizeOf(context).width * 1.0,
              height: MediaQuery.sizeOf(context).height * 1.0,
              userId: currentUserUid,
              compact: false,
              demoMode: false,
              onTap: () async {},
              onClose: () async {
                context.safePop();
              },
              onFormCheck: () async {},
            ),
          ),
        ),
      ),
    );
  }
}
