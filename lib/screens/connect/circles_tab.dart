import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:infano_care_mobile/widgets/joined_circle_card.dart';
import 'package:infano_care_mobile/widgets/explore_circle_card.dart';
import 'package:infano_care_mobile/widgets/circle_details_sheet.dart';
import 'package:infano_care_mobile/screens/connect/reply_thread_screen.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:infano_care_mobile/models/circle.dart';
import 'package:infano_care_mobile/models/event.dart';
import 'package:infano_care_mobile/models/post.dart';
import 'package:provider/provider.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

class CirclesTab extends StatefulWidget {
  const CirclesTab({super.key});

  @override
  State<CirclesTab> createState() => _CirclesTabState();
}

class _CirclesTabState extends State<CirclesTab> with AutomaticKeepAliveClientMixin {
  late CommunityApi _api;
  late Future<List<Circle>> _circlesFuture;
  
  // New Futures for rich hub
  Future<WeeklyChallenge?>? _challengeFuture;
  Future<List<CommunityEvent>>? _eventsFuture;
  Future<List<CommunityPost>>? _trendingFuture;

  // Search & Filters state
  String _searchQuery = "";
  String _selectedCategory = "All";

  final List<String> _categories = ["All", "Wellness", "Puberty", "Growth", "Social"];

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
      
      _challengeFuture = _api.getWeeklyChallenge().catchError((e) {
        debugPrint('CirclesTab: Error loading weekly challenge: $e');
        return null;
      });

      _eventsFuture = _api.getCommunityEvents(status: 'upcoming').catchError((e) {
        debugPrint('CirclesTab: Error loading events: $e');
        return <CommunityEvent>[];
      });

      _trendingFuture = _api.getMyFeed(page: 1).then((feed) {
        final List postsJson = feed['posts'] ?? [];
        return postsJson.map((e) => CommunityPost.fromJson(e as Map<String, dynamic>)).toList();
      }).catchError((e) {
        debugPrint('CirclesTab: Error loading trending feed: $e');
        return <CommunityPost>[];
      });
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

