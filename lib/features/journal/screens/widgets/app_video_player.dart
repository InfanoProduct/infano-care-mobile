import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class AppVideoPlayer extends StatefulWidget {
  final String videoPath;
  final bool autoPlay;
  final bool loop;
  final bool showControls;
  final BoxFit fit;

  const AppVideoPlayer({
    super.key,
    required this.videoPath,
    this.autoPlay = true,
    this.loop = true,
    this.showControls = true,
    this.fit = BoxFit.cover,
  });

  @override
  State<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(covariant AppVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _controller?.dispose();
      _isInitialized = false;
      _hasError = false;
      _initPlayer();
    }
  }

  Future<void> _initPlayer() async {
    try {
      final path = widget.videoPath;
      if (path.isEmpty) {
        setState(() => _hasError = true);
        return;
      }

      if (path.startsWith('http://') || path.startsWith('https://')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(path));
      } else if (path.startsWith('data:video/') || path.startsWith('data:application/')) {
        final commaIndex = path.indexOf(',');
        final base64Str = commaIndex != -1 ? path.substring(commaIndex + 1) : path;
        final bytes = base64Decode(base64Str);
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/video_cache_${path.hashCode.abs()}.mp4');
        if (!await tempFile.exists()) {
          await tempFile.writeAsBytes(bytes);
        }
        _controller = VideoPlayerController.file(tempFile);
      } else {
        File file = File(path);
        if (!await file.exists()) {
          final appDocDir = await getApplicationDocumentsDirectory();
          final fileName = path.split('/').last;
          final fallback1 = File('${appDocDir.path}/video_diaries/$fileName');
          if (await fallback1.exists()) {
            file = fallback1;
          } else {
            final fallback2 = File('${appDocDir.path}/$fileName');
            if (await fallback2.exists()) {
              file = fallback2;
            } else {
              if (mounted) setState(() => _hasError = true);
              return;
            }
          }
        }
        _controller = VideoPlayerController.file(file);
      }

      await _controller!.initialize();
      _controller!.setLooping(widget.loop);
      if (widget.autoPlay) {
        await _controller!.play();
      }
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || _controller == null) {
      return Container(
        color: const Color(0xFF111827),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.movie_filter_rounded, color: Colors.white70, size: 48),
              SizedBox(height: 8),
              Text(
                'Video Diary Memory ✨',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: const Color(0xFF111827),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFEC4899)),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.showControls
          ? () {
              setState(() {
                if (_controller!.value.isPlaying) {
                  _controller!.pause();
                } else {
                  _controller!.play();
                }
              });
            }
          : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: widget.fit,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
          if (widget.showControls && !_controller!.value.isPlaying)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
            ),
        ],
      ),
    );
  }
}
