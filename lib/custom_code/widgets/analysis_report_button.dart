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

import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui show TextDirection;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// "Something off?
///
/// Report this analysis" - the quiet link at the bottom of the analysis
/// result, with its report sheet built in.
///
/// Tap -> bottom sheet (what was off, real rep count, optional note, attach
/// the video) -> Send. The report is written to the Hive box
/// `pendingAnalysisReports` at once and the sheet closes; `syncAllPending`
/// uploads it (video first, then the row) whenever there is a connection.
/// Nothing here waits for the network.
///
/// Give it width infinity and height 44.
///
/// Values in (all optional): - analysis     : the whole analysis JSON - the
/// same object the video player gets. Reps, perfect reps, score, feedback and
/// the video (_source_video_uri) are read from it. Accepted as it sits in App
/// State (wrapped in "analysis" and / or "result"), as the analyzer returns
/// it, or as a saved set_analysis row. Only small fields are sent (per-rep
/// list, counters, debug numbers); frame telemetry never is. - exerciseName :
/// the ENGLISH exercise name (same one the analyzer gets) When the video file
/// still exists the sheet offers to attach it; it is copied into the app's
/// Documents so it survives until sync. - setLogId     : the set this
/// analysis belongs to, when there is one
///
/// Callback: onReported() - after the report was queued.
///
/// Localization: reads the app language from FFLocalizations (no parameter).
class AnalysisReportButton extends StatefulWidget {
  const AnalysisReportButton({
    super.key,
    this.width,
    this.height,
    this.analysis,
    this.exerciseName,
    this.setLogId,
    this.onReported,
  });

  final double? width;
  final double? height;
  final dynamic analysis;
  final String? exerciseName;
  final String? setLogId;
  final Future Function()? onReported;

  @override
  State<AnalysisReportButton> createState() => _AnalysisReportButtonState();
}

const Set<String> _kRtl = {'he', 'ar'};

/// The "attach the video" switch starts on. Flip to false for a public
/// release if the default should be opt-in.
const bool _kVideoDefaultOn = true;

const String _kReportsBox = 'pendingAnalysisReports';
const String _kVideoDir = 'report_videos';

