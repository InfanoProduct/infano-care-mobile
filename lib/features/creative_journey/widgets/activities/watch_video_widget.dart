import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class WatchVideoWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onCompleted;

  const WatchVideoWidget({super.key, required this.content, required this.onCompleted});

  @override
  State<WatchVideoWidget> createState() => _WatchVideoWidgetState();
}

class _WatchVideoWidgetState extends State<WatchVideoWidget> {
  YoutubePlayerController? _controller;
  bool _videoEnded = false;
  bool _answerSelected = false;
  int? _selectedOption;

  // Default educational YouTube video ID for growth spurts/puberty
  static const String _defaultYoutubeVideoId = 'L0MK7qz13bU';

  @override
  void initState() {
    super.initState();
    String videoId = widget.content['youtubeVideoId'] as String? ?? '';
    if (videoId.isEmpty || videoId == 'PLACEHOLDER_VIDEO_ID') {
      videoId = _defaultYoutubeVideoId;
    }

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
      ),
    )..addListener(_onPlayerStateChange);
  }

  void _onPlayerStateChange() {
    if (_controller?.value.playerState == PlayerState.ended && !_videoEnded) {
      setState(() => _videoEnded = true);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onPlayerStateChange);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Video player
          _buildVideoPlayer(),

          // Content below video
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.content['title'] as String? ?? '🎬 60 Seconds on Growth Spurts',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.content['scriptSummary'] as String? ??
                      'Gigi walks along the timeline road explaining growth spurts — fast bone growth, growing pains, and how every body\'s spurt is different.',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppColors.textMedium,
                    height: 1.5,
                  ),
                ),

                // Post-video question section
                const SizedBox(height: 24),
                _buildPostVideoQuestion(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_controller == null) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎬', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(
                'Video Loading...',
                style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.purple,
        progressColors: const ProgressBarColors(
          playedColor: AppColors.purple,
          handleColor: AppColors.pink,
        ),
      ),
    );
  }

  Widget _buildPostVideoQuestion() {
    final q = widget.content['postVideoQuestion'] as Map<String, dynamic>?;
    final questionText = q?['text'] as String? ?? 'Did you know growing pains were a real thing?';
    final options = List<String>.from(q?['options'] as List? ?? ['👍 Yes, I knew!', '😲 No, that\'s new!']);
    final feedbackText = q?['feedbackText'] as String? ?? 'Now you know — and knowing makes it way less scary when it happens! 🌱';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                questionText,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 14),

              ...options.asMap().entries.map((e) {
                final picked = _selectedOption == e.key;

                // Pastel styling for selected state
                final optionBg = picked
                    ? const Color(0xFFEDE9FE) // Soft Lavender Pastel
                    : Colors.white;
                final optionBorder = picked
                    ? const Color(0xFFA78BFA) // Pastel Purple Border
                    : AppColors.purple.withValues(alpha: 0.15);

                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedOption = e.key;
                    _answerSelected = true;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: optionBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: optionBorder,
                        width: picked ? 2.0 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: picked
                              ? const Color(0xFFA78BFA).withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.value,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: picked ? FontWeight.w900 : FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (picked)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.purple,
                            size: 22,
                          )
                        else
                          Icon(
                            Icons.radio_button_unchecked_rounded,
                            color: AppColors.textLight.withValues(alpha: 0.5),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        if (_answerSelected) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                const Text('🌱', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    feedbackText,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 20),

          // Solid Dark Purple CTA
          GestureDetector(
            onTap: widget.onCompleted,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.purple,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                'Collect XP ⭐',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }
}
