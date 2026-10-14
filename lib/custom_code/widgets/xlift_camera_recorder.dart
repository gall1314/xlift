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

// ============================================================================
// XliftCameraRecorder  —  FlutterFlow Custom Widget
// ----------------------------------------------------------------------------
// v7 — Calm redesign (built on the v5 camera logic, which is unchanged):
//   * Clean camera: thin rule-of-thirds grid + large corner frame, one hint
//     line, native-style controls. No scan line, glow or ghost figure.
//   * Setup tips are a centered card with a small animated figure of the
//     actual exercise (20 supported exercises, matched by name).
//   * Full bleed: the widget paints over the whole screen egven if the host
//     page keeps its safe area.
//   * Gallery button, ".5x | 1x" lens pill, REC timer.
//
// Camera behaviour kept from v2-v5: permission overlay, wakelock, gallery
// upload, native-camera-like lifecycle (inactive = ignore, paused = stop and
// keep the clip, deliver on resume), hidden status bar, guarded stop.
//
// ----------------------------------------------------------------------------
// FlutterFlow setup
// ----------------------------------------------------------------------------
// 1) Pubspec Dependencies:
//        camera: ^0.11.0
//        permission_handler: ^11.3.1
//        wakelock_plus: ^1.2.8
//        image_picker: ^1.1.2
//
// 2) iOS Info.plist:
//        NSCameraUsageDescription = "Record video to analyze exercise form"
//        NSPhotoLibraryUsageDescription = "Pick a video to analyze exercise form"
//
// 3) Custom Widget parameters:
//        width / height   : double (set both to Infinite)
//        exerciseName     : String  (optional) picks the animation + tips
//        showGuidance     : Boolean (optional, default true) show tips first
//        onVideoRecorded  : Action with Callback Parameter
//                           name = videoFile, type = Uploaded File
//        onClose          : Action (no parameters)
//        onDontShowAgain  : Action (no parameters)
// ============================================================================

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui; // Flutter's TextDirection (avoids the intl collision)
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class XliftCameraRecorder extends StatefulWidget {
  const XliftCameraRecorder({
    super.key,
    this.width,
    this.height,
    this.exerciseName,
    this.showGuidance,
    this.onVideoRecorded,
    this.onClose,
    this.onDontShowAgain,
  });

  final double? width;
  final double? height;

  /// Exercise name, used for the title, the animation and the tips.
  final String? exerciseName;

  /// Show the setup tips when the camera opens. Default true.
  final bool? showGuidance;

  /// Called with the recorded (or picked) file.
  final Future Function(FFUploadedFile videoFile)? onVideoRecorded;

  /// Called when the user taps the camera's close (X) button.
  final Future Function()? onClose;

  /// Called when the user taps "Don't show this again" on the tips card.
  final Future Function()? onDontShowAgain;

  @override
  State<XliftCameraRecorder> createState() => _XliftCameraRecorderState();
}

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------

const Color _kTeal = Color(0xFF14B8A6);
const Color _kRed = Color(0xFFF0453F);
const Color _kCard = Color(0xFF181B1E);

// ---------------------------------------------------------------------------
// Exercise animations (side view, figure faces right, unit square, y down)
// ---------------------------------------------------------------------------

enum _Ex {
  bodySquat,
  backSquat,
  frontSquat,
  gobletSquat,
  sumoSquat,
  zercherSquat,
  bulgarian,
  pushup,
  inclinePushup,
  dips,
  pullup,
  curl,
  deadlift,
  rdl,
  goodMorning,
  press,
}

_Ex _exOf(String? name) {
  final String n = (name ?? '').toLowerCase();
  if (n.contains('bulgarian')) return _Ex.bulgarian;
  if (n.contains('incline') && n.contains('push')) return _Ex.inclinePushup;
  if (n.contains('push-up') || n.contains('push up') || n.contains('pushup')) {
    return _Ex.pushup;
  }
  if (n.contains('dip')) return _Ex.dips;
  if (n.contains('pull-up') ||
      n.contains('pull up') ||
      n.contains('pullup') ||
      n.contains('chin')) {
    return _Ex.pullup;
  }
  if (n.contains('curl')) return _Ex.curl;
  if (n.contains('romanian') || n.contains('stiff') || n.contains('rdl')) {
    return _Ex.rdl;
  }
  if (n.contains('good morning')) return _Ex.goodMorning;
  if (n.contains('deadlift')) return _Ex.deadlift; // incl. sumo, trap bar
  if (n.contains('military') ||
      n.contains('overhead press') ||
      n.contains('shoulder press')) {
    return _Ex.press;
  }
  if (n.contains('front squat')) return _Ex.frontSquat;
  if (n.contains('goblet')) return _Ex.gobletSquat;
  if (n.contains('zercher')) return _Ex.zercherSquat;
  if (n.contains('sumo')) return _Ex.sumoSquat;
  if (n.contains('back squat') || n.contains('smith')) return _Ex.backSquat;
  return _Ex.bodySquat;
}

enum _Prop { none, barWrist, barBack, barFront, barElbow, weightWrist }

enum _Fixture { none, pullBar, dipBars, bench, box }

class _Pose {
  const _Pose({
    required this.head,
    required this.sh,
    required this.elbow,
    required this.wrist,
    required this.hip,
    required this.knee,
    required this.ankle,
    required this.toe,
    this.knee2,
    this.ankle2,
  });

