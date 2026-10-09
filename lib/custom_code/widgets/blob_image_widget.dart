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

import '/custom_code/widgets/index.dart';
import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';

import 'dart:typed_data';
import 'dart:convert';

class BlobImageWidget extends StatefulWidget {
  const BlobImageWidget({
    super.key,
    this.width,
    this.height,
    this.blobData, // נשאר אותו שם כדי ש-FF לא ישבר
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final String? blobData; // עכשיו String (Base64)
  final double? borderRadius;

  @override
  State<BlobImageWidget> createState() => _BlobImageWidgetState();
}

class _BlobImageWidgetState extends State<BlobImageWidget> {
  @override
  Widget build(BuildContext context) {
    final double width = widget.width ?? 100;
    final double height = widget.height ?? 100;
    final double radius = widget.borderRadius ?? 10;

    if (widget.blobData == null || widget.blobData!.isEmpty) {
      return _placeholder(width, height, radius);
    }

    try {
      // ניקוי prefix אם קיים (data:image/png;base64,...)
      final String base64Str = widget.blobData!.contains(',')
          ? widget.blobData!.split(',').last
          : widget.blobData!;

      final Uint8List imageBytes = base64Decode(base64Str);

      if (imageBytes.isEmpty) {
        return _placeholder(width, height, radius);
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.memory(
          imageBytes,
          width: width,
          height: height,

          // 🔥 הכי חשובים לאיכות
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,

          // ❌ לא לשים cacheWidth/cacheHeight
          gaplessPlayback: true,
        ),
      );
    } catch (e) {
      print("Base64 decode error: $e");
      return _placeholder(width, height, radius);
    }
  }

  Widget _placeholder(double w, double h, double r) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(r),
      ),
      child: const Center(
        child: Icon(Icons.image_not_supported),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
