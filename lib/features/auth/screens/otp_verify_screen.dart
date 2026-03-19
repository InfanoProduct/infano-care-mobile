import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/features/auth/repository/auth_repository.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';

class OtpVerifyScreen extends StatefulWidget {
  OtpVerifyScreen({
    super.key,
    required this.phone,
    required this.storage,
    this.fromOnboarding = false,
  });
  final String phone;
  final LocalStorageService storage;
  final bool fromOnboarding;

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  String _otp = '';
  bool _loading = false;
  String? _error;
  int _countdown = 60;

  late final AuthRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = AuthRepository(widget.storage);
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
    if (_otp.length < 4) return;
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _repo.verifyOtp(widget.phone, _otp);

      if (!mounted) return;

      if (widget.fromOnboarding) {
        final bloc = context.read<OnboardingBloc>();
        bloc.add(SubmitRegistration(result.tempToken));

        await for (final state in bloc.stream) {
          if (!state.isLoading) {
            if (state.errorMessage != null) {
              if (mounted) setState(() => _error = state.errorMessage);
            } else {
              if (mounted) context.go('/onboarding/welcome');
            }
            break;
          }
        }
      } else {
        if (result.isNewUser) {
          context.go('/onboarding/path');
        } else {
          await _repo.login(result.tempToken);
          if (mounted) context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() { _countdown = 60; _error = null; });
    _startCooldown();
    try {
      await _repo.sendOtp(widget.phone);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fromOnboarding) {
      return OnboardingScaffold(
        currentStep: 12,
        body: _buildBody(context),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final maskedPhone = widget.phone.length > 6
      ? '${widget.phone.substring(0, widget.phone.length - 6)}XXXXXX' : widget.phone;

    return BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              if (!widget.fromOnboarding)
                GestureDetector(
                  onTap: () => context.go('/auth/phone'),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textDark),
                  ),
                ),
              const SizedBox(height: 32),
              Text('Enter your code 🔐', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text('We sent a 4-digit code to $maskedPhone', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 48),
              PinCodeTextField(
                appContext: context,
                length: 4,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box, borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56, fieldWidth: 46,
                  activeFillColor: AppColors.surfaceCard, inactiveFillColor: AppColors.surfaceCard,
                  selectedFillColor: Colors.white, activeColor: AppColors.purple,
                  inactiveColor: const Color(0xFFE9D5FF), selectedColor: AppColors.purple,
                ),
                enableActiveFill: true,
                keyboardType: TextInputType.number,
                onChanged: (v) => setState(() => _otp = v),
                onCompleted: (_) => _verify(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                if (state.sessionExpired) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => context.go('/auth/phone'),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Verify Phone Again'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.purple),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              Center(
                child: _countdown > 0
                  ? Text('Resend code in ${_countdown}s', style: const TextStyle(color: AppColors.textLight))
                  : TextButton(onPressed: _resendOtp, child: const Text('Resend OTP', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w700))),
              ),
              const SizedBox(height: 60),
              GestureDetector(
                onTap: _otp.length == 4 && !_loading && !state.sessionExpired ? _verify : null,
                child: AnimatedOpacity(
                  opacity: (_otp.length == 4 && !state.sessionExpired) ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(gradient: AppGradients.brand, borderRadius: BorderRadius.circular(100)),
                    child: Center(
                      child: _loading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('Verify & Continue ✨', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ).animate().fadeIn(duration: 400.ms),
        ),
      );
    });
  }
}
