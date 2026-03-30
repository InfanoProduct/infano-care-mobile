import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

class PhaseInfoSheet extends StatelessWidget {
  final String phase;

  const PhaseInfoSheet({super.key, required this.phase});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> phaseData = _getPhaseData(phase);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: phaseData['color'].withOpacity(0.1), shape: BoxShape.circle),
                child: Text(phaseData['emoji'], style: const TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(phaseData['title'], style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.textDark)),
                    Text(phaseData['duration'], style: GoogleFonts.nunito(color: AppColors.textMedium, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0),
          const SizedBox(height: 32),
          
          Text('🧬 What\'s happening?', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textDark)),
          const SizedBox(height: 12),
          Text(phaseData['biology'], style: GoogleFonts.nunito(color: AppColors.textMedium, height: 1.6, fontSize: 15)),
          const SizedBox(height: 24),
          
          Text('🧠 Emotional vibe', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textDark)),
          const SizedBox(height: 12),
          Text(phaseData['emotions'], style: GoogleFonts.nunito(color: AppColors.textMedium, height: 1.6, fontSize: 15)),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: phaseData['color'].withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: phaseData['color'].withOpacity(0.1))),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 16),
                Expanded(child: Text(phaseData['tip'], style: GoogleFonts.nunito(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 14))),
              ],
            ),
          ).animate().scale(delay: 200.ms),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Map<String, dynamic> _getPhaseData(String phaseId) {
    switch (phaseId.toLowerCase()) {
      case 'menstrual':
        return {
          'title': 'Menstrual Phase',
          'emoji': '🩸',
          'color': const Color(0xFFF43F5E),
          'duration': 'Days 1-5',
          'biology': 'Your progesterone and estrogen levels are at their lowest. The uterine lining is shedding, which is why your energy might feel a bit lower than usual.',
          'emotions': 'You might feel introspective, quiet, or in need of extra rest. It\'s a great time for reflecting and taking things slowly.',
          'tip': 'Prioritize warm foods, gentle stretching, and early nights. You deserve the rest!',
        };
      case 'follicular':
        return {
          'title': 'Follicular Phase',
          'emoji': '🌱',
          'color': const Color(0xFF10B981),
          'duration': 'Days 6-11',
          'biology': 'Estrogen is starting to rise! Your body is preparing an egg for ovulation, and your brain is getting a boost of feel-good chemicals.',
          'emotions': 'Creativity and curiosity often peak here. You might feel more social, optimistic, and ready to take on new projects.',
          'tip': 'Perfect time to learn something new or start a creative hobby!',
        };
      case 'ovulation':
        return {
          'title': 'Ovulation Phase',
          'emoji': '✨',
          'color': const Color(0xFFFBBF24),
          'duration': 'Days 12-16',
          'biology': 'LH levels peak and an egg is released. Your estrogen is at its highest point, making you feel physically energized.',
          'emotions': 'Confidence is usually at an all-time high. You might feel more outgoing and expressive.',
          'tip': 'Schedule those social events or big presentations now — your confidence is glowing!',
        };
      case 'luteal':
        return {
          'title': 'Luteal Phase',
          'emoji': '🌙',
          'color': const Color(0xFF6366F1),
          'duration': 'Days 17-28',
          'biology': 'Progesterone takes the lead. This hormone can sometimes cause physical symptoms like bloating or skin changes as your body prepares for the next cycle.',
          'emotions': 'You might feel more sensitive or prefer being cozy at home. It\'s a time for self-care and setting boundaries.',
          'tip': 'Focus on hydration and magnesium-rich foods to help with PMS symptoms.',
        };
      default:
        return {
          'title': 'Phase Info',
          'emoji': '🌸',
          'color': AppColors.purple,
          'duration': 'Current Cycle',
          'biology': 'Your cycle is a complex and beautiful biological rhythm of hormones.',
          'emotions': 'Every day brings a different feeling, and that is completely normal.',
          'tip': 'Keep logging to see your unique patterns emerge!',
        };
    }
  }
}
