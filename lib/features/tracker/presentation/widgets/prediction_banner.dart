import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';

class PredictionBanner extends StatelessWidget {
  final CycleProfileModel profile;
  final PredictionResultModel? prediction;
  final VoidCallback? onClose;

  const PredictionBanner({
    super.key,
    required this.profile,
    required this.prediction,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final bannerInfo = _getBannerInfo();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: bannerInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: bannerInfo.color.withOpacity(0.3)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with confidence and Emoji
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            bannerInfo.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Gigi',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w900,
                              color: bannerInfo.color,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (prediction != null && profile.trackerMode != 'watching_waiting')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: bannerInfo.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getConfidenceText(),
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: bannerInfo.color,
                          ),
                        ),
                      ),
                    if (onClose != null)
                      GestureDetector(
                        onTap: onClose,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: Icon(Icons.close, size: 20, color: AppColors.textMedium),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Message Content
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gigi Mascot Image
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bannerInfo.color.withOpacity(0.1),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/gigi.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: bannerInfo.color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Speech Text
                    Expanded(
                      child: Text(
                        '"${bannerInfo.message}"',
                        style: GoogleFonts.nunito(
                          color: AppColors.textDark.withOpacity(0.9),
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // CTA Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bannerInfo.color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      bannerInfo.cta,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0);
  }

  String _getConfidenceText() {
    final cv = prediction?.coefficientOfVar ?? 0.0;
    if (cv == 0.0) return 'Learning...';
    if (cv < 8.0) return 'High Confidence';
    if (cv < 15.0) return 'Confident';
    return 'Building Confidence';
  }

  _BannerState _getBannerInfo() {
    final mode = profile.trackerMode;
    final cycles = prediction?.cyclesLogged ?? 0;
    final cv = prediction?.coefficientOfVar ?? 0.0;
    final daysUntil = prediction?.daysUntilPrediction;

    // Watching & Waiting
    if (mode == 'watching_waiting') {
      return _BannerState(
        message: "Your period hasn't started yet — and that's exactly right for where you are 🌱 Keep logging your mood and energy. When your period arrives, I'll be right here.",
        color: const Color(0xFF0D9488), // Teal
        emoji: '🌱',
        cta: 'Talk to Me',
      );
    }

    // Irregular
    if (mode == 'irregular_support' || prediction?.confidenceLevel == 'irregular') {
      return _BannerState(
        message: "Your cycle varies — which is completely normal for many people. Your period may arrive anywhere in this window. I'm tracking the patterns to get better at predicting yours specifically 💜",
        color: Colors.amber.shade700,
        emoji: '🧐',
        cta: 'Talk to Me',
      );
    }

    // None
    if (prediction == null || cycles == 0) {
      return _BannerState(
        message: 'Log a few days and your cycle ring will start to come alive! ✨ The more you log, the smarter your predictions get.',
        color: const Color(0xFF10B981), // Emerald Green
        emoji: '✨',
        cta: 'Talk to Me',
      );
    }

    // Period Overdue
    if (daysUntil != null && daysUntil <= -5) {
      return _BannerState(
        message: 'Your period is a few days later than expected — which is completely normal. Late periods happen for many reasons: stress, illness, travel, or your body taking its time 💜 Want to know more?',
        color: AppColors.purple,
        emoji: '💜',
        cta: 'Talk to Me',
      );
    }

    // Period Imminent
    if (daysUntil != null && daysUntil >= 0 && daysUntil <= 3) {
      return _BannerState(
        message: 'Your period may be arriving soon 🩸 — tap to prepare.',
        color: Colors.red.shade500,
        emoji: '🩸',
        cta: 'Talk to Me',
      );
    }

    // High Confidence
    if (cycles >= 5 && cv > 0 && cv < 8.0) {
      return _BannerState(
        message: 'Your period is likely tomorrow or the day after ✨',
        color: const Color(0xFF10B981), // Emerald Green
        emoji: '✨',
        cta: 'Talk to Me',
      );
    }

    // Confident
    if (cycles >= 3 && cv > 0 && cv < 15.0) {
      final range = '${daysUntil ?? 0}–${(daysUntil ?? 0) + 2}';
      return _BannerState(
        message: 'Your period is likely in $range days — you know your body 💜',
        color: const Color(0xFF10B981), // Emerald Green
        emoji: '😌',
        cta: 'Talk to Me',
      );
    }

    // Building
    if (cycles == 2 || cycles == 3) {
      final range = '${daysUntil ?? 0}–${(daysUntil ?? 0) + 5}';
      return _BannerState(
        message: "Your period is likely in the next $range days. I'm learning your pattern — each log makes this more accurate 🌱",
        color: const Color(0xFF10B981),
        emoji: '🤔',
        cta: 'Talk to Me',
      );
    }

    // Getting Started
    if (cycles == 1) {
      final range = '${daysUntil ?? 0}–${(daysUntil ?? 0) + 7}';
      return _BannerState(
        message: 'Based on your first cycle, your period may arrive around $range days from now. Keep logging — after one more cycle, my predictions will get much sharper 💜',
        color: const Color(0xFF10B981), // Emerald Green
        emoji: '😊',
        cta: 'Talk to Me',
      );
    }

    // Fallback
    return _BannerState(
      message: 'Keep logging your symptoms to help me learn your cycle better! 🌱',
      color: const Color(0xFF10B981),
      emoji: '🌱',
      cta: 'Talk to Me',
    );
  }
}

class _BannerState {
  final String message;
  final Color color;
  final String emoji;
  final String cta;

  _BannerState({
    required this.message,
    required this.color,
    required this.emoji,
    required this.cta,
  });
}
