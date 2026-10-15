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

import 'dart:math' as math;
import 'package:xlift_vision_pose/xlift_vision_pose.dart';

/// Experiment: Apple Vision 3D pose on a squat video.
/// Counts reps from the 3D knee angle and reports depth + torso lean.
/// Returns a human-readable report string.
Future<String> visionSquatTest(String videoPath) async {
  if (!await XliftVisionPose.isAvailable()) {
    return 'Vision 3D pose not available (needs iOS 17+).';
  }

  final sw = Stopwatch()..start();
  final Map<String, dynamic> res;
  try {
    res = await XliftVisionPose.analyzeVideo(videoPath, fps: 12);
  } catch (e) {
    return 'analyzeVideo failed: $e';
  }
  sw.stop();

  final frames = (res['frames'] as List<dynamic>? ?? const []);
  if (frames.isEmpty) return 'No frames returned.';

  // --- Placeholder thresholds. Calibrate from real logs, as usual. ---
  const double standingKnee = 150.0; // degrees, knee considered extended
  const double bottomKnee = 110.0; // degrees, knee considered "at depth"

  int detected = 0;
  int reps = 0;
  bool reachedBottom = false;
  double repMinKnee = 999, repMinHip = 999, repMaxLean = 0;
  final repLines = <String>[];

  for (final f in frames) {
    final joints =
        (f as Map<String, dynamic>)['joints'] as Map<String, dynamic>?;
    if (joints == null) continue;

    final lHip = _v(joints['leftHip']), rHip = _v(joints['rightHip']);
    final lKnee = _v(joints['leftKnee']), rKnee = _v(joints['rightKnee']);
    final lAnk = _v(joints['leftAnkle']), rAnk = _v(joints['rightAnkle']);
    final root = _v(joints['root']), shoulder = _v(joints['centerShoulder']);
    if ([lHip, rHip, lKnee, rKnee, lAnk, rAnk, root, shoulder]
        .any((v) => v == null)) {
      continue;
    }
    detected++;

    // 3D knee angle, averaged over both legs (hip-knee-ankle).
    final knee =
        (_angle(lHip!, lKnee!, lAnk!) + _angle(rHip!, rKnee!, rAnk!)) / 2;

    // Hip height above ankles, meters. Depth proxy that doesn't care about view.
    final ankleY = (lAnk[1] + rAnk[1]) / 2;
    final hipAboveAnkle = root![1] - ankleY;

    // Torso lean: angle between (root -> centerShoulder) and the vertical axis.
    final torso = [
      shoulder![0] - root[0],
      shoulder[1] - root[1],
      shoulder[2] - root[2],
    ];
    final lean = _angleToVertical(torso);

    // Minimal state machine: standing -> below bottomKnee -> back above standingKnee.
    if (knee < bottomKnee) reachedBottom = true;
    if (reachedBottom) {
      repMinKnee = math.min(repMinKnee, knee);
      repMinHip = math.min(repMinHip, hipAboveAnkle);
      repMaxLean = math.max(repMaxLean, lean);
    }
    if (reachedBottom && knee > standingKnee) {
      reps++;
      repLines.add('rep $reps: minKnee ${repMinKnee.toStringAsFixed(0)}°, '
          'hipAboveAnkle ${repMinHip.toStringAsFixed(2)}m, '
          'maxLean ${repMaxLean.toStringAsFixed(0)}°');
      reachedBottom = false;
      repMinKnee = 999;
      repMinHip = 999;
      repMaxLean = 0;
    }
  }

  final pct = (100 * detected / frames.length).toStringAsFixed(0);
  return [
    'frames ${frames.length} @ ${(res['sampledFps'] as num?)?.toStringAsFixed(1)}fps, '
        'body detected in $detected ($pct%), ${sw.elapsedMilliseconds}ms',
    'reps: $reps',
    ...repLines,
  ].join('\n');
}

List<double>? _v(dynamic j) {
  if (j is! Map) return null;
  final x = j['x'], y = j['y'], z = j['z'];
  if (x is! num || y is! num || z is! num) return null;
  return [x.toDouble(), y.toDouble(), z.toDouble()];
}

/// Angle at [b] formed by a-b-c, degrees.
double _angle(List<double> a, List<double> b, List<double> c) {
  final ab = [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
  final cb = [c[0] - b[0], c[1] - b[1], c[2] - b[2]];
  final dot = ab[0] * cb[0] + ab[1] * cb[1] + ab[2] * cb[2];
  final n = _len(ab) * _len(cb);
  if (n == 0) return 0;
  return math.acos((dot / n).clamp(-1.0, 1.0)) * 180 / math.pi;
}

double _angleToVertical(List<double> v) {
  final n = _len(v);
  if (n == 0) return 0;
  return math.acos((v[1] / n).clamp(-1.0, 1.0)) * 180 / math.pi;
}

double _len(List<double> v) =>
    math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
