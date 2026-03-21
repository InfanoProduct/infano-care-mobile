import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, required this.storage});

  final LocalStorageService storage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 32),
            _buildInfoSection(context),
            const SizedBox(height: 48),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppGradients.brandDiagonal,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Center(
            child: Text('👤', style: TextStyle(fontSize: 48)),
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 16),
        Text(
          storage.displayName ?? 'Infano User',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        Text(
          storage.phone ?? '',
          style: const TextStyle(fontSize: 14, color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.stars, 'Points earned', '${storage.points} ✨'),
          const Divider(height: 32),
          _buildInfoRow(Icons.verified_user_outlined, 'User ID', storage.userId?.substring(0, 8) ?? 'N/A'),
          const Divider(height: 32),
          _buildInfoRow(Icons.calendar_today_outlined, 'Birthday', 
            storage.birthMonth != null ? '${storage.birthMonth}/${storage.birthYear}' : 'Not set'),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.purple, size: 24),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 16)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textDark)),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _handleLogout(context),
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: const Text('Logout Session', style: TextStyle(color: AppColors.error)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: AppColors.error.withOpacity(0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to sign out? Your progress is saved safely.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await storage.clearAll();
      if (context.mounted) {
        context.go('/splash');
      }
    }
  }
}
