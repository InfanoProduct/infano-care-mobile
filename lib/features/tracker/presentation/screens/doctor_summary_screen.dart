import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/bloc/tracker_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DoctorSummaryScreen extends StatelessWidget {
  const DoctorSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrackerBloc, TrackerState>(
      builder: (context, state) {
        return state.maybeWhen(
          loaded: (profile, prediction, logs, history, dailyInsights, articles, milestone, isRefreshing) {
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
                      _reportRow('Average Cycle Length', '${profile.avgCycleLength.round()} days'),
                      _reportRow('Average Period Duration', '${profile.avgPeriodDuration.round()} days'),
                      _reportRow('Confidence Level', profile.confidenceLevel.toUpperCase()),
                    ]),
                    const SizedBox(height: 16),
                    _buildSummaryCard('Clinical Indicators', [
                      _reportRow('Primary Mood Pattern', _getTopItem(logs.map((l) => l.moodPrimary).whereType<String>().toList()) ?? 'Stable'),
                      _reportRow('Dominant Symptom', _formatSymptomName(_getTopItem(logs.expand((l) => l.symptoms).toList()) ?? 'None')),
                      _reportRow('Fluid Observation', _getTopItem(logs.map((l) => l.vaginalDischarge).whereType<String>().toList()) ?? 'Not tracked'),
                    ]),
                    const SizedBox(height: 16),
                    _buildSummaryCard('Sleep & Recovery', [
                      _reportRow('Avg Sleep Duration', '${_getAverageSleep(logs).toStringAsFixed(1)} hours'),
                      _reportRow('Avg Sleep Quality', '${_getAverageSleepQuality(logs).toStringAsFixed(1)} / 5'),
                    ]),
                    const SizedBox(height: 16),
                    _buildSummaryCard('Lifestyle Markers', [
                      _reportRow('Physical Activity', _getTopItem(logs.expand((l) => l.activityTags).toList()) ?? 'Not recorded'),
                      _reportRow('Nutrition/Cravings', _getTopItem(logs.expand((l) => l.nutritionTags).toList()) ?? 'Not recorded'),
                    ]),
                    const SizedBox(height: 16),
                    _buildSummaryCard('Clinical Synthesis', [
                      Text(
                        _generateClinicalSynthesis(profile, logs),
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
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
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
      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withValues(alpha: 0.1))),
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

  Widget _buildExportButton(BuildContext context, CycleProfileModel profile, List<CycleLogModel> logs) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _exportPdf(context, profile, logs),
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

  Future<void> _exportPdf(BuildContext context, CycleProfileModel profile, List<CycleLogModel> logs) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('INFANO.CARE CLINICAL REPORT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.blue900)),
              pw.Text(formattedDate, style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
        ),
        footer: (pw.Context context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Generated securely via Infano.Care App', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ],
          ),
        ),
        build: (pw.Context context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange50,
              border: pw.Border.all(color: PdfColors.orange200),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Text(
              'IMPORTANT: This report is for clinical reference and informational purposes only. It is intended to assist your healthcare provider in their diagnosis and does NOT prescribe any medication, treatment, or formal diagnosis.',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.orange900, fontStyle: pw.FontStyle.italic),
            ),
          ),
          pw.SizedBox(height: 24),
          _pdfSection('Cycle Overview', [
            _pdfRow('Average Cycle Length', '${profile.avgCycleLength.round()} days'),
            _pdfRow('Average Period Duration', '${profile.avgPeriodDuration.round()} days'),
            _pdfRow('Regularity Confidence', profile.confidenceLevel.toUpperCase()),
          ]),
          pw.SizedBox(height: 16),
          _pdfSection('Clinical Indicators', [
            _pdfRow('Primary Mood pattern', _getTopItem(logs.map((l) => l.moodPrimary).whereType<String>().toList()) ?? 'Stable'),
            _pdfRow('Dominant Symptom', _formatSymptomName(_getTopItem(logs.expand((l) => l.symptoms).toList()) ?? 'None')),
            _pdfRow('Cervical Fluid Pattern', _getTopItem(logs.map((l) => l.vaginalDischarge).whereType<String>().toList()) ?? 'Not tracked'),
          ]),
          pw.SizedBox(height: 16),
          _pdfSection('Sleep & Recovery', [
            _pdfRow('Avg Sleep Duration', '${_getAverageSleep(logs).toStringAsFixed(1)} hours'),
            _pdfRow('Avg Sleep Quality', '${_getAverageSleepQuality(logs).toStringAsFixed(1)} / 5'),
          ]),
          pw.SizedBox(height: 16),
          _pdfSection('Lifestyle Markers', [
            _pdfRow('Physical Activity', _getTopItem(logs.expand((l) => l.activityTags).toList()) ?? 'Not recorded'),
            _pdfRow('Nutrition/Cravings', _getTopItem(logs.expand((l) => l.nutritionTags).toList()) ?? 'Not recorded'),
          ]),
          pw.SizedBox(height: 16),
          _pdfSection('Clinical Synthesis', [
            pw.Text(
              _generateClinicalSynthesis(profile, logs),
              style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
            ),
          ]),
        ],
      ),
    );

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Infano_Clinical_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
      );
    } catch (e) {
      debugPrint('PDF Export Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: ${e.toString()}')),
        );
      }
    }
  }

  pw.Widget _pdfSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blue800)),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(children: children),
        ),
      ],
    );
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  void _shareReport(CycleProfileModel profile, List<CycleLogModel> logs) {
    final topSymptom = _getTopItem(logs.expand((l) => l.symptoms).toList()) ?? 'None';
    final avgSleep = _getAverageSleep(logs);
    final topDischarge = _getTopItem(logs.map((l) => l.vaginalDischarge).whereType<String>().toList()) ?? 'None';
    final topActivity = _getTopItem(logs.expand((l) => l.activityTags).toList()) ?? 'Not recorded';
    final topNutrition = _getTopItem(logs.expand((l) => l.nutritionTags).toList()) ?? 'Not recorded';

    final report = """
INFANO.CARE CLINICAL SUMMARY REPORT
Generated: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}

VITALS:
- Avg Cycle: ${profile.avgCycleLength.round()} days
- Avg Period: ${profile.avgPeriodDuration.round()} days
- Cycle Regularity: ${profile.confidenceLevel.toUpperCase()}

CLINICAL OBSERVATIONS:
- Top Symptom: ${_formatSymptomName(topSymptom)}
- Sleep Avg: ${avgSleep.toStringAsFixed(1)} hours
- Discharge Pattern: $topDischarge

LIFESTYLE MARKERS:
- Physical Activity: $topActivity
- Nutrition/Cravings: $topNutrition

RECENT LOGS (Last 3):
${logs.take(3).map((l) => "- ${DateFormat('MMM dd').format(l.date)}: ${l.flow ?? 'No flow'}, ${l.moodPrimary ?? 'No mood'}").join('\n')}

SYNTHESIS:
${_generateClinicalSynthesis(profile, logs)}

---
This report was generated securely via Infano.Care for clinical reference.
""";
    Share.share(report, subject: 'My Clinical Cycle Report (Infano.Care)');
  }

  String? _getTopItem(List<String> items) {
    if (items.isEmpty) return null;
    Map<String, int> counts = {};
    for (var i in items) {
      counts[i] = (counts[i] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  double _getAverageSleep(List<CycleLogModel> logs) {
    final valid = logs.where((l) => l.sleepHours != null).toList();
    if (valid.isEmpty) return 0.0;
    return valid.fold(0.0, (sum, l) => sum + l.sleepHours!) / valid.length;
  }

  double _getAverageSleepQuality(List<CycleLogModel> logs) {
    final valid = logs.where((l) => l.sleepQuality != null).toList();
    if (valid.isEmpty) return 0.0;
    return valid.fold(0.0, (sum, l) => sum + l.sleepQuality!) / valid.length;
  }

  String _formatSymptomName(String id) {
    return id.replaceAll('_', ' ').split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '').join(' ');
  }

  String _generateClinicalSynthesis(CycleProfileModel profile, List<CycleLogModel> logs) {
    if (logs.isEmpty) return "Insufficient data for synthesis. Continued tracking recommended.";
    
    final topSymptom = _formatSymptomName(_getTopItem(logs.expand((l) => l.symptoms).toList()) ?? 'none');
    final avgCycle = profile.avgCycleLength.round();
    
    return "Patient exhibits a cycle length of approximately $avgCycle days. Tracking data suggests $topSymptom is a recurring symptom. Sleep hygiene averages ${_getAverageSleep(logs).toStringAsFixed(1)} hours. These metrics can assist in evaluating hormonal balance and lifestyle impacts on menstrual health.";
  }
}
