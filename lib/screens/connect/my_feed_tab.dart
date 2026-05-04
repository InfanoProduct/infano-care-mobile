import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/community_api.dart';
import '../../models/post.dart';
import '../../widgets/post_card.dart';
import '../../core/services/local_storage_service.dart';
import 'reply_thread_screen.dart';

class MyFeedTab extends StatefulWidget {
  const MyFeedTab({Key? key}) : super(key: key);

  @override
  State<MyFeedTab> createState() => _MyFeedTabState();
}

class _MyFeedTabState extends State<MyFeedTab> with AutomaticKeepAliveClientMixin {
  late CommunityApi _api;
  final List<CommunityPost> _posts = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _currentUserId;
  String? _currentUserRole;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _api = Provider.of<CommunityApi>(context, listen: false);
    final storage = Provider.of<LocalStorageService>(context, listen: false);
    _currentUserId = storage.userId;
    _currentUserRole = storage.role;
    _loadPosts();
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _posts.clear();
      setState(() {
        _isLoading = true;
        _hasError = false;
        _hasMore = true;
      });
    }

    try {
      final response = await _api.getMyFeed(page: _currentPage);
      final List<dynamic> postsJson = response['posts'] ?? [];
      final List<CommunityPost> newPosts = postsJson
          .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
          .toList();
      
      if (mounted) {
        setState(() {
          _posts.addAll(newPosts);
          _isLoading = false;
          _hasMore = response['pagination']?['hasMore'] ?? false;
          _currentPage++;
        });
      }
    } catch (e) {
      debugPrint('Error loading feed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isLoading && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError && _posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Something went wrong'),
            TextButton(onPressed: () => _loadPosts(refresh: true), child: const Text('Try Again')),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadPosts(refresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rss_feed_rounded, size: 64, color: Colors.grey.shade200),
                const SizedBox(height: 24),
                const Text(
                  'Your feed is empty',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join some circles to see posts from the community here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadPosts(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: _posts.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            _loadPosts();
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final post = _posts[index];
          final canDelete = post.authorId == _currentUserId ||
              _currentUserRole?.toUpperCase() == 'ADMIN';
          return PostCard(
            key: ValueKey(post.id),
            post: post,
            onTap: () => _navigateToReplies(post),
            onReply: () => _navigateToReplies(post),
            onReact: (reaction) => _toggleReaction(post.id, reaction),
            onBookmark: () => _toggleBookmark(post),
            onDelete: canDelete ? () => _deletePost(post.id) : null,
          );
        },
      ),
    );
  }

  void _navigateToReplies(CommunityPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReplyThreadScreen(post: post),
      ),
    ).then((_) => _loadPosts(refresh: true)); // Refresh to get updated counts
  }

  Future<void> _toggleReaction(String postId, String reaction) async {
    // Optimistic update
    setState(() {
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = _posts[index];
        final oldReaction = post.myReaction;
        
        // If same reaction, just remove it
        if (oldReaction == reaction) {
          _posts[index] = post.copyWith(
            myReaction: null,
            reactionHeart: reaction == 'heart' ? post.reactionHeart - 1 : post.reactionHeart,
            reactionHug: reaction == 'hug' ? post.reactionHug - 1 : post.reactionHug,
            reactionBulb: reaction == 'bulb' ? post.reactionBulb - 1 : post.reactionBulb,
            reactionFist: reaction == 'fist' ? post.reactionFist - 1 : post.reactionFist,
          );
        } else {
          // Replace reaction
          int heart = post.reactionHeart;
          int hug = post.reactionHug;
          int bulb = post.reactionBulb;
          int fist = post.reactionFist;

          // Decrement old
          if (oldReaction == 'heart') heart--;
          if (oldReaction == 'hug') hug--;
          if (oldReaction == 'bulb') bulb--;
          if (oldReaction == 'fist') fist--;

          // Increment new
          if (reaction == 'heart') heart++;
          if (reaction == 'hug') hug++;
          if (reaction == 'bulb') bulb++;
          if (reaction == 'fist') fist++;

          _posts[index] = post.copyWith(
            myReaction: reaction,
            reactionHeart: heart,
            reactionHug: hug,
            reactionBulb: bulb,
            reactionFist: fist,
          );
        }
      }
    });

    try {
      await _api.toggleReaction(postId, reaction, contentType: 'post', action: 'add');
    } catch (e) {
      debugPrint('Error toggling reaction: $e');
      // Revert or just let the next refresh fix it
    }
  }

  Future<void> _toggleBookmark(CommunityPost post) async {
    final originalState = post.isBookmarked;
    
    // Optimistic update
    setState(() {
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(isBookmarked: !originalState);
      }
    });

    try {
      final result = await _api.toggleBookmark(post.id, contentType: 'post');
      if (mounted) {
        setState(() {
          final index = _posts.indexWhere((p) => p.id == post.id);
          if (index != -1) {
            _posts[index] = _posts[index].copyWith(isBookmarked: result['bookmarked'] ?? !originalState);
          }
        });
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      if (mounted) {
        setState(() {
          final index = _posts.indexWhere((p) => p.id == post.id);
          if (index != -1) {
            _posts[index] = _posts[index].copyWith(isBookmarked: originalState);
          }
        });
      }
    }
  }

  Future<void> _deletePost(String postId) async {
    // Optimistic remove
    final removedIndex = _posts.indexWhere((p) => p.id == postId);
    final removedPost = removedIndex != -1 ? _posts[removedIndex] : null;
    if (removedPost != null) {
      setState(() => _posts.removeAt(removedIndex));
    }

    try {
      await _api.deletePost(postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting post: $e');
      // Revert: put the post back in its original position
      if (mounted && removedPost != null) {
        setState(() {
          if (removedIndex <= _posts.length) {
            _posts.insert(removedIndex, removedPost);
          } else {
            _posts.add(removedPost);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete post. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
