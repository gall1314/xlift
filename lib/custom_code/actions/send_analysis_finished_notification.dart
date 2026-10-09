// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _flnp = FlutterLocalNotificationsPlugin();

bool _isInitialized = false;

/// חייב לקרוא לזה פעם אחת בתחילת האפליקציה
Future<void> initNotifications() async {
  if (_isInitialized) return;

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();

  const settings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await _flnp.initialize(settings);

  _isInitialized = true;
}

/// שליחת נוטיפיקציה - אנליזה הסתיימה
Future<void> sendAnalysisFinishedNotification(
  String? exerciseName,
  bool isVideo,
) async {
  // לוודא שהמערכת מאותחלת
  await initNotifications();

  final exName = (exerciseName != null && exerciseName.trim().isNotEmpty)
      ? exerciseName.trim()
      : 'Exercise';

  final String title =
      isVideo ? 'Video analysis finished' : 'Analysis finished';

  final String body =
      isVideo ? '$exName video analysis is ready' : '$exName analysis is ready';

  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      'analysis_channel',
      'Analysis Notifications',
      channelDescription: 'Notifications for completed analysis',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    ),
  );

  // ID ייחודי כדי לא לדרוס נוטיפיקציות
  final int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  await _flnp.show(
    id,
    title,
    body,
    details,
    payload: isVideo
        ? 'type=analysisVideo;exercise=${exerciseName ?? ''}'
        : 'type=analysis;exercise=${exerciseName ?? ''}',
  );
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