  final Offset head, sh, elbow, wrist, hip, knee, ankle, toe;
  final Offset? knee2, ankle2; // rear leg (only when it is visible)

  static Offset _l(Offset a, Offset b, double t) =>
      Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);

  static _Pose lerp(_Pose a, _Pose b, double t) => _Pose(
        head: _l(a.head, b.head, t),
        sh: _l(a.sh, b.sh, t),
        elbow: _l(a.elbow, b.elbow, t),
        wrist: _l(a.wrist, b.wrist, t),
        hip: _l(a.hip, b.hip, t),
        knee: _l(a.knee, b.knee, t),
        ankle: _l(a.ankle, b.ankle, t),
        toe: _l(a.toe, b.toe, t),
        knee2: (a.knee2 != null && b.knee2 != null)
            ? _l(a.knee2!, b.knee2!, t)
            : null,
        ankle2: (a.ankle2 != null && b.ankle2 != null)
            ? _l(a.ankle2!, b.ankle2!, t)
            : null,
      );
}

class _ExAnim {
  const _ExAnim(this.a, this.b,
      {this.prop = _Prop.none, this.fixture = _Fixture.none});
  final _Pose a, b;
  final _Prop prop;
  final _Fixture fixture;
}

// Body "cores": head, shoulder, hip, knee, ankle, toe as x,y pairs.
const List<double> _cStand = [
  0.50, 0.15, 0.50, 0.27, 0.49, 0.55, 0.50, 0.75, 0.49, 0.93, 0.57, 0.94 //
];
const List<double> _cSquat = [
  0.55, 0.36, 0.51, 0.47, 0.39, 0.72, 0.58, 0.74, 0.50, 0.93, 0.58, 0.94 //
];
const List<double> _cHinge = [
  0.70, 0.42, 0.62, 0.46, 0.42, 0.56, 0.48, 0.75, 0.49, 0.93, 0.57, 0.94 //
];
const List<double> _cDeadlift = [
  0.66, 0.43, 0.60, 0.53, 0.40, 0.66, 0.54, 0.77, 0.49, 0.93, 0.57, 0.94 //
];

/// Builds a pose from a core plus arm offsets relative to the shoulder.
_Pose _mk(List<double> c, Offset eOff, Offset wOff) {
  final Offset sh = Offset(c[2], c[3]);
  return _Pose(
    head: Offset(c[0], c[1]),
    sh: sh,
    elbow: sh + eOff,
    wrist: sh + wOff,
    hip: Offset(c[4], c[5]),
    knee: Offset(c[6], c[7]),
    ankle: Offset(c[8], c[9]),
    toe: Offset(c[10], c[11]),
  );
}

_ExAnim _squatAnim(
        Offset eTop, Offset wTop, Offset eBot, Offset wBot, _Prop prop) =>
    _ExAnim(_mk(_cStand, eTop, wTop), _mk(_cSquat, eBot, wBot), prop: prop);

