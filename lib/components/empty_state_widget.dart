import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'empty_state_model.dart';
export 'empty_state_model.dart';

/// Empty state component for a workout screen (fitness app).
///
/// Layout: a single centered Column, vertically and horizontally centered in
/// the available space, max width 280.
///
/// Icon: a dumbbell icon (outlined style, rounded), size 64, color
/// #9CA3AF at 40% opacity, inside a 110x110 circle with background
/// #14B8A6 at 8% opacity.
/// Title (16px, weight 600, color
/// #1A202C, center): "No exercises yet"
/// Subtitle (13.5px, weight 400, color
/// #9CA3AF, center, 2 lines max, 6px below title): "Add your first exercise
/// to start building this workout"
/// Spacing: 20px between icon and title.
///
/// Style: minimal and clean, generous whitespace, no borders, no cards, no
/// shadows. Background transparent (inherits page background
/// #F0F2F5). No button — the page already has an Add Exercise button.
///
/// Dark mode: title
/// #FFFFFF, subtitle
/// #6B7683, icon circle
/// #2DD4BF at 8% opacity, icon
/// #6B7683.
class EmptyStateWidget extends StatefulWidget {
  const EmptyStateWidget({
    super.key,
    bool? isDark,
  }) : this.isDark = isDark ?? false;

  final bool isDark;

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget> {
  late EmptyStateModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EmptyStateModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 550.0,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.rectangle,
      ),
      alignment: AlignmentDirectional(0.0, 0.0),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 280.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 110.0,
              height: 110.0,
              decoration: BoxDecoration(
                color: valueOrDefault<Color>(
                  valueOrDefault<bool>(
                    widget.isDark,
                    false,
                  )
                      ? Color(0x142DD4BF)
                      : Color(0x1414B8A6),
                  Color(0x00000000),
                ),
                borderRadius: BorderRadius.circular(9999.0),
                shape: BoxShape.rectangle,
              ),
              alignment: AlignmentDirectional(0.0, 0.0),
              child: Icon(
                Icons.fitness_center_rounded,
                color: valueOrDefault<Color>(
                  valueOrDefault<bool>(
                    widget.isDark,
                    false,
                  )
                      ? Color(0xFF6B7683)
                      : Color(0x669CA3AF),
                  Color(0x00000000),
                ),
                size: 64.0,
              ),
            ),
            Container(
              height: 20.0,
            ),
            Text(
              FFLocalizations.of(context).getText(
                'pyh9f1zv' /* No exercises yet */,
              ),
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                    color: valueOrDefault<bool>(
                      widget.isDark,
                      false,
                    )
                        ? Colors.white
                        : Color(0xFF1A202C),
                    fontSize: 16.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    lineHeight: 1.4,
                  ),
            ),
            Container(
              height: 6.0,
            ),
            Text(
              FFLocalizations.of(context).getText(
                'qbl2v59l' /* Add your first exercise to sta... */,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(
                      fontWeight: FontWeight.normal,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                    color: valueOrDefault<Color>(
                      valueOrDefault<bool>(
                        widget.isDark,
                        false,
                      )
                          ? Color(0xFF6B7683)
                          : Color(0xFF9CA3AF),
                      Color(0x00000000),
                    ),
                    fontSize: 13.5,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.normal,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    lineHeight: 1.4,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
