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
/// Visual styling matches AnalyzedVideoPlayerV2 (minus playback controls):
/// REP n/total box top-left, metric ring top-right, skeleton with lockout
/// flash glow, and GOOD REP / NEEDS WORK pill + feedback shown for the whole
/// span of each rep segment.
///
/// Input: the raw analyzer result map, or the workout-page set object that
/// wraps it under `analysis` (same shapes the player widget accepts).
///
/// Pipeline:
///   1) ffmpeg extracts frames at analyzed fps, capped at 720p.
///   2) Each frame is drawn to a Canvas with the overlays and appended as
///      RAW RGBA to ONE .rgba file.
///   3) ffmpeg encodes h264, remuxing the original audio if present.
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

  // Rep segments + total, same logic as the V2 player.
  final List<_RepSegment> segments = _buildSegments(result, frames);
  final int lockouts = segments.where((s) => s.index > 0).length;
  final List<dynamic> repsList = (result['reps'] as List?) ?? const [];
  final int totalReps =
      [lockouts, repsList.length, frames.last.reps].reduce(math.max);

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
      final _RawFrame? rf = await _renderFrameRaw(
        inputFramePath: inFiles[i].path,
        frame: frames[i],
        totalReps: totalReps,
        flash: _flashAt(frames, i),
        seg: _segmentAt(segments, frames[i].t),
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
// FRAME TELEMETRY
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
// REP SEGMENTS — same logic as the V2 player.
// Segment i runs from the previous lockout to this rep's lockout. After the
// last lockout comes a "tail" segment (index 0, good == null): no pill.
// ============================================================================
class _RepSegment {
  final double startT;
  final double endT;
  final bool? good;
  final int index; // 1-based rep number; 0 = tail
  final String? feedback;
  const _RepSegment(this.startT, this.endT, this.good, this.index,
      [this.feedback]);
}

String? _feedbackStr(dynamic f) {
  if (f == null) return null;
  if (f is List) {
    final parts =
        f.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join('\n');
  }
  final s = f.toString().trim();
  return s.isEmpty ? null : s;
}

List<_RepSegment> _buildSegments(Map result, List<_FrameTelemetry> frames) {
  final List<int> lockoutIdx = [];
  for (int i = 0; i < frames.length; i++) {
    if (frames[i].repJustFinished != null) lockoutIdx.add(i);
  }
  final List<dynamic> repsList = (result['reps'] as List?) ?? const [];
  final bool useReps = repsList.length == lockoutIdx.length;

  final segs = <_RepSegment>[];
  double prev = 0.0;
  for (int i = 0; i < lockoutIdx.length; i++) {
    final f = frames[lockoutIdx[i]];
    bool good = f.repJustFinished == 'good';
    String? fb;
    if (useReps && repsList[i] is Map) {
      final m = repsList[i] as Map;
      final g = m['good'];
      if (g is bool) good = g;
      fb = _feedbackStr(m['feedback']) ?? _feedbackStr(m['f']);
    }
    fb ??= _feedbackStr(f.feedback);
    segs.add(_RepSegment(prev, f.t, good, i + 1, fb));
    prev = f.t;
  }
  final double end = frames.isNotEmpty ? frames.last.t : prev;
  if (end > prev + 0.05) segs.add(_RepSegment(prev, end + 1.0, null, 0));
  return segs;
}

_RepSegment? _segmentAt(List<_RepSegment> segments, double t) {
  for (final s in segments) {
    if (t >= s.startT && t < s.endT) return s;
  }
  if (segments.isNotEmpty && t >= segments.last.startT) return segments.last;
  return null;
}

// ============================================================================
// SKELETON CONSTANTS + COLORS
// ============================================================================
const List<List<int>> _SKELETON_CONNECTIONS = [
  [11, 12],
  [11, 23],
  [12, 24],
  [23, 24],
  [11, 13],
  [13, 15],
  [12, 14],
  [14, 16],
  [23, 25],
  [25, 27],
  [27, 29],
  [29, 31],
  [27, 31],
  [24, 26],
  [26, 28],
  [28, 30],
  [30, 32],
  [28, 32],
];

const List<int> _SKELETON_DOT_INDICES = [
  11,
  12,
  13,
  14,
  15,
  16,
  23,
  24,
  25,
  26,
  27,
  28,
  29,
  30,
  31,
  32
];

const double _DRAW_VIS_THRESHOLD = 0.5;

const Color _GOOD = Color(0xFF28DC5A);
const Color _BAD = Color(0xFFFF9A1E);

const double _FLASH_FALLBACK_MAX_SEC = 0.35;
const double _FLASH_FALLBACK_MIN_SEC = 0.10;
const double _FLASH_FALLBACK_GAP_FRACTION = 0.40;

// ============================================================================
// FLASH — lockout glow; intensity fades 1 → 0 over the flash duration.
// ============================================================================
class _Flash {
  final Color color;
  final double intensity;
  final bool good;
  const _Flash(this.color, this.intensity, this.good);
}

_Flash? _flashAt(List<_FrameTelemetry> frames, int frameIdx) {
  if (frameIdx < 0 || frameIdx >= frames.length) return null;
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
      duration = gap.isInfinite
          ? _FLASH_FALLBACK_MAX_SEC
          : (gap * _FLASH_FALLBACK_GAP_FRACTION)
              .clamp(_FLASH_FALLBACK_MIN_SEC, _FLASH_FALLBACK_MAX_SEC);
    }

    final double age = currentT - f.t;
    if (age >= 0 && age <= duration) {
      final bool good = f.repJustFinished == 'good';
      final double intensity = (1.0 - age / duration).clamp(0.0, 1.0);
      return _Flash(good ? _GOOD : _BAD, intensity, good);
    }
    return null;
  }
  return null;
}

