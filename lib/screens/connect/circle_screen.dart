import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/models/circle.dart';
import 'package:infano_care_mobile/models/post.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:infano_care_mobile/widgets/post_card.dart';
import 'package:infano_care_mobile/screens/connect/reply_thread_screen.dart';
import 'package:infano_care_mobile/widgets/compose_box.dart';
import 'package:infano_care_mobile/models/event.dart';
import 'package:infano_care_mobile/widgets/crisis_resource_card.dart' as infano_crisis;

class CircleScreen extends StatefulWidget {
  final Circle circle;
  const CircleScreen({Key? key, required this.circle}) : super(key: key);

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  late CommunityApi _api;
  late Future<Map<String, dynamic>> _feedFuture;
  bool _isLoading = false;

  int _selectedTab = 0; // 0 = All Posts, 1 = This Week's Challenge
  String? _draftContent;
  String? _pendingDraft;
  bool _showDraftBanner = false;
  bool _showChallengeBanner = true;
  bool _isChallengeMode = false;
  WeeklyChallenge? _currentChallenge;
  bool _hasNewPosts = false;
  int _newPostsCount = 0;
  
  // Pagination
  bool _isMoreLoading = false;
  int _currentPage = 1;
  bool _hasMore = false;
  List<CommunityPost> _allPosts = [];
  List<CommunityPost> _pinnedPosts = [];
  
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  // Optimistic local overrides
  final Map<String, Map<String, int>> _localReactions = {}; // postId → {reaction → delta}
  final Map<String, int> _localReplyDelta = {};             // postId → reply count delta
  final Map<String, bool> _localPinState = {};              // postId → isPinned override
  final Map<String, bool> _localBookmarkState = {};         // postId → isBookmarked override

