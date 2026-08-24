import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';

class LastPeriodDateScreen extends StatefulWidget {
  const LastPeriodDateScreen({super.key});

  @override
  State<LastPeriodDateScreen> createState() => _LastPeriodDateScreenState();
}

class _LastPeriodDateScreenState extends State<LastPeriodDateScreen> {
  DateTime? _selected = DateTime.now();
  bool _dontRemember = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B7CD8),
      body: Stack(
        children: [
          // 1. 3D Background Illustration (Optimized pastel room image)
          Positioned.fill(
            child: Image.asset(
              'assets/images/period_tracker_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // 2. Subtle Soft Gradient Overlay for depth and text legibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF5B21B6).withValues(alpha: 0.1),
                    const Color(0xFF2D1557).withValues(alpha: 0.38),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. Back Button (Top Left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => context.go('/onboarding/terms'),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF5B21B6)),
              ),
            ),
          ),

          // 4. Interactive Glassmorphic Setup Card
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        // 3D Glassmorphic Calendar Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94), // Glassmorphic white card
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: Colors.white, width: 2.0),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4C1D95).withValues(alpha: 0.22),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 3D Calendar Badge Icon
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFEDE9FE), Color(0xFFF5F3FF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6D28D9).withValues(alpha: 0.16),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(Icons.calendar_month_rounded, size: 28, color: Color(0xFF6D28D9)),
                                ),
                              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                              const SizedBox(height: 14),

                              // Header Title
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Last period start?",
                                    style: GoogleFonts.nunito(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF2D1557),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('📅', style: TextStyle(fontSize: 18)),
                                ],
                              ),

                              const SizedBox(height: 4),

                              // Subtitle
                              Text(
                                "This helps us give you accurate predictions right away!",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6B7280),
                                  height: 1.35,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Calendar Picker inside styled glass container
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                                ),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF6D28D9),
                                      onPrimary: Colors.white,
                                      surface: Colors.transparent,
                                    ),
                                  ),
                                  child: CalendarDatePicker(
                                    initialDate: _selected ?? DateTime.now(),
                                    firstDate: DateTime.now().subtract(const Duration(days: 90)),
                                    lastDate: DateTime.now(),
                                    onDateChanged: (d) => setState(() {
                                      _selected = d;
                                      _dontRemember = false;
                                    }),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Estimate / Don't remember checkbox
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _dontRemember ? const Color(0xFFF3E8FF) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: CheckboxListTile(
                                  value: _dontRemember,
                                  onChanged: (v) => setState(() {
                                    _dontRemember = v ?? false;
                                    if (v == true) _selected = null;
                                  }),
                                  activeColor: const Color(0xFF6D28D9),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  title: Text(
                                    "I don't remember — estimate for me",
                                    style: GoogleFonts.nunito(
                                      color: const Color(0xFF374151),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Primary CTA Continue Button (Glassmorphic 3D styling matching phone entry screen)
                              GestureDetector(
                                onTap: (_selected != null || _dontRemember)
                                    ? () {
                                        final bloc = context.read<OnboardingBloc>();
                                        bloc.add(SetTrackerDetails(
                                          bloc.state.periodLength,
                                          bloc.state.cycleLength,
                                          _selected,
                                        ));
                                        context.go('/onboarding/tracker/details');
                                      }
                                    : null,
                                child: AnimatedOpacity(
                                  opacity: (_selected != null || _dontRemember) ? 1.0 : 0.6,
                                  duration: const Duration(milliseconds: 200),
                                  child: Container(
                                    height: 50,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF6D28D9), Color(0xFF5B21B6)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF5B21B6).withValues(alpha: 0.35),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Continue',
                                            style: GoogleFonts.nunito(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Skip Link
                              GestureDetector(
                                onTap: () async {
                                  final bloc = context.read<OnboardingBloc>();
                                  bloc.add(const SkipTracker());
                                  await bloc.stream.firstWhere((state) => !state.isLoading);
                                  if (!context.mounted) return;
                                  context.go('/home');
                                },
                                child: Text(
                                  "I'll do this later",
                                  style: GoogleFonts.nunito(
                                    color: const Color(0xFF6B7280),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
