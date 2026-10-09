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

/// Self-contained gym weight field + custom numpad (Xlift style).
///
/// Reads everything for this set straight from loggedSets, with
/// String/int-safe id matching. Typed text always STAYS. Caret behaves like a
/// real TextField: while editing an EMPTY field the hint is hidden and the
/// caret blinks alone, centered. LIVE commit on every keystroke via
/// onValueCommitted.
///
/// Bodyweight mode (showAsPlusButton): the set shows "+" while it has no
/// weight. Tapping "+" opens the pad; if an earlier set of this exercise has
/// a weight it is adopted immediately (committed to loggedSets, so mark-done
/// saves it with no extra logic). The pad has a "No added weight" button that
/// clears the weight and brings "+" back.
///
/// The pad lives in an Overlay (not a modal sheet): there is NO barrier, so a
/// tap outside the pad closes it AND still reaches whatever was tapped (e.g.
/// the reps field opens in the same tap). Tapping this field again while open
/// closes the pad. Open/close are animated like the system keyboard (slide up
/// 260ms easeOut, slide down 200ms easeIn).
///
/// External reset: the locally typed value is dropped ONLY when loggedSets
/// TRANSITIONS from having a weight for this set to having none (e.g. "Reset
/// Set") while the pad is closed. A state that never held the value (null ->
/// null, e.g. the commit hasn't landed yet) never clears what the user typed.
class WeightField extends StatefulWidget {
  const WeightField({
    super.key,
    this.width,
    this.height,
    this.loggedSets,
    this.exerciseId,
    this.setNumber,
    this.value,
    this.isKg = true,
    this.fontSize,
    this.fontWeight,
    this.textColor,
    this.hintColor,
    this.focusColor,
    this.isDark,
    this.hintText,
    this.stepSize,
    this.showAsPlusButton = false,
    this.plusButtonSize = 35,
    this.onValueCommitted,
  });

  final double? width;
  final double? height;
  final List<dynamic>? loggedSets;
  final int? exerciseId;
  final int? setNumber;
  final double? value;
  final bool isKg;
  final double? fontSize;
  final int? fontWeight;
  final Color? textColor;
  final Color? hintColor;
  final Color? focusColor;
  final bool? isDark;
  final String? hintText;
  final double? stepSize;
  final bool showAsPlusButton;
  final double plusButtonSize;
  final Future Function(double? value)? onValueCommitted;

  @override
  State<WeightField> createState() => _WeightFieldState();
}

