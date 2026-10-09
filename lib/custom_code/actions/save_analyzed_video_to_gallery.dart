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
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

/// Progress callback: [fraction] 0..1, [stage] one of
/// 'extract' | 'render' | 'encode' | 'save' | 'done'.
typedef SaveVideoProgress = void Function(double fraction, String stage);

/// FlutterFlow-facing action (unchanged signature). Delegates to
/// [saveAnalyzedVideoWithProgress] without a progress listener.
Future<bool> saveAnalyzedVideoToGallery(
  dynamic analysisResult,
) async {
  return saveAnalyzedVideoWithProgress(analysisResult, null);
}

/// Saves the analyzed exercise video WITH overlays burned into the pixels.
/// Visual styling is matched 1:1 to the live SquatAnalyzedVideoPlayer widget.
///
/// Input: the raw analyzer result map, or the workout-page set object that
/// wraps it under `analysis` (same shapes the player widget accepts).
///
/// Pipeline (fast path):
///   1) ffmpeg extracts frames at analyzed fps, capped at 720p.
///   2) Each frame is decoded, drawn to a Canvas with the overlays, and
///      exported as RAW RGBA (no PNG compression - that was the bottleneck)
///      appended to ONE .rgba file.
///   3) ffmpeg reads the raw stream (-f rawvideo) and encodes h264,
///      remuxing the original audio if present.
///   4) gal saves the mp4 to the gallery. Temp files cleaned in `finally`.
///
/// Returns true on success; false otherwise (reason via debugPrint).
Future<bool> saveAnalyzedVideoWithProgress(
  dynamic analysisResult,
  SaveVideoProgress? onProgress,
) async {
  void report(double f, String stage) {
    try {
      onProgress?.call(f.clamp(0.0, 1.0), stage);
    } catch (_) {}
  }

  // ---------- 0. Unwrap ----------
  if (analysisResult == null || analysisResult is! Map) {
    debugPrint('[saveAnalyzedVideo] analysisResult is null or not a Map');
    return false;
  }
  final Map result = _unwrapResult(analysisResult as Map);

  final String? rawUri = (result['_source_video_uri'] as String?) ??
      (result['video_path'] as String?);
  if (rawUri == null || rawUri.isEmpty) {
    debugPrint('[saveAnalyzedVideo] missing _source_video_uri / video_path');
    return false;
  }

  final List<dynamic>? frameTelemetry =
      result['_frame_telemetry'] as List<dynamic>?;
  if (frameTelemetry == null || frameTelemetry.isEmpty) {
    debugPrint('[saveAnalyzedVideo] missing or empty _frame_telemetry');
    return false;
  }

  final double fps =
      ((result['analyzed_fps'] as num?)?.toDouble() ?? 12.0).clamp(2.0, 30.0);

  String cleanPath = rawUri.trim();
  if (cleanPath.startsWith('file://')) {
    cleanPath = cleanPath.substring('file://'.length);
  }
  if (!await File(cleanPath).exists()) {
    debugPrint('[saveAnalyzedVideo] file missing: $cleanPath');
    return false;
  }

  final List<_FrameTelemetry> frames = frameTelemetry
      .where((e) => e is Map)
      .map((e) => _FrameTelemetry.fromMap(e as Map))
      .toList();
  if (frames.isEmpty) {
    debugPrint('[saveAnalyzedVideo] no valid telemetry frames');
    return false;
  }

  // ---------- Temp paths ----------
  final Directory tmp = await getTemporaryDirectory();
  final String sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  final Directory framesIn =
      Directory(p.join(tmp.path, 'overlay_in_$sessionId'));
  final String rawPath = p.join(tmp.path, 'overlay_$sessionId.rgba');
  final String outVideoPath = p.join(tmp.path, 'overlay_out_$sessionId.mp4');

  RandomAccessFile? rawSink;

  try {
    framesIn.createSync(recursive: true);
    report(0.02, 'extract');

    // ---------- 1. Extract frames (capped to 720p, even dims) ----------
    final String inPattern = p.join(framesIn.path, 'f_%05d.jpg');
    final String extractCmd =
        "-y -i \"$cleanPath\" -vf \"fps=$fps,scale='min(720,iw)':-2\" "
        "-q:v 2 \"$inPattern\"";
    final extractSession = await FFmpegKit.execute(extractCmd);
    if (!ReturnCode.isSuccess(await extractSession.getReturnCode())) {
      debugPrint('[saveAnalyzedVideo] ffmpeg extract failed');
      return false;
    }

    final List<File> inFiles = framesIn
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.jpg'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    if (inFiles.isEmpty) {
      debugPrint('[saveAnalyzedVideo] no frames extracted');
      return false;
    }
    report(0.10, 'render');

    // ---------- 2. Render frames -> one raw RGBA stream ----------
    final int n = math.min(inFiles.length, frames.length);
    int outW = 0, outH = 0;
    Uint8List? lastGood;
    rawSink = await File(rawPath).open(mode: FileMode.write);

    for (int i = 0; i < n; i++) {
      final Color skeletonColor = _computeSkeletonColorAt(frames, i);
      final _RawFrame? rf = await _renderFrameRaw(
        inputFramePath: inFiles[i].path,
        frame: frames[i],
        skeletonColor: skeletonColor,
      );

      if (rf != null) {
        if (outW == 0) {
          outW = rf.width;
          outH = rf.height;
        }
        // Guard against a stray frame with different dims (would corrupt
        // the raw stream) - reuse the last good frame instead.
        if (rf.width == outW && rf.height == outH) {
          lastGood = rf.bytes;
        }
      }
      if (lastGood == null) continue; // nothing rendered yet - skip
      await rawSink.writeFrom(lastGood);

      // Free the JPEG as we go - keeps temp footprint small.
      try {
        inFiles[i].deleteSync();
      } catch (_) {}

      if (i % 3 == 0 || i == n - 1) {
        report(0.10 + 0.75 * ((i + 1) / n), 'render');
      }
    }
    await rawSink.close();
    rawSink = null;

    if (outW == 0 || outH == 0) {
      debugPrint('[saveAnalyzedVideo] no frames rendered');
      return false;
    }
    report(0.86, 'encode');

    // ---------- 3. Encode raw RGBA -> h264 mp4, remux audio ----------
    final String encodeCmd = '-y '
        '-f rawvideo -pix_fmt rgba -s ${outW}x$outH -r $fps -i "$rawPath" '
        '-i "$cleanPath" '
        '-c:v libx264 -pix_fmt yuv420p -preset veryfast -crf 23 '
        '-c:a aac -b:a 128k '
        '-map 0:v:0 -map 1:a:0? -shortest '
        '"$outVideoPath"';
    final encodeSession = await FFmpegKit.execute(encodeCmd);
    if (!ReturnCode.isSuccess(await encodeSession.getReturnCode())) {
      debugPrint('[saveAnalyzedVideo] ffmpeg encode failed');
      return false;
    }
    if (!await File(outVideoPath).exists()) {
      debugPrint('[saveAnalyzedVideo] output mp4 missing');
      return false;
    }
    report(0.95, 'save');

    // ---------- 4. Save to gallery ----------
    try {
      final bool hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final bool granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          debugPrint('[saveAnalyzedVideo] gallery access denied');
          return false;
        }
      }
      await Gal.putVideo(outVideoPath, album: 'Xlift');
      report(1.0, 'done');
      debugPrint('[saveAnalyzedVideo] saved ok ${outW}x$outH @${fps}fps');
      return true;
    } on GalException catch (e) {
      debugPrint('[saveAnalyzedVideo] GalException: ${e.type} – $e');
      return false;
    }
  } catch (e, st) {
    debugPrint('[saveAnalyzedVideo] unexpected: $e\n$st');
    return false;
  } finally {
    try {
      await rawSink?.close();
    } catch (_) {}
    try {
      if (framesIn.existsSync()) framesIn.deleteSync(recursive: true);
    } catch (_) {}
    try {
      final f = File(rawPath);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
    try {
      final f = File(outVideoPath);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }
}

// ============================================================================
// UNWRAP INPUT — accepts either shape, exactly like the widget.
// ============================================================================
Map _unwrapResult(Map raw) {
  if (raw.containsKey('_source_video_uri') ||
      raw.containsKey('_frame_telemetry')) {
    return raw;
  }
  final inner = raw['analysis'];
  if (inner is Map &&
      (inner.containsKey('_source_video_uri') ||
          inner.containsKey('_frame_telemetry'))) {
    return inner;
  }
  return raw;
}

// ============================================================================
// FRAME TELEMETRY — mirrors the widget's _FrameData.
// ============================================================================
class _FrameTelemetry {
  final double t;
  final int reps;
  final double metricValue;
  final String metricLabel;
  final String? feedback;
  final String? repJustFinished;
  final List<List<double>> landmarks;
  final double flashDurationSec;
  final bool poseReliable;

  _FrameTelemetry({
    required this.t,
    required this.reps,
    required this.metricValue,
    required this.metricLabel,
    required this.feedback,
    required this.repJustFinished,
    required this.landmarks,
    required this.flashDurationSec,
    required this.poseReliable,
  });

  factory _FrameTelemetry.fromMap(Map m) {
    final List<dynamic> lmRaw = (m['landmarks'] as List?) ?? const <dynamic>[];
    final List<List<double>> lm = lmRaw.map<List<double>>((e) {
      if (e is! List) return [0.0, 0.0, 0.0];
      return [
        (e.isNotEmpty ? (e[0] as num).toDouble() : 0.0),
        (e.length > 1 ? (e[1] as num).toDouble() : 0.0),
        (e.length > 2 ? (e[2] as num).toDouble() : 0.0),
      ];
    }).toList();

    final double mv = (m['metric_value'] as num?)?.toDouble() ??
        (m['depth'] as num?)?.toDouble() ??
        0.0;

    return _FrameTelemetry(
      t: (m['t'] as num?)?.toDouble() ?? 0.0,
      reps: (m['reps'] as num?)?.toInt() ?? 0,
      metricValue: mv,
      metricLabel: (m['metric_label'] as String?) ?? 'DEPTH',
      feedback: m['feedback'] as String?,
      repJustFinished: m['rep_just_finished'] as String?,
      landmarks: lm,
      flashDurationSec: (m['flash_duration_sec'] as num?)?.toDouble() ?? 0.0,
      poseReliable: (m['pose_reliable'] as bool?) ?? true,
    );
  }
}

class _RawFrame {
  final int width;
  final int height;
  final Uint8List bytes;
  _RawFrame(this.width, this.height, this.bytes);
}

// ============================================================================
// SKELETON CONSTANTS — copied verbatim from _SquatOverlayPainter.
// ============================================================================
const int _L_SHOULDER = 11;
const int _R_SHOULDER = 12;
const int _L_ELBOW = 13;
const int _R_ELBOW = 14;
const int _L_WRIST = 15;
const int _R_WRIST = 16;
const int _L_HIP = 23;
const int _R_HIP = 24;
const int _L_KNEE = 25;
const int _R_KNEE = 26;
const int _L_ANKLE = 27;
const int _R_ANKLE = 28;
const int _L_HEEL = 29;
const int _R_HEEL = 30;
const int _L_FOOT = 31;
const int _R_FOOT = 32;

const List<List<int>> _SKELETON_CONNECTIONS = [
  [_L_SHOULDER, _R_SHOULDER],
  [_L_SHOULDER, _L_HIP],
  [_R_SHOULDER, _R_HIP],
  [_L_HIP, _R_HIP],
  [_L_SHOULDER, _L_ELBOW],
  [_L_ELBOW, _L_WRIST],
  [_R_SHOULDER, _R_ELBOW],
  [_R_ELBOW, _R_WRIST],
  [_L_HIP, _L_KNEE],
  [_L_KNEE, _L_ANKLE],
  [_L_ANKLE, _L_HEEL],
  [_L_HEEL, _L_FOOT],
  [_L_ANKLE, _L_FOOT],
  [_R_HIP, _R_KNEE],
  [_R_KNEE, _R_ANKLE],
  [_R_ANKLE, _R_HEEL],
  [_R_HEEL, _R_FOOT],
  [_R_ANKLE, _R_FOOT],
];

const List<int> _SKELETON_DOT_INDICES = [
  _L_SHOULDER,
  _R_SHOULDER,
  _L_ELBOW,
  _R_ELBOW,
  _L_WRIST,
  _R_WRIST,
  _L_HIP,
  _R_HIP,
  _L_KNEE,
  _R_KNEE,
  _L_ANKLE,
  _R_ANKLE,
  _L_HEEL,
  _R_HEEL,
  _L_FOOT,
  _R_FOOT,
];

const double _DRAW_VIS_THRESHOLD = 0.5;

const Color _FLASH_GOOD = Color.fromARGB(255, 40, 220, 90);
const Color _FLASH_BAD = Color.fromARGB(255, 255, 150, 30);

const double _FLASH_FALLBACK_MAX_SEC = 0.35;
const double _FLASH_FALLBACK_MIN_SEC = 0.10;
const double _FLASH_FALLBACK_GAP_FRACTION = 0.40;

// ============================================================================
// FLASH COLOR
// ============================================================================
Color _computeSkeletonColorAt(List<_FrameTelemetry> frames, int frameIdx) {
  if (frameIdx < 0 || frameIdx >= frames.length) return Colors.white;
  final double currentT = frames[frameIdx].t;

  for (int i = frameIdx; i >= 0 && i >= frameIdx - 50; i--) {
    final f = frames[i];
    if (f.repJustFinished == null) continue;

    double duration = f.flashDurationSec;
    if (duration <= 0) {
      double nextPulseT = double.infinity;
      for (int j = i + 1; j < frames.length; j++) {
        if (frames[j].repJustFinished != null) {
          nextPulseT = frames[j].t;
          break;
        }
      }
      final double gap = nextPulseT - f.t;
      if (gap.isInfinite) {
        duration = _FLASH_FALLBACK_MAX_SEC;
      } else {
        duration = (gap * _FLASH_FALLBACK_GAP_FRACTION)
            .clamp(_FLASH_FALLBACK_MIN_SEC, _FLASH_FALLBACK_MAX_SEC);
      }
    }

    final double age = currentT - f.t;
    if (age >= 0 && age <= duration) {
      return f.repJustFinished == 'good' ? _FLASH_GOOD : _FLASH_BAD;
    }
    return Colors.white;
  }
  return Colors.white;
}

// ============================================================================
// PER-FRAME RENDERER — returns RAW RGBA (no PNG compression).
// ============================================================================
Future<_RawFrame?> _renderFrameRaw({
  required String inputFramePath,
  required _FrameTelemetry frame,
  required Color skeletonColor,
}) async {
  ui.Image? image;
  ui.Image? rendered;
  try {
    final Uint8List bytes = await File(inputFramePath).readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo finfo = await codec.getNextFrame();
    image = finfo.image;
    final int w = image.width;
    final int h = image.height;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    );

    canvas.drawImage(image, Offset.zero, Paint());
    _paintSkeleton(canvas, w.toDouble(), h.toDouble(), frame, skeletonColor);
    _paintRepsBadge(canvas, w.toDouble(), h.toDouble(), frame);
    _paintDepthRing(canvas, w.toDouble(), h.toDouble(), frame);
    _paintFeedbackBubble(canvas, w.toDouble(), h.toDouble(), frame);

    final ui.Picture picture = recorder.endRecording();
    rendered = await picture.toImage(w, h);
    picture.dispose();

    final ByteData? byteData =
        await rendered.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return null;
    return _RawFrame(w, h, byteData.buffer.asUint8List());
  } catch (e) {
    debugPrint('[_renderFrameRaw] error: $e');
    return null;
  } finally {
    image?.dispose();
    rendered?.dispose();
  }
}

