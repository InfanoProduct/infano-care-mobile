import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

class LmsVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;
  final VoidCallback? onVideoCompleted;
  final bool isFullScreen;

  const LmsVideoPlayer({
    super.key,
    required this.videoUrl,
    this.title = '',
    this.onVideoCompleted,
    this.isFullScreen = false,
  });

  @override
  State<LmsVideoPlayer> createState() => _LmsVideoPlayerState();
}

class _LmsVideoPlayerState extends State<LmsVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  double _currentSpeed = 1.0;
  String _currentQuality = 'Auto';
  bool _isDraggingSlider = false;
  double _sliderValue = 0.0;

  // Double tap seek animation indicators
  bool _showRewindIndicator = false;
  bool _showForwardIndicator = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(LmsVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      _hasError = false;
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  void _initializePlayer([Duration? startAt]) {
    if (widget.videoUrl.trim().isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    try {
      final uri = Uri.parse(widget.videoUrl);
      _controller = VideoPlayerController.networkUrl(uri)
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {
            _isInitialized = true;
            _hasError = false;
          });
          if (startAt != null) {
            _controller?.seekTo(startAt);
          }
          _controller?.setPlaybackSpeed(_currentSpeed);
          _controller?.play();
          _startHideTimer();
        }).catchError((e) {
          debugPrint('[LmsVideoPlayer] Init Error: $e');
          if (mounted) {
            setState(() => _hasError = true);
          }
        });

      _controller?.addListener(_videoListener);
    } catch (e) {
      debugPrint('[LmsVideoPlayer] Exception during init: $e');
      setState(() => _hasError = true);
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;
    final value = _controller!.value;

    if (value.position >= value.duration && value.duration > Duration.zero) {
      widget.onVideoCompleted?.call();
    }

    if (!_isDraggingSlider) {
      setState(() {});
    }
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _showControls = true;
        _hideControlsTimer?.cancel();
      } else {
        _controller!.play();
        _startHideTimer();
      }
    });
  }

  void _seekRelative(int seconds) {
    if (_controller == null || !_isInitialized) return;
    HapticFeedback.selectionClick();
    final current = _controller!.value.position;
    final target = current + Duration(seconds: seconds);
    final duration = _controller!.value.duration;

    if (target < Duration.zero) {
      _controller!.seekTo(Duration.zero);
    } else if (target > duration) {
      _controller!.seekTo(duration);
    } else {
      _controller!.seekTo(target);
    }

    _startHideTimer();
  }

  void _onDoubleTapLeft() {
    setState(() => _showRewindIndicator = true);
    _seekRelative(-10);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showRewindIndicator = false);
    });
  }

  void _onDoubleTapRight() {
    setState(() => _showForwardIndicator = true);
    _seekRelative(10);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showForwardIndicator = false);
    });
  }

  void _openFullScreen(BuildContext context) async {
    if (_controller == null || !_isInitialized) return;
    HapticFeedback.lightImpact();

    final currentPosition = _controller!.value.position;
    final isPlaying = _controller!.value.isPlaying;

    _controller?.pause();

    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (ctx, anim1, anim2) {
          return _FullScreenVideoView(
            videoUrl: widget.videoUrl,
            title: widget.title,
            initialPosition: currentPosition,
            initialSpeed: _currentSpeed,
            initialQuality: _currentQuality,
            autoPlay: isPlaying,
          );
        },
        transitionsBuilder: (ctx, anim, _, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );

    // Returned to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (mounted) {
      _controller?.play();
      _startHideTimer();
    }
  }

  void _showQualityMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildQualitySheet(ctx),
    );
  }

  void _showSpeedMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSpeedSheet(ctx),
    );
  }

  Widget _buildQualitySheet(BuildContext context) {
    final qualities = [
      {'label': 'Auto (Recommended)', 'val': 'Auto', 'icon': Icons.auto_awesome_rounded},
      {'label': '1080p (Full HD)', 'val': '1080p', 'icon': Icons.hd_rounded},
      {'label': '720p (High Definition)', 'val': '720p', 'icon': Icons.high_quality_rounded},
      {'label': '480p (Standard)', 'val': '480p', 'icon': Icons.sd_rounded},
      {'label': '360p (Data Saver)', 'val': '360p', 'icon': Icons.data_saver_on_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_suggest_rounded, color: AppColors.purple, size: 22),
              const SizedBox(width: 10),
              Text(
                'Playback Quality',
                style: GoogleFonts.nunito(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...qualities.map((q) {
            final isSelected = _currentQuality == q['val'];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: isSelected ? const Color(0xFFF3E8FF) : Colors.transparent,
              leading: Icon(
                q['icon'] as IconData,
                color: isSelected ? AppColors.purple : const Color(0xFF64748B),
                size: 22,
              ),
              title: Text(
                q['label'] as String,
                style: GoogleFonts.nunito(
                  fontSize: 14.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.purple : AppColors.textDark,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.purple, size: 20)
                  : null,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentQuality = q['val'] as String);
                HapticFeedback.selectionClick();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Quality switched to $_currentQuality'),
                    duration: const Duration(seconds: 1),
                    backgroundColor: AppColors.purple,
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSpeedSheet(BuildContext context) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed_rounded, color: AppColors.purple, size: 22),
              const SizedBox(width: 10),
              Text(
                'Playback Speed',
                style: GoogleFonts.nunito(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...speeds.map((s) {
            final isSelected = _currentSpeed == s;
            final label = s == 1.0 ? '1.0x (Normal)' : '${s}x';
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: isSelected ? const Color(0xFFF3E8FF) : Colors.transparent,
              leading: Icon(
                Icons.play_circle_outline_rounded,
                color: isSelected ? AppColors.purple : const Color(0xFF64748B),
                size: 20,
              ),
              title: Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 14.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.purple : AppColors.textDark,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.purple, size: 20)
                  : null,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentSpeed = s);
                _controller?.setPlaybackSpeed(s);
                HapticFeedback.selectionClick();
              },
            );
          }),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final hours = d.inHours.toString();
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 220,
        color: const Color(0xFF0F172A),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off_rounded, size: 44, color: Color(0xFFEF4444)),
              const SizedBox(height: 10),
              Text(
                'Video unavailable or network error',
                style: GoogleFonts.nunito(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _hasError = false);
                  _initializePlayer();
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        height: 220,
        color: const Color(0xFF090D16),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.purple),
        ),
      );
    }

    final val = _controller!.value;
    final totalDuration = val.duration;
    final currentPosition = val.position;

    return AspectRatio(
      aspectRatio: val.aspectRatio > 0 ? val.aspectRatio : 16 / 9,
      child: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Raw Video Player Surface
            Positioned.fill(
              child: VideoPlayer(_controller!),
            ),

            // 2. Gesture Detectors for Double-Tap Rewind / Forward (Left 40% & Right 40%)
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onDoubleTap: _onDoubleTapLeft,
                    child: const SizedBox.expand(),
                  ),
                ),
                const Expanded(flex: 2, child: SizedBox.expand()),
                Expanded(
                  flex: 4,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onDoubleTap: _onDoubleTapRight,
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),

            // 3. Double-tap animated indicators
            if (_showRewindIndicator)
              Positioned(
                left: 30,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.fast_rewind_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 4),
                      Text('10s', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            if (_showForwardIndicator)
              Positioned(
                right: 30,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('10s', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      const Icon(Icons.fast_forward_rounded, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),

            // 4. Interactive Overlay (Animated Opacity)
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                // Quality Pill
                                InkWell(
                                  onTap: _showQualityMenu,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.hd_outlined, color: Colors.white, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          _currentQuality,
                                          style: GoogleFonts.nunito(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Speed Pill
                                InkWell(
                                  onTap: _showSpeedMenu,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_currentSpeed}x',
                                      style: GoogleFonts.nunito(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Center Play / Rewind / Forward Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            iconSize: 32,
                            icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                            onPressed: () => _seekRelative(-10),
                          ),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: AppColors.purple.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.purple.withValues(alpha: 0.4),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                val.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                size: 34,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            iconSize: 32,
                            icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                            onPressed: () => _seekRelative(10),
                          ),
                        ],
                      ),

                      // Bottom Progress & Fullscreen Row
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Scrubber & Duration Row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                Text(
                                  _formatDuration(currentPosition),
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 3,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                      activeTrackColor: AppColors.purple,
                                      inactiveTrackColor: Colors.white30,
                                      thumbColor: const Color(0xFFF472B6),
                                      overlayColor: AppColors.purple.withValues(alpha: 0.2),
                                    ),
                                    child: Slider(
                                      value: _isDraggingSlider
                                          ? _sliderValue
                                          : (totalDuration.inMilliseconds > 0
                                              ? currentPosition.inMilliseconds / totalDuration.inMilliseconds
                                              : 0.0).clamp(0.0, 1.0),
                                      onChanged: (val) {
                                        setState(() {
                                          _isDraggingSlider = true;
                                          _sliderValue = val;
                                        });
                                      },
                                      onChangeEnd: (val) {
                                        final targetMs = (val * totalDuration.inMilliseconds).round();
                                        _controller?.seekTo(Duration(milliseconds: targetMs));
                                        setState(() {
                                          _isDraggingSlider = false;
                                        });
                                        _startHideTimer();
                                      },
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatDuration(totalDuration),
                                  style: GoogleFonts.nunito(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Fullscreen Button
                                IconButton(
                                  iconSize: 22,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.fullscreen_rounded,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => _openFullScreen(context),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ],
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

/// Dedicated Landscape Full-Screen Viewer
class _FullScreenVideoView extends StatefulWidget {
  final String videoUrl;
  final String title;
  final Duration initialPosition;
  final double initialSpeed;
  final String initialQuality;
  final bool autoPlay;

  const _FullScreenVideoView({
    required this.videoUrl,
    required this.title,
    required this.initialPosition,
    required this.initialSpeed,
    required this.initialQuality,
    required this.autoPlay,
  });

  @override
  State<_FullScreenVideoView> createState() => _FullScreenVideoViewState();
}

class _FullScreenVideoViewState extends State<_FullScreenVideoView> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  late double _speed;
  late String _quality;
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  void initState() {
    super.initState();
    _speed = widget.initialSpeed;
    _quality = widget.initialQuality;

    // Lock to Landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _initPlayer();
  }

  void _initPlayer() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _isInitialized = true);
        _controller?.seekTo(widget.initialPosition);
        _controller?.setPlaybackSpeed(_speed);
        if (widget.autoPlay) {
          _controller?.play();
        }
        _startHideTimer();
      });

    _controller?.addListener(() {
      if (mounted && !_isDragging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _showControls = false);
      }
    });
  }

  void _seekRelative(int seconds) {
    if (_controller == null || !_isInitialized) return;
    HapticFeedback.selectionClick();
    final cur = _controller!.value.position;
    final dur = _controller!.value.duration;
    final target = cur + Duration(seconds: seconds);
    if (target < Duration.zero) {
      _controller!.seekTo(Duration.zero);
    } else if (target > dur) {
      _controller!.seekTo(dur);
    } else {
      _controller!.seekTo(target);
    }
    _startHideTimer();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.purple)),
      );
    }

    final val = _controller!.value;
    final total = val.duration;
    final cur = val.position;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () {
            setState(() => _showControls = !_showControls);
            if (_showControls) _startHideTimer();
          },
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: val.aspectRatio > 0 ? val.aspectRatio : 16 / 9,
                  child: VideoPlayer(_controller!),
                ),
              ),

              // Overlay Controls
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Fullscreen Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.title,
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    _quality,
                                    style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    '${_speed}x',
                                    style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Center Controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                iconSize: 42,
                                icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                                onPressed: () => _seekRelative(-10),
                              ),
                              const SizedBox(width: 32),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    val.isPlaying ? _controller!.pause() : _controller!.play();
                                  });
                                  if (_controller!.value.isPlaying) {
                                    _startHideTimer();
                                  }
                                },
                                child: Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: AppColors.purple.withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.purple.withValues(alpha: 0.5),
                                        blurRadius: 18,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    val.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    size: 42,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 32),
                              IconButton(
                                iconSize: 42,
                                icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                                onPressed: () => _seekRelative(10),
                              ),
                            ],
                          ),

                          // Bottom Fullscreen Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Row(
                              children: [
                                Text(
                                  _formatDuration(cur),
                                  style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                      activeTrackColor: AppColors.purple,
                                      inactiveTrackColor: Colors.white30,
                                      thumbColor: const Color(0xFFF472B6),
                                    ),
                                    child: Slider(
                                      value: _isDragging
                                          ? _dragValue
                                          : (total.inMilliseconds > 0
                                              ? cur.inMilliseconds / total.inMilliseconds
                                              : 0.0).clamp(0.0, 1.0),
                                      onChanged: (v) {
                                        setState(() {
                                          _isDragging = true;
                                          _dragValue = v;
                                        });
                                      },
                                      onChangeEnd: (v) {
                                        final ms = (v * total.inMilliseconds).round();
                                        _controller?.seekTo(Duration(milliseconds: ms));
                                        setState(() => _isDragging = false);
                                        _startHideTimer();
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDuration(total),
                                  style: GoogleFonts.nunito(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  iconSize: 26,
                                  icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
