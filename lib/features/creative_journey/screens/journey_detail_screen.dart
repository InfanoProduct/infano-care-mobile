import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import '../models/creative_journey_models.dart';
import '../repositories/creative_journey_repository.dart';

// ── Shared Journey Pastel Styles ───────────────────────────────────────────────

class JourneyPastelStyle {
  final Color heroGradientStart;
  final Color heroGradientEnd;
  final Color cardBg;
  final Color cardBorder;
  final Color ctaColor;
  final Color textColor;

  const JourneyPastelStyle({
    required this.heroGradientStart,
    required this.heroGradientEnd,
    required this.cardBg,
    required this.cardBorder,
    required this.ctaColor,
    required this.textColor,
  });

  static const List<JourneyPastelStyle> styles = [
    // 0: My Changing Body (Soft Lavender / Purple)
    JourneyPastelStyle(
      heroGradientStart: Color(0xFFEDE9FE),
      heroGradientEnd: Color(0xFFF5F3FF),
      cardBg: Color(0xFFF5F3FF),
      cardBorder: Color(0xFFDDD6FE),
      ctaColor: Color(0xFF8B5CF6),
      textColor: Color(0xFF1E1B4B),
    ),
    // 1: Period Diaries (Soft Rose / Pink)
    JourneyPastelStyle(
      heroGradientStart: Color(0xFFFCE7F3),
      heroGradientEnd: Color(0xFFFDF2F8),
      cardBg: Color(0xFFFDF2F8),
      cardBorder: Color(0xFFFBCFE8),
      ctaColor: Color(0xFFDB2777),
      textColor: Color(0xFF1E1B4B),
    ),
  ];

  static JourneyPastelStyle getStyle(String journeyId) {
    if (journeyId.contains('period')) {
      return styles[1];
    }
    return styles[0];
  }
}

// ── Pastel Episode Card Themes ──────────────────────────────────────────────────

class PastelEpisodeTheme {
  final Color bg;
  final Color border;
  final Color iconGradientStart;
  final Color iconGradientEnd;

  const PastelEpisodeTheme({
    required this.bg,
    required this.border,
    required this.iconGradientStart,
    required this.iconGradientEnd,
  });

  static const List<PastelEpisodeTheme> themes = [
    PastelEpisodeTheme(
      bg: Color(0xFFF5F3FF),
      border: Color(0xFFDDD6FE),
      iconGradientStart: Color(0xFFC4B5FD),
      iconGradientEnd: Color(0xFFA78BFA),
    ),
    PastelEpisodeTheme(
      bg: Color(0xFFFDF2F8),
      border: Color(0xFFFBCFE8),
      iconGradientStart: Color(0xFFFBCFE8),
      iconGradientEnd: Color(0xFFF472B6),
    ),
    PastelEpisodeTheme(
      bg: Color(0xFFF0FDF4),
      border: Color(0xFFA7F3D0),
      iconGradientStart: Color(0xFFA7F3D0),
      iconGradientEnd: Color(0xFF34D399),
    ),
    PastelEpisodeTheme(
      bg: Color(0xFFFFFBEB),
      border: Color(0xFFFDE68A),
      iconGradientStart: Color(0xFFFDE68A),
      iconGradientEnd: Color(0xFFFBBF24),
    ),
    PastelEpisodeTheme(
      bg: Color(0xFFEFF6FF),
      border: Color(0xFFBFDBFE),
      iconGradientStart: Color(0xFFBFDBFE),
      iconGradientEnd: Color(0xFF60A5FA),
    ),
  ];

  static PastelEpisodeTheme getTheme(int index) =>
      themes[index % themes.length];
}

// ── Journey Detail Screen ─────────────────────────────────────────────────────

class CreativeJourneyDetailScreen extends StatefulWidget {
  final String journeyId;

  const CreativeJourneyDetailScreen({
    super.key,
    required this.journeyId,
  });

  @override
  State<CreativeJourneyDetailScreen> createState() => _CreativeJourneyDetailScreenState();
}

