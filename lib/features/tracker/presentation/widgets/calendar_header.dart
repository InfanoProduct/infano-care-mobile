import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

/// Displays the current view month/year with animated prev/next chevrons.
/// Navigation callbacks are guarded externally by [CalendarCubit.changeMonth].
class CalendarHeader extends StatelessWidget {
  final int year;
  final int month;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final bool isRefreshing;

  const CalendarHeader({
    super.key,
    required this.year,
    required this.month,
    required this.onPrevMonth,
    required this.onNextMonth,
    this.isRefreshing = false,
  });

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavButton(
            icon: Icons.chevron_left_rounded,
            onTap: onPrevMonth,
            semanticLabel: 'Previous month',
          ),
          Expanded(
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    _months[month - 1],
                    key: ValueKey('$year-$month'),
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$year',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: AppColors.textMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isRefreshing) ...[
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.purple.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _NavButton(
            icon: Icons.chevron_right_rounded,
            onTap: onNextMonth,
            semanticLabel: 'Next month',
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms);
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  const _NavButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: AppColors.purple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: AppColors.purple, size: 22),
          ),
        ),
      ),
    );
  }
}
