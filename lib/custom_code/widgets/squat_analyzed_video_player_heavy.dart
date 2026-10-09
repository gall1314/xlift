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

import 'package:flutter/services.dart'; // for HapticFeedback
import 'package:audioplayers/audioplayers.dart';

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui show TextDirection;
import 'package:video_player/video_player.dart';

/// Custom widget: plays the analyzed squat video for the HEAVY pipeline
/// (pose_detection package — YOLOv8n + BlazePose Heavy) and draws an overlay.
///
/// This is a sibling of SquatAnalyzedVideoPlayer (the Full / ML Kit version)
/// with two material differences calibrated to the Heavy model's output:
///
/// 1. VISIBILITY THRESHOLDS — Heavy emits systematically lower visibility
/// scores than Full for landmarks of identical quality. This is a model
/// artifact, not a quality difference. The Full widget's thresholds (0.5 for
/// draw, 0.4 for hip position-lock, 0.7 for foot memory) were calibrated
/// against Full's distribution and reject too much in Heavy. We've shifted
/// each threshold down by ~0.15-0.20 to match Heavy's distribution.
///
/// 2. BOUNDING BOX RENDERING — the Heavy analyzer emits a per-frame bbox
/// (YOLOv8n person detection). The Full pipeline has no equivalent (ML Kit
/// hides its internal detector). We optionally render the bbox as a thin
/// outline so the user can see where the detector thinks the lifter is —
/// useful for debugging tracking drift in multi-person scenes and visible
/// confirmation that the right person is being analyzed. Off by default; opt
/// in via `showBoundingBox: true`.
///
/// Everything else (audio, haptic, flash, scrub, telemetry interpolation) is
/// byte-identical to the Full widget so any UI improvements there can be
/// ported across by direct copy-paste.
class SquatAnalyzedVideoPlayerHeavy extends StatefulWidget {
  const SquatAnalyzedVideoPlayerHeavy({
    Key? key,
    this.width,
    this.height,
    required this.analysisResult,
    this.showSkeleton = true,
    this.showBoundingBox = false,
    this.videoVolume = 0.25,
    this.lockFeet = false,
  }) : super(key: key);

  final double? width;
  final double? height;
  final dynamic analysisResult;
  final bool showSkeleton;
  // HEAVY-ONLY: render YOLOv8n bounding box as a thin outline. Off by
  // default to keep the visual clean; turn on for debugging tracking or
  // to give the user visible confirmation of who's being analyzed.
  final bool showBoundingBox;
  final double videoVolume;
  final bool lockFeet;

  @override
  State<SquatAnalyzedVideoPlayerHeavy> createState() =>
      _SquatAnalyzedVideoPlayerHeavyState();
}

