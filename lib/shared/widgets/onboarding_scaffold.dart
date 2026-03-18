import 'package:flutter/material.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

/// Consistent onboarding page wrapper with gradient progress bar, back nav, and safe-area padding.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.body,
    this.currentStep = 1,
    this.totalSteps = 16,
    this.canGoBack = true,
    this.onBack,
    this.bottomBar,
  });

  final Widget body;
  final int currentStep;
  final int totalSteps;
  final bool canGoBack;
  final VoidCallback? onBack;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  if (canGoBack)
                    GestureDetector(
                      onTap: onBack ?? () => Navigator.maybePop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.purple),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.surfaceCard,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: AppColors.purple,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(child: body),
            // Bottom bar
            if (bottomBar != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: bottomBar!,
              ),
          ],
        ),
      ),
    );
  }
}
