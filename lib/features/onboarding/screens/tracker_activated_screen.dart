import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/shared/widgets/gradient_button.dart';

class TrackerActivatedScreen extends StatefulWidget {
  const TrackerActivatedScreen({super.key});

  @override
  State<TrackerActivatedScreen> createState() => _TrackerActivatedScreenState();
}

class _TrackerActivatedScreenState extends State<TrackerActivatedScreen> {
  @override
  void initState() {
    super.initState();
    _autoRoute();
  }

  Future<void> _autoRoute() async {
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
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
                      children: [
                        const Spacer(),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE9D5FF), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.purple.withValues(alpha: 0.12),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🌙', style: TextStyle(fontSize: 48)),
                          ),
                        ).animate().scale(begin: const Offset(0.6, 0.6), duration: 500.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 28),
                        Text(
                          'Tracker Activated!',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w900,
                              ),
                        ).animate(delay: 200.ms).fadeIn(duration: 300.ms).slideY(begin: 0.2, duration: 300.ms),
                        const SizedBox(height: 10),
                        const Text(
                          "Your cycle predictions and reminders are now live 🌸\nCheck your dashboard anytime.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMedium, fontSize: 15, height: 1.4),
                        ).animate(delay: 350.ms).fadeIn(duration: 300.ms),
                        const SizedBox(height: 32),
                        // Points & Milestone summary card
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.purple.withValues(alpha: 0.05),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Your Total Bloom Points 🌸',
                                style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '145',
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                              ).animate(delay: 500.ms).scale(begin: const Offset(0.7, 0.7), duration: 400.ms, curve: Curves.elasticOut),
                              const Text(
                                'Points Earned During Setup! 🎉',
                                style: TextStyle(color: AppColors.textMedium, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 18),
                              const Divider(color: Color(0xFFE9D5FF)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: const [
                                  _SolidPointBadge('10', 'Name'),
                                  _SolidPointBadge('15', 'Goals'),
                                  _SolidPointBadge('10', 'Comfort'),
                                  _SolidPointBadge('20', 'Topics'),
                                  _SolidPointBadge('25', 'Safety'),
                                  _SolidPointBadge('65', 'Tracker'),
                                ],
                              ),
                            ],
                          ),
                        ).animate(delay: 450.ms).fadeIn(duration: 350.ms),
                        const Spacer(),
                        GradientButton(
                          label: 'Enter My Dashboard 🌸',
                          onPressed: () => context.go('/home'),
                        ).animate(delay: 700.ms).fadeIn(),
                        const SizedBox(height: 20),
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
  }
}

class _SolidPointBadge extends StatelessWidget {
  const _SolidPointBadge(this.pts, this.label);
  final String pts, label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '+$pts $label',
        style: const TextStyle(
          color: AppColors.purple,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
