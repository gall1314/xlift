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

import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

// ─── Singleton משותף ───────────────────────────────────────────
class _FLNPSingleton {
  _FLNPSingleton._();
  static final FlutterLocalNotificationsPlugin instance =
      FlutterLocalNotificationsPlugin();
}
// ───────────────────────────────────────────────────────────────

Future<void> scheduleRestNotification(
  int restSeconds,
  bool isRest,
  String? exerciseName,
) async {
  final flnp = _FLNPSingleton.instance;
  final secs = restSeconds <= 0 ? 1 : restSeconds;

  final String title;
  final String body;

  if (isRest) {
    title = 'Rest finished';
    body = 'Time to start your next set';
  } else {
    final exName = (exerciseName != null && exerciseName.trim().isNotEmpty)
        ? exerciseName.trim()
        : 'Exercise';
    title = '$exName timer finished';
    body = 'Great job! Your timed set is complete';
  }

  final details = const NotificationDetails(
    android: AndroidNotificationDetails(
      'rest_channel',
      'Rest Timers',
      channelDescription: 'Notifications for exercise rest timers',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    ),
  );

  final when = tz.TZDateTime.now(tz.local).add(Duration(seconds: secs));

  await flnp.zonedSchedule(
    1001,
    title,
    body,
    when,
    details,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    payload:
        isRest ? 'type=rest' : 'type=timedExercise;name=${exerciseName ?? ''}',
  );
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
