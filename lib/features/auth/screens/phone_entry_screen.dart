import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/features/auth/repository/auth_repository.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';
import 'package:infano_care_mobile/core/services/permission_service.dart';

class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key, required this.storage, this.fromOnboarding = false});
  final LocalStorageService storage;
  final bool fromOnboarding;

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _controller = TextEditingController();
  String _countryCode = '+91';
  String _countryFlag = '🇮🇳';
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
          // Auto-logged in. Route based on role + onboarding status from backend.
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
      if (mounted) setState(() => _error = e.toString());
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Top Navigation & Security Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!widget.fromOnboarding)
                  GestureDetector(
                    onTap: () => context.go('/splash'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textDark),
                    ),
                  )
                else
                  const SizedBox(width: 44),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.purple),
                      SizedBox(width: 5),
                      Text(
                        '100% Private & Safe',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Blossom Hero Emblem
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEDE9FE), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🌸', style: TextStyle(fontSize: 36)),
                ),
              ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.easeOutBack),
            ),

            const SizedBox(height: 20),

            // Title & Subtitle
            Center(
              child: Column(
                children: [
                  const Text(
                    'Welcome to Infano ✨',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Enter your mobile number to get instant, password-free access to your care hub.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMedium,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, duration: 400.ms),

            const SizedBox(height: 28),

            // Phone Entry Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEDE9FE), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.phone_iphone_rounded, size: 16, color: AppColors.purple),
                          SizedBox(width: 6),
                          Text(
                            'MOBILE NUMBER',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '10 Digits',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Country code & Phone Field
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _valid ? AppColors.purple : const Color(0xFFE9D5FF),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Country Code Selector
                        InkWell(
                          onTap: _showCountryPicker,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                            child: Row(
                              children: [
                                Text(_countryFlag, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Text(
                                  _countryCode,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.5,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textMedium),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 1.2,
                          height: 28,
                          color: const Color(0xFFE9D5FF),
                        ),
                        // Number Text Field
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            keyboardType: TextInputType.phone,
                            maxLength: 12,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              letterSpacing: 1.2,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '98765 43210',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                              suffixIcon: _controller.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textLight),
                                      onPressed: () {
                                        _controller.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) {
                              if (_valid && !_loading) _sendOtp();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Send OTP Button
                  InkWell(
                    onTap: _valid && !_loading ? _sendOtp : null,
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      constraints: const BoxConstraints(minHeight: 54),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: _valid
                            ? const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : null,
                        color: _valid ? null : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _valid
                            ? [
                                BoxShadow(
                                  color: AppColors.purple.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
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
                                  Flexible(
                                    child: Text(
                                      'Get Verification Code',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _valid ? Colors.white : const Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: _valid ? Colors.white : const Color(0xFF94A3B8),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, duration: 350.ms),

            const SizedBox(height: 28),

            // Benefits Row
            Row(
              children: [
                _buildBenefitItem(icon: Icons.flash_on_rounded, text: 'Instant OTP'),
                const SizedBox(width: 10),
                _buildBenefitItem(icon: Icons.key_off_rounded, text: 'No Password'),
                const SizedBox(width: 10),
                _buildBenefitItem(icon: Icons.favorite_rounded, text: 'Teens & Parents'),
              ],
            ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

            const SizedBox(height: 28),

            // Terms disclaimer
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'By signing in, you agree to Infano\'s Terms of Service and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem({required IconData icon, required String text}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDE9FE)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.purple),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker() {
    final countries = [
      {'code': '+91', 'flag': '🇮🇳', 'name': 'India'},
      {'code': '+1', 'flag': '🇺🇸', 'name': 'United States'},
      {'code': '+44', 'flag': '🇬🇧', 'name': 'United Kingdom'},
      {'code': '+61', 'flag': '🇦🇺', 'name': 'Australia'},
      {'code': '+971', 'flag': '🇦🇪', 'name': 'UAE'},
      {'code': '+65', 'flag': '🇸🇬', 'name': 'Singapore'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Country',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: countries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, i) {
                    final c = countries[i];
                    final isSelected = c['code'] == _countryCode;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: Text(c['flag']!, style: const TextStyle(fontSize: 24)),
                      title: Text(
                        c['name']!,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? AppColors.purple : AppColors.textDark,
                        ),
                      ),
                      trailing: Text(
                        c['code']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.purple : AppColors.textMedium,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _countryCode = c['code']!;
                          _countryFlag = c['flag']!;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
