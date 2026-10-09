import '/backend/sqlite/sqlite_manager.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'warmup_bottom_shit_model.dart';
export 'warmup_bottom_shit_model.dart';

/// Create a component,
/// “Design a modern mobile bottom sheet in light mode for a fitness app .
///
/// Style: clean, minimal, sharp edges with large rounded corners, subtle
/// depth (no heavy skeuomorphism). Background: pure white (#FFFFFF) with soft
/// grey dividers. Accent color: bright turquoise/teal (#28D1C1). Typography:
/// bold, legible headlines; compact labels in dark grey (#222222).
///
/// Content (top→bottom):
///
/// Header row:
/// Title: ‘Warm-up Generator’ (left), Close ‘✕’ (right).
/// Small subtitle under title: ‘Auto-create warm-up sets that won’t count
/// toward stats.’ in light grey text (#777777).
///
/// Target Weight (kg): numeric field with prefix ‘kg’, prefilled (e.g.,
/// ‘80’), helper text: ‘Pulled from your last session’.
///
/// Number of Warm-up Sets: stepper (− 2 +), default ‘3’.
///
/// Scheme (editable % per set): horizontal list of chips/inputs: ‘50%’,
/// ‘70%’, ‘85%’. Each chip is editable, with turquoise outline and rounded
/// shape.
///
/// Include Bar Weight: toggle ON/OFF (helper: ‘Subtracts empty bar from
/// target if on’).
///
/// Reps per set: segmented control ‘5 | 3 | 1 | Custom’.
///
/// Preview card (live):
/// Shows 3 rows labeled Set 1/2/3 with calculated weights (e.g., ‘Set 1 — 40
/// kg, 5 reps’, ‘Set 2 — 56 kg, 3 reps’, ‘Set 3 — 68 kg, 1 rep’). Each row
/// has a small turquoise pill ‘Warm-up’ and an edit icon.
///
/// Footer actions (sticky):
/// Left ghost button: ‘Reset’.
/// Right primary button: ‘Generate Warm-ups’ (filled turquoise).
/// Secondary text link under buttons: ‘Mark generated sets as warm-up only’
/// in grey.
///
/// Micro-interactions: soft shadows under cards, smooth slide-up animation,
/// subtle haptic feedback on tap.
/// Spacing: airy; no clutter.
/// Deliver as a high-fidelity mobile mockup (iOS/Android), 1080×1920,
/// centered composition.”
class WarmupBottomShitWidget extends StatefulWidget {
  const WarmupBottomShitWidget({
    super.key,
    required this.exerciseId,
    required this.equipment,
  });

  final int? exerciseId;
  final String? equipment;

  @override
  State<WarmupBottomShitWidget> createState() => _WarmupBottomShitWidgetState();
}

