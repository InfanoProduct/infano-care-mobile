import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
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
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;
    _onComplete();
  }

  void _onComplete() {
    try {
      context.read<TrackerBloc>().add(const TrackerEvent.load());
    } catch (_) {}

    final storage = context.read<LocalStorageService>();
    if (storage.isOnboarded) {
      if (context.canPop()) {
        Navigator.of(context).popUntil((route) {
          final routeName = route.settings.name ?? '';
          return route.isFirst || (!routeName.contains('tracker') && !routeName.contains('onboarding'));
        });
      } else {
        context.go('/home');
      }
    } else {
      context.go('/onboarding/terms');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600 || size.height >= 1000;

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

          // 3. Main Glassmorphic Activation Card
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 22,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 28,
                    ),
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
                        // 3D Animated Activation Icon Badge
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6D28D9).withValues(alpha: 0.25),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🌸', style: TextStyle(fontSize: 34)),
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scaleXY(
                              begin: 0.95,
                              end: 1.08,
                              duration: 1600.ms,
                              curve: Curves.easeInOut,
                            ),

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
                          "Your cycle prediction is live 🌸\nWe'll gently keep you informed and prepared.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6B7280),
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Success Status Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFDDD6FE),
                              width: 1.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6D28D9).withValues(alpha: 0.08),
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
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF6D28D9),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'CYCLE SETUP COMPLETE',
                                    style: GoogleFonts.nunito(
                                      color: const Color(0xFF5B21B6),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12.5,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Personalized predictions & guidance ready! ✨',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  color: const Color(0xFF4C1D95),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Primary Action Button (Phone Entry CTA Style)
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
                                    'Proceed',
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
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
          ),
        ],
      ),
    );
  }
}
