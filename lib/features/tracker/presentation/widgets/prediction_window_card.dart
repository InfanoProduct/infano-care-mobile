import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:intl/intl.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

class PredictionWindowCard extends StatelessWidget {
  final CycleProfileModel profile;
  final PredictionResultModel? prediction;

  const PredictionWindowCard({
    super.key,
    required this.profile,
    this.prediction,
  });

  @override
  Widget build(BuildContext context) {
    if (profile.predictionWindowEarly == null ||
        profile.predictionWindowLate == null) {
      return const SizedBox.shrink();
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    var start = profile.predictionWindowEarly!;
    var end = profile.predictionWindowLate!;
    var ovulation = prediction?.ovulationDate ?? start.subtract(const Duration(days: 14));
    var fertStart = prediction?.fertilityStart ?? ovulation.subtract(const Duration(days: 5));
    var fertEnd = prediction?.fertilityEnd ?? ovulation.add(const Duration(days: 1));

    final avgLen = profile.avgCycleLength > 0 ? profile.avgCycleLength.toInt() : 28;

    // If the expected period window is entirely in the past, project it forward
    // iteratively by avgCycleLength until the prediction window is in the future.
    while (end.isBefore(todayDate)) {
      start = start.add(Duration(days: avgLen));
      end = end.add(Duration(days: avgLen));
      ovulation = ovulation.add(Duration(days: avgLen));
      fertStart = fertStart.add(Duration(days: avgLen));
      fertEnd = fertEnd.add(Duration(days: avgLen));
    }

    final rangeStr = "${DateFormat('MMMM d').format(start)} – ${DateFormat('MMMM d').format(end)}";
    final ovulationStr = DateFormat('EEEE, MMMM d').format(ovulation);
    final fertStr = "${DateFormat('MMMM d').format(fertStart)} – ${DateFormat('MMMM d').format(fertEnd)}";

    // Confidence Level
    final confidence = prediction?.confidenceLevel ?? 'Medium';
    final confidenceColor = confidence.toLowerCase() == 'high' 
        ? const Color(0xFF10B981) // Green
        : const Color(0xFFF59E0B); // Amber

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F3FF), // Pastel lavender header
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🔮', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text(
                      "Gigi's Cycle Prediction",
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: const Color(0xFF5B21B6),
                      ),
                    ),
                  ],
                ),
                if (confidence.toLowerCase() != 'none')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: confidenceColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: confidenceColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${confidence[0].toUpperCase()}${confidence.substring(1)} Confidence',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: confidenceColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Body content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Expected Period Row
                _buildInfoRow(
                  icon: '🩸',
                  title: 'Expected Period Window',
                  value: rangeStr,
                  subtitle: 'Gigi expects your cycle to start during this time',
                  themeColor: const Color(0xFFFDF2F8), // Pastel pink background
                  borderColor: const Color(0xFFFBCFE8), // Pastel pink border
                  accentColor: const Color(0xFFEC4899), // Brand pink highlight
                ),
                const SizedBox(height: 16),
                
                // Next Ovulation Row
                _buildInfoRow(
                  icon: '🥚',
                  title: 'Predicted Ovulation Day',
                  value: ovulationStr,
                  subtitle: 'Most fertile day of your current cycle',
                  themeColor: const Color(0xFFF5F3FF), // Pastel violet background
                  borderColor: const Color(0xFFDDD6FE), // Pastel violet border
                  accentColor: const Color(0xFF7C3AED), // Brand purple highlight
                ),
                const SizedBox(height: 16),

                // Fertility Window Row
                _buildInfoRow(
                  icon: '✨',
                  title: 'Fertile Window',
                  value: fertStr,
                  subtitle: 'High chance of pregnancy during these days',
                  themeColor: const Color(0xFFECFDF5), // Pastel mint background
                  borderColor: const Color(0xFFA7F3D0), // Pastel mint border
                  accentColor: const Color(0xFF10B981), // Brand green highlight
                ),
                
                const SizedBox(height: 20),
                
                // Bottom advisory note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Color(0xFF7C3AED),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The prediction window narrows down as you log your cycle consistently.',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: const Color(0xFF6D28D9),
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String icon,
    required String title,
    required String value,
    required String subtitle,
    required Color themeColor,
    required Color borderColor,
    required Color accentColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: themeColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
