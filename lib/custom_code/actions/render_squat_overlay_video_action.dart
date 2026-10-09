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

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

/// Burn a reps counter and feedback text onto the source video using
/// telemetry from analyzeSquatVideoAction.
///
/// This version uses an ASS subtitle file (rendered via the `subtitles=`
/// filter) instead of dozens of `drawtext` calls. ASS handles thousands
/// of timed events efficiently, and avoids the expression-parsing limits
/// that the drawtext approach hit.
///
/// On success returns a `file://` URI string to the rendered video.
/// On failure returns a string starting with `ERROR:` with details.
Future<String> renderSquatOverlayVideoAction(
  dynamic analysisResult,
) async {
  void log(String msg) {
    // ignore: avoid_print
    print('[squat_overlay] $msg');
  }

  log('=== START renderSquatOverlayVideoAction ===');

  // ---------- 1) Validate input ----------
  if (analysisResult == null) {
    return 'ERROR: input - analysisResult is null';
  }
  if (analysisResult is! Map) {
    return 'ERROR: input - analysisResult is ${analysisResult.runtimeType}, expected Map';
  }
  log('analysisResult keys: ${analysisResult.keys.toList()}');

  final String? sourcePath = analysisResult['_source_video_path'] as String?;
  if (sourcePath == null || sourcePath.isEmpty) {
    return 'ERROR: input - _source_video_path missing';
  }
  log('sourcePath = $sourcePath');

  final File srcFile = File(sourcePath);
  if (!srcFile.existsSync()) {
    return 'ERROR: source - file not found at $sourcePath';
  }
  final int srcSize = srcFile.lengthSync();
  log('source video size: $srcSize bytes');
  if (srcSize == 0) return 'ERROR: source - file is empty';

  final List<dynamic> telemetry =
      (analysisResult['_frame_telemetry'] as List?) ?? [];
  log('telemetry rows: ${telemetry.length}');
  if (telemetry.isEmpty) return 'ERROR: input - telemetry empty';

  final double fps =
      (analysisResult['analyzed_fps'] as num?)?.toDouble() ?? 6.0;
  final int totalReps = (analysisResult['squat_count'] as num?)?.toInt() ?? 0;
  log('fps=$fps, totalReps=$totalReps');

  // ---------- 2) Build ASS subtitle file ----------
  // ASS format ref: https://aegisub.org/docs/3.2/ASS_Tags/
  // We use one Style per overlay element so positioning is independent.

  final StringBuffer ass = StringBuffer();

  // Header — PlayResX/Y are reference dimensions; ffmpeg scales to video.
  ass.writeln('[Script Info]');
  ass.writeln('ScriptType: v4.00+');
  ass.writeln('PlayResX: 1280');
  ass.writeln('PlayResY: 720');
  ass.writeln('ScaledBorderAndShadow: yes');
  ass.writeln('WrapStyle: 2');
  ass.writeln();
  ass.writeln('[V4+ Styles]');
  ass.writeln(
      'Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding');
  // Reps counter — top-left, white on semi-transparent black box.
  // BorderStyle=3 means "opaque box" (uses BackColour as box fill).
  // Colors are &HAABBGGRR (alpha+BGR). 80=50% transparent.
  ass.writeln(
      'Style: Reps,Arial,42,&H00FFFFFF,&H00FFFFFF,&H00000000,&H80000000,1,0,0,0,100,100,0,0,3,0,0,7,20,20,20,1');
  // Feedback banner — bottom center, white on dark.
  ass.writeln(
      'Style: Feedback,Arial,32,&H00FFFFFF,&H00FFFFFF,&H00000000,&H80000000,1,0,0,0,100,100,0,0,3,0,0,2,40,40,40,1');
  // Final total — center, big.
  ass.writeln(
      'Style: Total,Arial,64,&H00FFFFFF,&H00FFFFFF,&H00000000,&H80000000,1,0,0,0,100,100,0,0,3,0,0,5,40,40,40,1');
  ass.writeln();
  ass.writeln('[Events]');
  ass.writeln(
      'Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text');

  String fmtTime(double sec) {
    if (sec < 0) sec = 0;
    final int h = (sec ~/ 3600);
    final int m = ((sec % 3600) ~/ 60);
    final int s = (sec % 60).floor();
    final int cs = (((sec - sec.floor()) * 100)).floor();
    return '${h.toString()}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}';
  }

  String escAss(String s) {
    // ASS uses {} for tags and \N for newlines. Escape braces and strip
    // any non-ASCII chars (unicode rendering depends on installed fonts).
    return s
        .replaceAll('{', '(')
        .replaceAll('}', ')')
        .replaceAll(',', ' ')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '');
  }

  // ---- Reps counter events ----
  int currentReps = -1;
  double currentStart = 0;
  int repEventCount = 0;
  for (int i = 0; i < telemetry.length; i++) {
    final Map<String, dynamic> row =
        Map<String, dynamic>.from(telemetry[i] as Map);
    final int reps = (row['reps'] as num?)?.toInt() ?? 0;
    final double tSec = i / fps;
    if (reps != currentReps) {
      if (currentReps >= 0) {
        ass.writeln(
            'Dialogue: 0,${fmtTime(currentStart)},${fmtTime(tSec)},Reps,,0,0,0,,Reps: $currentReps');
        repEventCount++;
      }
      currentReps = reps;
      currentStart = tSec;
    }
  }
  if (currentReps >= 0) {
    final double endSec = telemetry.length / fps;
    ass.writeln(
        'Dialogue: 0,${fmtTime(currentStart)},${fmtTime(endSec)},Reps,,0,0,0,,Reps: $currentReps');
    repEventCount++;
  }
  log('reps events: $repEventCount');

  // ---- Feedback banner events ----
  String? lastFb;
  double lastFbStart = 0;
  int fbEventCount = 0;
  for (int i = 0; i < telemetry.length; i++) {
    final Map<String, dynamic> row =
        Map<String, dynamic>.from(telemetry[i] as Map);
    final String? fb = row['feedback'] as String?;
    final double tSec = i / fps;
    if (fb != null && fb != lastFb) {
      if (lastFb != null) {
        ass.writeln(
            'Dialogue: 0,${fmtTime(lastFbStart)},${fmtTime(tSec)},Feedback,,0,0,0,,${escAss(lastFb!)}');
        fbEventCount++;
      }
      lastFb = fb;
      lastFbStart = tSec;
    } else if (fb == null && lastFb != null) {
      ass.writeln(
          'Dialogue: 0,${fmtTime(lastFbStart)},${fmtTime(tSec + 1.2)},Feedback,,0,0,0,,${escAss(lastFb!)}');
      fbEventCount++;
      lastFb = null;
    }
  }
  if (lastFb != null) {
    final double endSec = telemetry.length / fps;
    ass.writeln(
        'Dialogue: 0,${fmtTime(lastFbStart)},${fmtTime(endSec)},Feedback,,0,0,0,,${escAss(lastFb!)}');
    fbEventCount++;
  }
  log('feedback events: $fbEventCount');

  // ---- Final total badge (last 2 seconds) ----
  final double totalSec = telemetry.length / fps;
  final double badgeStart = totalSec - 2.0 < 0 ? 0 : totalSec - 2.0;
  ass.writeln(
      'Dialogue: 0,${fmtTime(badgeStart)},${fmtTime(totalSec + 1)},Total,,0,0,0,,Total: $totalReps reps');

  final String assContent = ass.toString();
  log('ASS file size: ${assContent.length} chars');

  // ---------- 3) Write ASS file to disk ----------
  Directory tmp;
  try {
    tmp = await getTemporaryDirectory();
  } catch (e) {
    return 'ERROR: paths - cannot get tmp dir: $e';
  }
  final String assPath = p.join(
    tmp.path,
    'squat_overlay_${DateTime.now().millisecondsSinceEpoch}.ass',
  );
  try {
    await File(assPath).writeAsString(assContent);
  } catch (e) {
    return 'ERROR: write_ass - $e';
  }
  log('wrote ASS to $assPath');

  // ---------- 4) Resolve output path ----------
  Directory docsDir;
  try {
    docsDir = await getApplicationDocumentsDirectory();
  } catch (e) {
    return 'ERROR: paths - cannot get docs dir: $e';
  }
  final String outName =
      'squat_overlay_${DateTime.now().millisecondsSinceEpoch}.mp4';
  final String outPath = p.join(docsDir.path, outName);
  log('outPath = $outPath');

  // ---------- 5) Run ffmpeg ----------
  // The subtitles= filter needs the .ass path. On some platforms the
  // path needs single-quoting and colon-escaping, but ffmpeg-kit handles
  // file:// URIs and absolute paths well.
  // We escape `:` in the path because subtitles= treats `:` as a separator.
  final String escapedAssPath =
      assPath.replaceAll('\\', '\\\\').replaceAll(':', '\\:');

  final String filterStr = "subtitles='$escapedAssPath'";
  log('filter: $filterStr');

  // Attempt #1: with audio copy
  final String cmd1 = "-y -i \"$sourcePath\" -vf \"$filterStr\" "
      "-c:v libx264 -preset ultrafast -pix_fmt yuv420p "
      "-movflags +faststart -c:a copy \"$outPath\"";
  log('ffmpeg attempt #1');

  String? logs1;
  bool success = false;
  try {
    final session = await FFmpegKit.execute(cmd1);
    final rc = await session.getReturnCode();
    logs1 = await session.getAllLogsAsString();
    log('attempt #1 rc: $rc');
    if (ReturnCode.isSuccess(rc)) {
      success = true;
    } else {
      final tail = (logs1 ?? '').length > 600
          ? (logs1 ?? '').substring((logs1 ?? '').length - 600)
          : (logs1 ?? '');
      log('attempt #1 tail:\n$tail');
    }
  } catch (e) {
    return 'ERROR: ffmpeg1 - exception: $e';
  }

  // Attempt #2: no audio
  String? logs2;
  if (!success) {
    log('ffmpeg attempt #2 (no audio)');
    final String cmd2 = "-y -i \"$sourcePath\" -vf \"$filterStr\" "
        "-c:v libx264 -preset ultrafast -pix_fmt yuv420p "
        "-movflags +faststart -an \"$outPath\"";
    try {
      final session2 = await FFmpegKit.execute(cmd2);
      final rc2 = await session2.getReturnCode();
      logs2 = await session2.getAllLogsAsString();
      log('attempt #2 rc: $rc2');
      if (ReturnCode.isSuccess(rc2)) {
        success = true;
      } else {
        final tail = (logs2 ?? '').length > 600
            ? (logs2 ?? '').substring((logs2 ?? '').length - 600)
            : (logs2 ?? '');
        log('attempt #2 tail:\n$tail');
      }
    } catch (e) {
      return 'ERROR: ffmpeg2 - exception: $e';
    }
  }

  // Attempt #3 (last resort): no overlay at all — just re-encode the
  // source so the user at least gets a playable video back.
  if (!success) {
    log('ffmpeg attempt #3 (no overlay, fallback)');
    final String cmd3 = "-y -i \"$sourcePath\" "
        "-c:v libx264 -preset ultrafast -pix_fmt yuv420p "
        "-movflags +faststart -an \"$outPath\"";
    try {
      final session3 = await FFmpegKit.execute(cmd3);
      final rc3 = await session3.getReturnCode();
      log('attempt #3 rc: $rc3');
      if (ReturnCode.isSuccess(rc3)) {
        success = true;
        log('fallback succeeded — video has NO overlay');
      }
    } catch (e) {
      log('attempt #3 exception: $e');
    }
  }

  if (!success) {
    final String tail = (logs2 ?? logs1 ?? '');
    final String shortTail =
        tail.length > 400 ? tail.substring(tail.length - 400) : tail;
    return 'ERROR: ffmpeg - all attempts failed. Last log: $shortTail';
  }

  // ---------- 6) Verify output ----------
  final File outFile = File(outPath);
  if (!outFile.existsSync()) {
    return 'ERROR: output - file missing at $outPath';
  }
  final int outSize = outFile.lengthSync();
  log('output size: $outSize bytes');
  if (outSize == 0) return 'ERROR: output - file empty';

  // Clean up the ASS file (optional)
  try {
    File(assPath).deleteSync();
  } catch (_) {}

  final String fileUri = 'file://$outPath';
  log('SUCCESS: $fileUri');
  log('=== END ===');

  try {
    analysisResult['video_path'] = fileUri;
  } catch (_) {}

  return fileUri;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
