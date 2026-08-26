import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/location_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/safety/data/safety_repository.dart';

class LocationSettingsScreen extends StatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  final SafetyRepository _repository = SafetyRepository(ApiService.instance.dio);
  final LocationHelperService _locationService = LocationHelperService.instance;

  bool _isLoading = true;
  bool _isRefreshingGps = false;
  bool _isSavingPref = false;

  // Preferences state
  bool _locationEnabledForSos = true;

  // Diagnostics state
  LocationDiagnostics? _diagnostics;

  @override
  void initState() {
    super.initState();
    _loadAllSettings();
  }

  Future<void> _loadAllSettings() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repository.getPreferences(),
        _locationService.runDiagnostics(),
      ]);

      final prefs = results[0] as SosPreferences;
      final diag = results[1] as LocationDiagnostics;

      if (mounted) {
        setState(() {
          _locationEnabledForSos = prefs.locationEnabled;
          _diagnostics = diag;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
      _isSavingPref = true;
    });

    try {
      await _repository.savePreferences(locationEnabled: enabled);
      if (mounted) {
        setState(() => _isSavingPref = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled
                ? 'Location sharing enabled for SOS alerts 📍'
                : 'Location sharing turned off for SOS alerts'),
            backgroundColor: AppColors.purple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationEnabledForSos = !enabled;
          _isSavingPref = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update preference: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        title: Text(
          'Location & GPS Settings',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: AppColors.purple,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.purple),
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
            tooltip: 'Refresh GPS',
            onPressed: _isRefreshingGps ? null : _refreshGpsDiagnostics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : RefreshIndicator(
              onRefresh: _loadAllSettings,
              color: AppColors.purple,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Live GPS Health Card
                    _buildGpsHealthCard()
                        .animate()
                        .fade(duration: 350.ms)
                        .slideY(begin: 0.05),

                    const SizedBox(height: 24),

                    // 2. SOS Location Sharing Toggle Card
                    _buildSosSharingCard()
                        .animate()
                        .fade(duration: 400.ms)
                        .slideY(begin: 0.05),

                    const SizedBox(height: 24),

                    // 3. Live Coordinates & Reverse-Geocoded Address
                    _buildLivePositionCard()
                        .animate()
                        .fade(duration: 450.ms)
                        .slideY(begin: 0.05),

                    const SizedBox(height: 24),

                    // 4. Quick Device & App Settings Actions
                    _buildDeviceSettingsSection()
                        .animate()
                        .fade(duration: 500.ms)
                        .slideY(begin: 0.05),

                    const SizedBox(height: 24),

                    // 5. How Location Sharing Works in SOS
                    _buildExplainerCard()
                        .animate()
                        .fade(duration: 550.ms)
                        .slideY(begin: 0.05),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGpsHealthCard() {
    final isGpsOn = _diagnostics?.isServiceEnabled ?? false;
    final hasPerm = _diagnostics?.hasPermission ?? false;
    final isReady = _diagnostics?.isReady ?? false;

    Color statusColor;
    String statusTitle;
    String statusSubtitle;
    IconData statusIcon;

    if (isReady) {
      statusColor = const Color(0xFF10B981); // Emerald Green
      statusTitle = 'GPS & Location Active';
      statusSubtitle = 'High-accuracy positioning is ready for emergency SOS dispatch.';
      statusIcon = Icons.check_circle_rounded;
    } else if (!isGpsOn) {
      statusColor = const Color(0xFFEF4444); // Red
      statusTitle = 'Device GPS is Switched Off';
      statusSubtitle = 'Turn on Location in your device settings to enable SOS tracking.';
      statusIcon = Icons.location_off_rounded;
    } else if (!hasPerm) {
      statusColor = const Color(0xFFF59E0B); // Amber
      statusTitle = 'Location Permission Required';
      statusSubtitle = 'Infano Care needs permission to access location for SOS alerts.';
      statusIcon = Icons.security_update_warning_rounded;
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusTitle = 'Acquiring GPS Signal...';
      statusSubtitle = 'Waiting for satellite or network fix. Tap refresh to test.';
      statusIcon = Icons.satellite_alt_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 26),
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
                        fontSize: 17,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusSubtitle,
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
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 12),
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
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 12),
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

  Widget _buildSosSharingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                      'SOS Live Location Sharing',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Attach live Google Maps link in emergency alerts',
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
                onChanged: _isSavingPref ? null : _toggleSosLocationSharing,
                activeTrackColor: AppColors.purple,
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                const Icon(Icons.info_outline_rounded, color: AppColors.purple, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _locationEnabledForSos
                        ? 'When SOS is pressed, your trusted contacts immediately receive your live GPS coordinates & map route.'
                        : 'Warning: When disabled, contacts will receive SOS text but will NOT see your real-time GPS map location.',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
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

  Widget _buildLivePositionCard() {
    final pos = _diagnostics?.position;
    final address = _diagnostics?.address;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                child: const Icon(Icons.my_location_rounded, color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Current GPS Fix',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _isRefreshingGps ? null : _refreshGpsDiagnostics,
                icon: const Icon(Icons.satellite_alt_rounded, size: 14),
                label: Text(
                  _isRefreshingGps ? 'Testing...' : 'Test Fix',
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.purple,
                  side: BorderSide(color: AppColors.purple.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (pos != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.pin_drop_rounded, color: AppColors.purple, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address ?? 'Address resolved from satellite coordinates',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _diagnostics?.errorMessage ??
                          'No GPS fix available. Ensure GPS is enabled and location permission is granted.',
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
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
            fontSize: 11,
            color: AppColors.textLight,
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDeviceSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.tune_rounded, color: AppColors.purple, size: 20),
            ),
            title: Text(
              'Open Phone Location / GPS Settings',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              'Turn device location ON/OFF or switch accuracy modes',
              style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMedium),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
            onTap: () => _locationService.openLocationSettings(),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.app_settings_alt_rounded, color: AppColors.purple, size: 20),
            ),
            title: Text(
              'Open App Permissions',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              'Grant "Precise Location" & "Allow all the time"',
              style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMedium),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
            onTap: () => _locationService.openAppSettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildExplainerCard() {
    final lat = _diagnostics?.position?.latitude ?? 28.6139;
    final lng = _diagnostics?.position?.longitude ?? 77.2090;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF3E8FF),
            Color(0xFFFCE7F3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🛡️', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'How SOS Location Sharing Works',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: const Color(0xFF4C1D95),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '1. When you trigger SOS, your live coordinates are acquired in under 2 seconds.\n'
            '2. An SMS & app alert is dispatched immediately to your configured trusted protectors with a clickable Google Maps link:\n'
            '   https://maps.google.com/?q=${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}\n'
            '3. While SOS remains active, live coordinates refresh automatically every 30 seconds until you tap "I Am Safe Now".',
            style: GoogleFonts.nunito(
              fontSize: 12.5,
              height: 1.5,
              color: const Color(0xFF5B21B6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
