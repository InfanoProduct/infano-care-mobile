import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/features/safety/data/safety_repository.dart';

class SosActiveScreen extends StatefulWidget {
  final String? incidentId;
  final List<dynamic> contacts;
  final String emergencyType;

  const SosActiveScreen({
    super.key,
    this.incidentId,
    this.contacts = const [],
    this.emergencyType = 'physical_threat',
  });

  @override
  State<SosActiveScreen> createState() => _SosActiveScreenState();
}

class _SosActiveScreenState extends State<SosActiveScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  Timer? _elapsedTimer;
  Timer? _locationTimer;
  int _elapsedSeconds = 0;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });

    if (widget.incidentId != null) {
      _locationTimer =
          Timer.periodic(const Duration(seconds: 30), (_) => _pingLocation());
    }

    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _elapsedTimer?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _pingLocation() async {
    if (widget.incidentId == null) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      final repo = SafetyRepository(ApiService.instance.dio);
      await repo.updateSosLocation(
          widget.incidentId!, pos.latitude, pos.longitude);
    } catch (_) {}
  }

  Future<void> _onIAmSafe() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Confirm Safety Status',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'This will resolve the alert and notify your contacts that you are safe.',
          style: GoogleFonts.nunito(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Stay Alerting',
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold, color: AppColors.textMedium),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'I Am Safe',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isResolving = true);
    try {
      if (widget.incidentId != null) {
        final repo = SafetyRepository(ApiService.instance.dio);
        await repo.resolveSos(widget.incidentId!);
      }
      if (mounted) {
        _locationTimer?.cancel();
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResolving = false);
        context.go('/home');
      }
    }
  }

  Future<void> _callContact(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  String _formatElapsed() {
    final h = _elapsedSeconds ~/ 3600;
    final m = (_elapsedSeconds % 3600) ~/ 60;
    final s = _elapsedSeconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _emergencyLabel {
    const labels = {
      'physical_threat': 'Physical Threat',
      'medical_emergency': 'Medical Emergency',
      'mental_distress': 'Mental Crisis',
      'safe_walk': 'Safe Walk Check-In',
    };
    return labels[widget.emergencyType] ?? widget.emergencyType;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            // Immersive Deep Dark Radar Background
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F0206), Color(0xFF2D040E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Premium Status Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: AppColors.error.withOpacity(0.35),
                                width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              )
                                  .animate(onPlay: (c) => c.repeat())
                                  .fadeOut(duration: 600.ms)
                                  .then()
                                  .fadeIn(duration: 600.ms),
                              const SizedBox(width: 8),
                              Text(
                                'SOS ACTIVE',
                                style: GoogleFonts.nunito(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatElapsed(),
                          style: GoogleFonts.nunito(
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Immersive Pulsing Center HUD
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Ripple pulse waves
                              ...List.generate(3, (i) {
                                return AnimatedBuilder(
                                  animation: _rippleController,
                                  builder: (_, __) {
                                    final delay = i * 0.33;
                                    final progress =
                                        (_rippleController.value + delay) % 1.0;
                                    return Transform.scale(
                                      scale: 1.0 + progress * 2.0,
                                      child: Container(
                                        width: 110,
                                        height: 110,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.error.withOpacity(
                                                (1 - progress) * 0.5),
                                            width: 2.5,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }),
                              // Center glowing sphere
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (_, __) => Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.error.withOpacity(0.5 +
                                                _pulseController.value * 0.35),
                                        blurRadius:
                                            30 + _pulseController.value * 20,
                                        spreadRadius:
                                            6 + _pulseController.value * 8,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text('🚨',
                                        style: TextStyle(fontSize: 44)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 36),
                          Text(
                            'Help is Coming',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 32,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _emergencyLabel.toUpperCase(),
                            style: GoogleFonts.nunito(
                              color: AppColors.error,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Live sharing pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    color: Colors.greenAccent, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'Live GPS sharing active',
                                  style: GoogleFonts.nunito(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Frosted Glass Contacts List
                  if (widget.contacts.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PROTECTORS ALERTED',
                            style: GoogleFonts.nunito(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...widget.contacts.take(3).map((c) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.08)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      color: Colors.greenAccent, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c['name'] as String,
                                          style: GoogleFonts.nunito(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          c['phone'] as String,
                                          style: GoogleFonts.nunito(
                                            color: Colors.white
                                                .withOpacity(0.5),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        _callContact(c['phone'] as String),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: Colors.white
                                                .withOpacity(0.15)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.phone_rounded,
                                              color: Colors.white, size: 14),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Call',
                                            style: GoogleFonts.nunito(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                  // I Am Safe Now Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _isResolving ? null : _onIAmSafe,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1A0000),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32)),
                        ),
                        child: _isResolving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: AppColors.error, strokeWidth: 2.5),
                                ),
                                const SizedBox(width: 12),
                                Text('Resolving alert...'),
                              ],
                            )
                          : Text(
                              '✅  I Am Safe Now',
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