// ----------------------------------------------------------------------------
// SKELETON
// ----------------------------------------------------------------------------
void _paintSkeleton(
    Canvas canvas, double w, double h, _FrameTelemetry frame, Color color) {
  if (!frame.poseReliable) return;
  if (frame.landmarks.length < 33) return;

  final List<List<double>> lms = frame.landmarks;

  final Paint linePaint = Paint()
    ..color = color
    ..strokeWidth = math.max(2.0, h * 0.004)
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final Paint dotPaint = Paint()
    ..color = color
    ..style = PaintingStyle.fill;
  final double dotR = math.max(3.0, h * 0.006);

  Offset? pt(int idx) {
    if (idx < 0 || idx >= lms.length) return null;
    final lm = lms[idx];
    if (lm.length < 3) return null;
    if (lm[2] < _DRAW_VIS_THRESHOLD) return null;
    return Offset(lm[0] * w, lm[1] * h);
  }

  for (final conn in _SKELETON_CONNECTIONS) {
    final Offset? a = pt(conn[0]);
    final Offset? b = pt(conn[1]);
    if (a != null && b != null) canvas.drawLine(a, b, linePaint);
  }
  for (final i in _SKELETON_DOT_INDICES) {
    final Offset? c = pt(i);
    if (c != null) canvas.drawCircle(c, dotR, dotPaint);
  }
}

