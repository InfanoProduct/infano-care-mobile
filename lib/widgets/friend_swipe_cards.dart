import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:confetti/confetti.dart';
import '../models/friend_profile.dart';
import 'friend_profile_detail_sheet.dart';
import 'friend_empty_state.dart';
import 'package:provider/provider.dart';
import '../screens/connect/friend_profile_setup_screen.dart';

class FriendSwipeCards extends StatefulWidget {
  final List<FriendProfile> profiles;
  final Function(String targetId, String action) onSwipe;
  final VoidCallback onEmpty;
  final VoidCallback? onWidenRadius;
  final VoidCallback? onExploreCircles;

  const FriendSwipeCards({
    Key? key,
    required this.profiles,
    required this.onSwipe,
    required this.onEmpty,
    this.onWidenRadius,
    this.onExploreCircles,
  }) : super(key: key);

  @override
  State<FriendSwipeCards> createState() => _FriendSwipeCardsState();
}

class _FriendSwipeCardsState extends State<FriendSwipeCards> {
  final CardSwiperController controller = CardSwiperController();
  late ConfettiController _superConnectConfetti;

  @override
  void initState() {
    super.initState();
    _superConnectConfetti = ConfettiController(duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    controller.dispose();
    _superConnectConfetti.dispose();
    super.dispose();
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (previousIndex < 0 || previousIndex >= widget.profiles.length) return false;
    final profileId = widget.profiles[previousIndex].id;
    if (direction == CardSwiperDirection.right) {
      widget.onSwipe(profileId, 'LIKE');
      _showToast('Maybe friends? 💜', Colors.pink);
    } else if (direction == CardSwiperDirection.left) {
      widget.onSwipe(profileId, 'PASS');
      // No toast for pass
    } else if (direction == CardSwiperDirection.top) {
      widget.onSwipe(profileId, 'SUPER_CONNECT');
      _superConnectConfetti.play();
      _showToast('Super-connect sent! ⭐', Colors.amber.shade700);
    } else if (direction == CardSwiperDirection.bottom) {
      widget.onSwipe(profileId, 'SAVE');
      _showToast('Saved for later! 🔖', Colors.blue);
    }

    if (currentIndex == null || currentIndex >= widget.profiles.length - 1) {
      // Reached the end
      Future.delayed(const Duration(milliseconds: 300), widget.onEmpty);
    }
    return true;
  }

  void _showToast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profiles.isEmpty) {
      return FriendEmptyState(
        onWidenRadius: widget.onWidenRadius ?? () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FriendProfileSetupScreen(initialStep: 3, isWidenRadius: true)),
          );
        },
        onExploreCircles: widget.onExploreCircles ?? () {
          try {
            final tabController = Provider.of<TabController>(context, listen: false);
            tabController.animateTo(0); // Index 0 is Circles
          } catch (e) {
            debugPrint('Error navigating to circles: $e');
          }
        },
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: CardSwiper(
                controller: controller,
                cardsCount: widget.profiles.length,
                onSwipe: _onSwipe,
                allowedSwipeDirection: const AllowedSwipeDirection.all(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                numberOfCardsDisplayed: widget.profiles.length > 2 ? 3 : widget.profiles.length,
                backCardOffset: const Offset(0, 16),
                scale: 0.96,
                cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                  if (index < 0 || index >= widget.profiles.length) {
                    return const SizedBox.shrink();
                  }
                  return _buildCard(widget.profiles[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0, left: 24, right: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.close,
                    color: Colors.grey[600]!,
                    onPressed: () => controller.swipe(CardSwiperDirection.left),
                  ),
                  _buildActionButton(
                    icon: Icons.star_rounded,
                    color: Colors.amber,
                    size: 64,
                    iconSize: 36,
                    onPressed: () => controller.swipe(CardSwiperDirection.top),
                  ),
                  _buildActionButton(
                    icon: Icons.favorite_rounded,
                    color: Colors.pink,
                    gradient: const LinearGradient(colors: [Colors.pink, Colors.purple]),
                    iconColor: Colors.white,
                    onPressed: () => controller.swipe(CardSwiperDirection.right),
                  ),
                ],
              ),
            )
          ],
        ),
        Align(
          alignment: Alignment.center,
          child: ConfettiWidget(
            confettiController: _superConnectConfetti,
            blastDirectionality: BlastDirectionality.explosive,
            colors: const [Colors.amber, Colors.orange, Colors.yellow],
            maxBlastForce: 60,
            numberOfParticles: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    Color? iconColor,
    Gradient? gradient,
    double size = 56,
    double iconSize = 32,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gradient == null ? Colors.white : null,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: iconSize, color: iconColor ?? color),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildCard(FriendProfile profile) {
    return GestureDetector(
      onTap: () => FriendProfileDetailSheet.show(context, profile),
      onDoubleTap: () => controller.swipe(CardSwiperDirection.bottom),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Top Image/Avatar
            Positioned(
              top: 0, left: 0, right: 0, height: MediaQuery.of(context).size.height * 0.5,
              child: profile.photoUrl != null
                  ? Image.network(profile.photoUrl!, fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFFE1BEE7), Color(0xFFF8BBD0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      ),
                      child: const Center(child: Icon(Icons.face_retouching_natural, size: 120, color: Colors.white)),
                    ),
            ),
            
            // Bottom Gradient Overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),

            // Content
            Positioned(
              left: 20, right: 20, bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          profile.nickname ?? 'Anonymous',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.1),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (profile.ageBand != null)
                        Container(
                          margin: const EdgeInsets.only(left: 8, bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: Text(profile.ageBand!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(profile.locationLabel ?? 'Nearby', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Intent
                  if (profile.intent.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.9), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search, size: 14, color: Colors.black87),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              profile.intent.first,
                              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Vibe Tags
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: profile.vibeTags.take(4).map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    )).toList()
                      ..add(
                        profile.vibeTags.length > 4
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                                child: Text('+${profile.vibeTags.length - 4}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                              )
                            : Container(), // Empty fallback
                      ),
                  ),

                  // Compatibility Bar
                  if (profile.compatibilityScore != null) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: profile.compatibilityScore! / 100,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${profile.compatibilityScore}% Match',
                          style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  const Center(
                    child: Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
