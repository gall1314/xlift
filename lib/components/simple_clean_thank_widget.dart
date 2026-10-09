import '/components/thank_for_premium_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'simple_clean_thank_model.dart';
export 'simple_clean_thank_model.dart';

/// Design a simple, clean "thank you for subscribing" alert card for an iOS
/// fitness app.
///
/// Format: a centered modal card over a dimmed background. Rounded corners,
/// white background in light mode / dark card in dark mode, subtle shadow.
/// Comfortable padding all around.
///
/// Content, top to bottom, all centered, with fixed text (not parameters):
/// - A single icon at the top: a filled circle with a checkmark, using the
/// app's primary accent color.
/// - Title (bold, ~20px): "Welcome to Premium"
/// - Body text (regular, ~15px, muted color): "Thanks for supporting the app.
/// All features are now unlocked."
/// - One full-width primary button at the bottom: "Continue". Solid accent
/// background, white text, rounded.
///
/// Keep it minimal: no secondary buttons, no decorations, no gradients, no
/// animations beyond the default modal fade. Use the app's existing primary
/// color, background, and text colors — no custom hex values.
class SimpleCleanThankWidget extends StatefulWidget {
  const SimpleCleanThankWidget({super.key});

  @override
  State<SimpleCleanThankWidget> createState() => _SimpleCleanThankWidgetState();
}

class _SimpleCleanThankWidgetState extends State<SimpleCleanThankWidget> {
  late SimpleCleanThankModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SimpleCleanThankModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
      ),
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Container(
          child: Container(
            alignment: AlignmentDirectional(0.0, 0.0),
            child: wrapWithModel(
              model: _model.thankForPremiumModel,
              updateCallback: () => safeSetState(() {}),
              child: ThankForPremiumWidget(),
            ),
          ),
        ),
      ),
    );
  }
}
