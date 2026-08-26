import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/safety/data/safety_repository.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/location_service.dart';

class SosButton extends StatefulWidget {
  const SosButton({super.key});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  Timer? _holdTimer;
  int _secondsHeld = 0;
  bool _isHolding = false;
  late AnimationController _progressController;
  bool _hasContacts = false;
  bool _isCheckingContacts = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _checkContactsSilently();
  }

  Future<void> _checkContactsSilently() async {
    if (_isCheckingContacts) return;
    _isCheckingContacts = true;
    try {
      final repo = SafetyRepository(ApiService.instance.dio);
      final contacts = await repo.getTrustedContacts();
      if (mounted) {
        setState(() {
          _hasContacts = contacts.isNotEmpty;
          _isCheckingContacts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingContacts = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _startHold() {
    setState(() {
      _isHolding = true;
      _secondsHeld = 0;
    });
    HapticFeedback.heavyImpact();
    _progressController.forward(from: 0.0);
    
    if (!_hasContacts) {
      _verifyContactsDuringHold();
    }

    _holdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _secondsHeld++;
      });
      if (_secondsHeld >= 3) {
        _completeHold();
      }
    });
  }

  Future<void> _verifyContactsDuringHold() async {
    if (_isCheckingContacts) return;
    _isCheckingContacts = true;
    try {
      final repo = SafetyRepository(ApiService.instance.dio);
      final contacts = await repo.getTrustedContacts();
      if (mounted) {
        setState(() {
          _hasContacts = contacts.isNotEmpty;
          _isCheckingContacts = false;
        });
        
        if (!_hasContacts && _isHolding) {
          _cancelHold();
          _showAddContactWarning();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingContacts = false;
        });
      }
    }
  }

  void _showAddContactWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please add a trusted contact first.'),
        action: SnackBarAction(
          label: 'Add',
          textColor: Colors.white,
          onPressed: () => context.push('/safety/contacts'),
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _cancelHold() {
    if (!_isHolding) return;
    _holdTimer?.cancel();
    _progressController.stop();
    _progressController.reset();
    setState(() {
      _isHolding = false;
      _secondsHeld = 0;
    });
  }

  Future<void> _completeHold() async {
    _holdTimer?.cancel();
    HapticFeedback.vibrate();
    setState(() {
      _isHolding = false;
      _secondsHeld = 0;
    });
    _progressController.reset();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.error),
      ),
    );

    try {
      final repo = SafetyRepository(ApiService.instance.dio);
      final contacts = await repo.getTrustedContacts();
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        
        bool isConfigured = false;
        for (var contact in contacts) {
          final List<dynamic> types = contact['emergencyTypes'] ?? [];
          if (types.isNotEmpty) {
            isConfigured = true;
            break;
          }
        }

        if (!isConfigured) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please configure your emergency contacts first.'),
              backgroundColor: AppColors.purple,
            ),
          );
          context.push('/safety/sos_config');
        } else {
          _showEmergencyOptionsBottomSheet();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to verify configuration: $e')),
        );
      }
    }
  }

  void _showEmergencyOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final List<Map<String, dynamic>> categories = [
          {
            'id': 'physical_threat',
            'title': 'Physical Threat / Harassment',
            'icon': '🚨',
            'color': Colors.red,
          },
          {
            'id': 'medical_emergency',
            'title': 'Medical Emergency',
            'icon': '🚑',
            'color': Colors.orange,
          },
          {
            'id': 'mental_distress',
            'title': 'Mental Distress Crisis',
            'icon': '🧠',
            'color': Colors.purple,
          },
          {
            'id': 'safe_walk',
            'title': 'Follow Me / Safe Walk',
            'icon': '🚶‍♀️',
            'color': Colors.teal,
          },
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Select Emergency Crisis',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tapping an option will trigger the SOS alert instantly to configured contacts.',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 24),
                ...categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _triggerEmergencySos(cat['id'] as String, cat['title'] as String);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: (cat['color'] as Color).withOpacity(0.1),
                              child: Text(
                                cat['icon'] as String,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                cat['title'] as String,
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _triggerEmergencySos(String categoryId, String categoryTitle) async {
    // Show a loading/progress indicator overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.error),
      ),
    );

    try {
      final repo = SafetyRepository(ApiService.instance.dio);

      // Acquire live GPS fix (with fallback to last known)
      final position = await LocationHelperService.instance.getCurrentPosition(
        timeout: const Duration(seconds: 4),
      );
      final double lat = position?.latitude ?? 0.0;
      final double lng = position?.longitude ?? 0.0;

      // Trigger the backend alert using categoryId and live coordinates
      final response = await repo.triggerSos(
        lat,
        lng,
        emergencyType: categoryId,
      );

      final incidentId = response['id']?.toString();

      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        context.pushReplacement('/safety/sos/active', extra: {
          'incidentId': incidentId,
          'contacts': [],
          'emergencyType': categoryId,
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to trigger SOS: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _cancelHold(),
      onTapCancel: () => _cancelHold(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circular progress
          if (_isHolding)
            SizedBox(
              width: 140,
              height: 140,
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return CircularProgressIndicator(
                    value: _progressController.value,
                    strokeWidth: 8,
                    color: AppColors.error,
                    backgroundColor: AppColors.error.withOpacity(0.2),
                  );
                },
              ),
            ),
            
          // Main Button
          AnimatedScale(
            scale: _isHolding ? 0.9 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withOpacity(_isHolding ? 0.5 : 0.3),
                    blurRadius: _isHolding ? 30 : 20,
                    spreadRadius: _isHolding ? 12 : 8,
                  ),
                ],
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
              ),
              child: Center(
                child: Text(
                  _isHolding ? '${3 - _secondsHeld}' : 'SOS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
