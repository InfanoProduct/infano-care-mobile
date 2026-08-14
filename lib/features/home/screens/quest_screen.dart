import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/quest/celebration_overlay.dart';
import 'package:infano_care_mobile/features/home/bloc/dashboard_cubit.dart';
import 'package:infano_care_mobile/features/tracker/presentation/screens/all_insights_screen.dart';
import 'package:infano_care_mobile/features/tracker/data/models/insight_models.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import '../../tracker/bloc/quest_bloc.dart';
import '../../tracker/data/models/quest_models.dart';

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
    if (title == 'Review Daily Insights') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppColors.purple),
        ),
      );

      try {
        final response = await ApiService.instance.dio.get('/tracker/daily-insights');
        final insightsData = response.data as Map<String, dynamic>;
        final list = (insightsData['insights'] as List? ?? [])
            .map((json) => DailyInsight.fromJson(json as Map<String, dynamic>))
            .toList();

        if (context.mounted) {
          Navigator.of(context).pop(); // dismiss loading
        }

        if (context.mounted) {
          final questBloc = context.read<QuestBloc>();
          List<String> readInsightIds = [];
          questBloc.state.maybeWhen(
            loaded: (dailyQuests, _, __, ___, ____, _____, ______) {
              for (var q in dailyQuests) {
                if (q.questTemplate.title == 'Review Daily Insights' && q.progressJson != null) {
                  final readList = q.progressJson!['readIds'] as List?;
                  if (readList != null) {
                    readInsightIds = readList.map((e) => e.toString()).toList();
                  }
                  break;
                }
              }
            },
            orElse: () {},
          );

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AllInsightsScreen(insights: list, initialReadIds: readInsightIds),
            ),
          ).then((_) {
            questBloc.add(const QuestEvent.refresh());
          });
        }
      } catch (e) {
        debugPrint('[QUEST] Failed to fetch daily insights directly: $e');
        if (context.mounted) {
          Navigator.of(context).pop(); // dismiss loading
        }
        if (context.mounted) {
          context.read<DashboardCubit>().setTab(2);
        }
      }
      return;
    }

    switch (category) {
      case 'tracker':
        context.read<DashboardCubit>().setTab(2);
        break;
      case 'learning':
        context.read<DashboardCubit>().setTab(1);
        break;
      case 'community':
        context.read<DashboardCubit>().setTab(4);
        break;
      default:
        context.read<DashboardCubit>().setTab(0);
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
              return Stack(
                children: [
                  Scaffold(
                backgroundColor: Colors.white,
                body: RefreshIndicator(
                  onRefresh: () async {
                    final bloc = context.read<QuestBloc>();
                    bloc.add(const QuestEvent.refresh());
                    await bloc.stream.firstWhere((state) => state.maybeWhen(
                          loaded: (_, __, ___, ____, isRefreshing, _____, ______) => !isRefreshing,
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
              ),
              if (isRefreshing)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.6),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.purple,
                      ),
                    ),
                  ),
                ),
            ],
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

  IconData _levelIcon(int level) {
    if (level <= 2) return Icons.eco_outlined;
    if (level <= 5) return Icons.local_florist_outlined;
    return Icons.brightness_7_outlined;
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
    const thresholds = [500, 1500, 3500, 7000, 12000, 20000, 32000, 50000, 75000, 100000];
    if (level <= thresholds.length) return thresholds[level - 1];
    return 999999;
  }

  @override
  Widget build(BuildContext context) {
    final level = progress.currentLevel;
    final points = progress.pointsTotal;
    final nextLevel = _nextLevelPoints(level);
    final pct = (nextLevel > 0 ? points / nextLevel : 0.0).clamp(0.0, 1.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.purple, AppColors.purpleLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_levelIcon(level),
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level $level: ${_levelName(level)}',
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '$points Total Points',
                        style: GoogleFonts.nunito(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.bloom),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$points XP',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11)),
                  Text('$nextLevel XP',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11)),
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
    // Determine plant progress based on XP progress towards next level
    const thresholds = [500, 1500, 3500, 7000, 12000, 20000, 32000, 50000, 75000, 100000];
    final nextLevel = level <= thresholds.length ? thresholds[level - 1] : 999999;
    final pct = (nextLevel > 0 ? points / nextLevel : 0.0).clamp(0.0, 1.0);

    String stageName = 'Sprout';
    IconData plantIcon = Icons.eco_outlined;
    Color plantColor = Colors.green;
    String description = 'Keep completing daily quests to water your seedling.';

    if (pct >= 0.75) {
      stageName = 'Full Bloom';
      plantIcon = Icons.brightness_7_rounded;
      plantColor = Colors.amber;
      description = 'Stunning! Your self-care flower has bloomed beautifully!';
    } else if (pct >= 0.5) {
      stageName = 'Budding';
      plantIcon = Icons.local_florist_rounded;
      plantColor = Colors.pinkAccent;
      description = 'A bud is forming! You are nurturing consistency.';
    } else if (pct >= 0.25) {
      stageName = 'Growing';
      plantIcon = Icons.spa_rounded;
      plantColor = Colors.teal;
      description = 'Leaves are branching out. Great job watering your plant!';
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                )
              ]
            ),
            child: Icon(plantIcon, color: plantColor, size: 36)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(duration: 1.seconds, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1))
              .shimmer(delay: 2.seconds, duration: 1.seconds),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bloom Status: $stageName',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
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

  @override
  Widget build(BuildContext context) {
    if (quests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome,
                size: 64, color: AppColors.purple.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'No quests available yet.\nPull down to refresh.',
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
      itemCount: quests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final quest = quests[index];
        return _QuestCard(
          quest: quest,
          onAccept: () => onAccept(quest.id),
          onGo: () => onGo(quest.questTemplate.category, quest.questTemplate.title),
        );
      },
    );
  }
}

