import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:infano_care_mobile/features/tracker/data/repositories/tracker_repository.dart';
import 'package:infano_care_mobile/core/services/privacy_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class CycleSettingsScreen extends StatefulWidget {
  const CycleSettingsScreen({super.key});

  @override
  State<CycleSettingsScreen> createState() => _CycleSettingsScreenState();
}

class _CycleSettingsScreenState extends State<CycleSettingsScreen> {
  late TrackerRepository _repository;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  DateTime? _lastPeriodStart;
  int _avgCycleLength = 28;
  int _avgPeriodDuration = 5;

  @override
  void initState() {
    super.initState();
    _repository = TrackerRepository(
      ApiService.instance.dio,
      PrivacyService(const FlutterSecureStorage()),
    );
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _repository.getProfile();
    if (profile != null) {
      setState(() {
        _lastPeriodStart = profile.lastPeriodStart;
        _avgCycleLength = profile.avgCycleLength > 0 ? profile.avgCycleLength : 28;
        _avgPeriodDuration = profile.avgPeriodDuration > 0 ? profile.avgPeriodDuration : 5;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = "Failed to load cycle profile";
      });
    }
  }

  Future<void> _save() async {
    if (_lastPeriodStart == null) return;
    
    setState(() => _isSaving = true);
    try {
      await _repository.setupTracker({
        'lastPeriodStart': _lastPeriodStart!.toIso8601String(),
        'cycleLengthDays': _avgCycleLength,
        'periodLengthDays': _avgPeriodDuration,
        'trackerMode': 'active', 
      });
      if (mounted) {
        // If we came from the milestone screen or setup, go back to home dashboard
        context.go('/home');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF130F26),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Cycle Settings', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.purpleLight))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Baseline Data', 'Update your average cycle details to improve prediction accuracy.'),
                const SizedBox(height: 32),
                
                _buildDateTile(),
                const SizedBox(height: 24),
                
                _buildSliderCard(
                  title: 'Average Cycle Length',
                  value: _avgCycleLength.toDouble(),
                  min: 21, max: 45,
                  unit: 'days',
                  color: AppColors.purple,
                  onChanged: (v) => setState(() => _avgCycleLength = v.round()),
                ),
                const SizedBox(height: 20),
                
                _buildSliderCard(
                  title: 'Average Period Duration',
                  value: _avgPeriodDuration.toDouble(),
                  min: 2, max: 10,
                  unit: 'days',
                  color: const Color(0xFFF472B6),
                  onChanged: (v) => setState(() => _avgPeriodDuration = v.round()),
                ),
                
                if (_error != null) ...[
                  const SizedBox(height: 20),
                  Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ],
                
                const SizedBox(height: 48),
                _buildSaveButton(),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 8),
        Text(subtitle, style: GoogleFonts.nunito(fontSize: 15, color: Colors.white70, height: 1.5)),
      ],
    );
  }

  Widget _buildDateTile() {
    final dateStr = _lastPeriodStart != null 
        ? "${_lastPeriodStart!.day} ${_months[_lastPeriodStart!.month - 1]} ${_lastPeriodStart!.year}"
        : "Select Date";

    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: _lastPeriodStart ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 90)),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.purple,
                  onPrimary: Colors.white,
                  surface: Color(0xFF1A132C),
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (d != null) setState(() => _lastPeriodStart = d);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.purpleLight),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Last Period Start', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(dateStr, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.edit_calendar_rounded, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderCard({
    required String title,
    required double value,
    required double min,
    required double max,
    required String unit,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text('${value.round()} $unit', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.1),
              thumbColor: color,
              overlayColor: color.withOpacity(0.2),
              trackHeight: 6,
            ),
            child: Slider(value: value, min: min, max: max, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isSaving 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
}
