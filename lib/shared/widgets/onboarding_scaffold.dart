import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

/// Consistent onboarding page wrapper with gradient progress bar, back nav, and safe-area padding.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.body,
    this.currentStep = 1,
    this.totalSteps = 12,
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
                      onTap: onBack ?? () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          context.pop();
                        }
                      },
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE9D5FF), width: 1),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.purple),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step $currentStep of $totalSteps',
                          style: const TextStyle(
                            color: AppColors.purple,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.surfaceCard,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
                            minHeight: 8,
                          ),
                        ),
                      ],
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
