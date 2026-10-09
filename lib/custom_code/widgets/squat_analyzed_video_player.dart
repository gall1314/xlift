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

/// Custom widget: plays the analyzed exercise video and draws an overlay.
///
/// v18 — Added barbell bounding-box rendering. When per-frame telemetry
/// contains a `barbell_bbox` field (emitted by the test deadlift analyzer
/// that runs YOLO alongside pose detection), the widget draws a translucent
/// cyan rectangle over the detected barbell, with the confidence shown above
/// it. Toggleable via `showBarbellBox` (defaults to true). Hidden silently
/// when the field is absent or null, so existing analyzers that don't emit it
/// (squat, pushup, etc.) are unaffected.
///
/// v17 — Accepts either shape for `analysisResult`: (a) the raw analyzer
/// result map (used directly from the test page), which has _source_video_uri
/// / _frame_telemetry at the top level (b) a set object from the workout-page
/// app state list, which wraps the analyzer result under an 'analysis' key: {
/// setNumber, isProcessing, analysisDone, hasError, analysis: {...} } The
/// widget probes both layouts so the same call site works in both flows
/// without the caller having to unwrap.
///
/// v16 — Added pose_reliable awareness. The analyzer (RDL/StiffLeg) now emits
/// per-frame `pose_reliable` flags that mark frames where ML Kit's detection
/// is suspect (low visibility, snap to bystander, position-lock rejection).
/// When that flag is false, the widget hides the skeleton so what's drawn
/// matches what's counted. Resolves the "skeleton on bystander but rep
/// counted on lifter" inconsistency reported on RDL videos.
///
/// v15 — Flash duration fix: read `flash_duration_sec` from telemetry instead
/// of recomputing in the widget. Floor-semantic _frameAtTime for
/// counter/flash sync. Tightened fallback duration formula.
class SquatAnalyzedVideoPlayer extends StatefulWidget {
  const SquatAnalyzedVideoPlayer({
    Key? key,
    this.width,
    this.height,
    required this.analysisResult,
    this.showSkeleton = true,
    this.showBarbellBox = true,
    this.videoVolume = 0.25,
    this.lockFeet = false,
  }) : super(key: key);

  final double? width;
  final double? height;
  final dynamic analysisResult;
  final bool showSkeleton;
  // [v18] Toggle for the YOLO barbell bbox overlay. Drawing is silently
  // skipped when telemeכtry has no `barbell_bbox` field, so leaving this
  // true is safe for analyzers that don't run YOLO.
  final bool showBarbellBox;
  final double videoVolume;
  final bool lockFeet;

  @override
  State<SquatAnalyzedVideoPlayer> createState() =>
      _SquatAnalyzedVideoPlayerState();
}

class _SquatAnalyzedVideoPlayerState extends State<SquatAnalyzedVideoPlayer> {
  VideoPlayerController? _controller;
  String? _errorMessage;
  bool _isReady = false;
  bool _showControls = true;

  List<_FrameData> _telemetry = [];
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

  static const double _DRAW_VIS_THRESHOLD = 0.5;

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

  /// Unwrap the input to the analyzer-result map.
  ///
  /// Accepts either of two shapes:
  ///   (a) the raw analyzer result — has `_source_video_uri` / `_frame_telemetry`
  ///       at the top level. Used directly on the test page where we hand
  ///       the analyzer output straight to the widget.
  ///   (b) a set object from the workout-page app state list — wraps the
  ///       analyzer output under `analysis`:
  ///         { setNumber: 1, isProcessing: false, analysisDone: true,
  ///           hasError: false, analysis: { _source_video_uri: ..., ... } }
  /// Returns whichever inner map actually contains the analyzer fields.
  /// If neither layout matches, returns the original input so the caller's
  /// downstream null-check can produce a meaningful error.
  Map _unwrapResult(Map raw) {
    // Layout (a): top-level analyzer keys present.
    if (raw.containsKey('_source_video_uri') ||
        raw.containsKey('_frame_telemetry')) {
      return raw;
    }
    // Layout (b): wrapped under 'analysis'.
    final inner = raw['analysis'];
    if (inner is Map &&
        (inner.containsKey('_source_video_uri') ||
            inner.containsKey('_frame_telemetry'))) {
      return inner;
    }
    // Fallback: hand back whatever we got — the next null-check will
    // surface a clear 'Missing _source_video_uri' error.
    return raw;
  }

