import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/shared/widgets/gradient_button.dart';
import 'package:infano_care_mobile/shared/widgets/onboarding_scaffold.dart';

class ParentalConsentScreen extends StatefulWidget {
  const ParentalConsentScreen({super.key});

  @override
  State<ParentalConsentScreen> createState() => _ParentalConsentScreenState();
}

class _ParentalConsentScreenState extends State<ParentalConsentScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;

  bool get _validEmail {
    final email = _emailController.text.trim();
    return RegExp(r'^[\w\.\-]+@[\w\-]+\.\w+$').hasMatch(email);
  }

  Future<void> _sendNote() async {
    setState(() { _loading = true; _error = null; });
    try {
      // TODO: call repository.sendConsentEmail
      await Future.delayed(const Duration(seconds: 1));  // simulate
      if (mounted) context.go('/onboarding/consent/waiting');
    } catch (e) {
      setState(() { _error = 'Failed to send email. Please try again.'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 4,
      totalSteps: 13,
      bottomBar: GradientButton(label: 'Send the Note 💌', onPressed: _sendNote, enabled: _validEmail),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text('👨‍👧', style: TextStyle(fontSize: 64)).animate().fadeIn(),
              const SizedBox(height: 20),
              Text('One small step!', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text("Because you're under 13, we need a quick thumbs-up from your parent or guardian. It only takes a minute for them, and then you're in!",
                style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: "Parent or Guardian's email",
                  prefixIcon: Icon(Icons.mail_outline_rounded, color: AppColors.purple),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              Text("We'll send them a friendly note — no spam, just a one-time approval link.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textLight)),
            ],
          ).animate().fadeIn(duration: 400.ms),
        ),
      ),
    );
  }
}
