import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/features/tracker/bloc/tracker_bloc.dart';

class TrackerActivatedScreen extends StatefulWidget {
  const TrackerActivatedScreen({super.key});

  @override
  State<TrackerActivatedScreen> createState() => _TrackerActivatedScreenState();
}

class _TrackerActivatedScreenState extends State<TrackerActivatedScreen> {
  @override
  void initState() {
    super.initState();
    _autoRoute();
  }

  Future<void> _autoRoute() async {
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;
    _onComplete();
  }

  void _onComplete() {
    // 1. Instantly trigger global TrackerBloc reload so Homepage card updates to active state!
    try {
      context.read<TrackerBloc>().add(const TrackerEvent.load());
    } catch (_) {}

    // 2. Navigate to Homepage
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B7CD8),
      body: Stack(
        children: [
          // 1. 3D Background Illustration
          Positioned.fill(
            child: Image.asset(
              'assets/images/period_tracker_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // 2. Soft Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF5B21B6).withValues(alpha: 0.1),
                    const Color(0xFF2D1557).withValues(alpha: 0.38),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. Main Glassmorphic Activation Card (Center/Middle Aligned)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4C1D95).withValues(alpha: 0.22),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 3D Animated Coin / Reward Icon Badge
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD97706).withValues(alpha: 0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🪙', style: TextStyle(fontSize: 34)),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                       .scaleXY(begin: 0.95, end: 1.08, duration: 1600.ms, curve: Curves.easeInOut),

                      const SizedBox(height: 16),

                      Text(
                        'Tracker Activated!',
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF2D1557),
                        ),
                      ).animate().fadeIn(duration: 400.ms),

                      const SizedBox(height: 6),

                      Text(
                        "Your cycle prediction is live 🌸\nCheck your dashboard anytime.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 20 Coins Reward Container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFFCD34D), width: 1.4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🪙', style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 6),
                                Text(
                                  'SETUP REWARD',
                                  style: GoogleFonts.nunito(
                                    color: const Color(0xFFB45309),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '+20 Coins',
                              style: GoogleFonts.nunito(
                                color: const Color(0xFFD97706),
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                              ),
                            ).animate().scale(begin: const Offset(0.6, 0.6), duration: 600.ms, curve: Curves.elasticOut),
                            const SizedBox(height: 4),
                            Text(
                              '20 Coins added to your profile balance! 🎉',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                color: const Color(0xFF92400E),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Primary Button (Phone Entry CTA Style)
                      GestureDetector(
                        onTap: _onComplete,
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6D28D9), Color(0xFF5B21B6)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5B21B6).withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Enter My World',
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('🌸', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
