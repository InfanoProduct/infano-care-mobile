import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';

/// ComparisonFilterUnmaskWidget — "Feed vs. Reality Unmasker"
///
/// Updated Final Results Screen:
/// 1. Creative pastel gradient header card with animated bouncing lens badge & XP pill.
/// 2. Staggered pastel takeaway cards (Lavender, Rose, Sky Blue, Mint) with Gigi Reality Check pills.
/// 3. Elastic primary dark purple CTA button with glowing star animation.
class ComparisonFilterUnmaskWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onCompleted;

  const ComparisonFilterUnmaskWidget({
    super.key,
    required this.content,
    required this.onCompleted,
  });

  @override
  State<ComparisonFilterUnmaskWidget> createState() => _ComparisonFilterUnmaskWidgetState();
}

class _ComparisonFilterUnmaskWidgetState extends State<ComparisonFilterUnmaskWidget> {
  late final ConfettiController _confettiCtrl;

  late final List<_UnmaskPostData> _posts;
  final Set<int> _unmaskedIndices = {};
  int _currentIndex = 0;
  double _sliderPos = 0.15; // 0.0 (Filter) to 1.0 (Reality)
  bool _showResults = false;
  bool _isCompleting = false;

  List<Map<String, dynamic>> get _rawPosts =>
      List<Map<String, dynamic>>.from(widget.content['posts'] as List? ?? []);

  _UnmaskPostData get _currentPost => _posts[_currentIndex];
  bool get _isCurrentUnmasked => _unmaskedIndices.contains(_currentIndex) || _sliderPos > 0.45;
  bool get _allUnmasked => _unmaskedIndices.length >= _posts.length;

