import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/features/auth/repository/auth_repository.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';
import 'package:infano_care_mobile/core/services/permission_service.dart';

class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({
    super.key,
    required this.storage,
    this.fromOnboarding = false,
  });

  final LocalStorageService storage;
  final bool fromOnboarding;

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _controller = TextEditingController();
  String _countryCode = '+91';
  bool _loading = false;
  String? _error;

  late final AuthRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = AuthRepository(widget.storage);
    _controller.addListener(_formatPhoneNumber);
  }

  @override
  void dispose() {
    _controller.removeListener(_formatPhoneNumber);
    _controller.dispose();
    super.dispose();
  }

  /// Auto-formats the phone number with spaces for better readability (98765 43210)
  void _formatPhoneNumber() {
    String text = _controller.text.replaceAll(' ', '');
    if (text.length > 5) {
      text = '${text.substring(0, 5)} ${text.substring(5)}';
      if (_controller.text != text) {
        _controller.value = _controller.value.copyWith(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    }
  }

  bool get _valid => _controller.text.replaceAll(' ', '').length >= 10;

  Future<void> _sendOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rawNumber = _controller.text.replaceAll(' ', '').trim();
      final phone = '$_countryCode$rawNumber';

      final signature = await PermissionService.instance.getAppSignature();
      debugPrint("📤 Sending OTP for $phone (App Hash: $signature)");

      final result = await _repo.sendOtp(phone, appHash: signature);
      if (mounted) {
        if (result != null) {
          if (result.isOnboardingCompleted) {
            context.go('/home');
          } else {
            final role = result.role ?? widget.storage.role;
            if (role != null) {
              widget.storage.setUserType(role.toLowerCase());
            }
            context.go('/onboarding/name');
          }
        } else {
          context.go('/auth/otp?phone=${Uri.encodeComponent(phone)}&fromOnboarding=${widget.fromOnboarding}');
        }
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fromOnboarding) {
      return OnboardingScaffold(
        currentStep: 11,
        body: _buildBody(context),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF8B7CD8), // Match 3D background room lavender tone
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 700;

    return Stack(
      children: [
        // 1. 3D Background Illustration (Character visible)
        Positioned.fill(
          child: Image.asset(
            'assets/images/phone_entry_bg.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter, // Keep 3D character girl face & flower clearly visible!
          ),
        ),

        // 2. Subtle Soft Gradient Overlay for depth and clarity
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF5B21B6).withValues(alpha: 0.1),
                  const Color(0xFF2D1557).withValues(alpha: 0.35),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // 3. Back Button (Top Left)
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: GestureDetector(
            onTap: () {
              if (widget.fromOnboarding) {
                Navigator.of(context).maybePop();
              } else {
                context.go('/splash');
              }
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF5B21B6)),
            ),
          ),
        ),

        // 4. Interactive Glassmorphic Phone Card (Structured for best fit)
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(height: isCompact ? 100 : 160), // Leave top space so character girl is fully visible

                      // 3D Glassmorphic Phone Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: isCompact ? 20 : 26,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.93), // Premium glassmorphic white card
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4C1D95).withValues(alpha: 0.22),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 3D Heart Icon Badge
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEDE9FE), Color(0xFFF5F3FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6D28D9).withValues(alpha: 0.16),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.favorite_rounded, size: 28, color: Color(0xFF6D28D9)),
                              ),
                            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                            const SizedBox(height: 14),

                            // Header Title: What's your number? 📱
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "What's your number?",
                                  style: GoogleFonts.nunito(
                                    fontSize: 19.5,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF2D1557),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('📱', style: TextStyle(fontSize: 18)),
                              ],
                            ),

                            const SizedBox(height: 4),

                            // Subtitle
                            Text(
                              "We'll send you a 4-digit code to verify.\nNo password needed!",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6B7280),
                                height: 1.35,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Country Code + Phone Input Row
                            Row(
                              children: [
                                // Neumorphic Country Code Selector
                                GestureDetector(
                                  onTap: _showCountryPicker,
                                  child: Container(
                                    height: 50,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          _countryCode,
                                          style: GoogleFonts.nunito(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF59E0B),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // Phone Textfield Box
                                Expanded(
                                  child: Container(
                                    height: 50,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFD1D5DB), width: 1.2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.03),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: _controller,
                                      keyboardType: TextInputType.phone,
                                      maxLength: 12,
                                      style: GoogleFonts.nunito(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF111827),
                                        letterSpacing: 0.5,
                                      ),
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        counterText: '',
                                        hintText: '98765 43210',
                                        hintStyle: GoogleFonts.nunito(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF9CA3AF),
                                        ),
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (_error != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: GoogleFonts.nunito(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center,
                              ),
                            ],

                            const SizedBox(height: 20),

                            // Primary Send OTP Button
                            AnimatedOpacity(
                              opacity: _valid ? 1.0 : 0.65,
                              duration: const Duration(milliseconds: 200),
                              child: GestureDetector(
                                onTap: _valid && !_loading ? _sendOtp : null,
                                child: Container(
                                  height: 50,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF6D28D9), Color(0xFF5B21B6)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF5B21B6).withValues(alpha: 0.35),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: _loading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Send OTP',
                                                style: GoogleFonts.nunito(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text('📱', style: TextStyle(fontSize: 16)),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Don't have an account? Sign Up Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: GoogleFonts.nunito(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4B5563),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.go('/onboarding/path'),
                                  child: Text(
                                    'Sign Up',
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF5B21B6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08, duration: 500.ms, curve: Curves.easeOutBack),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['+91 🇮🇳 India', '+1 🇺🇸 USA', '+44 🇬🇧 UK', '+61 🇦🇺 Australia']
                .map(
                  (c) => ListTile(
                    title: Text(c, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                    onTap: () {
                      setState(() => _countryCode = c.split(' ').first);
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
