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
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:flutter_litert/flutter_litert.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:xlift_models/xlift_models.dart';

/// DIAGNOSTIC test action for the YOLOv8 barbell detector.
///
/// Runs the model on every frame of a video and returns rich debug info:
/// per-frame top-5 predictions (not just the max), confidence histogram,
/// and how detections distribute over the video.
///
/// Use this to answer questions like:
///   - "Is the model finding the barbell but below threshold?" → look at top-5
///   - "Is there a confidence cliff at some value?" → look at the histogram
///   - "Which frames are best/worst?" → look at frames_by_confidence
///
/// Uses LETTERBOX preprocessing (matches Roboflow training preprocessing).
/// The previous version stretched frames to 320x320, which on portrait video
/// squashed everything vertically and made the detector latch onto plates
/// instead of bars.
Future<dynamic> testBarbellDetection(
  FFUploadedFile videoFile,
) async {
  // ============== Config ==============
  // Low threshold so we see EVERYTHING the model thinks is a barbell, even
  // marginal detections. Top-5 per frame is reported regardless of threshold.
  const double CONFIDENCE_THRESHOLD = 0.10;
  const int INPUT_SIZE = 320;
  const double SAMPLE_FPS = 5.0;
  const int TOP_K_PER_FRAME = 5; // how many top predictions to keep per frame

  // ============== 0) Validate upload ==============
  if (videoFile.bytes == null || videoFile.bytes!.isEmpty) {
    return {
      'success': false,
      'error': 'empty_upload',
      'debug_string': 'ERROR: no video bytes',
    };
  }

  // ============== 1) Save video to temp ==============
  final Directory tmp = await getTemporaryDirectory();
  final String sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  final String videoPath = p.join(tmp.path, 'barbell_test_$sessionId.mp4');
  try {
    await File(videoPath).writeAsBytes(videoFile.bytes!, flush: true);
  } catch (e) {
    return {
      'success': false,
      'error': 'write_failed',
      'detail': '$e',
      'debug_string': 'ERROR: write video failed',
    };
  }

  // ============== 2) Extract frames at ORIGINAL resolution ==============
  // Don't pre-resize — we want to letterbox in Dart for precise control.
  final Directory framesDir =
      Directory(p.join(tmp.path, 'barbell_test_frames_$sessionId'));
  if (framesDir.existsSync()) framesDir.deleteSync(recursive: true);
  framesDir.createSync(recursive: true);

  final String framePattern = p.join(framesDir.path, 'f_%04d.jpg');
  final String extractCmd =
      '-y -i "$videoPath" -vf "fps=$SAMPLE_FPS" -q:v 3 "$framePattern"';
  final extractSession = await FFmpegKit.execute(extractCmd);
  final extractRc = await extractSession.getReturnCode();
  if (!ReturnCode.isSuccess(extractRc)) {
    return {
      'success': false,
      'error': 'ffmpeg_failed',
      'debug_string': 'ERROR: ffmpeg frame extract failed',
    };
  }

  final List<File> frameFiles = framesDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.jpg'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (frameFiles.isEmpty) {
    return {
      'success': false,
      'error': 'no_frames',
      'debug_string': 'ERROR: no frames extracted',
    };
  }

  // ============== 3) Load model ==============
  Interpreter? interpreter;
  String modelLoadInfo = '';
  try {
    final Uint8List modelBytes = await XliftModels.loadBarbellModel();
    interpreter = Interpreter.fromBuffer(modelBytes);
    modelLoadInfo = 'loaded(${modelBytes.length}B)';
  } catch (e) {
    return {
      'success': false,
      'error': 'model_load_failed',
      'detail': '$e',
      'debug_string': 'ERROR: model load failed — $e',
    };
  }

  // ============== 4) Inspect tensors ==============
  final inputTensor = interpreter.getInputTensor(0);
  final outputTensor = interpreter.getOutputTensor(0);
  final List<int> inputShape = inputTensor.shape;
  final List<int> outputShape = outputTensor.shape;
  final String inputTypeStr = inputTensor.type.toString();
  final String outputTypeStr = outputTensor.type.toString();

  final double inputScale = inputTensor.params.scale;
  final int inputZeroPoint = inputTensor.params.zeroPoint;
  final double outputScale = outputTensor.params.scale;
  final int outputZeroPoint = outputTensor.params.zeroPoint;

  final bool isFloatInput = inputTypeStr.toLowerCase().contains('float');
  final bool isFloatOutput = outputTypeStr.toLowerCase().contains('float');

  final int numChannels = outputShape[1]; // expected 5
  final int numPredictions = outputShape[2]; // expected ~2100

  if (numChannels != 5) {
    interpreter.close();
    return {
      'success': false,
      'error': 'unexpected_output_shape',
      'output_shape': outputShape,
      'debug_string':
          'ERROR: expected 5 channels (x,y,w,h,conf), got $numChannels',
    };
  }

  // ============== 5) Process each frame ==============
  final List<Map<String, dynamic>> perFrameResults = [];
  int framesWithBarbell = 0; // frames where best confidence >= threshold
  int framesProcessed = 0;
  int firstFrameW = 0;
  int firstFrameH = 0;

  // Confidence histogram buckets, for a quick visual of where confidence sits.
  // Buckets: 0-0.1, 0.1-0.2, 0.2-0.3, ..., 0.9-1.0
  final List<int> confHistogram = List<int>.filled(10, 0);

  for (int frameIdx = 0; frameIdx < frameFiles.length; frameIdx++) {
    final frameFile = frameFiles[frameIdx];

    final Uint8List bytes;
    try {
      bytes = await frameFile.readAsBytes();
    } catch (_) {
      continue;
    }
    final image = img.decodeImage(bytes);
    if (image == null) continue;

    if (frameIdx == 0) {
      firstFrameW = image.width;
      firstFrameH = image.height;
    }

    // ===== LETTERBOX PREPROCESSING =====
    // Match the Roboflow "Resize Fit (black edges)" training preprocessing.
    final int origW = image.width;
    final int origH = image.height;
    final double scale = math.min(
      INPUT_SIZE / origW,
      INPUT_SIZE / origH,
    );
    final int scaledW = (origW * scale).round();
    final int scaledH = (origH * scale).round();
    final int padX = ((INPUT_SIZE - scaledW) / 2).floor();
    final int padY = ((INPUT_SIZE - scaledH) / 2).floor();

    final img.Image canvas = img.Image(
      width: INPUT_SIZE,
      height: INPUT_SIZE,
    );
    img.fill(canvas, color: img.ColorRgb8(0, 0, 0));
    final img.Image resized = img.copyResize(
      image,
      width: scaledW,
      height: scaledH,
    );
    img.compositeImage(
      canvas,
      resized,
      dstX: padX,
      dstY: padY,
    );

    // ----- Build input tensor -----
    dynamic inputBuffer;
    if (isFloatInput) {
      final flat = Float32List(1 * INPUT_SIZE * INPUT_SIZE * 3);
      int idx = 0;
      for (int y = 0; y < INPUT_SIZE; y++) {
        for (int x = 0; x < INPUT_SIZE; x++) {
          final pixel = canvas.getPixel(x, y);
          flat[idx++] = pixel.r / 255.0;
          flat[idx++] = pixel.g / 255.0;
          flat[idx++] = pixel.b / 255.0;
        }
      }
      inputBuffer = flat.reshape([1, INPUT_SIZE, INPUT_SIZE, 3]);
    } else {
      final flat = Uint8List(1 * INPUT_SIZE * INPUT_SIZE * 3);
      int idx = 0;
      for (int y = 0; y < INPUT_SIZE; y++) {
        for (int x = 0; x < INPUT_SIZE; x++) {
          final pixel = canvas.getPixel(x, y);
          flat[idx++] = pixel.r.toInt() & 0xFF;
          flat[idx++] = pixel.g.toInt() & 0xFF;
          flat[idx++] = pixel.b.toInt() & 0xFF;
        }
      }
      inputBuffer = flat.reshape([1, INPUT_SIZE, INPUT_SIZE, 3]);
    }

    // ----- Build output tensor -----
    dynamic outputBuffer;
    if (isFloatOutput) {
      outputBuffer = List.generate(
        1,
        (_) => List.generate(
          numChannels,
          (_) => List<double>.filled(numPredictions, 0.0),
        ),
      );
    } else {
      outputBuffer = List.generate(
        1,
        (_) => List.generate(
          numChannels,
          (_) => List<int>.filled(numPredictions, 0),
        ),
      );
    }

    // ----- Run inference -----
    try {
      interpreter.run(inputBuffer, outputBuffer);
    } catch (e) {
      perFrameResults.add({
        'frame': frameIdx,
        'error': 'inference_failed: $e',
      });
      continue;
    }
    framesProcessed++;

    double dq(num v) => isFloatOutput
        ? v.toDouble()
        : (v.toDouble() - outputZeroPoint) * outputScale;

    // ----- Collect ALL confidences and find top-K -----
    // We track indices of the K highest-confidence predictions.
    final List<_Pred> topK = [];
    for (int i = 0; i < numPredictions; i++) {
      final double conf = dq(outputBuffer[0][4][i]);
      if (topK.length < TOP_K_PER_FRAME) {
        topK.add(_Pred(i, conf));
        if (topK.length == TOP_K_PER_FRAME) {
          topK.sort((a, b) => a.conf.compareTo(b.conf));
        }
      } else if (conf > topK[0].conf) {
        topK[0] = _Pred(i, conf);
        // Re-bubble the minimum to position 0
        int j = 0;
        while (j + 1 < topK.length && topK[j + 1].conf < topK[j].conf) {
          final tmp = topK[j];
          topK[j] = topK[j + 1];
          topK[j + 1] = tmp;
          j++;
        }
      }
    }
    // topK currently sorted ascending; flip so [0] is highest.
    topK.sort((a, b) => b.conf.compareTo(a.conf));

    final double maxConf = topK.isNotEmpty ? topK[0].conf : 0.0;

    // Histogram bucket
    final int bucket = math.min(9, (maxConf * 10).floor());
    confHistogram[bucket]++;

    final bool hasBarbell = maxConf >= CONFIDENCE_THRESHOLD;
    if (hasBarbell) framesWithBarbell++;

    // ----- Decode top-K boxes (in letterbox space, then map to original) -----
    final List<Map<String, dynamic>> topKDecoded = [];
    for (final pred in topK) {
      final int j = pred.idx;
      final double xcLetter = dq(outputBuffer[0][0][j]);
      final double ycLetter = dq(outputBuffer[0][1][j]);
      final double wLetter = dq(outputBuffer[0][2][j]);
      final double hLetter = dq(outputBuffer[0][3][j]);

      // Map back to original-frame normalized coords
      final double xcPx = xcLetter * INPUT_SIZE;
      final double ycPx = ycLetter * INPUT_SIZE;
      final double wPx = wLetter * INPUT_SIZE;
      final double hPx = hLetter * INPUT_SIZE;

      final double xcOrig = scaledW > 0 ? (xcPx - padX) / scaledW : 0.0;
      final double ycOrig = scaledH > 0 ? (ycPx - padY) / scaledH : 0.0;
      final double wOrig = scaledW > 0 ? wPx / scaledW : 0.0;
      final double hOrig = scaledH > 0 ? hPx / scaledH : 0.0;

      topKDecoded.add({
        'conf': _rd(pred.conf, 3),
        'x_center': _rd(xcOrig.clamp(0.0, 1.0), 3),
        'y_center': _rd(ycOrig.clamp(0.0, 1.0), 3),
        'width': _rd(wOrig.clamp(0.0, 1.0), 3),
        'height': _rd(hOrig.clamp(0.0, 1.0), 3),
        // aspect ratio is a strong sanity check: a barbell should be very
        // wide and very thin (high aspect ratio). A square box (ar ~1.0)
        // suggests the model latched onto a plate.
        'aspect': hOrig > 0.001 ? _rd(wOrig / hOrig, 2) : 0.0,
      });
    }

    perFrameResults.add({
      'frame': frameIdx,
      't_sec': _rd(frameIdx / SAMPLE_FPS, 2),
      'maxConf': _rd(maxConf, 3),
      'hasBarbell': hasBarbell,
      'top_k': topKDecoded,
    });
  }

  // ============== 6) Cleanup ==============
  interpreter.close();
  try {
    framesDir.deleteSync(recursive: true);
  } catch (_) {}
  try {
    File(videoPath).deleteSync();
  } catch (_) {}

  // ============== 7) Build summary ==============
  final double rate =
      frameFiles.isEmpty ? 0.0 : framesWithBarbell / frameFiles.length;

  // High-conf at various thresholds — shows where to put the gate
  int conf10 = 0, conf20 = 0, conf30 = 0, conf50 = 0, conf70 = 0;
  double avgMaxConf = 0.0;
  double bestConfEver = 0.0;
  int bestConfFrame = -1;
  for (final r in perFrameResults) {
    final num? c = r['maxConf'] as num?;
    if (c == null) continue;
    final cd = c.toDouble();
    if (cd >= 0.10) conf10++;
    if (cd >= 0.20) conf20++;
    if (cd >= 0.30) conf30++;
    if (cd >= 0.50) conf50++;
    if (cd >= 0.70) conf70++;
    avgMaxConf += cd;
    if (cd > bestConfEver) {
      bestConfEver = cd;
      bestConfFrame = r['frame'] as int;
    }
  }
  if (perFrameResults.isNotEmpty) avgMaxConf /= perFrameResults.length;

  // Aspect-ratio stats on the best box per frame — tells us if detections
  // are bar-shaped (high aspect) or plate-shaped (~1.0).
  int aspectBarLike = 0; // aspect >= 3.0
  int aspectMediumWide = 0; // 1.5 <= aspect < 3.0
  int aspectSquareLike = 0; // 0.7 <= aspect < 1.5
  int aspectTall = 0; // aspect < 0.7
  for (final r in perFrameResults) {
    final topKList = r['top_k'] as List?;
    if (topKList == null || topKList.isEmpty) continue;
    final best = topKList[0] as Map;
    final ar = (best['aspect'] as num?)?.toDouble() ?? 0.0;
    if (ar >= 3.0) {
      aspectBarLike++;
    } else if (ar >= 1.5) {
      aspectMediumWide++;
    } else if (ar >= 0.7) {
      aspectSquareLike++;
    } else if (ar > 0) {
      aspectTall++;
    }
  }

  // Top 5 best frames by confidence, for visual review
  final sortedByConf = List<Map<String, dynamic>>.from(perFrameResults);
  sortedByConf.sort((a, b) => ((b['maxConf'] as num).toDouble())
      .compareTo((a['maxConf'] as num).toDouble()));
  final top5BestFrames = sortedByConf.take(5).toList();

  // Build a single-line debug summary you can show in a Text widget
  final StringBuffer dbg = StringBuffer();
  dbg.write('frames=${frameFiles.length} ');
  dbg.write('processed=$framesProcessed ');
  dbg.write('size=${firstFrameW}x$firstFrameH ');
  dbg.write('model=$modelLoadInfo ');
  dbg.write('in=$inputTypeStr$inputShape ');
  dbg.write('out=$outputTypeStr$outputShape ');
  dbg.write('| maxConf: ');
  dbg.write('avg=${_rd(avgMaxConf, 3)} ');
  dbg.write('best=${_rd(bestConfEver, 3)}(f$bestConfFrame) ');
  dbg.write('| atThreshold: ');
  dbg.write('>=0.10:$conf10 ');
  dbg.write('>=0.20:$conf20 ');
  dbg.write('>=0.30:$conf30 ');
  dbg.write('>=0.50:$conf50 ');
  dbg.write('>=0.70:$conf70 ');
  dbg.write('| shape: ');
  dbg.write('barLike=$aspectBarLike ');
  dbg.write('mediumWide=$aspectMediumWide ');
  dbg.write('square=$aspectSquareLike ');
  dbg.write('tall=$aspectTall ');
  dbg.write('| histogram(0.0-1.0): ');
  dbg.write(confHistogram.join(','));

  return {
    'success': true,
    'total_frames': frameFiles.length,
    'frames_processed': framesProcessed,
    'frames_with_barbell_at_threshold_${(CONFIDENCE_THRESHOLD * 100).round()}':
        framesWithBarbell,
    'detection_rate_at_threshold': _rd(rate, 3),
    'first_frame_size': {'w': firstFrameW, 'h': firstFrameH},
    'best_conf_ever': _rd(bestConfEver, 3),
    'best_conf_frame': bestConfFrame,
    'avg_max_conf': _rd(avgMaxConf, 3),
    'frames_at_threshold': {
      '0.10': conf10,
      '0.20': conf20,
      '0.30': conf30,
      '0.50': conf50,
      '0.70': conf70,
    },
    'aspect_distribution': {
      'bar_like_3_plus': aspectBarLike,
      'medium_wide_1_5_to_3': aspectMediumWide,
      'square_0_7_to_1_5': aspectSquareLike,
      'tall_under_0_7': aspectTall,
    },
    'confidence_histogram': confHistogram,
    'top_5_best_frames': top5BestFrames,
    'per_frame': perFrameResults,
    'model_info': {
      'input_shape': inputShape,
      'output_shape': outputShape,
      'input_type': inputTypeStr,
      'output_type': outputTypeStr,
      'input_scale': inputScale,
      'input_zero_point': inputZeroPoint,
      'output_scale': outputScale,
      'output_zero_point': outputZeroPoint,
      'load_path': modelLoadInfo,
    },
    'debug_string': dbg.toString(),
  };
}

class _Pred {
  final int idx;
  final double conf;
  _Pred(this.idx, this.conf);
}

double _rd(double x, int decimals) {
  final m = math.pow(10, decimals);
  return (x * m).round() / m;
}
