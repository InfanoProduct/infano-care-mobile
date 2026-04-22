import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class CrisisResourceCard extends StatefulWidget {
  final VoidCallback? onDismiss;
  const CrisisResourceCard({Key? key, this.onDismiss}) : super(key: key);

  @override
  State<CrisisResourceCard> createState() => _CrisisResourceCardState();
}

class _CrisisResourceCardState extends State<CrisisResourceCard>
    with SingleTickerProviderStateMixin {
  bool _canDismiss = false;
  int _countdown = 10;
  Timer? _timer;
  bool _isLoading = true;
  List<dynamic> _helplines = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _fetchResources();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    debugPrint("[Analytics] crisis_resource_shown");
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        setState(() => _canDismiss = true);
        timer.cancel();
      }
    });
  }

  Future<void> _fetchResources() async {
    try {
      final api = Provider.of<CommunityApi>(context, listen: false);
      final data = await api.getCrisisResources();
      if (mounted) {
        setState(() {
          _helplines = data['helplines'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _helplines = [
            {
              'name': 'Vandrevala Foundation',
              'phone': '9999666555',
              'hours': '24/7',
              'sms': '9999666555'
            },
            {
              'name': 'National Alliance for Eating Disorders',
              'phone': '8666621235',
              'hours': 'Mon-Fri, 9am-7pm EST'
            }
          ];
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F1EA), // updated background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // 💜 Gradient Heart
              ScaleTransition(
                scale: _pulseAnimation,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
                  ).createShader(bounds),
                  child: const Icon(Icons.favorite,
                      size: 64, color: Colors.white),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'What you shared matters.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Here are people who can help right now.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: const Color(0xFF6B7280),
                ),
              ),

              const SizedBox(height: 32),

              // Helplines
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF8B5CF6)))
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: _helplines.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final h = _helplines[index];
                          return _buildHelplineCard(h);
                        },
                      ),
              ),

              const SizedBox(height: 16),

              // Buttons
              Column(
                children: [
                  // 🔶 Primary Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _helplines.isNotEmpty
                          ? () => _launchUrl(
                              'tel:${_helplines[0]['phone']}')
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE3643B),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        'I need help now →',
                        style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ⚪ Secondary Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _canDismiss
                          ? () {
                              if (widget.onDismiss != null) {
                                widget.onDismiss!();
                              } else {
                                Navigator.of(context).pop();
                              }
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 18),
                        side: BorderSide(
                          color: const Color(0xFFD1D5DB),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _canDismiss
                            ? "I'm safe"
                            : "I'm safe (Wait $_countdown s)",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelplineCard(dynamic h) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE07A5F),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  h['name'] ?? 'Helpline',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
              if (h['hours'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    h['hours'],
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      _launchUrl('tel:${h['phone']}'),
                  child: Text(
                    h['phone'] ?? '',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE3643B),
                    ),
                  ),
                ),
              ),

              if (h['sms'] != null)
                IconButton(
                  onPressed: () =>
                      _launchUrl('sms:${h['sms']}'),
                  icon: const Icon(Icons.sms_outlined,
                      color: Color(0xFFE3643B)),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFFEECE6),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}