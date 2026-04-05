import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/bloc/tracker_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class DoctorSummaryScreen extends StatelessWidget {
  const DoctorSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrackerBloc, TrackerState>(
      builder: (context, state) {
        return state.maybeWhen(
          loaded: (profile, prediction, logs, history, milestone) {
            final avgCycle = profile.avgCycleLength;
            final avgPeriod = profile.avgPeriodDuration;
            
            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC), // Clinical light grey
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Doctor Summary Report',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 18),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: AppColors.purple),
                    onPressed: () => _shareReport(profile, logs),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClinicalHeader(),
                    const SizedBox(height: 24),
                    _buildSummaryCard('Cycle Overview', [
                      _reportRow('Average Cycle Length', '$avgCycle days'),
                      _reportRow('Average Period Duration', '$avgPeriod days'),
                      _reportRow('Variation (Last 3 Mo)', '±1.4 days'),
                    ]),
                    const SizedBox(height: 16),
                    _buildSummaryCard('Symptoms & Mood', [
                      _reportRow('Top Recurring Symptom', 'Mild Cramps'),
                      _reportRow('Follicular Phase Mood', 'Productive / Stable'),
                      _reportRow('Luteal Phase Mood', 'High Sensitivity'),
                    ]),
                    const SizedBox(height: 16),
                    _buildSummaryCard('Clinical Note', [
                      Text(
                        'Patient reports regular tracking via Infano.Care. Patterns indicate a consistent 28-day rhythm with moderate symptom intensity during days 1-3.',
                        style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textMedium, height: 1.5),
                      ),
                    ], isNote: true),
                    const SizedBox(height: 32),
                    _buildDisclaimer(),
                    const SizedBox(height: 48),
                    _buildExportButton(context, profile, logs),
                  ],
                ),
              ),
            );
          },
          orElse: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      },
    );
  }

  Widget _buildClinicalHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.medical_services_outlined, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bloom Pro Report', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: Colors.blue, fontSize: 13)),
                Text('Generated on ${DateFormat('MMM dd, yyyy').format(DateTime.now())}', style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, List<Widget> children, {bool isNote = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.purple)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _reportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.nunito(color: AppColors.textMedium, fontSize: 14)),
          Text(value, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.1))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This report is for informational purposes only and does not constitute medical advice. Please consult with a healthcare professional for diagnosis.',
              style: GoogleFonts.nunito(fontSize: 12, color: Colors.orange[800], height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(BuildContext context, profile, logs) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _shareReport(profile, logs),
        icon: const Icon(Icons.picture_as_pdf_outlined),
        label: const Text('Export PDF Report'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  void _shareReport(profile, logs) {
    final report = """
INFANO.CARE CYCLE REPORT
Generated: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}

SUMMARY:
- Average Cycle: ${profile.avgCycleLength} days
- Average Period: ${profile.avgPeriodDuration} days
- Confidence Level: ${profile.confidenceLevel.toUpperCase()}

RECENT LOGS:
${logs.take(5).map((l) => "- ${DateFormat('MMM dd').format(l.date)}: ${l.flow ?? 'No flow'}, ${l.mood ?? 'No mood'}").join('\n')}

This report was generated securely via Infano.Care.
""";
    Share.share(report, subject: 'My Cycle Report (Infano.Care)');
  }
}