const Map<String, Map<String, String>> _kStrings = {
  "link": {
    "en": "Something off?",
    "es": "¿Algo no cuadra?",
    "he": "משהו לא מדויק?",
    "de": "Stimmt etwas nicht?",
    "fr": "Un souci ?"
  },
  "linkAction": {
    "en": "Report this analysis",
    "es": "Reportar el análisis",
    "he": "דיווח על הניתוח",
    "de": "Analyse melden",
    "fr": "Signaler l’analyse"
  },
  "sent": {
    "en": "Report sent. Thank you",
    "es": "Reporte enviado. Gracias",
    "he": "הדיווח נשלח. תודה",
    "de": "Meldung gesendet. Danke",
    "fr": "Signalement envoyé. Merci"
  },
  "title": {
    "en": "What was off?",
    "es": "¿Qué no cuadra?",
    "he": "מה לא היה מדויק?",
    "de": "Was stimmt nicht?",
    "fr": "Qu’est-ce qui cloche ?"
  },
  "sub": {
    "en": "Reports help us improve the analysis",
    "es": "Los reportes nos ayudan a mejorar el análisis",
    "he": "הדיווח עוזר לנו לשפר את הניתוח",
    "de": "Meldungen helfen uns, die Analyse zu verbessern",
    "fr": "Les signalements nous aident à améliorer l’analyse"
  },
  "rReps": {
    "en": "Rep count",
    "es": "Conteo de repeticiones",
    "he": "ספירת החזרות",
    "de": "Wiederholungen gezählt",
    "fr": "Nombre de répétitions"
  },
  "rScore": {
    "en": "Score doesn’t match",
    "es": "La nota no coincide",
    "he": "הציון לא תואם לביצוע",
    "de": "Bewertung passt nicht",
    "fr": "La note ne correspond pas"
  },
  "rFeedback": {
    "en": "Wrong feedback",
    "es": "Feedback incorrecto",
    "he": "המשוב לא נכון",
    "de": "Falsches Feedback",
    "fr": "Retour incorrect"
  },
  "rOther": {
    "en": "Something else",
    "es": "Otra cosa",
    "he": "משהו אחר",
    "de": "Etwas anderes",
    "fr": "Autre chose"
  },
  "actual": {
    "en": "Reps actually done",
    "es": "Repeticiones reales",
    "he": "חזרות שבוצעו בפועל",
    "de": "Tatsächliche Wiederholungen",
    "fr": "Répétitions réelles"
  },
  "note": {
    "en": "Add a note (optional)",
    "es": "Añadir una nota (opcional)",
    "he": "הערה (לא חובה)",
    "de": "Notiz hinzufügen (optional)",
    "fr": "Ajouter une note (facultatif)"
  },
  "video": {
    "en": "Attach the video",
    "es": "Adjuntar el video",
    "he": "צירוף הסרטון",
    "de": "Video anhängen",
    "fr": "Joindre la vidéo"
  },
  "videoSub": {
    "en": "The video is sent to the app team",
    "es": "El video se envía al equipo de la app",
    "he": "הסרטון נשלח לצוות האפליקציה",
    "de": "Das Video geht an das App-Team",
    "fr": "La vidéo est envoyée à l’équipe de l’app"
  },
  "send": {
    "en": "Send report",
    "es": "Enviar reporte",
    "he": "שליחת דיווח",
    "de": "Meldung senden",
    "fr": "Envoyer"
  },
  "less": {
    "en": "Less",
    "es": "Menos",
    "he": "פחות",
    "de": "Weniger",
    "fr": "Moins"
  },
  "more": {"en": "More", "es": "Más", "he": "יותר", "de": "Mehr", "fr": "Plus"},
};

String _tr(String lang, String key) {
  final m = _kStrings[key];
  return m == null ? key : (m[lang] ?? m['en'] ?? key);
}

String _langOf(BuildContext ctx) {
  try {
    final l = FFLocalizations.of(ctx).languageCode.trim().toLowerCase();
    return l.isEmpty ? 'en' : l;
  } catch (_) {
    return 'en';
  }
}

TextStyle _style(BuildContext ctx, double size, FontWeight w, Color c) {
  final th = FlutterFlowTheme.of(ctx);
  return th.bodyMedium.override(
    fontFamily: th.bodyMediumFamily,
    color: c,
    fontSize: size,
    fontWeight: w,
    letterSpacing: 0,
    useGoogleFonts: GoogleFonts.asMap().containsKey(th.bodyMediumFamily),
  );
}

