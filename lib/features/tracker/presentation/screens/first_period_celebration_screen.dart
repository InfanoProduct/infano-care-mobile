import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

class FirstPeriodCelebrationScreen extends StatelessWidget {
  const FirstPeriodCelebrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF1F2), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              _buildFlowerAnimation(),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    Text(
                      'A Special Milestone! 🌸',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        color: const Color(0xFFE11D48),
                      ),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 16),
                    Text(
                      'Your body is doing exactly what it’s designed to do. We’re so proud to walk this journey with you! ✨',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: AppColors.textMedium,
                        height: 1.6,
                      ),
                    ).animate().fadeIn(delay: 800.ms),
                  ],
                ),
              ),
              const Spacer(),
              _buildPointsBadge().animate().scale(delay: 1200.ms, curve: Curves.elasticOut),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE11D48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Start My Tracker Journey 🌸',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 1500.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlowerAnimation() {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Petals
          for (int i = 0; i < 8; i++)
            Transform.rotate(
              angle: (i * 45) * (3.14159 / 180),
              child: Transform.translate(
                offset: const Offset(0, -40),
                child: Container(
                  width: 60,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFB7185).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scale(
               begin: const Offset(0.5, 0.5),
               end: const Offset(1.1, 1.1),
               duration: 2000.ms,
               delay: (i * 100).ms,
               curve: Curves.easeInOut,
             ),
          
          // Core
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFFDE047),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.orangeAccent, blurRadius: 20)],
            ),
          ).animate().scale(duration: 1000.ms, curve: Curves.bounceOut),
        ],
      ),
    );
  }

  Widget _buildPointsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
        border: Border.all(color: const Color(0xFFFDE047), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Text(
            '+200 Points Unlock!',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
