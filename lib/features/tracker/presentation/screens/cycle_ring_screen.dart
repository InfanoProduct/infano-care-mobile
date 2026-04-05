import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/bloc/tracker_bloc.dart';
import 'package:infano_care_mobile/features/tracker/data/repositories/tracker_repository.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/privacy_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/cycle_ring.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/phase_info_sheet.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/daily_log_sheet.dart';

class CycleRingScreen extends StatelessWidget {
  const CycleRingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TrackerBloc(
        TrackerRepository(
          ApiService.instance.dio,
          PrivacyService(const FlutterSecureStorage()),
        ),
      )..add(const TrackerEvent.load()),
      child: const CycleRingView(),
    );
  }
}

class CycleRingView extends StatelessWidget {
  const CycleRingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF130F26), // Match TrackScreen background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Cycle Signature',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<TrackerBloc, TrackerState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator(color: AppColors.purple)),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.purple)),
            error: (msg) => _buildErrorState(context, msg),
            notStarted: () {
              WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
              return const SizedBox.shrink();
            },
            loaded: (profile, prediction, logs, history, milestone) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.95, 0.95)),
                    ),
                    const SizedBox(height: 60),
                    _buildImmersionCard(
                      title: 'Cycle Perspective',
                      subtitle: 'Swipe the ring to navigate through your history and see patterns emerge.',
                      icon: Icons.auto_graph_outlined,
                    ),
                    const SizedBox(height: 20),
                    _buildImmersionCard(
                      title: 'Interactive Insights',
                      subtitle: 'Tap any segment to understand the biology of your current phase.',
                      icon: Icons.lightbulb_outline,
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildImmersionCard({required String title, required String subtitle, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 28),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.nunito(color: Colors.white60, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  void _openDailyLog(BuildContext context, DateTime date) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<TrackerBloc>(),
          child: DailyLogScreen(date: date),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String msg) {
    return Center(
      child: Text(msg, style: const TextStyle(color: Colors.white70)),
    );
  }
}
