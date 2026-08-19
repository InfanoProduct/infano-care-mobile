import 'package:infano_care_mobile/features/tracker/presentation/screens/article_detail_screen.dart';
import 'package:infano_care_mobile/features/tracker/presentation/screens/all_articles_screen.dart';
import 'package:infano_care_mobile/features/tracker/presentation/screens/all_insights_screen.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/phase_info_sheet.dart';
import 'package:infano_care_mobile/features/tracker/presentation/screens/first_period_celebration_screen.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/daily_log_sheet.dart';
import 'package:infano_care_mobile/features/tracker/data/models/insight_models.dart';
import 'package:infano_care_mobile/features/tracker/presentation/screens/story_screen.dart';
import 'package:infano_care_mobile/features/tracker/bloc/tracker_bloc.dart';
import 'package:infano_care_mobile/features/tracker/bloc/quest_bloc.dart';
import 'package:infano_care_mobile/features/tracker/data/repositories/tracker_repository.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/cycle_ring.dart';
import 'package:infano_care_mobile/features/tracker/application/character_greeting_service.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:infano_care_mobile/features/home/bloc/dashboard_cubit.dart';

class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TrackerBloc(
        TrackerRepository(
          ApiService.instance.dio,
        ),
        context.read<LocalStorageService>(),
      )..add(const TrackerEvent.load()),

      child: Scaffold(
        backgroundColor: const Color(0xFFF5F4F7),
        body: BlocListener<TrackerBloc, TrackerState>(
          listener: (context, state) {
            state.maybeWhen(
              loaded: (profile, prediction, logs, history, dailyInsights, articles, milestone, pointsEarned, isRefreshing) {
                debugPrint('[TrackScreen] Listener receivedLoaded. Milestone: $milestone');
                if (milestone == 'first_period') {
                  debugPrint('[TrackScreen] Milestone detected. Navigating with Navigator.push...');
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FirstPeriodCelebrationScreen()),
                  );
                }
              },
              orElse: () {},
            );
          },
          child: BlocBuilder<TrackerBloc, TrackerState>(
            builder: (context, state) {
              return state.when(
                initial: () => const Center(child: CircularProgressIndicator(color: AppColors.purpleLight)),
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.purpleLight)),
                error: (msg) => _buildErrorState(context, msg),
                notStarted: () => _buildNotStartedState(context),
                loaded: (profile, prediction, logs, history, dailyInsights, articles, milestone, pointsEarned, isRefreshing) {
                  if (profile.trackerMode == 'watching_waiting' && profile.lastPeriodStart == null) {
                    return _buildNotStartedState(context);
                  }
                  final isUpdating = milestone == 'updating_tracker';
                  return _buildRedesignedDashboard(
                    context, 
                    profile, 
                    prediction, 
                    logs, 
                    history, 
                    dailyInsights, 
                    articles,
                    isRefreshing,
                    isUpdating,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRedesignedDashboard(
    BuildContext context, 
    CycleProfileModel profile, 
    PredictionResultModel? prediction, 
    List<CycleLogModel> logs, 
    List<CycleRecordModel> history,
    List<DailyInsight> dailyInsights,
    List<Map<String, String>> articles,
    bool isRefreshing,
    bool isUpdating,
  ) {
    final mode = profile.trackerMode;
    final char = CharacterGreetingService.getCharacter(mode);
    // Use the actual logs list to determine if today is logged, 
    // which is more reliable than server-side 'today' due to timezone differences.
    final hasLoggedToday = logs.any((l) => DateUtils.isSameDay(l.date, DateTime.now()));

    return Stack(
      children: [
        Container(
          color: const Color(0xFFF5F4F7),
          child: SafeArea(
            child: RefreshIndicator(
              color: AppColors.purple,
              onRefresh: () async {
                context.read<TrackerBloc>().add(const TrackerEvent.load(isRefresh: true));
                await Future.delayed(const Duration(milliseconds: 1500));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildRichHeader(context, profile, prediction, char),
                    const SizedBox(height: 32),
                    _buildCycleRing(context, profile, prediction, history, isRefreshing),
                    const SizedBox(height: 12),
                    _buildActionButtons(context, profile, logs, history),
                    const SizedBox(height: 32),
                    _buildPrimaryActions(context, profile, logs, hasLoggedToday),
                    if (mode != 'watching_waiting') ...[
                      const SizedBox(height: 20),
                      _buildQuestEntryCard(context, prediction?.currentLogStreak ?? 0),
                    ],
                    const SizedBox(height: 24),
                    _buildDailyInsightsSection(context, dailyInsights),
                    const SizedBox(height: 24),
                    _buildGoodToKnowSection(context, profile.currentPhase ?? 'menstrual', articles),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isUpdating)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.7),
              child: Center(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.purple,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Updating your tracker data...',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRichHeader(BuildContext context, CycleProfileModel profile, PredictionResultModel? prediction, TrackerCharacter char) {
    final storage = context.watch<LocalStorageService>();
    final userName = storage.displayName ?? 'Friend';
    final greeting = CharacterGreetingService.getGreeting(
      mode: profile.trackerMode,
      phase: profile.currentPhase ?? 'menstrual',
      streak: prediction?.currentLogStreak ?? 0,
      hasLoggedToday: prediction?.hasLoggedToday ?? false,
      hour: DateTime.now().hour,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purple.withValues(alpha: 0.08),
            AppColors.pink.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: AppColors.textMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      userName,
                      style: GoogleFonts.nunito(
                        fontSize: 28,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/account'),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    image: storage.avatarUrl != null
                        ? DecorationImage(
                            image: NetworkImage(storage.avatarUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: storage.avatarUrl == null
                      ? const Center(child: Text('👤', style: TextStyle(fontSize: 28)))
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '"$greeting"',
              style: GoogleFonts.nunito(
                color: AppColors.textDark.withValues(alpha: 0.8),
                fontSize: 15,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCycleRing(BuildContext context, CycleProfileModel profile, PredictionResultModel? prediction, List<CycleRecordModel> history, bool isRefreshing) {
    return Center(
      child: Container(
        width: 320, height: 320, // Increased size for the new technical specs
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD946EF).withValues(alpha: 0.1),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
        ),
        child: CycleRing(
          profile: profile,
          prediction: prediction,
          history: history,
          isRefreshing: isRefreshing,
          onCenterTap: () {
            final currentPhase = prediction?.currentPhase;
            final isDelayed = currentPhase == 'delayed' || 
                              currentPhase == 'late' || 
              (prediction != null && prediction.cycleDay > profile.avgCycleLength);
            if (isDelayed) {
              final duration = profile.avgPeriodDuration;
              final start = DateTime.now();
              final end = start.add(Duration(days: duration - 1));
              context.read<TrackerBloc>().add(TrackerEvent.updatePeriodRange(start, end));
            } else {
              _openDailyLog(context, DateTime.now());
            }
          },
          onSegmentTap: (phaseId) => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => PhaseInfoSheet(phase: phaseId),
          ),
        ),
      ),
    ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack);
  }

  Widget _buildPrimaryActions(BuildContext context, profile, logs, bool alreadyLogged) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [AppColors.purple, Color(0xFF9333EA)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => _openDailyLog(context, DateTime.now()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  alreadyLogged ? 'Edit Today\'s Log' : 'Log Today\'s Day',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900, 
                    color: Colors.white, 
                    fontSize: 17,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('✦', style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestEntryCard(BuildContext context, int streak) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE5DEFF), // Richer pastel lavender
            Color(0xFFFCDDEC), // Richer pastel pink
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFC084FC).withValues(alpha: 0.35), // Visible boundary
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.12), // Subtle deep shadow
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFF7C3AED), // Match brand purple
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bloom Journey',
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF1E1B4B), // High contrast dark text
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Complete quests to level up!',
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF4B5563), // High contrast medium text
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.read<DashboardCubit>().setTab(3),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED), // Primary dark purple CTA color
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'View Quests',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2);
  }

  void _openDailyLog(BuildContext context, DateTime date) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => BlocProvider.value(
          value: BlocProvider.of<TrackerBloc>(context),
          child: DailyLogScreen(date: date),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String msg) {
    return Container(
      color: const Color(0xFFF5F4F7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📅', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 24),
            Text('Hmm, something went wrong', style: GoogleFonts.nunito(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(msg, style: GoogleFonts.nunito(color: AppColors.textMedium, fontSize: 14), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<TrackerBloc>().add(const TrackerEvent.load()),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotStartedState(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F4F7),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/period_onboarding.png',
                height: 180,
                fit: BoxFit.contain,
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scaleXY(begin: 0.95, end: 1.05, duration: 1500.ms, curve: Curves.easeInOut),
              const SizedBox(height: 24),
              Text(
                'Your Bloom Tracker awaits! ✨',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Track your cycle, predict your next period, and understand your unique body patterns with Gigi\'s help.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: AppColors.textMedium,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.purple,
                  ),
                  child: ElevatedButton(
                    onPressed: () => context.push('/onboarding/tracker/date'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Set Up My Tracker 🌸',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ).animate().slideY(begin: 0.2, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildActionButtons(BuildContext context, profile, logs, history) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (profile.trackerMode != 'watching_waiting') ...[
          _buildSmallActionBtn(
            context, 
            'Cycle Insights', 
            Icons.auto_graph_outlined, 
            () => context.push('/tracker/insights', extra: {'profile': profile, 'logs': logs, 'history': history})
          ),
          const SizedBox(width: 12),
        ],
        _buildSmallActionBtn(
          context, 
          'View Calendar', 
          Icons.calendar_month_outlined, 
          () => context.push('/tracker/calendar').then((_) {
            if (context.mounted) {
              context.read<TrackerBloc>().add(const TrackerEvent.load(isRefresh: true));
            }
          })
        ),
      ],
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildSmallActionBtn(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.textMedium, size: 16),
      label: Text(
        label, 
        style: GoogleFonts.nunito(
          color: AppColors.textMedium, 
          fontWeight: FontWeight.w700,
          fontSize: 13,
        )
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
    );
  }

  Widget _buildGoodToKnowSection(BuildContext context, String phase, List<Map<String, String>> articles) {
    if (articles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.purple,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Good to Know',
                  style: GoogleFonts.nunito(
                    fontSize: 20, 
                    fontWeight: FontWeight.w900, 
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AllArticlesScreen(articles: articles),
                ),
              ),
              child: Text('See All', style: GoogleFonts.nunito(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 185,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: articles.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final art = articles[index];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: art)),
                ),
                child: _buildArticleCard(art, index),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _buildArticleCard(Map<String, String> art, int index) {
    final backgrounds = [
      const Color(0xFFEEF2FF), // Soft Indigo
      const Color(0xFFFDF2F8), // Soft Pink
      const Color(0xFFECFDF5), // Soft Mint
      const Color(0xFFFFFBEB), // Soft Amber
      const Color(0xFFF5F3FF), // Soft Violet
    ];
    
    final borders = [
      const Color(0xFFC7D2FE),
      const Color(0xFFFBCFE8),
      const Color(0xFFA7F3D0),
      const Color(0xFFFDE68A),
      const Color(0xFFDDD6FE),
    ];

    final colorIndex = index % backgrounds.length;
    final bgColor = backgrounds[colorIndex];
    final borderColor = borders[colorIndex];

    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              height: 90,
              width: double.infinity,
              color: Colors.white.withValues(alpha: 0.4),
              child: Center(child: Text(art['emoji'] ?? '📖', style: const TextStyle(fontSize: 32))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  art['title'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 12, color: AppColors.textMedium),
                    const SizedBox(width: 4),
                    Text(
                      art['time'] ?? '3 min read',
                      style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textMedium, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDailyInsightsSection(BuildContext context, List<DailyInsight> insights) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.pink,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'My Daily Insights',
                  style: GoogleFonts.nunito(
                    fontSize: 20, 
                    fontWeight: FontWeight.w900, 
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                List<String> readInsightIds = [];
                try {
                  final questBloc = context.read<QuestBloc>();
                  questBloc.state.maybeWhen(
                    loaded: (dailyQuests, _, _, _, _, _, _) {
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
                } catch (_) {}

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AllInsightsScreen(
                      insights: insights,
                      initialReadIds: readInsightIds,
                    ),
                  ),
                ).then((_) {
                  if (context.mounted) {
                    try {
                      context.read<QuestBloc>().add(const QuestEvent.refresh());
                    } catch (_) {}
                  }
                });
              },
              child: Text('See All', style: GoogleFonts.nunito(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: insights.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final insight = insights[index];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => StoryScreen(insight: insight)),
                ).then((_) {
                  if (context.mounted) {
                    try {
                      context.read<QuestBloc>().add(const QuestEvent.refresh());
                    } catch (_) {}
                  }
                }),
                child: _buildInsightCard(insight, index),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 700.ms);
  }

  Widget _buildInsightCard(DailyInsight insight, int index) {
    final backgrounds = [
      const Color(0xFFEEF2FF), // Soft Indigo
      const Color(0xFFFDF2F8), // Soft Pink
      const Color(0xFFECFDF5), // Soft Mint
      const Color(0xFFFFFBEB), // Soft Amber
      const Color(0xFFF5F3FF), // Soft Violet
    ];
    
    final borders = [
      const Color(0xFFC7D2FE),
      const Color(0xFFFBCFE8),
      const Color(0xFFA7F3D0),
      const Color(0xFFFDE68A),
      const Color(0xFFDDD6FE),
    ];

    final colorIndex = index % backgrounds.length;
    final bgColor = backgrounds[colorIndex];
    final borderColor = borders[colorIndex];

    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Text(insight.previewEmoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              insight.previewTitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800, 
                fontSize: 13, 
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

}


