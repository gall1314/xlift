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

import 'dart:io';
import 'package:path_provider/path_provider.dart';

// נפתר פעם אחת לכל הסשן — מונע async/הבהוב בכל הצגה
String? _docsDirPath;

class LocalProfileImage extends StatefulWidget {
  const LocalProfileImage({
    super.key,
    this.width,
    this.height,
    this.fileName,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final String? fileName;
  final double? borderRadius;

  @override
  State<LocalProfileImage> createState() => _LocalProfileImageState();
}

class _LocalProfileImageState extends State<LocalProfileImage> {
  File? _file;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant LocalProfileImage old) {
    super.didUpdateWidget(old);
    // כשמחליפים תמונה ו-App State מתעדכן — לטעון מחדש
    if (old.fileName != widget.fileName) _resolve();
  }

  Future<void> _resolve() async {
    final name = widget.fileName;
    if (name == null || name.isEmpty) {
      if (mounted) setState(() => _file = null);
      return;
    }
    _docsDirPath ??= (await getApplicationDocumentsDirectory()).path;
    final f = File('$_docsDirPath/$name');
    if (mounted) setState(() => _file = f.existsSync() ? f : null);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width, h = widget.height;

    final image = _file != null
        ? Image.file(_file!,
            width: w,
            height: h,
            fit: BoxFit.cover,
            gaplessPlayback: true) // לא מהבהב ברebuild
        : Image.asset('assets/images/default_avatar.png',
            width: w, height: h, fit: BoxFit.cover);

    // אם הוגדר רדיוס — פינות מעוגלות; אחרת עיגול מלא (התנהגות קודמת)
    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius!),
        child: image,
      );
    }
    return ClipOval(child: image);
  }
}