  // Curated pastel themes for result takeaway cards
  static const List<Map<String, Color>> _cardThemes = [
    {'bg': Color(0xFFF5F3FF), 'border': Color(0xFFDDD6FE), 'accent': Color(0xFF7C3AED)}, // Pastel Lavender
    {'bg': Color(0xFFFDF2F8), 'border': Color(0xFFFBCFE8), 'accent': Color(0xFFDB2777)}, // Pastel Rose
    {'bg': Color(0xFFF0F9FF), 'border': Color(0xFFBAE6FD), 'accent': Color(0xFF0284C7)}, // Pastel Sky
    {'bg': Color(0xFFF0FDFA), 'border': Color(0xFF99F6E4), 'accent': Color(0xFF0D9488)}, // Pastel Mint
  ];

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 4));
    _posts = _rawPosts.map(_UnmaskPostData.fromMap).toList();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _markCurrentUnmasked() {
    if (!_unmaskedIndices.contains(_currentIndex)) {
      AppSoundService.instance.playCorrect();
      HapticFeedback.mediumImpact();
      setState(() {
        _unmaskedIndices.add(_currentIndex);
      });

      if (_allUnmasked) {
        Future.delayed(const Duration(milliseconds: 500), () {
          AppSoundService.instance.playFanfare();
          _confettiCtrl.play();
          setState(() => _showResults = true);
        });
      }
    }
  }

  void _onSliderChanged(double val) {
    setState(() {
      _sliderPos = val;
      if (val >= 0.45) {
        _markCurrentUnmasked();
      }
    });
  }

  void _unmaskFully() {
    _onSliderChanged(1.0);
  }

  void _nextPost() {
    if (_currentIndex + 1 < _posts.length) {
      AppSoundService.instance.playPop();
      setState(() {
        _currentIndex++;
        _sliderPos = _unmaskedIndices.contains(_currentIndex) ? 1.0 : 0.15;
      });
    } else if (_allUnmasked) {
      AppSoundService.instance.playFanfare();
      _confettiCtrl.play();
      setState(() => _showResults = true);
    }
  }

  void _prevPost() {
    if (_currentIndex > 0) {
      AppSoundService.instance.playPop();
      setState(() {
        _currentIndex--;
        _sliderPos = _unmaskedIndices.contains(_currentIndex) ? 1.0 : 0.15;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showResults) return _buildResultsScreen();

    return Stack(
      children: [
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 14),
                _buildProgressBar(),
                const SizedBox(height: 16),
                _buildVisualPostCard(),
                const SizedBox(height: 16),
                _buildLensSlider(),
                const SizedBox(height: 16),
                _buildCTAControls(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiCtrl,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 35,
            gravity: 0.25,
            colors: const [
              Color(0xFF7C3AED), Color(0xFFEC4899),
              Color(0xFF10B981), Color(0xFF60A5FA), Color(0xFFA855F7),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5F3FF), Color(0xFFFDF2F8)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Text('🔍', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.content['title'] as String? ?? 'Feed vs. Reality Unmasker',
                  style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.content['instruction'] as String? ?? 'Drag the lens to unmask the truth & unlock Gigi\'s reality check!',
                  style: GoogleFonts.nunito(fontSize: 11.5, color: AppColors.textMedium, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.08);
  }

  Widget _buildProgressBar() {
    final pct = _posts.isEmpty ? 0.0 : (_unmaskedIndices.length / _posts.length).clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.purple.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${_unmaskedIndices.length} of ${_posts.length} unmasked',
          style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.purple),
        ),
      ],
    );
  }

  Widget _buildVisualPostCard() {
    final post = _currentPost;
    final isUnmasked = _isCurrentUnmasked;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isUnmasked ? AppColors.purple : AppColors.purple.withValues(alpha: 0.25),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFFEDE9FE), Color(0xFFFCE7F3)]),
                  ),
                  child: Center(child: Text(post.userEmoji, style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.username,
                        style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textDark),
                      ),
                      Text(
                        'Sponsored Feed Post • Filter Active ✨',
                        style: GoogleFonts.nunito(fontSize: 10.5, color: AppColors.textMedium, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUnmasked ? const Color(0xFFF3E8FF) : AppColors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isUnmasked ? 'UNMASKED 🔍' : 'FILTERED 📱',
                    style: GoogleFonts.nunito(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.purple,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 270,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Stack(
                      children: [
                        _buildImageWithFallback(
                          post.filteredImageUrl,
                          fallbackGradient: const LinearGradient(
                            colors: [Color(0xFFFCE7F3), Color(0xFFF5F3FF)],
                          ),
                        ),
                        Container(color: Colors.pink.withValues(alpha: 0.18)),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                post.filteredText,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  FractionallySizedBox(
                    widthFactor: _sliderPos,
                    child: Stack(
                      children: [
                        _buildImageWithFallback(
                          post.realityImageUrl,
                          fallbackGradient: const LinearGradient(
                            colors: [Color(0xFFE0F2FE), Color(0xFFF0FDF4)],
                          ),
                        ),
                        Container(color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.textDark.withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                post.realityText,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: (MediaQuery.of(context).size.width - 68) * _sliderPos,
                    child: Container(
                      width: 3,
                      color: Colors.white,
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: const Icon(Icons.code_rounded, size: 14, color: AppColors.purple),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          if (_sliderPos > 0.35)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF3E8FF), Color(0xFFFDF2F8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.purple,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: const Center(
                        child: Text('✨', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Gigi\'s Reality Check',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.purple,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.purple.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '💡 INSIGHT',
                                  style: GoogleFonts.nunito(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.purple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            post.gigiInsight,
                            style: GoogleFonts.nunito(
                              fontSize: 12.5,
                              color: AppColors.textDark,
                              height: 1.4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().scale(begin: const Offset(0.9, 0.9), duration: 300.ms, curve: Curves.easeOutBack).fadeIn(),
            ),
        ],
      ),
    );
  }

  Widget _buildImageWithFallback(String? url, {required Gradient fallbackGradient}) {
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('assets/')) {
        return Image.asset(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _fallbackBox(fallbackGradient),
        );
      }
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _fallbackBox(fallbackGradient),
      );
    }
    return _fallbackBox(fallbackGradient);
  }

  Widget _fallbackBox(Gradient gradient) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.black26, size: 40),
      ),
    );
  }

  Widget _buildLensSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('✨ Filter View', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.pink)),
            Text('🔍 Drag Lens to Unmask ➡️', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.purple)),
          ],
        ),
        Slider(
          value: _sliderPos,
          min: 0.0,
          max: 1.0,
          activeColor: AppColors.purple,
          inactiveColor: AppColors.purple.withValues(alpha: 0.2),
          onChanged: _onSliderChanged,
        ),
      ],
    );
  }

  Widget _buildCTAControls() {
    return Row(
      children: [
        if (_currentIndex > 0) ...[
          IconButton.filledTonal(
            onPressed: _prevPost,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.purple.withValues(alpha: 0.1),
              foregroundColor: AppColors.purple,
            ),
          ),
          const SizedBox(width: 10),
        ],

        Expanded(
          child: GestureDetector(
            onTap: _isCurrentUnmasked ? _nextPost : _unmaskFully,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.purple,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isCurrentUnmasked ? '🌟' : '🔍', style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    _isCurrentUnmasked
                        ? (_currentIndex + 1 < _posts.length ? 'Next Post ➔' : 'Complete Activity 🏆')
                        : 'Tap to Unmask Reality 🔍',
                    style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Highly Creative Pastel Results Screen
  Widget _buildResultsScreen() {
    final msg = widget.content['completionMessage'] as String? ??
        'You unmasked every post! Never compare your real 24/7 life to somebody else\'s 5-second edited highlight reel.';

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            children: [
              // Top Creative Pastel Trophy & Lens Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF5F3FF), Color(0xFFFDF2F8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('🔍', style: TextStyle(fontSize: 56))
                        .animate()
                        .scale(begin: const Offset(0, 0), duration: 600.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 12),
                    Text(
                      'Media Literacy Unlocked!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(fontSize: 23, fontWeight: FontWeight.w900, color: AppColors.textDark),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 8),
                    Text(
                      msg,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(fontSize: 13.5, color: AppColors.textMedium, height: 1.45),
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            '+10 Coins earned!',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF9A3412),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 700.ms).scaleXY(begin: 0.8),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),

              const SizedBox(height: 22),

              // Title Section for Unmasked Takeaways
              Row(
                children: [
                  const Text('📋', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'Unmasked Reality Takeaways',
                    style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 12),

              // Staggered Pastel Takeaway Cards
              ..._posts.asMap().entries.map((e) {
                final idx = e.key;
                final post = e.value;
                final theme = _cardThemes[idx % _cardThemes.length];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme['bg'],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme['border']!, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: theme['accent']!.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: theme['border']!),
                            ),
                            child: Center(child: Text(post.userEmoji, style: const TextStyle(fontSize: 16))),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            post.username,
                            style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textDark),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme['accent']!.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_rounded, size: 14, color: theme['accent']),
                                const SizedBox(width: 4),
                                Text(
                                  'Unmasked',
                                  style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: theme['accent']),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          post.gigiInsight,
                          style: GoogleFonts.nunito(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (300 + idx * 100).ms, duration: 400.ms).slideX(begin: 0.06);
              }),

              const SizedBox(height: 12),

              // Final Elastic Primary CTA Button
              GestureDetector(
                onTap: () {
                  if (!_isCompleting) {
                    setState(() => _isCompleting = true);
                    widget.onCompleted();
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEDE9FE), Color(0xFFFCE7F3)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC4B5FD), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFA78BFA).withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Collect 🪙 Coins & Continue!',
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF4C1D95),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms).scaleXY(begin: 0.9, curve: Curves.elasticOut),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiCtrl,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 45,
            gravity: 0.2,
            colors: const [
              Color(0xFF7C3AED), Color(0xFFEC4899),
              Color(0xFF10B981), Color(0xFF60A5FA), Color(0xFFA855F7),
            ],
          ),
        ),
      ],
    );
  }
}

class _UnmaskPostData {
  final String id;
  final String username;
  final String userEmoji;
  final String filteredText;
  final String realityText;
  final String gigiInsight;
  final String? filteredImageUrl;
  final String? realityImageUrl;

  _UnmaskPostData({
    required this.id,
    required this.username,
    required this.userEmoji,
    required this.filteredText,
    required this.realityText,
    required this.gigiInsight,
    this.filteredImageUrl,
    this.realityImageUrl,
  });

  factory _UnmaskPostData.fromMap(Map<String, dynamic> m) => _UnmaskPostData(
        id: m['id'] as String? ?? '',
        username: m['username'] as String? ?? 'Post',
        userEmoji: m['userEmoji'] as String? ?? '📸',
        filteredText: m['filteredText'] as String? ?? '',
        realityText: m['realityText'] as String? ?? '',
        gigiInsight: m['gigiInsight'] as String? ?? '',
        filteredImageUrl: m['filteredImageUrl'] as String?,
        realityImageUrl: m['realityImageUrl'] as String?,
      );
}
