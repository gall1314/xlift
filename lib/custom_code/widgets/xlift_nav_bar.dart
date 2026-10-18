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

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';

/// Xlift bottom nav bar with a raised center FAB for AI form analysis.
///
/// Tab order: Home · History · [FAB] · Stats · Library. currentPage:
/// 'history' | 'stats' | 'home' | 'library' (highlights that tab).
/// showFabLock: small lock badge on the FAB (free quota exhausted). isDark:
/// null = auto from theme.
///
/// FAB flow (v4) — runs entirely inside this widget, no FF callbacks between
/// the steps: tap FAB -> AnalyzeExercisePicker (bottom sheet) ->
/// XliftCameraRecorder (full-screen route) -> analyzing page (runs
/// analyzeExerciseVideoAction) -> onAnalysisDone(analysisResult).
/// analysisResult is the analyzer map PLUS `exercise_id`, `exercise_name` and
/// `is_bodyweight` (0/1 from SQLite exercise.is_bodyweight), so FF needs only
/// this one callback parameter to navigate to the result page ($.exercise_id,
/// $.exercise_name, $.is_bodyweight). When showFabLock is true the FAB only
/// fires onFabTap (paywall) instead.
///
/// FAB icon (v3): the app-wide "AI Form" glyph - a video camera with a
/// sparkle inside (same drawing as AiFormBadge / AiFormButton). 3s loop: the
/// sparkle twinkles (grows + quarter turn) and two small sparkles pop briefly
/// next to the camera. On tap the camera body flashes white (shutter).
class XliftNavBar extends StatefulWidget {
  const XliftNavBar({
    super.key,
    this.width,
    this.height,
    required this.currentPage,
    this.showFabLock = false,
    this.isDark,
    this.userId,
    this.showCameraGuidance,
    this.onHistoryTap,
    this.onStatsTap,
    this.onHomeTap,
    this.onLibraryTap,
    this.onFabTap,
    this.onDontShowAgain,
    this.onAnalysisDone,
  });

  final double? width;
  final double? height;
  final String currentPage;
  final bool showFabLock;
  final bool? isDark;

  /// Needed by the picker (Recent / last scores). Empty = no Recent row.
  final String? userId;

  /// Show the camera setup tips first. Default true.
  final bool? showCameraGuidance;

  final Future Function()? onHistoryTap;
  final Future Function()? onStatsTap;
  final Future Function()? onHomeTap;
  final Future Function()? onLibraryTap;

  /// Fired ONLY when showFabLock is true (quota exhausted -> paywall).
  final Future Function()? onFabTap;

  /// User tapped "Don't show this again" on the camera tips.
  final Future Function()? onDontShowAgain;

  /// Analysis finished successfully. analysisResult = analyzer map +
  /// `exercise_id` (int) + `exercise_name` (String) + `is_bodyweight` (0/1).
  final Future Function(dynamic analysisResult)? onAnalysisDone;

  @override
  State<XliftNavBar> createState() => _XliftNavBarState();
}

