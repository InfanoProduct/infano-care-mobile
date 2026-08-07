import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/safety/data/safety_repository.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
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
  bool _hasCheckedContacts = false;
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
          _hasCheckedContacts = true;
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
          _hasCheckedContacts = true;
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

  void _completeHold() {
    _holdTimer?.cancel();
    HapticFeedback.vibrate();
    setState(() {
      _isHolding = false;
      _secondsHeld = 0;
    });
    _progressController.reset();
    
    // Navigate to the SOS Cancel Window Screen
    context.push('/safety/sos_cancel');
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
                    backgroundColor: AppColors.error.withValues(alpha: 0.2),
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
                    color: AppColors.error.withValues(alpha: _isHolding ? 0.5 : 0.3),
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
