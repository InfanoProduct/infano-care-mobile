import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';
import 'package:infano_care_mobile/shared/widgets/points_burst.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';

class PeriodComfortScreen extends StatefulWidget {
  const PeriodComfortScreen({super.key});

  @override
  State<PeriodComfortScreen> createState() => _PeriodComfortScreenState();
}

class _PeriodComfortScreenState extends State<PeriodComfortScreen> {
  int? _selected;
  bool _showPoints = false;

  static const _scale = [
    ('😬', 'Umm... pretty\nembarrassed'),
    ('😕', 'A little\nuncomfortable'),
    ('😐', "It's okay,\nI guess"),
    ('🙂', 'Pretty\ncomfortable'),
    ('😄', 'Totally fine,\nlet\'s talk!'),
  ];

  static const _responses = [
    "That's totally okay — many girls feel the same way!\nWe'll go at your pace 💜",
    "Completely normal. We'll take it step by step 💜",
    "Good starting point! You're already here 🌸",
    "Love that comfort level! You're doing great 💜",
    "Amazing openness! You'll thrive here 🌟",
  ];

  void _select(int i) {
    context.read<OnboardingBloc>().add(SetPeriodComfort(i + 1));
    setState(() { _selected = i; _showPoints = true; });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) context.go('/onboarding/period-status');
    });
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 6,
      totalSteps: 13,
      bottomBar: _selected != null ? PointsBurst(points: 10, onComplete: () => setState(() => _showPoints = false)) : null,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text('How do you feel about talking about periods?', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text("Be honest — we don't judge! 😊", style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 48),
            // Emoji scale
            Row(
              children: _scale.asMap().entries.map((e) {
                final isSelected = _selected == e.key;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _select(e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.identity()..scale(isSelected ? 1.35 : 1.0),
                      transformAlignment: Alignment.center,
                      child: Column(
                        children: [
                          Text(e.value.$1, style: TextStyle(fontSize: isSelected ? 38 : 28)),
                          const SizedBox(height: 6),
                          Text(e.value.$2, textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, color: isSelected ? AppColors.purple : AppColors.textLight, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            // Connecting line
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _selected != null ? (_selected! + 1) / 5 : 0,
                  backgroundColor: AppColors.surfaceCard,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
                  minHeight: 4,
                ),
              ),
            ),
            if (_selected != null) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(20)),
                child: Text(_responses[_selected!],
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w600, height: 1.5)),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, duration: 300.ms),
            ],
            TextButton(
              onPressed: () => context.go('/onboarding/period-status'),
              child: const Text('Skip for now', style: TextStyle(color: AppColors.textLight)),
            ),
          ],
        ),
      ),
    );
  }
}
