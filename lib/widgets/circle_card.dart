import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/models/circle.dart';

class CircleCard extends StatefulWidget {
  final Circle circle;

  const CircleCard({Key? key, required this.circle}) : super(key: key);

  @override
  State<CircleCard> createState() => _CircleCardState();
}

class _CircleCardState extends State<CircleCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if ((widget.circle.unreadCount ?? 0) > 0) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(CircleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.circle.unreadCount ?? 0) > 0 && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if ((widget.circle.unreadCount ?? 0) == 0 && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Parse the hex accent color from backend
    Color accentColor;
    try {
      accentColor = Color(int.parse(widget.circle.accentColor.replaceAll('#', '0xFF')));
    } catch (_) {
      accentColor = const Color(0xFF8B5CF6);
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/community/circle', extra: widget.circle),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Accent bar on left edge
                Positioned(
                  left: 0,
                  top: 20,
                  bottom: 20,
                  width: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
                // Card content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Large emoji icon at top-left
                      Text(
                        widget.circle.iconEmoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(height: 4),
                      // Circle name
                      Text(
                        widget.circle.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                          height: 1.2,
                        ),
                      ),
                      const Spacer(),
                      
                      // "X new" badge if there are unread posts
                      if ((widget.circle.unreadCount ?? 0) > 0)
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488).withOpacity(0.12), // teal
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${widget.circle.unreadCount} new',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0D9488),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
