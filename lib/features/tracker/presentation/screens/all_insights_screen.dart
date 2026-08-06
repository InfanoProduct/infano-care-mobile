import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/data/models/insight_models.dart';
import 'package:infano_care_mobile/features/tracker/presentation/screens/story_screen.dart';
import 'package:infano_care_mobile/features/tracker/bloc/quest_bloc.dart';

class AllInsightsScreen extends StatefulWidget {
  final List<DailyInsight> insights;
  final List<String> initialReadIds;

  const AllInsightsScreen({
    super.key,
    required this.insights,
    this.initialReadIds = const [],
  });

  @override
  State<AllInsightsScreen> createState() => _AllInsightsScreenState();
}

class _AllInsightsScreenState extends State<AllInsightsScreen> {
  late List<String> _readIds;

  @override
  void initState() {
    super.initState();
    _readIds = List.from(widget.initialReadIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Daily Insights 📊',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
            fontSize: 18,
          ),
        ),
      ),
      body: widget.insights.isEmpty
          ? Center(
              child: Text(
                'No insights available today.',
                style: GoogleFonts.nunito(
                  color: AppColors.textMedium,
                  fontSize: 14,
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
              ),
              itemCount: widget.insights.length,
              itemBuilder: (context, index) {
                final insight = widget.insights[index];
                final isRead = _readIds.contains(insight.id);
                
                final backgrounds = [
                  const Color(0xFFEEF2FF), // Soft Indigo
                  const Color(0xFFFDF2F8), // Soft Pink
                  const Color(0xFFECFDF5), // Soft Mint
                  const Color(0xFFFFFBEB), // Soft Amber
                  const Color(0xFFF5F3FF), // Soft Violet
                ];
                
                final borders = [
                  const Color(0xFFC7D2FE),
                  const Color(0xFFFBCFE8),
                  const Color(0xFFA7F3D0),
                  const Color(0xFFFDE68A),
                  const Color(0xFFDDD6FE),
                ];

                final colorIndex = index % backgrounds.length;
                final bgColor = backgrounds[colorIndex];
                final borderColor = borders[colorIndex];

                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StoryScreen(insight: insight),
                    ),
                  ).then((_) {
                    if (context.mounted) {
                      try {
                        context.read<QuestBloc>().add(const QuestEvent.refresh());
                      } catch (_) {}
                    }
                    if (mounted) {
                      setState(() {
                        if (!_readIds.contains(insight.id)) {
                          _readIds.add(insight.id);
                        }
                      });
                    }
                  }),
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: isRead ? bgColor.withValues(alpha: 0.5) : bgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isRead ? borderColor.withValues(alpha: 0.5) : borderColor,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                insight.previewEmoji,
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text(
                                insight.previewTitle,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: isRead ? AppColors.textMedium : AppColors.textDark,
                                  decoration: isRead ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isRead)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
