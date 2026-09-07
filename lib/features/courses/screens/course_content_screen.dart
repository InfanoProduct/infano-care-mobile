import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/courses/data/models/course_models.dart';
import 'package:infano_care_mobile/features/courses/data/repositories/courses_repository.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class CourseContentScreen extends StatefulWidget {
  final String courseId;
  final String? initialChapterId;

  const CourseContentScreen({
    super.key,
    required this.courseId,
    this.initialChapterId,
  });

  @override
  State<CourseContentScreen> createState() => _CourseContentScreenState();
}

class _CourseContentScreenState extends State<CourseContentScreen>
    with SingleTickerProviderStateMixin {
  late final CoursesRepository _repo;
  late final ConfettiController _confettiController;
  late final TabController _tabController;

  LmsCourse? _course;
  LmsChapter? _activeChapter;
  List<LmsProgress> _progress = [];
  bool _isLoading = true;
  String? _error;

  // Video Controllers
  YoutubePlayerController? _ytController;
  VideoPlayerController? _videoPlayerController;


  // Likes & Comments
  ChapterLikesInfo _likesInfo = const ChapterLikesInfo(liked: false, count: 0);
  List<ChapterComment> _comments = [];
  bool _isPostingComment = false;
  final TextEditingController _commentController = TextEditingController();

  // Quiz State
  int _currentQuestionIndex = 0;
  int _selectedOptionIndex = -1;
  bool _isAnswerSubmitted = false;
  int _quizScore = 0;
  bool _isQuizCompleted = false;
  List<int> _userAnswers = [];
  bool _isReviewMode = false;

  @override
  void initState() {
    super.initState();
    _repo = CoursesRepository(ApiService.instance.dio);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _tabController = TabController(length: 4, vsync: this);
    _loadCourseAndChapter();
  }

  @override
  void dispose() {
    _disposeVideoControllers();
    _confettiController.dispose();
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _disposeVideoControllers() {
    _ytController?.dispose();
    _ytController = null;
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
  }

  Future<void> _loadCourseAndChapter() async {
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

      LmsChapter? targetChapter;
      if (widget.initialChapterId != null) {
        targetChapter = course.flatChapters.firstWhere(
          (c) => c.id == widget.initialChapterId,
          orElse: () => course.flatChapters.first,
        );
      } else {
        targetChapter = course.flatChapters.firstWhere(
          (c) => !progress.any((p) => p.chapterId == c.id && p.isCompleted),
          orElse: () => course.flatChapters.first,
        );
      }

      if (mounted) {
        setState(() {
          _course = course;
          _progress = progress;
          _isLoading = false;
        });
        _selectChapter(targetChapter);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load chapter content.';
          _isLoading = false;
        });
      }
    }
  }

  void _selectChapter(LmsChapter chapter) {
    _disposeVideoControllers();

    setState(() {
      _activeChapter = chapter;
      _currentQuestionIndex = 0;
      _selectedOptionIndex = -1;
      _isAnswerSubmitted = false;
      _userAnswers = [];
      _isReviewMode = false;
    });

    // Check if chapter was already completed
    final prog = _progress.firstWhere(
      (p) => p.chapterId == chapter.id && p.isCompleted,
      orElse: () => const LmsProgress(chapterId: '', isCompleted: false),
    );

    if (prog.isCompleted) {
      setState(() {
        _isQuizCompleted = true;
        _quizScore = prog.score ?? 0;
        _userAnswers = prog.answers ?? [];
      });
    } else {
      setState(() {
        _isQuizCompleted = false;
        _quizScore = 0;
      });
    }

    // Initialize Video if Video Chapter
    if (chapter.type == 'VIDEO' && chapter.video != null) {
      _initVideoPlayer(chapter.video!.videoUrl);
    }

    // Fetch likes and comments
    _loadChapterLikes(chapter.id);
    _loadChapterComments(chapter.id);
  }

  void _initVideoPlayer(String videoUrl) {
    if (videoUrl.isEmpty) return;

    final ytId = YoutubePlayer.convertUrlToId(videoUrl);
    if (ytId != null && ytId.isNotEmpty) {
      _ytController = YoutubePlayerController(
        initialVideoId: ytId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
        ),
      );
      setState(() {});
    } else {
      // Regular MP4 / Direct stream URL
      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(videoUrl))
            ..initialize().then((_) {
              if (mounted) {
                setState(() {});
              }
            });
    }
  }

  Future<void> _loadChapterLikes(String chapterId) async {
    try {
      final likes = await _repo.getChapterLikes(chapterId);
      if (mounted) {
        setState(() {
          _likesInfo = likes;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleChapterLike() async {
    if (_activeChapter == null) return;
    try {
      final likes = await _repo.toggleChapterLike(_activeChapter!.id);
      if (mounted) {
        setState(() {
          _likesInfo = likes;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadChapterComments(String chapterId) async {
    try {
      final comments = await _repo.getChapterComments(chapterId);
      if (mounted) {
        setState(() {
          _comments = comments;
        });
      }
    } catch (_) {}
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _activeChapter == null) return;

    setState(() => _isPostingComment = true);
    try {
      final comment =
          await _repo.postChapterComment(_activeChapter!.id, text);
      _commentController.clear();
      if (mounted) {
        setState(() {
          _comments.insert(0, comment);
          _isPostingComment = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment posted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPostingComment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post comment')),
        );
      }
    }
  }

  Future<void> _markChapterComplete({int? score, List<int>? answers}) async {
    if (_activeChapter == null || _course == null) return;

    try {
      await _repo.markChapterComplete(
        _course!.id,
        _activeChapter!.id,
        score: score,
        answers: answers,
      );

      // Update local progress
      final updated = List<LmsProgress>.from(_progress);
      final idx =
          updated.indexWhere((p) => p.chapterId == _activeChapter!.id);
      if (idx >= 0) {
        updated[idx] = LmsProgress(
          chapterId: _activeChapter!.id,
          isCompleted: true,
          score: score,
          answers: answers,
        );
      } else {
        updated.add(LmsProgress(
          chapterId: _activeChapter!.id,
          isCompleted: true,
          score: score,
          answers: answers,
        ));
      }

      setState(() {
        _progress = updated;
      });

      _confettiController.play();

      final next = _getNextChapter();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              score != null
                  ? '🎉 Quiz completed! Score: $score'
                  : '✓ Lesson completed! Keep it up!',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }

      if (next != null && next.id != _activeChapter!.id) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) {
            _selectChapter(next);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update progress')),
        );
      }
    }
  }

  LmsChapter? _getNextChapter() {
    if (_course == null || _activeChapter == null) return null;
    final flat = _course!.flatChapters;
    final idx = flat.indexWhere((c) => c.id == _activeChapter!.id);
    if (idx >= 0 && idx < flat.length - 1) {
      return flat[idx + 1];
    }
    return null;
  }

  LmsChapter? _getPreviousChapter() {
    if (_course == null || _activeChapter == null) return null;
    final flat = _course!.flatChapters;
    final idx = flat.indexWhere((c) => c.id == _activeChapter!.id);
    if (idx > 0) {
      return flat[idx - 1];
    }
    return null;
  }

  bool _isChapterCompleted(String chapterId) {
    return _progress.any((p) => p.chapterId == chapterId && p.isCompleted);
  }

  @override
  Widget build(BuildContext context) {
    final flatChapters = _course?.flatChapters ?? [];
    final completedCount =
        _progress.where((p) => p.isCompleted).length;
    final progressPct = flatChapters.isNotEmpty
        ? ((completedCount / flatChapters.length) * 100).round()
        : 0;

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
              context.pushReplacement(
                  '/courses/${widget.courseId}/overview');
            }
          },
        ),
        title: Column(
          children: [
            Text(
              _course?.title ?? 'Course',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_activeChapter != null)
              Text(
                _activeChapter!.title,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7C3AED),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Progress Chip
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded,
                    size: 14, color: Color(0xFF7C3AED)),
                const SizedBox(width: 4),
                Text(
                  '$progressPct%',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.format_list_bulleted_rounded,
                color: Color(0xFF7C3AED)),
            onPressed: _showChapterPlaylistSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFF7C3AED),
                Color(0xFFEC4899),
                Color(0xFF10B981),
                Color(0xFFF59E0B),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.purple),
      );
    }

    if (_error != null || _activeChapter == null) {
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
                _error ?? 'Chapter not found',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadCourseAndChapter,
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

    final chapter = _activeChapter!;

    return Column(
      children: [
        // ── Top Video / Quiz Area ──────────────────────────────────────────
        Container(
          width: double.infinity,
          color: Colors.black,
          child: chapter.type == 'VIDEO'
              ? _buildVideoPlayerArea(chapter)
              : _buildQuizArea(chapter),
        ),

        // ── Chapter Action Row ─────────────────────────────────────────────
        _buildChapterActionBar(chapter),

        // ── Tabs Navigation ────────────────────────────────────────────────
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorColor: const Color(0xFF7C3AED),
            indicatorWeight: 3,
            labelColor: const Color(0xFF7C3AED),
            unselectedLabelColor: const Color(0xFF6B7280),
            labelStyle: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            unselectedLabelStyle: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Tips'),
              Tab(text: 'FAQ'),
              Tab(text: 'Comments'),
            ],
          ),
        ),

        // ── Tab Views ──────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(chapter),
              _buildTipsTab(chapter),
              _buildFaqTab(chapter),
              _buildCommentsTab(chapter),
            ],
          ),
        ),
      ],
    );
  }

  // ── Video Player Area ──────────────────────────────────────────────────────
  Widget _buildVideoPlayerArea(LmsChapter chapter) {
    if (_ytController != null) {
      return YoutubePlayer(
        controller: _ytController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFF7C3AED),
        progressColors: const ProgressBarColors(
          playedColor: Color(0xFF7C3AED),
          handleColor: Color(0xFFEC4899),
        ),
      );
    }

    if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(_videoPlayerController!),
            VideoProgressIndicator(
              _videoPlayerController!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Color(0xFF7C3AED),
                bufferedColor: Colors.white54,
                backgroundColor: Colors.black26,
              ),
            ),
            Center(
              child: IconButton(
                iconSize: 48,
                icon: Icon(
                  _videoPlayerController!.value.isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_filled_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                onPressed: () {
                  setState(() {
                    _videoPlayerController!.value.isPlaying
                        ? _videoPlayerController!.pause()
                        : _videoPlayerController!.play();
                  });
                },
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 220,
      color: const Color(0xFF1E1B4B),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library_rounded,
                size: 48, color: Color(0xFFD8B4FE)),
            const SizedBox(height: 10),
            Text(
              'Interactive Video Lesson',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quiz Area ──────────────────────────────────────────────────────────────
  Widget _buildQuizArea(LmsChapter chapter) {
    final questions = chapter.assessment?.questions ?? [];
    if (questions.isEmpty) {
      return Container(
        height: 220,
        color: const Color(0xFFFAF7FF),
        child: Center(
          child: Text(
            'No quiz questions available for this chapter.',
            style: GoogleFonts.nunito(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (_isQuizCompleted && !_isReviewMode) {
      return _buildQuizCompletionView(questions);
    }

    final currentQuestion = questions[_currentQuestionIndex];
    final isDone = _isChapterCompleted(chapter.id);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFDFDFF), Color(0xFFF6F4FF), Color(0xFFECE9FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Question counter & dots
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QUESTION',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF9CA3AF),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${_currentQuestionIndex + 1} / ${questions.length}',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: List.generate(
                    questions.length,
                    (idx) => Container(
                      margin: const EdgeInsets.only(left: 4),
                      width: idx == _currentQuestionIndex ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: idx == _currentQuestionIndex
                            ? const Color(0xFF7C3AED)
                            : (idx < _currentQuestionIndex
                                ? const Color(0xFF10B981)
                                : const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question Text
            Text(
              currentQuestion.question,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),

            // Options List
            ...List.generate(currentQuestion.options.length, (optIdx) {
              final optText = currentQuestion.options[optIdx];
              final isSelected = _selectedOptionIndex == optIdx;
              final isCorrect =
                  optIdx == currentQuestion.correctAnswerIndex;

              Color optBg = Colors.white;
              Color optBorder = const Color(0xFFE9D5FF);
              Color textColor = AppColors.textDark;

              if (_isAnswerSubmitted) {
                if (isCorrect) {
                  optBg = const Color(0xFFECFDF5);
                  optBorder = const Color(0xFF10B981);
                  textColor = const Color(0xFF065F46);
                } else if (isSelected) {
                  optBg = const Color(0xFFFFF1F2);
                  optBorder = const Color(0xFFF43F5E);
                  textColor = const Color(0xFF9F1239);
                }
              } else if (isSelected) {
                optBg = const Color(0xFFF3E8FF);
                optBorder = const Color(0xFF7C3AED);
                textColor = const Color(0xFF7C3AED);
              }

              return GestureDetector(
                onTap: _isAnswerSubmitted
                    ? null
                    : () {
                        setState(() {
                          _selectedOptionIndex = optIdx;
                        });
                      },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: optBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: optBorder, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _isAnswerSubmitted && isCorrect
                              ? const Color(0xFF10B981)
                              : (_isAnswerSubmitted && isSelected && !isCorrect
                                  ? const Color(0xFFF43F5E)
                                  : (isSelected
                                      ? const Color(0xFF7C3AED)
                                      : const Color(0xFFF3F4F6))),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + optIdx),
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: isSelected ||
                                      (_isAnswerSubmitted && isCorrect)
                                  ? Colors.white
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          optText,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Explanation box if submitted
            if (_isAnswerSubmitted &&
                currentQuestion.explanation != null &&
                currentQuestion.explanation!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentQuestion.explanation!,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF92400E),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Submit / Next Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_isAnswerSubmitted)
                  ElevatedButton(
                    onPressed: _selectedOptionIndex == -1
                        ? null
                        : () {
                            final isCorrect = _selectedOptionIndex ==
                                currentQuestion.correctAnswerIndex;
                            setState(() {
                              _isAnswerSubmitted = true;
                              if (isCorrect) _quizScore++;
                              _userAnswers.add(_selectedOptionIndex);
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: Text(
                      'Submit Answer',
                      style: GoogleFonts.nunito(
                          fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      final next = _currentQuestionIndex + 1;
                      if (next < questions.length) {
                        setState(() {
                          _currentQuestionIndex = next;
                          _selectedOptionIndex = _isReviewMode
                              ? (_userAnswers.length > next
                                  ? _userAnswers[next]
                                  : -1)
                              : -1;
                          _isAnswerSubmitted = _isReviewMode;
                        });
                      } else {
                        // Finished Quiz
                        if (!_isReviewMode && !isDone) {
                          _markChapterComplete(
                            score: _quizScore,
                            answers: _userAnswers,
                          );
                        }
                        setState(() {
                          _isQuizCompleted = true;
                          _isReviewMode = false;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1B4B),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: Text(
                      _currentQuestionIndex + 1 < questions.length
                          ? 'Next Question →'
                          : (_isReviewMode ? 'Finish Review' : 'Finish Quiz 🎉'),
                      style: GoogleFonts.nunito(
                          fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCompletionView(List<AssessmentQuestion> questions) {
    final perfect = _quizScore == questions.length;
    final passed = _quizScore >= (questions.length / 2);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFDFDFF), Color(0xFFF6F4FF), Color(0xFFECE9FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFDE68A), width: 2),
            ),
            child: const Text('🏆', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 10),
          Text(
            'Quiz Completed! 🎉',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your Score',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$_quizScore / ${questions.length}',
            style: GoogleFonts.nunito(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: perfect
                  ? const Color(0xFFFEF3C7)
                  : (passed ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              perfect
                  ? '⭐ Perfect Score!'
                  : (passed ? '✓ Well Done!' : '📚 Keep Practicing'),
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: perfect
                    ? const Color(0xFFB45309)
                    : (passed
                        ? const Color(0xFF065F46)
                        : const Color(0xFF991B1B)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  final next = _getNextChapter();
                  if (next != null) {
                    _selectChapter(next);
                  }
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Next Chapter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  textStyle: GoogleFonts.nunito(
                      fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isQuizCompleted = false;
                    _isReviewMode = true;
                    _currentQuestionIndex = 0;
                    _selectedOptionIndex =
                        _userAnswers.isNotEmpty ? _userAnswers[0] : -1;
                    _isAnswerSubmitted = true;
                  });
                },
                icon: const Icon(Icons.rate_review_outlined, size: 16),
                label: const Text('Review Answers'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textDark,
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: GoogleFonts.nunito(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isQuizCompleted = false;
                    _currentQuestionIndex = 0;
                    _selectedOptionIndex = -1;
                    _isAnswerSubmitted = false;
                    _quizScore = 0;
                    _userAnswers = [];
                    _isReviewMode = false;
                  });
                },
                child: Text(
                  'Retake Quiz ↺',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Chapter Action Bar ─────────────────────────────────────────────────────
  Widget _buildChapterActionBar(LmsChapter chapter) {
    final isDone = _isChapterCompleted(chapter.id);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          // Like button
          if (chapter.type == 'VIDEO') ...[
            InkWell(
              onTap: _toggleChapterLike,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _likesInfo.liked
                      ? const Color(0xFFF3E8FF)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _likesInfo.liked
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _likesInfo.liked
                          ? Icons.thumb_up_alt_rounded
                          : Icons.thumb_up_off_alt_rounded,
                      size: 14,
                      color: _likesInfo.liked
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${_likesInfo.count}',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _likesInfo.liked
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Share Button
            InkWell(
              onTap: () {
                Share.share(
                  'Check out "${chapter.title}" on Infano!',
                  subject: chapter.title,
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.share_rounded,
                        size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      'Share',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const Spacer(),

          // Mark Complete CTA
          if (chapter.type == 'VIDEO')
            ElevatedButton.icon(
              onPressed: isDone ? null : () => _markChapterComplete(),
              icon: Icon(
                isDone ? Icons.check_circle_rounded : Icons.check_rounded,
                size: 16,
              ),
              label: Text(isDone ? 'Completed' : 'Mark Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDone
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFF10B981),
                foregroundColor:
                    isDone ? const Color(0xFF065F46) : Colors.white,
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
                elevation: isDone ? 0 : 2,
              ),
            ),
        ],
      ),
    );
  }

  // ── Tab 1: Overview ────────────────────────────────────────────────────────
  Widget _buildOverviewTab(LmsChapter chapter) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          chapter.title,
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          chapter.description ??
              'In this lesson, explore expert concepts, structured insights, and step-by-step guidance designed to support your learning journey.',
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4B5563),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        // Expert Instructor Card
        if (_course?.instructor != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F5FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE9D5FF)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFE9D5FF),
                  backgroundImage: _course!.instructor!.avatarUrl != null
                      ? NetworkImage(_course!.instructor!.avatarUrl!)
                      : null,
                  child: _course!.instructor!.avatarUrl == null
                      ? const Icon(Icons.person, color: Color(0xFF7C3AED))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _course!.instructor!.name,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (_course!.instructor!.designation != null)
                        Text(
                          _course!.instructor!.designation!,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Chapter Navigation Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: _getPreviousChapter() != null
                  ? () => _selectChapter(_getPreviousChapter()!)
                  : null,
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Previous'),
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _getNextChapter() != null
                  ? () => _selectChapter(_getNextChapter()!)
                  : null,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Tab 2: Tips & Good to Know ─────────────────────────────────────────────
  Widget _buildTipsTab(LmsChapter chapter) {
    final points = chapter.goodToKnowPoints;
    if (points.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💡', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 10),
              Text(
                'No special notes for this lesson.',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...points.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE9D5FF)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF374151),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ── Tab 3: FAQ ─────────────────────────────────────────────────────────────
  Widget _buildFaqTab(LmsChapter chapter) {
    final faqs = chapter.faqs;
    if (faqs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('❓', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 10),
              Text(
                'No FAQs available for this lesson.',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...faqs.map((faq) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1EAFA)),
              ),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 14),
                shape: const RoundedRectangleBorder(
                    side: BorderSide(color: Colors.transparent)),
                title: Text(
                  faq.question,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                children: [
                  Text(
                    faq.answer,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4B5563),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ── Tab 4: Comments ────────────────────────────────────────────────────────
  Widget _buildCommentsTab(LmsChapter chapter) {
    return Column(
      children: [
        Expanded(
          child: _comments.isEmpty
              ? Center(
                  child: Text(
                    'No comments yet. Start the conversation!',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1EAFA)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFFF3E8FF),
                            child: Text(
                              comment.authorInitials,
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      comment.authorName,
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        try {
                                          final res = await _repo
                                              .toggleCommentLike(comment.id);
                                          setState(() {
                                            _comments[index] = comment.copyWith(
                                              likes: res['likes'] as int?,
                                              liked: res['liked'] as bool?,
                                            );
                                          });
                                        } catch (_) {}
                                      },
                                      child: Row(
                                        children: [
                                          Icon(
                                            comment.liked
                                                ? Icons.thumb_up_alt_rounded
                                                : Icons.thumb_up_off_alt_rounded,
                                            size: 13,
                                            color: comment.liked
                                                ? const Color(0xFF7C3AED)
                                                : const Color(0xFF9CA3AF),
                                          ),
                                          if (comment.likes > 0) ...[
                                            const SizedBox(width: 4),
                                            Text(
                                              '${comment.likes}',
                                              style: GoogleFonts.nunito(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment.text,
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF374151),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Comment Input Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts or questions...',
                    hintStyle: GoogleFonts.nunito(
                      fontSize: 13,
                      color: const Color(0xFF9CA3AF),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _isPostingComment ? null : _postComment,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                ),
                icon: _isPostingComment
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Chapter Playlist Bottom Sheet ──────────────────────────────────────────
  void _showChapterPlaylistSheet() {
    if (_course == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Course Playlist',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _course!.modules.length,
                  itemBuilder: (context, modIdx) {
                    final module = _course!.modules[modIdx];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Module ${modIdx + 1}: ${module.title}',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF7C3AED),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        ...module.chapters.map((ch) {
                          final isCurrent = ch.id == _activeChapter?.id;
                          final isDone = _isChapterCompleted(ch.id);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? const Color(0xFFF3E8FF)
                                  : (isDone
                                      ? const Color(0xFFF0FDF4)
                                      : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCurrent
                                    ? const Color(0xFF7C3AED)
                                    : (isDone
                                        ? const Color(0xFF86EFAC)
                                        : const Color(0xFFF3F4F6)),
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: Icon(
                                isDone
                                    ? Icons.check_circle_rounded
                                    : (ch.type == 'VIDEO'
                                        ? Icons.play_circle_outline_rounded
                                        : Icons.quiz_outlined),
                                size: 18,
                                color: isDone
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF7C3AED),
                              ),
                              title: Text(
                                ch.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isCurrent
                                      ? const Color(0xFF7C3AED)
                                      : AppColors.textDark,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _selectChapter(ch);
                              },
                            ),
                          );
                        }),
                        const SizedBox(height: 10),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
