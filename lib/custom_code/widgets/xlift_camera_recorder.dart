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
// A self-contained analyzer camera:
//   1. Optional briefing panel on start (HUD style): an animated setup
//      diagram with a stick figure performing the chosen exercise, plus four
//      tips tuned per exercise. "Got it" dismisses it; "Don't show this
//      again" dismisses it and fires onDontShowAgain.
//   2. Records at 1080p with no audio — exactly the quality the analysis
//      pipeline expects (FRAME_MAX_WIDTH = 1080).
//   3. Returns an FFUploadedFile via onVideoRecorded (recorded or picked from
//      the gallery).
//
// v2 — Camera-permission overlay with Open Settings / Not now.
// v3 — Screen wakelock while the camera is open.
// v4 — Gallery upload button next to the record button.
// v5 — Lifecycle like the native Camera app (see _onBackgrounded/_onResumed).
//
// v6 — HUD redesign:
//   * exerciseName picks the stick-figure animation and the tip wording.
//   * showGuidance decides whether the briefing appears at all.
//   * onDontShowAgain callback.
//   * Full-bleed: the widget measures where it sits on screen and paints
//     itself across the WHOLE screen, even when its host applies a Safe
//     Area. (If an ancestor clips its children, e.g. a rounded bottom sheet,
//     the clip still wins.) Controls are placed using the real device
//     insets, so nothing sits under the notch or the home indicator.
//   * Lens pill (.5x / 1x), gallery button, REC timer, recording glow.
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
//        exerciseName     : String  (e.g. "Barbell Back Squat")
//        showGuidance     : bool    (false = skip the briefing)
//        onVideoRecorded  : Action with Callback Parameter
//                           name = videoFile, type = Uploaded File
//        onClose          : Action (no parameters)
//        onDontShowAgain  : Action (no parameters)
// ============================================================================

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui; // Flutter's TextDirection (avoids the intl collision)
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

  /// Exercise being recorded. Picks the animation and the tip wording.
  final String? exerciseName;

  /// Whether to show the briefing panel on start. Defaults to true.
  final bool? showGuidance;

  /// Called with the recorded (or picked) file.
  final Future Function(FFUploadedFile videoFile)? onVideoRecorded;

  /// Called when the user taps the camera's close (X) button.
  final Future Function()? onClose;

  /// Called when the user taps "Don't show this again" on the briefing.
  final Future Function()? onDontShowAgain;

  @override
  State<XliftCameraRecorder> createState() => _XliftCameraRecorderState();
}

// ---------------------------------------------------------------------------
// Palette
// ---------------------------------------------------------------------------

const Color _kTeal = Color(0xFF2CE6C8);
const Color _kBg = Color(0xFF060B0C);
const Color _kPanel = Color(0xF0091112);
const Color _kRed = Color(0xFFF0453F);
const Color _kMuted = Color(0xFFB8C7C5);
const Color _kTealInk = Color(0xFF06211D);

TextStyle _mono(double size, FontWeight w, Color c, {double ls = 0}) {
  return GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: w,
    color: c,
    letterSpacing: ls,
    decoration: TextDecoration.none,
  );
}

// ---------------------------------------------------------------------------
// Exercises: which animation + which tips
// ---------------------------------------------------------------------------

enum _Ex {
  squat,
  bulgarian,
  pushup,
  dips,
  pullup,
  curl,
  deadlift,
  rdl,
  stiffLeg,
  press,
  goodMorning,
  generic,
}

_Ex _exOf(String? name) {
  final String n = (name ?? '').toLowerCase();
  if (n.contains('bulgarian') || n.contains('split squat')) {
    return _Ex.bulgarian;
  }
  if (n.contains('squat')) return _Ex.squat;
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
  if (n.contains('romanian') || n.contains('rdl')) return _Ex.rdl;
  if (n.contains('stiff')) return _Ex.stiffLeg;
  if (n.contains('deadlift')) return _Ex.deadlift;
  if (n.contains('good morning')) return _Ex.goodMorning;
  if (n.contains('press')) return _Ex.press;
  return _Ex.generic;
}

enum _Prop { none, pullBar, dipBars, bench }

/// A side-on stick figure in a unit box (x right, y down), facing right.
class _Pose {
  const _Pose({
    required this.head,
    required this.sh,
    required this.hip,
    required this.knee,
    required this.ankle,
    required this.toe,
    required this.elbow,
    required this.wrist,
    this.knee2,
    this.ankle2,
  });

  final Offset head, sh, hip, knee, ankle, toe, elbow, wrist;
  final Offset? knee2, ankle2; // rear leg (Bulgarian split squat)

  static _Pose lerp(_Pose a, _Pose b, double t) {
    return _Pose(
      head: Offset.lerp(a.head, b.head, t)!,
      sh: Offset.lerp(a.sh, b.sh, t)!,
      hip: Offset.lerp(a.hip, b.hip, t)!,
      knee: Offset.lerp(a.knee, b.knee, t)!,
      ankle: Offset.lerp(a.ankle, b.ankle, t)!,
      toe: Offset.lerp(a.toe, b.toe, t)!,
      elbow: Offset.lerp(a.elbow, b.elbow, t)!,
      wrist: Offset.lerp(a.wrist, b.wrist, t)!,
      knee2: (a.knee2 == null || b.knee2 == null)
          ? null
          : Offset.lerp(a.knee2, b.knee2, t),
      ankle2: (a.ankle2 == null || b.ankle2 == null)
          ? null
          : Offset.lerp(a.ankle2, b.ankle2, t),
    );
  }
}

