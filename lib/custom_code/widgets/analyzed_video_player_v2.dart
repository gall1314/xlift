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
import 'dart:ui' as ui show TextDirection;
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';

/// Analyzed video player v2.
///
/// Same engine as SquatAnalyzedVideoPlayer (file loading, set-object unwrap,
/// landmark interpolation, pose_reliable, lockout flash, rep sounds +
/// haptics) with a new presentation: - Rep-segmented progress bar: one
/// segment per rep, colored good / bad. Tap a segment to jump to that rep,
/// drag to scrub. - Overlay: "REP n / total" top-left, metric ring top-right,
/// and for the whole span of the current rep segment: GOOD REP / NEEDS WORK
/// pill + that rep's feedback (if any). - Fullscreen button: opens a black
/// full-screen route on the SAME controller (no reload), X to close.
///
/// v2.1: ONE verdict per rep, taken from the telemetry pulse
/// (rep_just_finished), which is what the analyzers count as good_reps /
/// bad_reps. result.reps[i].good is only a fallback when the pulse has no tag
/// (analyzers also store a stricter score-based flag there, which used to
/// make the pill disagree with the summary and the skeleton flash). Rep
/// segments end AFTER the lockout flash, so the flash of rep i is shown while
/// the pill still says rep i.
///
/// Parameter names are compatible with the old widget so it can be swapped in
/// place. New: autoplay, goodColor, badColor, accentColor.
class AnalyzedVideoPlayerV2 extends StatefulWidget {
  const AnalyzedVideoPlayerV2({
    Key? key,
    this.width,
    this.height,
    required this.analysisResult,
    this.showSkeleton = true,
    this.showBarbellBox = false,
    this.videoVolume = 0.25,
    this.lockFeet = false,
    this.autoplay = false,
    this.goodColor,
    this.badColor,
    this.accentColor,
  }) : super(key: key);

  final double? width;
  final double? height;
  final dynamic analysisResult;
  final bool showSkeleton;
  final bool showBarbellBox;
  final double videoVolume;
  final bool lockFeet;
  final bool autoplay;
  final Color? goodColor;
  final Color? badColor;
  final Color? accentColor;

  @override
  State<AnalyzedVideoPlayerV2> createState() => _AnalyzedVideoPlayerV2State();
}

class _RepSegment {
  final double startT;
  final double endT;
  final bool? good; // null = tail / unknown
  final int index; // 1-based rep number, 0 for tail
  final String? feedback; // this rep's feedback (may be multi-line)
  const _RepSegment(this.startT, this.endT, this.good, this.index,
      [this.feedback]);
}

class _AnalyzedVideoPlayerV2State extends State<AnalyzedVideoPlayerV2> {
  VideoPlayerController? _controller;
  String? _errorMessage;
  bool _isReady = false;

  List<_FrameData> _telemetry = [];
  List<_RepSegment> _segments = [];
  // Telemetry index of each lockout pulse, in rep order, and the single
  // verdict per rep that every visual / audio cue uses.
  List<int> _lockoutIdx = [];
  List<bool> _lockoutGood = [];
  int _totalReps = 0;
  double _durationSec = 0;

  double _lastTickProcessedT = -1.0;
  final Set<int> _audioFiredFor = {};
  DateTime _lastHapticAt = DateTime.fromMillisecondsSinceEpoch(0);
  Offset? _lastRenderedHipCentroid;
  bool _fullscreenOpen = false;

  static const double _DRAW_VIS_THRESHOLD = 0.5;

  Color get _good => widget.goodColor ?? const Color(0xFF28DC5A);
  Color get _bad => widget.badColor ?? const Color(0xFFFF9A1E);
  Color get _accent => widget.accentColor ?? const Color(0xFF14B8A6);

  // ---------------- audio ----------------
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
  final List<AudioPlayer> _goodRepPool = [];
  final List<AudioPlayer> _badRepPool = [];
  int _goodPoolIdx = 0;
  int _badPoolIdx = 0;
  static const int _AUDIO_POOL_SIZE = 3;
  DateTime _lastAudioAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _AUDIO_MIN_GAP_MS = 80;

  @override
  void initState() {
    super.initState();
    _init();
  }

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

      final List<dynamic> raw =
          (result['_frame_telemetry'] as List?) ?? const [];
      _telemetry = raw.map((r) => _FrameData.fromMap(r as Map)).toList();

