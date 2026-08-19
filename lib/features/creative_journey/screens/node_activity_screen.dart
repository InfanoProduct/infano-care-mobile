import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import '../models/creative_journey_models.dart';
import '../repositories/creative_journey_repository.dart';
import '../widgets/activities/mystery_task_box_widget.dart';
import '../widgets/activities/quiz_widget.dart';
import '../widgets/activities/watch_video_widget.dart';
import '../widgets/activities/identify_image_widget.dart';
import '../widgets/activities/myth_busters_widget.dart';
import '../widgets/activities/timeline_builder_widget.dart';
import '../widgets/activities/spot_the_change_widget.dart';
import '../widgets/activities/ask_gigi_widget.dart';
import '../widgets/activities/emoji_decoder_widget.dart';
import '../widgets/activities/match_pairs_widget.dart';
import '../widgets/activities/drag_to_label_widget.dart';
import '../widgets/activities/drag_to_sort_widget.dart';
import '../widgets/activities/scenario_choice_widget.dart';
import '../widgets/activities/mirror_reflection_flip_widget.dart';
import '../widgets/activities/comparison_filter_unmask_widget.dart';
import '../widgets/activities/body_appreciation_jar_widget.dart';
import 'story_comic_screen.dart';
import 'reflection_reward_screen.dart';
import 'package:infano_care_mobile/widgets/coin_burst_overlay.dart';

class NodeActivityScreen extends StatefulWidget {
  final CreativeNode node;
  final String episodeId;
  final bool isAlreadyCompleted;
  final void Function(int xpEarned) onCompleted;

  const NodeActivityScreen({
    super.key,
    required this.node,
    required this.episodeId,
    this.isAlreadyCompleted = false,
    required this.onCompleted,
    this.episodeTitle,
  });

  /// Human-readable episode title (e.g. "Skin Stories") for scoping Ask Gigi AI.
  final String? episodeTitle;

  @override
  State<NodeActivityScreen> createState() => _NodeActivityScreenState();
}

class _NodeActivityScreenState extends State<NodeActivityScreen> {
  late bool _showRedoMode;