  Future<void> _init() async {
    try {
      final input = widget.analysisResult;
      if (input == null || input is! Map) {
        setState(() => _errorMessage = 'Invalid analysis result');
        return;
      }

      // Unwrap if we were handed a set object instead of the raw result.
      final Map result = _unwrapResult(input);

      final String? uri = result['_source_video_uri'] as String?;
      if (uri == null || uri.isEmpty) {
        setState(() => _errorMessage = 'Missing _source_video_uri');
        return;
      }

      _fps = (result['analyzed_fps'] as num?)?.toDouble() ?? 8.0;

      final List<dynamic> raw =
          (result['_frame_telemetry'] as List?) ?? const [];
      _telemetry = raw.map((r) => _FrameData.fromMap(r as Map)).toList();

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

// [v15->v23 SYNC FIX] Floor semantic — same as the flash search below.
// Returns the last frame whose timestamp is <= tSec. This guarantees
// the displayed reps count and the flash state are always derived from
// the SAME telemetry frame.
  _FrameData? _frameAtTime(double tSec) {
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
  static const double _FOOT_REMEMBER_THRESHOLD = 0.7;
  static const double _FOOT_FALLBACK_THRESHOLD = 0.5;
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
    final _FrameData b = _telemetry[lo];
    final _FrameData a = lo > 0 ? _telemetry[lo - 1] : b;

    if (a.landmarks.isEmpty || b.landmarks.isEmpty) return const [];

    // [v16 POSE-RELIABLE-FLAG] If EITHER neighbor was marked unreliable
    // by the analyzer (low visibility, position-lock rejection, identity
    // jump), hide the skeleton entirely for this moment in time. This
    // keeps the rendered skeleton consistent with the analyzer's
    // rep-counting: we never draw a skeleton on a frame the analyzer
    // refused to trust. Resolves the "skeleton on bystander, rep counted
    // on lifter" disconnect.
    //
    // Note: `poseReliable` defaults to true for older analyzer outputs
    // that don't emit the flag, so this is backward-compatible with
    // squat/pushup/curl telemetry.
    if (!a.poseReliable || !b.poseReliable) return const [];

    if (a.landmarks.length >= 25 && b.landmarks.length >= 25) {
      final aHipX = (a.landmarks[23][0] + a.landmarks[24][0]) / 2;
      final aHipY = (a.landmarks[23][1] + a.landmarks[24][1]) / 2;
      final bHipX = (b.landmarks[23][0] + b.landmarks[24][0]) / 2;
      final bHipY = (b.landmarks[23][1] + b.landmarks[24][1]) / 2;
      final aHipVis = (a.landmarks[23][2] + a.landmarks[24][2]) / 2;
      final bHipVis = (b.landmarks[23][2] + b.landmarks[24][2]) / 2;
      if (aHipVis > 0.4 && bHipVis > 0.4) {
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
    final _FrameData? frame = _frameAtTime(tSec);
    final bool isPlaying = controller.value.isPlaying;

    List<List<double>> currentLandmarks = _interpolatedLandmarksAt(tSec);

    if (currentLandmarks.length >= 25) {
      final hipX = (currentLandmarks[23][0] + currentLandmarks[24][0]) / 2;
      final hipY = (currentLandmarks[23][1] + currentLandmarks[24][1]) / 2;
      final hipVis = (currentLandmarks[23][2] + currentLandmarks[24][2]) / 2;
      if (hipVis > 0.4) {
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

    // [v15] Flash duration and color — reads flash_duration_sec from analyzer.
    const double FLASH_FALLBACK_MAX_SEC = 0.35;
    const double FLASH_FALLBACK_MIN_SEC = 0.10;
    const double FLASH_FALLBACK_GAP_FRACTION = 0.40;

    Color skeletonColor = Colors.white;
    double flashIntensity = 0.0;
    final List<_FrameData> tele = _telemetry;
    if (tele.isNotEmpty) {
      _FrameData? flashFrame;
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
                        painter: _SquatOverlayPainter(
                          frame: frame,
                          showSkeleton: widget.showSkeleton,
                          showBarbellBox: widget.showBarbellBox,
                          skeletonColor: skeletonColor,
                          flashIntensity: flashIntensity,
                          smoothedLandmarks: currentLandmarks,
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

// ---------------- Typed frame data ----------------

class _FrameData {
  final double t;
  final int reps;
  final double metricValue;
  final String metricLabel;
  final String? feedback;
  final String? repJustFinished;
  final List<List<double>> landmarks;
  // [v15] Flash duration that the analyzer chose for this rep.
  // 0.0 means "not provided" → widget falls back to a tight calculation.
  final double flashDurationSec;
  // [v16] Tells the widget whether ML Kit's detection for this frame is
  // trustworthy. False when the analyzer rejected the frame (position
  // lock failed, hip jumped, upper-body visibility too low, etc.). The
  // widget hides the skeleton when this is false so what's shown matches
  // what's counted. Defaults to true for backward compatibility with
  // older analyzer outputs that don't emit the flag.
  final bool poseReliable;
  // [v18] YOLOv8 barbell detection for this frame, if the analyzer ran the
  // YOLO model on it. Null when there was no detection above the analyzer's
  // confidence threshold, or for frames/analyzers that don't run YOLO at
  // all. Coordinates are normalized to the frame (0..1 for x_center,
  // y_center, width, height); confidence is 0..1.
  final _BarbellBbox? barbellBbox;

  _FrameData({
    required this.t,
    required this.reps,
    required this.metricValue,
    required this.metricLabel,
    required this.feedback,
    required this.repJustFinished,
    required this.landmarks,
    required this.flashDurationSec,
    this.poseReliable = true,
    this.barbellBbox,
  });

  factory _FrameData.fromMap(Map m) {
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

    // [v18] Parse barbell_bbox if present.
    _BarbellBbox? bbox;
    final rawBbox = m['barbell_bbox'];
    if (rawBbox is Map) {
      final xc = (rawBbox['x_center'] as num?)?.toDouble();
      final yc = (rawBbox['y_center'] as num?)?.toDouble();
      final bw = (rawBbox['width'] as num?)?.toDouble();
      final bh = (rawBbox['height'] as num?)?.toDouble();
      final conf = (rawBbox['confidence'] as num?)?.toDouble() ?? 0.0;
      if (xc != null && yc != null && bw != null && bh != null) {
        bbox = _BarbellBbox(
          xCenter: xc,
          yCenter: yc,
          width: bw,
          height: bh,
          confidence: conf,
        );
      }
    }

    return _FrameData(
      t: (m['t'] as num?)?.toDouble() ?? 0.0,
      reps: (m['reps'] as num?)?.toInt() ?? 0,
      metricValue: mv,
      metricLabel: ml,
      feedback: m['feedback'] as String?,
      repJustFinished: m['rep_just_finished'] as String?,
      landmarks: lm,
      flashDurationSec: (m['flash_duration_sec'] as num?)?.toDouble() ?? 0.0,
      // [v16] Read pose_reliable from analyzer telemetry. Defaults to
      // true if not provided (older analyzers).
      poseReliable: (m['pose_reliable'] as bool?) ?? true,
      barbellBbox: bbox,
    );
  }
}

/// [v18] Normalized barbell bounding box from the YOLO detector.
class _BarbellBbox {
  final double xCenter;
  final double yCenter;
  final double width;
  final double height;
  final double confidence;
  const _BarbellBbox({
    required this.xCenter,
    required this.yCenter,
    required this.width,
    required this.height,
    required this.confidence,
  });
}

// ---------------- Painter ----------------

class _SquatOverlayPainter extends CustomPainter {
  _SquatOverlayPainter({
    required this.frame,
    required this.showSkeleton,
    this.showBarbellBox = true,
    this.skeletonColor = Colors.white,
    this.flashIntensity = 0.0,
    this.smoothedLandmarks,
  });

  final _FrameData frame;
  final bool showSkeleton;
  final bool showBarbellBox;
  final Color skeletonColor;
  final double flashIntensity;
  final List<List<double>>? smoothedLandmarks;

  static const double _DRAW_VIS_THRESHOLD = 0.5;

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

    // [v18] Draw the barbell bbox underneath the skeleton so the skeleton
    // and the rep counter remain on top and stay readable. Coordinates are
    // normalized to the frame (0..1), so we just multiply by widget pixel
    // size to get the rectangle. The bbox is in the analyzer's input-space
    // (320x320 letterbox), which after Center+AspectRatio rendering lines
    // up with the visible video region pixel-for-pixel.
    final _BarbellBbox? bbox = frame.barbellBbox;
    if (showBarbellBox && bbox != null) {
      final double left = (bbox.xCenter - bbox.width / 2) * w;
      final double top = (bbox.yCenter - bbox.height / 2) * h;
      final double bw = bbox.width * w;
      final double bh = bbox.height * h;
      final Rect rect = Rect.fromLTWH(left, top, bw, bh);

      // Cyan box with a soft glow so it reads against any gym backdrop.
      final Paint glow = Paint()
        ..color = const Color.fromARGB(80, 0, 240, 200)
        ..strokeWidth = math.max(5.0, h * 0.010)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final Paint stroke = Paint()
        ..color = const Color.fromARGB(255, 0, 240, 200)
        ..strokeWidth = math.max(2.0, h * 0.004)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawRect(rect, glow);
      canvas.drawRect(rect, stroke);

      // Confidence pill in the top-left corner of the box.
      final String confLabel = '${(bbox.confidence * 100).round()}%';
      final double confFontSize = math.max(10.0, h * 0.022);
      final TextPainter confTp = TextPainter(
        text: TextSpan(
          text: confLabel,
          style: TextStyle(
            color: Colors.white,
            fontSize: confFontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      final double padX = 6;
      final double padY = 3;
      final double pillW = confTp.width + 2 * padX;
      final double pillH = confTp.height + 2 * padY;
      // Anchor pill just above the box; if it would clip off the top of the
      // frame, drop it inside the top of the box instead.
      double pillY = top - pillH - 2;
      if (pillY < 0) pillY = top + 2;
      double pillX = left;
      if (pillX + pillW > w) pillX = w - pillW;
      if (pillX < 0) pillX = 0;
      final Paint pillBg = Paint()
        ..color = const Color.fromARGB(220, 0, 180, 150);
      final RRect pillRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(pillX, pillY, pillW, pillH),
        const Radius.circular(4),
      );
      canvas.drawRRect(pillRRect, pillBg);
      confTp.paint(canvas, Offset(pillX + padX, pillY + padY));
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
        if (lm[2] < _DRAW_VIS_THRESHOLD) return null;
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
  bool shouldRepaint(covariant _SquatOverlayPainter old) {
    return old.frame != frame ||
        old.showSkeleton != showSkeleton ||
        old.showBarbellBox != showBarbellBox ||
        old.skeletonColor != skeletonColor ||
        old.flashIntensity != flashIntensity ||
        old.smoothedLandmarks != smoothedLandmarks;
  }
}
