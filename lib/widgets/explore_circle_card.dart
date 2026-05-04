import 'package:flutter/material.dart';
import 'package:infano_care_mobile/models/circle.dart';

class ExploreCircleCard extends StatelessWidget {
  final Circle circle;
  final VoidCallback onTap;

  const ExploreCircleCard({
    Key? key,
    required this.circle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color accentColor;
    try {
      accentColor = Color(int.parse(circle.accentColor.replaceAll('#', '0xFF')));
    } catch (e) {
      accentColor = const Color(0xFF6D28D9); // Fallback color
    }
    final Color pastelBg = accentColor.withOpacity(0.08);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: pastelBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accentColor.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -15,
                bottom: -15,
                child: Icon(
                  Icons.explore_rounded,
                  size: 60,
                  color: accentColor.withOpacity(0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              circle.iconEmoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                        if (circle.isPrivate)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      circle.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Expanded(child: SizedBox(height: 8)), // Using Expanded instead of Spacer
                    _buildSmallAvatarStack(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallAvatarStack() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(3, (index) {
          return Align(
            widthFactor: 0.6,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: NetworkImage('https://i.pravatar.cc/100?u=${circle.id}_$index'),
              ),
            ),
          );
        }),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF2DD4BF), // teal color from design
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '+${(circle.memberCount ?? 0) >= 1000 ? '${((circle.memberCount ?? 0) / 1000).toStringAsFixed(0)}k' : circle.memberCount ?? 0}',
            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
