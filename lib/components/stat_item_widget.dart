import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'stat_item_model.dart';
export 'stat_item_model.dart';

class StatItemWidget extends StatefulWidget {
  const StatItemWidget({
    super.key,
    String? value,
    String? label,
  })  : this.value = value ?? '52:41',
        this.label = label ?? 'Duration';

  final String value;
  final String label;

  @override
  State<StatItemWidget> createState() => _StatItemWidgetState();
}

class _StatItemWidgetState extends State<StatItemWidget> {
  late StatItemModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => StatItemModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          valueOrDefault<String>(
            widget.value,
            '52:41',
          ),
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
                color: Colors.white,
                fontSize: 26.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w800,
                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                lineHeight: 1.0,
              ),
        ),
        Text(
          valueOrDefault<String>(
            widget.label,
            'Duration',
          ),
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
                color: Color(0x8CFFFFFF),
                fontSize: 12.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w500,
                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                lineHeight: 1.4,
              ),
        ),
      ].divide(SizedBox(height: 4.0)),
    );
  }
}
