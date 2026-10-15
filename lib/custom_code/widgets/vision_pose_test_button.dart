// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:io';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:xlift_vision_pose/xlift_vision_pose.dart';

/// Debug-only experiment: small button -> record/pick a squat video ->
/// Apple Vision 3D pose -> result page with skeleton overlay + text report.
/// Self-contained. Touches nothing else in the app.
class VisionPoseTestButton extends StatefulWidget {
  const VisionPoseTestButton({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<VisionPoseTestButton> createState() => _VisionPoseTestButtonState();
}

class _VisionPoseTestButtonState extends State<VisionPoseTestButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: _busy
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('Analyzing…'),
              ],
            )
          : OutlinedButton.icon(
              icon: const Icon(Icons.view_in_ar, size: 18),
              label: const Text('Vision 3D test'),
              onPressed: _pickSource,
            ),
    );
  }

  Future<void> _pickSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record video'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pick from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _run(source);
  }

  Future<void> _run(ImageSource source) async {
    if (!await XliftVisionPose.isAvailable()) {
      _toast('Vision 3D pose needs iOS 17+');
      return;
    }
    final picked = await ImagePicker().pickVideo(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
      maxDuration: const Duration(seconds: 60),
    );
    if (picked == null) return;

    setState(() => _busy = true);
    try {
      final sw = Stopwatch()..start();
      final res = await XliftVisionPose.analyzeVideo(picked.path, fps: 12);
      sw.stop();
      final frames = (res['frames'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      final report = _squatReport(frames, res, sw.elapsedMilliseconds);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _VisionResultPage(
          videoPath: picked.path,
          frames: frames,
          report: report,
        ),
      ));
    } catch (e) {
      _toast('Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ---------------------------------------------------------------------------
// Result page: video + skeleton overlay + report
// ---------------------------------------------------------------------------

class _VisionResultPage extends StatefulWidget {
  const _VisionResultPage({
    required this.videoPath,
    required this.frames,
    required this.report,
  });

  final String videoPath;
  final List<Map<String, dynamic>> frames;
  final String report;

  @override
  State<_VisionResultPage> createState() => _VisionResultPageState();
}

class _VisionResultPageState extends State<_VisionResultPage> {
  late final VideoPlayerController _c;
  bool _ready = false;
  int _idx = -1;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.file(File(widget.videoPath));
    _c.initialize().then((_) async {
      await _c.setLooping(true);
      _c.addListener(_tick);
      if (mounted) setState(() => _ready = true);
      await _c.play();
    });
  }

  @override
  void dispose() {
    _c.removeListener(_tick);
    _c.dispose();
    super.dispose();
  }

  void _tick() {
    if (widget.frames.isEmpty) return;
    final t = _c.value.position.inMilliseconds / 1000.0;
    final i = _nearestFrame(t);
    if (i != _idx) setState(() => _idx = i);
  }

  int _nearestFrame(double t) {
    final f = widget.frames;
    int lo = 0, hi = f.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (((f[mid]['t'] as num?) ?? 0).toDouble() < t) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    if (lo > 0) {
      final a = ((f[lo - 1]['t'] as num?) ?? 0).toDouble();
      final b = ((f[lo]['t'] as num?) ?? 0).toDouble();
      if ((t - a).abs() < (b - t).abs()) return lo - 1;
    }
    return lo;
  }

  @override
  Widget build(BuildContext context) {
    final joints = (_idx >= 0 && _idx < widget.frames.length)
        ? widget.frames[_idx]['joints'] as Map<String, dynamic>?
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Vision 3D test'),
      ),
      body: Column(
        children: [
          if (!_ready)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else
            GestureDetector(
              onTap: () => _c.value.isPlaying ? _c.pause() : _c.play(),
              child: AspectRatio(
                aspectRatio: _c.value.aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoPlayer(_c),
                    CustomPaint(painter: _SkeletonPainter(joints)),
                  ],
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                widget.report,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter(this.joints);

  final Map<String, dynamic>? joints;

  static const _edges = [
    ['root', 'spine'],
    ['spine', 'centerShoulder'],
    ['centerShoulder', 'centerHead'],
    ['centerHead', 'topHead'],
    ['centerShoulder', 'leftShoulder'],
    ['leftShoulder', 'leftElbow'],
    ['leftElbow', 'leftWrist'],
    ['centerShoulder', 'rightShoulder'],
    ['rightShoulder', 'rightElbow'],
    ['rightElbow', 'rightWrist'],
    ['root', 'leftHip'],
    ['leftHip', 'leftKnee'],
    ['leftKnee', 'leftAnkle'],
    ['root', 'rightHip'],
    ['rightHip', 'rightKnee'],
    ['rightKnee', 'rightAnkle'],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final j = joints;
    if (j == null) {
      canvas.drawCircle(
          const Offset(16, 16), 6, Paint()..color = Colors.redAccent);
      return;
    }
    final line = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = Colors.white;

    for (final e in _edges) {
      final a = _pt(j[e[0]], size), b = _pt(j[e[1]], size);
      if (a != null && b != null) canvas.drawLine(a, b, line);
    }
    for (final v in j.values) {
      final p = _pt(v, size);
      if (p != null) canvas.drawCircle(p, 4, dot);
    }
  }

  Offset? _pt(dynamic v, Size size) {
    if (v is! Map) return null;
    final px = v['px'], py = v['py'];
    if (px is! num || py is! num) return null;
    return Offset(px * size.width, py * size.height);
  }

  @override
  bool shouldRepaint(_SkeletonPainter old) => old.joints != joints;
}

// ---------------------------------------------------------------------------
// Squat report from 3D joints
// ---------------------------------------------------------------------------

String _squatReport(
    List<Map<String, dynamic>> frames, Map<String, dynamic> res, int ms) {
  if (frames.isEmpty) return 'No frames returned.';

  // Placeholder thresholds — calibrate from real logs.
  const double standingKnee = 150.0;
  const double bottomKnee = 110.0;

  int detected = 0, reps = 0;
  bool reachedBottom = false;
  double repMinKnee = 999, repMinHip = 999, repMaxLean = 0;
  final lines = <String>[];

  for (final f in frames) {
    final j = f['joints'] as Map<String, dynamic>?;
    if (j == null) continue;
    final lHip = _v(j['leftHip']), rHip = _v(j['rightHip']);
    final lKnee = _v(j['leftKnee']), rKnee = _v(j['rightKnee']);
    final lAnk = _v(j['leftAnkle']), rAnk = _v(j['rightAnkle']);
    final root = _v(j['root']), sh = _v(j['centerShoulder']);
    if ([lHip, rHip, lKnee, rKnee, lAnk, rAnk, root, sh]
        .any((v) => v == null)) {
      continue;
    }
    detected++;

    final knee =
        (_angle(lHip!, lKnee!, lAnk!) + _angle(rHip!, rKnee!, rAnk!)) / 2;
    final hipAboveAnkle = root![1] - (lAnk[1] + rAnk[1]) / 2;
    final lean =
        _angleToVertical([sh![0] - root[0], sh[1] - root[1], sh[2] - root[2]]);

    if (knee < bottomKnee) reachedBottom = true;
    if (reachedBottom) {
      repMinKnee = math.min(repMinKnee, knee);
      repMinHip = math.min(repMinHip, hipAboveAnkle);
      repMaxLean = math.max(repMaxLean, lean);
    }
    if (reachedBottom && knee > standingKnee) {
      reps++;
      lines.add('rep $reps: minKnee ${repMinKnee.toStringAsFixed(0)}°  '
          'hipAboveAnkle ${repMinHip.toStringAsFixed(2)}m  '
          'maxLean ${repMaxLean.toStringAsFixed(0)}°');
      reachedBottom = false;
      repMinKnee = 999;
      repMinHip = 999;
      repMaxLean = 0;
    }
  }

  final pct = (100 * detected / frames.length).toStringAsFixed(0);
  final fps = (res['sampledFps'] as num?)?.toStringAsFixed(1) ?? '?';
  return [
    'frames ${frames.length} @ ${fps}fps, body in $detected ($pct%), ${ms}ms',
    'reps: $reps',
    ...lines,
  ].join('\n');
}

List<double>? _v(dynamic j) {
  if (j is! Map) return null;
  final x = j['x'], y = j['y'], z = j['z'];
  if (x is! num || y is! num || z is! num) return null;
  return [x.toDouble(), y.toDouble(), z.toDouble()];
}

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
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
