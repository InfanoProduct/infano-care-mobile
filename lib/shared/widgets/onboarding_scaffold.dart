import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

/// Clean, modern onboarding page wrapper with solid progress indicator, tactile back nav, and safe-area padding.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.body,
    this.currentStep = 1,
    this.totalSteps = 11,
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
    final progress = (currentStep / totalSteps).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Step Progress
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
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
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.purple,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 42),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Step $currentStep of $totalSteps',
                                style: const TextStyle(
                                  color: AppColors.purple,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            Text(
                              '${(progress * 100).round()}%',
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: const Color(0xFFE9D5FF),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Body Content
            Expanded(child: body),
            // Bottom Action Bar
            if (bottomBar != null)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                ),
                child: bottomBar!,
              ),
          ],
        ),
      ),
    );
  }
}
