import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      bg: Color(0xFFFAF5FF),
      border: Color(0xFFE9D5FF),
      iconGradientStart: Color(0xFFE9D5FF),
      iconGradientEnd: Color(0xFFC4B5FD),
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
    final completedEpisodeCount = journey.episodes.where((e) => _isEpisodeCompleted(e)).length;
    final totalEpisodes = journey.episodes.length;
    final overallRatio = totalEpisodes > 0 ? completedEpisodeCount / totalEpisodes : 0.0;

    // Find the next episode to feature in "Quick Continue Target Banner"
    CreativeEpisode? targetEpisode;
    for (int i = 0; i < journey.episodes.length; i++) {
      final ep = journey.episodes[i];
      if (_isEpisodeUnlocked(ep, i) && !_isEpisodeCompleted(ep)) {
        targetEpisode = ep;
        break;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.purple,
        child: CustomScrollView(
        slivers: [
          // App bar with matching pastel hero header & overall progress stats
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            backgroundColor: style.heroGradientStart,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildCreativeHero(journey, completedEpisodeCount, totalEpisodes, overallRatio, style),
            ),
          ),

          // Pinned Target "Continue Journey" Quick Action Card (if next episode available)
          if (targetEpisode != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              sliver: SliverToBoxAdapter(
                child: _buildContinueTargetCard(targetEpisode, style),
              ),
            ),

          // Title header for episode list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '📖 Episodes (${journey.episodes.length})',
                      style: GoogleFonts.nunito(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: style.ctaColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$completedEpisodeCount / ${journey.episodes.length} Done',
                      style: GoogleFonts.nunito(fontSize: 11.5, fontWeight: FontWeight.w800, color: style.ctaColor),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Episode List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final episode = journey.episodes[index];
                  final isUnlocked = _isEpisodeUnlocked(episode, index);
                  final isCompleted = _isEpisodeCompleted(episode);
                  final isNext = isUnlocked && !isCompleted;
                  final completedNodes = _getEpisodeCompletedNodeCount(episode);
                  final totalNodes = episode.nodes.length;

                  return _EpisodeCard(
                    episode: episode,
                    index: index,
                    isUnlocked: isUnlocked,
                    isCompleted: isCompleted,
                    isNextEpisode: isNext,
                    completedNodes: completedNodes,
                    totalNodes: totalNodes,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (isUnlocked) {
                        context.push('/creative-journey/episode/${episode.id}').then((_) {
                          if (mounted) _loadData();
                        });
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
                  ).animate().fadeIn(delay: (index * 50).ms, duration: 350.ms).slideY(begin: 0.08);
                },
                childCount: journey.episodes.length,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  bool _isEpisodeCompleted(CreativeEpisode episode) {
    if (episode.nodes.isEmpty) return false;
    final epNodeIds = episode.nodes.map((n) => n.nodeId).toSet();
    final completedCount = _progress
        .where((p) => p.isCompleted && epNodeIds.contains(p.nodeId))
        .length;

    return completedCount == epNodeIds.length;
  }

  int _getEpisodeCompletedNodeCount(CreativeEpisode episode) {
    if (episode.nodes.isEmpty) return 0;
    final epNodeIds = episode.nodes.map((n) => n.nodeId).toSet();
    return _progress.where((p) => p.isCompleted && epNodeIds.contains(p.nodeId)).length;
  }

  bool _isEpisodeUnlocked(CreativeEpisode episode, int index) {
    if (index == 0 || episode.order == 1) return true;
    if (_journey == null) return false;

    final prevEpisode = _journey!.episodes[index - 1];
    return _isEpisodeCompleted(prevEpisode);
  }

  Widget _buildCreativeHero(
    CreativeJourney journey,
    int completedEpisodeCount,
    int totalEpisodes,
    double overallRatio,
    JourneyPastelStyle style,
  ) {
    final percentage = (overallRatio * 100).round();

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
          padding: const EdgeInsets.fromLTRB(16, 36, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Top Title + XP Pill Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(journey.icon ?? '🌸', style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          journey.title,
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: style.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Ages ${journey.ageBand ?? "9-15"} • $completedEpisodeCount/$totalEpisodes Done ($percentage%)',
                          style: GoogleFonts.nunito(
                            fontSize: 11.5,
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Total XP Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 3),
                        Text(
                          '500 Coins',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Overall Journey Linear Progress Gauge
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: overallRatio,
                  backgroundColor: style.ctaColor.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(style.ctaColor),
                  minHeight: 5.5,
                ),
              ),
              const SizedBox(height: 8),

              // Creative Highlight Pill: "Designed by experts with Love & Care 💖"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: style.ctaColor.withValues(alpha: 0.08),
                      blurRadius: 8,
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
                    const Icon(Icons.favorite_rounded, color: Color(0xFFEC4899), size: 13),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Designed by experts with Love & Care',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: style.ctaColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildContinueTargetCard(CreativeEpisode episode, JourneyPastelStyle style) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [style.ctaColor, style.ctaColor.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: style.ctaColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/creative-journey/episode/${episode.id}').then((_) {
              if (mounted) _loadData();
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(episode.episodeIcon ?? '🎯', style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'UP NEXT TARGET',
                            style: GoogleFonts.nunito(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withValues(alpha: 0.9),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('🚀', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        episode.title,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Start Now',
                        style: GoogleFonts.nunito(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: style.ctaColor,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_forward_rounded, size: 13, color: style.ctaColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().scale(begin: const Offset(0.98, 0.98), end: const Offset(1.0, 1.0), duration: 600.ms, curve: Curves.easeInOut);
  }
}

// ── Spacious Creative Pastel Episode Card ──────────────────────────────────────

class _EpisodeCard extends StatelessWidget {
  final CreativeEpisode episode;
  final int index;
  final bool isUnlocked;
  final bool isCompleted;
  final bool isNextEpisode;
  final int completedNodes;
  final int totalNodes;
  final VoidCallback? onTap;

  const _EpisodeCard({
    required this.episode,
    required this.index,
    required this.isUnlocked,
    this.isCompleted = false,
    this.isNextEpisode = false,
    this.completedNodes = 0,
    this.totalNodes = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = PastelEpisodeTheme.getTheme(index);
    final nodeProgressRatio = totalNodes > 0 ? completedNodes / totalNodes : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isUnlocked ? theme.bg : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: isNextEpisode
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.28)
                : isUnlocked
                    ? const Color(0xFF644D95).withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.04),
            blurRadius: isNextEpisode ? 20 : 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.85),
            blurRadius: 6,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Live Background Element 1: Glowing Glass Specular Radial Orb (Top-Right)
            Positioned(
              top: -25,
              right: -25,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.85),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Live Background Element 2: Soft Watermark Motif (Bottom-Right)
            Positioned(
              bottom: -15,
              right: -15,
              child: Opacity(
                opacity: 0.08,
                child: Text(
                  episode.episodeIcon ?? '🗺️',
                  style: const TextStyle(fontSize: 90),
                ),
              ),
            ),

            // Main Card Content & InkWell Feedback
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                // 1. Episode Icon Thumbnail
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
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
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isUnlocked
                            ? [
                                BoxShadow(
                                  color: theme.iconGradientStart.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          episode.episodeIcon ?? '🗺️',
                          style: TextStyle(
                            fontSize: 24,
                            color: isUnlocked ? Colors.white : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                    if (isCompleted)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF10B981),
                            size: 20,
                          ),
                        ),
                      )
                    else if (!isUnlocked)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 20,
                          height: 20,
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
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

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
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: isUnlocked ? AppColors.textDark : AppColors.textMedium,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? const Color(0xFFFEF9C3)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🪙', style: TextStyle(fontSize: 10)),
                                const SizedBox(width: 2),
                                Text(
                                  '+83 Coins',
                                  style: GoogleFonts.nunito(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isUnlocked ? const Color(0xFF92400E) : AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        episode.description ?? '',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: isUnlocked ? AppColors.textMedium : AppColors.textLight,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Node Progress Indicator Bar (Responsive & Non-Overflowing)
                      if (isUnlocked && totalNodes > 0) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$completedNodes of $totalNodes nodes done',
                                style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isCompleted
                                      ? const Color(0xFF059669)
                                      : AppColors.textMedium,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCompleted)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🏆', style: TextStyle(fontSize: 10)),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Badge Earned',
                                    style: GoogleFonts.nunito(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: nodeProgressRatio,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              isCompleted ? const Color(0xFF10B981) : theme.iconGradientEnd,
                            ),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // 3. Bottom Row: Clean Responsive CTA Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isUnlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isNextEpisode
                                      ? const [Color(0xFFEDE9FE), Color(0xFFFCE7F3)]
                                      : [theme.iconGradientStart, theme.iconGradientEnd],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: isNextEpisode
                                    ? Border.all(color: const Color(0xFFC4B5FD), width: 1.2)
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isNextEpisode ? const Color(0xFFA78BFA) : theme.iconGradientStart).withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isNextEpisode ? 'Next Episode' : isCompleted ? 'Revisit Path' : 'Explore Path',
                                    style: GoogleFonts.nunito(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                      color: isNextEpisode ? const Color(0xFF4C1D95) : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 12,
                                    color: isNextEpisode ? const Color(0xFF4C1D95) : Colors.white,
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock_rounded, size: 11, color: AppColors.textLight),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Locked Episode',
                                    style: GoogleFonts.nunito(
                                      fontSize: 10.5,
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
    ],
  ),
),
);
}
}
