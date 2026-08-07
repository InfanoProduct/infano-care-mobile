import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/features/safety/widgets/sos_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The new SOS Orb Button with 3-second hold
          const SosButton(),
          const SizedBox(height: 24),
          
          TextButton.icon(
            onPressed: () => context.push('/safety/contacts'),
            icon: const Icon(Icons.group_add_outlined, color: AppColors.purple),
            label: const Text(
              'Manage Trusted Contacts',
              style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: AppColors.purple.withValues(alpha: 0.3)),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          const Text('🌸', style: TextStyle(fontSize: 60))
            .animate(onPlay: (c) => c.repeat())
            .scaleXY(begin: 0.9, end: 1.1, duration: 2000.ms, curve: Curves.easeInOut)
            .then().scaleXY(begin: 1.1, end: 0.9, duration: 2000.ms),
          const SizedBox(height: 24),
          Text('Welcome Home!', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 12),
          Text('Your Infano.Care dashboard is here!',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }
}
