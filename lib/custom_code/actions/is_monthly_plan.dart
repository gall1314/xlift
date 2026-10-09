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

import 'package:purchases_flutter/purchases_flutter.dart';

/// Assumes the user is already known to be entitleגd (paying).
///
/// true  = monthly plan false = yearly plan
Future<bool> isMonthlyPlan() async {
  try {
    final customerInfo = await Purchases.getCustomerInfo();

    if (customerInfo.entitlements.active.isEmpty) {
      // Shouldn't happen if called only for paying users; fail safe.
      return true;
    }

    final productId = customerInfo
        .entitlements.active.values.first.productIdentifier
        .toLowerCase();

    if (productId.contains('year') || productId.contains('annual')) {
      return false;
    }
    return true;
  } catch (_) {
    return true;
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
