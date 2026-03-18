import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌸', style: TextStyle(fontSize: 80))
                .animate(onPlay: (c) => c.repeat())
                .scaleXY(begin: 0.9, end: 1.1, duration: 2000.ms, curve: Curves.easeInOut)
                .then().scaleXY(begin: 1.1, end: 0.9, duration: 2000.ms),
              const SizedBox(height: 24),
              Text('Welcome Home!', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 12),
              Text('Your Infano.Care dashboard coming soon!',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center),
            ],
          ).animate().fadeIn(duration: 600.ms),
        ),
      ),
    );
  }
}