class _CreativeJourneyDetailScreenState extends State<CreativeJourneyDetailScreen> {
  late CreativeJourneyRepository _repo;
  CreativeJourney? _journey;
  List<NodeProgress> _progress = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = CreativeJourneyRepository(ApiService.instance.dio);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final journey = await _repo.getJourney(widget.journeyId);
      final progress = await _repo.getMyProgress();
      setState(() {
        _journey = journey;
        _progress = progress;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = JourneyPastelStyle.getStyle(widget.journeyId);

    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F5FF),
        appBar: AppBar(backgroundColor: style.heroGradientStart, leading: const BackButton(color: AppColors.textDark)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _journey == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F5FF),
        appBar: AppBar(backgroundColor: style.heroGradientStart, leading: const BackButton(color: AppColors.textDark)),
        body: Center(child: Text('Error: ${_error ?? "Journey not found"}')),
      );
    }

    final journey = _journey!;
    final totalXp = journey.episodes.fold(0, (sum, e) => sum + e.totalXP);
    final completedEpisodeCount = journey.episodes.where((e) => _isEpisodeCompleted(e)).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: CustomScrollView(
        slivers: [
          // App bar with matching pastel hero header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: style.heroGradientStart,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildCreativeHero(journey, totalXp, style),
            ),
          ),

          // Title header for episode list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    '📖 Episodes (${journey.episodes.length})',
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: style.ctaColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$completedEpisodeCount / ${journey.episodes.length} Done',
                      style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: style.ctaColor),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Episode List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final episode = journey.episodes[index];
                  final isUnlocked = _isEpisodeUnlocked(episode, index);
                  final isCompleted = _isEpisodeCompleted(episode);

                  // Next episode is the first unlocked episode that is not yet completed
                  final isNext = isUnlocked && !isCompleted;

                  return _EpisodeCard(
                    episode: episode,
                    index: index,
                    isUnlocked: isUnlocked,
                    isCompleted: isCompleted,
                    isNextEpisode: isNext,
                    onTap: () {
                      if (isUnlocked) {
                        context.push('/creative-journey/episode/${episode.id}');
                      } else {
                        final prevTitle = journey.episodes[index - 1].title;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '🔒 Complete "$prevTitle" to unlock this episode!',
                              style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                            ),
                            backgroundColor: AppColors.purple,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        );
                      }
                    },
                  ).animate().fadeIn(delay: (index * 60).ms, duration: 400.ms).slideY(begin: 0.1);
                },
                childCount: journey.episodes.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isEpisodeCompleted(CreativeEpisode episode) {
    if (episode.nodes.isEmpty) return false;

    // Collect all node IDs for this episode
    final epNodeIds = episode.nodes.map((n) => n.nodeId).toSet();

    // Count completed nodes matching this episode's node IDs
    final completedCount = _progress
        .where((p) => p.isCompleted && epNodeIds.contains(p.nodeId))
        .length;

    // Episode is completed ONLY when ALL nodes in this episode are completed
    return completedCount >= epNodeIds.length;
  }

  bool _isEpisodeUnlocked(CreativeEpisode episode, int index) {
    if (index == 0 || episode.order == 1) return true;
    if (_journey == null) return false;

    final prevEpisode = _journey!.episodes[index - 1];
    return _isEpisodeCompleted(prevEpisode);
  }

  Widget _buildCreativeHero(CreativeJourney journey, int totalXp, JourneyPastelStyle style) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [style.heroGradientStart, style.heroGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Top Title + XP Pill Row
              Row(
                children: [
                  Text(journey.icon ?? '🌸', style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          journey.title,
                          style: GoogleFonts.nunito(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: style.textColor,
                          ),
                        ),
                        Text(
                          'Ages ${journey.ageBand ?? "9-15"} • ${journey.episodes.length} Episodes',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Total XP Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '500 Coins',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Creative Highlight Pill: "Designed by experts with Love & Care 💖"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: style.ctaColor.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: style.ctaColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_rounded, color: Color(0xFFEC4899), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Designed by experts with Love & Care',
                      style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: style.ctaColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('✨', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Spacious Creative Pastel Episode Card ──────────────────────────────────────

class _EpisodeCard extends StatelessWidget {
  final CreativeEpisode episode;
  final int index;
  final bool isUnlocked;
  final bool isCompleted;
  final bool isNextEpisode;
  final VoidCallback? onTap;

  const _EpisodeCard({
    required this.episode,
    required this.index,
    required this.isUnlocked,
    this.isCompleted = false,
    this.isNextEpisode = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = PastelEpisodeTheme.getTheme(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: isUnlocked ? theme.bg : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isUnlocked ? theme.border : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isUnlocked
                ? theme.iconGradientStart.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Episode Icon Thumbnail
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: isUnlocked
                            ? LinearGradient(
                                colors: [theme.iconGradientStart, theme.iconGradientEnd],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [Colors.grey.shade200, Colors.grey.shade300],
                              ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isUnlocked
                            ? [
                                BoxShadow(
                                  color: theme.iconGradientStart.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          episode.episodeIcon ?? '🗺️',
                          style: TextStyle(
                            fontSize: 28,
                            color: isUnlocked ? Colors.white : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                    if (!isUnlocked)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: Color(0xFF9CA3AF),
                            size: 13,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 16),

                // 2. Episode Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + XP Pill Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              episode.title,
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isUnlocked ? AppColors.textDark : AppColors.textMedium,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? const Color(0xFFFEF9C3)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🪙', style: TextStyle(fontSize: 11)),
                                const SizedBox(width: 3),
                                Text(
                                  '+83 Coins',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isUnlocked ? const Color(0xFF92400E) : AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        episode.description ?? '',
                        style: GoogleFonts.nunito(
                          fontSize: 12.5,
                          color: isUnlocked ? AppColors.textMedium : AppColors.textLight,
                          height: 1.45,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),

                      // 3. Bottom Row: Clean CTA
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isUnlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isNextEpisode
                                      ? const [Color(0xFFEDE9FE), Color(0xFFFCE7F3)]
                                      : [theme.iconGradientStart, theme.iconGradientEnd],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: isNextEpisode
                                    ? Border.all(color: const Color(0xFFC4B5FD), width: 1.5)
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isNextEpisode ? const Color(0xFFA78BFA) : theme.iconGradientStart).withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isNextEpisode ? 'Next Episode' : 'Explore Path',
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: isNextEpisode ? const Color(0xFF4C1D95) : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 13,
                                    color: isNextEpisode ? const Color(0xFF4C1D95) : Colors.white,
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock_rounded, size: 12, color: AppColors.textLight),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Locked Episode',
                                    style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
