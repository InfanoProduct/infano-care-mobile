import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import '../models/creative_journey_models.dart';

class NodeBubbleWidget extends StatelessWidget {
  final CreativeNode node;
  final NodeProgress progress;
  final int index;
  final VoidCallback? onTap;

  const NodeBubbleWidget({
    super.key,
    required this.node,
    required this.progress,
    required this.index,
    this.onTap,
  });

  static const List<List<Color>> _completedPastelGradients = [
    [Color(0xFFEDE9FE), Color(0xFFDDD6FE)], // Soft Lavender
    [Color(0xFFFCE7F3), Color(0xFFFBCFE8)], // Soft Rose
    [Color(0xFFD1FAE5), Color(0xFFA7F3D0)], // Soft Mint
    [Color(0xFFDBEAFE), Color(0xFFBFDBFE)], // Soft Sky Blue
    [Color(0xFFFEF3C7), Color(0xFFFDE68A)], // Soft Peach
  ];

  static const List<Color> _completedPastelBorders = [
    Color(0xFFA78BFA),
    Color(0xFFF472B6),
    Color(0xFF34D399),
    Color(0xFF60A5FA),
    Color(0xFFFBBF24),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: progress.isTappable
          ? onTap
          : () => _showLockedTooltip(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        width: 72,
        height: 72,
        decoration: _buildDecoration(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildBubbleContent(),
            if (progress.isCompleted) _buildCheckBadge(),
            if (progress.isLocked) _buildLockBadge(),
          ],
        ),
      ).animate(target: progress.isUnlocked ? 1.0 : 0.0)
          .scaleXY(begin: 0.95, end: 1.05, duration: 1200.ms, curve: Curves.easeInOut)
          .then()
          .scaleXY(begin: 1.05, end: 0.95, duration: 1200.ms),
    );
  }

  BoxDecoration _buildDecoration() {
    final colorIdx = index % _completedPastelGradients.length;
    final gradientColors = _completedPastelGradients[colorIdx];
    final borderColor = _completedPastelBorders[colorIdx];

    if (progress.isCompleted) {
      return BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.8),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }

    if (progress.isUnlocked || progress.isInProgress) {
      return BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: borderColor,
          width: 3.0,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.4),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      );
    }

    // Locked
    return BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFFF3F4F6),
      border: Border.all(
        color: const Color(0xFFE5E7EB),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildBubbleContent() {
    if (progress.isLocked) {
      return Opacity(
        opacity: 0.45,
        child: Text(
          node.emoji,
          style: const TextStyle(fontSize: 26),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          node.emoji,
          style: TextStyle(
            fontSize: progress.isCompleted ? 26 : 28,
          ),
        ),
        if (progress.isInProgress)
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 24,
            height: 3,
            decoration: BoxDecoration(
              color: _completedPastelBorders[index % _completedPastelBorders.length],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }

  Widget _buildCheckBadge() {
    final borderColor = _completedPastelBorders[index % _completedPastelBorders.length];

    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(
          Icons.check_circle_rounded,
          color: borderColor,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildLockBadge() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 4,
            ),
          ],
        ),
        child: const Icon(
          Icons.lock_rounded,
          color: Color(0xFF9CA3AF),
          size: 13,
        ),
      ),
    );
  }

  void _showLockedTooltip(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Text('🔒', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Complete the previous node first!',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
          ),
        ]),
        backgroundColor: AppColors.textDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
