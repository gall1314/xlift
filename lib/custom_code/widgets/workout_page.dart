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
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// =============================================================================
// WorkoutPage — the whole live-workout screen.
//
// Top bar (back · WorkoutClock · Finish) with the progress line under it, a
// scrolling list of ExerciseCard (one per exercise, in exercisesets order) and
// "Add Exercises" at the bottom. Reads App State directly and rebuilds on
// every change. Give it width ∞ and height ∞ in FF; nothing else to set.
//
// Callbacks (navigation only):
//   onBack(), onFinish(), onAddExercises()
//   onHeaderTap(exerciseId), onCustomHeaderTap(exerciseId), onReplaceExercise(exerciseId),
//   onSupersetTap(exerciseId), onViewHistory(exerciseId),
//   onReorder(), onRemoveExercise(exerciseId)
//   onResultTap(exerciseId, exerciseName, setNumber, video), onLockTap()
//   onStartRest(exerciseId, exerciseName, setNumber, restMs), onDontShowAgain()
// =============================================================================

const Set<String> _kRtl = {'he', 'ar'};

String _langOf(BuildContext ctx) {
  try {
    final l = FFLocalizations.of(ctx).languageCode.trim().toLowerCase();
    return l.isEmpty ? 'en' : l;
  } catch (_) {
    return 'en';
  }
}

const Map<String, Map<String, String>> _kStrings = {
  "finish": {
    "en": "Finish",
    "es": "Terminar",
    "he": "סיום",
    "de": "Fertig",
    "fr": "Terminer"
  },
  "addExercises": {
    "en": "Add Exercises",
    "es": "Añadir ejercicios",
    "he": "הוסף תרגילים",
    "de": "Übungen hinzufügen",
    "fr": "Ajouter des exercices"
  },
  "empty": {
    "en": "No exercises yet",
    "es": "Aún no hay ejercicios",
    "he": "עדיין אין תרגילים",
    "de": "Noch keine Übungen",
    "fr": "Pas encore d’exercices"
  },
};

String _tr(String lang, String key) {
  final m = _kStrings[key];
  return m == null ? key : (m[lang] ?? m['en'] ?? key);
}

