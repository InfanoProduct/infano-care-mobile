import 'dart:math' as math;
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/quest/celebration_overlay.dart';
import 'package:infano_care_mobile/features/home/bloc/dashboard_cubit.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/daily_log_sheet.dart';
import 'package:infano_care_mobile/features/tracker/bloc/tracker_bloc.dart';
import '../../tracker/bloc/quest_bloc.dart';
import '../../tracker/data/models/quest_models.dart';

import 'package:infano_care_mobile/screens/connect/circle_screen.dart';
import 'package:infano_care_mobile/features/creative_journey/screens/episode_path_screen.dart';
import 'package:infano_care_mobile/features/creative_journey/repositories/creative_journey_repository.dart';
import 'package:infano_care_mobile/features/creative_journey/models/creative_journey_models.dart';

class QuestScreen extends StatefulWidget {
  const QuestScreen({super.key});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<QuestBloc>().add(const QuestEvent.refresh());
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToQuest(BuildContext context, String? category, String title) async {
    debugPrint('[QUEST] _navigateToQuest called with title: "$title", category: "$category"');
    if (title == 'Track Your Period' || title.contains('Track Your Period')) {
      context.push('/onboarding/tracker/date');
      return;
    }
    if (title == 'Log Period Start' || title == 'Confirm Period End' || title == 'Log Symptoms & Mood' || title.contains('Symptoms') || title.contains('Log Symptoms') || title.contains('Period Start') || title.contains('Period End')) {
      final questBloc = context.read<QuestBloc>();
      final trackerBloc = context.read<TrackerBloc>();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: trackerBloc,
            child: DailyLogScreen(date: DateTime.now()),
          ),
        ),
      ).then((_) {
        questBloc.add(const QuestEvent.refresh());
      });
      return;
    }
    if (title == 'Gratitude Note' || title.contains('Gratitude') || title.contains('Note') || title.contains('Journal') || category == 'wellbeing') {
      final questBloc = context.read<QuestBloc>();
      context.push('/journal/new').then((_) {
        questBloc.add(const QuestEvent.refresh());
      });
      return;
    }
    if (title == 'PeerLine Connection' || category == 'connect') {
      try {
        context.read<DashboardCubit>().setTab(3);
      } catch (_) {}
      context.go('/home?tab=3');
      return;
    }
    if (title == 'Connect & Share' || title == 'Support a Friend' || category == 'circle' || category == 'community') {
      final questBloc = context.read<QuestBloc>();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const CircleScreen(),
        ),
      ).then((_) {
        questBloc.add(const QuestEvent.refresh());
      });
      return;
    }
    if (title == 'Explore Episode' || title == 'Complete Node' || title.contains('Explore') || title.contains('Episode') || title.contains('Node') || category == 'learning') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppColors.purple),
        ),
      );

      String targetEpisodeId = 'ce_body_timeline';
      try {
        final repo = CreativeJourneyRepository(ApiService.instance.dio);
        final journeys = await repo.listJourneys();
        final allProgress = await repo.getMyProgress();

        if (journeys.isNotEmpty) {
          CreativeEpisode? targetEp;
          for (final j in journeys) {
            for (final ep in j.episodes) {
              final epTotalNodes = ep.nodes.isNotEmpty ? ep.nodes.length : 10;
              final epCompletedCount = allProgress
                  .where((p) =>
                      (p.episodeId == ep.id || p.nodeId.startsWith(_getEpisodePrefix(ep.id))) &&
                      p.isCompleted)
                  .length;

              if (epCompletedCount < epTotalNodes) {
                targetEp = ep;
                break;
              }
            }
            if (targetEp != null) break;
          }

          if (targetEp != null) {
            targetEpisodeId = targetEp.id;
          } else if (journeys.first.episodes.isNotEmpty) {
            targetEpisodeId = journeys.first.episodes.last.id;
          }
        }
      } catch (e) {
        debugPrint('[QUEST] Failed to determine next episode dynamically: $e');
      }

      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading
      }

      if (context.mounted) {
        final questBloc = context.read<QuestBloc>();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EpisodePathScreen(episodeId: targetEpisodeId),
          ),
        ).then((_) {
          questBloc.add(const QuestEvent.refresh());
        });
      }
      return;
    }

    switch (category) {
      case 'tracker':
        try { context.read<DashboardCubit>().setTab(2); } catch (_) {}
        context.go('/home?tab=2');
        break;
      case 'learning':
        try { context.read<DashboardCubit>().setTab(1); } catch (_) {}
        context.go('/home?tab=1');
        break;
      case 'circle':
      case 'community':
        try { context.read<DashboardCubit>().setTab(4); } catch (_) {}
        context.go('/home?tab=4');
        break;
      case 'connect':
        try { context.read<DashboardCubit>().setTab(3); } catch (_) {}
        context.go('/home?tab=3');
        break;
      default:
        try { context.read<DashboardCubit>().setTab(0); } catch (_) {}
    }
  }

  static String _getEpisodePrefix(String episodeId) {
    switch (episodeId) {
      case 'ce_body_timeline':
        return 'bt_';
      case 'ce_growing_pains':
        return 'gp_';
      case 'ce_skin_stories':
        return 'ss_';
      case 'ce_period_preview':
        return 'pp_';
      case 'ce_bra_basics':
        return 'bb_';
      case 'ce_body_image':
        return 'bi_';
      case 'ce_cycle_basics':
        return 'cb_';
      case 'ce_food_mood':
        return 'fm_';
      case 'ce_body_quiet':
        return 'bq_';
      default:
        return episodeId.replaceAll('ce_', '');
    }
  }

  void _showCelebration(BuildContext context, String title, int points,
      {bool isLevelUp = false}) {
    // Use rootNavigator: false + builder context to ensure we only pop the dialog, not the screen
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => QuestCelebrationOverlay(
        title: title,
        points: points,
        isLevelUp: isLevelUp,
        onDismiss: () {
          if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<QuestBloc, QuestState>(
      listener: (context, state) {
        state.maybeWhen(
          loaded: (dailyQuests, weeklyChallenges, progress, badges, isRefreshing,
              lastCompletedQuest, lastLevel) {
            if (lastCompletedQuest != null) {
              context.read<QuestBloc>().add(const QuestEvent.clearCompletedQuest());
              _showCelebration(
                context,
                lastCompletedQuest.questTemplate.title,
                lastCompletedQuest.questTemplate.pointsBase,
              );
            } else if (lastLevel != null &&
                progress.currentLevel > lastLevel) {
              context.read<QuestBloc>().add(const QuestEvent.clearCompletedQuest());
              _showCelebration(
                context,
                'You reached Level ${progress.currentLevel}!',
                500,
                isLevelUp: true,
              );
            }
          },
          orElse: () {},
        );
      },
      child: BlocBuilder<QuestBloc, QuestState>(
        builder: (context, state) {
          return state.when(
            initial: () => const _LoadingView(),
            loading: () => const _LoadingView(),
            error: (message) => _ErrorView(
              message: message,
              onRetry: () =>
                  context.read<QuestBloc>().add(const QuestEvent.load()),
            ),
            loaded: (dailyQuests, weeklyChallenges, progress, badges, isRefreshing,
                lastCompletedQuest, lastLevel) {
              return Scaffold(
                backgroundColor: Colors.white,
                body: RefreshIndicator(
                  onRefresh: () async {
                    final bloc = context.read<QuestBloc>();
                    bloc.add(const QuestEvent.refresh());
                    await bloc.stream.firstWhere((state) => state.maybeWhen(
                          loaded: (_, _, _, _, isRefreshing, _, _) => !isRefreshing,
                          error: (_) => true,
                          orElse: () => false,
                        ));
                  },
                  color: AppColors.purple,
                  child: NestedScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      SliverAppBar(
                        automaticallyImplyLeading: false,
                        expandedHeight: 330,
                        pinned: true,
                        backgroundColor: AppColors.purple,
                        bottom: TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white60,
                          indicatorColor: Colors.white,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelStyle:
                              GoogleFonts.nunito(fontWeight: FontWeight.w700),
                          tabs: const [
                            Tab(text: 'Daily'),
                            Tab(text: 'Badges'),
                            Tab(text: 'Milestones'),
                            Tab(text: 'Weekly'),
                          ],
                        ),
                        flexibleSpace: FlexibleSpaceBar(
                          collapseMode: CollapseMode.pin,
                          background: _HeaderBackground(progress: progress),
                        ),
                      ),
                    ],
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        _DailyTab(
                          quests: dailyQuests,
                          onAccept: (id) => context
                              .read<QuestBloc>()
                              .add(QuestEvent.acceptQuest(id)),
                          onGo: (category, title) =>
                              _navigateToQuest(context, category, title),
                        ),
                        _BadgesTab(badges: badges),
                        const _MilestonesTab(),
                        _WeeklyTab(challenges: weeklyChallenges),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Header Background ──────────────────────────────────────────────────────

class _HeaderBackground extends StatelessWidget {
  final UserQuestProgress progress;
  const _HeaderBackground({required this.progress});

  static const thresholds = [3000, 8000, 18000, 35000, 60000, 100000, 150000, 220000, 300000];

  IconData _levelIcon(int level) {
    if (level <= 2) return Icons.eco_rounded;
    if (level <= 5) return Icons.local_florist_rounded;
    return Icons.brightness_7_rounded;
  }

  String _levelName(int level) {
    const names = [
      'Seedling', 'Bloom', 'Blossom', 'Petal', 'Radiance',
      'Luminary', 'Celestial', 'Cosmic', 'Stellar', 'Aurora',
    ];
    if (level <= names.length) return names[level - 1];
    return 'Legend';
  }

  int _nextLevelPoints(int level) {
    if (level <= thresholds.length) return thresholds[level - 1];
    return 300000;
  }

  @override
  Widget build(BuildContext context) {
    final level = progress.currentLevel;
    final points = progress.pointsTotal;
    final coins = progress.coinsBalance;
    final nextLevel = _nextLevelPoints(level);
    final pct = (nextLevel > 0 ? points / nextLevel : 0.0).clamp(0.0, 1.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFC084FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_levelIcon(level),
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Level $level: ${_levelName(level)}',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            '$points Lifetime XP',
                            style: GoogleFonts.nunito(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ── SPENDABLE COINS VAULT COUNTER ───────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 5),
                        Text(
                          '$coins',
                          style: GoogleFonts.nunito(
                            color: const Color(0xFF92400E),
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFFFDE047)),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$points / $nextLevel XP to Level ${level + 1}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('${(pct * 100).toInt()}%',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              _BloomGardenWidget(points: points, level: level),
            ],
          ),
        ),
      ),
    );
  }
}

class _BloomGardenWidget extends StatelessWidget {
  final int points;
  final int level;
  
  const _BloomGardenWidget({required this.points, required this.level});

  @override
  Widget build(BuildContext context) {
    const thresholds = [3000, 8000, 18000, 35000, 60000, 100000, 150000, 220000, 300000];
    final nextLevel = level <= thresholds.length ? thresholds[level - 1] : 300000;
    final pct = (nextLevel > 0 ? points / nextLevel : 0.0).clamp(0.0, 1.0);

    String stageName = 'Seedling Sprout';
    IconData plantIcon = Icons.eco_rounded;
    Color plantColor = const Color(0xFF34D399);
    String description = 'Keep completing daily quests to nurture your sprout.';

    if (pct >= 0.75) {
      stageName = 'Radiant Bloom';
      plantIcon = Icons.brightness_7_rounded;
      plantColor = const Color(0xFFFBBF24);
      description = 'Stunning! Your self-care garden is in full vibrant bloom!';
    } else if (pct >= 0.5) {
      stageName = 'Flowering Blossom';
      plantIcon = Icons.local_florist_rounded;
      plantColor = const Color(0xFFF472B6);
      description = 'Beautiful flowers are opening! Your consistency is shining.';
    } else if (pct >= 0.25) {
      stageName = 'Growing Bud';
      plantIcon = Icons.spa_rounded;
      plantColor = const Color(0xFF38BDF8);
      description = 'Leaves are branching out nicely. Great self-care habits!';
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                )
              ]
            ),
            child: Icon(plantIcon, color: plantColor, size: 30)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(duration: 1.seconds, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bloom Status: $stageName',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.nunito(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ── Daily Quests Tab ───────────────────────────────────────────────────────

class _DailyTab extends StatelessWidget {
  final List<UserQuest> quests;
  final void Function(String id) onAccept;
  final void Function(String? category, String title) onGo;

  const _DailyTab({
    required this.quests,
    required this.onAccept,
    required this.onGo,
  });

  void _showVibeCheckModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _VibeCheckSheet(),
    );
  }

  void _showQuickSparkModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _QuickSparkModal(),
    );
  }

  void _openMysteryChest(BuildContext context) async {
    try {
      final res = await ApiService.instance.dio.post('/quest/open-chest');
      if (context.mounted) {
        context.read<QuestBloc>().add(const QuestEvent.refresh());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 ${res.data['data']['description']} (+150 XP, +100 Coins)'),
            backgroundColor: AppColors.purple,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final err = (e as dynamic);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err.response?.data?['message']?.toString() ?? 'Complete 3 daily quests to unlock the chest!'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = quests.where((q) => q.status == 'completed').length;
    final isChestAvailable = completedCount >= 3;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // ── CREATIVE MICRO-ACTIVITIES SECTION ─────────────────────────────
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showVibeCheckModal(context),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE7F3),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF472B6).withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('💖', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text('Vibe Check', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: const Color(0xFF9D174D), fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('30s Energy Check-in', style: GoogleFonts.nunito(fontSize: 11, color: const Color(0xFFBE185D))),
                      const SizedBox(height: 6),
                      Text('+30 XP • +20 🪙', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF831843))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _showQuickSparkModal(context),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text('Quick Spark', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: const Color(0xFF065F46), fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('3-Question Trivia', style: GoogleFonts.nunito(fontSize: 11, color: const Color(0xFF047857))),
                      const SizedBox(height: 6),
                      Text('+50 XP • +35 🪙', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF064E3B))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── MYSTERY DISCOVERY CHEST BANNER ───────────────────────────────────
        GestureDetector(
          onTap: () => _openMysteryChest(context),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isChestAvailable 
                    ? [const Color(0xFFFEF3C7), const Color(0xFFFDE047)]
                    : [Colors.grey.shade100, Colors.grey.shade200],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isChestAvailable ? const Color(0xFFF59E0B) : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Text(isChestAvailable ? '🎁' : '🔒', style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isChestAvailable ? 'Mystery Discovery Chest Ready!' : 'Mystery Chest Locked',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: isChestAvailable ? const Color(0xFF92400E) : AppColors.textDark,
                        ),
                      ),
                      Text(
                        isChestAvailable
                            ? 'Tap to claim +150 XP, +100 Coins & 1x Streak Freeze!'
                            : 'Complete $completedCount/3 daily quests to unlock',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: isChestAvailable ? const Color(0xFFB45309) : AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isChestAvailable ? const Color(0xFF92400E) : AppColors.textLight,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        Divider(
          color: Colors.black.withValues(alpha: 0.08),
          height: 1,
          thickness: 1,
        ),

        const SizedBox(height: 20),

        Text(
          'Daily Personalized Quests',
          style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark),
        ),
        const SizedBox(height: 6),

        if (quests.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No quests available.\nPull down to refresh.', textAlign: TextAlign.center),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int crossAxisCount = 2;
              double mainAxisExtent = 192;

              if (width >= 900) {
                crossAxisCount = 4;
                mainAxisExtent = 195;
              } else if (width >= 600) {
                crossAxisCount = 3;
                mainAxisExtent = 195;
              } else if (width < 360) {
                crossAxisCount = 1;
                mainAxisExtent = 160;
              } else {
                crossAxisCount = 2;
                mainAxisExtent = 192;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 22,
                  mainAxisExtent: mainAxisExtent,
                ),
                itemCount: quests.length,
                itemBuilder: (context, index) {
                  final quest = quests[index];
                  return _QuestCard(
                    quest: quest,
                    index: index,
                    onAccept: () => onAccept(quest.id),
                    onGo: () => onGo(quest.questTemplate.category, quest.questTemplate.title),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

// ── Pastel Theme Data ────────────────────────────────────────────────────────

class _PastelTheme {
  final Color bgStart;
  final Color bgEnd;
  final Color accentColor;
  final Color borderColor;
  final String bgSymbol;
  final IconData icon;

  const _PastelTheme({
    required this.bgStart,
    required this.bgEnd,
    required this.accentColor,
    required this.borderColor,
    required this.bgSymbol,
    required this.icon,
  });
}

_PastelTheme _getPastelTheme(String? category, int index, bool isCompleted) {
  if (isCompleted) {
    return const _PastelTheme(
      bgStart: Color(0xFFF0FDF4),
      bgEnd: Color(0xFFDCFCE7),
      accentColor: Color(0xFF15803D),
      borderColor: Color(0xFF86EFAC),
      bgSymbol: '🎉',
      icon: Icons.check_circle_rounded,
    );
  }

  // Good To Know inspired pastel color themes
  final themes = const [
    _PastelTheme(
      bgStart: Color(0xFFFFF1F2),
      bgEnd: Color(0xFFFCE7F3),
      accentColor: Color(0xFFE11D48),
      borderColor: Color(0xFFFBCFE8),
      bgSymbol: '🩸',
      icon: Icons.calendar_today_rounded,
    ),
    _PastelTheme(
      bgStart: Color(0xFFF3E8FF),
      bgEnd: Color(0xFFE9D5FF),
      accentColor: Color(0xFF9333EA),
      borderColor: Color(0xFFD8B4FE),
      bgSymbol: '✨',
      icon: Icons.menu_book_rounded,
    ),
    _PastelTheme(
      bgStart: Color(0xFFE0F2FE),
      bgEnd: Color(0xFFBAE6FD),
      accentColor: Color(0xFF0284C7),
      borderColor: Color(0xFF7DD3FC),
      bgSymbol: '💎',
      icon: Icons.forum_rounded,
    ),
    _PastelTheme(
      bgStart: Color(0xFFECFDF5),
      bgEnd: Color(0xFFD1FADF),
      accentColor: Color(0xFF059669),
      borderColor: Color(0xFFA7F3D0),
      bgSymbol: '🌿',
      icon: Icons.self_improvement_rounded,
    ),
    _PastelTheme(
      bgStart: Color(0xFFFEF3C7),
      bgEnd: Color(0xFFFDE68A),
      accentColor: Color(0xFFD97706),
      borderColor: Color(0xFFFCD34D),
      bgSymbol: '💖',
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  if (category == 'tracker') return themes[0];
  if (category == 'learning') return themes[1];
  if (category == 'circle' || category == 'community') return themes[2];
  if (category == 'wellbeing') return themes[3];
  if (category == 'connect') return themes[0];

  return themes[index % themes.length];
}

// ── 3D Glassmorphic Pastel Quest Card ───────────────────────────────────────

class _QuestCard extends StatefulWidget {
  final UserQuest quest;
  final int index;
  final VoidCallback onAccept;
  final VoidCallback onGo;

  const _QuestCard({
    required this.quest,
    required this.index,
    required this.onAccept,
    required this.onGo,
  });

  @override
  State<_QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<_QuestCard> {
  bool _isPressed = false;

  void _handleTap() async {
    setState(() => _isPressed = true);
    await Future.delayed(const Duration(milliseconds: 80));
    if (mounted) {
      setState(() => _isPressed = false);
      if (widget.quest.status != 'completed' && widget.quest.status != 'accepted') {
        widget.onAccept();
      }
      widget.onGo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.quest.questTemplate;
    final isCompleted = widget.quest.status == 'completed';
    final theme = _getPastelTheme(template.category, widget.index, isCompleted);

    final totalCount = widget.quest.progressJson?['totalCount'] ?? template.completionCondition?['count'] ?? 1;
    final currentCount = widget.quest.progressJson?['currentCount'] ?? 0;
    final showProgress = totalCount > 1;
    final int coinsEarned;
    final String qTitle = template.title;
    if (qTitle.contains('Track Your Period') || qTitle == 'PeerLine Connection') {
      coinsEarned = 10;
    } else if (qTitle == 'Log Period Start' || qTitle == 'Confirm Period End' || qTitle == 'Connect & Share' || qTitle.contains('Connect') || qTitle == 'Explore Episode') {
      coinsEarned = 5;
    } else if (qTitle == 'Log Symptoms & Mood' || qTitle == 'Gratitude Note' || qTitle.contains('Gratitude') || qTitle == 'Support a Friend') {
      coinsEarned = 3;
    } else if (qTitle == 'Complete Node') {
      coinsEarned = 2;
    } else {
      coinsEarned = math.max(5, (template.pointsBase / 6).round());
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.bgStart, theme.bgEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: theme.accentColor.withValues(alpha: 0.2),
                blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.antiAlias,
          children: [
            // 3D Background Decorative Elements
            Positioned(
              top: -18,
              right: -18,
              child: Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
            Positioned(
              bottom: -22,
              left: -22,
              child: Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Text(
                theme.bgSymbol,
                style: TextStyle(
                  fontSize: 18,
                  color: theme.accentColor.withValues(alpha: 0.35),
                ),
              ),
            ),

            // Glassmorphic Specular Highlight Overlay
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.45),
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Card Main Content Column
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Enlarged Category Glass Icon + Completed Checkmark
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.accentColor.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          theme.icon,
                          color: theme.accentColor,
                          size: 22,
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Color(0xFF166534),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Middle Column: Title & Description (Expanded to push rewards to bottom)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.title,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: isCompleted ? const Color(0xFF166534) : AppColors.textDark,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          template.description,
                          style: GoogleFonts.nunito(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isCompleted ? const Color(0xFF15803D) : AppColors.textMedium,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (showProgress) ...[
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (currentCount / totalCount).clamp(0.0, 1.0),
                              backgroundColor: theme.accentColor.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(theme.accentColor),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '$currentCount/$totalCount done',
                            style: GoogleFonts.nunito(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: theme.accentColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Bottom Aligned XP & Coins Glass Pill Display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: theme.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.accentColor.withValues(alpha: 0.22),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.accentColor.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          '⭐ ${template.pointsBase} XP',
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: theme.accentColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: 9,
                            color: theme.accentColor.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '🪙 $coinsEarned',
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFB45309),
                          ),
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
    ),
    ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.96, 0.96));
  }
}

// ── Badges Tab ─────────────────────────────────────────────────────────────

class _BadgesTab extends StatelessWidget {
  final List<Badge> badges;
  const _BadgesTab({required this.badges});

  static const List<Map<String, dynamic>> _journeyBadges = [
    {
      'id': 'jb_body_timeline',
      'title': 'The Body Timeline Badge',
      'journeyName': 'My Changing Body',
      'emoji': '🗺️',
      'color': Color(0xFF7C3AED),
      'bgColor': Color(0xFFEDE9FE),
      'isEarned': true,
      'piecesEarned': 5,
      'totalPieces': 5,
      'assets': [
        {'name': 'Mystery Letter Scroll', 'emoji': '📜', 'collected': true},
        {'name': 'Doorframe Ruler', 'emoji': '📐', 'collected': true},
        {'name': 'Growth Compass', 'emoji': '🧭', 'collected': true},
        {'name': 'Confidence Star', 'emoji': '⭐', 'collected': true},
        {'name': 'Timeline Crest', 'emoji': '🏆', 'collected': true},
      ],
    },
    {
      'id': 'jb_period_diaries',
      'title': 'Period Diaries Badge',
      'journeyName': 'Period Diaries',
      'emoji': '🩸',
      'color': Color(0xFFDB2777),
      'bgColor': Color(0xFFFCE7F3),
      'isEarned': false,
      'piecesEarned': 0,
      'totalPieces': 5,
      'assets': [
        {'name': 'Cycle Guide', 'emoji': '🩸', 'collected': false},
        {'name': 'Self-Care Kit', 'emoji': '🌸', 'collected': false},
        {'name': 'Myth Buster', 'emoji': '💡', 'collected': false},
        {'name': 'Discovery Key', 'emoji': '🔑', 'collected': false},
        {'name': 'Diaries Crest', 'emoji': '👑', 'collected': false},
      ],
    },
    {
      'id': 'jb_hygiene_hero',
      'title': 'Hygiene Hero Badge',
      'journeyName': 'Hygiene Hero',
      'emoji': '🧼',
      'color': Color(0xFF059669),
      'bgColor': Color(0xFFD1FAE5),
      'isEarned': false,
      'piecesEarned': 0,
      'totalPieces': 5,
      'assets': [
        {'name': 'Freshness Shield', 'emoji': '🧼', 'collected': false},
        {'name': 'Glow Spray', 'emoji': '✨', 'collected': false},
        {'name': 'Cleanliness Wand', 'emoji': '🪄', 'collected': false},
        {'name': 'Hero Star', 'emoji': '⭐', 'collected': false},
        {'name': 'Hygiene Crest', 'emoji': '🛡️', 'collected': false},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── LEARNING JOURNEY EPISODE BADGES SECTION ───────────────────────
          Row(
            children: [
              const Text('🛡️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Journey Episode Master Badges',
                style: GoogleFonts.nunito(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Each activity discovery chest contributes a badge asset to assemble these master badges!',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 14),

          // Journey Badges Cards
          ..._journeyBadges.map((jb) {
            return GestureDetector(
              onTap: () => _showJourneyBadgeSheet(context, jb),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (jb['color'] as Color).withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: jb['bgColor'] as Color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: jb['color'] as Color,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          jb['emoji'] as String,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jb['title'] as String,
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            jb['journeyName'] as String,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: jb['color'] as Color,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (jb['isEarned'] as bool)
                                      ? const Color(0xFFFEF3C7)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  (jb['isEarned'] as bool)
                                      ? '🏆 Master Badge Assembled'
                                      : '🧩 ${jb['piecesEarned']}/${jb['totalPieces']} Assets Collected',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: (jb['isEarned'] as bool)
                                        ? const Color(0xFF92400E)
                                        : AppColors.textMedium,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textLight),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // ── STANDARD QUEST BADGES SECTION ─────────────────────────────────
          Row(
            children: [
              const Text('⭐', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Quest Badges',
                style: GoogleFonts.nunito(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (badges.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Complete daily quests to earn more badges!',
                  style: GoogleFonts.nunito(color: AppColors.textLight, fontSize: 14),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.82,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                return GestureDetector(
                  onTap: () => _showBadgeDetails(context, badge),
                  child: _BadgePin(badge: badge),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showJourneyBadgeSheet(BuildContext context, Map<String, dynamic> jb) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final assets = List<Map<String, dynamic>>.from(jb['assets'] as List);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Badge Large Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: jb['bgColor'] as Color,
                  shape: BoxShape.circle,
                  border: Border.all(color: jb['color'] as Color, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: (jb['color'] as Color).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(jb['emoji'] as String, style: const TextStyle(fontSize: 40)),
                ),
              ),

              const SizedBox(height: 14),

              Text(
                jb['title'] as String,
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Journey: ${jb['journeyName']}',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: jb['color'] as Color,
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              Text(
                'Collected Badge Assets (Discovery Chests)',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 12),

              // Asset Collection List
              ...assets.map((ast) {
                final collected = ast['collected'] as bool;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: collected ? const Color(0xFFFEF3C7) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: collected ? const Color(0xFFFBBF24) : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        collected ? (ast['emoji'] as String) : '🧩',
                        style: TextStyle(
                          fontSize: 20,
                          color: collected ? null : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ast['name'] as String,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: collected ? AppColors.textDark : AppColors.textLight,
                          ),
                        ),
                      ),
                      Icon(
                        collected ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                        color: collected ? const Color(0xFFD97706) : Colors.grey.shade400,
                        size: 18,
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 20),

              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.purple,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Close',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBadgeDetails(BuildContext context, Badge badge) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BadgeDetailSheet(badge: badge),
    );
  }
}

class _BadgeDetailSheet extends StatelessWidget {
  final Badge badge;
  const _BadgeDetailSheet({required this.badge});

  @override
  Widget build(BuildContext context) {
    final earned = badge.isEarned;
    final rewardQuest = badge.rewardForQuests.isNotEmpty ? badge.rewardForQuests.first : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          _BadgeLargeIcon(badge: badge),
          const SizedBox(height: 24),
          Text(
            badge.name,
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          if (badge.rarity != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _rarityColor(badge.rarity).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge.rarity!.toUpperCase(),
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _rarityColor(badge.rarity),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            badge.description ?? 'A special badge for dedicated users.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: AppColors.textMedium,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          if (earned) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Earned on ${badge.awardedAt != null ? _formatDate(badge.awardedAt!) : 'your journey'}',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_outline, color: AppColors.purple, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'HOW TO UNLOCK',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.purple,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    rewardQuest != null 
                      ? 'Complete the quest: "${rewardQuest.title}"'
                      : 'This badge is earned by participating in special activities.',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (rewardQuest != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      rewardQuest.description,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        '${badge.progressPercentage.toInt()}% (${badge.currentStep}/${badge.totalSteps} Days)',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: badge.progressPercentage / 100,
                      backgroundColor: AppColors.purple.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Complete tracking your periods and logs to unlock this badge.',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                'Got it!',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _rarityColor(String? rarity) {
    switch (rarity?.toLowerCase()) {
      case 'rare': return Colors.blue;
      case 'epic': return Colors.purple;
      case 'legendary': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _BadgeLargeIcon extends StatelessWidget {
  final Badge badge;
  const _BadgeLargeIcon({required this.badge});

  @override
  Widget build(BuildContext context) {
    final earned = badge.isEarned;
    final url = badge.illustrationUrl;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: earned ? AppColors.purple.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: earned ? AppColors.purple.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: (url != null && url.isNotEmpty)
                ? Image.network(
                    url,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.shield_outlined,
                      color: earned ? AppColors.purple : AppColors.textLight,
                      size: 48,
                    ),
                  )
                : Icon(
                    Icons.shield_outlined,
                    color: earned ? AppColors.purple : AppColors.textLight,
                    size: 48,
                  ),
          ),
          if (!earned)
            Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.8), size: 32),
        ],
      ),
    );
  }
}

class _BadgePin extends StatelessWidget {
  final Badge badge;
  const _BadgePin({required this.badge});

  @override
  Widget build(BuildContext context) {
    final earned = badge.isEarned;
    final url = badge.illustrationUrl;

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: earned
                  ? AppColors.purple.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: earned
                    ? AppColors.purple.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: (url != null && url.isNotEmpty)
                      ? Image.network(
                          url,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.shield_outlined,
                            color: earned
                                ? AppColors.purple
                                : AppColors.textLight,
                            size: 32,
                          ),
                        )
                      : Icon(
                          Icons.shield_outlined,
                          color:
                              earned ? AppColors.purple : AppColors.textLight,
                          size: 32,
                        ),
                ),
                if (!earned)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: badge.progressPercentage > 0
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${badge.progressPercentage.toInt()}%',
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  'IN PROGRESS',
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            )
                          : const Icon(Icons.lock_outline,
                              color: Colors.white, size: 24),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          badge.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: earned ? AppColors.textDark : AppColors.textLight,
          ),
        ),
      ],
    ).animate().scale(delay: Duration(milliseconds: 50 * (badge.hashCode % 10)));
  }
}


// ── Loading / Error Views ──────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.error, size: 64),
              const SizedBox(height: 16),
              Text('Oops! Something went wrong',
                  style: GoogleFonts.nunito(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style:
                      GoogleFonts.nunito(color: AppColors.textMedium)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyTab extends StatelessWidget {
  final List<WeeklyChallenge> challenges;

  const _WeeklyTab({required this.challenges});

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'tracker':
        return Icons.calendar_today_outlined;
      case 'wellbeing':
        return Icons.self_improvement_outlined;
      default:
        return Icons.extension_outlined;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'tracker':
        return AppColors.purple;
      case 'wellbeing':
        return AppColors.bloom;
      default:
        return AppColors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stars_rounded,
                size: 64, color: AppColors.purple.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'No weekly challenges active right now.\nCheck back later!',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  color: AppColors.textLight, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        final color = _categoryColor(challenge.category);
        final pct = (challenge.targetTotal > 0
            ? challenge.progress / challenge.targetTotal
            : 0.0).clamp(0.0, 1.0);

        return Card(
          elevation: challenge.isCompleted ? 0 : 2,
          color: challenge.isCompleted
              ? AppColors.success.withValues(alpha: 0.05)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: challenge.isCompleted
                  ? AppColors.success.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_categoryIcon(challenge.category),
                          color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.title,
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: challenge.isCompleted
                                  ? AppColors.success
                                  : AppColors.textDark,
                            ),
                          ),
                          Text(
                            'Weekly Challenge',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (challenge.isCompleted)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 32)
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.bloom.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '+${challenge.rewardPoints} Coins 🪙',
                          style: GoogleFonts.nunito(
                            color: const Color(0xFFB45309),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  challenge.description,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                        challenge.isCompleted ? AppColors.success : color),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${challenge.progress} / ${challenge.targetTotal} completed',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      '${(pct * 100).toInt()}%',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: challenge.isCompleted ? AppColors.success : color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: const Duration(milliseconds: 50));
      },
    );
  }
}

class _MilestonesTab extends StatelessWidget {
  const _MilestonesTab();

  @override
  Widget build(BuildContext context) {
    final pastCycleFlowers = [
      {
        'name': 'Menstrual Rose',
        'cycle': 'Cycle 28 (May 2026)',
        'status': 'Fully Bloomed',
        'icon': Icons.brightness_7_outlined,
        'color': Colors.redAccent,
        'score': '1,450 XP Earned',
      },
      {
        'name': 'Lavender Balm',
        'cycle': 'Cycle 29 (June 2026)',
        'status': 'Fully Bloomed',
        'icon': Icons.local_florist_outlined,
        'color': Colors.purpleAccent,
        'score': '1,680 XP Earned',
      },
      {
        'name': 'Follicular Daisy',
        'cycle': 'Cycle 30 (July 2026)',
        'status': 'Fully Bloomed',
        'icon': Icons.filter_vintage_outlined,
        'color': Colors.amber,
        'score': '1,920 XP Earned',
      },
    ];

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.9,
      ),
      itemCount: pastCycleFlowers.length,
      itemBuilder: (context, index) {
        final item = pastCycleFlowers[index];
        final color = item['color'] as Color;

        return Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item['icon'] as IconData, color: color, size: 40)
                  .animate()
                  .scale(duration: 500.ms, delay: 100.ms)
                  .shake(hz: 4, curve: Curves.easeInOut),
                const SizedBox(height: 8),
                Text(
                  item['name'] as String,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  item['cycle'] as String,
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item['score'] as String,
                    style: GoogleFonts.nunito(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Vibe Check Interactive Sheet ──────────────────────────────────────────

class _VibeCheckSheet extends StatefulWidget {
  const _VibeCheckSheet();

  @override
  State<_VibeCheckSheet> createState() => _VibeCheckSheetState();
}

class _VibeCheckSheetState extends State<_VibeCheckSheet> {
  double _moodScore = 4.0;
  double _energyScore = 3.0;
  String _primaryEmotion = 'Balanced';
  bool _isSubmitting = false;

  final List<String> _emotions = ['Balanced', 'Energized', 'Calm', 'Tired', 'Focused', 'Grateful'];

  void _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final res = await ApiService.instance.dio.post('/quest/vibe-check', data: {
        'moodScore': _moodScore.toInt(),
        'energyScore': _energyScore.toInt(),
        'primaryEmotion': _primaryEmotion,
      });

      if (mounted) {
        Navigator.pop(context);
        context.read<QuestBloc>().add(const QuestEvent.refresh());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ Vibe Check Completed! +30 XP • +20 Coins 🪙\n"${res.data['data']['affirmation']}"'),
            backgroundColor: const Color(0xFF9D174D),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('💖', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Text(
                "Gigi's Daily Vibe Check",
                style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Take 30 seconds to check in with your mind & energy today.', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMedium)),
          const SizedBox(height: 20),

          Text('Primary Mood & Emotion', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _emotions.map((e) {
              final isSelected = _primaryEmotion == e;
              return ChoiceChip(
                label: Text(e),
                selected: isSelected,
                selectedColor: const Color(0xFFFCE7F3),
                labelStyle: GoogleFonts.nunito(
                  color: isSelected ? const Color(0xFF9D174D) : AppColors.textDark,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                ),
                onSelected: (val) => setState(() => _primaryEmotion = e),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          Text('Energy Level: ${_energyScore.toInt()}/5', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800)),
          Slider(
            value: _energyScore,
            min: 1.0,
            max: 5.0,
            divisions: 4,
            activeColor: const Color(0xFFF472B6),
            onChanged: (val) => setState(() => _energyScore = val),
          ),

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9D174D),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Complete Vibe Check (+30 XP • +20 🪙)', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Quick Spark Trivia Blitz Modal ───────────────────────────────────────

class _QuickSparkModal extends StatefulWidget {
  const _QuickSparkModal();

  @override
  State<_QuickSparkModal> createState() => _QuickSparkModalState();
}

class _QuickSparkModalState extends State<_QuickSparkModal> {
  int _currentQuestion = 0;
  int _score = 0;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Which phase of the cycle usually brings peak creative energy?',
      'options': ['Menstrual', 'Follicular', 'Ovulation', 'Luteal'],
      'answer': 2,
    },
    {
      'question': 'What is the recommended average daily water intake for teens?',
      'options': ['1 Litre', '2-2.5 Litres', '5 Litres', '500 ml'],
      'answer': 1,
    },
    {
      'question': 'Which hormone helps regulate your sleep-wake rhythm?',
      'options': ['Estrogen', 'Melatonin', 'Progesterone', 'Cortisol'],
      'answer': 1,
    },
  ];

  void _answer(int selected) {
    if (selected == _questions[_currentQuestion]['answer']) {
      _score++;
    }

    if (_currentQuestion < _questions.length - 1) {
      setState(() => _currentQuestion++);
    } else {
      _submit();
    }
  }

  void _submit() async {
    try {
      await ApiService.instance.dio.post('/quest/quick-spark', data: {
        'score': _score,
        'totalQuestions': _questions.length,
      });

      if (mounted) {
        Navigator.pop(context);
        context.read<QuestBloc>().add(const QuestEvent.refresh());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚡ Quick Spark Complete! Score: $_score/3 (+50 XP • +35 Coins 🪙)'),
            backgroundColor: const Color(0xFF065F46),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentQuestion];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Text(
                'Quick Spark Trivia Blitz',
                style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF065F46)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Question ${_currentQuestion + 1} of ${_questions.length}', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMedium)),
          const SizedBox(height: 16),

          Text(
            q['question'] as String,
            style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark),
          ),
          const SizedBox(height: 16),

          ...List.generate((q['options'] as List).length, (idx) {
            final opt = q['options'][idx] as String;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _answer(idx),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  side: const BorderSide(color: Color(0xFF34D399)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  opt,
                  style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF065F46)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
