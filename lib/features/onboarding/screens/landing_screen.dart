import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:infano_care_mobile/shared/widgets/gradient_button.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  bool _isResuming = false;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _checkAndRoute();
  }

  Future<void> _checkAndRoute() async {
    FlutterNativeSplash.remove();

    final storage = await LocalStorageService.create();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    
    final token = storage.authToken;
    
    if (token != null) {
      try {
        // Sync stage from server to reflect any external resets
        final resp = await ApiService.instance.dio.get('/user/me');
        final serverStage = resp.data['onboardingStage'];
        final serverName = resp.data['profile']?['displayName'];
        
        await storage.setStageComplete(serverStage.toString());
        if (serverName != null) await storage.setDisplayName(serverName);

        final stage = serverStage.toString();

        if (stage == '13') {
          // Fully complete: go home
          context.go('/home');
        } else if (int.parse(stage) > 1) {
          // Incomplete but started: show Resume button
          setState(() {
            _isResuming = true;
            _userName = serverName;
          });
        }
        // If stage is 0 or 1, they haven't really "started" the journey beyond phone entry,
        // so we show "Start My Journey".
      } catch (e) {
        // Token might be invalid or network error, fallback to local if available
        final stage = storage.stageComplete;
        if (stage != '13' && stage != null && int.parse(stage) > 1) {
          setState(() {
            _isResuming = true;
            _userName = storage.displayName;
          });
        }
      }
    }
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
                if (_isResuming) ...[
                  Text(
                    'Welcome back${_userName != null ? ', $_userName' : ''}! ✨',
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
                  label: _isResuming ? 'Resume My Journey' : 'Start My Journey',
                  icon: '✨',
                  onPressed: () {
                    if (_isResuming) {
                      context.go('/home'); // Router will redirect to the correct onboarding stage
                    } else {
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
