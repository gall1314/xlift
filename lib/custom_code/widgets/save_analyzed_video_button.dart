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

import 'dart:ui' as ui show TextDirection;
import 'package:flutter/services.dart';
import '/custom_code/actions/save_analyzed_video_to_gallery.dart';

// ---------------- Localization ----------------

const Set<String> _kRtl = {'he', 'ar'};

String _langOf(BuildContext ctx) {
  try {
    final l = FFLocalizations.of(ctx).languageCode.trim().toLowerCase();
    return l.isEmpty ? 'en' : l;
  } catch (_) {
    return 'en';
  }
}

/// {n} number.
const Map<String, Map<String, String>> _kStrings = {
  "save": {
    "en": "Save analyzed video",
    "es": "Guardar vídeo analizado",
    "he": "שמור את הווידאו המנותח",
    "de": "Analysiertes Video speichern",
    "fr": "Enregistrer la vidéo analysée"
  },
  "savedTitle": {
    "en": "Saved to Photos",
    "es": "Guardado en Fotos",
    "he": "נשמר בתמונות",
    "de": "In Fotos gespeichert",
    "fr": "Enregistré dans Photos"
  },
  "savedSub": {
    "en": "Find it in your Photos library",
    "es": "Lo encontrarás en tu galería",
    "he": "תמצא אותו בספריית התמונות",
    "de": "Du findest es in deiner Fotos-Mediathek",
    "fr": "Retrouvez-la dans votre photothèque"
  },
  "errTitle": {
    "en": "Couldn't save the video",
    "es": "No se pudo guardar el vídeo",
    "he": "לא הצלחנו לשמור את הווידאו",
    "de": "Video konnte nicht gespeichert werden",
    "fr": "Impossible d'enregistrer la vidéo"
  },
  "errSub": {
    "en": "Tap the button to try again",
    "es": "Toca el botón para reintentar",
    "he": "הקש על הכפתור כדי לנסות שוב",
    "de": "Zum Wiederholen tippen",
    "fr": "Touchez le bouton pour réessayer"
  },
  "errShort": {
    "en": "Couldn't save — tap to retry",
    "es": "Error — toca para reintentar",
    "he": "השמירה נכשלה — הקש לניסיון חוזר",
    "de": "Fehler — zum Wiederholen tippen",
    "fr": "Échec — touchez pour réessayer"
  },
  "stillTitle": {
    "en": "Still saving… {n}%",
    "es": "Guardando… {n}%",
    "he": "עדיין שומר… {n}%",
    "de": "Speichert noch… {n}%",
    "fr": "Enregistrement… {n}%"
  },
  "stillSub": {
    "en": "Keep the app open, almost there",
    "es": "Mantén la app abierta, ya casi",
    "he": "השאר את האפליקציה פתוחה, כמעט סיימנו",
    "de": "App geöffnet lassen, fast fertig",
    "fr": "Gardez l'app ouverte, c'est presque fini"
  },
  "savingTitle": {
    "en": "Saving your video…",
    "es": "Guardando tu vídeo…",
    "he": "שומר את הווידאו…",
    "de": "Video wird gespeichert…",
    "fr": "Enregistrement de la vidéo…"
  },
  "savingSub": {
    "en": "Takes about 20–30 seconds. Keep the app open.",
    "es": "Tarda unos 20–30 segundos. Mantén la app abierta.",
    "he": "לוקח כ-20–30 שניות. השאר את האפליקציה פתוחה.",
    "de": "Dauert ca. 20–30 Sekunden. App geöffnet lassen.",
    "fr": "Environ 20–30 secondes. Gardez l'app ouverte."
  },
  "stExtract": {
    "en": "Preparing…",
    "es": "Preparando…",
    "he": "מכין…",
    "de": "Vorbereiten…",
    "fr": "Préparation…"
  },
  "stRender": {
    "en": "Drawing overlays…",
    "es": "Dibujando capas…",
    "he": "מצייר שכבות…",
    "de": "Overlays zeichnen…",
    "fr": "Dessin des calques…"
  },
  "stEncode": {
    "en": "Encoding…",
    "es": "Codificando…",
    "he": "מקודד…",
    "de": "Kodieren…",
    "fr": "Encodage…"
  },
  "stSave": {
    "en": "Saving to Photos…",
    "es": "Guardando en Fotos…",
    "he": "שומר בתמונות…",
    "de": "In Fotos speichern…",
    "fr": "Enregistrement dans Photos…"
  },
  "stWork": {
    "en": "Working…",
    "es": "Procesando…",
    "he": "עובד…",
    "de": "Arbeitet…",
    "fr": "Traitement…"
  },
};