class _WarmupBottomShitWidgetState extends State<WarmupBottomShitWidget> {
  late WarmupBottomShitModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WarmupBottomShitModel());

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.weight2 = await SQLiteManager.instance.previosSet(
        exerciseId: widget.exerciseId!,
        setNumber: 1,
      );
      _model.weight = functions.suggestBumpedTarget(
          _model.weight2?.firstOrNull?.weight,
          widget.equipment!,
          FFAppState().isKg);
      safeSetState(() {});
    });
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 3.93,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          boxShadow: [
            BoxShadow(
              blurRadius: 10.0,
              color: Color(0x1A000000),
              offset: Offset(
                0.0,
                -2.0,
              ),
              spreadRadius: 0.0,
            )
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(24.0, 24.0, 24.0, 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FlutterFlowIconButton(
                    borderColor: Colors.transparent,
                    borderRadius: 20.0,
                    buttonSize: 40.0,
                    fillColor: Colors.transparent,
                    icon: Icon(
                      Icons.close,
                      color: FlutterFlowTheme.of(context).primaryText,
                      size: 24.0,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                  ),
                  Text(
                    FFLocalizations.of(context).getText(
                      'z195okww' /* Warm-up Generator */,
                    ),
                    style: FlutterFlowTheme.of(context).titleLarge.override(
                          font: GoogleFonts.interTight(
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleLarge
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).primaryText,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                          fontStyle:
                              FlutterFlowTheme.of(context).titleLarge.fontStyle,
                        ),
                  ),
                  FlutterFlowIconButton(
                    borderRadius: 8.0,
                    buttonSize: 40.0,
                    icon: Icon(
                      Icons.restart_alt,
                      color: FlutterFlowTheme.of(context).primaryText,
                      size: 24.0,
                    ),
                    onPressed: () async {
                      _model.numberSets = 3;
                      _model.weight = valueOrDefault<double>(
                        _model.weight2?.firstOrNull?.weight,
                        0.0,
                      );
                      safeSetState(() {});
                    },
                  ),
                ],
              ),
              Text(
                FFLocalizations.of(context).getText(
                  'f1s21xn3' /* Auto-create warm-up sets that ... */,
                ),
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      font: GoogleFonts.inter(
                        fontWeight:
                            FlutterFlowTheme.of(context).bodySmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      ),
                      color: Color(0xFF777777),
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).bodySmall.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodySmall.fontStyle,
                    ),
              ),
              Container(
                width: double.infinity,
                height: 1.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).alternate,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FFLocalizations.of(context).getText(
                      '914pplja' /* Target Weight (kg) */,
                    ),
                    style: FlutterFlowTheme.of(context).labelMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).primaryText,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                          fontStyle: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontStyle,
                        ),
                  ),
                  Align(
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Container(
                      width: 200.0,
                      height: 100.0,
                      child: custom_widgets.WeightStepperTextField(
                        width: 200.0,
                        height: 100.0,
                        initialWeight: functions.suggestBumpedTarget(
                            _model.weight2?.firstOrNull?.weight,
                            widget.equipment!,
                            FFAppState().isKg),
                        equipment: widget.equipment!,
                        isKg: FFAppState().isKg,
                        onChanged: (value) async {
                          _model.weight = value;
                          safeSetState(() {});
                        },
                      ),
                    ),
                  ),
                ].divide(SizedBox(height: 8.0)),
              ),
              Container(
                width: double.infinity,
                height: 1.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).alternate,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FFLocalizations.of(context).getText(
                      'rubwy8mq' /* Number of Warm-up Sets */,
                    ),
                    style: FlutterFlowTheme.of(context).labelMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).primaryText,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                          fontStyle: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontStyle,
                        ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FlutterFlowIconButton(
                        borderColor: FlutterFlowTheme.of(context).alternate,
                        borderRadius: 20.0,
                        borderWidth: 1.0,
                        buttonSize: 40.0,
                        fillColor:
                            FlutterFlowTheme.of(context).primaryBackground,
                        disabledIconColor:
                            FlutterFlowTheme.of(context).alternate,
                        icon: Icon(
                          Icons.remove,
                          color: FlutterFlowTheme.of(context).primaryText,
                          size: 20.0,
                        ),
                        onPressed: (_model.numberSets <= 1)
                            ? null
                            : () async {
                                _model.numberSets = _model.numberSets + -1;
                                safeSetState(() {});
                              },
                      ),
                      Text(
                        _model.numberSets.toString(),
                        style: FlutterFlowTheme.of(context)
                            .titleMedium
                            .override(
                              font: GoogleFonts.interTight(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).primaryText,
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .fontStyle,
                            ),
                      ),
                      FlutterFlowIconButton(
                        borderColor: FlutterFlowTheme.of(context).alternate,
                        borderRadius: 20.0,
                        borderWidth: 1.0,
                        buttonSize: 40.0,
                        fillColor:
                            FlutterFlowTheme.of(context).primaryBackground,
                        disabledIconColor:
                            FlutterFlowTheme.of(context).alternate,
                        icon: Icon(
                          Icons.add,
                          color: FlutterFlowTheme.of(context).primaryText,
                          size: 20.0,
                        ),
                        onPressed: (_model.numberSets >= 4)
                            ? null
                            : () async {
                                _model.numberSets = _model.numberSets + 1;
                                safeSetState(() {});
                              },
                      ),
                    ].divide(SizedBox(width: 16.0)),
                  ),
                ].divide(SizedBox(height: 20.0)),
              ),
              Container(
                width: double.infinity,
                height: 1.0,
                decoration: BoxDecoration(
                  color: Color(0xFFF0F0F0),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: FFButtonWidget(
                          onPressed: () async {
                            _model.warmup =
                                await actions.applyWarmupSimpleUnits(
                              FFAppState().warmupSets.toList(),
                              widget.exerciseId!,
                              widget.equipment!,
                              FFAppState().isKg,
                              _model.weight,
                              _model.numberSets,
                            );
                            FFAppState().warmupSets =
                                _model.warmup!.toList().cast<dynamic>();
                            safeSetState(() {});
                            Navigator.pop(context, true);

                            safeSetState(() {});
                          },
                          text: FFLocalizations.of(context).getText(
                            'ydjwxhqd' /* Generate Warm-ups */,
                          ),
                          options: FFButtonOptions(
                            height: 48.0,
                            padding: EdgeInsets.all(8.0),
                            iconPadding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 0.0),
                            color: Color(0xFF28D1C1),
                            textStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: Colors.white,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                            elevation: 0.0,
                            borderSide: BorderSide(
                              color: Colors.transparent,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                    ].divide(SizedBox(width: 16.0)),
                  ),
                ].divide(SizedBox(height: 12.0)),
              ),
            ].divide(SizedBox(height: 20.0)),
          ),
        ),
      ),
    );
  }
}
