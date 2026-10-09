import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'feedback_row2_model.dart';
export 'feedback_row2_model.dart';

class FeedbackRow2Widget extends StatefulWidget {
  const FeedbackRow2Widget({
    super.key,
    Color? iconColor,
    this.icon,
    String? content,
    this.showDivider,
  })  : this.iconColor = iconColor ?? const Color(0x00000000),
        this.content = content ??
            'Great hip hinge movement. You are engaging your posterior chain effectively.';

  final Color iconColor;
  final Widget? icon;
  final String content;
  final Widget Function()? showDivider;

  @override
  State<FeedbackRow2Widget> createState() => _FeedbackRow2WidgetState();
}

class _FeedbackRow2WidgetState extends State<FeedbackRow2Widget> {
  late FeedbackRow2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FeedbackRow2Model());
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 22.0,
              height: 22.0,
              decoration: BoxDecoration(
                color: valueOrDefault<Color>(
                  widget.iconColor,
                  FlutterFlowTheme.of(context).secondary,
                ),
                borderRadius: BorderRadius.circular(9999.0),
                shape: BoxShape.rectangle,
              ),
              child: widget.icon!,
            ),
            Expanded(
              flex: 1,
              child: Text(
                valueOrDefault<String>(
                  widget.content,
                  'Great hip hinge movement. You are engaging your posterior chain effectively.',
                ),
                maxLines: 2,
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      font: GoogleFonts.inter(
                        fontWeight:
                            FlutterFlowTheme.of(context).bodySmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      ),
                      color: Color(0xFF374151),
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).bodySmall.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      lineHeight: 1.4,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ].divide(SizedBox(width: 16.0)),
        ),
        Builder(builder: (_) {
          return widget.showDivider != null
              ? widget.showDivider!()
              : SizedBox.shrink();
        }),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 10.0),
          child: Container(
            child: Divider(
              height: 16.0,
              thickness: 1.0,
              indent: 0.0,
              endIndent: 0.0,
              color: Color(0xFFF3F4F6),
            ),
          ),
        ),
      ],
    );
  }
}
