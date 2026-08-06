import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/models/post.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/journal/data/models/journal_entry.dart';
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
                          const Text(
                            'PINNED',
                            style: TextStyle(
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
                                const Text('⭐', style: TextStyle(fontSize: 10)),
                                const SizedBox(width: 6),
                                Text(
                                  'Featured',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
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
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0F766E)),
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
                              style: TextStyle(
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: Color(0xFF1F2937),
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_getRoleLabel(widget.post.authorRole)} • $timeAgo',
                            style: TextStyle(
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
                        style: const TextStyle(
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
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // ── Embedded Journal Card (shown when post has journalData) ──
                if (widget.post.journalData != null) ...[
                  const SizedBox(height: 12),
                  _buildEmbeddedJournalCard(widget.post.journalData!),
                ],
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
              title: const Text('Report Post'),
              onTap: () {
                Navigator.pop(context);
                _showReportModal(context);
              },
            ),
            if (widget.onDelete != null) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text(
                  'Delete Post',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
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
        title: const Text('Delete Post?'),
        content: const Text(
          'This will permanently remove your post from the community. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
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
            child: const Text('Delete'),
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
                style: TextStyle(
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

  /// Renders the embedded rich journal scrapbook card inside a community post.
  Widget _buildEmbeddedJournalCard(Map<String, dynamic> data) {
    final String mode = (data['mode'] as String? ?? 'free_write').toLowerCase();
    final String? title = data['title'] as String?;
    final String? moodTag = data['moodTag'] as String?;
    final Map<String, dynamic> content =
        data['content'] is Map ? Map<String, dynamic>.from(data['content'] as Map) : {};

    // Mode metadata
    String modeEmoji;
    String modeLabel;
    List<Color> gradientColors;
    switch (mode) {
      case 'guided_prompt':
        modeEmoji = '💡'; modeLabel = 'Guided Prompt';
        gradientColors = const [Color(0xFF7C3AED), Color(0xFF9F67FA)];
        break;
      case 'mood_color':
        modeEmoji = '🎨'; modeLabel = 'Mood Color';
        gradientColors = const [Color(0xFFEC4899), Color(0xFFF97316)];
        break;
      case 'voice_note':
        modeEmoji = '🎤'; modeLabel = 'Voice Note';
        gradientColors = const [Color(0xFF0EA5E9), Color(0xFF6366F1)];
        break;
      case 'photo_board':
        modeEmoji = '📸'; modeLabel = 'Photo Board';
        gradientColors = const [Color(0xFF10B981), Color(0xFF0EA5E9)];
        break;
      case 'letter_mode':
        modeEmoji = '✉️'; modeLabel = 'Letter Mode';
        gradientColors = const [Color(0xFFF59E0B), Color(0xFFEC4899)];
        break;
      case 'video_diary':
        modeEmoji = '🎬'; modeLabel = 'Video Diary';
        gradientColors = const [Color(0xFF1E1B4B), Color(0xFF7C3AED)];
        break;
      case 'doodle':
        modeEmoji = '🖊️'; modeLabel = 'Doodle';
        gradientColors = const [Color(0xFFF97316), Color(0xFFEC4899)];
        break;
      case 'blackout_poetry':
        modeEmoji = '📝'; modeLabel = 'Blackout Poetry';
        gradientColors = const [Color(0xFF1F2937), Color(0xFF374151)];
        break;
      default:
        modeEmoji = '✏️'; modeLabel = 'Free Write';
        gradientColors = const [Color(0xFF6366F1), Color(0xFF8B5CF6)];
    }

    final String promptText = (content['promptText'] as String? ?? '').trim();
    final String headerTitle = (title?.isNotEmpty == true)
        ? title!
        : (promptText.isNotEmpty ? promptText : modeLabel);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gradientColors[0].withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(modeEmoji, style: const TextStyle(fontSize: 10)),
                            const SizedBox(width: 4),
                            Text(modeLabel,
                              style: GoogleFonts.nunito(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        headerTitle,
                        style: GoogleFonts.nunito(
                          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, height: 1.25),
                        maxLines: widget.isDetailView ? 10 : 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('📓 Journal',
                    style: GoogleFonts.nunito(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          // Mode-specific body
          _buildJournalCardBody(mode, content, moodTag, gradientColors),
        ],
      ),
    );
  }

  Widget _buildJournalCardBody(
    String mode,
    Map<String, dynamic> content,
    String? moodTag,
    List<Color> gradientColors,
  ) {
    final isDetail = widget.isDetailView;

    switch (mode) {

      case 'doodle':
        final rawStrokes = content['strokes'] as List? ?? [];
        final strokes = rawStrokes
            .map((s) => DoodleStroke.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList();
        return SizedBox(
          height: isDetail ? 240 : 180,
          child: strokes.isNotEmpty
              ? ClipRect(
                  child: CustomPaint(
                    painter: DoodlePainter(strokes: strokes),
                    size: Size.infinite,
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎨', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 6),
                      Text('Creative Doodle Page',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: const Color(0xFF6B7280), fontSize: 13)),
                    ],
                  ),
                ),
        );

      case 'mood_color':
        final rawColors = (content['colors'] as List?)?.map((c) => c.toString()).toList() ?? [];
        final caption = (content['caption'] as String? ?? '').trim();
        final label = (content['label'] as String? ?? '').trim();
        final displayColors = isDetail ? rawColors : rawColors.take(5).toList();
        return Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ...displayColors.map((hexStr) {
                    Color c = gradientColors[0];
                    try { c = Color(int.parse('FF${hexStr.replaceAll('#', '')}', radix: 16)); } catch (_) {}
                    return Container(
                      width: 30, height: 30,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: c, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1)],
                      ),
                    );
                  }),
                  if (label.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(child: Text(label,
                      style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF374151)),
                      overflow: TextOverflow.ellipsis)),
                  ],
                ],
              ),
              if (caption.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF4FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF5D0FE)),
                  ),
                  child: Text('"$caption"',
                    style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic, color: const Color(0xFF374151)),
                    maxLines: isDetail ? 100 : 4, overflow: TextOverflow.ellipsis),
                ),
              ],
              if (moodTag != null) ...[const SizedBox(height: 8), _moodTagPill(moodTag)],
            ],
          ),
        );

      case 'blackout_poetry':
        final poem = (content['poem'] as String? ?? '').trim();
        final selectedWords = (content['selectedWords'] as List? ?? []).map((e) => e.toString()).toList();
        final displayWords = isDetail ? selectedWords : selectedWords.take(10).toList();
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B4B),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (displayWords.isNotEmpty) ...[
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: displayWords.map((w) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFFBBF24), borderRadius: BorderRadius.circular(8)),
                    child: Text(w, style: GoogleFonts.nunito(
                      color: const Color(0xFF1E1B4B), fontWeight: FontWeight.w900, fontSize: 11)),
                  )).toList(),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                poem.isNotEmpty ? '"$poem"' : '✒️ A blackout poem',
                style: GoogleFonts.nunito(
                  color: poem.isNotEmpty ? Colors.white70 : Colors.white54,
                  fontSize: 13, fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic, height: 1.5),
                maxLines: isDetail ? 100 : 5, overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );

      case 'voice_note':
        final durationSecs = (content['durationSeconds'] as num? ?? 0).toInt();
        final mins = durationSecs ~/ 60;
        final secs = durationSecs % 60;
        final durationStr = '$mins:${secs.toString().padLeft(2, '0')}';
        return Padding(
          padding: const EdgeInsets.all(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
                  ),
                  child: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Voice Note',
                        style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF1E40AF))),
                      const SizedBox(height: 5),
                      Row(
                        children: List.generate(18, (i) {
                          const hs = [12.0, 18.0, 10.0, 22.0, 14.0, 20.0, 8.0, 24.0,
                                       12.0, 18.0, 10.0, 20.0, 14.0, 8.0, 22.0, 16.0, 10.0, 14.0];
                          return Container(
                            width: 3, height: hs[i],
                            margin: const EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(durationStr,
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E40AF))),
              ],
            ),
          ),
        );

      case 'video_diary':
        final caption = (content['caption'] as String? ?? '').trim();
        final vibeTag = (content['vibeTag'] as String? ?? '').trim();
        return Container(
          height: 130,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFFEC4899), Color(0xFF7C3AED)]),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                ),
              ),
              if (caption.isNotEmpty)
                Positioned(
                  bottom: 8, left: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(caption,
                      style: GoogleFonts.nunito(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      maxLines: isDetail ? 5 : 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              if (vibeTag.isNotEmpty)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Text(vibeTag, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
        );

      case 'photo_board':
        final photoCount = (content['photoCount'] as num? ?? 0).toInt();
        final caption = (content['caption'] as String? ?? '').trim();
        return Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF0EA5E9)]),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_rounded, color: Colors.white, size: 15),
                        const SizedBox(width: 5),
                        Text('$photoCount Photo${photoCount != 1 ? 's' : ''}',
                          style: GoogleFonts.nunito(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...List.generate(photoCount.clamp(0, 3), (i) => Container(
                    width: 34, height: 34,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF6EE7B7), width: 1),
                    ),
                    child: const Icon(Icons.image_rounded, size: 17, color: Color(0xFF10B981)),
                  )),
                ],
              ),
              if (caption.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(caption,
                  style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151), height: 1.5),
                  maxLines: isDetail ? 100 : 4, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        );

      case 'letter_mode':
        final to = (content['to'] as String? ?? '').trim();
        final body = (content['body'] as String? ?? content['text'] as String? ?? '').trim();
        return Padding(
          padding: const EdgeInsets.all(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (to.isNotEmpty) ...[
                  Text('Dear $to,',
                    style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF92400E))),
                  const SizedBox(height: 6),
                ],
                Text(
                  body.isEmpty ? '✉️ A heartfelt letter' : body,
                  style: GoogleFonts.nunito(
                    fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF78350F),
                    height: 1.5, fontStyle: body.isEmpty ? FontStyle.italic : FontStyle.normal),
                  maxLines: isDetail ? 100 : 6, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );

      default:
        final selectedOptions = (content['selectedOptions'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final answer = (content['answer'] as String?
            ?? content['text'] as String?
            ?? content['body'] as String?
            ?? '').trim();
        final displayOptions = isDetail ? selectedOptions : selectedOptions.take(5).toList();

        if (selectedOptions.isEmpty && answer.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text('✨ A personal journal entry',
              style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280), fontStyle: FontStyle.italic)),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (displayOptions.isNotEmpty) ...[
                Text('Selected Options:',
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF6B7280))),
                const SizedBox(height: 8),
                ...displayOptions.map((opt) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDD6FE), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_rounded, color: AppColors.purple, size: 14),
                      const SizedBox(width: 7),
                      Expanded(child: Text(opt,
                        style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.purple))),
                    ],
                  ),
                )),
                const SizedBox(height: 8),
              ],
              if (answer.isNotEmpty) ...[
                Text('Your Answer:',
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF6B7280))),
                const SizedBox(height: 6),
                Text(answer,
                  style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937), height: 1.5),
                  maxLines: isDetail ? 100 : 8, overflow: TextOverflow.ellipsis),
              ],
              if (moodTag != null) ...[const SizedBox(height: 8), _moodTagPill(moodTag)],
            ],
          ),
        );
    }
  }

  Widget _moodTagPill(String tag) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFDF2F8),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFBCFE8)),
    ),
    child: Text(tag,
      style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFFEC4899))),
  );
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
              style: TextStyle(
                fontSize: isSelected ? 17 : 15,
                shadows: isSelected ? [
                  Shadow(color: AppColors.purple.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 1))
                ] : null,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}K' : count.toString(),
              style: TextStyle(
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
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
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


