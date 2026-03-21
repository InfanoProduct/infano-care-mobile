import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/shared/widgets/gradient_button.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';

class AssentTermsScreen extends StatefulWidget {
  const AssentTermsScreen({super.key});

  @override
  State<AssentTermsScreen> createState() => _AssentTermsScreenState();
}

class _AssentTermsScreenState extends State<AssentTermsScreen> {
  bool _terms    = false;
  bool _privacy  = false;
  bool _marketing = false;
  int? _expanded;
  bool _loading  = false;

  static const _accordionItems = [
    ('What Infano.Care does', 'A safe, age-appropriate platform for young girls to learn about their bodies, track their health, and build confidence — in a supportive community free from ads or data selling.'),
    ('Your privacy', 'We collect only your name, phone number, birth year, and what you choose to share. We never sell your data. You can delete your account at any time.'),
    ('How we keep you safe', 'All content is reviewed by health educators. Our community is moderated. You control your privacy settings. COPPA-compliant for users under 13.'),
    ('Your rights', 'You can update or delete your data, change your preferences, or leave at any time. All your data belongs to you.'),
    ('Community rules', 'Be kind. Be yourself. No bullying, no sharing personal info publicly. We have a zero-tolerance policy for harmful content.'),
  ];

  bool get _canContinue => _terms && _privacy;

  Future<void> _letsBloom() async {
    final bloc = context.read<OnboardingBloc>();
    final storage = await LocalStorageService.create();
    
    // Save locally and update state
    await storage.setConsents(terms: _terms, privacy: _privacy, marketing: _marketing);
    bloc.add(SetConsent(_terms, _privacy, _marketing));
    
    // Since registration already happened at OTP verification for new users,
    // we can proceed directly to welcome. 
    // If we wanted to update terms in backend, we'd need a separate API, 
    // but for now this is sufficient.
    if (mounted) {
      context.go('/onboarding/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 10,
      bottomBar: GradientButton(
        label: "Let's Bloom! 🌸",
        onPressed: _letsBloom,
        enabled: _canContinue && !_loading,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Here\'s how we take care of you 💜',
                style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 24),
              // Accordion
              ..._accordionItems.asMap().entries.map((e) =>
                _AccordionCard(
                  index: e.key,
                  title: e.value.$1,
                  content: e.value.$2,
                  expanded: _expanded == e.key,
                  onTap: () => setState(() => _expanded = _expanded == e.key ? null : e.key),
                ).animate(delay: Duration(milliseconds: e.key * 80)).fadeIn(duration: 300.ms),
              ),
              const SizedBox(height: 24),
              // Checkboxes
              _Checkbox(
                value: _terms,
                label: 'I\'ve read and agree to the Terms of Service',
                onChanged: (v) => setState(() => _terms = v ?? false),
              ),
              const SizedBox(height: 8),
              _Checkbox(
                value: _privacy,
                label: 'I understand and agree to the Privacy Policy',
                onChanged: (v) => setState(() => _privacy = v ?? false),
              ),
              const SizedBox(height: 8),
              _Checkbox(
                value: _marketing,
                label: 'I\'d love tips and updates by SMS (optional)',
                onChanged: (v) => setState(() => _marketing = v ?? false),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccordionCard extends StatelessWidget {
  const _AccordionCard({required this.index, required this.title, required this.content, required this.expanded, required this.onTap});
  final int index;
  final String title, content;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: expanded ? AppColors.purple : const Color(0xFFE9D5FF), width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(['📌','🔒','🛡️','⚡','🤝'][index], style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark))),
                Icon(expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.purple),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 12),
              Text(content, style: const TextStyle(color: AppColors.textMedium, height: 1.6)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.value, required this.label, required this.onChanged});
  final bool value;
  final String label;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.purple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Expanded(child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(label, style: const TextStyle(color: AppColors.textDark, fontSize: 14)),
        )),
      ],
    );
  }
}
