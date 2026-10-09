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
import '/custom_code/actions/xlift_log_add.dart';

/// Live in-app console: shows xliftLogLines, auto-scrolls, copy icon copies
/// everything, trash clears.
///
/// Drop it at the bottom of any page (or in a bottom sheet) while debugging.
class DebugConsole extends StatefulWidget {
  const DebugConsole({
    super.key,
    this.width,
    this.height,
    this.fontSize,
  });

  final double? width;
  final double? height;
  final double? fontSize;

  @override
  State<DebugConsole> createState() => _DebugConsoleState();
}

class _DebugConsoleState extends State<DebugConsole> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height ?? 220,
      decoration: BoxDecoration(
        color: const Color(0xEE10151B),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      child: ValueListenableBuilder<List<String>>(
        valueListenable: xliftLogLines,
        builder: (context, lines, _) {
          _jumpToEnd();
          return Column(
            children: [
              Row(
                children: [
                  Text('console (${lines.length})',
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      )),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.copy_rounded,
                        size: 16, color: Color(0xFF9CA3AF)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: lines.join('\n')));
                    },
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 16, color: Color(0xFF9CA3AF)),
                    onPressed: () => xliftLogClear(),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  itemCount: lines.length,
                  itemBuilder: (context, i) => Text(
                    lines[i],
                    style: TextStyle(
                      color: const Color(0xFF2DD4BF),
                      fontSize: widget.fontSize ?? 10.5,
                      height: 1.35,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
