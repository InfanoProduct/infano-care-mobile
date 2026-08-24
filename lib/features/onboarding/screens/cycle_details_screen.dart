import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';

class CycleDetailsScreen extends StatefulWidget {
  const CycleDetailsScreen({super.key});

  @override
  State<CycleDetailsScreen> createState() => _CycleDetailsScreenState();
}

class _CycleDetailsScreenState extends State<CycleDetailsScreen> {
  int _periodLength = 5;
  int _cycleLength = 28;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B7CD8),
      body: Stack(
        children: [
          // 1. 3D Background Illustration (Optimized room image)
          Positioned.fill(
            child: Image.asset(
              'assets/images/period_tracker_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // 2. Subtle Soft Gradient Overlay
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
              onTap: () => context.go('/onboarding/tracker/date'),
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

                        // 3D Glassmorphic Details Card
                        BlocBuilder<OnboardingBloc, OnboardingState>(
                          builder: (context, state) {
                            final isPeriodActive = state.periodStatus == 'active';

                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.94),
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
                                  // 3D Badge Icon
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
                                      child: Icon(Icons.show_chart_rounded, size: 28, color: Color(0xFF6D28D9)),
                                    ),
                                  ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                                  const SizedBox(height: 14),

                                  // Title
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Cycle Details",
                                        style: GoogleFonts.nunito(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF2D1557),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text('🌙', style: TextStyle(fontSize: 18)),
                                    ],
                                  ),

                                  const SizedBox(height: 4),

                                  // Subtitle
                                  Text(
                                    "Don't worry if you're not sure — we'll refine predictions as you track!",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF6B7280),
                                      height: 1.35,
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  if (isPeriodActive) ...[
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Is your cycle regular?',
                                        style: GoogleFonts.nunito(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF374151),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        _RegularityChip(
                                          label: 'Regular',
                                          isSelected: !state.isIrregular,
                                          onTap: () => context.read<OnboardingBloc>().add(const SetRegularity(false)),
                                        ),
                                        const SizedBox(width: 12),
                                        _RegularityChip(
                                          label: 'Irregular',
                                          isSelected: state.isIrregular,
                                          onTap: () => context.read<OnboardingBloc>().add(const SetRegularity(true)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                  ],

                                  // Period length slider card
                                  _SliderCard(
                                    title: 'Period length',
                                    value: _periodLength.toDouble(),
                                    min: 2,
                                    max: 10,
                                    unit: 'days',
                                    color: const Color(0xFFE11D48),
                                    onChanged: (v) => setState(() => _periodLength = v.round()),
                                  ),

                                  const SizedBox(height: 14),

                                  // Cycle length slider card
                                  _SliderCard(
                                    title: 'Cycle length',
                                    value: _cycleLength.toDouble(),
                                    min: 21,
                                    max: 45,
                                    unit: 'days',
                                    color: const Color(0xFF6D28D9),
                                    onChanged: (v) => setState(() => _cycleLength = v.round()),
                                  ),

                                  const SizedBox(height: 16),

                                  // Info Card
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text('📊', style: TextStyle(fontSize: 20)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            state.isIrregular
                                                ? 'Irregular cycles are very common, especially in the first few years! We\'ll help you identify your rhythm. 💜'
                                                : 'Average period: 5 days · Average cycle: 28 days.',
                                            style: GoogleFonts.nunito(
                                              color: const Color(0xFF4B5563),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Primary Setup CTA Button
                                  GestureDetector(
                                    onTap: state.isLoading
                                        ? null
                                        : () async {
                                            final bloc = context.read<OnboardingBloc>();
                                            bloc.add(SetTrackerDetails(_periodLength, _cycleLength, bloc.state.lastPeriod));
                                            bloc.add(const SubmitTrackerSetup('active'));

                                            await for (final s in bloc.stream) {
                                              if (!s.isLoading) {
                                                if (s.errorMessage == null) {
                                                  if (mounted) context.go('/onboarding/tracker/done');
                                                } else {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text(s.errorMessage!)),
                                                    );
                                                  }
                                                }
                                                break;
                                              }
                                            }
                                          },
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
                                        child: state.isLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                              )
                                            : Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Set Up My Tracker',
                                                    style: GoogleFonts.nunito(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text('🌸', style: TextStyle(fontSize: 16)),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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

class _RegularityChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RegularityChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6D28D9) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? const Color(0xFF6D28D9) : const Color(0xFFE5E7EB), width: 1.2),
            boxShadow: isSelected
                ? [BoxShadow(color: const Color(0xFF6D28D9).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderCard extends StatelessWidget {
  const _SliderCard({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.color,
    required this.onChanged,
  });

  final String title, unit;
  final double value, min, max;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1F2937),
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${value.round()} $unit',
                  style: GoogleFonts.nunito(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.1),
              trackHeight: 6,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
