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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4C1D95), Color(0xFF831843)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🌙', style: TextStyle(fontSize: 100))
                  .animate(onPlay: (c) => c.repeat())
                  .rotate(begin: -0.05, end: 0.05, duration: 3000.ms, curve: Curves.easeInOut)
                  .then().rotate(begin: 0.05, end: -0.05, duration: 3000.ms),
                const SizedBox(height: 32),
                const Text('Tracker Activated!', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800))
                  .animate(delay: 500.ms).fadeIn(duration: 500.ms).slideY(begin: 0.3, duration: 500.ms),
                const SizedBox(height: 16),
                const Text("Your cycle prediction is live 🌸\nCheck your dashboard anytime.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.6))
                  .animate(delay: 900.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 40),
                // Points summary
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    children: [
                      const Text('Your Bloom Points 🌸', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 16),
                      Text('145', style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900))
                        .animate(delay: 1200.ms).scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),
                      const Text('Bloom Points earned! 🎉', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _PointRow('10', 'Name'),
                          _PointRow('15', 'Goals'),
                          _PointRow('10', 'Comfort'),
                          _PointRow('20', 'Topics'),
                          _PointRow('25', 'Avatar'),
                          _PointRow('15', 'Journey'),
                          _PointRow('50', 'Tracker'),
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: 1000.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 40),
                GradientButton(
                  label: 'Enter My World 🌸',
                  onPressed: () => context.go('/home'),
                ).animate(delay: 1600.ms).slideY(begin: 0.5, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PointRow extends StatelessWidget {
  const _PointRow(this.pts, this.label);
  final String pts, label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(pts, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}
