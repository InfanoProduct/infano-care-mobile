import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';

class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _controller = TextEditingController();
  String _countryCode = '+91';
  bool _loading = false;
  String? _error;

  bool get _valid => _controller.text.length >= 10;

  Future<void> _sendOtp() async {
    setState(() { _loading = true; _error = null; });
    try {
      final phone = '$_countryCode${_controller.text.trim()}';
      // TODO: call OnboardingRepository.sendOtp via BLoC
      if (mounted) context.go('/auth/otp?phone=${Uri.encodeComponent(phone)}');
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text('What\'s your number? 📱',
                style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text('We\'ll send you a 6-digit code to verify. No password needed!',
                style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 40),
              // Phone input
              Row(
                children: [
                  // Country code pill
                  GestureDetector(
                    onTap: () => _showCountryPicker(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
                      ),
                      child: Text('$_countryCode 🔽',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textDark)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.phone,
                      maxLength: 12,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: '98765 43210',
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const Spacer(),
              // Send OTP button
              AnimatedOpacity(
                opacity: _valid ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _valid && !_loading ? _sendOtp : null,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: _valid ? AppGradients.brand : null,
                      color: _valid ? null : AppColors.textLight,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Center(
                      child: _loading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('Send OTP 📲',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, duration: 400.ms),
        ),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['+91 🇮🇳 India', '+1 🇺🇸 USA', '+44 🇬🇧 UK', '+61 🇦🇺 Australia'].map((c) =>
            ListTile(
              title: Text(c, style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                setState(() => _countryCode = c.split(' ').first);
                Navigator.pop(context);
              },
            ),
          ).toList(),
        ),
      ),
    );
  }
}