class _XliftNavBarState extends State<XliftNavBar>
    with TickerProviderStateMixin {
  late final AnimationController _loopCtrl;
  late final AnimationController _shutterCtrl;

  static const double _fabSize = 60;
  static const double _fabLift = 28; // how much the FAB floats above the bar
  static const double _ringWidth = 4; // background-colored ring around FAB

  String? _pressed;
  bool _fabPressed = false;
  bool _flowOpen = false;

  @override
  void initState() {
    super.initState();
    _loopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _shutterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _loopCtrl.dispose();
    _shutterCtrl.dispose();
    super.dispose();
  }

  // ===========================================================================
  // AI analyze flow (picker -> camera -> analyzing -> onAnalysisDone)
  // ===========================================================================

  NavigatorState get _nav => Navigator.of(context, rootNavigator: true);

  void _onFab() {
    if (widget.showFabLock) {
      widget.onFabTap?.call();
      return;
    }
    _openPicker();
  }

  Future<void> _openPicker() async {
    if (_flowOpen) return;
    _flowOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: false,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) => FractionallySizedBox(
          heightFactor: 0.85,
          child: AnalyzeExercisePicker(
            userId: widget.userId ?? '',
            onPick: (int exerciseId, String exerciseName) async {
              Navigator.of(sheetCtx).pop();
              // Let the sheet close before pushing the camera.
              await Future.delayed(const Duration(milliseconds: 220));
              await _openCamera(exerciseId, exerciseName);
            },
            onClose: () async => Navigator.of(sheetCtx).pop(),
          ),
        ),
      );
    } finally {
      _flowOpen = false;
    }
  }

  Future<void> _openCamera(int exerciseId, String exerciseName) async {
    if (!mounted) return;
    await _nav.push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (ctx, a, b) => _CameraPage(
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          showGuidance: widget.showCameraGuidance ?? true,
          onDontShowAgain: widget.onDontShowAgain,
          onAnalysisDone: widget.onAnalysisDone,
        ),
        transitionsBuilder: (ctx, anim, sec, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool dark =
        widget.isDark ?? (Theme.of(context).brightness == Brightness.dark);

    final Color barColor = dark ? const Color(0xFF141A21) : Colors.white;
    // Ring matches the PAGE background so the FAB visually detaches
    // from the bar line (classic notched-FAB look without a notch).
    final Color ringColor =
        dark ? const Color(0xFF0B0F14) : const Color(0xFFF0F2F5);
    final Color active =
        dark ? const Color(0xFF2DD4BF) : const Color(0xFF14B8A6);
    final Color inactive =
        dark ? const Color(0xFF6B7683) : const Color(0xFF9CA3AF);
    final Color fabColor =
        dark ? const Color(0xFF2DD4BF) : const Color(0xFF14B8A6);

    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double barHeight = 62 + bottomInset;
    final double fabOuter = _fabSize + _ringWidth * 2;

    return SizedBox(
      height: barHeight + _fabLift + _ringWidth,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // ---- The bar ----
          Container(
            height: barHeight,
            padding: EdgeInsets.only(bottom: bottomInset),
            decoration: BoxDecoration(
              color: barColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(dark ? 0.35 : 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                _tab('home', Icons.home_rounded, 'Home', active, inactive, dark,
                    widget.onHomeTap),
                _tab('history', Icons.history_rounded, 'History', active,
                    inactive, dark, widget.onHistoryTap),
                const Expanded(child: SizedBox()), // FAB slot
                _tab('stats', Icons.query_stats_rounded, 'Stats', active,
                    inactive, dark, widget.onStatsTap),
                _tab('library', Icons.menu_book_rounded, 'Library', active,
                    inactive, dark, widget.onLibraryTap),
              ],
            ),
          ),

          // ---- The floating FAB ----
          Positioned(
            top: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => setState(() => _fabPressed = true),
              onTapCancel: () => setState(() => _fabPressed = false),
              onTapUp: (_) {
                setState(() => _fabPressed = false);
                HapticFeedback.mediumImpact();
                _shutterCtrl.forward(from: 0);
                _onFab();
              },
              child: AnimatedScale(
                scale: _fabPressed ? 0.90 : 1.0,
                duration: const Duration(milliseconds: 110),
                curve: Curves.easeOut,
                child: Container(
                  width: fabOuter,
                  height: fabOuter,
                  decoration: BoxDecoration(
                    color: ringColor,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(_ringWidth),
                  child: Container(
                    decoration: BoxDecoration(
                      color: fabColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        // Teal glow
                        BoxShadow(
                          color:
                              fabColor.withOpacity(_fabPressed ? 0.25 : 0.50),
                          blurRadius: _fabPressed ? 10 : 20,
                          spreadRadius: _fabPressed ? 0 : 1,
                          offset: Offset(0, _fabPressed ? 3 : 6),
                        ),
                        // Soft dark shadow for depth
                        BoxShadow(
                          color: Colors.black.withOpacity(dark ? 0.45 : 0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation:
                              Listenable.merge([_loopCtrl, _shutterCtrl]),
                          builder: (context, _) => CustomPaint(
                            size: const Size(_fabSize, _fabSize),
                            painter: _AiCameraGlyphPainter(
                              t: _loopCtrl.value,
                              shutter: _shutterCtrl.value,
                              fg: Colors.white,
                            ),
                          ),
                        ),
                        if (widget.showFabLock)
                          Positioned(
                            right: 1,
                            top: 1,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: dark
                                    ? const Color(0xFF141A21)
                                    : Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.lock_rounded,
                                  size: 11, color: fabColor),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(
    String id,
    IconData icon,
    String label,
    Color active,
    Color inactive,
    bool dark,
    Future Function()? onTap,
  ) {
    final bool selected = widget.currentPage.toLowerCase() == id;
    final bool pressed = _pressed == id;
    final Color c = selected ? active : inactive;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = id),
        onTapCancel: () => setState(() => _pressed = null),
        onTapUp: (_) {
          setState(() => _pressed = null);
          if (!selected) HapticFeedback.selectionClick();
          onTap?.call();
        },
        child: AnimatedScale(
          scale: pressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: pressed ? 0.6 : 1.0,
            duration: const Duration(milliseconds: 110),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: c),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
                      fontSize: 11,
                      color: c,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Camera page: hosts XliftCameraRecorder full screen. A recorded/picked clip
// replaces this page with the analyzing page.
// ===========================================================================

class _CameraPage extends StatelessWidget {
  const _CameraPage({
    required this.exerciseId,
    required this.exerciseName,
    required this.showGuidance,
    required this.onDontShowAgain,
    required this.onAnalysisDone,
  });

  final int exerciseId;
  final String exerciseName;
  final bool showGuidance;
  final Future Function()? onDontShowAgain;
  final Future Function(dynamic analysisResult)? onAnalysisDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: XliftCameraRecorder(
        width: double.infinity,
        height: double.infinity,
        exerciseName: exerciseName,
        showGuidance: showGuidance,
        onClose: () async => Navigator.of(context).pop(),
        onDontShowAgain: onDontShowAgain,
        onVideoRecorded: (FFUploadedFile videoFile) async {
          await Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              opaque: true,
              transitionDuration: const Duration(milliseconds: 260),
              pageBuilder: (ctx, a, b) => _AnalyzingPage(
                videoFile: videoFile,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                onAnalysisDone: onAnalysisDone,
              ),
              transitionsBuilder: (ctx, anim, sec, child) =>
                  FadeTransition(opacity: anim, child: child),
            ),
          );
        },
      ),
    );
  }
}

// ===========================================================================
// Analyzing page: runs the dispatcher, shows progress, then pops itself and
// hands the result to FF via onAnalysisDone.
// ===========================================================================

class _AnalyzingPage extends StatefulWidget {
  const _AnalyzingPage({
    required this.videoFile,
    required this.exerciseId,
    required this.exerciseName,
    required this.onAnalysisDone,
  });

  final FFUploadedFile videoFile;
  final int exerciseId;
  final String exerciseName;
  final Future Function(dynamic analysisResult)? onAnalysisDone;

  @override
  State<_AnalyzingPage> createState() => _AnalyzingPageState();
}

class _AnalyzingPageState extends State<_AnalyzingPage>
    with SingleTickerProviderStateMixin {
  static const Color _bg = Color(0xFF0F1A1A);
  static const Color _teal = Color(0xFF14B8A6);

  static const List<String> _stages = [
    'Extracting frames…',
    'Detecting your pose…',
    'Counting reps…',
    'Scoring technique…',
    'Almost there…',
  ];

  late final AnimationController _spin;
  Timer? _stageTimer;
  int _stage = 0;
  double _fakeProgress = 0.0;
  String? _error;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _startStageTicker();
    _run();
  }

  @override
  void dispose() {
    _stageTimer?.cancel();
    _spin.dispose();
    super.dispose();
  }

  // Stage label advances every ~6s; bar eases toward 90% over ~40s.
  void _startStageTicker() {
    _stageTimer?.cancel();
    _stage = 0;
    _fakeProgress = 0.0;
    int ticks = 0;
    _stageTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      ticks++;
      setState(() {
        _fakeProgress = 0.9 * (1 - math.exp(-ticks / 40.0));
        if (ticks % 12 == 0 && _stage < _stages.length - 1) _stage++;
      });
    });
  }

  Future<void> _run() async {
    if (_running) return;
    _running = true;
    setState(() => _error = null);
    _startStageTicker();

    dynamic result;
    try {
      result = await analyzeExerciseVideoAction(
        widget.videoFile,
        widget.exerciseName,
        null,
      );
    } catch (e) {
      result = {'error': 'exception', 'detail': e.toString()};
    }
    _stageTimer?.cancel();
    if (!mounted) return;

    final Map<String, dynamic> map = result is Map
        ? Map<String, dynamic>.from(result)
        : <String, dynamic>{'error': 'bad_result', 'detail': '$result'};

    if (map['error'] != null) {
      setState(() {
        _error = (map['detail'] ?? map['error']).toString();
        _running = false;
      });
      return;
    }

    // Attach the exercise so FF needs only this one callback parameter:
    //   $.exercise_id, $.exercise_name, $.is_bodyweight
    map['exercise_id'] = widget.exerciseId;
    map['exercise_name'] = widget.exerciseName;
    int isBodyweight = 0;
    try {
      final rows = await SQLiteManager.instance.database.rawQuery(
        'SELECT is_bodyweight FROM exercise WHERE id = ? LIMIT 1',
        [widget.exerciseId],
      );
      if (rows.isNotEmpty) {
        final v = rows.first['is_bodyweight'];
        final int n = v is num ? v.toInt() : (int.tryParse('$v') ?? 0);
        isBodyweight = n != 0 ? 1 : 0;
      }
    } catch (_) {}
    map['is_bodyweight'] = isBodyweight;

    setState(() => _fakeProgress = 1.0);
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    final nav = Navigator.of(context);
    nav.pop();
    _running = false;
    await widget.onAnalysisDone?.call(map);
  }

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _error == null ? _progress() : _failed(),
            ),
          ),
          if (_error != null)
            Positioned(
              left: 12,
              top: top + 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _progress() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 104,
          height: 104,
          child: Stack(
            alignment: Alignment.center,
            children: [
              RotationTransition(
                turns: _spin,
                child: CustomPaint(
                  size: const Size(104, 104),
                  painter: _ArcPainter(color: _teal),
                ),
              ),
              const Icon(Icons.auto_awesome_rounded, color: _teal, size: 30),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const Text(
          'Analyzing your set',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            '${widget.exerciseName} · ${_stages[_stage]}',
            key: ValueKey(_stage),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 22),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 220,
            height: 6,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: _fakeProgress),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOut,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                backgroundColor: Colors.white.withOpacity(0.10),
                valueColor: const AlwaysStoppedAnimation<Color>(_teal),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Text(
            'Keep the app open — about 20–40 seconds',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _failed() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline_rounded,
              color: Color(0xFFF59E0B), size: 36),
        ),
        const SizedBox(height: 22),
        const Text(
          "Couldn't analyze this video",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _error ?? '',
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 26),
        SizedBox(
          width: 220,
          height: 50,
          child: ElevatedButton(
            onPressed: _run,
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Try again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65), fontSize: 14)),
        ),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(3, 3, size.width - 6, size.height - 6);
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = Colors.white.withOpacity(0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 0.55,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => old.color != color;
}

/// App-wide "AI Form" glyph: video camera with a sparkle inside, drawn on
/// a 24x24 grid and centered in the FAB disc at half the disc size.
/// Loop: main sparkle twinkles, two small sparkles pop next to the camera.
/// Tap: camera body flashes white (shutter).
class _AiCameraGlyphPainter extends CustomPainter {
  _AiCameraGlyphPainter({
    required this.t,
    required this.shutter,
    required this.fg,
  });

  final double t; // 0..1 loop
  final double shutter; // 0..1 blink
  final Color fg;

  // Four-point sparkle centered on (0,0) with radius r.
  Path _sparkle(double r) {
    final double c = r * 0.2;
    return Path()
      ..moveTo(0, -r)
      ..cubicTo(c, -1.6 * c, 1.6 * c, -c, r, 0)
      ..cubicTo(1.6 * c, c, c, 1.6 * c, 0, r)
      ..cubicTo(-c, 1.6 * c, -1.6 * c, c, -r, 0)
      ..cubicTo(-1.6 * c, -c, -c, -1.6 * c, 0, -r)
      ..close();
  }

  // 0 -> 1 -> 0 while t goes from [start] to [end]; 0 outside.
  double _pulse(double start, double end) {
    if (t <= start || t >= end) return 0;
    return math.sin(math.pi * (t - start) / (end - start));
  }

  void _drawSparkle(
    Canvas canvas,
    Offset center,
    double r,
    double scale,
    double rotation,
    double opacity,
  ) {
    if (opacity <= 0 || scale <= 0) return;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.scale(scale);
    canvas.drawPath(
      _sparkle(r),
      Paint()
        ..color = fg.withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Glyph occupies half of the disc, centered.
    final double glyph = size.shortestSide * 0.5;
    final double k = glyph / 24.0;
    if (k <= 0) return;

    canvas.save();
    canvas.translate(
      (size.width - glyph) / 2,
      (size.height - glyph) / 2,
    );
    canvas.scale(k);

    final Paint line = Paint()
      ..color = fg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final RRect body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(2.5, 6, 13.5, 12),
      const Radius.circular(3),
    );

    // Shutter flash behind the outline (on tap).
    if (shutter > 0) {
      final double f = math.sin(shutter * math.pi); // 0 -> 1 -> 0
      canvas.drawRRect(
        body,
        Paint()..color = Colors.white.withOpacity(0.55 * f),
      );
    }

    // Camera body.
    canvas.drawRRect(body, line);

    // Camera wedge on the right.
    final Path wedge = Path()
      ..moveTo(16, 10.6)
      ..lineTo(21.5, 7.6)
      ..lineTo(21.5, 16.4)
      ..lineTo(16, 13.4);
    canvas.drawPath(wedge, line);

    // Main sparkle: twinkle during the first 40% of the loop.
    const double window = 0.4;
    double mainScale = 1.0;
    double mainRot = 0.0;
    if (t < window) {
      final double p = t / window;
      mainScale = 1.0 + 0.35 * math.sin(math.pi * p);
      mainRot = Curves.easeInOut.transform(p) * (math.pi / 2);
    }
    _drawSparkle(canvas, const Offset(9.25, 12), 3.6, mainScale, mainRot, 1.0);

    // Two small sparkles popping outside the camera, slightly staggered.
    final double a = _pulse(0.08, 0.42);
    _drawSparkle(canvas, const Offset(19.6, 3.4), 2.3, 0.4 + 0.6 * a,
        a * (math.pi / 4), a);

    final double b = _pulse(0.20, 0.54);
    _drawSparkle(canvas, const Offset(3.2, 21.2), 1.7, 0.4 + 0.6 * b,
        b * (math.pi / 4), b);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AiCameraGlyphPainter old) =>
      old.t != t || old.shutter != shutter || old.fg != fg;
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
