import 'package:infano_care_mobile/features/tracker/presentation/widgets/insight_card.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/tracker_calendar.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/tracker_insights.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/phase_info_sheet.dart';
import 'package:infano_care_mobile/features/tracker/presentation/screens/first_period_celebration_screen.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/daily_log_sheet.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/cycle_ring_painter.dart';
import 'package:infano_care_mobile/features/tracker/bloc/tracker_bloc.dart';
import 'package:infano_care_mobile/features/tracker/data/repositories/tracker_repository.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TrackerBloc(TrackerRepository(ApiService.instance.dio))..add(const TrackerEvent.load()),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text('Period Tracker', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: AppColors.textDark, fontSize: 20)),
            centerTitle: true,
            bottom: TabBar(
              indicatorColor: AppColors.purple,
              indicatorWeight: 4,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: AppColors.purple,
              unselectedLabelColor: AppColors.textLight,
              labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 14),
              tabs: const [
                Tab(text: 'Cycle', icon: Icon(Icons.donut_small_rounded)),
                Tab(text: 'Calendar', icon: Icon(Icons.calendar_month_rounded)),
                Tab(text: 'Insights', icon: Icon(Icons.analytics_rounded)),
              ],
            ),
          ),
          body: BlocListener<TrackerBloc, TrackerState>(
            listener: (context, state) {
              state.maybeWhen(
                loaded: (profile, prediction, logs, milestone) {
                  if (milestone == 'first_period') {
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
                  initial: () => const Center(child: CircularProgressIndicator()),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (msg) => _buildErrorState(context, msg),
                  loaded: (profile, prediction, logs, milestone) => Stack(
                    children: [
                      TabBarView(
                        children: [
                          _buildDashboardTab(context, profile, prediction, logs),
                          _buildCalendarTab(context, profile, prediction, logs),
                          _buildInsightsTab(context, profile, prediction, logs),
                        ],
                      ),
                      _buildLogButton(context),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardTab(BuildContext context, profile, prediction, logs) {
    final mode = profile.trackerMode;

    if (mode == 'watching_waiting') {
      return _buildWatchingWaitingDashboard(context, profile);
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildGigiGreeting(profile, prediction),
            const SizedBox(height: 32),
            _buildCycleRing(context, profile, prediction),
            if (mode == 'irregular_support') ...[
              const SizedBox(height: 16),
              _buildConfidenceMeter(context, profile.confidenceLevel),
            ],
            const SizedBox(height: 40),
            if (prediction != null && (prediction as dynamic).insights.isNotEmpty)
              InsightCard(
                title: mode == 'irregular_support' ? 'Irregularity Insight 🔮' : 'Gigi\'s AI Insight 🔮',
                message: (prediction as dynamic).insights.first,
                accentColor: mode == 'irregular_support' ? Colors.orange : AppColors.purple,
              ),
            const SizedBox(height: 24),
            _buildPredictionBanner(context, prediction, isIrregular: mode == 'irregular_support'),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarTab(BuildContext context, profile, prediction, logs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text('Your Cycle Journey 📅', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text('View past flows and future predictions.', style: GoogleFonts.nunito(color: AppColors.textMedium)),
          const SizedBox(height: 24),
          TrackerCalendar(logs: logs, prediction: prediction),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(BuildContext context, profile, prediction, logs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text('Menstrual Intelligence 📊', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text('Uncovering patterns in your unique cycle.', style: GoogleFonts.nunito(color: AppColors.textMedium)),
          const SizedBox(height: 32),
          TrackerInsights(profile: profile, logs: logs),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildWatchingWaitingDashboard(BuildContext context, profile) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildGigiGreeting(profile, null),
            const SizedBox(height: 40),
            _buildEducationalRing(context),
            const SizedBox(height: 40),
            InsightCard(
              title: 'Preparing for your first period 🌱',
              message: 'Your body is doing amazing work! Changes like breast tenderness or skin shifts are signs your first cycle is approaching. We\'re here to help you understand every step.',
              icon: Icons.spa,
              accentColor: Colors.teal,
            ),
            const SizedBox(height: 16),
            _buildActionCard(context, '📚 Learning', 'What to expect', Colors.teal),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationalRing(BuildContext context) {
    return Center(
      child: Container(
        width: 300, height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.05), blurRadius: 40)],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(300, 300),
              painter: CycleRingPainter(
                phases: [
                  CyclePhaseData(name: 'Waiting', startPercent: 0.0, endPercent: 1.0, gradient: [Colors.teal.shade200, Colors.teal.shade400]),
                ],
                currentProgress: 0.0,
                fertileOpacity: 0.0,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌱', style: TextStyle(fontSize: 50)),
                const SizedBox(height: 12),
                Text('GETTING READY', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.teal.shade700, letterSpacing: 1.5)),
                Text('Your journey starts soon', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textLight)),
              ],
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 1000.ms);
  }

  Widget _buildGigiGreeting(profile, prediction) {
    final mode = profile.trackerMode;
    final now = DateTime.now();
    final hour = now.hour;
    
    String greeting;
    if (hour < 12) greeting = 'Good morning! ☀️';
    else if (hour < 17) greeting = 'Good afternoon! 🌤️';
    else greeting = 'Good evening! 🌙';

    String subtext;
    if (profile.lastLogDate != null && 
        profile.lastLogDate!.year == now.year && 
        profile.lastLogDate!.month == now.month && 
        profile.lastLogDate!.day == now.day) {
      subtext = 'Your day is logged. You\'re doing great! ✨';
    } else {
      subtext = 'Haven\'t logged yet — takes 60 seconds 💜';
    }

    String charEmoji = '🌸'; // Gigi
    String charName = 'Gigi';
    if (mode == 'watching_waiting') {
      charEmoji = '🌱'; // Lily
      charName = 'Lily';
    } else if (mode == 'irregular_support') {
      charEmoji = '🌪️'; // Maya
      charName = 'Maya';
    }

    return Row(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.purple.withOpacity(0.1)),
          child: Center(child: Text(charEmoji, style: const TextStyle(fontSize: 32))),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.purple)),
              Text(
                'I\'m $charName, and $subtext',
                style: const TextStyle(color: AppColors.textMedium, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildConfidenceMeter(BuildContext context, String confidence) {
    final colors = {
      'high': Colors.green,
      'confident': Colors.greenAccent,
      'building': Colors.orange,
      'irregular': Colors.orangeAccent,
      'none': Colors.grey,
    };
    final color = colors[confidence] ?? Colors.orange;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              'Prediction Confidence: ${confidence.toUpperCase()}',
              style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleRing(BuildContext context, profile, prediction) {
    final mode = profile.trackerMode;
    final isIrregular = mode == 'irregular_support';

    // Phase Gradients - Seasonally inspired
    final phases = [
      CyclePhaseData(name: 'Menstrual', startPercent: 0.0, endPercent: 0.18, gradient: [const Color(0xFFF43F5E), const Color(0xFFFB7185)]),
      CyclePhaseData(name: 'Follicular', startPercent: 0.18, endPercent: 0.45, gradient: [const Color(0xFF10B981), const Color(0xFF34D399)]),
      CyclePhaseData(name: 'Ovulation', startPercent: 0.45, endPercent: 0.55, gradient: [const Color(0xFFFBBF24), const Color(0xFFFDE047)]),
      CyclePhaseData(name: 'Luteal', startPercent: 0.55, endPercent: 1.0, gradient: [const Color(0xFF6366F1), const Color(0xFF818CF8)]),
    ];

    final avgLength = profile.avgCycleLength > 0 ? profile.avgCycleLength : 28;
    final currentProgress = (profile.currentCycleDay ?? 1) / avgLength;

    // Fertility window calculation for the ring
    double fertileStart = 0.0;
    double fertileEnd = 0.0;
    if (prediction != null) {
      final lastStart = profile.lastPeriodStart ?? DateTime.now();
      final fStart = (prediction as dynamic).fertilityStart as DateTime;
      final fEnd = (prediction as dynamic).fertilityEnd as DateTime;
      fertileStart = fStart.difference(lastStart).inDays / avgLength;
      fertileEnd = fEnd.difference(lastStart).inDays / avgLength;
    }

    return Center(
      child: Container(
        width: 300, height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: isIrregular ? Colors.orange.withOpacity(0.05) : AppColors.purple.withOpacity(0.05), blurRadius: 40, spreadRadius: 5),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(300, 300),
              painter: CycleRingPainter(
                phases: phases,
                currentProgress: currentProgress.clamp(0.0, 1.0),
                dotPulseScale: 1.05,
                fertileStart: fertileStart.clamp(0.0, 1.0),
                fertileEnd: fertileEnd.clamp(0.0, 1.0),
                fertileOpacity: profile.currentPhase == 'ovulation' ? 1.0 : (isIrregular ? 0.4 : 0.6),
                isIrregular: isIrregular,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isIrregular ? '🌪️' : '🌸', style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => PhaseInfoSheet(phase: profile.currentPhase ?? 'menstrual'),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isIrregular ? 'IRREGULAR' : (profile.currentPhase?.toUpperCase() ?? 'TRACKING'), 
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textDark, letterSpacing: 1.5)
                      ),
                      Text(
                        'DAY ${profile.currentCycleDay ?? 1} ⓘ', 
                        style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textLight, fontWeight: FontWeight.w600)
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 1000.ms, curve: Curves.easeOutBack);
  }

  Widget _buildPredictionBanner(BuildContext context, prediction, {bool isIrregular = false}) {
    if (prediction == null) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isIrregular ? Colors.orange.withOpacity(0.1) : AppColors.purple.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: (isIrregular ? Colors.orange : AppColors.pink).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(isIrregular ? Icons.help_outline : Icons.calendar_today, color: isIrregular ? Colors.orange : AppColors.pink, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIrregular ? 'Estimated next period' : 'Next period: ${prediction.daysUntilPrediction} days', 
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textDark)
                ),
                const SizedBox(height: 4),
                Text(
                  isIrregular 
                    ? 'Window might shift while we learn your rhythm 🌪️'
                    : 'Predictions get better as you log! 💜',
                  style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMedium, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildLogButton(BuildContext context) {
    return Positioned(
      bottom: 40, right: 24,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (routeContext) => BlocProvider.value(
              value: BlocProvider.of<TrackerBloc>(context),
              child: DailyLogScreen(date: DateTime.now()),
            ),
          ),
        ),
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: AppColors.purple,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
            ],
          ),
          child: const Center(
            child: Icon(Icons.add_rounded, color: Colors.white, size: 32),
          ),
        ),
      ).animate().fadeIn(delay: 1000.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildErrorState(BuildContext context, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📅', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 24),
          Text('Hmm, something went wrong', style: Theme.of(context).textTheme.headlineMedium),
          Text(msg, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => context.read<TrackerBloc>().add(const TrackerEvent.load()), child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.star_outline, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textDark)),
                Text(subtitle, style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMedium)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: color.withOpacity(0.5)),
        ],
      ),
    );
  }
}
