import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';

class WelcomeWorldScreen extends StatefulWidget {
  const WelcomeWorldScreen({super.key});

  @override
  State<WelcomeWorldScreen> createState() => _WelcomeWorldScreenState();
}

class _WelcomeWorldScreenState extends State<WelcomeWorldScreen> {
  bool _loading = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _enterHome() async {
    if (_loading) return;
    setState(() => _loading = true);

    final bloc = context.read<OnboardingBloc>();
    try {
      final storage = await LocalStorageService.create();
      await storage.setIsOnboarded(true);
      bloc.add(const CompleteOnboardingFlow());
      await bloc.stream.firstWhere((state) => !state.isLoading);
    } catch (_) {}

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 700;
    final isVerySmall = size.width < 360;
    final isTablet = size.width >= 600 || size.height >= 1000;
    final horizontalPadding = isTablet ? 32.0 : (isVerySmall ? 14.0 : 20.0);
    final topSpace = isTablet
        ? (size.height * 0.18).clamp(70.0, 200.0)
        : (isCompact ? 50.0 : (size.height * 0.12).clamp(60.0, 130.0));

    return Scaffold(
      body: Stack(
        children: [
          // 1. 3D Background Illustration
          Positioned.fill(
            child: Image.asset(
              'assets/images/phone_entry_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // Confetti Celebration Effect
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFF8B5CF6),
                Color(0xFFEC4899),
                Color(0xFFF43F5E),
                Color(0xFF10B981),
                Color(0xFFF59E0B),
                Color(0xFF3B82F6),
                Colors.white,
              ],
              emissionFrequency: 0.05,
              numberOfParticles: 40,
              gravity: 0.15,
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

          // 3. Interactive Glassmorphic Welcome Card
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(height: topSpace),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 26 : (isVerySmall ? 16 : 22),
                                vertical: isCompact ? 20 : 26,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.93),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(color: Colors.white, width: 2),
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // 3D Celebration Badge
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFEDE9FE), Color(0xFFF5F3FF)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF6D28D9).withValues(alpha: 0.16),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '🎉',
                                        style: TextStyle(fontSize: 28),
                                      ),
                                    ),
                                  ).animate().scale(
                                        duration: 500.ms,
                                        curve: Curves.elasticOut,
                                      ),

                                  const SizedBox(height: 14),

                                  // Header Title
                                  Text(
                                    "You're all set! 🌸",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: isVerySmall ? 20 : 22,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF2D1557),
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  Text(
                                    'Welcome to Infano.Care — your safe, supportive space to bloom and grow with confidence.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B7280),
                                      height: 1.35,
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Achievement Summary Card (No points/coins)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Column(
                                      children: const [
                                        _AchievementRow(
                                          icon: '⭐',
                                          text: 'Profile Setup Completed',
                                        ),
                                        SizedBox(height: 10),
                                        _AchievementRow(
                                          icon: '🛡️',
                                          text: 'Privacy & Data Protection Active',
                                        ),
                                        SizedBox(height: 10),
                                        _AchievementRow(
                                          icon: '💜',
                                          text: 'Personalized Care Feed Ready',
                                        ),
                                      ],
                                    ),
                                  ).animate().fadeIn(duration: 400.ms),

                                  const SizedBox(height: 24),

                                  // Final CTA Button ("Enter My World 🌸")
                                  AnimatedOpacity(
                                    opacity: !_loading ? 1.0 : 0.65,
                                    duration: const Duration(milliseconds: 200),
                                    child: GestureDetector(
                                      onTap: !_loading ? _enterHome : null,
                                      child: Container(
                                        height: 50,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF6D28D9),
                                              Color(0xFF5B21B6),
                                            ],
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
                                          child: _loading
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2.5,
                                                  ),
                                                )
                                              : Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Enter My World 🌸',
                                                      style: GoogleFonts.nunito(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w900,
                                                        color: Colors.white,
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
                                  ),

                                  const SizedBox(height: 16),

                                  // Privacy Footer Note
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.shield_outlined,
                                        size: 14,
                                        color: Color(0xFF6B7280),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'We protect and never sell data to 3rd-party',
                                        style: GoogleFonts.nunito(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(duration: 500.ms).slideY(
                              begin: 0.08,
                              duration: 500.ms,
                              curve: Curves.easeOutBack,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. Top Floating Back Button (Navigates back to Assent & Terms if user wants to review)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: isTablet ? 32 : 16,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/onboarding/terms');
                }
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF5B21B6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.icon, required this.text});
  final String icon, text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF6D28D9).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(icon, style: const TextStyle(fontSize: 15)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.nunito(
              color: const Color(0xFF2D1557),
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
        ),
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF10B981),
          size: 18,
        ),
      ],
    );
  }
}
