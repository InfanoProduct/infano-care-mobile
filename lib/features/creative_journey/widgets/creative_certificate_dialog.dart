import 'dart:convert';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';

class CreativeCertificate {
  final String id;
  final String journeyId;
  final String journeyTitle;
  final String recipientName;
  final String issueDate;
  final int totalEpisodes;
  final int totalNodes;
  final String gigiQuote;

  CreativeCertificate({
    required this.id,
    required this.journeyId,
    required this.journeyTitle,
    required this.recipientName,
    required this.issueDate,
    required this.totalEpisodes,
    required this.totalNodes,
    required this.gigiQuote,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'journeyId': journeyId,
        'journeyTitle': journeyTitle,
        'recipientName': recipientName,
        'issueDate': issueDate,
        'totalEpisodes': totalEpisodes,
        'totalNodes': totalNodes,
        'gigiQuote': gigiQuote,
      };

  factory CreativeCertificate.fromJson(Map<String, dynamic> json) =>
      CreativeCertificate(
        id: json['id'] as String? ?? 'CERT-${DateTime.now().millisecondsSinceEpoch}',
        journeyId: json['journeyId'] as String? ?? 'cj_my_changing_body',
        journeyTitle: json['journeyTitle'] as String? ?? 'My Changing Body',
        recipientName: json['recipientName'] as String? ?? 'Young Explorer',
        issueDate: json['issueDate'] as String? ?? 'August 21, 2026',
        totalEpisodes: json['totalEpisodes'] as int? ?? 6,
        totalNodes: json['totalNodes'] as int? ?? 58,
        gigiQuote: json['gigiQuote'] as String? ??
            'Embrace your unique growth with courage, body gratitude, and wisdom!',
      );
}

class CreativeCertificateService {
  static const String _key = 'user_earned_certificates';

  static Future<void> saveCertificate(CreativeCertificate cert) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getCertificates();
    list.removeWhere((c) => c.journeyId == cert.journeyId);
    list.add(cert);

    final jsonList = list.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  static Future<List<CreativeCertificate>> getCertificates() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    return jsonList
        .map((s) => CreativeCertificate.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }
}

class CreativeCertificateDialog extends StatefulWidget {
  final CreativeCertificate certificate;
  final VoidCallback? onClaimed;

  const CreativeCertificateDialog({
    super.key,
    required this.certificate,
    this.onClaimed,
  });

  static Future<void> show(
    BuildContext context, {
    required CreativeCertificate certificate,
    VoidCallback? onClaimed,
  }) {
    AppSoundService.instance.playFanfare();
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CreativeCertificateDialog(
        certificate: certificate,
        onClaimed: onClaimed,
      ),
    );
  }

  @override
  State<CreativeCertificateDialog> createState() => _CreativeCertificateDialogState();
}

