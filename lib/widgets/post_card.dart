import 'package:google_fonts/google_fonts.dart';
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
  final VoidCallback? onDelete; // null = don't show delete option
  final bool isDetailView;
  final VoidCallback? onTap;
  final Function(String reason)? onAppeal;

  const PostCard({
    super.key,
    required this.post,
    this.onReact,
    this.onReply,
    this.onReport,
    this.onPin,
    this.onBookmark,
    this.onDelete,
    this.isDetailView = false,
    this.onTap,
    this.onAppeal,
  });

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
        return 'Expert';
      case 'PARENT':
      case 'GUARDIAN':
        return 'Guardian';
      case 'TEEN':
        return 'Student';
      default:
        return 'Peer';
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
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: widget.post.isPinned
              ? Border.all(color: AppColors.purple.withValues(alpha: 0.3), width: 2)
              : Border.all(color: Colors.grey.shade100.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: widget.post.status == 'REMOVED'
                      ? _buildRemovedCollapsedView()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pinned Badge
                if (widget.post.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.push_pin, size: 12, color: AppColors.purple),
                          const SizedBox(width: 6),
                          Text(
                            'PINNED',
                            style: GoogleFonts.nunito(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppColors.purple,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                // Featured / Challenge Chips
                if (widget.post.isFeatured || widget.post.challengeTheme != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14.0),
                    child: Row(
                      children: [
                        if (widget.post.isFeatured)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Text('⭐', style: GoogleFonts.nunito(fontSize: 10)),
                                const SizedBox(width: 6),
                                Text(
                                  'Featured',
                                  style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                                ),
                              ],
                            ),
                          ),
                        if (widget.post.challengeTheme != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCCFBF1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '#${widget.post.challengeTheme}',
                              style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0F766E)),
                            ),
                          ),
                      ],
                    ),
                  ),
        
                // Author row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar with Gradient Border
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            _getRoleColor(widget.post.authorRole).withValues(alpha: 0.8),
                            _getRoleColor(widget.post.authorRole).withValues(alpha: 0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: _getRoleColor(widget.post.authorRole).withValues(alpha: 0.1),
                            child: Text(
                              widget.post.authorName.isNotEmpty ? widget.post.authorName[0].toUpperCase() : '?',
                              style: GoogleFonts.nunito(
                                color: _getRoleColor(widget.post.authorRole),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981), // Online green
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Display name & Role
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.authorName,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: Color(0xFF1F2937),
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_getRoleLabel(widget.post.authorRole)} • $timeAgo',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // More Options
                    IconButton(
                      icon: Icon(Icons.more_horiz, color: Colors.grey.shade400, size: 20),
                      onPressed: () => _showMoreOptions(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF2F8), // Very light pastel pink
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayContent,
                        style: GoogleFonts.nunito(
                          fontSize: 15, 
                          height: 1.5,
                          color: Color(0xFF374151),
                          letterSpacing: 0.1,
                        ),
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
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: AppColors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (widget.post.imageUrl != null) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Builder(
                            builder: (context) {
                              String url = widget.post.imageUrl!;
                              if (!url.startsWith('http')) {
                                const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'https://api-dev.infano.care/api/');
                                final baseUrl = Uri.parse(apiUrl).origin;
                                url = '$baseUrl$url';
                              }
                              return Image.network(
                                url,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                  const SizedBox(height: 100, child: Center(child: Icon(Icons.broken_image, color: Colors.grey))),
                              );
                            }
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!widget.isDetailView) ...[
                  const SizedBox(height: 18),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _ReactionButton(
                          emoji: '💜',
                          count: widget.post.reactionHeart,
                          isSelected: widget.post.myReaction == 'heart',
                          onTap: () => _handleReact('heart'),
                        ),
                        _ReactionButton(
                          emoji: '🤗',
                          count: widget.post.reactionHug,
                          isSelected: widget.post.myReaction == 'hug',
                          onTap: () => _handleReact('hug'),
                        ),
                        _ReactionButton(
                          emoji: '💡',
                          count: widget.post.reactionBulb,
                          isSelected: widget.post.myReaction == 'bulb',
                          onTap: () => _handleReact('bulb'),
                        ),
                        _ReactionButton(
                          emoji: '👊',
                          count: widget.post.reactionFist,
                          isSelected: widget.post.myReaction == 'fist',
                          onTap: () => _handleReact('fist'),
                        ),
                        _ActionEmojiButton(
                          emoji: '💬',
                          label: widget.post.replyCount >= 1000 
                              ? '${(widget.post.replyCount / 1000).toStringAsFixed(1)}K' 
                              : widget.post.replyCount.toString(),
                          onTap: widget.onReply,
                        ),
                      ],
                    ),
                  ),
                ],
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

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onPin != null)
              ListTile(
                leading: Icon(
                  widget.post.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: AppColors.purple,
                ),
                title: Text(widget.post.isPinned ? 'Unpin Post' : 'Pin Post'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onPin!(!widget.post.isPinned);
                },
              ),
            ListTile(
              leading: Icon(
                widget.post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: Colors.amber,
              ),
              title: Text(widget.post.isBookmarked ? 'Remove Bookmark' : 'Save Post'),
              onTap: () {
                Navigator.pop(context);
                if (widget.onBookmark != null) widget.onBookmark!();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.redAccent),
              title: Text('Report Post'),
              onTap: () {
                Navigator.pop(context);
                _showReportModal(context);
              },
            ),
            if (widget.onDelete != null) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: Text(
                  'Delete Post',
                  style: GoogleFonts.nunito(color: Colors.red, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Post?'),
        content: Text(
          'This will permanently remove your post from the community. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete!();
            },
            child: Text('Delete'),
          ),
        ],
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
      return '${difference.inDays}d back';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h back';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m back';
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
                style: GoogleFonts.nunito(
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
                      style: GoogleFonts.nunito(
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
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(28),
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
                style: GoogleFonts.nunito(
                  color: AppColors.purple.withValues(alpha: 0.8),
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
  final bool isSelected;
  final VoidCallback? onTap;

  const _ReactionButton({
    required this.emoji,
    required this.count,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppColors.purple.withValues(alpha: 0.15) 
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 12 : 8,
              spreadRadius: isSelected ? 2 : 0,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSelected ? AppColors.purple.withValues(alpha: 0.4) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: GoogleFonts.nunito(
                fontSize: isSelected ? 17 : 15,
                shadows: isSelected ? [
                  Shadow(color: AppColors.purple.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 1))
                ] : null,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}K' : count.toString(),
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: isSelected ? AppColors.purple : const Color(0xFF4B5563),
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: GoogleFonts.nunito(fontSize: 15)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12, 
                color: Color(0xFF4B5563), 
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