class _ExAnim {
  const _ExAnim({
    required this.a,
    required this.b,
    this.plate = false,
    this.prop = _Prop.none,
  });

  final _Pose a; // start position
  final _Pose b; // end position
  final bool plate; // draw a barbell plate at the wrist
  final _Prop prop;
}

// Standing reference used by several exercises.
const _Pose _standBarAtHips = _Pose(
  head: Offset(0.50, 0.225),
  sh: Offset(0.50, 0.33),
  hip: Offset(0.50, 0.56),
  knee: Offset(0.50, 0.75),
  ankle: Offset(0.50, 0.94),
  toe: Offset(0.58, 0.95),
  elbow: Offset(0.50, 0.46),
  wrist: Offset(0.51, 0.58),
);

const _Pose _standBarOnBack = _Pose(
  head: Offset(0.50, 0.225),
  sh: Offset(0.50, 0.33),
  hip: Offset(0.50, 0.56),
  knee: Offset(0.50, 0.75),
  ankle: Offset(0.50, 0.94),
  toe: Offset(0.58, 0.95),
  elbow: Offset(0.46, 0.44),
  wrist: Offset(0.47, 0.33),
);

_ExAnim _animOf(_Ex e) {
  switch (e) {
    case _Ex.squat:
      return const _ExAnim(
        plate: true,
        a: _standBarOnBack,
        b: _Pose(
          head: Offset(0.56, 0.47),
          sh: Offset(0.52, 0.57),
          hip: Offset(0.39, 0.76),
          knee: Offset(0.58, 0.77),
          ankle: Offset(0.50, 0.94),
          toe: Offset(0.58, 0.95),
          elbow: Offset(0.47, 0.66),
          wrist: Offset(0.50, 0.56),
        ),
      );
    case _Ex.bulgarian:
      return const _ExAnim(
        prop: _Prop.bench,
        a: _Pose(
          head: Offset(0.50, 0.235),
          sh: Offset(0.50, 0.34),
          hip: Offset(0.50, 0.57),
          knee: Offset(0.60, 0.75),
          ankle: Offset(0.60, 0.94),
          toe: Offset(0.68, 0.95),
          elbow: Offset(0.50, 0.47),
          wrist: Offset(0.51, 0.59),
          knee2: Offset(0.38, 0.76),
          ankle2: Offset(0.24, 0.72),
        ),
        b: _Pose(
          head: Offset(0.48, 0.375),
          sh: Offset(0.47, 0.48),
          hip: Offset(0.45, 0.71),
          knee: Offset(0.62, 0.75),
          ankle: Offset(0.60, 0.94),
          toe: Offset(0.68, 0.95),
          elbow: Offset(0.47, 0.61),
          wrist: Offset(0.48, 0.73),
          knee2: Offset(0.36, 0.88),
          ankle2: Offset(0.24, 0.72),
        ),
      );
    case _Ex.pushup:
      return const _ExAnim(
        a: _Pose(
          head: Offset(0.82, 0.62),
          sh: Offset(0.72, 0.66),
          hip: Offset(0.50, 0.75),
          knee: Offset(0.33, 0.82),
          ankle: Offset(0.15, 0.88),
          toe: Offset(0.13, 0.94),
          elbow: Offset(0.72, 0.80),
          wrist: Offset(0.72, 0.94),
        ),
        b: _Pose(
          head: Offset(0.82, 0.80),
          sh: Offset(0.72, 0.83),
          hip: Offset(0.50, 0.84),
          knee: Offset(0.33, 0.87),
          ankle: Offset(0.15, 0.89),
          toe: Offset(0.13, 0.94),
          elbow: Offset(0.62, 0.78),
          wrist: Offset(0.72, 0.94),
        ),
      );
    case _Ex.dips:
      return const _ExAnim(
        prop: _Prop.dipBars,
        a: _Pose(
          head: Offset(0.50, 0.215),
          sh: Offset(0.50, 0.32),
          hip: Offset(0.50, 0.55),
          knee: Offset(0.50, 0.74),
          ankle: Offset(0.38, 0.82),
          toe: Offset(0.34, 0.80),
          elbow: Offset(0.50, 0.44),
          wrist: Offset(0.50, 0.56),
        ),
        b: _Pose(
          head: Offset(0.57, 0.37),
          sh: Offset(0.54, 0.47),
          hip: Offset(0.48, 0.69),
          knee: Offset(0.50, 0.87),
          ankle: Offset(0.38, 0.93),
          toe: Offset(0.34, 0.91),
          elbow: Offset(0.42, 0.45),
          wrist: Offset(0.50, 0.56),
        ),
      );
    case _Ex.pullup:
      return const _ExAnim(
        prop: _Prop.pullBar,
        a: _Pose(
          head: Offset(0.53, 0.26),
          sh: Offset(0.50, 0.35),
          hip: Offset(0.50, 0.58),
          knee: Offset(0.51, 0.76),
          ankle: Offset(0.46, 0.93),
          toe: Offset(0.50, 0.96),
          elbow: Offset(0.50, 0.23),
          wrist: Offset(0.50, 0.11),
        ),
        b: _Pose(
          head: Offset(0.54, 0.07),
          sh: Offset(0.50, 0.17),
          hip: Offset(0.49, 0.40),
          knee: Offset(0.51, 0.58),
          ankle: Offset(0.46, 0.75),
          toe: Offset(0.50, 0.78),
          elbow: Offset(0.46, 0.28),
          wrist: Offset(0.50, 0.11),
        ),
      );
    case _Ex.curl:
      return const _ExAnim(
        plate: true,
        a: _standBarAtHips,
        b: _Pose(
          head: Offset(0.50, 0.225),
          sh: Offset(0.50, 0.33),
          hip: Offset(0.50, 0.56),
          knee: Offset(0.50, 0.75),
          ankle: Offset(0.50, 0.94),
          toe: Offset(0.58, 0.95),
          elbow: Offset(0.50, 0.46),
          wrist: Offset(0.58, 0.37),
        ),
      );
    case _Ex.deadlift:
      return const _ExAnim(
        plate: true,
        a: _Pose(
          head: Offset(0.65, 0.49),
          sh: Offset(0.58, 0.56),
          hip: Offset(0.38, 0.68),
          knee: Offset(0.56, 0.76),
          ankle: Offset(0.50, 0.94),
          toe: Offset(0.58, 0.95),
          elbow: Offset(0.58, 0.69),
          wrist: Offset(0.57, 0.81),
        ),
        b: _standBarAtHips,
      );
    case _Ex.rdl:
      return const _ExAnim(
        plate: true,
        a: _standBarAtHips,
        b: _Pose(
          head: Offset(0.69, 0.42),
          sh: Offset(0.61, 0.47),
          hip: Offset(0.41, 0.57),
          knee: Offset(0.51, 0.75),
          ankle: Offset(0.50, 0.94),
          toe: Offset(0.58, 0.95),
          elbow: Offset(0.61, 0.60),
          wrist: Offset(0.60, 0.72),
        ),
      );
    case _Ex.stiffLeg:
      return const _ExAnim(
        plate: true,
        a: _standBarAtHips,
        b: _Pose(
          head: Offset(0.74, 0.49),
          sh: Offset(0.65, 0.52),
          hip: Offset(0.43, 0.57),
          knee: Offset(0.48, 0.75),
          ankle: Offset(0.50, 0.94),
          toe: Offset(0.58, 0.95),
          elbow: Offset(0.65, 0.65),
          wrist: Offset(0.64, 0.77),
        ),
      );
    case _Ex.press:
      return const _ExAnim(
        plate: true,
        a: _Pose(
          head: Offset(0.50, 0.225),
          sh: Offset(0.50, 0.33),
          hip: Offset(0.50, 0.56),
          knee: Offset(0.50, 0.75),
          ankle: Offset(0.50, 0.94),
          toe: Offset(0.58, 0.95),
          elbow: Offset(0.54, 0.45),
          wrist: Offset(0.55, 0.32),
        ),
        b: _Pose(
          head: Offset(0.50, 0.225),
          sh: Offset(0.50, 0.33),
          hip: Offset(0.50, 0.56),
          knee: Offset(0.50, 0.75),
          ankle: Offset(0.50, 0.94),
          toe: Offset(0.58, 0.95),
          elbow: Offset(0.52, 0.20),
          wrist: Offset(0.52, 0.08),
        ),
      );
    case _Ex.goodMorning:
      return const _ExAnim(
        plate: true,
        a: _standBarOnBack,
        b: _Pose(
          head: Offset(0.69, 0.42),
          sh: Offset(0.61, 0.47),
          hip: Offset(0.41, 0.57),
          knee: Offset(0.51, 0.75),
          ankle: Offset(0.50, 0.94),
          toe: Offset(0.58, 0.95),
          elbow: Offset(0.56, 0.57),
          wrist: Offset(0.59, 0.47),
        ),
      );
    case _Ex.generic:
      return const _ExAnim(a: _standBarAtHips, b: _standBarAtHips);
  }
}