// ----------------------------------------------------------------------------
// REPS BADGE
// ----------------------------------------------------------------------------
void _paintRepsBadge(Canvas canvas, double w, double h, _FrameTelemetry frame) {
  final double repsFontSize = math.max(14.0, h * 0.055);
  final ui.Paragraph para = _layoutText(
    'Reps: ${frame.reps}',
    fontSize: repsFontSize,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    maxWidth: w,
  );
  final double boxW = para.longestLine + 20;
  final double boxH = para.height + 12;
  final Paint bg = Paint()..color = Colors.black.withOpacity(0.55);
  canvas.drawRect(Rect.fromLTWH(0, 0, boxW, boxH), bg);
  canvas.drawParagraph(para, const Offset(10, 6));
}

// ----------------------------------------------------------------------------
// DEPTH RING
// ----------------------------------------------------------------------------
void _paintDepthRing(Canvas canvas, double w, double h, _FrameTelemetry frame) {
  final double repsFontSize = math.max(14.0, h * 0.055);
  final double refH = math.max(h * 0.07, repsFontSize * 1.7);
  final double radius = refH * 0.78;
  final double thick = math.max(3.0, radius * 0.25);
  final double cx = w - 12 - radius;
  final double cy = math.max(refH + radius / 8, radius + thick / 2 + 2);

  final Paint ringBgPaint = Paint()
    ..color = const Color.fromARGB(255, 70, 70, 70)
    ..strokeWidth = thick
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.butt;
  canvas.drawCircle(Offset(cx, cy), radius, ringBgPaint);

  final double pct = frame.metricValue.clamp(0.0, 1.0);
  if (pct > 0) {
    final Paint ringFgPaint = Paint()
      ..color = const Color.fromARGB(255, 40, 200, 80)
      ..strokeWidth = thick
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -math.pi / 2,
      2 * math.pi * pct,
      false,
      ringFgPaint,
    );
  }

  final double labelFontSize = math.max(9.0, h * 0.024);
  final double pctFontSize = math.max(11.0, h * 0.032);
  double labelSize = labelFontSize;
  double pctSize = pctFontSize;

  final double maxInnerW = (radius * 2.0) * 0.80;
  final double maxInnerH = (radius * 2.0) * 0.80;
  final int pctInt = (pct * 100).round();

  ui.Paragraph probe = _layoutText(
    '$pctInt%',
    fontSize: pctSize,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    maxWidth: maxInnerW,
  );
  int safety = 0;
  while (probe.longestLine > maxInnerW && pctSize > 8.0 && safety < 6) {
    final double scale = (maxInnerW / probe.longestLine).clamp(0.5, 1.0);
    pctSize = (pctSize * scale).clamp(8.0, pctFontSize);
    labelSize = (labelSize * scale).clamp(7.0, labelFontSize);
    probe = _layoutText(
      '$pctInt%',
      fontSize: pctSize,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      maxWidth: maxInnerW,
    );
    safety += 1;
  }

  ui.Paragraph labelTp = _layoutText(
    frame.metricLabel,
    fontSize: labelSize,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    maxWidth: maxInnerW,
  );
  ui.Paragraph pctTp = _layoutText(
    '$pctInt%',
    fontSize: pctSize,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    maxWidth: maxInnerW,
  );

  final double gap = math.max(2.0, radius * 0.10);
  if (labelTp.height + gap + pctTp.height > maxInnerH) {
    final double scale =
        maxInnerH / (labelTp.height + gap + pctTp.height) * 0.95;
    labelSize *= scale;
    pctSize *= scale;
    labelTp = _layoutText(
      frame.metricLabel,
      fontSize: labelSize,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      maxWidth: maxInnerW,
    );
    pctTp = _layoutText(
      '$pctInt%',
      fontSize: pctSize,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      maxWidth: maxInnerW,
    );
  }

  final double totalTextH = labelTp.height + gap + pctTp.height;
  final double labelY = cy - totalTextH / 2;
  canvas.drawParagraph(
    labelTp,
    Offset(cx - labelTp.longestLine / 2, labelY),
  );
  canvas.drawParagraph(
    pctTp,
    Offset(cx - pctTp.longestLine / 2, labelY + labelTp.height + gap),
  );
}

