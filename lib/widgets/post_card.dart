import 'package:flutter/material.dart';
import 'package:infano_care_mobile/models/post.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:infano_care_mobile/widgets/report_modal.dart';
import 'package:infano_care_mobile/widgets/appeal_modal.dart';

class PostCard extends StatefulWidget {
  final CommunityPost post;
  final Function(String)? onReact;
  final VoidCallback? onReply;
  final Function(String, String?)? onReport;
  final Function(bool)? onPin; // null = don't show pin option
  final VoidCallback? onBookmark;
  final bool isDetailView;
  final VoidCallback? onTap;
  final Function(String reason)? onAppeal;

  const PostCard({
    Key? key,
    required this.post,
    this.onReact,
    this.onReply,
    this.onReport,
    this.onPin,
    this.onBookmark,
    this.isDetailView = false,
    this.onTap,
    this.onAppeal,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isExpanded = false;

  void _showReportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportModal(
        postId: widget.post.id,
        onSubmit: (category, note) {
          if (widget.onReport != null) widget.onReport!(category, note);
        },
      ),
    );
  }

  void _showAppealModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppealModal(
        contentId: widget.post.id,
        contentType: 'post',
        onSubmit: (reason) {
          if (widget.onAppeal != null) widget.onAppeal!(reason);
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'EXPERT':
      case 'MENTOR':
        return const Color(0xFF8B5CF6); // Mentor - Purple
      case 'PARENT':
      case 'GUARDIAN':
      case 'REGULAR':
        return const Color(0xFF3B82F6); // Regular - Blue
      default: // TEEN / NEWCOMER
        return const Color(0xFF10B981); // Newcomer - Green
    }
  }

  String _getRoleLabel(String role) {
    switch (role.toUpperCase()) {
      case 'EXPERT':
      case 'MENTOR':
        return 'Mentor';
      case 'PARENT':
      case 'GUARDIAN':
      case 'REGULAR':
        return 'Regular';
      default:
        return 'Newcomer';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = _getTimeAgo(widget.post.createdAt);
    final isLongContent = widget.post.content.length > 280;
    final displayContent = !isLongContent || _isExpanded
        ? widget.post.content
        : '${widget.post.content.substring(0, 280)}...';

    return Hero(
      tag: 'post_${widget.post.id}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: widget.post.isPinned
              ? Border.all(color: AppColors.purple.withOpacity(0.3), width: 2)
              : Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: widget.post.status == 'REMOVED'
                      ? _buildRemovedCollapsedView()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pinned Badge
                if (widget.post.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                         Icon(Icons.push_pin, size: 14, color: AppColors.purple),
                        const SizedBox(width: 4),
                        const Text(
                          'PINNED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.purple,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                // Featured / Challenge Chips
                if (widget.post.isFeatured || widget.post.challengeTheme != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        if (widget.post.isFeatured)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Text('⭐', style: TextStyle(fontSize: 10)),
                                const SizedBox(width: 4),
                                Text(
                                  'Featured',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                ),
                              ],
                            ),
                          ),
                        if (widget.post.challengeTheme != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '#${widget.post.challengeTheme}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                            ),
                          ),
                      ],
                    ),
                  ),
        
                // Author row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Level dot (colour-coded)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _getRoleColor(widget.post.authorRole),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _getRoleColor(widget.post.authorRole).withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Display name
                    Flexible(
                      child: Text(
                        widget.post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    // Relative timestamp
                    Text(
                      timeAgo,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  displayContent,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
                if (isLongContent)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _isExpanded ? 'Read less' : 'Read more',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (!widget.isDetailView) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _ReactionButton(
                        emoji: '💜',
                        count: widget.post.reactionHeart,
                        onTap: () => _handleReact('heart'),
                      ),
                      _ReactionButton(
                        emoji: '🤗',
                        count: widget.post.reactionHug,
                        onTap: () => _handleReact('hug'),
                      ),
                      _ReactionButton(
                        emoji: '💡',
                        count: widget.post.reactionBulb,
                        onTap: () => _handleReact('bulb'),
                      ),
                      _ReactionButton(
                        emoji: '👊',
                        count: widget.post.reactionFist,
                        onTap: () => _handleReact('fist'),
                      ),
                      const Spacer(),
                      _ActionEmojiButton(
                        emoji: '💬',
                        label: '${widget.post.replyCount} replies',
                        onTap: widget.onReply,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                  // Action Row: Bookmark + Report (minimal opacity)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.onPin != null) ...[  
                        IconButton(
                          icon: Icon(
                            widget.post.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                            size: 18,
                            color: widget.post.isPinned ? AppColors.purple : Colors.grey.shade400,
                          ),
                          onPressed: () => widget.onPin!(!widget.post.isPinned),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                      ],
                      IconButton(
                        icon: Icon(
                          widget.post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          size: 20,
                          color: widget.post.isBookmarked ? AppColors.purple : Colors.grey.shade400,
                        ),
                        onPressed: widget.onBookmark,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: widget.post.isBookmarked ? 'Remove bookmark' : 'Bookmark',
                      ),
                      const SizedBox(width: 12),
                      Opacity(
                        opacity: 0.35,
                        child: IconButton(
                          icon: const Icon(Icons.flag_outlined, size: 18, color: Colors.grey),
                          onPressed: () => _showReportModal(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Report',
                        ),
                      ),
                    ],
                  ),
                          ],
                        ),
                ),
                _buildModerationOverlay(widget.post.status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleReact(String reaction) {
    if (widget.onReact != null) widget.onReact!(reaction);
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 7) {
      return DateFormat('MMM dd').format(dateTime);
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    }
    return 'Just now';
  }

  Widget _buildRemovedCollapsedView() {
    final bool canAppeal = DateTime.now().difference(widget.post.createdAt).inHours < 48;

    return Row(
      children: [
        Icon(Icons.report_gmailerrorred, color: Colors.grey.shade400, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This post was removed for violating community guidelines.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (canAppeal)
                GestureDetector(
                  onTap: () => _showAppealModal(context),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Appeal decision',
                      style: TextStyle(
                        color: AppColors.purple,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModerationOverlay(String status) {
    String label = 'Under Review';
    bool showSpinner = false;

    if (status == 'PENDING_AI') {
      label = 'Analyzing...';
      showSpinner = true;
    } else if (status == 'PENDING_HUMAN') {
      label = 'Under Review';
      showSpinner = false;
    } else {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSpinner) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: AppColors.purple.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final String emoji;
  final int count;
  final VoidCallback? onTap;

  const _ReactionButton({required this.emoji, required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionEmojiButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback? onTap;

  const _ActionEmojiButton({required this.emoji, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