  bool _matchesCategory(String circleName, String category) {
    if (category == "All") return true;
    final name = circleName.toLowerCase();
    if (category == "Wellness") return name.contains("self-care") || name.contains("mindfulness");
    if (category == "Puberty") return name.contains("period") || name.contains("body");
    if (category == "Growth") return name.contains("teen") || name.contains("power") || name.contains("goals");
    if (category == "Social") return name.contains("general") || name.contains("chat");
    return true;
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
                  Text('Could not load circles', style: GoogleFonts.outfit(color: Colors.grey.shade500)),
                  const SizedBox(height: 16),
                  TextButton(onPressed: _load, child: Text('Retry', style: GoogleFonts.outfit())),
                ],
              ),
            ),
          );
        }

        final allCircles = snapshot.data ?? [];
        
        // Filter based on search & category selection
        final joinedCircles = allCircles
            .where((c) => c.isJoined && !c.isAgeSpecific && _matchesCategory(c.name, _selectedCategory) && c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
            
        final exploreCircles = allCircles
            .where((c) => !c.isJoined && !c.isAgeSpecific && _matchesCategory(c.name, _selectedCategory) && c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        return RefreshIndicator(
          onRefresh: () async => _load(),
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Banner Header ──────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFF1F2),
                          Color(0xFFF5F3FF),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
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
                              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.pink.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.pink.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  'COMMUNITY',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.pink,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.6,
                                child: Text(
                                  '"Empowering your journey through collective wisdom."',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF4A3F6B),
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: -0.5,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.55,
                                child: Text(
                                  'Join our vibrant circles to accelerate your growth and find your tribe.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF4A3F6B).withValues(alpha: 0.7),
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

                // ── 1. Weekly Challenge Banner ──────────────────────────
                SliverToBoxAdapter(
                  child: FutureBuilder<WeeklyChallenge?>(
                    future: _challengeFuture,
                    builder: (context, challSnap) {
                      if (challSnap.connectionState == ConnectionState.waiting || challSnap.data == null) {
                        return const SizedBox.shrink();
                      }
                      final challenge = challSnap.data!;
                      return _buildWeeklyChallengeCard(challenge);
                    },
                  ),
                ),

                // ── 2. Search & Category Filters ──────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search community circles...',
                            hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
                            prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: AppColors.purple, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 38,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final cat = _categories[index];
                              final isSelected = _selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(
                                    cat,
                                    style: GoogleFonts.outfit(
                                      color: isSelected ? Colors.white : AppColors.textDark,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: AppColors.purple,
                                  backgroundColor: Colors.white,
                                  onSelected: (selected) {
                                    setState(() => _selectedCategory = cat);
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(color: isSelected ? AppColors.purple : Colors.grey.shade200),
                                  ),
                                  showCheckmark: false,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 3. Joined Circles (Horizontal) ──────────────────────────
                if (joinedCircles.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                      child: Row(
                        children: [
                          Text(
                            'Your Circles',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E).withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${joinedCircles.length}',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A1A2E),
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

                // ── 4. Upcoming Webinars & Events Carousel ──────────────────────────
                SliverToBoxAdapter(
                  child: FutureBuilder<List<CommunityEvent>>(
                    future: _eventsFuture,
                    builder: (context, eventsSnap) {
                      final events = eventsSnap.data ?? [];
                      if (events.isEmpty) return const SizedBox.shrink();
                      return _buildEventsCarousel(events);
                    },
                  ),
                ),

                // ── 5. Trending Posts Snippets ──────────────────────────
                SliverToBoxAdapter(
                  child: FutureBuilder<List<CommunityPost>>(
                    future: _trendingFuture,
                    builder: (context, trendingSnap) {
                      final posts = trendingSnap.data ?? [];
                      if (posts.isEmpty) return const SizedBox.shrink();
                      return _buildTrendingPosts(posts);
                    },
                  ),
                ),

                // ── 6. Explore Circles Section ──────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Explore New Circles',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1A2E),
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
                            Text(
                              'You have joined all available circles!', 
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(color: Colors.grey.shade500, fontWeight: FontWeight.w500)
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

  Widget _buildWeeklyChallengeCard(WeeklyChallenge challenge) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7C3AED), // Purple
            Color(0xFFEC4899), // Pink
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'WEEKLY CHALLENGE',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '⚡ ${challenge.participatingCount} active',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    challenge.theme,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to first circle or challenge details
                      if (challenge.promptsByCircle.isNotEmpty) {
                        context.push('/community/challenge/weekly', extra: challenge);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF7C3AED),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      challenge.userHasResponded ? 'View Responses' : 'Participate Now',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsCarousel(List<CommunityEvent> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
          child: Text(
            'Live & Upcoming Events',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
            ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final formattedTime = DateFormat('d MMM · h:mm a').format(event.startTime);

              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 14, bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'WEBINAR',
                                  style: GoogleFonts.outfit(
                                    color: Colors.blue.shade800,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                formattedTime,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppColors.purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            event.title,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.purple.withValues(alpha: 0.1),
                            child: Text(
                              (event.expertName ?? 'E')[0],
                              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.purple),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.expertName ?? 'Dr. Expert',
                                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  event.expertCredentials ?? 'Host',
                                  style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textMedium),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => context.push('/community/events/${event.id}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.purple,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text('Join', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingPosts(List<CommunityPost> posts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
          child: Text(
            'Trending Conversations',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
            ),
          ),
        ),
        SizedBox(
          height: 145,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: posts.take(5).length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReplyThreadScreen(post: post)),
                  ).then((_) => _load());
                },
                child: Container(
                  width: 250,
                  margin: const EdgeInsets.only(right: 14, bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          post.content,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppColors.textDark,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            const Icon(Icons.favorite_rounded, color: Colors.pink, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${post.reactionHeart + post.reactionHug}',
                              style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMedium, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 14),
                            const Icon(Icons.mode_comment_rounded, color: AppColors.purple, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${post.replyCount}',
                              style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMedium, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              'Tap to read',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: AppColors.purple,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