/// A random RFC 4122 version 4 id.
String _newId() {
  final rnd = math.Random.secure();
  final b = List<int>.generate(16, (_) => rnd.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return h.substring(0, 8) +
      '-' +
      h.substring(8, 12) +
      '-' +
      h.substring(12, 16) +
      '-' +
      h.substring(16, 20) +
      '-' +
      h.substring(20);
}

/// The real file behind [raw] (a path or a file:// URI), or null. The
/// prefix is cut the same way AnalyzedVideoPlayerV2 does it.
File? _videoFile(String? raw) {
  final String s = (raw ?? '').trim();
  if (s.isEmpty) return null;
  try {
    final String path = s.startsWith('file://') ? s.substring(7) : s;
    final File f = File(path);
    return f.existsSync() ? f : null;
  } catch (_) {
    return null;
  }
}

// ---- keeping only the small, useful part of the analyzer result ----

const Set<String> _kDropKeys = {
  '_frame_telemetry',
  'signal_trace',
  'landmarks',
  'video_path',
  '_source_video_uri',
};

dynamic _slim(dynamic v, int depth) {
  if (v == null || v is String || v is bool || v is int) return v;
  if (v is double) return v.isFinite ? v : null;
  if (v is num) return v;
  if (depth > 4) return null;
  if (v is Map) {
    final Map<String, dynamic> out = {};
    v.forEach((k, val) {
      final String key = k.toString();
      if (_kDropKeys.contains(key)) return;
      out[key] = _slim(val, depth + 1);
    });
    return out;
  }
  if (v is List) {
    final int n = v.length > 80 ? 80 : v.length;
    return [for (int i = 0; i < n; i++) _slim(v[i], depth + 1)];
  }
  return v.toString();
}

/// The analysis map itself, whatever it arrived wrapped in: a JSON string,
/// the App State set entry ({setNumber, analysis: {...}}) or the
/// {result: {...}} envelope. Null when there is nothing usable.
Map? _unwrap(dynamic analysis) {
  dynamic a = analysis;
  if (a is String) {
    try {
      a = jsonDecode(a);
    } catch (_) {
      return null;
    }
  }
  for (int i = 0; i < 3; i++) {
    if (a is! Map) return null;
    if (a['analysis'] is Map) {
      a = a['analysis'];
    } else if (a['result'] is Map) {
      a = a['result'];
    } else {
      break;
    }
  }
  return a is Map ? a : null;
}

int? _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

/// Total reps. Every analyzer names its counter after the exercise
/// (squat_count, pullup_count, ...); a saved row calls it total_reps.
int? _totalReps(Map a) {
  for (final String k in const ['total_reps', 'rep_count', 'reps_count']) {
    final int? v = _toInt(a[k]);
    if (v != null) return v;
  }
  for (final e in a.entries) {
    final String k = e.key.toString();
    if (!k.endsWith('_count') || k == 'frame_count') continue;
    final int? v = _toInt(e.value);
    if (v != null) return v;
  }
  return null;
}

int? _properReps(Map a) => _toInt(a['good_reps'] ?? a['proper_reps']);

double? _score(Map a) {
  final dynamic v = a['technique_score'] ?? a['score'];
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim());
  return null;
}

String? _feedbackText(Map a) {
  final dynamic v = a['feedback'];
  if (v is String) return v.trim().isEmpty ? null : v;
  if (v is List) {
    final String joined = v
        .map((e) => e == null ? '' : e.toString())
        .where((e) => e.isNotEmpty)
        .join(' | ');
    return joined.isEmpty ? null : joined;
  }
  return null;
}

String? _videoPathOf(Map a) {
  for (final String k in const ['_source_video_uri', 'video_path']) {
    final dynamic v = a[k];
    if (v is String && v.trim().isNotEmpty) return v;
  }
  return null;
}

Map<String, dynamic> _details(dynamic analysis) {
  final Map? a = _unwrap(analysis);
  if (a == null) return {};
  try {
    final dynamic s = _slim(a, 0);
    if (s is! Map<String, dynamic>) return {};
    jsonEncode(s); // must be plain JSON
    return s;
  } catch (_) {
    return {};
  }
}

class _AnalysisReportButtonState extends State<AnalysisReportButton> {
  bool _sent = false;
  bool _busy = false;

  Future<void> _open() async {
    if (_sent || _busy) return;
    HapticFeedback.selectionClick();
    final String lang = _langOf(context);
    final Map? a = _unwrap(widget.analysis);
    final File? video = _videoFile(a == null ? null : _videoPathOf(a));

    final Map<String, dynamic>? res =
        await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportSheet(
        lang: lang,
        initialReps: (a == null ? null : _totalReps(a)) ?? 0,
        hasVideo: video != null,
      ),
    );
    if (res == null || !mounted) return;

