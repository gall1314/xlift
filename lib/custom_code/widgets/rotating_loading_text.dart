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
import 'dart:ui' as ui show TextDirection;

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

/// Default messages per language (same order everywhere).
const Map<String, List<String>> _kDefaults = {
  'en': [
    'Analyzing your goals',
    'Selecting the right exercises',
    'Balancing muscle groups',
    'Setting sets and reps',
    'Optimizing recovery',
    'Finalizing your plan',
  ],
  'es': [
    'Analizando tus objetivos',
    'Eligiendo los ejercicios',
    'Equilibrando los músculos',
    'Definiendo series y reps',
    'Optimizando la recuperación',
    'Finalizando tu plan',
  ],
  'he': [
    'מנתח את המטרות שלך',
    'בוחר את התרגילים הנכונים',
    'מאזן קבוצות שרירים',
    'קובע סטים וחזרות',
    'מתאים זמני מנוחה',
    'מסיים את התוכנית',
  ],
  'de': [
    'Ziele werden analysiert',
    'Passende Übungen wählen',
    'Muskelgruppen ausgleichen',
    'Sätze und Wdh. festlegen',
    'Erholung optimieren',
    'Plan wird fertiggestellt',
  ],
  'fr': [
    'Analyse de vos objectifs',
    'Choix des exercices',
    'Équilibre des muscles',
    'Réglage séries et reps',
    'Optimisation de la récup',
    'Finalisation du plan',
  ],
};

/// Cycles through a list of short status messages with a cross-fade, e.g.
///
/// under an AI "Building your workout..." loader. Pass [messages] to override
/// the defaults (then they are shown as-is, no translation). Reads the app
/// language itself. Stops on dispose.
class RotatingLoadingText extends StatefulWidget {
  const RotatingLoadingText({
    super.key,
    this.width,
    this.height,
    this.messages,
    this.intervalMs = 2500,
    this.textColor,
    this.fontSize = 15.0,
  });

  final double? width;
  final double? height;
  final List<String>? messages;
  final int intervalMs;
  final Color? textColor;
  final double fontSize;

  @override
  State<RotatingLoadingText> createState() => _RotatingLoadingTextState();
}

class _RotatingLoadingTextState extends State<RotatingLoadingText> {
  Timer? _timer;
  int _index = 0;

  List<String> _messagesFor(String lang) {
    final m = widget.messages;
    if (m != null && m.isNotEmpty) return m;
    return _kDefaults[lang] ?? _kDefaults['en']!;
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant RotatingLoadingText old) {
    super.didUpdateWidget(old);
    if (old.intervalMs != widget.intervalMs ||
        old.messages != widget.messages) {
      _index = 0;
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(milliseconds: widget.intervalMs < 500 ? 500 : widget.intervalMs),
      (_) {
        if (!mounted) return;
        setState(() => _index++);
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);
    final List<String> msgs = _messagesFor(lang);
    final String text = msgs[_index % msgs.length];

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Text(
              text,
              key: ValueKey<String>('$_index-$text'),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: widget.textColor ?? theme.secondaryText,
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
