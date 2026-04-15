import 'package:flutter/material.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportModal extends StatefulWidget {
  final String postId;
  final Function(String category, String? note) onSubmit;

  const ReportModal({
    Key? key,
    required this.postId,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<ReportModal> createState() => _ReportModalState();
}

class _ReportModalState extends State<ReportModal> {
  String _selectedCategory = 'harmful';
  final TextEditingController _noteController = TextEditingController();

  final List<Map<String, String>> _categories = [
    {'id': 'harmful', 'label': 'Harmful or upsetting'},
    {'id': 'bullying', 'label': 'Bullying or harassment'},
    {'id': 'spam', 'label': 'Spam or off-topic'},
    {'id': 'misinformation', 'label': 'Misinformation'},
    {'id': 'other', 'label': 'Something else'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12, // Reduced for handle
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sheet Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Help us keep this space safe 💜',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Reporting is a safety tool, not a weapon. Select why you are flagging this post.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 24),
          ..._categories.map((cat) => RadioListTile<String>(
                title: Text(cat['label']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                value: cat['id']!,
                groupValue: _selectedCategory,
                activeColor: AppColors.purple,
                contentPadding: EdgeInsets.zero,
                dense: true,
                onChanged: (val) => setState(() => _selectedCategory = val!),
              )),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            maxLength: 100,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Anything else to add? (Optional)',
              hintStyle: const TextStyle(fontSize: 14),
              filled: true,
              fillColor: AppColors.background.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              counterText: '',
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                widget.onSubmit(_selectedCategory, _noteController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Thanks for letting us know We take every report seriously. 💜',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: AppColors.purple,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text('Submit report', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
