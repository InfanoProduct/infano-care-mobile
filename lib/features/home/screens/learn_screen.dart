import 'package:flutter/material.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📚', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              Text('Learn Content', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 12),
              Text('Discover and Grow', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
