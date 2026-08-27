import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/location_service.dart';
import 'package:infano_care_mobile/features/safety/data/safety_repository.dart';

class SosTestScreen extends StatefulWidget {
  const SosTestScreen({super.key});

  @override
  State<SosTestScreen> createState() => _SosTestScreenState();
}

class _SosTestScreenState extends State<SosTestScreen> {
  late final SafetyRepository _repo;
  bool _isSending = false;
  bool _testSent = false;

  @override
  void initState() {
    super.initState();
    _repo = SafetyRepository(ApiService.instance.dio);
  }

  Future<void> _sendTestAlert() async {
    setState(() => _isSending = true);
    try {
      final pos = await LocationHelperService.instance.getCurrentPosition(
        timeout: const Duration(seconds: 4),
      );
      final double lat = pos?.latitude ?? 0.0;
      final double lng = pos?.longitude ?? 0.0;

      final prefs = await _repo.getPreferences();
      await _repo.testSos(lat, lng,
          emergencyType: prefs.defaultEmergencyType);

      await _repo.savePreferences(setupCompleted: true);

      if (mounted) setState(() => _testSent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send test alert: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _completeSetup() async {
    await _repo.savePreferences(setupCompleted: true);
    if (mounted) context.go('/safety/sos');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5FF),
      appBar: AppBar(
        title: Text(
          'Step 3: Test Alert',
          style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900, color: AppColors.textDark),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.purple.withOpacity(0.1),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _testSent ? _buildSuccessState() : _buildPreTestState(),
        ),
      ),
    );
  }

  Widget _buildPreTestState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ready to test?',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w900,
            fontSize: 28,
            color: AppColors.textDark,
          ),
        ).animate().fade(duration: 300.ms).slideY(begin: 0.1),
        const SizedBox(height: 8),
        Text(
          'We will send a dummy test alert to your contacts to ensure everything works correctly.',
          style: GoogleFonts.nunito(
              fontSize: 15, color: AppColors.textMedium, height: 1.5),
        ).animate().fade(delay: 100.ms, duration: 300.ms),
        const SizedBox(height: 32),

        _buildCheckItem('👥', 'Trusted Contacts Added', 'Your protective circle is ready')
            .animate().fade(delay: 200.ms).slideX(begin: 0.05),
        const SizedBox(height: 14),
        _buildCheckItem('✅', 'Emergency Category Configured', 'Your default crisis setting is mapped')
            .animate().fade(delay: 300.ms).slideX(begin: 0.05),
        const SizedBox(height: 14),
        _buildCheckItem('⏳', 'Establish Test Link', 'Pending connection test')
            .animate().fade(delay: 400.ms).slideX(begin: 0.05),

        const SizedBox(height: 24),

        // Alert explanation box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'The test message clearly states "[TEST]" so they won\'t worry. It helps verify your settings.',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: Colors.orange.shade800,
                    height: 1.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fade(delay: 500.ms),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSending ? null : _sendTestAlert,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            child: _isSending
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5)),
                      const SizedBox(width: 12),
                      const Text('Sending test...'),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Send Test Alert',
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.send_rounded, size: 18),
                    ],
                  ),
          ),
        ).animate().fade(delay: 550.ms),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _completeSetup,
            child: Text(
              'Skip & Go to Hub',
              style: GoogleFonts.nunito(
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ),
        ).animate().fade(delay: 600.ms),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const Spacer(),
        // Party pop animation
        const Text('🎉', style: TextStyle(fontSize: 72))
            .animate()
            .scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        Text(
          'Verification Sent!',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w900,
            fontSize: 28,
            color: AppColors.textDark,
          ),
        ).animate().fade(duration: 300.ms),
        const SizedBox(height: 12),
        Text(
          'Your contacts have received the test alert.\n\nYour Safety Hub is fully active! 🛡️',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 15,
            color: AppColors.textMedium,
            height: 1.5,
          ),
        ).animate().fade(delay: 150.ms),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => context.go('/safety/sos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Go to My Safety Hub',
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.shield_outlined, size: 20),
              ],
            ),
          ),
        ).animate().fade(delay: 350.ms),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCheckItem(String icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Text(icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                      fontSize: 13, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
