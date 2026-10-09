import '/flutter_flow/flutter_flow_util.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'brand_squircle_model.dart';
export 'brand_squircle_model.dart';

class BrandSquircleWidget extends StatefulWidget {
  const BrandSquircleWidget({
    super.key,
    double? size,
    Color? bgColor,
    double? rotation,
    this.child,
  })  : this.size = size ?? 340.0,
        this.bgColor = bgColor ?? Colors.transparent,
        this.rotation = rotation ?? 8.0;

  final double size;
  final Color bgColor;
  final double rotation;
  final Widget Function()? child;

  @override
  State<BrandSquircleWidget> createState() => _BrandSquircleWidgetState();
}

class _BrandSquircleWidgetState extends State<BrandSquircleWidget> {
  late BrandSquircleModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BrandSquircleModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: valueOrDefault<double>(
            widget.rotation,
            8.0,
          ) *
          (math.pi / 180),
      alignment: AlignmentDirectional(0.0, 0.0),
      child: Container(
        width: valueOrDefault<double>(
          widget.size,
          340.0,
        ),
        height: valueOrDefault<double>(
          widget.size,
          340.0,
        ),
        decoration: BoxDecoration(
          color: valueOrDefault<Color>(
            widget.bgColor,
            Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(0.0),
          shape: BoxShape.rectangle,
        ),
        alignment: AlignmentDirectional(0.0, 0.0),
        child: Builder(builder: (_) {
          return widget.child != null ? widget.child!() : SizedBox.shrink();
        }),
      ),
    );
  }
}
