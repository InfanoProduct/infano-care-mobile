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
import 'package:infano_care_mobile/core/services/privacy_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/cycle_ring.dart';
import 'package:infano_care_mobile/features/tracker/application/character_greeting_service.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';

class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TrackerBloc(
        TrackerRepository(
          ApiService.instance.dio,
          PrivacyService(const FlutterSecureStorage()),
        ),
      )..add(const TrackerEvent.load()),

      child: Scaffold(
        backgroundColor: const Color(0xFF130F26), // Premium Dark Background
        body: BlocListener<TrackerBloc, TrackerState>(
          listener: (context, state) {
            state.maybeWhen(
              loaded: (profile, prediction, logs, history, milestone) {
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
                loaded: (profile, prediction, logs, history, milestone) => 
                    _buildRedesignedDashboard(context, profile, prediction, logs, history),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRedesignedDashboard(BuildContext context, CycleProfileModel profile, PredictionResultModel? prediction, List<CycleLogModel> logs, List<CycleRecordModel> history) {
    final mode = profile.trackerMode;
    final char = CharacterGreetingService.getCharacter(mode);
    final hasLoggedToday = prediction?.hasLoggedToday ?? false;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A132C), Color(0xFF130F26)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildTopBar(context, profile.trackerMode),
              const SizedBox(height: 12),
              _buildPhasePill(profile),
              const SizedBox(height: 24),
              _buildGigiHeader(char),
              const SizedBox(height: 16),
              _buildGreetingBubble(profile, prediction, char),
              const SizedBox(height: 48),
              _buildCycleRing(context, profile, prediction, history),
              const SizedBox(height: 12),
              _buildRingContextCTA(context),
              const SizedBox(height: 48),
              _buildPrimaryActions(context, profile, logs, hasLoggedToday),
              if (mode != 'watching_waiting') ...[
                const SizedBox(height: 24),
                _buildStreakInfo(prediction?.currentLogStreak ?? 0),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String? mode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (mode != 'watching_waiting') ...[
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, color: Colors.white54, size: 24),
            onPressed: () => context.push('/tracker/calendar'),
            tooltip: 'View Full Calendar',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white54, size: 28),
            onPressed: () async {
              final updated = await context.push('/tracker/settings');
              if (updated == true && context.mounted) {
                context.read<TrackerBloc>().add(const TrackerEvent.load());
              }
            },
            tooltip: 'Tracker Settings',
          ),
        ]
        else
          const SizedBox(height: 48), // Maintain spacing without showing the gear
      ],
    );
  }

  Widget _buildPhasePill(profile) {
    String dayText = profile.currentCycleDay != null ? 'Day ${profile.currentCycleDay}' : '';
    String phaseText = profile.currentPhase != null ? ' · ${profile.currentPhase[0].toUpperCase()}${profile.currentPhase.substring(1)}' : '';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFD946EF).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD946EF).withOpacity(0.3)),
      ),
      child: Text(
        '$dayText$phaseText',
        style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: const Color(0xFFF472B6), fontSize: 13),
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildGigiHeader(TrackerCharacter char) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFD946EF).withOpacity(0.2),
          ),
          child: Center(child: Text(char.emoji, style: const TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),
        Text(
          char.name,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: const Color(0xFFD946EF), fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildGreetingBubble(profile, prediction, TrackerCharacter char) {
    final greeting = CharacterGreetingService.getGreeting(
      mode: profile.trackerMode,
      phase: profile.currentPhase ?? 'menstrual',
      streak: prediction?.currentLogStreak ?? 0,
      hasLoggedToday: prediction?.hasLoggedToday ?? false,
      hour: DateTime.now().hour,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B).withOpacity(0.6),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Text(
        '"$greeting"',
        style: GoogleFonts.nunito(
          color: Colors.white.withOpacity(0.9),
          fontSize: 15,
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildCycleRing(BuildContext context, CycleProfileModel profile, PredictionResultModel? prediction, List<CycleRecordModel> history) {
    return Center(
      child: Container(
        width: 320, height: 320, // Increased size for the new technical specs
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD946EF).withOpacity(0.05),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: CycleRing(
          profile: profile,
          prediction: prediction,
          history: history,
          onCenterTap: () => _openDailyLog(context, DateTime.now()),
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
    final mode = profile.trackerMode;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFFE84393), Color(0xFFA855F7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA855F7).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _openDailyLog(context, DateTime.now()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                alreadyLogged ? 'Edit Today\'s Log ✦' : 'Log Today\'s Day ✦',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
        if (mode != 'watching_waiting') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => context.push('/tracker/insights', extra: {'profile': profile, 'logs': logs}),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF312E81), width: 1),
                backgroundColor: const Color(0xFF1E1B4B).withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'View Cycle Insights →',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: Colors.white70, fontSize: 15),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStreakInfo(int streak) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🔥', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          '$streak-day streak',
          style: GoogleFonts.nunito(color: Colors.white54, fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
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
      color: const Color(0xFF130F26),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📅', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 24),
            Text('Hmm, something went wrong', style: GoogleFonts.nunito(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(msg, style: GoogleFonts.nunito(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
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
      color: const Color(0xFF130F26),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌸', style: TextStyle(fontSize: 80)).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text(
                'Your Bloom Tracker awaits! ✨',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Track your cycle, predict your next period, and understand your unique body patterns with Gigi\'s help.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(colors: [Color(0xFFE84393), Color(0xFFA855F7)]),
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
                Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
                Text(subtitle, style: GoogleFonts.nunito(fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: color.withOpacity(0.5)),
        ],
      ),
    );
  }

  Widget _buildRingContextCTA(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () => context.push('/tracker/ring'),
        icon: const Icon(Icons.center_focus_strong_outlined, color: Colors.white70, size: 20),
        label: Text(
          'View Cycle Signature', 
          style: GoogleFonts.nunito(
            color: Colors.white70, 
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.5
          )
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          backgroundColor: Colors.white.withOpacity(0.03),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0);
  }
}
