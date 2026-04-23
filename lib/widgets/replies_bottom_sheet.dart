import 'package:flutter/material.dart';
import 'package:infano_care_mobile/models/post.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:provider/provider.dart';

class RepliesBottomSheet extends StatefulWidget {
  final CommunityPost post;

  const RepliesBottomSheet({Key? key, required this.post}) : super(key: key);

  @override
  State<RepliesBottomSheet> createState() => _RepliesBottomSheetState();
}

class _RepliesBottomSheetState extends State<RepliesBottomSheet> {
  late Future<List<CommunityReply>> _repliesFuture;
  final TextEditingController _replyController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _refreshReplies();
  }

  void _refreshReplies() {
    final api = Provider.of<CommunityApi>(context, listen: false);
    setState(() {
      _repliesFuture = api.getPostReplies(widget.post.id);
    });
  }

  Future<void> _submitReply({String? parentId, int depth = 1}) async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final api = Provider.of<CommunityApi>(context, listen: false);
      await api.createReply(
        widget.post.id, 
        _replyController.text.trim(), 
        parentReplyId: parentId
      );
      _replyController.clear();
      if (mounted) Navigator.pop(context, true); // Signal: a reply was posted
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Handle/Header
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Conversations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          
          // Reply List
          Expanded(
            child: FutureBuilder<List<CommunityReply>>(
              future: _repliesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading replies'));
                }

                final replies = snapshot.data ?? [];
                if (replies.isEmpty) {
                  return Center(
                    child: Text(
                      'No replies yet.\nBe the first to share support! 🤗',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: replies.length,
                  itemBuilder: (context, index) {
                    final reply = replies[index];
                    return _ReplyItem(
                      reply: reply,
                      onReplyTap: (parentId, depth) {
                        // Focus and set parent for next reply
                        // (Simplified for now: root level only or nested)
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Input field
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts...',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 12),
                _isSubmitting
                    ? const CircularProgressIndicator()
                    : FloatingActionButton(
                        onPressed: () => _submitReply(),
                        mini: true,
                        backgroundColor: AppColors.purple,
                        elevation: 0,
                        child: const Icon(Icons.send_rounded, color: Colors.white),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyItem extends StatelessWidget {
  final CommunityReply reply;
  final Function(String, int) onReplyTap;

  const _ReplyItem({required this.reply, required this.onReplyTap});

  @override
  Widget build(BuildContext context) {
    // Spec Requirement: 3-level depth limit
    // We visually indent based on depth
    final double leftPadding = (reply.depth - 1) * 24.0;

    return Padding(
      padding: EdgeInsets.only(left: leftPadding, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.purple.withOpacity(0.1),
                child: Text(
                  (reply.authorName.isNotEmpty ? reply.authorName[0] : 'A').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold, 
                    color: AppColors.purple
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                reply.authorName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              reply.content,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
          if (reply.depth < 3)
            TextButton(
              onPressed: () => onReplyTap(reply.id, reply.depth + 1),
              child: Text(
                'Reply',
                style: TextStyle(fontSize: 12, color: AppColors.purple),
              ),
            ),
        ],
      ),
    );
  }
}
