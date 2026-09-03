import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';

class SpotTheChangeWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onCompleted;

  const SpotTheChangeWidget({
    super.key,
    required this.content,
    required this.onCompleted,
  });

  @override
  State<SpotTheChangeWidget> createState() => _SpotTheChangeWidgetState();
}

class _SpotTheChangeWidgetState extends State<SpotTheChangeWidget> {
  final Set<String> _found = {};
  bool _allFound = false;

  final List<Map<String, dynamic>> _fallbackDetectiveClues = [
    {
      'id': 'd1',
      'emoji': '📏',
      'label': 'Growth & Posture',
      'hint': 'She grew taller & stands with a confident, proud posture!',
      'learning': 'Growth spurts change your height and posture as muscles & bones develop.',
    },
    {
      'id': 'd2',
      'emoji': '💇',
      'label': 'Hairstyle & Accessories',
      'hint': 'Her hair is styled up in a bun with a flower clip!',
      'learning': 'Personal expression and style evolve as you discover what feels most you.',
    },
    {
      'id': 'd3',
      'emoji': '🧴',
      'label': 'Skincare Habit',
      'hint': 'A gentle face wash is peeking out of her purple backpack!',
      'learning': 'Hormone changes bring skin stories — simple gentle hygiene habits help skin glow.',
    },
    {
      'id': 'd4',
      'emoji': '✨',
      'label': 'Inner Confidence',
      'hint': 'Notice her warm, calm, self-assured smile!',
      'learning': 'Confidence is invisible growth — feeling comfortable in your changing body.',
    },
    {
      'id': 'd5',
      'emoji': '🎒',
      'label': 'Growing Up Gear',
      'hint': 'From toy plane to personal care & school gear!',
      'learning': 'Your interests and responsibility grow hand-in-hand with your body.',
    },
  ];

  List<Map<String, dynamic>> get _clues {
    final raw = widget.content['differences'] as List?;
    if (raw != null && raw.isNotEmpty) {
      return raw.map((item) {
        if (item is Map<String, dynamic>) return item;
        if (item is Map) return Map<String, dynamic>.from(item);
        return <String, dynamic>{};
      }).where((m) => m.isNotEmpty).toList();
    }
    return _fallbackDetectiveClues;
  }

  bool get _isShelfAudit {
    final character = (widget.content['character'] as String? ?? '').toLowerCase();
    final instruction = (widget.content['instruction'] as String? ?? '').toLowerCase();
    return character.contains('shelf') || instruction.contains('shelf') || instruction.contains('audit');
  }

  final List<int> _itemPrices = [450, 400, 500, 450, 400];

  int get _currentShelfPrice {
    final totalItems = _clues.length;
    if (totalItems == 0) return 300;
    if (_found.length == totalItems) return 300;
    const startPrice = 2500;
    const endPrice = 300;
    final dropPerItem = (startPrice - endPrice) / totalItems;
    return (startPrice - (_found.length * dropPerItem)).round();
  }

  void _onClueTapped(String id) {
    if (_found.contains(id)) return;

    AppSoundService.instance.playCorrect();

    setState(() {
      _found.add(id);
      if (_found.length >= _clues.length) {
        _allFound = true;
        AppSoundService.instance.playFanfare();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_allFound) return _buildCompletion();

    if (_isShelfAudit) {
      return _buildCreativeShelfAuditUI();
    }

    return _buildGenericSpotTheChangeUI();
  }

  // ── INNOVATIVE CREATIVE 3D SHELF AUDIT UI ──────────────────────────────────
  Widget _buildCreativeShelfAuditUI() {
    final clues = _clues;
    final instruction = widget.content['instruction'] as String? ??
        "Amara spent ₹2500 on 7 products! Tap each product card to rotate it 3D, audit with Dr. Bloom, and remove it from the shelf!";

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏆 1. HIGH GRAPHICS SAVINGS RECEIPT DASHBOARD
          _buildGraphicReceiptDashboard(clues.length),
          const SizedBox(height: 16),

          // 🌿 2. DOCTOR-APPROVED 3 ESSENTIALS KEPT BAR
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFECFDF5), Color(0xFFF0FDF4)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.08),
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
                    const Icon(Icons.verified_rounded, color: AppColors.success, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '3 Doctor-Approved Essentials Kept:',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF065F46),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '~₹300/mo',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildEssentialPill('🫧 Gentle Cleanser'),
                      const SizedBox(width: 8),
                      _buildEssentialPill('💧 Moisturiser'),
                      const SizedBox(width: 8),
                      _buildEssentialPill('☀️ SPF Sunscreen'),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),
          const SizedBox(height: 22),

