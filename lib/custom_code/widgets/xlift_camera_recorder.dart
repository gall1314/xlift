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
// A self-contained camera with 3 jobs:
//   1. Shows a general guidance card on start; dismisses on tap (then the
//      camera controls appear).
//   2. Records at 1080p with no audio — exactly the quality the analysis
//      pipeline expects (FRAME_MAX_WIDTH = 1080), so no later compression /
//      transcoding is needed.
//   3. Returns an FFUploadedFile via the onVideoRecorded callback, ready to
//      feed straight into analyzeSquatVideoAction.
//
// v2 — Camera-permission overlay with Open Settings / Not now.
// v3 — Screen wakelock while the camera is open.
// v4 — Gallery upload button next to the record button.
//
// v5 — Lifecycle like the native Camera app:
//   * `inactive` (Dynamic Island tap, Control Center, notification pull,
//     incoming call banner) does NOTHING - recording keeps going.
//   * `paused` (really backgrounded) while recording: the clip is stopped
//     cleanly and KEPT, then delivered through onVideoRecorded as soon as
//     the app resumes - exactly as if the user had tapped Stop. Nothing is
//     lost anymore.
//   * Status bar is hidden while the camera is open (immersive, full
//     screen) and restored on exit. Controls respect the safe area.
//   * stopVideoRecording is guarded, so the "called when no video is
//     recording" error can't surface.
//
// There is also a separate close (X) button to EXIT the camera, which fires
// the onClose callback so you can handle the exit (e.g. navigate back) in
// FlutterFlow. This is independent of the guidance card's dismiss button.
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
//        onVideoRecorded  : Action with Callback Parameter
//                           name = videoFile, type = Uploaded File
//        onClose          : Action (no parameters)
//
// 4) The page/sheet hosting this widget must have Safe Area OFF and no
//    padding, otherwise the black bars you see at the top/bottom come from
//    the host, not from this widget.
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
    this.onVideoRecorded,
    this.onClose,
  });

  final double? width;
  final double? height;

  /// Called with the recorded (or picked) file.
  final Future Function(FFUploadedFile videoFile)? onVideoRecorded;

  /// Called when the user taps the camera's close (X) button.
  final Future Function()? onClose;

  @override
  State<XliftCameraRecorder> createState() => _XliftCameraRecorderState();
}

class _XliftCameraRecorderState extends State<XliftCameraRecorder>
    with WidgetsBindingObserver {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // [v3] Keep the screen awake while the camera is open.
    WakelockPlus.enable();
    // [v5] Full screen: hide status bar while the camera is open.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _setupCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    // [v5] Restore the normal system UI.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.dispose();
    super.dispose();
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
      if (mounted) setState(() => _isRecording = false);
      return;
    }
    setState(() => _busy = true);
    try {
      final XFile file = await c.stopVideoRecording();
      if (mounted) setState(() => _isRecording = false);
      await _deliverFile(file, picked: false);
      if (mounted) setState(() => _busy = false);
    } catch (e) {
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
      if (mounted) setState(() => _isRecording = false);
    }
    if (widget.onClose != null) {
      await widget.onClose!();
    }
  }

  // --- General guidance text ----------------------------------------------
  static const String _guidanceTitle = 'Before you start';
  static const String _guidanceSubtitle = 'A few tips for a good recording:';
  static const List<String> _guidanceLines = [
    'Film from the side, at a 90 degree angle to your body',
    'Keep your whole body in frame, head to feet',
    'Stand about 3 m from the camera',
    'Make sure you are well lit and the background is clear',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),
          if (!_permissionDenied) _cameraLayer(),
          if (_permissionDenied) _permissionOverlay(),
          if (_error == null) _closeButton(),
          if (!_permissionDenied &&
              !_showGuidance &&
              _error == null &&
              _wideAvailable)
            _wideButton(),
          if (!_permissionDenied && !_showGuidance && _error == null)
            _recordControls(),
          if (!_permissionDenied && _showGuidance && _error == null)
            _guidanceOverlay(),
        ],
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

  Widget _closeButton() {
    final double top = MediaQuery.of(context).padding.top;
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, top + 8, 12, 12),
        child: Material(
          color: Colors.black.withOpacity(0.45),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _handleClose,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.close_rounded, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _wideButton() {
    final double bottom = MediaQuery.of(context).padding.bottom;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom + 118),
        child: GestureDetector(
          onTap: _toggleWide,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.45),
              border: Border.all(
                color: _isWide ? const Color(0xFF1D9E75) : Colors.white54,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                _isWide ? '0.5x' : '1x',
                style: TextStyle(
                  color: _isWide ? const Color(0xFF1D9E75) : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // [v4] Small gallery button, shown to the left of the record button.
  Widget _galleryButton() {
    return GestureDetector(
      onTap: _busy ? null : _pickFromGallery,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.45),
          border: Border.all(color: Colors.white54, width: 1.5),
        ),
        child: const Icon(
          Icons.photo_library_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _recordControls() {
    final double bottom = MediaQuery.of(context).padding.bottom;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isRecording)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    _RecDot(),
                    SizedBox(width: 8),
                    Text('Recording',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // [v4] Gallery - hidden while recording.
                SizedBox(
                  width: 48,
                  height: 48,
                  child: _isRecording ? null : _galleryButton(),
                ),
                const SizedBox(width: 28),
                GestureDetector(
                  onTap: _busy
                      ? null
                      : (_isRecording ? _stopRecording : _startRecording),
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.25),
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: _isRecording ? 30 : 58,
                        height: _isRecording ? 30 : 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE24B4A),
                          borderRadius:
                              BorderRadius.circular(_isRecording ? 8 : 40),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 28),
                // Spacer mirroring the gallery button to keep symmetry.
                const SizedBox(width: 48, height: 48),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _guidanceOverlay() {
    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Container(
        color: Colors.black.withOpacity(0.62),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.videocam_rounded,
                  size: 34, color: Color(0xFF1D9E75)),
              const SizedBox(height: 12),
              const Text(
                _guidanceTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                _guidanceSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF6B6B6B)),
              ),
              const SizedBox(height: 18),
              ..._guidanceLines.map((line) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.check_circle_rounded,
                              size: 18, color: Color(0xFF1D9E75)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            line,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: Color(0xFF2C2C2A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => setState(() => _showGuidance = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9E75),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Got it, let's go",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

class _RecDot extends StatelessWidget {
  const _RecDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: Color(0xFFE24B4A),
        shape: BoxShape.circle,
      ),
    );
  }
}
