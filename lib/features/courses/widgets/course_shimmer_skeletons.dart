import 'package:flutter/material.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = 0.35 + (_animation.value * 0.45);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFFE2D9F3).withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Shimmer Skeleton for [MyCoursesScreen]
class MyCoursesListSkeleton extends StatelessWidget {
  const MyCoursesListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Top Overview Banner Skeleton
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE9D5FF).withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _ShimmerBox(width: 140, height: 18, borderRadius: 6),
                  _ShimmerBox(width: 60, height: 24, borderRadius: 12),
                ],
              ),
              const SizedBox(height: 12),
              const _ShimmerBox(width: double.infinity, height: 8, borderRadius: 4),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _ShimmerBox(width: 100, height: 14, borderRadius: 4),
                  _ShimmerBox(width: 80, height: 14, borderRadius: 4),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Section Title
        const _ShimmerBox(width: 120, height: 20, borderRadius: 6),
        const SizedBox(height: 14),

        // 3 Enrolled Course Cards Skeleton
        ...List.generate(
          3,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFF3E8FF),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail Skeleton
                const _ShimmerBox(width: 90, height: 90, borderRadius: 16),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          _ShimmerBox(width: 70, height: 14, borderRadius: 6),
                          _ShimmerBox(width: 40, height: 14, borderRadius: 6),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const _ShimmerBox(width: double.infinity, height: 16, borderRadius: 4),
                      const SizedBox(height: 6),
                      const _ShimmerBox(width: 120, height: 12, borderRadius: 4),
                      const SizedBox(height: 12),
                      const _ShimmerBox(width: double.infinity, height: 6, borderRadius: 3),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Shimmer Skeleton for [CourseOverviewScreen]
class CourseOverviewSkeleton extends StatelessWidget {
  const CourseOverviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Hero Card Skeleton
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE9D5FF).withValues(alpha: 0.6)),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: _ShimmerBox(width: double.infinity, height: 200, borderRadius: 24),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _ShimmerBox(width: 90, height: 18, borderRadius: 6),
                    SizedBox(height: 8),
                    _ShimmerBox(width: 220, height: 22, borderRadius: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Stats Row Skeleton
        Row(
          children: List.generate(
            3,
            (index) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 2 ? 10 : 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF3E8FF)),
                ),
                child: Column(
                  children: const [
                    _ShimmerBox(width: 28, height: 28, borderRadius: 8),
                    SizedBox(height: 8),
                    _ShimmerBox(width: 40, height: 12, borderRadius: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Instructor Row Skeleton
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF3E8FF)),
          ),
          child: Row(
            children: [
              const _ShimmerBox(width: 50, height: 50, borderRadius: 25),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _ShimmerBox(width: 130, height: 16, borderRadius: 4),
                    SizedBox(height: 6),
                    _ShimmerBox(width: 180, height: 12, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Curriculum Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _ShimmerBox(width: 140, height: 18, borderRadius: 6),
            _ShimmerBox(width: 60, height: 14, borderRadius: 4),
          ],
        ),
        const SizedBox(height: 14),

        // Module Accordion Skeletons
        ...List.generate(
          2,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF3E8FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _ShimmerBox(width: 160, height: 16, borderRadius: 4),
                    _ShimmerBox(width: 20, height: 20, borderRadius: 10),
                  ],
                ),
                const SizedBox(height: 12),
                const _ShimmerBox(width: double.infinity, height: 38, borderRadius: 10),
                const SizedBox(height: 8),
                const _ShimmerBox(width: double.infinity, height: 38, borderRadius: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Shimmer Skeleton for [CourseContentScreen] (Player / Lesson Screen)
class CourseContentSkeleton extends StatelessWidget {
  const CourseContentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 16:9 Video Player Skeleton
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: const Color(0xFF1E1B2E),
            child: Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white70, size: 36),
              ),
            ),
          ),
        ),

        // Content Area Below Player
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // Lesson Title & Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _ShimmerBox(width: 80, height: 18, borderRadius: 8),
                  _ShimmerBox(width: 70, height: 18, borderRadius: 8),
                ],
              ),
              const SizedBox(height: 10),
              const _ShimmerBox(width: 240, height: 22, borderRadius: 6),
              const SizedBox(height: 6),
              const _ShimmerBox(width: 160, height: 14, borderRadius: 4),
              const SizedBox(height: 18),

              // Tab Bar Skeleton
              Row(
                children: List.generate(
                  4,
                  (index) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                      child: const _ShimmerBox(
                          width: double.infinity, height: 32, borderRadius: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Lesson Playlist Item Skeletons
              ...List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF3E8FF)),
                  ),
                  child: Row(
                    children: [
                      const _ShimmerBox(width: 36, height: 36, borderRadius: 10),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _ShimmerBox(width: 150, height: 14, borderRadius: 4),
                            SizedBox(height: 6),
                            _ShimmerBox(width: 80, height: 10, borderRadius: 4),
                          ],
                        ),
                      ),
                      const _ShimmerBox(width: 20, height: 20, borderRadius: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shimmer Skeleton for [ExploreCoursesScreen]
class ExploreCoursesSkeleton extends StatelessWidget {
  const ExploreCoursesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Search Bar Skeleton
        const _ShimmerBox(width: double.infinity, height: 50, borderRadius: 25),
        const SizedBox(height: 16),

        // Categories Row Skeleton
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            children: List.generate(
              4,
              (index) => Container(
                margin: const EdgeInsets.only(right: 8),
                child: _ShimmerBox(
                    width: index == 0 ? 60 : 90, height: 36, borderRadius: 18),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Course Discovery Cards
        ...List.generate(
          3,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF3E8FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ShimmerBox(width: double.infinity, height: 140, borderRadius: 20),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          _ShimmerBox(width: 80, height: 14, borderRadius: 6),
                          _ShimmerBox(width: 60, height: 18, borderRadius: 6),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const _ShimmerBox(width: 220, height: 18, borderRadius: 4),
                      const SizedBox(height: 6),
                      const _ShimmerBox(width: 140, height: 12, borderRadius: 4),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          _ShimmerBox(width: 100, height: 12, borderRadius: 4),
                          _ShimmerBox(width: 70, height: 12, borderRadius: 4),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
