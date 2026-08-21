import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';

class ConsentWaitingScreen extends StatefulWidget {
  const ConsentWaitingScreen({super.key});

  @override
  State<ConsentWaitingScreen> createState() => _ConsentWaitingScreenState();
}

class _ConsentWaitingScreenState extends State<ConsentWaitingScreen> {
  Timer? _pollTimer;
  int _factIndex = 0;
  int _resendCooldown = 0;

  static const _facts = [
    'Did you know? The human body has about 37 trillion cells! 🌿',
    'Girls who read regularly score higher in empathy — true story! 📚',
    'Your heart beats about 100,000 times every single day! ❤️',
    'There are more stars in the universe than grains of sand on Earth! 🌟',
  ];

  @override
  void initState() {
    super.initState();
    _startPolling();
    _rotateFacts();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        context.read<OnboardingBloc>().add(const CheckConsentStatus());
      }
    });
  }

  void _rotateFacts() {
    Timer.periodic(const Duration(seconds: 5), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _factIndex = (_factIndex + 1) % _facts.length);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE9D5FF), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🌱', style: TextStyle(fontSize: 48)),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 1500.ms, curve: Curves.easeInOut),
              const SizedBox(height: 32),
              Text(
                "We've sent the note! 💌",
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Waiting for approval from your parent or guardian...',
                style: TextStyle(color: AppColors.textMedium, fontSize: 15, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Container(
                  key: ValueKey(_factIndex),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lightbulb_outline_rounded, color: AppColors.purple, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Fun Fact While You Wait',
                            style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _facts[_factIndex],
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.purple,
                  side: const BorderSide(color: Color(0xFFE9D5FF), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: AppColors.surface,
                ),
                icon: const Icon(Icons.refresh_rounded, color: AppColors.purple, size: 18),
                label: const Text(
                  'Resend Email',
                  style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w700),
                ),
                onPressed: _resendCooldown == 0 ? () {
                  final parentEmail = context.read<OnboardingBloc>().state.parentEmail;
                  if (parentEmail != null) {
                    context.read<OnboardingBloc>().add(SendConsentEmail(parentEmail));
                    setState(() => _resendCooldown = 60);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Verification email resent!'),
                        backgroundColor: AppColors.purple,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                } : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
