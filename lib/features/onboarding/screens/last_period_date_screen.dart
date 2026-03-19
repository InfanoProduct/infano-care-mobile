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
  DateTime? _selected;
  bool _dontRemember = false;

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 14,
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GradientButton(
            label: 'Continue',
            onPressed: () {
              final bloc = context.read<OnboardingBloc>();
              // Sync date with bloc state, keeping period/cycle defaults
              bloc.add(SetTrackerDetails(bloc.state.periodLength, bloc.state.cycleLength, _selected));
              context.go('/onboarding/tracker/details');
            },
            enabled: _selected != null || _dontRemember,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text("I'll do this later", style: TextStyle(color: AppColors.textLight)),
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
              Text('When did your last period start? 📅', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text("This helps us give you accurate predictions right away!", style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              // Calendar picker
              Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(primary: AppColors.purple),
                ),
                child: CalendarDatePicker(
                  initialDate: _selected ?? DateTime.now().subtract(const Duration(days: 14)),
                  firstDate: DateTime.now().subtract(const Duration(days: 90)),
                  lastDate: DateTime.now(),
                  onDateChanged: (d) => setState(() { _selected = d; _dontRemember = false; }),
                ),
              ),
              const Divider(color: Color(0xFFE9D5FF)),
              CheckboxListTile(
                value: _dontRemember,
                onChanged: (v) => setState(() { _dontRemember = v ?? false; if (v == true) _selected = null; }),
                activeColor: AppColors.purple,
                contentPadding: EdgeInsets.zero,
                title: const Text("I don't remember — estimate for me", style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(height: 24),
            ],
          ).animate().fadeIn(duration: 400.ms),
        ),
      ),
    );
  }
}
