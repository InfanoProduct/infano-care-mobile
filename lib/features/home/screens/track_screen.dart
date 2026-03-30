import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/bloc/tracker_bloc.dart';
import 'package:infano_care_mobile/features/tracker/data/repositories/tracker_repository.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/cycle_ring_painter.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/daily_log_sheet.dart';

class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TrackerBloc(TrackerRepository(ApiService.instance.dio))..add(const TrackerEvent.load()),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<TrackerBloc, TrackerState>(
          builder: (context, state) {
            return state.when(
              initial: () => const Center(child: CircularProgressIndicator()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (msg) => _buildErrorState(context, msg),
              loaded: (profile, prediction, logs) => _buildDashboard(context, profile, prediction, logs),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, profile, prediction, logs) {
    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildGigiGreeting(profile, prediction),
                const SizedBox(height: 32),
                _buildCycleRing(context, profile, prediction),
                const SizedBox(height: 40),
                _buildPredictionBanner(context, prediction),
                const SizedBox(height: 40),
                _buildQuickActions(context),
              ],
            ),
          ),
          _buildLogButton(context),
        ],
      ),
    );
  }

  Widget _buildGigiGreeting(profile, prediction) {
    return Row(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.purple.withOpacity(0.1)),
          child: const Center(child: Text('🌸', style: TextStyle(fontSize: 32))),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good morning! 🌸', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.purple)),
              Text(
                profile.currentLogStreak > 0 
                  ? 'Your ${profile.currentLogStreak}-day streak is amazing! 💜' 
                  : 'How are you feeling today?',
                style: const TextStyle(color: AppColors.textMedium),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildCycleRing(BuildContext context, profile, prediction) {
    // Generate dummy phases for the MVP visualization
    // In a full implementation, these would come from a CyclePhaseCalculator
    final phases = [
      CyclePhaseData(name: 'Menstrual', startPercent: 0.0, endPercent: 0.18, gradient: [Colors.red, Colors.orange]),
      CyclePhaseData(name: 'Follicular', startPercent: 0.18, endPercent: 0.45, gradient: [AppColors.purple, AppColors.pink]),
      CyclePhaseData(name: 'Ovulation', startPercent: 0.45, endPercent: 0.55, gradient: [Colors.amber, Colors.green]),
      CyclePhaseData(name: 'Luteal', startPercent: 0.55, endPercent: 1.0, gradient: [Colors.blue, Colors.purple]),
    ];

    final currentProgress = (profile.currentCycleDay ?? 1) / (profile.avgCycleLength > 0 ? profile.avgCycleLength : 28);

    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 280, height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(280, 280),
                  painter: CycleRingPainter(
                    phases: phases,
                    currentProgress: currentProgress.clamp(0.0, 1.0),
                    dotPulseScale: 1.1, // Would be animated in a StatefulWidget
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🌸', style: const TextStyle(fontSize: 40)),
                    const SizedBox(height: 8),
                    Text(profile.currentPhase?.toUpperCase() ?? 'TRACKING', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark, letterSpacing: 1.2)),
                    Text('DAY ${profile.currentCycleDay ?? 1}', style: const TextStyle(fontSize: 14, color: AppColors.textLight)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack);
  }

  Widget _buildPredictionBanner(BuildContext context, prediction) {
    if (prediction == null) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.softCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.purple.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.purple, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next period likely in ${prediction.daysUntilPrediction} days', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                Text(
                  prediction.confidenceLevel == 'high' 
                    ? 'Gigi says: Your body is very consistent! 💜' 
                    : 'I\'m learning your unique rhythm 🌸',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Insights', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildActionCard(context, '🌸 Flow Status', 'Normal', AppColors.pink),
            const SizedBox(width: 16),
            _buildActionCard(context, '⚡ Energy', 'Building', Colors.amber),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
            const SizedBox(height: 4),
            Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogButton(BuildContext context) {
    return Positioned(
      bottom: 40, left: 24, right: 24,
      child: ElevatedButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) => BlocProvider.value(
            value: BlocProvider.of<TrackerBloc>(context),
            child: const DailyLogSheet(date: null ?? DateTime.now()), // Passing current date
          ),
        ),
        child: const Text('Log Your Day 🌸'),
      ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut),
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
}