class _WeightFieldState extends State<WeightField>
    with SingleTickerProviderStateMixin {
  double? _typed;
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

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim());
  }

  static int? _idOf(dynamic v) {
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

  /// This set's entry in an arbitrary loggedSets list - String/int-safe.
  Map? _entryIn(List<dynamic>? ls) {
    if (ls == null || widget.exerciseId == null || widget.setNumber == null) {
      return null;
    }
    for (final s in ls) {
      if (s is Map &&
          _idOf(s['exerciseId']) == widget.exerciseId &&
          _idOf(s['setNumber']) == widget.setNumber) {
        return s;
      }
    }
    return null;
  }

  Map? get _ownEntry => _entryIn(widget.loggedSets);

  double? get _ownFromState => widget.value ?? _toDouble(_ownEntry?['weight']);

  bool get _isDone => _toBool(_ownEntry?['isDone']);

  /// Previous set's weight (> 0 only) - String/int-safe.
  double? get _prevWeight {
    final ls = widget.loggedSets;
    if (ls == null || widget.exerciseId == null || widget.setNumber == null) {
      return null;
    }
    double? best;
    int bestSn = -1;
    for (final s in ls) {
      if (s is! Map) continue;
      if (_idOf(s['exerciseId']) != widget.exerciseId) continue;
      final int sn = _idOf(s['setNumber']) ?? 0;
      final w = _toDouble(s['weight']);
      if (sn < widget.setNumber! && w != null && w > 0 && sn > bestSn) {
        best = w;
        bestSn = sn;
      }
    }
    return best;
  }

  String get _fallbackHint {
    if (widget.hintText != null) return widget.hintText!;
    final double? prev = _prevWeight;
    return prev == null ? '0' : fmt(prev);
  }

  double? get _shown => _hasTyped ? _typed : _ownFromState;

  static String fmt(double? v) {
    if (v == null) return '';
    if (v == v.roundToDouble()) return v.toInt().toString();
    String s = v.toStringAsFixed(2);
    while (s.endsWith('0')) s = s.substring(0, s.length - 1);
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s;
  }

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

  double get _effectiveStep => widget.stepSize ?? (widget.isKg ? 2.5 : 5.0);

  @override
  void didUpdateWidget(covariant WeightField old) {
    super.didUpdateWidget(old);
    if (_editing || !_hasTyped || _typed == null) return;

    // External reset = TRANSITION from "state had a weight for this set" to
    // "state has none". A state that never held it (commit not landed yet,
    // or the action didn't write) must NOT wipe what the user typed.
    final double? before =
        old.value ?? _toDouble(_entryIn(old.loggedSets)?['weight']);
    final double? now = _ownFromState;
    if (before != null && now == null) {
      _typed = null;
      _hasTyped = false;
      print('[weightField] ex=${widget.exerciseId} n=${widget.setNumber} '
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

  void _liveCommit(double? v) {
    setState(() {
      _typed = v;
      _hasTyped = true;
      _caretOn = true;
    });
    _startCaret();
    print('[weightField] ex=${widget.exerciseId} n=${widget.setNumber} '
        'commit=$v');
    widget.onValueCommitted?.call(v);
  }

  /// "No added weight": clear this set's weight and bring "+" back.
  void _clearWeight() {
    HapticFeedback.selectionClick();
    setState(() {
      _typed = null;
      _hasTyped = false;
    });
    widget.onValueCommitted?.call(null);
    _closePad();
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

    // Plus-tap inheritance: adopt the previous set's weight right away, so
    // mark-done saves it without any hint logic on the FF side.
    if (widget.showAsPlusButton && _shown == null) {
      final double? prev = _prevWeight;
      print('[weightField] plusTap ex=${widget.exerciseId} '
          'n=${widget.setNumber} prev=$prev');
      if (prev != null) _liveCommit(prev);
    }

    final bool dark =
        widget.isDark ?? (Theme.of(context).brightness == Brightness.dark);

    setState(() => _editing = true);
    _startCaret();
    _scrollClearOfPad();

    _padEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // No barrier: sees every tap outside the pad, closes the pad, and
          // lets the tap continue to whatever is underneath (e.g. the reps
          // field). Taps on this field itself are handled by its own onTap
          // (toggle), so ignore them here.
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
              child: _NumpadSheet(
                initial: _shown,
                isKg: widget.isKg,
                dark: dark,
                step: _effectiveStep,
                bodyweightMode: widget.showAsPlusButton,
                onChanged: _liveCommit,
                onClearWeight: _clearWeight,
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
    final String text = fmt(_shown);
    final bool empty = text.isEmpty;
    final bool done = _isDone;

    final Color teal = dark ? const Color(0xFF2DD4BF) : const Color(0xFF14B8A6);
    final Color focus = widget.focusColor ?? teal;

    if (widget.showAsPlusButton && empty && !done && !_editing) {
      return Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openPad,
          child: Container(
            width: widget.plusButtonSize,
            height: widget.plusButtonSize,
            decoration: BoxDecoration(color: teal, shape: BoxShape.circle),
            child: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
          ),
        ),
      );
    }

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

class _NumpadSheet extends StatefulWidget {
  const _NumpadSheet({
    required this.initial,
    required this.isKg,
    required this.dark,
    required this.step,
    required this.bodyweightMode,
    required this.onChanged,
    required this.onClearWeight,
    required this.onMeasured,
  });

  final double? initial;
  final bool isKg;
  final bool dark;
  final double step;
  final bool bodyweightMode;
  final void Function(double? value) onChanged;
  final VoidCallback onClearWeight;
  final void Function(double height) onMeasured;

  @override
  State<_NumpadSheet> createState() => _NumpadSheetState();
}

class _NumpadSheetState extends State<_NumpadSheet> {
  late String _text;
  String? _pressedKey;
  final GlobalKey _rootKey = GlobalKey();

  static const Color _teal = Color(0xFF14B8A6);
  static const Color _tealDark = Color(0xFF2DD4BF);

  @override
  void initState() {
    super.initState();
    _text = _WeightFieldState.fmt(widget.initial);
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

  RegExp get _valid => widget.isKg
      ? RegExp(r'^\d{0,4}(\.(25|5|75)?)?$')
      : RegExp(r'^\d{0,4}(\.5?)?$');

  bool get _afterDot => _text.endsWith('.');

  double get _snapUnit => widget.isKg ? 0.25 : 0.5;
  double _snap(double v) => (v / _snapUnit).roundToDouble() * _snapUnit;
  bool _canPress(String k) => _valid.hasMatch(_text + k);

  String _mapKey(String label) {
    if (_afterDot && widget.isKg) {
      if (label == '2') return '25';
      if (label == '7') return '75';
    }
    return label;
  }

  double? _committedValue() {
    String t = _text;
    if (t.endsWith('.')) t = t.substring(0, t.length - 1);
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    if (v == null) return null;
    return _snap(v);
  }

  void _emit() => widget.onChanged(_committedValue());

  void _keyDown(String keyId) {
    if (keyId == 'back') {
      if (_text.isEmpty) return;
      HapticFeedback.selectionClick();
      setState(() {
        _pressedKey = 'back';
        if (_text.endsWith('25') || _text.endsWith('75')) {
          final int dot = _text.lastIndexOf('.');
          if (dot >= 0 && _text.length - dot == 3) {
            _text = _text.substring(0, dot + 1);
          } else {
            _text = _text.substring(0, _text.length - 1);
          }
        } else {
          _text = _text.substring(0, _text.length - 1);
        }
      });
      _emit();
      return;
    }

    final String k = _mapKey(keyId);
    if (!_canPress(k)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pressedKey = keyId;
      _text = _text + k;
    });
    _emit();
  }

  void _keyUp() {
    if (_pressedKey != null) setState(() => _pressedKey = null);
  }

  void _stepBy(double delta) {
    HapticFeedback.selectionClick();
    final double base = _committedValue() ?? 0;
    double next = base + delta;
    if (next < 0) next = 0;
    next = _snap(next);
    setState(() => _text = _WeightFieldState.fmt(next));
    _emit();
  }

  Widget _key(String label, {bool isBackspace = false, Widget? child}) {
    final String keyId = isBackspace ? 'back' : label;
    final bool isInput = !isBackspace && label.isNotEmpty;
    final String shown = isInput ? _mapKey(label) : label;
    final bool enabled =
        isBackspace ? _text.isNotEmpty : (!isInput || _canPress(shown));
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
                    Text(shown,
                        style: TextStyle(
                          fontSize: shown.length > 1 ? 19 : 21,
                          fontWeight: FontWeight.w600,
                          color: shown.length > 1 ? _accent : _textColor,
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
                _stepBtn('-${_WeightFieldState.fmt(widget.step)}',
                    () => _stepBy(-widget.step)),
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
                      Text(widget.isKg ? 'Kg' : 'Lbs',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _accent,
                          )),
                    ],
                  ),
                ),
                _stepBtn('+${_WeightFieldState.fmt(widget.step)}',
                    () => _stepBy(widget.step)),
              ],
            ),
            // Bodyweight-only exercises: clear the weight, "+" comes back.
            if (widget.bodyweightMode)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (_) => widget.onClearWeight(),
                  child: Container(
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: _accent.withOpacity(0.6)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('No added weight',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _accent,
                        )),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Row(children: [_key('1'), _key('2'), _key('3')]),
            Row(children: [_key('4'), _key('5'), _key('6')]),
            Row(children: [_key('7'), _key('8'), _key('9')]),
            Row(children: [
              _key('.'),
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
