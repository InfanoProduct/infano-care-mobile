import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/shared/widgets/gradient_button.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';

class LastPeriodDateScreen extends StatefulWidget {
  const LastPeriodDateScreen({super.key});

  @override
  State<LastPeriodDateScreen> createState() => _LastPeriodDateScreenState();
}

class _LastPeriodDateScreenState extends State<LastPeriodDateScreen> {
  DateTime? _selected = DateTime.now();
  bool _dontRemember = false;

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 10,
      totalSteps: 11,
      onBack: () => context.go('/onboarding/terms'),
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GradientButton(
            label: 'Continue',
            onPressed: () {
              final bloc = context.read<OnboardingBloc>();
              bloc.add(SetTrackerDetails(bloc.state.periodLength, bloc.state.cycleLength, _selected));
              context.go('/onboarding/tracker/details');
            },
            enabled: _selected != null || _dontRemember,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              final bloc = context.read<OnboardingBloc>();
              bloc.add(const SkipTracker());
              await bloc.stream.firstWhere((state) => !state.isLoading);
              if (!context.mounted) return;
              context.go('/home');
            },
            child: const Text(
              "I'll do this later",
              style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'When was your last period? 📅',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select the start date so we can generate accurate cycle estimates.',
                style: TextStyle(color: AppColors.textMedium, fontSize: 15),
              ),
              const SizedBox(height: 24),
              // Calendar picker card
              Container(
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.purple,
                        onPrimary: Colors.white,
                        surface: AppColors.surface,
                      ),
                    ),
                    child: CalendarDatePicker(
                      initialDate: _selected ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 90)),
                      lastDate: DateTime.now(),
                      onDateChanged: (d) => setState(() { _selected = d; _dontRemember = false; }),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() {
                  _dontRemember = !_dontRemember;
                  if (_dontRemember) _selected = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _dontRemember ? AppColors.purple : const Color(0xFFE9D5FF),
                      width: _dontRemember ? 2 : 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _dontRemember ? AppColors.purple : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _dontRemember ? AppColors.purple : const Color(0xFFD8B4FE),
                            width: 1.5,
                          ),
                        ),
                        child: _dontRemember
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "I don't remember — estimate standard 28-day cycle",
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ).animate().fadeIn(duration: 350.ms),
        ),
      ),
    );
  }
}
