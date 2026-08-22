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
      currentStep: 11,
      totalSteps: 11,
      onBack: () => context.go('/onboarding/tracker/date'),
      bottomBar: BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
          return GradientButton(
            label: state.isLoading ? 'Setting Up...' : 'Save & Activate Tracker 🌸',
            onPressed: state.isLoading
                ? null
                : () async {
                    final bloc = context.read<OnboardingBloc>();
                    bloc.add(SetTrackerDetails(_periodLength, _cycleLength, bloc.state.lastPeriod));
                    bloc.add(const SubmitTrackerSetup('active'));

                    await for (final s in bloc.stream) {
                      if (!s.isLoading) {
                        if (s.errorMessage == null) {
                          if (mounted) context.go('/onboarding/tracker/done');
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(s.errorMessage!),
                                backgroundColor: AppColors.error,
                              ),
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
                Text(
                  'How does your cycle usually go? 🌙',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Don't worry if it varies — predictions continuously adapt as you track!",
                  style: TextStyle(color: AppColors.textMedium, fontSize: 15),
                ),
                const SizedBox(height: 28),

                if (isPeriodActive) ...[
                  Text(
                    'Is your cycle regular?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _RegularityChip(
                        label: 'Mostly Regular',
                        icon: '📅',
                        isSelected: !state.isIrregular,
                        onTap: () => context.read<OnboardingBloc>().add(const SetRegularity(false)),
                      ),
                      const SizedBox(width: 12),
                      _RegularityChip(
                        label: 'Irregular / Varies',
                        icon: '🌊',
                        isSelected: state.isIrregular,
                        onTap: () => context.read<OnboardingBloc>().add(const SetRegularity(true)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Live Visual Cycle Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Cycle Overview Preview',
                            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Text(
                            '$_cycleLength days total',
                            style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 14,
                          child: Row(
                            children: [
                              // Period days
                              Expanded(
                                flex: _periodLength,
                                child: Container(color: AppColors.pink),
                              ),
                              // Remaining cycle
                              Expanded(
                                flex: (_cycleLength - _periodLength).clamp(1, 45),
                                child: Container(color: AppColors.purple.withValues(alpha: 0.2)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.pink, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text('$_periodLength days period', style: const TextStyle(color: AppColors.textMedium, fontSize: 11.5)),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.purple.withValues(alpha: 0.4), shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text('${_cycleLength - _periodLength} days follicular/luteal', style: const TextStyle(color: AppColors.textMedium, fontSize: 11.5)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 250.ms),

                const SizedBox(height: 20),

                // Period length slider
                _SliderCard(
                  title: 'Period duration',
                  value: _periodLength.toDouble(),
                  min: 2,
                  max: 10,
                  unit: 'days',
                  color: AppColors.pink,
                  onChanged: (v) => setState(() => _periodLength = v.round()),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 16),

                // Cycle length slider
                _SliderCard(
                  title: 'Cycle duration',
                  value: _cycleLength.toDouble(),
                  min: 21,
                  max: 45,
                  unit: 'days',
                  color: AppColors.purple,
                  onChanged: (v) => setState(() => _cycleLength = v.round()),
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE9D5FF)),
                  ),
                  child: Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.isIrregular
                              ? 'Irregular cycles are very common in the first few years. We\'ll help you discover your natural rhythm!'
                              : 'Standard average: 5 days period, 28 days cycle. You can adjust anytime.',
                          style: const TextStyle(color: AppColors.textMedium, fontSize: 12.5, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 32),
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
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RegularityChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.purple : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.purple : const Color(0xFFE9D5FF),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderCard extends StatelessWidget {
  const _SliderCard({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.color,
    required this.onChanged,
  });

  final String title, unit;
  final double value, min, max;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${value.round()} $unit',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.15),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.15),
              trackHeight: 5,
            ),
            child: Slider(value: value, min: min, max: max, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}
