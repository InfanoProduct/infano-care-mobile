import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({super.key, required this.phone});
  final String phone;

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  String _otp = '';
  bool _loading = false;
  String? _error;
  int _countdown = 60;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _countdown = (_countdown - 1).clamp(0, 60));
      return _countdown > 0;
    });
  }

  Future<void> _verify() async {
    if (_otp.length < 6) return;
    setState(() { _loading = true; _error = null; });
    try {
      // TODO: call repo via BLoC, get tempToken + isNewUser
      // For now navigate to onboarding path
      if (mounted) context.go('/onboarding/path');
    } catch (e) {
      setState(() { _error = 'Invalid OTP. Please try again.'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maskedPhone = widget.phone.length > 6
      ? '${widget.phone.substring(0, widget.phone.length - 6)}XXXXXX'
      : widget.phone;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text('Enter your code 🔐',
                style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text('We sent a 6-digit code to $maskedPhone',
                style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 48),
              // OTP boxes
              PinCodeTextField(
                appContext: context,
                length: 6,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 46,
                  activeFillColor: AppColors.surfaceCard,
                  inactiveFillColor: AppColors.surfaceCard,
                  selectedFillColor: Colors.white,
                  activeColor: AppColors.purple,
                  inactiveColor: const Color(0xFFE9D5FF),
                  selectedColor: AppColors.purple,
                ),
                enableActiveFill: true,
                keyboardType: TextInputType.number,
                onChanged: (v) => setState(() => _otp = v),
                onCompleted: (_) => _verify(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              // Resend
              Center(
                child: _countdown > 0
                  ? Text('Resend code in ${_countdown}s',
                      style: const TextStyle(color: AppColors.textLight))
                  : TextButton(
                      onPressed: () {
                        setState(() => _countdown = 60);
                        _startCooldown();
                        // TODO: call sendOtp again
                      },
                      child: const Text('Resend OTP', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w700)),
                    ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _otp.length == 6 && !_loading ? _verify : null,
                child: AnimatedOpacity(
                  opacity: _otp.length == 6 ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppGradients.brand,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Center(
                      child: _loading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('Verify & Continue ✨',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ).animate().fadeIn(duration: 400.ms),
        ),
      ),
    );
  }
}
