import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/journal/data/models/journal_entry.dart';

class JournalModePickerScreen extends StatefulWidget {
  final Map<String, dynamic>? extra;

  const JournalModePickerScreen({super.key, this.extra});

  @override
  State<JournalModePickerScreen> createState() => _JournalModePickerScreenState();
}

class _JournalModePickerScreenState extends State<JournalModePickerScreen> {
  JournalMode? _hoveredMode;

  static const _allModes = JournalMode.values;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF4FF),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.88,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildModeTile(context, _allModes[index], index),
                childCount: _allModes.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        color: AppColors.textDark,
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF5F3FF), Color(0xFFFDF2F8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 70, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('How do you want to\nexpress yourself today?',
                style: GoogleFonts.nunito(
                  fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark, height: 1.2),
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
              const SizedBox(height: 4),
              Text('Pick whatever feels right ✨',
                style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMedium),
              ).animate().fadeIn(delay: 100.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeTile(BuildContext context, JournalMode mode, int index) {
    final isHovered = _hoveredMode == mode;
    return GestureDetector(
      onTapDown: (_) => setState(() => _hoveredMode = mode),
      onTapUp: (_) {
        setState(() => _hoveredMode = null);
        _navigateToComposer(context, mode);
      },
      onTapCancel: () => setState(() => _hoveredMode = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: isHovered
            ? (Matrix4.identity()..scale(0.95))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: mode.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: mode.gradient.first.withValues(alpha: isHovered ? 0.5 : 0.25),
              blurRadius: isHovered ? 20 : 12,
              offset: Offset(0, isHovered ? 8 : 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mode emoji in a circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(mode.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const Spacer(),
              Text(mode.displayName,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  height: 1.2,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 2),
              Text(mode.description,
                style: GoogleFonts.nunito(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 10,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: 40 * index), duration: 300.ms).scale(begin: const Offset(0.85, 0.85)),
    );
  }

  void _navigateToComposer(BuildContext context, JournalMode mode) {
    context.pushReplacement('/journal/compose', extra: {
      'mode': mode.apiValue,
      ...?widget.extra,
    });
  }
}
