import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/quest/celebration_overlay.dart';
import 'package:infano_care_mobile/features/home/bloc/dashboard_cubit.dart';
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

  void _navigateToQuest(BuildContext context, String? category) {
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
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
          // After celebration, refresh to clear lastCompletedQuest from state
          if (mounted) {
            context.read<QuestBloc>().add(const QuestEvent.refresh());
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
          loaded: (dailyQuests, progress, badges, isRefreshing,
              lastCompletedQuest, lastLevel) {
            if (lastCompletedQuest != null) {
              _showCelebration(
                context,
                lastCompletedQuest.questTemplate.title,
                lastCompletedQuest.questTemplate.pointsBase,
              );
            } else if (lastLevel != null &&
                progress.currentLevel > lastLevel) {
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
            loaded: (dailyQuests, progress, badges, isRefreshing,
                lastCompletedQuest, lastLevel) {
              return Scaffold(
                backgroundColor: Colors.white,
                body: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverAppBar(
                      expandedHeight: 220,
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
                  body: RefreshIndicator(
                    onRefresh: () async => context
                        .read<QuestBloc>()
                        .add(const QuestEvent.refresh()),
                    color: AppColors.purple,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _DailyTab(
                          quests: dailyQuests,
                          onAccept: (id) => context
                              .read<QuestBloc>()
                              .add(QuestEvent.acceptQuest(id)),
                          onGo: (category) =>
                              _navigateToQuest(context, category),
                        ),
                        _BadgesTab(badges: badges),
                        const _ComingSoonTab(
                            label: 'Milestones coming soon!'),
                        const _ComingSoonTab(
                            label: 'Weekly Challenges coming soon!'),
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
            ],
          ),
        ),
      ),
    );
  }
}

// ── Daily Quests Tab ───────────────────────────────────────────────────────

class _DailyTab extends StatelessWidget {
  final List<UserQuest> quests;
  final void Function(String id) onAccept;
  final void Function(String? category) onGo;

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
      padding: const EdgeInsets.all(16),
      itemCount: quests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final quest = quests[index];
        return _QuestCard(
          quest: quest,
          onAccept: () => onAccept(quest.id),
          onGo: () => onGo(quest.questTemplate.category),
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
    if (isAccepted) {
      return ElevatedButton(
        onPressed: onGo,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Go',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            SizedBox(width: 2),
            Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 14),
          ],
        ),
      );
    }
    return OutlinedButton(
      onPressed: () {
        onAccept();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quest started! Complete the activity to earn points.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.purple,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.purple),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
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

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined,
                size: 64, color: AppColors.purple.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Complete quests to earn badges!',
                style: GoogleFonts.nunito(
                    color: AppColors.textLight, fontSize: 16)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return GestureDetector(
          onTap: () => _showBadgeDetails(context, badge),
          child: _BadgePin(badge: badge),
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

// ── Coming Soon Tab ────────────────────────────────────────────────────────

class _ComingSoonTab extends StatelessWidget {
  final String label;
  const _ComingSoonTab({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty_rounded,
              size: 48, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text(label,
              style: GoogleFonts.nunito(
                  color: AppColors.textLight, fontSize: 15)),
        ],
      ),
    );
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
