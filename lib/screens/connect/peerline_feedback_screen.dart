import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:infano_care_mobile/models/peerline_session.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';

class PeerLineFeedbackScreen extends StatefulWidget {
  final String sessionId;

  const PeerLineFeedbackScreen({Key? key, required this.sessionId}) : super(key: key);

  @override
  State<PeerLineFeedbackScreen> createState() => _PeerLineFeedbackScreenState();
}

class _PeerLineFeedbackScreenState extends State<PeerLineFeedbackScreen> {
  int _rating = 0;
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;
  PeerLineSession? _session;
  bool _isLoading = true;
  String? _role;

  int _mentorSelfRating = 0;
  bool _wellbeingOk = true;
  bool _needsSupport = false;
  bool _readyForNext = true;
  bool _flagForModeration = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final api = Provider.of<CommunityApi>(context, listen: false);
      final storage = Provider.of<LocalStorageService>(context, listen: false);
      final session = await api.getSession(widget.sessionId);

      setState(() {
        _session = session;
        _isLoading = false;
        _role = session.menteeId == storage.userId ? 'mentee' : 'mentor';
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading session: $e')));
      }
    }
  }

  Future<void> _submit() async {
    if (_rating == 0 && _role == 'mentee') {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a rating.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final api = Provider.of<CommunityApi>(context, listen: false);
      await api.submitPeerLineFeedback(
        sessionId: widget.sessionId,
        role: _role!,
        rating: _rating,
        note: _noteController.text.trim(),
        mentorSelfRating: _mentorSelfRating > 0 ? _mentorSelfRating : null,
        wellbeingOk: _wellbeingOk,
        needsSupport: _needsSupport,
        readyForNext: _readyForNext,
        flagForModeration: _flagForModeration,
      );

      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting feedback: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (_role == null) {
      return const Scaffold(body: Center(child: Text('Unauthorized')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F1EA),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE7F6),
            borderRadius: BorderRadius.circular(24),
          ),
          child: _role == 'mentee'
              ? _buildMenteeView()
              : _buildMentorView(),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD2557A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('Done',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildMenteeView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thank you for connecting 💜',
            style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937))),
        const SizedBox(height: 8),
        Text(
          'Your conversation stays private. This helps us improve PeerLine for everyone.',
          style: GoogleFonts.outfit(
              fontSize: 14, color: const Color(0xFF6B7280)),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Did this conversation help?',
                  style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: List.generate(
                    5,
                    (index) => IconButton(
                          onPressed: () =>
                              setState(() => _rating = index + 1),
                          icon: Icon(
                            Icons.star_rounded,
                            color: index < _rating
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFE5E7EB),
                            size: 36,
                          ),
                        )),
              ),
              const SizedBox(height: 16),
              Text('Anything you\'d like to share? (optional)',
                  style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Aria was really kind and helped me feel less alone about my anxiety...',
                  filled: true,
                  fillColor: const Color(0xFFE9E5F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Text('Mentor wellbeing check',
            style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF15803D))),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildWellbeingRow(
                  'Are you okay after this session?',
                  _wellbeingOk,
                  (v) => setState(() => _wellbeingOk = v)),
              _buildWellbeingRow(
                  'Do you need to talk to someone?',
                  _needsSupport,
                  (v) => setState(() => _needsSupport = v)),
              _buildWellbeingRow(
                  'Ready for next session?',
                  _readyForNext,
                  (v) => setState(() => _readyForNext = v)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWellbeingRow(
      String text, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(text)),
          Row(
            children: [
              _chip('Yes', value == true, () => onChanged(true)),
              const SizedBox(width: 8),
              _chip('No', value == false, () => onChanged(false)),
            ],
          )
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF059669)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF059669)),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected
                    ? Colors.white
                    : const Color(0xFF059669))),
      ),
    );
  }

  Widget _buildMentorView() {
    return _buildMenteeView(); // UI same styling
  }
}