          // 📢 3. INSTRUCTION & ROTATING CARDS GUIDE
          Row(
            children: [
              Expanded(
                child: Text(
                  'Amara\'s Bathroom Shelf',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.rotate_right_rounded, color: AppColors.purple, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Tap Card to 3D Flip 🔄',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            instruction,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: AppColors.textMedium,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),

          // 🎴 4. BIG CREATIVE ROTATING / FLIPPING 3D CARDS
          ...clues.asMap().entries.map((e) {
            final clue = e.value;
            final id = (clue['id'] as String? ?? 'ra_${e.key}');
            final isAudited = _found.contains(id);
            final price = _itemPrices[e.key % _itemPrices.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _Audit3DFlipCard(
                clue: clue,
                index: e.key,
                isAudited: isAudited,
                itemPrice: price,
                onTap: () => _onClueTapped(id),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── HIGH-GRAPHICS SAVINGS & RECEIPT DASHBOARD ──────────────────────────────
  Widget _buildGraphicReceiptDashboard(int totalItems) {
    final currentPrice = _currentShelfPrice;
    final savedAmount = 2500 - currentPrice;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF5F3FF),
            Color(0xFFFDF2F8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFDDD6FE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Receipt Badge Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Text('🧾', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 5),
                    Text(
                      'AMARA\'S SHELF RECEIPT',
                      style: GoogleFonts.nunito(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF7C3AED),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE7F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_found.length} / $totalItems REMOVED',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFDB2777),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Price & Savings Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Original Shelf: ₹2500',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.65),
                      decoration: TextDecoration.lineThrough,
                      decorationColor: const Color(0xFFF43F5E),
                      decorationThickness: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹$currentPrice',
                        style: GoogleFonts.nunito(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        ' / mo',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),

              // Pulsing Savings Badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: savedAmount > 0 ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    if (savedAmount > 0)
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.5),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'TOTAL SAVINGS',
                      style: GoogleFonts.nunito(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹$savedAmount 💰',
                      style: GoogleFonts.nunito(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ).animate(target: _found.isEmpty ? 0 : 1).scale(duration: 400.ms, curve: Curves.elasticOut),
            ],
          ),
          const SizedBox(height: 16),

          // Glowing Multi-segment Progress Caps
          Row(
            children: List.generate(totalItems, (i) {
              final isDone = i < _found.length;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: i < totalItems - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isDone ? const Color(0xFFFDE047) : Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: isDone
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFDE047).withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEssentialPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.06),
            blurRadius: 6,
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF047857),
        ),
      ),
    );
  }

  // ── GENERIC SPOT THE CHANGE UI (FALLBACK FOR OTHER EPISODES) ──────────────
  Widget _buildGenericSpotTheChangeUI() {
    final clues = _clues;
    final instruction = widget.content['instruction'] as String? ??
        "Check carefully! Spot the changes or clues below. 🔍";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            widget.content['title'] as String? ?? '🕵️ Growth Detective',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            instruction,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: AppColors.textMedium,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              clues.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _found.length
                      ? AppColors.success
                      : const Color(0xFFE5E7EB),
                ),
                child: Icon(
                  i < _found.length ? Icons.check_rounded : Icons.search_rounded,
                  size: 16,
                  color: i < _found.length ? Colors.white : Colors.grey.shade400,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildImageCard(
                  assetPath: 'assets/images/growth_detective_before.jpg',
                  label: 'Riya • Age 9',
                  subLabel: 'Early School Days',
                  borderColor: const Color(0xFFFBCFE8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildImageCard(
                  assetPath: 'assets/images/growth_detective_after.jpg',
                  label: 'Riya • Age 13',
                  subLabel: 'Growing & Confident',
                  borderColor: const Color(0xFFDDD6FE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          ...clues.asMap().entries.map((e) {
            final clue = e.value;
            final id = (clue['id'] as String? ?? 'clue_${e.key}');
            final isFound = _found.contains(id);

            return GestureDetector(
              onTap: () => _onClueTapped(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isFound ? const Color(0xFFECFDF5) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isFound
                        ? AppColors.success.withValues(alpha: 0.6)
                        : AppColors.purple.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isFound
                          ? AppColors.success.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isFound
                            ? AppColors.success.withValues(alpha: 0.15)
                            : const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          clue['emoji'] as String? ?? '🔍',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clue['label'] as String? ?? 'Clue ${e.key + 1}',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isFound
                                ? (clue['learning'] as String? ?? clue['hint'] as String? ?? '')
                                : (clue['hint'] as String? ?? ''),
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: isFound ? AppColors.textDark : AppColors.textMedium,
                              height: 1.4,
                              fontWeight: isFound ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isFound ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                      color: isFound ? AppColors.success : AppColors.purple,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: (e.key * 60).ms, duration: 300.ms);
          }),
        ],
      ),
    );
  }

  Widget _buildImageCard({
    required String assetPath,
    required String label,
    required String subLabel,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: AspectRatio(
              aspectRatio: 0.9,
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFF5F3FF),
                  child: const Center(
                    child: Icon(Icons.image, size: 40, color: AppColors.purple),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  subLabel,
                  style: GoogleFonts.nunito(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── COMPLETION CELEBRATION SCREEN ─────────────────────────────────────────
  Widget _buildCompletion() {
    final completionMsg = widget.content['completionMessage'] as String? ??
        "Audit complete! Amara's shelf just got ₹2200 lighter and 100% evidence-based! Remember: gentle cleanser + moisturiser + SPF is the real glow-up formula. 🌟";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEF9C3), Color(0xFFFDE68A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Text('🧴✨', style: TextStyle(fontSize: 48)),
            ),
          ).animate().scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut),

          const SizedBox(height: 20),
          Text(
            _isShelfAudit ? 'Audit Complete! 🛍️✨' : 'Master Growth Detective!',
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_isShelfAudit) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.savings_rounded, color: AppColors.success, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          '₹2200 SAVED! (₹2500 ➔ ₹300)',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                Text(
                  completionMsg,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

          const SizedBox(height: 30),

          GestureDetector(
            onTap: () {
              AppSoundService.instance.playPop();
              HapticFeedback.selectionClick();
              widget.onCompleted();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.purple,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Continue Journey • Collect 🪙 Coins',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 19),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }
}

// ── 🎴 3D FLIPPABLE / ROTATING AUDIT CARD WIDGET ────────────────────────────
class _Audit3DFlipCard extends StatefulWidget {
  final Map<String, dynamic> clue;
  final int index;
  final bool isAudited;
  final int itemPrice;
  final VoidCallback onTap;

  const _Audit3DFlipCard({
    required this.clue,
    required this.index,
    required this.isAudited,
    required this.itemPrice,
    required this.onTap,
  });

  @override
  State<_Audit3DFlipCard> createState() => _Audit3DFlipCardState();
}

class _Audit3DFlipCardState extends State<_Audit3DFlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

    if (widget.isAudited) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _Audit3DFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAudited && !_controller.isCompleted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.isAudited) {
      widget.onTap();
    } else {
      // Toggle flip if already audited
      if (_controller.isCompleted) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardGradients = [
      const [Color(0xFFFFF5F5), Color(0xFFFED7D7)], // Rose
      const [Color(0xFFF5F3FF), Color(0xFFDDD6FE)], // Violet
      const [Color(0xFFFFFBEB), Color(0xFFFDE68A)], // Amber
      const [Color(0xFFEFF6FF), Color(0xFFBFDBFE)], // Soft Blue
      const [Color(0xFFFDF2F8), Color(0xFFFBCFE8)], // Soft Pink
    ];
    final gradientColors = cardGradients[widget.index % cardGradients.length];

    final emoji = widget.clue['emoji'] as String? ?? '🧴';
    final label = widget.clue['label'] as String? ?? 'Product';
    final hint = widget.clue['hint'] as String? ?? widget.clue['learning'] as String? ?? '';

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isBackFacing = angle >= pi / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective depth
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isBackFacing
                ? Transform(
                    transform: Matrix4.identity()..rotateY(pi), // Un-mirror back content
                    alignment: Alignment.center,
                    child: _buildBackFace(emoji, label, hint, gradientColors),
                  )
                : _buildFrontFace(emoji, label, gradientColors),
          );
        },
      ),
    );
  }

  // ── FRONT CARD FACE ───────────────────────────────────────────────────────
  Widget _buildFrontFace(String emoji, String label, List<Color> gradientColors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.25),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[1].withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Price Tag & Warning Badge Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏷️', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '₹${widget.itemPrice}',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.purple,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(
                      'UNNECESSARY PRODUCT ⚠️',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFDC2626),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Center Big Emoji & Product Details
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 34)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.nunito(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap card to Audit & Remove with Dr. Bloom',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bottom Interactive CTA Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.rotate_right_rounded, color: AppColors.purple, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Audit & Remove Product 🔄',
                  style: GoogleFonts.nunito(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── BACK CARD FACE (AUDITED & FLIPPED 180°) ────────────────────────────────
  Widget _buildBackFace(String emoji, String label, String hint, List<Color> gradientColors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Stamped Badge Row
          Row(
            children: [
              Transform.rotate(
                angle: -0.06,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'REMOVED 🗑️',
                        style: GoogleFonts.nunito(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFDC2626),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+₹${widget.itemPrice} Saved 💰',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF047857),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Doctor Kiran Quote Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9C3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('👩‍⚕️', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. Bloom\'s Audit Verdict:',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hint,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF78350F),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Bottom Tap to Flip Back Info
          Center(
            child: Text(
              'Tap card again to flip back 🔄',
              style: GoogleFonts.nunito(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
