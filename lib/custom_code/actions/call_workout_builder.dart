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

import 'dart:convert';
import 'package:http/http.dart' as http;

const String _kWorkoutBuilderUrl =
    'https://zlbmwitjsmenaxofabhi.supabase.co/functions/v1/super-worker';

// Anon key is public by design - safe to ship in the client.
// Real protection = user JWT + "Verify JWT" enabled on the Edge Function.
const String _kSupabaseAnonKey = 'PASTE_YOUR_ANON_KEY_HERE';

/// goal is an INTEGER contract with the model:
/// 0 = Hypertrophy, 1 = Strength, 2 = Muscular Endurance.
Future<dynamic> callWorkoutBuilder(
  int goal,
  String level,
  List<String> targetMuscles,
) async {
  try {
    // 1. Pull the logged-in user's JWT directly from the Supabase session.
    final String? jwt = SupaFlow.client.auth.currentSession?.accessToken;

    if (jwt == null || jwt.isEmpty) {
      return {
        'success': false,
        'error': 'no_session',
        'message': 'No logged-in user session found.',
      };
    }

    // Defensive clamp: anything outside 0-2 falls back to 0 (Hypertrophy),
    // matching the prompt's own fallback rule.
    final int safeGoal = (goal < 0 || goal > 2) ? 0 : goal;

    // 2. POST to the Edge Function.
    final response = await http
        .post(
          Uri.parse(_kWorkoutBuilderUrl),
          headers: {
            'Authorization': 'Bearer $jwt',
            'apikey': _kSupabaseAnonKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'goal': safeGoal,
            'level': level,
            'target_muscles': targetMuscles,
          }),
        )
        .timeout(const Duration(seconds: 60));

    // 3. Parse ajnd regturn.
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return {
          'success': false,
          'error': 'bad_json',
          'message': 'Response was not valid JSON.',
          'raw': response.body,
        };
      }
    }

    return {
      'success': false,
      'error': 'http_${response.statusCode}',
      'message': response.body,
    };
  } catch (e) {
    // Never throw - keep the action chain alive (fetchDirect pattern).
    return {
      'success': false,
      'error': 'exception',
      'message': e.toString(),
    };
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
