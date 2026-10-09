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

import 'dart:io';
import 'package:video_player/video_player.dart';

class SimpleVideoPlayer extends StatefulWidget {
  const SimpleVideoPlayer({
    Key? key,
    this.width,
    this.height,
    required this.videoPath,
    this.borderRadius = 12.0,
  }) : super(key: key);

  final double? width;
  final double? height;
  final String videoPath;
  final double borderRadius;

  @override
  State<SimpleVideoPlayer> createState() => _SimpleVideoPlayerState();
}

class _SimpleVideoPlayerState extends State<SimpleVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isReady = false;
  bool _hasError = false;
  bool _isNetworkError = false;
  bool _showIcon = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  bool _looksLikeNetworkError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('internet') ||
        s.contains('offline') ||
        s.contains('network') ||
        s.contains('connection') ||
        s.contains('socket') ||
        s.contains('timed out') ||
        s.contains('timeout') ||
        s.contains('host');
  }

  Future<void> _init() async {
    try {
      String path = widget.videoPath;
      if (path.isEmpty) {
        setState(() {
          _hasError = true;
          _isNetworkError = false;
        });
        return;
      }

      if (path.startsWith('file://')) {
        path = path.substring(7);
      }

      VideoPlayerController controller;

      if (path.startsWith('http://') || path.startsWith('https://')) {
        controller = VideoPlayerController.networkUrl(Uri.parse(path));
      } else {
        final file = File(path);
        if (!file.existsSync()) {
          setState(() {
            _hasError = true;
            _isNetworkError = false;
          });
          return;
        }
        controller = VideoPlayerController.file(file);
      }

      await controller.initialize();
      controller.setLooping(true);
      _controller = controller;

      if (mounted) {
        setState(() => _isReady = true);
        await controller.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isNetworkError = _looksLikeNetworkError(e);
        });
      }
    }
  }

  Future<void> _retry() async {
    _controller?.dispose();
    _controller = null;
    setState(() {
      _hasError = false;
      _isNetworkError = false;
      _isReady = false;
    });
    await _init();
  }

  void _handleTap() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
      _showIcon = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showIcon = false);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildContainer({required Widget child}) {
    final double w = widget.width ?? MediaQuery.of(context).size.width;
    final double h = widget.height ?? 220;
    return Container(
      width: w,
      height: h,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildContainer(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isNetworkError
                    ? Icons.wifi_off_rounded
                    : Icons.videocam_off_rounded,
                color: Colors.white.withOpacity(0.35),
                size: 44,
              ),
              const SizedBox(height: 10),
              Text(
                _isNetworkError
                    ? 'No internet connection'
                    : 'Video unavailable',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _retry,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: Colors.white.withOpacity(0.6),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Retry',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isReady || _controller == null) {
      return _buildContainer(
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final controller = _controller!;
    final bool isPlaying = controller.value.isPlaying;

    return _buildContainer(
      child: GestureDetector(
        onTap: _handleTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video fills container like BoxFitג.cover
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
            if (_showIcon || !isPlaying)
              Center(
                child: AnimatedOpacity(
                  opacity: (_showIcon || !isPlaying) ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.50),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