    setState(() => _busy = true);
    bool ok = false;
    try {
      ok = await _queue(res, video, lang);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _sent = ok;
    });
    if (!ok) return;
    HapticFeedback.lightImpact();
    // the upload runs in the background; nothing here waits for it
    unawaited(Future<void>(() async {
      try {
        await syncAllPending();
      } catch (_) {}
    }));
    try {
      await widget.onReported?.call();
    } catch (_) {}
  }

  /// Writes the report to the Hive queue. Returns false when nobody is
  /// signed in (the row needs an owner) or the box could not be written.
  Future<bool> _queue(
      Map<String, dynamic> res, File? video, String lang) async {
    final String uid = (SupaFlow.client.auth.currentUser?.id ?? '').trim();
    if (uid.isEmpty) return false;

    final String id = _newId();
    final String reason = (res['reason'] ?? 'other').toString();

    // Keep the video: the analyzer's copy lives in a temporary folder.
    // Only the file NAME is stored - the Documents path changes between
    // app updates.
    String videoLocal = '';
    if (video != null && res['attachVideo'] == true) {
      try {
        final Directory docs = await getApplicationDocumentsDirectory();
        final Directory dir = Directory(docs.path + '/' + _kVideoDir);
        if (!dir.existsSync()) dir.createSync(recursive: true);
        final String src = video.path.toLowerCase();
        final String ext = src.endsWith('.mov') ? '.mov' : '.mp4';
        final String name = id + ext;
        await video.copy(dir.path + '/' + name);
        videoLocal = name;
      } catch (_) {
        videoLocal = '';
      }
    }

    final String note = (res['note'] ?? '').toString().trim();
    final Map? a = _unwrap(widget.analysis);
    final Map<String, dynamic> row = {
      'id': id,
      'user_id': uid,
      'reported_at': DateTime.now().toUtc().toIso8601String(),
      'exercise_name': (widget.exerciseName ?? '').trim(),
      'set_log_id':
          (widget.setLogId ?? '').trim().isEmpty ? null : widget.setLogId,
      'reason': reason,
      'actual_reps': reason == 'reps' ? res['actualReps'] : null,
      'note': note.isEmpty ? null : note,
      'total_reps': a == null ? null : _totalReps(a),
      'proper_reps': a == null ? null : _properReps(a),
      'score': a == null ? null : _score(a),
      'feedback': a == null ? null : _feedbackText(a),
      'details': _details(widget.analysis),
      'platform':
          Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'other'),
      'language': lang,
      'video_path': null,
    };

    final box = await Hive.openBox(_kReportsBox);
    await box.put(id, {
      'id': id,
      'user_id': uid,
      'row_json': jsonEncode(row),
      'video_local': videoLocal,
      'video_attempts': 0,
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);
    final Color muted = th.secondaryText;

    final Widget content = _sent
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, size: 18, color: th.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(_tr(lang, 'sent'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _style(context, 14, FontWeight.w500, muted)),
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _busy
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: muted),
                    )
                  : Icon(Icons.outlined_flag_rounded, size: 18, color: muted),
              const SizedBox(width: 8),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: _tr(lang, 'link') + ' '),
                      TextSpan(
                        text: _tr(lang, 'linkAction'),
                        style:
                            _style(context, 14, FontWeight.w600, th.primaryText)
                                .copyWith(decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _style(context, 14, FontWeight.w500, muted),
                ),
              ),
            ],
          );

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _open,
        child: Container(
          width: widget.width,
          height: widget.height ?? 44,
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
  }
}

