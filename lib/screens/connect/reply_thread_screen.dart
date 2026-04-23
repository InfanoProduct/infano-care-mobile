import 'package:flutter/material.dart';
import 'package:infano_care_mobile/models/post.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/widgets/post_card.dart';
import 'package:infano_care_mobile/widgets/report_modal.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ReplyThreadScreen extends StatefulWidget {
  final CommunityPost post;

  const ReplyThreadScreen({Key? key, required this.post}) : super(key: key);

  @override
  State<ReplyThreadScreen> createState() => _ReplyThreadScreenState();
}

class _ReplyThreadScreenState extends State<ReplyThreadScreen> {
  late CommunityApi _api;
  late Future<List<CommunityReply>> _repliesFuture;
  final TextEditingController _replyController = TextEditingController();
  bool _isSubmitting = false;
  String? _replyingToId;
  String? _replyingToName;
  int _replyingToDepth = 1;

  final Map<String, bool> _localBookmarkState = {};
  final Map<String, Map<String, int>> _localReactionCounts = {};
  final Map<String, Map<String, bool>> _localUserReactions = {};

  @override
  void initState() {
    super.initState();
    _api = Provider.of<CommunityApi>(context, listen: false);
    _refreshReplies();
  }

  void _refreshReplies() {
    if (!mounted) return;
    setState(() {
      _repliesFuture = _api.getPostReplies(widget.post.id);
    });
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await _api.createReply(
        widget.post.id,
        _replyController.text.trim(),
        parentReplyId: _replyingToId,
      );
      _replyController.clear();
      setState(() {
        _replyingToId = null;
        _replyingToName = null;
        _replyingToDepth = 1;
      });
      _refreshReplies();
      if (mounted) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply submitted for moderation 💜')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _startReply(String id, String name, int depth) {
    setState(() {
      _replyingToId = id;
      _replyingToName = name;
      _replyingToDepth = depth;
    });
    FocusScope.of(context).requestFocus(FocusNode()); // Trigger keyboard if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Conversation'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _refreshReplies(),
              child: CustomScrollView(
                slivers: [
                  // Level 0: The Original Post
                  SliverToBoxAdapter(
                    child: PostCard(
                      post: widget.post,
                      isDetailView: true,
                      onTap: () {}, // Already here
                    ),
                  ),
                  const SliverToBoxAdapter(child: Divider(height: 1)),
                  
                  // Replies Tree
                  FutureBuilder<List<CommunityReply>>(
                    future: _repliesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return SliverFillRemaining(
                          child: Center(child: Text('Error loading replies: ${snapshot.error}')),
                        );
                      }

                      final replies = snapshot.data ?? [];
                      if (replies.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('🌿', style: TextStyle(fontSize: 40)),
                                const SizedBox(height: 16),
                                Text(
                                  'No replies yet.\nStart the conversation!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _ReplyTreeBranch(
                              reply: replies[index],
                              onReply: _startReply,
                              api: _api,
                            );
                          },
                          childCount: replies.length,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Level 3 Guardrail or Input
          _buildInputSection(),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    if (_replyingToDepth >= 3) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.softAmber.withOpacity(0.1),
          border: Border(top: BorderSide(color: AppColors.softAmber.withOpacity(0.3))),
        ),
        child: Column(
          children: [
            const Text(
              'This conversation is getting deep — continue the discussion in a new post 🌿',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            TextButton(
              onPressed: () {
                // Link to compose post (implementation deferred or handled by parent)
                Navigator.pop(context);
              },
              child: const Text('Back to Feed'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.only(
        bottom: 20,
        left: 16,
        right: 16,
        top: 12,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingToName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    'Replying to ',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    _replyingToName!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() {
                      _replyingToId = null;
                      _replyingToName = null;
                      _replyingToDepth = 1;
                    }),
                    child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  maxLength: 280,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts...',
                    counterText: '',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _isSubmitting
                  ? const SizedBox(
                      width: 40,
                      height: 40,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                    onPressed: _submitReply,
                    icon: Icon(Icons.send_rounded, color: AppColors.purple),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReplyTreeBranch extends StatelessWidget {
  final CommunityReply reply;
  final Function(String, String, int) onReply;
  final CommunityApi api;

  const _ReplyTreeBranch({
    required this.reply,
    required this.onReply,
    required this.api,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReplyNode(reply: reply, onReply: onReply, api: api),
        ...reply.childReplies.map((child) => _ReplyTreeBranch(
          reply: child,
          onReply: onReply,
          api: api,
        )),
      ],
    );
  }
}

class _ReplyNode extends StatefulWidget {
  final CommunityReply reply;
  final Function(String, String, int) onReply;
  final CommunityApi api;

  const _ReplyNode({
    required this.reply,
    required this.onReply,
    required this.api,
  });

  @override
  State<_ReplyNode> createState() => _ReplyNodeState();
}

class _ReplyNodeState extends State<_ReplyNode> {
  late bool _isBookmarked;
  late Map<String, int> _reactionCounts;
  late Map<String, bool> _userReactions;

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.reply.isBookmarked;
    _reactionCounts = {
      'heart': widget.reply.reactionHeart,
      'hug': widget.reply.reactionHug,
      'bulb': widget.reply.reactionBulb,
      'fist': widget.reply.reactionFist,
    };
    // Placeholder for user reactions per reply if backend supports it
    _userReactions = {}; 
  }

  Color _getBorderColor(int depth) {
    switch (depth) {
      case 1: return AppColors.teal;
      case 2: return AppColors.purple;
      case 3: return AppColors.softAmber;
      default: return Colors.grey;
    }
  }

  Future<void> _toggleReaction(String reaction) async {
    final isAdding = !(_userReactions[reaction] ?? false);
    setState(() {
      _userReactions[reaction] = isAdding;
      _reactionCounts[reaction] = (_reactionCounts[reaction] ?? 0) + (isAdding ? 1 : -1);
    });

    try {
      await widget.api.toggleReaction(
        widget.reply.id, 
        reaction, 
        contentType: 'reply', 
        action: isAdding ? 'add' : 'remove'
      );
    } catch (e) {
      setState(() {
        _userReactions[reaction] = !isAdding;
        _reactionCounts[reaction] = (_reactionCounts[reaction] ?? 0) + (isAdding ? -1 : 1);
      });
    }
  }

  Future<void> _toggleBookmark() async {
    final prev = _isBookmarked;
    setState(() => _isBookmarked = !prev);
    try {
      final res = await widget.api.toggleBookmark(widget.reply.id, contentType: 'reply');
      setState(() => _isBookmarked = res['bookmarked'] ?? !prev);
    } catch (e) {
      setState(() => _isBookmarked = prev);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double leftPadding = (widget.reply.depth - 1) * 16.0;
    
    return Padding(
      padding: EdgeInsets.only(left: leftPadding, right: 16, top: 12, bottom: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.reply.depth > 0)
              Container(
                width: 2,
                margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                decoration: BoxDecoration(
                  color: _getBorderColor(widget.reply.depth),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.reply.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 6),
                      Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey)),
                      const SizedBox(width: 6),
                      Text(
                        _formatTimeAgo(widget.reply.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.reply.content,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  _buildActionBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Row(
      children: [
        _buildReactionItem('❤️', 'heart'),
        _buildReactionItem('🤗', 'hug'),
        _buildReactionItem('💡', 'bulb'),
        _buildReactionItem('👊', 'fist'),
        const SizedBox(width: 8),
        if (widget.reply.depth < 3)
          TextButton(
            onPressed: () => widget.onReply(widget.reply.id, widget.reply.authorName, widget.reply.depth + 1),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('Reply', style: TextStyle(fontSize: 12, color: AppColors.purple, fontWeight: FontWeight.bold)),
          ),
        const Spacer(),
        IconButton(
          onPressed: _toggleBookmark,
          icon: Icon(
            _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
            size: 18,
            color: _isBookmarked ? AppColors.purple : Colors.grey.shade400,
          ),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
        ),
        IconButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => ReportModal(
                postId: widget.reply.id,
                onSubmit: (cat, note) => widget.api.reportPost(widget.reply.id, cat, note, contentType: 'reply'),
              ),
            );
          },
          icon: Icon(Icons.flag_outlined, size: 18, color: Colors.grey.shade400),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
        ),
      ],
    );
  }

  Widget _buildReactionItem(String emoji, String type) {
    final count = _reactionCounts[type] ?? 0;
    final isSelected = _userReactions[type] ?? false;
    
    return GestureDetector(
      onTap: () => _toggleReaction(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? AppColors.purple : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}
