import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import '../application/journey_map_cubit.dart';
import '../models/creative_journey_models.dart';
import '../repositories/creative_journey_repository.dart';
import 'package:infano_care_mobile/features/home/bloc/dashboard_cubit.dart';
import '../widgets/gigi_welcome_banner.dart';

// ── Pastel Design System ───────────────────────────────────────────────────────

class PastelCardStyle {
  final Color bg;
  final Color border;
  final Color ctaColor;
  final Color badgeBg;
  final Color badgeTextColor;
  final String assetImage;

  const PastelCardStyle({
    required this.bg,
    required this.border,
    required this.ctaColor,
    required this.badgeBg,
    required this.badgeTextColor,
    required this.assetImage,
  });

  static const List<PastelCardStyle> styles = [
    // 0: Soft Lavender / Purple
    PastelCardStyle(
      bg: Color(0xFFF5F3FF),
      border: Color(0xFFDDD6FE),
      ctaColor: Color(0xFF8B5CF6),
      badgeBg: Color(0xFFEDE9FE),
      badgeTextColor: Color(0xFF6D28D9),
      assetImage: 'assets/images/community_banner.png',
    ),
    // 1: Soft Rose / Pink
    PastelCardStyle(
      bg: Color(0xFFFDF2F8),
      border: Color(0xFFFBCFE8),
      ctaColor: Color(0xFFDB2777),
      badgeBg: Color(0xFFFCE7F3),
      badgeTextColor: Color(0xFFBE185D),
      assetImage: 'assets/images/period_onboarding.png',
    ),
    // 2: Soft Mint / Emerald
    PastelCardStyle(
      bg: Color(0xFFF0FDF4),
      border: Color(0xFFA7F3D0),
      ctaColor: Color(0xFF059669),
      badgeBg: Color(0xFFD1FAE5),
      badgeTextColor: Color(0xFF047857),
      assetImage: 'assets/images/maya.png',
    ),
    // 3: Soft Amber / Peach
    PastelCardStyle(
      bg: Color(0xFFFFFBEB),
      border: Color(0xFFFDE68A),
      ctaColor: Color(0xFFD97706),
      badgeBg: Color(0xFFFEF3C7),
      badgeTextColor: Color(0xFFB45309),
      assetImage: 'assets/images/hook.jpeg',
    ),
  ];

  static PastelCardStyle getStyle(int index) =>
      styles[index % styles.length];
}

// ── Hub Screen ─────────────────────────────────────────────────────────────────

class CreativeJourneyHubScreen extends StatelessWidget {
  const CreativeJourneyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => JourneyMapCubit(
        CreativeJourneyRepository(ApiService.instance.dio),
      )..load(),
      child: const _CreativeJourneyHubView(),
    );
  }
}

