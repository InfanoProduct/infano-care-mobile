import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/location_service.dart';
import 'package:infano_care_mobile/features/safety/data/safety_repository.dart';

class SosCountdownScreen extends StatefulWidget {
  final String emergencyType;
  final List<dynamic> contacts;

  const SosCountdownScreen({
    super.key,
    required this.emergencyType,
    required this.contacts,
  });

  @override
  State<SosCountdownScreen> createState() => _SosCountdownScreenState();
}

class _SosCountdownScreenState extends State<SosCountdownScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringController;
  Timer? _countdownTimer;
  int _secondsLeft = 3;
  bool _isCancelled = false;
  bool _isFiring = false;

  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _startCountdown();
    _fetchLocation();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _ringController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _ringController.reverse(from: 1.0);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _isCancelled) return;
      HapticFeedback.mediumImpact();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        _fireAlert();
      }
    });
  }

  Future<void> _fetchLocation() async {
    try {
      final pos = await LocationHelperService.instance.getCurrentPosition(
        timeout: const Duration(seconds: 4),
      );
      if (pos != null) {
        _lat = pos.latitude;
        _lng = pos.longitude;
      }
    } catch (_) {}
  }

  void _onCancel() {
    if (_isFiring) return;
    _isCancelled = true;
    _countdownTimer?.cancel();
    _ringController.stop();
    HapticFeedback.heavyImpact();
    if (mounted) {
      if (context.canPop()) context.pop();
    }
  }

  Future<void> _fireAlert() async {
    if (!mounted || _isCancelled) return;
    setState(() => _isFiring = true);

    try {
      // Ensure we have valid GPS coordinates before triggering alert
      if (_lat == null || _lng == null || (_lat == 0.0 && _lng == 0.0)) {
        try {
          final pos = await LocationHelperService.instance.getCurrentPosition(
            timeout: const Duration(seconds: 3),
          );
          if (pos != null) {
            _lat = pos.latitude;
            _lng = pos.longitude;
          }
        } catch (_) {}
      }

      final repo = SafetyRepository(ApiService.instance.dio);
      final response = await repo.triggerSos(
        _lat ?? 0.0,
        _lng ?? 0.0,
        emergencyType: widget.emergencyType,
      );
      final incidentId = response['id']?.toString();

      if (mounted) {
        context.pushReplacement('/safety/sos/active', extra: {
          'incidentId': incidentId,
          'contacts': widget.contacts,
          'emergencyType': widget.emergencyType,
        });
      }
    } catch (e) {
      if (mounted) {
        context.pushReplacement('/safety/sos/active', extra: {
          'incidentId': null,
          'contacts': widget.contacts,
          'emergencyType': widget.emergencyType,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            // Dark Crimson Gradient Background
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B0712), Color(0xFF991B1B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top warning icon
                      const Icon(
                        Icons.gpp_maybe_rounded,
                        size: 72,
                        color: Colors.white,
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(duration: 800.ms, begin: const Offset(1.0, 1.0), end: const Offset(1.15, 1.15)),
                      const SizedBox(height: 24),

                      Text(
                        _isFiring ? 'Alerting Help...' : 'SOS Triggered!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (!_isFiring) ...[
                        Text(
                          'Notifying: ${widget.contacts.take(2).map((c) => c['name']).join(', ')}${widget.contacts.length > 2 ? ' + ${widget.contacts.length - 2} more' : ''}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fade(duration: 300.ms),
                        const SizedBox(height: 8),
                        Text(
                          '📍 Resolving live GPS location...',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeOut(duration: 800.ms),
                      ] else ...[
                        Text(
                          'Dispatching emergency SMS & live GPS coordinates...',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ).animate().fade(duration: 300.ms),
                      ],

                      const Spacer(),

                      // Countdown Ring HUD or Loading Spinner
                      if (!_isFiring)
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer ambient glow ring
                            Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.03),
                              ),
                            ),
                            SizedBox(
                              width: 190,
                              height: 190,
                              child: AnimatedBuilder(
                                animation: _ringController,
                                builder: (_, __) => CircularProgressIndicator(
                                  value: _ringController.value,
                                  strokeWidth: 12,
                                  color: Colors.white,
                                  backgroundColor: Colors.white24,
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                            ),
                            Text(
                              '$_secondsLeft',
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize: 84,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        )
                      else
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 2,
                              ),
                            ),
                            child: const SizedBox(
                              width: 56,
                              height: 56,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 4.5,
                              ),
                            ),
                          ),
                        ),

                      const Spacer(),

                      // Cancel button or placeholder for spacing
                      if (!_isFiring)
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: _onCancel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.error,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32)),
                            ),
                            child: Text(
                              '✕   CANCEL ALERT',
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ).animate().scale(delay: 200.ms, duration: 300.ms, curve: Curves.easeOutBack)
                      else
                        const SizedBox(height: 64),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