String _tr(String lang, String key, {int? n}) {
  final m = _kStrings[key];
  var s = m == null ? key : (m[lang] ?? m['en'] ?? key);
  if (n != null) s = s.replaceAll('{n}', '$n');
  return s;
}

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
///
/// Localization: reads the app language from FFLocalizations (no parameter).
/// [label] still overrides the idle caption when given.
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
  bool _justFinishedShown = false;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  String get _lang => _langOf(context);

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
    final lang = _lang;
    if (s.phase == _JobPhase.saved && !_justFinishedShown) {
      _justFinishedShown = true;
      HapticFeedback.mediumImpact();
      _showSnack(
        title: _tr(lang, 'savedTitle'),
        subtitle: _tr(lang, 'savedSub'),
        icon: Icons.check_rounded,
      );
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _justFinishedShown = false);
      });
    } else if (s.phase == _JobPhase.error && !_justFinishedShown) {
      _justFinishedShown = true;
      HapticFeedback.heavyImpact();
      _showSnack(
        title: _tr(lang, 'errTitle'),
        subtitle: _tr(lang, 'errSub'),
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
    final bool rtl = _kRtl.contains(_lang);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: duration,
        backgroundColor: const Color(0xFF1E2731),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Directionality(
          textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: Row(
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
      ),
    );
  }

  void _tap() {
    final lang = _lang;
    final s = _job?.value;
    if (s != null && s.phase == _JobPhase.running) {
      HapticFeedback.selectionClick();
      _showSnack(
        title: _tr(lang, 'stillTitle', n: (s.progress * 100).round()),
        subtitle: _tr(lang, 'stillSub'),
        icon: Icons.hourglass_top_rounded,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    HapticFeedback.selectionClick();
    _justFinishedShown = false;
    _showSnack(
      title: _tr(lang, 'savingTitle'),
      subtitle: _tr(lang, 'savingSub'),
      icon: Icons.movie_creation_outlined,
      duration: const Duration(seconds: 4),
    );
    _attach(_ExportJobs.start(_key, widget.analysisResult));
  }

  String _stageText(String lang, String stage) {
    switch (stage) {
      case 'extract':
        return _tr(lang, 'stExtract');
      case 'render':
        return _tr(lang, 'stRender');
      case 'encode':
        return _tr(lang, 'stEncode');
      case 'save':
        return _tr(lang, 'stSave');
      default:
        return _tr(lang, 'stWork');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final String lang = _lang;
    final Color accent = _accent;
    final _JobState? s = _job?.value;
    final bool running = s?.phase == _JobPhase.running;
    final bool saved = s?.phase == _JobPhase.saved && _justFinishedShown;
    final bool error = s?.phase == _JobPhase.error && _justFinishedShown;
    final double progress = (s?.progress ?? 0).clamp(0.0, 1.0);

    final Widget body = widget.compact
        ? _compact(accent, running, saved, error, progress)
        : _full(theme, lang, accent, running, saved, error, progress,
            s?.stage ?? '');

    return Directionality(
      textDirection:
          _kRtl.contains(lang) ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: body,
    );
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
  Widget _full(FlutterFlowTheme theme, String lang, Color accent, bool running,
      bool saved, bool error, double progress, String stage) {
    final double h = widget.height ?? 52;
    final Color bg = error
        ? const Color(0xFFE5484D)
        : (saved ? const Color(0xFF2E9E6B) : accent);
    final String? custom =
        (widget.label ?? '').trim().isEmpty ? null : widget.label;
    final String label = custom ?? _tr(lang, 'save');

    Widget txt(String s, {double size = 16}) => Flexible(
          child: Text(s,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: size,
                  fontWeight: FontWeight.w600)),
        );

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
          txt('${_stageText(lang, stage)} $pct%', size: 15),
        ],
      );
    } else if (saved) {
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          txt(_tr(lang, 'savedTitle')),
        ],
      );
    } else if (error) {
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 8),
          txt(_tr(lang, 'errShort'), size: 15),
        ],
      );
    } else {
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.download_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          txt(label),
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
            // Progress fill sweeping from the start edge behind the label.
            if (running)
              Positioned.fill(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(color: Colors.white.withOpacity(0.18)),
                  ),
                ),
              ),
            SizedBox(
              width: widget.width ?? double.infinity,
              height: h,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
