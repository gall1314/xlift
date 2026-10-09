import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'brand_squircle_child_model.dart';
export 'brand_squircle_child_model.dart';

class BrandSquircleChildWidget extends StatefulWidget {
  const BrandSquircleChildWidget({super.key});

  @override
  State<BrandSquircleChildWidget> createState() =>
      _BrandSquircleChildWidgetState();
}

class _BrandSquircleChildWidgetState extends State<BrandSquircleChildWidget> {
  late BrandSquircleChildModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BrandSquircleChildModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340.0,
      height: 340.0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE9FBF2), Color(0xFFD7F5E8)],
          stops: [0.0, 1.0],
          begin: AlignmentDirectional(0.0, -1.0),
          end: AlignmentDirectional(0, 1.0),
        ),
        borderRadius: BorderRadius.circular(90.0),
        shape: BoxShape.rectangle,
      ),
    );
  }
}
