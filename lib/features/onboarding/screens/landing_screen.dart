import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
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
    FlutterNativeSplash.remove();

    final storage = context.read<LocalStorageService>();
    if (storage.authToken != null && !storage.isOnboarded) {
      context.read<OnboardingBloc>().add(const BootstrapApp());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final storage = context.read<LocalStorageService>();
        final step = storage.stepComplete;
        final isResuming = (step != null && int.parse(step) >= 1) || storage.authToken != null;
        final userName = state.displayName.isNotEmpty ? state.displayName : storage.displayName;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Spacer(flex: 2),
                            _LogoWheel(),
                            const SizedBox(height: 28),
                            Text(
                              'Infano.Care',
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                            const SizedBox(height: 12),
                            if (isResuming) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE9D5FF)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Welcome back${userName != null ? ', $userName' : ''}! ✨',
                                      style: const TextStyle(
                                        color: AppColors.purple,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Ready to continue your journey?',
                                      style: TextStyle(color: AppColors.textMedium, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, duration: 300.ms),
                            ] else
                              _TaglineReveal(),
                            const Spacer(flex: 2),
                            GradientButton(
                              label: isResuming
                                  ? (storage.authToken != null ? 'Resume My Journey' : 'Log In to Continue')
                                  : 'Start My Journey',
                              icon: '✨',
                              onPressed: () {
                                if (isResuming && storage.authToken != null) {
                                  context.go('/home');
                                } else {
                                  context.go('/auth/phone');
                                }
                              },
                            ).animate().slideY(begin: 0.2, duration: 350.ms, delay: 600.ms, curve: Curves.easeOut),
                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: () async {
                                await storage.clearAll();
                                if (context.mounted) {
                                  context.read<OnboardingBloc>().add(const SyncFromStorage());
                                  context.go('/splash');
                                }
                              },
                              child: const Text(
                                'Reset App Data',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ).animate().fadeIn(delay: 800.ms),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
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
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE9D5FF), width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Text('🌸', style: TextStyle(fontSize: 56)),
      ),
    ).animate().scale(begin: const Offset(0.7, 0.7), duration: 500.ms, curve: Curves.easeOutBack);
  }
}

class _TaglineReveal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Text(
        'Your Journey. Your Power. Your Safe Space.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.purple,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          height: 1.4,
        ),
      ),
    ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(begin: 0.15, duration: 300.ms);
  }
}
