import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/mindful_activity.dart';
import '../../services/mindful_api.dart';
import '../../core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';

class MindfulDetailScreen extends StatefulWidget {
  final MindfulActivity activity;

  const MindfulDetailScreen({super.key, required this.activity});

  @override
  State<MindfulDetailScreen> createState() => _MindfulDetailScreenState();
}

class _MindfulDetailScreenState extends State<MindfulDetailScreen> {
  late YoutubePlayerController _controller;
  late ConfettiController _confettiController;
  bool _isCompleted = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.activity.videoUrl);
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _completeActivity() async {
    if (_isSubmitting || _isCompleted) return;

    setState(() => _isSubmitting = true);
    try {
      final api = Provider.of<MindfulApi>(context, listen: false);
      final result = await api.completeActivity(widget.activity.id);
      
      if (result['success']) {
        setState(() {
          _isCompleted = true;
          _isSubmitting = false;
        });
        _confettiController.play();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Awesome! You earned ${result['pointsEarned']} Pts!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.purple,
        onReady: () {
          debugPrint('Player is ready.');
        },
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const BackButton(color: AppColors.textDark),
            title: Text(
              widget.activity.category,
              style: const TextStyle(color: AppColors.textMedium, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    player,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.activity.title,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textDark,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.purple.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        widget.activity.category.toUpperCase(),
                                        style: const TextStyle(color: AppColors.purple, fontSize: 10, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.bloom,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.bloom.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.bolt, color: Colors.white, size: 20),
                                    Text(
                                      '${widget.activity.points}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                                    ),
                                    const Text('PTS', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              _buildInfoChip(Icons.person_outline, widget.activity.expertName ?? "Infano Expert"),
                              const SizedBox(width: 12),
                              _buildInfoChip(Icons.access_time_rounded, '${widget.activity.duration} mins'),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'About this activity',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.activity.description ?? "Take a moment for yourself and learn this mindfulness technique to help stay balanced and calm.",
                            style: const TextStyle(fontSize: 16, color: AppColors.textMedium, height: 1.7),
                          ),
                          const SizedBox(height: 48),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                if (!_isCompleted)
                                  BoxShadow(
                                    color: AppColors.purple.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  )
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isCompleted ? null : _completeActivity,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isCompleted ? AppColors.success : AppColors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                elevation: 0,
                              ),
                              child: _isSubmitting
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(_isCompleted ? Icons.check_circle_rounded : Icons.auto_awesome, color: Colors.white),
                                        const SizedBox(width: 12),
                                        Text(
                                          _isCompleted ? 'ACTIVITY COMPLETED' : 'I\'VE LEARNED THIS ACTIVITY',
                                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [Colors.purple, Colors.pink, Colors.orange, Colors.blue],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.purple),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
