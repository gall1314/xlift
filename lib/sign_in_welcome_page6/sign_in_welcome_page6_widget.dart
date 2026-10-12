import '/auth/supabase_auth/auth_util.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sign_in_welcome_page6_model.dart';
export 'sign_in_welcome_page6_model.dart';

/// Create a sign-in welcome page for a fitness app.
///
/// iOS, light theme. Minimal and elegant - NO decorative shapes, NO cards, NO
/// squircles, NO containers with backgrounds. Just a gradient, a logo, text,
/// and buttons.
///
/// PAGE BACKGROUND: the entire screen is ONE vertical linear gradient:
/// #DFF6EA at the top → #F4FBF7 at 45% → #FFFFFF at the bottom. Every other
/// element sits directly on this gradient with transparent background.
///
/// CONTENT (single Column, SafeArea, horizontal padding 24px):
///
/// - Flexible space (pushes content to visual balance).
/// - Logo image (parameter: logoImage), 120x120, centered. Directly on the
/// gradient - no frame, no box, no background behind it.
/// - 20px gap.
/// - "XLIFT" - 34px, extra bold, letter-spacing 6px, #0A2A1F, centered.
/// - 8px gap.
/// - "Train smarter. Lift stronger." - 16px, #4E7A68, centered.
/// - Flexible space.
/// - "Continue with Apple" button: full width, 54px height, radius 16px,
/// solid black, white Apple icon + white 16px semi-bold text.
/// - 12px gap.
/// - "Continue with Google" button: full width, 54px, radius 16px, white, 1px
/// border #DADCE0, multicolor G icon + 16px semi-bold #1F1F1F text.
/// - 20px gap.
/// - "Continue with email" - text only, 15px semi-bold, #0F6E56, centered.
/// - 16px gap.
/// - "By continuing you agree to our Terms and Privacy Policy" - 12px
/// #8A8A8E, links in #0F6E56.
/// - 12px bottom padding.
///
/// RULES: no Stack layers, no shadows, no rotated shapes, no image
/// placeholders other than the logo. The gradient + typography + buttons ARE
/// the design. If tempted to add a decorative element - don't.
///
/// FEEL: calm, premium, confident minimalism. Like Oura / Linear login
/// screens.
class SignInWelcomePage6Widget extends StatefulWidget {
  const SignInWelcomePage6Widget({super.key});

  static String routeName = 'SignInWelcomePage6';
  static String routePath = '/signInWelcomePage6';

  @override
  State<SignInWelcomePage6Widget> createState() =>
      _SignInWelcomePage6WidgetState();
}

