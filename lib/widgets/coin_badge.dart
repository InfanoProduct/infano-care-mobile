import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CoinBadge extends StatefulWidget {
  final int coins;
  final String? label;
  final double fontSize;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const CoinBadge({
    super.key,
    required this.coins,
    this.label,
    this.fontSize = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.onTap,
  });

  @override
  State<CoinBadge> createState() => _CoinBadgeState();
}

class _CoinBadgeState extends State<CoinBadge> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0).chain(CurveTween(curve: Curves.elasticIn)), weight: 50),
    ]).animate(_pulseController);
  }

  @override
  void didUpdateWidget(CoinBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.coins != oldWidget.coins) {
      _pulseController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () {
          _pulseController.forward(from: 0.0);
          widget.onTap?.call();
        },
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDBA74).withValues(alpha: 0.6), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF97316).withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🪙', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(
                '${widget.coins} ${widget.label ?? 'Coins'}',
                style: GoogleFonts.nunito(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF9A3412),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
