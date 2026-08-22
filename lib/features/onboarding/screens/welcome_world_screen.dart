import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/shared/widgets/gradient_button.dart';
import 'package:go_router/go_router.dart';

class WelcomeWorldScreen extends StatefulWidget {
  const WelcomeWorldScreen({super.key});

  @override
  State<WelcomeWorldScreen> createState() => _WelcomeWorldScreenState();
}

class _WelcomeWorldScreenState extends State<WelcomeWorldScreen> {
  @override
  void initState() {
    super.initState();
    _autoRoute();
  }

  Future<void> _autoRoute() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    _proceedNext();
  }

  Future<void> _proceedNext() async {
    final bloc = context.read<OnboardingBloc>();
    final status = bloc.state.periodStatus;

    if (status == 'active') {
      context.go('/onboarding/tracker/date');
    } else {
      bloc.add(const SubmitTrackerSetup());
      await bloc.stream.firstWhere((state) => !state.isLoading);

      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE9D5FF), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.purple.withValues(alpha: 0.12),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🎉', style: TextStyle(fontSize: 54)),
                          ),
                        ).animate().scale(begin: const Offset(0.6, 0.6), duration: 500.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 28),
                        Text(
                          'You\'re all set! 🌸',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w900,
                              ),
                        ).animate(delay: 200.ms).fadeIn(duration: 300.ms).slideY(begin: 0.2, duration: 300.ms),
                        const SizedBox(height: 12),
                        const Text(
                          'Welcome to Infano.Care — your safe, supportive space to bloom.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMedium,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ).animate(delay: 350.ms).fadeIn(duration: 300.ms),
                        const SizedBox(height: 36),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.purple.withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Column(
                            children: [
                              _SolidAchievementRow(icon: '⭐', text: 'Onboarding Profile Complete'),
                              _SolidAchievementRow(icon: '🪙', text: '+45 Bloom Points Earned'),
                              _SolidAchievementRow(icon: '💜', text: 'Personalized Care Feed Ready'),
                            ],
                          ),
                        ).animate(delay: 500.ms).fadeIn(duration: 350.ms),
                        const Spacer(),
                        GradientButton(
                          label: 'Continue My Journey ✨',
                          onPressed: _proceedNext,
                        ).animate(delay: 700.ms).fadeIn(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SolidAchievementRow extends StatelessWidget {
  const _SolidAchievementRow({required this.icon, required this.text});
  final String icon, text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(icon, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
        ],
      ),
    );
  }
}