int _asInt(dynamic v, [int d = 0]) {
  if (v == null) return d;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim()) ?? d;
}

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({
    super.key,
    this.width,
    this.height,
    this.isLiveWorkout = true,
    this.showCameraGuidance,
    this.onBack,
    this.onFinish,
    this.onAddExercises,
    this.onHeaderTap,
    this.onCustomHeaderTap,
    this.onReplaceExercise,
    this.onSupersetTap,
    this.onViewHistory,
    this.onCustomViewHistory,
    this.onReorder,
    this.onRemoveExercise,
    this.onResultTap,
    this.onLockTap,
    this.onStartRest,
    this.onDontShowAgain,
  });

  final double? width;
  final double? height;

  /// true → live App State lists; false → the *Creation lists.
  final bool isLiveWorkout;
  final bool? showCameraGuidance;

  final Future Function()? onBack;
  final Future Function()? onFinish;
  final Future Function()? onAddExercises;
  final Future Function(int exerciseId)? onHeaderTap;
  final Future Function(int exerciseId)? onCustomHeaderTap;
  final Future Function(int exerciseId)? onReplaceExercise;
  final Future Function(int exerciseId)? onSupersetTap;
  final Future Function(int exerciseId)? onViewHistory;
  final Future Function(int exerciseId)? onCustomViewHistory;
  final Future Function()? onReorder;
  final Future Function(int exerciseId)? onRemoveExercise;
  final Future Function(int exerciseId, String exerciseName, int setNumber,
      FFUploadedFile? video)? onResultTap;
  final Future Function()? onLockTap;
  final Future Function(
          int exerciseId, String exerciseName, int setNumber, int restMs)?
      onStartRest;
  final Future Function()? onDontShowAgain;

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool get _live => widget.isLiveWorkout;

  List<dynamic> get _exerciseSets => List<dynamic>.from(
      _live ? FFAppState().exercisesets : FFAppState().exerciseSetsCretion);
  List<dynamic> get _loggedSets => List<dynamic>.from(
      _live ? FFAppState().loggedSets : FFAppState().loggedSetsCreation);

  /// Exercise ids in template order.
  List<int> get _ids {
    final out = <int>[];
    for (final e in _exerciseSets) {
      if (e is Map) {
        final id = _asInt(e['exerciseId'], -1);
        if (id >= 0 && !out.contains(id)) out.add(id);
      }
    }
    return out;
  }

  double get _progress {
    try {
      return workoutProgress(_exerciseSets, _loggedSets)
          .clamp(0.0, 1.0)
          .toDouble();
    } catch (_) {
      return 0.0;
    }
  }

  static TextStyle _ts(
          FlutterFlowTheme th, double size, FontWeight w, Color c) =>
      th.bodyMedium.override(
        fontFamily: th.bodyMediumFamily,
        color: c,
        fontSize: size,
        fontWeight: w,
        useGoogleFonts: GoogleFonts.asMap().containsKey(th.bodyMediumFamily),
      );

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final theme = FlutterFlowTheme.of(context);
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final ids = _ids;
    final double progress = _progress;
    final bool canFinish = progress > 0;
    final Color border =
        dark ? const Color(0xFF2A3644) : const Color(0xFFE3E7EB);
    final DateTime startedAt =
        FFAppState().activeWorkoutStartTime ?? DateTime.now();
    final double topInset = MediaQuery.of(context).padding.top;
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    final Widget topBar = Container(
      color: theme.secondaryBackground,
      padding: EdgeInsets.fromLTRB(8, topInset + 6, 12, 10),
      child: Row(
        children: [
          _Tap(
            onTap: () => widget.onBack?.call(),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                  rtl
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  size: 32,
                  color: theme.primaryText),
            ),
          ),
          Expanded(
            child: _live
                ? WorkoutClock(
                    startedAt: startedAt,
                    fontSize: 24,
                    color: theme.primaryText)
                : const SizedBox.shrink(),
          ),
          _Tap(
            onTap: () => widget.onFinish?.call(),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: canFinish ? theme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border:
                    canFinish ? null : Border.all(color: border, width: 1.5),
              ),
              child: Text(_tr(lang, 'finish'),
                  style: _ts(theme, 17, FontWeight.w700,
                      canFinish ? Colors.white : theme.secondaryText)),
            ),
          ),
        ],
      ),
    );

    final Widget progressLine = SizedBox(
      height: 4,
      child: Stack(
        children: [
          Container(color: border),
          FractionallySizedBox(
            widthFactor: progress,
            alignment: rtl ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(color: theme.primary),
          ),
        ],
      ),
    );

    final Widget addButton = _Tap(
      onTap: () => widget.onAddExercises?.call(),
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: theme.primary, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 24, color: Colors.white),
            const SizedBox(width: 8),
            Text(_tr(lang, 'addExercises'),
                style: _ts(theme, 18, FontWeight.w700, Colors.white)),
          ],
        ),
      ),
    );

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Container(
        width: widget.width,
        height: widget.height,
        color: theme.primaryBackground,
        child: Column(
          children: [
            topBar,
            progressLine,
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: ids.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == ids.length) {
                    return Padding(
                      padding: EdgeInsets.only(top: ids.isEmpty ? 40 : 8),
                      child: Column(
                        children: [
                          if (ids.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(_tr(lang, 'empty'),
                                  style: _ts(theme, 16, FontWeight.w500,
                                      theme.secondaryText)),
                            ),
                          addButton,
                        ],
                      ),
                    );
                  }
                  final int id = ids[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ExerciseCard(
                      key: ValueKey('exercise_$id'),
                      exerciseId: id,
                      isLiveWorkout: _live,
                      exerciseCount: ids.length,
                      showCameraGuidance: widget.showCameraGuidance,
                      onHeaderTap: () async => widget.onHeaderTap?.call(id),
                      onCustomHeaderTap: () async =>
                          widget.onCustomHeaderTap?.call(id),
                      onReplaceExercise: () async =>
                          widget.onReplaceExercise?.call(id),
                      onSupersetTap: () async => widget.onSupersetTap?.call(id),
                      onViewHistory: () async => widget.onViewHistory?.call(id),
                      onCustomViewHistory: () async =>
                          widget.onCustomViewHistory?.call(id),
                      onReorder: () async => widget.onReorder?.call(),
                      onRemoveExercise: () async =>
                          widget.onRemoveExercise?.call(id),
                      onResultTap: (name, setNumber, video) async =>
                          widget.onResultTap?.call(id, name, setNumber, video),
                      onLockTap: () async => widget.onLockTap?.call(),
                      onStartRest: widget.onStartRest,
                      onDontShowAgain: widget.onDontShowAgain,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tap extends StatefulWidget {
  const _Tap({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;
  @override
  State<_Tap> createState() => _TapState();
}

class _TapState extends State<_Tap> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: _down ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: widget.child,
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