      String path = uri;
      if (path.startsWith('file://')) path = path.substring(7);
      final File file = File(path);
      if (!file.existsSync()) {
        setState(() => _errorMessage = 'Video file not found');
        return;
      }

      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      controller.setLooping(false);
      try {
        await controller.setVolume(widget.videoVolume.clamp(0.0, 1.0));
      } catch (_) {}
      controller.addListener(_onVideoTick);
      _controller = controller;
      _durationSec = controller.value.duration.inMilliseconds / 1000.0;

      _buildSegments(result);
      _preloadAudio();

      if (mounted) setState(() => _isReady = true);
      if (widget.autoplay) await controller.play();
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Init error: $e');
    }
  }

  static String? _feedbackStr(dynamic f) {
    if (f == null) return null;
    if (f is List) {
      final parts =
          f.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
      return parts.isEmpty ? null : parts.join('\n');
    }
    final s = f.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// How long the lockout flash of telemetry frame [flashIdx] is held.
  /// flash_duration_sec when stamped, else half the gap to the next pulse.
  double _holdOf(int flashIdx) {
    final f = _telemetry[flashIdx];
    double d = f.flashDurationSec;
    if (d <= 0) {
      double nextPulseT = double.infinity;
      for (int i = flashIdx + 1; i < _telemetry.length; i++) {
        if (_telemetry[i].repJustFinished != null) {
          nextPulseT = _telemetry[i].t;
          break;
        }
      }
      final double gap = nextPulseT - f.t;
      d = gap.isInfinite ? 0.6 : (gap * 0.5).clamp(0.25, 0.6);
    }
    return d;
  }

  /// Verdict of the rep whose lockout pulse is telemetry frame [flashIdx].
  bool _verdictOfPulse(int flashIdx) {
    final int ord = _lockoutIdx.indexOf(flashIdx);
    if (ord >= 0 && ord < _lockoutGood.length) return _lockoutGood[ord];
    return _telemetry[flashIdx].repJustFinished != 'bad';
  }

  /// One segment per rep: [end of previous flash, lockout + flash hold].
  /// Verdict: the telemetry pulse tag ('good' / 'bad'); result.reps[i].good
  /// only when the tag is something else. Feedback from
  /// result.reps[i].feedback, else the lockout frame's feedback.
  void _buildSegments(Map result) {
    final List<int> lockoutIdx = [];
    for (int i = 0; i < _telemetry.length; i++) {
      if (_telemetry[i].repJustFinished != null) lockoutIdx.add(i);
    }
    final List<dynamic> repsList = (result['reps'] as List?) ?? const [];
    final bool useReps = repsList.length == lockoutIdx.length;

    final segs = <_RepSegment>[];
    final goods = <bool>[];
    double prev = 0.0;
    for (int i = 0; i < lockoutIdx.length; i++) {
      final f = _telemetry[lockoutIdx[i]];
      final String tag = (f.repJustFinished ?? '').toLowerCase();
      bool good = tag != 'bad';
      String? fb;
      if (useReps && repsList[i] is Map) {
        final m = repsList[i] as Map;
        if (tag != 'good' && tag != 'bad') {
          final g = m['good'];
          if (g is bool) good = g;
        }
        fb = _feedbackStr(m['feedback']) ?? _feedbackStr(m['f']);
      }
      fb ??= _feedbackStr(f.feedback);

      // The segment ends after the flash, so the flash belongs to this rep.
      double end = f.t + _holdOf(lockoutIdx[i]);
      if (_durationSec > 0) end = math.min(end, _durationSec);
      if (end <= prev) end = prev + 0.01;

      segs.add(_RepSegment(prev, end, good, i + 1, fb));
      goods.add(good);
      prev = end;
    }
    final double end = _durationSec > 0 ? _durationSec : prev;
    if (end > prev + 0.05) segs.add(_RepSegment(prev, end, null, 0));
    _segments = segs;
    _lockoutIdx = lockoutIdx;
    _lockoutGood = goods;
    _totalReps = lockoutIdx.length;
  }

  _RepSegment? _segmentAt(double tSec) {
    for (final s in _segments) {
      if (tSec >= s.startT && tSec < s.endT) return s;
    }
    return _segments.isNotEmpty && tSec >= _segments.last.startT
        ? _segments.last
        : null;
  }

  // ---------------- tick: audio + haptics only (painting is driven by
  // AnimatedBuilder on the controller) ----------------
  void _onVideoTick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final double tSec = controller.value.position.inMilliseconds / 1000.0;

    if (_lastTickProcessedT < 0 || tSec < _lastTickProcessedT) {
      _lastTickProcessedT = tSec;
      _audioFiredFor.clear();
      _footRemembered.clear();
      return;
    }
    if (!controller.value.isPlaying) {
      _lastTickProcessedT = tSec;
      return;
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
      if (f.repJustFinished == null || _audioFiredFor.contains(i)) continue;
      _audioFiredFor.add(i);
      final now = DateTime.now();
      final canHaptic = now.difference(_lastHapticAt).inMilliseconds >= 80;
      if (_verdictOfPulse(i)) {
        if (canHaptic) {
          _lastHapticAt = now;
          HapticFeedback.mediumImpact();
        }
        _playRepSound(true);
      } else {
        if (canHaptic) {
          _lastHapticAt = now;
          HapticFeedback.lightImpact();
          Future.delayed(const Duration(milliseconds: 90),
              () => HapticFeedback.lightImpact());
        }
        _playRepSound(false);
      }
    }
    _lastTickProcessedT = tSec;
  }

  Future<void> _preloadAudio() async {
    Future<void> fill(List<String> candidates, List<AudioPlayer> pool) async {
      for (final path in candidates) {
        try {
          final probe = AudioPlayer();
          await probe.setSource(AssetSource(path));
          await probe.dispose();
          for (int i = 0; i < _AUDIO_POOL_SIZE; i++) {
            final p = AudioPlayer();
            await p.setSource(AssetSource(path));
            await p.setVolume(1.0);
            await p.setReleaseMode(ReleaseMode.stop);
            pool.add(p);
          }
          return;
        } catch (_) {}
      }
    }

    await fill(_GOOD_REP_CANDIDATES, _goodRepPool);
    await fill(_BAD_REP_CANDIDATES, _badRepPool);
  }

  void _playRepSound(bool good) {
    final pool = good ? _goodRepPool : _badRepPool;
    if (pool.isEmpty) return;
    final now = DateTime.now();
    if (now.difference(_lastAudioAt).inMilliseconds < _AUDIO_MIN_GAP_MS) return;
    _lastAudioAt = now;
    try {
      final int idx = good ? _goodPoolIdx : _badPoolIdx;
      final player = pool[idx % pool.length];
      if (good) {
        _goodPoolIdx = (_goodPoolIdx + 1) % pool.length;
      } else {
        _badPoolIdx = (_badPoolIdx + 1) % pool.length;
      }
      player.seek(Duration.zero);
      player.resume();
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
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

  // ---------------- telemetry helpers ----------------
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
        if (math.sqrt(dx * dx + dy * dy) > 0.25) return const [];
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
    return List.generate(n, (i) {
      final la = a.landmarks[i];
      final lb = b.landmarks[i];
      if (la.length < 3 || lb.length < 3) return [0.0, 0.0, 0.0];
      final double va = la[2];
      final double vb = lb[2];
      if (widget.lockFeet && _FOOT_INDICES.contains(i)) {
        if (va < _FOOT_FALLBACK_THRESHOLD && vb < _FOOT_FALLBACK_THRESHOLD) {
          final remembered = _footRemembered[i];
          if (remembered != null) return [remembered[0], remembered[1], 1.0];
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
  }

  /// Flash state at tSec: (color, intensity, isGood) or null.
  ({Color color, double intensity, bool good})? _flashAt(double tSec) {
    final tele = _telemetry;
    if (tele.isEmpty) return null;
    int lo = 0, hi = tele.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (tele[mid].t <= tSec) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    _FrameData? flashFrame;
    int flashIdx = -1;
    for (int i = lo - 1; i >= 0 && i >= lo - 50; i--) {
      if (tele[i].repJustFinished != null) {
        flashFrame = tele[i];
        flashIdx = i;
        break;
      }
    }
    if (flashFrame == null) return null;
    final double durationSec = _holdOf(flashIdx);
    final double age = tSec - flashFrame.t;
    if (age < 0 || age > durationSec) return null;
    final bool good = _verdictOfPulse(flashIdx);
    return (
      color: good ? _good : _bad,
      intensity: 1.0 - (age / durationSec),
      good: good
    );
  }

  // ---------------- playback controls ----------------
  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    HapticFeedback.selectionClick();
    if (c.value.isPlaying) {
      c.pause();
    } else {
      if (c.value.position >= c.value.duration) {
        c.seekTo(Duration.zero);
        _lastTickProcessedT = 0.0;
      }
      c.play();
    }
  }

  void _seekToFraction(double f) {
    final c = _controller;
    if (c == null || _durationSec <= 0) return;
    final double t = (f.clamp(0.0, 1.0)) * _durationSec;
    c.seekTo(Duration(milliseconds: (t * 1000).round()));
    _lastTickProcessedT = t; // don't replay sounds for skipped reps
  }

  void _jumpToSegment(_RepSegment s) {
    HapticFeedback.selectionClick();
    final double t = s.startT + 0.05;
    _controller?.seekTo(Duration(milliseconds: (t * 1000).round()));
    _lastTickProcessedT = t;
    _audioFiredFor.clear();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ---------------- fullscreen ----------------
  void _openFullscreen() {
    if (_fullscreenOpen || _controller == null) return;
    _fullscreenOpen = true;
    HapticFeedback.selectionClick();
    Navigator.of(context, rootNavigator: true)
        .push(PageRouteBuilder(
          opaque: true,
          barrierColor: Colors.black,
          transitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (ctx, a, b) => Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(child: _surface(fullscreen: true)),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Material(
                      color: Colors.black.withOpacity(0.45),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(ctx).pop(),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.close_rounded,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          transitionsBuilder: (ctx, anim, sec, child) =>
              FadeTransition(opacity: anim, child: child),
        ))
        .whenComplete(() => _fullscreenOpen = false);
  }

  // ---------------- UI ----------------
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
            child: Text(_errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center),
          ),
        ),
      );
    }
    if (!_isReady || _controller == null) {
      return SizedBox(
        width: w,
        height: h,
        child: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    return SizedBox(
      width: w,
      height: h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _surface(fullscreen: false),
      ),
    );
  }

  /// Video + overlay + controls. Shared by inline and fullscreen.
  Widget _surface({required bool fullscreen}) {
    final controller = _controller!;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final double tSec = controller.value.position.inMilliseconds / 1000.0;
        final _FrameData? frame = _frameAtTime(tSec);
        final bool isPlaying = controller.value.isPlaying;
        final flash = _flashAt(tSec);
        final _RepSegment? seg = _segmentAt(tSec);

        List<List<double>> lms = _interpolatedLandmarksAt(tSec);
        if (lms.length >= 25) {
          final hipX = (lms[23][0] + lms[24][0]) / 2;
          final hipY = (lms[23][1] + lms[24][1]) / 2;
          final hipVis = (lms[23][2] + lms[24][2]) / 2;
          if (hipVis > 0.4) {
            if (_lastRenderedHipCentroid != null) {
              final dx = hipX - _lastRenderedHipCentroid!.dx;
              final dy = hipY - _lastRenderedHipCentroid!.dy;
              if (math.sqrt(dx * dx + dy * dy) > 0.20) {
                lms = const [];
              } else {
                _lastRenderedHipCentroid = Offset(hipX, hipY);
              }
            } else {
              _lastRenderedHipCentroid = Offset(hipX, hipY);
            }
          }
        }

        final double progress =
            _durationSec > 0 ? (tSec / _durationSec).clamp(0.0, 1.0) : 0.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _togglePlay,
              child: Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      VideoPlayer(controller),
                      if (frame != null)
                        CustomPaint(
                          painter: _OverlayPainterV2(
                            frame: frame,
                            totalReps: _totalReps,
                            showSkeleton: widget.showSkeleton,
                            showBarbellBox: widget.showBarbellBox,
                            landmarks: lms,
                            flashColor: flash?.color,
                            flashIntensity: flash?.intensity ?? 0.0,
                            segGood: seg?.good,
                            segFeedback: seg?.feedback,
                            goodColor: _good,
                            badColor: _bad,
                            accent: _accent,
                          ),
                        ),
                      if (!isPlaying)
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 40),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Controls
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(10, 18, 10, fullscreen ? 14 : 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SegmentBar(
                        segments: _segments,
                        durationSec: _durationSec,
                        progress: progress,
                        goodColor: _good,
                        badColor: _bad,
                        onSeekFraction: _seekToFraction,
                        onTapSegment: _jumpToSegment,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${_fmt(controller.value.position)} / ${_fmt(controller.value.duration)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (!fullscreen) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _openFullscreen,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.fullscreen_rounded,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------- Segmented progress bar ----------------

class _SegmentBar extends StatelessWidget {
  const _SegmentBar({
    required this.segments,
    required this.durationSec,
    required this.progress,
    required this.goodColor,
    required this.badColor,
    required this.onSeekFraction,
    required this.onTapSegment,
  });

  final List<_RepSegment> segments;
  final double durationSec;
  final double progress;
  final Color goodColor;
  final Color badColor;
  final void Function(double fraction) onSeekFraction;
  final void Function(_RepSegment seg) onTapSegment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final double w = c.maxWidth;
      double fracOf(Offset local) => (local.dx / w).clamp(0.0, 1.0);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          final f = fracOf(d.localPosition);
          final t = f * durationSec;
          for (final s in segments) {
            if (t >= s.startT && t < s.endT && s.index > 0) {
              onTapSegment(s);
              return;
            }
          }
          onSeekFraction(f);
        },
        onHorizontalDragUpdate: (d) => onSeekFraction(fracOf(d.localPosition)),
        child: SizedBox(
          height: 28,
          child: CustomPaint(
            painter: _SegmentBarPainter(
              segments: segments,
              durationSec: durationSec,
              progress: progress,
              goodColor: goodColor,
              badColor: badColor,
            ),
          ),
        ),
      );
    });
  }
}