// ── Quest Card ─────────────────────────────────────────────────────────────

class _QuestCard extends StatelessWidget {
  final UserQuest quest;
  final VoidCallback onAccept;
  final VoidCallback onGo;

  const _QuestCard({
    required this.quest,
    required this.onAccept,
    required this.onGo,
  });

  IconData _categoryIcon(String? cat) {
    switch (cat) {
      case 'tracker':
        return Icons.calendar_today_outlined;
      case 'learning':
        return Icons.menu_book_outlined;
      case 'community':
        return Icons.forum_outlined;
      case 'wellbeing':
        return Icons.self_improvement_outlined;
      default:
        return Icons.extension_outlined;
    }
  }

  Color _categoryColor(String? cat) {
    switch (cat) {
      case 'tracker':
        return AppColors.purple;
      case 'learning':
        return AppColors.pink;
      case 'community':
        return AppColors.teal;
      case 'wellbeing':
        return AppColors.bloom;
      default:
        return AppColors.bloom;
    }
  }

  @override
  Widget build(BuildContext context) {
    final template = quest.questTemplate;
    final isCompleted = quest.status == 'completed';
    final isAccepted = quest.status == 'accepted';
    final color = _categoryColor(template.category);
    final totalCount = quest.progressJson?['totalCount'] ?? template.completionCondition?['count'] ?? 1;
    final currentCount = quest.progressJson?['currentCount'] ?? 0;
    final showProgress = totalCount > 1;

    return Card(
      elevation: isCompleted ? 0 : 2,
      color: isCompleted ? AppColors.success.withValues(alpha: 0.05) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCompleted
              ? AppColors.success.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_categoryIcon(template.category),
                  color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isCompleted
                          ? AppColors.success
                          : AppColors.textDark,
                    ),
                  ),
                  Text(
                    template.description,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                  if (showProgress) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (currentCount / totalCount).clamp(0.0, 1.0),
                        backgroundColor: color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Progress: $currentCount/$totalCount completed',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.stars_rounded,
                          size: 14, color: AppColors.bloom),
                      const SizedBox(width: 3),
                      Text(
                        '${template.pointsBase} pts',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.bloom,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.timer_outlined,
                          size: 14, color: AppColors.textLight),
                      const SizedBox(width: 3),
                      Text(
                        '${template.estimatedMinutes}m',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildAction(context, isCompleted, isAccepted),
          ],
        ),
      ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 50));
  }

  Widget _buildAction(
      BuildContext context, bool isCompleted, bool isAccepted) {
    if (isCompleted) {
      return const Icon(Icons.check_circle_rounded,
          color: AppColors.success, size: 32);
    }
    return OutlinedButton(
      onPressed: () {
        if (!isAccepted) {
          onAccept();
        }
        onGo();
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.purple),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text(
        'Start',
        style: TextStyle(
            color: AppColors.purple,
            fontWeight: FontWeight.bold,
            fontSize: 13),
      ),
    );
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
                          '+${challenge.rewardPoints} XP',
                          style: GoogleFonts.nunito(
                            color: AppColors.bloom,
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
