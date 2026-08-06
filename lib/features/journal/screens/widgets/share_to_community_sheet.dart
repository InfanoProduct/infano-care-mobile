import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/journal/application/journal_cubit.dart';
import 'package:infano_care_mobile/features/journal/data/models/journal_entry.dart';
import 'package:infano_care_mobile/features/journal/data/repositories/journal_repository.dart';
import 'package:infano_care_mobile/models/circle.dart';
import 'package:infano_care_mobile/services/community_api.dart';

class ShareToCommunitySheet extends StatefulWidget {
  final JournalEntry entry;

  const ShareToCommunitySheet({super.key, required this.entry});

  @override
  State<ShareToCommunitySheet> createState() => _ShareToCommunitySheetState();
}

class _ShareToCommunitySheetState extends State<ShareToCommunitySheet> {
  final TextEditingController _captionController = TextEditingController();
  
  bool _isLoadingCircles = true;
  List<Circle> _joinedCircles = [];
  Circle? _selectedCircle;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _loadJoinedCircles();
  }

  Future<void> _loadJoinedCircles() async {
    try {
      final api = CommunityApi(ApiService.instance.dio);
      final allCircles = await api.getCircles();
      final joined = allCircles.where((c) => c.isJoined).toList();
      
      if (mounted) {
        setState(() {
          _joinedCircles = joined;
          // If no circles joined, fallback to all available circles so user can still post
          if (_joinedCircles.isNotEmpty) {
            _selectedCircle = _joinedCircles.first;
          } else if (allCircles.isNotEmpty) {
            _selectedCircle = allCircles.first;
          }
          _isLoadingCircles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCircles = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    if (_selectedCircle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a circle to share your entry.', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSharing = true);
    try {
      JournalRepository repo;
      try {
        repo = context.read<JournalCubit>().repo;
      } catch (_) {
        repo = JournalRepository(ApiService.instance.dio);
      }

      await repo.shareEntryToCommunity(
        entryId: widget.entry.id,
        circleId: _selectedCircle!.id,
        caption: _captionController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your journal entry is live in ${_selectedCircle!.name}! 🚀✨',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF7C3AED),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSharing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x207C3AED),
            blurRadius: 30,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header Banner
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF3E8FF), Color(0xFFFCE7F3)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text('🚀', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share to Community',
                      style: GoogleFonts.nunito(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Publish for peers to view, react, & comment 💬',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: AppColors.textMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

          const SizedBox(height: 22),

          // Circle Selection Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _joinedCircles.isNotEmpty ? 'Your Joined Circles:' : 'Select Circle to Post:',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              if (_joinedCircles.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_joinedCircles.length} Joined ✓',
                    style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF7C3AED)),
                  ),
                ),
            ],
          ).animate().fadeIn(delay: 100.ms, duration: 250.ms),

          const SizedBox(height: 10),

          if (_isLoadingCircles)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)),
                ),
              ),
            )
          else if (_joinedCircles.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You haven\'t joined any circles yet. Select a public circle to post, or join circles in Connect!',
                      style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _joinedCircles.map((circle) {
                final isSel = _selectedCircle?.id == circle.id;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: ChoiceChip(
                    label: Text('${circle.iconEmoji} ${circle.name}'),
                    selected: isSel,
                    onSelected: (_) => setState(() => _selectedCircle = circle),
                    selectedColor: const Color(0xFF7C3AED),
                    backgroundColor: const Color(0xFFF5F3FF),
                    side: BorderSide(
                      color: isSel ? const Color(0xFF7C3AED) : const Color(0xFFDDD6FE),
                      width: isSel ? 1.5 : 1.0,
                    ),
                    labelStyle: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: isSel ? Colors.white : AppColors.purple,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 150.ms, duration: 300.ms).slideY(begin: 0.15, end: 0),

          const SizedBox(height: 22),

          // Caption Input Section
          Text(
            'Add Caption / Reflection (Optional):',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 250.ms),

          const SizedBox(height: 8),

          TextField(
            controller: _captionController,
            maxLines: 2,
            style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'Share a note or thought with the community...',
              hintStyle: GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.8),
              ),
            ),
          ).animate().fadeIn(delay: 250.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 26),

          // Publish CTA Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: (_isSharing || _selectedCircle == null) ? null : _share,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: _isSharing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _selectedCircle != null ? 'Publish to ${_selectedCircle!.name} 🚀' : 'Select Circle to Publish 🚀',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 350.ms).scaleXY(begin: 0.95, end: 1.0, curve: Curves.easeOutBack),
        ],
      ),
    );
  }
}
