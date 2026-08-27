import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/location_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/safety/data/safety_repository.dart';
import 'package:infano_care_mobile/features/safety/screens/sos_type_setup_screen.dart';

class SosConfigScreen extends StatefulWidget {
  const SosConfigScreen({super.key});

  @override
  State<SosConfigScreen> createState() => _SosConfigScreenState();
}

class _SosConfigScreenState extends State<SosConfigScreen> {
  final SafetyRepository _repository = SafetyRepository(ApiService.instance.dio);
  final LocationHelperService _locationService = LocationHelperService.instance;

  bool _isLoading = true;
  bool _isRefreshingGps = false;
  bool _isSavingLocationPref = false;
  bool _isSavingMapping = false;

  List<dynamic> _contacts = [];
  LocationDiagnostics? _diagnostics;

  String _selectedEmergencyType = 'physical_threat';
  bool _locationEnabledForSos = true;

  // Emergency Categories definition for granular contact mapping
  final List<Map<String, dynamic>> _emergencies = [
    {
      'id': 'physical_threat',
      'title': 'Physical Threat / Harassment',
      'icon': '🚨',
      'color': const Color(0xFFDC2626),
      'desc': 'For immediate danger, feeling unsafe, or being followed.',
    },
    {
      'id': 'medical_emergency',
      'title': 'Medical Emergency',
      'icon': '🚑',
      'color': const Color(0xFFD97706),
      'desc': 'For severe physical illness, injury, or accident.',
    },
    {
      'id': 'mental_distress',
      'title': 'Mental Distress Crisis',
      'icon': '🧠',
      'color': const Color(0xFF7C3AED),
      'desc': 'For panic attacks or emotional crisis support.',
    },
    {
      'id': 'safe_walk',
      'title': 'Safe Walk / Check-In',
      'icon': '🚶‍♀️',
      'color': const Color(0xFF0D9488),
      'desc': 'For walking alone at night and needing active tracking.',
    },
  ];

