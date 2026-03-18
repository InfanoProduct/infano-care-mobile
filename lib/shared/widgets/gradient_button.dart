import 'package:flutter/material.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

/// Pill-shaped gradient CTA button (purple → pink).
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: enabled ? AppGradients.brand : null,
            color: enabled ? null : AppColors.textLight,
            borderRadius: BorderRadius.circular(100),
            boxShadow: enabled ? [
              BoxShadow(
                color: AppColors.purple.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ] : null,
          ),
          child: Center(
            child: Text(
              icon != null ? '$icon  $label' : label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
