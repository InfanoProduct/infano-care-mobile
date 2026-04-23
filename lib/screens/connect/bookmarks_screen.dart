import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/models/post.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:infano_care_mobile/widgets/post_card.dart';
import 'package:infano_care_mobile/screens/connect/reply_thread_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late CommunityApi _api;
  late Future<List<CommunityPost>> _bookmarksFuture;

  @override
  void initState() {
    super.initState();
    _api = Provider.of<CommunityApi>(context, listen: false);
    _loadBookmarks();
  }

  void _loadBookmarks() {
    if (!mounted) return;
    setState(() {
      _bookmarksFuture = _api.getBookmarks();
    });
  }

  void _navigateToReplies(CommunityPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReplyThreadScreen(post: post),
      ),
    ).then((_) => _loadBookmarks());
  }

  Future<void> _toggleBookmark(CommunityPost post) async {
    try {
      await _api.toggleBookmark(post.id, contentType: 'post');
      _loadBookmarks(); // Refresh list
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Posts', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadBookmarks(),
        child: FutureBuilder<List<CommunityPost>>(
          future: _bookmarksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Error: ${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                ),
              );
            }

            final posts = snapshot.data ?? [];
            if (posts.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No saved posts yet.\nPosts you bookmark will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostCard(
                  key: ValueKey(post.id),
                  post: post,
                  onTap: () => _navigateToReplies(post),
                  onReact: (r) async {
                    await _api.toggleReaction(post.id, r, contentType: 'post');
                    _loadBookmarks();
                  }, 
                  onReply: () => _navigateToReplies(post), 
                  onBookmark: () => _toggleBookmark(post),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
