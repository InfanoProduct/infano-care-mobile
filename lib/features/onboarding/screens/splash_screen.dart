import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:infano_care_mobile/shared/widgets/gradient_button.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAndRoute();
  }

  Future<void> _checkAndRoute() async {
    // Remove native splash now that Flutter is ready
    FlutterNativeSplash.remove();

    final storage = await LocalStorageService.create(); // Still fast, but ideally passed in
    await Future.delayed(const Duration(milliseconds: 400)); // Reduced from 600ms
    if (!mounted) return;
    
    // Returning user with token
    if (storage.authToken != null) {
      context.go('/home');
      return;
    }
    // New user who already started survey but hasn't registered
    // Router redirect handles the specific stage resumption
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.brandDiagonal),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🌸', style: TextStyle(fontSize: 56)),
                  ),
                ).animate().scale(begin: const Offset(0.3, 0.3), duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 32),
                Text(
                  'Infano.Care',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                const SizedBox(height: 16),
                _TaglineReveal(),
                const Spacer(flex: 2),
                GradientButton(
                  label: 'Start My Journey',
                  icon: '✨',
                  onPressed: () => context.go('/auth/phone?fromOnboarding=true'),
                ).animate().slideY(begin: 0.5, duration: 400.ms, delay: 1200.ms, curve: Curves.easeOut),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/auth/phone?fromOnboarding=false'),
                  child: const Text(
                    'Already have an account? Sign In',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ).animate().fadeIn(delay: 1400.ms),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaglineReveal extends StatelessWidget {
  final words = ['Your', 'Journey.', 'Your', 'Power.', 'Your', 'Safe', 'Space.'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 5,
      children: words.asMap().entries.map((e) =>
        Text(
          e.value,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ).animate(delay: Duration(milliseconds: 600 + e.key * 120)).fadeIn(duration: 300.ms),
      ).toList(),
    );
  }
}
