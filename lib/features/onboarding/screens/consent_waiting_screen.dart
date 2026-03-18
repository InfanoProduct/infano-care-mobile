import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

class ConsentWaitingScreen extends StatefulWidget {
  const ConsentWaitingScreen({super.key});

  @override
  State<ConsentWaitingScreen> createState() => _ConsentWaitingScreenState();
}

class _ConsentWaitingScreenState extends State<ConsentWaitingScreen> {
  Timer? _pollTimer;
  int _factIndex = 0;
  int _resendCooldown = 0;

  static const _facts = [
    'Did you know? The human body has about 37 trillion cells! 🌿',
    'Girls who read regularly score higher in empathy — true story! 📚',
    'Your heart beats about 100,000 times every single day! ❤️',
    'There are more stars in the universe than grains of sand on Earth! 🌟',
  ];

  @override
  void initState() {
    super.initState();
    _startPolling();
    _rotateFacts();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      // TODO: call repository.getConsentStatus()
      // if status == 'approved' → navigate to /onboarding/terms
    });
  }

  void _rotateFacts() {
    Timer.periodic(const Duration(seconds: 5), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _factIndex = (_factIndex + 1) % _facts.length);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌱', style: TextStyle(fontSize: 80)).animate(onPlay: (c) => c.repeat())
                .slideY(begin: -0.05, end: 0.05, duration: 2000.ms, curve: Curves.easeInOut)
                .then().slideY(begin: 0.05, end: -0.05, duration: 2000.ms),
              const SizedBox(height: 32),
              Text("We've sent the note! 💌", style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Waiting for the all-clear from your parent...', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
              const SizedBox(height: 40),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  key: ValueKey(_factIndex),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(20)),
                  child: Text(_facts[_factIndex], style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                ),
              ),
              const SizedBox(height: 40),
              TextButton.icon(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.purple),
                label: const Text('Resend Email', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w600)),
                onPressed: _resendCooldown == 0 ? () {
                  setState(() => _resendCooldown = 600);
                  // TODO: call sendConsentEmail again
                } : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