class _SegmentBarPainter extends CustomPainter {
  _SegmentBarPainter({
    required this.segments,
    required this.durationSec,
    required this.progress,
    required this.goodColor,
    required this.badColor,
  });

  final List<_RepSegment> segments;
  final double durationSec;
  final double progress;
  final Color goodColor;
  final Color badColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = 6;
    final double y = (size.height - h) / 2;
    const double gap = 3;
    final double playedX = progress * w;

    if (segments.isEmpty || durationSec <= 0) {
      final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, y, w, h), const Radius.circular(3));
      canvas.drawRRect(r, Paint()..color = Colors.white24);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(0, y, playedX, h), const Radius.circular(3)),
          Paint()..color = Colors.white);
      return;
    }

    for (final s in segments) {
      double x0 = (s.startT / durationSec) * w;
      double x1 = (s.endT / durationSec) * w;
      if (s != segments.first) x0 += gap / 2;
      if (s != segments.last) x1 -= gap / 2;
      if (x1 <= x0) continue;
      final Color base =
          s.good == null ? Colors.white : (s.good! ? goodColor : badColor);
      final RRect rr = RRect.fromRectAndRadius(
          Rect.fromLTWH(x0, y, x1 - x0, h), const Radius.circular(3));
      // Unplayed = dim; played = full color.
      canvas.drawRRect(rr, Paint()..color = base.withOpacity(0.28));
      if (playedX > x0) {
        final double px1 = math.min(playedX, x1);
        canvas.save();
        canvas.clipRRect(rr);
        canvas.drawRect(Rect.fromLTWH(x0, y, px1 - x0, h),
            Paint()..color = base.withOpacity(s.good == null ? 0.9 : 1.0));
        canvas.restore();
      }
    }

    // Playhead knob
    canvas.drawCircle(Offset(playedX, y + h / 2), 6,
        Paint()..color = Colors.black.withOpacity(0.35));
    canvas.drawCircle(
        Offset(playedX, y + h / 2), 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _SegmentBarPainter old) =>
      old.progress != progress ||
      old.segments != segments ||
      old.durationSec != durationSec;
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
  final double flashDurationSec;
  final bool poseReliable;
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
    _BarbellBbox? bbox;
    final rawBbox = m['barbell_bbox'];
    if (rawBbox is Map) {
      final xc = (rawBbox['x_center'] as num?)?.toDouble();
      final yc = (rawBbox['y_center'] as num?)?.toDouble();
      final bw = (rawBbox['width'] as num?)?.toDouble();
      final bh = (rawBbox['height'] as num?)?.toDouble();
      if (xc != null && yc != null && bw != null && bh != null) {
        bbox = _BarbellBbox(xc, yc, bw, bh);
      }
    }
    return _FrameData(
      t: (m['t'] as num?)?.toDouble() ?? 0.0,
      reps: (m['reps'] as num?)?.toInt() ?? 0,
      metricValue: mv,
      metricLabel: (m['metric_label'] as String?) ?? 'DEPTH',
      feedback: m['feedback'] as String?,
      repJustFinished: m['rep_just_finished']?.toString(),
      landmarks: lm,
      flashDurationSec: (m['flash_duration_sec'] as num?)?.toDouble() ?? 0.0,
      poseReliable: (m['pose_reliable'] as bool?) ?? true,
      barbellBbox: bbox,
    );
  }
}

