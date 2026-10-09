import '/flutter_flow/flutter_flow_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'brand_squircle_child2_model.dart';
export 'brand_squircle_child2_model.dart';

class BrandSquircleChild2Widget extends StatefulWidget {
  const BrandSquircleChild2Widget({super.key});

  @override
  State<BrandSquircleChild2Widget> createState() =>
      _BrandSquircleChild2WidgetState();
}

class _BrandSquircleChild2WidgetState extends State<BrandSquircleChild2Widget> {
  late BrandSquircleChild2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BrandSquircleChild2Model());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      fadeInDuration: Duration(milliseconds: 0),
      fadeOutDuration: Duration(milliseconds: 0),
      imageUrl: 'https://dimg.dreamflow.cloud/v1/image/XLIFT%20fitness%20logo',
      width: 140.0,
      height: 140.0,
      fit: BoxFit.contain,
      alignment: Alignment(0.0, 0.0),
    );
  }
}