_ExAnim _animOf(_Ex ex) {
  switch (ex) {
    case _Ex.bodySquat:
      return _squatAnim(const Offset(0.02, 0.13), const Offset(0.05, 0.25),
          const Offset(0.10, 0.03), const Offset(0.21, 0.00), _Prop.none);
    case _Ex.backSquat:
      return _squatAnim(const Offset(-0.04, 0.10), const Offset(-0.03, 0.01),
          const Offset(-0.04, 0.10), const Offset(-0.03, 0.01), _Prop.barBack);
    case _Ex.frontSquat:
      return _squatAnim(const Offset(0.08, 0.03), const Offset(0.03, -0.02),
          const Offset(0.08, 0.03), const Offset(0.03, -0.02), _Prop.barFront);
    case _Ex.gobletSquat:
      return _squatAnim(
          const Offset(0.03, 0.13),
          const Offset(0.05, 0.04),
          const Offset(0.03, 0.13),
          const Offset(0.05, 0.04),
          _Prop.weightWrist);
    case _Ex.sumoSquat:
      return _squatAnim(
          const Offset(0.01, 0.14),
          const Offset(0.02, 0.27),
          const Offset(0.01, 0.14),
          const Offset(0.02, 0.27),
          _Prop.weightWrist);
    case _Ex.zercherSquat:
      return _squatAnim(const Offset(0.05, 0.15), const Offset(0.07, 0.06),
          const Offset(0.05, 0.15), const Offset(0.07, 0.06), _Prop.barElbow);
    case _Ex.deadlift:
      return _ExAnim(
        _mk(_cStand, const Offset(0.01, 0.15), const Offset(0.02, 0.29)),
        _mk(_cDeadlift, const Offset(-0.01, 0.15), const Offset(-0.02, 0.30)),
        prop: _Prop.barWrist,
      );
    case _Ex.rdl:
      return _ExAnim(
        _mk(_cStand, const Offset(0.01, 0.15), const Offset(0.02, 0.29)),
        _mk(_cHinge, const Offset(-0.01, 0.14), const Offset(-0.02, 0.28)),
        prop: _Prop.barWrist,
      );
    case _Ex.goodMorning:
      return _ExAnim(
        _mk(_cStand, const Offset(-0.04, 0.10), const Offset(-0.03, 0.01)),
        _mk(_cHinge, const Offset(-0.04, 0.10), const Offset(-0.03, 0.01)),
        prop: _Prop.barBack,
      );
    case _Ex.curl:
      return _ExAnim(
        _mk(_cStand, const Offset(0.00, 0.14), const Offset(0.03, 0.28)),
        _mk(_cStand, const Offset(0.01, 0.14), const Offset(0.08, 0.03)),
        prop: _Prop.barWrist,
      );
    case _Ex.press:
      return _ExAnim(
        _mk(_cStand, const Offset(0.05, 0.11), const Offset(0.04, -0.01)),
        _mk(_cStand, const Offset(0.02, -0.13), const Offset(0.01, -0.25)),
        prop: _Prop.barWrist,
      );
    case _Ex.pullup:
      return const _ExAnim(
        _Pose(
          head: Offset(0.51, 0.32),
          sh: Offset(0.50, 0.43),
          elbow: Offset(0.50, 0.30),
          wrist: Offset(0.50, 0.17),
          hip: Offset(0.50, 0.68),
          knee: Offset(0.52, 0.82),
          ankle: Offset(0.42, 0.90),
          toe: Offset(0.40, 0.95),
        ),
        _Pose(
          head: Offset(0.46, 0.12),
          sh: Offset(0.48, 0.25),
          elbow: Offset(0.53, 0.36),
          wrist: Offset(0.50, 0.17),
          hip: Offset(0.49, 0.50),
          knee: Offset(0.51, 0.64),
          ankle: Offset(0.41, 0.72),
          toe: Offset(0.39, 0.77),
        ),
        fixture: _Fixture.pullBar,
      );
    case _Ex.dips:
      return const _ExAnim(
        _Pose(
          head: Offset(0.52, 0.13),
          sh: Offset(0.50, 0.25),
          elbow: Offset(0.50, 0.38),
          wrist: Offset(0.50, 0.50),
          hip: Offset(0.48, 0.52),
          knee: Offset(0.50, 0.70),
          ankle: Offset(0.40, 0.78),
          toe: Offset(0.38, 0.83),
        ),
        _Pose(
          head: Offset(0.60, 0.30),
          sh: Offset(0.55, 0.41),
          elbow: Offset(0.42, 0.38),
          wrist: Offset(0.50, 0.50),
          hip: Offset(0.48, 0.66),
          knee: Offset(0.50, 0.82),
          ankle: Offset(0.40, 0.88),
          toe: Offset(0.38, 0.93),
        ),
        fixture: _Fixture.dipBars,
      );
    case _Ex.pushup:
      return const _ExAnim(
        _Pose(
          head: Offset(0.78, 0.62),
          sh: Offset(0.68, 0.67),
          elbow: Offset(0.68, 0.80),
          wrist: Offset(0.68, 0.93),
          hip: Offset(0.44, 0.78),
          knee: Offset(0.30, 0.86),
          ankle: Offset(0.18, 0.91),
          toe: Offset(0.16, 0.95),
        ),
        _Pose(
          head: Offset(0.78, 0.82),
          sh: Offset(0.68, 0.85),
          elbow: Offset(0.58, 0.80),
          wrist: Offset(0.68, 0.93),
          hip: Offset(0.44, 0.88),
          knee: Offset(0.30, 0.90),
          ankle: Offset(0.18, 0.92),
          toe: Offset(0.16, 0.95),
        ),
      );
    case _Ex.inclinePushup:
      return const _ExAnim(
        _Pose(
          head: Offset(0.72, 0.38),
          sh: Offset(0.64, 0.45),
          elbow: Offset(0.65, 0.58),
          wrist: Offset(0.66, 0.70),
          hip: Offset(0.42, 0.66),
          knee: Offset(0.30, 0.79),
          ankle: Offset(0.18, 0.91),
          toe: Offset(0.16, 0.95),
        ),
        _Pose(
          head: Offset(0.71, 0.57),
          sh: Offset(0.63, 0.62),
          elbow: Offset(0.55, 0.60),
          wrist: Offset(0.66, 0.70),
          hip: Offset(0.42, 0.76),
          knee: Offset(0.30, 0.84),
          ankle: Offset(0.18, 0.92),
          toe: Offset(0.16, 0.95),
        ),
        fixture: _Fixture.box,
      );
    case _Ex.bulgarian:
      return const _ExAnim(
        _Pose(
          head: Offset(0.48, 0.13),
          sh: Offset(0.47, 0.25),
          elbow: Offset(0.47, 0.39),
          wrist: Offset(0.48, 0.52),
          hip: Offset(0.46, 0.52),
          knee: Offset(0.56, 0.73),
          ankle: Offset(0.56, 0.93),
          toe: Offset(0.64, 0.94),
          knee2: Offset(0.36, 0.74),
          ankle2: Offset(0.25, 0.69),
        ),
        _Pose(
          head: Offset(0.49, 0.29),
          sh: Offset(0.47, 0.41),
          elbow: Offset(0.47, 0.55),
          wrist: Offset(0.48, 0.68),
          hip: Offset(0.44, 0.68),
          knee: Offset(0.62, 0.72),
          ankle: Offset(0.56, 0.93),
          toe: Offset(0.64, 0.94),
          knee2: Offset(0.36, 0.88),
          ankle2: Offset(0.25, 0.70),
        ),
        fixture: _Fixture.bench,
      );
  }
}