class _CreativeCertificateDialogState extends State<CreativeCertificateDialog> {
  late final ConfettiController _confettiCtrl;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 4));
    _confettiCtrl.play();
    _checkSaved();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkSaved() async {
    final list = await CreativeCertificateService.getCertificates();
    if (mounted) {
      setState(() {
        _isSaved = list.any((c) => c.journeyId == widget.certificate.journeyId);
      });
    }
  }

  Future<void> _saveToProfile() async {
    await CreativeCertificateService.saveCertificate(widget.certificate);
    AppSoundService.instance.playCorrect();
    _confettiCtrl.play();
    if (mounted) {
      setState(() => _isSaved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎓 Graduation Certificate saved to your Profile!',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
          ),
          backgroundColor: AppColors.purple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  void _shareCertificate() {
    AppSoundService.instance.playPop();
    Share.share(
      '🎓 I just graduated from the "${widget.certificate.journeyTitle}" Creative Journey on Infano Care! '
      'Completed ${widget.certificate.totalEpisodes} Episodes & ${widget.certificate.totalNodes} Mindset Nodes with Gigi! 🌸✨',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cert = widget.certificate;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ultra-Attractive Pastel Certificate Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFAF5FF), // Soft Lavender Mist
                        Color(0xFFFFF0F5), // Rose Powder
                        Color(0xFFF0FDF4), // Mint Whisper
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFC4B5FD), width: 2.5), // Pastel Lavender Border
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA78BFA).withValues(alpha: 0.25),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Corner Ornate Watermark Accents (Pastel Violet)
                      Positioned(
                        top: -8,
                        left: -8,
                        child: const Text('🌿', style: TextStyle(fontSize: 24, color: Color(0xFFA78BFA))),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: const Text('🌿', style: TextStyle(fontSize: 24, color: Color(0xFFA78BFA))),
                      ),

                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          // Top Pastel Ribbon Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEDE9FE), Color(0xFFFCE7F3)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFA78BFA).withValues(alpha: 0.2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🎓', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  'OFFICIAL GRADUATION CERTIFICATE',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF5B21B6),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Certificate Header Title
                          Text(
                            'CERTIFICATE OF COMPLETION',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cinzel(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF4C1D95),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This certificate is proudly awarded to',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: AppColors.textMedium,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Recipient Name Highlight
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFA78BFA), width: 1.8),
                              ),
                            ),
                            child: Text(
                              cert.recipientName,
                              style: GoogleFonts.sacramento(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6D28D9),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Citation Body Text
                          Text(
                            'For successfully completing all ${cert.totalEpisodes} Episodes and ${cert.totalNodes} Mindset Nodes in the "${cert.journeyTitle}" Creative Journey, demonstrating courage, body gratitude, self-kindness, and puberty wisdom!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 12.5,
                              height: 1.5,
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Gigi's Personal Quote Card (Soft Pastel Lavender Tint)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFDDD6FE)),
                            ),
                            child: Row(
                              children: [
                                const Text('🐱', style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '"${cert.gigiQuote}"',
                                    style: GoogleFonts.nunito(
                                      fontSize: 11.5,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF5B21B6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Seal & Signatures Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left Signature Stamp (Gigi Guide)
                              Column(
                                children: [
                                  Text(
                                    '🐾 Gigi Mascot',
                                    style: GoogleFonts.sacramento(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF5B21B6),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(height: 1, width: 80, color: const Color(0xFFA78BFA)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Chief Empowerment Guide',
                                    style: GoogleFonts.nunito(fontSize: 9, color: AppColors.textMedium, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),

                              // Center Pastel Medal Emblem Seal
                              Container(
                                width: 54,
                                height: 54,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Color(0xFFC4B5FD), Color(0xFFF472B6)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(color: Color(0x40A78BFA), blurRadius: 10),
                                  ],
                                ),
                                child: const Center(
                                  child: Text('🏆', style: TextStyle(fontSize: 26)),
                                ),
                              ),

                              // Right Signature Stamp (Infano Care Team)
                              Column(
                                children: [
                                  Text(
                                    'Infano Care',
                                    style: GoogleFonts.sacramento(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF5B21B6),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(height: 1, width: 80, color: const Color(0xFFA78BFA)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Medical Expert Team',
                                    style: GoogleFonts.nunito(fontSize: 9, color: AppColors.textMedium, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Footer ID + Date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ID: ${cert.id}', style: GoogleFonts.nunito(fontSize: 9.5, color: AppColors.textLight, fontWeight: FontWeight.w700)),
                              Text('Date: ${cert.issueDate}', style: GoogleFonts.nunito(fontSize: 9.5, color: AppColors.textLight, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().scale(begin: const Offset(0.9, 0.9), duration: 500.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 16),

                // Dialog Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaved ? null : _saveToProfile,
                        icon: Icon(_isSaved ? Icons.check_circle_rounded : Icons.bookmark_add_rounded, size: 18),
                        label: Text(_isSaved ? 'Saved in Profile' : 'Save to Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSaved ? const Color(0xFF059669) : AppColors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      onPressed: _shareCertificate,
                      icon: const Icon(Icons.share_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.purple,
                        padding: const EdgeInsets.all(14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Complete & Done Button
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onClaimed?.call();
                  },
                  child: Text(
                    'Done & Collect Rewards ✨',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Confetti Animation Layer
          ConfettiWidget(
            confettiController: _confettiCtrl,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Color(0xFFA78BFA),
              Color(0xFFF472B6),
              Color(0xFF34D399),
              Color(0xFF60A5FA),
              Color(0xFFFBBF24),
            ],
          ),
        ],
      ),
    );
  }
}
