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
import 'package:flutter/services.dart';

/// Reps twin of WeightField - same look, colors, caret, push, live commit -
/// integers only.
///
/// String/int-safe id matching. Reads this set's reps from loggedSets, locks
/// on isDone ("-" when done+empty), previous set's reps as gray hint (falls
/// back to hintText, e.g. targetReps). While editing an EMPTY field the hint
/// is hidden and the caret blinks alone, centered - like a real TextField.
/// Numpad: digits + backspace, -1/+1 steppers (stepping from the hint when
/// empty), max 999. LIVE commit via onValueCommitted.
///
/// The pad lives in an Overlay (not a modal sheet): there is NO barrier, so a
/// tap outside the pad closes it AND still reaches whatever was tapped (e.g.
/// the weight field opens in the same tap). Tapping this field again while
/// open closes the pad. Open/close are animated like the system keyboard
/// (slide up 260ms easeOut, slide down 200ms easeIn).
///
/// External reset: if this set's reps disappear from loggedSets while the pad
/// is NOT open (e.g. "Reset Set"), the locally typed value is dropped and the
/// field falls back to the hint.
class RepsField extends StatefulWidget {
  const RepsField({
    super.key,
    this.width,
    this.height,
    this.loggedSets,
    this.exerciseId,
    this.setNumber,
    this.value,
    this.fontSize,
    this.fontWeight,
    this.textColor,
    this.hintColor,
    this.focusColor,
    this.isDark,
    this.hintText,
    this.onValueCommitted,
  });

  final double? width;
  final double? height;
  final List<dynamic>? loggedSets;
  final int? exerciseId;
  final int? setNumber;
  final int? value;
  final double? fontSize;
  final int? fontWeight;
  final Color? textColor;
  final Color? hintColor;
  final Color? focusColor;
  final bool? isDark;
  final String? hintText;
  final Future Function(int? value)? onValueCommitted;

  @override
  State<RepsField> createState() => _RepsFieldState();
}

