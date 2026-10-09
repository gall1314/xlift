import '/components/feature_row_widget.dart';
import '/components/price_card_widget.dart';
import '/components/thank_for_premium_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/revenue_cat_util.dart' as revenue_cat;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'premium_paywall_page_model.dart';
export 'premium_paywall_page_model.dart';

/// Design a premium paywall screen for "Xlift", a fitness app with AI-powered
/// form analysis.
///
/// Dark theme, mobile-first (iOS/Android).
///
/// **Overall style:**
/// - Background: very dark teal-tinted near-black (e.g. #0A1614 → #0D1F1B
/// subtle vertical gradient), NOT pure black
/// - Accent color: bright teal (#2DD4BF range), used sparingly for CTAs,
/// checkmarks, and highlights
/// - Typography: bold geometric sans-serif for headlines, clean regular
/// weight for body. High contrast white text on dark background
/// - Generous vertical spacing, premium/minimal feel — no clutter, no borders
/// unless needed
///
/// **Layout (top to bottom):**
///
/// 1. Top bar: small close (X) button top-right, low opacity white
/// 2. Eyebrow label: "XLIFT PREMIUM" — small caps, letter-spaced, teal color
/// 3. Headline: "Unlock your full potential" — large, bold, white, 2 lines,
/// centered
/// 4. Feature list (4 rows, left-aligned, centered block):
///    - Each row: teal circular checkmark icon + bold feature name +
/// regular-weight short description in muted gray
///    - Rows: "Advanced tracking — every set, rep and PR" / "Full workout
/// history — free keeps only 7 days" / "Form analysis — detailed movement
/// feedback" / "Progress insights — trends and weekly reports"
/// 5. Pricing cards: two cards side by side, equal width, ~12px gap
///    - Monthly card: "MONTHLY" label, "$3.99" large, "per month · 7-day free
/// trial" small
///    - Yearly card: "YEARLY" label, "$29.99" large, "$2.50/mo · save 37% ·
/// 7-day free trial" small; a small "BEST VALUE" teal pill badge overlapping
/// the top edge of this card
///    - Selected card state: teal border (1.5–2px) + slightly lighter card
/// background; unselected: subtle dark card with faint border
///    - Card corner radius: 16px
/// 6. Primary CTA: full-width pill button, bright teal fill, dark text,
/// "Start 7-Day Free Trial", height ~56px
/// 7. Below CTA: "Then $3.99/month. Cancel anytime." — small, muted gray,
/// centered
/// 8. Footer: "Privacy Policy · Terms · Restore" — small underlined links,
/// low-opacity white, centered
///
/// **Do NOT include:** navigation bars, tab bars, illustrations, or photos.
/// Keep it purely typographic + iconography. Design only — no functionality
/// or state logic required.
class PremiumPaywallPageWidget extends StatefulWidget {
  const PremiumPaywallPageWidget({super.key});

  static String routeName = 'PremiumPaywallPage';
  static String routePath = '/premiumPaywallPage';

  @override
  State<PremiumPaywallPageWidget> createState() =>
      _PremiumPaywallPageWidgetState();
}

