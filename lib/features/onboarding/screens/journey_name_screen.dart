import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/shared/widgets/gradient_button.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';

class JourneyNameScreen extends StatefulWidget {
  const JourneyNameScreen({super.key});

  @override
  State<JourneyNameScreen> createState() => _JourneyNameScreenState();
}

class _JourneyNameScreenState extends State<JourneyNameScreen> {
  final _controller = TextEditingController();
  bool _valid = false;

  static const _suggestions = ['My Bloom Journey', 'Rising Star', 'Wild Flower', 'Ocean Dreamer', 'Moonlight Path'];

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 10,
      totalSteps: 13,
      onBack: () => context.go('/onboarding/avatar'),
      bottomBar: GradientButton(
        label: 'Name My Journey ✨',
        onPressed: () async {
          final bloc = context.read<OnboardingBloc>();
          bloc.add(SetJourneyName(_controller.text.trim()));
          bloc.add(const SubmitJourneyName());

          if (mounted) {
            // Wait for sync to backend
            await bloc.stream.firstWhere((state) => !state.isLoading);
            if (mounted) context.go('/onboarding/terms');
          }
        },
        enabled: _valid,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text('Name your journey ✍️', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text('This is your personal space — give it a name that feels like you!', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                maxLength: 40,
                onChanged: (v) => setState(() => _valid = v.trim().length >= 2),
                decoration: const InputDecoration(
                  hintText: 'E.g. "My Bloom Journey"',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 20),
              Text('✨ Spark ideas:', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: _suggestions.map((s) =>
                  GestureDetector(
                    onTap: () {
                      _controller.text = s;
                      setState(() => _valid = true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(100), border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5)),
                      child: Text(s, style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ).toList(),
              ),
              const SizedBox(height: 32),
            ],
          ).animate().fadeIn(duration: 400.ms),
        ),
      ),
    );
  }
}
