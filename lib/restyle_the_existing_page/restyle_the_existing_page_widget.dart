import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'restyle_the_existing_page_model.dart';
export 'restyle_the_existing_page_model.dart';

/// Restyle the existing SignInWelcomePage.
///
/// Keep the exact structure and all widgets — only these changes:
///
/// 1. PAGE BACKGROUND: replace the flat #FAFBFA with a full-page vertical
/// gradient: #EAF9F1 at the very top, fading through #F4FBF7 (middle), to
/// #FFFFFF at the bottom. Subtle and airy - the green tint is noticeable at
/// the top and dissolves downward.
///
/// 2. BRAND SHAPE: keep the soft squircle behind the logo, but make it
/// slightly more present: gradient fill from #D7F5E8 to #C5F0DD at 85%
/// opacity, and add a very soft shadow (#1D9E75 at 12% opacity, blur 30,
/// offset y 12) so it floats over the gradient background instead of blending
/// flat.
///
/// 3. Add below the Google button (20px gap): a plain text button "Continue
/// with email" - 15px, semi-bold, color #0F6E56, centered, no background.
///
/// 4. Everything else stays exactly as is - logo placeholder, XLIFT title,
/// tagline, both buttons, legal line.
class RestyleTheExistingPageWidget extends StatefulWidget {
  const RestyleTheExistingPageWidget({super.key});

  static String routeName = 'RestyleTheExistingPage';
  static String routePath = '/restyleTheExistingPage';

  @override
  State<RestyleTheExistingPageWidget> createState() =>
      _RestyleTheExistingPageWidgetState();
}

class _RestyleTheExistingPageWidgetState
    extends State<RestyleTheExistingPageWidget> {
  late RestyleTheExistingPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RestyleTheExistingPageModel());
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
        body: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Opacity(
                opacity: 0.85,
                child: Container(
                  width: 100.0,
                  height: 100.0,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 30.0,
                        color: Color(0xFF1D9E75),
                        offset: Offset(
                          0.0,
                          12.0,
                        ),
                        spreadRadius: 0.0,
                      )
                    ],
                    gradient: LinearGradient(
                      colors: [Color(0xFFD7F5E8), Color(0xFFC5F0DD)],
                      stops: [0.0, 1.0],
                      begin: AlignmentDirectional(1.0, 1.0),
                      end: AlignmentDirectional(-1.0, -1.0),
                    ),
                    borderRadius: BorderRadius.circular(32.0),
                    shape: BoxShape.rectangle,
                  ),
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Icon(
                    Icons.fitness_center_rounded,
                    color: Color(0xFF0F6E56),
                    size: 48.0,
                  ),
                ),
              ),
              Container(
                height: 32.0,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    FFLocalizations.of(context).getText(
                      'fvw7a5wp' /* XLIFT */,
                    ),
                    style: FlutterFlowTheme.of(context).headlineLarge.override(
                          font: GoogleFonts.interTight(
                            fontWeight: FontWeight.w900,
                            fontStyle: FlutterFlowTheme.of(context)
                                .headlineLarge
                                .fontStyle,
                          ),
                          color: Color(0xFF0F6E56),
                          fontSize: 32.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w900,
                          fontStyle: FlutterFlowTheme.of(context)
                              .headlineLarge
                              .fontStyle,
                          lineHeight: 1.4,
                        ),
                  ),
                  Text(
                    FFLocalizations.of(context).getText(
                      'ha1lhuf6' /* Your strength, quantified. */,
                    ),
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).secondaryText,
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                          lineHeight: 1.4,
                        ),
                  ),
                ].divide(SizedBox(height: 4.0)),
              ),
              Container(
                height: 64.0,
              ),
              Container(
                width: 320.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 20.0,
                    ),
                    Container(
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Text(
                        FFLocalizations.of(context).getText(
                          '5o3ipctf' /* Continue with email */,
                        ),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: Color(0xFF0F6E56),
                              fontSize: 15.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                              lineHeight: 1.4,
                            ),
                      ),
                    ),
                  ].divide(SizedBox(height: 16.0)),
                ),
              ),
              Container(
                height: 48.0,
              ),
              Container(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Container(
                    child: Text(
                      FFLocalizations.of(context).getText(
                        'tsx0v41r' /* By continuing, you agree to ou... */,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: FlutterFlowTheme.of(context).labelSmall.override(
                            font: GoogleFonts.inter(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).secondaryText,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontStyle,
                            lineHeight: 1.4,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
