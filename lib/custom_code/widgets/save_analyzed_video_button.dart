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

import 'package:flutter/services.dart';
import '/custom_code/actions/save_analyzed_video_to_gallery.dart';

// ============================================================================
// Global export registry. The render runs independently of any widget, keyed
// by the video URI, so closing/reopening the sheet re-attaches to the SAME
// job and shows its real progress instead of a fresh idle button.
// ============================================================================
enum _JobPhase { running, saved, error }

class _JobState {
  final _JobPhase phase;
  final double progress;
  final String stage;
  const _JobState(this.phase, this.progress, this.stage);
}

class _ExportJobs {
  static final Map<String, ValueNotifier<_JobState>> _jobs = {};

  static String keyFor(dynamic analysisResult) {
    try {
      if (analysisResult is Map) {
        Map m = analysisResult;
        if (!m.containsKey('_source_video_uri') &&
            !m.containsKey('video_path') &&
            m['analysis'] is Map) {
          m = m['analysis'] as Map;
        }
        final v = m['_source_video_uri'] ?? m['video_path'];
        if (v != null && v.toString().isNotEmpty) return v.toString();
      }
    } catch (_) {}
    return 'unknown';
  }

  static ValueNotifier<_JobState>? get(String key) => _jobs[key];

  static ValueNotifier<_JobState> start(String key, dynamic analysisResult) {
    final existing = _jobs[key];
    if (existing != null && existing.value.phase == _JobPhase.running) {
      return existing;
    }
    final notifier = ValueNotifier<_JobState>(
        const _JobState(_JobPhase.running, 0, 'extract'));
    _jobs[key] = notifier;

    () async {
      bool ok = false;
      try {
        ok = await saveAnalyzedVideoWithProgress(
          analysisResult,
          (f, stage) => notifier.value = _JobState(_JobPhase.running, f, stage),
        );
      } catch (_) {
        ok = false;
      }
      notifier.value = _JobState(
          ok ? _JobPhase.saved : _JobPhase.error, ok ? 1.0 : 0.0, 'done');
      // Forget finished jobs after a while so a later tap can re-save.
      Future.delayed(const Duration(seconds: 4), () {
        if (_jobs[key] == notifier &&
            notifier.value.phase != _JobPhase.running) {
          _jobs.remove(key);
        }
      });
    }();

    return notifier;
  }
}

/// "Save analyzed video" button.
///
/// [compact] = 48x48 circle (icon only, progress ring around it) for
/// toolbars/corners. Otherwise a full-width pill with label. Progress
/// survives closing and reopening the sheet (global job registry). Pass the
/// same [analysisResult] you pass to the analyzed video player.
class SaveAnalyzedVideoButton extends StatefulWidget {
  const SaveAnalyzedVideoButton({
    super.key,
    this.width,
    this.height,
    required this.analysisResult,
    this.label,
    this.accentColor,
    this.compact = false,
  });

  final double? width;
  final double? height;
  final dynamic analysisResult;
  final String? label;
  final Color? accentColor;
  final bool compact;

  @override
  State<SaveAnalyzedVideoButton> createState() =>
      _SaveAnalyzedVideoButtonState();
}

