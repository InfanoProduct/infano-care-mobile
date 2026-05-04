import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/widgets/joined_circle_card.dart';
import 'package:infano_care_mobile/widgets/explore_circle_card.dart';
import 'package:infano_care_mobile/widgets/circle_details_sheet.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:infano_care_mobile/models/circle.dart';
import 'package:provider/provider.dart';

class CirclesTab extends StatefulWidget {
  const CirclesTab({Key? key}) : super(key: key);

  @override
  State<CirclesTab> createState() => _CirclesTabState();
}

class _CirclesTabState extends State<CirclesTab> with AutomaticKeepAliveClientMixin {
  late CommunityApi _api;
  late Future<List<Circle>> _circlesFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _api = Provider.of<CommunityApi>(context, listen: false);
    _load();
  }

  void _load() {
    if (!mounted) return;
    setState(() {
      _circlesFuture = _api.getCircles();
    });
  }

  void _showCircleDetails(Circle circle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CircleDetailsSheet(circle: circle),
    ).then((joined) {
      if (joined == true) {
        _load(); // Reload to update lists
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Circle>>(
      future: _circlesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Could not load circles', style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 16),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          );
        }

        final allCircles = snapshot.data ?? [];
        final joinedCircles = allCircles.where((c) => c.isJoined && !c.isAgeSpecific).toList();
        final exploreCircles = allCircles.where((c) => !c.isJoined && !c.isAgeSpecific).toList();

        return RefreshIndicator(
          onRefresh: () async => _load(),
          child: Container(
            color: const Color(0xFFF8FAFC), // Very light grey/blue background
            child: CustomScrollView(
              slivers: [
                // ── Growth Banner Header ──────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFF1F2), // Very soft pink
                          Color(0xFFF5F3FF), // Very soft purple
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Supporting Illustration on the right
                        Positioned(
                          right: -10,
                          bottom: -10,
                          child: Opacity(
                            opacity: 0.8,
                            child: Image.asset(
                              'assets/images/community_banner.png',
                              width: 180,
                              height: 180,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.pink.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.pink.withOpacity(0.2)),
                                ),
                                child: const Text(
                                  'COMMUNITY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.pink,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.6,
                                child: const Text(
                                  '"Empowering your journey through collective wisdom."',
                                  style: TextStyle(
                                    fontSize: 18, // Reduced from 24
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF4A3F6B),
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: -0.5,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.55,
                                child: Text(
                                  'Join our vibrant circles to accelerate your growth and find your tribe.',
                                  style: TextStyle(
                                    fontSize: 13, // Reduced from 15
                                    color: const Color(0xFF4A3F6B).withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
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

                // ── Joined Circles (Horizontal) ──────────────────────────
                if (joinedCircles.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                      child: Row(
                        children: [
                          const Text(
                            'Your Circles',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${joinedCircles.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: joinedCircles.length,
                        itemBuilder: (context, index) {
                          try {
                            final circle = joinedCircles[index];
                            return JoinedCircleCard(
                              circle: circle,
                              onTap: () => context.push('/community/circle', extra: circle),
                            );
                          } catch (e) {
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                  ),
                ],

                // ── Explore Circles Section ──────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Explore New Circles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          'See All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (exploreCircles.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(60.0),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('You have joined all available circles!', 
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 200,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          try {
                            final circle = exploreCircles[index];
                            return ExploreCircleCard(
                              circle: circle,
                              onTap: () => _showCircleDetails(circle),
                            );
                          } catch (e) {
                            return const SizedBox.shrink();
                          }
                        },
                        childCount: exploreCircles.length,
                      ),
                    ),
                  ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 60)),
              ],
            ),
          ),
        );
      },
    );
  }
}
