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

import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// TEMP DEBUG v2: richer diagnostics for Apple Sign In.
/// Tries: (1) availability, (2) sign-in WITHOUT scopes,
/// (3) sign-in WITH scopes. Reports each step.
Future<String> debugAppleSignIn() async {
  final log = StringBuffer();

  // Step 1: is Apple Sign In available on this device at all?
  try {
    final available = await SignInWithApple.isAvailable();
    log.write('available=$available | ');
    if (!available) {
      return log.toString() +
          'NOT AVAILABLE - device/iOS version blocks Apple Sign In';
    }
  } catch (e) {
    log.write('availability check failed: $e | ');
  }

  // Step 2: try WITHOUT scopes (no email/name requested).
  try {
    final c = await SignInWithApple.getAppleIDCredential(scopes: []);
    log.write('NO-SCOPES: SUCCESS user=${c.userIdentifier} | ');
  } catch (e) {
    log.write('NO-SCOPES: ${e.runtimeType}: $e | ');
  }

  // Step 3: try WITH scopes (email + name).
  try {
    final c = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    log.write('WITH-SCOPES: SUCCESS user=${c.userIdentifier}, '
        'email=${c.email ?? "null"}');
  } catch (e) {
    log.write('WITH-SCOPES: ${e.runtimeType}: $e');
  }

  return log.toString();
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
