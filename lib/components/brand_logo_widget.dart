import '/flutter_flow/flutter_flow_util.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'brand_logo_model.dart';
export 'brand_logo_model.dart';

class BrandLogoWidget extends StatefulWidget {
  const BrandLogoWidget({
    super.key,
    String? logoImage,
  }) : this.logoImage = logoImage ??
            'https://dimg.dreamflow.cloud/v1/image/modern%20minimalist%20fitness%20weight%20icon';

  final String logoImage;

  @override
  State<BrandLogoWidget> createState() => _BrandLogoWidgetState();
}

class _BrandLogoWidgetState extends State<BrandLogoWidget> {
  late BrandLogoModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BrandLogoModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330.0,
      height: 330.0,
      child: Stack(
        alignment: AlignmentDirectional(0.0, 0.0),
        children: [
          Opacity(
            opacity: 0.9,
            child: Transform.rotate(
              angle: 8.0 * (math.pi / 180),
              alignment: AlignmentDirectional(0.0, 0.0),
              child: Container(
                width: 330.0,
                height: 330.0,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 28.0,
                      color: Color(0xFF1D9E75),
                      offset: Offset(
                        0.0,
                        10.0,
                      ),
                      spreadRadius: 0.0,
                    )
                  ],
                  gradient: LinearGradient(
                    colors: [Color(0xFFCBF1DE), Color(0xFFB8ECD2)],
                    stops: [0.0, 1.0],
                    begin: AlignmentDirectional(0.0, -1.0),
                    end: AlignmentDirectional(0, 1.0),
                  ),
                  borderRadius: BorderRadius.circular(88.0),
                  shape: BoxShape.rectangle,
                ),
              ),
            ),
          ),
          Container(
            width: 215.0,
            height: 215.0,
            decoration: BoxDecoration(
              color: Color(0xE0FFFFFF),
              borderRadius: BorderRadius.circular(58.0),
              shape: BoxShape.rectangle,
            ),
            alignment: AlignmentDirectional(0.0, 0.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Image.asset(
                'assets/images/logo_11.png',
                width: 140.0,
                height: 140.0,
                fit: BoxFit.contain,
                alignment: Alignment(0.0, 0.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