class _CreativeJourneyHubView extends StatelessWidget {
  const _CreativeJourneyHubView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: BlocBuilder<JourneyMapCubit, JourneyMapState>(
        builder: (context, state) {
          return switch (state) {
            JourneyMapLoading() || JourneyMapInitial() => const Center(child: CircularProgressIndicator()),
            JourneyMapError(message: final msg) => Center(child: Text('Error: $msg')),
            JourneyMapLoaded(journeys: final journeys, growthStreakDays: final streak, allProgress: final progress) =>
              _buildLoaded(context, journeys, streak, progress),
            _ => const Center(child: CircularProgressIndicator()),
          };
        },
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, List<CreativeJourney> journeys, int streak, List<NodeProgress> progress) {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          floating: true,
          pinned: true,
          backgroundColor: const Color(0xFFEDE9FE),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                try {
                  context.read<DashboardCubit>().setTab(0);
                } catch (_) {
                  context.go('/');
                }
              }
            },
          ),
          title: Text(
            'Learning Journey',
            style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark),
          ),
          centerTitle: true,
        ),

        // 1. Dynamic Gigi Welcome Banner (Beanbag image + speech bubble tip)
        SliverToBoxAdapter(
          child: GigiWelcomeBanner(
            streakDays: streak,
            progress: progress,
          ),
        ),

        // 2. Section Header
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Text(
              '🗺️ Choose Your Journey',
              style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark),
            ),
          ),
        ),

        // 3. Journeys List Cards
        if (journeys.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('🌱', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                Text('Journeys coming soon!', style: GoogleFonts.nunito(fontSize: 16, color: AppColors.textMedium)),
              ]),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final journey = journeys[index];

                  // Journey 0 is unlocked by default. Journey N is unlocked if Journey N-1 is completed.
                  bool isUnlocked = index == 0;
                  String? prevJourneyTitle;
                  if (index > 0) {
                    final prevJourney = journeys[index - 1];
                    prevJourneyTitle = prevJourney.title;
                    final completedCount = progress.where((p) => p.isCompleted).length;
                    isUnlocked = completedCount >= 5; // Episode 1 has 5 nodes completed
                  }

                  return _JourneyCard(
                    journey: journey,
                    index: index,
                    isUnlocked: isUnlocked,
                    prevJourneyTitle: prevJourneyTitle,
                  )
                      .animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).slideY(begin: 0.1);
                },
                childCount: journeys.length,
              ),
            ),
          ),

        // 4. Coming Soon Teaser
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          sliver: SliverToBoxAdapter(
            child: _buildComingSoonTeaser(),
          ),
        ),
      ],
    );
  }

  Widget _buildComingSoonTeaser() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
      ),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFE9D5FF), Color(0xFFFBCFE8)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: Text('🧠', style: TextStyle(fontSize: 28))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mind & Mood Waves', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          const SizedBox(height: 2),
          Text('Coming soon — Journey 3', style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textLight)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
          child: Text('🔒 Soon', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textLight)),
        ),
      ]),
    );
  }
}

// ── Pastel Journey Card ─────────────────────────────────────────────────────────

class _JourneyCard extends StatelessWidget {
  final CreativeJourney journey;
  final int index;
  final bool isUnlocked;
  final String? prevJourneyTitle;

  const _JourneyCard({
    required this.journey,
    required this.index,
    this.isUnlocked = true,
    this.prevJourneyTitle,
  });

  @override
  Widget build(BuildContext context) {
    final style = PastelCardStyle.getStyle(index);

    return GestureDetector(
      onTap: () {
        if (isUnlocked) {
          context.push('/creative-journey/journey/${journey.id}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🔒 Complete all episodes in "${prevJourneyTitle ?? 'the previous journey'}" to unlock this journey! ✨',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
              ),
              backgroundColor: AppColors.purple,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isUnlocked ? style.bg : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isUnlocked ? style.border : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? style.ctaColor.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. Thumbnail Header Image with overlay & title
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: Image.asset(
                    style.assetImage,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => _buildGradientPlaceholder(journey, style),
                  ),
                ),
                // Gradient overlay for contrast
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          isUnlocked
                              ? Colors.black.withValues(alpha: 0.65)
                              : Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                ),
                // Title & Icon over image
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Row(
                    children: [
                      Text(journey.icon ?? '🌸', style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          journey.title,
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              const Shadow(
                                color: Colors.black45,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Chip (Age Band / Lock Badge)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isUnlocked ? Colors.black.withValues(alpha: 0.45) : const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isUnlocked ? 'Ages ${journey.ageBand ?? "9-15"}' : '🔒 LOCKED',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 2. Card Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    journey.description,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.textMedium,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),

                  // Info Badges Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isUnlocked ? style.badgeBg : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('📖', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              '${journey.episodes.length} Episodes',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isUnlocked ? style.badgeTextColor : AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isUnlocked ? const Color(0xFFFEF9C3) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              '500 Coins',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isUnlocked ? const Color(0xFF92400E) : AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. CTA Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isUnlocked ? style.ctaColor : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isUnlocked
                          ? [
                              BoxShadow(
                                color: style.ctaColor.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isUnlocked
                              ? 'Explore Journey (${journey.episodes.length} Ep)'
                              : '🔒 Locked (Complete ${prevJourneyTitle ?? "Previous Journey"})',
                          style: GoogleFonts.nunito(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isUnlocked ? Icons.arrow_forward_rounded : Icons.lock_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientPlaceholder(CreativeJourney journey, PastelCardStyle style) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [style.ctaColor, style.badgeTextColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
