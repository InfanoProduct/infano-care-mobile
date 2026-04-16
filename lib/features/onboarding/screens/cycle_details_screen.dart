import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/shared/widgets/gradient_button.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';

class CycleDetailsScreen extends StatefulWidget {
  const CycleDetailsScreen({super.key});

  @override
  State<CycleDetailsScreen> createState() => _CycleDetailsScreenState();
}

class _CycleDetailsScreenState extends State<CycleDetailsScreen> {
  int _periodLength = 5;
  int _cycleLength  = 28;

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 13,
      totalSteps: 13,
      onBack: () => context.go('/onboarding/tracker/date'),
      bottomBar: BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
          return GradientButton(
            label: state.isLoading ? 'Setting up...' : 'Set Up My Tracker 🌸',
            onPressed: state.isLoading ? null : () async {
              final bloc = context.read<OnboardingBloc>();
              bloc.add(SetTrackerDetails(_periodLength, _cycleLength, bloc.state.lastPeriod));
              bloc.add(const SubmitTrackerSetup());

              // Wait for submission completion
              await for (final s in bloc.stream) {
                if (!s.isLoading) {
                  if (s.errorMessage == null) {
                    if (mounted) context.go('/onboarding/tracker/done');
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.errorMessage!)),
                      );
                    }
                  }
                  break;
                }
              }
            },
          );
        },
      ),
      body: BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
          final isPeriodActive = state.periodStatus == 'active';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text('How does your cycle usually go? 🌙', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text("Don't worry if you're not sure — we'll refine predictions as you track!", style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 40),
                
                if (isPeriodActive) ...[
                  Text('Is your cycle regular?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _RegularityChip(
                        label: 'Regular',
                        isSelected: !state.isIrregular,
                        onTap: () => context.read<OnboardingBloc>().add(const SetRegularity(false)),
                      ),
                      const SizedBox(width: 12),
                      _RegularityChip(
                        label: 'Irregular',
                        isSelected: state.isIrregular,
                        onTap: () => context.read<OnboardingBloc>().add(const SetRegularity(true)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],

                // Period length
                _SliderCard(
                  title: 'Period length',
                  value: _periodLength.toDouble(),
                  min: 2, max: 10,
                  unit: 'days',
                  color: const Color(0xFFF472B6),
                  onChanged: (v) => setState(() => _periodLength = v.round()),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 20),
                
                // Cycle length
                _SliderCard(
                  title: 'Cycle length',
                  value: _cycleLength.toDouble(),
                  min: 21, max: 45,
                  unit: 'days',
                  color: AppColors.purple,
                  onChanged: (v) => setState(() => _cycleLength = v.round()),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Text('📊', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(
                        state.isIrregular 
                          ? 'Irregular cycles are very common, especially in the first few years! We\'ll help you identify your unique rhythm. 💜'
                          : 'Average period: 5 days · Average cycle: 28 days. This is just a starting point.',
                        style: const TextStyle(color: AppColors.textMedium, fontSize: 13, height: 1.5),
                      )),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RegularityChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RegularityChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.purple : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppColors.purple : const Color(0xFFE9D5FF), width: 1.5),
            boxShadow: isSelected ? [BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textMedium,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderCard extends StatelessWidget {
  const _SliderCard({required this.title, required this.value, required this.min, required this.max, required this.unit, required this.color, required this.onChanged});
  final String title, unit;
  final double value, min, max;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Text('${value.round()} $unit', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.2),
              thumbColor: color,
              overlayColor: color.withOpacity(0.2),
              trackHeight: 6,
            ),
            child: Slider(value: value, min: min, max: max, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}
