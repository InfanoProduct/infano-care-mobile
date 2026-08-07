import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/community_api.dart';
import '../../models/post.dart';
import '../../models/circle.dart';
import '../../widgets/post_card.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/theme/app_theme.dart';
import 'reply_thread_screen.dart';

class MyFeedTab extends StatefulWidget {
  const MyFeedTab({super.key});

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

  // Search & Filtering
  String _searchQuery = "";

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

  Future<void> _loadPosts({bool refresh = false, bool isSilent = false}) async {
    if (refresh) {
      _currentPage = 1;
      if (!isSilent) {
        _posts.clear();
        setState(() {
          _isLoading = true;
          _hasError = false;
          _hasMore = true;
        });
      }
    }

    try {
      final response = await _api.getMyFeed(page: _currentPage);
      final List<dynamic> postsJson = response['posts'] ?? [];
      final List<CommunityPost> newPosts = postsJson
          .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
          .toList();
      
      if (mounted) {
        setState(() {
          if (refresh) _posts.clear();
          _posts.addAll(newPosts);
          _isLoading = false;
          _hasMore = response['pagination']?['hasMore'] ?? false;
          _currentPage++;
          _hasError = false;
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

  List<CommunityPost> _getFilteredPosts() {
    if (_searchQuery.isEmpty) return _posts;
    return _posts.where((p) => p.content.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  Future<void> _showCreatePostSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreatePostSheet(api: _api),
    ).then((submitted) {
      if (submitted == true) {
        _loadPosts(refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isLoading && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError && _posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('Something went wrong', style: GoogleFonts.nunito(color: AppColors.textMedium)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _loadPosts(refresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Try Again', style: GoogleFonts.nunito(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final filteredPosts = _getFilteredPosts();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostSheet,
        backgroundColor: AppColors.purple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      body: Column(
        children: [
          // Search Box
          if (_posts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search feed...',
                  hintStyle: GoogleFonts.nunito(color: Colors.grey.shade400),
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
            ),

          Expanded(
            child: _posts.isEmpty
                ? RefreshIndicator(
                    onRefresh: () => _loadPosts(refresh: true, isSilent: true),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.55,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.purple.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.rss_feed_rounded, size: 48, color: AppColors.purple),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Your feed is empty',
                              style: GoogleFonts.nunito(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Join community circles to see posts and start sharing with others!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(color: AppColors.textMedium, fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Tap the "Circles" tab at the top to explore circles!', style: GoogleFonts.nunito()),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: AppColors.purple,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.explore_outlined, size: 18),
                              label: Text(
                                'Browse Circles',
                                style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.purple,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadPosts(refresh: true, isSilent: true),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filteredPosts.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == filteredPosts.length) {
                          _loadPosts();
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final post = filteredPosts[index];
                        final canDelete = post.authorId == _currentUserId ||
                            _currentUserRole?.toUpperCase() == 'ADMIN';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: PostCard(
                            key: ValueKey(post.id),
                            post: post,
                            onTap: () => _navigateToReplies(post),
                            onReply: () => _navigateToReplies(post),
                            onReact: (reaction) => _toggleReaction(post.id, reaction),
                            onBookmark: () => _toggleBookmark(post),
                            onDelete: canDelete ? () => _deletePost(post.id) : null,
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _navigateToReplies(CommunityPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReplyThreadScreen(post: post),
      ),
    ).then((_) => _loadPosts(refresh: true, isSilent: true)); // Refresh silently on back
  }

  Future<void> _toggleReaction(String postId, String reaction) async {
    setState(() {
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = _posts[index];
        final oldReaction = post.myReaction;
        
        if (oldReaction == reaction) {
          _posts[index] = post.copyWith(
            myReaction: null,
            reactionHeart: reaction == 'heart' ? post.reactionHeart - 1 : post.reactionHeart,
            reactionHug: reaction == 'hug' ? post.reactionHug - 1 : post.reactionHug,
            reactionBulb: reaction == 'bulb' ? post.reactionBulb - 1 : post.reactionBulb,
            reactionFist: reaction == 'fist' ? post.reactionFist - 1 : post.reactionFist,
          );
        } else {
          int heart = post.reactionHeart;
          int hug = post.reactionHug;
          int bulb = post.reactionBulb;
          int fist = post.reactionFist;

          if (oldReaction == 'heart') heart--;
          if (oldReaction == 'hug') hug--;
          if (oldReaction == 'bulb') bulb--;
          if (oldReaction == 'fist') fist--;

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
    }
  }

  Future<void> _toggleBookmark(CommunityPost post) async {
    final originalState = post.isBookmarked;
    
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

// ── Quick Create Post Sheet Component ─────────────────────────────────────────

class _CreatePostSheet extends StatefulWidget {
  final CommunityApi api;
  const _CreatePostSheet({required this.api});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final TextEditingController _textController = TextEditingController();
  List<Circle> _joinedCircles = [];
  Circle? _selectedCircle;
  bool _isLoadingCircles = true;
  bool _isSubmitting = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCircles();
  }

  Future<void> _loadCircles() async {
    try {
      final circles = await widget.api.getCircles();
      if (mounted) {
        setState(() {
          _joinedCircles = circles.where((c) => c.isJoined && !c.isAgeSpecific).toList();
          if (_joinedCircles.isNotEmpty) {
            _selectedCircle = _joinedCircles.first;
          }
          _isLoadingCircles = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading joined circles: $e');
      if (mounted) {
        setState(() => _isLoadingCircles = false);
      }
    }
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _selectedCircle == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await widget.api.uploadImage(_selectedImage!.path);
      }
      await widget.api.createPost(_selectedCircle!.id, text, imageUrl: imageUrl);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post published successfully to ${_selectedCircle!.name}! 🎉', style: GoogleFonts.nunito()),
            backgroundColor: AppColors.purple,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish post: $e', style: GoogleFonts.nunito()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboardSpace),
      child: _isLoadingCircles
          ? const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()))
          : _joinedCircles.isEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.orange.shade400, size: 40),
                    const SizedBox(height: 16),
                    Text(
                      'No Joined Circles',
                      style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You must join at least one circle before you can create a post.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('OK', style: GoogleFonts.nunito(color: Colors.white)),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Create New Post',
                          style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select circle to post to:',
                      style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMedium),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Circle>(
                          value: _selectedCircle,
                          isExpanded: true,
                          items: _joinedCircles.map((circle) {
                            return DropdownMenuItem<Circle>(
                              value: circle,
                              child: Text('${circle.iconEmoji} ${circle.name}', style: GoogleFonts.nunito(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedCircle = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _textController,
                      maxLines: 4,
                      maxLength: 500,
                      autofocus: true,
                      style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Share anonymously with the community...',
                        hintStyle: GoogleFonts.nunito(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.purple),
                        ),
                      ),
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 12),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_selectedImage!, height: 100, width: double.infinity, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: InkWell(
                              onTap: () => setState(() => _selectedImage = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image_outlined, color: AppColors.purple),
                          tooltip: 'Attach Image',
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text('Publish Anonymously', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }
}

