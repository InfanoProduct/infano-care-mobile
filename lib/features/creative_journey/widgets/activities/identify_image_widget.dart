import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';

class IdentifyImageWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onCompleted;

  const IdentifyImageWidget({super.key, required this.content, required this.onCompleted});

  @override
  State<IdentifyImageWidget> createState() => _IdentifyImageWidgetState();
}

class _IdentifyImageWidgetState extends State<IdentifyImageWidget> {
  final Set<String> _selected = {};
  bool _submitted = false;

  List<Map<String, dynamic>> get icons =>
      List<Map<String, dynamic>>.from(widget.content['icons'] as List? ?? []);

  int get correctCount => _selected.where((id) {
        final icon = icons.firstWhere((i) => i['id'] == id, orElse: () => {});
        return icon['isCorrect'] == true;
      }).length;

  int get expectedCorrect => icons.where((i) => i['isCorrect'] == true).length;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF5F3FF), Color(0xFFFDF2F8)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
            ),
            child: Column(children: [
              const Text('🔍', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                widget.content['instruction'] as String? ?? 'Tap all icons that are normal!',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark, height: 1.4),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: icons.length,
            itemBuilder: (context, i) {
              final icon = icons[i];
              final id = icon['id'] as String;
              final isSelected = _selected.contains(id);
              final isCorrect = icon['isCorrect'] as bool? ?? false;

              Color borderColor = AppColors.purple.withValues(alpha: 0.2);
              Color bgColor = Colors.white;

              if (_submitted) {
                if (isSelected && isCorrect) {
                  borderColor = AppColors.success;
                  bgColor = const Color(0xFFD1FAE5);
                } else if (isSelected && !isCorrect) {
                  borderColor = AppColors.error;
                  bgColor = const Color(0xFFFEE2E2);
                } else if (!isSelected && isCorrect) {
                  borderColor = const Color(0xFFFBBF24);
                  bgColor = const Color(0xFFFEF3C7);
                }
              } else if (isSelected) {
                borderColor = AppColors.purple;
                bgColor = const Color(0xFFF5F3FF);
              }

              return GestureDetector(
                onTap: _submitted
                    ? null
                    : () {
                        AppSoundService.instance.playPop();
                        setState(() {
                          if (_selected.contains(id)) {
                            _selected.remove(id);
                          } else {
                            _selected.add(id);
                          }
                        });
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(icon['emoji'] as String? ?? '❓', style: const TextStyle(fontSize: 32)),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          icon['label'] as String? ?? '',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.purple.withValues(alpha: 0.8),
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 10),
                        ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (i * 50).ms, duration: 300.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.easeOutBack);
            },
          ),

          // Distractor feedback
          if (_submitted)
            ...icons.where((i) => _selected.contains(i['id']) && i['isCorrect'] == false).map(
              (i) => Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9F0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.5)),
                ),
                child: Row(children: [
                  Text(i['emoji'] as String? ?? '❓', style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(i['distractorNote'] as String? ?? '', style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textDark, height: 1.4))),
                ]),
              ).animate().fadeIn(duration: 400.ms),
            ),

          if (_submitted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Text(
                widget.content['completionMessage'] as String? ?? 'Great work!',
                style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textDark, height: 1.5, fontWeight: FontWeight.w600),
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                AppSoundService.instance.playBunchOfCoinsSound();
                widget.onCompleted();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.purple,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text('Collect 🪙 Coins', textAlign: TextAlign.center, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
          ] else if (_selected.isNotEmpty) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                AppSoundService.instance.playCorrect();
                setState(() => _submitted = true);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.purple,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text('Check My Answers 🔍', textAlign: TextAlign.center, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
