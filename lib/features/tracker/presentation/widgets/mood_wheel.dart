import 'dart:math';
import 'package:flutter/material.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

class MoodState {
  final String id;
  final String emoji;
  final Color color;
  final String arousal; // High/Low
  final String valence; // Positive/Negative

  MoodState({
    required this.id,
    required this.emoji,
    required this.color,
    required this.arousal,
    required this.valence,
  });
}

class MoodWheel extends StatefulWidget {
  final Function(MoodState) onMoodSelected;
  final MoodState? initialMood;

  const MoodWheel({
    super.key,
    required this.onMoodSelected,
    this.initialMood,
  });

  @override
  State<MoodWheel> createState() => _MoodWheelState();
}

class _MoodWheelState extends State<MoodWheel> with SingleTickerProviderStateMixin {
  late List<MoodState> _moods;
  MoodState? _selectedMood;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.initialMood;
    _moods = [
      MoodState(id: 'joyful', emoji: '😄', color: const Color(0xFFFBBF24), arousal: 'High', valence: 'Positive'),
      MoodState(id: 'excited', emoji: '🤩', color: const Color(0xFFF97316), arousal: 'High', valence: 'Positive'),
      MoodState(id: 'energized', emoji: '⚡', color: const Color(0xFFEF4444), arousal: 'High', valence: 'Positive'),
      MoodState(id: 'motivated', emoji: '💪', color: const Color(0xFFEC4899), arousal: 'High', valence: 'Positive'),
      MoodState(id: 'content', emoji: '🙂', color: const Color(0xFFA855F7), arousal: 'Low', valence: 'Positive'),
      MoodState(id: 'calm', emoji: '😌', color: const Color(0xFF8B5CF6), arousal: 'Low', valence: 'Positive'),
      MoodState(id: 'grateful', emoji: '🥹', color: const Color(0xFF6366F1), arousal: 'Low', valence: 'Positive'),
      MoodState(id: 'hopeful', emoji: '🌱', color: const Color(0xFF3B82F6), arousal: 'Low', valence: 'Positive'),
      MoodState(id: 'anxious', emoji: '😰', color: const Color(0xFF0EA5E9), arousal: 'High', valence: 'Negative'),
      MoodState(id: 'irritable', emoji: '😠', color: const Color(0xFF0D9488), arousal: 'High', valence: 'Negative'),
      MoodState(id: 'restless', emoji: '😤', color: const Color(0xFF15803D), arousal: 'High', valence: 'Negative'),
      MoodState(id: 'overwhelmed', emoji: '😵', color: const Color(0xFF65A30D), arousal: 'High', valence: 'Negative'),
      MoodState(id: 'sad', emoji: '😔', color: const Color(0xFFCA8A04), arousal: 'Low', valence: 'Negative'),
      MoodState(id: 'tired', emoji: '😴', color: const Color(0xFFB45309), arousal: 'Low', valence: 'Negative'),
      MoodState(id: 'numb', emoji: '😶', color: const Color(0xFF92400E), arousal: 'Low', valence: 'Negative'),
      MoodState(id: 'withdrawn', emoji: '🫥', color: const Color(0xFF7C2D12), arousal: 'Low', valence: 'Negative'),
    ];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(Offset localPosition, double size) {
    final center = size / 2;
    final dx = localPosition.dx - center;
    final dy = localPosition.dy - center;
    final distance = sqrt(dx * dx + dy * dy);
    
    // Donut Hit Test (Ensure tap is within the wheel ring)
    final outerRadius = size / 2;
    final innerRadius = outerRadius * 0.4;
    
    if (distance < innerRadius || distance > outerRadius) return;

    // Calculate Angle
    var angle = atan2(dy, dx) + (pi / 2);
    if (angle < 0) angle += 2 * pi;

    final segmentAngle = (2 * pi) / _moods.length;
    final index = (angle / segmentAngle).floor() % _moods.length;

    setState(() {
      _selectedMood = _moods[index];
      widget.onMoodSelected(_selectedMood!);
      _controller.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onTapDown: (details) => _handleTap(details.localPosition, size),
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(size, size),
                  painter: MoodWheelPainter(
                    moods: _moods,
                    selectedMoodId: _selectedMood?.id,
                    animationValue: _controller.value,
                  ),
                ),
                // Center Emoji and Label
                if (_selectedMood != null)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedMood!.emoji,
                        style: TextStyle(fontSize: size * 0.12),
                      ),
                      Text(
                        _selectedMood!.id[0].toUpperCase() + _selectedMood!.id.substring(1),
                        style: TextStyle(
                          fontSize: size * 0.045,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MoodWheelPainter extends CustomPainter {
  final List<MoodState> moods;
  final String? selectedMoodId;
  final double animationValue;

  MoodWheelPainter({
    required this.moods,
    this.selectedMoodId,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.4;
    final segmentAngle = (2 * pi) / moods.length;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < moods.length; i++) {
      final mood = moods[i];
      final startAngle = -pi / 2 + (i * segmentAngle);
      final isSelected = mood.id == selectedMoodId;

      // Draw segment arc
      var sRadius = outerRadius;
      var iRadius = innerRadius;
      
      if (isSelected) {
        sRadius *= (1.0 + (0.1 * animationValue));
        iRadius *= (1.0 - (0.05 * animationValue));
      } else if (selectedMoodId != null) {
        sRadius *= 0.95;
      }

      final path = Path()
        ..moveTo(
          center.dx + iRadius * cos(startAngle),
          center.dy + iRadius * sin(startAngle),
        )
        ..lineTo(
          center.dx + sRadius * cos(startAngle),
          center.dy + sRadius * sin(startAngle),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: sRadius),
          startAngle,
          segmentAngle * 0.95, // Gap between segments
          false,
        )
        ..lineTo(
          center.dx + iRadius * cos(startAngle + segmentAngle * 0.95),
          center.dy + iRadius * sin(startAngle + segmentAngle * 0.95),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: iRadius),
          startAngle + segmentAngle * 0.95,
          -segmentAngle * 0.95,
          false,
        )
        ..close();

      paint.color = mood.color.withOpacity(isSelected ? 1.0 : (selectedMoodId == null ? 0.7 : 0.3));
      
      if (isSelected) {
        canvas.drawShadow(path, Colors.black26, 8, true);
      }
      
      canvas.drawPath(path, paint);
      
      // Draw Emoji on segment
      if (!isSelected || animationValue > 0.5) {
        final labelAngle = startAngle + (segmentAngle / 2);
        final labelRadius = (sRadius + iRadius) / 2;
        final labelOffset = Offset(
          center.dx + labelRadius * cos(labelAngle) - (isSelected ? 10 : 8),
          center.dy + labelRadius * sin(labelAngle) - (isSelected ? 10 : 8),
        );
        
        TextPainter(
          text: TextSpan(
            text: mood.emoji,
            style: TextStyle(fontSize: isSelected ? 20 : 14),
          ),
          textDirection: TextDirection.ltr,
        )
          ..layout()
          ..paint(canvas, labelOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MoodWheelPainter oldDelegate) {
    return oldDelegate.selectedMoodId != selectedMoodId ||
        oldDelegate.animationValue != animationValue;
  }
}
