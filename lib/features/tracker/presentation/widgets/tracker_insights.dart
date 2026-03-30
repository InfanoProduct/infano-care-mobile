import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TrackerInsights extends StatelessWidget {
  final CycleProfileModel profile;
  final List<CycleLogModel> logs;

  const TrackerInsights({super.key, required this.profile, required this.logs});

  @override
  Widget build(BuildContext context) {
    final hasEnoughData = logs.length >= 5; // Simplified for MVP

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCycleStats(hasEnoughData),
        const SizedBox(height: 24),
        _buildMoodTrends(hasEnoughData),
        const SizedBox(height: 24),
        _buildSymptomHighlights(hasEnoughData),
        const SizedBox(height: 24),
        _buildEnergyMapping(hasEnoughData),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildCycleStats(bool hasData) {
    return _buildInsightCard(
      title: 'Cycle Statistics 📊',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Avg Cycle', '${profile.avgCycleLength} d'),
          _statItem('Variation', hasData ? '±2 d' : '--'),
          _statItem('Avg Period', '${profile.avgPeriodDuration} d'),
        ],
      ),
    );
  }

  Widget _buildMoodTrends(bool hasData) {
    if (!hasData) return _buildPlaceholderCard('Mood Trends 🎭');

    // Simple Mood Count Logic
    Map<String, int> counts = {};
    for (var l in logs) { if (l.mood != null) counts[l.mood!] = (counts[l.mood!] ?? 0) + 1; }
    
    return _buildInsightCard(
      title: 'Common Emotions 🎭',
      child: Wrap(
        spacing: 12, runSpacing: 12,
        children: counts.entries.take(4).map((e) => _moodChip(e.key, e.value)).toList(),
      ),
    );
  }

  Widget _buildSymptomHighlights(bool hasData) {
    if (!hasData) return _buildPlaceholderCard('Symptom Frequency 🌡️');

    return _buildInsightCard(
      title: 'Top Symptoms 🌡️',
      child: Column(
        children: [
          _symptomRow('Cramps', 60, Colors.red),
          const SizedBox(height: 12),
          _symptomRow('Bloating', 40, Colors.orange),
          const SizedBox(height: 12),
          _symptomRow('Headache', 25, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildEnergyMapping(bool hasData) {
    return _buildInsightCard(
      title: 'Phase Energy ⚡',
      child: hasData 
        ? Container(
            height: 120,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _bar('Menst', 0.4, Colors.red),
                _bar('Foll', 0.8, Colors.green),
                _bar('Ovul', 0.95, Colors.yellow),
                _bar('Lute', 0.6, Colors.indigo),
              ],
            ),
          )
        : const Center(child: Text('Recording patterns...', style: TextStyle(color: Colors.grey))),
    );
  }

  Widget _buildInsightCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: AppColors.purple.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textDark)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPlaceholderCard(String title) {
    return _buildInsightCard(
      title: title,
      child: Center(
        child: Text('Logging regularly to unlock insights ✨', style: GoogleFonts.nunito(color: AppColors.textLight, fontSize: 13)),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.purple)),
        Text(label, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textLight)),
      ],
    );
  }

  Widget _moodChip(String mood, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Text('$mood ($count)', style: const TextStyle(fontSize: 12, color: AppColors.purple, fontWeight: FontWeight.w600)),
    );
  }

  Widget _symptomRow(String name, double percent, Color color) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        Expanded(
          child: LinearProgressIndicator(value: percent / 100, backgroundColor: color.withOpacity(0.1), color: color, minHeight: 4, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 12),
        Text('${percent.toInt()}%', style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _bar(String label, double heightFactor, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(width: 24, height: 80 * heightFactor, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