// ----------------------------------------------------------------------------
// FEEDBACK BUBBLE
// ----------------------------------------------------------------------------
void _paintFeedbackBubble(
    Canvas canvas, double w, double h, _FrameTelemetry frame) {
  final String? fb = frame.feedback;
  if (fb == null || fb.isEmpty) return;

  final List<String> fbLines =
      fb.split('\n').where((s) => s.trim().isNotEmpty).toList();
  if (fbLines.isEmpty) return;

  final double fbFontSize = math.max(12.0, h * 0.038);
  const double padX = 12;
  const double padY = 8;
  final double lineGap = math.max(2.0, h * 0.005);
  final double safe = math.max(6.0, h * 0.02);
  final double maxLineW = w - 2 * padX - 20;

  final List<ui.Paragraph> linePainters = fbLines.map((line) {
    return _layoutText(
      line,
      fontSize: fbFontSize,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      textAlign: TextAlign.center,
      maxWidth: maxLineW,
      maxLines: 2,
    );
  }).toList();

  double totalH = 2 * padY;
  for (int i = 0; i < linePainters.length; i++) {
    totalH += linePainters[i].height;
    if (i < linePainters.length - 1) totalH += lineGap;
  }
  final double fbY0 = math.max(0.0, h - safe - totalH);

  final Paint fbBoxBg = Paint()..color = Colors.black.withOpacity(0.55);
  canvas.drawRect(Rect.fromLTWH(0, fbY0, w, totalH), fbBoxBg);

  double y = fbY0 + padY;
  for (final tp in linePainters) {
    canvas.drawParagraph(tp, Offset((w - tp.longestLine) / 2, y));
    y += tp.height + lineGap;
  }
}

// ----------------------------------------------------------------------------
// TEXT HELPER
// ----------------------------------------------------------------------------
ui.Paragraph _layoutText(
  String text, {
  required double fontSize,
  required FontWeight fontWeight,
  required Color color,
  TextAlign textAlign = TextAlign.left,
  double maxWidth = 4096,
  int maxLines = 1,
}) {
  final ui.ParagraphStyle pStyle = ui.ParagraphStyle(
    textAlign: textAlign,
    fontSize: fontSize,
    fontWeight: fontWeight,
    maxLines: maxLines,
    ellipsis: maxLines > 1 ? '…' : null,
  );
  final ui.TextStyle tStyle = ui.TextStyle(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
  );
  final ui.ParagraphBuilder pb = ui.ParagraphBuilder(pStyle)
    ..pushStyle(tStyle)
    ..addText(text);
  return pb.build()..layout(ui.ParagraphConstraints(width: maxWidth));
}
