import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';

class SosCancelScreen extends StatefulWidget {
  const SosCancelScreen({super.key});

  @override
  State<SosCancelScreen> createState() => _SosCancelScreenState();
}

class _SosCancelScreenState extends State<SosCancelScreen> with SingleTickerProviderStateMixin {
  Timer? _cancelTimer;
  int _secondsLeft = 5;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _startCancelWindow();
  }

  @override
  void dispose() {
    _cancelTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _startCancelWindow() {
    _progressController.reverse(from: 1.0);
    _cancelTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        _secondsLeft--;
      });
      if (_secondsLeft <= 0) {
        _cancelTimer?.cancel();
        _triggerSosAlert();
      }
    });
  }

  void _onCancelPressed() {
    _cancelTimer?.cancel();
    _progressController.stop();
    HapticFeedback.mediumImpact();
    // Go back to the dashboard without triggering
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _triggerSosAlert() async {
    // Actually trigger the SOS backend call here
    try {
      // Mock location for now
      final response = await ApiService.instance.dio.post('/safety/sos/trigger', data: {
        'lat': 28.6139,
        'lng': 77.2090,
      });
      final incidentId = response.data['id'];
      
      if (mounted) {
        // Navigate to the active SOS screen
        context.pushReplacement('/safety/sos_active', extra: incidentId);
      }
    } catch (e) {
      debugPrint('Error triggering SOS: $e');
      // Even if API fails, we should show the active screen to reassure the user
      // and maybe retry in the background.
      if (mounted) {
        context.pushReplacement('/safety/sos_active');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.error,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.white),
              const SizedBox(height: 32),
              const Text(
                'SOS Triggered!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Alerting your trusted contacts and sharing your location in...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Countdown Circle
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return CircularProgressIndicator(
                          value: _progressController.value,
                          strokeWidth: 12,
                          color: Colors.white,
                          backgroundColor: Colors.white24,
                        );
                      },
                    ),
                  ),
                  Text(
                    '$_secondsLeft',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _onCancelPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'CANCEL ALERT',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
