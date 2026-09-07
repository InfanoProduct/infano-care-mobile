import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/courses/data/models/course_models.dart';
import 'package:infano_care_mobile/features/courses/data/repositories/courses_repository.dart';

class CourseOverviewScreen extends StatefulWidget {
  final String courseId;

  const CourseOverviewScreen({super.key, required this.courseId});

  @override
  State<CourseOverviewScreen> createState() => _CourseOverviewScreenState();
}

class _CourseOverviewScreenState extends State<CourseOverviewScreen> {
  late final CoursesRepository _repo;
  LmsCourse? _course;
  List<LmsProgress> _progress = [];
  bool _isLoading = true;
  String? _error;
  final Map<String, bool> _expandedModules = {};

  @override
  void initState() {
    super.initState();
    _repo = CoursesRepository(ApiService.instance.dio);
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _repo.getCourseDetails(widget.courseId),
        _repo.getCourseProgress(widget.courseId),
      ]);

      final course = results[0] as LmsCourse;
      final progress = results[1] as List<LmsProgress>;

      // Auto expand first in-progress or first module
      if (course.modules.isNotEmpty) {
        bool found = false;
        for (final mod in course.modules) {
          final done = mod.chapters
              .where((c) => progress.any((p) => p.chapterId == c.id && p.isCompleted))
              .length;
          if (done > 0 && done < mod.chapters.length) {
            _expandedModules[mod.id] = true;
            found = true;
            break;
          }
        }
        if (!found) {
          _expandedModules[course.modules.first.id] = true;
        }
      }

      if (mounted) {
        setState(() {
          _course = course;
          _progress = progress;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load course details. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  bool _isChapterCompleted(String chapterId) {
    return _progress.any((p) => p.chapterId == chapterId && p.isCompleted);
  }

  bool _isChapterUnlocked(String chapterId) {
    if (_course == null) return false;
    final flat = _course!.flatChapters;
    final idx = flat.indexWhere((c) => c.id == chapterId);
    if (idx <= 0) return true;
    final prevId = flat[idx - 1].id;
    return _progress.any((p) => p.chapterId == prevId && p.isCompleted);
  }

  LmsChapter? _getNextChapter() {
    if (_course == null) return null;
    final flat = _course!.flatChapters;
    for (final ch in flat) {
      if (!_isChapterCompleted(ch.id)) return ch;
    }
    return flat.isNotEmpty ? flat.last : null;
  }

  int _calculateQuizScore() {
    if (_course == null) return 0;
    int total = 0;
    for (final ch in _course!.flatChapters) {
      if (ch.type == 'ASSESSMENT' && ch.assessment != null) {
        final prog = _progress.firstWhere(
          (p) => p.chapterId == ch.id && p.isCompleted,
          orElse: () => const LmsProgress(chapterId: '', isCompleted: false),
        );
        if (prog.isCompleted) {
          total += prog.score ?? 0;
        }
      }
    }
    return total;
  }

  int _calculateMaxQuizScore() {
    if (_course == null) return 0;
    int max = 0;
    for (final ch in _course!.flatChapters) {
      if (ch.type == 'ASSESSMENT' && ch.assessment != null) {
        max += ch.assessment!.questions.length;
      }
    }
    return max;
  }

  void _navigateToPlayer([String? targetChapterId]) {
    if (_course == null || _course!.flatChapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No video lessons available in this course yet.'),
        ),
      );
      return;
    }

    final next = targetChapterId != null
        ? _course?.flatChapters.firstWhere(
            (c) => c.id == targetChapterId,
            orElse: () => _course!.flatChapters.first,
          )
        : (_getNextChapter() ?? _course!.flatChapters.first);

    context.push(
      '/courses/${widget.courseId}/player',
      extra: {
        'initialChapterId': next?.id,
      },
    ).then((_) {
      // Reload on back from player to refresh completed chapters
      _loadCourseData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.textDark),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/my-courses');
            }
          },
        ),
        title: Text(
          _course?.title ?? 'Course Overview',
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.purple),
      );
    }

    if (_error != null || _course == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 56, color: Color(0xFFEF4444)),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Course not found',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadCourseData,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final course = _course!;
    final totalChapters = course.totalChapters;
    final completedChapters =
        _progress.where((p) => p.isCompleted).length;
    final progressPct = totalChapters > 0
        ? ((completedChapters / totalChapters) * 100).round()
        : 0;
    final remainingChapters = (totalChapters - completedChapters).clamp(0, totalChapters);
    final totalScore = _calculateQuizScore();
    final maxScore = _calculateMaxQuizScore();
    final nextChapter = _getNextChapter();

    return RefreshIndicator(
      onRefresh: _loadCourseData,
      color: AppColors.purple,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // ── Hero Banner ──────────────────────────────────────────────────
          _buildHeroBanner(course, completedChapters, progressPct),
          const SizedBox(height: 16),

          // ── 4 Pastel Stats Cards ─────────────────────────────────────────
          _buildStatsGrid(
            progressPct: progressPct,
            completedChapters: completedChapters,
            totalChapters: totalChapters,
            remainingChapters: remainingChapters,
            nextChapter: nextChapter,
            totalScore: totalScore,
            maxScore: maxScore,
          ),
          const SizedBox(height: 16),

          // ── Next Chapter / Resume Banner ─────────────────────────────────
          if (nextChapter != null && progressPct < 100) ...[
            _buildNextChapterBanner(nextChapter, progressPct, completedChapters, totalChapters),
            const SizedBox(height: 16),
          ],

          // ── Course Completed Celebration Banner ──────────────────────────
          if (progressPct == 100) ...[
            _buildCompletedBanner(),
            const SizedBox(height: 16),
          ],

          // ── Modules Accordion List ───────────────────────────────────────
          _buildModulesSection(course),
          const SizedBox(height: 20),

          // ── Expert Card ──────────────────────────────────────────────────
          _buildExpertSection(course.instructor),
          const SizedBox(height: 16),

          // ── Highlights Checklist ─────────────────────────────────────────
          if (course.highlights.isNotEmpty) ...[
            _buildHighlightsSection(course.highlights),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(LmsCourse course, int completedChapters, int progressPct) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDE9FE), Color(0xFFF5F3FF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (course.category != null && course.category!.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD8B4FE)),
                  ),
                  child: Text(
                    course.category!,
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                ),
              if (progressPct == 100) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 12, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        'Completed!',
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            course.title,
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              height: 1.2,
            ),
          ),
          if (course.description != null && course.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              course.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Meta chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (course.timeDuration > 0)
                _buildMetaChip(Icons.access_time_rounded,
                    '${course.timeDuration} mins'),
              _buildMetaChip(Icons.layers_rounded,
                  '${course.modules.length} Modules'),
              _buildMetaChip(Icons.play_circle_outline_rounded,
                  '${course.totalChapters} Chapters'),
            ],
          ),

          const SizedBox(height: 18),

          // Big Start/Resume Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToPlayer(),
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: Text(
                completedChapters > 0 ? 'Resume Course' : 'Start Learning',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 4,
                shadowColor: const Color(0xFF7C3AED).withValues(alpha: 0.35),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid({
    required int progressPct,
    required int completedChapters,
    required int totalChapters,
    required int remainingChapters,
    required LmsChapter? nextChapter,
    required int totalScore,
    required int maxScore,
  }) {
    final accuracy = maxScore > 0 ? ((totalScore / maxScore) * 100).round() : 0;

    return Column(
      children: [
        Row(
          children: [
            // CARD 1: OVERALL PROGRESS (Rose)
            Expanded(
              child: _buildStatCard(
                bgColor: const Color(0xFFFFF4F6),
                borderColor: const Color(0xFFFECDD3),
                icon: Icons.pie_chart_rounded,
                iconColor: const Color(0xFFF43F5E),
                title: 'PROGRESS',
                titleColor: const Color(0xFFE11D48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$progressPct%',
                          style: GoogleFonts.nunito(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            value: (progressPct / 100).clamp(0.0, 1.0),
                            strokeWidth: 3.5,
                            backgroundColor: const Color(0xFFFCE7F3),
                            valueColor: const AlwaysStoppedAnimation(Color(0xFFF43F5E)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$completedChapters of $totalChapters done',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE11D48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // CARD 2: REMAINING (Blue)
            Expanded(
              child: _buildStatCard(
                bgColor: const Color(0xFFF0F7FF),
                borderColor: const Color(0xFFBFDBFE),
                icon: Icons.track_changes_rounded,
                iconColor: const Color(0xFF3B82F6),
                title: 'REMAINING',
                titleColor: const Color(0xFF2563EB),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$remainingChapters',
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      remainingChapters == 0 ? 'All finished! 🎉' : 'chapters to go',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // CARD 3: QUIZ SCORE (Emerald)
            Expanded(
              child: _buildStatCard(
                bgColor: const Color(0xFFF0FDF4),
                borderColor: const Color(0xFFBBF7D0),
                icon: Icons.stars_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'QUIZ SCORE',
                titleColor: const Color(0xFF059669),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (maxScore > 0) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$totalScore',
                            style: GoogleFonts.nunito(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '/$maxScore',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$accuracy% accuracy',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ] else ...[
                      Text(
                        '—',
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'No quizzes yet',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // CARD 4: MILESTONES (Purple)
            Expanded(
              child: _buildStatCard(
                bgColor: const Color(0xFFFAF5FF),
                borderColor: const Color(0xFFE9D5FF),
                icon: Icons.emoji_events_rounded,
                iconColor: const Color(0xFFA855F7),
                title: 'MILESTONES',
                titleColor: const Color(0xFF9333EA),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMilestonePill(
                      '🚀 First Step',
                      completedChapters >= 1,
                    ),
                    const SizedBox(height: 5),
                    _buildMilestonePill(
                      '🏆 Champion',
                      progressPct == 100,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required Color bgColor,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color titleColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildMilestonePill(String title, bool unlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked ? const Color(0xFFD8B4FE) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: unlocked ? const Color(0xFF7C3AED) : const Color(0xFF9CA3AF),
            ),
          ),
          if (unlocked) ...[
            const SizedBox(width: 4),
            const Icon(Icons.check_circle_rounded,
                size: 11, color: Color(0xFF7C3AED)),
          ],
        ],
      ),
    );
  }

  Widget _buildNextChapterBanner(
      LmsChapter nextChapter, int progressPct, int completed, int total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Icon(
                  nextChapter.type == 'VIDEO'
                      ? Icons.play_circle_filled_rounded
                      : Icons.quiz_rounded,
                  color: const Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        completed > 0 ? '📍 RESUME HERE' : '🚀 START HERE',
                        style: GoogleFonts.nunito(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFB45309),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nextChapter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completed of $total lessons complete',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (progressPct / 100).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: const Color(0xFFFEF3C7),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              ElevatedButton.icon(
                onPressed: () => _navigateToPlayer(nextChapter.id),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Play'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: const Center(
              child: Text('🎉', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Course Complete!',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF065F46),
                  ),
                ),
                Text(
                  "You've mastered every chapter. Great job!",
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesSection(LmsCourse course) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1EAFA), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.layers_rounded,
                        color: Color(0xFF7C3AED),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COURSE MODULES',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                            letterSpacing: 0.4,
                          ),
                        ),
                        Text(
                          '${course.modules.length} modules • ${course.totalChapters} chapters',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // List of Modules
          ...List.generate(course.modules.length, (modIndex) {
            final module = course.modules[modIndex];
            final isOpen = _expandedModules[module.id] ?? false;
            final chapters = module.chapters;
            final completedCount = chapters
                .where((c) => _isChapterCompleted(c.id))
                .length;
            final isModuleDone =
                completedCount == chapters.length && chapters.isNotEmpty;

            return Column(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedModules[module.id] = !isOpen;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isModuleDone
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isModuleDone
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFD8B4FE),
                            ),
                          ),
                          child: Center(
                            child: isModuleDone
                                ? const Icon(Icons.check_rounded,
                                    size: 16, color: Color(0xFF10B981))
                                : Text(
                                    '${modIndex + 1}',
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF7C3AED),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Module ${modIndex + 1}',
                                style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF9CA3AF),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Text(
                                module.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: chapters.isNotEmpty
                                            ? (completedCount / chapters.length)
                                                .clamp(0.0, 1.0)
                                            : 0.0,
                                        minHeight: 4,
                                        backgroundColor:
                                            const Color(0xFFF3F4F6),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          isModuleDone
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF7C3AED),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$completedCount/${chapters.length}',
                                    style: GoogleFonts.nunito(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isOpen
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF9CA3AF),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),

                // Expanded Chapters List
                if (isOpen)
                  Container(
                    color: const Color(0xFFFAFAFE),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    child: Column(
                      children: List.generate(chapters.length, (chIndex) {
                        final chapter = chapters[chIndex];
                        final isDone = _isChapterCompleted(chapter.id);
                        final isUnlocked = _isChapterUnlocked(chapter.id);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isDone
                                ? const Color(0xFFF0FDF4)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDone
                                  ? const Color(0xFFBBF7D0)
                                  : const Color(0xFFEDE9FE),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 2),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFF5F3FF),
                                  shape: BoxShape.circle,
                                ),
                                child: isDone
                                    ? const Icon(Icons.check_circle_rounded,
                                        size: 16, color: Color(0xFF10B981))
                                    : Icon(
                                        chapter.type == 'VIDEO'
                                            ? Icons.play_circle_outline_rounded
                                            : Icons.quiz_outlined,
                                        size: 16,
                                        color: isUnlocked
                                            ? const Color(0xFF7C3AED)
                                            : const Color(0xFF9CA3AF),
                                      ),
                              ),
                              title: Text(
                                '${chIndex + 1}. ${chapter.title}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isDone
                                      ? const Color(0xFF065F46)
                                      : isUnlocked
                                          ? AppColors.textDark
                                          : const Color(0xFF9CA3AF),
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  if (chapter.type == 'VIDEO' &&
                                      chapter.video != null &&
                                      chapter.video!.duration > 0)
                                    Text(
                                      '${(chapter.video!.duration / 60).round()}m video',
                                      style: GoogleFonts.nunito(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                    )
                                  else if (chapter.type == 'ASSESSMENT')
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3E8FF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Quiz',
                                        style: GoogleFonts.nunito(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF7C3AED),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: isUnlocked
                                  ? const Icon(Icons.arrow_forward_ios_rounded,
                                      size: 13, color: Color(0xFF7C3AED))
                                  : const Icon(Icons.lock_outline_rounded,
                                      size: 14, color: Color(0xFF9CA3AF)),
                              onTap: isUnlocked
                                  ? () => _navigateToPlayer(chapter.id)
                                  : () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              '🔒 Complete previous lessons to unlock this.'),
                                          backgroundColor: Color(0xFF1E1B4B),
                                          behavior: SnackBarBehavior.floating,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                if (modIndex < course.modules.length - 1)
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExpertSection(LmsInstructor? instructor) {
    if (instructor == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.school_rounded,
                  color: Color(0xFF3B82F6), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPERT-LED CONTENT',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF2563EB),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Crafted and reviewed by certified wellness & parenting experts at Infano.',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4B5563),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Color(0xFF10B981), size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'YOUR EXPERT',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF059669),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFDCFCE7),
                backgroundImage: instructor.avatarUrl != null
                    ? NetworkImage(instructor.avatarUrl!)
                    : null,
                child: instructor.avatarUrl == null
                    ? const Icon(Icons.person, color: Color(0xFF059669))
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instructor.name,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (instructor.designation != null)
                      Text(
                        instructor.designation!,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    if (instructor.experience != null)
                      Text(
                        instructor.experience!,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (instructor.bio != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFDCFCE7)),
            const SizedBox(height: 10),
            Text(
              instructor.bio!,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightsSection(List<String> highlights) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9D5FF), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: Color(0xFF7C3AED), size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                "WHAT YOU'LL LEARN",
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF7C3AED),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...highlights.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 16, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        h,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4B5563),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