class _SquatAnalyzedVideoPlayerHeavyState
    extends State<SquatAnalyzedVideoPlayerHeavy> {
  VideoPlayerController? _controller;
  String? _errorMessage;
  bool _isReady = false;
  bool _showControls = true;

  List<_HvFrameData> _telemetry = [];
  double _fps = 8.0;

  double _lastTickProcessedT = -1.0;
  final Set<int> _audioFiredFor = {};
  DateTime _lastPaintAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _PAINT_MIN_GAP_MS = 50;
  DateTime _lastHapticAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool? _wasPlaying;
  Offset? _lastRenderedHipCentroid;

  void _scheduleRepaint({bool force = false}) {
    if (!mounted) return;
    final now = DateTime.now();
    final elapsedMs = now.difference(_lastPaintAt).inMilliseconds;
    if (force || elapsedMs >= _PAINT_MIN_GAP_MS) {
      _lastPaintAt = now;
      setState(() {});
    }
  }

  // HEAVY: lowered from 0.5 (Full's value) to 0.30. Heavy assigns
  // systematically lower confidence to landmarks of identical quality.
  // At 0.5 we were hiding correct landmarks; 0.30 matches the Heavy
  // distribution's "this point is genuinely visible" inflection.
  static const double _DRAW_VIS_THRESHOLD = 0.30;

  // HEAVY: lowered from 0.4 (Full's value). Hip-jump check should only
  // engage when both neighbor frames have hip landmarks the model
  // actually believes in. With Heavy's distribution, 0.4 was too strict
  // and disabled the jump-check during legitimate squats.
  static const double _HIP_JUMP_VIS_THRESHOLD = 0.25;

  // HEAVY: lowered from 0.7 / 0.5 for foot remember / fallback. Feet
  // routinely get visibility ~0.5 in Heavy even when clearly visible.
  static const double _FOOT_REMEMBER_THRESHOLD = 0.50;
  static const double _FOOT_FALLBACK_THRESHOLD = 0.30;

  static const List<String> _GOOD_REP_CANDIDATES = [
    'audios/good_rep.mp3',
    'audio/good_rep.mp3',
    'good_rep.mp3',
    'assets/audios/good_rep.mp3',
    'assets/audio/good_rep.mp3',
  ];
  static const List<String> _BAD_REP_CANDIDATES = [
    'audios/bad_rep.mp3',
    'audio/bad_rep.mp3',
    'bad_rep.mp3',
    'assets/audios/bad_rep.mp3',
    'assets/audio/bad_rep.mp3',
  ];
  final AudioPlayer _goodRepPlayer = AudioPlayer();
  final AudioPlayer _badRepPlayer = AudioPlayer();
  bool _audioReady = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// Unwrap the analyzer-result map from either (a) raw analyzer output
  /// or (b) workout-page set wrapper. Identical to the Full widget.
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

  Future<void> _init() async {
    try {
      final input = widget.analysisResult;
      if (input == null || input is! Map) {
        setState(() => _errorMessage = 'Invalid analysis result');
        return;
      }

      final Map result = _unwrapResult(input);

      final String? uri = result['_source_video_uri'] as String?;
      if (uri == null || uri.isEmpty) {
        setState(() => _errorMessage = 'Missing _source_video_uri');
        return;
      }

      // HEAVY: default fps for this pipeline is 8 (from HeavyTuningParams),
      // not 12 like the Full pipeline. The fallback respects that.
      _fps = (result['analyzed_fps'] as num?)?.toDouble() ?? 8.0;

      final List<dynamic> raw =
          (result['_frame_telemetry'] as List?) ?? const [];
      _telemetry = raw.map((r) => _HvFrameData.fromMap(r as Map)).toList();

      String path = uri;
      if (path.startsWith('file://')) {
        path = path.substring(7);
      }
      final File file = File(path);
      if (!file.existsSync()) {
        setState(() => _errorMessage = 'Video file not found:\n$path');
        return;
      }

      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      controller.setLooping(false);
      final double volClamped = widget.videoVolume.clamp(0.0, 1.0);
      try {
        await controller.setVolume(volClamped);
      } catch (_) {}
      controller.addListener(_onVideoTick);
      _controller = controller;

      _preloadAudio();

      if (mounted) setState(() => _isReady = true);
      await controller.play();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Init error: $e');
      }
    }
  }

  void _onVideoTick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      _scheduleRepaint();
      return;
    }

    final double tSec = controller.value.position.inMilliseconds / 1000.0;

    if (_lastTickProcessedT < 0 || tSec < _lastTickProcessedT) {
      _lastTickProcessedT = tSec;
      _audioFiredFor.clear();
      _footRemembered.clear();
      _scheduleRepaint(force: true);
      return;
    }

    const double AUDIO_LOOKAHEAD_SEC = 0.20;
    final double scanEnd = tSec + AUDIO_LOOKAHEAD_SEC;
    int loA = 0, hiA = _telemetry.length;
    while (loA < hiA) {
      final mid = (loA + hiA) >> 1;
      if (_telemetry[mid].t <= _lastTickProcessedT) {
        loA = mid + 1;
      } else {
        hiA = mid;
      }
    }
    for (int i = loA;
        i < _telemetry.length && _telemetry[i].t <= scanEnd;
        i++) {
      final f = _telemetry[i];
      if (f.repJustFinished == null) continue;
      if (f.t <= tSec) continue;
      if (_audioFiredFor.contains(i)) continue;
      _audioFiredFor.add(i);
      if (f.repJustFinished == 'good') {
        _playGoodRepSound();
      } else {
        _playBadRepSound();
      }
    }

    int lo = 0, hi = _telemetry.length;
    while (lo < hi) {
      final int mid = (lo + hi) >> 1;
      if (_telemetry[mid].t <= _lastTickProcessedT) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }

    for (int i = lo; i < _telemetry.length && _telemetry[i].t <= tSec; i++) {
      final f = _telemetry[i];
      if (f.repJustFinished != null) {
        final now = DateTime.now();
        final canHaptic = now.difference(_lastHapticAt).inMilliseconds >= 80;
        if (f.repJustFinished == 'good') {
          if (canHaptic) {
            _lastHapticAt = now;
            HapticFeedback.mediumImpact();
          }
          if (!_audioFiredFor.contains(i)) {
            _audioFiredFor.add(i);
            _playGoodRepSound();
          }
        } else {
          if (canHaptic) {
            _lastHapticAt = now;
            HapticFeedback.lightImpact();
            Future.delayed(const Duration(milliseconds: 90), () {
              HapticFeedback.lightImpact();
            });
          }
          if (!_audioFiredFor.contains(i)) {
            _audioFiredFor.add(i);
            _playBadRepSound();
          }
        }
      }
    }

    bool repBoundaryCrossed = false;
    for (int i = lo; i < _telemetry.length && _telemetry[i].t <= tSec; i++) {
      if (_telemetry[i].repJustFinished != null) {
        repBoundaryCrossed = true;
        break;
      }
    }

    final bool nowPlaying = controller.value.isPlaying;
    final bool playingChanged =
        _wasPlaying != null && _wasPlaying != nowPlaying;
    _wasPlaying = nowPlaying;

    _lastTickProcessedT = tSec;
    _scheduleRepaint(force: repBoundaryCrossed || playingChanged);
  }

  String? _goodRepWorkingPath;
  String? _badRepWorkingPath;

  Future<void> _preloadAudio() async {
    bool goodOk = false;
    bool badOk = false;

    for (final path in _GOOD_REP_CANDIDATES) {
      try {
        await _goodRepPlayer.setSource(AssetSource(path));
        await _goodRepPlayer.setVolume(1.0);
        await _goodRepPlayer.setReleaseMode(ReleaseMode.stop);
        _goodRepWorkingPath = path;
        goodOk = true;
        break;
      } catch (_) {}
    }

    for (final path in _BAD_REP_CANDIDATES) {
      try {
        await _badRepPlayer.setSource(AssetSource(path));
        await _badRepPlayer.setVolume(1.0);
        await _badRepPlayer.setReleaseMode(ReleaseMode.stop);
        _badRepWorkingPath = path;
        badOk = true;
        break;
      } catch (_) {}
    }

    _audioReady = goodOk || badOk;
    if (_audioReady) {
      await _initAudioPool();
    }
  }

  final List<AudioPlayer> _goodRepPool = [];
  final List<AudioPlayer> _badRepPool = [];
  int _goodPoolIdx = 0;
  int _badPoolIdx = 0;
  static const int _AUDIO_POOL_SIZE = 3;

  Future<void> _initAudioPool() async {
    if (_goodRepWorkingPath != null) {
      for (int i = 0; i < _AUDIO_POOL_SIZE; i++) {
        try {
          final p = AudioPlayer();
          await p.setSource(AssetSource(_goodRepWorkingPath!));
          await p.setVolume(1.0);
          await p.setReleaseMode(ReleaseMode.stop);
          _goodRepPool.add(p);
        } catch (_) {}
      }
    }
    if (_badRepWorkingPath != null) {
      for (int i = 0; i < _AUDIO_POOL_SIZE; i++) {
        try {
          final p = AudioPlayer();
          await p.setSource(AssetSource(_badRepWorkingPath!));
          await p.setVolume(1.0);
          await p.setReleaseMode(ReleaseMode.stop);
          _badRepPool.add(p);
        } catch (_) {}
      }
    }
  }

  DateTime _lastAudioAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _AUDIO_MIN_GAP_MS = 80;

  void _playRepSound(String? workingPath, {double volume = 1.0}) {
    if (!_audioReady || workingPath == null) return;
    final now = DateTime.now();
    if (now.difference(_lastAudioAt).inMilliseconds < _AUDIO_MIN_GAP_MS) {
      return;
    }
    _lastAudioAt = now;
    try {
      final bool isGood = workingPath == _goodRepWorkingPath;
      final pool = isGood ? _goodRepPool : _badRepPool;
      if (pool.isEmpty) {
        final player = AudioPlayer();
        player.onPlayerComplete.listen((_) {
          player.dispose();
        });
        player.play(AssetSource(workingPath), volume: volume);
        return;
      }
      final int idx = isGood ? _goodPoolIdx : _badPoolIdx;
      final player = pool[idx % pool.length];
      if (isGood) {
        _goodPoolIdx = (_goodPoolIdx + 1) % pool.length;
      } else {
        _badPoolIdx = (_badPoolIdx + 1) % pool.length;
      }
      player.seek(Duration.zero);
      player.resume();
    } catch (_) {}
  }

  void _playGoodRepSound() => _playRepSound(_goodRepWorkingPath);
  void _playBadRepSound() => _playRepSound(_badRepWorkingPath);

  @override
  void dispose() {
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    _goodRepPlayer.dispose();
    _badRepPlayer.dispose();
    for (final p in _goodRepPool) {
      try {
        p.dispose();
      } catch (_) {}
    }
    for (final p in _badRepPool) {
      try {
        p.dispose();
      } catch (_) {}
    }
    super.dispose();
  }

  _HvFrameData? _frameAtTime(double tSec) {
    if (_telemetry.isEmpty) return null;
    int lo = 0, hi = _telemetry.length;
    while (lo < hi) {
      final int mid = (lo + hi) >> 1;
      if (_telemetry[mid].t <= tSec) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo > 0 ? _telemetry[lo - 1] : _telemetry[0];
  }

  static const Set<int> _FOOT_INDICES = {27, 28, 29, 30, 31, 32};
  final Map<int, List<double>> _footRemembered = {};

  List<List<double>> _interpolatedLandmarksAt(double tSec) {
    if (_telemetry.isEmpty) return const [];

    if (tSec <= _telemetry.first.t) return _telemetry.first.landmarks;
    if (tSec >= _telemetry.last.t) return _telemetry.last.landmarks;

    int lo = 0, hi = _telemetry.length - 1;
    while (lo < hi) {
      final int mid = (lo + hi) >> 1;
      if (_telemetry[mid].t < tSec) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    final _HvFrameData b = _telemetry[lo];
    final _HvFrameData a = lo > 0 ? _telemetry[lo - 1] : b;

    if (a.landmarks.isEmpty || b.landmarks.isEmpty) return const [];

    // poseReliable defaults to true on Heavy (analyzer doesn't emit it).
    if (!a.poseReliable || !b.poseReliable) return const [];

    if (a.landmarks.length >= 25 && b.landmarks.length >= 25) {
      final aHipX = (a.landmarks[23][0] + a.landmarks[24][0]) / 2;
      final aHipY = (a.landmarks[23][1] + a.landmarks[24][1]) / 2;
      final bHipX = (b.landmarks[23][0] + b.landmarks[24][0]) / 2;
      final bHipY = (b.landmarks[23][1] + b.landmarks[24][1]) / 2;
      final aHipVis = (a.landmarks[23][2] + a.landmarks[24][2]) / 2;
      final bHipVis = (b.landmarks[23][2] + b.landmarks[24][2]) / 2;
      // HEAVY: lowered hip-vis gate from 0.4 to 0.25.
      if (aHipVis > _HIP_JUMP_VIS_THRESHOLD &&
          bHipVis > _HIP_JUMP_VIS_THRESHOLD) {
        final dx = aHipX - bHipX;
        final dy = aHipY - bHipY;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist > 0.25) return const [];
      }
    }

    if (widget.lockFeet) {
      for (final foot in _FOOT_INDICES) {
        if (foot >= b.landmarks.length) continue;
        final lb = b.landmarks[foot];
        if (lb.length < 3) continue;
        if (lb[2] >= _FOOT_REMEMBER_THRESHOLD) {
          _footRemembered[foot] = [lb[0], lb[1]];
        }
      }
    }

    final double span = (b.t - a.t);
    final double u = span > 0 ? ((tSec - a.t) / span).clamp(0.0, 1.0) : 0.0;

    final int n = math.min(a.landmarks.length, b.landmarks.length);
    final List<List<double>> interp = List.generate(n, (i) {
      final la = a.landmarks[i];
      final lb = b.landmarks[i];
      if (la.length < 3 || lb.length < 3) return [0.0, 0.0, 0.0];
      final double va = la[2];
      final double vb = lb[2];

      if (widget.lockFeet && _FOOT_INDICES.contains(i)) {
        if (va < _FOOT_FALLBACK_THRESHOLD && vb < _FOOT_FALLBACK_THRESHOLD) {
          final remembered = _footRemembered[i];
          if (remembered != null) {
            return [remembered[0], remembered[1], 1.0];
          }
          return [la[0], la[1], 0.0];
        }
      }

      if (va < _DRAW_VIS_THRESHOLD || vb < _DRAW_VIS_THRESHOLD) {
        return [la[0], la[1], 0.0];
      }
      return [
        la[0] + (lb[0] - la[0]) * u,
        la[1] + (lb[1] - la[1]) * u,
        math.min(va, vb),
      ];
    });

    return interp;
  }

  @override
  Widget build(BuildContext context) {
    final double w = widget.width ?? MediaQuery.of(context).size.width;
    final double h = widget.height ?? 300;

    if (_errorMessage != null) {
      return SizedBox(
        width: w,
        height: h,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (!_isReady || _controller == null) {
      return SizedBox(
        width: w,
        height: h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final controller = _controller!;
    final double videoAspect = controller.value.aspectRatio;

    final double tSec = controller.value.position.inMilliseconds / 1000.0;
    final _HvFrameData? frame = _frameAtTime(tSec);
    final bool isPlaying = controller.value.isPlaying;

    List<List<double>> currentLandmarks = _interpolatedLandmarksAt(tSec);

    if (currentLandmarks.length >= 25) {
      final hipX = (currentLandmarks[23][0] + currentLandmarks[24][0]) / 2;
      final hipY = (currentLandmarks[23][1] + currentLandmarks[24][1]) / 2;
      final hipVis = (currentLandmarks[23][2] + currentLandmarks[24][2]) / 2;
      if (hipVis > _HIP_JUMP_VIS_THRESHOLD) {
        if (_lastRenderedHipCentroid != null) {
          final dx = hipX - _lastRenderedHipCentroid!.dx;
          final dy = hipY - _lastRenderedHipCentroid!.dy;
          final dist = math.sqrt(dx * dx + dy * dy);
          if (dist > 0.20) {
            currentLandmarks = const [];
          } else {
            _lastRenderedHipCentroid = Offset(hipX, hipY);
          }
        } else {
          _lastRenderedHipCentroid = Offset(hipX, hipY);
        }
      }
    }

    const double FLASH_FALLBACK_MAX_SEC = 0.35;
    const double FLASH_FALLBACK_MIN_SEC = 0.10;
    const double FLASH_FALLBACK_GAP_FRACTION = 0.40;

    Color skeletonColor = Colors.white;
    double flashIntensity = 0.0;
    final List<_HvFrameData> tele = _telemetry;
    if (tele.isNotEmpty) {
      _HvFrameData? flashFrame;
      int flashIdx = -1;
      int lo = 0, hi = tele.length;
      while (lo < hi) {
        final mid = (lo + hi) >> 1;
        if (tele[mid].t <= tSec) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }
      for (int i = lo - 1; i >= 0 && i >= lo - 50; i--) {
        if (tele[i].repJustFinished != null) {
          flashFrame = tele[i];
          flashIdx = i;
          break;
        }
      }
      if (flashFrame != null && flashIdx >= 0) {
        double durationSec = flashFrame.flashDurationSec;

        if (durationSec <= 0) {
          double nextPulseT = double.infinity;
          for (int i = flashIdx + 1; i < tele.length; i++) {
            if (tele[i].repJustFinished != null) {
              nextPulseT = tele[i].t;
              break;
            }
          }
          final double gapToNext = nextPulseT - flashFrame.t;
          if (gapToNext.isInfinite) {
            durationSec = FLASH_FALLBACK_MAX_SEC;
          } else {
            durationSec = (gapToNext * FLASH_FALLBACK_GAP_FRACTION)
                .clamp(FLASH_FALLBACK_MIN_SEC, FLASH_FALLBACK_MAX_SEC);
          }
        }

        final double age = tSec - flashFrame.t;
        if (age >= 0 && age <= durationSec) {
          flashIntensity = 1.0 - (age / durationSec);
          skeletonColor = flashFrame.repJustFinished == 'good'
              ? const Color.fromARGB(255, 40, 220, 90)
              : const Color.fromARGB(255, 255, 150, 30);
        }
      }
    }

    return SizedBox(
      width: w,
      height: h,
      child: GestureDetector(
        onTap: () {
          setState(() => _showControls = !_showControls);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black),
            Center(
              child: AspectRatio(
                aspectRatio: videoAspect,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoPlayer(controller),
                    if (frame != null)
                      CustomPaint(
                        painter: _HvSquatOverlayPainter(
                          frame: frame,
                          showSkeleton: widget.showSkeleton,
                          showBoundingBox: widget.showBoundingBox,
                          skeletonColor: skeletonColor,
                          flashIntensity: flashIntensity,
                          smoothedLandmarks: currentLandmarks,
                          drawVisThreshold: _DRAW_VIS_THRESHOLD,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_showControls)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.65),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          if (isPlaying) {
                            controller.pause();
                          } else {
                            if (controller.value.position >=
                                controller.value.duration) {
                              controller.seekTo(Duration.zero);
                              _lastTickProcessedT = 0.0;
                            }
                            controller.play();
                          }
                          if (mounted) {
                            setState(() {
                              _lastPaintAt = DateTime.now();
                            });
                          }
                        },
                      ),
                      Expanded(
                        child: VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Color(0xFF28C850),
                            bufferedColor: Colors.white30,
                            backgroundColor: Colors.white12,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(controller.value.position) +
                            ' / ' +
                            _formatDuration(controller.value.duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ---------------- Typed frame data (Heavy variant) ----------------

class _HvFrameData {
  final double t;
  final int reps;
  final double metricValue;
  final String metricLabel;
  final String? feedback;
  final String? repJustFinished;
  final List<List<double>> landmarks;
  final double flashDurationSec;
  final bool poseReliable;
  // HEAVY-ONLY: YOLOv8n bounding box in normalized (0..1) frame coords.
  // Null on frames where the detector found no person.
  final List<double>? bbox; // [l, t, r, b, score]
  final bool bboxAtEdge;

  _HvFrameData({
    required this.t,
    required this.reps,
    required this.metricValue,
    required this.metricLabel,
    required this.feedback,
    required this.repJustFinished,
    required this.landmarks,
    required this.flashDurationSec,
    this.poseReliable = true,
    this.bbox,
    this.bboxAtEdge = false,
  });

  factory _HvFrameData.fromMap(Map m) {
    final List<dynamic> lmRaw = (m['landmarks'] as List?) ?? const <dynamic>[];
    final List<List<double>> lm = lmRaw.map<List<double>>((e) {
      final List l = e as List;
      return [
        (l.isNotEmpty ? (l[0] as num).toDouble() : 0.0),
        (l.length > 1 ? (l[1] as num).toDouble() : 0.0),
        (l.length > 2 ? (l[2] as num).toDouble() : 0.0),
      ];
    }).toList();
    final double mv = (m['metric_value'] as num?)?.toDouble() ??
        (m['depth'] as num?)?.toDouble() ??
        0.0;
    final String ml = (m['metric_label'] as String?) ?? 'DEPTH';

    // HEAVY: parse bbox if present. Analyzer emits as
    // {'l': 0.21, 't': 0.39, 'r': 0.41, 'b': 0.57, 'score': 0.50}
    List<double>? bboxParsed;
    final dynamic bboxRaw = m['bbox'];
    if (bboxRaw is Map) {
      try {
        bboxParsed = [
          (bboxRaw['l'] as num?)?.toDouble() ?? 0.0,
          (bboxRaw['t'] as num?)?.toDouble() ?? 0.0,
          (bboxRaw['r'] as num?)?.toDouble() ?? 0.0,
          (bboxRaw['b'] as num?)?.toDouble() ?? 0.0,
          (bboxRaw['score'] as num?)?.toDouble() ?? 0.0,
        ];
      } catch (_) {
        bboxParsed = null;
      }
    }

    return _HvFrameData(
      t: (m['t'] as num?)?.toDouble() ?? 0.0,
      reps: (m['reps'] as num?)?.toInt() ?? 0,
      metricValue: mv,
      metricLabel: ml,
      feedback: m['feedback'] as String?,
      repJustFinished: m['rep_just_finished'] as String?,
      landmarks: lm,
      flashDurationSec: (m['flash_duration_sec'] as num?)?.toDouble() ?? 0.0,
      poseReliable: (m['pose_reliable'] as bool?) ?? true,
      bbox: bboxParsed,
      bboxAtEdge: (m['bbox_at_edge'] as bool?) ?? false,
    );
  }
}

// ---------------- Painter (Heavy variant with bbox support) ----------------

class _HvSquatOverlayPainter extends CustomPainter {
  _HvSquatOverlayPainter({
    required this.frame,
    required this.showSkeleton,
    required this.showBoundingBox,
    this.skeletonColor = Colors.white,
    this.flashIntensity = 0.0,
    this.smoothedLandmarks,
    this.drawVisThreshold = 0.30,
  });

  final _HvFrameData frame;
  final bool showSkeleton;
  final bool showBoundingBox;
  final Color skeletonColor;
  final double flashIntensity;
  final List<List<double>>? smoothedLandmarks;
  final double drawVisThreshold;

  static const int NOSE = 0;
  static const int L_SHOULDER = 11;
  static const int R_SHOULDER = 12;
  static const int L_ELBOW = 13;
  static const int R_ELBOW = 14;
  static const int L_WRIST = 15;
  static const int R_WRIST = 16;
  static const int L_HIP = 23;
  static const int R_HIP = 24;
  static const int L_KNEE = 25;
  static const int R_KNEE = 26;
  static const int L_ANKLE = 27;
  static const int R_ANKLE = 28;
  static const int L_HEEL = 29;
  static const int R_HEEL = 30;
  static const int L_FOOT = 31;
  static const int R_FOOT = 32;

  static const List<List<int>> _connections = [
    [L_SHOULDER, R_SHOULDER],
    [L_SHOULDER, L_HIP],
    [R_SHOULDER, R_HIP],
    [L_HIP, R_HIP],
    [L_SHOULDER, L_ELBOW],
    [L_ELBOW, L_WRIST],
    [R_SHOULDER, R_ELBOW],
    [R_ELBOW, R_WRIST],
    [L_HIP, L_KNEE],
    [L_KNEE, L_ANKLE],
    [L_ANKLE, L_HEEL],
    [L_HEEL, L_FOOT],
    [L_ANKLE, L_FOOT],
    [R_HIP, R_KNEE],
    [R_KNEE, R_ANKLE],
    [R_ANKLE, R_HEEL],
    [R_HEEL, R_FOOT],
    [R_ANKLE, R_FOOT],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // HEAVY: bounding box renders FIRST so the skeleton draws on top.
    // The bbox is intentionally drawn semi-transparent so it doesn't
    // dominate; it's reference data, not the main visual.
    if (showBoundingBox && frame.bbox != null && frame.bbox!.length >= 4) {
      final double l = frame.bbox![0] * w;
      final double t = frame.bbox![1] * h;
      final double r = frame.bbox![2] * w;
      final double b = frame.bbox![3] * h;

      // Border color hints at edge status: bright if person is well within
      // the frame, amber if the bbox is touching a frame edge (which means
      // the analyzer suppressed back-angle feedback for this frame).
      final Color bboxColor = frame.bboxAtEdge
          ? const Color.fromARGB(220, 255, 180, 40) // amber: cropped
          : const Color.fromARGB(180, 80, 220, 255); // cyan: fully in frame

      final Paint bboxPaint = Paint()
        ..color = bboxColor
        ..strokeWidth = math.max(1.5, h * 0.0035)
        ..style = PaintingStyle.stroke;

      canvas.drawRect(Rect.fromLTRB(l, t, r, b), bboxPaint);

      // Small score label in the top-left corner of the box.
      if (frame.bbox!.length >= 5) {
        final double score = frame.bbox![4];
        final TextPainter scoreTp = TextPainter(
          text: TextSpan(
            text: 'P ${(score * 100).round()}%',
            style: TextStyle(
              color: bboxColor,
              fontSize: math.max(9.0, h * 0.020),
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        // Position the label just inside the top-left of the box; clamp
        // to canvas bounds so it never falls offscreen if the bbox
        // touches an edge.
        final double labelX = l.clamp(2.0, w - scoreTp.width - 2.0);
        final double labelY = (t - scoreTp.height - 2.0).clamp(0.0, h);
        scoreTp.paint(canvas, Offset(labelX, labelY));
      }
    }

    final List<List<double>> lms =
        (smoothedLandmarks != null && smoothedLandmarks!.length >= 33)
            ? smoothedLandmarks!
            : frame.landmarks;
    if (showSkeleton && lms.length >= 33) {
      final Paint linePaint = Paint()
        ..color = skeletonColor
        ..strokeWidth = math.max(2.0, h * 0.004)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final Paint dotPaint = Paint()
        ..color = skeletonColor
        ..style = PaintingStyle.fill;
      final double dotR = math.max(3.0, h * 0.006);

      Offset? pt(int idx) {
        if (idx < 0 || idx >= lms.length) return null;
        final lm = lms[idx];
        if (lm.length < 3) return null;
        if (lm[2] < drawVisThreshold) return null;
        return Offset(lm[0] * w, lm[1] * h);
      }

      for (final conn in _connections) {
        final a = pt(conn[0]);
        final b = pt(conn[1]);
        if (a != null && b != null) {
          canvas.drawLine(a, b, linePaint);
        }
      }

      const bodyIndices = [
        L_SHOULDER,
        R_SHOULDER,
        L_ELBOW,
        R_ELBOW,
        L_WRIST,
        R_WRIST,
        L_HIP,
        R_HIP,
        L_KNEE,
        R_KNEE,
        L_ANKLE,
        R_ANKLE,
        L_HEEL,
        R_HEEL,
        L_FOOT,
        R_FOOT,
      ];
      for (final i in bodyIndices) {
        final p = pt(i);
        if (p != null) {
          canvas.drawCircle(p, dotR, dotPaint);
        }
      }
    }

    final double repsFontSize = math.max(14.0, h * 0.055);
    final TextPainter repsTp = TextPainter(
      text: TextSpan(
        text: 'Reps: ${frame.reps}',
        style: TextStyle(
          color: Colors.white,
          fontSize: repsFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final double repsBoxW = repsTp.width + 20;
    final double repsBoxH = repsTp.height + 12;
    final Paint repsBoxBg = Paint()..color = Colors.black.withOpacity(0.55);
    canvas.drawRect(Rect.fromLTWH(0, 0, repsBoxW, repsBoxH), repsBoxBg);
    repsTp.paint(canvas, const Offset(10, 6));

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

    TextPainter buildPainter(String text, double fontSize, FontWeight weight) {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: weight,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
    }

    {
      TextPainter probe =
          buildPainter('${(pct * 100).round()}%', pctSize, FontWeight.bold);
      int safety = 0;
      while (probe.width > maxInnerW && pctSize > 8.0 && safety < 6) {
        final double scale = (maxInnerW / probe.width).clamp(0.5, 1.0);
        pctSize = (pctSize * scale).clamp(8.0, pctFontSize);
        labelSize = (labelSize * scale).clamp(7.0, labelFontSize);
        probe =
            buildPainter('${(pct * 100).round()}%', pctSize, FontWeight.bold);
        safety += 1;
      }
    }

    final TextPainter labelTp =
        buildPainter(frame.metricLabel, labelSize, FontWeight.w600);
    final TextPainter pctTp =
        buildPainter('${(pct * 100).round()}%', pctSize, FontWeight.bold);

    final double gap = math.max(2.0, radius * 0.10);
    if (labelTp.height + gap + pctTp.height > maxInnerH) {
      final double scale =
          maxInnerH / (labelTp.height + gap + pctTp.height) * 0.95;
      labelSize *= scale;
      pctSize *= scale;
      final lt2 = buildPainter(frame.metricLabel, labelSize, FontWeight.w600);
      final pt2 =
          buildPainter('${(pct * 100).round()}%', pctSize, FontWeight.bold);
      final double totalTextH2 = lt2.height + gap + pt2.height;
      final double labelY2 = cy - totalTextH2 / 2;
      lt2.paint(canvas, Offset(cx - lt2.width / 2, labelY2));
      pt2.paint(
        canvas,
        Offset(cx - pt2.width / 2, labelY2 + lt2.height + gap),
      );
    } else {
      final double totalTextH = labelTp.height + gap + pctTp.height;
      final double labelY = cy - totalTextH / 2;
      labelTp.paint(canvas, Offset(cx - labelTp.width / 2, labelY));
      pctTp.paint(
        canvas,
        Offset(cx - pctTp.width / 2, labelY + labelTp.height + gap),
      );
    }

    final String? fb = frame.feedback;
    if (fb != null && fb.isNotEmpty) {
      final List<String> fbLines =
          fb.split('\n').where((s) => s.trim().isNotEmpty).toList();
      if (fbLines.isNotEmpty) {
        final double fbFontSize = math.max(12.0, h * 0.038);
        final double padX = 12;
        final double padY = 8;
        final double lineGap = math.max(2.0, h * 0.005);
        final double safe = math.max(6.0, h * 0.02);

        final List<TextPainter> linePainters = fbLines.map((line) {
          return TextPainter(
            text: TextSpan(
              text: line,
              style: TextStyle(
                color: Colors.white,
                fontSize: fbFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            textDirection: ui.TextDirection.ltr,
            textAlign: TextAlign.center,
            maxLines: 2,
            ellipsis: '…',
          )..layout(maxWidth: w - 2 * padX - 20);
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
          tp.paint(canvas, Offset((w - tp.width) / 2, y));
          y += tp.height + lineGap;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HvSquatOverlayPainter old) {
    return old.frame != frame ||
        old.showSkeleton != showSkeleton ||
        old.showBoundingBox != showBoundingBox ||
        old.skeletonColor != skeletonColor ||
        old.flashIntensity != flashIntensity ||
        old.smoothedLandmarks != smoothedLandmarks ||
        old.drawVisThreshold != drawVisThreshold;
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
