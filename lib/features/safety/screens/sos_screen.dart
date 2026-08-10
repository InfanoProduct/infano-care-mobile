import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/features/safety/data/safety_repository.dart';
import 'package:infano_care_mobile/features/safety/screens/sos_type_setup_screen.dart';

class SosHubScreen extends StatefulWidget {
  const SosHubScreen({super.key});

  @override
  State<SosHubScreen> createState() => _SosHubScreenState();
}

class _SosHubScreenState extends State<SosHubScreen> {
  late final SafetyRepository _repo;
  List<dynamic> _contacts = [];
  SosPreferences? _prefs;
  bool _isLoading = true;
  bool _hasActiveIncident = false;
  String? _activeIncidentId;

  @override
  void initState() {
    super.initState();
    _repo = SafetyRepository(ApiService.instance.dio);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repo.getTrustedContacts(),
        _repo.getPreferences(),
        _repo.getActiveIncident(),
      ]);

      final contacts = results[0] as List<dynamic>;
      final prefs = results[1] as SosPreferences;
      final activeIncident = results[2];

      if (mounted) {
        setState(() {
          _contacts = contacts;
          _prefs = prefs;
          _hasActiveIncident = activeIncident != null;
          _activeIncidentId = activeIncident?['id']?.toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isReady => _contacts.isNotEmpty && (_prefs?.setupCompleted ?? false);

  Map<String, dynamic> get _currentType {
    final id = _prefs?.defaultEmergencyType ?? 'physical_threat';
    return kEmergencyTypes.firstWhere(
      (t) => t['id'] == id,
      orElse: () => kEmergencyTypes.first,
    );
  }

  void _onSosHeld() {
    context.push('/safety/sos/countdown', extra: {
      'emergencyType': _prefs?.defaultEmergencyType ?? 'physical_threat',
      'contacts': _contacts,
    });
  }

  Future<void> _callEmergencyServices() async {
    final uri = Uri(scheme: 'tel', path: '112');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openHelpline() async {
    final uri = Uri(scheme: 'tel', path: '9999666555');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5FF),
      appBar: AppBar(
        title: Text(
          'Safety Hub',
          style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900, color: AppColors.textDark),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.purple.withOpacity(0.1),
            height: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.textDark),
            onPressed: () =>
                context.push('/safety/setup-type').then((_) => _loadData()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.purple,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    // Glowing Active Alert Banner
                    if (_hasActiveIncident) ...[
                      _buildActiveIncidentBanner(),
                      const SizedBox(height: 20),
                    ],

                    // Layout Status Card
                    _buildStatusCard()
                        .animate()
                        .fade(duration: 400.ms)
                        .slideY(begin: 0.05),
                    const SizedBox(height: 36),

                    // Centered SOS Trigger Area
                    if (_isReady)
                      _SosButtonWidget(onHoldComplete: _onSosHeld)
                          .animate()
                          .scale(duration: 450.ms, curve: Curves.easeOutBack)
                    else
                      _buildSetupPrompt()
                          .animate()
                          .fade(duration: 400.ms),

                    const SizedBox(height: 48),

                    // Quick Dial Panel
                    _buildQuickActionsRow()
                        .animate()
                        .fade(delay: 150.ms, duration: 400.ms),
                    const SizedBox(height: 24),

                    // Secondary Cards
                    _buildContactsCard()
                        .animate()
                        .fade(delay: 200.ms, duration: 400.ms),
                    const SizedBox(height: 14),
                    _buildCrisisCard()
                        .animate()
                        .fade(delay: 250.ms, duration: 400.ms),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActiveIncidentBanner() {
    return GestureDetector(
      onTap: () => context.push('/safety/sos/active', extra: {
        'incidentId': _activeIncidentId,
        'contacts': _contacts,
        'emergencyType': _prefs?.defaultEmergencyType ?? 'physical_threat',
      }),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'SOS IS ACTIVE — RETURN TO TRACKER',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 14),
          ],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.2));
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isReady ? const Color(0xFFECFDF5) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isReady
              ? const Color(0xFFA7F3D0)
              : Colors.purple.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isReady
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _isReady ? '🛡️' : '⚠️',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isReady ? 'Protected' : 'Setup Required',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isReady
                          ? '${_contacts.length} trusted contact${_contacts.length > 1 ? 's' : ''} configured'
                          : 'Configure your protective circle to enable SOS',
                      style: GoogleFonts.nunito(
                          fontSize: 13, color: AppColors.textMedium),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isReady) ...[
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: const Color(0xFFD1FAE5),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => context
                  .push('/safety/setup-type')
                  .then((_) => _loadData()),
              child: Row(
                children: [
                  Text(_currentType['emoji'],
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Alert Style: ${_currentType['label']}',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Text(
                    'Modify',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.purple,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: AppColors.purple),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetupPrompt() {
    return Column(
      children: [
        Opacity(
          opacity: 0.25,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Center(
              child: Text(
                'SOS',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 200,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () =>
                context.push('/safety/welcome').then((_) => _loadData()),
            icon: const Icon(Icons.shield_outlined, size: 18),
            label: Text(
              'Set Up Safety',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            icon: Icons.phone_in_talk_rounded,
            label: 'Emergency Dial\nCall 112',
            color: AppColors.error,
            onTap: _callEmergencyServices,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.support_agent_rounded,
            label: 'Talk to Helpline\n24/7 Support',
            color: const Color(0xFF7C3AED),
            onTap: _openHelpline,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.15), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: color,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsCard() {
    return GestureDetector(
      onTap: () => context.push('/safety/contacts').then((_) => _loadData()),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.purple.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            const Text('👥', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trusted Contacts Circle',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _contacts.isEmpty
                        ? 'No contacts added yet'
                        : '${_contacts.map((c) => c['name']).take(2).join(', ')}${_contacts.length > 2 ? ' +${_contacts.length - 2} more' : ''}',
                    style: GoogleFonts.nunito(
                        fontSize: 13, color: AppColors.textMedium),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildCrisisCard() {
    return GestureDetector(
      onTap: _openHelpline,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.purple.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            const Text('📞', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need to talk to someone?',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vandrevala Foundation • 24/7 Free Helpline',
                    style: GoogleFonts.nunito(
                        fontSize: 13, color: AppColors.textMedium),
                  ),
                ],
              ),
            ),
            const Icon(Icons.call_outlined, size: 20, color: AppColors.purple),
          ],
        ),
      ),
    );
  }
}

// ─── Modern Hold Button ────────────────────────────────────────────────────────

class _SosButtonWidget extends StatefulWidget {
  final VoidCallback onHoldComplete;
  const _SosButtonWidget({required this.onHoldComplete});

  @override
  State<_SosButtonWidget> createState() => _SosButtonWidgetState();
}

class _SosButtonWidgetState extends State<_SosButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _isHolding = false;
  int _secondsHeld = 0;
  dynamic _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _isHolding = true;
      _secondsHeld = 0;
    });
    _ctrl.forward(from: 0);

    _timer = Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (!mounted) return;
      setState(() => _secondsHeld++);
      if (_secondsHeld >= 2) {
        _complete();
      }
    });
  }

  void _cancel() {
    _timer?.cancel();
    _ctrl.stop();
    _ctrl.reset();
    if (mounted) setState(() { _isHolding = false; _secondsHeld = 0; });
  }

  void _complete() {
    _timer?.cancel();
    _ctrl.reset();
    if (mounted) setState(() { _isHolding = false; _secondsHeld = 0; });
    widget.onHoldComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => _start(),
          onTapUp: (_) => _cancel(),
          onTapCancel: () => _cancel(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer radar rings when pressed
              if (_isHolding)
                ...List.generate(2, (i) {
                  return Container(
                    width: 170 + i * 30,
                    height: 170 + i * 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.15 - i * 0.05),
                        width: 4,
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .scale(
                        duration: 1200.ms,
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.3, 1.3),
                      )
                      .fadeOut(duration: 1200.ms);
                }),

              // Hold progress indicator ring
              SizedBox(
                width: 170,
                height: 170,
                child: CircularProgressIndicator(
                  value: _isHolding ? _ctrl.value : 0.0,
                  strokeWidth: 8,
                  color: AppColors.error,
                  backgroundColor: _isHolding
                      ? AppColors.error.withOpacity(0.15)
                      : Colors.purple.withOpacity(0.04),
                ),
              ),

              // Button sphere
              AnimatedScale(
                scale: _isHolding ? 0.92 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  width: 142,
                  height: 142,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error
                            .withOpacity(_isHolding ? 0.6 : 0.35),
                        blurRadius: _isHolding ? 40 : 24,
                        spreadRadius: _isHolding ? 12 : 4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _isHolding ? '${2 - _secondsHeld}' : 'SOS',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: _isHolding ? 0 : 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _isHolding ? 'Release to cancel' : 'Hold for 2 seconds to alert',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: AppColors.textMedium,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
