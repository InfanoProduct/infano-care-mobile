import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:infano_care_mobile/models/circle.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';

class AgeRoomSection extends StatelessWidget {
  final List<Circle> circles;
  const AgeRoomSection({Key? key, required this.circles}) : super(key: key);

  /// Determine which age-specific slug to show based on birth year.
  String _getMyAgeSlug(LocalStorageService storage) {
    final birthYear = storage.birthYear;
    if (birthYear == null) return 'teen_community'; // default fallback

    final age = DateTime.now().year - birthYear;
    if (age <= 13) return 'junior_girls';
    if (age <= 17) return 'teen_community';
    return 'young_adults';
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<LocalStorageService>(context, listen: false);
    final mySlug = _getMyAgeSlug(storage);

    // Find the matching age-specific circle from the server list
    final ageCircles = circles.where((c) => c.isAgeSpecific).toList();
    final myCircle = ageCircles.cast<Circle?>().firstWhere(
      (c) => c!.slug == mySlug,
      orElse: () => ageCircles.isNotEmpty ? ageCircles.first : null,
    );

    if (myCircle == null) return const SizedBox.shrink();

    // Define display properties per slug
    final _roomData = {
      'junior_girls': _RoomInfo(
        label: 'Ages 10–13',
        subtitle: 'Junior safe space (age-verified)',
        emoji: '🌱',
        gradientStart: const Color(0xFF34D399),
        gradientEnd: const Color(0xFF10B981),
      ),
      'teen_community': _RoomInfo(
        label: 'Ages 14–17',
        subtitle: 'Teen community (age-verified)',
        emoji: '🌸',
        gradientStart: const Color(0xFFA78BFA),
        gradientEnd: const Color(0xFF8B5CF6),
      ),
      'young_adults': _RoomInfo(
        label: 'Ages 18–24',
        subtitle: 'Young adult space (age-verified)',
        emoji: '✨',
        gradientStart: const Color(0xFFFBBF24),
        gradientEnd: const Color(0xFFF59E0B),
      ),
    };

    final info = _roomData[myCircle.slug] ?? _roomData['teen_community']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR SPACE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => context.push('/community/circle', extra: myCircle),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(2), // Gradient border width
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [info.gradientStart, info.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: info.gradientStart.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(info.emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: info.gradientEnd,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          info.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: info.gradientEnd,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomInfo {
  final String label;
  final String subtitle;
  final String emoji;
  final Color gradientStart;
  final Color gradientEnd;
  const _RoomInfo({
    required this.label,
    required this.subtitle,
    required this.emoji,
    required this.gradientStart,
    required this.gradientEnd,
  });
}
