import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';

/// Shown when [prediction.daysUntilPrediction] <= 7.
/// Displays a countdown with confidence badge.
class PredictionBanner extends StatelessWidget {
  final PredictionResultModel prediction;

  const PredictionBanner({super.key, required this.prediction});

  static bool shouldShow(PredictionResultModel? prediction) =>
      prediction != null && prediction.daysUntilPrediction <= 7;

  @override
  Widget build(BuildContext context) {
    final days = prediction.daysUntilPrediction;
    final isToday = days <= 0;
    final label = isToday
        ? 'Your period may start today 🩸'
        : 'Your period is expected in $days ${days == 1 ? 'day' : 'days'} 🩸';

    final conf = prediction.confidenceLevel.toLowerCase();
    final confidenceColor = conf == 'high'
        ? AppColors.success
        : conf == 'medium'
            ? AppColors.bloom
            : AppColors.textMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFCE7F3), Color(0xFFFEF2F8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.pink.withOpacity(0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.pink.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.pink.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Text('🔮', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: confidenceColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: confidenceColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${prediction.confidenceLevel} confidence',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: confidenceColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cycle day ${prediction.cycleDay}',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 350.ms)
          .slideY(begin: -0.1, end: 0, duration: 350.ms),
    );
  }
}
