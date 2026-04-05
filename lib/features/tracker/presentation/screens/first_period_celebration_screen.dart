import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

class FirstPeriodCelebrationScreen extends StatefulWidget {
  const FirstPeriodCelebrationScreen({super.key});

  @override
  State<FirstPeriodCelebrationScreen> createState() => _FirstPeriodCelebrationScreenState();
}

class _FirstPeriodCelebrationScreenState extends State<FirstPeriodCelebrationScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFFFCE4F3), Color(0xFFFAF5FF)],
          ),
        ),
        child: Stack(
          children: [
            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                maxBlastForce: 5,
                minBlastForce: 2,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.1,
                colors: const [Colors.pink, Colors.purple, Colors.orange, Colors.yellow],
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    // Animated Flower (Placeholder for Lottie)
                    _buildFlowerAnimation(),
                    
                    const SizedBox(height: 40),
                    
                    // Milestone Text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          _buildPointsAward(),
                          const SizedBox(height: 32),
                          _buildDialogueBox(),
                        ],
                      ),
                    ),
      
                    const SizedBox(height: 48),
                    
                    // Interaction Elements
                    _buildInteractionPanel(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowerAnimation() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.3),
      ),
      child: Center(
        child: Icon(Icons.favorite, size: 80, color: AppColors.pink.withOpacity(0.8))
            .animate(onPlay: (c) => c.repeat())
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1500.ms, curve: Curves.easeInOut)
            .then()
            .shake(hz: 3, rotation: 0.05),
      ),
    ).animate().fadeIn(duration: 1000.ms).scale();
  }

  Widget _buildPointsAward() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: AppColors.pink.withOpacity(0.2), blurRadius: 20)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✨', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: 200),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Text(
                    '+$value pts',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.pink),
                  );
                },
              ),
            ],
          ),
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5, end: 0),
        const SizedBox(height: 8),
        Text(
          'First period milestone!',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.purple),
        ).animate().fadeIn(delay: 700.ms),
      ],
    );
  }

  Widget _buildDialogueBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.pink.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textDark, height: 1.4),
              children: [
                const TextSpan(text: 'Gigi: "', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.purple)),
                const TextSpan(text: 'This is a big moment 💜 Your period has arrived! Your body is doing something incredible — and I\'ll be right here for every cycle.'),
                const TextSpan(text: '"', style: TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textDark, height: 1.4),
              children: [
                const TextSpan(text: 'Maya: "', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.green)),
                const TextSpan(text: 'Every body is different, and yours is doing exactly what it should 🌱'),
                const TextSpan(text: '"', style: TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildInteractionPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 30, offset: Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => context.push('/learning/journeys'),
            child: Text(
              'Read Episode 1: What just happened →',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: AppColors.pink, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.pink, AppColors.purple]),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [BoxShadow(color: AppColors.pink.withOpacity(0.3), blurRadius: 15)],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              ),
              onPressed: () => context.push('/tracker/settings'),
              child: Text(
                'Set Up My Tracker →',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Gigi: "I\'ll be here every day. You\'re never alone in this 💜"',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textMedium, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    ).animate().slideY(begin: 1.0, end: 0, duration: 600.ms, delay: 1500.ms);
  }
}