class _BarbellBbox {
  final double xCenter, yCenter, width, height;
  const _BarbellBbox(this.xCenter, this.yCenter, this.width, this.height);
}

// ---------------- Overlay painter (v2 design) ----------------

class _OverlayPainterV2 extends CustomPainter {
  _OverlayPainterV2({
    required this.frame,
    required this.totalReps,
    required this.showSkeleton,
    required this.showBarbellBox,
    required this.landmarks,
    required this.flashColor,
    required this.flashIntensity,
    required this.segGood,
    required this.segFeedback,
    required this.goodColor,
    required this.badColor,
    required this.accent,
  });

  final _FrameData frame;
  final int totalReps;
  final bool showSkeleton;
  final bool showBarbellBox;
  final List<List<double>> landmarks;
  final Color? flashColor;
  final double flashIntensity;
  final bool? segGood; // verdict of the current rep segment (null = tail)
  final String? segFeedback; // feedback of the current rep segment
  final Color goodColor;
  final Color badColor;
  final Color accent;

  static const double _VIS = 0.5;
  static const List<List<int>> _connections = [
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
  static const List<int> _dots = [
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

  TextPainter _tp(String text, double size, FontWeight weight, Color color,
      {double? maxWidth, double letterSpacing = 0, int maxLines = 2}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: letterSpacing,
          height: 1.15,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    );
    tp.layout(maxWidth: maxWidth ?? double.infinity);
    return tp;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double pad = math.max(10.0, w * 0.035);

    // --- barbell bbox (test analyzers only) ---
    final bb = frame.barbellBbox;
    if (showBarbellBox && bb != null) {
      final rect = Rect.fromLTWH((bb.xCenter - bb.width / 2) * w,
          (bb.yCenter - bb.height / 2) * h, bb.width * w, bb.height * h);
      canvas.drawRect(
          rect,
          Paint()
            ..color = const Color(0xFF00F0C8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }

    // --- skeleton ---
    final Color skel = flashColor == null
        ? Colors.white
        : Color.lerp(Colors.white, flashColor!, flashIntensity.clamp(0, 1))!;
    if (showSkeleton && landmarks.length >= 33) {
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
        if (i >= landmarks.length) return null;
        final l = landmarks[i];
        if (l.length < 3 || l[2] < _VIS) return null;
        return Offset(l[0] * w, l[1] * h);
      }

      for (final c in _connections) {
        final a = pt(c[0]), b = pt(c[1]);
        if (a != null && b != null) {
          if (flashIntensity > 0) canvas.drawLine(a, b, glow);
          canvas.drawLine(a, b, line);
        }
      }
      for (final i in _dots) {
        final p = pt(i);
        if (p != null) canvas.drawCircle(p, r, dot);
      }
    }

    // --- REP counter (top-left) ---
    final double labelSize = math.max(9.0, h * 0.022);
    final double numSize = math.max(22.0, h * 0.075);
    final double totalSize = math.max(12.0, h * 0.032);
    final label = _tp(
        'REP', labelSize, FontWeight.w700, Colors.white.withOpacity(0.85),
        letterSpacing: 1.5);
    final num = _tp('${frame.reps}', numSize, FontWeight.w800, Colors.white);
    final tot = _tp(totalReps > 0 ? ' / $totalReps' : '', totalSize,
        FontWeight.w600, Colors.white.withOpacity(0.75));
    final double boxW =
        math.max(label.width, num.width + tot.width) + pad * 1.6;
    final double boxH = label.height + 4 + num.height + pad * 1.2;
    final RRect box = RRect.fromRectAndRadius(
        Rect.fromLTWH(pad, pad, boxW, boxH), const Radius.circular(12));
    canvas.drawRRect(box, Paint()..color = Colors.black.withOpacity(0.45));
    label.paint(canvas, Offset(pad + pad * 0.8, pad + pad * 0.6));
    final double numY = pad + pad * 0.6 + label.height + 4;
    num.paint(canvas, Offset(pad + pad * 0.8, numY));
    tot.paint(
        canvas,
        Offset(
            pad + pad * 0.8 + num.width, numY + num.height - tot.height - 2));

    // --- metric ring (top-right) ---
    final double radius = math.max(22.0, h * 0.055);
    final double thick = math.max(3.5, radius * 0.18);
    final double cx = w - pad - radius;
    final double cy = pad + radius;
    canvas.drawCircle(Offset(cx, cy), radius + thick,
        Paint()..color = Colors.black.withOpacity(0.35));
    canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..color = Colors.white.withOpacity(0.18)
          ..strokeWidth = thick
          ..style = PaintingStyle.stroke);
    final double pct = frame.metricValue.clamp(0.0, 1.0);
    if (pct > 0) {
      canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius),
          -math.pi / 2,
          2 * math.pi * pct,
          false,
          Paint()
            ..color = goodColor
            ..strokeWidth = thick
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke);
    }
    final rl = _tp(frame.metricLabel, math.max(7.5, radius * 0.26),
        FontWeight.w700, Colors.white.withOpacity(0.85),
        letterSpacing: 0.8);
    final rp = _tp('${(pct * 100).round()}%', math.max(11.0, radius * 0.42),
        FontWeight.w800, Colors.white);
    final double th = rl.height + 2 + rp.height;
    rl.paint(canvas, Offset(cx - rl.width / 2, cy - th / 2));
    rp.paint(canvas, Offset(cx - rp.width / 2, cy - th / 2 + rl.height + 2));