// =============================================================================
// The report sheet. Pops {reaso5n, actuccalReps, note, attachVideo} or null.
// =============================================================================

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({
    required this.lang,
    required this.initialReps,
    required this.hasVideo,
  });

  final String lang;
  final int initialReps;
  final bool hasVideo;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _reason;
  late int _reps = widget.initialReps < 0 ? 0 : widget.initialReps;
  late bool _attach = widget.hasVideo && _kVideoDefaultOn;
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _pick(String r) {
    HapticFeedback.selectionClick();
    setState(() => _reason = r);
  }

  void _step(int d) {
    final int v = _reps + d;
    if (v < 0 || v > 200) return;
    HapticFeedback.selectionClick();
    setState(() => _reps = v);
  }

  void _send() {
    if (_reason == null) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(<String, dynamic>{
      'reason': _reason,
      'actualReps': _reps,
      'note': _note.text.trim(),
      'attachVideo': _attach,
    });
  }

  Widget _option(String key, String label) {
    final th = FlutterFlowTheme.of(context);
    final bool on = _reason == key;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _pick(key),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: th.primaryBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: on ? th.primary : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: on ? th.primary : th.secondaryText, width: 2),
              ),
              child: on
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: th.primary, shape: BoxShape.circle),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: _style(context, 16,
                      on ? FontWeight.w600 : FontWeight.w400, th.primaryText)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBtn(IconData icon, String label, int d) {
    final th = FlutterFlowTheme.of(context);
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _step(d),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: th.secondaryBackground, shape: BoxShape.circle),
          child: Icon(icon, size: 22, color: th.primaryText),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final String lang = widget.lang;
    final bool rtl = _kRtl.contains(lang);
    final MediaQueryData mq = MediaQuery.of(context);
    final double safe = mq.padding.bottom > 0 ? mq.padding.bottom : 12;
    final bool canSend = _reason != null;

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Padding(
        // the sheet rides above the keyboard while the note is typed
        padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: mq.size.height * 0.9),
          decoration: BoxDecoration(
            color: th.secondaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + safe),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: th.alternate,
                        borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                const SizedBox(height: 18),
                Text(_tr(lang, 'title'),
                    style:
                        _style(context, 22, FontWeight.w700, th.primaryText)),
                const SizedBox(height: 4),
                Text(_tr(lang, 'sub'),
                    style:
                        _style(context, 14, FontWeight.w400, th.secondaryText)),
                const SizedBox(height: 16),
                _option('reps', _tr(lang, 'rReps')),
                if (_reason == 'reps') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: th.primaryBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_tr(lang, 'actual'),
                              style: _style(context, 15, FontWeight.w400,
                                  th.primaryText)),
                        ),
                        // numbers read left to right in every language
                        Directionality(
                          textDirection: ui.TextDirection.ltr,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _stepBtn(
                                  Icons.remove_rounded, _tr(lang, 'less'), -1),
                              SizedBox(
                                width: 48,
                                child: Text(_reps.toString(),
                                    textAlign: TextAlign.center,
                                    style: _style(context, 20, FontWeight.w700,
                                        th.primaryText)),
                              ),
                              _stepBtn(Icons.add_rounded, _tr(lang, 'more'), 1),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _option('score', _tr(lang, 'rScore')),
                const SizedBox(height: 8),
                _option('feedback', _tr(lang, 'rFeedback')),
                const SizedBox(height: 8),
                _option('other', _tr(lang, 'rOther')),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: th.primaryBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _note,
                    minLines: 1,
                    maxLines: 3,
                    maxLength: 300,
                    textCapitalization: TextCapitalization.sentences,
                    style: _style(context, 15, FontWeight.w400, th.primaryText),
                    cursorColor: th.primary,
                    decoration: InputDecoration(
                      isDense: true,
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      hintText: _tr(lang, 'note'),
                      hintStyle: _style(
                          context, 15, FontWeight.w400, th.secondaryText),
                    ),
                  ),
                ),
                if (widget.hasVideo) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_tr(lang, 'video'),
                                style: _style(context, 15, FontWeight.w600,
                                    th.primaryText)),
                            const SizedBox(height: 2),
                            Text(_tr(lang, 'videoSub'),
                                style: _style(context, 13, FontWeight.w400,
                                    th.secondaryText)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch.adaptive(
                        value: _attach,
                        activeColor: th.primary,
                        onChanged: (v) => setState(() => _attach = v),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: canSend ? _send : null,
                  child: Opacity(
                    opacity: canSend ? 1.0 : 0.45,
                    child: Container(
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: th.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(_tr(lang, 'send'),
                          style: _style(
                              context, 17, FontWeight.w700, Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