class _PremiumPaywallPageWidgetState extends State<PremiumPaywallPageWidget> {
  late PremiumPaywallPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PremiumPaywallPageModel());
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
        backgroundColor: Color(0xFF0A1614),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A1614), Color(0xFF0D1F1B)],
              stops: [0.0, 1.0],
              begin: AlignmentDirectional(0.0, -1.0),
              end: AlignmentDirectional(0, 1.0),
            ),
            shape: BoxShape.rectangle,
          ),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 25.0, 0.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FlutterFlowIconButton(
                        borderRadius: 8.0,
                        buttonSize: 44.0,
                        fillColor: Colors.transparent,
                        icon: Icon(
                          Icons.close_rounded,
                          color: Color(0x66FFFFFF),
                          size: 28.0,
                        ),
                        onPressed: () async {
                          context.safePop();
                        },
                      ),
                    ],
                  ),
                ),
                Spacer(),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      FFLocalizations.of(context).getText(
                        't8rryeqh' /* XLIFT PREMIUM */,
                      ),
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            color: Color(0xFF2DD4BF),
                            fontSize: 12.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w800,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                            lineHeight: 1.4,
                          ),
                    ),
                    Text(
                      FFLocalizations.of(context).getText(
                        'lw64qsg0' /* Unlock your
full potential */
                        ,
                      ),
                      textAlign: TextAlign.center,
                      style:
                          FlutterFlowTheme.of(context).headlineLarge.override(
                                font: GoogleFonts.interTight(
                                  fontWeight: FontWeight.w800,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineLarge
                                      .fontStyle,
                                ),
                                color: Colors.white,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w800,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .headlineLarge
                                    .fontStyle,
                                lineHeight: 1.4,
                              ),
                    ),
                  ].divide(SizedBox(height: 16.0)),
                ),
                Container(
                  height: 40.0,
                ),
                Container(
                  child: Container(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        wrapWithModel(
                          model: _model.featureRowModel1,
                          updateCallback: () => safeSetState(() {}),
                          child: FeatureRowWidget(
                            title: 'Advanced tracking',
                            desc: 'every set, rep and PR',
                          ),
                        ),
                        wrapWithModel(
                          model: _model.featureRowModel2,
                          updateCallback: () => safeSetState(() {}),
                          child: FeatureRowWidget(
                            title: 'Full workout history',
                            desc: 'free keeps only 30 days',
                          ),
                        ),
                        wrapWithModel(
                          model: _model.featureRowModel3,
                          updateCallback: () => safeSetState(() {}),
                          child: FeatureRowWidget(
                            title: 'Form analysis',
                            desc: 'detailed movement feedback',
                          ),
                        ),
                        wrapWithModel(
                          model: _model.featureRowModel4,
                          updateCallback: () => safeSetState(() {}),
                          child: FeatureRowWidget(
                            title: 'Progress insights',
                            desc: 'trends and weekly reports',
                          ),
                        ),
                      ].divide(SizedBox(height: 24.0)),
                    ),
                  ),
                ),
                Spacer(flex: 2),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 1,
                      child: InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          _model.yearly = false;
                          safeSetState(() {});
                        },
                        child: wrapWithModel(
                          model: _model.priceCardModel1,
                          updateCallback: () => safeSetState(() {}),
                          child: PriceCardWidget(
                            selected: !_model.yearly,
                            label: 'MONTHLY',
                            price: '\$5.99',
                            sub: 'per month · 7-day free trial',
                            showBadge: false,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          _model.yearly = true;
                          safeSetState(() {});
                        },
                        child: wrapWithModel(
                          model: _model.priceCardModel2,
                          updateCallback: () => safeSetState(() {}),
                          child: PriceCardWidget(
                            selected: _model.yearly,
                            label: 'YEARLY',
                            price: '\$39.99',
                            sub: '\$3.33/mo · save 37% · 7-day free trial',
                            showBadge: true,
                          ),
                        ),
                      ),
                    ),
                  ].divide(SizedBox(width: 16.0)),
                ),
                Container(
                  height: 32.0,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Builder(
                      builder: (context) => FFButtonWidget(
                        onPressed: () async {
                          final isEntitled =
                              await revenue_cat.isEntitled('Xliftfinal Pro') ??
                                  false;
                          if (!isEntitled) {
                            await revenue_cat.loadOfferings();
                          }

                          if (isEntitled) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'already premium',
                                  style: TextStyle(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                  ),
                                ),
                                duration: Duration(milliseconds: 4000),
                                backgroundColor:
                                    FlutterFlowTheme.of(context).secondary,
                              ),
                            );
                          } else {
                            if (!_model.yearly) {
                              _model.month = await revenue_cat.purchasePackage(
                                  revenue_cat
                                      .offerings!.current!.monthly!.identifier);
                            } else {
                              _model.year = await revenue_cat.purchasePackage(
                                  revenue_cat
                                      .offerings!.current!.annual!.identifier);
                            }

                            FFAppState().isPremium = true;
                            safeSetState(() {});
                            context.safePop();
                            await showDialog(
                              context: context,
                              builder: (dialogContext) {
                                return Dialog(
                                  elevation: 0,
                                  insetPadding: EdgeInsets.zero,
                                  backgroundColor: Colors.transparent,
                                  alignment: AlignmentDirectional(0.0, 0.0)
                                      .resolve(Directionality.of(context)),
                                  child: GestureDetector(
                                    onTap: () {
                                      FocusScope.of(dialogContext).unfocus();
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                    },
                                    child: ThankForPremiumWidget(),
                                  ),
                                );
                              },
                            );
                          }

                          safeSetState(() {});
                        },
                        text: FFLocalizations.of(context).getText(
                          'yd1g8q07' /* Start 7-Day Free Trial */,
                        ),
                        options: FFButtonOptions(
                          width: double.infinity,
                          height: 56.0,
                          padding: EdgeInsets.all(8.0),
                          iconPadding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 0.0, 0.0),
                          color: FlutterFlowTheme.of(context).secondary,
                          textStyle:
                              FlutterFlowTheme.of(context).titleMedium.override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                    ),
                                    color: Colors.white,
                                    fontSize: 18.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                          elevation: 0.0,
                          borderSide: BorderSide(
                            color: Colors.transparent,
                          ),
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                      ),
                    ),
                    Text(
                      _model.yearly
                          ? 'Then \$29.99/year. Cancel anytime.'
                          : 'Then \$3.99/month. Cancel anytime.',
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).labelSmall.override(
                            font: GoogleFonts.inter(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .fontStyle,
                            ),
                            color: Color(0x66FFFFFF),
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
                  ].divide(SizedBox(height: 16.0)),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: InkWell(
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
                              '214fymmx' /* Privacy Policy */,
                            ),
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .labelSmall
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                  ),
                                  color: Color(0x4DFFFFFF),
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .labelSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .labelSmall
                                      .fontStyle,
                                  decoration: TextDecoration.underline,
                                  lineHeight: 1.4,
                                ),
                          ),
                        ),
                      ),
                      Text(
                        FFLocalizations.of(context).getText(
                          's0krmnr4' /* · */,
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
                              color: Color(0x33FFFFFF),
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
                      Expanded(
                        child: InkWell(
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
                              'ca4hmb6f' /* Terms */,
                            ),
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .labelSmall
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                  ),
                                  color: Color(0x4DFFFFFF),
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .labelSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .labelSmall
                                      .fontStyle,
                                  decoration: TextDecoration.underline,
                                  lineHeight: 1.4,
                                ),
                          ),
                        ),
                      ),
                      Text(
                        FFLocalizations.of(context).getText(
                          'bff1v9sz' /* · */,
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
                              color: Color(0x33FFFFFF),
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
                      Expanded(
                        child: InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            await revenue_cat.restorePurchases();
                          },
                          child: Text(
                            FFLocalizations.of(context).getText(
                              'vpkpqnes' /* Restore */,
                            ),
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .labelSmall
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                  ),
                                  color: Color(0x4DFFFFFF),
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .labelSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .labelSmall
                                      .fontStyle,
                                  decoration: TextDecoration.underline,
                                  lineHeight: 1.4,
                                ),
                          ),
                        ),
                      ),
                    ].divide(SizedBox(width: 16.0)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
