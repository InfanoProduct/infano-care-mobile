import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

/// Gate screen shown before the journal. Uses biometrics or a PIN to unlock.
class JournalLockScreen extends StatefulWidget {
  final Widget child;

  static bool isSessionUnlocked = false;

  static void lockSession() {
    isSessionUnlocked = false;
  }

  static void unlockSession() {
    isSessionUnlocked = true;
  }

  const JournalLockScreen({super.key, required this.child});

  @override
  State<JournalLockScreen> createState() => _JournalLockScreenState();
}

class _JournalLockScreenState extends State<JournalLockScreen> {
  static const _correctPin = '0000'; // Placeholder — real apps use secure storage

  final _auth = LocalAuthentication();
  bool _isUnlocked = JournalLockScreen.isSessionUnlocked;
  bool _showPin = false;
  final _pinControllers = List.generate(4, (_) => TextEditingController());
  int _pinIndex = 0;
  bool _pinError = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    if (!JournalLockScreen.isSessionUnlocked) {
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    if (JournalLockScreen.isSessionUnlocked) {
      if (mounted) setState(() => _isUnlocked = true);
      return;
    }
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) {
        setState(() => _showPin = true);
        return;
      }
      setState(() => _isAuthenticating = true);
      final authenticated = await _auth.authenticate(
        localizedReason: 'Unlock your private journal',
        options: const AuthenticationOptions(biometricOnly: false),
      );
      if (mounted) {
        if (authenticated) {
          JournalLockScreen.unlockSession();
          setState(() => _isUnlocked = true);
        } else {
          setState(() { _showPin = true; _isAuthenticating = false; });
        }
      }
    } catch (_) {
      if (mounted) setState(() { _showPin = true; _isAuthenticating = false; });
    }
  }

  void _onPinDigit(String digit) {
    if (_pinIndex >= 4) return;
    _pinControllers[_pinIndex].text = digit;
    _pinIndex++;
    if (_pinIndex == 4) _validatePin();
    setState(() => _pinError = false);
  }

  void _onPinDelete() {
    if (_pinIndex == 0) return;
    _pinIndex--;
    _pinControllers[_pinIndex].text = '';
    setState(() => _pinError = false);
  }

  void _validatePin() {
    final entered = _pinControllers.map((c) => c.text).join();
    if (entered == _correctPin) {
      JournalLockScreen.unlockSession();
      setState(() => _isUnlocked = true);
    } else {
      setState(() => _pinError = true);
      for (final c in _pinControllers) { c.clear(); }
      _pinIndex = 0;
    }
  }

  @override
  void dispose() {
    for (final c in _pinControllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isUnlocked || JournalLockScreen.isSessionUnlocked) return widget.child;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.mounted) Navigator.of(context).maybePop();
        }
      },
      child: _buildLockScreen(context),
    );
  }

  Widget _buildLockScreen(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back button row
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _showPin ? _buildPinPad() : _buildBiometricPrompt(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricPrompt() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🔐', style: TextStyle(fontSize: 80)).animate().scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        Text('Your Journal', style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Private & protected ✨', style: GoogleFonts.nunito(fontSize: 15, color: Colors.white70)),
        const SizedBox(height: 40),
        if (_isAuthenticating)
          const CircularProgressIndicator(color: Colors.white)
        else
          Column(children: [
            ElevatedButton.icon(
              onPressed: _tryBiometric,
              icon: const Icon(Icons.fingerprint_rounded, size: 22),
              label: Text('Use biometrics', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.purple,
                minimumSize: const Size(220, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => setState(() => _showPin = true),
              child: Text('Use PIN instead', style: GoogleFonts.nunito(color: Colors.white70, fontSize: 14)),
            ),
          ]),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildPinPad() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🔒', style: TextStyle(fontSize: 64)).animate().scale(begin: const Offset(0.6, 0.6), duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 20),
        Text('Enter PIN', style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
        Text('Default: 0000', style: GoogleFonts.nunito(fontSize: 12, color: Colors.white38)),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 16, height: 16,
            decoration: BoxDecoration(
              color: _pinControllers[i].text.isNotEmpty
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: _pinError ? const Color(0xFFFCA5A5) : Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
          )),
        ),
        const SizedBox(height: 8),
        if (_pinError)
          Text('Incorrect PIN', style: GoogleFonts.nunito(color: const Color(0xFFFCA5A5), fontSize: 13))
              .animate().fadeIn(duration: 200.ms),
        const SizedBox(height: 32),
        _buildNumberPad(),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _tryBiometric,
          icon: const Icon(Icons.fingerprint_rounded, color: Colors.white54),
          label: Text('Use biometrics', style: GoogleFonts.nunito(color: Colors.white54, fontSize: 13)),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildNumberPad() {
    const digits = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      children: digits.map((row) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((d) => GestureDetector(
            onTap: d.isEmpty ? null : (d == '⌫' ? _onPinDelete : () => _onPinDigit(d)),
            child: Container(
              width: 72, height: 64,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: d.isEmpty ? Colors.transparent : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: d == '⌫'
                    ? const Icon(Icons.backspace_outlined, color: Colors.white, size: 22)
                    : Text(d, style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          )).toList(),
        ),
      )).toList(),
    );
  }
}
