import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _isLoading = true;
  bool _periodPrediction = true;
  bool _dailyReminder = true;
  String _dailyReminderTime = "20:00";
  bool _symptomPatterns = true;
  bool _latePeriod = true;
  bool _streakAtRisk = true;
  bool _monthlyInsights = false;
  bool _phaseChange = false;
  bool _doctorConnect = true;
  bool _cycleMilestones = true;
  bool _globalEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final res = await ApiService.instance.dio.get('/api/v1/tracker/notification-preferences');
      final data = res.data;
      if (mounted) {
        setState(() {
          _periodPrediction = data['periodPrediction'] ?? true;
          _dailyReminder = data['dailyReminder'] ?? true;
          _dailyReminderTime = data['dailyReminderTime'] ?? "20:00";
          _symptomPatterns = data['symptomPatterns'] ?? true;
          _latePeriod = data['latePeriod'] ?? true;
          _streakAtRisk = data['streakAtRisk'] ?? true;
          _monthlyInsights = data['monthlyInsights'] ?? false;
          _phaseChange = data['phaseChange'] ?? false;
          _doctorConnect = data['doctorConnect'] ?? true;
          _cycleMilestones = data['cycleMilestones'] ?? true;
          _globalEnabled = data['globalEnabled'] ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load preferences: $e')),
        );
      }
    }
  }

  Future<void> _updatePreference(String key, dynamic value) async {
    try {
      final dataStr = {
        'periodPrediction': _periodPrediction,
        'dailyReminder': _dailyReminder,
        'dailyReminderTime': _dailyReminderTime,
        'symptomPatterns': _symptomPatterns,
        'latePeriod': _latePeriod,
        'streakAtRisk': _streakAtRisk,
        'monthlyInsights': _monthlyInsights,
        'phaseChange': _phaseChange,
        'doctorConnect': _doctorConnect,
        'cycleMilestones': _cycleMilestones,
        'globalEnabled': _globalEnabled,
        key: value,
      };
      
      // Optimistic update
      setState(() {
        if (key == 'periodPrediction') _periodPrediction = value;
        if (key == 'dailyReminder') _dailyReminder = value;
        if (key == 'dailyReminderTime') _dailyReminderTime = value;
        if (key == 'symptomPatterns') _symptomPatterns = value;
        if (key == 'latePeriod') _latePeriod = value;
        if (key == 'streakAtRisk') _streakAtRisk = value;
        if (key == 'monthlyInsights') _monthlyInsights = value;
        if (key == 'phaseChange') _phaseChange = value;
        if (key == 'doctorConnect') _doctorConnect = value;
        if (key == 'cycleMilestones') _cycleMilestones = value;
        if (key == 'globalEnabled') _globalEnabled = value;
      });

      await ApiService.instance.dio.put('/api/v1/tracker/notification-preferences', data: dataStr);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
      // Revert optimism if failed
      _loadPreferences();
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final timeParts = _dailyReminderTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(timeParts[0]) ?? 20, 
      minute: int.tryParse(timeParts[1]) ?? 0,
    );

    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.purple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newTime != null) {
      final hour = newTime.hour.toString().padLeft(2, '0');
      final minute = newTime.minute.toString().padLeft(2, '0');
      _updatePreference('dailyReminderTime', "\$hour:\$minute");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Data & Notifications', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
        : ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _buildToggleRow(
                title: 'Enable All Notifications',
                subtitle: 'Master toggle for all cycle reminders.',
                value: _globalEnabled,
                onChanged: (val) => _updatePreference('globalEnabled', val),
                isCritical: true,
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.purple.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: AppColors.purple),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All reminders are designed to feel supportive, not anxious 💜',
                        style: GoogleFonts.nunito(color: AppColors.purple, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

              _buildSectionHeader('Period Predictions'),
              _buildToggleRow(
                title: 'Period Prediction Alerts',
                subtitle: 'Notify me 3 days before my predicted period start.',
                value: _periodPrediction,
                onChanged: (val) {
                  if (!val) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Heads up: you\'ll still see predictions in the app, you just won\'t be notified 3 days before.'), duration: Duration(seconds: 4)),
                    );
                  }
                  _updatePreference('periodPrediction', val);
                },
              ),
              _buildToggleRow(
                title: 'Late Period Comfort',
                subtitle: 'Gentle check-in if your period is missing.',
                value: _latePeriod,
                onChanged: (val) => _updatePreference('latePeriod', val),
              ),

              _buildSectionHeader('Daily Logging'),
              _buildToggleRow(
                title: 'Daily Check-in Reminder',
                subtitle: 'Remind me to log my symptoms and mood.',
                value: _dailyReminder,
                onChanged: (val) => _updatePreference('dailyReminder', val),
              ),
              if (_dailyReminder)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  title: Text('Reminder Time', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  subtitle: Text('Current: $_dailyReminderTime', style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textMedium)),
                  trailing: TextButton(
                    onPressed: () => _selectTime(context),
                    child: const Text('Change', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold)),
                  ),
                ),
              _buildToggleRow(
                title: 'Streak At Risk Alert',
                subtitle: 'Save your streak before midnight.',
                value: _streakAtRisk,
                onChanged: (val) => _updatePreference('streakAtRisk', val),
              ),

              _buildSectionHeader('Insights & Patterns'),
              _buildToggleRow(
                title: 'Symptom Patterns',
                subtitle: 'Notify me when Gigi notices a recurring pattern.',
                value: _symptomPatterns,
                onChanged: (val) => _updatePreference('symptomPatterns', val),
              ),
              _buildToggleRow(
                title: 'Monthly Insights Ready',
                subtitle: 'Get notified when your monthly reflection is ready.',
                value: _monthlyInsights,
                onChanged: (val) => _updatePreference('monthlyInsights', val),
              ),

              _buildSectionHeader('Smart Alerts'),
              _buildToggleRow(
                title: 'Phase Change Reminders',
                subtitle: 'Learn about your energy and mood as your phase shifts.',
                value: _phaseChange,
                onChanged: (val) => _updatePreference('phaseChange', val),
              ),
              _buildToggleRow(
                title: 'Cycle Celebrations',
                subtitle: 'Celebrate your tracking milestones and anniversaries.',
                value: _cycleMilestones,
                onChanged: (val) => _updatePreference('cycleMilestones', val),
              ),
              _buildToggleRow(
                title: 'Healthcare Provider Prompts',
                subtitle: 'Gentle alerts for patterns worth sharing with a doctor.',
                value: _doctorConnect,
                onChanged: (val) => _updatePreference('doctorConnect', val),
              ),
              
              const SizedBox(height: 48),
            ],
          ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w900,
          color: AppColors.textLight,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool isCritical = false,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      title: Text(title, style: GoogleFonts.nunito(
        fontSize: 16, 
        fontWeight: isCritical ? FontWeight.w800 : FontWeight.w600, 
        color: isCritical ? AppColors.purple : AppColors.textDark
      )),
      subtitle: Text(subtitle, style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textMedium)),
      value: value,
      activeColor: AppColors.purple,
      onChanged: _globalEnabled || isCritical ? onChanged : null,
    );
  }
}