class _SignInWelcomePage6WidgetState extends State<SignInWelcomePage6Widget>
    with TickerProviderStateMixin {
  late SignInWelcomePage6Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SignInWelcomePage6Model());

    animationsMap.addAll({
      'columnOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: Offset(0.0, 60.0),
            end: Offset(0.0, 0.0),
          ),
          TiltEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: Offset(-0.349, 0),
            end: Offset(0, 0),
          ),
        ],
      ),
    });
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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFDFF6EA), Color(0xFFF4FBF7), Colors.white],
              stops: [0.0, 0.45, 1.0],
              begin: AlignmentDirectional(0.0, -1.0),
              end: AlignmentDirectional(0, 1.0),
            ),
            shape: BoxShape.rectangle,
          ),
          alignment: AlignmentDirectional(0.0, 0.0),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Spacer(flex: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Image.asset(
                    'assets/images/logo_11.png',
                    width: 120.0,
                    height: 120.0,
                    fit: BoxFit.contain,
                    alignment: Alignment(0.0, 0.0),
                  ),
                ),
                Container(
                  height: 20.0,
                ),
                Text(
                  FFLocalizations.of(context).getText(
                    'e8nt6zeb' /* XLIFT */,
                  ),
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                        color: Color(0xFF0A2A1F),
                        fontSize: 34.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w900,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        lineHeight: 1.4,
                      ),
                ),
                Container(
                  height: 8.0,
                ),
                Text(
                  FFLocalizations.of(context).getText(
                    'dcgmtwg7' /* Train smarter. Lift stronger. */,
                  ),
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.inter(
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                        color: Color(0xFF4E7A68),
                        fontSize: 16.0,
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        lineHeight: 1.4,
                      ),
                ),
                Spacer(flex: 4),
                Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      isAndroid
                          ? Container()
                          : Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 16.0),
                              child: FFButtonWidget(
                                onPressed: () async {
                                  GoRouter.of(context).prepareAuthEvent();
                                  final user = await authManager
                                      .signInWithApple(context);
                                  if (user == null) {
                                    return;
                                  }
                                  _model.user = await UsersTable().queryRows(
                                    queryFn: (q) => q.eqOrNull(
                                      'id',
                                      currentUserUid,
                                    ),
                                  );
                                  await SQLiteManager.instance.insertUser(
                                    id: _model.user!.firstOrNull!.id,
                                    username:
                                        _model.user!.firstOrNull!.username!,
                                    email: _model.user!.firstOrNull!.email!,
                                    isKg: 1,
                                  );
                                  FFAppState().signedApple = true;
                                  safeSetState(() {});
                                  await actions.revenueCatLogin(
                                    currentUserUid,
                                  );
                                  await actions.restoreAllFromCloud(
                                    currentUserUid,
                                  );

                                  context.goNamedAuth(
                                    MasterPageWidget.routeName,
                                    context.mounted,
                                    queryParameters: {
                                      'initialTab': serializeParam(
                                        3,
                                        ParamType.int,
                                      ),
                                    }.withoutNulls,
                                  );

                                  await actions.initHive();
                                  await actions.initLocalNotifications();

                                  safeSetState(() {});
                                },
                                text: FFLocalizations.of(context).getText(
                                  't5l67562' /* Continue with Apple */,
                                ),
                                icon: FaIcon(
                                  FaIconData(const IconData(/* apple */ 0xf179,
                                      fontFamily: 'FontAwesomeBrands',
                                      fontPackage: 'font_awesome_flutter')),
                                  size: 20.0,
                                ),
                                options: FFButtonOptions(
                                  width: MediaQuery.sizeOf(context).width * 1.0,
                                  height: 54.0,
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 0.0),
                                  iconPadding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 0.0),
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  textStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                        fontSize: 14.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                  elevation: 0.0,
                                  borderSide: BorderSide(
                                    color: Color(0xFFE0E3E7),
                                  ),
                                  borderRadius: BorderRadius.circular(40.0),
                                  hoverColor: Color(0xFFF1F4F8),
                                ),
                              ),
                            ),
                      Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
                        child: FFButtonWidget(
                          onPressed: () async {
                            GoRouter.of(context).prepareAuthEvent();
                            final user =
                                await authManager.signInWithGoogle(context);
                            if (user == null) {
                              return;
                            }
                            _model.user1 = await UsersTable().queryRows(
                              queryFn: (q) => q.eqOrNull(
                                'id',
                                currentUserUid,
                              ),
                            );
                            await SQLiteManager.instance.insertUser(
                              id: _model.user1!.firstOrNull!.id,
                              username: _model.user1!.firstOrNull!.username!,
                              email: _model.user1!.firstOrNull!.email!,
                              isKg: 1,
                            );
                            FFAppState().signedApple = true;
                            safeSetState(() {});
                            await actions.revenueCatLogin(
                              currentUserUid,
                            );
                            await actions.restoreAllFromCloud(
                              '',
                            );

                            context.goNamedAuth(
                              MasterPageWidget.routeName,
                              context.mounted,
                              queryParameters: {
                                'initialTab': serializeParam(
                                  3,
                                  ParamType.int,
                                ),
                              }.withoutNulls,
                            );

                            await actions.initLocalNotifications();

                            safeSetState(() {});
                          },
                          text: FFLocalizations.of(context).getText(
                            'i1rz68vz' /* Continue with Google */,
                          ),
                          icon: FaIcon(
                            FaIconData(const IconData(/* google */ 0xf1a0,
                                fontFamily: 'FontAwesomeBrands',
                                fontPackage: 'font_awesome_flutter')),
                            size: 20.0,
                          ),
                          options: FFButtonOptions(
                            width: MediaQuery.sizeOf(context).width * 1.0,
                            height: 54.0,
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 0.0),
                            iconPadding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 0.0),
                            color: Colors.white,
                            textStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: Color(0xFF101213),
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                            elevation: 0.0,
                            borderSide: BorderSide(
                              color: Color(0xFFE0E3E7),
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(40.0),
                            hoverColor: Color(0xFFF1F4F8),
                          ),
                        ),
                      ),
                    ],
                  ).animateOnPageLoad(
                      animationsMap['columnOnPageLoadAnimation']!),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 12.0,
                    ),
                    Container(
                      height: 20.0,
                    ),
                    InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        context.pushNamed(SignupInWidget.routeName);
                      },
                      child: Text(
                        FFLocalizations.of(context).getText(
                          'nxmlj0r3' /* Continue with email */,
                        ),
                        textAlign: TextAlign.center,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).primary,
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
                    Container(
                      height: 16.0,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          FFLocalizations.of(context).getText(
                            'eai5gy4m' /* By continuing you agree to our */,
                          ),
                          textAlign: TextAlign.center,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF8A8A8E),
                                    fontSize: 12.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                    lineHeight: 1.4,
                                  ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                await launchURL(
                                    'https://docs.google.com/document/d/1cWUt2qPeCEgUHytTRbMkomw6QLaP5Ctj9lCsWzOgw2Q/edit?usp=sharing');
                              },
                              child: Text(
                                FFLocalizations.of(context).getText(
                                  'yqyu9bkf' /* Terms */,
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      fontSize: 12.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                      lineHeight: 1.4,
                                    ),
                              ),
                            ),
                            Text(
                              FFLocalizations.of(context).getText(
                                'nak0vblh' /* and */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF8A8A8E),
                                    fontSize: 12.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                    lineHeight: 1.4,
                                  ),
                            ),
                            InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                await launchURL(
                                    'https://docs.google.com/document/d/1ByRIeU1FcEoXFC3s3pF5PNH-iKnPEZO8rYhGLs9AGBc/edit?usp=sharing');
                              },
                              child: Text(
                                FFLocalizations.of(context).getText(
                                  'y252v12n' /* Privacy Policy */,
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      fontSize: 12.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                      lineHeight: 1.4,
                                    ),
                              ),
                            ),
                          ].divide(SizedBox(width: 4.0)),
                        ),
                      ].divide(SizedBox(height: 4.0)),
                    ),
                  ].divide(SizedBox(height: 0.0)),
                ),
                Container(
                  height: 12.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