// ---------------------------------------------------------------------------
// Tips
// ---------------------------------------------------------------------------

class _Tip {
  const _Tip(this.icon, this.title, this.sub);
  final IconData icon;
  final String title, sub;
}

List<_Tip> _tipsOf(_Ex ex) {
  final _Tip angle;
  if (ex == _Ex.pullup) {
    angle = const _Tip(Icons.swap_horiz_rounded, 'Film from the side or front',
        'Both angles work for pull-ups.');
  } else if (ex == _Ex.press) {
    angle = const _Tip(Icons.swap_horiz_rounded, 'Film from the side',
        'Front works for counting, side gives full feedback.');
  } else {
    angle = const _Tip(Icons.swap_horiz_rounded, 'Film from the side',
        'Phone at 90° to your body.');
  }
  return [
    angle,
    const _Tip(Icons.crop_free_rounded, 'Whole body in frame',
        'Head to feet, through the whole rep.'),
    const _Tip(Icons.stay_current_portrait_rounded,
        'About 3 m away, phone still', 'Prop it up. No room? Switch to .5x.'),
    const _Tip(Icons.wb_sunny_outlined, 'Only you, well lit',
        'Keep other people out of the shot.'),
  ];
}

String _angleLabel(_Ex ex) =>
    ex == _Ex.pullup ? 'Film from the side or front' : 'Film from the side';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _XliftCameraRecorderState extends State<XliftCameraRecorder>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // --- Recording quality --------------------------------------------------
  static const ResolutionPreset _resolution = ResolutionPreset.veryHigh;

  CameraController? _controller;
  bool _initialized = false;
  bool _showGuidance = true;
  bool _isRecording = false;
  bool _busy = false; // blocks double taps during start/stop
  String? _error;
  // [v2] True when camera permission was denied - shows the settings overlay.
  bool _permissionDenied = false;

  // [v5] A clip that was stopped because the app got backgrounded while
  // recording. Delivered on resume.
  XFile? _pendingClip;
  bool _delivering = false;

  // --- Ultra-wide (0.5x) support via LENS SWITCHING ------------------------
  List<CameraDescription> _backCams = [];
  CameraDescription? _mainCam; // standard wide = "1x"
  CameraDescription? _ultraWideCam; // ultra-wide = "0.5x" (null if none)
  bool _wideAvailable = false;
  bool _isWide = false;

  // [v4] Gallery picker.
  final ImagePicker _picker = ImagePicker();

  // [v7] UI animation + recording timer + full-bleed origin.
  late final AnimationController _loop; // figure + REC dot
  late final AnimationController _intro; // tips card entrance
  Timer? _recTimer;
  int _recSeconds = 0;
  Offset _origin = Offset.zero;
  final List<Timer> _measureTimers = [];

  _Ex get _ex => _exOf(widget.exerciseName);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // [v3] Keep the screen awake while the camera is open.
    WakelockPlus.enable();
    // [v5] Full screen: hide status bar while the camera is open.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _showGuidance = widget.showGuidance ?? true;
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (_showGuidance) _intro.forward();

    // [v7] The page transition moves this widget; re-measure a few times.
    for (final int ms in const [120, 400, 900]) {
      _measureTimers.add(Timer(Duration(milliseconds: ms), _measure));
    }

    _setupCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    // [v5] Restore the normal system UI.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    for (final t in _measureTimers) {
      t.cancel();
    }
    _recTimer?.cancel();
    _loop.dispose();
    _intro.dispose();
    _controller?.dispose();
    super.dispose();
  }

  // [v7] Where this widget sits on the screen, so it can paint full bleed.
  void _measure() {
    if (!mounted) return;
    final ro = context.findRenderObject();
    if (ro is RenderBox && ro.attached && ro.hasSize) {
      final Offset o = ro.localToGlobal(Offset.zero);
      if ((o - _origin).distance > 0.5) setState(() => _origin = o);
    }
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  // [v5] Lifecycle like the native Camera app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        // Dynamic Island / Control Center / notification banner: ignore.
        return;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _onBackgrounded();
        return;
      case AppLifecycleState.resumed:
        _onResumed();
        return;
    }
  }

  Future<void> _onBackgrounded() async {
    final c = _controller;
    if (c == null) return;
    _controller = null; // clear first so _openController won't re-dispose it

    // If a recording is in flight, stop it cleanly and KEEP the file.
    if (_isRecording) {
      try {
        if (c.value.isRecordingVideo) {
          _pendingClip = await c.stopVideoRecording();
        }
      } catch (_) {
        // Nothing to keep - the OS already killed the session.
      }
      _isRecording = false;
      _stopRecTimer();
    }

    try {
      await c.dispose();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _initialized = false;
        _busy = false;
      });
    }
  }

  Future<void> _onResumed() async {
    // Re-enable immersive mode (iOS drops it when the app is backgrounded).
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // A clip survived the background trip -> deliver it, exactly like Stop.
    if (_pendingClip != null && !_delivering) {
      final XFile clip = _pendingClip!;
      _pendingClip = null;
      await _deliverFile(clip, picked: false);
      return; // the callback usually navigates away; don't reopen the camera
    }

    if (_controller == null) {
      // [v2] The user may have just enabled camera access in Settings.
      _permissionDenied = false;
      _setupCamera();
    }
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _error = 'No camera found on this device');
        return;
      }

      _backCams = cameras
          .where((c) => c.lensDirection == CameraLensDirection.back)
          .toList();

      if (_backCams.isEmpty) {
        _mainCam = cameras.first;
        _ultraWideCam = null;
      } else {
        _mainCam = _backCams.first; // wide = 1x
        _ultraWideCam = _backCams.length >= 2 ? _backCams.last : null;
      }
      _wideAvailable = _ultraWideCam != null;

      final CameraDescription target =
          (_isWide && _ultraWideCam != null) ? _ultraWideCam! : _mainCam!;
      await _openController(target);

      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      // [v2] Distinguish permission denial from other camera failures.
      final String msg = e.toString();
      final bool isPermission = msg.contains('CameraAccessDenied') ||
          msg.contains('AccessDenied') ||
          msg.contains('permission');
      if (mounted) {
        setState(() {
          if (isPermission) {
            _permissionDenied = true;
          } else {
            _error = 'Camera init failed: $e';
          }
        });
      }
    }
  }

  Future<void> _openController(CameraDescription desc) async {
    final old = _controller;
    _controller = null;
    if (mounted) setState(() => _initialized = false);
    await old?.dispose();

    final controller = CameraController(
      desc,
      _resolution,
      enableAudio: false,
    );
    await controller.initialize();
    _controller = controller;
  }

  Future<void> _setWide(bool wide) async {
    if (!_wideAvailable || _busy || _isRecording || wide == _isWide) return;
    final CameraDescription? target = wide ? _ultraWideCam : _mainCam;
    if (target == null) return;

    HapticFeedback.selectionClick();
    setState(() => _busy = true);
    try {
      await _openController(target);
      if (mounted) {
        setState(() {
          _isWide = wide;
          _initialized = true;
          _busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lens switch failed: $e';
          _busy = false;
        });
      }
    }
  }

  void _startRecTimer() {
    _recTimer?.cancel();
    _recSeconds = 0;
    _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recSeconds += 1);
    });
  }

  void _stopRecTimer() {
    _recTimer?.cancel();
    _recTimer = null;
  }

  Future<void> _startRecording() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _isRecording || _busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      await c.startVideoRecording();
      if (mounted) {
        _startRecTimer();
        setState(() {
          _isRecording = true;
          _busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to start recording: $e';
          _busy = false;
        });
      }
    }
  }

  Future<void> _stopRecording() async {
    final c = _controller;
    if (c == null || !_isRecording || _busy) return;
    // [v5] Guard: never call stop when the controller isn't recording.
    if (!c.value.isRecordingVideo) {
      _stopRecTimer();
      if (mounted) setState(() => _isRecording = false);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      final XFile file = await c.stopVideoRecording();
      _stopRecTimer();
      if (mounted) setState(() => _isRecording = false);
      await _deliverFile(file, picked: false);
      if (mounted) setState(() => _busy = false);
    } catch (e) {
      _stopRecTimer();
      if (mounted) {
        setState(() {
          _error = 'Failed to stop recording: $e';
          _busy = false;
          _isRecording = false;
        });
      }
    }
  }

  /// Hands a clip (recorded or picked) to FlutterFlow.
  Future<void> _deliverFile(XFile file, {required bool picked}) async {
    if (_delivering) return;
    _delivering = true;
    try {
      final bytes = await File(file.path).readAsBytes();
      final String ext = file.path.contains('.')
          ? file.path.substring(file.path.lastIndexOf('.'))
          : '.mp4';
      final uploaded = FFUploadedFile(
        name: picked
            ? 'xlift_upload_${DateTime.now().millisecondsSinceEpoch}$ext'
            : 'xlift_${DateTime.now().millisecondsSinceEpoch}.mp4',
        bytes: bytes,
      );
      if (widget.onVideoRecorded != null) {
        await widget.onVideoRecorded!(uploaded);
      }
    } finally {
      _delivering = false;
    }
  }

  // [v4] Pick a video from the gallery and deliver it through the same
  // callback as a recorded clip. Silently returns if the user cancels.
  Future<void> _pickFromGallery() async {
    if (_isRecording || _busy) return;
    setState(() => _busy = true);
    try {
      final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file == null) {
        if (mounted) setState(() => _busy = false);
        return; // user cancelled
      }
      await _deliverFile(file, picked: true);
      if (mounted) setState(() => _busy = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to pick video: $e';
          _busy = false;
        });
      }
    }
  }

  Future<void> _handleClose() async {
    if (_isRecording) {
      final c = _controller;
      try {
        if (c != null && c.value.isRecordingVideo) {
          await c.stopVideoRecording();
        }
      } catch (_) {}
      _stopRecTimer();
      if (mounted) setState(() => _isRecording = false);
    }
    if (widget.onClose != null) {
      await widget.onClose!();
    }
  }

  // [v7] Tips card open / close.
  void _openGuidance() {
    if (_isRecording) return;
    setState(() => _showGuidance = true);
    _intro.forward(from: 0);
  }

  void _closeGuidance() {
    HapticFeedback.selectionClick();
    setState(() => _showGuidance = false);
  }

  Future<void> _dontShowAgain() async {
    _closeGuidance();
    await widget.onDontShowAgain?.call();
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // [v7] Full bleed: lay out against the real screen, not the host box.
    final MediaQueryData mq = MediaQueryData.fromView(View.of(context));
    final Size screen = mq.size;
    final EdgeInsets insets = mq.viewPadding;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

    final bool camUi = !_permissionDenied && _error == null;
    final bool liveUi = camUi && !_showGuidance;

    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: screen.width,
        maxWidth: screen.width,
        minHeight: screen.height,
        maxHeight: screen.height,
        child: Transform.translate(
          offset: -_origin,
          child: SizedBox(
            width: screen.width,
            height: screen.height,
            child: Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.black),
                  if (!_permissionDenied) _cameraLayer(),
                  if (camUi) _frameLayer(insets),
                  if (liveUi) _topInfo(insets),
                  if (liveUi) _hint(insets),
                  if (liveUi) _controls(insets),
                  if (camUi && _showGuidance) _guidanceOverlay(insets),
                  if (_permissionDenied) _permissionOverlay(),
                  if (!_permissionDenied) _closeButton(insets),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cameraLayer() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      );
    }
    final c = _controller;
    if (c == null || !_initialized || !c.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    final previewSize = c.value.previewSize;
    if (previewSize == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(c),
        ),
      ),
    );
  }

  // Rule-of-thirds grid + large corner frame. Never blocks touches.
  Widget _frameLayer(EdgeInsets insets) {
    final double target = _showGuidance ? 0.25 : (_isRecording ? 0.4 : 0.75);
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: target),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        builder: (context, v, _) => CustomPaint(
          painter: _FramePainter(opacity: v, insets: insets),
        ),
      ),
    );
  }

  Widget _roundButton({
    required Widget child,
    required VoidCallback? onTap,
    required String label,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.black.withOpacity(0.35),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Center(child: child)),
        ),
      ),
    );
  }

  Widget _closeButton(EdgeInsets insets) {
    return Positioned(
      left: 12,
      top: insets.top + 8,
      child: _roundButton(
        label: 'Close camera',
        onTap: _handleClose,
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  String _mmss(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  // Title (ready) or REC timer (recording), plus the "?" tips button.
  Widget _topInfo(EdgeInsets insets) {
    final String name = (widget.exerciseName ?? '').trim();
    final Widget center = _isRecording
        ? Container(
            key: const ValueKey('rec'),
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _kRed,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.3).animate(_loop),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _mmss(_recSeconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [ui.FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          )
        : Column(
            key: const ValueKey('title'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name.isEmpty ? 'AI Form Check' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _angleLabel(_ex),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
              ),
            ],
          );

    return Positioned(
      left: 0,
      right: 0,
      top: insets.top + 8,
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 64),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: center,
              ),
            ),
            if (!_isRecording)
              Positioned(
                right: 12,
                child: _roundButton(
                  label: 'Show filming tips',
                  onTap: _openGuidance,
                  child: const Text(
                    '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _hint(EdgeInsets insets) {
    final String text = _isRecording
        ? 'Finish your set, then tap stop'
        : 'Keep your whole body in view';
    return Positioned(
      left: 0,
      right: 0,
      bottom: insets.bottom + 120,
      child: IgnorePointer(
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Container(
              key: ValueKey(text),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lensPill() {
    Widget seg(String label, bool wide) {
      final bool on = _isWide == wide;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _setWide(wide),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color:
                  on ? const Color(0xFF101315) : Colors.white.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [seg('.5x', true), seg('1x', false)],
      ),
    );
  }

  Widget _controls(EdgeInsets insets) {
    final bool side = !_isRecording;
    return Positioned(
      left: 0,
      right: 0,
      bottom: insets.bottom + 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // [v4] Gallery - hidden while recording.
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 36),
                child: IgnorePointer(
                  ignoring: !side,
                  child: AnimatedOpacity(
                    opacity: side ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Semantics(
                      button: true,
                      label: 'Pick a video from your library',
                      child: GestureDetector(
                        onTap: _busy ? null : _pickFromGallery,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.photo_library_outlined,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: _isRecording ? 'Stop recording' : 'Start recording',
            child: GestureDetector(
              onTap: _busy
                  ? null
                  : (_isRecording ? _stopRecording : _startRecording),
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: _isRecording ? 28 : 60,
                    height: _isRecording ? 28 : 60,
                    decoration: BoxDecoration(
                      color: _kRed,
                      borderRadius:
                          BorderRadius.circular(_isRecording ? 7 : 40),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 28),
                child: IgnorePointer(
                  ignoring: !side || !_wideAvailable,
                  child: AnimatedOpacity(
                    opacity: (side && _wideAvailable) ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: _lensPill(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Tips card (centered)
  // -------------------------------------------------------------------------

  Widget _guidanceOverlay(EdgeInsets insets) {
    final List<_Tip> tips = _tipsOf(_ex);
    final String name = (widget.exerciseName ?? '').trim();

    Widget tipRow(int i) {
      final double start = 0.30 + i * 0.12;
      final Animation<double> a = CurvedAnimation(
        parent: _intro,
        curve: Interval(start, (start + 0.30).clamp(0.0, 1.0),
            curve: Curves.easeOut),
      );
      return FadeTransition(
        opacity: a,
        child: SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
                  .animate(a),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(tips[i].icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tips[i].title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tips[i].sub,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Widget card = Container(
      constraints: const BoxConstraints(maxWidth: 380),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 60,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Set up your shot',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            if (name.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
              ),
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _SetupPainter(anim: _animOf(_ex), loop: _loop),
                ),
              ),
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < tips.length; i++) ...[
              tipRow(i),
              if (i < tips.length - 1) const SizedBox(height: 18),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _closeGuidance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kTeal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: TextButton(
                onPressed: _dontShowAgain,
                child: Text(
                  "Don't show this again",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _intro,
      builder: (context, child) {
        final double v = Curves.easeOutCubic
            .transform((_intro.value / 0.45).clamp(0.0, 1.0));
        return Stack(
          fit: StackFit.expand,
          children: [
            // Scrim: also swallows taps so the camera controls stay inert.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Container(color: Colors.black.withOpacity(0.55 * v)),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, insets.top + 60, 16, insets.bottom + 16),
              child: Center(
                child: Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - v)),
                    child: Transform.scale(
                      scale: 0.97 + 0.03 * v,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: card,
    );
  }

  // [v2] Shown when camera permission is denied.
  Widget _permissionOverlay() {
    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Container(
        color: Colors.black,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1D9E75).withOpacity(0.12),
                ),
                child: const Icon(Icons.no_photography_rounded,
                    size: 28, color: Color(0xFF1D9E75)),
              ),
              const SizedBox(height: 14),
              const Text(
                'Camera access needed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'To record and analyze your form, allow camera access in Settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, height: 1.4, color: Color(0xFF6B6B6B)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    await openAppSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9E75),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Open Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 44,
                child: TextButton(
                  onPressed: _handleClose,
                  child: const Text(
                    'Not now',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------

/// Thin rule-of-thirds grid + four large corner brackets.
class _FramePainter extends CustomPainter {
  _FramePainter({required this.opacity, required this.insets});

  final double opacity; // bracket opacity
  final EdgeInsets insets;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width, h = size.height;

    // Grid.
    final Paint grid = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(w / 3, 0), Offset(w / 3, h), grid);
    canvas.drawLine(Offset(2 * w / 3, 0), Offset(2 * w / 3, h), grid);
    canvas.drawLine(Offset(0, h / 3), Offset(w, h / 3), grid);
    canvas.drawLine(Offset(0, 2 * h / 3), Offset(w, 2 * h / 3), grid);

    // Brackets: almost the whole screen, between the title and the hint.
    final Rect r = Rect.fromLTRB(
      20,
      insets.top + 72,
      w - 20,
      h - insets.bottom - 174,
    );
    if (r.height < 120) return;

    const double arm = 20, rad = 12;
    final Paint p = Paint()
      ..color = Colors.white.withOpacity(opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path path = Path()
      // top-left
      ..moveTo(r.left, r.top + rad + arm)
      ..lineTo(r.left, r.top + rad)
      ..arcToPoint(Offset(r.left + rad, r.top),
          radius: const Radius.circular(rad))
      ..lineTo(r.left + rad + arm, r.top)
      // top-right
      ..moveTo(r.right - rad - arm, r.top)
      ..lineTo(r.right - rad, r.top)
      ..arcToPoint(Offset(r.right, r.top + rad),
          radius: const Radius.circular(rad))
      ..lineTo(r.right, r.top + rad + arm)
      // bottom-right
      ..moveTo(r.right, r.bottom - rad - arm)
      ..lineTo(r.right, r.bottom - rad)
      ..arcToPoint(Offset(r.right - rad, r.bottom),
          radius: const Radius.circular(rad))
      ..lineTo(r.right - rad - arm, r.bottom)
      // bottom-left
      ..moveTo(r.left + rad + arm, r.bottom)
      ..lineTo(r.left + rad, r.bottom)
      ..arcToPoint(Offset(r.left, r.bottom - rad),
          radius: const Radius.circular(rad))
      ..lineTo(r.left, r.bottom - rad - arm);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) =>
      old.opacity != opacity || old.insets != insets;
}

/// Setup illustration: phone on a stand, "about 3 m", and the animated
/// exercise figure inside a small teal frame.
class _SetupPainter extends CustomPainter {
  _SetupPainter({required this.anim, required this.loop})
      : super(repaint: loop);

  final _ExAnim anim;
  final Animation<double> loop;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;

    // Figure box: a square on the right.
    final double side = h - 20;
    final Rect box = Rect.fromLTWH(w - 18 - side, 6, side, side);

    Offset m(Offset p) => Offset(
          box.left + (0.05 + p.dx * 0.90) * box.width,
          box.top + (0.07 + p.dy * 0.90) * box.height,
        );
    final double u = box.height * 0.90; // unit length in pixels
    final double groundY = m(const Offset(0, 0.95)).dy;

    final Paint faint = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..strokeWidth = 1;
    final Paint white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Paint dim = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final Paint gear = Paint()
      ..color = Colors.white.withOpacity(0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Paint teal = Paint()
      ..color = _kTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Ground.
    canvas.drawLine(Offset(14, groundY), Offset(w - 14, groundY), faint);

    // Phone on a stand.
    const double px = 26, pw = 16, ph = 30;
    final Rect phone = Rect.fromLTWH(px, groundY - 14 - ph, pw, ph);
    final Paint phonePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(
        RRect.fromRectAndRadius(phone, const Radius.circular(4)), phonePaint);
    canvas.drawLine(Offset(px + pw / 2, phone.bottom),
        Offset(px + pw / 2, groundY), phonePaint);
    canvas.drawLine(Offset(px, groundY), Offset(px + pw, groundY), phonePaint);

    // Distance: dashed line + label.
    final double dx0 = px + pw + 14, dx1 = box.left - 10;
    if (dx1 - dx0 > 30) {
      final Paint dash = Paint()
        ..color = Colors.white.withOpacity(0.40)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      final double dy = groundY + 8;
      for (double x = dx0; x < dx1; x += 9) {
        canvas.drawLine(
            Offset(x, dy), Offset((x + 3).clamp(dx0, dx1), dy), dash);
      }
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: 'about 3 m',
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      if (tp.width < dx1 - dx0) {
        tp.paint(
          canvas,
          Offset((dx0 + dx1) / 2 - tp.width / 2, groundY - 12 - tp.height),
        );
      }
    }

    // Teal frame around the figure.
    const double fa = 8;
    final Rect fr =
        Rect.fromLTRB(box.left - 2, box.top + 2, box.right + 2, groundY + 3);
    final Path frame = Path()
      ..moveTo(fr.left, fr.top + fa)
      ..lineTo(fr.left, fr.top)
      ..lineTo(fr.left + fa, fr.top)
      ..moveTo(fr.right - fa, fr.top)
      ..lineTo(fr.right, fr.top)
      ..lineTo(fr.right, fr.top + fa)
      ..moveTo(fr.right, fr.bottom - fa)
      ..lineTo(fr.right, fr.bottom)
      ..lineTo(fr.right - fa, fr.bottom)
      ..moveTo(fr.left + fa, fr.bottom)
      ..lineTo(fr.left, fr.bottom)
      ..lineTo(fr.left, fr.bottom - fa);
    canvas.drawPath(frame, teal);

    // Fixtures (bar, bench, box).
    switch (anim.fixture) {
      case _Fixture.none:
        break;
      case _Fixture.pullBar:
        canvas.drawLine(
            m(const Offset(0.36, 0.16)), m(const Offset(0.64, 0.16)), gear);
        break;
      case _Fixture.dipBars:
        canvas.drawLine(
            m(const Offset(0.36, 0.51)), m(const Offset(0.64, 0.51)), gear);
        canvas.drawLine(
            m(const Offset(0.40, 0.51)), m(const Offset(0.40, 0.95)), gear);
        canvas.drawLine(
            m(const Offset(0.60, 0.51)), m(const Offset(0.60, 0.95)), gear);
        break;
      case _Fixture.bench:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromPoints(
                m(const Offset(0.14, 0.73)), m(const Offset(0.30, 0.95))),
            const Radius.circular(3),
          ),
          gear,
        );
        break;
      case _Fixture.box:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromPoints(
                m(const Offset(0.60, 0.72)), m(const Offset(0.80, 0.95))),
            const Radius.circular(3),
          ),
          gear,
        );
        break;
    }

    // Pose: ease, with a short hold at both ends.
    final double raw = ((loop.value - 0.12) / 0.76).clamp(0.0, 1.0);
    final _Pose p = _Pose.lerp(anim.a, anim.b, Curves.easeInOut.transform(raw));

    // Rear leg first (dimmer).
    if (p.knee2 != null && p.ankle2 != null) {
      canvas.drawLine(m(p.hip), m(p.knee2!), dim);
      canvas.drawLine(m(p.knee2!), m(p.ankle2!), dim);
    }

    // Body.
    canvas.drawLine(m(p.sh), m(p.hip), white);
    canvas.drawLine(m(p.hip), m(p.knee), white);
    canvas.drawLine(m(p.knee), m(p.ankle), white);
    canvas.drawLine(m(p.ankle), m(p.toe), white);
    canvas.drawLine(m(p.sh), m(p.elbow), white);
    canvas.drawLine(m(p.elbow), m(p.wrist), white);
    canvas.drawCircle(m(p.head), u * 0.06, white);

    // Equipment.
    Offset? at;
    double r = u * 0.065;
    switch (anim.prop) {
      case _Prop.none:
        break;
      case _Prop.barWrist:
        at = p.wrist;
        break;
      case _Prop.barBack:
        at = p.sh + const Offset(-0.03, -0.01);
        break;
      case _Prop.barFront:
        at = p.sh + const Offset(0.04, -0.01);
        break;
      case _Prop.barElbow:
        at = p.elbow;
        break;
      case _Prop.weightWrist:
        at = p.wrist;
        r = u * 0.045;
        break;
    }
    if (at != null) {
      final Offset c = m(at);
      canvas.drawCircle(c, r, Paint()..color = _kCard);
      canvas.drawCircle(c, r, teal);
      canvas.drawCircle(c, 1.6, Paint()..color = _kTeal);
    }
  }

  @override
  bool shouldRepaint(covariant _SetupPainter old) =>
      old.anim != anim || old.loop != loop;
}
