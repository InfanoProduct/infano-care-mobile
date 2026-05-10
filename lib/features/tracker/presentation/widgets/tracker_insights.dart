import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class TrackerInsights extends StatelessWidget {
  final CycleProfileModel profile;
  final List<CycleLogModel> logs;
  final List<CycleRecordModel> history;

  const TrackerInsights({
    super.key, 
    required this.profile, 
    required this.logs,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final hasEnoughData = logs.length >= 3; // Reduced for testing

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDoctorBanner(context),
        const SizedBox(height: 24),
        _buildGigiAnalysis(),
        const SizedBox(height: 24),
        _buildCycleStats(hasEnoughData),
        const SizedBox(height: 24),
        _buildMoodTrends(hasEnoughData),
        const SizedBox(height: 24),
        _buildSymptomHighlights(hasEnoughData),
        const SizedBox(height: 24),
        _buildSleepAnalysis(hasEnoughData),
        const SizedBox(height: 24),
        _buildDischargeTracking(hasEnoughData),
        const SizedBox(height: 24),
        _buildLifestylePatterns(hasEnoughData),
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
          _statItem('Avg Cycle', '${profile.avgCycleLength.toInt()} d'),
          _statItem('Variation', hasData ? '±2 d' : '--'),
          _statItem('Avg Period', '${profile.avgPeriodDuration.toInt()} d'),
        ],
      ),
    );
  }

  Widget _buildMoodTrends(bool hasData) {
    if (!hasData) return _buildPlaceholderCard('Mood Trends 🎭');

    // Simple Mood Count Logic
    Map<String, int> counts = {};
    for (var l in logs) { 
      if (l.moodPrimary != null) {
        counts[l.moodPrimary!] = (counts[l.moodPrimary!] ?? 0) + 1;
      } 
    }
    
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

    // Aggregate Symptoms
    Map<String, int> counts = {};
    for (var l in logs) {
      for (var s in l.symptoms) {
        counts[s] = (counts[s] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) return _buildPlaceholderCard('Symptom Frequency 🌡️');

    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topSymptoms = sorted.take(4).toList();

    return _buildInsightCard(
      title: 'Top Symptoms 🌡️',
      child: Column(
        children: topSymptoms.map((e) {
          final percent = (e.value / logs.length) * 100;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _symptomRow(_formatSymptomName(e.key), percent, _getSymptomColor(e.key)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEnergyMapping(bool hasData) {
    if (!hasData) return _buildPlaceholderCard('Phase Energy ⚡');

    // Map energy levels to phases
    Map<String, List<int>> phaseEnergyMap = {
      'menstrual': [],
      'follicular': [],
      'ovulation': [],
      'luteal': [],
    };

    for (var log in logs) {
      if (log.energyLevel == null) continue;
      final phase = _getPhaseForDate(log.date);
      if (phase != null && phaseEnergyMap.containsKey(phase)) {
        phaseEnergyMap[phase]!.add(log.energyLevel!);
      }
    }

    // Calculate averages (1-5 scale)
    Map<String, double> phaseAverages = {};
    phaseEnergyMap.forEach((phase, levels) {
      if (levels.isEmpty) {
        phaseAverages[phase] = 0.5; // Default middle-low if no data
      } else {
        phaseAverages[phase] = levels.reduce((a, b) => a + b) / (levels.length * 5.0);
      }
    });

    return _buildInsightCard(
      title: 'Phase Energy ⚡',
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _bar('Menst', phaseAverages['menstrual']!, const Color(0xFFC026D3)),
            _bar('Foll', phaseAverages['follicular']!, const Color(0xFFFDE047)),
            _bar('Ovul', phaseAverages['ovulation']!, const Color(0xFF2563EB)),
            _bar('Lute', phaseAverages['luteal']!, const Color(0xFF7DD3FC)),
          ],
        ),
      ),
    );
  }

  String? _getPhaseForDate(DateTime date) {
    // 1. Check current cycle
    if (profile.lastPeriodStart != null) {
      final start = profile.lastPeriodStart!;
      if (date.isAfter(start) || DateUtils.isSameDay(date, start)) {
        final day = date.difference(start).inDays + 1;
        return _calculatePhase(day, profile.avgCycleLength);
      }
    }

    // 2. Check history
    for (var record in history) {
      if (date.isAfter(record.startDate) || DateUtils.isSameDay(date, record.startDate)) {
        if (record.endDate == null || date.isBefore(record.endDate!) || DateUtils.isSameDay(date, record.endDate!)) {
          final day = date.difference(record.startDate).inDays + 1;
          return _calculatePhase(day, record.cycleLengthDays ?? 28);
        }
      }
    }
    return null;
  }

  String _calculatePhase(int day, int avgLength) {
    if (day <= 5) return 'menstrual';
    if (day <= avgLength * 0.45) return 'follicular';
    if (day <= avgLength * 0.55) return 'ovulation';
    if (day <= avgLength) return 'luteal';
    return 'luteal';
  }

  String _formatSymptomName(String id) {
    return id.replaceAll('_', ' ').split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '').join(' ');
  }

  Color _getSymptomColor(String id) {
    switch (id) {
      case 'cramps': return Colors.red;
      case 'headache': return Colors.blue;
      case 'bloating': return Colors.orange;
      case 'acne': return Colors.pink;
      case 'fatigue': return Colors.purple;
      default: return AppColors.purple;
    }
  }

  Widget _buildDoctorBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.purple,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AppColors.purple.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🩺', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Share with your doctor?',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 16),
                ),
              ),
              const Icon(Icons.star, color: Colors.amber, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Generate a clinical summary of your last 3 cycles for your next appointment.',
            style: GoogleFonts.nunito(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/tracker/doctor-summary'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.purple,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Preview Report ✨'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.05)),
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
      decoration: BoxDecoration(color: AppColors.purple.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
      child: Text('$mood ($count)', style: const TextStyle(fontSize: 12, color: AppColors.purple, fontWeight: FontWeight.w600)),
    );
  }

  Widget _symptomRow(String name, double percent, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          flex: 3,
          child: LinearProgressIndicator(
            value: percent / 100, 
            backgroundColor: color.withValues(alpha: 0.1), 
            color: color, 
            minHeight: 6, 
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 35,
          child: Text('${percent.toInt()}%', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildGigiAnalysis() {
    if (logs.length < 3) return const SizedBox.shrink();

    // Determine a pattern
    final topSymptom = _getTopItem(logs.expand((l) => l.symptoms).toList());
    final topMood = _getTopItem(logs.map((l) => l.moodPrimary).whereType<String>().toList());
    
    String analysis = "Your body is showing a consistent pattern. ";
    if (topSymptom != null) {
      analysis += "You often experience ${_formatSymptomName(topSymptom)}, which is quite common in your current phase. ";
    }
    if (topMood != null) {
      analysis += "Emotionally, you've been feeling $topMood recently. ";
    }
    
    analysis += "Your energy tends to peak during Ovulation—perfect for high-impact activities! 🌸";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF4FF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.pink.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Text(
                'Gigi\'s Quick Analysis',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            analysis,
            style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textMedium, height: 1.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepAnalysis(bool hasData) {
    if (!hasData) return _buildPlaceholderCard('Sleep Patterns 😴');

    final validLogs = logs.where((l) => l.sleepHours != null).toList();
    if (validLogs.isEmpty) return _buildPlaceholderCard('Sleep Patterns 😴');

    final avgSleep = validLogs.fold(0.0, (sum, l) => sum + l.sleepHours!) / validLogs.length;
    final avgQuality = validLogs.fold(0, (sum, l) => sum + (l.sleepQuality ?? 0)) / validLogs.length;

    return _buildInsightCard(
      title: 'Sleep Patterns 😴',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Avg Sleep', '${avgSleep.toStringAsFixed(1)}h'),
              _statItem('Quality', '${avgQuality.toStringAsFixed(1)}/5'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            avgQuality >= 4 ? 'You\'re getting high-quality rest! Keep it up. ✨' : 'Your rest seems a bit interrupted. Try a wind-down routine. 🌙',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMedium, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDischargeTracking(bool hasData) {
    if (!hasData) return _buildPlaceholderCard('Fluid Tracking 💧');

    Map<String, int> counts = {};
    for (var l in logs) {
      if (l.vaginalDischarge != null) {
        counts[l.vaginalDischarge!] = (counts[l.vaginalDischarge!] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) return _buildPlaceholderCard('Fluid Tracking 💧');

    return _buildInsightCard(
      title: 'Fluid Tracking 💧',
      child: Column(
        children: counts.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _symptomRow(e.key, (e.value / logs.length) * 100, AppColors.purpleLight),
        )).toList(),
      ),
    );
  }

  Widget _buildLifestylePatterns(bool hasData) {
    if (!hasData) return _buildPlaceholderCard('Lifestyle & Nutrition 🥗');

    final topNutrition = _getTopItem(logs.expand((l) => l.nutritionTags).toList());
    final topActivity = _getTopItem(logs.expand((l) => l.activityTags).toList());

    return _buildInsightCard(
      title: 'Lifestyle & Nutrition 🥗',
      child: Row(
        children: [
          Expanded(child: _lifestyleItem('Main Fuel', topNutrition ?? 'Healthy', '🥗')),
          Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.1)),
          Expanded(child: _lifestyleItem('Main Move', topActivity ?? 'Walking', '👟')),
        ],
      ),
    );
  }

  Widget _lifestyleItem(String label, String value, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textDark)),
        Text(label, style: GoogleFonts.nunito(fontSize: 10, color: AppColors.textLight)),
      ],
    );
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
