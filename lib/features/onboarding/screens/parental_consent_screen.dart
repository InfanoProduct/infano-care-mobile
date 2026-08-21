import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:infano_care_mobile/shared/widgets/gradient_button.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';

class ParentalConsentScreen extends StatefulWidget {
  const ParentalConsentScreen({super.key});

  @override
  State<ParentalConsentScreen> createState() => _ParentalConsentScreenState();
}

class _ParentalConsentScreenState extends State<ParentalConsentScreen> {
  final _emailController = TextEditingController();
  String? _error;

  bool get _validEmail {
    final email = _emailController.text.trim();
    return RegExp(r'^[\w\.\-]+@[\w\-]+\.\w+$').hasMatch(email);
  }

  Future<void> _sendNote() async {
    setState(() { _error = null; });
    try {
      final email = _emailController.text.trim();
      context.read<OnboardingBloc>().add(SendConsentEmail(email));
      
      if (!mounted) return;
      context.go('/onboarding/consent/waiting');
    } catch (e) {
      setState(() { _error = 'Failed to send email. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 4,
      totalSteps: 11,
      onBack: () => context.go('/onboarding/birthday'),
      bottomBar: GradientButton(
        label: 'Send Approval Note 💌',
        onPressed: _sendNote,
        enabled: _validEmail,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
                ),
                child: const Center(
                  child: Text('🛡️', style: TextStyle(fontSize: 32)),
                ),
              ).animate().scale(duration: 300.ms),
              const SizedBox(height: 20),
              Text(
                'One quick approval!',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Because you're under 13, privacy laws (COPPA) require a quick parent or guardian approval so you can safely use the app.",
                style: TextStyle(color: AppColors.textMedium, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: "Parent or Guardian's email",
                    hintStyle: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.normal),
                    prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.purple),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE9D5FF), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE9D5FF), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.purple, width: 2),
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "We'll send them a one-click approval link — no spam or ads, guaranteed.",
                        style: TextStyle(color: AppColors.textMedium, fontSize: 13, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(duration: 350.ms),
        ),
      ),
    );
  }
}
