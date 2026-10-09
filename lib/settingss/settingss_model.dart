import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/instant_timer.dart';
import '/index.dart';
import 'settingss_widget.dart' show SettingssWidget;
import 'package:flutter/material.dart';

class SettingssModel extends FlutterFlowModel<SettingssWidget> {
  ///  Local state fields for this page.

  bool notificationsDenied = false;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - isNotificationsDenied] action in settingss widget.
  bool? denied;
  InstantTimer? instantTimer;
  // State field(s) for Switch widget.
  bool? switchValue;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    instantTimer?.cancel();
  }
}