  // Mapping of emergencyId -> List of contactIds
  Map<String, List<String>> _configMapping = {
    'physical_threat': [],
    'medical_emergency': [],
    'mental_distress': [],
    'safe_walk': [],
  };

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repository.getTrustedContacts(),
        _repository.getPreferences(),
        _locationService.runDiagnostics(),
      ]);

      final contacts = results[0] as List<dynamic>;
      final prefs = results[1] as SosPreferences;
      final diag = results[2] as LocationDiagnostics;

      // Populate config mapping from backend-driven contact.emergencyTypes
      final mapping = <String, List<String>>{
        'physical_threat': [],
        'medical_emergency': [],
        'mental_distress': [],
        'safe_walk': [],
      };

      for (var contact in contacts) {
        final contactId = contact['id']?.toString() ?? '';
        final List<dynamic> types = contact['emergencyTypes'] ?? [];
        for (var type in types) {
          if (mapping.containsKey(type)) {
            mapping[type]!.add(contactId);
          }
        }
      }

      if (mounted) {
        setState(() {
          _contacts = contacts;
          _diagnostics = diag;
          _selectedEmergencyType = prefs.defaultEmergencyType;
          _locationEnabledForSos = prefs.locationEnabled;
          _configMapping = mapping;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load safety settings: $e')),
        );
      }
    }
  }

  Future<void> _refreshGpsDiagnostics() async {
    setState(() => _isRefreshingGps = true);
    HapticFeedback.lightImpact();
    try {
      final diag = await _locationService.runDiagnostics();
      if (mounted) {
        setState(() {
          _diagnostics = diag;
          _isRefreshingGps = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(diag.position != null
                ? '✅ GPS fix acquired (${diag.position!.latitude.toStringAsFixed(4)}, ${diag.position!.longitude.toStringAsFixed(4)})'
                : '⚠️ GPS not ready: ${diag.errorMessage ?? "Check device settings"}'),
            backgroundColor: diag.position != null ? const Color(0xFF10B981) : AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshingGps = false);
      }
    }
  }

  Future<void> _toggleSosLocationSharing(bool enabled) async {
    setState(() {
      _locationEnabledForSos = enabled;
      _isSavingLocationPref = true;
    });
    HapticFeedback.selectionClick();

    try {
      await _repository.savePreferences(locationEnabled: enabled);
      if (mounted) {
        setState(() => _isSavingLocationPref = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled
                ? '📍 Live GPS sharing enabled for SOS alerts'
                : '⚠️ Live GPS sharing turned off for SOS alerts'),
            backgroundColor: enabled ? const Color(0xFF10B981) : AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationEnabledForSos = !enabled;
          _isSavingLocationPref = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update GPS preference: $e')),
        );
      }
    }
  }

  Future<void> _selectDefaultAlertType(String typeId) async {
    if (_selectedEmergencyType == typeId) return;
    setState(() {
      _selectedEmergencyType = typeId;
    });
    HapticFeedback.mediumImpact();

    try {
      await _repository.savePreferences(defaultEmergencyType: typeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert style updated! ✅'),
            backgroundColor: AppColors.purple,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update alert style: $e')),
        );
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await _locationService.requestPermission();
    if (status == LocationPermission.deniedForever) {
      await _locationService.openAppSettings();
    }
    await _refreshGpsDiagnostics();
  }

  void _toggleContactForEmergency(String emergencyId, String contactId) {
    setState(() {
      final currentList = _configMapping[emergencyId] ?? [];
      if (currentList.contains(contactId)) {
        currentList.remove(contactId);
      } else {
        currentList.add(contactId);
      }
      _configMapping[emergencyId] = currentList;
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _saveContactMappings() async {
    setState(() => _isSavingMapping = true);
    HapticFeedback.heavyImpact();
    try {
      for (var contact in _contacts) {
        final contactId = contact['id']?.toString() ?? '';
        final List<String> assignedTypes = [];
        _configMapping.forEach((emergId, contactIds) {
          if (contactIds.contains(contactId)) {
            assignedTypes.add(emergId);
          }
        });
        await _repository.updateContactEmergencies(contactId, assignedTypes);
      }

      if (mounted) {
        setState(() => _isSavingMapping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency Contact Mapping Saved! ✅'),
            backgroundColor: AppColors.purple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingMapping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save mapping: $e')),
        );
      }
    }
  }

  Future<void> _callEmergencyService(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  bool get _isArmed =>
      _contacts.isNotEmpty &&
      (_diagnostics?.hasPermission ?? false) &&
      _locationEnabledForSos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        title: Text(
          'Safety & SOS Settings',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: AppColors.textDark,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.purple.withValues(alpha: 0.08), height: 1),
        ),
        actions: [
          IconButton(
            icon: _isRefreshingGps
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple),
                  )
                : const Icon(Icons.refresh_rounded, color: AppColors.purple),
            tooltip: 'Refresh Diagnostics',
            onPressed: _isRefreshingGps ? null : _loadAllData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : RefreshIndicator(
              onRefresh: _loadAllData,
              color: AppColors.purple,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Overall Safety Readiness & Status Hero Card
                    _buildReadinessOverviewCard()
                        .animate()
                        .fade(duration: 350.ms)
                        .slideY(begin: 0.05),

                    const SizedBox(height: 24),

                    // 2. GPS & Live Location Services Section
                    _buildSectionHeader(
                      title: 'GPS & LOCATION DISPATCH',
                      subtitle: 'Real-time GPS coordinates attached to emergency alerts',
                      icon: Icons.location_on_rounded,
                      iconColor: const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 12),
                    _buildGpsHealthCard()
                        .animate()
                        .fade(delay: 100.ms, duration: 350.ms),
                    const SizedBox(height: 12),
                    _buildSosLocationToggleCard()
                        .animate()
                        .fade(delay: 150.ms, duration: 350.ms),
                    const SizedBox(height: 12),
                    _buildLiveCoordinatesCard()
                        .animate()
                        .fade(delay: 200.ms, duration: 350.ms),
                    const SizedBox(height: 12),
                    _buildDeviceShortcutsCard()
                        .animate()
                        .fade(delay: 250.ms, duration: 350.ms),

                    const SizedBox(height: 28),

                    // 3. Default Emergency Alert Style
                    _buildSectionHeader(
                      title: 'DEFAULT ALERT STYLE',
                      subtitle: 'Primary crisis mode triggered on quick SOS hold',
                      icon: Icons.warning_amber_rounded,
                      iconColor: const Color(0xFFDC2626),
                    ),
                    const SizedBox(height: 12),
                    _buildAlertTypeSelector()
                        .animate()
                        .fade(delay: 300.ms, duration: 350.ms),

                    const SizedBox(height: 28),

                    // 4. Protective Circle & Granular Emergency Mapping
                    _buildSectionHeader(
                      title: 'PROTECTIVE CIRCLE & MAPPING',
                      subtitle: 'Customise which trusted contacts receive specific alerts',
                      icon: Icons.groups_rounded,
                      iconColor: AppColors.purple,
                    ),
                    const SizedBox(height: 12),
                    _buildProtectiveCircleCard()
                        .animate()
                        .fade(delay: 350.ms, duration: 350.ms),
                    const SizedBox(height: 12),
                    _buildCategoryMappingSection()
                        .animate()
                        .fade(delay: 400.ms, duration: 350.ms),

                    const SizedBox(height: 28),

                    // 5. Direct Emergency Services & Crisis Hotlines
                    _buildSectionHeader(
                      title: 'DIRECT EMERGENCY HOTLINES',
                      subtitle: 'One-tap direct dial to national emergency responders',
                      icon: Icons.phone_in_talk_rounded,
                      iconColor: const Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 12),
                    _buildEmergencyHotlinesCard()
                        .animate()
                        .fade(delay: 450.ms, duration: 350.ms),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Section Header ──────────────────────────────────────────────────────────

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: AppColors.textLight,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            subtitle,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
          ),
        ),
      ],
    );
  }

  // ─── 1. Readiness Hero Card ───────────────────────────────────────────────────

  Widget _buildReadinessOverviewCard() {
    final statusColor = _isArmed ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final statusText = _isArmed ? 'Protected & Ready' : 'Setup Incomplete';
    final statusDesc = _isArmed
        ? 'GPS high-accuracy tracking is active with ${_contacts.length} trusted protector${_contacts.length > 1 ? 's' : ''}.'
        : 'Ensure GPS permissions and trusted contacts are configured for full protection.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isArmed
              ? [const Color(0xFFECFDF5), Colors.white]
              : [const Color(0xFFFFFBEB), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _isArmed ? '🛡️' : '⚠️',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusDesc,
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildReadinessMetric(
                  label: 'Protectors',
                  value: '${_contacts.length}/5',
                  isGood: _contacts.isNotEmpty,
                ),
              ),
              Container(width: 1, height: 28, color: Colors.grey.shade200),
              Expanded(
                child: _buildReadinessMetric(
                  label: 'Live GPS',
                  value: _locationEnabledForSos ? 'Active' : 'Disabled',
                  isGood: _locationEnabledForSos && (_diagnostics?.hasPermission ?? false),
                ),
              ),
              Container(width: 1, height: 28, color: Colors.grey.shade200),
              Expanded(
                child: _buildReadinessMetric(
                  label: 'Alert Style',
                  value: _getAlertShortLabel(_selectedEmergencyType),
                  isGood: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/safety/test'),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: Text(
                'Run Non-Emergency SOS Test',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.purple,
                side: BorderSide(color: AppColors.purple.withValues(alpha: 0.35), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessMetric({
    required String label,
    required String value,
    required bool isGood,
  }) {
    final color = isGood ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            color: AppColors.textLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getAlertShortLabel(String id) {
    switch (id) {
      case 'medical_emergency':
        return 'Medical';
      case 'mental_distress':
        return 'Distress';
      case 'safe_walk':
        return 'Safe Walk';
      default:
        return 'Threat';
    }
  }

  // ─── 2. GPS Health & Sharing Cards ──────────────────────────────────────────

  Widget _buildGpsHealthCard() {
    final isGpsOn = _diagnostics?.isServiceEnabled ?? false;
    final hasPerm = _diagnostics?.hasPermission ?? false;
    final isReady = _diagnostics?.isReady ?? false;

    Color statusColor;
    String statusTitle;
    String statusSubtitle;
    IconData statusIcon;

    if (isReady) {
      statusColor = const Color(0xFF10B981);
      statusTitle = 'GPS & Positioning Active';
      statusSubtitle = 'High-accuracy GPS fix is ready for emergency dispatch.';
      statusIcon = Icons.check_circle_rounded;
    } else if (!isGpsOn) {
      statusColor = const Color(0xFFEF4444);
      statusTitle = 'Device GPS is Off';
      statusSubtitle = 'Turn on Location in phone settings to enable live tracking.';
      statusIcon = Icons.location_off_rounded;
    } else if (!hasPerm) {
      statusColor = const Color(0xFFF59E0B);
      statusTitle = 'Permission Required';
      statusSubtitle = 'Grant permission to attach your live GPS location.';
      statusIcon = Icons.security_update_warning_rounded;
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusTitle = 'Acquiring GPS Signal...';
      statusSubtitle = 'Waiting for satellite fix. Tap refresh to test.';
      statusIcon = Icons.satellite_alt_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      statusSubtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildPill(
                label: 'Device GPS',
                isActive: isGpsOn,
                activeText: 'ON',
                inactiveText: 'OFF',
              ),
              _buildPill(
                label: 'Permission',
                isActive: hasPerm,
                activeText: 'GRANTED',
                inactiveText: 'DENIED',
              ),
              if (!hasPerm)
                TextButton.icon(
                  onPressed: _requestLocationPermission,
                  icon: const Icon(Icons.security_rounded, size: 14),
                  label: Text(
                    'Grant Permission',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 11.5),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.purple,
                    backgroundColor: AppColors.purple.withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )
              else if (!isGpsOn)
                TextButton.icon(
                  onPressed: () => _locationService.openLocationSettings(),
                  icon: const Icon(Icons.settings_rounded, size: 14),
                  label: Text(
                    'Enable GPS',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 11.5),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.purple,
                    backgroundColor: AppColors.purple.withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required bool isActive,
    required String activeText,
    required String inactiveText,
  }) {
    final color = isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ${isActive ? activeText : inactiveText}',
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSosLocationToggleCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🚨', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live GPS Dispatch with SOS',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Send real-time Google Maps link to contacts',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _locationEnabledForSos,
                onChanged: _isSavingLocationPref ? null : _toggleSosLocationSharing,
                activeTrackColor: AppColors.purple,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF5FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.purple, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locationEnabledForSos
                        ? 'When SOS is pressed, your trusted contacts immediately receive your live satellite coordinates and route updates.'
                        : 'Warning: When disabled, contacts will receive emergency text alerts but will NOT see your real-time map location.',
                    style: GoogleFonts.nunito(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _locationEnabledForSos ? AppColors.textDark : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCoordinatesCard() {
    final pos = _diagnostics?.position;
    final address = _diagnostics?.address;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.my_location_rounded, color: Color(0xFF10B981), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Current Location Fix',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _isRefreshingGps ? null : _refreshGpsDiagnostics,
                icon: const Icon(Icons.satellite_alt_rounded, size: 13),
                label: Text(
                  _isRefreshingGps ? 'Testing...' : 'Test Fix',
                  style: GoogleFonts.nunito(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.purple,
                  side: BorderSide(color: AppColors.purple.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (pos != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.pin_drop_rounded, color: AppColors.purple, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address ?? 'Address resolved from satellite coordinates',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildMetricItem('Latitude', pos.latitude.toStringAsFixed(5))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildMetricItem('Longitude', pos.longitude.toStringAsFixed(5))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildMetricItem('Accuracy', '±${pos.accuracy.toStringAsFixed(0)} m')),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _diagnostics?.errorMessage ?? 'No satellite fix yet. Tap Test Fix to acquire coordinates.',
                      style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 10.5,
            color: AppColors.textLight,
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDeviceShortcutsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.tune_rounded, color: AppColors.purple, size: 18),
            ),
            title: Text(
              'Open Phone Location / GPS Settings',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textLight),
            onTap: () => _locationService.openLocationSettings(),
          ),
          const Divider(height: 1, indent: 48),
          ListTile(
            dense: true,
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.app_settings_alt_rounded, color: AppColors.purple, size: 18),
            ),
            title: Text(
              'Open App Permissions (Precise Location)',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textLight),
            onTap: () => _locationService.openAppSettings(),
          ),
        ],
      ),
    );
  }

  // ─── 3. Default Emergency Alert Style ────────────────────────────────────────

  Widget _buildAlertTypeSelector() {
    return Column(
      children: kEmergencyTypes.map((type) {
        final isSelected = _selectedEmergencyType == type['id'];
        final color = type['color'] as Color;

        return GestureDetector(
          onTap: () => _selectDefaultAlertType(type['id'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : const Color(0xFFFCFCFD),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : Colors.grey.shade200,
                width: isSelected ? 2.2 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSelected
                          ? (type['gradient'] as List<Color>)
                          : [color.withValues(alpha: 0.12), color.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      type['emoji'] as String,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            type['label'] as String,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: AppColors.textDark,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'DEFAULT',
                                style: GoogleFonts.nunito(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        type['desc'] as String,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? color : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── 4. Protective Circle & Granular Mapping ──────────────────────────────────

  Widget _buildProtectiveCircleCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('👥', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text(
                    'Trusted Circle (${_contacts.length}/5)',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => context.push('/safety/contacts').then((_) => _loadAllData()),
                icon: const Icon(Icons.edit_rounded, size: 14),
                label: Text(
                  _contacts.isEmpty ? 'Add People' : 'Manage',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_contacts.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2F8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_add_alt_1_rounded, color: AppColors.purple, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No trusted contacts configured yet. Add up to 5 contacts to enable SOS dispatch.',
                      style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _contacts.map((c) {
                final name = c['name'] as String? ?? 'Contact';
                final relation = c['relation'] as String? ?? 'Friend';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: AppColors.purple,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$name ($relation)',
                        style: GoogleFonts.nunito(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryMappingSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Row(
              children: [
                const Icon(Icons.alt_route_rounded, color: AppColors.purple, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category-Specific Contact Alerts',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Expand an emergency type to choose which contacts get alerted',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Add trusted contacts above to configure category mappings.',
                  style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textLight),
                ),
              ),
            )
          else ...[
            ..._emergencies.map((emerg) {
              final emergencyId = emerg['id'] as String;
              final mappedContactIds = _configMapping[emergencyId] ?? [];
              final Color color = emerg['color'] as Color;

              return ExpansionTile(
                shape: const Border(),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Text(emerg['icon'] as String, style: const TextStyle(fontSize: 14)),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        emerg['title'] as String,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${mappedContactIds.length}/${_contacts.length} notified',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  emerg['desc'] as String,
                  style: GoogleFonts.nunito(fontSize: 11.5, color: AppColors.textMedium),
                ),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  const Divider(height: 1),
                  ..._contacts.map((contact) {
                    final contactId = contact['id']?.toString() ?? '';
                    final isSelected = mappedContactIds.contains(contactId);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (_) => _toggleContactForEmergency(emergencyId, contactId),
                      activeColor: AppColors.purple,
                      dense: true,
                      title: Text(
                        contact['name'] as String? ?? 'Contact',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      subtitle: Text(
                        '${contact['relation'] ?? 'Friend'} • ${contact['phone']}',
                        style: GoogleFonts.nunito(fontSize: 11.5),
                      ),
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                ],
              );
            }),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _isSavingMapping ? null : _saveContactMappings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSavingMapping
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Save Contact Mappings',
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 13.5),
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── 5. Emergency Hotlines ───────────────────────────────────────────────────

  Widget _buildEmergencyHotlinesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildHotlineTile(
            title: '112 — National Emergency Dispatch',
            subtitle: 'Police, Ambulance & Fire Response',
            icon: Icons.emergency_rounded,
            color: const Color(0xFFDC2626),
            onTap: () => _callEmergencyService('112'),
          ),
          const Divider(height: 1, indent: 56),
          _buildHotlineTile(
            title: '1091 — Women Safety Helpline',
            subtitle: 'National Commission for Women 24/7 Helpline',
            icon: Icons.shield_rounded,
            color: const Color(0xFF7C3AED),
            onTap: () => _callEmergencyService('1091'),
          ),
          const Divider(height: 1, indent: 56),
          _buildHotlineTile(
            title: '9999 666 555 — Vandrevala Mental Health',
            subtitle: 'Free & Confidential 24/7 Crisis Support',
            icon: Icons.psychology_rounded,
            color: const Color(0xFF0D9488),
            onTap: () => _callEmergencyService('9999666555'),
          ),
        ],
      ),
    );
  }

  Widget _buildHotlineTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textDark),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.nunito(fontSize: 11.5, color: AppColors.textMedium),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.call_rounded, color: color, size: 16),
      ),
      onTap: onTap,
    );
  }
}
