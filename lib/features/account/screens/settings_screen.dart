import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/core/services/notification_service.dart';
import 'package:infano_care_mobile/l10n/generated/app_localizations.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.storage});

  final LocalStorageService? storage;

  LocalStorageService _getStorage(BuildContext context) {
    return storage ?? Provider.of<LocalStorageService>(context, listen: false);
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to sign out? Your progress is saved safely.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // 1. If mentor, clear availability on server before clearing local storage
      try {
        final api = Provider.of<CommunityApi>(context, listen: false);
        final status = await api.getMentorStatus();
        if (status['is_certified'] == true) {
          await api.updateMentorAvailability(false);
        }
      } catch (e) {
        debugPrint('Logout: Could not clear availability: $e');
      }

      // 2. Unregister FCM token from backend so logged out users don't receive notifications
      try {
        await NotificationService().unregisterToken();
      } catch (e) {
        debugPrint('Logout: Could not unregister FCM token: $e');
      }

      // 3. Clear local storage
      final localStorage = _getStorage(context);
      await localStorage.clearAll();

      if (context.mounted) {
        context.go('/splash');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final storage = _getStorage(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F7),
      appBar: AppBar(
        title: Text(
          l10n.settingsTitle,
          style: const TextStyle(
            color: AppColors.purple,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.purple),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                l10n.settingsSectionPreferences,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildNavRow(
                    context,
                    icon: Icons.shield_outlined,
                    label: l10n.settingsSafetySos,
                    route: '/safety/sos_config',
                    iconColor: AppColors.purple,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildNavRow(
                    context,
                    icon: Icons.emergency_outlined,
                    label: l10n.settingsSafetyHub,
                    route: '/safety/sos',
                    iconColor: const Color(0xFFEF4444),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildNavRow(
                    context,
                    icon: Icons.notifications_none_rounded,
                    label: l10n.settingsDataNotifications,
                    route: '/account/notifications',
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildNavRow(
                    context,
                    icon: Icons.shield_outlined,
                    label: l10n.settingsHealthPrivacy,
                    route: '/account/data-rights',
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),

            const SizedBox(height: 28),

            // ── APPEARANCE & LANGUAGE ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                l10n.settingsSectionAppearance,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildLanguageRow(context, storage, l10n),
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05),

            const SizedBox(height: 28),

            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                l10n.settingsSectionAccount,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                ),
                title: Text(
                  l10n.logOut,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  l10n.logOutSubtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                onTap: () => _handleLogout(context),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildNavRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    Color iconColor = AppColors.purple,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () => context.push(route),
    );
  }

  // ── Language row & picker ──────────────────────────────────────────────────

  /// Maps a language code to its display name and flag.
  static const _languages = [
    {'code': 'en', 'label': 'English', 'flag': '🇬🇧'},
    {'code': 'hi', 'label': 'हिन्दी (Hindi)', 'flag': '🇮🇳'},
  ];

  Widget _buildLanguageRow(
    BuildContext context,
    LocalStorageService storage,
    AppLocalizations l10n,
  ) {
    final current = _languages.firstWhere(
      (l) => l['code'] == storage.appLocale,
      orElse: () => _languages.first,
    );

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.purple.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.language_rounded, color: AppColors.purple, size: 20),
      ),
      title: Text(
        l10n.language,
        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
      ),
      subtitle: Text(
        '${current['flag']}  ${current['label']}',
        style: const TextStyle(fontSize: 13, color: AppColors.textLight),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () => _showLanguagePicker(context, storage, l10n),
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    LocalStorageService storage,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  l10n.selectLanguage,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                ..._languages.map((lang) {
                  final isSelected = storage.appLocale == lang['code'];
                  return GestureDetector(
                    onTap: () async {
                      await storage.setAppLocale(lang['code']!);
                      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.purple.withValues(alpha: 0.08)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.purple : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            lang['flag']!,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              lang['label']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.purple
                                    : AppColors.textDark,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.purple,
                              size: 22,
                            ),
                        ],
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
}
