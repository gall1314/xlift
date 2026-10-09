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

// Begin custom widget code

import 'dart:math';

/// Saves all flattened analyses with verbose logging. Replaces the
/// FlutterFlow loop over insertSetAnaגlysis. Returns 'ok:<n>' or
/// 'error:<detail>'. NEVER throws - the chבain always continues.
Future<String> saveAnalysesWithLogs(
  List<dynamic> flatAnalyses,
) async {
  final sw = Stopwatch()..start();
  print('[saveAnalyses] START items=${flatAnalyses.length}');

  String uuid() {
    final r = Random();
    String hex(int n) =>
        List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-'
        '${(8 + r.nextInt(4)).toRadixString(16)}${hex(3)}-${hex(12)}';
  }

  int saved = 0;
  try {
    final db = SQLiteManager.instance.database;

    for (final item in flatAnalyses) {
      if (item is! Map) {
        print('[saveAnalyses] SKIP non-map item');
        continue;
      }

      final setLogId = item['setLogId']?.toString() ?? '';
      if (setLogId.isEmpty) {
        print('[saveAnalyses] SKIP empty setLogId');
        continue;
      }

      print('[saveAnalyses] inserting setLogId=$setLogId '
          'score=${item['technique_score']}');

      try {
        await db.rawInsert(
          'INSERT OR REPLACE INTO set_analysis '
          '(id, set_log_id, analyzed_at, score, total_reps, proper_reps, '
          'feedback, technique_label, technique_score_display, form_tip) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            uuid(),
            setLogId,
            DateTime.now().toIso8601String(),
            (item['technique_score'] as num?)?.toDouble() ?? 0.0,
            item['squat_count'] ?? 0,
            item['good_reps'] ?? 0,
            item['feedback']?.toString() ?? '[]',
            item['technique_label']?.toString() ?? '',
            item['technique_score_display']?.toString() ?? '',
            item['form_tip']?.toString() ?? '',
          ],
        );
        saved++;
        print('[saveAnalyses] OK ($saved/${flatAnalyses.length}) '
            'elapsed=${sw.elapsedMilliseconds}ms');
      } catch (e) {
        print('[saveAnalyses] INSERT FAILED setLogId=$setLogId: $e');
        return 'error:insert:$setLogId:$e';
      }
    }

    print('[saveAnalyses] DONE saved=$saved total=${sw.elapsedMilliseconds}ms');
    return 'ok:$saved';
  } catch (e) {
    print('[saveAnalyses] FATAL: $e');
    return 'error:fatal:$e';
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