class _SaveAnalyzedVideoButtonState extends State<SaveAnalyzedVideoButton>
    with SingleTickerProviderStateMixin {
  late String _key;
  ValueNotifier<_JobState>? _job;
  _JobState? _shownFinal; // saved/error we already reacted to
  bool _justFinishedShown = false;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _key = _ExportJobs.keyFor(widget.analysisResult);
    _attach(_ExportJobs.get(_key));
  }

  @override
  void didUpdateWidget(covariant SaveAnalyzedVideoButton old) {
    super.didUpdateWidget(old);
    final k = _ExportJobs.keyFor(widget.analysisResult);
    if (k != _key) {
      _key = k;
      _attach(_ExportJobs.get(_key));
    }
  }

  void _attach(ValueNotifier<_JobState>? job) {
    _job?.removeListener(_onJob);
    _job = job;
    _job?.addListener(_onJob);
    if (mounted) setState(() {});
  }

  void _onJob() {
    if (!mounted) return;
    final s = _job?.value;
    setState(() {});
    if (s == null) return;
    if (s.phase == _JobPhase.saved && !_justFinishedShown) {
      _justFinishedShown = true;
      HapticFeedback.mediumImpact();
      _showSnack(
        title: 'Saved to Photos',
        subtitle: 'Find it in the Xlift album',
        icon: Icons.check_rounded,
      );
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _justFinishedShown = false);
      });
    } else if (s.phase == _JobPhase.error && !_justFinishedShown) {
      _justFinishedShown = true;
      HapticFeedback.heavyImpact();
      _showSnack(
        title: "Couldn't save the video",
        subtitle: 'Tap the button to try again',
        icon: Icons.error_outline_rounded,
        danger: true,
      );
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _justFinishedShown = false);
      });
    }
  }

  @override
  void dispose() {
    _job?.removeListener(_onJob);
    _pulse.dispose();
    super.dispose();
  }

  Color get _accent =>
      widget.accentColor ?? FlutterFlowTheme.of(context).primary;

  void _showSnack({
    required String title,
    required String subtitle,
    required IconData icon,
    bool danger = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: duration,
        backgroundColor: const Color(0xFF1E2731),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: danger ? const Color(0xFFE5484D) : _accent,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFFB8C1CC), fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _tap() {
    final s = _job?.value;
    if (s != null && s.phase == _JobPhase.running) {
      // Already saving this video - just remind.
      HapticFeedback.selectionClick();
      _showSnack(
        title: 'Still saving… ${(s.progress * 100).round()}%',
        subtitle: 'Keep the app open, almost there',
        icon: Icons.hourglass_top_rounded,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    HapticFeedback.selectionClick();
    _justFinishedShown = false;
    _showSnack(
      title: 'Saving your video…',
      subtitle: 'Takes about 20–30 seconds. Keep the app open.',
      icon: Icons.movie_creation_outlined,
      duration: const Duration(seconds: 4),
    );
    _attach(_ExportJobs.start(_key, widget.analysisResult));
  }

  String _stageText(String stage) {
    switch (stage) {
      case 'extract':
        return 'Preparing…';
      case 'render':
        return 'Drawing overlays…';
      case 'encode':
        return 'Encoding…';
      case 'save':
        return 'Saving to Photos…';
      default:
        return 'Working…';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final Color accent = _accent;
    final _JobState? s = _job?.value;
    final bool running = s?.phase == _JobPhase.running;
    final bool saved = s?.phase == _JobPhase.saved && _justFinishedShown;
    final bool error = s?.phase == _JobPhase.error && _justFinishedShown;
    final double progress = (s?.progress ?? 0).clamp(0.0, 1.0);

    if (widget.compact)
      return _compact(accent, running, saved, error, progress);
    return _full(
        theme, accent, running, saved, error, progress, s?.stage ?? '');
  }

  // ---------------- compact: 48x48 circle with progress ring ----------------
  Widget _compact(
      Color accent, bool running, bool saved, bool error, double progress) {
    final double size = widget.height ?? widget.width ?? 48;
    final Color bg = error
        ? const Color(0xFFE5484D)
        : (saved ? const Color(0xFF2E9E6B) : accent);

    Widget inner;
    if (running) {
      final int pct = (progress * 100).round();
      inner = Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size - 6,
            height: size - 6,
            child: CircularProgressIndicator(
              value: progress <= 0.02 ? null : progress,
              strokeWidth: 3,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          Text('$pct',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w700,
                  height: 1.0)),
        ],
      );
    } else if (saved) {
      inner = Icon(Icons.check_rounded, color: Colors.white, size: size * 0.5);
    } else if (error) {
      inner = Icon(Icons.priority_high_rounded,
          color: Colors.white, size: size * 0.5);
    } else {
      inner =
          Icon(Icons.download_rounded, color: Colors.white, size: size * 0.5);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Transform.scale(
          scale: running ? 1.0 + 0.04 * _pulse.value : 1.0,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: bg.withOpacity(0.35),
                blurRadius: running ? 14 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(child: inner),
        ),
      ),
    );
  }

  // ---------------- full-width pill ----------------
  Widget _full(FlutterFlowTheme theme, Color accent, bool running, bool saved,
      bool error, double progress, String stage) {
    final double h = widget.height ?? 52;
    final Color bg = error
        ? const Color(0xFFE5484D)
        : (saved ? const Color(0xFF2E9E6B) : accent);
    final String label = widget.label ?? 'Save analyzed video';

    Widget child;
    if (running) {
      final int pct = (progress * 100).round();
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              value: progress <= 0.02 ? null : progress,
              strokeWidth: 2.5,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Text('${_stageText(stage)} $pct%',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ],
      );
    } else if (saved) {
      child = const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('Saved to Photos',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ],
      );
    } else if (error) {
      child = const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text("Couldn't save — tap to retry",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ],
      );
    } else {
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.download_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ],
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.width ?? double.infinity,
              height: h,
              color: bg,
            ),
            // Progress fill sweeping left -> right behind the label.
            if (running)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(color: Colors.white.withOpacity(0.18)),
                  ),
                ),
              ),
            SizedBox(
              width: widget.width ?? double.infinity,
              height: h,
              child: Center(child: child),
            ),
          ],
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
