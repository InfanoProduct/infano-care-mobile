import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';

class PeriodExperienceScreen extends StatefulWidget {
  const PeriodExperienceScreen({super.key});

  @override
  State<PeriodExperienceScreen> createState() => _PeriodExperienceScreenState();
}

class _PeriodExperienceScreenState extends State<PeriodExperienceScreen> {
  static const _options = [
    ('active',  '🌸', "Yes, I have!",              "Great! Let's set up your tracker."),
    ('waiting', '🌱', "Not yet, but I'm curious!", "Totally normal — you're right where you should be. 🌱"),
    ('unsure',  '🤔', "I'm not sure...",           "That's okay too! We'll help you figure it out. 💜"),
  ];

  void _select(String status, String message) {
    context.read<OnboardingBloc>().add(SetPeriodStatus(status));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.purple, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      context.go('/onboarding/interests');
    });
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 7,
      totalSteps: 13,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text('Have you had your first period yet?', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text("No rush — everyone's timeline is different 🌱", style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 40),
            ..._options.asMap().entries.map((e) {
              final o = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () => _select(o.$1, o.$4),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Text(o.$2, style: const TextStyle(fontSize: 36)),
                        const SizedBox(width: 16),
                        Expanded(child: Text(o.$3,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.textDark))),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textLight),
                      ],
                    ),
                  ),
                ).animate(delay: Duration(milliseconds: e.key * 100)).fadeIn(duration: 300.ms).slideX(begin: 0.1, duration: 300.ms),
              );
            }),
          ],
        ),
      ),
    );
  }
}
