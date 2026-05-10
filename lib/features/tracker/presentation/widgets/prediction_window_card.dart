import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:intl/intl.dart';

class PredictionWindowCard extends StatelessWidget {
  final CycleProfileModel profile;

  const PredictionWindowCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile.predictionWindowEarly == null ||
        profile.predictionWindowLate == null) {
      return const SizedBox.shrink();
    }

    final start = profile.predictionWindowEarly!;
    final end = profile.predictionWindowLate!;
    final rangeStr =
        "${DateFormat('MMM d').format(start)} and ${DateFormat('MMM d').format(end)}";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF5F3FF), // Soft Pastel Lavender
            const Color(0xFFFDF2F8), // Soft Pastel Pinkish-Lavender
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE9FE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Text('🔮', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Text(
                'Next Prediction',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: const Color(
                    0xFF5B21B6,
                  ), // Deeper purple for better contrast
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: GoogleFonts.nunito(
                fontSize: 15,
                color: const Color(0xFF4B5563), // Slightly darker gray
                height: 1.5,
              ),
              children: [
                const TextSpan(
                  text: "Gigi is expecting your next cycle to begin between ",
                ),
                TextSpan(
                  text: rangeStr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const TextSpan(text: "."),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: Color(0xFF7C3AED),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'As you keep managing the data, the prediction window will get smaller.',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: const Color(0xFF6D28D9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
