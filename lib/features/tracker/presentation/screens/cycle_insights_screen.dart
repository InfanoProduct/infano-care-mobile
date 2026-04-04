import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/tracker_insights.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';

class CycleInsightsScreen extends StatelessWidget {
  final CycleProfileModel profile;
  final List<CycleLogModel> logs;

  const CycleInsightsScreen({
    super.key, 
    required this.profile, 
    required this.logs
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cycle Insights 📊',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: AppColors.textDark, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Menstrual Intelligence', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text('Uncovering patterns in your unique body.', style: GoogleFonts.nunito(color: AppColors.textMedium, fontSize: 14)),
            const SizedBox(height: 32),
            TrackerInsights(profile: profile, logs: logs),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
