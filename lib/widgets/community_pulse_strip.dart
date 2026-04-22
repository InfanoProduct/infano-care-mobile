import 'package:flutter/material.dart';
import 'package:infano_care_mobile/models/circle.dart';
import 'package:infano_care_mobile/widgets/circle_card.dart';
import 'package:go_router/go_router.dart';

class CommunityPulseStrip extends StatefulWidget {
  final List<Circle> circles;

  const CommunityPulseStrip({Key? key, required this.circles}) : super(key: key);

  @override
  State<CommunityPulseStrip> createState() => _CommunityPulseStripState();
}

class _CommunityPulseStripState extends State<CommunityPulseStrip> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    final pulseCircles = widget.circles.take(3).toList();
    _controllers = List.generate(
      pulseCircles.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _animations = _controllers.map((controller) {
      return CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      );
    }).toList();

    _startAnimations();
  }

  void _startAnimations() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(Duration(milliseconds: 100 * i));
      if (mounted) _controllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pulseCircles = widget.circles.take(3).toList();
    if (pulseCircles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Community Pulse',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to the first pulse circle or a general view
                  if (pulseCircles.isNotEmpty) {
                    context.push('/community/circle', extra: pulseCircles.first);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'View in Circle',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.pink,
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.pink),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 125,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: pulseCircles.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return ScaleTransition(
                scale: _animations[index],
                child: FadeTransition(
                  opacity: _animations[index],
                  child: SizedBox(
                    width: 140, // Compact card width
                    child: CircleCard(circle: pulseCircles[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
