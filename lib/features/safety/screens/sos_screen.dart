import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/safety/widgets/sos_button.dart';

class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5FF), // Light purple background
      appBar: AppBar(
        title: Text(
          'Emergency SOS Hub',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: AppColors.purple),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.purple),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🚨', style: TextStyle(fontSize: 36)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency Response',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hold the SOS button for 3 seconds to immediately alert your configured emergency contacts with your live location.',
                            style: GoogleFonts.nunito(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),

              // The SOS Button
              const Center(
                child: SosButton(),
              ),

              const SizedBox(height: 60),

              // Settings and Navigation Options
              Text(
                'Safety Configurations',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildConfigCard(
                      context,
                      icon: '👥',
                      title: 'Trusted Contacts',
                      subtitle: 'Add up to 5 people',
                      path: '/safety/contacts',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildConfigCard(
                      context,
                      icon: '⚙️',
                      title: 'Configure SOS',
                      subtitle: 'Assign per emergency',
                      path: '/safety/sos_config',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Crisis resource banner
              GestureDetector(
                onTap: () {
                  // Direct to crisis resources
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Direct support: Vandrevala Foundation Helpline 9999666555 available 24/7.',
                        style: GoogleFonts.nunito(),
                      ),
                      backgroundColor: AppColors.purple,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Text('📞', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Need to talk to someone?',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              'Find free, immediate crisis support helplines.',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: AppColors.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigCard(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required String path,
  }) {
    return GestureDetector(
      onTap: () => context.push(path),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
