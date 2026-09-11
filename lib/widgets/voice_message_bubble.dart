import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:infano_care_mobile/core/services/audio_manager.dart';

class VoiceMessageBubble extends StatefulWidget {
  final String url;
  final bool isMe;
  final Color? primaryColor;
  final Color? backgroundColor;

  const VoiceMessageBubble({
    super.key,
    required this.url,
    required this.isMe,
    this.primaryColor,
    this.backgroundColor,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackRate = 1.0;

  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _playerCompleteSub;
  StreamSubscription? _playerStateSub;

  @override
  void initState() {
    super.initState();
    _setupPlayer();
  }

  void _setupPlayer() {
    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _positionSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _playerCompleteSub = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });

    _playerStateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    AudioManager.instance.stopIfActive(_player);
    _durationSub?.cancel();
    _positionSub?.cancel();
    _playerCompleteSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      setState(() => _isLoading = true);
      try {
        final Source source = widget.url.startsWith('http://') || widget.url.startsWith('https://')
            ? UrlSource(widget.url)
            : DeviceFileSource(widget.url);

        await AudioManager.instance.registerAndPlay(_player, widget.url, source);
        await _player.setPlaybackRate(_playbackRate);
      } catch (e) {
        debugPrint('[VoiceMessageBubble] Error playing audio: $e');
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _isLoading = false;
          });
        }
      }
    }
  }

  void _togglePlaybackRate() async {
    double nextRate = 1.0;
    if (_playbackRate == 1.0) {
      nextRate = 1.5;
    } else if (_playbackRate == 1.5) {
      nextRate = 2.0;
    } else {
      nextRate = 1.0;
    }

    setState(() => _playbackRate = nextRate);
    if (_isPlaying) {
      await _player.setPlaybackRate(nextRate);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.primaryColor ??
        (widget.isMe ? const Color(0xFF9F1239) : const Color(0xFF6D28D9));

    final totalMillis = _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0;
    final currentMillis = _position.inMilliseconds.toDouble().clamp(0.0, totalMillis);

    return Container(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Play/Pause/Loading Button
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: _isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                          ),
                        )
                      : Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: themeColor,
                          size: 24,
                        ),
                ),
              ),
              const SizedBox(width: 8),

              // Waveform / Slider
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                        activeTrackColor: themeColor,
                        inactiveTrackColor: themeColor.withValues(alpha: 0.25),
                        thumbColor: themeColor,
                      ),
                      child: Slider(
                        value: currentMillis,
                        max: totalMillis,
                        onChanged: (val) {
                          _player.seek(Duration(milliseconds: val.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: themeColor.withValues(alpha: 0.8),
                            ),
                          ),
                          Text(
                            _duration == Duration.zero ? 'Voice Note' : _formatDuration(_duration),
                            style: TextStyle(
                              fontSize: 10,
                              color: themeColor.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              // Playback Speed Toggle (1x, 1.5x, 2x)
              GestureDetector(
                onTap: _togglePlaybackRate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_playbackRate == 1.0 ? '1' : _playbackRate == 1.5 ? '1.5' : '2'}x',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