    // --- bottom: verdict pill + feedback, for the whole rep segment ---
    // In a rep segment: pill always, feedback if the rep has any.
    // In the tail (no segment): no pill, frame feedback if any.
    final bool showPill = segGood != null;
    final String? fbRaw = segGood != null ? segFeedback : frame.feedback;
    final String fb = (fbRaw ?? '').trim();
    final bool hasFb = fb.isNotEmpty;
    if (showPill || hasFb) {
      final double bottomSafe = math.max(44.0, h * 0.12); // above controls
      double y = h - bottomSafe;
      if (hasFb) {
        final double fbSize = math.max(12.0, h * 0.028);
        final fbTp = _tp(fb, fbSize, FontWeight.w700, Colors.white,
            maxWidth: w - pad * 2, maxLines: 3);
        y -= fbTp.height;
        final shadow = _tp(
            fb, fbSize, FontWeight.w700, Colors.black.withOpacity(0.6),
            maxWidth: w - pad * 2, maxLines: 3);
        shadow.paint(canvas, Offset(pad + 1, y + 1));
        fbTp.paint(canvas, Offset(pad, y));
        y -= 8;
      }
      if (showPill) {
        final bool g = segGood!;
        final pillTp = _tp(g ? 'GOOD REP' : 'NEEDS WORK',
            math.max(10.0, h * 0.024), FontWeight.w800, Colors.white,
            letterSpacing: 1.0);
        final double pw = pillTp.width + 20, ph = pillTp.height + 10;
        y -= ph;
        final RRect pill = RRect.fromRectAndRadius(
            Rect.fromLTWH(pad, y, pw, ph), Radius.circular(ph / 2));
        canvas.drawRRect(
            pill,
            Paint()
              ..color = (g ? goodColor : badColor)
                  .withOpacity(0.78 + 0.22 * flashIntensity.clamp(0, 1)));
        pillTp.paint(canvas, Offset(pad + 10, y + 5));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainterV2 old) =>
      old.frame != frame ||
      old.landmarks != landmarks ||
      old.flashColor != flashColor ||
      old.flashIntensity != flashIntensity ||
      old.segGood != segGood ||
      old.segFeedback != segFeedback ||
      old.totalReps != totalReps;
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
