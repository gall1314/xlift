import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'price_card_model.dart';
export 'price_card_model.dart';

class PriceCardWidget extends StatefulWidget {
  const PriceCardWidget({
    super.key,
    bool? selected,
    String? label,
    String? price,
    String? sub,
    bool? showBadge,
  })  : this.selected = selected ?? false,
        this.label = label ?? 'MONTHLY',
        this.price = price ?? '\$3.99',
        this.sub = sub ?? 'per month · 7-day free trial',
        this.showBadge = showBadge ?? false;

  final bool selected;
  final String label;
  final String price;
  final String sub;
  final bool showBadge;

  @override
  State<PriceCardWidget> createState() => _PriceCardWidgetState();
}

class _PriceCardWidgetState extends State<PriceCardWidget> {
  late PriceCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PriceCardModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional(-1.0, -1.0),
      children: [
        Container(
          constraints: BoxConstraints(
            minHeight: 140.0,
          ),
          decoration: BoxDecoration(
            color: valueOrDefault<Color>(
              valueOrDefault<bool>(
                widget.selected,
                false,
              )
                  ? Color(0xFF162C28)
                  : Color(0xFF0D1F1B),
              Color(0x00000000),
            ),
            borderRadius: BorderRadius.circular(16.0),
            shape: BoxShape.rectangle,
            border: Border.all(
              color: valueOrDefault<Color>(
                valueOrDefault<bool>(
                  widget.selected,
                  false,
                )
                    ? Color(0xFF2DD4BF)
                    : Color(0x1AFFFFFF),
                Color(0x00000000),
              ),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    valueOrDefault<String>(
                      widget.label,
                      'MONTHLY',
                    ),
                    style: FlutterFlowTheme.of(context).labelSmall.override(
                          font: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontStyle,
                          ),
                          color: valueOrDefault<Color>(
                            valueOrDefault<bool>(
                              widget.selected,
                              false,
                            )
                                ? Color(0xFF2DD4BF)
                                : Color(0x99FFFFFF),
                            Color(0x00000000),
                          ),
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelSmall.fontStyle,
                          lineHeight: 1.4,
                        ),
                  ),
                  Text(
                    widget.price,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: Colors.white,
                          fontSize: 28.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w800,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                          lineHeight: 1.4,
                        ),
                  ),
                  Text(
                    valueOrDefault<String>(
                      widget.sub,
                      'per month · 7-day free trial',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: Color(0x80FFFFFF),
                          fontSize: 11.0,
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                          lineHeight: 1.4,
                        ),
                  ),
                ].divide(SizedBox(height: 8.0)),
              ),
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional(0.0, -1.0),
          child: Container(
            alignment: AlignmentDirectional(0.0, -1.0),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF2DD4BF),
                borderRadius: BorderRadius.circular(20.0),
                shape: BoxShape.rectangle,
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(10.0, 4.0, 10.0, 4.0),
                child: Container(
                  child: Text(
                    FFLocalizations.of(context).getText(
                      '8gj007xu' /* BEST VALUE */,
                    ),
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: Color(0xFF0A1614),
                          fontSize: 10.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w900,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                          lineHeight: 1.4,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
