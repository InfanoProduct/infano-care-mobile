import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/shared/widgets/gradient_button.dart';

class PermissionsOnboardingSheet extends StatelessWidget {
  const PermissionsOnboardingSheet({super.key, required this.onAllow, required this.onDeny});
  final VoidCallback onAllow, onDeny;

  static Future<void> show(BuildContext context, {required VoidCallback onAllow, required VoidCallback onDeny}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PermissionsOnboardingSheet(onAllow: onAllow, onDeny: onDeny),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 32),
          const Text('📲', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 24),
          Text('Make Login Easier!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          const Text(
            'By allowing Infano to read your SMS, we can automatically fill in your 4-digit code. No more switching apps or typing errors!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMedium, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 40),
          GradientButton(
            label: 'Allow SMS Auto-fill ✨',
            onPressed: () {
              Navigator.pop(context);
              onAllow();
            },
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDeny();
            },
            child: const Text('I\'ll type it manually', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
