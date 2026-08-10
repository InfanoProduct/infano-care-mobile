import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

class SafetyWelcomeScreen extends StatelessWidget {
  const SafetyWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('👥', 'Add Trusted People', 'Up to 5 contacts who get your alert'),
      ('🚨', 'Set Alert Style', 'Your default emergency category'),
      ('📤', 'Send a Test', 'So your contacts know what to expect'),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Ambient Fluid Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFAF5FF),
                    Color(0xFFFFF1F2),
                    Color(0xFFF5F3FF)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.purple.withOpacity(0.15),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  duration: 4.seconds,
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.3, 1.3),
                ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Shield Badge
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.purple.withOpacity(0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '🛡️',
                              style: TextStyle(fontSize: 40),
                            ),
                          ),
                        )
                            .animate()
                            .scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack)
                            .shimmer(delay: 600.ms, duration: 1200.ms),
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          'Your Personal\nSafety Guard',
                          style: GoogleFonts.nunito(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                        ).animate().fade(duration: 400.ms).slideY(begin: 0.2),
                        const SizedBox(height: 16),

                        Text(
                          'When you need help, one press sends an instant alert '
                          'with your live location to people you trust. '
                          'Simple, silent, and fast.',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            color: AppColors.textMedium,
                            height: 1.5,
                          ),
                        ).animate().fade(delay: 150.ms, duration: 400.ms),
                        const SizedBox(height: 36),

                        // Divider Title
                        Text(
                          'QUICK SETUP STEPS',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: AppColors.purple,
                            letterSpacing: 1.5,
                          ),
                        ).animate().fade(delay: 200.ms),
                        const SizedBox(height: 16),

                        // Glassmorphic Steps Cards
                        ...steps.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final step = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                // Step Icon Badge
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      step.$1,
                                      style: const TextStyle(fontSize: 26),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Step ${idx + 1}: ${step.$2}',
                                        style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        step.$3,
                                        style: GoogleFonts.nunito(
                                          fontSize: 13,
                                          color: AppColors.textMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fade(delay: (250 + idx * 100).ms, duration: 400.ms)
                              .slideX(begin: 0.1);
                        }),
                      ],
                    ),
                  ),
                ),

                // Premium Sticky Bottom Panel
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 24,
                        offset: const Offset(0, -8),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => context.push('/safety/contacts?wizard=true'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.purple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: AppColors.purple.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Get Started Now',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go('/home'),
                        child: Text(
                          'Skip for now',
                          style: GoogleFonts.nunito(
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fade(delay: 600.ms, duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
