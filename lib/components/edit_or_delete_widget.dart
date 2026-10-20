import '/backend/sqlite/sqlite_manager.dart';
import '/components/delete_alert_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_or_delete_model.dart';
export 'edit_or_delete_model.dart';

class EditOrDeleteWidget extends StatefulWidget {
  const EditOrDeleteWidget({
    super.key,
    required this.workout,
  });

  final GetdirtyworkoutsRow? workout;

  @override
  State<EditOrDeleteWidget> createState() => _EditOrDeleteWidgetState();
}

class _EditOrDeleteWidgetState extends State<EditOrDeleteWidget> {
  late EditOrDeleteModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditOrDeleteModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 135.0,
      height: 108.1,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: InkWell(
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () async {
                context.pushNamed(
                  EditWorkoutV2Widget.routeName,
                  queryParameters: {
                    'shouldInit': serializeParam(
                      true,
                      ParamType.bool,
                    ),
                    'workoutId': serializeParam(
                      widget.workout?.id,
                      ParamType.String,
                    ),
                    'workoutName': serializeParam(
                      widget.workout?.name,
                      ParamType.String,
                    ),
                  }.withoutNulls,
                );
              },
              child: Container(
                decoration: BoxDecoration(),
                child: Container(
                  height: 44.0,
                  decoration: BoxDecoration(),
                  child: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.edit,
                          color: FlutterFlowTheme.of(context).primaryText,
                          size: 20.0,
                        ),
                        Text(
                          FFLocalizations.of(context).getText(
                            '9kxd6esc' /* Edit */,
                          ),
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
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                        ),
                      ].divide(SizedBox(width: 12.0)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Divider(
            thickness: 2.0,
            color: FlutterFlowTheme.of(context).alternate,
          ),
          Builder(
            builder: (context) => InkWell(
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () async {
                await showAlignedDialog(
                  context: context,
                  isGlobal: false,
                  avoidOverflow: false,
                  targetAnchor: AlignmentDirectional(0.0, 0.0)
                      .resolve(Directionality.of(context)),
                  followerAnchor: AlignmentDirectional(0.0, 0.0)
                      .resolve(Directionality.of(context)),
                  builder: (dialogContext) {
                    return Material(
                      color: Colors.transparent,
                      child: DeleteAlertWidget(
                        workoutID: widget.workout!.id,
                      ),
                    );
                  },
                );
              },
              child: Container(
                decoration: BoxDecoration(),
                child: Container(
                  height: 44.0,
                  decoration: BoxDecoration(),
                  child: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.delete,
                          color: FlutterFlowTheme.of(context).error,
                          size: 20.0,
                        ),
                        Text(
                          FFLocalizations.of(context).getText(
                            '5nhj04kn' /* Delete */,
                          ),
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
                                    color: FlutterFlowTheme.of(context).error,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                        ),
                      ].divide(SizedBox(width: 12.0)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