/// [title, detail] x 4, tuned to how the analyzer for that exercise works.
List<List<String>> _tipsOf(_Ex e) {
  List<String> view = const [
    'Film from the side',
    'Phone at 90° to your body. Other angles are less accurate.',
  ];
  List<String> frame = const [
    'Whole body in frame',
    'Head to feet at every point of the rep, top and bottom.',
  ];
  if (e == _Ex.pullup) {
    view = const [
      'Film from the side or front',
      'Both work for pull-ups. From the side it also catches swinging.',
    ];
    frame = const [
      'Whole body in frame',
      'From the bar down to your feet, for the entire rep.',
    ];
  } else if (e == _Ex.press) {
    view = const [
      'Film from the side',
      'Front works for counting, but the side gives full form feedback.',
    ];
    frame = const [
      'Whole body in frame',
      'Include your hands at the very top of the press.',
    ];
  }
  return [
    view,
    frame,
    const [
      'About 3 m away, phone still',
      "Prop it up, don't hand-hold. No room? Switch to .5x.",
    ],
    const [
      'Only you, well lit',
      'The AI follows one body, so keep others out of the shot.',
    ],
  ];
}

String _viewLabel(_Ex e) => e == _Ex.pullup ? 'SIDE OR FRONT' : 'SIDE ON';

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

  // [v6] Animation clocks. _loop drives every looping effect (scan line,
  // pulses, spinning ring, the exercise figure); _intro staggers the tips.
  late final AnimationController _loop;
  late final AnimationController _intro;
  static const double _loopSeconds = 60.0;

  // [v6] Recording timer.
  Timer? _recTimer;
  int _recSeconds = 0;

  // [v6] Full-bleed: where this widget's top-left sits on screen.
  Offset _origin = Offset.zero;
  Animation<double>? _routeAnim;

  @override
  void initState() {
    super.initState();
    _showGuidance = widget.showGuidance ?? true;
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..forward();

    WidgetsBinding.instance.addObserver(this);
    // [v3] Keep the screen awake while the camera is open.
    WakelockPlus.enable();
    // [v5] Full screen: hide status bar while the camera is open.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _setupCamera();

    // [v6] The host may still be sliding in; re-measure a few times.
    for (final ms in const [120, 350, 700, 1200]) {
      Timer(Duration(milliseconds: ms), _measure);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // [v6] Follow the host route's transition so the full-bleed offset stays
    // right while a page or sheet animates in.
    final Animation<double>? a = ModalRoute.of(context)?.animation;
    if (a != _routeAnim) {
      _routeAnim?.removeListener(_measure);
      _routeAnim = a;
      _routeAnim?.addListener(_measure);
    }
  }

  @override
  void dispose() {
    _routeAnim?.removeListener(_measure);
    _recTimer?.cancel();
    _loop.dispose();
    _intro.dispose();
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    // [v5] Restore the normal system UI.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  /// [v6] Reads this widget's position on screen. Only rebuilds on change.
  void _measure() {
    if (!mounted) return;
    final ro = context.findRenderObject();
    if (ro is RenderBox && ro.attached && ro.hasSize) {
      final Offset o = ro.localToGlobal(Offset.zero);
      if ((o - _origin).distance > 0.5) {
        setState(() => _origin = o);
      }
    }
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

  Future<void> _toggleWide() async {
    if (!_wideAvailable || _busy || _isRecording) return;
    final CameraDescription? target = _isWide ? _mainCam : _ultraWideCam;
    if (target == null) return;

    setState(() => _busy = true);
    try {
      await _openController(target);
      if (mounted) {
        setState(() {
          _isWide = !_isWide;
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
    setState(() => _busy = true);
    try {
      await c.startVideoRecording();
      if (mounted) {
        setState(() {
          _isRecording = true;
          _busy = false;
        });
        _startRecTimer();
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

  void _dismissGuidance({required bool forever}) {
    HapticFeedback.selectionClick();
    setState(() => _showGuidance = false);
    if (forever) widget.onDontShowAgain?.call();
  }

  // ---------- text ----------
  TextStyle _sans(double size, FontWeight w, Color c, {double? height}) {
    final th = FlutterFlowTheme.of(context);
    return th.bodyMedium.override(
      fontFamily: th.bodyMediumFamily,
      color: c,
      fontSize: size,
      fontWeight: w,
      letterSpacing: 0,
      lineHeight: height,
      useGoogleFonts: GoogleFonts.asMap().containsKey(th.bodyMediumFamily),
    );
  }

  double get _t => _loop.value * _loopSeconds; // seconds on the loop clock

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    // [v6] Keep the full-bleed offset fresh after every rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

    final ui.FlutterView view = View.of(context);
    final double dpr = view.devicePixelRatio;
    final Size screen = view.physicalSize / dpr;
    final EdgeInsets safe = EdgeInsets.fromViewPadding(view.padding, dpr);

    final _Ex ex = _exOf(widget.exerciseName);
    final bool cameraUi = !_permissionDenied && _error == null;
    final bool hud = cameraUi && !_showGuidance;

    final Widget content = Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: screen.width,
          height: screen.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: _kBg),
              if (!_permissionDenied) _cameraLayer(),
              if (_permissionDenied) _permissionOverlay(),
              if (hud) _hudLayer(screen, safe, ex),
              if (cameraUi) _topBar(safe, ex),
              if (hud) _bottomArea(screen, safe, ex),
              if (cameraUi && _showGuidance) _guidanceOverlay(screen, safe, ex),
            ],
          ),
        ),
      ),
    );

    // [v6] Full-bleed: paint across the whole screen from wherever the host
    // put this widget.
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
          offset: Offset(-_origin.dx, -_origin.dy),
          child: content,
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      );
    }
    final c = _controller;
    if (c == null || !_initialized || !c.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: _kTeal),
      );
    }
    final previewSize = c.value.previewSize;
    if (previewSize == null) {
      return const Center(
        child: CircularProgressIndicator(color: _kTeal),
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

  /// Frame the user should stand in, in screen coordinates.
  Rect _frameRect(Size screen, EdgeInsets safe) {
    final double top = safe.top + 108;
    final double bottom = screen.height - safe.bottom - 262;
    return Rect.fromLTRB(
      screen.width * 0.145,
      top,
      screen.width * 0.855,
      math.max(top + 160, bottom),
    );
  }

  // ---------- HUD over the camera ----------
  Widget _hudLayer(Size screen, EdgeInsets safe, _Ex ex) {
    final Rect frame = _frameRect(screen, safe);
    final _ExAnim anim = _animOf(ex);
    final double side = math.min(frame.width, frame.height) * 0.92;
    final Rect ghost = Rect.fromCenter(
      center: frame.center,
      width: side,
      height: side,
    );
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _loop,
        builder: (_, __) => CustomPaint(
          painter: _HudPainter(
            t: _t,
            frame: frame,
            recording: _isRecording,
            ghostBox: ghost,
            ghostPose: anim.a,
            anim: anim,
          ),
        ),
      ),
    );
  }

  // ---------- top bar ----------
  Widget _topBar(EdgeInsets safe, _Ex ex) {
    final String name = (widget.exerciseName ?? '').trim().toUpperCase();
    final String mm = (_recSeconds ~/ 60).toString().padLeft(2, '0');
    final String ss = (_recSeconds % 60).toString().padLeft(2, '0');

    return Positioned(
      left: 12,
      right: 12,
      top: safe.top + 8,
      child: Row(
        children: [
          _roundButton(Icons.close_rounded, _handleClose),
          const SizedBox(width: 10),
          Expanded(
            child: Center(
              child: _isRecording
                  ? Text('$mm:$ss',
                      style: _mono(26, FontWeight.w700, Colors.white, ls: 1))
                  : (name.isEmpty
                      ? const SizedBox.shrink()
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _kBg.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: _kTeal.withOpacity(0.5), width: 1),
                          ),
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _mono(11, FontWeight.w700, _kTeal, ls: 1.4),
                          ),
                        )),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedBuilder(
            animation: _loop,
            builder: (_, __) {
              final double blink =
                  0.25 + 0.75 * (math.sin(_t * math.pi / 0.7)).abs();
              final Color dot = _isRecording ? _kRed : _kTeal;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _isRecording
                      ? _kRed.withOpacity(0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: blink,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dot,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: dot.withOpacity(0.9), blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isRecording ? 'REC' : 'AI READY',
                      style: _mono(11, FontWeight.w700, Colors.white, ls: 1.2),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  // ---------- bottom: hints + controls ----------
  Widget _bottomArea(Size screen, EdgeInsets safe, _Ex ex) {
    final List<String> chips = [
      ex == _Ex.pullup ? 'Side or front' : 'Side on, 90°',
      'Head to feet',
      'About 3 m away',
    ];

    return Positioned(
      left: 0,
      right: 0,
      bottom: safe.bottom + 26,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isRecording
                ? 'KEEP YOUR WHOLE BODY IN THE FRAME'
                : 'MATCH YOUR BODY TO THE GUIDE',
            textAlign: TextAlign.center,
            style: _mono(11, FontWeight.w700, _kTeal, ls: 1.4),
          ),
          const SizedBox(height: 12),
          if (_isRecording)
            Text('Finish your set, then tap stop.',
                style: _sans(13, FontWeight.w400, _kMuted))
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in chips)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(c,
                          style: _sans(
                              12, FontWeight.w500, const Color(0xFFE6F3F1))),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gallery (hidden while recording)
              SizedBox(
                width: 92,
                height: 52,
                child: _isRecording
                    ? null
                    : Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _busy ? null : _pickFromGallery,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.35)),
                            ),
                            child: const Icon(Icons.photo_library_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 26),
              _recordButton(),
              const SizedBox(width: 26),
              // Lens pill (hidden while recording / when there is no 0.5x)
              SizedBox(
                width: 92,
                height: 52,
                child: (_isRecording || !_wideAvailable)
                    ? null
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: _lensPill(),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recordButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _busy ? null : (_isRecording ? _stopRecording : _startRecording),
      child: SizedBox(
        width: 92,
        height: 92,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _loop,
                builder: (_, __) => CustomPaint(
                  painter: _RecordRingPainter(
                    t: _t,
                    recording: _isRecording,
                    seconds: _recSeconds,
                  ),
                ),
              ),
            ),
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _isRecording ? 30 : 54,
              height: _isRecording ? 30 : 54,
              decoration: BoxDecoration(
                color: _kRed,
                borderRadius: BorderRadius.circular(_isRecording ? 8 : 40),
                boxShadow: [
                  BoxShadow(color: _kRed.withOpacity(0.55), blurRadius: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lensPill() {
    Widget seg(String label, bool active) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: active ? null : _toggleWide,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? _kTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: _mono(12, FontWeight.w700, active ? _kTealInk : _kMuted),
          ),
        ),
      );
    }

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg('.5x', _isWide),
          seg('1x', !_isWide),
        ],
      ),
    );
  }

  // ---------- briefing ----------
  Widget _guidanceOverlay(Size screen, EdgeInsets safe, _Ex ex) {
    final _ExAnim anim = _animOf(ex);
    final List<List<String>> tips = _tipsOf(ex);
    final String name = (widget.exerciseName ?? '').trim().toUpperCase();
    final double maxH = screen.height - safe.top - safe.bottom - 84;

    Widget tipRow(int i) {
      return AnimatedBuilder(
        animation: _intro,
        builder: (_, child) {
          final double start = 0.12 + 0.17 * i;
          final double o =
              ((_intro.value - start) / 0.22).clamp(0.0, 1.0).toDouble();
          return Opacity(
            opacity: o,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - o)),
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _kTeal.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('0${i + 1}',
                    style: _mono(12, FontWeight.w700, _kTeal)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tips[i][0],
                        style: _sans(15, FontWeight.w600, Colors.white)),
                    const SizedBox(height: 2),
                    Text(tips[i][1],
                        style:
                            _sans(13, FontWeight.w400, _kMuted, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Widget panel = Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kTeal.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(color: _kTeal.withOpacity(0.12), blurRadius: 40),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('BEFORE YOU RECORD',
                        style: _mono(11, FontWeight.w700, _kTeal, ls: 2)),
                    const SizedBox(height: 4),
                    Text('Set up your shot',
                        style: _sans(20, FontWeight.w700, Colors.white)),
                  ],
                ),
              ),
              if (name.isNotEmpty) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kTeal.withOpacity(0.5)),
                    ),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _mono(11, FontWeight.w700, _kTeal, ls: 1.2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          // Setup diagram with the animated exercise figure
          Container(
            height: 136,
            decoration: BoxDecoration(
              color: _kTeal.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: AnimatedBuilder(
              animation: _loop,
              builder: (_, __) {
                // Smooth there-and-back between the two key poses.
                final double phase = (_t / 2.6) % 1.0;
                final double s = 0.5 - 0.5 * math.cos(2 * math.pi * phase);
                return CustomPaint(
                  painter: _SetupPainter(
                    t: _t,
                    pose: _Pose.lerp(anim.a, anim.b, s),
                    anim: anim,
                    label: _viewLabel(ex),
                    labelStyle: _mono(10, FontWeight.w700, _kTeal),
                    distStyle: _mono(12, FontWeight.w700, Colors.white),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < tips.length; i++) tipRow(i),
          const SizedBox(height: 2),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _dismissGuidance(forever: false),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _kTeal,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: _kTeal.withOpacity(0.35), blurRadius: 24),
                ],
              ),
              child: Text("Got it, let's go",
                  style: _sans(16, FontWeight.w700, _kTealInk)),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _dismissGuidance(forever: true),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              child: Text("Don't show this again",
                  style: _sans(13, FontWeight.w500, _kMuted)),
            ),
          ),
        ],
      ),
    );

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        padding: EdgeInsets.fromLTRB(16, safe.top + 64, 16, safe.bottom + 16),
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 420, maxHeight: maxH),
          child: SingleChildScrollView(child: panel),
        ),
      ),
    );
  }

  // [v2] Shown when camera permission is denied.
  Widget _permissionOverlay() {
    return Container(
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
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'To record and analyze your form, allow camera access in Settings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF6B6B6B),
                decoration: TextDecoration.none,
              ),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Painting
// ---------------------------------------------------------------------------

/// Draws the stick figure for [p] inside [box] (a square works best).
void _paintFigure(
  Canvas canvas,
  Rect box,
  _Pose p,
  _ExAnim anim, {
  required Color bone,
  required Color accent,
  double stroke = 2.5,
  bool floor = true,
}) {
  Offset m(Offset u) =>
      Offset(box.left + u.dx * box.width, box.top + u.dy * box.height);

  final Paint bonePaint = Paint()
    ..color = bone
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke
    ..strokeCap = StrokeCap.round;
  final Paint faint = Paint()
    ..color = bone.withOpacity(bone.opacity * 0.3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round;
  final Paint accentPaint = Paint()
    ..color = accent
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke
    ..strokeCap = StrokeCap.round;

  if (floor) {
    canvas.drawLine(
        m(const Offset(0.04, 0.965)), m(const Offset(0.96, 0.965)), faint);
  }

  // Props
  switch (anim.prop) {
    case _Prop.pullBar:
      canvas.drawLine(m(const Offset(0.36, 0.10)), m(const Offset(0.64, 0.10)),
          accentPaint);
      break;
    case _Prop.dipBars:
      canvas.drawLine(m(const Offset(0.30, 0.56)), m(const Offset(0.70, 0.56)),
          accentPaint);
      canvas.drawLine(
          m(const Offset(0.33, 0.56)), m(const Offset(0.33, 0.965)), faint);
      canvas.drawLine(
          m(const Offset(0.67, 0.56)), m(const Offset(0.67, 0.965)), faint);
      break;
    case _Prop.bench:
      canvas.drawLine(m(const Offset(0.10, 0.74)), m(const Offset(0.32, 0.74)),
          accentPaint);
      canvas.drawLine(
          m(const Offset(0.13, 0.74)), m(const Offset(0.13, 0.965)), faint);
      canvas.drawLine(
          m(const Offset(0.29, 0.74)), m(const Offset(0.29, 0.965)), faint);
      break;
    case _Prop.none:
      break;
  }

  // Rear leg first, dimmer, so the front leg reads on top.
  if (p.knee2 != null && p.ankle2 != null) {
    final Paint rear = Paint()
      ..color = bone.withOpacity(bone.opacity * 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(m(p.hip), m(p.knee2!), rear);
    canvas.drawLine(m(p.knee2!), m(p.ankle2!), rear);
  }

  // Bones
  canvas.drawLine(m(p.sh), m(p.hip), bonePaint);
  canvas.drawLine(m(p.hip), m(p.knee), bonePaint);
  canvas.drawLine(m(p.knee), m(p.ankle), bonePaint);
  canvas.drawLine(m(p.ankle), m(p.toe), bonePaint);
  canvas.drawLine(m(p.sh), m(p.elbow), bonePaint);
  canvas.drawLine(m(p.elbow), m(p.wrist), bonePaint);

  // Head + neck
  final double headR = 0.052 * box.width;
  final Offset head = m(p.head);
  final Offset sh = m(p.sh);
  final Offset d = sh - head;
  if (d.distance > headR) {
    canvas.drawLine(head + d / d.distance * headR, sh, bonePaint);
  }
  canvas.drawCircle(head, headR, bonePaint);

  // Joints
  final Paint jointPaint = Paint()..color = bone;
  for (final j in [p.sh, p.hip, p.knee, p.ankle, p.elbow, p.wrist]) {
    canvas.drawCircle(m(j), stroke * 0.95, jointPaint);
  }

  // Barbell plate, seen end-on
  if (anim.plate) {
    final Offset w = m(p.wrist);
    canvas.drawCircle(
        w,
        0.062 * box.width,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawCircle(w, 2, Paint()..color = accent);
  }
}

void _paintBrackets(Canvas canvas, Rect r, Paint paint, double len) {
  canvas.drawPath(
    Path()
      ..moveTo(r.left, r.top + len)
      ..lineTo(r.left, r.top)
      ..lineTo(r.left + len, r.top)
      ..moveTo(r.right - len, r.top)
      ..lineTo(r.right, r.top)
      ..lineTo(r.right, r.top + len)
      ..moveTo(r.left, r.bottom - len)
      ..lineTo(r.left, r.bottom)
      ..lineTo(r.left + len, r.bottom)
      ..moveTo(r.right - len, r.bottom)
      ..lineTo(r.right, r.bottom)
      ..lineTo(r.right, r.bottom - len),
    paint,
  );
}

/// Briefing diagram: phone on a stand, distance line, framed lifter.
class _SetupPainter extends CustomPainter {
  _SetupPainter({
    required this.t,
    required this.pose,
    required this.anim,
    required this.label,
    required this.labelStyle,
    required this.distStyle,
  });

  final double t;
  final _Pose pose;
  final _ExAnim anim;
  final String label;
  final TextStyle labelStyle, distStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final double groundY = size.height - 22;
    final double figSide = math.min(size.height - 34, size.width * 0.34);
    final Rect figBox = Rect.fromLTWH(
      size.width - figSide - 20,
      groundY - figSide * 0.965,
      figSide,
      figSide,
    );

    // Ground
    canvas.drawLine(
      Offset(14, groundY),
      Offset(size.width - 14, groundY),
      Paint()
        ..color = Colors.white.withOpacity(0.18)
        ..strokeWidth = 1,
    );

    // Phone on a stand
    final Paint white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final Rect phone = Rect.fromLTWH(28, groundY - 50, 18, 34);
    canvas.drawRRect(
        RRect.fromRectAndRadius(phone, const Radius.circular(4)), white);
    canvas.drawCircle(
        Offset(phone.center.dx, phone.top + 8), 2.2, Paint()..color = _kTeal);
    canvas.drawLine(Offset(phone.center.dx, phone.bottom),
        Offset(phone.center.dx, groundY), white);
    canvas.drawLine(
        Offset(phone.left, groundY), Offset(phone.right, groundY), white);

    // Field of view, breathing
    final double sweep = 0.25 + 0.6 * (0.5 + 0.5 * math.sin(t * 2.6));
    final Paint fov = Paint()
      ..color = _kTeal.withOpacity(sweep)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(phone.right, phone.top + 10),
        Offset(figBox.left - 6, figBox.top), fov);
    canvas.drawLine(Offset(phone.right, phone.top + 16),
        Offset(figBox.left - 6, groundY), fov);

    // Distance line with marching dashes
    final double y = groundY + 10;
    final double x0 = phone.right + 8;
    final double x1 = figBox.left + 4;
    final Paint dash = Paint()
      ..color = _kTeal
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const double seg = 6, gap = 6;
    final double offset = (t * 14) % (seg + gap);
    for (double x = x0 - offset; x < x1; x += seg + gap) {
      final double a = math.max(x, x0);
      final double b = math.min(x + seg, x1);
      if (b > a) canvas.drawLine(Offset(a, y), Offset(b, y), dash);
    }
    canvas.drawLine(Offset(x0, y - 5), Offset(x0, y + 5), dash);
    canvas.drawLine(Offset(x1, y - 5), Offset(x1, y + 5), dash);

    final tp = TextPainter(
      text: TextSpan(text: '3 m', style: distStyle),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final Offset mid = Offset((x0 + x1) / 2, y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: mid, width: tp.width + 14, height: tp.height + 4),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF0B1516),
    );
    tp.paint(canvas, mid - Offset(tp.width / 2, tp.height / 2));

    // Frame + animated figure
    final Rect frame = figBox.inflate(6);
    _paintBrackets(
      canvas,
      Rect.fromLTRB(frame.left, frame.top + 10, frame.right, groundY),
      Paint()
        ..color = _kTeal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
      10,
    );
    _paintFigure(canvas, figBox, pose, anim,
        bone: Colors.white, accent: _kTeal, stroke: 2.2, floor: false);

    final lp = TextPainter(
      text: TextSpan(text: label, style: labelStyle),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    lp.paint(canvas, Offset(frame.center.dx - lp.width / 2, 4));
  }

  @override
  bool shouldRepaint(covariant _SetupPainter old) => true;
}

/// Camera HUD: grid, frame brackets, scan line, ghost start pose, and the
/// red glow while recording.
class _HudPainter extends CustomPainter {
  _HudPainter({
    required this.t,
    required this.frame,
    required this.recording,
    required this.ghostBox,
    required this.ghostPose,
    required this.anim,
  });

  final double t;
  final Rect frame;
  final bool recording;
  final Rect ghostBox;
  final _Pose ghostPose;
  final _ExAnim anim;

  @override
  void paint(Canvas canvas, Size size) {
    // Faint grid
    final Paint grid = Paint()
      ..color = _kTeal.withOpacity(0.05)
      ..strokeWidth = 1;
    const double step = 39;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final double pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi / 2.0);

    // Recording glow around the whole screen
    if (recording) {
      final Rect r = Offset.zero & size;
      canvas.drawRect(
        r.deflate(1),
        Paint()
          ..color = _kRed.withOpacity(0.25 + 0.3 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 26
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );
      canvas.drawRect(
        r.deflate(1),
        Paint()
          ..color = _kRed.withOpacity(0.55 + 0.4 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Frame brackets
    _paintBrackets(
      canvas,
      frame,
      Paint()
        ..color = _kTeal.withOpacity(recording ? 0.55 + 0.45 * pulse : 1.0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
      28,
    );

    // Centre ticks
    final Paint tick = Paint()
      ..color = _kTeal.withOpacity(0.45)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(frame.left - 16, frame.center.dy),
        Offset(frame.left - 4, frame.center.dy), tick);
    canvas.drawLine(Offset(frame.right + 4, frame.center.dy),
        Offset(frame.right + 16, frame.center.dy), tick);
    canvas.drawLine(Offset(frame.center.dx, frame.top - 16),
        Offset(frame.center.dx, frame.top - 4), tick);
    canvas.drawLine(Offset(frame.center.dx, frame.bottom + 4),
        Offset(frame.center.dx, frame.bottom + 16), tick);

    if (recording) return;

    // Ghost of the start position, breathing
    _paintFigure(
      canvas,
      ghostBox,
      ghostPose,
      anim,
      bone: _kTeal.withOpacity(0.30 + 0.35 * pulse),
      accent: _kTeal.withOpacity(0.30 + 0.35 * pulse),
      stroke: 2.5,
      floor: false,
    );

    // Scan line
    final double phase = (t / 3.0) % 1.0;
    final double fade =
        phase < 0.08 ? phase / 0.08 : (phase > 0.92 ? (1 - phase) / 0.08 : 1.0);
    final double y = frame.top + frame.height * phase;
    canvas.drawLine(
      Offset(frame.left, y),
      Offset(frame.right, y),
      Paint()
        ..color = _kTeal.withOpacity(0.7 * fade)
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawLine(
      Offset(frame.left, y),
      Offset(frame.right, y),
      Paint()
        ..color = _kTeal.withOpacity(fade)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _HudPainter old) => true;
}

/// Ring around the record button: spinning dashes when idle, a red ring
/// that fills over 60 seconds while recording.
class _RecordRingPainter extends CustomPainter {
  _RecordRingPainter({
    required this.t,
    required this.recording,
    required this.seconds,
  });

  final double t;
  final bool recording;
  final int seconds;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.width / 2 - 2;
    final Rect rect = Rect.fromCircle(center: c, radius: r);

    if (recording) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = Colors.white.withOpacity(0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      final double f = ((seconds % 60) / 60.0);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * math.max(f, 0.01),
        false,
        Paint()
          ..color = _kRed
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    final Paint dash = Paint()
      ..color = _kTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const int n = 24;
    final double rot = (t / 9.0) * 2 * math.pi;
    for (int i = 0; i < n; i++) {
      final double a = rot + i * 2 * math.pi / n;
      canvas.drawArc(rect, a, 0.07, false, dash);
    }
  }

  @override
  bool shouldRepaint(covariant _RecordRingPainter old) => true;
}