  @override
  void initState() {
    super.initState();
    // If already completed, show summary first; otherwise show activity directly
    _showRedoMode = !widget.isAlreadyCompleted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDE9FE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(children: [
          Text(widget.node.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.node.title,
              style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('🪙', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                '+${widget.node.xpReward} Coins',
                style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFFB45309)),
              ),
            ]),
          ),
        ],
      ),
      body: _showRedoMode
          ? _buildActivity(context)
          : _buildCompletedSummary(context),
    );
  }

  Widget _buildCompletedSummary(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji Badge Container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF3E8FF), Color(0xFFFDF2F8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.35), width: 3),
              ),
              child: Center(
                child: Text(
                  widget.node.emoji,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 24),

            // Title
            Text(
              '${widget.node.title} — Completed!',
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // XP Collected Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '+${widget.node.xpReward} Coins Collected 🪙',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Subtitle description
            Text(
              'You\'ve already walked this step on your Body Timeline! You can review your progress or redo the activity anytime.',
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                color: AppColors.textMedium,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 36),

            // Action Buttons
            // 1. Back to Path (Primary CTA)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.purple,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Back to Path 🗺️',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 2. Redo Activity (Secondary Button)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showRedoMode = true;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.purple, width: 1.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.replay_rounded, color: AppColors.purple, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Redo Activity 🔄',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.purple,
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

  Widget _buildActivity(BuildContext context) {
    final content = {
      ...?widget.node.content,
      'xpReward': widget.node.xpReward,
      'coinsReward': widget.node.xpReward,
    };
    void complete([int? customCoins]) {
      final earnedCoins = customCoins ?? widget.node.xpReward;
      CoinBurstOverlay.show(
        context,
        coinsEarned: earnedCoins,
        onComplete: () {
          widget.onCompleted(earnedCoins);
        },
      );
    }

    return switch (widget.node.type) {
      'story' => StoryComicScreen(content: content, onCompleted: complete),
      'mystery_task_box' => MysteryTaskBoxWidget(content: content, onCompleted: complete),
      'quiz' => QuizWidget(content: content, onCompleted: complete),
      'watch_video' => WatchVideoWidget(content: content, onCompleted: complete),
      'identify_image' => IdentifyImageWidget(content: content, onCompleted: complete),
      'myth_busters' => MythBustersWidget(content: content, onCompleted: complete),
      'timeline_builder' => TimelineBuilderWidget(content: content, onCompleted: complete),
      'spot_the_change' => SpotTheChangeWidget(content: content, onCompleted: complete),
      'anonymous_question_box' => AskGigiWidget(
          content: {
            ...content,
            // Inject episode context so Gigi can scope her responses
            if (widget.episodeTitle != null) 'episodeTitle': widget.episodeTitle!,
            if (widget.episodeTitle != null)
              'episodeTopics': _topicsForEpisode(widget.episodeTitle!),
          },
          episodeId: widget.episodeId,
          nodeId: widget.node.nodeId,
          repo: CreativeJourneyRepository(ApiService.instance.dio),
          onCompleted: complete,
        ),
      'emoji_decoder' => EmojiDecoderWidget(content: content, onCompleted: complete),
      'match_pairs' => MatchPairsWidget(content: content, onCompleted: complete),
      'drag_to_label' => DragToLabelWidget(content: content, onCompleted: complete),
      'drag_to_sort' => DragToSortWidget(content: content, onCompleted: complete),
      'scenario_choice' => ScenarioChoiceWidget(content: content, onCompleted: complete),
      'mirror_reflection_flip' => MirrorReflectionFlipWidget(content: content, onCompleted: complete),
      'comparison_filter_unmask' => ComparisonFilterUnmaskWidget(content: content, onCompleted: complete),
      'body_appreciation_jar' => BodyAppreciationJarWidget(content: content, onCompleted: complete),
      'reflection_reward' => ReflectionRewardScreen(
          content: content,
          episodeTitle: widget.node.title,
          onCompleted: complete,
        ),
      _ => _buildFallback(complete),
    };
  }

  Widget _buildFallback(VoidCallback complete) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(widget.node.emoji, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text(widget.node.title, style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark)),
        const SizedBox(height: 8),
        Text('Activity coming soon!', style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textMedium)),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: complete,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.purple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Collect 🪙 Coins', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ),
      ]),
    );
  }

  /// Maps a cleaned episode title to a short comma-separated topic list
  /// that Gigi uses to scope her responses to the episode.
  static String _topicsForEpisode(String episodeTitle) {
    final t = episodeTitle.toLowerCase();
    if (t.contains('skin')) {
      return 'teenage skin, sebum, pimples, acne, oily skin, SPF, skincare routine, body hair, body odour, sweating';
    } else if (t.contains('growing pain') || t.contains('growing pains')) {
      return 'growth spurts, bone growth, growth plates, stretch marks, oestrogen, body reshaping, growing pains, tight clothes';
    } else if (t.contains('body timeline') || t.contains('timeline')) {
      return 'puberty timeline, growth spurts, body changes, skin changes, periods, body hair, hormones, body comparison';
    } else if (t.contains('period preview') || t.contains('period')) {
      return 'periods, menstrual cycle, first period, menstruation, pads, tampons, cramps, cycle tracking';
    } else if (t.contains('bra') || t.contains('basics')) {
      return 'bras, breast development, fitting, comfort, body confidence, breast changes in puberty';
    } else if (t.contains('body image')) {
      return 'body image, self-confidence, social media comparison, beauty standards, body positivity';
    } else if (t.contains('hygiene')) {
      return 'hygiene, deodorant, sweating, body odour, daily routine, dental care, cleanliness during puberty';
    }
    // Default: generic puberty topics
    return 'puberty, body changes, growing up, health, wellbeing for adolescent girls';
  }
}