class _RepsFieldState extends State<RepsField>
    with SingleTickerProviderStateMixin {
  int? _typed;
  bool _hasTyped = false;

  bool _editing = false;
  bool _caretOn = true;
  Timer? _blink;

  double _padHeight = 0;
  OverlayEntry? _padEntry;
  bool _closing = false;

  // Keyboard-like slide: up 260ms easeOut, down 200ms easeIn.
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 200),
  );
  late final Animation<Offset> _slideOffset = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _slide,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  ));

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  static bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    return v?.toString().toLowerCase() == 'true';
  }

  /// This set's own entry - String/int-safe id matching.
  Map? get _ownEntry {
    final ls = widget.loggedSets;
    if (ls == null || widget.exerciseId == null || widget.setNumber == null) {
      return null;
    }
    for (final s in ls) {
      if (s is Map &&
          _toInt(s['exerciseId']) == widget.exerciseId &&
          _toInt(s['setNumber']) == widget.setNumber) {
        return s;
      }
    }
    return null;
  }

  int? get _ownFromState => widget.value ?? _toInt(_ownEntry?['reps']);

  bool get _isDone => _toBool(_ownEntry?['isDone']);

  /// Previous set's reps - String/int-safe.
  int? get _prevReps {
    final ls = widget.loggedSets;
    if (ls == null || widget.exerciseId == null || widget.setNumber == null) {
      return null;
    }
    int? best;
    int bestSn = -1;
    for (final s in ls) {
      if (s is! Map) continue;
      if (_toInt(s['exerciseId']) != widget.exerciseId) continue;
      final int sn = _toInt(s['setNumber']) ?? 0;
      final int? r = _toInt(s['reps']);
      if (sn < widget.setNumber! && r != null && sn > bestSn) {
        best = r;
        bestSn = sn;
      }
    }
    return best;
  }

  String get _fallbackHint {
    final int? prev = _prevReps;
    if (prev != null) return prev.toString();
    if (widget.hintText != null && widget.hintText!.isNotEmpty) {
      return widget.hintText!;
    }
    return '0';
  }

  int get _stepBase {
    final int? prev = _prevReps;
    if (prev != null) return prev;
    final int? hinted = _toInt(widget.hintText);
    return hinted ?? 0;
  }

  int? get _shown => _hasTyped ? _typed : _ownFromState;

  static FontWeight weightFromInt(int? w) {
    switch (w) {
      case 100:
        return FontWeight.w100;
      case 200:
        return FontWeight.w200;
      case 300:
        return FontWeight.w300;
      case 400:
        return FontWeight.w400;
      case 500:
        return FontWeight.w500;
      case 600:
        return FontWeight.w600;
      case 800:
        return FontWeight.w800;
      case 900:
        return FontWeight.w900;
      case 700:
      default:
        return FontWeight.w700;
    }
  }

  @override
  void didUpdateWidget(covariant RepsField old) {
    super.didUpdateWidget(old);
    // External reset: state says "no reps" for this set, we're not editing,
    // but we still hold a locally typed value -> drop it and follow state.
    if (!_editing && _hasTyped && _typed != null && _ownFromState == null) {
      _typed = null;
      _hasTyped = false;
      print('[repsField] ex=${widget.exerciseId} n=${widget.setNumber} '
          'external reset -> cleared');
    }
  }

  @override
  void dispose() {
    _blink?.cancel();
    _padEntry?.remove();
    _padEntry = null;
    _slide.dispose();
    super.dispose();
  }

  void _startCaret() {
    _blink?.cancel();
    _caretOn = true;
    _blink = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _caretOn = !_caretOn);
    });
  }

  void _stopCaret() {
    _blink?.cancel();
    _blink = null;
  }

  void _liveCommit(int? v) {
    setState(() {
      _typed = v;
      _hasTyped = true;
      _caretOn = true;
    });
    _startCaret();
    print('[repsField] ex=${widget.exerciseId} n=${widget.setNumber} '
        'commit=$v');
    widget.onValueCommitted?.call(v);
  }

  void _scrollClearOfPad({bool animate = true}) {
    try {
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) return;

      final media = MediaQuery.of(context);
      final double padH =
          _padHeight > 0 ? _padHeight : 276 + media.padding.bottom;
      final double padTop = media.size.height - padH;
      const double gap = 10;

      final double fieldBottom =
          box.localToGlobal(Offset(0, box.size.height)).dy;
      final double delta = fieldBottom - (padTop - gap);
      if (delta <= 0.5) return;

      ScrollableState? scroll = Scrollable.maybeOf(context);
      int hops = 0;
      while (scroll != null && hops < 6) {
        final pos = scroll.position;
        if (pos.axis == Axis.vertical && pos.maxScrollExtent > 0) break;
        scroll = Scrollable.maybeOf(scroll.context);
        hops++;
      }
      if (scroll == null) return;

      final pos = scroll.position;
      final double target =
          (pos.pixels + delta).clamp(pos.minScrollExtent, pos.maxScrollExtent);
      if ((target - pos.pixels).abs() < 1) return;

      if (animate) {
        pos.animateTo(target,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic);
      } else {
        pos.jumpTo(target);
      }
    } catch (_) {}
  }

  void _onPadMeasured(double h) {
    if ((h - _padHeight).abs() < 1) return;
    _padHeight = h;
    _scrollClearOfPad(animate: true);
  }

  /// True if a global pointer position lands on this field itself.
  bool _hitsSelf(Offset globalPos) {
    try {
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) return false;
      final local = box.globalToLocal(globalPos);
      return box.size.contains(local);
    } catch (_) {
      return false;
    }
  }

  void _openPad() {
    if (_isDone || _editing) return;
    HapticFeedback.selectionClick();

    // Re-tapped while the previous pad is still sliding down: drop it now
    // so we never end up with two entries.
    if (_padEntry != null) {
      _padEntry!.remove();
      _padEntry = null;
      _closing = false;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    try {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    } catch (_) {}

    final bool dark =
        widget.isDark ?? (Theme.of(context).brightness == Brightness.dark);

    setState(() => _editing = true);
    _startCaret();
    _scrollClearOfPad();

    _padEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // No barrier: sees every tap outside the pad, closes the pad, and
          // lets the tap continue to whatever is underneath (e.g. the
          // weight field). Taps on this field itself are handled by its
          // own onTap (toggle), so ignore them here.
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (e) {
                if (_hitsSelf(e.position)) return;
                _closePad();
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _slideOffset,
              child: _RepsPadSheet(
                initial: _shown,
                stepBase: _stepBase,
                dark: dark,
                onChanged: _liveCommit,
                onMeasured: _onPadMeasured,
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_padEntry!);
    _slide.forward(from: 0);
  }

  Future<void> _closePad() async {
    if (_padEntry == null || _closing) return;
    _closing = true;
    _stopCaret();
    if (mounted && _editing) setState(() => _editing = false);

    // Slide down, then remove. orCancel: if something interrupts the
    // animation we still fall through and clean up.
    try {
      await _slide.reverse().orCancel;
    } catch (_) {}

    final entry = _padEntry;
    _padEntry = null;
    entry?.remove();
    _closing = false;
  }

  @override
  Widget build(BuildContext context) {
    final bool dark =
        widget.isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final String text = _shown == null ? '' : _shown.toString();
    final bool empty = text.isEmpty;
    final bool done = _isDone;

    final Color teal = dark ? const Color(0xFF2DD4BF) : const Color(0xFF14B8A6);
    final Color focus = widget.focusColor ?? teal;

    final Color primary =
        widget.textColor ?? (dark ? Colors.white : const Color(0xFF1A202C));
    final Color secondary = widget.hintColor ??
        (dark ? const Color(0xFF6B7683) : const Color(0xFF9CA3AF));
    final double fs = widget.fontSize ?? 16;

    // Like a real TextField: while editing an EMPTY field, hide the
    // hint - the caret blinks alone, centered.
    final bool caretAlone = _editing && empty;
    final String display = caretAlone
        ? ''
        : ((done && empty) ? '-' : (empty ? _fallbackHint : text));
    final Color color =
        (done && empty) ? secondary : (empty ? secondary : primary);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: done ? null : (_editing ? _closePad : _openPad),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: _editing
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: focus, width: 2),
                ),
              )
            : null,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (display.isNotEmpty)
                Text(
                  display,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: fs,
                    fontWeight: weightFromInt(widget.fontWeight),
                    height: 1.0,
                    color: color,
                  ),
                ),
              if (_editing)
                Padding(
                  padding: EdgeInsets.only(left: display.isNotEmpty ? 1.5 : 0),
                  child: Opacity(
                    opacity: _caretOn ? 1.0 : 0.0,
                    child: Container(
                      width: 2,
                      height: fs * 1.15,
                      decoration: BoxDecoration(
                        color: focus,
                        borderRadius: BorderRadius.circular(1),
                      ),
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

class _RepsPadSheet extends StatefulWidget {
  const _RepsPadSheet({
    required this.initial,
    required this.stepBase,
    required this.dark,
    required this.onChanged,
    required this.onMeasured,
  });

  final int? initial;
  final int stepBase;
  final bool dark;
  final void Function(int? value) onChanged;
  final void Function(double height) onMeasured;

  @override
  State<_RepsPadSheet> createState() => _RepsPadSheetState();
}

class _RepsPadSheetState extends State<_RepsPadSheet> {
  late String _text;
  String? _pressedKey;
  final GlobalKey _rootKey = GlobalKey();

  static const Color _teal = Color(0xFF14B8A6);
  static const Color _tealDark = Color(0xFF2DD4BF);

  @override
  void initState() {
    super.initState();
    _text = widget.initial == null ? '' : widget.initial.toString();
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
  }

  void _report() {
    final box = _rootKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) widget.onMeasured(box.size.height);
  }

  Color get _accent => widget.dark ? _tealDark : _teal;
  Color get _sheetBg => widget.dark ? const Color(0xFF141A21) : Colors.white;
  Color get _keyBg =>
      widget.dark ? const Color(0xFF1E2731) : const Color(0xFFF0F2F5);
  Color get _keyPressedBg =>
      widget.dark ? const Color(0xFF2A3644) : const Color(0xFFD5DAE1);
  Color get _textColor => widget.dark ? Colors.white : const Color(0xFF1A202C);

  bool _canPress(String k) => (_text + k).length <= 3;

  int? _committedValue() {
    if (_text.isEmpty) return null;
    return int.tryParse(_text);
  }

  void _emit() => widget.onChanged(_committedValue());

  void _keyDown(String keyId) {
    if (keyId == 'back') {
      if (_text.isEmpty) return;
      HapticFeedback.selectionClick();
      setState(() {
        _pressedKey = 'back';
        _text = _text.substring(0, _text.length - 1);
      });
      _emit();
      return;
    }
    if (!_canPress(keyId)) return;
    if (_text.isEmpty && keyId == '0') return;
    HapticFeedback.selectionClick();
    setState(() {
      _pressedKey = keyId;
      _text = _text + keyId;
    });
    _emit();
  }

  void _keyUp() {
    if (_pressedKey != null) setState(() => _pressedKey = null);
  }

  void _stepBy(int delta) {
    HapticFeedback.selectionClick();
    final int base = _committedValue() ?? widget.stepBase;
    int next = base + delta;
    if (next < 0) next = 0;
    if (next > 999) next = 999;
    setState(() => _text = next == 0 ? '' : next.toString());
    _emit();
  }

  Widget _key(String label, {bool isBackspace = false, Widget? child}) {
    final String keyId = isBackspace ? 'back' : label;
    final bool isInput = !isBackspace && label.isNotEmpty;
    final bool enabled = isBackspace
        ? _text.isNotEmpty
        : (!isInput || (_canPress(label) && !(_text.isEmpty && label == '0')));
    final bool pressed = _pressedKey == keyId;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.30,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: enabled ? (_) => _keyDown(keyId) : null,
            onPointerUp: (_) => _keyUp(),
            onPointerCancel: (_) => _keyUp(),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: pressed ? _keyPressedBg : _keyBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: child ??
                    Text(label,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        )),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final display = _text.isEmpty ? '0' : _text;

    // Material so text/ink render correctly inside the Overlay.
    return Material(
      color: Colors.transparent,
      child: Container(
        key: _rootKey,
        decoration: BoxDecoration(
          color: _sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(widget.dark ? 0.5 : 0.15),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(10, 8, 10, 6 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: _textColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                _stepBtn('-1', () => _stepBy(-1)),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(display,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            color: _textColor,
                          )),
                      const SizedBox(width: 4),
                      Text('Reps',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _accent,
                          )),
                    ],
                  ),
                ),
                _stepBtn('+1', () => _stepBy(1)),
              ],
            ),
            const SizedBox(height: 6),
            Row(children: [_key('1'), _key('2'), _key('3')]),
            Row(children: [_key('4'), _key('5'), _key('6')]),
            Row(children: [_key('7'), _key('8'), _key('9')]),
            Row(children: [
              _key(''),
              _key('0'),
              _key('',
                  isBackspace: true,
                  child: Icon(Icons.backspace_outlined,
                      size: 21, color: _textColor)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _stepBtn(String label, VoidCallback onTap) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onTap(),
      child: Container(
        width: 58,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _keyBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _accent,
            )),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
