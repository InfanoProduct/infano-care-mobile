import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
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
    context.go('/onboarding/tracker/date');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.brandDiagonal),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🌸', style: const TextStyle(fontSize: 100))
                  .animate(onPlay: (c) => c.repeat())
                  .scaleXY(begin: 0.9, end: 1.1, duration: 1500.ms, curve: Curves.easeInOut)
                  .then().scaleXY(begin: 1.1, end: 0.9, duration: 1500.ms),
                const SizedBox(height: 32),
                Text('You\'re in! 🎉', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white))
                  .animate(delay: 500.ms).fadeIn(duration: 500.ms).slideY(begin: 0.3, duration: 500.ms),
                const SizedBox(height: 16),
                Text('Welcome to Infano.Care, your safe space to bloom. 🌸',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500, height: 1.5))
                  .animate(delay: 900.ms).fadeIn(duration: 500.ms),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      _AchievementRow(icon: '⭐', text: 'Stage 4 complete!'),
                      _AchievementRow(icon: '🪙', text: '+15 points for your Journey Name'),
                      _AchievementRow(icon: '💜', text: 'Your avatar is ready'),
                    ],
                  ),
                ).animate(delay: 1300.ms).fadeIn(duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.icon, required this.text});
  final String icon, text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