// ============================================================================
// PER-FRAME RENDERER — returns RAW RGBA (no PNG compression).
// ============================================================================
Future<_RawFrame?> _renderFrameRaw({
  required String inputFramePath,
  required _FrameTelemetry frame,
  required int totalReps,
  required _Flash? flash,
  required _RepSegment? seg,
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
    _paintOverlayV2(
        canvas, w.toDouble(), h.toDouble(), frame, totalReps, flash, seg);

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

// ============================================================================
// V2 OVERLAY (mirrors the player's painter, no playback controls)
// ============================================================================
void _paintOverlayV2(Canvas canvas, double w, double h, _FrameTelemetry frame,
    int totalReps, _Flash? flash, _RepSegment? seg) {
  final double pad = math.max(10.0, w * 0.035);
  final double flashI = (flash?.intensity ?? 0.0).clamp(0.0, 1.0);

  // --- skeleton (white, tinted + glow during lockout flash) ---
  final Color skel = flash == null
      ? Colors.white
      : Color.lerp(Colors.white, flash.color, flashI)!;
  if (frame.poseReliable && frame.landmarks.length >= 33) {
    final lms = frame.landmarks;
    final line = Paint()
      ..color = skel
      ..strokeWidth = math.max(2.0, h * 0.004)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final glow = Paint()
      ..color = skel.withOpacity(0.35)
      ..strokeWidth = math.max(5.0, h * 0.010)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = skel;
    final double r = math.max(3.0, h * 0.006);
    Offset? pt(int i) {
      if (i >= lms.length) return null;
      final l = lms[i];
      if (l.length < 3 || l[2] < _DRAW_VIS_THRESHOLD) return null;
      return Offset(l[0] * w, l[1] * h);
    }

    for (final c in _SKELETON_CONNECTIONS) {
      final a = pt(c[0]), b = pt(c[1]);
      if (a != null && b != null) {
        if (flashI > 0) canvas.drawLine(a, b, glow);
        canvas.drawLine(a, b, line);
      }
    }
    for (final i in _SKELETON_DOT_INDICES) {
      final p0 = pt(i);
      if (p0 != null) canvas.drawCircle(p0, r, dot);
    }
  }

  // --- REP counter (top-left): "REP" over "n / total" ---
  final double labelSize = math.max(9.0, h * 0.022);
  final double numSize = math.max(22.0, h * 0.075);
  final double totalSize = math.max(12.0, h * 0.032);
  final ui.Paragraph label = _layoutText('REP',
      fontSize: labelSize,
      fontWeight: FontWeight.w700,
      color: Colors.white.withOpacity(0.85),
      letterSpacing: 1.5);
  final ui.Paragraph numP = _layoutText('${frame.reps}',
      fontSize: numSize, fontWeight: FontWeight.w800, color: Colors.white);
  final ui.Paragraph tot = _layoutText(totalReps > 0 ? ' / $totalReps' : '',
      fontSize: totalSize,
      fontWeight: FontWeight.w600,
      color: Colors.white.withOpacity(0.75));
  final double boxW =
      math.max(label.longestLine, numP.longestLine + tot.longestLine) +
          pad * 1.6;
  final double boxH = label.height + 4 + numP.height + pad * 1.2;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(pad, pad, boxW, boxH), const Radius.circular(12)),
    Paint()..color = Colors.black.withOpacity(0.45),
  );
  canvas.drawParagraph(label, Offset(pad + pad * 0.8, pad + pad * 0.6));
  final double numY = pad + pad * 0.6 + label.height + 4;
  canvas.drawParagraph(numP, Offset(pad + pad * 0.8, numY));
  canvas.drawParagraph(
    tot,
    Offset(pad + pad * 0.8 + numP.longestLine,
        numY + numP.height - tot.height - 2),
  );

  // --- metric ring (top-right) ---
  final double radius = math.max(22.0, h * 0.055);
  final double thick = math.max(3.5, radius * 0.18);
  final double cx = w - pad - radius - thick;
  final double cy = pad + radius + thick;
  canvas.drawCircle(Offset(cx, cy), radius + thick,
      Paint()..color = Colors.black.withOpacity(0.35));
  canvas.drawCircle(
    Offset(cx, cy),
    radius,
    Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = thick
      ..style = PaintingStyle.stroke,
  );
  final double pct = frame.metricValue.clamp(0.0, 1.0);
  if (pct > 0) {
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -math.pi / 2,
      2 * math.pi * pct,
      false,
      Paint()
        ..color = _GOOD
        ..strokeWidth = thick
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }
  final ui.Paragraph rl = _layoutText(frame.metricLabel,
      fontSize: math.max(7.5, radius * 0.26),
      fontWeight: FontWeight.w700,
      color: Colors.white.withOpacity(0.85),
      letterSpacing: 0.8);
  final ui.Paragraph rp = _layoutText('${(pct * 100).round()}%',
      fontSize: math.max(11.0, radius * 0.42),
      fontWeight: FontWeight.w800,
      color: Colors.white);
  final double th = rl.height + 2 + rp.height;
  canvas.drawParagraph(rl, Offset(cx - rl.longestLine / 2, cy - th / 2));
  canvas.drawParagraph(
      rp, Offset(cx - rp.longestLine / 2, cy - th / 2 + rl.height + 2));

  // --- bottom: verdict pill + feefdback, for the whole rep segment ---
  // In a rep segment: pill always, feedback if the rep has any.
  // In the tail (no verdict): no pill, frame feedbac;k if any.
  final bool? segGood = seg?.good;
  final bool showPill = segGood != null;
  final String fb =
      ((segGood != null ? seg?.feedback : frame.feedback) ?? '').trim();
  final bool hasFb = fb.isNotEmpty;
  if (!showPill && !hasFb) return;

  final double bottomSafe = math.max(16.0, h * 0.05); // no controls in file
  double y = h - bottomSafe;

  if (hasFb) {
    final double fbSize = math.max(12.0, h * 0.028);
    final ui.Paragraph fbTp = _layoutText(fb,
        fontSize: fbSize,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        maxWidth: w - pad * 2,
        maxLines: 3);
    final ui.Paragraph shadow = _layoutText(fb,
        fontSize: fbSize,
        fontWeight: FontWeight.w700,
        color: Colors.black.withOpacity(0.6),
        maxWidth: w - pad * 2,
        maxLines: 3);
    y -= fbTp.height;
    canvas.drawParagraph(shadow, Offset(pad + 1, y + 1));
    canvas.drawParagraph(fbTp, Offset(pad, y));
    y -= 8;
  }

  if (showPill) {
    final bool g = segGood;
    final ui.Paragraph pillTp = _layoutText(g ? 'GOOD REP' : 'NEEDS WORK',
        fontSize: math.max(10.0, h * 0.024),
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 1.0);
    final double pw = pillTp.longestLine + 20;
    final double ph = pillTp.height + 10;
    y -= ph;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(pad, y, pw, ph), Radius.circular(ph / 2)),
      Paint()..color = (g ? _GOOD : _BAD).withOpacity(0.78 + 0.22 * flashI),
    );
    canvas.drawParagraph(pillTp, Offset(pad + 10, y + 5));
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
  double letterSpacing = 0,
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
    letterSpacing: letterSpacing,
  );
  final ui.ParagraphBuilder pb = ui.ParagraphBuilder(pStyle)
    ..pushStyle(tStyle)
    ..addText(text);
  return pb.build()..layout(ui.ParagraphConstraints(width: maxWidth));
}
