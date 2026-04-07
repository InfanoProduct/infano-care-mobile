import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:infano_care_mobile/shared/widgets/gradient_button.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('[LandingScreen] initState reached ✅');
    
    // 1. Remove native splash as soon as we start our own loading
    FlutterNativeSplash.remove();
    
    // 2. Start bootstrapping ONLY if necessary.
    // If we're already authenticated and onboarded, the router will soon move us to /home.
    // We can skip the blocking bootstrap and let Dashboard handle background sync.
    final storage = context.read<LocalStorageService>();
    if (storage.authToken != null && storage.isOnboarded) {
      debugPrint('[LandingScreen] Fast-track: Skipper server bootstrap for onboarded user.');
    } else {
      context.read<OnboardingBloc>().add(const BootstrapApp());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        // If we are currently fetching user data from server
        if (state.isBootstrapping) {
          return const Scaffold(
            backgroundColor: Color(0xFF6D28D9),
            body: Center(
              child: CircularProgressIndicator(color: Colors.white70),
            ),
          );
        }

        final storage = context.read<LocalStorageService>();
        final step = storage.stepComplete;
        final isResuming = (step != null && int.parse(step) >= 1) || storage.authToken != null;
        final userName = state.displayName.isNotEmpty ? state.displayName : storage.displayName;

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
                    _LogoWheel(),
                    const SizedBox(height: 32),
                    Text(
                      'Infano.Care',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white),
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                    const SizedBox(height: 16),
                    if (isResuming) ...[
                      Text(
                        'Welcome back${userName != null ? ', $userName' : ''}! ✨',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                      ).animate().fadeIn(delay: 600.ms),
                      const SizedBox(height: 8),
                      const Text(
                        'Ready to continue your journey?',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ).animate().fadeIn(delay: 800.ms),
                    ] else
                      _TaglineReveal(),
                    const Spacer(flex: 2),
                    GradientButton(
                      label: isResuming ? (storage.authToken != null ? 'Resume My Journey' : 'Log In to Continue') : 'Start My Journey',
                      icon: '✨',
                      onPressed: () {
                        if (isResuming && storage.authToken != null) {
                          // Already have a session: go home (and let router handle the step)
                          context.go('/home');
                        } else {
                          // No session: must go to phone login
                          context.go('/auth/phone');
                        }
                      },
                    ).animate().slideY(begin: 0.5, duration: 400.ms, delay: 1200.ms, curve: Curves.easeOut),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LogoWheel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120, height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text('🌸', style: TextStyle(fontSize: 56)),
      ),
    ).animate().scale(begin: const Offset(0.3, 0.3), duration: 600.ms, curve: Curves.elasticOut);
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