  @override
  void initState() {
    super.initState();
    _api = Provider.of<CommunityApi>(context, listen: false);
    _loadInitialFeed();
    _checkDraft();
    _markAsRead();
    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 4;
      if (scrolled != _isScrolled && mounted) {
        setState(() => _isScrolled = scrolled);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _markAsRead() {
    _api.trackCircleVisit(widget.circle.id).catchError((e) {
      debugPrint('[CircleScreen] Error marking as read: $e');
    });
  }

  Future<void> _checkDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draft = prefs.getString('draft_circle_${widget.circle.id}');
    if (draft != null && draft.isNotEmpty && mounted) {
      setState(() {
        _pendingDraft = draft;
        _showDraftBanner = true;
      });
    }
  }

  void _loadInitialFeed() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchPage(1),
      _fetchChallenge(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchChallenge() async {
    try {
      final challenge = await _api.getWeeklyChallenge();
      if (mounted) {
        setState(() {
          _currentChallenge = challenge;
        });
      }
    } catch (e) {
      debugPrint('[CircleScreen] Challenge fetch error: $e');
    }
  }

  Future<void> _fetchPage(int page) async {
    try {
      final responseMap = await _api.getCirclePosts(widget.circle.id, page: page);
      
      final postsJson = responseMap['posts'] as List? ?? [];
      final pinsJson = responseMap['pinned'] as List? ?? [];
      final pagination = responseMap['pagination'] as Map<String, dynamic>?;
      
      if (mounted) {
        setState(() {
          final newPosts = postsJson.map((j) => CommunityPost.fromJson(j)).toList();
          if (page == 1) {
            _allPosts = newPosts;
            _pinnedPosts = pinsJson.map((j) => CommunityPost.fromJson(j)).toList();
          } else {
            _allPosts.addAll(newPosts);
          }
          
          _currentPage = page;
          _hasMore = pagination?['hasMore'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('[CircleScreen] Fetch error: $e');
    }
  }

  Future<void> _loadMore() async {
    if (_isMoreLoading || !_hasMore) return;
    setState(() => _isMoreLoading = true);
    await _fetchPage(_currentPage + 1);
    if (mounted) setState(() => _isMoreLoading = false);
  }

  void _loadFeed() { // For refresh indicator
    _loadInitialFeed();
    _localReactions.clear();
    _localReplyDelta.clear();
    _localPinState.clear();
  }

  // ── Reactions (optimistic, no reload) ────────────────────────────────────
  Future<void> _toggleReaction(String postId, String reaction) async {
    setState(() {
      _localReactions[postId] ??= {};
      _localReactions[postId]![reaction] = (_localReactions[postId]![reaction] ?? 0) + 1;
    });
    try {
      await _api.toggleReaction(postId, reaction, contentType: 'post', action: 'add');
    } catch (e) {
      setState(() {
        final cur = _localReactions[postId]?[reaction] ?? 1;
        _localReactions[postId]![reaction] = cur - 1;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not react: $e')));
    }
  }

  // ── Bookmarks (optimistic) ──────────────────────────────────────────────
  Future<void> _toggleBookmark(String postId, bool current) async {
    setState(() => _localBookmarkState[postId] = !current);
    try {
      final result = await _api.toggleBookmark(postId, contentType: 'post');
      // Backend returns { success, bookmarked }
      if (mounted) {
        setState(() {
          _localBookmarkState[postId] = result['bookmarked'] ?? !current;
        });
      }
    } catch (e) {
      setState(() => _localBookmarkState.remove(postId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update bookmark: $e')));
    }
  }

  // ── Replies (Navigate to full screen with Hero animation) ─────────
  void _navigateToReplies(CommunityPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReplyThreadScreen(post: post),
      ),
    ).then((_) => _loadInitialFeed()); // Refresh on back to get updated counts
  }

  // ── Pin / Unpin (optimistic, refresh to re-sort) ──────────────────────────
  Future<void> _togglePin(String postId, bool pin) async {
    setState(() {
      _localPinState[postId] = pin;
      // Manually update _pinnedPosts for instant UI feedback without reload
      if (pin) {
        // Find post in allPosts and add to pinned if not already there
        try {
          final post = _allPosts.firstWhere((p) => p.id == postId);
          if (!_pinnedPosts.any((p) => p.id == postId)) {
            _pinnedPosts.insert(0, post.copyWith(isPinned: true));
          }
        } catch (e) {
          debugPrint('Post not found in feed list for pinning');
        }
      } else {
        _pinnedPosts.removeWhere((p) => p.id == postId);
      }
    });

    try {
      await _api.togglePin(postId, pin: pin);
      // No reload needed now as we updated local state manually above
    } catch (e) {
      if (mounted) {
        setState(() {
          _localPinState.remove(postId);
          // Only hard refresh on backend failure to reconcile state
          _loadInitialFeed();
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update pin: $e')));
      }
    }
  }

  // ── New Post ─────────────────────────────────────────────────────────────
  Future<void> _submitPost(String content) async {
    final optimisticPost = CommunityPost(
      id: 'temp-post-${DateTime.now().millisecondsSinceEpoch}',
      circleId: widget.circle.id,
      authorId: 'me',
      authorName: 'You',
      content: content,
      createdAt: DateTime.now(),
      isChallengeResponse: false,
      status: 'PENDING_AI',
    );

    setState(() {
      _allPosts.insert(0, optimisticPost);
    });

    try {
      final responseMap = await _api.createPost(widget.circle.id, content);
      
      if (mounted) {
        final postData = responseMap['post'] as Map<String, dynamic>? ?? {};
        final severity = postData['crisisSeverity']?.toString() ?? 'NONE';
        final newPost = CommunityPost.fromJson(postData);
        
        setState(() {
          // Replace optimistic post with actual server post
          final index = _allPosts.indexWhere((p) => p.id == optimisticPost.id);
          if (index != -1) {
            _allPosts[index] = newPost;
          }
          _isChallengeMode = false;
        });

        if (severity == 'HIGH' || severity == 'CRITICAL') {
          showDialog(
            context: context,
            barrierDismissible: false,
            useSafeArea: false,
            builder: (ctx) => const infano_crisis.CrisisResourceCard(),
          );
        } else if (newPost.status != 'APPROVED') {
          // Don't show toast for pending posts since the pending card itself is the feedback
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Post submitted!')),
                ],
              ),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allPosts.removeWhere((p) => p.id == optimisticPost.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ── Apply local overrides to a post ──────────────────────────────────────
  CommunityPost _withLocalOverrides(CommunityPost post) {
    final reactions = _localReactions[post.id];
    final replyDelta = _localReplyDelta[post.id] ?? 0;
    final pinnedOverride = _localPinState[post.id];
    final bookmarkOverride = _localBookmarkState[post.id];
    return CommunityPost(
      id: post.id,
      circleId: post.circleId,
      authorId: post.authorId,
      authorName: post.authorName,
      content: post.content,
      createdAt: post.createdAt,
      reactionHeart: post.reactionHeart + (reactions?['heart'] ?? 0),
      reactionHug: post.reactionHug + (reactions?['hug'] ?? 0),
      reactionBulb: post.reactionBulb + (reactions?['bulb'] ?? 0),
      reactionFist: post.reactionFist + (reactions?['fist'] ?? 0),
      replyCount: post.replyCount + replyDelta,
      isPinned: pinnedOverride ?? post.isPinned,
      isFeatured: post.isFeatured,
      isBookmarked: bookmarkOverride ?? post.isBookmarked,
      isChallengeResponse: post.isChallengeResponse,
      challengeTheme: post.challengeTheme,
      authorRole: post.authorRole,
      status: post.status,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Current filtered posts
    List<CommunityPost> posts = _allPosts
        .map((p) => _withLocalOverrides(p))
        .toList();

    if (_selectedTab == 1) {
      posts = posts.where((p) => p.isChallengeResponse).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB), // Light grey background
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async => _loadFeed(),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Zone 1: Collapsible Circle Header
                SliverAppBar(
                  expandedHeight: 110.0,
                  floating: false,
                  pinned: true,
                  elevation: _isScrolled ? 4 : 0,
                  shadowColor: Colors.black.withOpacity(0.08),
                  backgroundColor: const Color(0xFFFDF2F8), // Light pink header
                  surfaceTintColor: const Color(0xFFFDF2F8),
                  // Title fades in ONLY when collapsed (scroll offset > threshold)
                  title: AnimatedOpacity(
                    opacity: _isScrolled ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.circle.iconEmoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          widget.circle.name,
                          style: const TextStyle(
                            color: Color(0xFF1A1A2E),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  centerTitle: true,
                  // Background shown only when expanded
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: ClipRect(
                      child: Container(
                        color: const Color(0xFFFDF2F8), // Light pink background
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 14, left: 24, right: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(widget.circle.iconEmoji, style: const TextStyle(fontSize: 28)),
                                const SizedBox(height: 4),
                                Text(
                                  widget.circle.name,
                                  style: const TextStyle(
                                    color: Color(0xFF1A1A2E),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.purple.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.group_outlined, size: 12, color: AppColors.purple.withOpacity(0.7)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${((widget.circle.memberCount ?? 0) > 0 ? widget.circle.memberCount : _allPosts.map((p) => p.authorId).toSet().length)} members',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.purple.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),


                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 16),

                      // Draft Banner
                      if (_showDraftBanner) _buildDraftBanner(),

                      // Pinned Posts row (Zone 2)
                      if (_pinnedPosts.isNotEmpty) _buildPinnedRow(),

                      // Weekly Challenge Banner (Zone 3)
                      if (_showChallengeBanner && _currentChallenge != null) _WeeklyChallengeHeader(
                        circle: widget.circle, 
                        challenge: _currentChallenge!,
                        onDismiss: () => setState(() => _showChallengeBanner = false),
                        onRespond: () {
                          setState(() => _isChallengeMode = true);
                          // Scroll to compose box
                          _scrollController.animateTo(200, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                        },
                      ),

                      // New Posts Banner (Zone 4)
                      if (_hasNewPosts) _buildNewPostsBanner(),

                      const SizedBox(height: 16),
                      // Compose Box (Zone 5)
                      ComposeBox(
                        key: ValueKey('${_draftContent ?? 'new'}_$_isChallengeMode'),
                        placeholder: 'Share something with this circle...',
                        initialText: _draftContent,
                        draftKey: 'draft_circle_${widget.circle.id}',
                        isChallengeMode: _isChallengeMode || _selectedTab == 1,
                        challengePrompt: _currentChallenge?.promptsByCircle[widget.circle.id],
                        onSubmitted: (content, {isChallengeResponse = false}) {
                          if (isChallengeResponse || _selectedTab == 1) {
                            // Submitting as challenge
                            _submitChallengeResponse(content);
                          } else {
                            _submitPost(content);
                          }
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      // Tabs
                      Row(
                        children: [
                          _buildTab(0, 'All Posts'),
                          const SizedBox(width: 12),
                          _buildTab(1, 'This Week\'s Challenge'),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),

                // Post Feed (Zone 6)
                if (_isLoading)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildSkeletonCard(),
                        childCount: 4,
                      ),
                    ),
                  )
                else if (posts.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: _selectedTab == 1 
                      ? SliverToBoxAdapter(child: _buildChallengeTabContent())
                      : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == posts.length) {
                              // "Load More" Button
                              return _hasMore 
                                  ? _buildLoadMoreButton() 
                                  : const SizedBox(height: 100);
                            }
                            final post = posts[index];
                            if (post.status.toUpperCase().contains('PENDING')) {
                              return _buildModerationPendingCard();
                            }
                            return PostCard(
                              key: ValueKey(post.id),
                              post: post,
                              onTap: () => _navigateToReplies(post),
                              onReact: (r) => _toggleReaction(post.id, r),
                              onReply: () => _navigateToReplies(post),
                              onPin: (pin) => _togglePin(post.id, pin),
                              onBookmark: () => _toggleBookmark(post.id, post.isBookmarked),
                              onReport: (category, note) async {
                                try {
                                  await _api.reportPost(post.id, category, note, contentType: 'post');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Report submitted. Thank you for helping keep our community safe!')),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error submitting report: $e')),
                                    );
                                  }
                                }
                              },
                            );
                          },
                          childCount: posts.length + 1,
                        ),
                      ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note, color: Colors.orange),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'You have an unsent draft — continue or discard?',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('draft_circle_${widget.circle.id}');
                  setState(() {
                    _pendingDraft = null;
                    _showDraftBanner = false;
                  });
                },
                child: const Text('Discard', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _draftContent = _pendingDraft;
                    _showDraftBanner = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Continue', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedRow() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.push_pin, color: Colors.redAccent.withOpacity(0.6), size: 14),
              // Removed "Pinned" text label
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _pinnedPosts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final pin = _pinnedPosts[index];
                final snippet = pin.content.length > 50
                    ? '${pin.content.substring(0, 50)}…'
                    : pin.content;
                return GestureDetector(
                  onTap: () => _navigateToReplies(pin),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, fontFamily: 'Inter'),
                        children: [
                          const TextSpan(
                            text: '📌 ',
                            style: TextStyle(fontSize: 11),
                          ),
                          TextSpan(
                            text: snippet,
                            style: const TextStyle(
                              color: Color(0xFF4A3428),
                              fontWeight: FontWeight.w500,
                            ),
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
      ),
    );
  }

  Widget _buildNewPostsBanner() {
    return GestureDetector(
      onTap: () {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
        setState(() => _hasNewPosts = false);
        _loadFeed();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.purple,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.4), blurRadius: 10)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_upward, color: Colors.white, size: 14),
            const SizedBox(width: 8),
            Text('$_newPostsCount new posts — tap to see', 
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: _isMoreLoading
            ? const CircularProgressIndicator()
            : TextButton(
                onPressed: _loadMore,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: AppColors.purple.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Load older posts', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold)),
              ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row skeleton
          Row(
            children: [
              _SkeletonBox(width: 36, height: 36, isCircle: true),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(width: 120, height: 12),
                  const SizedBox(height: 6),
                  _SkeletonBox(width: 64, height: 10),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Content lines skeleton
          _SkeletonBox(width: double.infinity, height: 12),
          const SizedBox(height: 8),
          _SkeletonBox(width: double.infinity, height: 12),
          const SizedBox(height: 8),
          _SkeletonBox(width: 200, height: 12),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // Reaction row skeleton
          Row(
            children: [
              _SkeletonBox(width: 40, height: 24, radius: 12),
              const SizedBox(width: 8),
              _SkeletonBox(width: 40, height: 24, radius: 12),
              const SizedBox(width: 8),
              _SkeletonBox(width: 40, height: 24, radius: 12),
              const Spacer(),
              _SkeletonBox(width: 60, height: 24, radius: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Text(widget.circle.iconEmoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          Text(
            'No posts yet in ${widget.circle.name}.\nBe the first to start the conversation!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTab = index;
        _isChallengeMode = (index == 1); // Auto-activate challenge mode on challenge tab
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purple : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.purple : Colors.grey.shade300),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ── Challenge Helpers ─────────────────────────────────────────────────────

  Future<void> _submitChallengeResponse(String content) async {
    if (_currentChallenge == null) return;
    
    debugPrint('[CircleScreen] Submitting challenge response. id="${_currentChallenge!.id}", circleId="${widget.circle.id}"');
    
    final optimisticPost = CommunityPost(
      id: 'temp-challenge-${DateTime.now().millisecondsSinceEpoch}',
      circleId: widget.circle.id,
      authorId: 'me',
      authorName: 'You',
      content: content,
      createdAt: DateTime.now(),
      isChallengeResponse: true,
      challengeTheme: _currentChallenge!.theme,
    );

    setState(() {
      _allPosts.insert(0, optimisticPost);
    });

    try {
      final challengeId = _currentChallenge!.id.isNotEmpty ? _currentChallenge!.id : null;
      await _api.createPost(
        widget.circle.id, 
        content, 
        isChallengeResponse: true, 
        challengeId: challengeId,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(child: Text('Challenge response submitted! +40 points obtained 💛')),
              ],
            ),
            backgroundColor: AppColors.purple,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isChallengeMode = false);
        _loadInitialFeed();
      }
    } catch (e) {
      debugPrint('[CircleScreen] Challenge submit error: $e');
      if (mounted) {
        setState(() {
          _allPosts.removeWhere((p) => p.id == optimisticPost.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildChallengeTabContent() {
    if (_currentChallenge == null) return _buildEmptyState();

    final prompt = _currentChallenge!.promptsByCircle[widget.circle.id] ?? 'Participate in this week\'s community theme!';
    final featured = _currentChallenge!.featuredResponses.where((p) => p.circleId == widget.circle.id).toList();
    final circleResponses = _allPosts.where((p) => p.isChallengeResponse).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Prompt Context Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.purple.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.purple.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentChallenge!.theme.toUpperCase(),
                style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1),
              ),
              const SizedBox(height: 8),
              Text(
                prompt,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, height: 1.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Ends on ${(_currentChallenge!.endDate.day)}/${_currentChallenge!.endDate.month}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Featured Section
        if (featured.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Text('Featured Responses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          ...featured.map((post) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: PostCard(
              key: ValueKey(post.id),
              post: _withLocalOverrides(post),
              onTap: () => _navigateToReplies(post),
              onReact: (r) => _toggleReaction(post.id, r),
              onReply: () => _navigateToReplies(post),
              onBookmark: () => _toggleBookmark(post.id, post.isBookmarked),
            ),
          )),
          const SizedBox(height: 12),
        ],

        // All responses
        const Text('Circle Responses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        if (circleResponses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(child: Text('No responses yet in this circle.', style: TextStyle(color: Colors.grey.shade500))),
          )
        else
          ...circleResponses.map((post) => PostCard(
            key: ValueKey(post.id),
            post: _withLocalOverrides(post),
            onTap: () => _navigateToReplies(post),
            onReact: (r) => _toggleReaction(post.id, r),
            onReply: () => _navigateToReplies(post),
            onBookmark: () => _toggleBookmark(post.id, post.isBookmarked),
          )),
        
        const SizedBox(height: 40),
        Center(
          child: TextButton.icon(
            onPressed: () { /* Navigate to archive */ },
            icon: const Icon(Icons.history, size: 16),
            label: const Text('View Past Challenges'),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildModerationPendingCard() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.purple),
                SizedBox(width: 8),
                Text('Under Review'),
              ],
            ),
            content: const Text(
              "We're reviewing your post. This usually takes just a few minutes. Thanks for helping us keep the community safe!",
              style: TextStyle(height: 1.4, color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Got it', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
          ],
          image: DecorationImage(
            image: const NetworkImage('https://www.transparenttextures.com/patterns/cubes.png'), // Subtle texture
            colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.9), BlendMode.lighten),
            fit: BoxFit.cover,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.pink.shade50, shape: BoxShape.circle),
              child: const Text('🌸', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your post is being reviewed",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "— it'll appear soon",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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


class _WeeklyChallengeHeader extends StatelessWidget {
  final Circle circle;
  final WeeklyChallenge challenge;
  final VoidCallback onDismiss;
  final VoidCallback onRespond;
  const _WeeklyChallengeHeader({
    required this.circle, 
    required this.challenge,
    required this.onDismiss,
    required this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    final prompt = challenge.promptsByCircle[circle.id] ?? 'Participate in this week\'s community theme!';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)], // Amber/Gold gradient (Matches Event Tab)
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'WEEKLY CHALLENGE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                          onPressed: onDismiss,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      challenge.theme.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prompt,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${challenge.participatingCount} girls participated',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: challenge.userHasResponded ? null : onRespond,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFF59E0B),
                  disabledBackgroundColor: Colors.white54,
                  disabledForegroundColor: Colors.black45,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  minimumSize: const Size(0, 36),
                ),
                child: Text(
                  challenge.userHasResponded ? 'Already Participated ✓' : 'Respond →', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single shimmer-style placeholder box used in the loading skeleton.
class _SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final bool isCircle;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
    this.isCircle = false,
  });

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300.withOpacity(_animation.value),
            borderRadius: widget.isCircle
                ? BorderRadius.circular(widget.height / 2)
                : BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}
