import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

/// Floating "+N points" animated badge that floats upward and fades out.
class PointsBurst extends StatefulWidget {
  const PointsBurst({super.key, required this.points, this.onComplete});
  final int points;
  final VoidCallback? onComplete;

  @override
  State<PointsBurst> createState() => _PointsBurstState();
}

class _PointsBurstState extends State<PointsBurst> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _visible = false);
      widget.onComplete?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Animate(
      effects: [
        FadeEffect(duration: 300.ms),
        SlideEffect(begin: const Offset(0, 0.5), end: Offset.zero, duration: 300.ms),
        FadeEffect(delay: 1000.ms, duration: 400.ms, begin: 1, end: 0),
        SlideEffect(
          delay: 1000.ms, duration: 400.ms,
          begin: Offset.zero, end: const Offset(0, -0.5),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppGradients.brand,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          '+${widget.points} 🌸',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
    );
  }
}
